import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/ui/pages/chat_history_page.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/web/web_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _legacyKey = 'chat_history_v1';
const _key = 'chat_sessions_v1';

String _encodeLegacy(List<(String, String)> turns) => jsonEncode([
  for (final t in turns) {'role': t.$1, 'content': t.$2},
]);

String _encodeSessions(
  List<(String, List<(String, String)>)> conversations, {
  String? activeId,
  int stamp = 1000,
}) => jsonEncode({
  'activeId': activeId,
  'conversations': [
    for (final c in conversations)
      {
        'id': c.$1,
        'updatedAt': stamp,
        'turns': [
          for (final t in c.$2) {'role': t.$1, 'content': t.$2},
        ],
      },
  ],
});

Future<ChatSessionsController> _controller() async {
  final c = ChatSessionsController();
  // The constructor reads preferences asynchronously.
  await pumpEventQueue();
  expect(c.state.loaded, isTrue);
  return c;
}

Future<Map<String, Object?>> _stored() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_key);
  if (raw == null) return {};
  return jsonDecode(raw) as Map<String, Object?>;
}

Future<List<Object?>> _storedConversations() async =>
    (await _stored())['conversations'] as List? ?? const [];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('loading', () {
    test('starts empty when nothing was stored', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _controller();
      expect(c.state.conversations, isEmpty);
      expect(c.state.activeId, isNull);
      expect(c.state.activeTurns, isEmpty);
    });

    test('restores conversations and reopens the last one', () async {
      SharedPreferences.setMockInitialValues({
        _key: _encodeSessions([
          ('a', [('user', 'Hi'), ('assistant', 'Hello!')]),
          ('b', [('user', 'Second')]),
        ], activeId: 'b'),
      });
      final c = await _controller();
      expect(c.state.conversations.length, 2);
      expect(c.state.activeId, 'b');
      expect(c.state.activeTurns.single.content, 'Second');
    });

    test('drops a reply cut off by the app being killed', () async {
      SharedPreferences.setMockInitialValues({
        _key: _encodeSessions([
          ('a', [('user', 'Hi'), ('assistant', '')]),
        ], activeId: 'a'),
      });
      final c = await _controller();
      expect(c.state.conversations.single.turns.length, 1);
      expect(c.state.conversations.single.turns.single.role, 'user');
    });

    test('an active id pointing at a deleted chat is ignored', () async {
      SharedPreferences.setMockInitialValues({
        _key: _encodeSessions([
          ('a', [('user', 'Hi')]),
        ], activeId: 'gone'),
      });
      final c = await _controller();
      expect(c.state.activeId, isNull);
    });

    test('survives a corrupt stored value', () async {
      SharedPreferences.setMockInitialValues({_key: 'not json at all'});
      final c = await _controller();
      expect(c.state.conversations, isEmpty);
    });

    test('carries over a thread saved before conversations existed', () async {
      SharedPreferences.setMockInitialValues({
        _legacyKey: _encodeLegacy([('user', 'Old chat'), ('assistant', 'Hi')]),
      });
      final c = await _controller();
      expect(c.state.conversations.length, 1);
      expect(c.state.activeTurns.first.content, 'Old chat');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(_legacyKey),
        isNull,
        reason: 'the old key is retired once migrated',
      );
      expect(await _storedConversations(), hasLength(1));
    });
  });

  group('conversations', () {
    test('the first message creates a conversation and saves it', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _controller();

      c.startExchange('What is a GGUF?');
      await pumpEventQueue();
      expect(c.state.conversations.length, 1);
      expect(c.state.activeTurns.map((t) => t.role), ['user', 'assistant']);
      expect(
        await _storedConversations(),
        hasLength(1),
        reason: 'the question is saved before the reply arrives',
      );

      c.updateLast('A file format');
      await c.finishExchange();
      expect(c.state.activeTurns.last.content, 'A file format');
    });

    test('a new chat leaves the old one in the list', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _controller();
      c.startExchange('First');
      c.updateLast('reply');
      await c.finishExchange();

      c.startNewChat();
      expect(c.state.activeId, isNull);
      expect(c.state.activeTurns, isEmpty);
      expect(c.state.conversations.length, 1, reason: 'the old chat is kept');

      c.startExchange('Second');
      await c.finishExchange();
      expect(c.state.conversations.length, 2);
    });

    test('an untouched new chat is never stored', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _controller();
      c.startNewChat();
      c.startNewChat();
      await pumpEventQueue();
      expect(await _storedConversations(), isEmpty);
    });

    test('the most recent conversation sorts first', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _controller();
      c.startExchange('First');
      await c.finishExchange();
      final first = c.state.activeId;

      c.startNewChat();
      c.startExchange('Second');
      await c.finishExchange();
      expect(c.state.conversations.first.id, isNot(first));

      // Reopening and adding to the older chat moves it back to the top.
      c.open(first!);
      c.startExchange('More');
      await c.finishExchange();
      expect(c.state.conversations.first.id, first);
    });

    test('opening switches which thread the chat shows', () async {
      SharedPreferences.setMockInitialValues({
        _key: _encodeSessions([
          ('a', [('user', 'Alpha')]),
          ('b', [('user', 'Beta')]),
        ], activeId: 'a'),
      });
      final c = await _controller();
      c.open('b');
      expect(c.state.activeTurns.single.content, 'Beta');
    });

    test('deleting the open chat clears the screen', () async {
      SharedPreferences.setMockInitialValues({
        _key: _encodeSessions([
          ('a', [('user', 'Alpha')]),
          ('b', [('user', 'Beta')]),
        ], activeId: 'a'),
      });
      final c = await _controller();
      await c.deleteActive();
      expect(c.state.activeId, isNull);
      expect(c.state.conversations.single.id, 'b');
      expect(await _storedConversations(), hasLength(1));
    });

    test('delete all wipes the stored copy too', () async {
      SharedPreferences.setMockInitialValues({
        _key: _encodeSessions([
          ('a', [('user', 'Alpha')]),
        ], activeId: 'a'),
      });
      final c = await _controller();
      await c.deleteAll();
      expect(c.state.conversations, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_key), isNull);
    });
  });

  group('web sources', () {
    test('stay with the reply they were fetched for', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _controller();

      c.startExchange('whats the news in tamil');
      c.attachSources(const [
        WebResult(
          title: 'Tamil Nadu news today',
          url: 'https://www.thehindu.com/news/tamil',
          snippet: 'not persisted',
        ),
      ]);
      c.updateLast('Rain warning for six districts [1].');
      await c.finishExchange();

      // On the reply, not the question: the links belong under the answer
      // they support.
      expect(c.state.activeTurns.first.sources, isEmpty);
      expect(c.state.activeTurns.last.sources, hasLength(1));
      expect(c.state.activeTurns.last.content, contains('[1]'));

      final stored = (await _storedConversations()).first as Map;
      final turns = stored['turns'] as List;
      expect((turns.last as Map)['sources'], hasLength(1));
    });

    test('come back when the conversation is reloaded', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await _controller();
      first.startExchange('news');
      first.attachSources(const [
        WebResult(title: 'Vikatan', url: 'https://www.vikatan.com/live'),
      ]);
      first.updateLast('Here is what happened.');
      await first.finishExchange();

      final reloaded = await _controller();
      final restored = reloaded.state.activeTurns.last.sources;
      expect(restored, hasLength(1));
      expect(restored.single.url, 'https://www.vikatan.com/live');
      expect(restored.single.displayUrl, 'vikatan.com');
    });

    test('a chat saved before the feature existed still loads', () async {
      SharedPreferences.setMockInitialValues({
        _key: _encodeSessions([
          ('a', [('user', 'hi'), ('assistant', 'hello')]),
        ], activeId: 'a'),
      });
      final c = await _controller();
      expect(c.state.activeTurns, hasLength(2));
      expect(c.state.activeTurns.last.sources, isEmpty);
    });
  });

  group('titles and previews', () {
    ChatConversation build(List<(String, String)> turns) => ChatConversation(
      id: 'x',
      updatedAt: DateTime(2026),
      turns: [for (final t in turns) ChatTurn(role: t.$1, content: t.$2)],
    );

    test('the title comes from the opening question', () {
      expect(
        build([('user', 'What is a GGUF?'), ('assistant', 'A format')]).title,
        'What is a GGUF?',
      );
    });

    test('a long title is cut short on one line', () {
      final title = build([('user', 'word ' * 40)]).title;
      expect(title.length, lessThanOrEqualTo(48));
      expect(title, endsWith('…'));
      expect(title, isNot(contains('\n')));
    });

    test('an empty conversation is named rather than left blank', () {
      expect(build([]).title, 'New chat');
      expect(build([]).preview, 'No messages yet');
    });

    test('the preview shows the last thing said, marking your own', () {
      expect(build([('user', 'Hi'), ('assistant', 'Hello')]).preview, 'Hello');
      expect(
        build([('assistant', 'Hello'), ('user', 'Hi')]).preview,
        'You: Hi',
      );
    });
  });

  group('caps', () {
    test('only the newest messages are kept in a long thread', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _controller();
      for (var i = 0; i < 120; i++) {
        c.startExchange('question $i');
        c.updateLast('answer $i');
      }
      await c.finishExchange();

      final saved = (await _storedConversations()).single as Map;
      final turns = saved['turns'] as List;
      expect(turns.length, lessThanOrEqualTo(200));
      expect((turns.last as Map)['content'], 'answer 119');
    });

    test('one reply bigger than the whole budget is still kept', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _controller();
      c.startExchange('q');
      c.updateLast('x' * 200000);
      await c.finishExchange();
      expect(await _storedConversations(), isNotEmpty);
    });

    test('the oldest conversations fall off the end', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await _controller();
      for (var i = 0; i < 50; i++) {
        c.startNewChat();
        c.startExchange('chat $i');
        c.updateLast('reply $i');
        await c.finishExchange();
      }
      expect((await _storedConversations()).length, lessThanOrEqualTo(40));
    });
  });

  group('timestamps', () {
    final now = DateTime(2026, 8, 21, 12, 0);
    String at(DateTime when) => formatChatTimestamp(when, now: now);

    test('reads as relative while that is useful', () {
      expect(at(now.subtract(const Duration(seconds: 20))), 'Just now');
      expect(at(now.subtract(const Duration(minutes: 5))), '5m ago');
      expect(at(now.subtract(const Duration(hours: 3))), '3h ago');
      expect(at(now.subtract(const Duration(days: 1))), 'Yesterday');
      expect(at(now.subtract(const Duration(days: 3))), '3 days ago');
    });

    test('falls back to a date once relative stops helping', () {
      expect(at(DateTime(2026, 8, 2)), '2 Aug');
      expect(at(DateTime(2025, 12, 30)), '30 Dec 2025');
    });
  });
}
