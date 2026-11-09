/// The Thinai orb: the desktop app's living centrepiece.
///
/// One GPU shader (shaders/orb.frag) with a single input that matters:
/// energy. [OrbMood] sets where energy rests, [OrbController.pulse] kicks it
/// up for a moment (one call per streamed token makes the orb "speak"), and
/// the widget eases toward the target every frame, so state changes never
/// jump.
///
/// Performance rules this follows:
/// * The shader program loads once per process and is shared.
/// * Painting is isolated in a RepaintBoundary; nothing else rebuilds per
///   frame.
/// * The ticker stops while the window is hidden or minimised, and when the
///   OS asks for reduced motion the orb holds still apart from state fades.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/desk_theme.dart';

/// What the orb is showing.
enum OrbMood {
  /// Waiting: a slow breath.
  idle(0.10),

  /// Something is loading or the web is being searched: faster swirl.
  thinking(0.62),

  /// A reply is streaming in: lively, with pulses per token.
  speaking(0.42),

  /// Something went wrong.
  error(0.30);

  const OrbMood(this.energy);

  /// Energy the orb settles at in this mood.
  final double energy;
}

/// Drives an [Orb] from outside: mood changes and token pulses.
class OrbController extends ChangeNotifier {
  OrbMood _mood = OrbMood.idle;
  OrbMood get mood => _mood;

  double _kick = 0;

  /// Pulse energy waiting to be absorbed by the next frame.
  double takeKick() {
    final k = _kick;
    _kick = 0;
    return k;
  }

  set mood(OrbMood value) {
    if (value == _mood) return;
    _mood = value;
    notifyListeners();
  }

  /// A brief surge, e.g. once per streamed token. Cheap: no rebuild.
  void pulse([double amount = 0.08]) {
    _kick = math.min(0.5, _kick + amount);
  }
}

class Orb extends StatefulWidget {
  const Orb({super.key, required this.size, this.controller, this.mood});

  final double size;

  /// Optional: drives mood and pulses. Without one, [mood] is used.
  final OrbController? controller;
  final OrbMood? mood;

  @override
  State<Orb> createState() => _OrbState();
}

class _OrbState extends State<Orb>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static Future<ui.FragmentProgram>? _programLoad;
  ui.FragmentShader? _shader;

  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);
  double _energy = OrbMood.idle.energy;
  double _boost = 0;
  Duration _last = Duration.zero;
  bool _visible = true;

  OrbMood get _mood => widget.controller?.mood ?? widget.mood ?? OrbMood.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick);
    _programLoad ??= ui.FragmentProgram.fromAsset('shaders/orb.frag');
    _programLoad!.then(
      (program) {
        if (!mounted) return;
        setState(() => _shader = program.fragmentShader());
      },
      onError: (Object _) {
        // No shader (very old GPU driver): the gradient fallback paints.
      },
    );
    _energy = _mood.energy;
    _syncTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    _syncTicker();
  }

  void _syncTicker() {
    final reduce = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    final shouldRun = _visible && !reduce;
    if (shouldRun && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;

    final kick = widget.controller?.takeKick() ?? 0;
    _boost = math.min(0.45, _boost + kick);
    // Boost decays in ~250 ms; energy chases its target in ~350 ms.
    _boost *= math.exp(-dt / 0.25);
    final target = _mood.energy + _boost;
    _energy += (target - _energy) * (1 - math.exp(-dt / 0.35));
    // Time runs a little faster with energy, so the swirl speeds up smoothly
    // instead of jumping phase.
    _time.value += dt * (0.8 + 0.6 * _energy);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _shader?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _shader == null
              ? _FallbackOrbPainter(repaint: _time, dark: palette.isDark)
              : _OrbPainter(
                  shader: _shader!,
                  repaint: _time,
                  energy: () => _energy,
                  dark: palette.isDark,
                ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.shader,
    required this.repaint,
    required this.energy,
    required this.dark,
  }) : super(repaint: repaint);

  final ui.FragmentShader shader;
  final ValueNotifier<double> repaint;
  final double Function() energy;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    const core = DeskColors.green;
    const glow = DeskColors.mint;
    final deep = dark ? DeskColors.shadowGreen : const Color(0xFF14532D);
    var i = 0;
    void f(double v) => shader.setFloat(i++, v);
    void c(Color col) {
      f(col.r);
      f(col.g);
      f(col.b);
    }

    f(size.width);
    f(size.height);
    f(repaint.value);
    f(energy());
    c(core);
    c(glow);
    c(deep);
    f(dark ? 1 : 0);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.shader != shader || old.dark != dark;
}

/// Used only if the shader cannot load: a breathing radial gradient.
class _FallbackOrbPainter extends CustomPainter {
  _FallbackOrbPainter({required this.repaint, required this.dark})
    : super(repaint: repaint);

  final ValueNotifier<double> repaint;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide * 0.31 * (1 + 0.02 * math.sin(repaint.value));
    canvas.drawCircle(
      center,
      r * 1.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            DeskColors.mint.withValues(alpha: dark ? 0.35 : 0.2),
            DeskColors.mint.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.5)),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: [
            DeskColors.mintSoft,
            DeskColors.green,
            DeskColors.shadowGreen,
          ],
          stops: [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_FallbackOrbPainter old) => old.dark != dark;
}

/// Keeps a controller's mood in step with a stream of moods; helper for
/// widgets that watch app state.
extension OrbControllerSync on OrbController {
  void follow(OrbMood next) => scheduleMicrotask(() => mood = next);
}
