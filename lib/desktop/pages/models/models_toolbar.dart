/// The Models page toolbar pieces: search box, sliding segmented control and
/// the goal menu.
library;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models_repo/use_cases.dart';
import '../../l10n/models_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import '../../widgets/measure_size.dart';

class ModelSearchField extends StatelessWidget {
  const ModelSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = DeskPalette.of(context);
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13.5),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: l.modelsSearchHint,
          hintStyle: TextStyle(color: palette.textFaint, fontSize: 13.5),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: palette.textMuted,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, v, _) => AnimatedOpacity(
              duration: DeskMotion.fast,
              opacity: v.text.isEmpty ? 0 : 1,
              child: IgnorePointer(
                ignoring: v.text.isEmpty,
                child: DeskIconButton(
                  icon: Icons.close_rounded,
                  tooltip: l.modelsClearSearch,
                  size: 28,
                  iconSize: 16,
                  onPressed: onClear,
                ),
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 40),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// One option in [SegmentedTabs].
class Segment<T> {
  const Segment(this.value, this.label, this.icon);
  final T value;
  final String label;
  final IconData icon;
}

/// A segmented control whose selection pill slides to the chosen option.
class SegmentedTabs<T> extends StatefulWidget {
  const SegmentedTabs({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  State<SegmentedTabs<T>> createState() => _SegmentedTabsState<T>();
}

class _SegmentedTabsState<T> extends State<SegmentedTabs<T>> {
  // Measured after layout: labels differ in width (and in Tamil a lot), so
  // the pill takes each segment's real size rather than an equal share.
  final _widths = <int, double>{};

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final index = widget.segments.indexWhere((s) => s.value == widget.selected);
    final measured = _widths.length == widget.segments.length;
    var left = 0.0;
    for (var i = 0; i < index; i++) {
      left += _widths[i] ?? 0;
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.panel,
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
                  color: DeskColors.green.withValues(
                    alpha: palette.isDark ? 0.18 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(DeskSize.radiusS + 1),
                  border: Border.all(
                    color: DeskColors.green.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.segments.length; i++)
                MeasureSize(
                  onChange: (size) {
                    if (mounted && _widths[i] != size.width) {
                      setState(() => _widths[i] = size.width);
                    }
                  },
                  child: Hoverable(
                    cursor: SystemMouseCursors.click,
                    builder: (context, hovered) {
                      final selected = i == index;
                      final fg = selected
                          ? (palette.isDark
                                ? DeskColors.mint
                                : DeskColors.greenDeep)
                          : hovered
                          ? scheme.onSurface
                          : palette.textMuted;
                      return GestureDetector(
                        onTap: () => widget.onChanged(widget.segments[i].value),
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.segments[i].icon,
                                size: 15,
                                color: fg,
                              ),
                              const SizedBox(width: 6),
                              AnimatedDefaultTextStyle(
                                duration: DeskMotion.fast,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: fg,
                                ),
                                child: Text(widget.segments[i].label),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Goal ▾": opens the nine goals, each with what it optimises for.
class GoalButton extends StatelessWidget {
  const GoalButton({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final UseCase? selected;
  final ValueChanged<UseCase?> onChanged;

  static const _clear = -1;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ModelsStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final goal = selected;

    return PopupMenuButton<int>(
      tooltip: l.modelsChooseGoal,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
      onSelected: (v) => onChanged(v == _clear ? null : UseCase.values[v]),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          enabled: false,
          height: 34,
          child: Text(
            l.modelsChooseGoal,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
        ),
        for (final u in UseCase.values)
          PopupMenuItem<int>(
            value: u.index,
            height: 50,
            child: Row(
              children: [
                Icon(
                  u.icon,
                  size: 18,
                  color: u == goal ? DeskColors.green : palette.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        u.localizedLabel(l),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: u == goal
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: u == goal ? DeskColors.green : null,
                        ),
                      ),
                      Text(
                        u.localizedBlurb(l),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (u == goal)
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: DeskColors.green,
                  ),
              ],
            ),
          ),
        if (goal != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem<int>(
            value: _clear,
            height: 40,
            child: Row(
              children: [
                Icon(Icons.close_rounded, size: 18, color: palette.textMuted),
                const SizedBox(width: 12),
                Text(l.modelsClearGoal, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ],
      child: Hoverable(
        cursor: SystemMouseCursors.click,
        builder: (context, hovered) => AnimatedContainer(
          duration: DeskMotion.fast,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: goal != null
                ? DeskColors.green.withValues(
                    alpha: palette.isDark ? 0.16 : 0.10,
                  )
                : hovered
                ? Color.alphaBlend(
                    scheme.onSurface.withValues(alpha: 0.04),
                    palette.panel,
                  )
                : palette.panel,
            borderRadius: BorderRadius.circular(DeskSize.radiusM),
            border: Border.all(
              color: goal != null
                  ? DeskColors.green.withValues(alpha: 0.4)
                  : palette.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                goal?.icon ?? Icons.flag_outlined,
                size: 16,
                color: goal != null ? DeskColors.green : palette.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                goal == null
                    ? '${l.modelsGoals}: ${s.noGoal}'
                    : l.modelsTargeting(goal.localizedLabel(l)),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: goal != null ? null : palette.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
