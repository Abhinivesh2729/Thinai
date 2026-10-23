import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinai_tamil_evals/thinai_tamil_evals.dart';

import 'package:local_llm/models_repo/tamil_eval_store.dart';

EvalReport _report(String model, double score) => EvalReport(
  language: 'ta',
  datasetVersion: '1.0.0',
  modelId: model,
  startedAt: DateTime.utc(2026, 10, 24),
  elapsed: const Duration(seconds: 160),
  overall: score,
  axes: {'understanding': score},
  tasks: const [],
  items: const [
    ItemResult(
      taskId: 'qa',
      itemId: 'q01',
      output: 'சென்னை',
      score: 1,
      elapsed: Duration(seconds: 2),
    ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts empty', () async {
    expect(await const TamilEvalStore().load(), isEmpty);
  });

  test('keeps the latest report per model', () async {
    const store = TamilEvalStore();
    await store.record(_report('lfm', 12));
    await store.record(_report('gemma', 48));
    await store.record(_report('lfm', 15));
    final loaded = await store.load();
    expect(loaded.keys, unorderedEquals(['lfm', 'gemma']));
    expect(loaded['lfm']!.overall, 15);
    expect(loaded['lfm']!.items.single.output, 'சென்னை');
  });

  test('skips what it cannot read', () {
    expect(TamilEvalStore.decode(null), isEmpty);
    expect(TamilEvalStore.decode(''), isEmpty);
    expect(TamilEvalStore.decode('{not json'), isEmpty);
    expect(TamilEvalStore.decode('{"a": 1}'), isEmpty);
    final good = TamilEvalStore.encode({'lfm': _report('lfm', 12)});
    final mixed =
        '[1, {"model": "broken"}, ${good.substring(1, good.length - 1)}]';
    expect(TamilEvalStore.decode(mixed).keys, ['lfm']);
  });
}
