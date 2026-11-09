/// One message in the desktop transcript.
///
/// Streaming cost is the thing to beat: a reply is re-parsed on every frame
/// it grows. [StreamingMarkdown] splits the text into blocks (paragraphs,
/// lists, fenced code) and reuses the widget for every block that has not
/// changed, so only the last, growing block is laid out again. A 2,000-word
/// answer streams as cheaply as a sentence.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/providers.dart';
import '../../ui/widgets/markdown_text.dart';
import '../../web/web_search.dart';
import '../l10n/desk_l10n.dart';
import '../theme/desk_theme.dart';
import '../widgets/hover.dart';
import '../widgets/toast.dart';

/// Splits Markdown into top-level blocks at blank lines, never inside a
/// fenced code block.
List<String> splitMarkdownBlocks(String text) {
  final blocks = <String>[];
  final buf = StringBuffer();
  var inFence = false;
  for (final line in text.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      inFence = !inFence;
    }
    if (!inFence && line.trim().isEmpty) {
      if (buf.isNotEmpty) {
        blocks.add(buf.toString());
        buf.clear();
      }
      continue;
    }
    if (buf.isNotEmpty) buf.write('\n');
    buf.write(line);
  }
  if (buf.isNotEmpty) blocks.add(buf.toString());
  return blocks;
}

class StreamingMarkdown extends StatefulWidget {
  const StreamingMarkdown({
    super.key,
    required this.text,
    required this.style,
    this.streaming = false,
  });

  final String text;
  final TextStyle style;
  final bool streaming;

  @override
  State<StreamingMarkdown> createState() => _StreamingMarkdownState();
}

class _StreamingMarkdownState extends State<StreamingMarkdown> {
  List<String> _blocks = const [];
  List<Widget> _widgets = const [];
  TextStyle? _style;
  Brightness? _brightness;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final brightness = Theme.of(context).brightness;
    final blocks = splitMarkdownBlocks(widget.text);
    final styleChanged = _style != widget.style || _brightness != brightness;
    final widgets = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final last = i == blocks.length - 1;
      final reusable =
          !styleChanged &&
          !last &&
          i < _blocks.length &&
          _blocks[i] == blocks[i] &&
          i < _widgets.length;
      widgets.add(
        reusable
            ? _widgets[i]
            : Padding(
                key: ValueKey('b$i'),
                padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                child: MarkdownText(
                  data: blocks[i],
                  style: widget.style,
                  selectable: false,
                  codeBackground: palette.codeBg,
                  mutedColor: palette.textMuted,
                  streamingCursor: widget.streaming && last,
                  cursorColor: DeskColors.mint,
                ),
              ),
      );
    }
    _blocks = blocks;
    _widgets = widgets;
    _style = widget.style;
    _brightness = brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class DeskMessage extends StatelessWidget {
  const DeskMessage({
    super.key,
    required this.turn,
    this.streaming = false,
    this.searching = false,
    this.footer,
  });

  final ChatTurn turn;
  final bool streaming;
  final bool searching;

  /// Shown under an assistant reply (e.g. speed), when not streaming.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return turn.role == 'user'
        ? _UserMessage(text: turn.content)
        : _AssistantMessage(
            turn: turn,
            streaming: streaming,
            searching: searching,
            footer: footer,
          );
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: palette.userBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DeskSize.radiusL),
                topRight: Radius.circular(DeskSize.radiusL),
                bottomLeft: Radius.circular(DeskSize.radiusL),
                bottomRight: Radius.circular(6),
              ),
              border: Border.all(
                color: DeskColors.green.withValues(
                  alpha: palette.isDark ? 0.22 : 0.18,
                ),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({
    required this.turn,
    required this.streaming,
    required this.searching,
    this.footer,
  });

  final ChatTurn turn;
  final bool streaming;
  final bool searching;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = ShellStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final empty = turn.content.isEmpty;
    final style = TextStyle(
      fontSize: 15,
      height: 1.65,
      color: scheme.onSurface,
    );

    return Hoverable(
      builder: (context, hovered) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (empty && streaming)
              _Waiting(label: searching ? s.searching : s.thinking)
            else if (empty)
              Text(
                s.stopped,
                style: style.copyWith(
                  fontStyle: FontStyle.italic,
                  color: palette.textMuted,
                ),
              )
            else
              StreamingMarkdown(
                text: turn.content,
                style: style,
                streaming: streaming,
              ),
            if (!streaming && !empty)
              AnimatedOpacity(
                duration: DeskMotion.fast,
                opacity: hovered ? 1 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      DeskIconButton(
                        icon: Icons.content_copy_rounded,
                        tooltip: s.copy,
                        size: 30,
                        iconSize: 15,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: turn.content),
                          );
                          showDeskToast(s.copied, tone: DeskTone.success);
                        },
                      ),
                      if (footer != null) ...[
                        const SizedBox(width: 8),
                        footer!,
                      ],
                    ],
                  ),
                ),
              ),
            if (turn.sources.isNotEmpty) _Sources(sources: turn.sources),
          ],
        ),
      ),
    );
  }
}

class _Waiting extends StatefulWidget {
  const _Waiting({required this.label});
  final String label;

  @override
  State<_Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<_Waiting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // A soft highlight sweeping across the label: "working on it".
        final t = _c.value;
        return ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(-1 + 3 * t - 1, 0),
            end: Alignment(-1 + 3 * t, 0),
            colors: [palette.textFaint, DeskColors.mint, palette.textFaint],
          ).createShader(rect),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _Sources extends StatelessWidget {
  const _Sources({required this.sources});
  final List<WebResult> sources;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < sources.length; i++)
            Tooltip(
              message: '${sources[i].title}\n${sources[i].url}',
              child: Hoverable(
                cursor: SystemMouseCursors.click,
                builder: (context, hovered) => GestureDetector(
                  onTap: () => launchUrl(
                    Uri.parse(sources[i].url),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: AnimatedContainer(
                    duration: DeskMotion.fast,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: hovered ? palette.panelRaised : palette.panel,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: DeskColors.green.withValues(
                            alpha: 0.18,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: DeskColors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            Uri.tryParse(
                                  sources[i].url,
                                )?.host.replaceFirst('www.', '') ??
                                sources[i].title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
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
    );
  }
}
