import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/update/app_updater.dart';

const _channel = MethodChannel('de.ffuf.in_app_update/methods');

/// Stands in for Play's answer to `checkForUpdate`. Field names match what the
/// plugin's Android side puts on the channel.
Map<String, Object?> playAnswer({
  int availability = 2, // updateAvailable
  int installStatus = 0, // unknown
  bool flexible = true,
  bool immediate = true,
  int priority = 0,
  int? staleness,
  int? versionCode = 12,
}) => {
  'updateAvailability': availability,
  'immediateAllowed': immediate,
  'immediateAllowedPreconditions': <int>[],
  'flexibleAllowed': flexible,
  'flexibleAllowedPreconditions': <int>[],
  'availableVersionCode': versionCode,
  'installStatus': installStatus,
  'packageName': 'in.atmega.thinai',
  'clientVersionStalenessDays': staleness,
  'updatePriority': priority,
};

void mockPlay(Map<String, Object?>? answer) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
        if (answer == null) {
          throw PlatformException(code: 'ERROR_APP_NOT_OWNED');
        }
        return answer;
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => mockPlay(null));

  group('reading Play', () {
    test('a published newer build is offered', () async {
      mockPlay(playAnswer(versionCode: 14));
      final status = await const AppUpdater().check();
      expect(status.state, UpdateState.available);
      expect(status.availableVersionCode, 14);
      expect(status.hasUpdate, isTrue);
    });

    test('nothing newer stays quiet', () async {
      mockPlay(playAnswer(availability: 1));
      final status = await const AppUpdater().check();
      expect(status.state, UpdateState.upToDate);
      expect(status.hasUpdate, isFalse);
    });

    test('an already downloaded build only needs the restart', () async {
      // installStatus wins over availability: Play still reports an update as
      // available once the APK is on the device, and asking the user to
      // download what they already have is the bug this guards.
      mockPlay(playAnswer(installStatus: 11));
      final status = await const AppUpdater().check();
      expect(status.state, UpdateState.readyToInstall);
      expect(status.hasUpdate, isTrue);
    });

    test(
      'a developer-triggered update in progress is not re-offered',
      () async {
        mockPlay(playAnswer(availability: 3));
        final status = await const AppUpdater().check();
        expect(status.state, UpdateState.downloading);
      },
    );

    test(
      'a build Play did not install reports unavailable, not an error',
      () async {
        // Sideloaded and debug builds throw on the channel. The check has to
        // swallow that: "cannot check" is nothing the user can act on.
        mockPlay(null);
        final status = await const AppUpdater().check();
        expect(status.state, UpdateState.unavailable);
        expect(status.hasUpdate, isFalse);
      },
    );
  });

  group('when to interrupt', () {
    test('an ordinary update never takes the screen', () async {
      mockPlay(playAnswer(priority: 3, staleness: 2));
      final status = await const AppUpdater().check();
      expect(status.isCritical, isFalse);
    });

    test('priority 4 and up takes the screen', () async {
      mockPlay(playAnswer(priority: 4));
      final status = await const AppUpdater().check();
      expect(status.isCritical, isTrue);
    });

    test('an update ignored for a fortnight takes the screen', () async {
      mockPlay(playAnswer(priority: 0, staleness: 14));
      final status = await const AppUpdater().check();
      expect(status.isCritical, isTrue);
    });

    test('nothing is forced when Play forbids the immediate flow', () async {
      mockPlay(playAnswer(priority: 5, staleness: 30, immediate: false));
      final status = await const AppUpdater().check();
      expect(status.isCritical, isFalse);
    });

    test('a downloaded update is never forced', () async {
      // Already on the device: the only step left is a restart, and taking
      // over the screen to demand one is not what priority means.
      mockPlay(playAnswer(installStatus: 11, priority: 5));
      final status = await const AppUpdater().check();
      expect(status.isCritical, isFalse);
    });
  });
}
