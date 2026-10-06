import 'dart:convert';
import 'dart:typed_data';

import 'package:local_llm/chat/prompt_budget.dart';
import 'package:local_llm/llm/context_limits.dart';
import 'package:local_llm/llm/chat_message.dart';
import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/gguf_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a GGUF v3 header in memory: enough of the format to exercise the
/// reader, with a tokenizer array standing in for the bulk a real one skips.
Uint8List ggufHeader(List<(String, int, Object)> kvs) {
  final out = BytesBuilder();
  void u32(int v) =>
      out.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u64(int v) =>
      out.add((ByteData(8)..setUint64(0, v, Endian.little)).buffer.asUint8List());
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
      case 9:
        final strings = value as List<String>;
        u32(8);
        u64(strings.length);
        strings.forEach(str);
      default:
        throw ArgumentError('type $type');
    }
  }
  return out.toBytes();
}

void main() {
  const gib = 1024 * 1024 * 1024;

  final qwen = ggufHeader([
    ('general.architecture', 8, 'qwen2'),
    ('general.name', 8, 'Qwen2.5 0.5B'),
    ('tokenizer.ggml.tokens', 9, List.generate(1000, (i) => 'tok$i')),
    ('qwen2.context_length', 4, 32768),
    ('qwen2.block_count', 4, 24),
    ('qwen2.attention.head_count', 4, 14),
    ('qwen2.attention.head_count_kv', 4, 2),
    ('qwen2.embedding_length', 4, 896),
  ]);

  group('parseGgufHeader', () {
    test('reads the keys that size a context, skipping arrays', () {
      final info = parseGgufHeader(GgufBytes(qwen));
      expect(info.architecture, 'qwen2');
      expect(info.name, 'Qwen2.5 0.5B');
      expect(info.trainedContext, 32768);
      expect(info.layers, 24);
      expect(info.kvHeads, 2);
      // 24 layers × 2 kv heads × (64 + 64) × 2 bytes.
      expect(info.kvBytesPerToken, 12288);
    });

    test('rejects a file that is not GGUF', () {
      expect(
        () => parseGgufHeader(GgufBytes(Uint8List.fromList([1, 2, 3, 4]))),
        throwsA(isA<GgufFormatException>()),
      );
    });

    test('round-trips through JSON', () {
      final info = parseGgufHeader(GgufBytes(qwen));
      final back = GgufModelInfo.fromJson(info.toJson());
      expect(back.kvBytesPerToken, info.kvBytesPerToken);
      expect(back.trainedContext, 32768);
    });
  });

  group('contextLimitFor', () {
    final info = parseGgufHeader(GgufBytes(qwen));

    test('a small model on a big phone is held to what it was trained for', () {
      final limit = contextLimitFor(
        info: info,
        fileBytes: 400 * 1024 * 1024,
        device: const DeviceProfile(totalRamBytes: 8 * gib, cores: 8),
      );
      expect(limit.cap, 32768);
      expect(limit.ramLimited, isFalse);
    });

    test('a heavy KV cache on a small phone is held down by RAM', () {
      const heavy = GgufModelInfo(
        trainedContext: 32768,
        layers: 32,
        heads: 32,
        kvHeads: 32,
        embeddingLength: 4096,
      );
      final limit = contextLimitFor(
        info: heavy,
        fileBytes: 2 * gib,
        device: const DeviceProfile(totalRamBytes: 6 * gib, cores: 8),
      );
      expect(limit.ramLimited, isTrue);
      expect(limit.cap, lessThan(32768));
      expect(limit.cap, greaterThanOrEqualTo(kMinContextSize));
    });

    test('falls back to the catalogue figure without a header', () {
      final limit = contextLimitFor(
        catalogTrained: 4096,
        fileBytes: 0,
        device: DeviceProfile.unknownProfile,
      );
      expect(limit.cap, 4096);
    });

    test('clamp snaps down to a step and never past the cap', () {
      const limit = ContextLimit(cap: 8192, trained: 8192);
      expect(limit.clamp(999999), 8192);
      expect(limit.clamp(3000), 2048);
      expect(limit.clamp(10), kMinContextSize);
      expect(limit.steps, [512, 1024, 2048, 4096, 8192]);
    });
  });

  group('fitToContext', () {
    ChatMessage m(String role, int chars) =>
        ChatMessage(role: role, content: role[0] * chars);

    test('leaves a conversation that fits alone', () {
      final messages = [m('system', 100), m('user', 100)];
      expect(fitToContext(messages, 4096), messages);
    });

    test('drops the oldest exchanges first and keeps the system message', () {
      final messages = [
        m('system', 200),
        for (var i = 0; i < 20; i++) ...[m('user', 1000), m('assistant', 1000)],
        m('user', 300),
      ];
      final fitted = fitToContext(messages, 2048);
      expect(fitted.first.role, 'system');
      expect(fitted.last.content, messages.last.content);
      expect(fitted.length, lessThan(messages.length));
      final tokens =
          fitted.fold(0, (s, x) => s + estimateTokens(x.content) + 8);
      expect(tokens, lessThanOrEqualTo(2048 - kMinReplyReserve));
    });

    test('shortens an oversized final turn but keeps its end', () {
      final question = 'x' * 20000 + 'Question: what now?';
      final fitted = fitToContext(
        [ChatMessage(role: 'user', content: question)],
        1024,
      );
      expect(fitted.single.content, endsWith('Question: what now?'));
      expect(fitted.single.content.length, lessThan(question.length));
    });
  });
}
