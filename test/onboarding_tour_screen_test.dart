import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/ui/widgets/onboarding_tour_screen.dart';

const _tags = [
  'PRIVATE & OFFLINE',
  'MODEL CATALOG',
  'GPU ACCELERATION',
  'IMAGES & DOCUMENTS',
  'LOCAL API',
];

Finder get _nextArrow => find.byIcon(Icons.arrow_forward_rounded);
Finder get _backArrow => find.byIcon(Icons.arrow_back_rounded);

/// Opens the tour on top of a home page, the way first launch does, and
/// returns how many times it reported completion.
Future<List<int>> _openTour(WidgetTester tester) async {
  final completions = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => OnboardingTourScreen.show(
              context: context,
              onComplete: () => completions.add(1),
            ),
            child: const Text('home'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('home'));
  await tester.pumpAndSettle();
  return completions;
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(_nextArrow);
  await tester.pumpAndSettle();
}

Future<bool?> _seen() async => (await SharedPreferences.getInstance()).getBool(
  OnboardingTourScreen.tourSeenKey,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('starts on the privacy slide with Back hidden', (tester) async {
    await _openTour(tester);

    expect(find.text(_tags.first), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(
      find.text('Nothing leaves your device. Works in Airplane mode.'),
      findsOneWidget,
    );
    final back = tester.widget<IgnorePointer>(
      find.ancestor(of: _backArrow, matching: find.byType(IgnorePointer)).first,
    );
    expect(back.ignoring, isTrue);
  });

  testWidgets('Next walks through every slide', (tester) async {
    await _openTour(tester);

    for (final tag in _tags.skip(1)) {
      await _next(tester);
      expect(find.text(tag), findsOneWidget);
    }
    expect(find.text('Get started'), findsOneWidget);
    expect(await _seen(), isNull, reason: 'nothing is saved before the end');
  });

  testWidgets('Back returns to the previous slide', (tester) async {
    await _openTour(tester);
    await _next(tester);
    await _next(tester);

    await tester.tap(_backArrow);
    await tester.pumpAndSettle();

    expect(find.text(_tags[1]), findsOneWidget);
  });

  testWidgets('tapping a dot jumps to that slide', (tester) async {
    await _openTour(tester);

    final dots = find.descendant(
      of: find.byType(Row),
      matching: find.byType(GestureDetector),
    );
    // The five page dots are the only bare gesture detectors in the dock.
    final dotList = dots.evaluate().where((e) {
      final w = e.widget as GestureDetector;
      return w.child is AnimatedContainer;
    }).toList();
    expect(dotList, hasLength(5));

    await tester.tap(find.byWidget(dotList[3].widget));
    await tester.pumpAndSettle();

    expect(find.text(_tags[3]), findsOneWidget);
  });

  testWidgets('Skip saves the tour as seen and closes it', (tester) async {
    final completions = await _openTour(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(await _seen(), isTrue);
    expect(completions, [1]);
    expect(find.byType(OnboardingTourScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Next on the last slide finishes the tour', (tester) async {
    final completions = await _openTour(tester);
    for (var i = 0; i < 4; i++) {
      await _next(tester);
    }

    await _next(tester);

    expect(await _seen(), isTrue);
    expect(completions, [1]);
    expect(find.byType(OnboardingTourScreen), findsNothing);
  });

  testWidgets('Get started finishes the tour', (tester) async {
    final completions = await _openTour(tester);
    for (var i = 0; i < 4; i++) {
      await _next(tester);
    }

    await tester.ensureVisible(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(await _seen(), isTrue);
    expect(completions, [1]);
  });

  testWidgets('finishing as the root page still saves and reports', (
    tester,
  ) async {
    // With nothing underneath there is no route to pop back to.
    final completions = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingTourScreen(onComplete: () => completions.add(1)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(await _seen(), isTrue);
    expect(completions, [1]);
    expect(find.byType(OnboardingTourScreen), findsOneWidget);
  });
}
