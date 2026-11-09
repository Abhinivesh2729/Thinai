// Entry point for the desktop build (Windows first):
//   flutter run -d windows -t lib/main_desktop.dart
//
// Shares the engine, models, chat storage and API server with the phone app
// (lib/main.dart) but none of its UI.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'desktop/smoke_test.dart';
import 'llm/generation_settings.dart';
import 'ui/app.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final smoke = SmokeArgs.parse(args);
  if (smoke != null) {
    exit(await runSmokeTest(smoke));
  }

  // Disk reads start now and finish while the first frame is built.
  unawaited(SharedPreferences.getInstance());
  unawaited(GenerationSettingsStore.instance.ensureLoaded());
  runApp(const ProviderScope(child: LocalLlmApp()));
}
