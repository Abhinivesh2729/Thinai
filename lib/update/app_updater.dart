import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

export 'package:in_app_update/in_app_update.dart'
    show AppUpdateResult, InstallStatus;

/// Where the installed build stands against the newest one on Play.
enum UpdateState {
  /// Play has nothing newer than what is installed.
  upToDate,

  /// A newer build is published and can be fetched.
  available,

  /// A fetch started earlier is still running.
  downloading,

  /// A newer build is already on the device; only a restart is left.
  readyToInstall,

  /// Play could not answer: a debug or sideloaded build, no Play services, or
  /// the store was unreachable. Deliberately not an error state — "cannot
  /// check" is nothing the user can act on, so the UI stays silent.
  unavailable,
}

/// The answer to "is there a newer version", plus what Play will let us do
/// about it.
@immutable
class UpdateStatus {
  const UpdateStatus(
    this.state, {
    this.availableVersionCode,
    this.flexibleAllowed = false,
    this.immediateAllowed = false,
    this.priority = 0,
    this.stalenessDays,
  });

  final UpdateState state;

  /// versionCode of the build waiting on Play, when there is one.
  final int? availableVersionCode;

  /// Flexible: download in the background, install on the next restart.
  final bool flexibleAllowed;

  /// Immediate: Play takes over the screen until the update is installed.
  final bool immediateAllowed;

  /// 0-5, set per release in the Play Developer API. Used to decide when an
  /// update is important enough to interrupt for.
  final int priority;

  /// Days since this device's Play Store first saw the update.
  final int? stalenessDays;

  bool get hasUpdate =>
      state == UpdateState.available || state == UpdateState.readyToInstall;

  /// A release the user should not be able to keep postponing. Priority is the
  /// signal we set at publish time; staleness catches anyone who has ignored a
  /// normal update for a fortnight.
  bool get isCritical =>
      state == UpdateState.available &&
      immediateAllowed &&
      (priority >= 4 || (stalenessDays ?? 0) >= 14);
}

/// App self-update, built on Play's in-app update API.
///
/// Play already knows every version published and already holds the APK, so
/// this asks Play rather than any endpoint of ours: no update server, no
/// version manifest to keep in sync, and no `REQUEST_INSTALL_PACKAGES`
/// permission — Play installs the APK itself, signed by the same key, so the
/// install is silent to us.
///
/// Consequence worth knowing: none of this works on a build that Play did not
/// install. Debug runs, `flutter install`, and sideloaded APKs all report
/// [UpdateState.unavailable]. Testing needs the app on an internal-test or
/// closed track, installed from Play, with a lower versionCode than the one
/// published.
class AppUpdater {
  const AppUpdater();

  /// Everything below is a Play Store API. Guarded here so the desktop and web
  /// builds in this repo do not trip a MissingPluginException.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Asks Play what it has. Never throws: every failure path is
  /// [UpdateState.unavailable].
  Future<UpdateStatus> check() async {
    if (!isSupported) return const UpdateStatus(UpdateState.unavailable);
    try {
      final info = await InAppUpdate.checkForUpdate();
      return UpdateStatus(
        _stateOf(info),
        availableVersionCode: info.availableVersionCode,
        flexibleAllowed: info.flexibleUpdateAllowed,
        immediateAllowed: info.immediateUpdateAllowed,
        priority: info.updatePriority,
        stalenessDays: info.clientVersionStalenessDays,
      );
    } catch (_) {
      return const UpdateStatus(UpdateState.unavailable);
    }
  }

  static UpdateState _stateOf(AppUpdateInfo info) {
    if (info.installStatus == InstallStatus.downloaded) {
      return UpdateState.readyToInstall;
    }
    switch (info.updateAvailability) {
      case UpdateAvailability.updateAvailable:
        return UpdateState.available;
      case UpdateAvailability.developerTriggeredUpdateInProgress:
        return UpdateState.downloading;
      case UpdateAvailability.updateNotAvailable:
        return UpdateState.upToDate;
      case UpdateAvailability.unknown:
        return UpdateState.unavailable;
    }
  }

  /// Downloads the update in the background. Play shows its own consent sheet
  /// first, so only call this from a user action. The future completes when
  /// the download has finished, after which [install] is what applies it.
  Future<AppUpdateResult> download() async {
    if (!isSupported) return AppUpdateResult.inAppUpdateFailed;
    try {
      return await InAppUpdate.startFlexibleUpdate();
    } catch (_) {
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  /// Applies a downloaded update. Restarts the app, so anything unsaved has to
  /// be written before this is called.
  Future<void> install() async {
    if (!isSupported) return;
    await InAppUpdate.completeFlexibleUpdate();
  }

  /// Hands the whole flow to Play: a full-screen progress UI, then a restart.
  /// For releases nobody should be running the old build of.
  Future<AppUpdateResult> updateNow() async {
    if (!isSupported) return AppUpdateResult.inAppUpdateFailed;
    try {
      return await InAppUpdate.performImmediateUpdate();
    } catch (_) {
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  /// Download progress for an update started with [download]. Emits
  /// [InstallStatus.downloaded] when the APK is on the device.
  Stream<InstallStatus> get installProgress =>
      isSupported ? InAppUpdate.installUpdateListener : const Stream.empty();

  /// The running build, as "2.2.0 (9)".
  static Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}
