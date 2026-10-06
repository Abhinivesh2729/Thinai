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

  /// Display names of the models currently downloading (one entry per active
  /// download), so the notification can name them.
  static final List<String> _downloads = [];

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

  static Future<void> downloadStarted(String label) async {
    _downloads.add(label);
    await _sync();
  }

  static Future<void> downloadFinished(String label) async {
    _downloads.remove(label);
    await _sync();
  }

  static bool get _needed => _serverRunning || _downloads.isNotEmpty;

  static String get _title {
    if (_downloads.isNotEmpty) {
      final extra = _downloads.length - 1;
      final suffix = extra > 0 ? '  +$extra more' : '';
      return 'Downloading ${_downloads.first}$suffix';
    }
    if (_serverRunning) return 'Thinai server running';
    return 'Thinai';
  }

  static String get _text {
    final parts = <String>[];
    if (_serverRunning) {
      final host = _serverLan && _serverIp != null ? _serverIp : '127.0.0.1';
      parts.add('API at http://$host:$_serverPort');
    }
    if (_downloads.isNotEmpty) {
      parts.add(
        _serverRunning
            ? 'Downloading ${_downloads.length} model${_downloads.length == 1 ? '' : 's'}'
            : 'Saving to your models. Keep the app open or backgrounded',
      );
    }
    return parts.isEmpty ? 'Thinai' : parts.join(' · ');
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
