/// Suggested next questions after a reply.
///
/// The model writes them in a short second pass. Small on-device models are
/// loose with format — numbering, bullets, a chatty preamble, quotes — so the
/// parsing here is forgiving about shape and strict about what survives.
library;

import '../llm/llm_engine.dart';

/// How many suggestions are shown.
const kFollowUpCount = 3;

/// Characters of the answer quoted back to the model. The suggestions only
/// need the gist, and a short prompt is what keeps this pass to a second or
/// two on a phone.
const _answerBudget = 1200;

/// The one-message prompt asking for follow-ups to [question] and [answer].
List<ChatMessage> followUpPrompt(String question, String answer) {
  final trimmed = answer.length <= _answerBudget
      ? answer
      : '${answer.substring(0, _answerBudget)}…';
  return [
    ChatMessage(
      role: 'user',
      content:
          'A user asked a question and got an answer.\n\n'
          'Question: ${question.trim()}\n\n'
          'Answer: ${trimmed.trim()}\n\n'
          'Write exactly $kFollowUpCount short follow-up questions the user '
          'might ask next. Keep each under 12 words. Reply with only the '
          'questions, one per line, with no numbering and no other text.',
    ),
  ];
}

final _listMarker = RegExp(r'^\s*(?:[-*•–]+|\d{1,2}[.):]|\(?\d{1,2}\))\s*');
final _wrapping = RegExp(r'^[\s"“”‘’*_`]+|[\s"“”‘’*_`]+$');

/// The usable questions in [raw], at most [kFollowUpCount], in order.
///
/// Drops anything that is not a question someone would tap: preambles ("Here
/// are three questions:"), headings, blank lines, fragments, run-ons, repeats,
/// and a restatement of what was just asked.
List<String> parseFollowUps(String raw, {String? askedQuestion}) {
  final asked = _normalise(askedQuestion ?? '');
  final seen = <String>{};
  final out = <String>[];
  for (final line in raw.split('\n')) {
    var text = line.replaceFirst(_listMarker, '').replaceAll(_wrapping, '');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) continue;
    if (text.endsWith(':')) continue;
    final lower = text.toLowerCase();
    if (lower.startsWith('here are') ||
        lower.startsWith('here is') ||
        lower.startsWith('sure') ||
        lower.startsWith('follow-up')) {
      continue;
    }
    final words = text.split(' ').length;
    if (words < 3 || text.length > 120) continue;
    final key = _normalise(text);
    if (key == asked || !seen.add(key)) continue;
    out.add(text);
    if (out.length == kFollowUpCount) break;
  }
  return out;
}

String _normalise(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9஀-௿]+'), ' ').trim();
