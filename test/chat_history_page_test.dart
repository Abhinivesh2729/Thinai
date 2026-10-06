import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/chat_history_page.dart';

String _sessions(List<(String, List<(String, String)>)> conversations,
        {String? activeId}) =>
    jsonEncode({
      'activeId': activeId,
      'conversations': [
        for (final c in conversations)
          {
            'id': c.$1,
            'updatedAt': 1000,
            'turns': [
              for (final t in c.$2) {'role': t.$1, 'content': t.$2},
            ],
          },
      ],
    });

Future<ProviderContainer> _pump(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ChatHistoryPage()),
    ),
  );
  // Let the controller read its stored conversations.
  await tester.pump();
  await tester.pump();
  return container;
}

void main() {
  testWidgets('lists saved chats by their opening question', (tester) async {
    SharedPreferences.setMockInitialValues({
      'chat_sessions_v1': _sessions([
        ('a', [('user', 'What is a GGUF?'), ('assistant', 'A file format')]),
        ('b', [('user', 'Explain embeddings')]),
      ], activeId: 'a'),
    });

    await _pump(tester);

    expect(find.text('What is a GGUF?'), findsOneWidget);
    expect(find.text('Explain embeddings'), findsOneWidget);
    // The reply is the preview line for the chat that has one.
    expect(find.text('A file format'), findsOneWidget);
    // The chat currently on the Chat tab is marked.
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('tapping a chat makes it the open one', (tester) async {
    SharedPreferences.setMockInitialValues({
      'chat_sessions_v1': _sessions([
        ('a', [('user', 'Alpha')]),
        ('b', [('user', 'Beta')]),
      ], activeId: 'a'),
    });

    final container = await _pump(tester);
    expect(container.read(chatSessionsProvider).activeId, 'a');

    await tester.tap(find.text('Beta'));
    await tester.pump();

    expect(container.read(chatSessionsProvider).activeId, 'b');
    expect(container.read(chatSessionsProvider).activeTurns.single.content,
        'Beta');
  });

  testWidgets('New chat clears the open conversation', (tester) async {
    SharedPreferences.setMockInitialValues({
      'chat_sessions_v1': _sessions([
        ('a', [('user', 'Alpha')]),
      ], activeId: 'a'),
    });

    final container = await _pump(tester);
    await tester.tap(find.text('New chat'));
    await tester.pump();

    final sessions = container.read(chatSessionsProvider);
    expect(sessions.activeId, isNull);
    expect(sessions.conversations, hasLength(1),
        reason: 'starting a new chat does not discard the old one');
  });

  testWidgets('deleting asks first, then removes the chat', (tester) async {
    SharedPreferences.setMockInitialValues({
      'chat_sessions_v1': _sessions([
        ('a', [('user', 'Alpha')]),
        ('b', [('user', 'Beta')]),
      ], activeId: 'a'),
    });

    final container = await _pump(tester);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Delete this chat?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(container.read(chatSessionsProvider).conversations, hasLength(1));
  });

  testWidgets('says so when there is nothing saved', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester);
    expect(find.text('No saved chats yet'), findsOneWidget);
    expect(find.byIcon(Icons.delete_sweep_rounded), findsNothing,
        reason: 'nothing to delete in bulk');
  });
}
