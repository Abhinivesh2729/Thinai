import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/catalog.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/ui/widgets/model_brand_logo.dart';

CatalogModel _catalog({
  required String id,
  String name = 'Model',
  String author = 'someone',
  ModelKind kind = ModelKind.chat,
}) => CatalogModel(
  id: id,
  displayName: name,
  author: author,
  url: 'https://example.invalid/$id.gguf',
  filename: '$id.gguf',
  approxBytes: 1 << 30,
  parameters: '1B',
  contextTokens: 4096,
  description: '',
  accent: const Color(0xFF000000),
  emoji: '',
  kind: kind,
);

LocalModel _local(String id, {String? name}) => LocalModel(
  id: id,
  displayName: name ?? '$id.gguf',
  path: '/nowhere/$id.gguf',
  sizeBytes: 1 << 30,
  modifiedAt: DateTime(2026, 1, 1),
);

void main() {
  group('catalogModelLogoAsset', () {
    test('maps known families by id, name or author', () {
      final cases = <CatalogModel, String>{
        _catalog(id: 'gemma-3-1b'): 'gemma',
        _catalog(id: 'x', author: 'Google'): 'google',
        _catalog(id: 'llama-3.2-1b'): 'meta',
        _catalog(id: 'x', author: 'Meta'): 'meta',
        _catalog(id: 'phi-4-mini'): 'microsoft',
        _catalog(id: 'x', name: 'Qwen3 1.7B'): 'qwen',
        _catalog(id: 'x', author: 'Alibaba Cloud'): 'qwen',
        _catalog(id: 'deepseek-coder'): 'deepseek',
        _catalog(id: 'ministral-3b'): 'mistral',
        _catalog(id: 'smollm2-360m'): 'huggingface',
        _catalog(id: 'granite-3.3-2b'): 'ibm',
        _catalog(id: 'lfm2.5-350m'): 'liquid',
        _catalog(id: 'nomic-embed', kind: ModelKind.embedding): 'nomic',
        _catalog(id: 'bge-small', kind: ModelKind.embedding): 'baai',
      };
      cases.forEach((model, brand) {
        expect(
          catalogModelLogoAsset(model),
          'assets/logos/$brand.png',
          reason: model.id,
        );
      });
    });

    test('gemma wins over the generic Google author', () {
      expect(
        catalogModelLogoAsset(_catalog(id: 'gemma-2b', author: 'google')),
        'assets/logos/gemma.png',
      );
    });

    test('returns null for an unknown family', () {
      expect(catalogModelLogoAsset(_catalog(id: 'mystery-7b')), isNull);
    });

    test('every mapped logo exists as an asset', () {
      for (final m in [...chatCatalog, ...embeddingCatalog]) {
        final asset = catalogModelLogoAsset(m);
        if (asset == null) continue;
        expect(File(asset).existsSync(), isTrue, reason: '${m.id} -> $asset');
      }
    });
  });

  group('localModelLogoAsset', () {
    test('maps known families by file id or name', () {
      final cases = <LocalModel, String>{
        _local('gemma-3-270m-it-q8_0'): 'gemma',
        _local('google-thing'): 'google',
        _local('llama-3.2-1b-instruct-q4_k_m'): 'meta',
        _local('phi-4-mini-q4'): 'microsoft',
        _local('qwen3-0.6b-q8_0'): 'qwen',
        _local('deepseek-r1-distill'): 'deepseek',
        _local('mistral-7b'): 'mistral',
        _local('smollm2-135m'): 'huggingface',
        _local('granite-3.3-2b'): 'ibm',
        _local('lfm2-350m'): 'liquid',
        _local('nomic-embed-text'): 'nomic',
        _local('x', name: 'bge-small-en.gguf'): 'baai',
      };
      cases.forEach((model, brand) {
        expect(
          localModelLogoAsset(model),
          'assets/logos/$brand.png',
          reason: model.id,
        );
      });
    });

    test('returns null for an unknown file', () {
      expect(localModelLogoAsset(_local('my-finetune')), isNull);
    });
  });

  group('modelFallbackVectorIcon', () {
    test('embedding and vision take priority', () {
      expect(
        modelFallbackVectorIcon(
          id: 'coder',
          name: 'Coder',
          kind: ModelKind.embedding,
        ),
        Icons.hub_rounded,
      );
      expect(
        modelFallbackVectorIcon(id: 'coder', name: 'Coder', hasVision: true),
        Icons.visibility_rounded,
      );
    });

    test('code, reasoning and default icons', () {
      expect(
        modelFallbackVectorIcon(id: 'qwen-code', name: 'Qwen'),
        Icons.code_rounded,
      );
      expect(
        modelFallbackVectorIcon(id: 'x', name: 'DeepSeek'),
        Icons.psychology_rounded,
      );
      expect(
        modelFallbackVectorIcon(id: 'reasoner', name: 'X'),
        Icons.psychology_rounded,
      );
      expect(
        modelFallbackVectorIcon(id: 'plain', name: 'Plain'),
        Icons.smart_toy_rounded,
      );
    });
  });

  group('ModelBrandLogo widget', () {
    testWidgets('shows the brand image for a known catalog model', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModelBrandLogo.catalog(model: _catalog(id: 'gemma-3-1b')),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('falls back to an icon for an unknown local model', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ModelBrandLogo.local(model: _local('my-finetune'))),
      );
      expect(find.byType(Image), findsNothing);
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
