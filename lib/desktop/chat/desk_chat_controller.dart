/// The desktop chat turn: send, stream, stop. Same behaviour as the phone's
/// chat screen (same prompt, search rules, trimming and storage), moved out of
/// the widget so the UI only draws state.
///
/// What differs on desktop:
/// * Streaming text reaches the transcript at most once per frame, however
///   fast tokens arrive. Without this every token rebuilt the conversation
///   list and the sidebar, which is where chat UIs start to stutter.
/// * Attachments clear after they are sent, instead of riding along with
///   every later message (mobile known issue C4).
/// * The last reply's speed is kept for the UI.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/document_attachment.dart';
import '../../chat/image_attachment.dart';
import '../../chat/prompt_budget.dart';
import '../../chat/prompt_builder.dart';
import '../../chat/system_prompt.dart';
import '../../llm/generation_settings.dart';
import '../../llm/llm_engine.dart';
import '../../state/providers.dart';
import '../../web/web_search.dart';
import '../diagnostics.dart';
import '../widgets/orb.dart';

/// Something the UI should tell the user. [kind] selects the wording; the UI
/// localises it.
class DeskNotice {
  const DeskNotice(this.kind, [this.detail = '']);
  final DeskNoticeKind kind;
  final String detail;
}

enum DeskNoticeKind {
  loadModelFirst,
  modelMissing,
  engineError,
  searchBlocked,
  searchNoResults,
  searchFailed,
  searchError,
  documentTrimmed,
  attachmentRefused,
  noVision,
}

class DeskChatState {
  const DeskChatState({
    this.generating = false,
    this.searching = false,
    this.document,
    this.image,
    this.lastStats,
  });

  final bool generating;
  final bool searching;
  final DocumentAttachment? document;
  final ImageAttachment? image;

  /// Speed of the most recent reply, for the status line under it.
  final LlmStats? lastStats;

  DeskChatState copyWith({
    bool? generating,
    bool? searching,
    DocumentAttachment? document,
    bool clearDocument = false,
    ImageAttachment? image,
    bool clearImage = false,
    LlmStats? lastStats,
  }) => DeskChatState(
    generating: generating ?? this.generating,
    searching: searching ?? this.searching,
    document: clearDocument ? null : (document ?? this.document),
    image: clearImage ? null : (image ?? this.image),
    lastStats: lastStats ?? this.lastStats,
  );
}

/// Shared orb, so the chat, the rail and the title bar all show one mood.
final deskOrbProvider = Provider<OrbController>((ref) {
  final orb = OrbController();
  ref.onDispose(orb.dispose);
  return orb;
});

final deskChatProvider =
    StateNotifierProvider<DeskChatController, DeskChatState>(
      (ref) => DeskChatController(ref),
    );

class DeskChatController extends StateNotifier<DeskChatState> {
  DeskChatController(this._ref) : super(const DeskChatState());

  final Ref _ref;
  final _notices = StreamController<DeskNotice>.broadcast();

  /// Messages for the toast layer.
  Stream<DeskNotice> get notices => _notices.stream;

  StreamSubscription<LlmToken>? _reply;
  Completer<void>? _turnDone;
  CancelToken? _searchCancel;
  bool _abandonTurn = false;

  // Per-frame coalescing of streamed text.
  String? _pendingText;
  bool _flushScheduled = false;

  OrbController get _orb => _ref.read(deskOrbProvider);

  void _notify(DeskNoticeKind kind, [String detail = '']) {
    if (!_notices.isClosed) _notices.add(DeskNotice(kind, detail));
  }

  // ── attachments ───────────────────────────────────────────────────────────

  /// Attaches a text/code file. Returns false when it was refused.
  bool attachDocument(String name, Uint8List bytes) {
    try {
      final doc = readDocument(name, bytes);
      state = state.copyWith(document: doc);
      if (doc.truncated) _notify(DeskNoticeKind.documentTrimmed, doc.sizeLabel);
      return true;
    } on FormatException catch (e) {
      _notify(DeskNoticeKind.attachmentRefused, e.message);
      _lastRefusal = e;
      return false;
    }
  }

  /// The last refused attachment, so the UI can localise the reason.
  FormatException? _lastRefusal;
  FormatException? takeLastRefusal() {
    final e = _lastRefusal;
    _lastRefusal = null;
    return e;
  }

  /// Attaches an image for a vision model. Returns false when refused.
  bool attachImage(String name, Uint8List bytes) {
    if (!_ref.read(visionReadyProvider)) {
      _notify(DeskNoticeKind.noVision);
      return false;
    }
    try {
      state = state.copyWith(image: readImage(name, bytes));
      return true;
    } on FormatException catch (e) {
      _lastRefusal = e;
      _notify(DeskNoticeKind.attachmentRefused, e.message);
      return false;
    }
  }

  /// Routes a dropped or pasted file by its extension.
  bool attachAny(String name, Uint8List bytes) {
    final ext = extensionOf(name);
    if (kImageExtensions.contains(ext)) return attachImage(name, bytes);
    return attachDocument(name, bytes);
  }

  void removeDocument() => state = state.copyWith(clearDocument: true);
  void removeImage() => state = state.copyWith(clearImage: true);

  // ── turn ──────────────────────────────────────────────────────────────────

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.generating) return;

    final activeId = _ref.read(activeModelIdProvider);
    if (activeId == null) {
      _notify(DeskNoticeKind.loadModelFirst);
      return;
    }
    final model = await _ref.read(modelStoreProvider).findById(activeId);
    if (model == null) {
      _notify(DeskNoticeKind.modelMissing);
      return;
    }

    final history = _ref.read(chatSessionsProvider.notifier);
    final document = state.document;
    final image = state.image;
    final searchWeb =
        _ref.read(webSearchEnabledProvider) &&
        document == null &&
        image == null &&
        needsWebSearch(text);
    final priorTurns = _ref.read(chatSessionsProvider).activeTurns;

    history.startExchange(text);
    // Sent once, then gone: the next question is about whatever the user
    // attaches next, not this file again.
    state = DeskChatState(
      generating: true,
      searching: searchWeb,
      lastStats: state.lastStats,
    );
    _orb.mood = OrbMood.thinking;

    final search = searchWeb
        ? await _lookUp(text, history, priorTurns: priorTurns)
        : null;
    if (_abandonTurn) {
      _abandonTurn = false;
      history.attachSources(const []);
      await history.finishExchange();
      _endTurn();
      return;
    }
    state = state.copyWith(searching: false);

    final options = await GenerationSettingsStore.instance.optionsFor(model);
    final systemPrompt = await _ref
        .read(systemPromptProvider.notifier)
        .current();

    final prompt = buildChatPrompt(
      priorTurns,
      text,
      systemPrompt: systemPrompt,
      document: document,
      image: image,
      search: search,
    );

    final sw = Stopwatch()..start();
    Diagnostics.log(
      'chat: send to ${model.id} (ctx ${options.contextSize}, '
      'gpu ${options.gpuBackend.name}/${options.numGpuLayers})',
    );
    final done = Completer<void>();
    _turnDone = done;
    var first = true;
    _reply = _ref
        .read(llmEngineProvider)
        .chat(
          fitToContext(prompt, options.contextSize),
          modelPath: model.path,
          options: options,
        )
        .listen(
          (token) {
            if (token.isError) {
              Diagnostics.log('chat: engine error: ${token.full}');
              _notify(DeskNoticeKind.engineError, _briefly(token.full));
              _orb.mood = OrbMood.error;
              return;
            }
            if (first) {
              first = false;
              _orb.mood = OrbMood.speaking;
              Diagnostics.log(
                'chat: first token after ${sw.elapsedMilliseconds} ms',
              );
            }
            _orb.pulse();
            _queueText(token.full);
            if (token.done) {
              state = state.copyWith(lastStats: token.stats);
              final tps = token.stats.tokensPerSecond;
              Diagnostics.log(
                'chat: done, ${token.stats.tokens} tokens'
                '${tps == null ? '' : ', ${tps.toStringAsFixed(1)} tok/s'}',
              );
            }
          },
          onError: (Object e) {
            Diagnostics.log('chat: stream error: $e');
            _notify(DeskNoticeKind.engineError, '$e');
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (!done.isCompleted) done.complete();
          },
          cancelOnError: true,
        );

    await done.future;
    final reply = _reply;
    _reply = null;
    _turnDone = null;
    await reply?.cancel();
    _flushNow();
    await history.finishExchange();
    _endTurn();
  }

  void _endTurn() {
    if (!mounted) return;
    state = state.copyWith(generating: false, searching: false);
    if (_orb.mood != OrbMood.error) _orb.mood = OrbMood.idle;
    // An error glow fades back to idle on its own.
    if (_orb.mood == OrbMood.error) {
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (_orb.mood == OrbMood.error) _orb.mood = OrbMood.idle;
      });
    }
  }

  void stop() {
    if (!state.generating) return;
    if (state.searching) {
      _searchCancel?.cancel();
      _abandonTurn = true;
      state = state.copyWith(searching: false);
      return;
    }
    _ref.read(llmEngineProvider).cancelCurrent();
    final done = _turnDone;
    if (done != null && !done.isCompleted) done.complete();
  }

  void _queueText(String full) {
    _pendingText = full;
    if (_flushScheduled) return;
    _flushScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _flushScheduled = false;
      _flushNow();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _flushNow() {
    final text = _pendingText;
    if (text == null) return;
    _pendingText = null;
    _ref.read(chatSessionsProvider.notifier).updateLast(text);
  }

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
      final results = await _ref
          .read(webSearchProvider)
          .search(query, cancelToken: cancel);
      if (cancel.isCancelled) return null;
      if (results.isEmpty) {
        _notify(
          results.blocked
              ? DeskNoticeKind.searchBlocked
              : DeskNoticeKind.searchNoResults,
        );
        return null;
      }
      history.attachSources([
        for (final result in results.results) result.withQuery(results.query),
      ]);
      return results;
    } on WebSearchException catch (e) {
      _notify(DeskNoticeKind.searchError, e.message);
    } catch (_) {
      if (!cancel.isCancelled) _notify(DeskNoticeKind.searchFailed);
    } finally {
      if (identical(_searchCancel, cancel)) _searchCancel = null;
    }
    return null;
  }

  static String _briefly(String message) {
    final firstLine = message
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => message.trim());
    if (firstLine.length <= 160) return firstLine;
    return '${firstLine.substring(0, 157)}...';
  }

  @override
  void dispose() {
    _reply?.cancel();
    _notices.close();
    super.dispose();
  }
}
