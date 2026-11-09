/// Non-blocking toasts, bottom-right, stacked. Callable from anywhere without
/// a BuildContext: `showDeskToast('Copied')`.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/desk_theme.dart';

enum DeskTone { info, success, warning, error }

class _Toast {
  _Toast(this.id, this.message, this.tone, this.lasting);
  final int id;
  final String message;
  final DeskTone tone;
  final Duration lasting;
}

final _toasts = ValueNotifier<List<_Toast>>(const []);
var _nextId = 0;

void showDeskToast(
  String message, {
  DeskTone tone = DeskTone.info,
  Duration lasting = const Duration(seconds: 4),
}) {
  final toast = _Toast(_nextId++, message, tone, lasting);
  // Newest at the bottom; at most four on screen.
  final list = [..._toasts.value, toast];
  _toasts.value = list.length > 4 ? list.sublist(list.length - 4) : list;
  Timer(lasting, () => dismissDeskToast(toast.id));
}

void dismissDeskToast(int id) {
  _toasts.value = [
    for (final t in _toasts.value)
      if (t.id != id) t,
  ];
}

/// Put once above the app content.
class DeskToastLayer extends StatelessWidget {
  const DeskToastLayer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 20,
          bottom: 20,
          child: ValueListenableBuilder<List<_Toast>>(
            valueListenable: _toasts,
            builder: (context, toasts, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final t in toasts)
                  _ToastCard(key: ValueKey(t.id), toast: t),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({super.key, required this.toast});
  final _Toast toast;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: DeskMotion.medium,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (widget.toast.tone) {
      DeskTone.info => (Icons.info_outline_rounded, scheme.onSurfaceVariant),
      DeskTone.success => (Icons.check_circle_rounded, DeskColors.green),
      DeskTone.warning => (Icons.warning_amber_rounded, DeskColors.amber),
      DeskTone.error => (Icons.error_outline_rounded, DeskColors.danger),
    };
    final anim = CurvedAnimation(parent: _c, curve: DeskMotion.spring);
    return FadeTransition(
      opacity: _c,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(anim),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Material(
            color: palette.panelRaised,
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DeskSize.radiusM),
              side: BorderSide(color: palette.hairline),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(DeskSize.radiusM),
              onTap: () => dismissDeskToast(widget.toast.id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.toast.message,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
