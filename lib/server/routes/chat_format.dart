/// Request parsing shared by the OpenAI and Ollama chat endpoints.
///
/// Every function here throws [FormatException] with a client-facing message
/// when the request is malformed, so a route can turn it into a 400 instead of
/// letting a cast blow up into a 500.
library;

import '../../llm/llm_engine.dart';

/// Flattens the `content` field of a chat message into the plain text the
/// engine takes.
///
/// OpenAI clients send either a string or an array of typed parts, and many
/// send the array form even for pure text — the official SDKs among them. Only
/// accepting the string was worth a 500 on the first request those clients
/// made.
///
/// Image parts are turned into the `<img src="data:...">` tag llama.cpp's
/// bridge extracts, but only when [visionReady] — a model with no image
/// encoder loaded cannot see, and a 400 saying so beats confidently answering
/// a question about a picture nobody looked at. Audio always throws: there is
/// no audio path at all.
String parseMessageContent(dynamic content, {bool visionReady = false}) {
  if (content == null) return '';
  if (content is String) return content;

  if (content is List) {
    final buffer = StringBuffer();
    for (final part in content) {
      if (part is String) {
        buffer.write(part);
        continue;
      }
      if (part is! Map) continue;

      final type = part['type'];
      switch (type) {
        case 'text':
        case 'input_text':
        case 'output_text':
          final text = part['text'];
          if (text is String) buffer.write(text);
        case 'image_url':
        case 'input_image':
        case 'image':
          if (!visionReady) {
            throw const FormatException(
              'image content needs a vision model with its image encoder '
              'loaded. Load one (ex. Gemma 3 4B) and try again.',
            );
          }
          buffer.write(_imageTag(part));
        case 'input_audio':
        case 'audio':
          throw const FormatException(
            'audio content is not supported: this server runs text-only '
            'models. Send content as text.',
          );
        default:
          // Unknown part types (refusals, annotations, provider extensions)
          // carry no prompt text worth guessing at. Take any `text` they do
          // have and move on rather than failing the request.
          final text = part['text'];
          if (text is String) buffer.write(text);
      }
    }
    return buffer.toString();
  }

  throw const FormatException(
    'content must be a string or an array of content parts',
  );
}

/// Turns an image part into the tag the native bridge scans for.
///
/// Only data URIs: fetching a remote URL would mean the server making outbound
/// requests on the user's behalf from a phone they may not want doing that,
/// and llama.cpp needs the bytes inline regardless.
String _imageTag(Map<dynamic, dynamic> part) {
  final source = part['image_url'];
  final url = source is Map ? source['url'] : (source ?? part['url']);
  if (url is! String || url.isEmpty) {
    throw const FormatException('image_url must carry a url');
  }
  if (!url.startsWith('data:image/')) {
    throw const FormatException(
      'only data: image URLs are supported, ex. '
      'data:image/jpeg;base64,<data>',
    );
  }
  return '<img src="$url">';
}

/// Parses an OpenAI/Ollama `messages` array.
///
/// Assistant `tool_calls` and `tool` replies are carried through, which is what
/// makes a second round trip work: the model needs to see the call it made
/// beside the result that came back, or the tool message reads as an answer to
/// nothing.
List<ChatMessage> parseChatMessages(
  List<dynamic> raw, {
  bool visionReady = false,
}) {
  // `tool` messages identify what they answer by id, while the chat template
  // renders a name. Remember the mapping as the assistant turns go by so the
  // name can be recovered.
  final namesById = <String, String>{};
  final messages = <ChatMessage>[];

  for (final entry in raw) {
    if (entry is! Map) {
      throw const FormatException('each message must be an object');
    }
    final role = entry['role'];
    if (role != null && role is! String) {
      throw const FormatException('message role must be a string');
    }

    final toolCalls = _parseAssistantToolCalls(entry['tool_calls']);
    if (toolCalls != null) {
      for (final call in toolCalls) {
        final id = call['id'];
        final function = call['function'];
        if (id is String && function is Map && function['name'] is String) {
          namesById[id] = function['name'] as String;
        }
      }
    }

    String? toolName;
    if (role == 'tool') {
      final named = entry['name'] ?? entry['tool_name'];
      final callId = entry['tool_call_id'];
      toolName = named is String && named.isNotEmpty
          ? named
          : (callId is String ? namesById[callId] : null);
    }

    messages.add(ChatMessage(
      role: (role as String?) ?? 'user',
      content: parseMessageContent(entry['content'], visionReady: visionReady),
      toolCalls: toolCalls,
      toolName: toolName,
    ));
  }

  return messages;
}

List<Map<String, dynamic>>? _parseAssistantToolCalls(dynamic raw) {
  if (raw is! List || raw.isEmpty) return null;
  final calls = <Map<String, dynamic>>[];
  for (final call in raw) {
    if (call is! Map) continue;
    final function = call['function'];
    if (function is! Map) continue;
    final name = function['name'];
    if (name is! String) continue;

    // Ollama sends arguments as an object, OpenAI as a JSON string. The
    // template renders whatever it is given, so pass both through as-is.
    calls.add({
      if (call['id'] is String) 'id': call['id'],
      'type': 'function',
      'function': {
        'name': name,
        if (function['arguments'] != null) 'arguments': function['arguments'],
      },
    });
  }
  return calls.isEmpty ? null : calls;
}

/// Parses a `tools` array into engine specs. Shared because Ollama copied
/// OpenAI's shape verbatim.
List<ToolSpec> parseTools(dynamic raw) {
  if (raw == null) return const [];
  if (raw is! List) {
    throw const FormatException('tools must be an array');
  }

  final tools = <ToolSpec>[];
  for (final entry in raw) {
    if (entry is! Map) {
      throw const FormatException('each tool must be an object');
    }
    final function = entry['function'];
    if (function is! Map) {
      throw const FormatException(
        "each tool must have a 'function' object",
      );
    }
    final name = function['name'];
    if (name is! String || name.isEmpty) {
      throw const FormatException('each tool needs a function name');
    }

    final parameters = function['parameters'];
    if (parameters != null && parameters is! Map) {
      throw FormatException('parameters for tool $name must be an object');
    }
    final description = function['description'];

    tools.add(ToolSpec(
      name: name,
      description: description is String ? description : '',
      // A tool taking no arguments still needs a schema: the grammar built
      // from it is what keeps the model from inventing parameters.
      parameters: parameters is Map
          ? parameters.cast<String, dynamic>()
          : const {'type': 'object', 'properties': {}},
    ));
  }
  return tools;
}

/// A parsed `tool_choice`. [name] is set only for OpenAI's
/// `{"type": "function", "function": {"name": ...}}` form, which pins the
/// model to one specific tool.
class ToolChoiceSpec {
  final String? mode;
  final String? name;
  const ToolChoiceSpec({this.mode, this.name});

  static const none = ToolChoiceSpec();
}

ToolChoiceSpec parseToolChoice(dynamic raw) {
  if (raw == null) return ToolChoiceSpec.none;

  if (raw is String) {
    switch (raw) {
      case 'auto':
      case 'none':
      case 'required':
        return ToolChoiceSpec(mode: raw);
      default:
        throw const FormatException(
          "tool_choice must be 'auto', 'none', 'required', or a function "
          'object',
        );
    }
  }

  if (raw is Map) {
    final function = raw['function'];
    final name = function is Map ? function['name'] : null;
    if (name is! String || name.isEmpty) {
      throw const FormatException(
        "tool_choice object must name a function, ex. {\"type\": \"function\", "
        '"function": {"name": "get_weather"}}',
      );
    }
    // Naming a tool means "call this one", which llama.cpp expresses as
    // `required` over a single-tool list.
    return ToolChoiceSpec(mode: 'required', name: name);
  }

  throw const FormatException(
    "tool_choice must be a string or a function object",
  );
}

/// Parses `stop`, which OpenAI allows as a single string or up to four of them.
List<String> parseStopSequences(dynamic raw) {
  if (raw == null) return const [];
  if (raw is String) return raw.isEmpty ? const [] : [raw];
  if (raw is List) {
    final stops = <String>[];
    for (final entry in raw) {
      if (entry is! String) {
        throw const FormatException('stop must contain only strings');
      }
      if (entry.isNotEmpty) stops.add(entry);
    }
    if (stops.length > 4) {
      throw const FormatException('stop accepts at most 4 sequences');
    }
    return stops;
  }
  throw const FormatException(
    'stop must be a string or an array of strings',
  );
}

/// Fills in ids llama.cpp left empty and drops the streaming-only `index`, so
/// the result is the shape a non-streaming `message.tool_calls` takes.
///
/// The id matters beyond cosmetics: it is what a client puts on the `tool`
/// message that answers the call, and an empty one collapses parallel calls
/// into an unanswerable pair.
List<Map<String, dynamic>> finalizeToolCalls(
  List<Map<String, dynamic>> calls,
  String Function(int index) idFor,
) {
  final out = <Map<String, dynamic>>[];
  for (var i = 0; i < calls.length; i++) {
    final call = calls[i];
    final id = call['id'];
    final index = call['index'] is int ? call['index'] as int : i;
    final function = call['function'];
    out.add({
      'id': id is String && id.isNotEmpty ? id : idFor(index),
      'type': 'function',
      'function': {
        'name': function is Map ? (function['name'] ?? '') : '',
        'arguments': function is Map ? (function['arguments'] ?? '') : '',
      },
    });
  }
  return out;
}
