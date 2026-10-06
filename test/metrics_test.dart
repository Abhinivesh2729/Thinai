import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/llm/llm_engine.dart';
import 'package:local_llm/models_repo/catalog.dart';

void main() {
  group('LlmStats.tokensPerSecond', () {
    test('is null until there are two tokens to measure between', () {
      expect(const LlmStats().tokensPerSecond, isNull);
      expect(
        const LlmStats(
          tokens: 1,
          decodeTime: Duration(seconds: 1),
        ).tokensPerSecond,
        isNull,
      );
    });

    test('measures the gaps between tokens, not the tokens', () {
      // 11 tokens with 10 gaps over 1 second is 10 tok/s. Counting tokens
      // instead of gaps would report 11 and quietly credit the model for the
      // prompt-processing time that produced the first one.
      const stats = LlmStats(tokens: 11, decodeTime: Duration(seconds: 1));
      expect(stats.tokensPerSecond, closeTo(10, 1e-9));
    });

    test('is null when no decode time has elapsed', () {
      expect(const LlmStats(tokens: 5).tokensPerSecond, isNull);
    });
  });

  group('CatalogModel.contextLabel', () {
    CatalogModel withContext(int tokens) => CatalogModel(
      id: 'x',
      displayName: 'X',
      author: 'X',
      url: 'https://example.invalid/x.gguf',
      filename: 'x.gguf',
      approxBytes: 1,
      parameters: '1 B',
      contextTokens: tokens,
      description: 'x',
      accent: const Color(0xFF000000),
      emoji: 'x',
    );

    test('shows small windows as a plain token count', () {
      expect(withContext(512).contextLabel, '512');
    });

    test('shows larger windows in K', () {
      expect(withContext(2048).contextLabel, '2K');
      expect(withContext(32768).contextLabel, '32K');
      expect(withContext(131072).contextLabel, '128K');
      expect(withContext(262144).contextLabel, '256K');
    });

    test('keeps one decimal for windows that are not whole K', () {
      expect(withContext(1536).contextLabel, '1.5K');
    });

    test('shows million-token windows in M', () {
      expect(withContext(1048576).contextLabel, '1M');
      expect(withContext(1572864).contextLabel, '1.5M');
    });
  });

  group('catalog', () {
    test('every model declares a context window', () {
      for (final m in modelCatalog) {
        expect(m.contextTokens, greaterThan(0), reason: m.id);
      }
    });

    test('the starter model is the smallest chat download', () {
      final pick = starterModel;
      expect(pick, isNotNull);
      expect(pick!.kind, ModelKind.chat);
      for (final m in chatCatalog) {
        expect(m.approxBytes, greaterThanOrEqualTo(pick.approxBytes));
      }
    });

    test('chat and embedding catalogs do not overlap', () {
      final chat = {for (final m in chatCatalog) m.id};
      final embedding = {for (final m in embeddingCatalog) m.id};
      expect(chat.intersection(embedding), isEmpty);
      expect(chat.length + embedding.length, modelCatalog.length);
    });
  });
}
