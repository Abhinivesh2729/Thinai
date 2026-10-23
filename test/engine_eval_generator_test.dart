import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thinai_tamil_evals/thinai_tamil_evals.dart';

import 'package:local_llm/eval/engine_eval_generator.dart';
import 'package:local_llm/llm/llm_engine.dart';

const _prompt = EvalPrompt(
  system: 'sys',
  user: 'கேள்வி',
  maxTokens: 1,
  grammar: kOptionGrammar,
);

LlmToken _t(String delta, {bool done = false, bool error = false}) =>
    LlmToken(delta: delta, full: delta, done: done, isError: error);

void main() {
  late List<List<ChatMessage>> sent;
  late List<GenerationOptions> options;
  late int cancels;

  setUp(() {
    sent = [];
    options = [];
    cancels = 0;
  });

  EngineEvalGenerator gen(
    Stream<LlmToken> Function() script, {
    EvalOptions? opts,
  }) => EngineEvalGenerator(
    chat: (messages, o) {
      sent.add(messages);
      options.add(o);
      return script();
    },
    cancel: () => cancels++,
    options:
        opts ??
        (p) async => GenerationOptions(
          maxTokens: p.maxTokens,
          grammar: p.grammar,
          temperature: 0,
        ),
  );

  test('streams the visible deltas and sends system and user', () async {
    final g = gen(
      () => Stream.fromIterable([_t('B'), _t(''), _t('', done: true)]),
    );
    expect(await g.generate(_prompt).toList(), ['B']);
    expect(sent.single.map((m) => m.role), ['system', 'user']);
    expect(sent.single.last.content, 'கேள்வி');
    expect(options.single.grammar, kOptionGrammar);
    expect(cancels, 0);
  });

  test('closes when the engine stream ends without a done token', () async {
    final g = gen(() => Stream.fromIterable([_t('அ')]));
    expect(await g.generate(_prompt).toList(), ['அ']);
  });

  test('an error token becomes a stream error', () async {
    final g = gen(
      () =>
          Stream.fromIterable([_t('Failed to load', done: true, error: true)]),
    );
    await expectLater(g.generate(_prompt), emitsError(isA<StateError>()));
  });

  test('an engine error becomes a stream error', () async {
    final g = gen(() => Stream.error(StateError('no model')));
    await expectLater(g.generate(_prompt), emitsError(isA<StateError>()));
  });

  test('an options failure becomes a stream error', () async {
    final g = gen(
      () => const Stream.empty(),
      opts: (_) async => throw StateError('no settings'),
    );
    await expectLater(g.generate(_prompt), emitsError(isA<StateError>()));
    expect(sent, isEmpty);
  });

  test('cancelling mid-reply stops the engine', () async {
    final engine = StreamController<LlmToken>();
    final g = gen(() => engine.stream);
    final sub = g.generate(_prompt).listen((_) {});
    await pumpEventQueue();
    engine.add(_t('அ'));
    await pumpEventQueue();
    await sub.cancel();
    expect(cancels, 1);
    await engine.close();
  });

  test('cancelling before the request starts sends nothing', () async {
    final opts = Completer<GenerationOptions>();
    final g = gen(() => const Stream.empty(), opts: (_) => opts.future);
    final sub = g.generate(_prompt).listen((_) {});
    await pumpEventQueue();
    await sub.cancel();
    opts.complete(const GenerationOptions());
    await pumpEventQueue();
    expect(sent, isEmpty);
    expect(cancels, 0);
  });

  test('a late cancel after the reply ends leaves the engine alone', () async {
    final g = gen(() => Stream.fromIterable([_t('B', done: true)]));
    final sub = g.generate(_prompt).listen((_) {});
    await pumpEventQueue();
    await sub.cancel();
    expect(cancels, 0);
  });
}
