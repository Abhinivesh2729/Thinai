/// One message in a conversation sent to the model.
///
/// Its own file, free of the native engine, so code that only shapes prompts —
/// trimming them to a context window, fencing untrusted text — can be used and
/// tested without loading llama.cpp or Flutter.
class ChatMessage {
  final String role;
  final String content;

  /// Tool calls being replayed to the model on an `assistant` message, in
  /// OpenAI's `tool_calls` shape. Carrying them back matters: without the call
  /// it made, the model cannot make sense of the `tool` message that answers
  /// it.
  final List<Map<String, dynamic>>? toolCalls;

  /// Name of the tool a `role: tool` message is answering.
  final String? toolName;

  const ChatMessage({
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolName,
  });
}
