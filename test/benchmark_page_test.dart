import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/llm/generation_settings.dart';
import 'package:local_llm/llm/llm_engine.dart';
import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/benchmark_page.dart';

/// Engine that replays a scripted stream instead of loading a model.
class _FakeEngine implements LlmEngine {
  /// Builds the stream for each `generate` call.
  Stream<LlmToken> Function() script = () => const Stream.empty();

  final prompts = <String>[];
  final modelPaths = <String?>[];
  var cancels = 0;

  @override
  Stream<LlmToken> generate(
    String prompt, {
    String? modelPath,
    GenerationOptions options = const GenerationOptions(),
  }) {
    prompts.add(prompt);
    modelPaths.add(modelPath);
    return script();
  }

  @override
  void cancelCurrent() => cancels++;

  @override
  void setActiveModel(String? path, {String? projectorPath}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LocalModel _model(String id, {int sizeBytes = 1 << 30}) => LocalModel(
  id: id,
  displayName: '$id.gguf',
  path: '/nowhere/$id.gguf',
  sizeBytes: sizeBytes,
  modifiedAt: DateTime(2026, 1, 1),
);

LlmToken _token(
  int tokens, {
  required String full,
  bool done = false,
  int stepMs = 250,
}) => LlmToken(
  delta: '',
  full: full,
  done: done,
  stats: LlmStats(
    tokens: tokens,
    timeToFirstToken: const Duration(milliseconds: 300),
    decodeTime: Duration(milliseconds: stepMs * (tokens - 1)),
    elapsed: Duration(milliseconds: 300 + stepMs * (tokens - 1)),
  ),
);

/// Five tokens a quarter second apart: 4 tok/s over a one second decode.
Stream<LlmToken> _steadyRun() => Stream.fromIterable([
  for (var i = 1; i <= 5; i++)
    _token(i, full: 'Neural networks learn $i', done: i == 5),
]);

const _eightGbPhone = DeviceProfile(
  totalRamBytes: 8 * 1024 * 1024 * 1024,
  availableRamBytes: 5 * 1024 * 1024 * 1024,
  cores: 8,
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Future<List<LocalModel>> Function()? models,
  _FakeEngine? engine,
  DeviceProfile device = _eightGbPhone,
}) async {
  // Tall enough that the whole page lays out without scrolling.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      modelListProvider.overrideWith(
        (ref) => models?.call() ?? Future.value([_model('alpha')]),
      ),
      deviceProfileProvider.overrideWith((ref) async => device),
      llmEngineProvider.overrideWithValue(engine ?? _FakeEngine()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: BenchmarkPage()),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

/// Lets the run finish. The settings store reads the model file with real
/// I/O (and a helper isolate), so real time has to pass between frames.
Future<void> _letRunFinish(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 400 && find.text('Running…').evaluate().isNotEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.text('Running…'), findsNothing, reason: 'the run never ended');
  // Let the gauge and history bars finish animating to their final values.
  await tester.pump(const Duration(seconds: 1));
}

String _selectedModelName(WidgetTester tester) {
  final dropdown = tester.widget<DropdownButton<String>>(
    find.byType(DropdownButton<String>),
  );
  return dropdown.value!;
}

void main() {
  setUpAll(() async {
    // The settings store caches its first load as a Future. Created inside one
    // test's fake-async zone, that Future never delivers in the next test, so
    // load it once here in the real zone.
    SharedPreferences.setMockInitialValues({});
    await GenerationSettingsStore.instance.ensureLoaded();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows a spinner while the installed models load', (
    tester,
  ) async {
    final never = Completer<List<LocalModel>>();
    await _pump(tester, models: () => never.future);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Run benchmark'), findsNothing);
  });

  testWidgets('reports a failure to list models', (tester) async {
    await _pump(tester, models: () => Future.error(StateError('disk gone')));
    expect(find.text('Error: Bad state: disk gone'), findsOneWidget);
  });

  testWidgets('explains there is nothing to measure without a model', (
    tester,
  ) async {
    await _pump(tester, models: () async => []);
    expect(find.text('No models to measure'), findsOneWidget);
    expect(find.text('Download a model to measure its speed.'), findsOneWidget);
    expect(find.text('Run benchmark'), findsNothing);
  });

  testWidgets('starts idle with empty readings', (tester) async {
    await _pump(tester);

    expect(find.text('Benchmark'), findsOneWidget);
    expect(find.text('0.0'), findsOneWidget);
    expect(find.text('tokens / second'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Run a benchmark to plot it'), findsOneWidget);
    expect(find.text('First token'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('-'), findsNWidgets(2));
    expect(find.text('Run benchmark'), findsOneWidget);
    expect(find.textContaining('Generates 128 tokens'), findsOneWidget);
    expect(find.byTooltip('Stop'), findsNothing);
    expect(find.text('This session'), findsNothing);
    expect(find.text('Sample output'), findsNothing);
  });

  testWidgets('defaults to the model loaded for chat', (tester) async {
    final container = await _pump(
      tester,
      models: () async => [_model('alpha'), _model('beta')],
    );
    expect(_selectedModelName(tester), 'alpha');
    // The page only adopts the active model before it has picked one, so a
    // fresh page is needed to see it.
    container.dispose();
    await tester.pumpWidget(const SizedBox());

    final engine = _FakeEngine();
    final second = ProviderContainer(
      overrides: [
        modelListProvider.overrideWith(
          (ref) async => [_model('alpha'), _model('beta')],
        ),
        deviceProfileProvider.overrideWith((ref) async => _eightGbPhone),
        llmEngineProvider.overrideWithValue(engine),
      ],
    );
    addTearDown(second.dispose);
    await second.read(activeModelIdProvider.notifier).set(_model('beta'));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: second,
        child: const MaterialApp(home: BenchmarkPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(_selectedModelName(tester), 'beta');
  });

  testWidgets('the model picker switches which model is measured', (
    tester,
  ) async {
    final engine = _FakeEngine()..script = _steadyRun;
    await _pump(
      tester,
      engine: engine,
      models: () async => [_model('alpha'), _model('beta')],
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('beta.gguf').last);
    await tester.pumpAndSettle();
    expect(_selectedModelName(tester), 'beta');

    await tester.tap(find.text('Run benchmark'));
    await _letRunFinish(tester);
    expect(engine.modelPaths, ['/nowhere/beta.gguf']);
  });

  testWidgets('hardware advice names the phone before any measurement', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Best for your hardware'), findsOneWidget);
    expect(
      find.textContaining('run a benchmark to replace the estimates'),
      findsOneWidget,
    );
    expect(find.textContaining('8.0 GB RAM'), findsOneWidget);
  });

  testWidgets('hardware advice asks for a run on an unreadable phone', (
    tester,
  ) async {
    await _pump(tester, device: const DeviceProfile(cores: 4));
    expect(find.text('Run a benchmark to calibrate these'), findsOneWidget);
  });

  testWidgets('hardware advice uses a stored measurement once there is one', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'benchmark_results_v1': jsonEncode([
        {
          'id': 'alpha',
          'tps': 10,
          'bytes': 2 * 1024 * 1024 * 1024,
          'at': '2026-10-01T00:00:00.000',
        },
      ]),
    });
    await _pump(tester);
    expect(find.textContaining('measured 20.0 GB/s effective'), findsOneWidget);
    expect(find.text('Fast chat'), findsOneWidget);
  });

  testWidgets('a completed run shows its speed, output and history', (
    tester,
  ) async {
    final engine = _FakeEngine()..script = _steadyRun;
    final container = await _pump(tester, engine: engine);

    await tester.tap(find.text('Run benchmark'));
    await _letRunFinish(tester);

    expect(engine.prompts.single, contains('neural network'));
    // Gauge and history both report the 4 tok/s decode rate.
    expect(find.text('4.0'), findsOneWidget);
    expect(find.text('4.0 tok/s'), findsOneWidget);
    // The graph has samples to plot. Its first sample also counts the first
    // token (prompt processing), so the peak is not asserted exactly.
    expect(find.textContaining('peak '), findsOneWidget);
    expect(find.text('Run a benchmark to plot it'), findsNothing);
    // Stat tiles: first token, token count and total time.
    expect(find.text('0.30s'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('1.30s'), findsOneWidget);
    expect(find.text('Sample output'), findsOneWidget);
    expect(find.textContaining('Neural networks learn 5'), findsOneWidget);
    expect(find.text('This session'), findsOneWidget);
    expect(find.text('alpha.gguf'), findsWidgets);
    expect(
      find.text('5 tokens · first token 0.30s · total 1.30s'),
      findsOneWidget,
    );
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Run benchmark'), findsOneWidget);

    // The rate is kept for the Models page and recalibrates the advice.
    final saved = container.read(benchmarkResultsProvider)['alpha'];
    expect(saved?.tokensPerSecond, closeTo(4.0, 1e-9));
    expect(saved?.modelBytes, 1 << 30);
    expect(find.textContaining('measured 4.0 GB/s effective'), findsOneWidget);
  });

  testWidgets('history keeps only the six most recent runs', (tester) async {
    final engine = _FakeEngine()..script = _steadyRun;
    await _pump(tester, engine: engine);

    for (var i = 0; i < 7; i++) {
      await tester.tap(find.text('Run benchmark'));
      await _letRunFinish(tester);
    }
    expect(engine.prompts, hasLength(7));
    expect(find.text('4.0 tok/s'), findsNWidgets(6));
  });

  testWidgets('while running it shows progress and can be stopped', (
    tester,
  ) async {
    final tokens = StreamController<LlmToken>();
    final engine = _FakeEngine()..script = () => tokens.stream;
    await _pump(tester, engine: engine);

    await tester.tap(find.text('Run benchmark'));
    await tester.pump();
    expect(find.text('Running…'), findsOneWidget);
    expect(find.text('MEASURING'), findsOneWidget);
    expect(find.text('Warming up…'), findsOneWidget);
    final run = find.widgetWithText(FilledButton, 'Running…');
    expect(tester.widget<FilledButton>(run).onPressed, isNull);
    final picker = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(picker.onChanged, isNull, reason: 'model is locked mid-run');

    // Wait for the settings lookup so the stream is being listened to.
    for (var i = 0; i < 400 && !tokens.hasListener; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tokens.hasListener, isTrue);
    tokens.add(_token(1, full: 'Partial'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.textContaining('Partial'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop'));
    expect(engine.cancels, 1);

    // The engine ends the stream when cancelled.
    tokens.add(_token(1, full: 'Partial', done: true));
    await tokens.close();
    await _letRunFinish(tester);
    expect(find.byTooltip('Stop'), findsNothing);
    expect(find.text('Run benchmark'), findsOneWidget);
    expect(
      find.text('This session'),
      findsNothing,
      reason: 'one token is not enough to measure a rate',
    );
  });

  testWidgets('an engine failure is shown in an error card', (tester) async {
    final engine = _FakeEngine()
      ..script = () => Stream.error(StateError('No model loaded'));
    await _pump(tester, engine: engine);

    await tester.tap(find.text('Run benchmark'));
    await _letRunFinish(tester);

    expect(find.text('Bad state: No model loaded'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Run benchmark'), findsOneWidget);
    expect(find.text('This session'), findsNothing);
  });

  testWidgets('slower runs switch to coarser time formats', (tester) async {
    Stream<LlmToken> threeTokens(int stepMs) => Stream.fromIterable([
      _token(1, full: 'a', stepMs: stepMs),
      _token(2, full: 'ab', stepMs: stepMs),
      _token(3, full: 'abc', stepMs: stepMs, done: true),
    ]);
    final engine = _FakeEngine()..script = () => threeTokens(5000);
    await _pump(tester, engine: engine);

    // 10.3 s of wall time: past ten seconds, one decimal place.
    await tester.tap(find.text('Run benchmark'));
    await _letRunFinish(tester);
    expect(find.text('10.3s'), findsOneWidget);

    // 60.3 s: minutes and whole seconds.
    engine.script = () => threeTokens(30000);
    await tester.tap(find.text('Run benchmark'));
    await _letRunFinish(tester);
    expect(find.text('1m 0s'), findsOneWidget);
    expect(find.textContaining('total 1m 0s'), findsOneWidget);
    expect(find.textContaining('total 10.3s'), findsOneWidget);
  });
}
