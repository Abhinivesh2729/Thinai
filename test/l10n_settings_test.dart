import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/chat/system_prompt.dart';
import 'package:local_llm/l10n/l10n.dart';
import 'package:local_llm/llm/generation_settings.dart';
import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/about_page.dart';
import 'package:local_llm/ui/pages/benchmark_page.dart';
import 'package:local_llm/ui/pages/settings_page.dart';
import 'package:local_llm/ui/pages/system_prompt_page.dart';

const _systemPromptKey = 'chat_system_prompt_v1';

Future<ProviderContainer> _pumpTamil(
  WidgetTester tester,
  Widget page, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      deviceProfileProvider.overrideWith(
        (ref) async => const DeviceProfile(cores: 8),
      ),
      appVersionProvider.overrideWith((ref) async => '2.4.0 (13)'),
      modelListProvider.overrideWith((ref) async => const <LocalModel>[]),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('ta'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

void main() {
  setUpAll(() async {
    // Load the settings store once in the real zone; see benchmark_page_test.
    SharedPreferences.setMockInitialValues({});
    await GenerationSettingsStore.instance.ensureLoaded();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Tamil UI renders', () {
    testWidgets('settings hub', (tester) async {
      await _pumpTamil(tester, const SettingsPage());
      expect(tester.takeException(), isNull);
      expect(find.text('அமைப்புகள்'), findsOneWidget);
      expect(find.text('தோற்றம்'), findsOneWidget);
      expect(find.text('சிஸ்டம் ப்ராம்ப்ட்'), findsOneWidget);
      expect(find.text('பற்றி & வழிகாட்டல்'), findsOneWidget);
      expect(find.text('Appearance'), findsNothing);
    });

    testWidgets('appearance', (tester) async {
      await _pumpTamil(tester, const AppearanceSettingsPage());
      expect(tester.takeException(), isNull);
      expect(find.text('தோற்றம்'), findsOneWidget);
      expect(find.text('மொழி'), findsOneWidget);
      expect(find.text('தீம்'), findsOneWidget);
      expect(find.text('அரட்டையில் இணையத் தேடல்'), findsOneWidget);
    });

    testWidgets('about', (tester) async {
      await _pumpTamil(tester, const AboutPage());
      expect(tester.takeException(), isNull);
      expect(find.text('Thinai பற்றி'), findsOneWidget);
      expect(find.text('அடிப்படைத் தூண்கள்'), findsOneWidget);
      expect(find.text('v2.4.0 (13) · சாதனத்திலேயே இயங்கும் தனிப்பட்ட AI'),
          findsOneWidget);
      // Technical values stay in English.
      expect(find.text('GGUF (Q4_K_M, Q8_0, BF16)'), findsOneWidget);
    });

    testWidgets('system prompt', (tester) async {
      await _pumpTamil(tester, const SystemPromptPage());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('சிஸ்டம் ப்ராம்ப்ட்'), findsOneWidget);
      expect(find.text('சேமி'), findsOneWidget);
      expect(find.text('இயல்புநிலைக்கு மீட்டமை'), findsOneWidget);
      expect(find.textContaining('எழுத்துகள்'), findsOneWidget);
    });

    testWidgets('benchmark with no models', (tester) async {
      await _pumpTamil(tester, const BenchmarkPage());
      expect(tester.takeException(), isNull);
      expect(find.text('பெஞ்ச்மார்க்'), findsOneWidget);
      expect(find.text('அளவிட மாடல்கள் இல்லை'), findsOneWidget);
    });

    testWidgets('benchmark with a model', (tester) async {
      await _pumpTamil(
        tester,
        const BenchmarkPage(),
        overrides: [
          modelListProvider.overrideWith(
            (ref) async => [
              LocalModel(
                id: 'alpha',
                displayName: 'alpha.gguf',
                path: '/nowhere/alpha.gguf',
                sizeBytes: 1 << 30,
                modifiedAt: DateTime(2026),
              ),
            ],
          ),
        ],
      );
      expect(tester.takeException(), isNull);
      expect(find.text('பெஞ்ச்மார்க் இயக்கு'), findsOneWidget);
      expect(find.text('tokens / வினாடி'), findsOneWidget);
      expect(find.text('சும்மா உள்ளது'), findsOneWidget);
    });
  });

  group('AppLanguageController', () {
    test('starts on system when nothing was saved', () async {
      final c = AppLanguageController();
      await Future<void>.delayed(Duration.zero);
      expect(c.state, AppLanguage.system);
    });

    test('persists the choice under app_language', () async {
      await AppLanguageController().set(AppLanguage.tamil);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'tamil');

      final reloaded = AppLanguageController();
      await Future<void>.delayed(Duration.zero);
      expect(reloaded.state, AppLanguage.tamil);
    });

    test('an unknown stored value falls back to system', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'klingon'});
      final c = AppLanguageController();
      await Future<void>.delayed(Duration.zero);
      expect(c.state, AppLanguage.system);
    });
  });

  group('isTamilUiProvider', () {
    Future<bool> isTamil(AppLanguage language, String systemCode) async {
      final container = ProviderContainer(
        overrides: [systemLanguageCodeProvider.overrideWithValue(systemCode)],
      );
      addTearDown(container.dispose);
      // Let the controller finish its initial load before setting.
      container.read(appLanguageProvider);
      await Future<void>.delayed(Duration.zero);
      await container.read(appLanguageProvider.notifier).set(language);
      return container.read(isTamilUiProvider);
    }

    test('system follows the phone language', () async {
      expect(await isTamil(AppLanguage.system, 'ta'), isTrue);
      expect(await isTamil(AppLanguage.system, 'en'), isFalse);
    });

    test('english is never Tamil', () async {
      expect(await isTamil(AppLanguage.english, 'ta'), isFalse);
    });

    test('tamil is always Tamil', () async {
      expect(await isTamil(AppLanguage.tamil, 'en'), isTrue);
    });
  });

  group('SystemPromptController(tamil: true)', () {
    test('defaults to the Tamil prompt', () async {
      final c = SystemPromptController(tamil: true);
      expect(await c.current(), kDefaultSystemPromptTamil);
      expect(c.defaultPrompt, kDefaultSystemPromptTamil);
      expect(c.isDefault, isTrue);
    });

    test('a stored custom prompt still wins', () async {
      SharedPreferences.setMockInitialValues({
        _systemPromptKey: 'Be brief.',
      });
      final c = SystemPromptController(tamil: true);
      expect(await c.current(), 'Be brief.');
      expect(c.isDefault, isFalse);
    });
  });
}
