import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_llm/server/foreground_handler.dart';
import 'package:local_llm/ui/pages/chat_page.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('hasForegroundService', () {
    test('is on for Android, where the server needs the service', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(hasForegroundService, isTrue);
    });

    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ]) {
      test('is off on ${platform.name}, which has no such plugin', () {
        debugDefaultTargetPlatformOverride = platform;
        expect(hasForegroundService, isFalse);
      });
    }
  });

  group('greetingName', () {
    test('phones have no account name to greet', () {
      expect(
        greetingName('phone', {'USER': 'kalidas'}, windows: false),
        isNull,
      );
    });

    test('Windows reads USERNAME, others read USER', () {
      final env = {'USERNAME': 'Win', 'USER': 'Posix'};
      expect(greetingName('desktop', env, windows: true), 'Win');
      expect(greetingName('desktop', env, windows: false), 'Posix');
    });

    test('an all-caps or all-lower account name reads as a name', () {
      expect(
        greetingName('desktop', {'USERNAME': 'KALIDAS'}, windows: true),
        'Kalidas',
      );
      expect(
        greetingName('desktop', {'USER': 'kalidas'}, windows: false),
        'Kalidas',
      );
    });

    test('a mixed-case name is kept as written', () {
      expect(
        greetingName('desktop', {'USER': 'McKenzie'}, windows: false),
        'McKenzie',
      );
    });

    test('a missing or blank name falls back to no name', () {
      expect(greetingName('desktop', const {}, windows: true), isNull);
      expect(greetingName('desktop', {'USER': '  '}, windows: false), isNull);
    });
  });
}
