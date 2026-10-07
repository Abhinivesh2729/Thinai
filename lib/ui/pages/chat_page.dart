import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../chat/document_attachment.dart';
import '../../chat/follow_ups.dart';
import '../../chat/image_attachment.dart';
import '../../chat/prompt_budget.dart';
import '../../llm/generation_settings.dart';
import '../../llm/llm_engine.dart';
import '../../models_repo/catalog.dart';
import '../../models_repo/model_store.dart';
import '../../state/providers.dart';
import '../../web/web_search.dart';
import '../theme/app_theme.dart';
import '../share.dart';
import '../widgets/app_drawer.dart';
import '../widgets/coach_mark_targets.dart';
import '../widgets/markdown_text.dart';
import '../widgets/model_settings_sheet.dart';
import '../widgets/ui_kit.dart';
import 'chat_history_page.dart';

/// Builds the message list sent to the model, with same-role neighbours merged.
///
/// Chat templates such as Gemma's require the roles to strictly alternate and
/// `raise_exception` rather than degrade when they do not. A reply stopped
/// before it produced anything leaves an empty assistant turn, which is not
/// worth sending, and dropping it would put two user messages back to back —
/// poisoning not just that send but every later one in the conversation, since
/// the empty turn stays in the history. Merging neighbours keeps the transcript
/// sendable without discarding anything the user wrote.
List<ChatMessage> _promptFrom(
  List<ChatTurn> turns,
  String pending, {
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

  // The document leads, as a system message: it belongs to the conversation
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

/// Size of the round button left of the message field, and of the icon in it.
const double kComposerButton = 40;
const double kComposerIcon = 21;

/// The speed dial's entries, named so tests can reach them without matching on
/// label text that also appears elsewhere in the composer.
const Key dialWebSearchKey = ValueKey('composer.dial.web');
const Key dialCameraKey = ValueKey('composer.dial.camera');
const Key dialImageKey = ValueKey('composer.dial.image');
const Key dialDocumentKey = ValueKey('composer.dial.document');

/// Trims an engine failure to something a snack bar can carry. The native
/// messages run to several paragraphs of Jinja stack trace; the first line
/// carries the part worth reading.
String _briefly(String message) {
  final firstLine = message
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => message.trim());
  if (firstLine.length <= 160) return firstLine;
  return '${firstLine.substring(0, 157)}...';
}

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();

  /// Document pinned to this conversation, if one has been attached. Stays
  /// until the user removes it so follow-up questions still see it.
  DocumentAttachment? _document;

  /// Image pinned to this conversation, same idea: one photo, several
  /// questions about it.
  ImageAttachment? _image;
  final _scroll = ScrollController();
  bool _generating = false;

  /// True while the web search for this turn is still running, before the
  /// model has been given anything to answer from.
  bool _searching = false;

  /// Set when stop is pressed during that search. The reply never starts;
  /// [_send] sees this when the search returns and winds the turn up.
  bool _abandonTurn = false;

  /// The reply in flight. Held so stopping can detach from it immediately
  /// rather than waiting for the engine to wind down natively.
  StreamSubscription<LlmToken>? _reply;

  /// Completes when the current turn is over, whether the model finished, the
  /// stream failed, or the user pressed stop.
  Completer<void>? _turnDone;

  /// Whether arriving tokens should keep the newest message in view. Cleared
  /// the moment the user drags back through the conversation, so reading an
  /// earlier message is not fought by the stream, and restored when they
  /// return to the bottom.
  bool _followTail = true;

  /// Guards against stacking one post-frame scroll callback per token.
  bool _scrollScheduled = false;

  /// How close to the end still counts as being at the bottom.
  static const _tailSlack = 48.0;

  /// Frames allowed for the jump to settle when a conversation is opened.
  /// Larger than the streaming budget: there is only this one chance to land
  /// on the newest message, and the extent of a long transcript takes several
  /// passes to firm up. Costs nothing when it converges early, which it does.
  static const _openSettleFrames = 30;

  @override
  void initState() {
    super.initState();
    // Covers the case where the conversations are already in hand when this
    // page is built. At a cold start they are still loading, and the listener
    // in [build] catches them when they arrive.
    _revealLatest();
  }

  @override
  void dispose() {
    _reply?.cancel();
    _followUpReply?.cancel();
    _searchCancel?.cancel();
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Picks a text document and pins it to the conversation.
  Future<void> _attachDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kTextExtensions.toList(),
        withData: true,
      );
      final file = result?.files.singleOrNull;
      if (file == null) return;
      final bytes = file.bytes;
      if (bytes == null) {
        _toast('Could not read that file.');
        return;
      }
      final document = readDocument(file.name, bytes);
      if (!mounted) return;
      setState(() => _document = document);
      if (document.truncated) {
        _toast(
          'Attached the first ${document.sizeLabel}. '
          'The rest did not fit the context window.',
        );
      }
    } on FormatException catch (e) {
      if (mounted) _toast(e.message);
    } catch (e) {
      if (mounted) _toast('Could not attach that file: $e');
    }
  }

  /// Whether the loaded model can be shown a picture, saying why not when it
  /// cannot. Checked before the camera or the gallery opens: finding out after
  /// framing a shot that the model is blind is the wrong order.
  bool _canSeeImages() {
    if (ref.read(visionReadyProvider)) return true;
    _toast('This model cannot read images. Try Gemma 3 4B instead.');
    return false;
  }

  /// Takes a photo with the phone's camera and pins it to the conversation.
  ///
  /// The shot is handed over by the system camera app, so no camera permission
  /// of ours is involved. It is asked for at a size the projector can actually
  /// use — a 12 MP original is downsampled to a few hundred pixels a side
  /// regardless, and the full-size bytes would be base64'd into the prompt on
  /// the way there.
  Future<void> _attachCamera() async {
    if (!_canSeeImages()) return;
    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (shot == null) return;
      final bytes = await shot.readAsBytes();
      // The camera hands back a JPEG; a name without a usable extension would
      // only fail the format check for no reason.
      final name = mimeTypeForImage(shot.name) == null
          ? 'photo.jpg'
          : shot.name;
      final image = readImage(name, bytes);
      if (!mounted) return;
      setState(() => _image = image);
    } on FormatException catch (e) {
      if (mounted) _toast(e.message);
    } catch (e) {
      if (mounted) _toast('Could not take that photo: $e');
    }
  }

  /// Picks an image and pins it to the conversation.
  Future<void> _attachImage() async {
    if (!_canSeeImages()) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kImageExtensions.toList(),
        withData: true,
      );
      final file = result?.files.singleOrNull;
      if (file == null) return;
      final bytes = file.bytes;
      if (bytes == null) {
        _toast('Could not read that image.');
        return;
      }
      final image = readImage(file.name, bytes);
      if (!mounted) return;
      setState(() => _image = image);
    } on FormatException catch (e) {
      if (mounted) _toast(e.message);
    } catch (e) {
      if (mounted) _toast('Could not attach that image: $e');
    }
  }

  /// Searches the web for [text] and pins what came back to the reply being
  /// written.
  ///
  /// Never throws: a search that fails is a worse answer, not a failed turn, so
  /// the user is told what happened and the model answers on its own — which is
  /// still the whole app working, just without today's news.
  ///
  /// [priorTurns] is the conversation before this message. "what is its price"
  /// after "latest iphone" means nothing to a search engine on its own — live,
  /// it came back with grammar guides to "its" — so the previous question's key
  /// words ride along with a follow-up that leans on it.
  Future<WebSearchResults?> _lookUp(
    String text,
    ChatSessionsController history, {
    List<ChatTurn> priorTurns = const [],
  }) async {
    final cancel = CancelToken();
    _searchCancel = cancel;
    try {
      final query = searchQueryFrom(
        text,
        previousUserTurns: [
          for (final turn in priorTurns)
            if (turn.role == 'user') turn.content,
        ],
      );
      final results = await ref
          .read(webSearchProvider)
          .search(query, cancelToken: cancel);
      // Stopped while the top page was being read, which never throws.
      if (cancel.isCancelled) return null;
      if (results.isEmpty) {
        if (mounted) {
          _toast(
            results.blocked
                ? 'Search engines are rate-limiting this network right now. '
                      'Answering without the web.'
                : 'No web results for that. Answering from the model itself.',
          );
        }
        return null;
      }
      // The query goes with the sources so the list can say what was actually
      // searched — the first thing to check when an answer is off.
      history.attachSources([
        for (final result in results.results) result.withQuery(results.query),
      ]);
      return results;
    } on WebSearchException catch (e) {
      if (mounted) _toast('${e.message} Answering without it.');
    } catch (_) {
      // A stop is the user's doing, not a failure worth a snack bar.
      if (!cancel.isCancelled && mounted) {
        _toast('Web search failed. Answering without it.');
      }
    } finally {
      if (identical(_searchCancel, cancel)) _searchCancel = null;
      if (mounted) setState(() => _searching = false);
    }
    return null;
  }

  /// The search in flight, held so stop can abort the request itself rather
  /// than let it run to completion and throw the answer away.
  CancelToken? _searchCancel;

  /// Sends what is in the composer: a new question, or — while editing — the
  /// new version of an earlier one.
  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _generating) return;
    final editing = _editingIndex;
    final turns = ref.read(chatSessionsProvider).activeTurns;
    if (editing != null && editing < turns.length) {
      final unchanged = turns[editing].content.trim() == text;
      final sent = await _runExchange(
        text,
        priorTurns: turns.sublist(0, editing),
        begin: (history) => history.forkAt(editing, text),
      );
      if (sent) {
        setState(() => _editingIndex = null);
        if (unchanged) _toast('Same question, new answer.');
      }
      return;
    }
    await _runExchange(
      text,
      priorTurns: turns,
      begin: (history) => history.startExchange(text),
    );
  }

  /// Asks the latest question again for a different answer. The old answer is
  /// kept as the previous version, one tap away.
  Future<void> _regenerate() async {
    if (_generating) return;
    final turns = ref.read(chatSessionsProvider).activeTurns;
    final index = turns.lastIndexWhere((t) => t.role == 'user');
    if (index < 0) return;
    final text = turns[index].content;
    await _runExchange(
      text,
      priorTurns: turns.sublist(0, index),
      begin: (history) => history.forkAt(index, text),
      clearInput: false,
    );
  }

  /// Sends a suggested follow-up as the next question, leaving anything the
  /// user had started typing where it is.
  Future<void> _askFollowUp(String question) async {
    if (_generating) return;
    await _runExchange(
      question,
      priorTurns: ref.read(chatSessionsProvider).activeTurns,
      begin: (history) => history.startExchange(question),
      clearInput: false,
    );
  }

  /// One exchange, start to finish: search if it wants the web, stream the
  /// reply, save it, then suggest what to ask next.
  ///
  /// [begin] puts the question into the conversation — appended, or as a new
  /// version of an earlier one — and [priorTurns] is everything before it.
  /// Returns false when nothing was sent.
  Future<bool> _runExchange(
    String text, {
    required List<ChatTurn> priorTurns,
    required void Function(ChatSessionsController history) begin,
    bool clearInput = true,
  }) async {
    final activeId = ref.read(activeModelIdProvider);
    if (activeId == null) {
      _toast('Load a model from the Models tab first.');
      return false;
    }
    final model = await ref.read(modelStoreProvider).findById(activeId);
    if (model == null) {
      _toast('Active model is missing from disk.');
      return false;
    }
    // Suggestions still being written for the last reply would hold the
    // engine's queue in front of this one.
    _cancelFollowUps();
    if (!mounted) return false;

    final history = ref.read(chatSessionsProvider.notifier);

    // Decided here rather than asked: web search is on unless it was turned
    // off, and each question is judged on whether it wants live information.
    // An attachment answers its own questions, so neither the document nor the
    // photo in front of the model is a reason to go to the internet.
    final searchWeb =
        ref.read(webSearchEnabledProvider) &&
        _document == null &&
        _image == null &&
        needsWebSearch(text);

    begin(history);
    if (clearInput) _input.clear();
    _stoppedByUser = false;
    ref.read(chatGeneratingProvider.notifier).state = true;
    setState(() {
      _generating = true;
      // The search runs before the model sees anything, so the bubble says so
      // rather than pretending a reply is already being written.
      _searching = searchWeb;
      // Sending is a deliberate jump to the end of the conversation.
      _followTail = true;
    });
    _stickToBottom();

    final search = searchWeb
        ? await _lookUp(text, history, priorTurns: priorTurns)
        : null;
    if (!mounted) return true;
    // Stop pressed while the search was still out: the turn ends here, leaving
    // the empty reply the same "Stopped" bubble a cancelled generation does.
    if (_abandonTurn) {
      _abandonTurn = false;
      setState(() {
        _generating = false;
        _searching = false;
      });
      ref.read(chatGeneratingProvider.notifier).state = false;
      // Sources under a reply that was never written would credit an answer
      // that does not exist.
      history.attachSources(const []);
      await history.finishExchange();
      return true;
    }

    // The model's context window and temperature, as set from the tune button
    // — the same values the API server uses for it.
    final options = await GenerationSettingsStore.instance.optionsFor(model);

    final prompt = _promptFrom(
      priorTurns,
      text,
      document: _document,
      image: _image,
      search: search,
    );

    var failed = false;
    final turnDone = Completer<void>();
    _turnDone = turnDone;
    _reply = ref
        .read(llmEngineProvider)
        // Trimmed to the window it is sent to: a chat that outgrew it — or had
        // its window turned down — would otherwise fail every message.
        .chat(
          fitToContext(prompt, options.contextSize),
          modelPath: model.path,
          options: options,
        )
        .listen(
          (token) {
            if (!mounted) return;
            // Kept out of the transcript: an error stored as the reply is read
            // back to the model as prior assistant output on every later turn.
            if (token.isError) {
              failed = true;
              _toast(_briefly(token.full), lasting: const Duration(seconds: 6));
              return;
            }
            history.updateLast(token.full);
            _stickToBottom();
          },
          onError: (Object e) {
            failed = true;
            if (mounted) _toast('Error: $e');
            if (!turnDone.isCompleted) turnDone.complete();
          },
          onDone: () {
            if (!turnDone.isCompleted) turnDone.complete();
          },
          cancelOnError: true,
        );

    await turnDone.future;

    // Detaching here stops a reply the native side is still winding down after
    // a stop from writing any more text into the bubble.
    final reply = _reply;
    _reply = null;
    _turnDone = null;
    await reply?.cancel();

    // Persists whatever was produced, including a reply cut short by the
    // stop button or an error.
    await history.finishExchange();
    if (!mounted) return true;
    setState(() => _generating = false);
    ref.read(chatGeneratingProvider.notifier).state = false;

    // A reply that was stopped or failed is not one to build on.
    final sessions = ref.read(chatSessionsProvider);
    final answer = sessions.activeTurns.isEmpty
        ? ''
        : sessions.activeTurns.last.content;
    if (!_stoppedByUser &&
        !failed &&
        answer.trim().isNotEmpty &&
        sessions.activeId != null &&
        ref.read(followUpsEnabledProvider)) {
      unawaited(_suggestFollowUps(model, sessions.activeId!, text, answer));
    }
    return true;
  }

  /// The follow-up pass in flight, held so a new question can stop it.
  StreamSubscription<LlmToken>? _followUpReply;

  /// True while follow-ups for the latest reply are being written.
  bool _suggesting = false;

  /// Writes three next questions for [answer] and pins them under it.
  ///
  /// Best effort and silent: a model that rambles, fails, or is interrupted
  /// simply leaves no suggestions, since nothing here is worth an error.
  Future<void> _suggestFollowUps(
    LocalModel model,
    String conversationId,
    String question,
    String answer,
  ) async {
    final options = await GenerationSettingsStore.instance.optionsFor(
      model,
      requestedTemperature: 0.6,
      maxTokens: 96,
    );
    if (!mounted || _generating) return;
    setState(() => _suggesting = true);
    _stickToBottom();
    final done = Completer<void>();
    _followUpDone = done;
    var raw = '';
    final stream = ref
        .read(llmEngineProvider)
        .chat(
          fitToContext(followUpPrompt(question, answer), options.contextSize),
          modelPath: model.path,
          options: options,
        );
    _followUpStream = stream;
    _followUpReply = stream.listen(
      (token) {
        if (!token.isError) raw = token.full;
      },
      onError: (Object _) {
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
      cancelOnError: true,
    );
    await done.future;
    final interrupted = _followUpReply == null;
    _followUpReply = null;
    _followUpStream = null;
    _followUpDone = null;
    if (mounted) setState(() => _suggesting = false);
    if (interrupted) return;
    final followUps = parseFollowUps(raw, askedQuestion: question);
    if (followUps.isEmpty) return;
    await ref
        .read(chatSessionsProvider.notifier)
        .setFollowUps(conversationId, answer, followUps);
    _stickToBottom();
  }

  /// The follow-up request itself, so withdrawing it stops only that one.
  Stream<LlmToken>? _followUpStream;

  /// Completes the follow-up pass's wait when it is withdrawn early.
  Completer<void>? _followUpDone;

  /// Stops a follow-up pass that is still running, if there is one.
  void _cancelFollowUps() {
    final pending = _followUpReply;
    if (pending == null) return;
    _followUpReply = null;
    final stream = _followUpStream;
    if (stream != null) ref.read(llmEngineProvider).cancelStream(stream);
    unawaited(pending.cancel());
    final done = _followUpDone;
    if (done != null && !done.isCompleted) done.complete();
    if (mounted) setState(() => _suggesting = false);
  }

  /// Set by the stop button, so a reply the user cut short gets no
  /// suggestions built on half an answer.
  bool _stoppedByUser = false;

  /// The earlier question being rewritten in the composer, if any.
  int? _editingIndex;

  /// Puts the question at [index] in the composer to be rewritten.
  void _startEdit(int index) {
    final turns = ref.read(chatSessionsProvider).activeTurns;
    if (_generating || index >= turns.length) return;
    final text = turns[index].content;
    setState(() => _editingIndex = index);
    _input
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    _inputFocus.requestFocus();
  }

  void _cancelEdit() {
    if (_editingIndex == null) return;
    setState(() => _editingIndex = null);
    _input.clear();
  }

  /// Ends the reply in flight. The engine is told to cancel, and the UI stops
  /// listening straight away instead of waiting for the native side to
  /// acknowledge, so the button is always immediate.
  void _stop() {
    if (!_generating) return;
    _stoppedByUser = true;
    // Nothing has been handed to the engine yet: the search is what is in
    // flight, and its answer is dropped when it lands.
    if (_searching) {
      _searchCancel?.cancel();
      setState(() {
        _abandonTurn = true;
        _searching = false;
      });
      return;
    }
    ref.read(llmEngineProvider).cancelCurrent();
    final turnDone = _turnDone;
    if (turnDone != null && !turnDone.isCompleted) turnDone.complete();
  }

  /// Turns automatic web search on or off.
  ///
  /// No dialog either way. On is the normal state and asking permission per
  /// question is exactly what this feature exists to avoid; off is a plain
  /// preference. The snack bar says which way it went, since the button that
  /// did it looks the same afterwards.
  Future<void> _toggleWebSearch() async {
    final next = !ref.read(webSearchEnabledProvider);
    await ref.read(webSearchEnabledProvider.notifier).set(next);
    if (!mounted) return;
    _toast(next ? 'Web search on.' : 'Web search off.');
  }

  /// Deletes the conversation on screen after confirming, since it is also
  /// being removed from the history list.
  Future<void> _deleteCurrent() async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete this chat?',
      message: 'It is removed from your chat history too.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(chatSessionsProvider.notifier).deleteActive();
  }

  void _openHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChatHistoryPage()));
  }

  /// Puts a starter prompt in the field for the user to edit or send. Filled
  /// rather than sent: a suggestion is a sentence to start from, and sending
  /// it on tap would spend a reply on words the user never chose.
  void _usePrompt(String prompt) {
    _input
      ..text = prompt
      ..selection = TextSelection.collapsed(offset: prompt.length);
    _inputFocus.requestFocus();
  }

  /// Opens the model switcher. The sheet only says what was chosen; acting on
  /// it happens here, from a context that outlives the sheet's closing route.
  Future<void> _openModelSheet() async {
    FocusScope.of(context).unfocus();
    final choice = await showModalBottomSheet<_SheetChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ModelSheet(generating: _generating),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case _SheetChoice(:final model?):
        if (model.id == ref.read(activeModelIdProvider)) return;
        await ref.read(activeModelIdProvider.notifier).set(model);
      case _SheetChoice(settings: true):
        final id = ref.read(activeModelIdProvider);
        if (id == null) return;
        final model = await ref.read(modelStoreProvider).findById(id);
        if (model == null || !mounted) return;
        await showModelSettingsSheet(context, model);
      case _SheetChoice():
        ref.read(shellTabIndexProvider.notifier).state = 1;
    }
  }

  /// Keeps the newest message in view as tokens arrive, but only while the
  /// user has not scrolled away to read something earlier.
  void _stickToBottom({int settleFrames = 8}) {
    if (!_followTail || _scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || !_followTail || !_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if ((_scroll.position.pixels - target).abs() < 1) return;
      // Jumped, not animated: a 200ms animation per token never finishes
      // before the next token restarts it, which leaves the list permanently
      // mid-animation and unable to settle anywhere else.
      _scroll.jumpTo(target);
      // A builder-backed list only estimates the extent of the items it has
      // not laid out, so on a long conversation this lands short of the true
      // end and the estimate grows once the tail is built. Chase it over the
      // next few frames rather than relying on the next token to try again —
      // a short reply may not have one. Settles as soon as the two agree.
      if (settleFrames > 0) _stickToBottom(settleFrames: settleFrames - 1);
    });
  }

  /// Puts the view on the newest message.
  ///
  /// Opening a conversation would otherwise start at the top, leaving the
  /// reader to scroll through the whole transcript to reach the reply they
  /// came back for.
  void _revealLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_followTail) setState(() => _followTail = true);
      _stickToBottom(settleFrames: _openSettleFrames);
    });
  }

  Future<void> _jumpToLatest() async {
    setState(() => _followTail = true);
    if (!_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  /// Tracks whether the user has parked away from the newest message.
  ///
  /// Only user-driven scrolls count. The list also reports offset changes when
  /// a streaming reply makes it taller, and reading those as "the user scrolled
  /// up" is what would unpin the view a token after pinning it.
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      // Forward means the content is moving down, exposing earlier messages:
      // the user is scrolling back to read, so stop chasing the tail.
      if (notification.direction == ScrollDirection.forward && _followTail) {
        setState(() => _followTail = false);
      }
    } else if (notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      final atBottom = metrics.pixels >= metrics.maxScrollExtent - _tailSlack;
      if (atBottom != _followTail) setState(() => _followTail = atBottom);
    }
    return false;
  }

  /// Shares [text] through Android's share sheet, or copies it where there
  /// is no sheet to open.
  Future<void> _share(String text) async {
    final shared = await shareText(text);
    if (!shared && mounted) {
      await copyWithToast(context, text, message: 'Copied to share');
    }
  }

  /// Everything that can be done with the message at [index], behind a long
  /// press: the gesture people already try on a chat message.
  Future<void> _showMessageActions(int index) async {
    final turns = ref.read(chatSessionsProvider).activeTurns;
    if (index >= turns.length) return;
    final turn = turns[index];
    if (turn.content.isEmpty) return;
    HapticFeedback.mediumImpact();
    final isUser = turn.role == 'user';
    final latestAnswer = !isUser && index == turns.length - 1;
    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      builder: (_) => _MessageActionsSheet(
        preview: turn.content,
        isUser: isUser,
        canEdit: isUser && !_generating,
        canRegenerate: latestAnswer && !_generating,
        canDelete: !_generating,
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _MessageAction.copy:
        await copyWithToast(
          context,
          turn.content,
          message: isUser ? 'Message copied' : 'Reply copied',
        );
      case _MessageAction.select:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _SelectTextPage(text: turn.content),
          ),
        );
      case _MessageAction.edit:
        _startEdit(index);
      case _MessageAction.regenerate:
        await _regenerate();
      case _MessageAction.share:
        await _share(turn.content);
      case _MessageAction.delete:
        final ok = await confirmAction(
          context,
          title: 'Delete this exchange?',
          message: 'The question and its answer are removed from this chat.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (ok) {
          _cancelEdit();
          await ref.read(chatSessionsProvider.notifier).deleteExchange(index);
        }
    }
  }

  void _toast(String text, {Duration? lasting}) =>
      showToast(context, text, duration: lasting);

  @override
  Widget build(BuildContext context) {
    final activeId = ref.watch(activeModelIdProvider);
    final sessions = ref.watch(chatSessionsProvider);
    final messages = sessions.activeTurns;

    // Switching conversations — picking one from history, or the stored ones
    // arriving at startup — should land on the newest message. The page is
    // kept alive inside the shell's IndexedStack, so there is no remount to
    // hang this off.
    ref.listen<String?>(chatSessionsProvider.select((s) => s.activeId), (
      previous,
      next,
    ) {
      if (previous == next) return;
      // An edit belongs to the conversation it was started in.
      if (_editingIndex != null) _cancelEdit();
      _revealLatest();
    });

    return Scaffold(
      appBar: AppBar(
        leading: MenuButton(key: CoachMarkTargets.menuButton),
        titleSpacing: 0,
        title: _ModelSwitcher(activeId: activeId, onTap: _openModelSheet),
        actions: [
          // Only offered once there is something to leave behind: on a blank
          // chat it would do nothing.
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New chat',
              onPressed: _generating
                  ? null
                  : () =>
                        ref.read(chatSessionsProvider.notifier).startNewChat(),
            ),
          PopupMenuButton<_ChatMenu>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            position: PopupMenuPosition.under,
            onSelected: (choice) async {
              switch (choice) {
                case _ChatMenu.tune:
                  final id = ref.read(activeModelIdProvider);
                  if (id == null) return;
                  final model = await ref.read(modelStoreProvider).findById(id);
                  if (model == null || !context.mounted) return;
                  await showModelSettingsSheet(context, model);
                case _ChatMenu.history:
                  _openHistory();
                case _ChatMenu.delete:
                  await _deleteCurrent();
              }
            },
            itemBuilder: (context) => [
              if (activeId != null)
                const PopupMenuItem(
                  value: _ChatMenu.tune,
                  child: _MenuRow(
                    icon: Icons.tune_rounded,
                    label: 'Context & temperature',
                  ),
                ),
              const PopupMenuItem(
                value: _ChatMenu.history,
                child: _MenuRow(
                  icon: Icons.history_rounded,
                  label: 'All chats',
                ),
              ),
              if (messages.isNotEmpty)
                PopupMenuItem(
                  value: _ChatMenu.delete,
                  enabled: !_generating,
                  child: const _MenuRow(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete chat',
                    danger: true,
                  ),
                ),
            ],
          ),
          const SizedBox(width: Space.xs),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _EmptyChat(
                    activeId: activeId,
                    webSearch: ref.watch(webSearchEnabledProvider),
                    onPrompt: _usePrompt,
                    onChooseModel: () =>
                        ref.read(shellTabIndexProvider.notifier).state = 1,
                  )
                : Stack(
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: _onScrollNotification,
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(
                            Space.lg,
                            Space.sm,
                            Space.lg,
                            Space.xl,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, i) {
                            final last = i == messages.length - 1;
                            final latestUser =
                                messages[i].role == 'user' &&
                                messages.lastIndexWhere(
                                      (t) => t.role == 'user',
                                    ) ==
                                    i;
                            return _MessageBubble(
                              msg: messages[i],
                              // Typing dots mean "the reply is on its way".
                              // Once the turn is over an empty bubble means
                              // the reply was stopped before it started, and
                              // animating forever would be a lie.
                              pending: _generating && last,
                              searching: _searching && last,
                              latest: last || latestUser,
                              busy: _generating,
                              editing: _editingIndex == i,
                              suggesting: _suggesting && last,
                              onLongPress: () => _showMessageActions(i),
                              onEdit: () => _startEdit(i),
                              onSwitchVersion: (target) {
                                // The edit was of the version being left.
                                _cancelEdit();
                                ref
                                    .read(chatSessionsProvider.notifier)
                                    .switchVersion(i, target);
                              },
                              onRegenerate: _regenerate,
                              onShare: () => _share(messages[i].content),
                              onFollowUp: _askFollowUp,
                            );
                          },
                        ),
                      ),
                      // Offered only once the user has parked away from the
                      // newest message, which is exactly when the view has
                      // stopped following the stream.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: Space.md,
                        child: Center(
                          child: IgnorePointer(
                            ignoring: _followTail,
                            child: AnimatedOpacity(
                              opacity: _followTail ? 0 : 1,
                              duration: Motion.fast,
                              child: AnimatedSlide(
                                offset: _followTail
                                    ? const Offset(0, 0.4)
                                    : Offset.zero,
                                duration: Motion.base,
                                curve: Motion.curve,
                                child: _JumpToLatest(onTap: _jumpToLatest),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          _Composer(
            controller: _input,
            focusNode: _inputFocus,
            editing: _editingIndex != null,
            onCancelEdit: _cancelEdit,
            enabled: !_generating && activeId != null,
            onSubmit: _send,
            onStop: _stop,
            generating: _generating,
            document: _document,
            image: _image,
            visionReady: ref.watch(visionReadyProvider),
            webSearch: ref.watch(webSearchEnabledProvider),
            onToggleWebSearch: _toggleWebSearch,
            onAttachDocument: _attachDocument,
            onAttachImage: _attachImage,
            onAttachCamera: _attachCamera,
            onRemoveDocument: () => setState(() => _document = null),
            onRemoveImage: () => setState(() => _image = null),
          ),
        ],
      ),
    );
  }
}

enum _ChatMenu { tune, history, delete }

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : scheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: Space.md),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

/// What a served id is called in the catalogue, or the id itself for a model
/// that was imported or downloaded by URL.
String _modelLabel(String id) {
  for (final m in [...chatCatalog, ...embeddingCatalog]) {
    if (m.servedId == id) return m.displayName;
  }
  return id;
}

/// The header: which model is answering, and the way to change it.
///
/// Replaces a coloured banner that sat between the header and the chat. The
/// model is the one piece of context that changes what every reply is like,
/// so it belongs in the title, where switching it is one tap away — the way
/// every serious chat client has converged on.
class _ModelSwitcher extends StatelessWidget {
  const _ModelSwitcher({required this.activeId, required this.onTap});

  final String? activeId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final app = AppColors.of(context);
    final id = activeId;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.sm, 6, Space.xs, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        id == null ? 'Choose a model' : _modelLabel(id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: id == null ? scheme.outline : app.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        id == null ? 'No model loaded' : 'On-device',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the model sheet was closed with: a model to switch to, the active
/// model's settings, or (neither) the Models tab.
class _SheetChoice {
  const _SheetChoice({this.model, this.settings = false});

  final LocalModel? model;
  final bool settings;
}

/// Installed chat models, one tap to switch, plus the two places a user goes
/// next: the active model's settings and the full Models page.
class _ModelSheet extends ConsumerWidget {
  const _ModelSheet({required this.generating});

  /// Switching mid-reply would swap the weights out from under the stream.
  final bool generating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeId = ref.watch(activeModelIdProvider);
    final installed = ref.watch(modelListProvider).valueOrNull ?? const [];
    final embeddingIds = {for (final m in embeddingCatalog) m.servedId};
    final chatModels = [
      for (final m in installed)
        if (!embeddingIds.contains(m.id)) m,
    ];

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xxl,
                0,
                Space.xxl,
                Space.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Model', style: theme.textTheme.titleLarge),
                  const SizedBox(height: Space.xs),
                  Text(
                    generating
                        ? 'Wait for the reply to finish before switching.'
                        : 'Runs entirely on this phone. Switch any time.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (chatModels.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xxl,
                  Space.sm,
                  Space.xxl,
                  Space.lg,
                ),
                child: InlineNotice(
                  text:
                      'No chat models on this phone yet. Download one from '
                      'the Models tab. The smallest takes under a minute.',
                  icon: Icons.download_rounded,
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  children: [
                    for (final m in chatModels)
                      _ModelOption(
                        label: _modelLabel(m.id),
                        detail: _fmtBytes(m.sizeBytes),
                        selected: m.id == activeId,
                        onTap: generating
                            ? null
                            : () => Navigator.pop(
                                context,
                                _SheetChoice(model: m),
                              ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.sm,
                Space.lg,
                Space.lg,
              ),
              child: Row(
                children: [
                  if (activeId != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Settings'),
                        onPressed: () => Navigator.pop(
                          context,
                          const _SheetChoice(settings: true),
                        ),
                      ),
                    ),
                  if (activeId != null) const SizedBox(width: Space.md),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('Browse models'),
                      onPressed: () =>
                          Navigator.pop(context, const _SheetChoice()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelOption extends StatelessWidget {
  const _ModelOption({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.md,
          ),
          child: Row(
            children: [
              IconTile(
                icon: Icons.memory_rounded,
                size: 36,
                background: selected
                    ? scheme.primary
                    : scheme.surfaceContainerLow,
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    Text(detail, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} '
      '${units[unit]}';
}

/// Puts the user back on the newest message after they have scrolled away.
class _JumpToLatest extends StatelessWidget {
  final VoidCallback onTap;
  const _JumpToLatest({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.of(context).card,
      shape: CircleBorder(side: BorderSide(color: scheme.outlineVariant)),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 20,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// A starting point for a blank conversation.
class _Starter {
  const _Starter(this.icon, this.title, this.detail, this.prompt);

  final IconData icon;
  final String title;
  final String detail;
  final String prompt;
}

const _starters = [
  _Starter(
    Icons.lightbulb_outline_rounded,
    'Explain',
    'how on-device AI works',
    'Explain how on-device AI works, in simple terms.',
  ),
  _Starter(
    Icons.edit_outlined,
    'Write',
    'a polite follow-up email',
    'Write a short, polite follow-up email after a job interview.',
  ),
  _Starter(
    Icons.code_rounded,
    'Code',
    'a Python helper',
    'Write a Python function that checks whether a string is a palindrome.',
  ),
  _Starter(
    Icons.map_outlined,
    'Plan',
    'a weekend trip to Ooty',
    'Plan a relaxed two-day trip to Ooty on a modest budget.',
  ),
];

class _EmptyChat extends StatelessWidget {
  final String? activeId;

  /// Whether questions will be looked up before they are answered. Worth
  /// saying here: "runs entirely on-device" stops being true the moment it is
  /// on, and a promise that quietly lapses is worse than no promise.
  final bool webSearch;

  /// Fills the composer with a starter prompt.
  final ValueChanged<String> onPrompt;

  /// Takes the user to where models are downloaded.
  final VoidCallback onChooseModel;

  const _EmptyChat({
    required this.activeId,
    required this.onPrompt,
    required this.onChooseModel,
    this.webSearch = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ready = activeId != null;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: Space.xxl),
              const ThinaiMark(size: 56),
              const SizedBox(height: Space.xl),
              Text(
                ready ? 'What can I help with?' : 'Ready when you are',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: Space.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  !ready
                      ? 'Load a model, then start chatting.'
                      : webSearch
                      ? 'Answers run on-device, with live results from the web.'
                      : 'Your conversation runs entirely on-device.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: Space.xxl),
              if (!ready)
                FilledButton.icon(
                  onPressed: onChooseModel,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Choose a model'),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      for (var row = 0; row < _starters.length; row += 2) ...[
                        if (row > 0) const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _StarterCard(
                                starter: _starters[row],
                                onTap: () => onPrompt(_starters[row].prompt),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StarterCard(
                                starter: _starters[row + 1],
                                onTap: () =>
                                    onPrompt(_starters[row + 1].prompt),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: Space.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({required this.starter, required this.onTap});

  final _Starter starter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      radius: Radii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(starter.icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(starter.title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            starter.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  /// An earlier question is being rewritten: sending saves it as a new
  /// version instead of asking something new.
  final bool editing;
  final VoidCallback onCancelEdit;
  final bool enabled;
  final bool generating;
  final VoidCallback onSubmit;

  /// Cancels the reply in flight. The one button is send or stop depending on
  /// what is happening, so the control is always where the thumb already is.
  final VoidCallback onStop;

  /// Attachments currently pinned to the conversation, if any.
  final DocumentAttachment? document;
  final ImageAttachment? image;

  /// Whether the loaded model has an image encoder. The camera button is shown
  /// either way — hiding it would leave someone hunting for a feature the app
  /// does have — but it explains itself when tapped without one.
  final bool visionReady;

  /// Whether the next message is looked up on the web before it is answered.
  final bool webSearch;
  final VoidCallback onToggleWebSearch;

  final VoidCallback onAttachDocument;
  final VoidCallback onAttachImage;

  /// Takes a photo now, rather than choosing one already on the phone.
  final VoidCallback onAttachCamera;

  final VoidCallback onRemoveDocument;
  final VoidCallback onRemoveImage;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.editing,
    required this.onCancelEdit,
    required this.enabled,
    required this.generating,
    required this.onSubmit,
    required this.onStop,
    required this.document,
    required this.image,
    required this.visionReady,
    required this.webSearch,
    required this.onToggleWebSearch,
    required this.onAttachDocument,
    required this.onAttachImage,
    required this.onAttachCamera,
    required this.onRemoveDocument,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.xs,
          Space.md,
          Space.md,
        ),
        child: Container(
          key: CoachMarkTargets.chatComposer,
          decoration: BoxDecoration(
            color: AppColors.of(context).card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05,
                ),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (editing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 0, 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          'Editing your question',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cancel editing',
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        color: scheme.onSurfaceVariant,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: onCancelEdit,
                      ),
                    ],
                  ),
                ),
              if (document != null || image != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                  child: Row(
                    children: [
                      if (image != null)
                        _AttachmentChip(
                          icon: Icons.image_outlined,
                          label: image!.name,
                          detail: image!.sizeLabel,
                          thumbnail: image!.bytes,
                          onRemove: onRemoveImage,
                        ),
                      if (image != null && document != null)
                        const SizedBox(width: Space.sm),
                      if (document != null)
                        _AttachmentChip(
                          icon: Icons.description_outlined,
                          label: document!.name,
                          detail: document!.truncated
                              ? '${document!.sizeLabel} · trimmed'
                              : document!.sizeLabel,
                          onRemove: onRemoveDocument,
                        ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // One control for everything a message can carry.
                  _ComposerSpeedDial(
                    enabled: enabled,
                    visionReady: visionReady,
                    webSearch: webSearch,
                    onCamera: onAttachCamera,
                    onImage: onAttachImage,
                    onDocument: onAttachDocument,
                    onToggleWebSearch: onToggleWebSearch,
                  ),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      minLines: 1,
                      maxLines: 6,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onSubmit(),
                      style: theme.textTheme.bodyLarge,
                      decoration: bareInputDecoration(
                        hintText: generating
                            ? 'Generating…'
                            : enabled
                            ? 'Ask anything'
                            : 'Load a model to start',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  // Lights up only once there is something to send, so the
                  // button says what will happen before it is pressed.
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final canSend = enabled && value.text.trim().isNotEmpty;
                      return _SendButton(
                        generating: generating,
                        editing: editing,
                        canSend: canSend,
                        onSend: onSubmit,
                        onStop: onStop,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.generating,
    required this.canSend,
    required this.onSend,
    required this.onStop,
    this.editing = false,
  });

  final bool generating;

  /// Saving an edited question rather than sending a new one.
  final bool editing;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = generating || canSend;
    // Stop is drawn in ink rather than red: ending a reply is routine, and a
    // red button mid-sentence reads as something having gone wrong.
    final bg = generating
        ? scheme.onSurface
        : canSend
        ? scheme.primary
        : scheme.surfaceContainerHigh;
    final fg = generating
        ? scheme.surface
        : canSend
        ? scheme.onPrimary
        : scheme.onSurfaceVariant.withValues(alpha: 0.7);
    return AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.curve,
      width: kComposerButton,
      height: kComposerButton,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: kComposerIcon,
        tooltip: generating
            ? 'Stop'
            : editing
            ? 'Save and ask again'
            : 'Send',
        onPressed: generating ? onStop : (active ? onSend : null),
        icon: AnimatedSwitcher(
          duration: Motion.fast,
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            generating
                ? Icons.stop_rounded
                : editing
                ? Icons.check_rounded
                : Icons.arrow_upward_rounded,
            key: ValueKey((generating, editing)),
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatTurn msg;

  /// True while this is the reply currently being generated.
  final bool pending;

  /// True while the web search for this reply is still out. Said rather than
  /// animated over: several seconds of typing dots for something that is not
  /// yet typing looks like the model has stalled.
  final bool searching;

  /// The newest question or the newest reply: the ones that carry their
  /// actions on screen rather than only behind a long press.
  final bool latest;

  /// A reply is streaming somewhere in the chat, so nothing that changes the
  /// thread can run.
  final bool busy;

  /// This question is the one being rewritten in the composer.
  final bool editing;

  /// Follow-up questions for this reply are being written.
  final bool suggesting;

  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final ValueChanged<int> onSwitchVersion;
  final VoidCallback onRegenerate;
  final VoidCallback onShare;
  final ValueChanged<String> onFollowUp;

  const _MessageBubble({
    required this.msg,
    required this.onLongPress,
    required this.onEdit,
    required this.onSwitchVersion,
    required this.onRegenerate,
    required this.onShare,
    required this.onFollowUp,
    this.pending = false,
    this.searching = false,
    this.latest = false,
    this.busy = false,
    this.editing = false,
    this.suggesting = false,
  });

  /// Left inset of everything under an assistant reply: the avatar's width
  /// plus the gap after it, so the actions line up with the reply they belong
  /// to rather than with the avatar.
  static const double _gutter = 36;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final app = AppColors.of(context);
    final isUser = msg.role == 'user';

    if (isUser) {
      // The user's own words sit in a quiet bubble on the right; the model's
      // reply is the page itself. Long answers read like a document instead
      // of a column of speech balloons.
      final versions = msg.versionCount;
      return Padding(
        padding: const EdgeInsets.only(top: Space.md, bottom: Space.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 48),
                Flexible(
                  child: GestureDetector(
                    onLongPress: onLongPress,
                    child: AnimatedContainer(
                      duration: Motion.fast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: editing
                            ? scheme.primaryContainer
                            : app.userBubble,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(Radii.xl),
                          topRight: Radius.circular(Radii.xl),
                          bottomLeft: Radius.circular(Radii.xl),
                          bottomRight: Radius.circular(Radii.xs),
                        ),
                        border: editing
                            ? Border.all(
                                color: scheme.primary.withValues(alpha: 0.5),
                              )
                            : null,
                      ),
                      child: Text(
                        msg.content,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: editing
                              ? scheme.onPrimaryContainer
                              : app.onUserBubble,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (versions > 1 || (latest && !busy))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (latest && !busy)
                      _ActionIcon(
                        icon: Icons.edit_outlined,
                        tooltip: 'Edit question',
                        onTap: onEdit,
                      ),
                    if (versions > 1)
                      _VersionSwitcher(
                        index: msg.variantIndex,
                        count: versions,
                        enabled: !busy,
                        onChanged: onSwitchVersion,
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final Widget body = msg.content.isEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 7),
            child: searching
                ? _SearchingLine(color: scheme.onSurfaceVariant)
                : pending
                ? _TypingDots(color: scheme.onSurfaceVariant)
                : Text(
                    'Stopped',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          )
        // Model replies arrive as Markdown; a user's own message is whatever
        // they typed, so it stays literal. Not selectable inline: a long
        // press opens the message's actions, which include selecting text.
        : Padding(
            padding: const EdgeInsets.only(top: 2),
            child: MarkdownText(
              data: msg.content,
              selectable: false,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: scheme.onSurface,
              ),
              codeBackground: app.codeSurface,
              mutedColor: scheme.onSurfaceVariant,
            ),
          );

    final hasWords = msg.content.isNotEmpty;
    final done = hasWords && !pending;

    // The avatar belongs to the reply, so it sits in a row with it rather
    // than beside the whole block — otherwise a reply carrying sources leaves
    // it stranded at the bottom, level with the links instead of the reply.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: hasWords ? onLongPress : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 13,
                  backgroundColor: kBrandNavy,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: kBrandGold,
                  ),
                ),
                const SizedBox(width: _gutter - 26),
                Expanded(child: body),
              ],
            ),
          ),
          // Held back until the reply has words in it. Five links under an
          // empty bubble read as the answer itself, which is what a list of
          // headlines above three dots looked like.
          if (hasWords && (done || msg.sources.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(left: _gutter - 8, top: 2),
              child: Row(
                children: [
                  // Actions wait for the whole reply; copying or sharing half
                  // an answer mid-stream is never what was meant.
                  if (done) ...[
                    _ActionIcon(
                      icon: Icons.content_copy_rounded,
                      tooltip: 'Copy reply',
                      onTap: () => copyWithToast(
                        context,
                        msg.content,
                        message: 'Reply copied',
                      ),
                    ),
                    _ActionIcon(
                      icon: Icons.share_outlined,
                      tooltip: 'Share reply',
                      onTap: onShare,
                    ),
                    if (latest && !busy)
                      _ActionIcon(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Regenerate',
                        onTap: onRegenerate,
                      ),
                  ],
                  if (msg.sources.isNotEmpty) ...[
                    if (done) const SizedBox(width: Space.xs),
                    _SourcesPill(sources: msg.sources),
                  ],
                ],
              ),
            ),
          if (latest &&
              done &&
              !busy &&
              (suggesting || msg.followUps.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(left: _gutter, top: Space.md),
              child: _FollowUps(
                questions: msg.followUps,
                loading: suggesting && msg.followUps.isEmpty,
                onTap: onFollowUp,
              ),
            ),
        ],
      ),
    );
  }
}

/// A small icon button for the row under a message.
class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      iconSize: 17,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: Icon(icon),
      onPressed: onTap,
    );
  }
}

/// ‹ 2/3 › under a question that has been edited or re-asked: which version
/// of the conversation is on screen, and the way to the others.
class _VersionSwitcher extends StatelessWidget {
  const _VersionSwitcher({
    required this.index,
    required this.count,
    required this.enabled,
    required this.onChanged,
  });

  final int index;
  final int count;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous version',
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          color: scheme.onSurfaceVariant,
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: enabled && index > 0 ? () => onChanged(index - 1) : null,
        ),
        Text(
          '${index + 1}/$count',
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        IconButton(
          tooltip: 'Next version',
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          color: scheme.onSurfaceVariant,
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: enabled && index < count - 1
              ? () => onChanged(index + 1)
              : null,
        ),
      ],
    );
  }
}

/// Three questions worth asking next, each one tap from being sent.
class _FollowUps extends StatelessWidget {
  const _FollowUps({
    required this.questions,
    required this.loading,
    required this.onTap,
  });

  final List<String> questions;

  /// Shown as placeholders while the model writes them, so the space they
  /// will take is already there and the list does not jump in.
  final bool loading;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rows = loading
        ? [for (var i = 0; i < kFollowUpCount; i++) _FollowUpPlaceholder(i)]
        : [
            for (final q in questions)
              InkWell(
                onTap: () => onTap(q),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    11,
                    Space.sm,
                    11,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          q,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Icon(
                        Icons.north_east_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Space.xs, bottom: Space.sm),
          child: Row(
            children: [
              Icon(
                Icons.subdirectory_arrow_right_rounded,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                loading ? 'Thinking of follow-ups…' : 'Ask next',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          radius: Radii.md + 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FollowUpPlaceholder extends StatefulWidget {
  const _FollowUpPlaceholder(this.index);

  final int index;

  @override
  State<_FollowUpPlaceholder> createState() => _FollowUpPlaceholderState();
}

class _FollowUpPlaceholderState extends State<_FollowUpPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Staggered widths so three bars read as three different lines of text.
    const widths = [0.78, 0.62, 0.7];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: widths[widget.index % widths.length],
          child: FadeTransition(
            opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
            child: Container(
              height: 11,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(Radii.xs),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _MessageAction { copy, select, edit, regenerate, share, delete }

/// The long-press sheet: a short preview of the message, then what can be
/// done with it.
class _MessageActionsSheet extends StatelessWidget {
  const _MessageActionsSheet({
    required this.preview,
    required this.isUser,
    required this.canEdit,
    required this.canRegenerate,
    required this.canDelete,
  });

  final String preview;
  final bool isUser;
  final bool canEdit;
  final bool canRegenerate;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget item(
      _MessageAction action,
      IconData icon,
      String label, {
      bool danger = false,
    }) {
      final color = danger ? scheme.error : scheme.onSurface;
      return ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => Navigator.pop(context, action),
      );
    }

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xxl,
              0,
              Space.xxl,
              Space.md,
            ),
            child: Text(
              preview.replaceAll(RegExp(r'\s+'), ' ').trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: Space.xs),
          item(_MessageAction.copy, Icons.content_copy_rounded, 'Copy'),
          item(_MessageAction.select, Icons.text_fields_rounded, 'Select text'),
          if (canEdit)
            item(_MessageAction.edit, Icons.edit_outlined, 'Edit question'),
          if (canRegenerate)
            item(
              _MessageAction.regenerate,
              Icons.refresh_rounded,
              'Regenerate',
            ),
          item(_MessageAction.share, Icons.share_outlined, 'Share'),
          if (canDelete)
            item(
              _MessageAction.delete,
              Icons.delete_outline_rounded,
              'Delete',
              danger: true,
            ),
          const SizedBox(height: Space.sm),
        ],
      ),
    );
  }
}

/// The whole message as selectable text, for copying part of it.
class _SelectTextPage extends StatelessWidget {
  const _SelectTextPage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select text'),
        actions: [
          IconButton(
            tooltip: 'Copy all',
            icon: const Icon(Icons.content_copy_rounded),
            onPressed: () => copyWithToast(context, text, message: 'Copied'),
          ),
          const SizedBox(width: Space.xs),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.sm,
          Space.gutter,
          Space.xxxl,
        ),
        child: SelectableText(text, style: theme.textTheme.bodyLarge),
      ),
    );
  }
}

/// What the reply shows while the search is out.
class _SearchingLine extends StatelessWidget {
  const _SearchingLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.travel_explore_rounded, size: 15, color: color),
        const SizedBox(width: 7),
        Text(
          'Searching the web…',
          style: TextStyle(color: color, fontSize: 13.5),
        ),
        const SizedBox(width: Space.sm),
        _TypingDots(color: color),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_c.value - i * 0.2).clamp(0.0, 1.0);
            final wave = (1 - (t * 2 - 1).abs()).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -2.5 * wave),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.35 + 0.65 * wave),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Everything a message can carry, behind one button.
///
/// A speed dial rather than a row of controls: the composer is the most
/// crowded line in the app, and taking a photo, choosing one, attaching a
/// document and searching the web are all the same gesture as far as the user
/// is concerned — "add something to this message". Labelled items, because an
/// unlabelled tray of small glyphs is a quiz.
class _ComposerSpeedDial extends StatefulWidget {
  const _ComposerSpeedDial({
    required this.enabled,
    required this.visionReady,
    required this.webSearch,
    required this.onCamera,
    required this.onImage,
    required this.onDocument,
    required this.onToggleWebSearch,
  });

  /// Whether an attachment can be added right now. False while a reply is
  /// streaming and before a model is loaded — but the dial still opens, since
  /// web search is a setting for the *next* message and there is no reason to
  /// make someone wait to change it.
  final bool enabled;

  /// Whether the loaded model has an image encoder. The camera and the gallery
  /// are shown either way — hiding them would leave someone hunting for a
  /// feature the app does have — but they say so before the picker opens.
  final bool visionReady;

  final bool webSearch;
  final VoidCallback onCamera;
  final VoidCallback onImage;
  final VoidCallback onDocument;
  final VoidCallback onToggleWebSearch;

  @override
  State<_ComposerSpeedDial> createState() => _ComposerSpeedDialState();
}

class _ComposerSpeedDialState extends State<_ComposerSpeedDial>
    with SingleTickerProviderStateMixin {
  /// Ties the items to the button, so they stay put when the keyboard opens
  /// and pushes the composer up the screen.
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  /// Built here rather than lazily: a dial that was never opened would
  /// otherwise have its controller created by [dispose] reaching for it, which
  /// looks up a ticker through an element that is already on its way out.
  late final AnimationController _anim;

  bool get _open => _portal.isShowing;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 130),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _close();
      return;
    }
    // Nothing here types, and a keyboard covering the items it is not needed
    // for is the most common speed-dial annoyance.
    FocusScope.of(context).unfocus();
    setState(_portal.show);
    _anim.forward();
  }

  Future<void> _close() async {
    if (!_open) return;
    await _anim.reverse();
    if (!mounted) return;
    setState(_portal.hide);
  }

  /// Closes the dial, then does the thing. In that order: a file picker or a
  /// dialog opening over a menu that is still on screen looks like two things
  /// happened.
  void _choose(VoidCallback action) {
    _close();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lit = _open;
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: FadeTransition(
                opacity: _anim,
                child: ColoredBox(color: scheme.scrim.withValues(alpha: 0.28)),
              ),
            ),
          ),
          // The child sizes to its content, which is what lets the follower
          // anchor its bottom-left to the button: given loose constraints it
          // would fill the overlay instead, and hang the whole stack off the
          // top of the screen.
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(-6, -14),
            child: _items(scheme),
          ),
        ],
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: SizedBox(
          width: kComposerButton,
          height: kComposerButton,
          child: IconButton(
            onPressed: _toggle,
            iconSize: kComposerIcon + 1,
            padding: EdgeInsets.zero,
            tooltip: _open ? 'Close' : 'Add to this message',
            style: IconButton.styleFrom(
              backgroundColor: lit
                  ? scheme.primaryContainer
                  : Colors.transparent,
              foregroundColor: lit
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            // The plus turns into a close as the items come out, so the same
            // button always undoes what it just did.
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedRotation(
                  turns: _open ? 0.125 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: const Icon(Icons.add_circle_outline_rounded),
                ),
                // Web search is a standing mode, not a pressed button: a dot
                // says it is on without lighting the whole control forever.
                if (widget.webSearch && !_open)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.of(context).card,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _items(ColorScheme scheme) {
    final entries = <Widget>[
      _DialItem(
        key: dialWebSearchKey,
        icon: Icons.travel_explore_rounded,
        label: 'Web search',
        detail: widget.webSearch ? 'Automatic, on when needed' : 'Off',
        active: widget.webSearch,
        onTap: () => _choose(widget.onToggleWebSearch),
      ),
      _DialItem(
        key: dialCameraKey,
        icon: Icons.photo_camera_outlined,
        label: 'Camera',
        detail: widget.visionReady
            ? 'Take a photo now'
            : 'Needs a vision model',
        enabled: widget.enabled,
        onTap: () => _choose(widget.onCamera),
      ),
      _DialItem(
        key: dialImageKey,
        icon: Icons.image_outlined,
        label: 'Image',
        detail: widget.visionReady ? 'PNG, JPEG, WebP' : 'Needs a vision model',
        enabled: widget.enabled,
        onTap: () => _choose(widget.onImage),
      ),
      _DialItem(
        key: dialDocumentKey,
        icon: Icons.description_outlined,
        label: 'Document',
        detail: 'Text, Markdown, CSV, code',
        enabled: widget.enabled,
        onTap: () => _choose(widget.onDocument),
      ),
    ];

    // Sized to the widest item, but never wider than a narrow phone can hold
    // beside the margin the dial hangs off.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < entries.length; i++)
              // Staggered from the bottom up, so the items read as coming out
              // of the button rather than appearing all at once.
              AnimatedBuilder(
                animation: _anim,
                builder: (context, child) {
                  final start = 0.08 * (entries.length - 1 - i);
                  final t = CurvedAnimation(
                    parent: _anim,
                    curve: Interval(start, 1, curve: Curves.easeOutBack),
                    reverseCurve: const Interval(0, 1, curve: Curves.easeIn),
                  ).value;
                  return Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 12),
                      child: Transform.scale(
                        scale: 0.94 + 0.06 * t.clamp(0.0, 1.0),
                        alignment: Alignment.bottomLeft,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: entries[i],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One row of the speed dial.
class _DialItem extends StatelessWidget {
  const _DialItem({
    super.key,
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.enabled = true,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool enabled;

  /// Drawn as switched on, for the one item that is a mode rather than an act.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = enabled ? scheme.onSurface : scheme.onSurfaceVariant;
    return Material(
      color: AppColors.of(context).card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(
          color: active
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outlineVariant,
        ),
      ),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(
                icon: icon,
                size: 34,
                background: active
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerLow,
                color: active ? scheme.onPrimaryContainer : fg,
              ),
              const SizedBox(width: Space.md),
              // Flexible, so a long second line ellipsises instead of pushing
              // the item off the side of a narrow phone.
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(color: fg),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: active ? scheme.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Colour for a source's badge, picked from the domain so the same site keeps
/// the same mark down a list and between replies.
Color _badgeColor(String seed, ColorScheme scheme) {
  const palette = [
    Color(0xFF3B5BDB),
    Color(0xFF0C8599),
    Color(0xFFD9480F),
    Color(0xFF862E9C),
    Color(0xFF2B8A3E),
    Color(0xFFC2255C),
  ];
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return palette[hash % palette.length];
}

/// The badge standing in for a site's favicon: its first letter, in its own
/// colour. Deliberately not the real icon — fetching one would mean a request
/// to every site in the list, from a phone that has only searched so far.
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source, this.size = 20});

  final WebResult source;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final domain = source.displayUrl;
    final letter = domain.isEmpty ? '?' : domain[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _badgeColor(domain, scheme),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.of(context).card, width: 1.5),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.5,
          height: 1,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// What a searched reply carries under it: a quiet row of site marks and the
/// word "Sources".
///
/// Collapsed by default. The full list is worth reading when someone doubts a
/// claim, and is clutter under every other answer — five headlines under a
/// two-line reply left the sources looking like the point of the message.
class _SourcesPill extends StatelessWidget {
  const _SourcesPill({required this.sources});

  final List<WebResult> sources;

  /// Marks shown in the collapsed row. Past three they stop being legible and
  /// start being a smudge.
  static const _stack = 3;

  void _openList(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SourcesSheet(sources: sources),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = sources.take(_stack).toList();
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openList(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Overlapped, the way a stack of cards reads as one thing.
              SizedBox(
                width: 20 + (shown.length - 1) * 12,
                height: 20,
                child: Stack(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      Positioned(
                        left: i * 12,
                        child: _SourceBadge(source: shown[i]),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              Text(
                sources.length == 1 ? 'Source' : 'Sources',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full list of what the answer was built from.
///
/// Site, headline, and the line the search returned — enough to judge a source
/// without leaving the app, and one tap to open it if that is not enough.
class _SourcesSheet extends StatelessWidget {
  const _SourcesSheet({required this.sources});

  final List<WebResult> sources;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xxl,
                0,
                Space.xxl,
                Space.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sources', style: theme.textTheme.titleLarge),
                  // What was actually sent. A follow-up is searched with words
                  // from the question before it, so when the sources look off
                  // this is the first thing worth reading. Older chats saved no
                  // query and simply show none.
                  if (sources.isNotEmpty && sources.first.query.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.xs),
                      child: Text(
                        'Searched: "${sources.first.query}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: Space.xs),
                itemCount: sources.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: Space.xxl,
                  endIndent: Space.xxl,
                  color: scheme.outlineVariant,
                ),
                itemBuilder: (context, i) {
                  final source = sources[i];
                  return InkWell(
                    onTap: () => _open(source.url),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Space.xxl,
                        14,
                        Space.xxl,
                        14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _SourceBadge(source: source, size: 18),
                              const SizedBox(width: Space.sm),
                              Expanded(
                                child: Text(
                                  source.displayUrl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              // The number the model was told to cite by, so a
                              // "[2]" in the answer has somewhere to land.
                              Tag('${i + 1}', dense: true),
                            ],
                          ),
                          const SizedBox(height: Space.sm),
                          Text(
                            source.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 15,
                            ),
                          ),
                          if (source.snippet.isNotEmpty) ...[
                            const SizedBox(height: Space.xs),
                            Text(
                              source.snippet,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A pinned attachment, with the affordance to unpin it.
class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onRemove,
    this.thumbnail,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onRemove;
  final Uint8List? thumbnail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final image = thumbnail;
    return Flexible(
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 2, 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.sm),
              child: SizedBox(
                width: 36,
                height: 36,
                child: image != null
                    ? Image.memory(
                        image,
                        fit: BoxFit.cover,
                        // A picture the model can read but the phone cannot
                        // decode for display is possible; show the icon rather
                        // than a broken box.
                        errorBuilder: (_, _, _) => Icon(icon, size: 18),
                      )
                    : ColoredBox(
                        color: scheme.primaryContainer,
                        child: Icon(
                          icon,
                          size: 18,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: Space.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
