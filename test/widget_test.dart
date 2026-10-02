import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/app.dart';
import 'package:local_llm/ui/pages/splash_page.dart';
import 'package:local_llm/ui/widgets/coach_mark_targets.dart';

Finder get _menu => find.byKey(CoachMarkTargets.menuButton);

void main() {
  setUp(() {
    // app_tour_seen_v2 keeps the coach marks from starting: they animate
    // continuously, so pumpAndSettle would never return.
    SharedPreferences.setMockInitialValues({'app_tour_seen_v2': true});
  });

  testWidgets('App opens on Chat, with Models and Server in the drawer', (
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
    // _Shell shows SplashPage for 3s before the shell mounts, so a single
    // pump only ever sees the splash.
    await tester.pump(const Duration(seconds: 4));
    // One more frame for the setState that swaps the splash for the shell.
    // Not pumpAndSettle: the Models section spins on a model list that never
    // resolves here, so nothing ever settles.
    await tester.pump();

    // Chat is home: no bottom bar, a menu button instead.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Ready when you are'), findsOneWidget);
    expect(_menu, findsOneWidget);

    await tester.tap(_menu);
    // Two frames: one to start the drawer's slide, one to finish it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('New chat'), findsOneWidget);
    expect(find.text('Models'), findsOneWidget);
    expect(find.text('Server'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Models'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.widgetWithText(AppBar, 'Models'), findsOneWidget);
    expect(find.text('Ready when you are'), findsNothing);

    // Back from a section returns to the conversation instead of leaving.
    // The same request the system back gesture makes of the navigator.
    unawaited(
      tester.state<NavigatorState>(find.byType(Navigator).first).maybePop(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Ready when you are'), findsOneWidget);
  });

  testWidgets('a launch lands on a new chat, the last one kept in recents', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'app_tour_seen_v2': true,
      'chat_sessions_v1': jsonEncode({
        'activeId': 'a',
        'conversations': [
          {
            'id': 'a',
            'updatedAt': 1000,
            'turns': [
              {'role': 'user', 'content': 'Yesterday question'},
              {'role': 'assistant', 'content': 'Yesterday answer'},
            ],
          },
        ],
      }),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appBootstrapProvider.overrideWith((ref) async {})],
        child: const LocalLlmApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    // The chat open when the app was last closed is not reopened...
    expect(find.text('Ready when you are'), findsOneWidget);
    expect(find.text('Yesterday answer'), findsNothing);

    // ...but it is one tap away.
    await tester.tap(_menu);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Yesterday question'), findsOneWidget);
    await tester.tap(find.text('Yesterday question'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Yesterday answer'), findsOneWidget);
  });

  testWidgets('the splash gives up rather than trapping the user', (
    tester,
  ) async {
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
    expect(_menu, findsOneWidget);
  });
}
