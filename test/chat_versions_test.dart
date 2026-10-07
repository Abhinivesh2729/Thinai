import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/state/providers.dart';

Future<ChatSessionsController> _controller([Map<String, Object>? prefs]) async {
  SharedPreferences.setMockInitialValues(prefs ?? {});
  final controller = ChatSessionsController();
  while (!controller.state.loaded) {
    await Future<void>.delayed(Duration.zero);
  }
  return controller;
}

/// Plays a question and its answer into the open chat.
void _exchange(ChatSessionsController c, String question, String answer) {
  c.startExchange(question);
  c.updateLast(answer);
}

List<String> _thread(ChatSessionsController c) => [
  for (final t in c.state.activeTurns) '${t.role[0]}:${t.content}',
];

void main() {
  test('editing a question keeps the old version and its answer', () async {
    final c = await _controller();
    _exchange(c, 'What is Ooty?', 'A hill station.');
    _exchange(c, 'How cold?', 'Quite cold.');

    c.forkAt(0, 'What is Erode?');
    c.updateLast('A city in Tamil Nadu.');

    expect(_thread(c), ['u:What is Erode?', 'a:A city in Tamil Nadu.']);
    final question = c.state.activeTurns.first;
    expect(question.versionCount, 2);
    expect(question.variantIndex, 1);

    c.switchVersion(0, 0);
    expect(_thread(c), [
      'u:What is Ooty?',
      'a:A hill station.',
      'u:How cold?',
      'a:Quite cold.',
    ], reason: 'the whole earlier thread comes back with its version');
    expect(c.state.activeTurns.first.variantIndex, 0);

    c.switchVersion(0, 1);
    expect(_thread(c), ['u:What is Erode?', 'a:A city in Tamil Nadu.']);
  });

  test('regenerating is a new version of the same question', () async {
    final c = await _controller();
    _exchange(c, 'Tell a joke', 'Joke one.');
    c.forkAt(0, 'Tell a joke');
    c.updateLast('Joke two.');

    expect(_thread(c), ['u:Tell a joke', 'a:Joke two.']);
    c.switchVersion(0, 0);
    expect(_thread(c), ['u:Tell a joke', 'a:Joke one.']);
  });

  test('versions nest: an edit inside an older version survives', () async {
    final c = await _controller();
    _exchange(c, 'A', 'a1');
    _exchange(c, 'B', 'b1');
    c.forkAt(2, 'B2');
    c.updateLast('b2');
    // Now fork the first question too; the B/B2 versions live in the tail.
    c.forkAt(0, 'A2');
    c.updateLast('a2');

    c.switchVersion(0, 0);
    expect(_thread(c), ['u:A', 'a:a1', 'u:B2', 'a:b2']);
    c.switchVersion(2, 0);
    expect(_thread(c), ['u:A', 'a:a1', 'u:B', 'a:b1']);
  });

  test('ignores switches and forks that make no sense', () async {
    final c = await _controller();
    _exchange(c, 'Q', 'A');
    final before = _thread(c);
    c.switchVersion(0, 3);
    c.switchVersion(9, 0);
    c.forkAt(1, 'not a question');
    c.forkAt(7, 'out of range');
    expect(_thread(c), before);
  });

  test('versions are saved and come back after a restart', () async {
    final c = await _controller();
    _exchange(c, 'Q1', 'first');
    c.forkAt(0, 'Q2');
    c.updateLast('second');
    await c.finishExchange();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('chat_sessions_v1')!;

    final restored = await _controller({'chat_sessions_v1': stored});
    expect(_thread(restored), ['u:Q2', 'a:second']);
    restored.switchVersion(0, 0);
    expect(_thread(restored), ['u:Q1', 'a:first']);
  });

  test('a malformed version list is dropped, the thread kept', () async {
    final c = await _controller({
      'chat_sessions_v1': jsonEncode({
        'activeId': 'a',
        'conversations': [
          {
            'id': 'a',
            'updatedAt': 1000,
            'turns': [
              {
                'role': 'user',
                'content': 'Q',
                'variants': [
                  [
                    {'role': 'user', 'content': 'old'},
                  ],
                ],
                'variantIndex': 5,
              },
              {'role': 'assistant', 'content': 'A'},
            ],
          },
        ],
      }),
    });
    expect(_thread(c), ['u:Q', 'a:A']);
    expect(c.state.activeTurns.first.versionCount, 1);
  });

  test('a fresh session opens a blank chat and keeps the old ones', () async {
    final c = await _controller({
      'chat_sessions_v1': jsonEncode({
        'activeId': 'a',
        'conversations': [
          {
            'id': 'a',
            'updatedAt': 1000,
            'turns': [
              {'role': 'user', 'content': 'Old'},
              {'role': 'assistant', 'content': 'Kept'},
            ],
          },
        ],
      }),
    });
    await c.startFreshSession();
    expect(c.state.activeId, isNull);
    expect(c.state.activeTurns, isEmpty);
    expect(c.state.conversations, hasLength(1));
    expect(c.state.conversations.single.turns.last.content, 'Kept');
  });

  test('a fresh session waits for stored chats before clearing', () async {
    SharedPreferences.setMockInitialValues({
      'chat_sessions_v1': jsonEncode({
        'activeId': 'a',
        'conversations': [
          {
            'id': 'a',
            'updatedAt': 1000,
            'turns': [
              {'role': 'user', 'content': 'Old'},
            ],
          },
        ],
      }),
    });
    // Called straight away, before the stored chats have been read back: the
    // read must not land afterwards and reopen the old chat on top.
    final c = ChatSessionsController();
    await c.startFreshSession();
    expect(c.state.loaded, isTrue);
    expect(c.state.activeId, isNull);
    expect(c.state.conversations, hasLength(1));
  });

  group('deleteExchange', () {
    test('removes a question and its answer, keeping the rest', () async {
      final c = await _controller();
      _exchange(c, 'One', '1');
      _exchange(c, 'Two', '2');
      await c.deleteExchange(1); // the answer deletes with its question
      expect(_thread(c), ['u:Two', 'a:2']);
    });

    test('with versions, removes only the one on screen', () async {
      final c = await _controller();
      _exchange(c, 'Q', 'first');
      c.forkAt(0, 'Q');
      c.updateLast('second');
      await c.deleteExchange(0);
      expect(_thread(c), ['u:Q', 'a:first']);
      expect(c.state.activeTurns.first.versionCount, 1);
    });

    test('deleting the last exchange deletes the chat', () async {
      final c = await _controller();
      _exchange(c, 'Only', 'one');
      await c.deleteExchange(0);
      expect(c.state.conversations, isEmpty);
      expect(c.state.activeId, isNull);
    });
  });

  group('setFollowUps', () {
    test('pins suggestions under the reply they were written for', () async {
      final c = await _controller();
      _exchange(c, 'Q', 'Answer');
      final id = c.state.activeId!;
      await c.setFollowUps(id, 'Answer', ['Next one?', 'Another?']);
      expect(c.state.activeTurns.last.followUps, ['Next one?', 'Another?']);

      final prefs = await SharedPreferences.getInstance();
      final restored = await _controller({
        'chat_sessions_v1': prefs.getString('chat_sessions_v1')!,
      });
      expect(restored.state.activeTurns.last.followUps, [
        'Next one?',
        'Another?',
      ]);
    });

    test('drops suggestions that arrive after the reply moved on', () async {
      final c = await _controller();
      _exchange(c, 'Q', 'Answer');
      final id = c.state.activeId!;
      _exchange(c, 'Newer', 'Newer answer');
      await c.setFollowUps(id, 'Answer', ['Stale?']);
      expect(c.state.activeTurns.last.followUps, isEmpty);
      await c.setFollowUps('missing', 'Answer', ['Nope?']);
    });
  });
}
