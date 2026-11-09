/// The Speed tab's instruments: the tokens/second dial, the live sparkline
/// and the stat tiles. Each paints in its own RepaintBoundary, so a new token
/// repaints the instrument and nothing around it.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../theme/desk_theme.dart';
import 'lab_common.dart';

// ─── dial ──────────────────────────────────────────────────────────────────

/// Large dial for the live decode rate.
///
/// Both the reading and the scale ease to each new value, so a noisy
/// per-token rate reads as a needle settling rather than a number flickering,
/// and the scale growing mid-run does not make the arc jump backwards.
/// The Lab's one meter. Speed and Tamil score both read on it, so every
/// measurement in the app looks and moves the same way.
class LabGauge extends StatelessWidget {
  const LabGauge({
    super.key,
    required this.value,
    required this.unit,
    required this.running,
    this.peak = 0,
    this.fixedMax,
    this.decimals = 1,
    this.status,
  });

  final double value;
  final String unit;
  final bool running;

  /// Amber marker for the best reading so far; 0 hides it.
  final double peak;

  /// A fixed scale (e.g. 100 for a score). Null scales to [peak].
  final double? fixedMax;
  final int decimals;

  /// Replaces the Ready/Measuring pill (e.g. a verdict).
  final Widget? status;

  /// A round number above the peak, so ticks land on readable values.
  static double scaleFor(double peak) {
    final target = math.max(20.0, peak * 1.2);
    final step = target <= 50 ? 10.0 : (target <= 200 ? 25.0 : 100.0);
    return (target / step).ceil() * step;
  }

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: fixedMax ?? scaleFor(peak)),
        duration: DeskMotion.slow,
        curve: DeskMotion.ease,
        builder: (context, scaleMax, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: DeskMotion.slow,
          curve: DeskMotion.ease,
          builder: (context, shown, _) => CustomPaint(
            painter: _GaugePainter(
              value: shown,
              peak: peak,
              scaleMax: scaleMax,
              track: palette.hairline,
              tickColor: palette.textFaint,
              glow: palette.isDark ? 0.45 : 0.25,
            ),
            child: Align(
              alignment: const Alignment(0, 0.12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    shown.toStringAsFixed(decimals),
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.5,
                      height: 1,
                      color: scheme.onSurface,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  status ?? _StatusPill(running: running),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tokens per second on the [LabGauge].
class SpeedGauge extends StatelessWidget {
  const SpeedGauge({
    super.key,
    required this.tokensPerSecond,
    required this.peak,
    required this.running,
  });

  final double tokensPerSecond;
  final double peak;
  final bool running;

  @override
  Widget build(BuildContext context) => LabGauge(
    value: tokensPerSecond,
    unit: context.l10n.benchmarkTokensPerSecond,
    running: running,
    peak: peak,
  );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.peak,
    required this.scaleMax,
    required this.track,
    required this.tickColor,
    required this.glow,
  });

  final double value;
  final double peak;
  final double scaleMax;
  final Color track;
  final Color tickColor;
  final double glow;

  // Tick labels are laid out once and kept. Building and disposing them
  // inside paint() every frame both wasted time and freed paragraphs the
  // frame being recorded could still reference.
  static final _labels = <String, TextPainter>{};

  TextPainter _label(String text) {
    final key = '$text|${tickColor.toARGB32()}';
    return _labels.putIfAbsent(key, () {
      if (_labels.length > 200) _labels.clear();
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 10,
            color: tickColor,
            fontWeight: FontWeight.w600,
            fontFeatures: tabularFigures,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  // 240 degrees with the gap at the bottom: wide enough to read as a dial,
  // open enough to leave room for the status pill under the number.
  static const _start = math.pi * (150 / 180);
  static const _sweep = math.pi * (240 / 180);
  static const _stroke = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width / 2, size.height / 1.82) - 26;
    if (radius <= 40) return;
    final center = Offset(size.width / 2, 26 + radius + _stroke / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final fraction = (value / scaleMax).clamp(0.0, 1.0);

    canvas.drawArc(
      rect,
      _start,
      _sweep,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round,
    );

    if (fraction > 0.002) {
      final shader = const SweepGradient(
        colors: [DeskColors.greenDeep, DeskColors.green, DeskColors.mint],
        stops: [0, 0.55, 1],
        startAngle: 0,
        endAngle: _sweep,
        transform: GradientRotation(_start),
      ).createShader(rect);
      // A soft copy underneath gives the arc a glow without a second colour.
      canvas.drawArc(
        rect,
        _start,
        _sweep * fraction,
        false,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke + 6
          ..strokeCap = StrokeCap.round
          ..color = Color.fromRGBO(0, 0, 0, glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawArc(
        rect,
        _start,
        _sweep * fraction,
        false,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Ticks outside the ring with labels on the major ones, so the dial is a
    // measurement, not a decoration.
    final tick = Paint()
      ..color = tickColor
      ..strokeCap = StrokeCap.round;
    const minor = 40;
    for (var i = 0; i <= minor; i++) {
      final angle = _start + _sweep * (i / minor);
      final major = i % 10 == 0;
      final inner = radius + _stroke / 2 + 5;
      final outer = inner + (major ? 8 : 4);
      tick.strokeWidth = major ? 2 : 1;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center + dir * inner, center + dir * outer, tick);
      if (major) {
        final label = _label((scaleMax * i / minor).round().toString());
        final at = center + dir * (outer + 12);
        label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
      }
    }

    // Peak marker: where the run topped out, so a reading that fell back
    // still shows what the model managed.
    if (peak > 0) {
      final pf = (peak / scaleMax).clamp(0.0, 1.0);
      final angle = _start + _sweep * pf;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * (radius - _stroke / 2 - 2),
        center + dir * (radius + _stroke / 2 + 2),
        Paint()
          ..color = DeskColors.amber
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    final angle = _start + _sweep * fraction;
    final knob = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(
      knob,
      13,
      Paint()..color = DeskColors.mint.withValues(alpha: 0.22),
    );
    canvas.drawCircle(knob, 7, Paint()..color = DeskColors.mint);
    canvas.drawCircle(knob, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value ||
      old.peak != peak ||
      old.scaleMax != scaleMax ||
      old.track != track ||
      old.tickColor != tickColor;
}

/// "Ready", or a breathing "Measuring" while a run is in flight.
class _StatusPill extends StatefulWidget {
  const _StatusPill({required this.running});

  final bool running;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with TickerProviderStateMixin {
  // Built per run and dropped after: an idle repeating controller would drive
  // frames forever for an indicator nobody is looking at. Not the Single
  // mixin, because each run creates a fresh ticker.
  AnimationController? _controller;

  AnimationController get _c => _controller ??= AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(_StatusPill old) {
    super.didUpdateWidget(old);
    if (!widget.running && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final running = widget.running;
    final color = running ? DeskColors.green : palette.textMuted;
    final label = running
        ? context.l10n.benchmarkMeasuring
        : context.l10n.benchmarkIdle;
    Widget dot(double t) => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: running ? 0.35 + 0.65 * t : 0.6),
      ),
    );
    return AnimatedContainer(
      duration: DeskMotion.medium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (running)
            AnimatedBuilder(animation: _c, builder: (_, _) => dot(_c.value))
          else
            dot(1),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: context.tracking(1),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── sparkline ─────────────────────────────────────────────────────────────

/// Windowed throughput over the run as a smooth filled curve. The vertical
/// scale eases as the peak grows, so the line never snaps.
class SpeedSparkline extends StatelessWidget {
  const SpeedSparkline({
    super.key,
    required this.samples,
    required this.running,
  });

  final List<double> samples;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    if (samples.length < 2) {
      return Center(
        child: Text(
          running
              ? context.l10n.benchmarkWarmingUp
              : context.l10n.benchmarkPlotEmpty,
          style: TextStyle(fontSize: 12.5, color: palette.textFaint),
        ),
      );
    }
    final top = samples.reduce(math.max) * 1.15;
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: top),
        duration: DeskMotion.medium,
        curve: DeskMotion.ease,
        builder: (context, scaleTop, _) => CustomPaint(
          size: Size.infinite,
          painter: _SparklinePainter(
            samples: samples,
            top: scaleTop,
            grid: palette.hairline,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.samples,
    required this.top,
    required this.grid,
  });

  final List<double> samples;
  final double top;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (top <= 0) return;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final step = size.width / (samples.length - 1);
    final points = [
      for (var i = 0; i < samples.length; i++)
        Offset(
          step * i,
          size.height - (samples[i] / top).clamp(0.0, 1.0) * size.height,
        ),
    ];

    // Midpoint quadratic smoothing: passes near every sample without the
    // overshoot a cubic spline gives on a sudden drop.
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final mid = Offset(
        (prev.dx + points[i].dx) / 2,
        (prev.dy + points[i].dy) / 2,
      );
      line.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    line.lineTo(points.last.dx, points.last.dy);

    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DeskColors.green.withValues(alpha: 0.32),
            DeskColors.green.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = DeskColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final last = points.last;
    canvas.drawCircle(
      last,
      7,
      Paint()..color = DeskColors.mint.withValues(alpha: 0.25),
    );
    canvas.drawCircle(last, 3.5, Paint()..color = DeskColors.mint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.samples.length != samples.length ||
      (samples.isNotEmpty && old.samples.last != samples.last) ||
      old.top != top ||
      old.grid != grid;
}

// ─── stat tile ─────────────────────────────────────────────────────────────

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Optional 0 to 1 bar under the value, e.g. tokens out of 128.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.canvas,
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: DeskColors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: palette.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: scheme.onSurface,
              fontFeatures: tabularFigures,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(end: progress!.clamp(0.0, 1.0)),
              duration: DeskMotion.medium,
              curve: DeskMotion.ease,
              builder: (context, t, _) => ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: t,
                  minHeight: 3,
                  color: DeskColors.green,
                  backgroundColor: palette.hairline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
