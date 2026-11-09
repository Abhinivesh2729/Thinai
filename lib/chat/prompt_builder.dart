/// Assembles what the model receives for one chat turn. Shared by the phone
/// and desktop chat screens so both send the same prompt.
library;

import '../llm/chat_message.dart';
import '../state/providers.dart' show ChatTurn;
import '../web/web_search.dart';
import 'document_attachment.dart';
import 'image_attachment.dart';

/// Builds the message list sent to the model, with same-role neighbours merged.
///
/// Chat templates such as Gemma's require the roles to strictly alternate and
/// `raise_exception` rather than degrade when they do not. A reply stopped
/// before it produced anything leaves an empty assistant turn, which is not
/// worth sending, and dropping it would put two user messages back to back —
/// poisoning not just that send but every later one in the conversation, since
/// the empty turn stays in the history. Merging neighbours keeps the transcript
/// sendable without discarding anything the user wrote.
List<ChatMessage> buildChatPrompt(
  List<ChatTurn> turns,
  String pending, {
  String systemPrompt = '',
  DocumentAttachment? document,
  ImageAttachment? image,
  WebSearchResults? search,
}) {
  // Results the last reply was built from. A follow-up — "what is the model
  // name" after an answer about the latest models — is asked of a history
  // that holds the question and the reply but not what they were based on, so
  // they go back in unless this turn ran a search of its own.
  final recall =
      search == null && turns.isNotEmpty && turns.last.role == 'assistant'
      ? turns.last.sources
      : const <WebResult>[];
  final messages = <ChatMessage>[];

  void add(String role, String content) {
    if (content.isEmpty) return;
    final last = messages.isEmpty ? null : messages.last;
    if (last != null && last.role == role) {
      messages[messages.length - 1] = ChatMessage(
        role: role,
        content: '${last.content}\n\n$content',
      );
      return;
    }
    messages.add(ChatMessage(role: role, content: content));
  }

  // The user's system prompt opens the conversation. The document and search
  // lines below merge into the same system message after it, so a template
  // that allows only one still renders.
  add('system', systemPrompt.trim());

  // The document follows, as a system message: it belongs to the conversation
  // rather than to one turn, so every follow-up question can still see it
  // without the text being repeated into the history.
  if (document != null) {
    add('system', documentSystemMessage(document));
  }
  // One line about the search, merged into the same system message rather than
  // opening a second one — several templates allow only one, and a prompt the
  // template refuses to render fails the whole turn. The results themselves go
  // with the question, where a small model will actually use them.
  final searched = search != null && search.isNotEmpty;
  if (searched || recall.isNotEmpty) {
    add('system', kWebSearchSystemLine);
  }

  for (final turn in turns) {
    add(turn.role, turn.content);
  }

  final asked = searched
      ? webSearchPrompt(search, pending)
      : recall.isNotEmpty
      ? webRecallPrompt(recall, pending)
      : pending;
  // The image goes on the user's own turn rather than a system message: the
  // native side finds it wherever it lands in the prompt, but these models
  // were trained with the picture attached to the question about it.
  add('user', promptWithImage(image, asked));
  return messages;
}
