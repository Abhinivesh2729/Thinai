import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/ui/widgets/markdown_text.dart';

const _base = TextStyle(fontSize: 14, color: Color(0xFF111111));

TextSpan _parse(String source) => buildMarkdownSpan(
  source,
  base: _base,
  codeBackground: const Color(0x11000000),
  muted: const Color(0xFF666666),
);

/// Flattens the span tree to (text, style) pairs, dropping empties, so a test
/// can assert on what the user actually sees.
List<(String, TextStyle?)> _flatten(InlineSpan span) {
  final out = <(String, TextStyle?)>[];
  void walk(InlineSpan s) {
    if (s is! TextSpan) return;
    if (s.text != null && s.text!.isNotEmpty) out.add((s.text!, s.style));
    for (final child in s.children ?? const <InlineSpan>[]) {
      walk(child);
    }
  }

  walk(span);
  return out;
}

String _plain(String source) => _flatten(_parse(source)).map((e) => e.$1).join();

TextStyle? _styleOf(String source, String text) {
  for (final part in _flatten(_parse(source))) {
    if (part.$1 == text) return part.$2;
  }
  return null;
}

void main() {
  group('emphasis', () {
    test('bold loses its asterisks and gains weight', () {
      expect(_plain('a **training** b'), 'a training b');
      expect(_styleOf('a **training** b', 'training')?.fontWeight,
          FontWeight.w700);
    });

    test('underscore bold works too', () {
      expect(_plain('__loud__'), 'loud');
      expect(_styleOf('__loud__', 'loud')?.fontWeight, FontWeight.w700);
    });

    test('single asterisks italicise', () {
      expect(_plain('an *aside* here'), 'an aside here');
      expect(_styleOf('an *aside* here', 'aside')?.fontStyle,
          FontStyle.italic);
    });

    test('bold nests inside italics', () {
      expect(_plain('*soft **hard** soft*'), 'soft hard soft');
      final hard = _styleOf('*soft **hard** soft*', 'hard');
      expect(hard?.fontWeight, FontWeight.w700);
      expect(hard?.fontStyle, FontStyle.italic);
    });

    test('identifiers with underscores are left alone', () {
      expect(_plain('call model_store_path now'), 'call model_store_path now');
      expect(_plain('snake_case and file_name.dart'),
          'snake_case and file_name.dart');
    });

    test('an unterminated marker stays literal', () {
      // Happens constantly mid-stream, when only half the bold has arrived.
      expect(_plain('a **partial'), 'a **partial');
    });

    test('bare asterisks are not treated as markup', () {
      expect(_plain('2 * 3 * 4'), '2 * 3 * 4');
    });
  });

  group('code', () {
    test('inline code drops its backticks and goes monospace', () {
      expect(_plain('run `flutter test` now'), 'run flutter test now');
      expect(_styleOf('run `flutter test` now', 'flutter test')?.fontFamily,
          'monospace');
    });

    test('markup inside inline code is not interpreted', () {
      expect(_plain('`a **b** c`'), 'a **b** c');
    });

    test('a fenced block keeps its lines and drops the fences', () {
      const source = 'before\n```dart\nvar x = 1;\n```\nafter';
      expect(_plain(source), 'before\nvar x = 1;\nafter');
      expect(_styleOf(source, 'var x = 1;')?.fontFamily, 'monospace');
    });
  });

  group('blocks', () {
    test('headings lose their hashes and get heavier', () {
      expect(_plain('## Training'), 'Training');
      final style = _styleOf('## Training', 'Training');
      expect(style?.fontWeight, FontWeight.w800);
      expect(style!.fontSize!, greaterThan(14));
    });

    test('bullets become real bullets', () {
      expect(_plain('- one\n- two'), '•  one\n•  two');
    });

    test('numbered lists keep their numbers', () {
      expect(_plain('1. first\n2. second'), '1. first\n2. second');
    });

    test('task boxes render as boxes', () {
      expect(_plain('- [x] done\n- [ ] todo'), '☑  done\n☐  todo');
    });

    test('a quote is marked and muted', () {
      expect(_plain('> mind this'), '┃ mind this');
      expect(_styleOf('> mind this', 'mind this')?.fontStyle,
          FontStyle.italic);
    });

    test('link labels survive, the target does not show', () {
      expect(_plain('see [the docs](https://example.invalid/x)'),
          'see the docs');
    });

    test('plain prose is untouched', () {
      const prose = 'Neural networks learn from data.\nThat is all.';
      expect(_plain(prose), prose);
    });

    test('blank lines between paragraphs are preserved', () {
      expect(_plain('one\n\ntwo'), 'one\n\ntwo');
    });
  });

  testWidgets('renders selectable text without exploding', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarkdownText(
            data: '# Title\n\nSome **bold** and `code`.\n\n- a\n- b',
            style: _base,
          ),
        ),
      ),
    );
    expect(find.byType(SelectableText), findsOneWidget);
  });
}
