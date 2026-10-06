import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/server/routes/chat_format.dart';

void main() {
  group('parseMessageContent', () {
    test('passes a plain string through', () {
      expect(parseMessageContent('hello'), 'hello');
    });

    test('flattens the parts array clients send even for pure text', () {
      // The shape that used to 500: a cast to String on a List.
      expect(
        parseMessageContent([
          {'type': 'text', 'text': 'why is '},
          {'type': 'text', 'text': 'the sky blue?'},
        ]),
        'why is the sky blue?',
      );
    });

    test('accepts the Responses-API spellings of a text part', () {
      expect(
        parseMessageContent([
          {'type': 'input_text', 'text': 'a'},
          {'type': 'output_text', 'text': 'b'},
        ]),
        'ab',
      );
    });

    test('treats a null or missing content as empty', () {
      expect(parseMessageContent(null), '');
    });

    test('rejects image parts when no image encoder is loaded', () {
      expect(
        () => parseMessageContent([
          {'type': 'text', 'text': 'what is this?'},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/png;base64,AAAA'},
          },
        ]),
        throwsFormatException,
      );
    });

    test('turns an image part into the tag the native bridge reads', () {
      final text = parseMessageContent([
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/png;base64,AAAA'},
        },
        {'type': 'text', 'text': 'what is this?'},
      ], visionReady: true);
      expect(text, contains('<img src="data:image/png;base64,AAAA">'));
      expect(text, contains('what is this?'));
    });

    test("refuses to fetch a remote image on the user's behalf", () {
      expect(
        () => parseMessageContent([
          {
            'type': 'image_url',
            'image_url': {'url': 'https://example.com/cat.png'},
          },
        ], visionReady: true),
        throwsFormatException,
      );
    });

    test('rejects audio parts', () {
      expect(
        () => parseMessageContent([
          {'type': 'input_audio', 'input_audio': {}},
        ]),
        throwsFormatException,
      );
    });

    test('skips unknown part types instead of failing', () {
      expect(
        parseMessageContent([
          {'type': 'text', 'text': 'kept'},
          {'type': 'some_future_thing', 'blob': 1},
        ]),
        'kept',
      );
    });

    test('rejects content that is neither string nor array', () {
      expect(() => parseMessageContent(42), throwsFormatException);
      expect(() => parseMessageContent({'text': 'x'}), throwsFormatException);
    });
  });

  group('parseChatMessages', () {
    test('reads role and content', () {
      final messages = parseChatMessages([
        {'role': 'system', 'content': 'be terse'},
        {'role': 'user', 'content': 'hi'},
      ]);
      expect(messages.map((m) => m.role), ['system', 'user']);
      expect(messages.last.content, 'hi');
    });

    test('defaults a missing role to user', () {
      expect(parseChatMessages([
        {'content': 'hi'},
      ]).single.role, 'user');
    });

    test('carries assistant tool calls back to the model', () {
      final messages = parseChatMessages([
        {'role': 'user', 'content': 'weather?'},
        {
          'role': 'assistant',
          'content': '',
          'tool_calls': [
            {
              'id': 'call_1',
              'type': 'function',
              'function': {'name': 'get_weather', 'arguments': '{"city":"NY"}'},
            },
          ],
        },
      ]);
      final calls = messages.last.toolCalls!;
      expect(calls.single['id'], 'call_1');
      expect((calls.single['function'] as Map)['name'], 'get_weather');
    });

    test('resolves a tool reply back to the name it is answering', () {
      // The client identifies the reply by id; the chat template renders a
      // name. Without the lookup the model sees an answer to nothing.
      final messages = parseChatMessages([
        {
          'role': 'assistant',
          'content': '',
          'tool_calls': [
            {
              'id': 'call_1',
              'function': {'name': 'get_weather', 'arguments': '{}'},
            },
          ],
        },
        {'role': 'tool', 'tool_call_id': 'call_1', 'content': '18C'},
      ]);
      expect(messages.last.toolName, 'get_weather');
    });

    test('prefers an explicit tool name when one is sent', () {
      final messages = parseChatMessages([
        {'role': 'tool', 'name': 'lookup', 'content': 'x'},
      ]);
      expect(messages.single.toolName, 'lookup');
    });

    test('rejects a non-object message', () {
      expect(() => parseChatMessages(['hi']), throwsFormatException);
    });
  });

  group('parseTools', () {
    test('reads OpenAI tool definitions', () {
      final tools = parseTools([
        {
          'type': 'function',
          'function': {
            'name': 'get_weather',
            'description': 'Look up weather',
            'parameters': {
              'type': 'object',
              'properties': {
                'city': {'type': 'string'},
              },
            },
          },
        },
      ]);
      expect(tools.single.name, 'get_weather');
      expect(tools.single.description, 'Look up weather');
      expect(tools.single.parameters['type'], 'object');
    });

    test('gives an argument-less tool an empty object schema', () {
      final tools = parseTools([
        {
          'function': {'name': 'ping'},
        },
      ]);
      expect(tools.single.parameters, {'type': 'object', 'properties': {}});
    });

    test('returns nothing for a missing tools field', () {
      expect(parseTools(null), isEmpty);
    });

    test('rejects malformed definitions', () {
      expect(() => parseTools('get_weather'), throwsFormatException);
      expect(() => parseTools([{}]), throwsFormatException);
      expect(
        () => parseTools([
          {'function': {}},
        ]),
        throwsFormatException,
      );
      expect(
        () => parseTools([
          {
            'function': {'name': 'x', 'parameters': 'not an object'},
          },
        ]),
        throwsFormatException,
      );
    });
  });

  group('parseToolChoice', () {
    test('reads the string forms', () {
      expect(parseToolChoice('auto').mode, 'auto');
      expect(parseToolChoice('none').mode, 'none');
      expect(parseToolChoice('required').mode, 'required');
    });

    test('is unset when absent', () {
      expect(parseToolChoice(null).mode, isNull);
      expect(parseToolChoice(null).name, isNull);
    });

    test('turns a named function into required-over-one', () {
      final choice = parseToolChoice({
        'type': 'function',
        'function': {'name': 'get_weather'},
      });
      expect(choice.mode, 'required');
      expect(choice.name, 'get_weather');
    });

    test('rejects unknown values', () {
      expect(() => parseToolChoice('maybe'), throwsFormatException);
      expect(() => parseToolChoice({'type': 'function'}), throwsFormatException);
      expect(() => parseToolChoice(7), throwsFormatException);
    });
  });

  group('parseStopSequences', () {
    test('accepts a single string', () {
      expect(parseStopSequences('\n\n'), ['\n\n']);
    });

    test('accepts an array', () {
      expect(parseStopSequences(['a', 'b']), ['a', 'b']);
    });

    test('drops empty entries, which would match everywhere', () {
      expect(parseStopSequences(['', 'a']), ['a']);
      expect(parseStopSequences(''), isEmpty);
    });

    test('is empty when absent', () {
      expect(parseStopSequences(null), isEmpty);
    });

    test('enforces the four-sequence limit', () {
      expect(
        () => parseStopSequences(['a', 'b', 'c', 'd', 'e']),
        throwsFormatException,
      );
    });

    test('rejects wrong types', () {
      expect(() => parseStopSequences(7), throwsFormatException);
      expect(() => parseStopSequences([1]), throwsFormatException);
    });
  });

  group('finalizeToolCalls', () {
    test('drops the streaming index and keeps the id llama.cpp gave', () {
      final calls = finalizeToolCalls([
        {
          'index': 0,
          'id': 'call_abc',
          'type': 'function',
          'function': {'name': 'f', 'arguments': '{}'},
        },
      ], (i) => 'generated_$i');
      expect(calls.single.containsKey('index'), isFalse);
      expect(calls.single['id'], 'call_abc');
    });

    test('fills in an id when the model produced none', () {
      // The id is what a client puts on the tool reply, so an empty one makes
      // parallel calls unanswerable.
      final calls = finalizeToolCalls([
        {
          'index': 1,
          'id': '',
          'function': {'name': 'f', 'arguments': '{}'},
        },
      ], (i) => 'generated_$i');
      expect(calls.single['id'], 'generated_1');
    });

    test('keeps arguments as the string OpenAI clients expect', () {
      final calls = finalizeToolCalls([
        {
          'index': 0,
          'function': {'name': 'f', 'arguments': '{"city":"NY"}'},
        },
      ], (i) => 'x');
      expect((calls.single['function'] as Map)['arguments'], '{"city":"NY"}');
    });
  });
}
