import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/ui/widgets/coach_mark_targets.dart';
import 'package:local_llm/ui/widgets/spotlight_coach_marks.dart';

/// The panel's top edge. 'App Tour' is the first line inside it, so it tracks
/// the panel without depending on the panel's height.
double _panelTop(WidgetTester tester) =>
    tester.getTopLeft(find.text('App Tour')).dy;

void main() {
  late GlobalKey nearTop;
  late GlobalKey nearBottom;
  late BuildContext ctx;

  Future<void> pumpHost(WidgetTester tester) async {
    nearTop = GlobalKey();
    nearBottom = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return Stack(
                children: [
                  Positioned(
                    top: 100,
                    left: 20,
                    child: SizedBox(key: nearTop, width: 120, height: 40),
                  ),
                  Positioned(
                    top: 500,
                    left: 20,
                    child: SizedBox(key: nearBottom, width: 120, height: 40),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('panel holds position while the next target resolves', (
    tester,
  ) async {
    await pumpHost(tester);

    unawaited(
      SpotlightCoachMarks.show(
        context: ctx,
        steps: [
          SpotlightCoachStep(
            targetKey: nearTop,
            title: 'One',
            message: 'first',
          ),
          SpotlightCoachStep(
            targetKey: nearBottom,
            title: 'Two',
            message: 'second',
            // Stands in for the real tour's tab switch, which is what opened
            // the window where the panel used to sit at the top.
            beforeShow: () =>
                Future<void>.delayed(const Duration(milliseconds: 260)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final atStepOne = _panelTop(tester);
    expect(atStepOne, greaterThan(100), reason: 'panel sits by its target');

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The regression: with the rect cleared on step change, the panel fell to
    // y=22 here for the whole beforeShow window, then snapped back down.
    expect(
      _panelTop(tester),
      atStepOne,
      reason: 'panel must not jump while the next target resolves',
    );

    await tester.pumpAndSettle();
    expect(
      _panelTop(tester),
      greaterThan(atStepOne),
      reason: 'panel ends up at the lower target',
    );
  });

  testWidgets('panel travels smoothly rather than snapping', (tester) async {
    await pumpHost(tester);

    unawaited(
      SpotlightCoachMarks.show(
        context: ctx,
        steps: [
          SpotlightCoachStep(
            targetKey: nearTop,
            title: 'One',
            message: 'first',
          ),
          SpotlightCoachStep(
            targetKey: nearBottom,
            title: 'Two',
            message: 'second',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final atStepOne = _panelTop(tester);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));

    // Mid-flight: past the start, short of the destination.
    final midFlight = _panelTop(tester);
    await tester.pumpAndSettle();
    final atStepTwo = _panelTop(tester);

    expect(midFlight, greaterThan(atStepOne));
    expect(midFlight, lessThan(atStepTwo));
  });

  /// Drives [action] while the test pumps frames for it.
  ///
  /// The reveal animates and waits between steps, and neither finishes unless
  /// something is producing frames — awaiting it directly just hangs.
  Future<void> runWithFrames(
    WidgetTester tester,
    Future<void> Function() action,
  ) async {
    final done = action();
    await tester.pumpAndSettle();
    await done;
    await tester.pumpAndSettle();
  }

  testWidgets('reveals a target the list has not built yet', (tester) async {
    // The regression this guards: a card added to the top of the Models page
    // pushed the tour's step-2 target down far enough that the list had never
    // built it. With no element there is no context, so ensureVisible has
    // nothing to act on and the step silently points at nothing.
    final target = GlobalKey();
    final controller = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            controller: controller,
            itemCount: 40,
            itemBuilder: (context, index) => SizedBox(
              key: index == 25 ? target : null,
              height: 200,
              child: Text('row $index'),
            ),
          ),
        ),
      ),
    );

    // Far enough down that it does not exist yet.
    expect(target.currentContext, isNull);

    await runWithFrames(
      tester,
      () => revealCoachTarget(target, controller),
    );

    expect(target.currentContext, isNotNull,
        reason: 'scrolling to the target should have built it');
    final rect = tester.getRect(find.byKey(target));
    final screen = tester.getSize(find.byType(MaterialApp));
    expect(rect.top, greaterThanOrEqualTo(0.0));
    expect(rect.bottom, lessThanOrEqualTo(screen.height));
  });

  testWidgets('gives up quietly when the target never appears', (tester) async {
    // A filtered catalogue must cost a moment, not hang the tour.
    final missing = GlobalKey();
    final controller = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            controller: controller,
            itemCount: 20,
            itemBuilder: (context, index) =>
                SizedBox(height: 200, child: Text('row $index')),
          ),
        ),
      ),
    );

    await runWithFrames(
      tester,
      () => revealCoachTarget(missing, controller),
    );

    expect(missing.currentContext, isNull);
    expect(controller.offset, controller.position.maxScrollExtent);
  });

  testWidgets('does nothing when no list is attached', (tester) async {
    final key = GlobalKey();
    final controller = ScrollController();
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    // Must not throw on a controller with no clients.
    await revealCoachTarget(key, controller);
  });
}
