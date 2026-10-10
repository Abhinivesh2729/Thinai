import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Renders Markdown emitted by LLM models with rich structured code blocks,
/// language tags, one-tap copy actions, headings, lists, quotes, and inline code.
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

  /// Fill behind inline code tags.
  final Color? codeBackground;

  /// Colour for quotes and rules. Defaults to the text colour at 60%.
  final Color? mutedColor;

  final bool selectable;

  /// Whether to render a breathing ChatGPT-style cursor at the end of streaming text.
  final bool streamingCursor;

  /// Colour for the streaming cursor.
  final Color? cursorColor;

  @override
  Widget build(BuildContext context) {
    final effectiveCodeBg = codeBackground ??
        (style.color ?? const Color(0xFF000000)).withValues(alpha: 0.10);
    final effectiveMuted = mutedColor ??
        (style.color ?? const Color(0xFF000000)).withValues(alpha: 0.62);
    final effectiveCursor = cursorColor ?? style.color ?? const Color(0xFF2CA048);

    final blocks = _parseBlocks(data, streamingCursor);

    // If there are no fenced code blocks, render a single span tree for efficiency
    if (blocks.isEmpty || (blocks.length == 1 && blocks.first.type == _BlockType.text)) {
      final span = buildMarkdownSpan(
        data,
        base: style,
        codeBackground: effectiveCodeBg,
        muted: effectiveMuted,
        streamingCursor: streamingCursor,
        cursorColor: effectiveCursor,
      );
      return (selectable && !streamingCursor)
          ? SelectableText.rich(span)
          : Text.rich(span);
    }

    // When code blocks exist, render structured code cards with headers & copy buttons
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (blocks[i].type == _BlockType.text && blocks[i].content.trim().isNotEmpty) ...[
            if (i > 0) const SizedBox(height: 6),
            Builder(builder: (ctx) {
              final isLastBlock = i == blocks.length - 1;
              final span = buildMarkdownSpan(
                blocks[i].content,
                base: style,
                codeBackground: effectiveCodeBg,
                muted: effectiveMuted,
                streamingCursor: isLastBlock && streamingCursor,
                cursorColor: effectiveCursor,
              );
              return (selectable && !streamingCursor)
                  ? SelectableText.rich(span)
                  : Text.rich(span);
            }),
            if (i < blocks.length - 1) const SizedBox(height: 6),
          ] else if (blocks[i].type == _BlockType.code) ...[
            _StructuredCodeBlock(
              code: blocks[i].content,
              language: blocks[i].language ?? 'code',
              isStreaming: blocks[i].isStreaming,
              cursorColor: effectiveCursor,
            ),
          ],
        ],
      ],
    );
  }
}

enum _BlockType { text, code }

class _MarkdownBlock {
  final _BlockType type;
  final String content;
  final String? language;
  final bool isStreaming;

  const _MarkdownBlock({
    required this.type,
    required this.content,
    this.language,
    this.isStreaming = false,
  });
}

/// Parses raw markdown content into alternating text and fenced code blocks.
List<_MarkdownBlock> _parseBlocks(String data, bool streamingCursor) {
  final blocks = <_MarkdownBlock>[];
  final lines = data.split('\n');
  var inCode = false;
  String? currentLang;
  final currentLines = <String>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      if (!inCode) {
        if (currentLines.isNotEmpty) {
          final text = currentLines.join('\n');
          if (text.isNotEmpty) {
            blocks.add(_MarkdownBlock(type: _BlockType.text, content: text));
          }
          currentLines.clear();
        }
        inCode = true;
        final fence = trimmed.startsWith('```') ? '```' : '~~~';
        currentLang = trimmed.substring(fence.length).trim();
        if (currentLang.isEmpty) currentLang = 'code';
      } else {
        inCode = false;
        final codeText = currentLines.join('\n');
        blocks.add(_MarkdownBlock(
          type: _BlockType.code,
          content: codeText,
          language: currentLang ?? 'code',
          isStreaming: false,
        ));
        currentLines.clear();
        currentLang = null;
      }
    } else {
      currentLines.add(line);
    }
  }

  if (currentLines.isNotEmpty) {
    if (inCode) {
      final codeText = currentLines.join('\n');
      blocks.add(_MarkdownBlock(
        type: _BlockType.code,
        content: codeText,
        language: currentLang ?? 'code',
        isStreaming: streamingCursor,
      ));
    } else {
      final text = currentLines.join('\n');
      if (text.isNotEmpty) {
        blocks.add(_MarkdownBlock(type: _BlockType.text, content: text));
      }
    }
  }

  return blocks;
}

/// Beautiful, high-contrast, structured code block widget with language tag,
/// tactile copy button, horizontal scrolling, and monospaced typography.
class _StructuredCodeBlock extends StatefulWidget {
  final String code;
  final String language;
  final bool isStreaming;
  final Color? cursorColor;

  const _StructuredCodeBlock({
    required this.code,
    required this.language,
    this.isStreaming = false,
    this.cursorColor,
  });

  @override
  State<_StructuredCodeBlock> createState() => _StructuredCodeBlockState();
}

class _StructuredCodeBlockState extends State<_StructuredCodeBlock> {
  bool _copied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyCode() async {
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayLang = widget.language.isEmpty || widget.language.toLowerCase() == 'code'
        ? 'CODE'
        : widget.language.toUpperCase();

    const bgCard = Color(0xFF0F172A); // Modern dark IDE canvas
    const bgHeader = Color(0xFF1E293B);
    const borderCard = Color(0xFF334155);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCard, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar with Language tag & Copy Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            color: bgHeader,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.terminal_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayLang,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _copyCode,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 13,
                          color: _copied ? const Color(0xFF4ADE80) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _copied ? 'Copied!' : 'Copy',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _copied ? const Color(0xFF4ADE80) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Horizontally Scrollable Monospaced Code
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: widget.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.0,
                      height: 1.5,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                  if (widget.isStreaming)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _StreamingBlinkingCursor(
                        color: widget.cursorColor ?? const Color(0xFF2CA048),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
