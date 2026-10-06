import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../../llm/generation_settings.dart';
import '../../llm/llm_engine.dart';
import '../../models_repo/model_store.dart';
import 'chat_format.dart';
import 'embedding_format.dart';

final _uuid = Uuid();

Router openAiRouter() {
  final router = Router();

  router.get('/v1/models', (Request req) async {
    final models = await ModelStore.instance.list();
    final body = {
      'object': 'list',
      'data': [
        for (final m in models)
          {
            'id': m.id,
            'object': 'model',
            'created': m.modifiedAt.millisecondsSinceEpoch ~/ 1000,
            'owned_by': 'local',
          },
      ],
    };
    return Response.ok(jsonEncode(body),
        headers: {'content-type': 'application/json'});
  });

  router.post('/v1/embeddings', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final modelName = body['model'] as String?;

    final List<String> inputs;
    try {
      inputs = parseEmbeddingInputs(body['input']);
    } on FormatException catch (e) {
      return _error(400, e.message, 'invalid_request_error');
    }

    final encodingFormat = (body['encoding_format'] as String?) ?? 'float';
    if (encodingFormat != 'float' && encodingFormat != 'base64') {
      return _error(
        400,
        "encoding_format must be 'float' or 'base64'",
        'invalid_request_error',
      );
    }

    final dimensions = body['dimensions'];
    if (dimensions != null && (dimensions is! int || dimensions <= 0)) {
      return _error(
        400,
        'dimensions must be a positive integer',
        'invalid_request_error',
      );
    }

    final model = await _resolveModel(modelName);
    if (model == null) {
      return _error(404, 'model not found: $modelName', 'not_found');
    }

    try {
      final result = await LlmEngine.instance.embedBatch(
        inputs,
        modelPath: model.path,
      );

      var vectors = result.embeddings;
      if (dimensions is int) {
        if (dimensions > result.dimensions) {
          return _error(
            400,
            'dimensions ($dimensions) exceeds the model output size '
                '(${result.dimensions})',
            'invalid_request_error',
          );
        }
        vectors = [for (final v in vectors) shortenEmbedding(v, dimensions)];
      }

      return Response.ok(
        jsonEncode({
          'object': 'list',
          'data': [
            for (var i = 0; i < vectors.length; i++)
              {
                'object': 'embedding',
                'index': i,
                'embedding': encodingFormat == 'base64'
                    ? embeddingToBase64(vectors[i])
                    : vectors[i],
              },
          ],
          'model': model.id,
          'usage': {
            'prompt_tokens': result.totalTokens,
            'total_tokens': result.totalTokens,
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    } on EmbeddingException catch (e) {
      return _error(400, e.message, 'invalid_request_error');
    }
  });

  router.post('/v1/chat/completions', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final modelName = body['model'] as String?;
    final stream = (body['stream'] as bool?) ?? false;
    final streamOptions = body['stream_options'];
    final includeUsage =
        streamOptions is Map && streamOptions['include_usage'] == true;

    final List<ChatMessage> messages;
    final List<ToolSpec> allTools;
    final ToolChoiceSpec toolChoice;
    final List<String> stop;
    try {
      messages = parseChatMessages(
        (body['messages'] as List?) ?? const [],
        visionReady: LlmEngine.instance.visionReady,
      );
      allTools = parseTools(body['tools']);
      toolChoice = parseToolChoice(body['tool_choice']);
      stop = parseStopSequences(body['stop']);
    } on FormatException catch (e) {
      return _error(400, e.message, 'invalid_request_error');
    }

    // Naming a tool means "call this one", which llama.cpp expresses as
    // `required` over a list holding only that tool.
    var tools = allTools;
    if (toolChoice.name != null) {
      tools = [
        for (final t in allTools)
          if (t.name == toolChoice.name) t
      ];
      if (tools.isEmpty) {
        return _error(
          400,
          'tool_choice names ${toolChoice.name}, which is not in tools',
          'invalid_request_error',
        );
      }
    }

    final model = await _resolveModel(modelName);
    if (model == null) {
      return _error(404, 'model not found: $modelName', 'not_found');
    }
    LlmEngine.instance.setActiveModel(model.path);

    // Context window and temperature come from the model's settings — the
    // same ones chat uses — and a temperature the client actually sent wins
    // over the saved one.
    final options = await GenerationSettingsStore.instance.optionsFor(
      model,
      requestedTemperature: _asDoubleOrNull(body['temperature']),
      topP: _asDoubleOrNull(body['top_p']) ?? 1.0,
      // `max_completion_tokens` is the current spelling; `max_tokens` is the
      // deprecated one that most clients still send.
      maxTokens:
          _asIntOrNull(body['max_completion_tokens'] ?? body['max_tokens']) ??
              -1,
      stop: stop,
    );

    final id = 'chatcmpl-${_uuid.v4()}';
    final created = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tokenStream = LlmEngine.instance.chat(
      messages,
      modelPath: model.path,
      options: options,
      tools: tools,
      toolChoice: toolChoice.mode,
    );

    Map<String, dynamic> chunk(Map<String, dynamic> choice) => {
          'id': id,
          'object': 'chat.completion.chunk',
          'created': created,
          'model': model.id,
          'choices': [choice],
        };

    if (!stream) {
      final buf = StringBuffer();
      var finishReason = 'stop';
      var promptTokens = 0;
      var completionTokens = 0;
      List<Map<String, dynamic>>? toolCalls;
      String? failure;

      await for (final t in tokenStream) {
        if (t.isError) {
          failure = t.full;
          break;
        }
        buf.write(t.delta);
        promptTokens = t.stats.promptTokens;
        completionTokens = t.stats.predictedTokens ?? t.stats.tokens;
        if (t.done) {
          finishReason = t.finishReason ?? 'stop';
          toolCalls = t.toolCalls;
          break;
        }
      }

      // A native failure arrives as text on the token stream rather than as a
      // thrown error. Passing it off as the assistant's reply would let
      // "request exceeds the available context size" land in a transcript as
      // something the model said.
      if (failure != null) {
        return _error(500, failure, 'server_error');
      }

      final calls = toolCalls == null
          ? null
          : finalizeToolCalls(toolCalls, (i) => 'call_${_uuid.v4()}');
      final text = buf.toString();

      return Response.ok(
        jsonEncode({
          'id': id,
          'object': 'chat.completion',
          'created': created,
          'model': model.id,
          'choices': [
            {
              'index': 0,
              'message': {
                'role': 'assistant',
                // OpenAI sends a null content beside tool calls, and clients
                // branch on exactly that.
                'content': calls != null && text.isEmpty ? null : text,
                'tool_calls': ?calls,
              },
              'finish_reason': finishReason,
            },
          ],
          'usage': {
            'prompt_tokens': promptTokens,
            'completion_tokens': completionTokens,
            'total_tokens': promptTokens + completionTokens,
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final controller = StreamController<List<int>>();
    () async {
      // Ids llama.cpp did not supply, kept per tool-call index so every delta
      // for one call carries the same id.
      final callIds = <int, String>{};
      var promptTokens = 0;
      var completionTokens = 0;

      void send(Map<String, dynamic> payload) =>
          controller.add(utf8.encode(_sse(payload)));

      void fail(String message) {
        send({
          'error': {'message': message, 'type': 'server_error'}
        });
        // Still terminate the stream properly. A client that only watches for
        // the sentinel would otherwise sit waiting on a connection that is
        // never coming back.
        controller.add(utf8.encode('data: [DONE]\n\n'));
      }

      try {
        // Opening role chunk.
        send(chunk({
          'index': 0,
          'delta': {'role': 'assistant'},
          'finish_reason': null,
        }));

        await for (final t in tokenStream) {
          if (t.isError) {
            fail(t.full);
            return;
          }

          promptTokens = t.stats.promptTokens;
          completionTokens = t.stats.predictedTokens ?? t.stats.tokens;

          for (final delta in t.toolCallDeltas) {
            final index = delta['index'] is int ? delta['index'] as int : 0;
            final existing = delta['id'];
            final callId = existing is String && existing.isNotEmpty
                ? existing
                : callIds.putIfAbsent(index, () => 'call_${_uuid.v4()}');
            send(chunk({
              'index': 0,
              'delta': {
                'tool_calls': [
                  {...delta, 'id': callId, 'type': 'function'}
                ]
              },
              'finish_reason': null,
            }));
          }

          if (t.delta.isNotEmpty) {
            send(chunk({
              'index': 0,
              'delta': {'content': t.delta},
              'finish_reason': null,
            }));
          }

          if (t.done) {
            send(chunk({
              'index': 0,
              'delta': {},
              'finish_reason': t.finishReason ?? 'stop',
            }));
            break;
          }
        }

        if (includeUsage) {
          // Per the streaming spec the usage chunk carries an empty choices
          // array and comes last.
          send({
            'id': id,
            'object': 'chat.completion.chunk',
            'created': created,
            'model': model.id,
            'choices': [],
            'usage': {
              'prompt_tokens': promptTokens,
              'completion_tokens': completionTokens,
              'total_tokens': promptTokens + completionTokens,
            },
          });
        }
        controller.add(utf8.encode('data: [DONE]\n\n'));
      } catch (e) {
        fail(e.toString());
      } finally {
        await controller.close();
      }
    }();

    return Response.ok(controller.stream, headers: {
      'content-type': 'text/event-stream',
      'cache-control': 'no-cache',
      'connection': 'keep-alive',
    });
  });

  return router;
}

String _sse(Map<String, dynamic> payload) => 'data: ${jsonEncode(payload)}\n\n';

Response _error(int status, String message, String type) => Response(
      status,
      body: jsonEncode({
        'error': {'message': message, 'type': type}
      }),
      headers: {'content-type': 'application/json'},
    );

/// A number the client sent, or null when it sent none — so an absent field
/// falls through to the model's setting rather than to a hardcoded default.
double? _asDoubleOrNull(dynamic v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

int? _asIntOrNull(dynamic v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

Future<LocalModel?> _resolveModel(String? name) async {
  if (name == null || name.isEmpty) {
    final all = await ModelStore.instance.list();
    return all.isEmpty ? null : all.first;
  }
  return ModelStore.instance.findById(name.toLowerCase());
}
