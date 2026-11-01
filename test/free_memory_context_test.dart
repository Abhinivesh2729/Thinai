import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/llm/context_limits.dart';
import 'package:local_llm/llm/generation_settings.dart';
import 'package:local_llm/llm/llm_engine.dart';
import 'package:local_llm/models_repo/gguf_metadata.dart';
import 'package:local_llm/models_repo/model_store.dart';

import 'context_limits_test.dart' show ggufHeader;

const _mb = 1024 * 1024;
const _gb = 1024 * _mb;

void main() {
  group('freeMemoryContextCap', () {
    const kv = 100 * 1024; // 100 KB of cache per token

    test('is null when the cache size per token is unknown', () {
      expect(
        freeMemoryContextCap(availableBytes: 4 * _gb, fileBytes: _gb),
        isNull,
      );
      expect(
        freeMemoryContextCap(
          availableBytes: 4 * _gb,
          fileBytes: _gb,
          kvBytesPerToken: 0,
        ),
        isNull,
      );
    });

    test('counts weights and compute buffers, then snaps down to a step', () {
      // Room for 3,000 tokens of cache: the step below is 2048.
      final available = _gb + kContextOverheadBytes + 3000 * kv;
      expect(
        freeMemoryContextCap(
          availableBytes: available,
          fileBytes: _gb,
          kvBytesPerToken: kv,
        ),
        2048,
      );
    });

    test('never goes below the smallest window', () {
      expect(
        freeMemoryContextCap(
          availableBytes: 500 * _mb,
          fileBytes: 2 * _gb,
          kvBytesPerToken: kv,
        ),
        kMinContextSize,
      );
    });
  });

  group('LlmEngine resident model', () {
    final engine = LlmEngine.instance;
    late Future<int> Function({String? keepModelPath}) originalRelease;
    late DateTime Function() originalClock;
    late List<String?> released;
    var now = DateTime(2026, 11, 1, 12);

    setUp(() {
      originalRelease = engine.releaseIdleModels;
      originalClock = engine.clock;
      released = [];
      engine.releaseIdleModels = ({String? keepModelPath}) async {
        released.add(keepModelPath);
        return 0;
      };
      engine.clock = () => now;
      engine.setActiveModel(null);
      released.clear();
    });

    tearDown(() {
      engine.setActiveModel(null);
      engine.releaseIdleModels = originalRelease;
      engine.clock = originalClock;
    });

    test('keeps its context while running and for a while after', () {
      engine.markResident('/m/a.gguf', 4096, running: true);
      now = now.add(const Duration(minutes: 10));
      expect(engine.residentContext('/m/a.gguf'), 4096);

      engine.markResident('/m/a.gguf', 4096);
      now = now.add(const Duration(seconds: 99));
      expect(engine.residentContext('/m/a.gguf'), 4096);
      expect(engine.residentContext('/m/b.gguf'), isNull);

      now = now.add(LlmEngine.residentWindow);
      expect(engine.residentContext('/m/a.gguf'), isNull);
    });

    test('switching models unloads the old one at once', () async {
      engine.setActiveModel('/m/a.gguf');
      engine.markResident('/m/a.gguf', 4096);
      engine.setActiveModel('/m/b.gguf');
      await Future<void>.delayed(Duration.zero);

      expect(released.last, '/m/b.gguf');
      expect(engine.residentContext('/m/a.gguf'), isNull);
    });

    test('setting the same model again unloads nothing', () async {
      engine.setActiveModel('/m/a.gguf');
      await Future<void>.delayed(Duration.zero);
      released.clear();
      engine.setActiveModel('/m/a.gguf', projectorPath: '/m/p.gguf');
      await Future<void>.delayed(Duration.zero);
      expect(released, isEmpty);
    });

    test('a running model is not forgotten by a release', () async {
      engine.markResident('/m/a.gguf', 2048, running: true);
      await engine.releaseIdle();
      expect(engine.residentContext('/m/a.gguf'), 2048);
    });

    test('a native failure to unload is not fatal', () async {
      engine.releaseIdleModels = ({String? keepModelPath}) async =>
          throw StateError('no native library');
      await engine.releaseIdle(keep: '/m/a.gguf');
    });
  });

  group('GenerationSettingsStore.fitToFreeMemory', () {
    final store = GenerationSettingsStore.instance;
    final engine = LlmEngine.instance;
    late Directory dir;
    late LocalModel model;
    late int kv;
    late Future<int?> Function() originalRead;
    late Future<int> Function({String? keepModelPath}) originalRelease;
    late List<String?> released;
    int? available;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('free_memory_context_test');
      final file = File('${dir.path}/qwen.gguf')
        ..writeAsBytesSync(
          ggufHeader([
            ('general.architecture', 8, 'qwen2'),
            ('qwen2.block_count', 4, 24),
            ('qwen2.attention.head_count', 4, 14),
            ('qwen2.attention.head_count_kv', 4, 2),
            ('qwen2.embedding_length', 4, 896),
          ]),
        );
      kv = (await readGgufInfo(file.path))!.kvBytesPerToken!;
      // Pretend the weights are 1 GB; only the header needs to be real.
      model = LocalModel(
        id: 'qwen',
        displayName: 'qwen',
        path: file.path,
        sizeBytes: _gb,
        modifiedAt: DateTime(2026),
      );
      originalRead = store.readAvailableBytes;
      originalRelease = engine.releaseIdleModels;
      released = [];
      available = null;
      store.readAvailableBytes = () async => available;
      engine.releaseIdleModels = ({String? keepModelPath}) async {
        released.add(keepModelPath);
        return 0;
      };
      engine.setActiveModel(null);
      await Future<void>.delayed(Duration.zero);
      released.clear();
    });

    tearDown(() {
      store.readAvailableBytes = originalRead;
      engine.releaseIdleModels = originalRelease;
      engine.setActiveModel(null);
      dir.deleteSync(recursive: true);
    });

    test('leaves the window alone where memory cannot be read', () async {
      expect(await store.fitToFreeMemory(model, 8192), 8192);
      expect(released, isEmpty);
    });

    test('unloads idle models before measuring', () async {
      available = 16 * _gb;
      expect(await store.fitToFreeMemory(model, 8192), 8192);
      expect(released, [null]);
    });

    test('shrinks the window to what fits beside the weights', () async {
      // Room for 3,000 tokens of cache after weights and compute buffers.
      available = _gb + kContextOverheadBytes + 3000 * kv;
      expect(await store.fitToFreeMemory(model, 8192), 2048);
    });

    test('falls to the smallest window when the weights barely fit', () async {
      available = _gb;
      expect(await store.fitToFreeMemory(model, 8192), kMinContextSize);
    });

    test(
      'a loaded model keeps its window rather than being reloaded',
      () async {
        available = _gb; // its own footprint makes free memory look tiny
        engine.markResident(model.path, 4096);
        expect(await store.fitToFreeMemory(model, 8192), 4096);
        expect(await store.fitToFreeMemory(model, 2048), 2048);
        expect(released, isEmpty);
      },
    );

    test('a model whose cache size is unknown keeps its window', () async {
      final plain = File('${dir.path}/plain.gguf')..writeAsStringSync('x');
      final unknown = LocalModel(
        id: 'plain',
        displayName: 'plain',
        path: plain.path,
        sizeBytes: _gb,
        modifiedAt: DateTime(2026),
      );
      available = _gb;
      expect(await store.fitToFreeMemory(unknown, 8192), 8192);
    });
  });
}
