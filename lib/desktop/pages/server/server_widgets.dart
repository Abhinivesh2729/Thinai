/// Building blocks shared by the Server page cards.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import '../../widgets/toast.dart';

/// No mono font ships with the app, so lean on what each OS has: Cascadia
/// Mono and Consolas on Windows, SF Mono / Menlo on macOS.
const _monoFamily = 'Cascadia Mono';
const _monoFallback = [
  'Consolas',
  'SF Mono',
  'Menlo',
  'DejaVu Sans Mono',
  'monospace',
];

TextStyle monoStyle({
  double size = 13,
  Color? color,
  FontWeight weight = FontWeight.w400,
  double height = 1.5,
}) => TextStyle(
  fontFamily: _monoFamily,
  fontFamilyFallback: _monoFallback,
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: height,
);

/// Copies [text] and confirms with a toast naming [label].
void copyWithToast(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  showDeskToast(context.l10n.serverCopiedLabel(label), tone: DeskTone.success);
}

/// Enough of a token to tell keys apart without revealing it.
String maskToken(String token) => token.length <= 8
    ? '••••••'
    : '${token.substring(0, 4)}••••••${token.substring(token.length - 4)}';

// ─── port problems ──────────────────────────────────────────────────────────

enum PortProblem { inUse, blocked }

/// Reads a bind failure out of the server's error text. The controller only
/// keeps `e.toString()`, so this matches the OS error codes: EADDRINUSE is
/// 48 on macOS, 98 on Linux and 10048 on Windows; 10013 is Windows refusing
/// a port inside a reserved (Hyper-V / WSL) range.
PortProblem? portProblemOf(String? error) {
  if (error == null) return null;
  final e = error.toLowerCase();
  if (RegExp(r'errno = (48|98|10048)\b').hasMatch(e) ||
      e.contains('already in use') ||
      e.contains('only one usage of each socket address')) {
    return PortProblem.inUse;
  }
  if (RegExp(r'errno = (13|10013)\b').hasMatch(e) ||
      e.contains('forbidden by its access permissions')) {
    return PortProblem.blocked;
  }
  return null;
}

/// Tries the bind the server would make, so the port editor can refuse a
/// taken port before the user hits Start.
Future<PortProblem?> probePort(int port, {required bool lan}) async {
  try {
    final socket = await ServerSocket.bind(
      lan ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4,
      port,
    );
    await socket.close();
    return null;
  } on SocketException catch (e) {
    return portProblemOf(e.toString()) ?? PortProblem.inUse;
  }
}

// ─── cards ──────────────────────────────────────────────────────────────────

/// A page section: panel surface, hairline border, optional header.
class ServerCard extends StatelessWidget {
  const ServerCard({
    super.key,
    required this.child,
    this.icon,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(DeskSize.radiusL),
        border: Border.all(color: palette.hairline),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DeskColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(DeskSize.radiusM),
                    ),
                    child: Icon(icon, size: 18, color: DeskColors.green),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 16), trailing!],
              ],
            ),
            const SizedBox(height: 20),
          ],
          child,
        ],
      ),
    );
  }
}

/// Small caps-free label above a value.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: DeskPalette.of(context).textMuted,
      ),
    ),
  );
}

/// A mono value in a code-tinted well, copied with one click anywhere on it.
class CopyField extends StatelessWidget {
  const CopyField({
    super.key,
    required this.label,
    required this.value,
    this.copyValue,
    this.copyLabel,
    this.dimmed = false,
  });

  final String label;
  final String value;

  /// What goes on the clipboard when it differs from what is shown (masked
  /// tokens).
  final String? copyValue;
  final String? copyLabel;

  /// For placeholders that are not worth copying.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final onCopy = dimmed
        ? null
        : () => copyWithToast(context, copyValue ?? value, copyLabel ?? label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        Hoverable(
          cursor: onCopy == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          builder: (context, hovered) => GestureDetector(
            onTap: onCopy,
            child: AnimatedContainer(
              duration: DeskMotion.fast,
              curve: DeskMotion.ease,
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                color: palette.codeBg,
                borderRadius: BorderRadius.circular(DeskSize.radiusM),
                border: Border.all(
                  color: hovered && onCopy != null
                      ? DeskColors.green.withValues(alpha: 0.5)
                      : palette.hairline,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: DeskMotion.medium,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: Text(
                        value,
                        key: ValueKey(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: monoStyle(
                          size: 13.5,
                          color: dimmed ? palette.textFaint : scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  DeskIconButton(
                    icon: Icons.content_copy_rounded,
                    tooltip: context.l10n.commonCopy,
                    iconSize: 15,
                    size: 30,
                    color: hovered ? DeskColors.green : null,
                    onPressed: onCopy,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A row of pill tabs; the selected one fills in.
class PillTabs extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.dense = false,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.codeBg,
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            Hoverable(
              cursor: SystemMouseCursors.click,
              builder: (context, hovered) {
                final selected = i == index;
                return GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: DeskMotion.medium,
                    curve: DeskMotion.ease,
                    padding: EdgeInsets.symmetric(
                      horizontal: dense ? 10 : 14,
                      vertical: dense ? 5 : 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? palette.panelRaised
                          : hovered
                          ? scheme.onSurface.withValues(alpha: 0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(DeskSize.radiusS),
                      border: Border.all(
                        color: selected ? palette.hairline : Colors.transparent,
                      ),
                      boxShadow: selected && !palette.isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: DeskMotion.medium,
                      style: TextStyle(
                        fontSize: dense ? 12 : 12.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? scheme.onSurface : palette.textMuted,
                      ),
                      child: Text(labels[i]),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// An HTTP method badge: GET in blue, POST in green.
class MethodBadge extends StatelessWidget {
  const MethodBadge(this.method, {super.key});
  final String method;

  @override
  Widget build(BuildContext context) {
    final color = method == 'GET' ? const Color(0xFF3B82F6) : DeskColors.green;
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        method,
        style: monoStyle(size: 11, color: color, weight: FontWeight.w700),
      ),
    );
  }
}

/// A one-line note with an icon, tinted by tone.
class InlineNote extends StatelessWidget {
  const InlineNote({
    super.key,
    required this.icon,
    required this.text,
    this.color,
    this.action,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final tint = color ?? palette.textMuted;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: color == null ? 0.06 : 0.09),
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: color ?? palette.textMuted,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 10), action!],
        ],
      ),
    );
  }
}

// ─── code block ─────────────────────────────────────────────────────────────

/// A code sample: highlighted, selectable, scrolls sideways, copy button.
class CodeBlock extends StatefulWidget {
  const CodeBlock({
    super.key,
    required this.code,
    this.copyCode,
    this.filename,
    this.language = 'bash',
  });

  final String code;

  /// The clipboard text when it differs from [code] (masked tokens).
  final String? copyCode;
  final String? filename;
  final String language;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: widget.copyCode ?? widget.code),
    );
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final colors = _SyntaxColors.of(palette.isDark);
    return Container(
      decoration: BoxDecoration(
        color: palette.codeBg,
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.hairline)),
            ),
            child: Row(
              children: [
                Text(
                  widget.filename ?? widget.language,
                  style: monoStyle(size: 12, color: palette.textMuted),
                ),
                const Spacer(),
                Hoverable(
                  cursor: SystemMouseCursors.click,
                  builder: (context, hovered) => GestureDetector(
                    onTap: _copy,
                    child: AnimatedContainer(
                      duration: DeskMotion.fast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: hovered || _copied
                            ? DeskColors.green.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(DeskSize.radiusS),
                      ),
                      child: AnimatedSwitcher(
                        duration: DeskMotion.medium,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween(begin: 0.85, end: 1.0).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Row(
                          key: ValueKey(_copied),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _copied
                                  ? Icons.check_rounded
                                  : Icons.content_copy_rounded,
                              size: 14,
                              color: _copied || hovered
                                  ? DeskColors.green
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.commonCopy,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _copied || hovered
                                    ? DeskColors.green
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: SelectableText.rich(
              TextSpan(
                style: monoStyle(size: 13, color: colors.plain, height: 1.6),
                children: _highlight(widget.code, widget.language, colors),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyntaxColors {
  const _SyntaxColors({
    required this.plain,
    required this.string,
    required this.keyword,
    required this.number,
    required this.comment,
    required this.key,
  });

  final Color plain, string, keyword, number, comment, key;

  static _SyntaxColors of(bool dark) => dark ? _dark : _light;

  static const _dark = _SyntaxColors(
    plain: Color(0xFFD4DAE3),
    string: Color(0xFF86EFAC),
    keyword: Color(0xFFC4A7FF),
    number: Color(0xFFFBBF77),
    comment: Color(0xFF5B6778),
    key: Color(0xFF7DD3FC),
  );

  static const _light = _SyntaxColors(
    plain: Color(0xFF1E293B),
    string: Color(0xFF15803D),
    keyword: Color(0xFF7C3AED),
    number: Color(0xFFC2410C),
    comment: Color(0xFF94A3B8),
    key: Color(0xFF0369A1),
  );
}

const _keywords = {
  'python': {'from', 'import', 'print', 'await', 'as', 'def', 'return'},
  'javascript': {'import', 'from', 'const', 'await', 'new', 'console'},
  'bash': {'curl', 'export'},
  'yaml': <String>{},
  'json': {'true', 'false', 'null'},
};

/// A deliberately small highlighter: strings, comments, numbers, keywords
/// and object keys. Enough to make samples scannable without a dependency.
List<TextSpan> _highlight(String code, String language, _SyntaxColors c) {
  final keywords = _keywords[language] ?? const <String>{};
  final comment = language == 'javascript' ? r'//[^\n]*' : r'#[^\n]*';
  final pattern = RegExp(
    '($comment)' // 1 comment
    r'|("(?:\\.|[^"\\])*"\s*:)' // 2 JSON / JS key
    r'|("(?:\\.|[^"\\])*"' // 3 string
    r"|'(?:\\.|[^'\\])*')"
    r'|(^\s*(?:-\s+)?[A-Za-z_][\w-]*:(?=\s))' // 4 YAML / JS key
    r'|(\b\d+(?:\.\d+)?\b)' // 5 number
    r'|(\b[A-Za-z_]\w*\b)', // 6 word
    multiLine: true,
  );
  final spans = <TextSpan>[];
  var last = 0;
  for (final m in pattern.allMatches(code)) {
    if (m.start > last) {
      spans.add(TextSpan(text: code.substring(last, m.start)));
    }
    final text = m[0]!;
    Color? color;
    if (m[1] != null) {
      color = c.comment;
    } else if (m[2] != null) {
      color = c.key;
    } else if (m[3] != null) {
      // A single-quoted shell body (curl -d '...') is JSON, not a string.
      color = language == 'bash' && text.startsWith("'") ? null : c.string;
    } else if (m[4] != null) {
      color = language == 'yaml' || language == 'javascript' ? c.key : null;
    } else if (m[5] != null) {
      color = c.number;
    } else if (m[6] != null && keywords.contains(text)) {
      color = c.keyword;
    }
    if (color == null && m[3] != null && language == 'bash') {
      // Highlight the JSON inside the quotes instead.
      spans.add(const TextSpan(text: "'"));
      spans.addAll(_highlight(text.substring(1, text.length - 1), 'json', c));
      spans.add(const TextSpan(text: "'"));
    } else {
      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(color: color),
        ),
      );
    }
    last = m.end;
  }
  if (last < code.length) spans.add(TextSpan(text: code.substring(last)));
  return spans;
}
