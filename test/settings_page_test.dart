import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/llm/generation_settings.dart';
import 'package:local_llm/llm/gpu_support.dart';
import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/downloader.dart';
import 'package:local_llm/models_repo/importer.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/server/api_server.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/about_page.dart';
import 'package:local_llm/ui/pages/contact_support_page.dart';
import 'package:local_llm/ui/pages/settings_page.dart';
import 'package:local_llm/ui/widgets/gpu_settings_card.dart';
import 'package:local_llm/ui/widgets/model_settings_sheet.dart';
import 'package:local_llm/update/app_updater.dart';

const _gib = 1024 * 1024 * 1024;

final _qwen = LocalModel(
  id: 'qwen-test',
  displayName: 'Qwen Test',
  path: '/nowhere/qwen-test.gguf',
  sizeBytes: 1000,
  modifiedAt: DateTime(2026),
);

/// Reports a server already running without binding a socket.
class _RunningServer extends ServerController {
  _RunningServer() : super(ApiServer()) {
    state = const ServerStatus(running: true, port: 11434);
  }
}

/// Answers the model store calls the settings pages make, without touching
/// the filesystem.
class _FakeStore implements ModelStore {
  _FakeStore({this.cleared = 0, this.clearError});

  final int cleared;
  final Object? clearError;
  int clearCalls = 0;

  @override
  Future<int> clearAllDownloads() async {
    clearCalls++;
    if (clearError != null) throw clearError!;
    return cleared;
  }

  @override
  Future<List<LocalModel>> list() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImporter extends ModelImporter {
  const _FakeImporter({this.result, this.error});

  final LocalModel? result;
  final Object? error;

  @override
  Future<LocalModel?> pickAndImport() async {
    if (error != null) throw error!;
    return result;
  }
}

class _FakeDownloader extends ModelDownloader {
  _FakeDownloader({this.error});

  final Object? error;
  final progress = StreamController<DownloadProgress>.broadcast();
  final calls = <(String, String?, String?)>[];

  @override
  Future<DownloadHandle> start(
    String url, {
    String? filename,
    String? displayName,
  }) async {
    calls.add((url, filename, displayName));
    if (error != null) throw error!;
    return DownloadHandle(
      url: url,
      destPath: '/nowhere/${filename ?? 'model.gguf'}',
      cancelToken: CancelToken(),
      progress: progress.stream,
      label: displayName ?? url,
    );
  }
}

class _FakeUpdater extends AppUpdater {
  _FakeUpdater(this.state, {this.downloadResult = AppUpdateResult.success});

  final UpdateState state;
  final AppUpdateResult downloadResult;
  int downloads = 0;
  int installs = 0;

  @override
  Future<UpdateStatus> check() async => UpdateStatus(state);

  @override
  Future<AppUpdateResult> download() async {
    downloads++;
    return downloadResult;
  }

  @override
  Future<void> install() async => installs++;
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget page, {
  List<Override> overrides = const [],
  DeviceProfile device = const DeviceProfile(cores: 8, totalRamBytes: 8 * _gib),
}) async {
  final container = ProviderContainer(
    overrides: [
      deviceProfileProvider.overrideWith((ref) async => device),
      appVersionProvider.overrideWith((ref) async => '2.4.0 (13)'),
      modelListProvider.overrideWith((ref) async => const []),
      modelStoreProvider.overrideWithValue(_FakeStore()),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: page),
    ),
  );
  // Let the preference-backed controllers and future providers settle.
  await tester.pump();
  await tester.pump();
  return container;
}

/// Opens the dropdown currently showing [current] and picks [choice].
Future<void> _choose(WidgetTester tester, String current, String choice) async {
  await tester.tap(find.text(current).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(choice).last);
  await tester.pumpAndSettle();
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GenerationSettingsStore.instance.setGpu(GpuBackend.none);
  });

  group('settings hub', () {
    testWidgets('lists every settings section', (tester) async {
      await _pump(tester, const SettingsPage());

      for (final title in [
        'Appearance',
        'System Prompt',
        'Hardware',
        'Model & Storage',
        'Local Server',
        'About & Help',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Erode, Tamilnadu'), findsOneWidget);
    });

    for (final (tile, page) in [
      ('Appearance', AppearanceSettingsPage),
      ('Hardware', HardwareSettingsPage),
      ('Model & Storage', ModelStorageSettingsPage),
      ('Local Server', LocalServerSettingsPage),
      ('About & Help', AboutGuidanceSettingsPage),
    ]) {
      testWidgets('tapping $tile opens its page', (tester) async {
        await _pump(tester, const SettingsPage());
        await tester.tap(find.text(tile));
        await tester.pumpAndSettle();
        expect(find.byType(page), findsOneWidget);
      });
    }

    testWidgets('tapping System Prompt opens the prompt editor', (
      tester,
    ) async {
      await _pump(tester, const SettingsPage());
      await tester.tap(find.text('System Prompt'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage, skipOffstage: false), findsOneWidget);
      expect(
        find.widgetWithText(AppBar, 'System Prompt'),
        findsOneWidget,
        reason: 'the editor page is on top',
      );
    });
  });

  group('appearance', () {
    testWidgets('shows the saved choices', (tester) async {
      SharedPreferences.setMockInitialValues({
        'default_start_page': 2,
        'theme_mode': 'dark',
        'web_search_enabled': false,
      });
      await _pump(tester, const AppearanceSettingsPage());

      expect(find.text('Server'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('picking a start page saves it', (tester) async {
      final container = await _pump(tester, const AppearanceSettingsPage());

      await _choose(tester, 'Chat', 'Models');

      expect(container.read(startPageProvider), 1);
      expect((await _prefs()).getInt('default_start_page'), 1);
    });

    testWidgets('picking a theme saves it', (tester) async {
      final container = await _pump(tester, const AppearanceSettingsPage());

      // The language dropdown also reads "System", so open the theme one by
      // type.
      await tester.tap(find.byType(DropdownButton<ThemeMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light').last);
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect((await _prefs()).getString('theme_mode'), 'light');
    });

    testWidgets('turning web search off saves it', (tester) async {
      final container = await _pump(tester, const AppearanceSettingsPage());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(container.read(webSearchEnabledProvider), isFalse);
      expect((await _prefs()).getBool('web_search_enabled'), isFalse);
    });
  });

  group('hardware', () {
    testWidgets('shows the GPU choice and the device specs', (tester) async {
      await _pump(tester, const HardwareSettingsPage());

      expect(find.text('CPU'), findsOneWidget);
      expect(find.text('8 cores · 8.0 GB RAM'), findsOneWidget);
    });

    testWidgets('falls back to the core count when RAM is unknown', (
      tester,
    ) async {
      await _pump(
        tester,
        const HardwareSettingsPage(),
        device: const DeviceProfile(cores: 4),
      );
      expect(find.text('4 CPU cores'), findsOneWidget);
    });

    testWidgets('picking a GPU backend saves it', (tester) async {
      await _pump(tester, const HardwareSettingsPage());

      await _choose(tester, 'CPU', 'Vulkan');
      // The settings store was first loaded outside the test's fake clock, so
      // its follow-up work runs on the real event loop.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      await tester.pump();

      expect(GenerationSettingsStore.instance.settings.gpu, GpuBackend.vulkan);
      expect(find.text('Vulkan'), findsOneWidget);
      expect(
        (await _prefs()).getString('generation_settings_v1'),
        contains('vulkan'),
      );
      // Put it back so the GPU card is not asked to probe in later tests.
      await tester.runAsync(
        () => GenerationSettingsStore.instance.setGpu(GpuBackend.none),
      );
      await tester.pump();
    });

    testWidgets('GPU speed test opens the GPU card in a sheet', (tester) async {
      await _pump(tester, const HardwareSettingsPage());

      await tester.tap(find.text('GPU speed test'));
      await tester.pumpAndSettle();

      final card = tester.widget<GpuSettingsCard>(find.byType(GpuSettingsCard));
      expect(card.embedded, isTrue);
      expect(find.text('Find GPU'), findsOneWidget);
    });

    testWidgets('Benchmark opens the benchmark page', (tester) async {
      await _pump(tester, const HardwareSettingsPage());

      await tester.tap(find.text('Benchmark'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HardwareSettingsPage), findsNothing);
    });
  });

  group('model and storage', () {
    testWidgets('without a loaded model it points at the catalog', (
      tester,
    ) async {
      final container = await _pump(tester, const SettingsPage());
      await tester.tap(find.text('Model & Storage'));
      await tester.pumpAndSettle();

      expect(find.text('No model loaded'), findsOneWidget);
      await tester.tap(find.text('No model loaded'));
      await tester.pumpAndSettle();

      expect(container.read(shellTabIndexProvider), 1);
      expect(
        find.byType(ModelStorageSettingsPage),
        findsNothing,
        reason: 'the page pops back to the shell',
      );
    });

    testWidgets('with a loaded model it offers to tune it', (tester) async {
      final container = await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [
          modelListProvider.overrideWith((ref) async => [_qwen]),
        ],
      );
      await container.read(activeModelIdProvider.notifier).set(_qwen);
      await tester.pump();
      await tester.pump();

      expect(find.text('Qwen Test'), findsOneWidget);
      expect(find.text('Tune'), findsOneWidget);

      await tester.tap(find.text('Qwen Test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ModelSettingsSheet), findsOneWidget);
    });

    testWidgets('importing a model reports it and refreshes the list', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [
          modelImporterProvider.overrideWithValue(_FakeImporter(result: _qwen)),
        ],
      );
      final before = container.read(modelsRefreshProvider);

      await tester.tap(find.text('Import .gguf'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Imported Qwen Test'), findsOneWidget);
      expect(container.read(modelsRefreshProvider), before + 1);
    });

    testWidgets('a cancelled import says nothing', (tester) async {
      await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [
          modelImporterProvider.overrideWithValue(const _FakeImporter()),
        ],
      );

      await tester.tap(find.text('Import .gguf'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a failed import is reported', (tester) async {
      await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [
          modelImporterProvider.overrideWithValue(
            const _FakeImporter(error: 'not a gguf'),
          ),
        ],
      );

      await tester.tap(find.text('Import .gguf'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Import failed: not a gguf'), findsOneWidget);
    });

    testWidgets('download by URL needs a URL before it starts', (tester) async {
      final downloader = _FakeDownloader();
      await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [modelDownloaderProvider.overrideWithValue(downloader)],
      );

      await tester.tap(find.text('Download from URL'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();
      expect(
        find.byType(AlertDialog),
        findsOneWidget,
        reason: 'an empty URL keeps the dialog open',
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(downloader.calls, isEmpty);
    });

    testWidgets('download by URL starts and reports completion', (
      tester,
    ) async {
      final downloader = _FakeDownloader();
      final container = await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [modelDownloaderProvider.overrideWithValue(downloader)],
      );

      await tester.tap(find.text('Download from URL'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'GGUF URL'),
        ' https://example.test/m.gguf ',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Name (optional)'),
        'mine.gguf',
      );
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      expect(downloader.calls.single, (
        'https://example.test/m.gguf',
        'mine.gguf',
        'mine.gguf',
      ));
      expect(find.text('Download started'), findsOneWidget);

      final before = container.read(modelsRefreshProvider);
      downloader.progress.add(
        const DownloadProgress(received: 10, total: 10, done: true),
      );
      await tester.pump();
      await tester.pump();
      expect(container.read(modelsRefreshProvider), before + 1);
      // Snackbars queue, so let the first one time out.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Download complete'), findsOneWidget);
    });

    testWidgets('an unnamed download lets the downloader pick the name', (
      tester,
    ) async {
      final downloader = _FakeDownloader();
      await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [modelDownloaderProvider.overrideWithValue(downloader)],
      );

      await tester.tap(find.text('Download from URL'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'GGUF URL'),
        'https://example.test/m.gguf',
      );
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      expect(downloader.calls.single, (
        'https://example.test/m.gguf',
        null,
        null,
      ));
    });

    testWidgets('a download that stops part way says progress is kept', (
      tester,
    ) async {
      final downloader = _FakeDownloader();
      await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [modelDownloaderProvider.overrideWithValue(downloader)],
      );

      await tester.tap(find.text('Download from URL'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'GGUF URL'),
        'https://example.test/m.gguf',
      );
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      downloader.progress.add(
        const DownloadProgress(
          received: 5,
          total: 10,
          done: true,
          error: 'connection lost',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(
        find.text('Download stopped: connection lost. Resume it from Models.'),
        findsOneWidget,
      );
    });

    testWidgets('a download that fails at once says it failed', (tester) async {
      final downloader = _FakeDownloader();
      await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [modelDownloaderProvider.overrideWithValue(downloader)],
      );

      await tester.tap(find.text('Download from URL'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'GGUF URL'),
        'https://example.test/m.gguf',
      );
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      downloader.progress.add(
        const DownloadProgress(
          received: 0,
          total: null,
          done: true,
          error: '404',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('Download failed: 404'), findsOneWidget);
    });

    testWidgets('a download that cannot start is reported', (tester) async {
      await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [
          modelDownloaderProvider.overrideWithValue(
            _FakeDownloader(error: 'bad url'),
          ),
        ],
      );

      await tester.tap(find.text('Download from URL'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'GGUF URL'),
        'https://example.test/m.txt',
      );
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      expect(find.text('Download failed: bad url'), findsOneWidget);
    });

    testWidgets('clearing downloads asks first and can be cancelled', (
      tester,
    ) async {
      final store = _FakeStore(cleared: 2);
      await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [modelStoreProvider.overrideWithValue(store)],
      );

      await tester.tap(find.text('Clear downloads'));
      await tester.pumpAndSettle();
      expect(find.text('Delete all downloads?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.clearCalls, 0);
    });

    testWidgets('clearing downloads removes them and unloads the model', (
      tester,
    ) async {
      final store = _FakeStore(cleared: 2);
      final container = await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [modelStoreProvider.overrideWithValue(store)],
      );
      await container.read(activeModelIdProvider.notifier).set(_qwen);
      await tester.pump();

      await tester.tap(find.text('Clear downloads'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(store.clearCalls, 1);
      expect(container.read(activeModelIdProvider), isNull);
      expect((await _prefs()).getString('active_model_id'), isNull);
      expect(find.text('Cleared 2 downloads'), findsOneWidget);
    });

    for (final (cleared, message) in [
      (1, 'Cleared 1 download'),
      (0, 'Nothing to clear'),
    ]) {
      testWidgets('clearing $cleared downloads says "$message"', (
        tester,
      ) async {
        await _pump(
          tester,
          const ModelStorageSettingsPage(),
          overrides: [
            modelStoreProvider.overrideWithValue(_FakeStore(cleared: cleared)),
          ],
        );

        await tester.tap(find.text('Clear downloads'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text(message), findsOneWidget);
      });
    }

    testWidgets('a failed clear is reported', (tester) async {
      await _pump(
        tester,
        const ModelStorageSettingsPage(),
        overrides: [
          modelStoreProvider.overrideWithValue(
            _FakeStore(clearError: 'disk busy'),
          ),
        ],
      );

      await tester.tap(find.text('Clear downloads'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Clear failed: disk busy'), findsOneWidget);
    });
  });

  group('local server', () {
    testWidgets('shows the saved port and that the server is off', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'server_port': 9000});
      await _pump(tester, const LocalServerSettingsPage());

      expect(find.text(':9000'), findsOneWidget);
      expect(find.text('Stopped'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('shows a running server as active', (tester) async {
      await _pump(
        tester,
        const LocalServerSettingsPage(),
        overrides: [
          serverControllerProvider.overrideWith((ref) => _RunningServer()),
        ],
      );
      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('turning on Wi-Fi sharing saves it', (tester) async {
      final container = await _pump(tester, const LocalServerSettingsPage());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(container.read(lanShareProvider), isTrue);
      expect((await _prefs()).getBool('server_lan_share'), isTrue);
    });

    testWidgets('the port dialog rejects an out of range port', (tester) async {
      await _pump(tester, const LocalServerSettingsPage());

      await tester.tap(find.text('Port'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '70000');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Server port'), findsOneWidget);
      expect((await _prefs()).getInt('server_port'), isNull);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Server port'), findsNothing);
    });

    testWidgets('saving a port while stopped needs no restart', (tester) async {
      await _pump(tester, const LocalServerSettingsPage());

      await tester.tap(find.text('Port'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '8080');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect((await _prefs()).getInt('server_port'), 8080);
      expect(find.text('Port set to 8080'), findsOneWidget);
      expect(find.text(':8080'), findsOneWidget);
    });

    testWidgets('server status jumps to the Server tab', (tester) async {
      final container = await _pump(tester, const SettingsPage());
      await tester.tap(find.text('Local Server'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Status'));
      await tester.pumpAndSettle();

      expect(container.read(shellTabIndexProvider), 2);
      expect(find.byType(LocalServerSettingsPage), findsNothing);
    });
  });

  group('about and guidance', () {
    testWidgets('shows the running version', (tester) async {
      await _pump(tester, const AboutGuidanceSettingsPage());
      expect(find.text('v2.4.0 (13)'), findsOneWidget);
    });

    testWidgets('start app tour asks the shell for the tour', (tester) async {
      final container = await _pump(tester, const SettingsPage());
      await tester.tap(find.text('About & Help'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('App tour'));
      await tester.pumpAndSettle();

      expect(container.read(coachTourRequestProvider), 1);
      expect(find.byType(AboutGuidanceSettingsPage), findsNothing);
    });

    testWidgets('contact support opens the support page', (tester) async {
      await _pump(tester, const AboutGuidanceSettingsPage());
      await tester.tap(find.text('Help & support'));
      await tester.pumpAndSettle();
      expect(find.byType(ContactSupportPage), findsOneWidget);
    });

    testWidgets('About Thinai opens the about page', (tester) async {
      await _pump(tester, const AboutGuidanceSettingsPage());
      await tester.tap(find.text('About Thinai'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutPage), findsOneWidget);
    });

    for (final (state, message) in [
      (UpdateState.upToDate, 'Thinai is up to date'),
      (UpdateState.unavailable, "Couldn't check for updates"),
      (UpdateState.downloading, 'Update already downloading'),
    ]) {
      testWidgets('checking for updates when ${state.name} says so', (
        tester,
      ) async {
        await _pump(
          tester,
          const AboutGuidanceSettingsPage(),
          overrides: [
            appUpdaterProvider.overrideWithValue(_FakeUpdater(state)),
          ],
        );

        await tester.tap(find.text('Check for updates'));
        await tester.pump();
        await tester.pump();

        expect(find.text(message), findsOneWidget);
      });
    }

    testWidgets('a downloaded update restarts only when asked', (tester) async {
      final updater = _FakeUpdater(UpdateState.readyToInstall);
      await _pump(
        tester,
        const AboutGuidanceSettingsPage(),
        overrides: [appUpdaterProvider.overrideWithValue(updater)],
      );

      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.text('Update ready'), findsOneWidget);
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(updater.installs, 0);

      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restart'));
      await tester.pumpAndSettle();
      expect(updater.installs, 1);
    });

    testWidgets('an available update downloads, then offers the restart', (
      tester,
    ) async {
      final updater = _FakeUpdater(UpdateState.available);
      await _pump(
        tester,
        const AboutGuidanceSettingsPage(),
        overrides: [appUpdaterProvider.overrideWithValue(updater)],
      );

      await tester.tap(find.text('Check for updates'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Downloading update…'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(updater.downloads, 1);
      expect(find.text('Update ready'), findsOneWidget);
    });

    testWidgets('a failed update download is reported', (tester) async {
      await _pump(
        tester,
        const AboutGuidanceSettingsPage(),
        overrides: [
          appUpdaterProvider.overrideWithValue(
            _FakeUpdater(
              UpdateState.available,
              downloadResult: AppUpdateResult.inAppUpdateFailed,
            ),
          ),
        ],
      );

      await tester.tap(find.text('Check for updates'));
      await tester.pump();
      await tester.pump();
      // The "downloading" snackbar has to time out before the next one shows.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('Update failed. Try Play Store.'), findsOneWidget);
    });

    testWidgets('a declined update download stays quiet', (tester) async {
      await _pump(
        tester,
        const AboutGuidanceSettingsPage(),
        overrides: [
          appUpdaterProvider.overrideWithValue(
            _FakeUpdater(
              UpdateState.available,
              downloadResult: AppUpdateResult.userDeniedUpdate,
            ),
          ),
        ],
      );

      await tester.tap(find.text('Check for updates'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('Update ready'), findsNothing);
      expect(find.text('Update failed. Try Play Store.'), findsNothing);
    });
  });
}
