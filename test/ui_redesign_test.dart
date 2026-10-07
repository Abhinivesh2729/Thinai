import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/chat_history_page.dart';
import 'package:local_llm/ui/pages/chat_page.dart';
import 'package:local_llm/ui/pages/server_page.dart';
import 'package:local_llm/ui/theme/app_theme.dart';

Future<ProviderContainer> _pump(WidgetTester tester, Widget home) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildAppTheme(Brightness.light), home: home),
    ),
  );
  // Let the controllers read their stored preferences.
  await tester.pump();
  await tester.pump();
  return container;
}

String _chat({required String answer, int updatedAt = 1000}) => jsonEncode({
  'activeId': 'a',
  'conversations': [
    {
      'id': 'a',
      'updatedAt': updatedAt,
      'turns': [
        {'role': 'user', 'content': 'What is a GGUF?'},
        {'role': 'assistant', 'content': answer},
      ],
    },
  ],
});

void main() {
  group('curl examples', () {
    test('stay bare on loopback', () {
      expect(
        curlExample('http://127.0.0.1:11434', '/api/tags'),
        'curl http://127.0.0.1:11434/api/tags',
      );
    });

    test('carry the bearer token while sharing on the network', () {
      // The LAN server rejects every request without it, loopback included,
      // so an example missing the header would only ever answer 401.
      final curl = curlExample(
        'http://192.168.1.5:11434',
        '/v1/chat/completions',
        body: '{"model":"m"}',
        lan: true,
        json: true,
      );
      expect(
        curl,
        'curl http://192.168.1.5:11434/v1/chat/completions '
        r'-H "Authorization: Bearer $THINAI_TOKEN" '
        '-H "Content-Type: application/json" '
        "-d '{\"model\":\"m\"}'",
      );
    });
  });

  group('chat', () {
    testWidgets('a starter prompt fills the composer without sending it', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'web_search_enabled': false});
      final container = await _pump(tester, const ChatPage());
      // Starters are offered once a model is loaded; this test has no engine,
      // so the id is driven directly.
      container.read(activeModelIdProvider.notifier).state = 'gemma3:4b';
      await tester.pump();

      expect(find.text('What can I help with?'), findsOneWidget);
      await tester.tap(find.text('Explain'));
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(
        field.controller!.text,
        'Explain how on-device AI works, in simple terms.',
      );
      expect(
        container.read(chatSessionsProvider).activeTurns,
        isEmpty,
        reason: 'a suggestion is a sentence to start from, not a sent message',
      );
    });

    testWidgets('with no model, the empty chat leads to the Models tab', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final container = await _pump(tester, const ChatPage());
      container.read(shellTabIndexProvider.notifier).state = 0;

      expect(find.text('Ready when you are'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Choose a model'));
      await tester.pump();

      expect(container.read(shellTabIndexProvider), 1);
    });

    testWidgets('the header opens the model switcher', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pump(tester, const ChatPage());

      await tester.tap(find.text('No model loaded'));
      await tester.pumpAndSettle();

      expect(find.text('Model'), findsOneWidget);
      expect(find.text('Browse models'), findsOneWidget);
      expect(
        find.textContaining('No chat models on this phone'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a finished reply can be copied, an empty one cannot', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'chat_sessions_v1': _chat(answer: 'A file format for model weights.'),
      });
      await _pump(tester, const ChatPage());
      expect(find.byTooltip('Copy reply'), findsOneWidget);
    });

    testWidgets('a stopped reply offers nothing to copy', (tester) async {
      // Mid-conversation, because a trailing empty reply is trimmed on load.
      SharedPreferences.setMockInitialValues({
        'chat_sessions_v1': jsonEncode({
          'activeId': 'a',
          'conversations': [
            {
              'id': 'a',
              'updatedAt': 1000,
              'turns': [
                {'role': 'user', 'content': 'What is a GGUF?'},
                {'role': 'assistant', 'content': ''},
                {'role': 'user', 'content': 'Still there?'},
              ],
            },
          ],
        }),
      });
      await _pump(tester, const ChatPage());
      expect(find.text('Stopped'), findsOneWidget);
      expect(find.byTooltip('Copy reply'), findsNothing);
    });
  });

  group('history', () {
    testWidgets('groups conversations by when they happened', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'chat_sessions_v1': jsonEncode({
          'activeId': 'a',
          'conversations': [
            {
              'id': 'a',
              'updatedAt': now,
              'turns': [
                {'role': 'user', 'content': 'Fresh question'},
              ],
            },
            {
              'id': 'b',
              'updatedAt': 1000,
              'turns': [
                {'role': 'user', 'content': 'Ancient question'},
              ],
            },
          ],
        }),
      });
      await _pump(tester, const ChatHistoryPage());

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('OLDER'), findsOneWidget);
      final today = tester.getTopLeft(find.text('TODAY')).dy;
      final older = tester.getTopLeft(find.text('OLDER')).dy;
      final fresh = tester.getTopLeft(find.text('Fresh question')).dy;
      final ancient = tester.getTopLeft(find.text('Ancient question')).dy;
      expect(today, lessThan(fresh));
      expect(fresh, lessThan(older));
      expect(older, lessThan(ancient));
    });
  });
}
