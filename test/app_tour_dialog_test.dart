import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_llm/ui/widgets/app_tour_dialog.dart';

class _Calls {
  final tabs = <int>[];
  int walkthroughs = 0;
  int starters = 0;
}

/// Opens the tour from a button, the way the shell does.
Future<_Calls> _openTour(WidgetTester tester) async {
  final calls = _Calls();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => AppTourDialog.show(
              context: context,
              onNavigateTab: calls.tabs.add,
              onStartLiveWalkthrough: () => calls.walkthroughs++,
              onSelectStarterModel: () => calls.starters++,
            ),
            child: const Text('open tour'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open tour'));
  await tester.pumpAndSettle();
  return calls;
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('Next Step'));
  await tester.pumpAndSettle();
}

/// Moves to the last slide, where the launch options are.
Future<void> _toLastSlide(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await _next(tester);
  }
  expect(find.text('STAGE 5 OF 5'), findsOneWidget);
}

Future<void> _pressLaunchOption(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  group('app tour dialog', () {
    testWidgets('opens on the privacy slide with Skip, not Back', (
      tester,
    ) async {
      await _openTour(tester);

      expect(find.text('THINAI TOUR'), findsOneWidget);
      expect(find.text('STAGE 1 OF 5'), findsOneWidget);
      expect(find.text('Thinai (On-Device)'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
      expect(find.text('Next Step'), findsOneWidget);
    });

    testWidgets('Skip closes the tour', (tester) async {
      await _openTour(tester);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.byType(AppTourDialog), findsNothing);
    });

    testWidgets('the close button closes the tour', (tester) async {
      await _openTour(tester);
      await tester.tap(find.byTooltip('Close Tour'));
      await tester.pumpAndSettle();
      expect(find.byType(AppTourDialog), findsNothing);
    });

    testWidgets('Next walks through every slide in order', (tester) async {
      await _openTour(tester);

      await _next(tester);
      expect(find.text('STAGE 2 OF 5'), findsOneWidget);
      expect(find.text('Smart Memory Fit System'), findsOneWidget);
      expect(find.text('Fits Easily'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      await _next(tester);
      expect(find.text('STAGE 3 OF 5'), findsOneWidget);
      expect(find.text('Reasoning Traces'), findsOneWidget);

      await _next(tester);
      expect(find.text('STAGE 4 OF 5'), findsOneWidget);
      expect(find.text('/v1/chat/completions'), findsOneWidget);

      await _next(tester);
      expect(find.text('STAGE 5 OF 5'), findsOneWidget);
      expect(find.text('Complete Tour'), findsOneWidget);
      expect(find.text('Next Step'), findsNothing);
    });

    testWidgets('Back returns to the previous slide', (tester) async {
      await _openTour(tester);
      await _next(tester);
      await _next(tester);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('STAGE 2 OF 5'), findsOneWidget);
    });

    testWidgets('Complete Tour on the last slide closes it', (tester) async {
      final calls = await _openTour(tester);
      await _toLastSlide(tester);

      await tester.tap(find.text('Complete Tour'));
      await tester.pumpAndSettle();

      expect(find.byType(AppTourDialog), findsNothing);
      expect(calls.tabs, isEmpty);
      expect(calls.walkthroughs, 0);
      expect(calls.starters, 0);
    });

    testWidgets('Get Starter Model closes the tour and asks for the model', (
      tester,
    ) async {
      final calls = await _openTour(tester);
      await _toLastSlide(tester);

      await _pressLaunchOption(tester, 'Get Starter Model');

      expect(find.byType(AppTourDialog), findsNothing);
      expect(calls.starters, 1);
    });

    testWidgets('Open Models Catalog goes to the Models tab', (tester) async {
      final calls = await _openTour(tester);
      await _toLastSlide(tester);

      await _pressLaunchOption(tester, 'Open Models Catalog');

      expect(find.byType(AppTourDialog), findsNothing);
      expect(calls.tabs, [1]);
    });

    testWidgets('Start Live Guide starts the walkthrough', (tester) async {
      final calls = await _openTour(tester);
      await _toLastSlide(tester);

      await _pressLaunchOption(tester, 'Start Live Guide');

      expect(find.byType(AppTourDialog), findsNothing);
      expect(calls.walkthroughs, 1);
    });
  });

  group('live guided tour dock', () {
    Future<(List<int>, List<void>)> pumpDock(
      WidgetTester tester,
      int step,
    ) async {
      final steps = <int>[];
      final dismissals = <void>[];
      await tester.pumpWidget(
        MaterialApp(
          // The test font draws most glyphs a full em wide, so the dock's
          // button row only fits at the size a real font would give it.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(0.7)),
            child: child!,
          ),
          home: Scaffold(
            body: LiveGuidedTourDock(
              step: step,
              onStepChanged: steps.add,
              onDismiss: () => dismissals.add(null),
            ),
          ),
        ),
      );
      return (steps, dismissals);
    }

    const titles = [
      'Models Catalog (Tab 2)',
      'Management & Benchmarking',
      'Chat Studio (Tab 1)',
      'Local API Server (Tab 3)',
    ];

    for (var step = 0; step < titles.length; step++) {
      testWidgets('step ${step + 1} explains ${titles[step]}', (tester) async {
        await pumpDock(tester, step);
        expect(find.text('STEP ${step + 1} OF 4'), findsOneWidget);
        expect(find.text(titles[step]), findsOneWidget);
      });
    }

    testWidgets('the first step has no Previous button', (tester) async {
      await pumpDock(tester, 0);
      expect(find.text('Previous'), findsNothing);
      expect(find.text('Next Step'), findsOneWidget);
    });

    testWidgets('Next Step moves forward', (tester) async {
      final (steps, dismissals) = await pumpDock(tester, 1);
      await tester.tap(find.text('Next Step'));
      expect(steps, [2]);
      expect(dismissals, isEmpty);
    });

    testWidgets('Previous moves back', (tester) async {
      final (steps, _) = await pumpDock(tester, 2);
      await tester.tap(find.text('Previous'));
      expect(steps, [1]);
    });

    testWidgets('Finish Tour on the last step dismisses the dock', (
      tester,
    ) async {
      final (steps, dismissals) = await pumpDock(tester, 3);
      expect(find.text('Next Step'), findsNothing);
      await tester.tap(find.text('Finish Tour'));
      expect(steps, isEmpty);
      expect(dismissals, hasLength(1));
    });

    testWidgets('Exit Tour and the close icon both dismiss', (tester) async {
      final (_, dismissals) = await pumpDock(tester, 1);
      await tester.tap(find.text('Exit Tour'));
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissals, hasLength(2));
    });
  });
}
