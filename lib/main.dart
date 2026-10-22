import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'llm/generation_settings.dart';
import 'server/foreground_handler.dart';
import 'ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Warm up SharedPreferences and GenerationSettings immediately so disk I/O
  // completes in parallel while Flutter inflates the widget tree and boots Riverpod.
  unawaited(SharedPreferences.getInstance());
  unawaited(GenerationSettingsStore.instance.ensureLoaded());
  // Opens the port the service's task isolate uses to reach this one. Must
  // run before the service starts, otherwise the notification's Stop button
  // has nowhere to deliver its tap.
  FlutterForegroundTask.initCommunicationPort();
  initForegroundTaskOptions();
  // The bundled cloudflared binary isn't a Dart package, so list it by hand.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'cloudflared',
    ], await rootBundle.loadString('assets/licenses/cloudflared.txt'));
  });
  runApp(const ProviderScope(child: LocalLlmApp()));
}
