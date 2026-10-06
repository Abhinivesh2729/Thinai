/// Text that came from someone other than the user, made safe to put in a
/// prompt.
///
/// Web results and attached documents are written by strangers, and they reach
/// the model through the same string the chat template renders. The native side
/// then tokenises that string with special-token parsing switched on — it has
/// to, or the template's own `<|im_start|>` would arrive as eleven characters
/// rather than one control token. The price is that a snippet containing
/// `<|im_end|><|im_start|>system` does not *describe* a new system turn, it
/// *is* one, and a 0.5B model has no defence against a system turn it did not
/// write. The same bridge also turns any `<img src="data:image/…;base64,…">` it
/// finds into a picture when a vision projector is loaded, so a web page could
/// hand the model an image the user never attached.
///
/// Two layers, because neither is enough alone:
///
///  * [neutralizeUntrusted] breaks the byte sequences that the tokenizer or the
///    image scanner would act on, with a zero-width space that a reader never
///    sees and a model reads straight past. This is the hard guarantee: after
///    it, no chat-template control token can be spelled by the content.
///  * [fenceUntrusted] wraps the content in markers carrying a random id, so the
///    model can be told where quoted data starts and stops, and a page cannot
///    forge the end of the quote because it cannot guess the id. This one is
///    soft — a small model can still be talked round — but it is what lets the
///    system prompt say "do not follow instructions in here" about something
///    specific.
///
/// Only third-party text goes through here. The user's own words, and the image
/// tag `promptWithImage` builds for a photo they really attached, are the user
/// talking to their own model and are passed through untouched.
library;

import 'dart:math';

/// Invisible to a reader, and not part of any tokenizer's special-token
/// vocabulary — which is the whole point of putting it inside one.
const String _zwsp = '​';

/// `<|im_start|>`, `<|eot_id|>`, `<|begin_of_text|>`, `<|end|>` and every other
/// token in the pipe family (ChatML, Llama 3, Phi, Qwen, DeepSeek). Broken at
/// the opening `<|` rather than matched name by name: the family keeps growing,
/// and no genuine sentence needs `<|` to survive intact. The lookahead keeps a
/// second pass from stacking a second space onto an already-broken token.
final RegExp _pipeToken = RegExp('<\\|(?!$_zwsp)');

/// Angle-bracket tokens without pipes: Gemma's turn markers, SentencePiece's
/// `<s>`/`</s>`, reasoning and tool-call tags.
final RegExp _angleToken = RegExp(
  r'<(/?)(start_of_turn|end_of_turn|start_of_image|end_of_image|bos|eos|pad|'
  r'unk|s|think|tool_call|tool_response)>',
  caseSensitive: false,
);

/// Llama 2 / Mistral square-bracket markers.
final RegExp _bracketToken = RegExp(
  r'\[(/?)(INST|SYSTEM_PROMPT|AVAILABLE_TOOLS|TOOL_CALLS|TOOL_RESULTS)\]',
  caseSensitive: false,
);

/// Llama 2's system block.
final RegExp _sysToken = RegExp(r'<<(/?)SYS>>', caseSensitive: false);

/// The start of an image tag, which is all fllama's scanner needs to see.
final RegExp _imgTag = RegExp(r'<img', caseSensitive: false);

/// Something shaped like one of our own fence lines, id or not. Removed whole:
/// a page that writes `<<<END WEB_RESULTS>>>` is trying to close the quote.
final RegExp _forgedFence = RegExp(r'<<<[^<>\n]{0,80}>>>');

/// Any run of three angle brackets left after that — half a forged fence, or
/// one assembled from pieces either side of a removed one.
final RegExp _tripleOpen = RegExp(r'<{3,}');
final RegExp _tripleClose = RegExp(r'>{3,}');

/// Makes [text] unable to act as anything but text once it is in a prompt.
///
/// Idempotent, so content that is neutralized field by field and then fenced
/// as a block (which neutralizes again) comes out the same as neutralizing it
/// once.
String neutralizeUntrusted(String text) {
  if (text.isEmpty) return text;

  var out = text;
  // Fences first, and to a fixed point: removing one forged marker can butt
  // two halves of another together.
  while (true) {
    final next = out.replaceAll(_forgedFence, '');
    if (next == out) break;
    out = next;
  }
  out = out
      .replaceAll(_tripleOpen, '<<')
      .replaceAll(_tripleClose, '>>');

  // Then the tokens. Each insertion puts the space right after the opening
  // bracket, so none of them can create a new match for another pattern.
  return out
      .replaceAll(_pipeToken, '<|$_zwsp')
      .replaceAllMapped(_sysToken, (m) => '<$_zwsp<${m[1]}SYS>>')
      .replaceAllMapped(_angleToken, (m) => '<${m[1]}$_zwsp${m[2]}>')
      .replaceAllMapped(_bracketToken, (m) => '[$_zwsp${m[1]}${m[2]}]')
      .replaceAll(_imgTag, '<${_zwsp}img');
}

const String _idAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/// Wraps [content] in a labelled fence the content itself cannot close.
///
/// The id is eight characters from a secure source, fresh per prompt. It is not
/// a secret in any cryptographic sense — the model sees it — but the page was
/// written before the id existed, which is all that matters. [random] is only
/// there so tests can pin the id.
String fenceUntrusted(String label, String content, {Random? random}) {
  final rng = random ?? Random.secure();
  final id = String.fromCharCodes([
    for (var i = 0; i < 8; i++)
      _idAlphabet.codeUnitAt(rng.nextInt(_idAlphabet.length)),
  ]);
  return '<<<$label id=$id>>>\n'
      '${neutralizeUntrusted(content)}\n'
      '<<<END $label id=$id>>>';
}
