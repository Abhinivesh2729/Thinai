import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

/// Id of the notification's "Stop server" action, shared by the task handler
/// that receives the tap and the main isolate that acts on it.
const kStopServerAction = 'stop_server';

/// Entry point for the service's Dart task isolate.
///
/// The service needs a task handler for one reason only: notification action
/// buttons are delivered to it. The handler does no work of its own, it
/// forwards the tap to the main isolate, where the HTTP server actually
/// lives.
@pragma('vm:entry-point')
void thinaiServiceCallback() {
  FlutterForegroundTask.setTaskHandler(_ThinaiTaskHandler());
}

class _ThinaiTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == kStopServerAction) {
      FlutterForegroundTask.sendDataToMain(kStopServerAction);
    }
  }
}

void initForegroundTaskOptions() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'thinai_server',
      channelName: 'Thinai background',
      channelDescription: 'Keeps the server and downloads running.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      // Hold both locks so the CPU keeps serving requests / writing the
      // download when the screen is off, and the Wi-Fi radio does not sleep
      // (needed for the LAN endpoint and for downloads to keep flowing).
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

/// Single owner of the Android foreground service.
///
/// The service must stay up whenever there is a reason to keep the Dart
/// isolate alive in the background: the HTTP server is running, or one or more
/// model downloads are in progress. Callers acquire/release those reasons and
/// this class starts, updates, or stops the one service accordingly, keeping
/// the notification text in sync.
class ForegroundServiceManager {
  ForegroundServiceManager._();

  /// Small icon for the notification: the app's logo silhouette, declared as
  /// a manifest meta-data (see AndroidManifest.xml). Without this the plugin
  /// falls back to the full launcher icon, which renders as a white square.
  static const _icon = NotificationIcon(
    metaDataName: 'in.atmega.thinai.notification_icon',
    backgroundColor: Color(0xFF0E4B75),
  );

  /// Shown only while the server is running, so the notification never
  /// offers to stop something that is not up. A download-only notification
  /// carries no button.
  static const _stopServerButton = NotificationButton(
    id: kStopServerAction,
    text: 'Stop server',
  );

  static bool _serverRunning = false;
  static int _serverPort = 11434;
  static bool _serverLan = false;
  static String? _serverIp;

  /// Tracks active model downloads with progress metrics for notification updates.
  static final Map<String, _ModelDownloadProgress> _activeDownloads = {};

  /// Recently completed model download to show a completion notification.
  static String? _recentCompletedModel;
  static Timer? _completedDismissTimer;
  static DateTime _lastProgressSync = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> serverStarted({
    required int port,
    required bool lan,
    String? ip,
  }) async {
    _serverRunning = true;
    _serverPort = port;
    _serverLan = lan;
    _serverIp = ip;
    await _sync();
  }

  static Future<void> serverStopped() async {
    _serverRunning = false;
    await _sync();
  }

  static Future<void> downloadStarted(String label, {int? totalBytes}) async {
    _completedDismissTimer?.cancel();
    _recentCompletedModel = null;
    _activeDownloads[label] = _ModelDownloadProgress(
      label: label,
      received: 0,
      total: totalBytes,
    );
    await _sync();
  }

  static void downloadProgress(String label, int received, int? total) {
    final entry = _activeDownloads[label];
    if (entry == null) return;
    entry.received = received;
    if (total != null && total > 0) entry.total = total;

    // Throttle notification updates: at most once every 700ms to avoid IPC spam
    final now = DateTime.now();
    if (now.difference(_lastProgressSync).inMilliseconds >= 700) {
      _lastProgressSync = now;
      _sync();
    }
  }

  static Future<void> downloadCompleted(String label) async {
    _activeDownloads.remove(label);
    _recentCompletedModel = label;
    await _sync();

    // Keep the "Download completed" notice visible for 5s before dismissing
    _completedDismissTimer?.cancel();
    _completedDismissTimer = Timer(const Duration(seconds: 5), () {
      _recentCompletedModel = null;
      _sync();
    });
  }

  static Future<void> downloadFinished(String label) async {
    _activeDownloads.remove(label);
    await _sync();
  }

  static bool get _needed =>
      _serverRunning || _activeDownloads.isNotEmpty || _recentCompletedModel != null;

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  static String get _title {
    if (_activeDownloads.isNotEmpty) {
      final first = _activeDownloads.values.first;
      final percent = (first.total != null && first.total! > 0)
          ? ' · ${((first.received / first.total!) * 100).clamp(0, 100).toInt()}%'
          : '';
      final extra = _activeDownloads.length - 1;
      final suffix = extra > 0 ? ' (+$extra more)' : '';
      return 'Downloading ${first.label}$percent$suffix';
    }
    if (_recentCompletedModel != null) {
      return 'Download completed: $_recentCompletedModel';
    }
    if (_serverRunning) return 'Thinai server running';
    return 'Thinai';
  }

  static String get _text {
    if (_activeDownloads.isNotEmpty) {
      final first = _activeDownloads.values.first;
      final parts = <String>[];
      if (first.total != null && first.total! > 0) {
        parts.add('${_formatBytes(first.received)} of ${_formatBytes(first.total!)}');
      } else if (first.received > 0) {
        parts.add(_formatBytes(first.received));
      }
      if (_serverRunning) {
        parts.add('Server active on :$_serverPort');
      } else {
        parts.add('Saving to local storage');
      }
      return parts.join(' · ');
    }
    if (_recentCompletedModel != null) {
      return 'Model is installed and ready for inference';
    }
    if (_serverRunning) {
      final host = _serverLan && _serverIp != null ? _serverIp : '127.0.0.1';
      return 'API at http://$host:$_serverPort';
    }
    return 'Thinai';
  }

  static Future<void> _sync() async {
    final running = await FlutterForegroundTask.isRunningService;
    final buttons = _serverRunning ? [_stopServerButton] : <NotificationButton>[];
    if (_needed) {
      if (running) {
        await FlutterForegroundTask.updateService(
          notificationTitle: _title,
          notificationText: _text,
          notificationIcon: _icon,
          notificationButtons: buttons,
        );
      } else {
        await _ensureNotificationPermission();
        await FlutterForegroundTask.startService(
          notificationTitle: _title,
          notificationText: _text,
          notificationIcon: _icon,
          notificationButtons: buttons,
          callback: thinaiServiceCallback,
        );
      }
    } else if (running) {
      await FlutterForegroundTask.stopService();
    }
  }

  static Future<void> _ensureNotificationPermission() async {
    if (await Permission.notification.isGranted) return;
    await Permission.notification.request();
  }
}

class _ModelDownloadProgress {
  final String label;
  int received;
  int? total;

  _ModelDownloadProgress({
    required this.label,
    required this.received,
    this.total,
  });
}
