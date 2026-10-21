import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/models_repo/catalog.dart';
import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/downloader.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/models_repo/recommender.dart';
import 'package:local_llm/models_repo/use_cases.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/models_page.dart';

import 'helpers/fonts.dart';

const _gib = 1024 * 1024 * 1024;

/// Hands out handles whose progress the test drives, so nothing touches the
/// network or the foreground service.
class _FakeDownloader extends ModelDownloader {
  final started = <String>[];
  final streams = <String, StreamController<DownloadProgress>>{};
  final tokens = <String, CancelToken>{};

  @override
  Future<DownloadHandle> start(
    String url, {
    String? filename,
    String? displayName,
  }) async {
    final name = filename ?? url.split('/').last;
    started.add(name);
    final controller = StreamController<DownloadProgress>.broadcast();
    final token = CancelToken();
    streams[name] = controller;
    tokens[name] = token;
    return DownloadHandle(
      url: url,
      destPath: '/nowhere/$name',
      cancelToken: token,
      progress: controller.stream,
      label: displayName ?? name,
    );
  }
}

/// A catalog chat model whose download size is shown by no other card, so
/// its button can be found by that label. Never the featured model, whose
/// hero card has a button of its own.
CatalogModel _uniqueSizedModel() {
  final chat = chatCatalog;
  final sizes = <String, int>{};
  for (final m in modelCatalog) {
    sizes[m.approxSize] = (sizes[m.approxSize] ?? 0) + 1;
  }
  return chat.firstWhere(
    (m) =>
        sizes[m.approxSize] == 1 &&
        !m.supportsVision &&
        m.id != featuredModelId,
  );
}

LocalModel _installed(CatalogModel m) => LocalModel(
  id: m.servedId,
  displayName: m.filename,
  path: '/nowhere/${m.filename}',
  sizeBytes: m.approxBytes,
  modifiedAt: DateTime(2026),
);

PartialDownload _partial(CatalogModel m, {double done = 0.25}) =>
    PartialDownload(
      filename: m.filename,
      path: '/nowhere/${m.filename}.part',
      bytes: (m.approxBytes * done).round(),
      meta: PartialMeta(url: m.url, label: m.displayName, total: m.approxBytes),
    );

late Directory _support;

Future<(ProviderContainer, _FakeDownloader)> _pump(
  WidgetTester tester, {
  List<LocalModel> installed = const [],
  List<PartialDownload> partials = const [],
  DeviceProfile device = const DeviceProfile(
    totalRamBytes: 8 * _gib,
    availableRamBytes: 5 * _gib,
    cores: 8,
  ),
  Size size = const Size(420, 1800),
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final downloader = _FakeDownloader();
  final container = ProviderContainer(
    overrides: [
      modelListProvider.overrideWith((ref) async => installed),
      partialDownloadsProvider.overrideWith((ref) async => partials),
      missingProjectorsProvider.overrideWith((ref) async => <String>{}),
      deviceProfileProvider.overrideWith((ref) async => device),
      modelDownloaderProvider.overrideWithValue(downloader),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Roboto'),
        home: const ModelsPage(),
      ),
    ),
  );
  await _settle(tester);
  return (container, downloader);
}

/// The page has no endless animations, but futures resolve over a few
/// frames and snack bars animate in.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  setUpAll(() async {
    await loadRoboto();
    _support = await Directory.systemTemp.createTemp('thinai_models_page_');
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => _support.path,
        );
  });

  tearDownAll(() async {
    if (await _support.exists()) await _support.delete(recursive: true);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('featured', () {
    testWidgets('LFM2.5 350M is the hero and is listed only once', (
      tester,
    ) async {
      await _pump(tester, size: const Size(420, 12000));
      final featured = featuredModel!;

      expect(featured.id, 'lfm2.5-350m-q8_0');
      // Hero card above Explore Models, and nowhere below it.
      expect(find.text(featured.displayName), findsOneWidget);
      final hero = tester.getTopLeft(find.text(featured.displayName));
      final explore = tester.getTopLeft(find.text('More models'));
      expect(hero.dy, lessThan(explore.dy));
    });

    testWidgets('the smallest model moves into Explore Models', (tester) async {
      await _pump(tester, size: const Size(420, 12000));
      final smallest = starterModel!;

      final card = tester.getTopLeft(find.text(smallest.displayName));
      final explore = tester.getTopLeft(find.text('More models'));
      expect(card.dy, greaterThan(explore.dy));
    });

    testWidgets('the Featured header has no dead arrow', (tester) async {
      await _pump(tester);
      expect(find.text('Featured'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('searching hides the hero', (tester) async {
      await _pump(tester);
      await tester.enterText(find.byType(TextField), 'qwen');
      await _settle(tester);
      expect(find.text('Featured'), findsNothing);
    });
  });

  group('catalog', () {
    testWidgets(
      'shows the featured model, the catalog and the way to the Hub',
      (tester) async {
        await _pump(tester, size: const Size(420, 12000));

        expect(find.text('Featured'), findsOneWidget);
        expect(find.text('More models'), findsOneWidget);
        expect(find.text('Embedding models'), findsOneWidget);
        expect(find.text('Find more on Hugging Face'), findsOneWidget);
        expect(
          find.text('Models run fully offline on this phone.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('an installed model is marked rather than offered again', (
      tester,
    ) async {
      final m = _uniqueSizedModel();
      await _pump(tester, installed: [_installed(m)]);

      await tester.enterText(find.byType(TextField), m.displayName);
      await _settle(tester);
      expect(find.text('Installed'), findsWidgets);
      expect(find.text(m.approxSize), findsNothing);
    });

    testWidgets('a phone without the memory is told so on every big model', (
      tester,
    ) async {
      await _pump(
        tester,
        device: const DeviceProfile(
          totalRamBytes: 2 * _gib,
          availableRamBytes: _gib,
          cores: 4,
        ),
        size: const Size(420, 12000),
      );
      expect(find.text('Needs RAM'), findsWidgets);
      // The cards stay short; the full sentence waits for the download.
      expect(find.textContaining('this phone has'), findsNothing);
    });

    testWidgets(
      'a tight fit is a chip on the card and a sentence on download',
      (tester) async {
        const device = DeviceProfile(
          totalRamBytes: 6 * _gib,
          availableRamBytes: 3 * _gib,
          cores: 8,
        );
        final sizes = <String, int>{};
        for (final m in modelCatalog) {
          sizes[m.approxSize] = (sizes[m.approxSize] ?? 0) + 1;
        }
        final m = chatCatalog.firstWhere(
          (m) =>
              fitFor(m, device) == RamFit.tight &&
              sizes[m.approxSize] == 1 &&
              m.id != featuredModelId,
        );
        await _pump(tester, device: device);
        await tester.enterText(find.byType(TextField), m.displayName);
        await _settle(tester);

        expect(find.text('Tight fit'), findsOneWidget);
        expect(find.textContaining('Other apps may close'), findsNothing);

        await _tapText(tester, m.approxSize);
        expect(find.text('Download?'), findsOneWidget);
        expect(find.textContaining('Other apps may close'), findsOneWidget);
      },
    );

    testWidgets('a model too big for the phone says why before downloading', (
      tester,
    ) async {
      const device = DeviceProfile(
        totalRamBytes: 2 * _gib,
        availableRamBytes: _gib,
        cores: 4,
      );
      final m = chatCatalog.firstWhere(
        (m) => fitFor(m, device) == RamFit.tooBig && !m.supportsVision,
      );
      await _pump(tester, device: device);
      await tester.enterText(find.byType(TextField), m.displayName);
      await _settle(tester);

      await tester.tap(find.byTooltip('Model details').first);
      await _settle(tester);
      await _tapText(tester, 'Download ${m.approxSize}');
      expect(find.text('Download?'), findsOneWidget);
      expect(find.textContaining('this phone has'), findsOneWidget);
    });

    testWidgets('the details sheet describes a model', (tester) async {
      final m = _uniqueSizedModel();
      await _pump(tester);
      await tester.enterText(find.byType(TextField), m.displayName);
      await _settle(tester);

      await tester.tap(find.byTooltip('Model details').first);
      await _settle(tester);
      expect(find.text(m.description), findsWidgets);
    });
  });

  group('search', () {
    testWidgets('narrows the catalog and offers a Hub search for the query', (
      tester,
    ) async {
      final m = _uniqueSizedModel();
      await _pump(tester);

      await tester.enterText(find.byType(TextField), m.displayName);
      await _settle(tester);
      expect(find.text('Search Hugging Face for "${m.displayName}"'), findsOne);
      expect(find.text('Featured'), findsNothing);
    });

    testWidgets('no match points to Hugging Face and can reset', (
      tester,
    ) async {
      await _pump(tester);

      await tester.enterText(find.byType(TextField), 'zzqx-no-such-model');
      await _settle(tester);
      expect(find.text('No models match "zzqx-no-such-model"'), findsOneWidget);
      expect(find.text('Search Hugging Face'), findsOneWidget);

      await _tapText(tester, 'Reset filters');
      expect(find.text('Featured'), findsOneWidget);
    });

    testWidgets('the Hub prompt opens the Hugging Face search', (tester) async {
      await _pump(tester);
      await tester.enterText(find.byType(TextField), 'zzqx');
      await _settle(tester);

      await _tapText(tester, 'Search Hugging Face');
      expect(find.text('Hugging Face'), findsOneWidget);
      expect(find.textContaining('Search uses the internet'), findsOneWidget);
    });
  });

  group('filters', () {
    Future<void> pick(WidgetTester tester, String label) async {
      await tester.tap(find.byTooltip('Filter Category'));
      await _settle(tester);
      await tester.tap(find.text(label).last);
      await _settle(tester);
    }

    testWidgets('each category shows its own section', (tester) async {
      await _pump(tester, size: const Size(420, 12000));

      await pick(tester, 'Vision');
      expect(find.text('Vision models'), findsOneWidget);

      await pick(tester, 'Chat');
      expect(find.text('Chat models'), findsOneWidget);

      await pick(tester, 'Embedding');
      expect(find.text('Embedding models'), findsOneWidget);
      expect(find.text('Chat models'), findsNothing);
    });

    testWidgets('Installed with nothing installed points back to the catalog', (
      tester,
    ) async {
      await _pump(tester);
      await pick(tester, 'Installed');

      expect(find.text('No models installed yet'), findsOneWidget);
      await _tapText(tester, 'Browse Catalog');
      expect(find.text('Featured'), findsOneWidget);
    });

    testWidgets('Installed lists models and loads one when tapped', (
      tester,
    ) async {
      final m = _uniqueSizedModel();
      final (container, _) = await _pump(tester, installed: [_installed(m)]);
      await pick(tester, 'Installed (1)');

      expect(find.text('Installed (1)'), findsWidgets);
      await _tapText(tester, m.filename);
      expect(container.read(activeModelIdProvider), m.servedId);
      expect(find.text('Loaded ${m.filename}'), findsOneWidget);
    });

    testWidgets('deleting asks first and can be declined', (tester) async {
      final m = _uniqueSizedModel();
      await _pump(tester, installed: [_installed(m)]);
      await pick(tester, 'Installed (1)');

      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await _settle(tester);
      expect(find.text('Delete model?'), findsOneWidget);
      await _tapText(tester, 'Cancel');
      expect(find.text('Delete model?'), findsNothing);
    });
  });

  group('goals', () {
    testWidgets('picking a goal recommends models for it', (tester) async {
      await _pump(tester, size: const Size(420, 4000));

      await _tapText(tester, 'Goal');
      expect(find.text('Choose a goal'), findsOneWidget);
      await _tapText(tester, UseCase.coding.label);

      expect(find.text('Goal: ${UseCase.coding.label}'), findsOneWidget);
      expect(find.text('Top picks'), findsOneWidget);
      expect(find.text('Other models'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await _settle(tester);
      expect(find.text('Featured'), findsOneWidget);
    });
  });

  group('downloads', () {
    testWidgets('download asks first, then shows progress and a Pause button', (
      tester,
    ) async {
      final m = _uniqueSizedModel();
      final (container, downloader) = await _pump(tester);
      await tester.enterText(find.byType(TextField), m.displayName);
      await _settle(tester);

      await _tapText(tester, m.approxSize);
      expect(find.text('Download?'), findsOneWidget);
      await _tapText(tester, 'Download');
      expect(downloader.started, [m.filename]);

      downloader.streams[m.filename]!.add(
        DownloadProgress(
          received: m.approxBytes ~/ 2,
          total: m.approxBytes,
          done: false,
        ),
      );
      await _settle(tester);
      expect(find.text('50%'), findsOneWidget);

      await _tapText(tester, 'Pause');
      expect(downloader.tokens[m.filename]!.isCancelled, isTrue);
      expect(container.read(downloadsProvider), isEmpty);
      expect(find.text('Download paused'), findsOne);
    });

    testWidgets('declining the question starts nothing', (tester) async {
      final m = _uniqueSizedModel();
      final (_, downloader) = await _pump(tester);
      await tester.enterText(find.byType(TextField), m.displayName);
      await _settle(tester);

      await _tapText(tester, m.approxSize);
      await _tapText(tester, 'Cancel');
      expect(downloader.started, isEmpty);
    });

    testWidgets('a dropped connection says progress is saved', (tester) async {
      final m = _uniqueSizedModel();
      final (_, downloader) = await _pump(tester);
      await tester.enterText(find.byType(TextField), m.displayName);
      await _settle(tester);
      await _tapText(tester, m.approxSize);
      await _tapText(tester, 'Download');

      downloader.streams[m.filename]!.add(
        DownloadProgress(
          received: 1000,
          total: m.approxBytes,
          done: true,
          error: 'No internet connection',
        ),
      );
      await _settle(tester);
      expect(
        find.text(
          '${m.displayName} stopped: No internet connection. '
          'Tap Resume to continue.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a finished download is reported', (tester) async {
      final m = _uniqueSizedModel();
      final (container, downloader) = await _pump(tester);
      await tester.enterText(find.byType(TextField), m.displayName);
      await _settle(tester);
      await _tapText(tester, m.approxSize);
      await _tapText(tester, 'Download');

      downloader.streams[m.filename]!.add(
        DownloadProgress(
          received: m.approxBytes,
          total: m.approxBytes,
          done: true,
        ),
      );
      // Finding the finished file touches the disk, so let real time pass.
      final toast = find.textContaining('Downloaded');
      for (var i = 0; i < 50 && toast.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(container.read(downloadsProvider), isEmpty);
      expect(find.textContaining('Downloaded'), findsOneWidget);
    });

    testWidgets('a paused download offers Resume with its progress', (
      tester,
    ) async {
      final m = _uniqueSizedModel();
      final (_, downloader) = await _pump(tester, partials: [_partial(m)]);
      await tester.enterText(find.byType(TextField), m.displayName);
      await _settle(tester);

      expect(find.text('Paused · 25%'), findsOneWidget);
      // Resuming does not ask again: the user agreed when it started.
      await _tapText(tester, 'Resume 25%');
      expect(find.text('Download?'), findsNothing);
      expect(downloader.started, [m.filename]);
    });
  });

  group('Model Manager', () {
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.layers_rounded));
      await _settle(tester);
    }

    testWidgets('empty, it points back to the catalog', (tester) async {
      await _pump(tester);
      await open(tester);

      expect(find.text('No models installed'), findsOneWidget);
      await _tapText(tester, 'Browse Catalog');
      expect(find.text('Model Manager'), findsNothing);
    });

    testWidgets('lists installed models and activates one', (tester) async {
      final m = _uniqueSizedModel();
      final (container, _) = await _pump(tester, installed: [_installed(m)]);
      await open(tester);

      expect(find.text('Model Manager'), findsOneWidget);
      expect(find.text('No model loaded'), findsOneWidget);
      await _tapText(tester, 'Load');
      expect(container.read(activeModelIdProvider), m.servedId);
    });

    testWidgets('lists paused downloads with Resume and Discard', (
      tester,
    ) async {
      final m = _uniqueSizedModel();
      final (_, downloader) = await _pump(tester, partials: [_partial(m)]);
      await open(tester);

      expect(find.text('Paused download'), findsOneWidget);
      // Once on its card behind the sheet, once in the sheet.
      expect(find.text(m.displayName), findsWidgets);

      await tester.tap(find.byTooltip('Discard download'));
      await _settle(tester);
      expect(find.text('Discard download?'), findsOneWidget);
      await _tapText(tester, 'Cancel');

      await tester.tap(find.byTooltip('Resume download'));
      await _settle(tester);
      expect(downloader.started, [m.filename]);
    });

    testWidgets('shows a download in flight and pauses it', (tester) async {
      final m = _uniqueSizedModel();
      final (container, downloader) = await _pump(tester);
      await container.read(downloadsProvider.notifier).start(m);
      await _settle(tester);
      await open(tester);

      expect(find.text('Downloading model'), findsOneWidget);
      await tester.tap(find.byTooltip('Pause download'));
      await _settle(tester);
      expect(downloader.tokens[m.filename]!.isCancelled, isTrue);
    });
  });
}
