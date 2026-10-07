import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/chat_page.dart';
import 'package:local_llm/ui/theme/app_theme.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester,
  List<Map<String, Object?>> turns,
) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'chat_sessions_v1': jsonEncode({
      'activeId': 'a',
      'conversations': [
        {'id': 'a', 'updatedAt': 1000, 'turns': turns},
      ],
    }),
  });
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const ChatPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

Map<String, Object?> _user(String text) => {'role': 'user', 'content': text};
Map<String, Object?> _bot(String text, {List<String>? followUps}) => {
  'role': 'assistant',
  'content': text,
  'followUps': ?followUps,
};

void main() {
  testWidgets('an edited question shows its versions and switches between '
      'them', (tester) async {
    await _pump(tester, [
      {
        ..._user('What is Erode known for?'),
        'variants': [
          [_user('What is Ooty known for?'), _bot('Tea gardens.')],
          <Object>[],
        ],
        'variantIndex': 1,
      },
      _bot('Turmeric and textiles.'),
    ]);

    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Turmeric and textiles.'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous version'));
    await tester.pump();

    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('What is Ooty known for?'), findsOneWidget);
    expect(find.text('Tea gardens.'), findsOneWidget);
    expect(find.text('Turmeric and textiles.'), findsNothing);
  });

  testWidgets('long-pressing a question offers to edit it, in the composer', (
    tester,
  ) async {
    await _pump(tester, [_user('Plan a trip to Ooty'), _bot('Sure.')]);

    await tester.longPress(find.text('Plan a trip to Ooty'));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Select text'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(
      find.text('Regenerate'),
      findsNothing,
      reason: 'regenerating belongs to the answer',
    );

    await tester.tap(find.text('Edit question'));
    await tester.pumpAndSettle();

    expect(find.text('Editing your question'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Plan a trip to Ooty');
    expect(find.byTooltip('Save and ask again'), findsOneWidget);

    await tester.tap(find.byTooltip('Cancel editing'));
    await tester.pump();
    expect(find.text('Editing your question'), findsNothing);
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('the latest question carries an edit button', (tester) async {
    await _pump(tester, [
      _user('First'),
      _bot('One.'),
      _user('Second'),
      _bot('Two.'),
    ]);
    expect(find.byTooltip('Edit question'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit question'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Second');
  });

  testWidgets('long-pressing the latest answer offers regenerate, not edit', (
    tester,
  ) async {
    await _pump(tester, [_user('Q'), _bot('The answer.')]);
    await tester.longPress(find.text('The answer.'));
    await tester.pumpAndSettle();
    expect(find.text('Regenerate'), findsOneWidget);
    expect(find.text('Edit question'), findsNothing);
  });

  testWidgets('select text opens the whole message as selectable text', (
    tester,
  ) async {
    await _pump(tester, [_user('Q'), _bot('Pick **some** of this.')]);
    await tester.longPress(find.text('Pick some of this.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select text'));
    await tester.pumpAndSettle();
    expect(find.text('Select text'), findsOneWidget); // the page title
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('deleting asks first, then removes the exchange', (tester) async {
    final container = await _pump(tester, [
      _user('Keep me'),
      _bot('Kept.'),
      _user('Remove me'),
      _bot('Removed.'),
    ]);
    await tester.longPress(find.text('Remove me'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this exchange?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(
      [
        for (final t in container.read(chatSessionsProvider).activeTurns)
          t.content,
      ],
      ['Keep me', 'Kept.'],
    );
  });

  testWidgets('follow-ups show under the latest answer only', (tester) async {
    await _pump(tester, [
      _user('Old'),
      _bot('Old answer.', followUps: ['Stale suggestion?']),
      _user('What is Ooty?'),
      _bot(
        'A hill station.',
        followUps: ['How cold is Ooty?', 'How do I get there?'],
      ),
    ]);
    expect(find.text('Ask next'), findsOneWidget);
    expect(find.text('How cold is Ooty?'), findsOneWidget);
    expect(find.text('How do I get there?'), findsOneWidget);
    expect(find.text('Stale suggestion?'), findsNothing);
  });

  testWidgets('tapping a follow-up with no model says what to do', (
    tester,
  ) async {
    final container = await _pump(tester, [
      _user('What is Ooty?'),
      _bot('A hill station.', followUps: ['How cold is Ooty?']),
    ]);
    await tester.tap(find.text('How cold is Ooty?'));
    await tester.pump();
    expect(
      find.text('Load a model from the Models tab first.'),
      findsOneWidget,
    );
    expect(container.read(chatSessionsProvider).activeTurns, hasLength(2));
  });

  testWidgets('a table in a reply renders as a table', (tester) async {
    await _pump(tester, [
      _user('Difference between Ooty vs Erode in table'),
      _bot(
        '| | Ooty | Erode |\n'
        '|---|---|---|\n'
        '| Climate | Cool | Hot |\n'
        '| Known for | Tea | Turmeric |',
      ),
    ]);
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('Climate'), findsOneWidget);
    expect(find.text('Turmeric'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
