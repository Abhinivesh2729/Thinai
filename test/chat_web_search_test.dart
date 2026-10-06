import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/chat_page.dart';
import 'package:local_llm/ui/widgets/markdown_text.dart';

/// A stored conversation whose reply came from a search, including two hits on
/// one site — the case a bare domain list cannot tell apart.
String _searchedChat({String answer = 'Claude Fable 5.1 is the newest [1].'}) =>
    jsonEncode({
  'activeId': 'a',
  'conversations': [
    {
      'id': 'a',
      'updatedAt': 1000,
      'turns': [
        {'role': 'user', 'content': 'latest anthropic model'},
        {
          'role': 'assistant',
          'content': answer,
          'sources': [
            {
              'title': 'Introducing Claude Fable 5.1',
              'url': 'https://www.anthropic.com/news/claude-fable-5-1',
              'snippet': 'Anthropic says it is up to 45 percent cheaper for '
                  'agentic work.',
            },
            {
              'title': 'Models overview',
              'url': 'https://www.anthropic.com/docs/models',
            },
          ],
        },
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
      child: const MaterialApp(home: ChatPage()),
    ),
  );
  // Let the controllers read their stored preferences.
  await tester.pump();
  await tester.pump();
  return container;
}

/// Opens the composer's speed dial, waiting out any snack bar sitting over the
/// button first.
Future<void> _openDial(WidgetTester tester) async {
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('one button carries everything a message can hold',
      (tester) async {
    // A narrow phone: the composer row is the most crowded in the app, and
    // what it offers must not squeeze the message field off screen.
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    await _pump(tester);

    // Closed, the composer is one button and the field.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(dialCameraKey), findsNothing);

    await _openDial(tester);
    expect(find.byKey(dialWebSearchKey), findsOneWidget);
    expect(find.byKey(dialCameraKey), findsOneWidget);
    expect(find.byKey(dialImageKey), findsOneWidget);
    expect(find.byKey(dialDocumentKey), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tapping away shuts it, which is the only way out that does not commit
    // to one of the four.
    await tester.tapAt(const Offset(180, 120));
    await tester.pumpAndSettle();
    expect(find.byKey(dialCameraKey), findsNothing);
  });

  testWidgets('web search is on without anyone being asked', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = await _pump(tester);

    // Nothing to opt into: a question that needs the web gets it, and the
    // only decision left is turning that off.
    expect(container.read(webSearchEnabledProvider), isTrue);

    await _openDial(tester);
    await tester.tap(find.byKey(dialWebSearchKey));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing,
        reason: 'no permission dialog, in either direction');
    expect(container.read(webSearchEnabledProvider), isFalse);

    await _openDial(tester);
    await tester.tap(find.byKey(dialWebSearchKey));
    await tester.pumpAndSettle();
    expect(container.read(webSearchEnabledProvider), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('web_search_enabled'), isTrue,
        reason: 'the choice survives a restart');
  });

  testWidgets('someone who switched it off stays switched off',
      (tester) async {
    SharedPreferences.setMockInitialValues({'web_search_enabled': false});
    final container = await _pump(tester);
    expect(container.read(webSearchEnabledProvider), isFalse);
  });

  testWidgets('sources sit under the reply, not level with the avatar',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'chat_sessions_v1': _searchedChat()});
    await _pump(tester);

    // The avatar belongs to the reply. Before, a reply carrying sources
    // dragged it to the bottom of the whole block, level with the links.
    final avatar = tester.getCenter(find.byType(CircleAvatar));
    final bubble = tester.getRect(find.byType(MarkdownText));
    expect(avatar.dy, greaterThanOrEqualTo(bubble.top));
    expect(avatar.dy, lessThanOrEqualTo(bubble.bottom));

    // Collapsed under the reply, the way it stays out of the way of an answer
    // that is only two lines long.
    expect(find.text('Sources'), findsOneWidget);
    expect(find.text('Introducing Claude Fable 5.1'), findsNothing);

    await tester.tap(find.text('Sources'));
    await tester.pumpAndSettle();

    // Opened, it says what each page was — two hits on one site have to be
    // told apart, and "anthropic.com" twice tells a reader nothing.
    expect(find.text('Introducing Claude Fable 5.1'), findsOneWidget);
    expect(find.text('Models overview'), findsOneWidget);
    expect(find.textContaining('cheaper for agentic work'), findsOneWidget);
    expect(find.text('anthropic.com'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a reply still being written shows no sources yet',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'chat_sessions_v1': _searchedChat(answer: ''),
    });
    await _pump(tester);
    // Five links under an empty bubble read as the answer itself.
    expect(find.text('Sources'), findsNothing);
  });

  testWidgets('an empty chat does not promise privacy the search would break',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'active_model_id': 'gemma3:4b',
      'web_search_enabled': true,
    });
    final container = await _pump(tester);
    // The banner copy keys off a loaded model, which this test has no engine
    // for, so drive the id directly.
    container.read(activeModelIdProvider.notifier).state = 'gemma3:4b';
    await tester.pump();

    expect(find.text('Your conversation runs entirely on-device.'),
        findsNothing);
    expect(find.textContaining('live results from the web'), findsOneWidget);
  });
}
