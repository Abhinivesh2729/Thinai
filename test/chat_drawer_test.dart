import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/about_page.dart';
import 'package:local_llm/ui/widgets/chat_drawer.dart';
import 'package:local_llm/ui/widgets/model_settings_sheet.dart';

/// Model store that never touches the file system.
class _FakeModelStore implements ModelStore {
  _FakeModelStore([this.models = const []]);

  final List<LocalModel> models;

  @override
  Future<List<LocalModel>> list() async => models;

  @override
  Future<LocalModel?> findById(String id) async {
    for (final m in models) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Future<String?> projectorPathFor(String? filename) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LocalModel _model(String id) => LocalModel(
  id: id,
  displayName: '$id.gguf',
  path: '/nowhere/$id.gguf',
  sizeBytes: 1 << 30,
  modifiedAt: DateTime(2026, 1, 1),
);

/// Noon on the day [daysAgo] days before today, so the date group is the same
/// whatever time the test runs.
int _daysAgo(int daysAgo) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 12);
  return today.subtract(Duration(days: daysAgo)).millisecondsSinceEpoch;
}

/// Stores conversations as `(id, opening question, reply, days ago)`.
void _seed(List<(String, String, String, int)> conversations) {
  SharedPreferences.setMockInitialValues({
    'chat_sessions_v1': jsonEncode({
      'conversations': [
        for (final c in conversations)
          {
            'id': c.$1,
            'updatedAt': _daysAgo(c.$4),
            'turns': [
              {'role': 'user', 'content': c.$2},
              if (c.$3.isNotEmpty) {'role': 'assistant', 'content': c.$3},
            ],
          },
      ],
    }),
  });
}

void _seedFive() => _seed([
  ('t', 'Today question', 'Fresh answer', 0),
  ('y', 'Yesterday question', 'About llamas', 1),
  ('w', 'Earlier this week', 'Weekly reply', 3),
  ('m', 'Earlier this month', 'Monthly reply', 15),
  ('o', 'Long ago question', 'Ancient reply', 60),
]);

final _scaffoldKey = GlobalKey<ScaffoldState>();

Future<ProviderContainer> _openDrawer(
  WidgetTester tester, {
  ModelStore? store,
}) async {
  // Tall enough that every row and the footer are laid out without scrolling.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      modelStoreProvider.overrideWithValue(store ?? _FakeModelStore()),
      appVersionProvider.overrideWith((ref) async => '1.2.3'),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          key: _scaffoldKey,
          drawer: const ChatDrawer(),
          body: const Text('Chat body'),
        ),
      ),
    ),
  );
  // Let the sessions controller read its stored conversations.
  await tester.pump();
  await tester.pump();
  _scaffoldKey.currentState!.openDrawer();
  await tester.pumpAndSettle();
  return container;
}

bool _drawerOpen() => _scaffoldKey.currentState!.isDrawerOpen;

List<String> _ids(ProviderContainer c) => [
  for (final conv in c.read(chatSessionsProvider).conversations) conv.id,
];

Finder _moreButton(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(Row)).first,
  matching: find.byIcon(Icons.more_horiz_rounded),
);

void main() {
  testWidgets(
    'shows an empty state and no search box when there is no history',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _openDrawer(tester);

      expect(find.text('No chats yet'), findsOneWidget);
      expect(find.text('Your chats show up here.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('0 conversations'), findsOneWidget);
    },
  );

  testWidgets('groups conversations under relative date headers', (
    tester,
  ) async {
    _seedFive();
    await _openDrawer(tester);

    final headers = [
      'TODAY',
      'YESTERDAY',
      'PREVIOUS 7 DAYS',
      'THIS MONTH',
      'OLDER',
    ];
    for (final h in headers) {
      expect(find.text(h), findsOneWidget);
    }
    // Headers appear newest first, each above its own conversation.
    final tops = [for (final h in headers) tester.getTopLeft(find.text(h)).dy];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(
      tester.getTopLeft(find.text('Yesterday question')).dy,
      greaterThan(tester.getTopLeft(find.text('YESTERDAY')).dy),
    );
    expect(find.text('5 conversations'), findsOneWidget);
  });

  testWidgets('a single conversation is counted without a plural', (
    tester,
  ) async {
    _seed([('a', 'Only one', '', 0)]);
    await _openDrawer(tester);
    expect(find.text('1 conversation'), findsOneWidget);
  });

  testWidgets('search filters by title and by the last reply', (tester) async {
    _seedFive();
    await _openDrawer(tester);

    await tester.enterText(find.byType(TextField), 'llamas');
    await tester.pump();
    expect(find.text('Yesterday question'), findsOneWidget);
    expect(find.text('Today question'), findsNothing);
    expect(find.text('TODAY'), findsNothing);

    await tester.enterText(find.byType(TextField), 'EARLIER');
    await tester.pump();
    expect(find.text('Earlier this week'), findsOneWidget);
    expect(find.text('Earlier this month'), findsOneWidget);
    expect(find.text('Long ago question'), findsNothing);
  });

  testWidgets('a search with no match says so and the clear icon resets it', (
    tester,
  ) async {
    _seedFive();
    await _openDrawer(tester);

    await tester.enterText(find.byType(TextField), 'zebra');
    await tester.pump();
    expect(find.text('No chats for "zebra"'), findsOneWidget);

    final clear = find.descendant(
      of: find.byType(TextField),
      matching: find.byIcon(Icons.close_rounded),
    );
    await tester.tap(clear);
    await tester.pump();
    expect(find.text('No chats for "zebra"'), findsNothing);
    expect(find.text('Today question'), findsOneWidget);
    expect(find.text('Long ago question'), findsOneWidget);
  });

  testWidgets('tapping a conversation opens it on the chat tab', (
    tester,
  ) async {
    _seedFive();
    final container = await _openDrawer(tester);
    container.read(shellTabIndexProvider.notifier).state = 2;

    await tester.tap(find.text('Earlier this week'));
    await tester.pumpAndSettle();

    expect(container.read(chatSessionsProvider).activeId, 'w');
    expect(container.read(shellTabIndexProvider), 0);
    expect(_drawerOpen(), isFalse);
  });

  testWidgets('the open conversation is shown in bold', (tester) async {
    _seedFive();
    final container = await _openDrawer(tester);
    container.read(chatSessionsProvider.notifier).open('y');
    await tester.pump();

    FontWeight? weight(String title) =>
        tester.widget<Text>(find.text(title)).style?.fontWeight;
    expect(weight('Yesterday question'), FontWeight.w600);
    expect(weight('Today question'), FontWeight.w400);
  });

  testWidgets('New chat clears the open conversation and closes the drawer', (
    tester,
  ) async {
    _seedFive();
    final container = await _openDrawer(tester);
    container.read(chatSessionsProvider.notifier).open('t');
    container.read(shellTabIndexProvider.notifier).state = 1;
    await tester.pump();

    await tester.tap(find.text('New chat'));
    await tester.pumpAndSettle();

    expect(container.read(chatSessionsProvider).activeId, isNull);
    expect(_ids(container), hasLength(5), reason: 'nothing is discarded');
    expect(container.read(shellTabIndexProvider), 0);
    expect(_drawerOpen(), isFalse);
  });

  testWidgets('the close button dismisses the drawer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _openDrawer(tester);
    await tester.tap(find.byTooltip('Close menu'));
    await tester.pumpAndSettle();
    expect(_drawerOpen(), isFalse);
  });

  testWidgets('the options sheet lists manage, rename and delete', (
    tester,
  ) async {
    _seedFive();
    await _openDrawer(tester);

    await tester.tap(_moreButton('Today question'));
    await tester.pumpAndSettle();

    expect(find.text('Select'), findsOneWidget);
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Delete chat'), findsOneWidget);
    // The sheet repeats the conversation's title as its header.
    expect(find.text('Today question'), findsNWidgets(2));
  });

  testWidgets('renaming with Save changes the title', (tester) async {
    _seedFive();
    final container = await _openDrawer(tester);

    await tester.tap(_moreButton('Today question'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Rename chat'), findsOneWidget);
    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(field).controller!.text, 'Today question');

    await tester.enterText(field, '  Renamed chat  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Renamed chat'), findsOneWidget);
    expect(
      container.read(chatSessionsProvider).conversations.first.customTitle,
      'Renamed chat',
    );
  });

  testWidgets('renaming also works from the keyboard submit action', (
    tester,
  ) async {
    _seedFive();
    await _openDrawer(tester);

    await tester.tap(_moreButton('Long ago question'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'Submitted name');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Submitted name'), findsOneWidget);
    expect(find.text('Long ago question'), findsNothing);
  });

  testWidgets('a blank rename or Cancel leaves the title alone', (
    tester,
  ) async {
    _seedFive();
    await _openDrawer(tester);

    Future<Finder> openRename() async {
      await tester.tap(_moreButton('Today question'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      return find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
    }

    await tester.enterText(await openRename(), '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Today question'), findsOneWidget);

    await tester.enterText(await openRename(), 'Never saved');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Never saved'), findsNothing);
    expect(find.text('Today question'), findsOneWidget);
  });

  testWidgets('deleting from the options sheet asks first', (tester) async {
    _seedFive();
    final container = await _openDrawer(tester);

    await tester.tap(_moreButton('Earlier this month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete chat'));
    await tester.pumpAndSettle();

    expect(find.text('Delete chat?'), findsOneWidget);
    expect(
      find.textContaining('"Earlier this month"'),
      findsOneWidget,
      reason: 'the dialog names the chat it will delete',
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_ids(container), contains('m'));

    await tester.tap(_moreButton('Earlier this month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(_ids(container), isNot(contains('m')));
    expect(find.text('Earlier this month'), findsNothing);
    expect(find.text('4 conversations'), findsOneWidget);
  });

  testWidgets('long press opens the options sheet', (tester) async {
    _seedFive();
    await _openDrawer(tester);

    await tester.longPress(find.text('Yesterday question'));
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget);
  });

  testWidgets('Select / Manage enters manage mode with that chat ticked', (
    tester,
  ) async {
    _seedFive();
    await _openDrawer(tester);

    await tester.longPress(find.text('Yesterday question'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    expect(find.text('Manage chats'), findsOneWidget);
    expect(find.text('1 of 5 selected'), findsOneWidget);
    expect(find.text('Delete (1)'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    // Row menus and the New chat button are hidden while managing.
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    expect(find.text('New chat'), findsNothing);
  });

  testWidgets('manage mode toggles rows by tap and long press', (tester) async {
    _seedFive();
    final container = await _openDrawer(tester);

    await tester.tap(find.text('Manage chats'));
    await tester.pumpAndSettle();
    expect(find.text('Tap to select'), findsOneWidget);
    final delete = find.widgetWithText(FilledButton, 'Delete');
    expect(tester.widget<FilledButton>(delete).onPressed, isNull);

    await tester.tap(find.text('Today question'));
    await tester.pump();
    expect(find.text('1 of 5 selected'), findsOneWidget);
    // Tapping a row selects it rather than opening it.
    expect(container.read(chatSessionsProvider).activeId, isNull);
    expect(_drawerOpen(), isTrue);

    await tester.longPress(find.text('Long ago question'));
    await tester.pump();
    expect(find.text('2 of 5 selected'), findsOneWidget);

    await tester.tap(find.text('Today question'));
    await tester.pump();
    await tester.longPress(find.text('Long ago question'));
    await tester.pump();
    expect(find.text('Tap to select'), findsOneWidget);
  });

  testWidgets('Select all and Deselect all flip the whole visible list', (
    tester,
  ) async {
    _seedFive();
    await _openDrawer(tester);

    await tester.tap(find.text('Manage chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select all'));
    await tester.pump();
    expect(find.text('5 of 5 selected'), findsOneWidget);
    expect(find.text('Delete (5)'), findsOneWidget);

    await tester.tap(find.text('Deselect all'));
    await tester.pump();
    expect(find.text('Tap to select'), findsOneWidget);
  });

  testWidgets('Select all only takes the chats the search is showing', (
    tester,
  ) async {
    _seedFive();
    await _openDrawer(tester);

    await tester.enterText(find.byType(TextField), 'earlier');
    await tester.pump();
    await tester.tap(find.text('Manage chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select all'));
    await tester.pump();
    expect(find.text('2 of 2 selected'), findsOneWidget);
  });

  testWidgets('Select all is disabled when the search matches nothing', (
    tester,
  ) async {
    _seedFive();
    await _openDrawer(tester);

    await tester.enterText(find.byType(TextField), 'zebra');
    await tester.pump();
    await tester.tap(find.text('Manage chats'));
    await tester.pumpAndSettle();

    final selectAll = find.widgetWithText(TextButton, 'Select all');
    expect(tester.widget<TextButton>(selectAll).onPressed, isNull);
  });

  testWidgets('the back arrow and Done both leave manage mode', (tester) async {
    _seedFive();
    await _openDrawer(tester);

    await tester.tap(find.text('Manage chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today question'));
    await tester.pump();
    await tester.tap(find.byTooltip('Exit manage mode'));
    await tester.pump();
    expect(find.text('New chat'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);

    await tester.tap(find.text('Manage chats'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tap to select'),
      findsOneWidget,
      reason: 'leaving manage mode drops the old selection',
    );
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('New chat'), findsOneWidget);
  });

  testWidgets('batch delete asks first and can be cancelled', (tester) async {
    _seedFive();
    final container = await _openDrawer(tester);

    await tester.tap(find.text('Manage chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today question'));
    await tester.tap(find.text('Long ago question'));
    await tester.pump();
    await tester.tap(find.text('Delete (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Delete 2 chats?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_ids(container), hasLength(5));
    expect(find.text('2 of 5 selected'), findsOneWidget);
  });

  testWidgets('batch delete removes the selected chats and reports it', (
    tester,
  ) async {
    _seedFive();
    final container = await _openDrawer(tester);

    await tester.tap(find.text('Manage chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today question'));
    await tester.tap(find.text('Long ago question'));
    await tester.pump();
    await tester.tap(find.text('Delete (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(_ids(container), unorderedEquals(['y', 'w', 'm']));
    expect(find.text('Deleted 2 chats'), findsOneWidget);
    // Chats remain, so the drawer stays in manage mode with nothing ticked.
    expect(find.text('Tap to select'), findsOneWidget);
  });

  testWidgets('deleting every chat leaves manage mode', (tester) async {
    _seed([('a', 'Lonely chat', '', 0)]);
    final container = await _openDrawer(tester);

    await tester.tap(find.text('Manage chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lonely chat'));
    await tester.pump();
    await tester.tap(find.text('Delete (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Delete 1 chat?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(_ids(container), isEmpty);
    expect(find.text('Deleted 1 chat'), findsOneWidget);
    expect(find.text('No chats yet'), findsOneWidget);
    expect(find.text('New chat'), findsOneWidget);
  });

  testWidgets('App Settings switches to the settings tab', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = await _openDrawer(tester);

    await tester.tap(find.text('App Settings'));
    await tester.pumpAndSettle();
    expect(container.read(shellTabIndexProvider), 3);
    expect(_drawerOpen(), isFalse);
  });

  testWidgets('About Thinai opens the about page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _openDrawer(tester);

    await tester.tap(find.text('About Thinai'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsOneWidget);
  });

  testWidgets('Model Settings without a model explains what to do', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _openDrawer(tester);

    await tester.tap(find.text('Model Settings'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Download a model first.'), findsOneWidget);
    expect(find.byType(ModelSettingsSheet), findsNothing);
  });

  testWidgets('Model Settings opens the sheet for the active model', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = _FakeModelStore([_model('first'), _model('second')]);
    final container = await _openDrawer(tester, store: store);
    await container.read(activeModelIdProvider.notifier).set(store.models.last);

    await tester.tap(find.text('Model Settings'));
    await tester.pump();
    await tester.pump();

    final sheet = tester.widget<ModelSettingsSheet>(
      find.byType(ModelSettingsSheet),
    );
    expect(sheet.model.id, 'second');
  });

  testWidgets('Model Settings falls back to the first installed model', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = _FakeModelStore([_model('first'), _model('second')]);
    await _openDrawer(tester, store: store);

    await tester.tap(find.text('Model Settings'));
    await tester.pump();
    await tester.pump();

    final sheet = tester.widget<ModelSettingsSheet>(
      find.byType(ModelSettingsSheet),
    );
    expect(sheet.model.id, 'first');
  });
}
