import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/l10n/l10n.dart';
import 'package:local_llm/ui/pages/splash_page.dart';
import 'package:local_llm/ui/widgets/app_tour_dialog.dart';
import 'package:local_llm/ui/widgets/made_in_erode.dart';
import 'package:local_llm/ui/widgets/onboarding_tour_screen.dart';
import 'package:local_llm/ui/widgets/spotlight_coach_marks.dart';
import 'package:local_llm/ui/widgets/welcome_tour_sheet.dart';

import 'helpers/fonts.dart';

/// The Tamil strings, read from the generated class so the test follows the
/// ARB rather than repeating it.
final _ta = lookupAppLocalizations(const Locale('ta'));

/// A small phone: 360x780 logical pixels.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _tamilApp({required Widget home}) => MaterialApp(
  locale: const Locale('ta'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// Pumps [home] in a Tamil app with a button that opens whatever [open] shows.
Future<void> _openFrom(
  WidgetTester tester,
  Future<void> Function(BuildContext context) open,
) async {
  await tester.pumpWidget(
    _tamilApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => open(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRoboto);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('onboarding tour renders every slide in Tamil without overflow', (
    tester,
  ) async {
    _phone(tester);
    await _openFrom(
      tester,
      (context) => OnboardingTourScreen.show(context: context),
    );

    final tags = [
      _ta.onboardingPrivateTag,
      _ta.onboardingCatalogTag,
      _ta.onboardingGpuTag,
      _ta.onboardingStudioTag,
      _ta.onboardingServerTag,
    ];
    expect(find.text(_ta.commonSkip), findsOneWidget);
    expect(find.text(_ta.onboardingPrivateBullet1), findsOneWidget);
    for (var i = 0; i < tags.length; i++) {
      expect(find.text(tags[i]), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (i < tags.length - 1) {
        await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text(_ta.onboardingStartButton), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('app tour dialog renders every slide in Tamil without overflow', (
    tester,
  ) async {
    _phone(tester);
    await _openFrom(tester, (context) => AppTourDialog.show(context: context));

    expect(find.text(_ta.tourBadge), findsOneWidget);
    expect(find.text(_ta.tourOnDeviceTitle), findsOneWidget);
    expect(find.text(_ta.commonSkip), findsOneWidget);
    expect(find.byTooltip(_ta.tourCloseTooltip), findsOneWidget);

    for (var stage = 1; stage <= 5; stage++) {
      expect(find.text(_ta.tourStageLabel(stage, 5)), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (stage < 5) {
        await tester.tap(find.text(_ta.tourNextStep));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text(_ta.tourOptionLiveButton), findsOneWidget);
    expect(find.text(_ta.tourCompleteTour), findsOneWidget);
    expect(find.text(_ta.commonBack), findsOneWidget);
  });

  testWidgets('live tour dock renders every step in Tamil without overflow', (
    tester,
  ) async {
    _phone(tester);
    for (var step = 0; step < 4; step++) {
      await tester.pumpWidget(
        _tamilApp(
          home: Scaffold(
            body: LiveGuidedTourDock(
              step: step,
              onStepChanged: (_) {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_ta.tourDockStep(step + 1, 4)), findsOneWidget);
      expect(find.text(_ta.tourExitTour), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(find.text(_ta.tourDockServerTitle), findsOneWidget);
    expect(find.text(_ta.tourFinishTour), findsOneWidget);
  });

  testWidgets('welcome sheet renders in Tamil without overflow', (
    tester,
  ) async {
    _phone(tester);
    await _openFrom(
      tester,
      (context) => WelcomeTourSheet.show(
        context: context,
        onStartTour: () {},
        onBrowseModels: () {},
        onStartChat: () {},
      ),
    );

    expect(find.text(_ta.tourWelcomeTitle), findsOneWidget);
    expect(find.text(_ta.tourWelcomeOfflineBadge), findsOneWidget);
    expect(find.text(_ta.tourWelcomePrivateTitle), findsOneWidget);
    expect(find.text(_ta.tourWelcomeStartTour), findsOneWidget);
    expect(find.text(_ta.tourWelcomeSkipToChat), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spotlight panel renders in Tamil without overflow', (
    tester,
  ) async {
    _phone(tester);
    final target = GlobalKey();
    await _openFrom(
      tester,
      (context) => SpotlightCoachMarks.show(
        context: context,
        steps: [
          SpotlightCoachStep(targetKey: target, title: 'one', message: 'm'),
          SpotlightCoachStep(targetKey: target, title: 'two', message: 'm'),
        ],
      ),
    );
    // The target never resolves here; the panel still lays out.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(_ta.tourAppTour), findsOneWidget);
    expect(find.text(_ta.commonSkip), findsOneWidget);
    expect(find.text(_ta.commonNext), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash and credit name Erode in Tamil', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_tamilApp(home: const SplashPage()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(_ta.splashTagline), findsOneWidget);
    expect(
      find.text(_ta.splashCraftedIn(_ta.splashPlace), findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _tamilApp(home: const Scaffold(body: Center(child: MadeInErode()))),
    );
    expect(find.text(_ta.brandPlace), findsOneWidget);
    expect(find.text('Erode, Tamilnadu'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
