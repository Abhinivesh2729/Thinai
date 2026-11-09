/// The slim left rail: orb mark, the four places, settings at the bottom.
/// The selection pill slides between items instead of jumping.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../chat/desk_chat_controller.dart';
import '../l10n/desk_l10n.dart';
import '../theme/desk_theme.dart';
import '../widgets/hover.dart';
import '../widgets/orb.dart';
import 'desk_nav.dart';

class DeskRail extends ConsumerWidget {
  const DeskRail({super.key});

  static const _itemHeight = 56.0;
  static const _top = [
    DeskPage.chat,
    DeskPage.models,
    DeskPage.lab,
    DeskPage.server,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ShellStrings.of(context);
    final palette = DeskPalette.of(context);
    final page = ref.watch(deskPageProvider);
    final serverOn = ref.watch(
      serverControllerProvider.select((s) => s.running),
    );
    final downloads = ref.watch(downloadsProvider.select((d) => d.length));
    final index = _top.indexOf(page);

    void go(DeskPage p) => ref.read(deskPageProvider.notifier).state = p;

    return Container(
      width: DeskSize.railWidth,
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border(right: BorderSide(color: palette.hairline)),
      ),
      child: Column(
        children: [
          SizedBox(height: Platform.isMacOS ? 40 : 14),
          Tooltip(
            message: s.newChat,
            child: GestureDetector(
              onTap: () {
                ref.read(chatSessionsProvider.notifier).startNewChat();
                go(DeskPage.chat);
                ref.read(deskFocusComposerProvider.notifier).state++;
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Orb(size: 44, controller: ref.watch(deskOrbProvider)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: _itemHeight * _top.length,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: DeskMotion.medium,
                  curve: DeskMotion.spring,
                  top: index < 0 ? -_itemHeight : index * _itemHeight + 6,
                  left: 12,
                  right: 12,
                  height: _itemHeight - 12,
                  child: AnimatedOpacity(
                    duration: DeskMotion.fast,
                    opacity: index < 0 ? 0 : 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: DeskColors.green.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(DeskSize.radiusM),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    _RailItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: s.navChat,
                      selected: page == DeskPage.chat,
                      onTap: () => go(DeskPage.chat),
                    ),
                    _RailItem(
                      icon: Icons.view_in_ar_outlined,
                      activeIcon: Icons.view_in_ar_rounded,
                      label: s.navModels,
                      selected: page == DeskPage.models,
                      badge: downloads > 0 ? '$downloads' : null,
                      onTap: () => go(DeskPage.models),
                    ),
                    _RailItem(
                      icon: Icons.speed_outlined,
                      activeIcon: Icons.speed_rounded,
                      label: s.navLab,
                      selected: page == DeskPage.lab,
                      onTap: () => go(DeskPage.lab),
                    ),
                    _RailItem(
                      icon: Icons.dns_outlined,
                      activeIcon: Icons.dns_rounded,
                      label: s.navServer,
                      selected: page == DeskPage.server,
                      dot: serverOn,
                      onTap: () => go(DeskPage.server),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          _RailItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: s.navSettings,
            selected: page == DeskPage.settings,
            onTap: () => go(DeskPage.settings),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.dot = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      preferBelow: false,
      verticalOffset: 0,
      margin: const EdgeInsets.only(left: 64),
      child: Hoverable(
        cursor: SystemMouseCursors.click,
        builder: (context, hovered) => GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: DeskRail._itemHeight,
            width: DeskSize.railWidth,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    duration: DeskMotion.fast,
                    scale: hovered && !selected ? 1.08 : 1,
                    child: AnimatedSwitcher(
                      duration: DeskMotion.fast,
                      child: Icon(
                        selected ? activeIcon : icon,
                        key: ValueKey(selected),
                        size: 22,
                        color: selected
                            ? DeskColors.green
                            : hovered
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (dot)
                    Positioned(
                      right: -3,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: DeskColors.mint,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: DeskColors.mint.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (badge != null)
                    Positioned(
                      right: -10,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: DeskColors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
