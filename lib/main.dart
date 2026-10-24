import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

import 'llm/generation_settings.dart';
import 'server/foreground_handler.dart';
import 'ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Before the first SharedPreferences read: on Windows the plugin stores in
  // the Roaming profile, which managed PCs copy to a server. Chats and the
  // API token stay on this PC instead, beside the models.
  if (Platform.isWindows) {
    SharedPreferencesStorePlatform.instance = SharedPreferencesWindows()
      // The plugin has no public option for its folder; this is its hook.
      // ignore: invalid_use_of_visible_for_testing_member
      ..pathProvider = _LocalAppData();
  }
  // Warm up SharedPreferences and GenerationSettings immediately so disk I/O
  // completes in parallel while Flutter inflates the widget tree and boots Riverpod.
  unawaited(SharedPreferences.getInstance());
  unawaited(GenerationSettingsStore.instance.ensureLoaded());
  // Opens the port the service's task isolate uses to reach this one. Must
  // run before the service starts, otherwise the notification's Stop button
  // has nowhere to deliver its tap.
  if (foregroundServiceSupported) {
    FlutterForegroundTask.initCommunicationPort();
    initForegroundTaskOptions();
  }
  runApp(const ProviderScope(child: LocalLlmApp()));
}

/// `%LOCALAPPDATA%\<company>\<product>`: the local counterpart of the support
/// directory, the same folder the model store uses.
class _LocalAppData extends PathProviderWindows {
  @override
  Future<String?> getApplicationSupportPath() => getApplicationCachePath();
}
