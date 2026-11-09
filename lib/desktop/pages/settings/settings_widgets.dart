/// Building blocks for the desktop Settings page: cards, rows, a segmented
/// control, a toggle, a select and buttons, all on the desktop palette.
library;

import 'package:flutter/material.dart';

import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import '../../widgets/measure_size.dart';

/// A group of rows on one panel, split by hairlines.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(DeskSize.radiusL),
        border: Border.all(color: palette.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DeskSize.radiusL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const Divider(indent: 18, endIndent: 18),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// One setting: title and hint on the left, the control on the right, and
/// optionally more content underneath ([below]).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.below,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget body(bool hovered) => AnimatedContainer(
      duration: DeskMotion.fast,
      color: hovered && onTap != null
          ? scheme.onSurface.withValues(alpha: 0.035)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                IconTile(icon: icon!),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 16), trailing!],
            ],
          ),
          if (below != null) ...[
            const SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.only(left: icon != null ? 46 : 0),
              child: below,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return body(false);
    return Hoverable(
      cursor: SystemMouseCursors.click,
      builder: (context, hovered) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: body(hovered),
      ),
    );
  }
}

/// The small tinted square that carries a row's icon.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.color});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DeskColors.green;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DeskSize.radiusS + 1),
      ),
      child: Icon(icon, size: 17, color: c),
    );
  }
}

/// One option of a [DeskSegmented].
class Segment<T> {
  const Segment(this.value, this.label, {this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// A segmented control whose thumb slides to the picked option. Segments are
/// sized by their labels, so a long Tamil word does not squeeze its
/// neighbours.
class DeskSegmented<T> extends StatefulWidget {
  const DeskSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final List<Segment<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  State<DeskSegmented<T>> createState() => _DeskSegmentedState<T>();
}

class _DeskSegmentedState<T> extends State<DeskSegmented<T>> {
  late List<double> _widths = List.filled(widget.segments.length, 0);

  @override
  void didUpdateWidget(covariant DeskSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments.length != widget.segments.length) {
      _widths = List.filled(widget.segments.length, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final index = widget.segments.indexWhere((s) => s.value == widget.value);
    final measured = _widths.every((w) => w > 0);
    final left = index <= 0
        ? 0.0
        : _widths.take(index).fold<double>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: palette.isDark ? 0.05 : 0.04),
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        border: Border.all(color: palette.hairline),
      ),
      child: Stack(
        children: [
          if (measured && index >= 0)
            AnimatedPositioned(
              duration: DeskMotion.medium,
              curve: DeskMotion.spring,
              left: left,
              top: 0,
              bottom: 0,
              width: _widths[index],
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.isDark
                      ? palette.panelRaised
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(DeskSize.radiusS + 1),
                  border: Border.all(
                    color: DeskColors.green.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: palette.isDark ? 0.3 : 0.06,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, s) in widget.segments.indexed)
                MeasureSize(
                  onChange: (size) {
                    if (!mounted || i >= _widths.length) return;
                    if (_widths[i] == size.width) return;
                    setState(() => _widths[i] = size.width);
                  },
                  child: _SegmentButton(
                    label: s.label,
                    icon: s.icon,
                    selected: i == index,
                    onTap: widget.onChanged == null
                        ? null
                        : () => widget.onChanged!(s.value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = DeskPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Hoverable(
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, hovered) {
          final color = selected
              ? scheme.onSurface
              : hovered
              ? scheme.onSurface.withValues(alpha: 0.85)
              : palette.textMuted;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    AnimatedSwitcher(
                      duration: DeskMotion.fast,
                      child: Icon(
                        icon,
                        key: ValueKey(selected),
                        size: 15,
                        color: selected ? DeskColors.green : color,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: DeskMotion.fast,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A compact on/off switch that animates its thumb and track.
class DeskToggle extends StatelessWidget {
  const DeskToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = DeskPalette.of(context);
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onChanged?.call(!value);
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: enabled ? () => onChanged!(!value) : null,
          child: AnimatedOpacity(
            duration: DeskMotion.fast,
            opacity: enabled ? 1 : 0.5,
            child: AnimatedContainer(
              duration: DeskMotion.medium,
              curve: DeskMotion.ease,
              width: 40,
              height: 22,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value
                    ? DeskColors.green
                    : scheme.onSurface.withValues(
                        alpha: palette.isDark ? 0.16 : 0.14,
                      ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: AnimatedAlign(
                duration: DeskMotion.medium,
                curve: DeskMotion.spring,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
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

/// A dropdown that looks like a quiet field and opens a menu of [options].
class DeskSelect<T> extends StatelessWidget {
  const DeskSelect({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<Segment<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final current = options.where((o) => o.value == value).firstOrNull;

    return PopupMenuButton<T>(
      tooltip: '',
      initialValue: value,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final o in options)
          PopupMenuItem<T>(
            value: o.value,
            height: 38,
            child: Row(
              children: [
                if (o.icon != null) ...[
                  Icon(
                    o.icon,
                    size: 16,
                    color: o.value == value
                        ? DeskColors.green
                        : palette.textMuted,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    o.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: o.value == value
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (o.value == value)
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: DeskColors.green,
                  ),
              ],
            ),
          ),
      ],
      child: Hoverable(
        cursor: SystemMouseCursors.click,
        builder: (context, hovered) => AnimatedContainer(
          duration: DeskMotion.fast,
          constraints: const BoxConstraints(minWidth: 150),
          padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
          decoration: BoxDecoration(
            color: hovered
                ? scheme.onSurface.withValues(alpha: 0.05)
                : scheme.onSurface.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(DeskSize.radiusM - 2),
            border: Border.all(color: palette.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (current?.icon != null) ...[
                Icon(current!.icon, size: 15, color: DeskColors.green),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  current?.label ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.unfold_more_rounded,
                size: 16,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum DeskButtonKind { primary, secondary, ghost, danger }

/// A compact desktop button. Built on Material buttons so it keeps keyboard
/// focus, Enter/Space activation and hover for free.
class DeskButton extends StatelessWidget {
  const DeskButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = DeskButtonKind.secondary,
    this.busy = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final DeskButtonKind kind;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DeskSize.radiusS + 2),
    );
    const padding = EdgeInsets.symmetric(horizontal: 14);
    const minSize = Size(0, 34);
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    final fg = switch (kind) {
      DeskButtonKind.primary => Colors.white,
      DeskButtonKind.danger => DeskColors.danger,
      _ => scheme.onSurface,
    };
    final leading = busy
        ? SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : icon == null
        ? null
        : Icon(icon, size: 16);
    final child = leading == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [leading, const SizedBox(width: 8), Text(label)],
          );
    final onTap = busy ? null : onPressed;

    return switch (kind) {
      DeskButtonKind.primary => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: DeskColors.greenDeep,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DeskColors.greenDeep.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
          elevation: 0,
        ),
        child: child,
      ),
      DeskButtonKind.ghost => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
        ),
        child: child,
      ),
      _ => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          backgroundColor: kind == DeskButtonKind.danger
              ? DeskColors.danger.withValues(alpha: 0.06)
              : Colors.transparent,
          side: BorderSide(
            color: kind == DeskButtonKind.danger
                ? DeskColors.danger.withValues(alpha: 0.35)
                : palette.hairline,
          ),
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
        ),
        child: child,
      ),
    };
  }
}

/// A small rounded label, e.g. a version or a status.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.color, this.dot = false});
  final String label;
  final Color? color;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final c = color;
    return AnimatedContainer(
      duration: DeskMotion.medium,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c == null
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)
            : c.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: c ?? palette.textFaint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: c ?? palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog titles a size down from Material's, so a long Tamil word fits.
TextStyle? deskDialogTitle(BuildContext context) => Theme.of(
  context,
).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700);

/// Asks a yes/no question with a destructive confirm button.
Future<bool> confirmDanger(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  required String cancel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      titleTextStyle: deskDialogTitle(ctx),
      title: Text(title),
      content: SizedBox(width: 380, child: Text(body)),
      actions: [
        DeskButton(
          label: cancel,
          kind: DeskButtonKind.ghost,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: DeskColors.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 34),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DeskSize.radiusS + 2),
            ),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok == true;
}
