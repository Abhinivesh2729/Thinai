import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../llm/generation_settings.dart';
import '../../llm/llm_engine.dart';
import '../../models_repo/gguf_metadata.dart';
import '../../models_repo/model_store.dart';
import 'chat_format.dart';
import 'embedding_format.dart';

Router ollamaRouter() {
  final router = Router();

  router.get('/api/tags', (Request req) async {
    final models = await ModelStore.instance.list();
    final body = {
      'models': [
        for (final m in models)
          {
            'name': m.id,
            'model': m.id,
            'modified_at': m.modifiedAt.toUtc().toIso8601String(),
            'size': m.sizeBytes,
            'digest': '',
            'details': {
              'format': 'gguf',
              'family': 'llama',
              'families': ['llama'],
              'parameter_size': '',
              'quantization_level': '',
            },
          },
      ],
    };
    return Response.ok(jsonEncode(body),
        headers: {'content-type': 'application/json'});
  });

  router.get('/api/ps', (Request req) async {
    final active = LlmEngine.instance.activeModelPath;
    final body = {
      'models': [
        if (active != null)
          {
            'name': _idFromPath(active),
            'model': _idFromPath(active),
            'size': 0,
          }
      ],
    };
    return Response.ok(jsonEncode(body),
        headers: {'content-type': 'application/json'});
  });

  router.post('/api/show', (Request req) async {
    final bodyStr = await req.readAsString();
    final body = bodyStr.isEmpty ? {} : jsonDecode(bodyStr) as Map;
    final name = body['name'] ?? body['model'];
    if (name is! String) {
      return Response(400, body: jsonEncode({'error': 'name is required'}));
    }
    final model = await ModelStore.instance.findById(name.toLowerCase());
    if (model == null) {
      return Response(404, body: jsonEncode({'error': 'model not found'}));
    }
    // Read from the file's own header, so clients that size their prompts by
    // `{arch}.context_length` (as Ollama clients do) see the real window.
    final info = await readGgufInfo(model.path);
    final limit = await GenerationSettingsStore.instance.limitFor(model);
    final family = info?.architecture ?? 'llama';
    return Response.ok(
      jsonEncode({
        'modelfile': '',
        'parameters': '',
        'template': '',
        'details': {
          'format': 'gguf',
          'family': family,
          'families': [family],
          'parameter_size': '',
          'quantization_level': '',
        },
        'model_info': {
          'size': model.sizeBytes,
          'general.architecture': family,
          if (info?.trainedContext != null)
            '$family.context_length': info!.trainedContext,
          if (info?.layers != null) '$family.block_count': info!.layers,
          if (info?.embeddingLength != null)
            '$family.embedding_length': info!.embeddingLength,
          // The largest num_ctx this phone will actually honour.
          'thinai.context_cap': limit.cap,
        },
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  router.post('/api/generate', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final modelName = body['model'] as String?;
    final prompt = body['prompt'] as String? ?? '';
    final stream = (body['stream'] as bool?) ?? true;

    final model = await _resolveModel(modelName);
    if (model == null) {
      return Response(404,
          body: jsonEncode({'error': 'model not found: $modelName'}));
    }
    LlmEngine.instance.setActiveModel(model.path);
    final options = await _generationOptionsFor(body, model);

    final startedAt = DateTime.now();
    final tokenStream = LlmEngine.instance.chat(
      [ChatMessage(role: 'user', content: prompt)],
      modelPath: model.path,
      options: options,
    );

    if (!stream) {
      final buf = StringBuffer();
      var stats = const LlmStats();
      var doneReason = 'stop';
      await for (final t in tokenStream) {
        buf.write(t.delta);
        stats = t.stats;
        if (t.done) {
          doneReason = t.finishReason ?? 'stop';
          break;
        }
      }
      return Response.ok(
        jsonEncode({
          'model': model.id,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'response': buf.toString(),
          'done': true,
          'done_reason': doneReason,
          ..._counters(stats, startedAt),
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final controller = StreamController<List<int>>();
    () async {
      try {
        await for (final t in tokenStream) {
          final line = '${jsonEncode({
                'model': model.id,
                'created_at': DateTime.now().toUtc().toIso8601String(),
                'response': t.delta,
                'done': t.done,
                if (t.done) 'done_reason': t.finishReason ?? 'stop',
                if (t.done) ..._counters(t.stats, startedAt),
              })}\n';
          controller.add(utf8.encode(line));
        }
      } catch (e) {
        final line = '${jsonEncode({'error': e.toString(), 'done': true})}\n';
        controller.add(utf8.encode(line));
      } finally {
        await controller.close();
      }
    }();

    return Response.ok(controller.stream, headers: {
      'content-type': 'application/x-ndjson',
      'cache-control': 'no-cache',
    });
  });

  // Ollama's current embedding endpoint. `input` is a string or array of
  // strings; the response always carries an array of vectors.
  router.post('/api/embed', (Request req) async {
    final startedAt = DateTime.now();
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final modelName = body['model'] as String?;

    final List<String> inputs;
    try {
      inputs = parseEmbeddingInputs(body['input']);
    } on FormatException catch (e) {
      return Response(400,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'});
    }

    final model = await _resolveModel(modelName);
    if (model == null) {
      return Response(404,
          body: jsonEncode({'error': 'model not found: $modelName'}),
          headers: {'content-type': 'application/json'});
    }

    final options = _optionsFrom(body);
    try {
      final result = await LlmEngine.instance.embedBatch(
        inputs,
        modelPath: model.path,
        contextSize: options.contextSize,
        numGpuLayers: options.numGpuLayers,
      );
      return Response.ok(
        jsonEncode({
          'model': model.id,
          'embeddings': result.embeddings,
          'total_duration':
              DateTime.now().difference(startedAt).inMicroseconds * 1000,
          'load_duration': 0,
          'prompt_eval_count': result.totalTokens,
        }),
        headers: {'content-type': 'application/json'},
      );
    } on EmbeddingException catch (e) {
      return Response(400,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'});
    }
  });

  // Ollama's legacy embedding endpoint: single `prompt`, single `embedding`.
  // Still what a number of clients (and older LangChain versions) call.
  router.post('/api/embeddings', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final modelName = body['model'] as String?;
    final prompt = body['prompt'];
    if (prompt is! String || prompt.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'prompt is required'}),
          headers: {'content-type': 'application/json'});
    }

    final model = await _resolveModel(modelName);
    if (model == null) {
      return Response(404,
          body: jsonEncode({'error': 'model not found: $modelName'}),
          headers: {'content-type': 'application/json'});
    }

    final options = _optionsFrom(body);
    try {
      final result = await LlmEngine.instance.embedBatch(
        [prompt],
        modelPath: model.path,
        contextSize: options.contextSize,
        numGpuLayers: options.numGpuLayers,
      );
      return Response.ok(
        jsonEncode({'embedding': result.embeddings.first}),
        headers: {'content-type': 'application/json'},
      );
    } on EmbeddingException catch (e) {
      return Response(400,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'});
    }
  });

  router.post('/api/chat', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final modelName = body['model'] as String?;
    final stream = (body['stream'] as bool?) ?? true;

    final List<ChatMessage> messages;
    final List<ToolSpec> tools;
    try {
      messages = parseChatMessages(
        (body['messages'] as List?) ?? const [],
        visionReady: LlmEngine.instance.visionReady,
      );
      tools = parseTools(body['tools']);
    } on FormatException catch (e) {
      return Response(400,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'});
    }

    final model = await _resolveModel(modelName);
    if (model == null) {
      return Response(404,
          body: jsonEncode({'error': 'model not found: $modelName'}));
    }
    LlmEngine.instance.setActiveModel(model.path);
    final options = await _generationOptionsFor(body, model);

    final startedAt = DateTime.now();
    final tokenStream = LlmEngine.instance.chat(
      messages,
      modelPath: model.path,
      options: options,
      tools: tools,
    );

    if (!stream) {
      final buf = StringBuffer();
      var stats = const LlmStats();
      var doneReason = 'stop';
      List<Map<String, dynamic>>? toolCalls;
      await for (final t in tokenStream) {
        buf.write(t.delta);
        stats = t.stats;
        if (t.done) {
          doneReason = t.finishReason ?? 'stop';
          toolCalls = t.toolCalls;
          break;
        }
      }
      return Response.ok(
        jsonEncode({
          'model': model.id,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'message': {
            'role': 'assistant',
            'content': buf.toString(),
            if (toolCalls != null) 'tool_calls': _ollamaToolCalls(toolCalls),
          },
          'done': true,
          'done_reason': doneReason,
          ..._counters(stats, startedAt),
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final controller = StreamController<List<int>>();
    () async {
      try {
        await for (final t in tokenStream) {
          final toolCalls = t.done ? t.toolCalls : null;
          final line = '${jsonEncode({
                'model': model.id,
                'created_at': DateTime.now().toUtc().toIso8601String(),
                'message': {
                  'role': 'assistant',
                  'content': t.delta,
                  if (toolCalls != null)
                    'tool_calls': _ollamaToolCalls(toolCalls),
                },
                'done': t.done,
                if (t.done) 'done_reason': t.finishReason ?? 'stop',
                if (t.done) ..._counters(t.stats, startedAt),
              })}\n';
          controller.add(utf8.encode(line));
        }
      } catch (e) {
        final line = '${jsonEncode({'error': e.toString(), 'done': true})}\n';
        controller.add(utf8.encode(line));
      } finally {
        await controller.close();
      }
    }();

    return Response.ok(controller.stream, headers: {
      'content-type': 'application/x-ndjson',
      'cache-control': 'no-cache',
    });
  });

  return router;
}

Future<LocalModel?> _resolveModel(String? name) async {
  if (name == null || name.isEmpty) {
    final all = await ModelStore.instance.list();
    return all.isEmpty ? null : all.first;
  }
  return ModelStore.instance.findById(name.toLowerCase());
}

double? _asDoubleOrNull(dynamic v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

int? _asIntOrNull(dynamic v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

/// Options for a completion on [model].
///
/// `num_ctx` and `temperature` in the request override the model's saved
/// settings, as Ollama clients expect, but `num_ctx` is clamped to what the
/// model was trained for and this phone's RAM can hold: past the first,
/// llama.cpp would clamp it anyway, and past the second the app is killed.
Future<GenerationOptions> _generationOptionsFor(
  Map<String, dynamic> body,
  LocalModel model,
) async {
  final options = (body['options'] as Map?) ?? {};
  final store = GenerationSettingsStore.instance;
  final resolved = await store.resolve(
    model,
    requestedContext: _asIntOrNull(options['num_ctx']),
    requestedTemperature:
        _asDoubleOrNull(options['temperature'] ?? body['temperature']),
  );

  // `num_gpu: 0` asks for the CPU and always gets it. Any other value only
  // matters when GPU acceleration is switched on in the app: a client cannot
  // turn on a GPU driver the phone's owner chose to keep off.
  final requestedLayers = _asIntOrNull(options['num_gpu']);
  final backend =
      requestedLayers == 0 ? GpuBackend.none : store.settings.gpu;
  final layers = backend == GpuBackend.none
      ? 0
      : (requestedLayers ?? kAllGpuLayers);

  return GenerationOptions(
    temperature: resolved.temperature,
    topP: _asDoubleOrNull(options['top_p'] ?? body['top_p']) ?? 1.0,
    maxTokens: _asIntOrNull(options['num_predict'] ?? body['max_tokens']) ?? -1,
    contextSize: resolved.contextSize,
    numGpuLayers: layers,
    gpuBackend: backend,
    stop: _stopFrom(options['stop'] ?? body['stop']),
  );
}

/// Raw options, for the embedding routes, which size their own context.
GenerationOptions _optionsFrom(Map<String, dynamic> body) {
  final options = (body['options'] as Map?) ?? {};
  double asDouble(dynamic v, double d) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? d : d);
  int asInt(dynamic v, int d) =>
      v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? d : d);

  return GenerationOptions(
    temperature: asDouble(options['temperature'] ?? body['temperature'], 0.7),
    topP: asDouble(options['top_p'] ?? body['top_p'], 1.0),
    maxTokens: asInt(options['num_predict'] ?? body['max_tokens'], -1),
    contextSize: asInt(options['num_ctx'], kDefaultContextSize),
    numGpuLayers: asInt(options['num_gpu'], 0),
    // Ollama carries stop words inside `options`; a bad one is not worth
    // failing a generation over here, so fall back to none.
    stop: _stopFrom(options['stop'] ?? body['stop']),
  );
}

List<String> _stopFrom(dynamic raw) {
  try {
    return parseStopSequences(raw);
  } on FormatException {
    return const [];
  }
}

/// Ollama's `tool_calls` differ from OpenAI's in two ways: no id, and
/// `arguments` is an object rather than a JSON string.
List<Map<String, dynamic>> _ollamaToolCalls(List<Map<String, dynamic>> calls) {
  return [
    for (final call in calls)
      {
        'function': {
          'name': (call['function'] as Map?)?['name'] ?? '',
          'arguments': _decodeArguments(
            (call['function'] as Map?)?['arguments'],
          ),
        },
      },
  ];
}

dynamic _decodeArguments(dynamic arguments) {
  if (arguments is Map) return arguments;
  if (arguments is! String || arguments.isEmpty) return const {};
  try {
    final decoded = jsonDecode(arguments);
    return decoded is Map ? decoded : {'value': decoded};
  } on FormatException {
    // The grammar makes malformed arguments unlikely, but a truncated
    // generation can still cut one short. Hand back what was generated rather
    // than dropping the call.
    return {'_raw': arguments};
  }
}

/// The token counters and timings Ollama clients read off a `done` message.
/// Durations are nanoseconds, as Ollama reports them.
Map<String, dynamic> _counters(LlmStats stats, DateTime startedAt) => {
      'total_duration':
          DateTime.now().difference(startedAt).inMicroseconds * 1000,
      'load_duration': 0,
      'prompt_eval_count': stats.promptTokens,
      'prompt_eval_duration':
          (stats.timeToFirstToken ?? Duration.zero).inMicroseconds * 1000,
      'eval_count': stats.predictedTokens ?? stats.tokens,
      'eval_duration': stats.decodeTime.inMicroseconds * 1000,
    };

String _idFromPath(String path) {
  final slash = path.replaceAll('\\', '/');
  final name = slash.split('/').last;
  final stripped =
      name.toLowerCase().endsWith('.gguf') ? name.substring(0, name.length - 5) : name;
  return stripped.toLowerCase();
}
