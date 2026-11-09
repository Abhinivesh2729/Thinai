/// Desktop chat history in SQLite: no conversation cap, and full-text search
/// over every message.
///
/// The phone keeps chats as one JSON blob in preferences, capped at 40. On a
/// PC people keep months of chats and expect to find an old answer by typing
/// a word from it, so the desktop build swaps the storage underneath the same
/// [ChatSessionsController] the UI already uses.
///
/// Layout:
/// * `conversations(id, updated_at, json)`: each conversation as the same
///   JSON the phone stores, so the formats never drift apart.
/// * `turns_fts`: an FTS5 index of every message's text, for search. Falls
///   back to LIKE when the bundled SQLite has no FTS5.
///
/// Writes are incremental: conversations are immutable values, so only the
/// ones that are not identical to what was last written get rewritten.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../state/providers.dart';
import '../diagnostics.dart';

class SqliteChatStore {
  SqliteChatStore._(this._db, this._fts);

  final Database _db;
  final bool _fts;

  static Future<SqliteChatStore> open({String? path}) async {
    final file = path ?? await defaultPath();
    await File(file).parent.create(recursive: true);
    final db = sqlite3.open(file);
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA synchronous = NORMAL;');
    db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        updated_at INTEGER NOT NULL,
        json TEXT NOT NULL
      );
    ''');
    var fts = true;
    try {
      db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS turns_fts
        USING fts5(content, conv_id UNINDEXED, tokenize = 'unicode61');
      ''');
    } on SqliteException catch (e) {
      fts = false;
      Diagnostics.log('chat store: FTS5 unavailable, using LIKE ($e)');
    }
    return SqliteChatStore._(db, fts);
  }

  static Future<String> defaultPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}${Platform.pathSeparator}chats.sqlite3';
  }

  List<ChatConversation> loadAll() {
    final rows = _db.select(
      'SELECT json FROM conversations ORDER BY updated_at DESC',
    );
    final out = <ChatConversation>[];
    for (final row in rows) {
      try {
        final c = ChatConversation.fromJson(jsonDecode(row['json'] as String));
        if (c != null) out.add(c);
      } on Object catch (e) {
        Diagnostics.log('chat store: skipped unreadable conversation ($e)');
      }
    }
    return out;
  }

  void upsert(ChatConversation c) {
    _db.execute('BEGIN');
    try {
      _db.execute(
        'INSERT INTO conversations(id, updated_at, json) VALUES (?, ?, ?) '
        'ON CONFLICT(id) DO UPDATE SET updated_at = excluded.updated_at, '
        'json = excluded.json',
        [c.id, c.updatedAt.millisecondsSinceEpoch, jsonEncode(c.toJson())],
      );
      if (_fts) {
        _db.execute('DELETE FROM turns_fts WHERE conv_id = ?', [c.id]);
        final insert = _db.prepare(
          'INSERT INTO turns_fts(content, conv_id) VALUES (?, ?)',
        );
        try {
          final title = c.customTitle;
          if (title != null && title.isNotEmpty) insert.execute([title, c.id]);
          for (final turn in c.turns) {
            if (turn.content.isNotEmpty) insert.execute([turn.content, c.id]);
          }
        } finally {
          insert.close();
        }
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void deleteIds(Iterable<String> ids) {
    _db.execute('BEGIN');
    try {
      for (final id in ids) {
        _db.execute('DELETE FROM conversations WHERE id = ?', [id]);
        if (_fts) _db.execute('DELETE FROM turns_fts WHERE conv_id = ?', [id]);
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void clear() {
    _db.execute('DELETE FROM conversations');
    if (_fts) _db.execute('DELETE FROM turns_fts');
  }

  /// Ids of conversations whose title or any message matches [query], best
  /// match first. Every word must appear (as a word prefix).
  List<String> search(String query, {int limit = 200}) {
    final words = query
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll('"', ''))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return const [];
    if (_fts) {
      final match = words.map((w) => '"$w"*').join(' AND ');
      try {
        final rows = _db.select(
          'SELECT conv_id, min(rank) AS r FROM turns_fts WHERE turns_fts '
          'MATCH ? GROUP BY conv_id ORDER BY r LIMIT ?',
          [match, limit],
        );
        return [for (final r in rows) r['conv_id'] as String];
      } on SqliteException {
        // Fall through to LIKE on odd input.
      }
    }
    final where = List.filled(words.length, 'json LIKE ?').join(' AND ');
    final rows = _db.select(
      'SELECT id FROM conversations WHERE $where ORDER BY updated_at DESC '
      'LIMIT ?',
      [for (final w in words) '%$w%', limit],
    );
    return [for (final r in rows) r['id'] as String];
  }

  void dispose() => _db.close();
}

/// [ChatSessionsController] backed by [SqliteChatStore]: same API and
/// behaviour, no cap, incremental writes.
class SqliteChatSessionsController extends ChatSessionsController {
  SqliteChatSessionsController(this._storeFuture);

  final Future<SqliteChatStore> _storeFuture;
  SqliteChatStore? _store;

  /// What was last written, by id. Conversations are immutable, so an
  /// identical instance needs no write.
  final Map<String, ChatConversation> _written = {};

  @override
  int? get maxConversations => null;

  Future<SqliteChatStore> get _ready async => _store ??= await _storeFuture;

  @override
  Future<void> load() async {
    try {
      final store = await _ready;
      final loaded = publishLoaded(store.loadAll());
      for (final c in loaded) {
        _written[c.id] = c;
      }
    } on Object catch (e, st) {
      Diagnostics.log('chat store: load failed: $e\n$st');
      publishLoaded(const []);
    }
  }

  @override
  Future<void> persist() async {
    final store = await _ready;
    final current = tidyForSave();
    final ids = <String>{};
    for (final c in current) {
      ids.add(c.id);
      if (identical(_written[c.id], c)) continue;
      try {
        store.upsert(c);
        _written[c.id] = c;
      } on Object catch (e) {
        Diagnostics.log('chat store: write failed for ${c.id}: $e');
      }
    }
    final gone = _written.keys.where((id) => !ids.contains(id)).toList();
    if (gone.isNotEmpty) {
      store.deleteIds(gone);
      gone.forEach(_written.remove);
    }
  }

  @override
  Future<void> clearStorage() async {
    (await _ready).clear();
    _written.clear();
  }

  /// Full-text search across every conversation; see [SqliteChatStore.search].
  Future<List<String>> search(String query) async =>
      (await _ready).search(query);
}
