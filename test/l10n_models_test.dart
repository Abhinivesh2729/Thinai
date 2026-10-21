import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/l10n/l10n.dart';
import 'package:local_llm/llm/generation_settings.dart';
import 'package:local_llm/models_repo/catalog.dart';
import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/model_skills.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/models_repo/recommender.dart';
import 'package:local_llm/models_repo/use_cases.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/models_page.dart';
import 'package:local_llm/ui/widgets/model_advisor.dart';
import 'package:local_llm/ui/widgets/model_settings_sheet.dart';

import 'context_limits_test.dart' show ggufHeader;
import 'helpers/fonts.dart';

const _gib = 1024 * 1024 * 1024;

final _ta = lookupAppLocalizations(const Locale('ta'));
final _en = lookupAppLocalizations(const Locale('en'));

const _phone = DeviceProfile(
  totalRamBytes: 8 * _gib,
  availableRamBytes: 5 * _gib,
  cores: 8,
);

late Directory _dir;

/// Holds Tamil from the first frame, the way a saved choice does once loaded.
class _TamilLanguage extends AppLanguageController {
  _TamilLanguage() {
    state = AppLanguage.tamil;
  }
}

Widget _app(Widget home, {Locale locale = const Locale('ta')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ThemeData(fontFamily: 'Roboto'),
  home: home,
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpModelsPage(
  WidgetTester tester, {
  required List<Override> language,
  List<LocalModel> installed = const [],
}) async {
  tester.view.physicalSize = const Size(420, 4000) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        modelListProvider.overrideWith((ref) async => installed),
        partialDownloadsProvider.overrideWith(
          (ref) async => const <PartialDownload>[],
        ),
        missingProjectorsProvider.overrideWith((ref) async => <String>{}),
        deviceProfileProvider.overrideWith((ref) async => _phone),
        ...language,
      ],
      child: _app(const ModelsPage()),
    ),
  );
  await _settle(tester);
}

void main() {
  setUpAll(() async {
    await loadRoboto();
    _dir = Directory.systemTemp.createTempSync('l10n_models_test');
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => _dir.path,
        );
    GenerationSettingsStore.instance.deviceForTesting =
        DeviceProfile.unknownProfile;
  });

  tearDownAll(() => _dir.deleteSync(recursive: true));

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Models page in Tamil', () {
    testWidgets('opens on the Tamil goal when the app language is Tamil', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'app_language': 'tamil'});
      await _pumpModelsPage(
        tester,
        language: [appLanguageProvider.overrideWith((ref) => _TamilLanguage())],
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_ta.navModels), findsOneWidget);
      expect(
        find.text(_ta.modelsTargeting(_ta.modelsUseCaseTamil)),
        findsOneWidget,
      );
      // The goal chip in the filter row shows the Tamil goal too.
      expect(find.text(_ta.modelsUseCaseTamil), findsWidgets);
      expect(find.text(_ta.modelsChange), findsOneWidget);
      expect(find.text(_ta.modelsTopPicks), findsOneWidget);
      // Nothing from the English copy leaks through.
      expect(find.text('Targeting: Tamil'), findsNothing);
      expect(find.text(_en.modelsTopPicks), findsNothing);
    });

    testWidgets('follows a Tamil phone when the language is left on System', (
      tester,
    ) async {
      await _pumpModelsPage(
        tester,
        language: [systemLanguageCodeProvider.overrideWithValue('ta')],
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text(_ta.modelsTargeting(_ta.modelsUseCaseTamil)),
        findsOneWidget,
      );
    });

    testWidgets('opens with no goal in English', (tester) async {
      await _pumpModelsPage(
        tester,
        language: [isTamilUiProvider.overrideWithValue(false)],
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining(_ta.modelsTargeting('')), findsNothing);
      expect(find.text(_ta.modelsGoals), findsOneWidget);
      expect(find.text(_ta.modelsFeaturedTitle), findsOneWidget);
      expect(find.text(_ta.modelsExploreModels), findsOneWidget);
    });

    testWidgets('filter menu, goal sheet and Model Manager are in Tamil', (
      tester,
    ) async {
      await _pumpModelsPage(
        tester,
        language: [isTamilUiProvider.overrideWithValue(false)],
      );

      await tester.tap(find.text(_ta.modelsFilterAll));
      await tester.pumpAndSettle();
      expect(find.text(_ta.modelsFilterVision), findsWidgets);
      expect(find.text(_ta.modelsFilterInstalled), findsOneWidget);
      await tester.tap(find.text(_ta.modelsFilterInstalled));
      await tester.pumpAndSettle();
      expect(find.text(_ta.modelsNoneInstalledYet), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(_ta.modelsGoals));
      await tester.pumpAndSettle();
      expect(find.text(_ta.modelsChooseGoal), findsOneWidget);
      for (final useCase in UseCase.values) {
        expect(find.text(useCase.localizedBlurb(_ta)), findsOneWidget);
      }
      await tester.tap(find.text(_ta.modelsUseCaseCoding));
      await tester.pumpAndSettle();
      expect(find.text(_ta.modelsTopPicks), findsOneWidget);
      expect(
        find.text(_ta.modelsTargeting(_ta.modelsUseCaseCoding)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip(_ta.modelsManagerTitle));
      await tester.pumpAndSettle();
      expect(find.text(_ta.modelsManagerTitle), findsOneWidget);
      expect(find.text(_ta.modelsNoneInstalled), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('download confirmation is in Tamil', (tester) async {
      await _pumpModelsPage(
        tester,
        language: [isTamilUiProvider.overrideWithValue(false)],
      );
      final featured = featuredModel!;
      await tester.tap(find.text(featured.approxSize).first);
      await tester.pumpAndSettle();

      expect(find.text(_ta.modelsConfirmDownloadTitle), findsOneWidget);
      expect(find.text(_ta.commonCancel), findsOneWidget);
      expect(find.text(_ta.commonDownload), findsOneWidget);
      await tester.tap(find.text(_ta.commonCancel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Model advisor in Tamil', () {
    testWidgets('asks the question and explains the pick in Tamil', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 2400) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: ModelAdvisor(
                speed: SpeedKnowledge(device: _phone),
                installedCatalogIds: const {},
                onDownload: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text(_ta.modelsAdvisorPrompt), findsOneWidget);
      expect(find.text(_ta.modelsUseCaseFastChat), findsOneWidget);

      await tester.tap(find.text(_ta.modelsUseCaseFastChat));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(_ta.modelsTopPick), findsOneWidget);
      expect(
        find.text(Skill.excellent.localizedReason(_ta, UseCase.fastChat)),
        findsOneWidget,
      );
      expect(find.text('Excellent for quick conversations'), findsNothing);
      expect(find.text(_ta.modelsFitComfortable), findsOneWidget);
    });
  });

  group('Model settings sheet in Tamil', () {
    testWidgets('labels and the context cap read in Tamil', (tester) async {
      final file = File('${_dir.path}/tamil-sheet.gguf')
        ..writeAsBytesSync(
          ggufHeader([
            ('general.architecture', 8, 'qwen2'),
            ('qwen2.context_length', 4, 32768),
            ('qwen2.block_count', 4, 24),
            ('qwen2.attention.head_count', 4, 14),
            ('qwen2.attention.head_count_kv', 4, 2),
            ('qwen2.embedding_length', 4, 896),
          ]),
        );
      final model = LocalModel(
        id: 'tamil-sheet',
        displayName: 'tamil-sheet',
        path: file.path,
        sizeBytes: file.lengthSync(),
        modifiedAt: DateTime(2026),
      );
      await GenerationSettingsStore.instance.ensureLoaded();

      tester.view.physicalSize = const Size(420, 2000) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(Scaffold(body: ModelSettingsSheet(model: model))),
      );
      final title = find.text(_ta.modelsSettingsTitle);
      for (var i = 0; i < 100 && title.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
      expect(title, findsOneWidget);
      expect(find.text(_ta.modelsSettingsResetDefaults), findsOneWidget);
      expect(find.text(_ta.modelsSettingsPrecise), findsOneWidget);
      expect(find.text(_ta.modelsSettingsCapTraining('32K')), findsOneWidget);
      expect(find.text('Model settings'), findsNothing);
    });
  });

  group('labels built outside a widget', () {
    test('every goal, fit and rating has a Tamil wording', () {
      for (final useCase in UseCase.values) {
        expect(useCase.localizedLabel(_en), useCase.label);
        expect(useCase.localizedBlurb(_en), useCase.blurb);
        expect(useCase.localizedLabel(_ta), isNot(useCase.label));
        for (final skill in Skill.values) {
          expect(skill.localizedReason(_ta, useCase), isNotEmpty);
        }
      }
      for (final fit in RamFit.values) {
        expect(fit.localizedLabel(_en), fit.label);
        expect(fit.localizedLabel(_ta), isNot(fit.label));
      }
    });

    test('English reasons match the strings the recommender already gives', () {
      for (final useCase in UseCase.values) {
        final result = recommend(useCase, _phone);
        for (final pick in result.picks) {
          expect(pick.localizedReasons(_en), pick.reasons);
          expect(pick.localizedReasons(_ta), hasLength(pick.reasons.length));
        }
        expect(result.localizedCaveat(_en), result.caveat);
      }
    });

    test('caveats are worded per job in both languages', () {
      // A phone with nothing to spare: nothing fits, so a caveat is given.
      const tiny = DeviceProfile(
        totalRamBytes: _gib ~/ 4,
        availableRamBytes: _gib ~/ 8,
        cores: 4,
      );
      final result = recommend(UseCase.reasoning, tiny);
      expect(result.caveat, isNotNull);
      expect(result.localizedCaveat(_en), result.caveat);
      expect(result.localizedCaveat(_ta), isNot(result.caveat));
      expect(chatCatalog, isNotEmpty);
    });
  });
}
