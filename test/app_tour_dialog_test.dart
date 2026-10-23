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
  await tester.tap(find.text('Next'));
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
      expect(find.text('Thinai, on device'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Skip closes the tour', (tester) async {
      await _openTour(tester);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.byType(AppTourDialog), findsNothing);
    });

    testWidgets('the close button closes the tour', (tester) async {
      await _openTour(tester);
      await tester.tap(find.byTooltip('Close tour'));
      await tester.pumpAndSettle();
      expect(find.byType(AppTourDialog), findsNothing);
    });

    testWidgets('Next walks through every slide in order', (tester) async {
      await _openTour(tester);

      await _next(tester);
      expect(find.text('STAGE 2 OF 5'), findsOneWidget);
      expect(find.text('Memory fit'), findsOneWidget);
      expect(find.text('Fits'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      await _next(tester);
      expect(find.text('STAGE 3 OF 5'), findsOneWidget);
      expect(find.text('Reasoning'), findsOneWidget);

      await _next(tester);
      expect(find.text('STAGE 4 OF 5'), findsOneWidget);
      expect(find.text('/v1/chat/completions'), findsOneWidget);

      await _next(tester);
      expect(find.text('STAGE 5 OF 5'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('Back returns to the previous slide', (tester) async {
      await _openTour(tester);
      await _next(tester);
      await _next(tester);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('STAGE 2 OF 5'), findsOneWidget);
    });

    testWidgets('Finish on the last slide closes it', (tester) async {
      final calls = await _openTour(tester);
      await _toLastSlide(tester);

      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(find.byType(AppTourDialog), findsNothing);
      expect(calls.tabs, isEmpty);
      expect(calls.walkthroughs, 0);
      expect(calls.starters, 0);
    });

    testWidgets('Starter model closes the tour and asks for the model', (
      tester,
    ) async {
      final calls = await _openTour(tester);
      await _toLastSlide(tester);

      await _pressLaunchOption(tester, 'Starter model');

      expect(find.byType(AppTourDialog), findsNothing);
      expect(calls.starters, 1);
    });

    testWidgets('Full catalog goes to the Models tab', (tester) async {
      final calls = await _openTour(tester);
      await _toLastSlide(tester);

      await _pressLaunchOption(tester, 'Full catalog');

      expect(find.byType(AppTourDialog), findsNothing);
      expect(calls.tabs, [1]);
    });

    testWidgets('Guided tour starts the walkthrough', (tester) async {
      final calls = await _openTour(tester);
      await _toLastSlide(tester);

      await _pressLaunchOption(tester, 'Guided tour');

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

    const titles = ['Models', 'Downloads & speed', 'Chat', 'Local API server'];

    for (var step = 0; step < titles.length; step++) {
      testWidgets('step ${step + 1} explains ${titles[step]}', (tester) async {
        await pumpDock(tester, step);
        expect(find.text('STEP ${step + 1} OF 4'), findsOneWidget);
        expect(find.text(titles[step]), findsOneWidget);
      });
    }

    testWidgets('the first step has no Back button', (tester) async {
      await pumpDock(tester, 0);
      expect(find.text('Back'), findsNothing);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Next moves forward', (tester) async {
      final (steps, dismissals) = await pumpDock(tester, 1);
      await tester.tap(find.text('Next'));
      expect(steps, [2]);
      expect(dismissals, isEmpty);
    });

    testWidgets('Back moves back', (tester) async {
      final (steps, _) = await pumpDock(tester, 2);
      await tester.tap(find.text('Back'));
      expect(steps, [1]);
    });

    testWidgets('Finish on the last step dismisses the dock', (tester) async {
      final (steps, dismissals) = await pumpDock(tester, 3);
      expect(find.text('Next'), findsNothing);
      await tester.tap(find.text('Finish'));
      expect(steps, isEmpty);
      expect(dismissals, hasLength(1));
    });

    testWidgets('the close icon exits the tour', (tester) async {
      final (_, dismissals) = await pumpDock(tester, 1);
      await tester.tap(find.byTooltip('Exit'));
      expect(dismissals, hasLength(1));
    });
  });
}
