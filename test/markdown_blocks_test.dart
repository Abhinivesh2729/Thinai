import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/ui/theme/app_theme.dart';
import 'package:local_llm/ui/widgets/markdown_text.dart';

const _table =
    'Here is the comparison:\n'
    '\n'
    '| City | District | Known for |\n'
    '| :--- | :---: | ---: |\n'
    '| Ooty | Nilgiris | **Tea** gardens |\n'
    '| Erode | Erode | Turmeric \\| textiles |\n'
    '\n'
    'Both are in Tamil Nadu.';

void main() {
  group('parseMarkdownBlocks', () {
    test('prose with no code or tables stays one block', () {
      final blocks = parseMarkdownBlocks('# Hi\n\nSome **text**.\n- a');
      expect(blocks, hasLength(1));
      expect(blocks.single, isA<MarkdownTextBlock>());
    });

    test('finds a table between two paragraphs', () {
      final blocks = parseMarkdownBlocks(_table);
      expect(blocks, hasLength(3));
      expect(
        (blocks[0] as MarkdownTextBlock).source,
        'Here is the comparison:',
      );
      final table = blocks[1] as MarkdownTableBlock;
      expect(table.header, ['City', 'District', 'Known for']);
      expect(table.align, [TextAlign.left, TextAlign.center, TextAlign.right]);
      expect(table.rows, [
        ['Ooty', 'Nilgiris', '**Tea** gardens'],
        ['Erode', 'Erode', 'Turmeric | textiles'],
      ]);
      expect(
        (blocks[2] as MarkdownTextBlock).source,
        'Both are in Tamil Nadu.',
      );
    });

    test('pads short rows and cuts long ones to the header width', () {
      final table =
          parseMarkdownBlocks('a | b\n--- | ---\n1 |\n1 | 2 | 3').single
              as MarkdownTableBlock;
      expect(table.rows, [
        ['1', ''],
        ['1', '2'],
      ]);
    });

    test('a header with no separator row yet is still prose', () {
      // Mid-stream: the separator has not arrived, so there is no table yet.
      final blocks = parseMarkdownBlocks('| City | District |');
      expect(blocks.single, isA<MarkdownTextBlock>());
    });

    test('fenced code keeps its language and body', () {
      final blocks = parseMarkdownBlocks(
        'Run this:\n```python\nprint("hi")\n```\nDone.',
      );
      expect(blocks, hasLength(3));
      final code = blocks[1] as MarkdownCodeBlock;
      expect(code.language, 'python');
      expect(code.code, 'print("hi")');
    });

    test('an unclosed fence is code to the end, as while streaming', () {
      final code =
          parseMarkdownBlocks('```\nline one\nline two').single
              as MarkdownCodeBlock;
      expect(code.language, isNull);
      expect(code.code, 'line one\nline two');
    });
  });

  group('MarkdownText', () {
    Future<void> pump(
      WidgetTester tester,
      String data, {
      double fontSize = 15,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: MarkdownText(
                data: data,
                style: TextStyle(fontSize: fontSize),
                selectable: false,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('draws a table as a real grid', (tester) async {
      await pump(tester, _table);
      expect(find.byType(Table), findsOneWidget);
      final table = tester.widget<Table>(find.byType(Table));
      expect(table.children, hasLength(3), reason: 'header plus two rows');
      expect(find.text('Here is the comparison:'), findsOneWidget);
      expect(find.text('Both are in Tamil Nadu.'), findsOneWidget);
      // The pipe syntax itself is gone from what is shown.
      expect(find.textContaining('| City |'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a wide table scrolls rather than overflowing', (tester) async {
      final header = List.generate(8, (i) => 'Column number $i').join(' | ');
      final rule = List.filled(8, '---').join(' | ');
      final row = List.generate(8, (i) => 'value $i').join(' | ');
      await pump(tester, '$header\n$rule\n$row');
      expect(find.byType(Table), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a few columns fit the screen; many columns scroll', (
      tester,
    ) async {
      Finder sideways() => find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      // The test font draws every glyph as a wide square, so a smaller size
      // stands in for Inter's real proportions.
      await pump(tester, _table, fontSize: 12);
      expect(sideways(), findsNothing, reason: 'three columns wrap to fit');

      final header = List.generate(8, (i) => 'Column $i').join(' | ');
      final rule = List.filled(8, '---').join(' | ');
      await pump(tester, '$header\n$rule\n${List.filled(8, 'x').join(' | ')}');
      expect(sideways(), findsOneWidget, reason: 'eight do not');
    });

    testWidgets('a short label column is never squeezed mid-word', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: SizedBox(
              width: 360,
              child: MarkdownText(
                data:
                    '| Feature | Tea | Coffee |\n'
                    '|---|---|---|\n'
                    '| Appearance | Green tea, light and grassy, often served '
                    'plain | Bold and bitter, often served with milk |',
                style: TextStyle(fontSize: 10),
                selectable: false,
              ),
            ),
          ),
        ),
      );
      // Fits without scrolling, and the label stays on one line. Weighting
      // columns by text length alone gave this one a sliver and split the
      // word across lines.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
        findsNothing,
      );
      final lineHeight = 10 * 0.92 * 1.4;
      expect(
        tester.getSize(find.text('Appearance')).height,
        lessThan(lineHeight * 1.5),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('code gets a labelled block with a copy button', (
      tester,
    ) async {
      await pump(tester, 'Try:\n```dart\nvoid main() {}\n```');
      expect(find.text('dart'), findsOneWidget);
      expect(find.text('void main() {}'), findsOneWidget);
      expect(find.byTooltip('Copy code'), findsOneWidget);
    });
  });
}
