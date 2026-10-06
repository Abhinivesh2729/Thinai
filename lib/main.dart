import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'server/foreground_handler.dart';
import 'ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Opens the port the service's task isolate uses to reach this one. Must
  // run before the service starts, otherwise the notification's Stop button
  // has nowhere to deliver its tap.
  FlutterForegroundTask.initCommunicationPort();
  initForegroundTaskOptions();
  runApp(const ProviderScope(child: LocalLlmApp()));
}
