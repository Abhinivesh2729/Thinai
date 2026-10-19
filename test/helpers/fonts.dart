import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real Roboto that ships with the Flutter SDK.
///
/// The test default (Ahem) draws every glyph as a full square, so rows that
/// fit on a phone overflow in a test and layout checks mean nothing.
Future<void> loadRoboto() async {
  // flutter_tester lives under bin/cache/artifacts/engine/<host>/.
  var dir = File(Platform.resolvedExecutable).parent;
  while (!Directory('${dir.path}/material_fonts').existsSync() &&
      dir.parent.path != dir.path) {
    dir = dir.parent;
  }
  final fonts = Directory('${dir.path}/material_fonts');
  expect(fonts.existsSync(), isTrue, reason: 'Roboto not found in the SDK');

  final loader = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
    final file = File('${fonts.path}/Roboto-$weight.ttf');
    if (!file.existsSync()) continue;
    final bytes = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}
