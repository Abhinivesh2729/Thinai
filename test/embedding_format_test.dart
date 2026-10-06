import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/server/routes/embedding_format.dart';

void main() {
  group('parseEmbeddingInputs', () {
    test('accepts a single string', () {
      expect(parseEmbeddingInputs('hello'), ['hello']);
    });

    test('accepts an array of strings', () {
      expect(parseEmbeddingInputs(['a', 'b']), ['a', 'b']);
    });

    test('rejects missing input', () {
      expect(() => parseEmbeddingInputs(null), throwsFormatException);
    });

    test('rejects empty string and empty array', () {
      expect(() => parseEmbeddingInputs(''), throwsFormatException);
      expect(() => parseEmbeddingInputs(<String>[]), throwsFormatException);
    });

    test('rejects non-string array entries rather than guessing', () {
      // Token-array input would need a detokenizer to produce the same vector.
      expect(() => parseEmbeddingInputs([1, 2, 3]), throwsFormatException);
      expect(() => parseEmbeddingInputs(['ok', 5]), throwsFormatException);
    });

    test('rejects wrong types', () {
      expect(() => parseEmbeddingInputs(42), throwsFormatException);
      expect(() => parseEmbeddingInputs({'a': 1}), throwsFormatException);
    });
  });

  group('shortenEmbedding', () {
    test('truncates to the requested length', () {
      final out = shortenEmbedding([1, 0, 0, 0], 2);
      expect(out, hasLength(2));
    });

    test('re-normalizes to unit length so cosine == dot product', () {
      // Truncating [0.6, 0.8, ...] to 2 dims leaves a unit vector already,
      // so use one where truncation actually shortens the vector.
      final out = shortenEmbedding([3, 4, 12], 2);
      final norm = math.sqrt(out.fold<double>(0, (s, v) => s + v * v));
      expect(norm, closeTo(1.0, 1e-9));
      // Direction is preserved: 3/5, 4/5.
      expect(out[0], closeTo(0.6, 1e-9));
      expect(out[1], closeTo(0.8, 1e-9));
    });

    test('does not divide by zero on an all-zero head', () {
      final out = shortenEmbedding([0, 0, 1], 2);
      expect(out, [0.0, 0.0]);
    });

    test('keeps full vector when dimensions equals length', () {
      final out = shortenEmbedding([0.6, 0.8], 2);
      expect(out[0], closeTo(0.6, 1e-9));
      expect(out[1], closeTo(0.8, 1e-9));
    });
  });

  group('embeddingToBase64', () {
    test('round-trips as little-endian float32', () {
      const vector = [1.0, -2.5, 0.0, 3.25];
      final encoded = embeddingToBase64(vector);
      final bytes = base64Decode(encoded);

      expect(bytes, hasLength(vector.length * 4));

      final decoded = <double>[];
      final view = ByteData.sublistView(bytes);
      for (var i = 0; i < vector.length; i++) {
        decoded.add(view.getFloat32(i * 4, Endian.little));
      }
      expect(decoded, vector);
    });

    test('matches a known-good OpenAI-style payload', () {
      // 1.0f little-endian is 00 00 80 3F.
      expect(embeddingToBase64([1.0]), base64Encode([0x00, 0x00, 0x80, 0x3F]));
    });

    test('handles an empty vector', () {
      expect(embeddingToBase64([]), '');
    });
  });
}
