import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';

import 'package:local_llm/llm/llm_engine.dart';
import 'package:local_llm/server/routes/openai_routes.dart';

/// Unit tests for the OpenAI-compatible routes, calling the router directly.
///
/// Like ollama_routes_test.dart, nothing here reaches llama.cpp: each request
/// fails validation or names a model that is not on disk. A request that
/// resolves a model goes into LlmEngine and the native bridge, which has no
/// seam to stub.

late Directory _support;

Directory get _modelsDir => Directory('${_support.path}/models');

Future<Response> _get(String path) =>
    openAiRouter().call(Request('GET', Uri.parse('http://localhost$path')));

Future<Response> _post(String path, Object? body) => openAiRouter().call(
  Request('POST', Uri.parse('http://localhost$path'), body: jsonEncode(body)),
);

Future<Map<String, dynamic>> _json(Response res) async =>
    jsonDecode(await res.readAsString()) as Map<String, dynamic>;

/// Expects an OpenAI-shaped error: `{"error": {"message", "type"}}`.
Future<void> _expectError(
  Response res,
  int status,
  String type, [
  Object? message,
]) async {
  expect(res.statusCode, status);
  expect(res.headers['content-type'], 'application/json');
  final error = (await _json(res))['error'] as Map;
  expect(error['type'], type);
  if (message != null) expect(error['message'], message);
}

const _hi = [
  {'role': 'user', 'content': 'hi'},
];

Map<String, dynamic> _tool(String name) => {
  'type': 'function',
  'function': {
    'name': name,
    'parameters': {'type': 'object', 'properties': {}},
  },
};

void main() {
  setUpAll(() async {
    _support = await Directory.systemTemp.createTemp('thinai_openai_routes_');
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => _support.path,
        );
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    if (await _support.exists()) await _support.delete(recursive: true);
  });

  setUp(() async {
    // ModelStore caches its directory, so empty it rather than replace it.
    if (await _modelsDir.exists()) await _modelsDir.delete(recursive: true);
    await _modelsDir.create(recursive: true);
  });

  tearDown(() => LlmEngine.instance.setActiveModel(null));

  group('GET /v1/models', () {
    test('is an empty list when nothing is downloaded', () async {
      final res = await _get('/v1/models');
      expect(res.statusCode, 200);
      expect(res.headers['content-type'], 'application/json');
      expect(await _json(res), {'object': 'list', 'data': []});
    });

    test('lists each model with a creation time in seconds', () async {
      final file = File('${_modelsDir.path}/Llama-3.2-1B.gguf');
      await file.writeAsBytes([1, 2, 3]);
      await File('${_modelsDir.path}/mmproj-llama.gguf').writeAsBytes([1]);

      final data = (await _json(await _get('/v1/models')))['data'] as List;

      expect(data, hasLength(1));
      final model = data.single as Map;
      expect(model['id'], 'llama-3.2-1b');
      expect(model['object'], 'model');
      expect(model['owned_by'], 'local');
      final modified = (await file.stat()).modified;
      expect(model['created'], modified.millisecondsSinceEpoch ~/ 1000);
    });
  });

  group('POST /v1/embeddings', () {
    test('rejects a missing input', () async {
      await _expectError(
        await _post('/v1/embeddings', {'model': 'any'}),
        400,
        'invalid_request_error',
        'input is required and must be a string or an array of strings',
      );
    });

    test('rejects token arrays', () async {
      await _expectError(
        await _post('/v1/embeddings', {
          'model': 'any',
          'input': [
            [1, 2],
          ],
        }),
        400,
        'invalid_request_error',
        'input array must contain only strings',
      );
    });

    test('rejects an unknown encoding_format', () async {
      await _expectError(
        await _post('/v1/embeddings', {
          'model': 'any',
          'input': 'hello',
          'encoding_format': 'int8',
        }),
        400,
        'invalid_request_error',
        "encoding_format must be 'float' or 'base64'",
      );
    });

    for (final dimensions in <Object>[0, -3, 1.5, '256']) {
      test('rejects dimensions of $dimensions', () async {
        await _expectError(
          await _post('/v1/embeddings', {
            'model': 'any',
            'input': 'hello',
            'dimensions': dimensions,
          }),
          400,
          'invalid_request_error',
          'dimensions must be a positive integer',
        );
      });
    }

    test('is 404 for a model that is not downloaded', () async {
      // A valid request otherwise: base64 and dimensions both pass checks.
      await _expectError(
        await _post('/v1/embeddings', {
          'model': 'Nomic',
          'input': ['a', 'b'],
          'encoding_format': 'base64',
          'dimensions': 64,
        }),
        404,
        'not_found',
        'model not found: Nomic',
      );
    });

    test('is 404 with no model named and none downloaded', () async {
      await _expectError(
        await _post('/v1/embeddings', {'input': 'hello'}),
        404,
        'not_found',
        'model not found: null',
      );
    });
  });

  group('POST /v1/chat/completions', () {
    test('rejects a message role that is not a string', () async {
      await _expectError(
        await _post('/v1/chat/completions', {
          'model': 'any',
          'messages': [
            {'role': 1, 'content': 'hi'},
          ],
        }),
        400,
        'invalid_request_error',
        'message role must be a string',
      );
    });

    test('rejects audio content', () async {
      await _expectError(
        await _post('/v1/chat/completions', {
          'model': 'any',
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'input_audio', 'input_audio': {}},
              ],
            },
          ],
        }),
        400,
        'invalid_request_error',
      );
    });

    test('rejects a tool without a function name', () async {
      await _expectError(
        await _post('/v1/chat/completions', {
          'model': 'any',
          'messages': _hi,
          'tools': [
            {'type': 'function', 'function': {}},
          ],
        }),
        400,
        'invalid_request_error',
      );
    });

    test('rejects an unknown tool_choice string', () async {
      await _expectError(
        await _post('/v1/chat/completions', {
          'model': 'any',
          'messages': _hi,
          'tool_choice': 'always',
        }),
        400,
        'invalid_request_error',
      );
    });

    test('rejects more than four stop sequences', () async {
      // Stricter than the Ollama routes, which drop a bad stop list instead.
      await _expectError(
        await _post('/v1/chat/completions', {
          'model': 'any',
          'messages': _hi,
          'stop': ['a', 'b', 'c', 'd', 'e'],
        }),
        400,
        'invalid_request_error',
        'stop accepts at most 4 sequences',
      );
    });

    test('rejects a tool_choice naming a tool not in tools', () async {
      // Checked before the model is looked up, so the 400 wins over a 404.
      await _expectError(
        await _post('/v1/chat/completions', {
          'model': 'missing',
          'messages': _hi,
          'tools': [_tool('get_weather')],
          'tool_choice': {
            'type': 'function',
            'function': {'name': 'get_time'},
          },
        }),
        400,
        'invalid_request_error',
        'tool_choice names get_time, which is not in tools',
      );
    });

    test('rejects a named tool_choice when no tools are sent', () async {
      await _expectError(
        await _post('/v1/chat/completions', {
          'model': 'missing',
          'messages': _hi,
          'tool_choice': {
            'type': 'function',
            'function': {'name': 'get_time'},
          },
        }),
        400,
        'invalid_request_error',
      );
    });

    test(
      'is 404 when a named tool_choice matches but the model is missing',
      () async {
        await _expectError(
          await _post('/v1/chat/completions', {
            'model': 'missing',
            'messages': _hi,
            'tools': [_tool('get_weather'), _tool('get_time')],
            'tool_choice': {
              'type': 'function',
              'function': {'name': 'get_time'},
            },
          }),
          404,
          'not_found',
          'model not found: missing',
        );
      },
    );

    test('is 404 for a model that is not downloaded', () async {
      await _expectError(
        await _post('/v1/chat/completions', {
          'model': 'Missing',
          'messages': _hi,
          'stream': true,
          'stream_options': {'include_usage': true},
          'stop': 'END',
          'tool_choice': 'auto',
        }),
        404,
        'not_found',
        'model not found: Missing',
      );
    });

    test('does not activate a model it could not find', () async {
      await _post('/v1/chat/completions', {
        'model': 'missing',
        'messages': _hi,
      });
      expect(LlmEngine.instance.activeModelPath, isNull);
    });
  });

  group('routing', () {
    test('does not answer Ollama paths', () async {
      final res = await _get('/api/tags');
      expect(res.statusCode, 404);
    });
  });
}
