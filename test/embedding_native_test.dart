@Tags(['native'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/llm/llm_engine.dart';

/// End-to-end test of the embedding path: real GGUF, real llama.cpp forward
/// pass, real vectors, via the fllama_embed bridge in third_party/fllama.
///
/// Downloads a 24 MB model on first run and caches it in the system temp dir.
/// Excluded from the default run because of that download; run with:
///   flutter test --tags native
void main() {
  // all-MiniLM-L6-v2 Q8_0: 24 MB, 384 dims. Smallest real embedding model in
  // the catalog, which keeps this test cheap.
  const url =
      'https://huggingface.co/leliuga/all-MiniLM-L6-v2-GGUF/resolve/main/all-MiniLM-L6-v2.Q8_0.gguf';
  const dimensions = 384;

  // Downloaded once, lazily, and shared by every test below.
  Future<String>? modelFuture;
  Future<String> ensureModel() => modelFuture ??= () async {
        final dir = Directory('${Directory.systemTemp.path}/thanai_test_models');
        await dir.create(recursive: true);
        final file = File('${dir.path}/all-MiniLM-L6-v2.Q8_0.gguf');

        if (!await file.exists() || await file.length() < 1024 * 1024) {
          final client = HttpClient();
          final req = await client.getUrl(Uri.parse(url));
          final res = await req.close();
          if (res.statusCode != 200) {
            throw StateError('model download failed: HTTP ${res.statusCode}');
          }
          await res.pipe(file.openWrite());
          client.close();
        }
        return file.path;
      }();

  double dot(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  test('produces one L2-normalized vector of the model dimension per input',
      () async {
    final result = await LlmEngine.instance.embedBatch(
      ['hello world'],
      modelPath: await ensureModel(),
    );

    expect(result.embeddings, hasLength(1));
    expect(result.dimensions, dimensions);
    expect(result.embeddings.first, hasLength(dimensions));
    expect(result.tokenCounts.first, greaterThan(0));

    // Not all zeros / NaN, i.e. an actual forward pass happened.
    expect(result.embeddings.first.any((v) => v != 0.0), isTrue);
    expect(result.embeddings.first.every((v) => v.isFinite), isTrue);

    // Default normalization is L2, so the vector is unit length.
    final norm = math.sqrt(dot(result.embeddings.first, result.embeddings.first));
    expect(norm, closeTo(1.0, 1e-4));
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('is deterministic for the same input', () async {
    final a = await LlmEngine.instance.embedBatch(['repeatable'],
        modelPath: await ensureModel());
    final b = await LlmEngine.instance.embedBatch(['repeatable'],
        modelPath: await ensureModel());
    expect(dot(a.embeddings.first, b.embeddings.first), closeTo(1.0, 1e-4));
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('batches inputs and keeps them in request order', () async {
    // The ordering guarantee matters: wait_for_all() does not preserve order,
    // so fllama_embed.cpp sorts by task index. If that sort regressed, the
    // vector for "a cat sitting on a mat" would come back against the wrong
    // input and this assertion would fail.
    const inputs = [
      'a cat sitting on a mat',
      'quantum chromodynamics and gauge theory',
      'a kitten resting on a rug',
    ];
    final batch = await LlmEngine.instance.embedBatch(
      inputs,
      modelPath: await ensureModel(),
    );
    expect(batch.embeddings, hasLength(3));
    expect(batch.tokenCounts, hasLength(3));

    // Each batched vector must match what a single-input call returns.
    for (var i = 0; i < inputs.length; i++) {
      final single = await LlmEngine.instance.embedBatch(
        [inputs[i]],
        modelPath: await ensureModel(),
      );
      expect(
        dot(batch.embeddings[i], single.embeddings.first),
        closeTo(1.0, 1e-3),
        reason: 'batch[$i] does not match a single embed of "${inputs[i]}"',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 8)));

  test('vectors are semantically meaningful, not noise', () async {
    // The real check that this is an embedding and not garbage: related
    // sentences must land closer together than unrelated ones.
    final r = await LlmEngine.instance.embedBatch(
      [
        'a cat sitting on a mat',
        'a kitten resting on a rug',
        'quantum chromodynamics and gauge theory',
      ],
      modelPath: await ensureModel(),
    );

    final catVsKitten = dot(r.embeddings[0], r.embeddings[1]);
    final catVsPhysics = dot(r.embeddings[0], r.embeddings[2]);

    expect(
      catVsKitten,
      greaterThan(catVsPhysics),
      reason: 'cat~kitten ($catVsKitten) should beat cat~physics '
          '($catVsPhysics)',
    );
    expect(catVsKitten, greaterThan(0.5));
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('rejects an empty input list', () async {
    final path = await ensureModel();
    expect(
      () => LlmEngine.instance.embedBatch([], modelPath: path),
      throwsA(isA<EmbeddingException>()),
    );
  });
}
