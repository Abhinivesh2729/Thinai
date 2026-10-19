import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';

import 'package:local_llm/llm/llm_engine.dart';
import 'package:local_llm/server/routes/ollama_routes.dart';

/// Unit tests for the Ollama-compatible routes, calling the router directly.
///
/// None of these reach llama.cpp. Every request here either fails validation
/// or names a model that is not on disk, because a request that resolves a
/// model goes straight into LlmEngine and the native bridge, which has no
/// seam to stub. Those paths are covered by the `native` tagged tests.

late Directory _support;

Directory get _modelsDir => Directory('${_support.path}/models');

/// Builds a GGUF v3 header with string (8) and u32 (4) values only, which is
/// all the sizing reader needs. Same layout as context_limits_test.dart.
Uint8List _ggufHeader(List<(String, int, Object)> kvs) {
  final out = BytesBuilder();
  void u32(int v) => out.add(
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List(),
  );
  void u64(int v) => out.add(
    (ByteData(8)..setUint64(0, v, Endian.little)).buffer.asUint8List(),
  );
  void str(String s) {
    final b = utf8.encode(s);
    u64(b.length);
    out.add(b);
  }

  u32(0x46554747);
  u32(3);
  u64(0);
  u64(kvs.length);
  for (final (key, type, value) in kvs) {
    str(key);
    u32(type);
    switch (type) {
      case 4:
        u32(value as int);
      case 8:
        str(value as String);
      default:
        throw ArgumentError('type $type');
    }
  }
  return out.toBytes();
}

Future<File> _addModel(String filename, List<int> bytes) async {
  await _modelsDir.create(recursive: true);
  final file = File('${_modelsDir.path}/$filename');
  await file.writeAsBytes(bytes);
  return file;
}

Future<Response> _get(String path) =>
    ollamaRouter().call(Request('GET', Uri.parse('http://localhost$path')));

Future<Response> _post(String path, Object? body) => ollamaRouter().call(
  Request(
    'POST',
    Uri.parse('http://localhost$path'),
    body: body is String ? body : jsonEncode(body),
  ),
);

Future<Map<String, dynamic>> _json(Response res) async =>
    jsonDecode(await res.readAsString()) as Map<String, dynamic>;

void main() {
  setUpAll(() async {
    _support = await Directory.systemTemp.createTemp('thinai_ollama_routes_');
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

  group('GET /api/tags', () {
    test('lists no models when none are downloaded', () async {
      final res = await _get('/api/tags');
      expect(res.statusCode, 200);
      expect(res.headers['content-type'], 'application/json');
      expect(await _json(res), {'models': []});
    });

    test('lists each model under its lowercased id', () async {
      await _addModel('Alpha-Q4.gguf', [1, 2, 3]);
      await _addModel('beta.gguf', [1, 2, 3, 4, 5]);

      final models = (await _json(await _get('/api/tags')))['models'] as List;

      expect(models.map((m) => m['name']), ['alpha-q4', 'beta']);
      final beta = models[1] as Map;
      expect(beta['model'], 'beta');
      expect(beta['size'], 5);
      expect(beta['details']['format'], 'gguf');
      expect(DateTime.parse(beta['modified_at'] as String).isUtc, isTrue);
    });

    test('leaves image encoders and partial downloads out', () async {
      await _addModel('model.gguf', [1]);
      await _addModel('mmproj-model.gguf', [1]);
      await _addModel('other.gguf.part', [1]);

      final models = (await _json(await _get('/api/tags')))['models'] as List;

      expect(models.map((m) => m['name']), ['model']);
    });
  });

  group('GET /api/ps', () {
    test('is empty when no model is active', () async {
      LlmEngine.instance.setActiveModel(null);
      expect(await _json(await _get('/api/ps')), {'models': []});
    });

    test('names the active model by its file name', () async {
      LlmEngine.instance.setActiveModel('/data/models/Qwen2.5-0.5B.GGUF');

      final models = (await _json(await _get('/api/ps')))['models'] as List;

      expect(models, [
        {'name': 'qwen2.5-0.5b', 'model': 'qwen2.5-0.5b', 'size': 0},
      ]);
    });

    test('handles Windows separators and names without .gguf', () async {
      LlmEngine.instance.setActiveModel(r'C:\models\Tiny');

      final models = (await _json(await _get('/api/ps')))['models'] as List;

      expect(models.single['name'], 'tiny');
    });
  });

  group('POST /api/show', () {
    test('needs a name', () async {
      final res = await _post('/api/show', '');
      expect(res.statusCode, 400);
      expect(await _json(res), {'error': 'name is required'});
    });

    test('rejects a name that is not a string', () async {
      final res = await _post('/api/show', {'name': 7});
      expect(res.statusCode, 400);
    });

    test('is 404 for a model that is not downloaded', () async {
      final res = await _post('/api/show', {'name': 'missing'});
      expect(res.statusCode, 404);
      expect(await _json(res), {'error': 'model not found'});
    });

    test('reports sizing from the GGUF header', () async {
      await _addModel(
        'qwen-tiny.gguf',
        _ggufHeader([
          ('general.architecture', 8, 'qwen2'),
          ('qwen2.context_length', 4, 32768),
          ('qwen2.block_count', 4, 24),
          ('qwen2.embedding_length', 4, 896),
        ]),
      );

      // `model` is accepted in place of `name`, and lookup ignores case.
      final res = await _post('/api/show', {'model': 'QWEN-TINY'});
      expect(res.statusCode, 200);
      final body = await _json(res);

      expect(body['details']['family'], 'qwen2');
      expect(body['details']['families'], ['qwen2']);
      final info = body['model_info'] as Map;
      expect(info['general.architecture'], 'qwen2');
      expect(info['qwen2.context_length'], 32768);
      expect(info['qwen2.block_count'], 24);
      expect(info['qwen2.embedding_length'], 896);
      expect(info['thinai.context_cap'], isA<int>());
      expect(info['thinai.context_cap'] as int, greaterThan(0));
    });

    test('falls back to llama when the header cannot be read', () async {
      final file = await _addModel('junk.gguf', utf8.encode('not a gguf'));

      final body = await _json(await _post('/api/show', {'name': 'junk'}));

      expect(body['details']['family'], 'llama');
      final info = body['model_info'] as Map;
      expect(info['size'], await file.length());
      expect(info.containsKey('llama.context_length'), isFalse);
      expect(info.containsKey('llama.block_count'), isFalse);
      expect(info.containsKey('llama.embedding_length'), isFalse);
    });
  });

  group('POST /api/generate', () {
    test('is 404 for a model that is not downloaded', () async {
      final res = await _post('/api/generate', {
        'model': 'Missing',
        'prompt': 'hi',
      });
      expect(res.statusCode, 404);
      expect(await _json(res), {'error': 'model not found: Missing'});
    });

    test('is 404 with no model named and none downloaded', () async {
      final res = await _post('/api/generate', {'prompt': 'hi'});
      expect(res.statusCode, 404);
    });

    test('treats an empty model name as unnamed', () async {
      final res = await _post('/api/generate', {'model': '', 'prompt': 'hi'});
      expect(res.statusCode, 404);
      expect(await _json(res), {'error': 'model not found: '});
    });
  });

  group('POST /api/chat', () {
    test('rejects a message that is not an object', () async {
      final res = await _post('/api/chat', {
        'model': 'any',
        'messages': ['hello'],
      });
      expect(res.statusCode, 400);
      expect(res.headers['content-type'], 'application/json');
      expect(await _json(res), {'error': 'each message must be an object'});
    });

    test('rejects tools that are not an array', () async {
      final res = await _post('/api/chat', {
        'model': 'any',
        'messages': [
          {'role': 'user', 'content': 'hi'},
        ],
        'tools': 'get_weather',
      });
      expect(res.statusCode, 400);
      expect(await _json(res), {'error': 'tools must be an array'});
    });

    test('rejects an image when no image encoder is loaded', () async {
      final res = await _post('/api/chat', {
        'model': 'any',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/png;base64,AAAA'},
              },
            ],
          },
        ],
      });
      expect(res.statusCode, 400);
      expect((await _json(res))['error'], contains('vision model'));
    });

    test('is 404 for a model that is not downloaded', () async {
      final res = await _post('/api/chat', {
        'model': 'missing',
        'messages': [
          {'role': 'user', 'content': 'hi'},
        ],
      });
      expect(res.statusCode, 404);
      expect(await _json(res), {'error': 'model not found: missing'});
    });

    test('is 404 with no messages and no model downloaded', () async {
      final res = await _post('/api/chat', {'model': 'missing'});
      expect(res.statusCode, 404);
    });
  });

  group('POST /api/embed', () {
    test('rejects a missing input', () async {
      final res = await _post('/api/embed', {'model': 'any'});
      expect(res.statusCode, 400);
      expect(res.headers['content-type'], 'application/json');
      expect(
        (await _json(res))['error'],
        'input is required and must be a string or an array of strings',
      );
    });

    test('rejects an empty input', () async {
      final res = await _post('/api/embed', {'model': 'any', 'input': ''});
      expect(res.statusCode, 400);
      expect(await _json(res), {'error': 'input must not be empty'});
    });

    test('rejects token arrays', () async {
      final res = await _post('/api/embed', {
        'model': 'any',
        'input': [1, 2, 3],
      });
      expect(res.statusCode, 400);
      expect(await _json(res), {
        'error': 'input array must contain only strings',
      });
    });

    test('is 404 for a model that is not downloaded', () async {
      final res = await _post('/api/embed', {
        'model': 'nomic',
        'input': ['a', 'b'],
      });
      expect(res.statusCode, 404);
      expect(res.headers['content-type'], 'application/json');
      expect(await _json(res), {'error': 'model not found: nomic'});
    });
  });

  group('POST /api/embeddings', () {
    test('needs a prompt', () async {
      final res = await _post('/api/embeddings', {'model': 'any'});
      expect(res.statusCode, 400);
      expect(res.headers['content-type'], 'application/json');
      expect(await _json(res), {'error': 'prompt is required'});
    });

    test('rejects an empty prompt', () async {
      final res = await _post('/api/embeddings', {
        'model': 'any',
        'prompt': '',
      });
      expect(res.statusCode, 400);
    });

    test('rejects a prompt that is not a string', () async {
      // The legacy endpoint takes one string; arrays belong to /api/embed.
      final res = await _post('/api/embeddings', {
        'model': 'any',
        'prompt': ['a'],
      });
      expect(res.statusCode, 400);
    });

    test('is 404 for a model that is not downloaded', () async {
      final res = await _post('/api/embeddings', {
        'model': 'nomic',
        'prompt': 'hello',
      });
      expect(res.statusCode, 404);
      expect(await _json(res), {'error': 'model not found: nomic'});
    });
  });

  group('routing', () {
    test('does not answer paths it does not own', () async {
      final res = await _get('/v1/models');
      expect(res.statusCode, 404);
    });
  });
}
