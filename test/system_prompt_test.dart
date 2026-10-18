import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/chat/system_prompt.dart';
import 'package:local_llm/ui/pages/system_prompt_page.dart';

const _key = 'chat_system_prompt_v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('store', () {
    test('starts on the default when nothing was saved', () async {
      SharedPreferences.setMockInitialValues({});
      final c = SystemPromptController();
      expect(await c.current(), kDefaultSystemPrompt);
      expect(c.isDefault, isTrue);
    });

    test('a saved prompt survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      await SystemPromptController().set('Answer only in Tamil.');

      final reloaded = SystemPromptController();
      expect(await reloaded.current(), 'Answer only in Tamil.');
    });

    test('the first read waits for the saved prompt', () async {
      SharedPreferences.setMockInitialValues({_key: 'Be brief.'});
      // No pump between construction and the read: a message sent straight
      // after launch must still go out with the user's prompt.
      expect(await SystemPromptController().current(), 'Be brief.');
    });

    test('an empty prompt is kept, not swapped for the default', () async {
      SharedPreferences.setMockInitialValues({});
      await SystemPromptController().set('');
      expect(await SystemPromptController().current(), '');
    });

    test('reset goes back to the default and forgets the edit', () async {
      SharedPreferences.setMockInitialValues({_key: 'Be brief.'});
      final c = SystemPromptController();
      await c.reset();
      expect(c.state, kDefaultSystemPrompt);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_key), isNull);
    });
  });

  group('page', () {
    Future<ProviderContainer> pump(WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SystemPromptPage()),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('shows, edits, saves and resets the prompt', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await pump(tester);

      expect(find.text(kDefaultSystemPrompt), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('systemPrompt.field')),
        'Reply like a pirate.',
      );
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(container.read(systemPromptProvider), 'Reply like a pirate.');

      await tester.tap(find.text('Reset to default'));
      await tester.pumpAndSettle();
      expect(container.read(systemPromptProvider), kDefaultSystemPrompt);
      expect(find.text(kDefaultSystemPrompt), findsOneWidget);
    });
  });
}
