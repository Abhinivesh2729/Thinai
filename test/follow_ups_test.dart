import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/chat/follow_ups.dart';

void main() {
  group('parseFollowUps', () {
    test('keeps three clean questions from a tidy reply', () {
      expect(
        parseFollowUps(
          'What is the best season to visit Ooty?\n'
          'How far is Ooty from Erode?\n'
          'Which hotels are budget friendly?',
        ),
        [
          'What is the best season to visit Ooty?',
          'How far is Ooty from Erode?',
          'Which hotels are budget friendly?',
        ],
      );
    });

    test('strips numbering, bullets, quotes and bold markers', () {
      expect(
        parseFollowUps(
          '1. **What does GGUF stand for?**\n'
          '- "How big is a 4B model?"\n'
          '• Can it run without internet?\n'
          '(4) Is this one dropped as the fourth?',
        ),
        [
          'What does GGUF stand for?',
          'How big is a 4B model?',
          'Can it run without internet?',
        ],
      );
    });

    test('skips preambles, headings, fragments and blank lines', () {
      expect(
        parseFollowUps(
          'Here are three follow-up questions:\n'
          '\n'
          'Follow-up questions\n'
          'Why?\n'
          'How does quantization affect quality?\n',
        ),
        ['How does quantization affect quality?'],
      );
    });

    test('drops repeats and a restatement of the question asked', () {
      expect(
        parseFollowUps(
          'What is Ooty known for?\n'
          'How cold does Ooty get?\n'
          'how cold does ooty get?',
          askedQuestion: 'What is Ooty known for',
        ),
        ['How cold does Ooty get?'],
      );
    });

    test('drops run-ons too long to be a tappable question', () {
      final long = 'Why ${'very ' * 40}long?';
      expect(parseFollowUps(long), isEmpty);
    });

    test('returns nothing for empty output', () {
      expect(parseFollowUps(''), isEmpty);
    });
  });

  group('followUpPrompt', () {
    test('quotes the question and answer and asks for one per line', () {
      final prompt = followUpPrompt('  What is RAM? ', 'Memory. ');
      expect(prompt, hasLength(1));
      expect(prompt.single.role, 'user');
      expect(prompt.single.content, contains('Question: What is RAM?'));
      expect(prompt.single.content, contains('Answer: Memory.'));
      expect(prompt.single.content, contains('one per line'));
    });

    test('trims a long answer to keep the pass short', () {
      final prompt = followUpPrompt('Q', 'x' * 5000);
      expect(prompt.single.content.length, lessThan(1700));
      expect(prompt.single.content, contains('…'));
    });
  });
}
