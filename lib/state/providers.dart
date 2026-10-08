import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../llm/generation_settings.dart';
import '../llm/gpu_support.dart';
import '../llm/llm_engine.dart';
import '../models_repo/benchmark_store.dart';
import '../models_repo/catalog.dart';
import '../models_repo/device_profile.dart';
import '../models_repo/downloader.dart';
import '../models_repo/recommender.dart';
import '../models_repo/importer.dart';
import '../models_repo/model_store.dart';
import '../server/api_server.dart';
import '../server/foreground_handler.dart';
import '../server/lan_address.dart';
import '../update/app_updater.dart';
import '../web/web_search.dart';

import 'dart:math';

final llmEngineProvider = Provider<LlmEngine>((ref) => LlmEngine.instance);
final modelStoreProvider = Provider<ModelStore>((ref) => ModelStore.instance);
final modelImporterProvider = Provider<ModelImporter>(
  (ref) => const ModelImporter(),
);
final modelDownloaderProvider = Provider<ModelDownloader>(
  (ref) => ModelDownloader(),
);

/// App self-update. Play holds the versions and the APK, so there is no
/// update server of ours behind this; see [AppUpdater].
final appUpdaterProvider = Provider<AppUpdater>((ref) => const AppUpdater());

/// The running build, as "2.2.0 (9)". Read from the platform rather than
/// pubspec so a `--build-name` override at build time still shows the truth.
final appVersionProvider = FutureProvider<String>(
  (ref) => AppUpdater.currentVersion(),
);

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// What this phone can run, for the model recommendations on the Models page.
///
/// Read once per session: RAM and core count do not change while the app is
/// open, and `MemAvailable` moving around under other apps would only make the
/// advice flicker.
final deviceProfileProvider = FutureProvider<DeviceProfile>(
  (ref) => DeviceProfile.read(),
);

final modelsRefreshProvider = StateProvider<int>((ref) => 0);

/// Set at startup when GPU acceleration crashed the previous launch and was
/// switched off, so Settings can say why the choice changed on its own.
final gpuCrashNoticeProvider = StateProvider<GpuBackend?>((ref) => null);

// Preference keys. Kept together so it is obvious what the app persists.
const _kActiveModelKey = 'active_model_id';
const _kServerRunningKey = 'server_was_running';
const _kServerPortKey = 'server_port';
const _kChatHistoryKey = 'chat_history_v1'; // superseded, migrated on load
const _kChatSessionsKey = 'chat_sessions_v1';
const _kWebSearchKey = 'web_search_enabled';

const _kServerBearerTokenKey = 'server_bearer_token';

// ─── theme ──────────────────────────────────────────────────────────────────

/// App theme mode, persisted across launches. Defaults to following the
/// system setting.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system) {
    _load();
  }

  static const _key = 'theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = switch (prefs.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(),
);

// ─── server LAN sharing ─────────────────────────────────────────────────────

/// Whether the server binds to the local network (true) or loopback only
/// (false). Persisted; defaults off so the API stays on-device unless the
/// user opts in.
class LanShareController extends StateNotifier<bool> {
  LanShareController() : super(false) {
    _load();
  }

  /// Also read at startup by [appBootstrapProvider], which cannot wait for
  /// this controller's own asynchronous load.
  static const lanShareKey = 'server_lan_share';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(lanShareKey) ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(lanShareKey, value);
  }
}

final lanShareProvider = StateNotifierProvider<LanShareController, bool>(
  (ref) => LanShareController(),
);

/// The device's current LAN IPv4 address, shown on the Server page regardless
/// of whether sharing is on. Recomputes whenever the server (re)starts, since
/// that is when the network/binding may have changed.
final deviceLanIpProvider = FutureProvider<String?>((ref) async {
  ref.watch(serverControllerProvider);
  return lanIpv4();
});

// ─── web search ─────────────────────────────────────────────────────────────

final webSearchProvider = Provider<WebSearch>((ref) => WebSearch());

/// Whether the Chat tab may look things up on the web before answering.
///
/// On by default, and automatic: the app decides per question whether one
/// needs the live web (see `needsWebSearch`), rather than asking the user to
/// predict what the model already knows — which is the one thing they cannot
/// know in advance. Only the question itself goes out, and only when it is
/// asked; the conversation and the model stay on the phone either way.
///
/// Still a flag, and still persisted, so anyone who wants the phone fully
/// offline can turn it off in Settings or from the composer and have that
/// stick.
class WebSearchController extends StateNotifier<bool> {
  WebSearchController() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Absent means never touched, which is the automatic default. Someone who
    // switched it off has `false` stored and keeps it.
    state = prefs.getBool(_kWebSearchKey) ?? true;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWebSearchKey, value);
  }
}

final webSearchEnabledProvider =
    StateNotifierProvider<WebSearchController, bool>(
      (ref) => WebSearchController(),
    );

// Bottom navigation index for the main shell: 0=Chat, 1=Models, 2=Server.
// Defaults to 0 (Chat).
final shellTabIndexProvider = StateProvider<int>((ref) => 0);

/// Controls which tab/screen opens when Thinai launches:
/// 0 = Chat (Default)
/// 1 = Models
/// 2 = Server
/// 3 = Settings
class StartPageController extends StateNotifier<int> {
  StartPageController() : super(0) {
    _load();
  }

  static const key = 'default_start_page';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(key) ?? 0;
    state = (saved >= 0 && saved <= 3) ? saved : 0;
  }

  Future<void> set(int index) async {
    if (index < 0 || index > 3) return;
    state = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, index);
  }
}

final startPageProvider = StateNotifierProvider<StartPageController, int>(
  (ref) => StartPageController(),
);

// Increment to request a fresh coach-mark walkthrough from anywhere in the UI.
final coachTourRequestProvider = StateProvider<int>((ref) => 0);

final modelListProvider = FutureProvider<List<LocalModel>>((ref) async {
  ref.watch(modelsRefreshProvider);
  return ref.watch(modelStoreProvider).list();
});

/// The model the Chat tab and the completion endpoints use, as its served id.
///
/// Owns the two side effects that must travel with it: pointing the engine at
/// the file, and persisting the choice so the next launch comes back with the
/// same model loaded. Nothing should set the id without those.
class ActiveModelController extends StateNotifier<String?> {
  ActiveModelController(this._engine, this._store) : super(null);

  final LlmEngine _engine;
  final ModelStore _store;

  Future<void> set(LocalModel? model) async {
    // Loading a vision model without pointing llama.cpp at its encoder gives
    // a model that cannot see and no indication why, so the lookup happens
    // here rather than being left to each caller.
    final projector = model == null ? null : await _projectorFor(model);
    _engine.setActiveModel(model?.path, projectorPath: projector);
    state = model?.id;
    final prefs = await SharedPreferences.getInstance();
    if (model == null) {
      await prefs.remove(_kActiveModelKey);
    } else {
      await prefs.setString(_kActiveModelKey, model.id);
    }
  }

  /// The downloaded image encoder for [model], if it is a catalogue vision
  /// model and the file is present.
  Future<String?> _projectorFor(LocalModel model) async {
    for (final entry in chatCatalog) {
      if (entry.servedId != model.id || !entry.supportsVision) continue;
      return _store.projectorPathFor(entry.mmprojFilename);
    }
    return null;
  }
}

final activeModelIdProvider =
    StateNotifierProvider<ActiveModelController, String?>(
      (ref) => ActiveModelController(
        ref.watch(llmEngineProvider),
        ref.watch(modelStoreProvider),
      ),
    );

/// Catalogue vision models whose weights are installed but whose image encoder
/// is not. These can be given sight with one extra download.
final missingProjectorsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(modelsRefreshProvider);
  final store = ref.watch(modelStoreProvider);
  final installed = await store.list();
  final installedIds = {for (final m in installed) m.id};

  final missing = <String>{};
  for (final entry in chatCatalog) {
    if (!entry.supportsVision) continue;
    if (!installedIds.contains(entry.servedId)) continue;
    if (await store.projectorPathFor(entry.mmprojFilename) == null) {
      missing.add(entry.id);
    }
  }
  return missing;
});

/// True when the loaded model can be shown an image: a vision model whose
/// encoder finished downloading.
final visionReadyProvider = Provider<bool>((ref) {
  ref.watch(activeModelIdProvider);
  return ref.watch(llmEngineProvider).visionReady;
});

// ─── benchmark results ──────────────────────────────────────────────────────

/// Measured decode rates, keyed by model id.
///
/// Held app-wide rather than on the Benchmark page because the Models page is
/// the main consumer: a measurement taken once turns every speed figure there
/// from a guess into something grounded.
class BenchmarkResultsController
    extends StateNotifier<Map<String, BenchmarkResult>> {
  BenchmarkResultsController(this._store) : super(const {}) {
    _load();
  }

  final BenchmarkStore _store;

  Future<void> _load() async {
    state = await _store.load();
  }

  Future<void> record(BenchmarkResult result) async {
    state = {...state, result.modelId: result};
    await _store.record(result);
  }

  Future<void> clear() async {
    state = const {};
    await _store.clear();
  }
}

final benchmarkStoreProvider = Provider<BenchmarkStore>(
  (ref) => const BenchmarkStore(),
);

final benchmarkResultsProvider = StateNotifierProvider<
    BenchmarkResultsController, Map<String, BenchmarkResult>>(
  (ref) => BenchmarkResultsController(ref.watch(benchmarkStoreProvider)),
);

/// Everything known about speed on this phone: the device class, plus whatever
/// the Benchmark page has actually measured.
final speedKnowledgeProvider = Provider<SpeedKnowledge>((ref) {
  final device = ref.watch(deviceProfileProvider).maybeWhen(
        data: (d) => d,
        orElse: () => DeviceProfile.unknownProfile,
      );
  return SpeedKnowledge(
    device: device,
    measurements: ref.watch(benchmarkResultsProvider),
  );
});

// ─── chat history ───────────────────────────────────────────────────────────

/// One message in a conversation. Only what is needed to redraw the thread
/// and rebuild the prompt: no timing, since the chat no longer shows any.
class ChatTurn {
  final String role;
  final String content;

  /// Web results this reply was answered from, when the search was on.
  ///
  /// Kept beside the message rather than inside it: they belong under the
  /// bubble as links the reader can check, and folding them into the text
  /// would read them back to the model as something it had said.
  final List<WebResult> sources;

  const ChatTurn({
    required this.role,
    required this.content,
    this.sources = const [],
  });

  ChatTurn withContent(String value) =>
      ChatTurn(role: role, content: value, sources: sources);

  ChatTurn withSources(List<WebResult> value) =>
      ChatTurn(role: role, content: content, sources: value);

  Map<String, Object?> toJson() => {
    'role': role,
    'content': content,
    if (sources.isNotEmpty)
      'sources': [for (final s in sources) s.toJson()],
  };

  static ChatTurn? fromJson(Object? value) {
    if (value is! Map) return null;
    final role = value['role'];
    final content = value['content'];
    if (role is! String || content is! String) return null;
    final sources = <WebResult>[];
    for (final entry in (value['sources'] as List? ?? const [])) {
      final source = WebResult.fromJson(entry);
      if (source != null) sources.add(source);
    }
    return ChatTurn(role: role, content: content, sources: sources);
  }
}

/// A saved conversation.
class ChatConversation {
  final String id;
  final List<ChatTurn> turns;
  final DateTime updatedAt;
  final String? customTitle;

  const ChatConversation({
    required this.id,
    required this.turns,
    required this.updatedAt,
    this.customTitle,
  });

  /// Derived from custom title if present, otherwise from the opening message.
  String get title {
    if (customTitle != null && customTitle!.trim().isNotEmpty) {
      return customTitle!.trim();
    }
    for (final turn in turns) {
      if (turn.role == 'user' && turn.content.trim().isNotEmpty) {
        final line = turn.content.trim().replaceAll(RegExp(r'\s+'), ' ');
        return line.length <= 48 ? line : '${line.substring(0, 47)}…';
      }
    }
    return 'New chat';
  }

  /// The last thing said, for the second line of a history row.
  String get preview {
    for (final turn in turns.reversed) {
      if (turn.content.trim().isEmpty) continue;
      final line = turn.content.trim().replaceAll(RegExp(r'\s+'), ' ');
      final prefix = turn.role == 'user' ? 'You: ' : '';
      final body = line.length <= 70 ? line : '${line.substring(0, 69)}…';
      return '$prefix$body';
    }
    return 'No messages yet';
  }

  bool get isEmpty => turns.isEmpty;

  ChatConversation copyWith({
    List<ChatTurn>? turns,
    DateTime? updatedAt,
    String? customTitle,
    bool clearCustomTitle = false,
  }) =>
      ChatConversation(
        id: id,
        turns: turns ?? this.turns,
        updatedAt: updatedAt ?? this.updatedAt,
        customTitle: clearCustomTitle ? null : (customTitle ?? this.customTitle),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'turns': [for (final t in turns) t.toJson()],
    if (customTitle != null && customTitle!.trim().isNotEmpty)
      'customTitle': customTitle!.trim(),
  };

  static ChatConversation? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    if (id is! String) return null;
    final turns = <ChatTurn>[];
    for (final entry in (value['turns'] as List? ?? const [])) {
      final turn = ChatTurn.fromJson(entry);
      if (turn != null) turns.add(turn);
    }
    final stamp = value['updatedAt'];
    final customTitle = value['customTitle'] as String?;
    return ChatConversation(
      id: id,
      turns: turns,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        stamp is int ? stamp : 0,
      ),
      customTitle: customTitle,
    );
  }
}

/// Every conversation plus which one the Chat tab is showing.
class ChatSessions {
  /// Most recently used first, which is the order the history list wants.
  final List<ChatConversation> conversations;

  /// Null means a fresh chat that has not been written to yet. Nothing is
  /// stored until the first message, so tapping "New chat" repeatedly cannot
  /// litter the history with empties.
  final String? activeId;

  /// False until the stored conversations have been read back.
  final bool loaded;

  const ChatSessions({
    this.conversations = const [],
    this.activeId,
    this.loaded = false,
  });

  ChatConversation? get active {
    for (final c in conversations) {
      if (c.id == activeId) return c;
    }
    return null;
  }

  List<ChatTurn> get activeTurns => active?.turns ?? const [];

  ChatSessions copyWith({
    List<ChatConversation>? conversations,
    String? activeId,
    bool clearActive = false,
    bool? loaded,
  }) => ChatSessions(
    conversations: conversations ?? this.conversations,
    activeId: clearActive ? null : (activeId ?? this.activeId),
    loaded: loaded ?? this.loaded,
  );
}

/// Owns the conversations and their persistence.
///
/// Writes happen when an exchange starts and when it ends, not per token: a
/// preference write per decoded token would be dozens of disk writes a second
/// for no gain. Losing a half-finished reply to a kill is the accepted cost.
class ChatSessionsController extends StateNotifier<ChatSessions> {
  ChatSessionsController() : super(const ChatSessions()) {
    _load();
  }

  /// Conversations kept. Old chats are cheap, but not free, and a phone
  /// preference file is the wrong place for an unbounded archive.
  static const _maxConversations = 40;

  /// Messages kept per conversation.
  static const _maxTurns = 200;

  /// Characters kept per conversation, counted from the newest message back.
  static const _maxChars = 120000;

  static const _uuid = Uuid();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    var conversations = <ChatConversation>[];
    String? activeId;

    final raw = prefs.getString(_kChatSessionsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final entry in (decoded['conversations'] as List? ?? const [])) {
            final conversation = ChatConversation.fromJson(entry);
            if (conversation != null && !conversation.isEmpty) {
              conversations.add(conversation);
            }
          }
          final stored = decoded['activeId'];
          if (stored is String) activeId = stored;
        }
      } catch (_) {
        // Corrupt or from an older shape: start clean rather than crash the
        // Chat tab on every launch.
        await prefs.remove(_kChatSessionsKey);
        conversations = [];
        activeId = null;
      }
    } else {
      // Single-thread storage from before conversations existed: carry it
      // over as the first chat instead of dropping the user's history.
      final legacy = prefs.getString(_kChatHistoryKey);
      if (legacy != null && legacy.isNotEmpty) {
        try {
          final decoded = jsonDecode(legacy);
          if (decoded is List) {
            final turns = <ChatTurn>[];
            for (final entry in decoded) {
              final turn = ChatTurn.fromJson(entry);
              if (turn != null) turns.add(turn);
            }
            if (turns.isNotEmpty) {
              final migrated = ChatConversation(
                id: _uuid.v4(),
                turns: turns,
                updatedAt: DateTime.now(),
              );
              conversations = [migrated];
              activeId = migrated.id;
            }
          }
        } catch (_) {
          // Nothing recoverable; fall through to an empty history.
        }
      }
      await prefs.remove(_kChatHistoryKey);
    }

    conversations = _tidy(conversations);
    // A reply cut off by the app being killed leaves an empty placeholder.
    // Drop it, keep the question.
    conversations = [
      for (final c in conversations) _dropTrailingPlaceholder(c),
    ]..removeWhere((c) => c.isEmpty);

    state = ChatSessions(
      conversations: conversations,
      activeId: conversations.any((c) => c.id == activeId) ? activeId : null,
      loaded: true,
    );
    if (raw != null || conversations.isNotEmpty) unawaited(_save());
  }

  /// Adds the user's message plus the placeholder the reply streams into,
  /// creating the conversation if this is a fresh chat.
  void startExchange(String text) {
    final now = DateTime.now();
    final current = state.active;
    final turns = [
      ...?current?.turns,
      ChatTurn(role: 'user', content: text),
      const ChatTurn(role: 'assistant', content: ''),
    ];
    final conversation = current == null
        ? ChatConversation(id: _uuid.v4(), turns: turns, updatedAt: now)
        : current.copyWith(turns: turns, updatedAt: now);
    _put(conversation, makeActive: true);
    unawaited(_save());
  }

  /// Records what the web search found for the reply now being written, so the
  /// sources stay with it in the history.
  void attachSources(List<WebResult> sources) {
    final current = state.active;
    if (current == null || current.turns.isEmpty) return;
    final turns = [...current.turns];
    turns[turns.length - 1] = turns.last.withSources(sources);
    _put(current.copyWith(turns: turns));
  }

  /// Replaces the streaming reply's text. Not persisted; [finishExchange]
  /// does that once.
  void updateLast(String content) {
    final current = state.active;
    if (current == null || current.turns.isEmpty) return;
    final turns = [...current.turns];
    turns[turns.length - 1] = turns.last.withContent(content);
    _put(current.copyWith(turns: turns));
  }

  Future<void> finishExchange() async {
    final current = state.active;
    if (current != null) {
      _put(current.copyWith(updatedAt: DateTime.now()));
    }
    await _save();
  }

  /// Leaves the current chat open in the list and starts a blank one. The new
  /// chat is not stored until it has a message.
  void startNewChat() {
    state = state.copyWith(clearActive: true);
    unawaited(_save());
  }

  void open(String id) {
    state = state.copyWith(activeId: id);
    unawaited(_save());
  }

  Future<void> rename(String id, String newTitle) async {
    final trimmed = newTitle.trim();
    final updated = [
      for (final c in state.conversations)
        if (c.id == id)
          c.copyWith(
            customTitle: trimmed.isEmpty ? null : trimmed,
            clearCustomTitle: trimmed.isEmpty,
          )
        else
          c,
    ];
    state = state.copyWith(conversations: updated);
    await _save();
  }

  Future<void> delete(String id) async {
    final remaining = [
      for (final c in state.conversations)
        if (c.id != id) c,
    ];
    state = ChatSessions(
      conversations: remaining,
      activeId: state.activeId == id ? null : state.activeId,
      loaded: true,
    );
    await _save();
  }

  /// Deletes multiple conversations in a single batch.
  Future<void> deleteMultiple(Set<String> ids) async {
    if (ids.isEmpty) return;
    final remaining = [
      for (final c in state.conversations)
        if (!ids.contains(c.id)) c,
    ];
    state = ChatSessions(
      conversations: remaining,
      activeId: ids.contains(state.activeId) ? null : state.activeId,
      loaded: true,
    );
    await _save();
  }

  /// Deletes the conversation on screen, if there is one.
  Future<void> deleteActive() async {
    final id = state.activeId;
    if (id == null) return;
    await delete(id);
  }

  Future<void> deleteAll() async {
    state = const ChatSessions(loaded: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kChatSessionsKey);
  }

  /// Inserts or replaces [conversation] and keeps the list newest-first.
  void _put(ChatConversation conversation, {bool makeActive = false}) {
    final others = [
      for (final c in state.conversations)
        if (c.id != conversation.id) c,
    ];
    final all = [conversation, ...others]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = ChatSessions(
      conversations: all,
      activeId: makeActive ? conversation.id : state.activeId,
      loaded: true,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final tidied = _tidy(state.conversations);
    // Keep the live list in step with what was written, so the history page
    // never lists a chat that would be gone after a restart.
    if (tidied.length != state.conversations.length) {
      state = state.copyWith(conversations: tidied);
    }
    await prefs.setString(
      _kChatSessionsKey,
      jsonEncode({
        'activeId': state.activeId,
        'conversations': [for (final c in tidied) c.toJson()],
      }),
    );
  }

  static ChatConversation _dropTrailingPlaceholder(ChatConversation c) {
    final turns = [...c.turns];
    while (turns.isNotEmpty && turns.last.content.isEmpty) {
      turns.removeLast();
    }
    return c.copyWith(turns: turns);
  }

  /// Applies every cap: newest conversations, newest messages within each.
  static List<ChatConversation> _tidy(List<ChatConversation> conversations) {
    final sorted = [...conversations]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final kept = sorted.take(_maxConversations);
    return [for (final c in kept) c.copyWith(turns: _trimTurns(c.turns))];
  }

  static List<ChatTurn> _trimTurns(List<ChatTurn> turns) {
    final kept = <ChatTurn>[];
    var chars = 0;
    for (var i = turns.length - 1; i >= 0; i--) {
      chars += turns[i].content.length;
      // Never trim to nothing: one reply longer than the whole budget should
      // still be the thing that comes back, not an empty screen.
      if (kept.isNotEmpty && (kept.length >= _maxTurns || chars > _maxChars)) {
        break;
      }
      kept.insert(0, turns[i]);
    }
    return kept;
  }
}

final chatSessionsProvider =
    StateNotifierProvider<ChatSessionsController, ChatSessions>(
      (ref) => ChatSessionsController(),
    );

// ─── downloads ──────────────────────────────────────────────────────────────

/// A finished download, surfaced so whichever screen is on top can report it.
class DownloadOutcome {
  final CatalogModel? catalogModel;
  final String label;
  final String? error;
  final LocalModel? installed;

  /// The user stopped it. Distinct from a failure: nothing went wrong, and
  /// telling them it "failed" reads as the app blaming them for their own
  /// decision.
  final bool cancelled;

  const DownloadOutcome({
    required this.label,
    this.catalogModel,
    this.error,
    this.installed,
    this.cancelled = false,
  });

  bool get ok => error == null && !cancelled;
}

/// In-flight catalog downloads, keyed by catalog model id.
///
/// Lives above the widget tree because two things need it: the Models page
/// (progress bars, cancel) and the first-run auto-download, which starts
/// before any page is built. Keeping it in page state would also drop the
/// handles whenever the page was rebuilt.
class DownloadsController extends StateNotifier<Map<String, DownloadHandle>> {
  DownloadsController(this._ref) : super(const {});

  final Ref _ref;
  final _outcomes = StreamController<DownloadOutcome>.broadcast();

  Stream<DownloadOutcome> get outcomes => _outcomes.stream;

  bool isDownloading(String catalogId) => state.containsKey(catalogId);

  /// Starts [model] downloading unless it is already in flight. Returns false
  /// when the download could not be started.
  Future<bool> start(CatalogModel model) async {
    if (state.containsKey(model.id)) return false;
    try {
      final handle = await _ref
          .read(modelDownloaderProvider)
          .start(
            model.url,
            filename: model.filename,
            displayName: model.displayName,
          );
      state = {...state, model.id: handle};
      handle.progress.listen((p) async {
        if (!p.done) return;
        state = {...state}..remove(model.id);
        _ref.read(modelsRefreshProvider.notifier).state++;
        if (p.cancelled) {
          _emit(
            DownloadOutcome(
              label: model.displayName,
              catalogModel: model,
              cancelled: true,
            ),
          );
          return;
        }
        if (p.error != null) {
          _emit(
            DownloadOutcome(
              label: model.displayName,
              catalogModel: model,
              error: p.error,
            ),
          );
          return;
        }
        // A vision model without its projector is a text model that looks
        // like it should see. Fetch the encoder before calling this done.
        if (model.supportsVision) {
          await _downloadProjector(model);
        }

        final installed = await _findDownloaded(model.id, handle.destPath);
        // Only chat models become the active model. Loading an embedding
        // model here would point the Chat tab at something that cannot
        // generate text; the embedding endpoints resolve their own model
        // per-request by name.
        if (installed != null && model.kind == ModelKind.chat) {
          await _ref.read(activeModelIdProvider.notifier).set(installed);
        }
        _emit(
          DownloadOutcome(
            label: model.displayName,
            catalogModel: model,
            installed: installed,
          ),
        );
      });
      return true;
    } catch (e) {
      _emit(
        DownloadOutcome(
          label: model.displayName,
          catalogModel: model,
          error: e.toString(),
        ),
      );
      return false;
    }
  }

  void cancel(String catalogId) => state[catalogId]?.cancel();

  /// Fetches the image encoder for a vision model whose weights are already
  /// installed.
  ///
  /// Needed because the encoder otherwise only arrives with the weights: a
  /// model downloaded before vision shipped would be stuck without one, told
  /// it cannot read images and given no way to fix that.
  Future<void> addVisionSupport(CatalogModel model) async {
    if (state.containsKey(model.id)) return;
    await _downloadProjector(model);
    _ref.read(modelsRefreshProvider.notifier).state++;

    // The engine holds the projector path from when the model was activated,
    // so re-activate to pick up the file that just landed.
    final active = _ref.read(activeModelIdProvider);
    if (active != null && active == model.servedId) {
      final installed = await _ref.read(modelStoreProvider).findById(active);
      if (installed != null) {
        await _ref.read(activeModelIdProvider.notifier).set(installed);
      }
    }
    _emit(
      DownloadOutcome(label: '${model.displayName} image encoder',
          catalogModel: model),
    );
  }

  /// Fetches [model]'s image encoder if it is not already on disk.
  ///
  /// Runs under the same catalog id as the model, so the Models page shows one
  /// continuous download rather than the progress bar vanishing and returning.
  /// A failure here is reported but does not fail the model: the weights are
  /// still usable for text.
  Future<void> _downloadProjector(CatalogModel model) async {
    final filename = model.mmprojFilename;
    final url = model.mmprojUrl;
    if (filename == null || url == null) return;

    final store = _ref.read(modelStoreProvider);
    if (await store.projectorPathFor(filename) != null) return;

    try {
      final handle = await _ref.read(modelDownloaderProvider).start(
            url,
            filename: filename,
            displayName: '${model.displayName} · image encoder',
          );
      state = {...state, model.id: handle};
      await for (final progress in handle.progress) {
        if (!progress.done) continue;
        if (progress.error != null && !progress.cancelled) {
          _emit(
            DownloadOutcome(
              label: '${model.displayName} image encoder',
              catalogModel: model,
              error: progress.error,
            ),
          );
        }
        break;
      }
    } catch (e) {
      _emit(
        DownloadOutcome(
          label: '${model.displayName} image encoder',
          catalogModel: model,
          error: e.toString(),
        ),
      );
    }
  }

  void _emit(DownloadOutcome outcome) {
    if (!_outcomes.isClosed) _outcomes.add(outcome);
  }

  Future<LocalModel?> _findDownloaded(String expectedId, String destPath) async {
    final store = _ref.read(modelStoreProvider);
    final byId = await store.findById(expectedId);
    if (byId != null) return byId;
    final all = await store.list();
    final segments = Uri.file(destPath).pathSegments;
    final destName = segments.isEmpty ? destPath : segments.last;
    final wanted = _normalizeModelKey(destName);
    for (final m in all) {
      if (m.path == destPath) return m;
      if (_normalizeModelKey(m.displayName) == wanted) return m;
    }
    return null;
  }

  @override
  void dispose() {
    _outcomes.close();
    super.dispose();
  }
}

final downloadsProvider =
    StateNotifierProvider<DownloadsController, Map<String, DownloadHandle>>(
      (ref) => DownloadsController(ref),
    );

String _normalizeModelKey(String input) {
  var key = input.trim().toLowerCase();
  if (key.endsWith('.gguf')) {
    key = key.substring(0, key.length - 5);
  }
  return key;
}


Future<String> _getOrCreateServerBearerToken() async {
  final prefs = await SharedPreferences.getInstance();

  final existing = prefs.getString(_kServerBearerTokenKey);
  if (existing != null && existing.isNotEmpty) {
    return existing;
  }

  final random = Random.secure();

  // 32 random bytes = 256 bits of entropy.
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));

  final token = base64UrlEncode(bytes);

  await prefs.setString(_kServerBearerTokenKey, token);

  return token;
}

/// Returns the current LAN API bearer token, if one has been created.
final serverBearerTokenProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kServerBearerTokenKey);
});

/// Generates a new LAN API bearer token.
///
/// The running server must be restarted by the UI after this operation so
/// that the new token becomes the active authentication credential.
Future<String> regenerateServerBearerToken() async {
  final prefs = await SharedPreferences.getInstance();

  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  final token = base64UrlEncode(bytes);

  await prefs.setString(_kServerBearerTokenKey, token);

  return token;
}

// ─── server ─────────────────────────────────────────────────────────────────

class ServerStatus {
  final bool running;
  final int port;

  /// Whether the running server is bound to the LAN (vs loopback only).
  final bool lan;

  /// The device's LAN IPv4 address when [lan] is on and one is available;
  /// null for loopback-only or when off-network.
  final String? lanIp;
  final String? error;

  const ServerStatus({
    required this.running,
    required this.port,
    this.lan = false,
    this.lanIp,
    this.error,
  });
}

class ServerController extends StateNotifier<ServerStatus> {
  final ApiServer _server;
  ServerController(this._server)
    : super(const ServerStatus(running: false, port: 11434));

  Future<void> start({required int port, bool lanMode = false}) async {
    try {
      String? bearerToken;

      if (lanMode) {
        bearerToken = await _getOrCreateServerBearerToken();
      }

      await _server.start(
        ApiServerConfig(
          port: port,
          lanMode: lanMode,
          bearerToken: bearerToken,
        ),
      );

      final ip = lanMode ? await lanIpv4() : null;

      state = ServerStatus(
        running: true,
        port: _server.port ?? port,
        lan: lanMode,
        lanIp: ip,
      );

      await _remember(
        running: true,
        port: state.port,
      );
    } catch (e) {
      state = ServerStatus(
        running: false,
        port: port,
        lan: lanMode,
        error: e.toString(),
      );

      await _remember(
        running: false,
        port: port,
      );
    }
  }

  Future<void> stop() async {
    await _server.stop();
    state = ServerStatus(running: false, port: state.port, lan: state.lan);
    await _remember(running: false, port: state.port);
  }

  /// Records whether the server should come back on the next launch.
  ///
  /// Swiping the app away tears down the Dart isolate, which takes the HTTP
  /// server with it. Persisting the intent is what lets the next launch put
  /// the Server page back into the state the user left it in.
  Future<void> _remember({required bool running, required int port}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kServerRunningKey, running);
    await prefs.setInt(_kServerPortKey, port);
  }
}

final apiServerProvider = Provider<ApiServer>((ref) {
  final server = ApiServer();
  ref.onDispose(() => server.stop());
  return server;
});

final serverControllerProvider =
    StateNotifierProvider<ServerController, ServerStatus>((ref) {
      return ServerController(ref.watch(apiServerProvider));
    });

/// The port to show in the Server page field: whatever was last used.
final savedServerPortProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_kServerPortKey) ?? 11434;
});

// ─── startup ────────────────────────────────────────────────────────────────

/// Restores session state at launch.
///
/// Runs once, behind the splash screen. Two jobs:
///  1. Reload the model that was active when the app was last closed.
///  2. Restart the HTTP server if it was running then, since swiping the app
///     away kills the isolate and stops it silently.
///
/// Deliberately does not fetch a model on a first run. Downloading hundreds
/// of megabytes on someone's mobile data before they have asked for anything
/// is not a decision the app gets to make; the tour points at the catalog
/// instead.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  // Concurrently load preferences, generation settings, GPU trial check, and installed models.
  final store = ref.read(modelStoreProvider);
  final initResults = await Future.wait([
    SharedPreferences.getInstance(),
    GenerationSettingsStore.instance.ensureLoaded(),
    takeCrashedGpuTrial(),
    store.list(),
  ]);

  final prefs = initResults[0] as SharedPreferences;
  final crashedGpu = initResults[2] as GpuBackend?;
  final installed = initResults[3] as List<LocalModel>;

  // A GPU attempt that never produced a token means the driver took the app
  // down last time. Switch GPU off before anything can load a model with it.
  if (crashedGpu != null) {
    await GenerationSettingsStore.instance.setGpu(GpuBackend.none);
    ref.read(gpuCrashNoticeProvider.notifier).state = crashedGpu;
    // This launch counts as the crash; one more failure rests the backend.
    LlmEngine.instance.gpuFailures.recordFailure(crashedGpu);
  }

  // 1. Active model.
  final savedId = prefs.getString(_kActiveModelKey);
  if (savedId != null) {
    LocalModel? match;
    for (final m in installed) {
      if (m.id == savedId) {
        match = m;
        break;
      }
    }
    // A missing file means the model was deleted from outside the app; drop
    // the stored id rather than pointing the engine at a dead path.
    await ref.read(activeModelIdProvider.notifier).set(match);
  }

  // 2. Default startup tab.
  final savedStart = prefs.getInt(StartPageController.key) ?? 0;
  final startPage = (savedStart >= 0 && savedStart <= 3) ? savedStart : 0;
  ref.read(shellTabIndexProvider.notifier).state = startPage;

  // 3. Server.
  //
  // Any service still running at this point is a leftover: reaching here
  // means a fresh isolate, and the HTTP server lived in the old one.
  // Resume in background so the UI shell displays immediately without
  // waiting for Android IPC service checks, socket binding, or LAN interface scans.
  unawaited(_resumeServerIfConfigured(ref, prefs));
});

Future<void> _resumeServerIfConfigured(Ref ref, SharedPreferences prefs) async {
  try {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    if (prefs.getBool(_kServerRunningKey) ?? false) {
      final port = prefs.getInt(_kServerPortKey) ?? 11434;
      // lanShareProvider loads its own preference asynchronously, so read the
      // stored value directly instead of racing it.
      final lan = prefs.getBool(LanShareController.lanShareKey) ?? false;
      await ref.read(serverControllerProvider.notifier).start(
        port: port,
        lanMode: lan,
      );
      final status = ref.read(serverControllerProvider);
      if (status.running) {
        await ForegroundServiceManager.serverStarted(
          port: status.port,
          lan: status.lan,
          ip: status.lanIp,
        );
      }
    }
  } catch (_) {
    // Background server recovery should never crash the app.
  }
}
