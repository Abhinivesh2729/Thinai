/// The Server page's top card: live status, address, port and Start/Stop.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../l10n/server_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import 'server_widgets.dart';

enum ServerPhase { stopped, starting, running, stopping }

class ServerHeroCard extends StatelessWidget {
  const ServerHeroCard({
    super.key,
    required this.phase,
    required this.port,
    required this.lan,
    required this.error,
    required this.activeModelId,
    required this.onToggle,
    required this.onEditPort,
    required this.onTune,
    required this.onChooseModel,
  });

  final ServerPhase phase;
  final int port;

  /// Whether the running server is bound to the network.
  final bool lan;

  /// The last start failure, shown under the controls until the next try.
  final String? error;
  final String? activeModelId;
  final VoidCallback onToggle;
  final VoidCallback onEditPort;
  final VoidCallback onTune;
  final VoidCallback onChooseModel;

  bool get _running => phase == ServerPhase.running;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = ServerStrings.of(context);
    final url = 'http://127.0.0.1:$port';

    final (title, subtitle) = switch (phase) {
      ServerPhase.running => (
        context.l10n.serverStatusRunning,
        lan ? s.runningLan : s.runningLocal,
      ),
      ServerPhase.starting => (s.starting, s.stoppedHint),
      ServerPhase.stopping => (s.stopping, lan ? s.runningLan : s.runningLocal),
      ServerPhase.stopped => (context.l10n.serverStatusStopped, s.stoppedHint),
    };

    return AnimatedContainer(
      duration: DeskMotion.slow,
      curve: DeskMotion.ease,
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(DeskSize.radiusXL),
        border: Border.all(
          color: _running
              ? DeskColors.green.withValues(alpha: 0.35)
              : palette.hairline,
        ),
        // A faint glow from the orb's corner while serving; gradients lerp,
        // so the card warms up instead of snapping.
        gradient: RadialGradient(
          center: const Alignment(-0.85, -0.6),
          radius: 1.4,
          colors: [
            DeskColors.green.withValues(
              alpha: _running ? (palette.isDark ? 0.14 : 0.08) : 0,
            ),
            palette.panel.withValues(alpha: 0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _running
                ? DeskColors.green.withValues(
                    alpha: palette.isDark ? 0.10 : 0.08,
                  )
                : Colors.black.withValues(alpha: palette.isDark ? 0.0 : 0.03),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            child: LayoutBuilder(
              builder: (context, box) {
                final narrow = box.maxWidth < 620;
                final info = _Info(
                  title: title,
                  subtitle: subtitle,
                  url: url,
                  port: port,
                  canEditPort:
                      phase == ServerPhase.stopped ||
                      phase == ServerPhase.running,
                  onEditPort: onEditPort,
                );
                final button = _StartStopButton(phase: phase, onTap: onToggle);
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusOrb(phase: phase, size: 72),
                          const SizedBox(width: 20),
                          Expanded(child: info),
                        ],
                      ),
                      const SizedBox(height: 20),
                      button,
                    ],
                  );
                }
                return Row(
                  children: [
                    StatusOrb(phase: phase),
                    const SizedBox(width: 28),
                    Expanded(child: info),
                    const SizedBox(width: 24),
                    button,
                  ],
                );
              },
            ),
          ),
          AnimatedSize(
            duration: DeskMotion.medium,
            curve: DeskMotion.ease,
            alignment: Alignment.topCenter,
            child: error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                    child: _ErrorNote(
                      error: error!,
                      port: port,
                      onEditPort: onEditPort,
                    ),
                  ),
          ),
          Container(height: 1, color: palette.hairline),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 14, 20, 14),
            child: _ModelRow(
              activeModelId: activeModelId,
              onTune: onTune,
              onChooseModel: onChooseModel,
              textColor: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.port,
    required this.canEditPort,
    required this.onEditPort,
  });

  final String title, subtitle, url;
  final int port;
  final bool canEditPort;
  final VoidCallback onEditPort;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = ServerStrings.of(context);

    Widget fade(Widget child) => AnimatedSwitcher(
      duration: DeskMotion.medium,
      switchInCurve: DeskMotion.ease,
      switchOutCurve: DeskMotion.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        fade(
          Text(
            title,
            key: ValueKey(title),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: context.tracking(-0.5),
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        fade(
          Text(
            subtitle,
            key: ValueKey(subtitle),
            style: TextStyle(fontSize: 13.5, color: palette.textMuted),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _UrlPill(url: url),
            _PortChip(
              port: port,
              label: s.port,
              tooltip: s.changePort,
              onTap: canEditPort ? onEditPort : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _UrlPill extends StatelessWidget {
  const _UrlPill({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: context.l10n.serverCopyAddressTooltip,
      child: Hoverable(
        cursor: SystemMouseCursors.click,
        builder: (context, hovered) => GestureDetector(
          onTap: () => copyWithToast(context, url, url),
          child: AnimatedContainer(
            duration: DeskMotion.fast,
            padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
            decoration: BoxDecoration(
              color: palette.codeBg,
              borderRadius: BorderRadius.circular(DeskSize.radiusM),
              border: Border.all(
                color: hovered
                    ? DeskColors.green.withValues(alpha: 0.55)
                    : palette.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: DeskMotion.medium,
                  child: Text(
                    url,
                    key: ValueKey(url),
                    style: monoStyle(
                      size: 15,
                      weight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.content_copy_rounded,
                  size: 15,
                  color: hovered ? DeskColors.green : palette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortChip extends StatelessWidget {
  const _PortChip({
    required this.port,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final int port;
  final String label, tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Hoverable(
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, hovered) => GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: DeskMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hovered && onTap != null
                  ? scheme.onSurface.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(DeskSize.radiusM),
              border: Border.all(color: palette.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  '$port',
                  style: monoStyle(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.edit_rounded,
                  size: 13,
                  color: onTap == null
                      ? palette.textFaint.withValues(alpha: 0.5)
                      : hovered
                      ? DeskColors.green
                      : palette.textFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({
    required this.error,
    required this.port,
    required this.onEditPort,
  });

  final String error;
  final int port;
  final VoidCallback onEditPort;

  @override
  Widget build(BuildContext context) {
    final s = ServerStrings.of(context);
    final problem = portProblemOf(error);
    final text = switch (problem) {
      PortProblem.inUse => s.portInUse(port),
      PortProblem.blocked => s.portBlocked(port),
      null => context.l10n.serverToastStartFailed(error),
    };
    return InlineNote(
      icon: Icons.error_outline_rounded,
      text: text,
      color: DeskColors.danger,
      action: problem == null
          ? null
          : TextButton(onPressed: onEditPort, child: Text(s.changePort)),
    );
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({
    required this.activeModelId,
    required this.onTune,
    required this.onChooseModel,
    required this.textColor,
  });

  final String? activeModelId;
  final VoidCallback onTune;
  final VoidCallback onChooseModel;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final s = ServerStrings.of(context);
    final id = activeModelId;
    return AnimatedSwitcher(
      duration: DeskMotion.medium,
      child: Row(
        key: ValueKey(id),
        children: [
          Icon(
            id == null ? Icons.hourglass_empty_rounded : Icons.memory_rounded,
            size: 18,
            color: id == null ? palette.textFaint : DeskColors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: id == null
                ? Text(
                    context.l10n.serverNoModelLoaded,
                    style: TextStyle(fontSize: 13.5, color: palette.textMuted),
                  )
                : Tooltip(
                    message: s.servingHint,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${s.serving}  ',
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.textMuted,
                            ),
                          ),
                          TextSpan(
                            text: id,
                            style: monoStyle(
                              size: 13.5,
                              weight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          id == null
              ? FilledButton.tonalIcon(
                  onPressed: onChooseModel,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(context.l10n.serverBrowseModels),
                )
              : TextButton.icon(
                  onPressed: onTune,
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: Text(context.l10n.serverTune),
                ),
        ],
      ),
    );
  }
}

// ─── start / stop ───────────────────────────────────────────────────────────

class _StartStopButton extends StatefulWidget {
  const _StartStopButton({required this.phase, required this.onTap});
  final ServerPhase phase;
  final VoidCallback onTap;

  @override
  State<_StartStopButton> createState() => _StartStopButtonState();
}

class _StartStopButtonState extends State<_StartStopButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    final busy = phase == ServerPhase.starting || phase == ServerPhase.stopping;
    final running = phase == ServerPhase.running;
    final s = ServerStrings.of(context);

    // Start is the primary green action; Stop is a quieter danger outline,
    // so a running server never looks like it is asking to be stopped.
    final (label, icon) = switch (phase) {
      ServerPhase.stopped => (
        context.l10n.serverStart,
        Icons.play_arrow_rounded,
      ),
      ServerPhase.running => (context.l10n.serverStop, Icons.stop_rounded),
      ServerPhase.starting => (s.starting, null),
      ServerPhase.stopping => (s.stopping, null),
    };
    final danger = running || phase == ServerPhase.stopping;
    final fg = danger ? DeskColors.danger : Colors.white;

    return Hoverable(
      cursor: busy ? SystemMouseCursors.basic : SystemMouseCursors.click,
      builder: (context, hovered) {
        final Color bg;
        if (danger) {
          bg = DeskColors.danger.withValues(
            alpha: hovered && !busy ? 0.16 : 0.10,
          );
        } else if (busy) {
          bg = DeskColors.green.withValues(alpha: 0.7);
        } else {
          bg = hovered ? DeskColors.greenDeep : DeskColors.green;
        }
        return GestureDetector(
          onTapDown: busy ? null : (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: busy ? null : widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: DeskMotion.fast,
            curve: DeskMotion.ease,
            child: AnimatedContainer(
              duration: DeskMotion.medium,
              curve: DeskMotion.ease,
              width: 156,
              height: 52,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(DeskSize.radiusL - 2),
                border: Border.all(
                  color: danger
                      ? DeskColors.danger.withValues(alpha: 0.35)
                      : Colors.transparent,
                ),
                boxShadow: [
                  BoxShadow(
                    color: !danger && !busy
                        ? DeskColors.green.withValues(
                            alpha: hovered ? 0.45 : 0.30,
                          )
                        : Colors.transparent,
                    blurRadius: hovered ? 22 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: DeskMotion.medium,
                switchInCurve: DeskMotion.ease,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.9, end: 1.0).animate(anim),
                    child: child,
                  ),
                ),
                child: Row(
                  key: ValueKey(phase),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null)
                      Icon(icon, size: 22, color: fg)
                    else
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: fg,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── status orb ─────────────────────────────────────────────────────────────

/// Green core with rings rippling out while running; a turning arc while
/// starting or stopping; a still grey core when stopped. The ticker runs
/// only while something moves, so a stopped server costs no frames.
class StatusOrb extends StatefulWidget {
  const StatusOrb({super.key, required this.phase, this.size = 88});
  final ServerPhase phase;
  final double size;

  @override
  State<StatusOrb> createState() => _StatusOrbState();
}

class _StatusOrbState extends State<StatusOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(StatusOrb old) {
    super.didUpdateWidget(old);
    if (old.phase != widget.phase) _sync();
  }

  void _sync() {
    if (widget.phase == ServerPhase.stopped) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final target = switch (widget.phase) {
      ServerPhase.running => DeskColors.green,
      ServerPhase.starting || ServerPhase.stopping => DeskColors.amber,
      ServerPhase.stopped => palette.textFaint,
    };
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: target),
      duration: DeskMotion.slow,
      curve: DeskMotion.ease,
      builder: (context, color, _) => RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _OrbPainter(
            t: _loop,
            color: color ?? target,
            phase: widget.phase,
            track: palette.hairline,
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.t,
    required this.color,
    required this.phase,
    required this.track,
  }) : super(repaint: t);

  final Animation<double> t;
  final Color color;
  final ServerPhase phase;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final core = r * 0.30;

    // Resting ring, always there so the orb keeps its footprint.
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = track,
    );

    switch (phase) {
      case ServerPhase.running:
        // Two ripples half a period apart, easing out as they grow.
        for (final offset in const [0.0, 0.5]) {
          final p = (t.value + offset) % 1.0;
          final e = Curves.easeOut.transform(p);
          canvas.drawCircle(
            c,
            core + (r - core) * e,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = color.withValues(alpha: 0.45 * (1 - p)),
          );
        }
        canvas.drawCircle(
          c,
          core * 1.9,
          Paint()
            ..color = color.withValues(alpha: 0.16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      case ServerPhase.starting || ServerPhase.stopping:
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 0.62),
          t.value * 2 * math.pi * 2,
          math.pi * 0.6,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
      case ServerPhase.stopped:
        break;
    }

    canvas.drawCircle(c, core, Paint()..color = color);
    // A soft highlight so the core reads as a lit bead, not a flat dot.
    canvas.drawCircle(
      c.translate(-core * 0.3, -core * 0.3),
      core * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.color != color || old.phase != phase || old.track != track;
}
