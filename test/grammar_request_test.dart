import 'dart:convert';

import 'package:fllama/fllama.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // llama.cpp reads `grammar` from the request JSON (src/fllama.cpp) and hands
  // it to the sampler, so this is the whole Dart side of the constraint.
  test('a grammar goes into the request JSON', () {
    final json =
        jsonDecode(
              OpenAiRequest(
                modelPath: 'm.gguf',
                grammar: 'root ::= [ABCD]',
              ).toJsonString(),
            )
            as Map<String, dynamic>;
    expect(json['grammar'], 'root ::= [ABCD]');
  });

  test('no grammar, or an empty one, leaves the field out', () {
    for (final grammar in [null, '']) {
      final json =
          jsonDecode(
                OpenAiRequest(
                  modelPath: 'm.gguf',
                  grammar: grammar,
                ).toJsonString(),
              )
              as Map<String, dynamic>;
      expect(json.containsKey('grammar'), isFalse);
    }
  });
}
