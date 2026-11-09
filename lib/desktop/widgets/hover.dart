/// Small interaction helpers shared by desktop widgets.
library;

import 'package:flutter/material.dart';

import '../theme/desk_theme.dart';

/// Rebuilds [builder] with whether the pointer is over it.
class Hoverable extends StatefulWidget {
  const Hoverable({super.key, required this.builder, this.cursor});
  final Widget Function(BuildContext context, bool hovered) builder;
  final MouseCursor? cursor;

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.cursor ?? MouseCursor.defer,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: widget.builder(context, _hovered),
  );
}

/// A quiet icon button with a hover fill and a tooltip.
class DeskIconButton extends StatelessWidget {
  const DeskIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 34,
    this.iconSize = 18,
    this.color,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? (active ? DeskColors.green : scheme.onSurfaceVariant);
    return Tooltip(
      message: tooltip,
      child: Hoverable(
        cursor: onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, hovered) => GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: DeskMotion.fast,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: active
                  ? DeskColors.green.withValues(alpha: 0.14)
                  : hovered && onPressed != null
                  ? scheme.onSurface.withValues(alpha: 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(DeskSize.radiusS + 2),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: onPressed == null ? fg.withValues(alpha: 0.4) : fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and slides a child in when it first appears.
class EnterAnimation extends StatefulWidget {
  const EnterAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.04),
    this.duration = DeskMotion.slow,
  });

  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;

  @override
  State<EnterAnimation> createState() => _EnterAnimationState();
}

class _EnterAnimationState extends State<EnterAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: DeskMotion.ease);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: widget.offset, end: Offset.zero).animate(curved),
        child: widget.child,
      ),
    );
  }
}
