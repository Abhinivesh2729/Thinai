import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SpotlightCoachStep {
  const SpotlightCoachStep({
    required this.targetKey,
    required this.title,
    required this.message,
    this.beforeShow,
    this.borderRadius = 14,
    this.padding = 10,
  });

  final GlobalKey targetKey;
  final String title;
  final String message;
  final Future<void> Function()? beforeShow;
  final double borderRadius;
  final double padding;
}

class SpotlightCoachMarks {
  const SpotlightCoachMarks._();

  static Future<void> show({
    required BuildContext context,
    required List<SpotlightCoachStep> steps,
  }) async {
    if (steps.isEmpty) return;

    final completer = Completer<void>();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _SpotlightCoachOverlay(
        steps: steps,
        onDone: () {
          entry.remove();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ),
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(entry);
    await completer.future;
  }
}

class _SpotlightCoachOverlay extends StatefulWidget {
  const _SpotlightCoachOverlay({required this.steps, required this.onDone});

  final List<SpotlightCoachStep> steps;
  final VoidCallback onDone;

  @override
  State<_SpotlightCoachOverlay> createState() => _SpotlightCoachOverlayState();
}

class _SpotlightCoachOverlayState extends State<_SpotlightCoachOverlay> {
  static const _maxResolveAttempts = 30;

  /// How long the spotlight and panel take to travel between two steps. The
  /// mask and the panel share it so they arrive together.
  static const _moveDuration = Duration(milliseconds: 320);
  static const _moveCurve = Curves.easeOutCubic;

  int _index = 0;
  Rect? _targetRect;
  bool _resolving = true;

  SpotlightCoachStep get _step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    unawaited(_activateStep(0));
  }

  Future<void> _activateStep(int nextIndex) async {
    if (!mounted) return;
    if (nextIndex < 0 || nextIndex >= widget.steps.length) {
      widget.onDone();
      return;
    }

    setState(() {
      _index = nextIndex;
      _resolving = true;
      // _targetRect deliberately survives the step change. Resolving the next
      // target takes ~300ms (a tab switch, then polling for the render box),
      // and clearing it here parked the panel at the top of the screen for
      // that whole window before it snapped back down, a visible bounce on
      // every step. Holding the last rect lets the spotlight glide instead.
    });

    final step = widget.steps[nextIndex];
    if (step.beforeShow != null) {
      await step.beforeShow!();
    }

    await _scrollTargetIntoView(step.targetKey);
    final rect = await _resolveTargetRect(step.targetKey, step.padding);
    if (!mounted) return;

    if (rect == null) {
      await _activateStep(nextIndex + 1);
      return;
    }

    setState(() {
      _targetRect = rect;
      _resolving = false;
    });
  }

  /// Scrolls [key]'s target into view before the spotlight is measured.
  ///
  /// Without this a step points at whatever happens to be on screen: a target
  /// further down a scrolling page gets a spotlight below the fold, or one
  /// hidden behind the instruction panel. Aligning to the upper third keeps
  /// the highlight clear of the panel, which sits low.
  Future<void> _scrollTargetIntoView(GlobalKey key) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final context = key.currentContext;
      // The page may still be building after a tab switch; that is the only
      // case worth waiting for.
      if (context == null) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        continue;
      }
      // A target that is not inside a scroll view is already as visible as it
      // is going to get. Returning at once matters: waiting here would delay
      // every such step by the retry budget for no gain.
      if (!context.mounted || Scrollable.maybeOf(context) == null) return;

      await Scrollable.ensureVisible(
        context,
        alignment: 0.35,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      // Let the scroll settle before the rect is read, or the spotlight lands
      // where the target was rather than where it is.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      return;
    }
  }

  Future<Rect?> _resolveTargetRect(GlobalKey key, double padding) async {
    for (var attempt = 0; attempt < _maxResolveAttempts; attempt++) {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is RenderBox &&
          renderObject.attached &&
          renderObject.hasSize) {
        final topLeft = renderObject.localToGlobal(Offset.zero);
        final rect = (topLeft & renderObject.size).inflate(padding);
        if (rect.width > 2 && rect.height > 2) {
          return rect;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    return null;
  }

  Future<void> _next() async {
    final last = _index >= widget.steps.length - 1;
    if (last) {
      widget.onDone();
      return;
    }
    await _activateStep(_index + 1);
  }

  Future<void> _previous() async {
    if (_index == 0) return;
    await _activateStep(_index - 1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context).size;

    final panelWidth = math.min(media.width - 24, 360.0);
    const panelHeightEstimate = 220.0;

    final rect = _targetRect;
    final placeBelow = rect == null || rect.center.dy < media.height * 0.56;

    var panelTop = 22.0;
    if (rect != null) {
      panelTop = placeBelow ? rect.bottom + 14 : rect.top - panelHeightEstimate;
      panelTop = panelTop.clamp(12.0, media.height - panelHeightEstimate - 12);
    }

    final panelLeft = rect == null
        ? (media.width - panelWidth) / 2
        : (rect.center.dx - panelWidth / 2).clamp(
            12.0,
            media.width - panelWidth - 12,
          );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              // Null only before the first target resolves, and
              // TweenAnimationBuilder cannot carry a null end value.
              child: rect == null
                  ? CustomPaint(
                      painter: _SpotlightMaskPainter(
                        targetRect: null,
                        borderRadius: _step.borderRadius,
                      ),
                    )
                  : TweenAnimationBuilder<Rect?>(
                      // Mounts on the first resolve with begin == end, so the
                      // opening hole appears in place; only later steps, which
                      // change `end`, animate.
                      tween: RectTween(end: rect),
                      duration: _moveDuration,
                      curve: _moveCurve,
                      builder: (context, animatedRect, _) => Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _SpotlightMaskPainter(
                                targetRect: animatedRect,
                                borderRadius: _step.borderRadius,
                              ),
                            ),
                          ),
                          if (animatedRect != null)
                            Positioned.fromRect(
                              rect: animatedRect,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    _step.borderRadius,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 22,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
          AnimatedPositioned(
            duration: _moveDuration,
            curve: _moveCurve,
            top: panelTop,
            left: panelLeft,
            width: panelWidth,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.of(context).card,
                borderRadius: BorderRadius.circular(Radii.xl),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.lg,
                Space.lg,
                Space.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'App Tour',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      // Progress as a row of segments: how far along, and how
                      // much is left, at a glance.
                      for (var i = 0; i < widget.steps.length; i++)
                        AnimatedContainer(
                          duration: Motion.base,
                          margin: const EdgeInsets.only(left: 4),
                          width: i == _index ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= _index
                                ? scheme.primary
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _step.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_resolving)
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Locating control…',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        onPressed: widget.onDone,
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                        ),
                        child: const Text('Skip'),
                      ),
                      if (_index > 0)
                        TextButton(
                          onPressed: _resolving ? null : _previous,
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _resolving ? null : _next,
                        child: Text(
                          _index == widget.steps.length - 1 ? 'Done' : 'Next',
                        ),
                      ),
                    ],
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

class _SpotlightMaskPainter extends CustomPainter {
  const _SpotlightMaskPainter({
    required this.targetRect,
    required this.borderRadius,
  });

  final Rect? targetRect;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final maskPaint = Paint()..color = const Color(0xCC04070D);

    if (targetRect == null) {
      canvas.drawRect(fullRect, maskPaint);
      return;
    }

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(fullRect)
      ..addRRect(
        RRect.fromRectAndRadius(targetRect!, Radius.circular(borderRadius)),
      );
    canvas.drawPath(path, maskPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightMaskPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius;
  }
}
