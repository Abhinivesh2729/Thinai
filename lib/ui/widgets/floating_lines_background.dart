import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Flutter native recreation of the FloatingLines component from React / Three.js.
///
/// Features:
/// - Three harmonic undulating wave groups: top, middle, and bottom waves.
/// - Parametric coordinate rotation, logarithmic warp, and multi-line depth offsets.
/// - Dynamic touch/pointer bend interaction with radial exponential falloff.
/// - Color system tailored to Thinai's signature emerald, neon mint, and cyan palette.
/// - Ultra-efficient native 60/120 FPS Canvas rendering optimized for mobile devices.
class FloatingLinesBackground extends StatefulWidget {
  const FloatingLinesBackground({
    super.key,
    this.linesGradient,
    this.backgroundColor,
    this.enabledWaves = const ['top', 'middle', 'bottom'],
    this.lineCount = const [5, 6, 5],
    this.lineDistance = const [4.0, 4.5, 4.0],
    this.topWavePosition = const WavePosition(x: 8.0, y: 0.45, rotate: -0.35),
    this.middleWavePosition = const WavePosition(x: 4.0, y: 0.0, rotate: 0.18),
    this.bottomWavePosition = const WavePosition(x: 1.8, y: -0.55, rotate: 0.35),
    this.animationSpeed = 1.0,
    this.interactive = true,
    this.bendRadius = 4.0,
    this.bendStrength = -0.45,
    this.mouseDamping = 0.08,
    this.parallax = true,
    this.parallaxStrength = 0.15,
    this.lightMode,
    this.animated = true,
    this.isDark,
  });

  /// Palette of line gradient colors. If omitted, uses Thinai's brand emerald and server palette.
  final List<Color>? linesGradient;

  /// Background surface color.
  final Color? backgroundColor;

  /// Which wave groups are rendered: 'top', 'middle', 'bottom'.
  final List<String> enabledWaves;

  /// Number of lines per wave group [top, middle, bottom].
  final List<int> lineCount;

  /// Distance multiplier between lines per wave group [top, middle, bottom].
  final List<double> lineDistance;

  /// Top wave position & angle configuration.
  final WavePosition topWavePosition;

  /// Middle wave position & angle configuration.
  final WavePosition middleWavePosition;

  /// Bottom wave position & angle configuration.
  final WavePosition bottomWavePosition;

  /// Speed multiplier for the wave undulation.
  final double animationSpeed;

  /// Whether pointer/touch gestures bend the lines.
  final bool interactive;

  /// Radial falloff influence around cursor/finger.
  final double bendRadius;

  /// Strength of touch displacement / deflection.
  final double bendStrength;

  /// Damping factor for smooth pointer smoothing.
  final double mouseDamping;

  /// Whether subtle parallax shifts the wave field.
  final bool parallax;

  /// Parallax strength scale.
  final double parallaxStrength;

  /// Explicit light mode styling override.
  final bool? lightMode;

  /// When true, animates continuously. When false, runs at a calm ambient idle rate.
  final bool animated;

  /// Explicit dark/light mode override.
  final bool? isDark;

  @override
  State<FloatingLinesBackground> createState() =>
      _FloatingLinesBackgroundState();
}

class WavePosition {
  const WavePosition({required this.x, required this.y, required this.rotate});
  final double x;
  final double y;
  final double rotate;
}

class _FloatingLinesBackgroundState extends State<FloatingLinesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Pointer interaction state (smoothly lerped for liquid responsiveness)
  Offset _targetMouse = const Offset(-1000, -1000);
  Offset _currentMouse = const Offset(-1000, -1000);
  double _targetInfluence = 0.0;
  double _currentInfluence = 0.0;
  Offset _targetParallax = Offset.zero;
  Offset _currentParallax = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event, Size size) {
    if (!widget.interactive || size.height <= 0) return;
    _updatePointer(event.localPosition, size);
    _targetInfluence = 1.0;
  }

  void _onPointerMove(PointerMoveEvent event, Size size) {
    if (!widget.interactive || size.height <= 0) return;
    _updatePointer(event.localPosition, size);
    _targetInfluence = 1.0;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!widget.interactive) return;
    _targetInfluence = 0.0;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!widget.interactive) return;
    _targetInfluence = 0.0;
  }

  void _updatePointer(Offset pos, Size size) {
    // Convert to normalized coordinates [-aspect, aspect] x [-1, 1]
    final halfW = size.width / 2.0;
    final halfH = size.height / 2.0;

    final normX = ((pos.dx - halfW) / halfH);
    final normY = -((pos.dy - halfH) / halfH);

    _targetMouse = Offset(normX, normY);

    if (widget.parallax) {
      final offX = ((pos.dx - halfW) / size.width) * widget.parallaxStrength;
      final offY = -((pos.dy - halfH) / size.height) * widget.parallaxStrength;
      _targetParallax = Offset(offX, offY);
    }
  }

  void _tickInteraction() {
    if (!widget.interactive) return;
    final damping = widget.mouseDamping.clamp(0.01, 0.5);

    // Smooth lerp mouse coordinates
    _currentMouse = Offset(
      _currentMouse.dx + (_targetMouse.dx - _currentMouse.dx) * damping,
      _currentMouse.dy + (_targetMouse.dy - _currentMouse.dy) * damping,
    );

    _currentInfluence += (_targetInfluence - _currentInfluence) * damping;

    if (widget.parallax) {
      _currentParallax = Offset(
        _currentParallax.dx + (_targetParallax.dx - _currentParallax.dx) * damping,
        _currentParallax.dy + (_targetParallax.dy - _currentParallax.dy) * damping,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark ??
        (Theme.of(context).brightness == Brightness.dark);
    final scheme = Theme.of(context).colorScheme;

    // Thinai Brand Floating Lines Palette:
    // Emerald green (#2CA048), bright neon green (#4ADE80), cyan/teal accent (#2DD4BF), mint (#6EE7B7)
    final effectiveGradient = widget.linesGradient ??
        (isDark
            ? const [
                Color(0xFF2CA048), // Brand leaf emerald
                Color(0xFF4ADE80), // Neon light emerald
                Color(0xFF2DD4BF), // Crystalline teal / cyan
                Color(0xFF6EE7B7), // Mint accent
                Color(0xFFA7F3D0), // Soft luminous core
              ]
            : const [
                Color(0xFF1B8738), // Deep emerald
                Color(0xFF2CA048), // Brand emerald
                Color(0xFF0D9488), // Slate teal
                Color(0xFF16A34A), // Rich green
                Color(0xFF34D399), // Mint glow
              ]);

    final effectiveBackground = widget.backgroundColor ??
        (isDark ? const Color(0xFF090E14) : scheme.surfaceContainerLow);

    // Active speed when server is running; calm ambient drift when stopped
    final effectiveSpeed = widget.animated
        ? widget.animationSpeed
        : (widget.animationSpeed * 0.35);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return RepaintBoundary(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) => _onPointerDown(e, size),
            onPointerMove: (e) => _onPointerMove(e, size),
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                _tickInteraction();

                return CustomPaint(
                  painter: _FloatingLinesPainter(
                    time: _controller.value * 2.0 * math.pi * effectiveSpeed,
                    colors: effectiveGradient,
                    backgroundColor: effectiveBackground,
                    enabledWaves: widget.enabledWaves,
                    lineCounts: widget.lineCount,
                    lineDistances: widget.lineDistance,
                    topWavePosition: widget.topWavePosition,
                    middleWavePosition: widget.middleWavePosition,
                    bottomWavePosition: widget.bottomWavePosition,
                    interactive: widget.interactive,
                    mouseUv: _currentMouse,
                    bendRadius: widget.bendRadius,
                    bendStrength: widget.bendStrength,
                    bendInfluence: _currentInfluence,
                    parallaxOffset: _currentParallax,
                    isDark: isDark,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FloatingLinesPainter extends CustomPainter {
  _FloatingLinesPainter({
    required this.time,
    required this.colors,
    required this.backgroundColor,
    required this.enabledWaves,
    required this.lineCounts,
    required this.lineDistances,
    required this.topWavePosition,
    required this.middleWavePosition,
    required this.bottomWavePosition,
    required this.interactive,
    required this.mouseUv,
    required this.bendRadius,
    required this.bendStrength,
    required this.bendInfluence,
    required this.parallaxOffset,
    required this.isDark,
  })  : _bgPaint = Paint()..color = backgroundColor,
        _haloPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
        _corePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

  final double time;
  final List<Color> colors;
  final Color backgroundColor;
  final List<String> enabledWaves;
  final List<int> lineCounts;
  final List<double> lineDistances;
  final WavePosition topWavePosition;
  final WavePosition middleWavePosition;
  final WavePosition bottomWavePosition;
  final bool interactive;
  final Offset mouseUv;
  final double bendRadius;
  final double bendStrength;
  final double bendInfluence;
  final Offset parallaxOffset;
  final bool isDark;

  final Paint _bgPaint;
  final Paint _haloPaint;
  final Paint _corePaint;

  // Sample density across horizontal card width for silky smooth bezier curves
  static const int _sampleSteps = 48;

  Color _getGradientColor(double t) {
    if (colors.isEmpty) return const Color(0xFF2CA048);
    if (colors.length == 1) return colors.first;

    final clampedT = t.clamp(0.0, 0.9999);
    final scaled = clampedT * (colors.length - 1);
    final idx = scaled.floor();
    final f = scaled - idx;
    final nextIdx = math.min(idx + 1, colors.length - 1);

    return Color.lerp(colors[idx], colors[nextIdx], f) ?? colors[idx];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Solid card background surface
    canvas.drawRect(Offset.zero & size, _bgPaint);

    final halfW = size.width / 2.0;
    final halfH = size.height / 2.0;

    // 2. Draw ambient radial glow in the center-right to give luminous depth
    final glowCenter = Offset(size.width * 0.72, size.height * 0.45);
    final glowRadius = size.width * 0.75;
    final primaryColor = colors.isNotEmpty ? colors.first : const Color(0xFF2CA048);
    final accentColor = colors.length > 2 ? colors[2] : primaryColor;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
          accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius));
    canvas.drawCircle(glowCenter, glowRadius, glowPaint);

    // 3. Render wave ribbons
    final enableBottom = enabledWaves.contains('bottom');
    final enableMiddle = enabledWaves.contains('middle');
    final enableTop = enabledWaves.contains('top');

    final bottomCount = lineCounts.isNotEmpty ? lineCounts[0] : 5;
    final middleCount = lineCounts.length > 1 ? lineCounts[1] : 6;
    final topCount = lineCounts.length > 2 ? lineCounts[2] : 5;

    final bottomDist = (lineDistances.isNotEmpty ? lineDistances[0] : 4.0) * 0.02;
    final middleDist = (lineDistances.length > 1 ? lineDistances[1] : 4.5) * 0.02;
    final topDist = (lineDistances.length > 2 ? lineDistances[2] : 4.0) * 0.02;

    // Render Bottom Waves
    if (enableBottom) {
      _paintWaveGroup(
        canvas: canvas,
        size: size,
        halfW: halfW,
        halfH: halfH,
        count: bottomCount,
        distance: bottomDist,
        position: bottomWavePosition,
        baseOffset: 1.5,
        offsetStep: 0.20,
        intensityScale: 0.65,
        invertX: false,
      );
    }

    // Render Middle Waves
    if (enableMiddle) {
      _paintWaveGroup(
        canvas: canvas,
        size: size,
        halfW: halfW,
        halfH: halfH,
        count: middleCount,
        distance: middleDist,
        position: middleWavePosition,
        baseOffset: 2.0,
        offsetStep: 0.16,
        intensityScale: 1.0,
        invertX: false,
      );
    }

    // Render Top Waves
    if (enableTop) {
      _paintWaveGroup(
        canvas: canvas,
        size: size,
        halfW: halfW,
        halfH: halfH,
        count: topCount,
        distance: topDist,
        position: topWavePosition,
        baseOffset: 1.0,
        offsetStep: 0.20,
        intensityScale: 0.55,
        invertX: true,
      );
    }
  }

  void _paintWaveGroup({
    required Canvas canvas,
    required Size size,
    required double halfW,
    required double halfH,
    required int count,
    required double distance,
    required WavePosition position,
    required double baseOffset,
    required double offsetStep,
    required double intensityScale,
    required bool invertX,
  }) {
    if (count <= 0) return;

    final path = Path();

    for (var i = 0; i < count; i++) {
      final t = i / math.max(count - 1, 1);
      final lineColor = _getGradientColor(t);

      final lineOffset = baseOffset + offsetStep * i;
      final xOffsetPos = distance * i + position.x;
      final yBase = position.y;

      final amp = math.sin(lineOffset + time * 0.2) * 0.32;
      final xMovement = time * 0.1;

      path.reset();
      var isFirst = true;

      // Sample along horizontal UV coordinate
      for (var s = 0; s <= _sampleSteps; s++) {
        final screenFraction = s / _sampleSteps;
        final screenX = screenFraction * size.width;

        // Normalized coordinate: centered, aspect corrected
        var uvX = (screenX - halfW) / halfH;
        if (invertX) uvX = -uvX;

        // Add parallax offset
        uvX += parallaxOffset.dx;

        // Apply harmonic rotation angle: angle = position.rotate * log(length(uv) + 1.0)
        final distFromCenter = uvX.abs();
        final angle = position.rotate * math.log(distFromCenter + 1.0);
        final cosA = math.cos(angle);
        final sinA = math.sin(angle);

        // Sinusoidal wave function
        var waveY = math.sin(uvX + xOffsetPos + xMovement) * amp + yBase;

        // Coordinate rotation
        final rotatedY = (-uvX * sinA) + (waveY * cosA);

        // Screen space UV
        final screenUvX = (screenX - halfW) / halfH;
        final screenUvY = rotatedY;

        // Pointer bend interaction with radial exponential falloff
        var finalY = rotatedY;
        if (interactive && bendInfluence > 0.005) {
          final dx = screenUvX - mouseUv.dx;
          final dy = screenUvY - mouseUv.dy;
          final distSq = dx * dx + dy * dy;
          final influence = math.exp(-distSq * bendRadius);
          final bendOffset =
              (mouseUv.dy - screenUvY) * influence * bendStrength * bendInfluence;
          finalY += bendOffset;
        }

        // Convert back to canvas pixel coordinate (invert Y back to downward positive)
        final pixelY = halfH - (finalY * halfH) + (parallaxOffset.dy * halfH);

        if (isFirst) {
          path.moveTo(screenX, pixelY);
          isFirst = false;
        } else {
          path.lineTo(screenX, pixelY);
        }
      }

      final alpha = (isDark ? 0.90 : 0.75) * intensityScale;

      // 1. Soft atmospheric glowing halo
      _haloPaint
        ..color = lineColor.withValues(alpha: alpha * (isDark ? 0.35 : 0.22))
        ..strokeWidth = isDark ? 4.8 : 3.5;
      canvas.drawPath(path, _haloPaint);

      // 2. Luminous crisp core line
      _corePaint
        ..color = (isDark ? lineColor : lineColor.withValues(alpha: alpha * 0.9))
        ..strokeWidth = isDark ? 1.6 : 1.4;
      canvas.drawPath(path, _corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingLinesPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.mouseUv != mouseUv ||
        oldDelegate.bendInfluence != bendInfluence ||
        oldDelegate.parallaxOffset != parallaxOffset ||
        oldDelegate.isDark != isDark;
  }
}
