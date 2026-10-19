import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/downloader.dart';
import 'package:local_llm/models_repo/model_store.dart';

/// A file server in memory that honours `Range` and `If-Range` the way the
/// Hugging Face CDN does, with switches for the ways real servers do not.
class _RangeServer implements HttpClientAdapter {
  _RangeServer(this.content);

  Uint8List content;
  String etag = '"v1"';

  /// Answer every request with the whole file, as a server without range
  /// support does.
  bool ignoreRange = false;

  /// Stop after this many bytes of the body, as a dropped connection does.
  int? dropAfter;

  /// Never finish the body, as a stalled connection does.
  bool stall = false;

  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final range = options.headers['range'] as String?;
    final ifRange = options.headers['if-range'] as String?;
    final total = content.length;

    var start = 0;
    var status = 200;
    if (range != null && !ignoreRange && (ifRange == null || ifRange == etag)) {
      start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
      if (start >= total) {
        return ResponseBody(
          const Stream.empty(),
          416,
          headers: {
            'content-range': ['bytes */$total'],
          },
        );
      }
      status = 206;
    }

    var body = content.sublist(start);
    final dropped = dropAfter != null && dropAfter! < body.length;
    if (dropped) body = body.sublist(0, dropAfter!);

    final controller = StreamController<Uint8List>();
    () async {
      for (var i = 0; i < body.length; i += 4) {
        final end = i + 4 > body.length ? body.length : i + 4;
        controller.add(Uint8List.fromList(body.sublist(i, end)));
        await Future<void>.delayed(Duration.zero);
      }
      if (!stall) await controller.close();
    }();

    return ResponseBody(
      controller.stream,
      status,
      headers: {
        Headers.contentLengthHeader: ['${total - start}'],
        'etag': [etag],
        if (status == 206)
          'content-range': ['bytes $start-${total - 1}/$total'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Uint8List _bytes(int n, {int seed = 0}) =>
    Uint8List.fromList(List.generate(n, (i) => (i * 7 + seed) % 256));

void main() {
  late Directory dir;
  late String part;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('thinai_resume_');
    part = '${dir.path}/model.gguf.part';
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<int> fetch(
    _RangeServer server, {
    CancelToken? token,
    List<(int, int?)>? progress,
  }) => fetchResumable(
    dio: Dio()..httpClientAdapter = server,
    url: 'https://example.test/model.gguf',
    partPath: part,
    label: 'Test model',
    cancelToken: token ?? CancelToken(),
    onProgress: (r, t) => progress?.add((r, t)),
  );

  group('fetchResumable', () {
    test('downloads a whole file and records where it came from', () async {
      final server = _RangeServer(_bytes(100));
      final size = await fetch(server);

      expect(size, 100);
      expect(await File(part).readAsBytes(), server.content);
      expect(server.requests.single.headers['range'], isNull);

      final meta = await readPartialMeta(part);
      expect(meta?.url, 'https://example.test/model.gguf');
      expect(meta?.total, 100);
      expect(meta?.etag, '"v1"');
      expect(meta?.label, 'Test model');
    });

    test('keeps the part when the connection drops', () async {
      final server = _RangeServer(_bytes(100))..dropAfter = 40;

      await expectLater(fetch(server), throwsA(isA<HttpException>()));
      expect(await File(part).length(), 40);
      expect((await readPartialMeta(part))?.total, 100);
    });

    test('resumes from the saved part with Range and If-Range', () async {
      final server = _RangeServer(_bytes(100))..dropAfter = 40;
      await expectLater(fetch(server), throwsA(anything));

      server.dropAfter = null;
      final progress = <(int, int?)>[];
      final size = await fetch(server, progress: progress);

      expect(size, 100);
      expect(await File(part).readAsBytes(), server.content);
      final resumed = server.requests.last.headers;
      expect(resumed['range'], 'bytes=40-');
      expect(resumed['if-range'], '"v1"');
      // Progress counts the saved part, so the bar picks up at 40%.
      expect(progress.first, (40, 100));
      expect(progress.last, (100, 100));
    });

    test('starts over when the server ignores the range', () async {
      final server = _RangeServer(_bytes(100))..dropAfter = 40;
      await expectLater(fetch(server), throwsA(anything));

      server
        ..dropAfter = null
        ..ignoreRange = true;
      final size = await fetch(server);

      expect(size, 100);
      expect(await File(part).readAsBytes(), server.content);
    });

    test('starts over when the file changed upstream', () async {
      final server = _RangeServer(_bytes(100))..dropAfter = 40;
      await expectLater(fetch(server), throwsA(anything));

      // Re-uploaded under the same URL: a new ETag, so If-Range fails and the
      // server sends the new file whole instead of a mismatched tail.
      server
        ..content = _bytes(120, seed: 3)
        ..etag = '"v2"'
        ..dropAfter = null;
      final size = await fetch(server);

      expect(size, 120);
      expect(await File(part).readAsBytes(), server.content);
      expect((await readPartialMeta(part))?.etag, '"v2"');
    });

    test(
      'finishes a part that is already complete without refetching',
      () async {
        final server = _RangeServer(_bytes(100));
        await fetch(server);

        final size = await fetch(server);
        expect(size, 100);
        expect(server.requests.last.headers['range'], 'bytes=100-');
        expect(await File(part).readAsBytes(), server.content);
      },
    );

    test('restarts when the server rejects a range it cannot serve', () async {
      // A part larger than the file, and no record of the real size.
      await File(part).writeAsBytes(_bytes(150));
      final server = _RangeServer(_bytes(100));

      final size = await fetch(server);
      expect(size, 100);
      expect(await File(part).readAsBytes(), server.content);
    });

    test('ignores a part that came from a different URL', () async {
      await File(part).writeAsBytes(_bytes(40, seed: 9));
      await File(partialMetaPath(part)).writeAsString(
        '{"url":"https://elsewhere.test/other.gguf","total":100}',
      );
      final server = _RangeServer(_bytes(100));

      await fetch(server);
      expect(server.requests.single.headers['range'], isNull);
      expect(await File(part).readAsBytes(), server.content);
    });

    test('pausing a stalled download keeps what arrived', () async {
      final server = _RangeServer(_bytes(100))
        ..dropAfter = 24
        ..stall = true;
      final token = CancelToken();
      final progress = <(int, int?)>[];

      final future = fetch(server, token: token, progress: progress);
      while (progress.isEmpty || progress.last.$1 < 24) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      token.cancel('Paused');

      await expectLater(
        future,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(await File(part).length(), 24);
    });
  });

  group('parseContentRange', () {
    test('reads start and total', () {
      expect(parseContentRange('bytes 40-99/100'), (start: 40, total: 100));
    });

    test('an unknown total is null', () {
      expect(parseContentRange('bytes 0-9/*'), (start: 0, total: null));
    });

    test('rejects what is not a byte range', () {
      expect(parseContentRange(null), isNull);
      expect(parseContentRange('bytes */100'), isNull);
      expect(parseContentRange('items 0-1/2'), isNull);
    });
  });

  group('PartialMeta', () {
    test('round-trips through JSON', () {
      const meta = PartialMeta(
        url: 'https://x.test/a.gguf',
        label: 'A',
        total: 5,
        etag: '"e"',
      );
      final back = PartialMeta.fromJson(meta.toJson());
      expect(back?.url, meta.url);
      expect(back?.label, meta.label);
      expect(back?.total, meta.total);
      expect(back?.etag, meta.etag);
    });

    test('rejects a record with no URL', () {
      expect(PartialMeta.fromJson({'total': 5}), isNull);
      expect(PartialMeta.fromJson('nope'), isNull);
    });
  });

  group('ModelStore partial downloads', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => dir.path,
          );
    });

    test('lists parts with their progress, skipping empty ones', () async {
      final store = ModelStore.instance;
      // The store caches its directory across tests; recreate it here.
      final models = await (await store.modelsDir()).create(recursive: true);
      final a = '${models.path}/alpha.gguf.part';
      await File(a).writeAsBytes(_bytes(25));
      await File(partialMetaPath(a)).writeAsString(
        '{"url":"https://x.test/alpha.gguf","label":"Alpha","total":100}',
      );
      await File('${models.path}/empty.gguf.part').writeAsBytes(const []);
      await File('${models.path}/done.gguf').writeAsBytes(_bytes(10));

      final partials = await store.listPartial();
      final alpha = partials.singleWhere((p) => p.filename == 'alpha.gguf');
      expect(alpha.bytes, 25);
      expect(alpha.total, 100);
      expect(alpha.fraction, 0.25);
      expect(alpha.label, 'Alpha');
      expect(partials.any((p) => p.filename == 'empty.gguf'), isFalse);
      // A part is not a model: the installed list must not offer it.
      expect(
        (await store.list()).any((m) => m.displayName.contains('alpha')),
        isFalse,
      );

      await store.discardPartial(alpha);
      expect(await File(a).exists(), isFalse);
      expect(await File(partialMetaPath(a)).exists(), isFalse);
    });

    test('a part with no record falls back to its file name', () {
      const p = PartialDownload(
        filename: 'beta-q4_k_m.gguf',
        path: '/x/beta-q4_k_m.gguf.part',
        bytes: 10,
      );
      expect(p.label, 'beta-q4_k_m');
      expect(p.fraction, isNull);
    });

    test('clear all downloads removes parts and their records', () async {
      final store = ModelStore.instance;
      // The store caches its directory across tests; recreate it here.
      final models = await (await store.modelsDir()).create(recursive: true);
      final c = '${models.path}/gamma.gguf.part';
      await File(c).writeAsBytes(_bytes(5));
      await File(partialMetaPath(c)).writeAsString('{"url":"u"}');

      await store.clearAllDownloads();
      expect(await File(c).exists(), isFalse);
      expect(await File(partialMetaPath(c)).exists(), isFalse);
    });
  });
}
