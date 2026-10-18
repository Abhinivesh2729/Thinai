import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/app.dart';
import 'package:local_llm/ui/pages/splash_page.dart';
import 'package:local_llm/ui/widgets/onboarding_tour_screen.dart';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  setUp(() {
    // A finished tour sends the app straight to the shell instead of the
    // first-run onboarding screen.
    SharedPreferences.setMockInitialValues({
      OnboardingTourScreen.tourSeenKey: true,
    });
  });

  testWidgets('App renders bottom navigation with Chat/Models/Server tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        // Startup restore reads the models directory and the foreground
        // service state. Neither platform channel answers under the test
        // binding, so the work itself is stubbed out and what is under test
        // is the shell that comes after it.
        overrides: [appBootstrapProvider.overrideWith((ref) async {})],
        child: const LocalLlmApp(),
      ),
    );
    // The splash shows for ~2.8s before the tabbed shell mounts, so a single
    // pump only ever sees the splash.
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

    // The shell defers its logo precache and update check by a few seconds;
    // let them fire so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a hung startup restore does not trap the user on the splash', (
    tester,
  ) async {
    // No override and no platform mocks, so startup restore hangs exactly the
    // way a wedged plugin would on a device.
    await tester.pumpWidget(const ProviderScope(child: LocalLlmApp()));
    expect(find.byType(SplashPage), findsOneWidget);

    // Restore runs in the background, so the shell opens on the splash's own
    // timer rather than waiting for it.
    await tester.pump(const Duration(seconds: 4));
    // Past the splash's cross-fade out.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SplashPage), findsNothing);
    expect(_navLabel('Chat'), findsOneWidget);

    // Let the shell's deferred logo precache and update check fire.
    await tester.pump(const Duration(seconds: 5));
  });
}
