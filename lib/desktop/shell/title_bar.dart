/// Frameless window chrome: a drag area and, on Windows, our own minimise /
/// maximise / close buttons drawn to match the app instead of the grey
/// system caption.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/desk_l10n.dart';
import '../theme/desk_theme.dart';
import '../widgets/hover.dart';

class DeskTitleBar extends StatelessWidget {
  const DeskTitleBar({super.key, this.center});

  /// Optional content in the middle of the bar (e.g. the chat title).
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final s = ShellStrings.of(context);
    return SizedBox(
      height: DeskSize.titleBarHeight,
      child: Row(
        children: [
          // macOS keeps its traffic lights at the top left.
          if (Platform.isMacOS) const SizedBox(width: 78),
          Expanded(
            child: DragToMoveArea(
              child: SizedBox.expand(
                child: center == null
                    ? null
                    : Align(alignment: Alignment.center, child: center),
              ),
            ),
          ),
          if (Platform.isWindows) ...[
            _CaptionButton(
              icon: Icons.remove_rounded,
              tooltip: s.minimize,
              onTap: () => windowManager.minimize(),
            ),
            _MaximizeButton(tooltip: s.maximize),
            _CaptionButton(
              icon: Icons.close_rounded,
              tooltip: s.close,
              danger: true,
              onTap: () => windowManager.close(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MaximizeButton extends StatefulWidget {
  const _MaximizeButton({required this.tooltip});
  final String tooltip;

  @override
  State<_MaximizeButton> createState() => _MaximizeButtonState();
}

class _MaximizeButtonState extends State<_MaximizeButton> with WindowListener {
  bool _max = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((v) {
      if (mounted) setState(() => _max = v);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _max = true);
  @override
  void onWindowUnmaximize() => setState(() => _max = false);

  @override
  Widget build(BuildContext context) => _CaptionButton(
    icon: _max ? Icons.filter_none_rounded : Icons.crop_square_rounded,
    iconSize: _max ? 13 : 15,
    tooltip: widget.tooltip,
    onTap: () async {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    },
  );
}

class _CaptionButton extends StatelessWidget {
  const _CaptionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
    this.iconSize = 16,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Hoverable(
      builder: (context, hovered) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DeskMotion.fast,
          width: 46,
          height: DeskSize.titleBarHeight,
          color: hovered
              ? (danger
                    ? const Color(0xFFE81123)
                    : scheme.onSurface.withValues(alpha: 0.08))
              : Colors.transparent,
          child: Icon(
            icon,
            size: iconSize,
            color: hovered && danger ? Colors.white : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
