/// Request parsing and response encoding shared by the Ollama and OpenAI
/// embedding endpoints.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Parses the `input` field shared by Ollama's /api/embed and OpenAI's
/// /v1/embeddings. Both accept either a single string or an array of strings.
///
/// Throws [FormatException] with a client-facing message when the field is
/// missing or the wrong shape.
List<String> parseEmbeddingInputs(dynamic input) {
  if (input is String) {
    if (input.isEmpty) {
      throw const FormatException('input must not be empty');
    }
    return [input];
  }

  if (input is List) {
    if (input.isEmpty) {
      throw const FormatException('input must not be empty');
    }
    final inputs = <String>[];
    for (final item in input) {
      if (item is! String) {
        // Token-array input (List<int>) is part of the OpenAI spec but needs a
        // detokenizer to reach the same vector; rejecting beats guessing.
        throw const FormatException(
          'input array must contain only strings',
        );
      }
      inputs.add(item);
    }
    return inputs;
  }

  throw const FormatException(
    'input is required and must be a string or an array of strings',
  );
}

/// Truncates [vector] to [dimensions] and re-normalizes to unit length, which
/// is what OpenAI's `dimensions` parameter does. Valid only for models trained
/// with Matryoshka representation learning (ex. nomic-embed-text-v1.5); on
/// other models a truncated vector is still a degraded one, so callers should
/// only pass `dimensions` when the model supports it.
///
/// Re-normalizing matters: lopping off components shortens the vector, and
/// clients that assume unit length (cosine == dot product) would otherwise get
/// silently wrong similarity scores.
List<double> shortenEmbedding(List<double> vector, int dimensions) {
  final head = vector.sublist(0, dimensions);
  var sumSquares = 0.0;
  for (final v in head) {
    sumSquares += v * v;
  }
  final norm = math.sqrt(sumSquares);
  if (norm == 0) return head;
  return [for (final v in head) v / norm];
}

/// Encodes [vector] the way the OpenAI clients expect for
/// `encoding_format: base64`: little-endian float32, then base64.
String embeddingToBase64(List<double> vector) {
  final floats = Float32List.fromList(vector);
  final bytes = floats.buffer.asUint8List(
    floats.offsetInBytes,
    floats.lengthInBytes,
  );
  if (Endian.host == Endian.little) {
    return base64Encode(bytes);
  }
  // Big-endian host: byte-swap each float so the wire format stays LE.
  final swapped = Uint8List(bytes.length);
  for (var i = 0; i < bytes.length; i += 4) {
    swapped[i] = bytes[i + 3];
    swapped[i + 1] = bytes[i + 2];
    swapped[i + 2] = bytes[i + 1];
    swapped[i + 3] = bytes[i];
  }
  return base64Encode(swapped);
}
