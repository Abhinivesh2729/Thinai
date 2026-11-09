/// A plain log file the desktop app writes as it runs.
///
/// The founder tests Windows builds with no debugger on the machine, so when
/// something breaks the log is the evidence: Settings > About has "Open log
/// folder" and "Copy diagnostics". It records startup timings, model loads,
/// engine errors and uncaught exceptions. Never chat text, never prompts.
///
/// File: `<app support>/logs/thinai.log`, rotated at 2 MB (one `.1` kept).
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

abstract final class Diagnostics {
  static IOSink? _sink;
  static String? _path;
  static final _pending = <String>[];
  static final _started = DateTime.now();

  /// Recent lines, for "Copy diagnostics".
  static final recent = <String>[];

  static String? get logPath => _path;

  /// True when the previous run died in native code (see crash.txt).
  static bool previousCrash = false;

  static Future<void>? _initialized;

  /// Completes once [init] has opened the log and read any crash report.
  static Future<void> get initialized => _initialized ?? Future.value();

  /// Opens the log file. Lines logged before this are kept and flushed.
  static Future<void> init() => _initialized ??= _init();

  static Future<void> _init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logs = Directory('${dir.path}${Platform.pathSeparator}logs');
      await logs.create(recursive: true);
      final file = File('${logs.path}${Platform.pathSeparator}thinai.log');
      if (await file.exists() && await file.length() > 2 * 1024 * 1024) {
        final old = File('${file.path}.1');
        if (await old.exists()) await old.delete();
        await file.rename(old.path);
      }
      _path = file.path;
      _sink = file.openWrite(mode: FileMode.append);
      _sink!.writeln('');
      _sink!.writeln(
        '==== Thinai started ${_started.toIso8601String()} '
        '(${Platform.operatingSystemVersion}, '
        '${Platform.numberOfProcessors} cores) ====',
      );
      for (final line in _pending) {
        _sink!.writeln(line);
      }
      _pending.clear();
      await _collectNativeCrash(logs.path);
    } on Object catch (e) {
      debugPrint('diagnostics: cannot open log: $e');
    }
  }

  /// The Windows runner writes crash.txt when the process dies in native
  /// code, and keeps the previous run's stderr (llama.cpp) as
  /// native.prev.log. Fold both into this log once, so the crash travels
  /// with "Copy diagnostics".
  static Future<void> _collectNativeCrash(String dir) async {
    final sep = Platform.pathSeparator;
    final crash = File('$dir${sep}crash.txt');
    if (!await crash.exists()) return;
    final report = (await crash.readAsString()).trim();
    previousCrash = true;
    log('PREVIOUS RUN CRASHED (native):\n$report');
    final native = File('$dir${sep}native.prev.log');
    if (await native.exists()) {
      final lines = (await native.readAsString()).trim().split('\n');
      final tail = lines.length > 40 ? lines.sublist(lines.length - 40) : lines;
      log('Last native log lines before the crash:\n${tail.join('\n')}');
    }
    await crash.rename('$dir${sep}crash.prev.txt');
  }

  static void log(String message) {
    final ms = DateTime.now().difference(_started).inMilliseconds;
    final line = '[+${(ms / 1000).toStringAsFixed(3)}s] $message';
    recent.add(line);
    if (recent.length > 300) recent.removeRange(0, recent.length - 300);
    if (kDebugMode) debugPrint(line);
    final sink = _sink;
    if (sink == null) {
      _pending.add(line);
    } else {
      sink.writeln(line);
    }
  }

  /// Routes Flutter and zone errors into the log as well as the console.
  static void captureErrors() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      log('FlutterError: ${details.exceptionAsString()}\n${details.stack}');
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      log('Uncaught: $error\n$stack');
      return true;
    };
  }

  static Future<void> flush() async => _sink?.flush();
}
