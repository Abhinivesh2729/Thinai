// Entry point for the desktop build (Windows first):
//   flutter run -d windows -t lib/main_desktop.dart
//
// Shares the engine, models, chat logic and API server with the phone app
// (lib/main.dart). The UI is its own (lib/desktop/).
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'desktop/desk_window.dart';
import 'desktop/desktop_app.dart';
import 'desktop/dev_snapshots.dart';
import 'desktop/diagnostics.dart';
import 'desktop/smoke_test.dart';
import 'desktop/storage/sqlite_chat_store.dart';
import 'llm/generation_settings.dart';
import 'state/providers.dart';

Future<void> main(List<String> args) async {
  final launched = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  final smoke = SmokeArgs.parse(args);
  if (smoke != null) {
    exit(await runSmokeTest(smoke));
  }

  Diagnostics.captureErrors();
  unawaited(Diagnostics.init());

  // Disk reads start now and finish while the window and first frame are
  // being prepared.
  unawaited(SharedPreferences.getInstance());
  unawaited(GenerationSettingsStore.instance.ensureLoaded());
  final chatStore = SqliteChatStore.open();

  // Window chrome is set up in parallel with the first frame rather than
  // before it: nothing on screen depends on it, and startup is what users feel.
  final windowReady = initDeskWindow();

  final container = ProviderContainer(
    overrides: [
      chatSessionsProvider.overrideWith(
        (ref) => SqliteChatSessionsController(chatStore),
      ),
    ],
  );
  await DeskWindowController(container).attach();

  Diagnostics.log('startup: runApp at ${launched.elapsedMilliseconds} ms');
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: DesktopApp(launched: launched),
    ),
  );
  await windowReady;
  unawaited(runSnapshots(container));
}
