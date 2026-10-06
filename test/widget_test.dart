import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/app.dart';
import 'package:local_llm/ui/pages/splash_page.dart';

Finder _navLabel(String label) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text(label),
);

void main() {
  setUp(() {
    // app_tour_seen_v2 keeps the coach marks from starting: they animate
    // continuously, so pumpAndSettle would never return.
    SharedPreferences.setMockInitialValues({'app_tour_seen_v2': true});
  });

  testWidgets('App renders bottom navigation with Chat/Models/Server tabs',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Startup restore reads the models directory and the foreground
        // service state. Neither platform channel answers under the test
        // binding, so the work itself is stubbed out and what is under test
        // is the shell that comes after it.
        overrides: [
          appBootstrapProvider.overrideWith((ref) async {}),
        ],
        child: const LocalLlmApp(),
      ),
    );
    // _Shell shows SplashPage for 3s before the tabbed shell mounts, so a
    // single pump only ever sees the splash.
    await tester.pump(const Duration(seconds: 4));
    // One more frame for the setState that swaps the splash for the shell.
    // Not pumpAndSettle: the Models tab spins on a model list that never
    // resolves here, so nothing ever settles.
    await tester.pump();

    // Scope to the NavigationBar: the selected tab's AppBar title repeats the
    // destination label, so a bare find.text('Models') matches twice.
    expect(_navLabel('Chat'), findsOneWidget);
    expect(_navLabel('Models'), findsOneWidget);
    expect(_navLabel('Server'), findsOneWidget);
  });

  testWidgets('the splash gives up rather than trapping the user',
      (tester) async {
    // No override and no platform mocks, so startup restore hangs exactly the
    // way a wedged plugin would on a device.
    await tester.pumpWidget(const ProviderScope(child: LocalLlmApp()));
    await tester.pump(const Duration(seconds: 4));
    expect(
      find.byType(SplashPage),
      findsOneWidget,
      reason: 'still waiting on startup restore',
    );

    // Past the bootstrap timeout the app opens anyway.
    await tester.pump(const Duration(seconds: 12));
    await tester.pump();
    expect(_navLabel('Chat'), findsOneWidget);
  });
}
