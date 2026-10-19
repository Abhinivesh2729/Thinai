import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/downloader.dart';
import 'package:local_llm/models_repo/hf_hub.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/models_page.dart';

import 'helpers/fonts.dart';

const _gib = 1024 * 1024 * 1024;

class _FakeHub implements HttpClientAdapter {
  _FakeHub(this.handle);

  final ResponseBody Function(RequestOptions options) handle;
  var calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return handle(options);
  }

  @override
  void close({bool force = false}) {}
}

class _FakeDownloader extends ModelDownloader {
  final started = <String>[];
  final tokens = <String, CancelToken>{};
  final streams = <String, StreamController<DownloadProgress>>{};

  @override
  Future<DownloadHandle> start(
    String url, {
    String? filename,
    String? displayName,
  }) async {
    final name = filename!;
    started.add(name);
    final controller = StreamController<DownloadProgress>.broadcast();
    streams[name] = controller;
    tokens[name] = CancelToken();
    return DownloadHandle(
      url: url,
      destPath: '/nowhere/$name',
      cancelToken: tokens[name]!,
      progress: controller.stream,
      label: displayName ?? name,
    );
  }
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, dynamic> _repo({bool gated = false, List<Map>? siblings}) => {
  'id': 'acme/Tiny-GGUF',
  'sha': 'abc123',
  'downloads': 4200,
  'likes': 7,
  'gated': gated ? 'manual' : false,
  'cardData': {'license': 'mit'},
  'gguf': {'total': 1500000000, 'context_length': 32768},
  'siblings':
      siblings ??
      [
        {'rfilename': 'Tiny-Q4_K_M.gguf', 'size': 900 * 1024 * 1024},
        {'rfilename': 'Tiny-Q8_0.gguf', 'size': 1600 * 1024 * 1024},
        {'rfilename': 'Tiny-F16.gguf', 'size': 6 * _gib},
        {'rfilename': 'mmproj-F16.gguf', 'size': 600 * 1024 * 1024},
      ],
};

ResponseBody Function(RequestOptions) _serve(Map<String, dynamic> repo) =>
    (o) => o.uri.path.endsWith('README.md')
    ? ResponseBody.fromString(
        'A tiny model for testing the repo page on a phone screen.',
        200,
      )
    : _json(repo);

Future<_FakeDownloader> _pump(
  WidgetTester tester,
  _FakeHub hub, {
  List<LocalModel> installed = const [],
  List<PartialDownload> partials = const [],
}) async {
  tester.view.physicalSize = const Size(420 * 2, 3000 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final downloader = _FakeDownloader();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hfHubProvider.overrideWithValue(
          HfHub(dio: Dio()..httpClientAdapter = hub),
        ),
        modelListProvider.overrideWith((ref) async => installed),
        partialDownloadsProvider.overrideWith((ref) async => partials),
        // 4 GB: the 900 MB file fits, 1.6 GB is tight, 6 GB is too big.
        deviceProfileProvider.overrideWith(
          (ref) async => const DeviceProfile(
            totalRamBytes: 4 * _gib,
            availableRamBytes: 2 * _gib,
            cores: 8,
          ),
        ),
        modelDownloaderProvider.overrideWithValue(downloader),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Roboto'),
        home: const HfRepoPage(repoId: 'acme/Tiny-GGUF'),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return downloader;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(loadRoboto);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the card and the loadable files with their fit', (
    tester,
  ) async {
    await _pump(tester, _FakeHub(_serve(_repo())));

    expect(find.text('Tiny-GGUF'), findsWidgets);
    expect(find.text('by acme'), findsOneWidget);
    expect(find.text('mit'), findsOneWidget);
    expect(find.text('32K ctx'), findsOneWidget);
    expect(find.text('1.5B'), findsOneWidget);
    expect(
      find.text('A tiny model for testing the repo page on a phone screen.'),
      findsOneWidget,
    );
    expect(find.text('GGUF files (3)'), findsOneWidget);
    expect(find.textContaining('1 other GGUF file is hidden'), findsOneWidget);
    expect(find.text('Q4_K_M'), findsOneWidget);
    expect(find.text('Too big for your phone'), findsOneWidget);
    expect(find.textContaining('Search uses the internet'), findsOneWidget);
  });

  testWidgets('downloads a file after asking', (tester) async {
    final downloader = await _pump(tester, _FakeHub(_serve(_repo())));

    await _tap(tester, find.text('Download').first);
    expect(find.text('Download model?'), findsOneWidget);
    expect(find.textContaining('Tiny-Q4_K_M.gguf'), findsWidgets);
    await _tap(tester, find.widgetWithText(FilledButton, 'Download'));
    expect(downloader.started, ['Tiny-Q4_K_M.gguf']);

    downloader.streams['Tiny-Q4_K_M.gguf']!.add(
      const DownloadProgress(received: 50, total: 100, done: false),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('50%'), findsOneWidget);

    await _tap(tester, find.text('Pause'));
    expect(downloader.tokens['Tiny-Q4_K_M.gguf']!.isCancelled, isTrue);
  });

  testWidgets('a file too big for the phone needs a second look', (
    tester,
  ) async {
    final downloader = await _pump(tester, _FakeHub(_serve(_repo())));

    await _tap(tester, find.text('Download').last);
    expect(find.text('Too big for this phone?'), findsOneWidget);
    expect(find.textContaining('will probably not load'), findsOneWidget);
    await _tap(tester, find.text('Cancel'));
    expect(downloader.started, isEmpty);
  });

  testWidgets('a tight fit is mentioned before downloading', (tester) async {
    await _pump(tester, _FakeHub(_serve(_repo())));
    await _tap(tester, find.text('Download').at(1));
    expect(find.textContaining('A tight fit'), findsWidgets);
  });

  testWidgets('installed and paused files show their state', (tester) async {
    final downloader = await _pump(
      tester,
      _FakeHub(_serve(_repo())),
      installed: [
        LocalModel(
          id: 'tiny-q4_k_m',
          displayName: 'Tiny-Q4_K_M.gguf',
          path: '/nowhere/Tiny-Q4_K_M.gguf',
          sizeBytes: 1,
          modifiedAt: DateTime(2026),
        ),
      ],
      partials: [
        const PartialDownload(
          filename: 'Tiny-Q8_0.gguf',
          path: '/nowhere/Tiny-Q8_0.gguf.part',
          bytes: 800 * 1024 * 1024,
          meta: PartialMeta(url: 'u', total: 1600 * 1024 * 1024),
        ),
      ],
    );

    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('Paused · 50%'), findsOneWidget);
    await _tap(tester, find.text('Resume 50%'));
    expect(downloader.started, ['Tiny-Q8_0.gguf']);
  });

  testWidgets('a gated repo explains why nothing can be installed', (
    tester,
  ) async {
    await _pump(tester, _FakeHub(_serve(_repo(gated: true))));
    expect(find.text('Sign-in required'), findsOneWidget);
    expect(find.text('Download'), findsNothing);
  });

  testWidgets('a repo with only split files says so', (tester) async {
    await _pump(
      tester,
      _FakeHub(
        _serve(
          _repo(
            siblings: [
              {'rfilename': 'Big-00001-of-00002.gguf', 'size': 5},
            ],
          ),
        ),
      ),
    );
    expect(find.text('Nothing to install here'), findsOneWidget);
  });

  testWidgets('a failed load offers to try again', (tester) async {
    var fail = true;
    final hub = _FakeHub((o) {
      if (fail) {
        throw DioException.connectionError(requestOptions: o, reason: 'x');
      }
      return _serve(_repo())(o);
    });
    await _pump(tester, hub);

    expect(find.text('Could not open this model'), findsOneWidget);
    fail = false;
    await _tap(tester, find.text('Try again'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('GGUF files (3)'), findsOneWidget);
  });
}
