import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_llm/l10n/l10n.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ta = lookupAppLocalizations(const Locale('ta'));

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Android names the phone', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(deviceKind, 'phone');
    expect(en.chatEmptyBody(deviceKind), contains('your phone'));
    expect(ta.chatEmptyBody(deviceKind), contains('கைப்பேசியில்'));
  });

  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ]) {
    test('${platform.name} names the computer', () {
      debugDefaultTargetPlatformOverride = platform;
      expect(deviceKind, 'desktop');
      expect(en.chatEmptyBody(deviceKind), contains('your computer'));
      expect(
        en.modelsFitNeeds(deviceKind, '4 GB', '2 GB'),
        'Needs 4 GB, this computer has 2 GB to spare.',
      );
      expect(ta.chatEmptyBody(deviceKind), contains('கணினியில்'));
      expect(ta.modelsFitTooLarge(deviceKind), isNot(contains('கைப்பேசி')));
    });
  }
}
