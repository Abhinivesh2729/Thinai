import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinai_tamil_evals/thinai_tamil_evals.dart';

import 'package:local_llm/l10n/l10n.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/tamil_eval_page.dart';
import 'package:local_llm/ui/widgets/tamil_dial.dart';

import 'helpers/fonts.dart';

LocalModel _model(String id) => LocalModel(
  id: id,
  displayName: '$id.gguf',
  path: '/nowhere/$id.gguf',
  sizeBytes: 1 << 30,
  modifiedAt: DateTime(2026, 1, 1),
);

/// Answers every item from [answer], one delta each, after a microtask.
class _ScriptedGenerator implements EvalGenerator {
  _ScriptedGenerator(this.answer, {this.hangAt});

  final String Function(EvalPrompt prompt) answer;

  /// Item index at which the generator stops answering, to test stopping.
  final int? hangAt;
  var calls = 0;
  var cancelled = false;

  @override
  Stream<String> generate(EvalPrompt prompt) {
    final index = calls++;
    late final StreamController<String> c;
    c = StreamController<String>(
      onListen: () {
        if (index == hangAt) return;
        Future<void>.delayed(const Duration(milliseconds: 5), () {
          c.add(answer(prompt));
          c.close();
        });
      },
      // Only the item left hanging can be cancelled: the rest have finished.
      onCancel: () {
        if (index == hangAt) cancelled = true;
      },
    );
    return c.stream;
  }
}

class _FailingGenerator implements EvalGenerator {
  @override
  Stream<String> generate(EvalPrompt prompt) =>
      Stream.error(StateError('model failed to load'));
}

/// Right on every multiple-choice item, the reference elsewhere.
String _perfect(EvalPrompt prompt) {
  for (final task in tamilV1().tasks) {
    for (final item in task.items) {
      final p = buildPrompt(task, item);
      if (p.user != prompt.user || p.system != prompt.system) continue;
      return switch (item) {
        McqItem() => kOptionLetters[item.answer],
        TranslateItem() => item.references.first,
        QaItem() => item.answers.first,
        WritingItem() =>
          'மழை நன்றி காலை பறவை பிடிக்கும் வீட்டுக்கு பள்ளி. எனக்கு உணவு பிடிக்கும்.',
        CorrectionItem() => item.reference,
      };
    }
  }
  return '';
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  EvalGenerator? generator,
  List<LocalModel>? models,
  Locale locale = const Locale('en'),
  Size size = const Size(360, 2600),
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      modelListProvider.overrideWith(
        (ref) async => models ?? [_model('lfm'), _model('gemma')],
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(fontFamily: 'Roboto'),
        darkTheme: ThemeData.dark(),
        home: TamilEvalPage(
          generatorFor: (_) => generator ?? _ScriptedGenerator(_perfect),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

Future<void> _finishRun(WidgetTester tester) async {
  for (var i = 0; i < 200 && find.text('Running…').evaluate().isNotEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.text('Running…'), findsNothing, reason: 'the run never ended');
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUpAll(loadRoboto);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('starts idle with the intro and an empty dial', (tester) async {
    await _pump(tester);
    expect(find.text('Tamil eval'), findsOneWidget);
    expect(find.text('Not tested yet'), findsOneWidget);
    expect(find.textContaining('60 short questions'), findsOneWidget);
    expect(find.text('Start Tamil eval'), findsOneWidget);
    expect(find.byTooltip('Stop'), findsNothing);
    expect(find.text('Understanding'), findsOneWidget);
    expect(find.text('Tested on this phone'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('runs every question, scores it and saves the report', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.tap(find.text('Start Tamil eval'));
    await tester.pump();
    expect(find.text('Running…'), findsOneWidget);
    expect(find.byTooltip('Stop'), findsOneWidget);

    await _finishRun(tester);
    expect(tester.takeException(), isNull);

    final dial = tester.widget<TamilDial>(find.byType(TamilDial));
    expect(dial.mode, TamilDialMode.score);
    expect(dial.readout, '100');
    expect(find.text('Strong'), findsOneWidget);
    expect(find.text('Run again'), findsOneWidget);
    expect(find.text('8 of 8 right'), findsNWidgets(3));

    final saved = container.read(tamilEvalResultsProvider)['lfm']!;
    expect(saved.overall, 100);
    expect(saved.items, hasLength(60));
    expect(container.read(tamilScoreProvider('lfm')), 100);
    expect(container.read(tamilScoreProvider('gemma')), isNull);
  });

  testWidgets('a task opens its questions with replies and answers', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Start Tamil eval'));
    await _finishRun(tester);

    await tester.tap(find.text('Grammar'));
    await tester.pumpAndSettle();
    expect(find.text('சரியான வாக்கியம் எது?'), findsOneWidget);
    // The perfect run chose C, so the reply and the expected answer match.
    expect(
      find.textContaining('C. அவர்கள் நேற்று வந்தார்கள்.'),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compares every model tested on this phone', (tester) async {
    final container = await _pump(tester);
    await container
        .read(tamilEvalResultsProvider.notifier)
        .record(
          EvalReport.score(
            dataset: tamilV1(),
            modelId: 'gemma',
            startedAt: DateTime(2026),
            elapsed: const Duration(seconds: 90),
            items: const [],
          ),
        );
    await tester.tap(find.text('Start Tamil eval'));
    await _finishRun(tester);
    expect(find.text('Tested on this phone'), findsOneWidget);

    await tester.tap(find.text('gemma.gguf').last);
    await tester.pump(const Duration(seconds: 2));
    final dial = tester.widget<TamilDial>(find.byType(TamilDial));
    expect(dial.readout, '0');
    expect(find.text('Little Tamil'), findsOneWidget);
  });

  testWidgets('stopping discards the run', (tester) async {
    final gen = _ScriptedGenerator(_perfect, hangAt: 5);
    final container = await _pump(tester, generator: gen);
    await tester.tap(find.text('Start Tamil eval'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(find.text('5/60'), findsOneWidget);
    expect(find.text('Live reply'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(gen.cancelled, isTrue);
    expect(find.text('Stopped. Nothing was saved.'), findsOneWidget);
    expect(container.read(tamilEvalResultsProvider), isEmpty);
  });

  testWidgets('asks before leaving a run, and stays when told to', (
    tester,
  ) async {
    final gen = _ScriptedGenerator(_perfect, hangAt: 2);
    tester.view.physicalSize = const Size(360, 2600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        modelListProvider.overrideWith((ref) async => [_model('lfm')]),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: const Text('models'),
        ),
      ),
    );
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => TamilEvalPage(generatorFor: (_) => gen),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    await tester.tap(find.text('Start Tamil eval'));
    await tester.pump(const Duration(milliseconds: 100));

    // The repeating progress animations never settle, so time is pumped.
    unawaited(nav.maybePop());
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Stop the Tamil eval?'), findsOneWidget);
    await tester.tap(find.text('Keep running'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Running…'), findsOneWidget);
    expect(gen.cancelled, isFalse);

    unawaited(nav.maybePop());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Stop and leave'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(gen.cancelled, isTrue);
    expect(find.text('models'), findsOneWidget);
    expect(find.byType(TamilEvalPage), findsNothing);
  });

  testWidgets('a failed item ends the run with the error', (tester) async {
    await _pump(tester, generator: _FailingGenerator());
    await tester.tap(find.text('Start Tamil eval'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('model failed to load'), findsOneWidget);
    expect(find.text('Start Tamil eval'), findsOneWidget);
  });

  testWidgets('explains there is nothing to test without a model', (
    tester,
  ) async {
    await _pump(tester, models: const []);
    expect(find.text('No models to test'), findsOneWidget);
    expect(find.text('Start Tamil eval'), findsNothing);
  });

  for (final locale in const [Locale('en'), Locale('ta')]) {
    testWidgets('fits a small phone in ${locale.languageCode}', (tester) async {
      await _pump(tester, locale: locale, size: const Size(320, 3000));
      expect(tester.takeException(), isNull);
      final l10n = lookupAppLocalizations(locale);
      await tester.tap(find.text(l10n.tamilEvalRun));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      await _finishRunIn(tester, l10n);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _finishRunIn(WidgetTester tester, AppLocalizations l10n) async {
  for (
    var i = 0;
    i < 200 && find.text(l10n.tamilEvalRunning).evaluate().isNotEmpty;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(seconds: 2));
}
