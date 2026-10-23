import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/llm/generation_settings.dart';
import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/ui/widgets/model_settings_sheet.dart';

import 'context_limits_test.dart' show ggufHeader;

const _thinkingTemplate =
    '{%- if enable_thinking is defined and enable_thinking is false %}'
    '<think>\n\n</think>{%- endif %}';

final _store = GenerationSettingsStore.instance;
late Directory _dir;
var _files = 0;

/// Writes a small GGUF header to disk and returns it as an installed model.
///
/// Each call gets its own file, since header reads are cached by path.
LocalModel _model({int? trainedContext, bool canThink = false}) {
  final id = 'model-${_files++}';
  final file = File('${_dir.path}/$id.gguf')
    ..writeAsBytesSync(
      ggufHeader([
        ('general.architecture', 8, 'qwen2'),
        if (trainedContext != null) ('qwen2.context_length', 4, trainedContext),
        ('qwen2.block_count', 4, 24),
        ('qwen2.attention.head_count', 4, 14),
        ('qwen2.attention.head_count_kv', 4, 2),
        ('qwen2.embedding_length', 4, 896),
        if (canThink) ('tokenizer.chat_template', 8, _thinkingTemplate),
      ]),
    );
  return LocalModel(
    id: id,
    displayName: id,
    path: file.path,
    sizeBytes: file.lengthSync(),
    modifiedAt: DateTime(2026),
  );
}

/// Lets the sheet finish reading the model file. The header is read on
/// another isolate, which only progresses on the real event loop.
Future<void> _waitForLoad(WidgetTester tester, {Finder? until}) async {
  final done = until ?? find.text('Model settings');
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (done.evaluate().isNotEmpty) return;
  }
  fail('the sheet never finished loading');
}

Future<void> _pump(WidgetTester tester, LocalModel model) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ModelSettingsSheet(model: model)),
    ),
  );
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  await _waitForLoad(tester);
}

/// Lets a store write started from the sheet reach the settings.
Future<void> _flushStore(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

Future<void> _dragToEnd(WidgetTester tester, Finder slider, double dx) async {
  await tester.ensureVisible(slider);
  await tester.pumpAndSettle();
  await tester.drag(slider, Offset(dx, 0));
  await tester.pumpAndSettle();
  await _flushStore(tester);
}

ModelGenerationSettings _saved(LocalModel model) =>
    _store.settings.forModel(model.id);

void main() {
  setUpAll(() {
    _dir = Directory.systemTemp.createTempSync('model_settings_sheet_test');
    // A phone whose RAM could not be read: the caps below are the model's
    // own, the same on a Mac and on the Linux CI runner.
    _store.deviceForTesting = DeviceProfile.unknownProfile;
  });

  tearDownAll(() => _dir.deleteSync(recursive: true));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _store.ensureLoaded();
  });

  testWidgets('shows the defaults for an untouched model', (tester) async {
    final model = _model(trainedContext: 32768);
    await _pump(tester, model);

    expect(find.text(model.id), findsOneWidget);
    expect(find.text('8K tokens'), findsOneWidget);
    expect(find.text("Max 32K, the model's limit."), findsOneWidget);
    expect(find.text('0.70'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('0.95'), findsOneWidget);
    expect(
      find.text('Thinking'),
      findsNothing,
      reason: 'this model has no thinking switch in its template',
    );
  });

  testWidgets('a model without a trained length gets the general cap', (
    tester,
  ) async {
    await _pump(tester, _model());
    expect(find.text('Max 32K.'), findsOneWidget);
  });

  testWidgets('a long-context model shows its window in millions', (
    tester,
  ) async {
    await _pump(tester, _model(trainedContext: 1 << 20));
    expect(find.text("Max 1M, the model's limit."), findsOneWidget);
  });

  testWidgets('shows saved values instead of the defaults', (tester) async {
    final model = _model(trainedContext: 32768);
    await tester.runAsync(
      () => _store.update(
        model.id,
        contextSize: 2048,
        temperature: 0.3,
        topK: 0,
        topP: 0.5,
      ),
    );
    await _pump(tester, model);

    expect(find.text('2K tokens'), findsOneWidget);
    expect(find.text('0.30'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget, reason: 'Top-K 0 means no limit');
    expect(find.text('0.50'), findsOneWidget);
  });

  testWidgets('dragging the context slider saves the new window', (
    tester,
  ) async {
    final model = _model(trainedContext: 32768);
    await _pump(tester, model);

    await _dragToEnd(tester, find.byType(Slider).first, -1000);

    expect(find.text('512 tokens'), findsOneWidget);
    expect(_saved(model).contextSize, 512);
  });

  testWidgets('dragging temperature saves it', (tester) async {
    final model = _model(trainedContext: 32768);
    await _pump(tester, model);

    await _dragToEnd(tester, find.byType(Slider).at(1), 1000);

    expect(find.text('2.00'), findsOneWidget);
    expect(_saved(model).temperature, 2.0);
  });

  testWidgets('dragging Top-K to zero turns the limit off', (tester) async {
    final model = _model(trainedContext: 32768);
    await _pump(tester, model);

    await _dragToEnd(
      tester,
      find.byKey(const ValueKey('modelSettings.topK')),
      -1000,
    );

    expect(find.text('Off'), findsOneWidget);
    expect(_saved(model).topK, 0);
  });

  testWidgets('dragging Top-P to the top keeps every word', (tester) async {
    final model = _model(trainedContext: 32768);
    await tester.runAsync(() => _store.update(model.id, topP: 0.5));
    await _pump(tester, model);

    await _dragToEnd(
      tester,
      find.byKey(const ValueKey('modelSettings.topP')),
      1000,
    );

    expect(find.text('1.00'), findsOneWidget);
    expect(_saved(model).topP, 1.0);
  });

  testWidgets('a thinking model gets a switch that saves', (tester) async {
    final model = _model(trainedContext: 32768, canThink: true);
    await _pump(tester, model);

    final toggle = find.byKey(const ValueKey('modelSettings.thinking'));
    expect(toggle, findsOneWidget);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await _flushStore(tester);

    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(_saved(model).thinking, isFalse);
  });

  testWidgets('Reset to defaults forgets the saved values', (tester) async {
    final model = _model(trainedContext: 32768);
    await tester.runAsync(
      () => _store.update(model.id, temperature: 1.5, topK: 10),
    );
    await _pump(tester, model);
    expect(find.text('1.50'), findsOneWidget);

    await tester.ensureVisible(find.text('Reset to defaults'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset to defaults'));
    await _waitForLoad(tester, until: find.text('0.70'));

    expect(find.text('40'), findsOneWidget);
    expect(_saved(model).isDefault, isTrue);
  });

  testWidgets('showModelSettingsSheet opens the sheet for the model', (
    tester,
  ) async {
    final model = _model(trainedContext: 32768);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModelSettingsSheet(context, model),
              child: const Text('tune'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('tune'));
    await tester.pump();
    await _waitForLoad(tester);
    await tester.pumpAndSettle();

    expect(
      tester.widget<ModelSettingsSheet>(find.byType(ModelSettingsSheet)).model,
      model,
    );
    expect(find.text(model.id), findsOneWidget);
  });
}
