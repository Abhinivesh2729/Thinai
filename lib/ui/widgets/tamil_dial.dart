import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Score fractions where the colour scale changes: below [kTamilLowEnd] is
/// little Tamil, below [kTamilMidEnd] basic, and above it fair or better.
/// The dial's band, the verdict and every score bar use the same scale.
const kTamilLowEnd = 0.2;
const kTamilMidEnd = 0.45;

const _amber = Color(0xFFE0A526);

/// Red, amber or green for a score [fraction] from 0 to 1.
Color tamilScoreColor(ColorScheme scheme, double fraction) {
  if (fraction >= kTamilMidEnd) return scheme.primary;
  if (fraction >= kTamilLowEnd) return _amber;
  return scheme.error;
}

/// What the needle on a [TamilDial] is showing.
enum TamilDialMode {
  /// Share of the questions answered so far.
  progress,

  /// The Tamil score, from 0 to 100.
  score,
}

/// An instrument-style dial: a full face with a 240 degree scale, a tapered
/// needle, and a hub that carries the letter த.
///
/// The needle eases to each new reading. Moving from progress to a score it
/// sweeps with a slight overshoot, the way a gauge needle settles, which is
/// the one moment on the page that is allowed some character.
class TamilDial extends StatelessWidget {
  const TamilDial({
    super.key,
    required this.value,
    required this.mode,
    required this.readout,
    required this.caption,
  });

  /// Needle position, from 0 to 1.
  final double value;

  final TamilDialMode mode;

  /// Large text below the hub, ex. `23/60` or `72`.
  final String readout;

  /// Small text under [readout].
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isScore = mode == TamilDialMode.score;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Square, but never so large that the dial pushes the controls off a
        // small phone's first screen.
        final side = math.min(width, 300.0);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: TweenAnimationBuilder<double>(
              // Begins at 0 so a saved score sweeps up when the page opens.
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: isScore
                  ? const Duration(milliseconds: 1300)
                  : const Duration(milliseconds: 650),
              curve: isScore ? Curves.easeOutBack : Curves.easeOutCubic,
              builder: (context, needle, _) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: isScore ? 1 : 0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, band, _) => CustomPaint(
                    painter: _DialPainter(
                      needle: needle,
                      band: band,
                      face: scheme.surfaceContainerLow,
                      faceCenter: scheme.surfaceContainer,
                      bezel: scheme.outline,
                      ink: scheme.onSurface,
                      muted: scheme.onSurfaceVariant,
                      // A score is drawn in its own colour, so the needle
                      // says the verdict before the number is read.
                      accent: isScore
                          ? tamilScoreColor(scheme, value)
                          : scheme.primary,
                      high: scheme.primary,
                      low: scheme.error,
                      mid: _amber,
                      hub: scheme.surfaceContainerHigh,
                      numeral: TextStyle(
                        fontSize: side * 0.038,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    child: _Readout(
                      side: side,
                      readout: readout,
                      caption: caption,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// The number and its caption, in the open bottom of the scale.
class _Readout extends StatelessWidget {
  const _Readout({
    required this.side,
    required this.readout,
    required this.caption,
  });

  final double side;
  final String readout;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: const Alignment(0, 0.56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              readout,
              key: ValueKey(readout),
              style: TextStyle(
                fontSize: side * 0.125,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: -0.5,
                color: scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(height: side * 0.014),
          SizedBox(
            width: side * 0.5,
            child: Text(
              caption,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: side * 0.04,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.needle,
    required this.band,
    required this.face,
    required this.faceCenter,
    required this.bezel,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.high,
    required this.low,
    required this.mid,
    required this.hub,
    required this.numeral,
  });

  /// Needle position, 0 to 1. May overshoot slightly while settling.
  final double needle;

  /// Opacity of the score band, 0 to 1.
  final double band;

  final Color face;
  final Color faceCenter;
  final Color bezel;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color high;
  final Color low;
  final Color mid;
  final Color hub;
  final TextStyle numeral;

  // Zero at about seven o'clock, full scale at five: the classic instrument
  // layout, which leaves the bottom of the face free for the readout.
  static const _start = math.pi * 5 / 6;
  static const _sweep = math.pi * 4 / 3;

  double _angle(double t) => _start + _sweep * t;

  Offset _at(Offset c, double angle, double r) =>
      c + Offset(math.cos(angle), math.sin(angle)) * r;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 2;
    if (r <= 0) return;

    _paintFace(canvas, c, r);
    _paintBand(canvas, c, r);
    _paintScale(canvas, c, r);
    _paintNeedle(canvas, c, r);
  }

  void _paintFace(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [faceCenter, face],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Two fine rings read as a machined bezel without any chrome effects.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = bezel,
    );
    canvas.drawCircle(
      c,
      r * 0.93,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = bezel.withValues(alpha: 0.6),
    );
  }

  void _paintBand(Canvas canvas, Offset c, double r) {
    if (band <= 0) return;
    // Between the bezel's inner ring and the lit arc, so the two never meet.
    final rect = Rect.fromCircle(center: c, radius: r * 0.9);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.018
      ..strokeCap = StrokeCap.butt;
    void segment(double from, double to, Color color) {
      paint.color = color.withValues(alpha: 0.75 * band);
      canvas.drawArc(rect, _angle(from), _sweep * (to - from), false, paint);
    }

    segment(0, kTamilLowEnd, low);
    segment(kTamilLowEnd, kTamilMidEnd, mid);
    segment(kTamilMidEnd, 1, high);
  }

  void _paintScale(Canvas canvas, Offset c, double r) {
    final lit = needle.clamp(0.0, 1.0);
    final outer = r * 0.83;
    final tick = Paint()..strokeCap = StrokeCap.round;

    // 50 minor steps of 2, mid ticks every 10, numbered ticks every 20.
    for (var i = 0; i <= 50; i++) {
      final t = i / 50;
      final major = i % 10 == 0;
      final mid = i % 5 == 0;
      final len = r * (major ? 0.11 : (mid ? 0.075 : 0.045));
      final on = t <= lit + 1e-9 && lit > 0;
      tick
        ..strokeWidth = major ? 2.2 : (mid ? 1.6 : 1.1)
        ..color = on
            ? accent.withValues(alpha: major ? 1 : 0.85)
            : (major
                  ? ink.withValues(alpha: 0.7)
                  : muted.withValues(alpha: 0.4));
      final a = _angle(t);
      canvas.drawLine(_at(c, a, outer), _at(c, a, outer - len), tick);

      if (major) {
        final label = TextPainter(
          text: TextSpan(text: '${i * 2}', style: numeral),
          textDirection: TextDirection.ltr,
        )..layout();
        final pos = _at(c, a, outer - r * 0.2);
        label.paint(canvas, pos - Offset(label.width / 2, label.height / 2));
      }
    }

    // A thin lit arc along the inside of the ticks traces the reading.
    if (lit > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: outer + r * 0.022),
        _start,
        _sweep * lit,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.016
          ..strokeCap = StrokeCap.round
          ..color = accent,
      );
    }
  }

  void _paintNeedle(Canvas canvas, Offset c, double r) {
    final a = _angle(needle.clamp(-0.02, 1.02));
    final dir = Offset(math.cos(a), math.sin(a));
    final normal = Offset(-dir.dy, dir.dx);
    final tip = c + dir * r * 0.74;
    final tail = c - dir * r * 0.14;
    final base = r * 0.03;

    final needlePath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((c + normal * base).dx, (c + normal * base).dy)
      ..lineTo((tail + normal * base * 0.6).dx, (tail + normal * base * 0.6).dy)
      ..lineTo((tail - normal * base * 0.6).dx, (tail - normal * base * 0.6).dy)
      ..lineTo((c - normal * base).dx, (c - normal * base).dy)
      ..close();
    canvas.drawShadow(needlePath, const Color(0xFF000000), 3, false);
    canvas.drawPath(needlePath, Paint()..color = accent);

    // Hub cap carrying the letter த: the dial's one mark of identity.
    final hubR = r * 0.14;
    canvas.drawCircle(c, hubR, Paint()..color = hub);
    canvas.drawCircle(
      c,
      hubR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = bezel,
    );
    final glyph = TextPainter(
      text: TextSpan(
        text: 'த',
        style: TextStyle(
          fontSize: hubR * 1.05,
          fontWeight: FontWeight.w700,
          color: accent,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(canvas, c - Offset(glyph.width / 2, glyph.height / 2));
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.needle != needle ||
      old.band != band ||
      old.accent != accent ||
      old.face != face ||
      old.ink != ink ||
      old.numeral != numeral;
}
