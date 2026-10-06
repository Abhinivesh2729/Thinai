import 'package:flutter/material.dart';

/// What a model can actually do. Chat models generate text (/api/chat,
/// /v1/chat/completions); embedding models produce vectors (/api/embed,
/// /v1/embeddings). They are not interchangeable in either direction: a chat
/// model has no pooling layer and is rejected by the embedding endpoints, and
/// an embedding model cannot generate text.
enum ModelKind { chat, embedding }

class CatalogModel {
  final String id;
  final String displayName;
  final String author;
  final String url;
  final String filename;
  final int approxBytes;
  final String parameters;

  /// Context window the model was trained for, in tokens. Shown on the model
  /// card because it is the number that decides how much a user can actually
  /// feed the model; the quantisation level is the same Q4_K_M for nearly
  /// every entry here and told the user nothing.
  final int contextTokens;
  final String description;
  final Color accent;
  final String emoji;
  final ModelKind kind;

  /// Output vector size, for [ModelKind.embedding] only. Null for chat models.
  final int? dimensions;

  /// Image encoder for a vision model — llama.cpp calls it the multimodal
  /// projector, and ships it as a second GGUF beside the weights.
  ///
  /// The weights alone cannot see: without this file the model loads and
  /// chats normally but has no way to turn pixels into tokens. Null on every
  /// text-only model.
  final String? mmprojUrl;
  final String? mmprojFilename;

  /// Download size of the projector. Worth showing separately — it is often
  /// half a gigabyte on top of the model itself.
  final int? mmprojBytes;

  const CatalogModel({
    required this.id,
    required this.displayName,
    required this.author,
    required this.url,
    required this.filename,
    required this.approxBytes,
    required this.parameters,
    required this.contextTokens,
    required this.description,
    required this.accent,
    required this.emoji,
    this.kind = ModelKind.chat,
    this.dimensions,
    this.mmprojUrl,
    this.mmprojFilename,
    this.mmprojBytes,
  });

  /// True when this model can read images, given its projector is downloaded.
  bool get supportsVision => mmprojUrl != null && mmprojFilename != null;

  /// Model plus projector, which is what a vision model actually costs.
  int get totalDownloadBytes => approxBytes + (mmprojBytes ?? 0);

  String get mmprojSize {
    final bytes = mmprojBytes;
    if (bytes == null) return '';
    final mb = bytes / (1024 * 1024);
    if (mb < 1024) return '${mb.toStringAsFixed(0)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }

  String get approxSize {
    final mb = approxBytes / (1024 * 1024);
    if (mb < 1024) return '${mb.toStringAsFixed(0)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }

  /// Context window as a short label: 512, 2K, 32K, 128K, 256K, 1M.
  String get contextLabel {
    if (contextTokens < 1024) return '$contextTokens';
    // Million-token windows exist in the catalog now. '1024K' is a number the
    // reader has to convert; '1M' is the one they already think in.
    if (contextTokens >= 1024 * 1024) {
      return '${_short(contextTokens / (1024 * 1024))}M';
    }
    return '${_short(contextTokens / 1024)}K';
  }

  static String _short(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  /// The id the HTTP API answers to once this model is downloaded.
  ///
  /// Not the same string as [id]: ModelStore derives ids from the file on
  /// disk, so the served id follows the upstream filename's punctuation
  /// (`nomic-embed-text-v1.5.Q5_K_M.gguf` serves as
  /// `nomic-embed-text-v1.5.q5_k_m`, with a dot where [id] has a dash).
  /// Anything quoting a model id at an endpoint must use this.
  String get servedId {
    final name = filename.toLowerCase();
    return name.endsWith('.gguf') ? name.substring(0, name.length - 5) : name;
  }
}

/// Chat models only: what the Chat tab and the completion endpoints can use.
///
/// Sorted smallest first: download size is the constraint a phone user picks
/// against, so the entries they can actually run come first. Sorting here
/// rather than relying on source order keeps the list right wherever a new
/// entry lands in [modelCatalog].
List<CatalogModel> get chatCatalog =>
    modelCatalog.where((m) => m.kind == ModelKind.chat).toList()
      ..sort((a, b) => a.approxBytes.compareTo(b.approxBytes));

/// Embedding models only: what /api/embed and /v1/embeddings can use.
/// Sorted smallest first, as [chatCatalog].
List<CatalogModel> get embeddingCatalog =>
    modelCatalog.where((m) => m.kind == ModelKind.embedding).toList()
      ..sort((a, b) => a.approxBytes.compareTo(b.approxBytes));

/// The model the app tour recommends to someone with nothing installed.
///
/// The smallest chat model in the catalog: the download has to finish on a
/// phone's data plan and the model has to load on a low-end device, which
/// makes size the only sensible criterion for a first pick.
CatalogModel? get starterModel {
  final chat = chatCatalog;
  return chat.isEmpty ? null : chat.first;
}

const modelCatalog = <CatalogModel>[
  CatalogModel(
    id: 'qwen2.5-0.5b-instruct-q4_k_m',
    displayName: 'Qwen 2.5 · 0.5B Instruct',
    author: 'Alibaba',
    url:
        'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
    filename: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
    approxBytes: 469 * 1024 * 1024,
    parameters: '0.5 B',
    contextTokens: 32768,
    description:
        'Tiny and fast. Runs on almost any phone. Good for testing and lightweight chat.',
    accent: Color(0xFF7C3AED),
    emoji: '🚀',
  ),
  CatalogModel(
    id: 'tinyllama-1.1b-chat-q4_k_m',
    displayName: 'TinyLlama · 1.1B Chat',
    author: 'TinyLlama',
    url:
        'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    filename: 'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    approxBytes: 638 * 1024 * 1024,
    parameters: '1.1 B',
    contextTokens: 2048,
    description:
        'Small chat model distilled for phones. Balanced speed vs quality.',
    accent: Color(0xFFF59E0B),
    emoji: '🦙',
  ),
  CatalogModel(
    id: 'llama-3.2-1b-instruct-q4_k_m',
    displayName: 'Llama 3.2 · 1B Instruct',
    author: 'Meta',
    url:
        'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
    filename: 'Llama-3.2-1B-Instruct-Q4_K_M.gguf',
    approxBytes: 770 * 1024 * 1024,
    parameters: '1 B',
    contextTokens: 131072,
    description:
        'Meta\'s mobile-tuned Llama 3.2. Strong instruction following at a small size.',
    accent: Color(0xFF2563EB),
    emoji: '🔷',
  ),
  CatalogModel(
    id: 'qwen2.5-1.5b-instruct-q4_k_m',
    displayName: 'Qwen 2.5 · 1.5B Instruct',
    author: 'Alibaba',
    url:
        'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
    filename: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
    approxBytes: 1066 * 1024 * 1024,
    parameters: '1.5 B',
    contextTokens: 32768,
    description:
        'Noticeable quality jump over 0.5B. Good sweet spot for mid-range phones.',
    accent: Color(0xFF7C3AED),
    emoji: '⚡',
  ),
  CatalogModel(
    id: 'gemma-2-2b-it-q4_k_m',
    displayName: 'Gemma 2 · 2B Instruct',
    author: 'Google',
    url:
        'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf',
    filename: 'gemma-2-2b-it-Q4_K_M.gguf',
    approxBytes: 1629 * 1024 * 1024,
    parameters: '2 B',
    contextTokens: 8192,
    description:
        'Google\'s efficient 2B model. High-quality reasoning for its size.',
    accent: Color(0xFF0EA5E9),
    emoji: '💎',
  ),
  CatalogModel(
    id: 'llama-3.2-3b-instruct-q4_k_m',
    displayName: 'Llama 3.2 · 3B Instruct',
    author: 'Meta',
    url:
        'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    filename: 'Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    approxBytes: 1926 * 1024 * 1024,
    parameters: '3 B',
    contextTokens: 131072,
    description:
        'Full-capability chat model. Needs a flagship phone for comfortable speed.',
    accent: Color(0xFF2563EB),
    emoji: '🧠',
  ),
  CatalogModel(
    id: 'phi-3.5-mini-instruct-q4_k_m',
    displayName: 'Phi-3.5 · Mini Instruct',
    author: 'Microsoft',
    url:
        'https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf',
    filename: 'Phi-3.5-mini-instruct-Q4_K_M.gguf',
    approxBytes: 2282 * 1024 * 1024,
    parameters: '3.8 B',
    contextTokens: 131072,
    description:
        'Microsoft\'s reasoning-focused mini model. Punches well above its size.',
    accent: Color(0xFF10B981),
    emoji: '🎯',
  ),
  CatalogModel(
    id: 'qwen3-0.6b-q8_0',
    displayName: 'Qwen 3 · 0.6B',
    author: 'Alibaba',
    url:
        'https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf',
    filename: 'Qwen3-0.6B-Q8_0.gguf',
    approxBytes: 610 * 1024 * 1024,
    parameters: '0.6 B',
    contextTokens: 32768,
    description:
        'Latest Qwen generation with hybrid thinking. Tiny, and Q8 keeps quality high.',
    accent: Color(0xFF7C3AED),
    emoji: '✨',
  ),
  CatalogModel(
    id: 'qwen3-1.7b-q8_0',
    displayName: 'Qwen 3 · 1.7B',
    author: 'Alibaba',
    url:
        'https://huggingface.co/Qwen/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q8_0.gguf',
    filename: 'Qwen3-1.7B-Q8_0.gguf',
    approxBytes: 1749 * 1024 * 1024,
    parameters: '1.7 B',
    contextTokens: 32768,
    description:
        'Strong reasoning for its size. A good default on a modern mid-range phone.',
    accent: Color(0xFF7C3AED),
    emoji: '🌟',
  ),
  CatalogModel(
    id: 'qwen3-4b-q4_k_m',
    displayName: 'Qwen 3 · 4B',
    author: 'Alibaba',
    url:
        'https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf',
    filename: 'Qwen3-4B-Q4_K_M.gguf',
    approxBytes: 2382 * 1024 * 1024,
    parameters: '4 B',
    contextTokens: 32768,
    description:
        'The original Qwen 3 at 4B. Flagship phone recommended; expect slower tokens.',
    accent: Color(0xFF6D28D9),
    emoji: '🧩',
  ),
  CatalogModel(
    id: 'gemma-3-1b-it-q4_k_m',
    displayName: 'Gemma 3 · 1B Instruct',
    author: 'Google',
    url:
        'https://huggingface.co/ggml-org/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf',
    filename: 'gemma-3-1b-it-Q4_K_M.gguf',
    approxBytes: 769 * 1024 * 1024,
    parameters: '1 B',
    contextTokens: 32768,
    description:
        'Google\'s newest small Gemma. 32K context and quick on modest hardware.',
    accent: Color(0xFF0EA5E9),
    emoji: '💠',
  ),
  CatalogModel(
    id: 'gemma-3-4b-it-q4_k_m',
    displayName: 'Gemma 3 · 4B Instruct',
    author: 'Google',
    url:
        'https://huggingface.co/ggml-org/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf',
    filename: 'gemma-3-4b-it-Q4_K_M.gguf',
    approxBytes: 2374 * 1024 * 1024,
    parameters: '4 B',
    contextTokens: 131072,
    description:
        'Gemma 3 at 4B: broad knowledge and long context. Best on flagship devices.',
    accent: Color(0xFF0284C7),
    emoji: '🔹',
    mmprojUrl:
        'https://huggingface.co/ggml-org/gemma-3-4b-it-GGUF/resolve/main/mmproj-model-f16.gguf',
    mmprojFilename: 'mmproj-gemma-3-4b-it-f16.gguf',
    mmprojBytes: 851251104,
  ),
  CatalogModel(
    id: 'smollm2-1.7b-instruct-q4_k_m',
    displayName: 'SmolLM2 · 1.7B Instruct',
    author: 'Hugging Face',
    url:
        'https://huggingface.co/bartowski/SmolLM2-1.7B-Instruct-GGUF/resolve/main/SmolLM2-1.7B-Instruct-Q4_K_M.gguf',
    filename: 'SmolLM2-1.7B-Instruct-Q4_K_M.gguf',
    approxBytes: 1007 * 1024 * 1024,
    parameters: '1.7 B',
    contextTokens: 8192,
    description:
        'Trained specifically for on-device use. Snappy, with a friendly chat style.',
    accent: Color(0xFFF59E0B),
    emoji: '🤗',
  ),
  CatalogModel(
    id: 'phi-4-mini-instruct-q4_k_m',
    displayName: 'Phi-4 · Mini Instruct',
    author: 'Microsoft',
    url:
        'https://huggingface.co/bartowski/microsoft_Phi-4-mini-instruct-GGUF/resolve/main/microsoft_Phi-4-mini-instruct-Q4_K_M.gguf',
    filename: 'microsoft_Phi-4-mini-instruct-Q4_K_M.gguf',
    approxBytes: 2376 * 1024 * 1024,
    parameters: '3.8 B',
    contextTokens: 131072,
    description:
        'Newest Phi generation. Excellent at maths and reasoning for its size.',
    accent: Color(0xFF10B981),
    emoji: '🎓',
  ),
  CatalogModel(
    id: 'gemma-3-270m-it-q8_0',
    displayName: 'Gemma 3 · 270M Instruct',
    author: 'Google',
    url:
        'https://huggingface.co/ggml-org/gemma-3-270m-it-GGUF/resolve/main/gemma-3-270m-it-Q8_0.gguf',
    filename: 'gemma-3-270m-it-Q8_0.gguf',
    approxBytes: 278 * 1024 * 1024,
    parameters: '270 M',
    contextTokens: 32768,
    description:
        'The smallest model here. Instant replies on any phone; best for simple tasks.',
    accent: Color(0xFF38BDF8),
    emoji: '🐣',
  ),
  CatalogModel(
    id: 'lfm2-1.2b-q4_k_m',
    displayName: 'LFM2 · 1.2B',
    author: 'Liquid AI',
    url:
        'https://huggingface.co/LiquidAI/LFM2-1.2B-GGUF/resolve/main/LFM2-1.2B-Q4_K_M.gguf',
    filename: 'LFM2-1.2B-Q4_K_M.gguf',
    approxBytes: 697 * 1024 * 1024,
    parameters: '1.2 B',
    contextTokens: 32768,
    description:
        'Built from the ground up for phones. Unusually fast decode for its quality.',
    accent: Color(0xFF06B6D4),
    emoji: '💧',
  ),
  CatalogModel(
    id: 'smollm3-3b-q4_k_m',
    displayName: 'SmolLM3 · 3B',
    author: 'Hugging Face',
    url:
        'https://huggingface.co/ggml-org/SmolLM3-3B-GGUF/resolve/main/SmolLM3-Q4_K_M.gguf',
    filename: 'SmolLM3-Q4_K_M.gguf',
    approxBytes: 1826 * 1024 * 1024,
    parameters: '3 B',
    contextTokens: 65536,
    description:
        'Newest SmolLM, with optional thinking mode and multilingual support.',
    accent: Color(0xFFF59E0B),
    emoji: '🤗',
  ),
  CatalogModel(
    id: 'granite-4.0-h-micro-q4_k_m',
    displayName: 'Granite 4.0 · H Micro',
    author: 'IBM',
    url:
        'https://huggingface.co/ibm-granite/granite-4.0-h-micro-GGUF/resolve/main/granite-4.0-h-micro-Q4_K_M.gguf',
    filename: 'granite-4.0-h-micro-Q4_K_M.gguf',
    approxBytes: 1852 * 1024 * 1024,
    parameters: '3 B',
    contextTokens: 131072,
    description:
        'IBM\'s hybrid-Mamba model. Tuned for tool calling and long documents.',
    accent: Color(0xFF3B82F6),
    emoji: '🏛️',
  ),
  CatalogModel(
    id: 'qwen3-4b-instruct-2507-q4_k_m',
    displayName: 'Qwen 3 · 4B Instruct 2507',
    author: 'Alibaba',
    url:
        'https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF/resolve/main/Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
    filename: 'Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
    approxBytes: 2381 * 1024 * 1024,
    parameters: '4 B',
    contextTokens: 262144,
    description:
        'Refreshed Qwen3 4B: big gains over the original, and no thinking preamble.',
    accent: Color(0xFF6D28D9),
    emoji: '🛠️',
  ),
  CatalogModel(
    id: 'gemma-3n-e2b-it-q4_k_m',
    displayName: 'Gemma 3n · E2B Instruct',
    author: 'Google',
    url:
        'https://huggingface.co/unsloth/gemma-3n-E2B-it-GGUF/resolve/main/gemma-3n-E2B-it-Q4_K_M.gguf',
    filename: 'gemma-3n-E2B-it-Q4_K_M.gguf',
    approxBytes: 2886 * 1024 * 1024,
    parameters: '5 B (2 B active)',
    contextTokens: 32768,
    description:
        'Designed for on-device: 5B weights but only ~2B active per token.',
    accent: Color(0xFF0284C7),
    emoji: '🔋',
  ),
  CatalogModel(
    id: 'gemma-4-e2b-it-q4_0',
    displayName: 'Gemma 4 · E2B Instruct',
    author: 'Google',
    url:
        'https://huggingface.co/ggml-org/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q4_0.gguf',
    filename: 'gemma-4-E2B-it-Q4_0.gguf',
    approxBytes: 2709 * 1024 * 1024,
    parameters: '2.3 B effective',
    contextTokens: 262144,
    description:
        'Gemma 4\'s phone tier. 256K context, 140+ languages, and QAT weights that stay sharp at Q4.',
    accent: Color(0xFF0369A1),
    emoji: '🌀',
    mmprojUrl:
        'https://huggingface.co/ggml-org/gemma-4-E2B-it-GGUF/resolve/main/mmproj-gemma-4-E2B-it-Q8_0.gguf',
    mmprojFilename: 'mmproj-gemma-4-E2B-it-Q8_0.gguf',
    mmprojBytes: 557368064,
  ),
  CatalogModel(
    id: 'gemma-4-e4b-it-q4_0',
    displayName: 'Gemma 4 · E4B Instruct',
    author: 'Google',
    url:
        'https://huggingface.co/ggml-org/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q4_0.gguf',
    filename: 'gemma-4-E4B-it-Q4_0.gguf',
    approxBytes: 4378 * 1024 * 1024,
    parameters: '4.5 B effective',
    contextTokens: 262144,
    description:
        'The larger on-device Gemma 4. Biggest download here, so it needs a flagship with RAM to spare.',
    accent: Color(0xFF075985),
    emoji: '🔆',
    mmprojUrl:
        'https://huggingface.co/ggml-org/gemma-4-E4B-it-GGUF/resolve/main/mmproj-gemma-4-E4B-it-Q8_0.gguf',
    mmprojFilename: 'mmproj-gemma-4-E4B-it-Q8_0.gguf',
    mmprojBytes: 559874816,
  ),

  CatalogModel(
    id: 'lfm2.5-350m-q8_0',
    displayName: 'LFM2.5 · 350M',
    author: 'Liquid AI',
    url:
        'https://huggingface.co/LiquidAI/LFM2.5-350M-GGUF/resolve/main/LFM2.5-350M-Q8_0.gguf',
    filename: 'LFM2.5-350M-Q8_0.gguf',
    approxBytes: 362 * 1024 * 1024,
    parameters: '350 M',
    contextTokens: 128000,
    description:
        'Liquid\'s smallest. Near-instant replies on any phone, and a 125K window.',
    accent: Color(0xFF22D3EE),
    emoji: '💦',
  ),
  CatalogModel(
    id: 'qwen3.5-0.8b-q8_0',
    displayName: 'Qwen 3.5 · 0.8B',
    author: 'Alibaba',
    url:
        'https://huggingface.co/ggml-org/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q8_0.gguf',
    filename: 'Qwen3.5-0.8B-Q8_0.gguf',
    approxBytes: 795 * 1024 * 1024,
    parameters: '0.8 B',
    contextTokens: 262144,
    description:
        'Newest tiny Qwen: a 256K window under a gigabyte, and Q8 keeps it sharp.',
    accent: Color(0xFF7C3AED),
    emoji: '🌱',
  ),
  CatalogModel(
    id: 'lfm2.5-1.2b-instruct-q4_k_m',
    displayName: 'LFM2.5 · 1.2B Instruct',
    author: 'Liquid AI',
    url:
        'https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF/resolve/main/LFM2.5-1.2B-Instruct-Q4_K_M.gguf',
    filename: 'LFM2.5-1.2B-Instruct-Q4_K_M.gguf',
    approxBytes: 697 * 1024 * 1024,
    parameters: '1.2 B',
    contextTokens: 128000,
    description:
        'LFM2 rebuilt: same download, four times the context, better at instructions.',
    accent: Color(0xFF06B6D4),
    emoji: '🌊',
  ),
  CatalogModel(
    id: 'qwen3.5-2b-q4_k_m',
    displayName: 'Qwen 3.5 · 2B',
    author: 'Alibaba',
    url:
        'https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q4_K_M.gguf',
    filename: 'Qwen3.5-2B-Q4_K_M.gguf',
    approxBytes: 1222 * 1024 * 1024,
    parameters: '2 B',
    contextTokens: 262144,
    description:
        'The mid-size Qwen 3.5. Strong multilingual chat, and 256K of context.',
    accent: Color(0xFF7C3AED),
    emoji: '🔮',
  ),
  CatalogModel(
    id: 'lfm2.5-2.6b-q4_k_m',
    displayName: 'LFM2.5 · 2.6B',
    author: 'Liquid AI',
    url:
        'https://huggingface.co/LiquidAI/LFM2.5-2.6B-GGUF/resolve/main/LFM2.5-2.6B-Q4_K_M.gguf',
    filename: 'LFM2.5-2.6B-Q4_K_M.gguf',
    approxBytes: 1597 * 1024 * 1024,
    parameters: '2.6 B',
    contextTokens: 131072,
    description:
        'Built for on-device agents: tool calling and 128K context in 1.6 GB.',
    accent: Color(0xFF0891B2),
    emoji: '🤖',
  ),
  CatalogModel(
    id: 'granite-4.1-3b-q4_k_m',
    displayName: 'Granite 4.1 · 3B',
    author: 'IBM',
    url:
        'https://huggingface.co/ibm-granite/granite-4.1-3b-GGUF/resolve/main/granite-4.1-3b-Q4_K_M.gguf',
    filename: 'granite-4.1-3b-Q4_K_M.gguf',
    approxBytes: 2002 * 1024 * 1024,
    parameters: '3 B',
    contextTokens: 131072,
    description:
        'IBM\'s newest Granite. Aimed at tool calling, RAG, and long documents.',
    accent: Color(0xFF1D4ED8),
    emoji: '🧱',
  ),
  CatalogModel(
    id: 'qwen3.5-4b-q4_k_m',
    displayName: 'Qwen 3.5 · 4B',
    author: 'Alibaba',
    url:
        'https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf',
    filename: 'Qwen3.5-4B-Q4_K_M.gguf',
    approxBytes: 2614 * 1024 * 1024,
    parameters: '4 B',
    contextTokens: 262144,
    description:
        'The strongest small Qwen yet. Flagship phone; expect slower tokens.',
    accent: Color(0xFF6D28D9),
    emoji: '🏆',
  ),
  CatalogModel(
    id: 'nemotron-3-nano-4b-q4_k_m',
    displayName: 'Nemotron 3 Nano · 4B',
    author: 'NVIDIA',
    url:
        'https://huggingface.co/nvidia/NVIDIA-Nemotron-3-Nano-4B-GGUF/resolve/main/NVIDIA-Nemotron3-Nano-4B-Q4_K_M.gguf',
    filename: 'NVIDIA-Nemotron3-Nano-4B-Q4_K_M.gguf',
    approxBytes: 2706 * 1024 * 1024,
    parameters: '4 B',
    contextTokens: 1048576,
    description:
        'NVIDIA\'s on-device Nemotron. Hybrid-Mamba layers and a million-token window.',
    accent: Color(0xFF65A30D),
    emoji: '📜',
  ),

  // ── Embedding models ────────────────────────────────────────────────
  // These power /api/embed and /v1/embeddings. They cannot chat, and the
  // Chat tab filters them out via [chatCatalog].
  CatalogModel(
    id: 'nomic-embed-text-v1.5-q5_k_m',
    displayName: 'Nomic Embed Text v1.5',
    author: 'Nomic',
    url:
        'https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q5_K_M.gguf',
    filename: 'nomic-embed-text-v1.5.Q5_K_M.gguf',
    approxBytes: 95 * 1024 * 1024,
    parameters: '137 M',
    contextTokens: 8192,
    description:
        'The default for on-device RAG. Supports shortening via `dimensions`.',
    accent: Color(0xFF22D3EE),
    emoji: '🧭',
    kind: ModelKind.embedding,
    dimensions: 768,
  ),
  CatalogModel(
    id: 'embeddinggemma-300m-q8_0',
    displayName: 'EmbeddingGemma · 300M',
    author: 'Google',
    url:
        'https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF/resolve/main/embeddinggemma-300M-Q8_0.gguf',
    filename: 'embeddinggemma-300M-Q8_0.gguf',
    approxBytes: 318 * 1024 * 1024,
    parameters: '300 M',
    contextTokens: 2048,
    description:
        'Google\'s embedding model, trained for 100+ languages. Best multilingual retrieval.',
    accent: Color(0xFF34D399),
    emoji: '🌍',
    kind: ModelKind.embedding,
    dimensions: 768,
  ),
  CatalogModel(
    id: 'qwen3-embedding-0.6b-q8_0',
    displayName: 'Qwen 3 Embedding · 0.6B',
    author: 'Alibaba',
    url:
        'https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF/resolve/main/Qwen3-Embedding-0.6B-Q8_0.gguf',
    filename: 'Qwen3-Embedding-0.6B-Q8_0.gguf',
    approxBytes: 609 * 1024 * 1024,
    parameters: '600 M',
    contextTokens: 32768,
    description:
        'Top-ranked multilingual embedder. The most accurate option, and the largest.',
    accent: Color(0xFF818CF8),
    emoji: '🧬',
    kind: ModelKind.embedding,
    dimensions: 1024,
  ),
  CatalogModel(
    id: 'bge-small-en-v1.5-q8_0',
    displayName: 'BGE Small EN v1.5',
    author: 'BAAI',
    url:
        'https://huggingface.co/CompendiumLabs/bge-small-en-v1.5-gguf/resolve/main/bge-small-en-v1.5-q8_0.gguf',
    filename: 'bge-small-en-v1.5-q8_0.gguf',
    approxBytes: 35 * 1024 * 1024,
    parameters: '33 M',
    contextTokens: 512,
    description:
        'Tiny English retrieval model. Punches far above 35 MB for search and RAG.',
    accent: Color(0xFFA78BFA),
    emoji: '🔎',
    kind: ModelKind.embedding,
    dimensions: 384,
  ),
  CatalogModel(
    id: 'all-minilm-l6-v2-q8_0',
    displayName: 'All-MiniLM L6 v2',
    author: 'Sentence-Transformers',
    url:
        'https://huggingface.co/leliuga/all-MiniLM-L6-v2-GGUF/resolve/main/all-MiniLM-L6-v2.Q8_0.gguf',
    filename: 'all-MiniLM-L6-v2.Q8_0.gguf',
    approxBytes: 24 * 1024 * 1024,
    parameters: '22 M',
    contextTokens: 512,
    description:
        'The classic lightweight embedder. Smallest and fastest option at 24 MB.',
    accent: Color(0xFFF472B6),
    emoji: '🪶',
    kind: ModelKind.embedding,
    dimensions: 384,
  ),
];
