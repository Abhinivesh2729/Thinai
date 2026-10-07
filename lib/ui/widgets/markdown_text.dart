import 'package:flutter/material.dart';

/// Renders the small slice of Markdown that models actually emit.
///
/// Not a general Markdown implementation: no tables, images, or reference
/// links. It covers what shows up in chat replies, and anything it does not
/// understand falls through as plain text rather than disappearing.
///
/// Everything is built into a single [TextSpan] tree so a reply stays
/// selectable end to end. Splitting blocks into separate widgets would break
/// selection at every paragraph.
class MarkdownText extends StatelessWidget {
  const MarkdownText({
    super.key,
    required this.data,
    required this.style,
    this.codeBackground,
    this.mutedColor,
    this.selectable = true,
    this.streamingCursor = false,
    this.cursorColor,
  });

  final String data;
  final TextStyle style;

  /// Fill behind inline and fenced code. Defaults to a light wash of the
  /// text colour, which works on both bubble tints.
  final Color? codeBackground;

  /// Colour for quotes and rules. Defaults to the text colour at 60%.
  final Color? mutedColor;

  final bool selectable;

  /// Whether to render a breathing ChatGPT-style cursor at the end of the text.
  final bool streamingCursor;

  /// Colour for the streaming cursor.
  final Color? cursorColor;

  @override
  Widget build(BuildContext context) {
    final span = buildMarkdownSpan(
      data,
      base: style,
      codeBackground:
          codeBackground ??
          (style.color ?? const Color(0xFF000000)).withValues(alpha: 0.10),
      muted:
          mutedColor ??
          (style.color ?? const Color(0xFF000000)).withValues(alpha: 0.62),
      streamingCursor: streamingCursor,
      cursorColor: cursorColor ?? style.color ?? const Color(0xFF2CA048),
    );
    return (selectable && !streamingCursor)
        ? SelectableText.rich(span)
        : Text.rich(span);
  }
}

/// Parses [data] into a span tree. Split out from the widget so it can be
/// tested without pumping a frame.
TextSpan buildMarkdownSpan(
  String data, {
  required TextStyle base,
  required Color codeBackground,
  required Color muted,
  bool streamingCursor = false,
  Color? cursorColor,
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

  if (streamingCursor) {
    children.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _StreamingBlinkingCursor(
          color: cursorColor ?? base.color ?? const Color(0xFF2CA048),
        ),
      ),
    );
  }

  return TextSpan(style: base, children: children);
}

/// Smooth breathing cursor block similar to ChatGPT's streaming indicator.
class _StreamingBlinkingCursor extends StatefulWidget {
  final Color color;
  const _StreamingBlinkingCursor({required this.color});

  @override
  State<_StreamingBlinkingCursor> createState() =>
      _StreamingBlinkingCursorState();
}

class _StreamingBlinkingCursorState extends State<_StreamingBlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
      child: Container(
        width: 8,
        height: 15,
        margin: const EdgeInsets.only(left: 3),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
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
      spans.add(TextSpan(text: text.substring(cursor, match.start), style: style));
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
