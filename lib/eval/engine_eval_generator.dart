import 'dart:async';

import 'package:thinai_tamil_evals/thinai_tamil_evals.dart';

import '../llm/generation_settings.dart';
import '../llm/llm_engine.dart';
import '../models_repo/model_store.dart';

/// Context window for eval runs.
///
/// llama.cpp shares `n_ctx` between fllama's four parallel slots, so one
/// request gets a quarter of it: 1024 tokens here. Every v1 prompt plus its
/// reply fits in 1024 (the library tests that), and the window is still half
/// of chat's default, so an eval never needs more memory than chat.
const kEvalContextSize = 4096;

/// Generation options for one eval prompt.
typedef EvalOptions = Future<GenerationOptions> Function(EvalPrompt prompt);

/// The options a real run uses: greedy decoding so a run repeats, thinking
/// off since reasoning would multiply the run time and measure something
/// other than Tamil, and the saved GPU choice so the eval runs the way chat
/// does.
EvalOptions evalOptionsFor(LocalModel model) =>
    (prompt) => GenerationSettingsStore.instance.optionsFor(
      model,
      requestedContext: kEvalContextSize,
      requestedTemperature: 0,
      requestedThinking: false,
      maxTokens: prompt.maxTokens,
      stop: prompt.stop,
      grammar: prompt.grammar,
    );

/// Runs a chat request: [LlmEngine.chat] for one model, or a fake in tests.
typedef EvalChat =
    Stream<LlmToken> Function(
      List<ChatMessage> messages,
      GenerationOptions options,
    );

/// Answers eval prompts with the on-device engine.
class EngineEvalGenerator implements EvalGenerator {
  EngineEvalGenerator({
    required this.chat,
    required this.cancel,
    required this.options,
  });

  /// [model] on [engine], with the options a real run uses.
  factory EngineEvalGenerator.forModel(LlmEngine engine, LocalModel model) =>
      EngineEvalGenerator(
        chat: (messages, options) =>
            engine.chat(messages, modelPath: model.path, options: options),
        cancel: engine.cancelCurrent,
        options: evalOptionsFor(model),
      );

  final EvalChat chat;

  /// Stops the request in flight.
  final void Function() cancel;

  final EvalOptions options;

  @override
  Stream<String> generate(EvalPrompt prompt) {
    StreamSubscription<LlmToken>? sub;
    // Set once the engine has said its last word, so a late cancel does not
    // stop whatever request the engine runs next.
    var finished = false;
    var cancelled = false;
    late final StreamController<String> out;

    void finish() {
      finished = true;
      if (!out.isClosed) unawaited(out.close());
    }

    out = StreamController<String>(
      onListen: () async {
        final GenerationOptions opts;
        try {
          opts = await options(prompt);
        } on Object catch (e, st) {
          out.addError(e, st);
          finish();
          return;
        }
        if (cancelled) return;
        sub =
            chat([
              ChatMessage(role: 'system', content: prompt.system),
              ChatMessage(role: 'user', content: prompt.user),
            ], opts).listen(
              (t) {
                if (t.isError) {
                  out.addError(StateError(t.full));
                  finish();
                  return;
                }
                if (t.delta.isNotEmpty) out.add(t.delta);
                if (t.done) finish();
              },
              onError: (Object e, StackTrace st) {
                out.addError(e, st);
                finish();
              },
              onDone: finish,
            );
      },
      onCancel: () {
        cancelled = true;
        if (!finished && sub != null) cancel();
        unawaited(sub?.cancel());
      },
    );
    return out.stream;
  }
}
