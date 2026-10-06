@Tags(['native'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/llm/llm_engine.dart';

/// End-to-end test of the chat path: real GGUF, real llama.cpp generation.
///
/// What it is really checking is the seam between llama.cpp and the engine —
/// the OpenAI-shaped chunk JSON that carries token counts, the finish reason,
/// and tool calls. Those are parsed from a wire format no unit test can stand
/// in for, so the only way to know they are read correctly is to run the thing.
///
/// **Skipped by default because it cannot run under `flutter_tester`.** The
/// embedding path can (see embedding_native_test.dart), but chat brings up
/// llama.cpp's full server context and the test host dies the moment it does —
/// instantly, with no output, before any native logging. So this is kept for a
/// harness that can host it, and gated rather than left to take the suite down
/// with it:
///
///     THANAI_NATIVE_CHAT=1 flutter test test/chat_native_test.dart --tags native
///
/// Downloads a 469 MB model on first run and caches it in the system temp dir.
void main() {
  final enabled = Platform.environment['THANAI_NATIVE_CHAT'] == '1';
  const disabledReason =
      'chat brings up llama.cpp server context, which crashes flutter_tester; '
      'set THANAI_NATIVE_CHAT=1 on a host that can run it';

  // Smallest chat model in the app catalog, and its template has a tool
  // section — which the tool-calling test needs.
  const url =
      'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf';

  Future<String>? modelFuture;
  Future<String> ensureModel() => modelFuture ??= () async {
        final dir = Directory('${Directory.systemTemp.path}/thanai_test_models');
        await dir.create(recursive: true);
        final file =
            File('${dir.path}/qwen2.5-0.5b-instruct-q4_k_m.gguf');

        if (!await file.exists() || await file.length() < 100 * 1024 * 1024) {
          final client = HttpClient();
          var target = Uri.parse(url);
          for (var redirects = 0; redirects < 5; redirects++) {
            final req = await client.getUrl(target);
            req.followRedirects = false;
            final res = await req.close();
            if (res.isRedirect) {
              final location = res.headers.value(HttpHeaders.locationHeader);
              await res.drain<void>();
              if (location == null) {
                throw StateError('redirect with no location');
              }
              target = target.resolve(location);
              continue;
            }
            if (res.statusCode != 200) {
              throw StateError('model download failed: HTTP ${res.statusCode}');
            }
            await res.pipe(file.openWrite());
            break;
          }
          client.close();
        }
        return file.path;
      }();

  Future<List<LlmToken>> run(
    List<ChatMessage> messages, {
    GenerationOptions options = const GenerationOptions(maxTokens: 64),
    List<ToolSpec> tools = const [],
    String? toolChoice,
  }) async {
    final tokens = <LlmToken>[];
    await for (final token in LlmEngine.instance.chat(
      messages,
      modelPath: await ensureModel(),
      options: options,
      tools: tools,
      toolChoice: toolChoice,
    )) {
      tokens.add(token);
      if (token.done) break;
    }
    return tokens;
  }

  test('reports the token counts llama.cpp actually measured', () async {
    final tokens = await run([
      const ChatMessage(role: 'user', content: 'Say hello in three words.'),
    ]);

    final last = tokens.last;
    expect(last.done, isTrue);
    expect(last.isError, isFalse, reason: last.full);
    expect(last.full.trim(), isNotEmpty);

    // The counts used to be hardcoded zeros. These come from the timings
    // llama.cpp reports beside each token.
    expect(last.stats.promptTokens, greaterThan(0));
    expect(last.stats.predictedTokens, isNotNull);
    expect(last.stats.predictedTokens, greaterThan(0));
  },
      timeout: const Timeout(Duration(minutes: 10)),
      skip: enabled ? null : disabledReason);

  test('distinguishes a truncated reply from a finished one', () async {
    final capped = await run(
      [const ChatMessage(role: 'user', content: 'Count slowly from 1 to 200.')],
      options: const GenerationOptions(maxTokens: 8),
    );
    expect(capped.last.finishReason, 'length');
    expect(capped.last.stats.predictedTokens, lessThanOrEqualTo(9));

    final complete = await run([
      const ChatMessage(role: 'user', content: 'Reply with the single word: ok'),
    ]);
    expect(complete.last.finishReason, 'stop');
  },
      timeout: const Timeout(Duration(minutes: 10)),
      skip: enabled ? null : disabledReason);

  test('cuts generation at a stop sequence without emitting it', () async {
    final tokens = await run(
      [
        const ChatMessage(
          role: 'user',
          content: 'Write exactly: alpha STOPHERE beta',
        ),
      ],
      options: const GenerationOptions(maxTokens: 64, stop: ['STOPHERE']),
    );

    final text = tokens.map((t) => t.delta).join();
    expect(text, isNot(contains('STOPHERE')));
    expect(tokens.last.full, isNot(contains('STOPHERE')));
    expect(text, tokens.last.full);
    expect(tokens.last.finishReason, 'stop');
  },
      timeout: const Timeout(Duration(minutes: 10)),
      skip: enabled ? null : disabledReason);

  test('assembles a tool call from the streamed fragments', () async {
    final tokens = await run(
      [
        const ChatMessage(
          role: 'user',
          content: 'What is the weather in Paris?',
        ),
      ],
      tools: const [
        ToolSpec(
          name: 'get_weather',
          description: 'Current weather for a city',
          parameters: {
            'type': 'object',
            'properties': {
              'city': {'type': 'string', 'description': 'City name'},
            },
            'required': ['city'],
          },
        ),
      ],
      // `required` makes the outcome deterministic enough to assert on: a 0.5B
      // model left to `auto` may well answer in prose.
      toolChoice: 'required',
    );

    final calls = tokens.last.toolCalls;
    expect(calls, isNotNull, reason: 'no tool call in: ${tokens.last.full}');
    expect(calls!.single['function']['name'], 'get_weather');

    // Arguments arrive split across tokens and must concatenate into exactly
    // one parseable JSON object — a fragment counted twice would still contain
    // "city" while being unparseable, so decode it rather than search it.
    final arguments = calls.single['function']['arguments'] as String;
    final decoded = jsonDecode(arguments);
    expect(decoded, isA<Map>());
    expect((decoded as Map)['city'], isNotNull);
    expect(tokens.last.finishReason, 'tool_calls');

    // The fragments the streaming route forwards should describe the same call.
    final deltas = [for (final t in tokens) ...t.toolCallDeltas];
    expect(deltas, isNotEmpty);
  },
      timeout: const Timeout(Duration(minutes: 10)),
      skip: enabled ? null : disabledReason);
}
