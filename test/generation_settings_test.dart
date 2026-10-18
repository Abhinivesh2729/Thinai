import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/llm/generation_settings.dart';
import 'package:local_llm/models_repo/gguf_metadata.dart';

import 'context_limits_test.dart' show ggufHeader;

void main() {
  group('per-model sampling settings', () {
    test('Top-K, Top-P and thinking survive a save and load', () {
      const saved = GenerationSettings(
        perModel: {
          'qwen3-1.7b': ModelGenerationSettings(
            topK: 20,
            topP: 0.8,
            thinking: false,
          ),
        },
      );
      final loaded = GenerationSettings.fromJson(saved.toJson());
      final m = loaded.forModel('qwen3-1.7b');
      expect(m.topK, 20);
      expect(m.topP, 0.8);
      expect(m.thinking, isFalse);
      expect(m.isDefault, isFalse);
    });

    test('settings saved before these existed still load as defaults', () {
      final loaded = GenerationSettings.fromJson({
        'gpu': 'none',
        'perModel': {
          'gemma': {'temperature': 0.4},
        },
      });
      final m = loaded.forModel('gemma');
      expect(m.temperature, 0.4);
      expect(m.topK, isNull);
      expect(m.topP, isNull);
      expect(m.thinking, isNull);
    });

    test('an untouched model is not written out', () {
      const s = GenerationSettings(perModel: {'x': ModelGenerationSettings()});
      expect((s.toJson()['perModel'] as Map), isEmpty);
    });
  });

  group('parseGgufChatTemplate', () {
    test('finds the template past the vocabulary', () {
      final bytes = ggufHeader([
        ('general.architecture', 8, 'qwen3'),
        ('tokenizer.ggml.tokens', 9, List.generate(5000, (i) => 'tok$i')),
        (
          'tokenizer.chat_template',
          8,
          '{%- if enable_thinking is defined and enable_thinking is false %}'
              '<think>\n\n</think>{%- endif %}',
        ),
      ]);
      expect(
        parseGgufChatTemplate(GgufBytes(bytes)),
        contains('enable_thinking'),
      );
    });

    test('is null for a file without one', () {
      final bytes = ggufHeader([
        ('general.architecture', 8, 'llama'),
        ('tokenizer.ggml.tokens', 9, ['a', 'b']),
      ]);
      expect(parseGgufChatTemplate(GgufBytes(bytes)), isNull);
    });
  });
}
