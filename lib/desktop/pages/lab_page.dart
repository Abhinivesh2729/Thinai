/// The Lab: where this PC becomes a known quantity.
///
/// Three tabs: Speed (the benchmark), Tamil score (the Tamil eval and a
/// leaderboard) and GPU (find the card, CPU vs GPU). Each tab is built the
/// first time it is opened and then kept alive, so a run keeps going while
/// another tab is on screen; hidden tabs get TickerMode off, like the shell's
/// pages.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../l10n/lab_strings.dart';
import '../theme/desk_theme.dart';
import '../widgets/hover.dart';
import 'lab/gpu_tab.dart';
import 'lab/lab_common.dart';
import 'lab/speed_tab.dart';
import 'lab/tamil_tab.dart';

enum _LabTab { speed, tamil, gpu }

class DeskLabPage extends ConsumerStatefulWidget {
  const DeskLabPage({super.key});

  @override
  ConsumerState<DeskLabPage> createState() => _DeskLabPageState();
}

class _DeskLabPageState extends ConsumerState<DeskLabPage> {
  _LabTab _tab = _LabTab.speed;
  final _visited = <_LabTab>{_LabTab.speed};

  Widget _build(_LabTab tab) => switch (tab) {
    _LabTab.speed => const LabSpeedTab(),
    _LabTab.tamil => const LabTamilTab(),
    _LabTab.gpu => const LabGpuTab(),
  };

  void _select(_LabTab tab) => setState(() {
    _tab = tab;
    _visited.add(tab);
  });

  @override
  Widget build(BuildContext context) {
    final strings = LabStrings.of(context);
    final busy = ref.watch(labBusyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
          child: EnterAnimation(child: _Header(strings: strings)),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _TabBar(
              current: _tab,
              labels: {
                _LabTab.speed: strings.tabSpeed,
                _LabTab.tamil: strings.tabTamil,
                _LabTab.gpu: strings.tabGpu,
              },
              running: {
                if (busy == LabJob.speed) _LabTab.speed,
                if (busy == LabJob.gpu) _LabTab.gpu,
              },
              onSelect: _select,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Stack(
            children: [
              for (final tab in _LabTab.values)
                if (_visited.contains(tab))
                  _TabLayer(
                    key: ValueKey(tab),
                    active: tab == _tab,
                    child: _build(tab),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.strings});

  final LabStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(deviceProfileProvider).valueOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: context.tracking(-0.6),
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.subtitle,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        AnimatedSwitcher(
          duration: DeskMotion.medium,
          child: profile == null
              ? const SizedBox.shrink()
              : Container(
                  key: const ValueKey('chip'),
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: palette.panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.computer_rounded,
                        size: 15,
                        color: DeskColors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        profile.localizedSummary(context.l10n),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                          fontFeatures: tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Segmented tab bar with a highlight that slides between segments.
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.current,
    required this.labels,
    required this.running,
    required this.onSelect,
  });

  final _LabTab current;
  final Map<_LabTab, String> labels;

  /// Tabs with a measurement in flight, marked with a live dot.
  final Set<_LabTab> running;
  final ValueChanged<_LabTab> onSelect;

  static const _segment = 168.0;
  static const _height = 40.0;

  static IconData _icon(_LabTab tab) => switch (tab) {
    _LabTab.speed => Icons.speed_rounded,
    _LabTab.tamil => Icons.translate_rounded,
    _LabTab.gpu => Icons.memory_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    const tabs = _LabTab.values;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(DeskSize.radiusM + 2),
        border: Border.all(color: palette.hairline),
      ),
      child: SizedBox(
        width: _segment * tabs.length,
        height: _height,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: DeskMotion.medium,
              curve: DeskMotion.spring,
              left: _segment * current.index,
              top: 0,
              width: _segment,
              height: _height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: DeskColors.green.withValues(
                    alpha: palette.isDark ? 0.18 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(DeskSize.radiusM - 2),
                  border: Border.all(
                    color: DeskColors.green.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final tab in tabs)
                  SizedBox(
                    width: _segment,
                    height: _height,
                    child: Semantics(
                      button: true,
                      selected: tab == current,
                      child: Hoverable(
                        cursor: SystemMouseCursors.click,
                        builder: (context, hovered) {
                          final selected = tab == current;
                          final fg = selected
                              ? DeskColors.green
                              : hovered
                              ? scheme.onSurface
                              : palette.textMuted;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onSelect(tab),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_icon(tab), size: 16, color: fg),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: AnimatedDefaultTextStyle(
                                    duration: DeskMotion.fast,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: fg,
                                    ),
                                    child: Text(
                                      labels[tab]!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (running.contains(tab)) ...[
                                  const SizedBox(width: 8),
                                  const _LiveDot(),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
    child: Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: DeskColors.mint,
      ),
    ),
  );
}

class _TabLayer extends StatelessWidget {
  const _TabLayer({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !active,
        child: TickerMode(
          enabled: active,
          child: AnimatedOpacity(
            duration: DeskMotion.medium,
            curve: DeskMotion.ease,
            opacity: active ? 1 : 0,
            child: AnimatedSlide(
              duration: DeskMotion.medium,
              curve: DeskMotion.ease,
              offset: active ? Offset.zero : const Offset(0, 0.01),
              child: ExcludeFocus(excluding: !active, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
