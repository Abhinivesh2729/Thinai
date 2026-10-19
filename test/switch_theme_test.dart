import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/ui/app.dart';
import 'package:local_llm/ui/pages/server_page.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

/// The colours a [Switch] paints with [theme], falling back to Material 3's
/// defaults where the theme leaves a slot empty.
(Color thumb, Color track, Color outline) _paint(
  ThemeData theme, {
  required bool on,
}) {
  final s = theme.colorScheme;
  final states = {if (on) WidgetState.selected};
  final t = theme.switchTheme;
  return (
    t.thumbColor?.resolve(states) ?? (on ? s.onPrimary : s.outline),
    t.trackColor?.resolve(states) ??
        (on ? s.primary : s.surfaceContainerHighest),
    t.trackOutlineColor?.resolve(states) ??
        (on ? Colors.transparent : s.outline),
  );
}

void main() {
  // #54: in dark theme the off thumb and border matched the track.
  for (final brightness in Brightness.values) {
    for (final on in [false, true]) {
      test(
        '${brightness.name} switch thumb stands out when ${on ? 'on' : 'off'}',
        () {
          final (thumb, track, outline) = _paint(
            buildAppTheme(brightness),
            on: on,
          );
          // WCAG's 3:1 minimum for UI components.
          expect(_contrast(thumb, track), greaterThanOrEqualTo(3));
          if (!on) expect(_contrast(outline, track), greaterThanOrEqualTo(3));
        },
      );
    }
  }

  testWidgets('LAN switch takes its colours from the theme', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          home: const ServerPage(),
        ),
      ),
    );
    await tester.pump();

    final lanSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(lanSwitch.activeThumbColor, isNull);
    expect(lanSwitch.thumbColor, isNull);
    expect(lanSwitch.trackColor, isNull);
  });
}
