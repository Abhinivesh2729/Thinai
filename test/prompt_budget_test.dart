import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/chat/prompt_budget.dart';
import 'package:local_llm/llm/chat_message.dart';

int _cost(List<ChatMessage> list) =>
    list.fold(0, (sum, m) => sum + estimateTokens(m.content) + 8);

void main() {
  group('estimateTokens', () {
    test('rounds up and counts empty text as zero', () {
      expect(estimateTokens(''), 0);
      expect(estimateTokens('a'), 1);
      expect(estimateTokens('a' * 32), 10);
      expect(estimateTokens('a' * 33), 11);
    });
  });

  group('fitToContext', () {
    test('returns an empty conversation unchanged', () {
      expect(fitToContext(const [], 4096), isEmpty);
    });

    test('keeps only the last message when the reserve leaves no budget', () {
      final messages = [
        const ChatMessage(role: 'system', content: 'be brief'),
        const ChatMessage(role: 'user', content: 'hi'),
      ];
      final fitted = fitToContext(messages, 100);
      expect(fitted, [messages.last]);
    });

    test('honours an explicit reply reserve', () {
      final messages = [
        ChatMessage(role: 'user', content: 'a' * 3200),
        ChatMessage(role: 'assistant', content: 'b' * 3200),
        const ChatMessage(role: 'user', content: 'next?'),
      ];
      // Fits with a tiny reserve, not with the default 512.
      expect(fitToContext(messages, 2600, replyReserve: 64), messages);
      expect(fitToContext(messages, 2600).length, lessThan(3));
    });

    test('drops a reply left without the question it answered', () {
      final messages = [
        ChatMessage(role: 'user', content: 'q' * 4000),
        ChatMessage(role: 'assistant', content: 'a' * 4000),
        const ChatMessage(role: 'user', content: 'and now?'),
      ];
      final fitted = fitToContext(messages, 2048);
      expect(fitted.single.content, 'and now?');
    });

    test('shortens a long system message from the middle', () {
      final system = 'A' * 5000 + 'B' * 5000;
      final messages = [
        ChatMessage(role: 'system', content: system),
        const ChatMessage(role: 'user', content: 'question'),
      ];
      final fitted = fitToContext(messages, 2048);
      expect(fitted, hasLength(2));
      expect(fitted.first.content, startsWith('AAAA'));
      expect(fitted.first.content, endsWith('BBBB'));
      expect(
        fitted.first.content,
        contains('trimmed to fit the context window'),
      );
      expect(fitted.last.content, 'question');
      expect(_cost(fitted), lessThanOrEqualTo(2048 - kMinReplyReserve));
    });

    test('drops the system message and shortens the question when both '
        'overflow a small window', () {
      final messages = [
        ChatMessage(role: 'system', content: 's' * 10000),
        ChatMessage(role: 'user', content: 'u' * 10000 + 'END'),
      ];
      final fitted = fitToContext(messages, 1024);
      expect(fitted, hasLength(1));
      expect(fitted.single.role, 'user');
      expect(fitted.single.content, endsWith('END'));
      expect(_cost(fitted), lessThanOrEqualTo(1024 - kMinReplyReserve));
    });

    test('keeps tool metadata on a shortened message', () {
      final messages = [
        ChatMessage(
          role: 'tool',
          content: 't' * 20000,
          toolName: 'web_search',
          toolCalls: const [
            {'id': '1'},
          ],
        ),
      ];
      final fitted = fitToContext(messages, 1024);
      expect(fitted.single.toolName, 'web_search');
      expect(fitted.single.toolCalls, messages.single.toolCalls);
      expect(fitted.single.content.length, lessThan(20000));
    });
  });
}
