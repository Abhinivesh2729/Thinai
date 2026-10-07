import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// Renders the slice of Markdown that models actually emit.
///
/// Not a general Markdown implementation: no images or reference links. It
/// covers what shows up in chat replies — emphasis, lists, quotes, headings,
/// fenced code and tables — and anything it does not understand falls through
/// as plain text rather than disappearing.
///
/// Prose stays one [TextSpan] tree per run, so a paragraph-heavy reply is
/// selectable end to end. Code and tables are real widgets: a table drawn
/// with spaces never lines up in a proportional font, and code needs its own
/// scroll and copy.
class MarkdownText extends StatelessWidget {
  const MarkdownText({
    super.key,
    required this.data,
    required this.style,
    this.codeBackground,
    this.mutedColor,
    this.selectable = true,
  });

  final String data;
  final TextStyle style;

  /// Fill behind inline and fenced code. Defaults to a light wash of the
  /// text colour, which works on both bubble tints.
  final Color? codeBackground;

  /// Colour for quotes and rules. Defaults to the text colour at 60%.
  final Color? mutedColor;

  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final code =
        codeBackground ??
        (style.color ?? const Color(0xFF000000)).withValues(alpha: 0.10);
    final muted =
        mutedColor ??
        (style.color ?? const Color(0xFF000000)).withValues(alpha: 0.62);

    Widget prose(String source) {
      final span = buildMarkdownSpan(
        source,
        base: style,
        codeBackground: code,
        muted: muted,
      );
      return selectable ? SelectableText.rich(span) : Text.rich(span);
    }

    final blocks = parseMarkdownBlocks(data);
    if (blocks.every((b) => b is MarkdownTextBlock)) return prose(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          switch (blocks[i]) {
            MarkdownTextBlock(:final source) => prose(source),
            MarkdownCodeBlock(:final code, :final language) => _CodeFence(
              code: code,
              language: language,
              style: style,
            ),
            MarkdownTableBlock(:final header, :final align, :final rows) =>
              _MarkdownTable(
                header: header,
                align: align,
                rows: rows,
                style: style,
                codeBackground: code,
                muted: muted,
              ),
          },
        ],
      ],
    );
  }
}

// ─── blocks ────────────────────────────────────────────────────────────────

/// One stretch of a reply: prose, a fenced code block, or a table.
sealed class MarkdownBlock {
  const MarkdownBlock();
}

class MarkdownTextBlock extends MarkdownBlock {
  const MarkdownTextBlock(this.source);
  final String source;
}

class MarkdownCodeBlock extends MarkdownBlock {
  const MarkdownCodeBlock(this.code, {this.language});
  final String code;

  /// The fence's language tag, when it had one.
  final String? language;
}

class MarkdownTableBlock extends MarkdownBlock {
  const MarkdownTableBlock({
    required this.header,
    required this.align,
    required this.rows,
  });

  final List<String> header;
  final List<TextAlign> align;

  /// Body rows, each padded or cut to the header's width.
  final List<List<String>> rows;
}

final _tableSeparatorCell = RegExp(r'^:?-{1,}:?$');

/// Splits [data] into prose, code and table blocks.
///
/// Built to cope with a reply still streaming in: an unclosed fence is code
/// up to the end, and a table appears as soon as its separator row has
/// arrived, growing a row at a time after that.
List<MarkdownBlock> parseMarkdownBlocks(String data) {
  final blocks = <MarkdownBlock>[];
  final lines = data.split('\n');
  final prose = <String>[];

  void flushProse() {
    // Blank lines at the edges of a run become the gap between blocks, not
    // extra empty lines inside it.
    while (prose.isNotEmpty && prose.first.trim().isEmpty) {
      prose.removeAt(0);
    }
    while (prose.isNotEmpty && prose.last.trim().isEmpty) {
      prose.removeLast();
    }
    if (prose.isNotEmpty) blocks.add(MarkdownTextBlock(prose.join('\n')));
    prose.clear();
  }

  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    final trimmed = line.trimLeft();

    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      flushProse();
      final marker = trimmed.substring(0, 3);
      final tag = trimmed.substring(3).trim().split(RegExp(r'\s+')).first;
      final body = <String>[];
      i++;
      while (i < lines.length && !lines[i].trimLeft().startsWith(marker)) {
        body.add(lines[i]);
        i++;
      }
      i++; // the closing fence, if there was one
      blocks.add(
        MarkdownCodeBlock(body.join('\n'), language: tag.isEmpty ? null : tag),
      );
      continue;
    }

    if (line.contains('|') && i + 1 < lines.length) {
      final separator = _tableCells(lines[i + 1]);
      final header = _tableCells(line);
      final isTable =
          header.isNotEmpty &&
          separator.isNotEmpty &&
          lines[i + 1].contains('-') &&
          separator.every((c) => _tableSeparatorCell.hasMatch(c));
      if (isTable) {
        flushProse();
        final width = header.length;
        final align = [
          for (var c = 0; c < width; c++)
            c < separator.length ? _alignmentOf(separator[c]) : TextAlign.left,
        ];
        final rows = <List<String>>[];
        i += 2;
        while (i < lines.length &&
            lines[i].contains('|') &&
            lines[i].trim().isNotEmpty) {
          final cells = _tableCells(lines[i]);
          rows.add([
            for (var c = 0; c < width; c++) c < cells.length ? cells[c] : '',
          ]);
          i++;
        }
        blocks.add(
          MarkdownTableBlock(header: header, align: align, rows: rows),
        );
        continue;
      }
    }

    prose.add(line);
    i++;
  }
  flushProse();
  return blocks;
}

/// The cells of one table row, honouring `\|` as a literal pipe.
List<String> _tableCells(String line) {
  var text = line.trim();
  if (text.startsWith('|')) text = text.substring(1);
  if (text.endsWith('|') && !text.endsWith(r'\|')) {
    text = text.substring(0, text.length - 1);
  }
  final cells = <String>[];
  final cell = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == r'\' && i + 1 < text.length && text[i + 1] == '|') {
      cell.write('|');
      i++;
    } else if (char == '|') {
      cells.add(cell.toString().trim());
      cell.clear();
    } else {
      cell.write(char);
    }
  }
  cells.add(cell.toString().trim());
  return cells;
}

TextAlign _alignmentOf(String separator) {
  final left = separator.startsWith(':');
  final right = separator.endsWith(':');
  if (left && right) return TextAlign.center;
  if (right) return TextAlign.right;
  return TextAlign.left;
}

/// A fenced code block: its language, a copy button, and a body that scrolls
/// sideways instead of wrapping code into nonsense.
class _CodeFence extends StatelessWidget {
  const _CodeFence({
    required this.code,
    required this.language,
    required this.style,
  });

  final String code;
  final String? language;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final app = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: app.codeSurface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(Space.md, 2, 2, 2),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language ?? 'code',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      letterSpacing: 0,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  color: scheme.onSurfaceVariant,
                  icon: const Icon(Icons.content_copy_rounded),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) showToast(context, 'Code copied');
                  },
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              Space.md,
              10,
              Space.md,
              Space.md,
            ),
            child: Text(
              code,
              style: style.copyWith(
                fontFamily: 'monospace',
                fontSize: (style.fontSize ?? 14) * 0.86,
                height: 1.55,
                letterSpacing: 0,
                color: app.onCodeSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A Markdown table as a real grid: aligned columns, a header row, hairline
/// rules, and a sideways scroll when it is wider than the screen.
class _MarkdownTable extends StatelessWidget {
  const _MarkdownTable({
    required this.header,
    required this.align,
    required this.rows,
    required this.style,
    required this.codeBackground,
    required this.muted,
  });

  final List<String> header;
  final List<TextAlign> align;
  final List<List<String>> rows;
  final TextStyle style;
  final Color codeBackground;
  final Color muted;

  /// Widest a column gets before its text wraps. Keeps one long cell from
  /// pushing every other column off screen.
  static const _maxCellWidth = 240.0;

  TextStyle _cellStyle({bool head = false}) => style.copyWith(
    fontSize: (style.fontSize ?? 14) * 0.92,
    height: 1.4,
    fontWeight: head ? FontWeight.w600 : null,
  );

  /// Horizontal padding inside a cell, on each side.
  static const _cellPad = Space.md;

  Widget _cell(
    String text,
    int column, {
    bool head = false,
    bool capped = false,
  }) {
    final cellStyle = _cellStyle(head: head);
    final code = cellStyle.copyWith(
      fontFamily: 'monospace',
      backgroundColor: codeBackground,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _cellPad, vertical: 9),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: capped ? _maxCellWidth : double.infinity,
        ),
        child: Text.rich(
          TextSpan(children: _inlineSpans(text, cellStyle, code, muted)),
          textAlign: align[column],
        ),
      ),
    );
  }

  /// Narrowest a column may be squeezed when fitting the table to the screen.
  /// Below this the words wrap one per line, and scrolling reads better.
  static const _minFitColumn = 92.0;

  /// Relative column widths for a table that fits the screen, from how much
  /// text each column holds: a label column stays narrow, a description
  /// column gets the room.
  List<double> _weights() {
    return [
      for (var c = 0; c < header.length; c++)
        [
          header[c].length,
          for (final row in rows) row[c].length,
        ].reduce((a, b) => a > b ? a : b).clamp(4, 28).toDouble(),
    ];
  }

  /// Width of the longest word in each column, padding included: the
  /// narrowest each column can be without breaking a word in half.
  List<double> _wordWidths(TextScaler scaler) {
    final painter = TextPainter(textDirection: TextDirection.ltr);
    double widest(String text, TextStyle style) {
      var result = 0.0;
      // Markup characters are not drawn, so they take no room.
      final plain = text.replaceAll(RegExp(r'[*_`~]'), '');
      for (final word in plain.split(RegExp(r'\s+'))) {
        if (word.isEmpty) continue;
        painter
          ..text = TextSpan(text: word, style: style)
          ..textScaler = scaler
          ..layout();
        if (painter.width > result) result = painter.width;
      }
      return result;
    }

    final body = _cellStyle();
    final head = _cellStyle(head: true);
    final widths = [
      for (var c = 0; c < header.length; c++)
        [
              widest(header[c], head),
              for (final row in rows) widest(row[c], body),
            ].reduce((a, b) => a > b ? a : b) +
            _cellPad * 2 +
            1,
    ];
    painter.dispose();
    return widths;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rule = BorderSide(color: scheme.outlineVariant);
    final scaler = MediaQuery.textScalerOf(context);

    Table grid(Map<int, TableColumnWidth>? widths, {bool capped = false}) {
      return Table(
        columnWidths: widths,
        defaultColumnWidth: const IntrinsicColumnWidth(flex: 1),
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        border: TableBorder(horizontalInside: rule, verticalInside: rule),
        children: [
          TableRow(
            decoration: BoxDecoration(color: scheme.surfaceContainerLow),
            children: [
              for (var c = 0; c < header.length; c++)
                _cell(header[c], c, head: true, capped: capped),
            ],
          ),
          for (final row in rows)
            TableRow(
              children: [
                for (var c = 0; c < header.length; c++)
                  _cell(row[c], c, capped: capped),
              ],
            ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.fromBorderSide(rule),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // A few columns fit the screen with their text wrapped, which is
          // how a phone should read a table. It scrolls only when there are
          // many columns, or when even one word per column would not fit.
          final available = constraints.maxWidth;
          final fewColumns = header.length * _minFitColumn <= available;
          if (fewColumns &&
              _wordWidths(scaler).fold(0.0, (a, b) => a + b) <= available) {
            final weights = _weights();
            return grid({
              for (var c = 0; c < weights.length; c++)
                c: _WordSafeFlexColumnWidth(weights[c]),
            });
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: grid(null, capped: true),
            ),
          );
        },
      ),
    );
  }
}

/// A flexible column that never gets narrower than its longest word.
///
/// [FlexColumnWidth] starts every column at zero and hands out space by
/// weight alone, so a short label column next to two wordy ones was squeezed
/// until "Appearance" broke across lines. This one starts each column at the
/// width of its longest word and shares out what is left by weight.
class _WordSafeFlexColumnWidth extends TableColumnWidth {
  const _WordSafeFlexColumnWidth(this.weight);

  final double weight;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    var result = 0.0;
    for (final cell in cells) {
      final width = cell.getMinIntrinsicWidth(double.infinity);
      if (width > result) result = width;
    }
    return result;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      minIntrinsicWidth(cells, containerWidth);

  @override
  double? flex(Iterable<RenderBox> cells) => weight;
}

/// Parses [data] into a span tree. Split out from the widget so it can be
/// tested without pumping a frame.
TextSpan buildMarkdownSpan(
  String data, {
  required TextStyle base,
  required Color codeBackground,
  required Color muted,
}) {
  final code = base.copyWith(
    fontFamily: 'monospace',
    fontSize: (base.fontSize ?? 14) * 0.92,
    backgroundColor: codeBackground,
  );

  final children = <InlineSpan>[];
  final lines = data.split('\n');
  var inFence = false;

  for (var i = 0; i < lines.length; i++) {
    if (i > 0) children.add(const TextSpan(text: '\n'));
    final line = lines[i];
    final trimmed = line.trimLeft();

    // Fenced code. The fence line itself (and any language tag) is markup,
    // not content, so it is dropped rather than printed.
    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      inFence = !inFence;
      // Drop the newline that was added for this line so closing a fence does
      // not leave a blank gap.
      if (children.isNotEmpty && children.last == const TextSpan(text: '\n')) {
        children.removeLast();
      }
      continue;
    }
    if (inFence) {
      children.add(TextSpan(text: line, style: code));
      continue;
    }

    children.addAll(_blockSpans(line, base, code, muted));
  }

  return TextSpan(style: base, children: children);
}

/// One line of Markdown: heading, list item, quote, rule, or paragraph.
List<InlineSpan> _blockSpans(
  String line,
  TextStyle base,
  TextStyle code,
  Color muted,
) {
  final indent = line.length - line.trimLeft().length;
  final content = line.trimLeft();

  if (content.isEmpty) return [const TextSpan(text: '')];

  // Horizontal rule.
  if (RegExp(r'^(-{3,}|_{3,}|\*{3,})$').hasMatch(content)) {
    return [
      TextSpan(
        text: '─' * 12,
        style: base.copyWith(color: muted),
      ),
    ];
  }

  // Heading. Larger and bolder, scaled off the body size so it still fits a
  // chat bubble.
  final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(content);
  if (heading != null) {
    const scales = [1.34, 1.22, 1.12, 1.06, 1.0, 1.0];
    final level = heading.group(1)!.length;
    final style = base.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: (base.fontSize ?? 14) * scales[level - 1],
      height: 1.5,
    );
    return _inlineSpans(heading.group(2)!, style, code, muted);
  }

  // Blockquote.
  final quote = RegExp(r'^>\s?(.*)$').firstMatch(content);
  if (quote != null) {
    final style = base.copyWith(color: muted, fontStyle: FontStyle.italic);
    return [
      TextSpan(text: '┃ ', style: style),
      ..._inlineSpans(quote.group(1)!, style, code, muted),
    ];
  }

  // Task list, checked before plain bullets since it is a bullet plus a box.
  final task = RegExp(r'^[-*+]\s+\[([ xX])\]\s+(.*)$').firstMatch(content);
  if (task != null) {
    final done = task.group(1)!.toLowerCase() == 'x';
    return [
      TextSpan(text: '${' ' * indent}${done ? '☑' : '☐'}  '),
      ..._inlineSpans(task.group(2)!, base, code, muted),
    ];
  }

  final bullet = RegExp(r'^[-*+]\s+(.*)$').firstMatch(content);
  if (bullet != null) {
    return [
      TextSpan(text: '${' ' * indent}•  '),
      ..._inlineSpans(bullet.group(1)!, base, code, muted),
    ];
  }

  final ordered = RegExp(r'^(\d{1,3})[.)]\s+(.*)$').firstMatch(content);
  if (ordered != null) {
    return [
      TextSpan(
        text: '${' ' * indent}${ordered.group(1)}. ',
        style: base.copyWith(fontWeight: FontWeight.w600),
      ),
      ..._inlineSpans(ordered.group(2)!, base, code, muted),
    ];
  }

  return _inlineSpans(line, base, code, muted);
}

/// Emphasis, code, strikethrough, and links inside one line.
///
/// The underscore forms require a non-word character on both sides so that
/// `snake_case_names` and `file_name.dart` survive unstyled, which is the
/// usual reason a naive renderer mangles model output.
final _inlinePattern = RegExp(
  r'(\*\*|__)(?=\S)(.+?)(?<=\S)\1'
  r'|(?<![\w*])\*(?=[^\s*])((?:[^*]|\*\*)+?)(?<=\S)\*(?![\w*])'
  r'|(?<![\w_])_(?=\S)([^_]+?)(?<=\S)_(?![\w_])'
  r'|`([^`]+)`'
  r'|~~(?=\S)(.+?)(?<=\S)~~'
  r'|\[([^\]]+)\]\((?:[^)\s]*)\)',
);

List<InlineSpan> _inlineSpans(
  String text,
  TextStyle style,
  TextStyle code,
  Color muted, [
  int depth = 0,
]) {
  if (text.isEmpty) return [TextSpan(text: '', style: style)];
  // Emphasis can nest (bold inside a bullet inside italics); a couple of
  // levels covers real output and the cap stops a pathological string from
  // recursing forever.
  if (depth > 4) return [TextSpan(text: text, style: style)];

  final spans = <InlineSpan>[];
  var cursor = 0;

  for (final match in _inlinePattern.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, match.start), style: style),
      );
    }
    cursor = match.end;

    final bold = match.group(2);
    final starItalic = match.group(3);
    final underscoreItalic = match.group(4);
    final inlineCode = match.group(5);
    final strike = match.group(6);
    final link = match.group(7);

    if (bold != null) {
      spans.addAll(
        _inlineSpans(
          bold,
          style.copyWith(fontWeight: FontWeight.w700),
          code,
          muted,
          depth + 1,
        ),
      );
    } else if (starItalic != null || underscoreItalic != null) {
      spans.addAll(
        _inlineSpans(
          starItalic ?? underscoreItalic!,
          style.copyWith(fontStyle: FontStyle.italic),
          code,
          muted,
          depth + 1,
        ),
      );
    } else if (inlineCode != null) {
      spans.add(
        TextSpan(
          text: inlineCode,
          style: code.copyWith(
            color: style.color,
            fontWeight: style.fontWeight,
          ),
        ),
      );
    } else if (strike != null) {
      spans.addAll(
        _inlineSpans(
          strike,
          style.copyWith(decoration: TextDecoration.lineThrough),
          code,
          muted,
          depth + 1,
        ),
      );
    } else if (link != null) {
      // The label only. Nothing here can open a URL, and printing the target
      // would be noise in a chat bubble.
      spans.addAll(
        _inlineSpans(
          link,
          style.copyWith(decoration: TextDecoration.underline),
          code,
          muted,
          depth + 1,
        ),
      );
    }
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: style));
  }
  return spans;
}
