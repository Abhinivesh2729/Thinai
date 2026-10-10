import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../chat/document_attachment.dart';
import '../../chat/image_attachment.dart';
import '../../chat/prompt_budget.dart';
import '../../llm/generation_settings.dart';
import '../../llm/llm_engine.dart';
import '../../state/providers.dart';
import '../../web/web_search.dart';
import '../widgets/chat_drawer.dart';
import '../widgets/coach_mark_targets.dart';
import '../widgets/markdown_text.dart';
import '../widgets/model_settings_sheet.dart';

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
    _searchCancel?.cancel();
    _input.dispose();
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

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _generating) return;
    final activeId = ref.read(activeModelIdProvider);
    if (activeId == null) {
      _toast('Load a model from the Models tab first.');
      return;
    }
    final model = await ref.read(modelStoreProvider).findById(activeId);
    if (model == null) {
      _toast('Active model is missing from disk.');
      return;
    }

    // Tactile pulse on send — makes the interaction feel physical.
    HapticFeedback.lightImpact();

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

    // Everything said so far, captured before the placeholder the reply will
    // stream into is added to the conversation.
    final priorTurns = ref.read(chatSessionsProvider).activeTurns;

    history.startExchange(text);
    _input.clear();
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
    if (!mounted) return;
    // Stop pressed while the search was still out: the turn ends here, leaving
    // the empty reply the same "Stopped" bubble a cancelled generation does.
    if (_abandonTurn) {
      _abandonTurn = false;
      setState(() {
        _generating = false;
        _searching = false;
      });
      // Sources under a reply that was never written would credit an answer
      // that does not exist.
      history.attachSources(const []);
      await history.finishExchange();
      return;
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
              _toast(_briefly(token.full), lasting: const Duration(seconds: 6));
              return;
            }
            history.updateLast(token.full);
            _stickToBottom();
          },
          onError: (Object e) {
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
    if (mounted) setState(() => _generating = false);
  }

  /// Ends the reply in flight. The engine is told to cancel, and the UI stops
  /// listening straight away instead of waiting for the native side to
  /// acknowledge, so the button is always immediate.
  void _stop() {
    if (!_generating) return;
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

  void _toast(String text, {Duration? lasting}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: lasting ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

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
      _revealLatest();
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Menu & Chats',
          onPressed: () {
            if (shellScaffoldKey.currentState != null) {
              shellScaffoldKey.currentState!.openDrawer();
            } else {
              Scaffold.maybeOf(context)?.openDrawer();
            }
          },
        ),
        title: Text(
          sessions.active?.title ?? 'Thinai',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
        actions: [
          _ModelSwitcherAction(activeId: activeId),
        ],
      ),
      body: Column(
        children: [
          if (activeId == null) const _NoModelWarningBanner(),
          Expanded(
            child: messages.isEmpty
                ? _EmptyChat(
                    activeId: activeId,
                    webSearch: ref.watch(webSearchEnabledProvider),
                    onSuggestion: (text) {
                      _input.text = text;
                      _input.selection = TextSelection.fromPosition(
                        TextPosition(offset: _input.text.length),
                      );
                    },
                  )
                : Stack(
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: _onScrollNotification,
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                          itemCount: messages.length,
                          itemBuilder: (context, i) => _MessageBubble(
                            msg: messages[i],
                            // Typing dots mean "the reply is on its way". Once
                            // the turn is over an empty bubble means the reply
                            // was stopped before it started, and animating
                            // forever would be a lie.
                            pending: _generating && i == messages.length - 1,
                            searching: _searching && i == messages.length - 1,
                          ),
                        ),
                      ),
                      // Offered only once the user has parked away from the
                      // newest message, which is exactly when the view has
                      // stopped following the stream.
                      Positioned(
                        right: 14,
                        bottom: 10,
                        child: IgnorePointer(
                          ignoring: _followTail,
                          child: AnimatedOpacity(
                            opacity: _followTail ? 0 : 1,
                            duration: const Duration(milliseconds: 150),
                            child: _JumpToLatest(onTap: _jumpToLatest),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          _Composer(
            controller: _input,
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

/// Red warning banner displayed at the top of the chat page when no local model
/// is loaded into memory or downloaded in the app.
class _NoModelWarningBanner extends ConsumerWidget {
  const _NoModelWarningBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final models = ref.watch(modelListProvider).valueOrNull ?? const [];
    final hasInstalled = models.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: scheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasInstalled
                  ? 'No model loaded — tap to select or browse.'
                  : 'No model downloaded — tap to download.',
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              ref.read(shellTabIndexProvider.notifier).state = 1;
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 32),
              backgroundColor: scheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              hasInstalled ? 'Select' : 'Download',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top-right AppBar action button to switch between installed models.
class _ModelSwitcherAction extends ConsumerWidget {
  final String? activeId;
  const _ModelSwitcherAction({required this.activeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    const logoGreen = Color(0xFF2CA048);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: activeId != null
                    ? logoGreen.withValues(alpha: 0.12)
                    : scheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                activeId != null ? Icons.memory_rounded : Icons.warning_amber_rounded,
                size: 20,
                color: activeId != null ? logoGreen : scheme.error,
              ),
            ),
            // Live status indicator dot
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: activeId != null ? logoGreen : scheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        tooltip: activeId != null
            ? 'Active model: $activeId (tap to switch)'
            : 'No model loaded (tap to choose)',
        onPressed: () => _showModelSwitchSheet(context, ref),
      ),
    );
  }
}

Future<void> _showModelSwitchSheet(BuildContext context, WidgetRef ref) async {
  HapticFeedback.lightImpact();
  final activeId = ref.read(activeModelIdProvider);
  final store = ref.read(modelStoreProvider);
  final installedModels = await store.list();
  if (!context.mounted) return;

  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final scheme = theme.colorScheme;
  const logoGreen = Color(0xFF2CA048);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (modalContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: logoGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.memory_rounded,
                      size: 20,
                      color: logoGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Switch Model',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          installedModels.isEmpty
                              ? 'No models installed'
                              : '${installedModels.length} installed on device',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(modalContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (installedModels.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.explore_outlined, size: 36, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'No models downloaded yet',
                        style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Download an open model from the catalogue to begin chatting.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Browse Models'),
                        style: FilledButton.styleFrom(
                          backgroundColor: logoGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.of(modalContext).pop();
                          ref.read(shellTabIndexProvider.notifier).state = 1;
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: installedModels.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final m = installedModels[index];
                      final isSelected = m.id == activeId;
                      return Material(
                        color: isSelected
                            ? logoGreen.withValues(alpha: isDark ? 0.16 : 0.08)
                            : scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            await ref.read(activeModelIdProvider.notifier).set(m);
                            if (modalContext.mounted) Navigator.of(modalContext).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? logoGreen : scheme.outlineVariant,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: isSelected ? logoGreen : scheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.displayName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                              : scheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${m.sizeFormatted} · ${m.id}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected) ...[
                                  IconButton(
                                    icon: const Icon(Icons.tune_rounded, size: 18),
                                    color: logoGreen,
                                    tooltip: 'Model Parameters',
                                    onPressed: () async {
                                      Navigator.of(modalContext).pop();
                                      await showModelSettingsSheet(context, m);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Download More Models'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                    side: BorderSide(color: scheme.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(modalContext).pop();
                    ref.read(shellTabIndexProvider.notifier).state = 1;
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Puts the user back on the newest message after they have scrolled away.
class _JumpToLatest extends StatelessWidget {
  final VoidCallback onTap;
  const _JumpToLatest({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
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

class _EmptyChat extends ConsumerWidget {
  final String? activeId;

  /// Whether questions will be looked up before they are answered.
  final bool webSearch;

  /// Callback when a quick starter chip is selected.
  final ValueChanged<String>? onSuggestion;

  const _EmptyChat({
    required this.activeId,
    this.webSearch = false,
    this.onSuggestion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const logoGreen = Color(0xFF2CA048);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // High-resolution removed-background logo (white text for dark, black text for light)
            Image.asset(
              isDark
                  ? 'assets/images/logo_dark.png'
                  : 'assets/images/logo_transparent.png',
              width: activeId == null ? 200 : 170,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(height: 14),
            if (activeId == null) ...[
              const Text(
                'Private Offline AI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chat privately with AI models that run 100% on your phone. '
                'No internet required, zero cloud tracking, and your data never leaves your device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Browse & Download Models'),
                style: FilledButton.styleFrom(
                  backgroundColor: logoGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  ref.read(shellTabIndexProvider.notifier).state = 1;
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: logoGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: logoGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: logoGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      webSearch ? 'AI Ready · Web Search On' : 'AI Ready · 100% Offline',
                      style: const TextStyle(
                        color: logoGreen,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Running privately on your phone silicon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 22),
              // Starter prompt suggestions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _StarterChip(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Brainstorm ideas',
                    onTap: () => onSuggestion?.call(
                      'Give me 5 creative ideas to build an on-device AI app',
                    ),
                  ),
                  _StarterChip(
                    icon: Icons.code_rounded,
                    label: 'Write Python code',
                    onTap: () => onSuggestion?.call(
                      'Write a Python script to sort and deduplicate a list of items',
                    ),
                  ),
                  _StarterChip(
                    icon: Icons.summarize_outlined,
                    label: 'Summarize text',
                    onTap: () => onSuggestion?.call(
                      'Summarize the key takeaways from the following:\n\n',
                    ),
                  ),
                  _StarterChip(
                    icon: Icons.speed_rounded,
                    label: 'Measure speed',
                    onTap: () => onSuggestion?.call(
                      'What is your generation speed on this phone?',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StarterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StarterChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: const Color(0xFF2CA048)),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
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
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (document != null || image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                      const SizedBox(width: 8),
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
                // One control for everything a message can carry. It rides 4pt off
                // the bottom so its centre lines up with the text on a one-line
                // field, while still travelling down as the field grows to five.
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _ComposerSpeedDial(
                    enabled: enabled,
                    visionReady: visionReady,
                    webSearch: webSearch,
                    onCamera: onAttachCamera,
                    onImage: onAttachImage,
                    onDocument: onAttachDocument,
                    onToggleWebSearch: onToggleWebSearch,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    key: CoachMarkTargets.chatComposer,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: controller,
                      enabled: enabled,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSubmit(),
                      decoration: InputDecoration(
                        hintText: generating
                            ? 'Generating…'
                            : 'Message your model',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: generating
                        ? scheme.error
                        : (enabled
                              ? const Color(0xFF2CA048)
                              : scheme.surfaceContainerHigh),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 22,
                    tooltip: generating ? 'Stop' : 'Send',
                    onPressed: generating
                        ? onStop
                        : (enabled ? onSubmit : null),
                    icon: Icon(
                      generating
                          ? Icons.stop_rounded
                          : Icons.arrow_upward_rounded,
                      color: generating
                          ? Colors.white
                          : (enabled ? Colors.white : scheme.onSurfaceVariant),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
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

  const _MessageBubble({
    required this.msg,
    this.pending = false,
    this.searching = false,
  });


  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareText(BuildContext context, String text) {
    HapticFeedback.lightImpact();
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _showUserOptions(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.copy_rounded, size: 20),
                title: const Text(
                  'Copy text',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _copyText(context, msg.content);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, size: 20),
                title: const Text(
                  'Share text',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _shareText(context, msg.content);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = msg.role == 'user';

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4, right: 14, left: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: GestureDetector(
                onLongPress: () => _showUserOptions(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262C38) : const Color(0xFFE9ECEF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SelectableText(
                    msg.content,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.45,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant Reply: Pure ChatGPT style — borderless, seamless, full width markdown
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: msg.content.isEmpty
                ? (searching
                      ? _SearchingLine(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        )
                      : pending
                      ? _TypingDots(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        )
                      : Text(
                          'Stopped',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ))
                : MarkdownText(
                    data: msg.content,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF0F172A),
                      height: 1.55,
                      fontSize: 15.0,
                    ),
                    codeBackground: isDark
                        ? const Color(0xFF1E2638)
                        : const Color(0xFFE2E8F0),
                    mutedColor: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    streamingCursor: pending,
                    cursorColor: const Color(0xFF2CA048),
                  ),
          ),
          // Action row: Minimalist icon buttons like ChatGPT
          if (msg.content.isNotEmpty && !pending)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, right: 16),
              child: Row(
                children: [
                  _BubbleIconButton(
                    icon: Icons.copy_rounded,
                    tooltip: 'Copy',
                    onTap: () => _copyText(context, msg.content),
                  ),
                  const SizedBox(width: 4),
                  _BubbleIconButton(
                    icon: Icons.share_rounded,
                    tooltip: 'Share',
                    onTap: () => _shareText(context, msg.content),
                  ),
                  if (msg.sources.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _SourcesPill(sources: msg.sources),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Minimalist icon button under assistant messages (ChatGPT style)
class _BubbleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _BubbleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 16),
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      splashRadius: 18,
      onPressed: onTap,
    );
  }
}

/// What the bubble shows while the search is out.
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
          style: TextStyle(color: color, fontSize: 13),
        ),
        const SizedBox(width: 8),
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
            final opacity = 0.3 + 0.7 * (1 - (t * 2 - 1).abs()).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: opacity),
                  shape: BoxShape.circle,
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
      duration: const Duration(milliseconds: 190),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const logoGreen = Color(0xFF2CA048);

    final buttonBg = _open
        ? (isDark ? const Color(0xFF2E3A4E) : const Color(0xFFE2E8F0))
        : (isDark ? const Color(0xFF202736) : const Color(0xFFF1F5F9));

    final buttonBorder = widget.webSearch
        ? logoGreen.withValues(alpha: 0.7)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));

    final iconColor = _open
        ? (isDark ? Colors.white : const Color(0xFF0F172A))
        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155));

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
                child: ColoredBox(color: scheme.scrim.withValues(alpha: 0.32)),
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
            offset: const Offset(0, -10),
            child: _items(scheme),
          ),
        ],
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: SizedBox(
          width: kComposerButton,
          height: kComposerButton,
          child: Material(
            color: buttonBg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: Container(
                width: kComposerButton,
                height: kComposerButton,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: buttonBorder,
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: AnimatedRotation(
                  turns: _open ? 0.125 : 0,
                  duration: const Duration(milliseconds: 190),
                  curve: Curves.easeOut,
                  child: Icon(
                    Icons.add_rounded,
                    size: 22,
                    color: iconColor,
                  ),
                ),
              ),
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
              // Staggered from the bottom up, so the items read as coming out of
              // the button rather than appearing all at once.
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
                        scale: 0.9 + 0.1 * t.clamp(0.0, 1.0),
                        alignment: Alignment.bottomLeft,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const logoGreen = Color(0xFF2CA048);

    final cardBg = isDark ? const Color(0xFF1E2636) : Colors.white;
    final borderColor = active
        ? logoGreen.withValues(alpha: 0.7)
        : (isDark ? const Color(0xFF2E384D) : const Color(0xFFE2E8F0));
    final fg = enabled ? scheme.onSurface : scheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: active ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: active
                          ? logoGreen.withValues(alpha: 0.15)
                          : (isDark ? const Color(0xFF283245) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 19,
                      color: active ? logoGreen : fg,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: active ? scheme.onSurface : fg,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: active
                                ? logoGreen
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: logoGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ON',
                        style: TextStyle(
                          color: logoGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
    Color(0xFF4C6EF5),
    Color(0xFF12B886),
    Color(0xFFE8590C),
    Color(0xFF9C36B5),
    Color(0xFF1098AD),
    Color(0xFFD6336C),
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
  const _SourceBadge({required this.source, this.size = 22});

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
        border: Border.all(color: scheme.surface, width: 1.5),
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
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _SourcesSheet(sources: sources),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = sources.take(_stack).toList();
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openList(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Overlapped, the way a stack of cards reads as one thing.
            SizedBox(
              width: 22 + (shown.length - 1) * 14,
              height: 22,
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(
                      left: i * 14,
                      child: _SourceBadge(source: shown[i]),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              sources.length == 1 ? 'Source' : 'Sources',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sources',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  // What was actually sent. A follow-up is searched with words
                  // from the question before it, so when the sources look off
                  // this is the first thing worth reading. Older chats saved no
                  // query and simply show none.
                  if (sources.isNotEmpty && sources.first.query.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Searched: "${sources.first.query}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: sources.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
                itemBuilder: (context, i) {
                  final source = sources[i];
                  return InkWell(
                    onTap: () => _open(source.url),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _SourceBadge(source: source, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  source.displayUrl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              // The number the model was told to cite by, so a
                              // "[2]" in the answer has somewhere to land.
                              Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            source.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (source.snippet.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              source.snippet,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                color: scheme.onSurfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;
    final image = thumbnail;
    return Flexible(
      child: Container(
        padding: EdgeInsets.fromLTRB(image == null ? 10 : 4, 4, 4, 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  image,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  // A picture the model can read but the phone cannot decode
                  // for display is possible; show the icon rather than a
                  // broken box.
                  errorBuilder: (_, _, _) => Icon(icon, size: 18),
                ),
              )
            else
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
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
