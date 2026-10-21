import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/l10n/l10n.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/settings_page.dart';
import 'package:local_llm/ui/widgets/tamil_glossary_dialog.dart';

Future<void> _pumpAppearance(
  WidgetTester tester, {
  String phoneLanguage = 'en',
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [systemLanguageCodeProvider.overrideWithValue(phoneLanguage)],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          locale: ref.watch(appLocaleProvider),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppearanceSettingsPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pickLanguage(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButton<AppLanguage>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('switching to Tamil shows the glossary', (tester) async {
    await _pumpAppearance(tester);
    await _pickLanguage(tester, 'தமிழ்');

    expect(find.byType(TamilGlossaryDialog), findsOneWidget);
    for (final (english, tamil) in tamilGlossary) {
      expect(find.text(english), findsWidgets);
      expect(find.text(tamil), findsWidgets);
    }

    await tester.tap(find.text('சரி'));
    await tester.pumpAndSettle();
    expect(find.byType(TamilGlossaryDialog), findsNothing);
  });

  testWidgets('switching back to English does not', (tester) async {
    SharedPreferences.setMockInitialValues({'flutter.app_language': 'tamil'});
    await _pumpAppearance(tester);
    await _pickLanguage(tester, 'English');

    expect(find.byType(TamilGlossaryDialog), findsNothing);
  });

  testWidgets('System on a Tamil phone counts as switching to Tamil', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'flutter.app_language': 'english'});
    await _pumpAppearance(tester, phoneLanguage: 'ta');
    await _pickLanguage(tester, 'System');

    expect(find.byType(TamilGlossaryDialog), findsOneWidget);
  });

  testWidgets('the Glossary row opens it in either language', (tester) async {
    await _pumpAppearance(tester);
    await tester.tap(find.text('Glossary'));
    await tester.pumpAndSettle();

    expect(find.byType(TamilGlossaryDialog), findsOneWidget);
  });
}
