import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/l10n/l10n.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/chat_history_page.dart';
import 'package:local_llm/ui/pages/chat_page.dart';
import 'package:local_llm/ui/widgets/chat_drawer.dart';
import 'package:local_llm/ui/widgets/markdown_text.dart';

import 'helpers/fonts.dart';

/// Model store that never touches the file system.
class _FakeModelStore implements ModelStore {
  @override
  Future<List<LocalModel>> list() async => const [];

  @override
  Future<LocalModel?> findById(String id) async => null;

  @override
  Future<String?> projectorPathFor(String? filename) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Two conversations from today, the first with a searched reply.
String _sessions() => jsonEncode({
  'activeId': 'a',
  'conversations': [
    {
      'id': 'a',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'turns': [
        {'role': 'user', 'content': 'latest news'},
        {
          'role': 'assistant',
          'content': 'Here it is [1].',
          'sources': [
            {'title': 'One', 'url': 'https://example.com/1'},
            {'title': 'Two', 'url': 'https://example.org/2'},
          ],
        },
      ],
    },
    {
      'id': 'b',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'turns': [
        {'role': 'user', 'content': 'hello'},
      ],
    },
  ],
});

final _scaffoldKey = GlobalKey<ScaffoldState>();

/// Pumps [home] in Tamil, the way the app does when the user picks it.
Future<ProviderContainer> _pumpTamil(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      modelStoreProvider.overrideWithValue(_FakeModelStore()),
      appVersionProvider.overrideWith((ref) async => '1.2.3'),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('ta'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  // Let the controllers read their stored preferences.
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(loadRoboto);

  testWidgets('chat page empty state and composer read in Tamil', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpTamil(tester, const ChatPage());

    expect(find.text('தனிப்பட்ட ஆஃப்லைன் AI'), findsOneWidget);
    expect(
      find.text('அறிவுரு பதிவிறக்கப்படவில்லை. பதிவிறக்க தட்டவும்.'),
      findsOneWidget,
    );
    expect(find.text('அறிவுருக்களை உலாவிப் பதிவிறக்கு'), findsOneWidget);
    expect(find.text('உங்கள் அறிவுருவுக்குஉரை அனுப்பவும்'), findsOneWidget);
    expect(find.text('Private Offline AI'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a searched reply and the speed dial read in Tamil', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'chat_sessions_v1': _sessions()});
    final container = await _pumpTamil(tester, const ChatPage());
    container.read(chatSessionsProvider.notifier).open('a');
    await tester.pumpAndSettle();

    expect(find.text('ஆதாரங்கள்'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('இணையத் தேடல்'), findsOneWidget);
    expect(find.text('கேமரா'), findsOneWidget);
    expect(find.text('ஆவணம்'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer reads in Tamil', (tester) async {
    SharedPreferences.setMockInitialValues({'chat_sessions_v1': _sessions()});
    await _pumpTamil(
      tester,
      Scaffold(
        key: _scaffoldKey,
        drawer: const ChatDrawer(),
        body: const SizedBox(),
      ),
    );
    _scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('புதிய உரையாடல்'), findsOneWidget);
    expect(find.text('இன்று'), findsOneWidget);
    expect(find.text('2 உரையாடல்கள்'), findsOneWidget);
    expect(find.text('Thinai பற்றி'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat history reads in Tamil', (tester) async {
    SharedPreferences.setMockInitialValues({'chat_sessions_v1': _sessions()});
    final container = await _pumpTamil(tester, const ChatHistoryPage());
    container.read(chatSessionsProvider.notifier).open('a');
    await tester.pumpAndSettle();

    expect(find.text('உரையாடல் வரலாறு'), findsOneWidget);
    expect(find.text('செயலில்'), findsOneWidget);
    expect(find.text('2 உரைகள்'), findsOneWidget);
    expect(find.text('1 உரை'), findsOneWidget);
    expect(find.text('இப்போது'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('code block header reads in Tamil', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpTamil(
      tester,
      const Scaffold(
        body: MarkdownText(
          data: '```\nprint(1)\n```',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );

    expect(find.text('குறியீடு'), findsOneWidget);
    expect(find.text('நகலெடு'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('timestamps follow the language they are given', () {
    final ta = lookupAppLocalizations(const Locale('ta'));
    final now = DateTime(2026, 8, 21, 12);
    String at(DateTime when) => formatChatTimestamp(when, now: now, l10n: ta);

    expect(at(now.subtract(const Duration(seconds: 5))), 'இப்போது');
    expect(at(now.subtract(const Duration(minutes: 5))), '5 நிமி. முன்');
    expect(at(now.subtract(const Duration(days: 1))), 'நேற்று');
    expect(at(now.subtract(const Duration(days: 3))), '3 நாட்களுக்கு முன்');
  });
}
