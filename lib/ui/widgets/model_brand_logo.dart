import 'package:flutter/material.dart';

import '../../models_repo/catalog.dart';
import '../../models_repo/model_store.dart';

/// Finds the official real brand logo asset for a [CatalogModel].
String? catalogModelLogoAsset(CatalogModel m) {
  final author = m.author.toLowerCase();
  final id = m.id.toLowerCase();
  final name = m.displayName.toLowerCase();

  // Gemma (Google)
  if (id.contains('gemma') || name.contains('gemma')) {
    return 'assets/logos/gemma.png';
  }
  // Google
  if (author.contains('google')) {
    return 'assets/logos/google.png';
  }
  // Meta / Llama
  if (author.contains('meta') || id.contains('llama') || name.contains('llama')) {
    return 'assets/logos/meta.png';
  }
  // Microsoft / Phi
  if (author.contains('microsoft') || id.contains('phi') || name.contains('phi')) {
    return 'assets/logos/microsoft.png';
  }
  // Alibaba / Qwen
  if (author.contains('alibaba') || id.contains('qwen') || name.contains('qwen')) {
    return 'assets/logos/qwen.png';
  }
  // DeepSeek
  if (author.contains('deepseek') ||
      id.contains('deepseek') ||
      name.contains('deepseek') ||
      id.contains('r1')) {
    return 'assets/logos/deepseek.png';
  }
  // Mistral AI
  if (author.contains('mistral') ||
      id.contains('mistral') ||
      name.contains('mistral') ||
      id.contains('ministral')) {
    return 'assets/logos/mistral.png';
  }
  // Hugging Face / SmolLM
  if (author.contains('hugging') || id.contains('smollm') || name.contains('smollm')) {
    return 'assets/logos/huggingface.png';
  }
  // IBM Granite
  if (author.contains('ibm') || id.contains('granite') || name.contains('granite')) {
    return 'assets/logos/ibm.png';
  }
  // Liquid AI
  if (author.contains('liquid') || id.contains('lfm') || name.contains('lfm')) {
    return 'assets/logos/liquid.png';
  }
  // Nomic AI
  if (author.contains('nomic') || id.contains('nomic') || name.contains('nomic')) {
    return 'assets/logos/nomic.png';
  }
  // BAAI
  if (author.contains('baai') || id.contains('bge') || name.contains('bge')) {
    return 'assets/logos/baai.png';
  }
  return null;
}

/// Finds the official real brand logo asset for a [LocalModel].
String? localModelLogoAsset(LocalModel m) {
  final id = m.id.toLowerCase();
  final name = m.displayName.toLowerCase();

  if (id.contains('gemma') || name.contains('gemma')) return 'assets/logos/gemma.png';
  if (id.contains('google')) return 'assets/logos/google.png';
  if (id.contains('llama') || name.contains('llama')) return 'assets/logos/meta.png';
  if (id.contains('phi') || name.contains('phi')) return 'assets/logos/microsoft.png';
  if (id.contains('qwen') || name.contains('qwen')) return 'assets/logos/qwen.png';
  if (id.contains('deepseek') || name.contains('deepseek') || id.contains('r1')) {
    return 'assets/logos/deepseek.png';
  }
  if (id.contains('mistral') || name.contains('mistral') || id.contains('ministral')) {
    return 'assets/logos/mistral.png';
  }
  if (id.contains('smollm') || name.contains('smollm')) {
    return 'assets/logos/huggingface.png';
  }
  if (id.contains('granite') || name.contains('granite')) return 'assets/logos/ibm.png';
  if (id.contains('lfm') || name.contains('lfm')) return 'assets/logos/liquid.png';
  if (id.contains('nomic') || name.contains('nomic')) return 'assets/logos/nomic.png';
  if (id.contains('bge') || name.contains('bge')) return 'assets/logos/baai.png';
  return null;
}

/// Fallback vector icon when a logo asset is not available.
IconData modelFallbackVectorIcon({
  required String id,
  required String name,
  ModelKind kind = ModelKind.chat,
  bool hasVision = false,
}) {
  if (kind == ModelKind.embedding) return Icons.hub_rounded;
  if (hasVision) return Icons.visibility_rounded;
  final lowerId = id.toLowerCase();
  final lowerName = name.toLowerCase();
  if (lowerId.contains('code') || lowerName.contains('coder') || lowerName.contains('coding')) {
    return Icons.code_rounded;
  }
  if (lowerId.contains('r1') || lowerId.contains('reason') || lowerName.contains('deepseek')) {
    return Icons.psychology_rounded;
  }
  return Icons.smart_toy_rounded;
}

/// Renders the real, authentic brand logo for a model with graceful fallback.
class ModelBrandLogo extends StatelessWidget {
  final CatalogModel? catalogModel;
  final LocalModel? localModel;
  final double size;

  const ModelBrandLogo.catalog({
    super.key,
    required CatalogModel model,
    this.size = 28,
  })  : catalogModel = model,
        localModel = null;

  const ModelBrandLogo.local({
    super.key,
    required LocalModel model,
    this.size = 28,
  })  : localModel = model,
        catalogModel = null;

  @override
  Widget build(BuildContext context) {
    final asset = catalogModel != null
        ? catalogModelLogoAsset(catalogModel!)
        : (localModel != null ? localModelLogoAsset(localModel!) : null);

    if (asset != null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final cacheDim = (size * 2.5).round().clamp(48, 128);
      Widget image = Image.asset(
        asset,
        width: size,
        height: size,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );

      // Adaptive coloring for monochrome logos (e.g. Nomic) for optimal dark/light contrast
      if (asset.contains('nomic')) {
        image = ColorFiltered(
          colorFilter: ColorFilter.mode(
            isDark ? Colors.white : const Color(0xFF1E293B),
            BlendMode.srcIn,
          ),
          child: image,
        );
      }

      return image;
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = catalogModel != null
        ? modelFallbackVectorIcon(
            id: catalogModel!.id,
            name: catalogModel!.displayName,
            kind: catalogModel!.kind,
            hasVision: catalogModel!.mmprojUrl != null,
          )
        : modelFallbackVectorIcon(
            id: localModel?.id ?? '',
            name: localModel?.displayName ?? '',
          );

    return Icon(
      icon,
      size: size * 0.85,
      color: catalogModel?.accent ?? scheme.primary,
    );
  }
}
