/// Keeps a conversation inside the context window it is about to be sent to.
///
/// llama.cpp refuses a prompt longer than the window outright ("request
/// exceeds the available context size"), so a chat that has grown past it —
/// or one that just had its window turned down — would fail every message
/// from then on. Trimming here keeps it answering: the oldest exchanges go
/// first, since they matter least to the next reply, and what the model is
/// being asked right now, with whatever it was given to answer from, stays.
library;

import '../llm/chat_message.dart';

/// Characters per token assumed when estimating. Deliberately low — English
/// runs nearer 4, but code, numbers and non-Latin scripts such as Tamil run
/// far lower, and an estimate that reads long only trims a little early.
const double kCharsPerToken = 3.2;

/// Tokens held back for the reply, and for the chat template's own markup.
const int kMinReplyReserve = 512;

/// Rough token count for [text].
int estimateTokens(String text) => (text.length / kCharsPerToken).ceil();

/// Messages that fit in [contextSize] tokens with room left for a reply.
///
/// In order of what gives way: whole earlier turns, oldest first; then the
/// system message and the final user turn are shortened from the end of their
/// bodies, the system message first. The final user turn always survives in
/// some form, since without it there is nothing to answer.
List<ChatMessage> fitToContext(
  List<ChatMessage> messages,
  int contextSize, {
  int? replyReserve,
}) {
  if (messages.isEmpty) return messages;
  final reserve = replyReserve ??
      (contextSize ~/ 4 > kMinReplyReserve ? contextSize ~/ 4 : kMinReplyReserve);
  final budget = contextSize - reserve;
  if (budget <= 0) return [messages.last];

  int cost(List<ChatMessage> list) =>
      list.fold(0, (sum, m) => sum + estimateTokens(m.content) + 8);

  final result = [...messages];
  if (cost(result) <= budget) return result;

  // 1. Earlier turns, oldest first. The leading system message and the final
  //    message are never dropped here.
  final firstDroppable = result.first.role == 'system' ? 1 : 0;
  while (result.length - firstDroppable > 1 && cost(result) > budget) {
    result.removeAt(firstDroppable);
    // A reply left without the question it answered reads to the model as
    // the start of the conversation; drop it too.
    if (result.length - firstDroppable > 1 &&
        result[firstDroppable].role == 'assistant') {
      result.removeAt(firstDroppable);
    }
  }
  if (cost(result) <= budget) return result;

  // 2. Shorten what is left, system message first.
  for (final index in [0, result.length - 1]) {
    final over = cost(result) - budget;
    if (over <= 0) break;
    final message = result[index];
    final keepChars =
        message.content.length - (over * kCharsPerToken).ceil() - 1;
    if (keepChars <= 0 && index != result.length - 1) {
      result.removeAt(index);
      continue;
    }
    result[index] = ChatMessage(
      role: message.role,
      content: _shorten(message.content, keepChars),
      toolCalls: message.toolCalls,
      toolName: message.toolName,
    );
  }
  return result;
}

/// Cuts from the middle of a long user turn rather than its end: a prompt
/// built from reference material followed by the question keeps the question.
String _shorten(String text, int keep) {
  if (keep >= text.length) return text;
  if (keep < 64) return text.substring(text.length - (keep < 0 ? 0 : keep));
  const marker = '\n…[trimmed to fit the context window]…\n';
  final tail = keep ~/ 3;
  final head = keep - tail - marker.length;
  if (head <= 0) return text.substring(text.length - keep);
  return text.substring(0, head) + marker + text.substring(text.length - tail);
}
