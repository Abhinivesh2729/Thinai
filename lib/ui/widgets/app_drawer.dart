import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../pages/chat_history_page.dart';
import '../pages/settings_page.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// The shell's scaffold, so a page's own app bar can open the shell's drawer.
/// Each section brings its own [Scaffold], and `Scaffold.of` from inside one
/// would find that instead.
final shellScaffoldKey = GlobalKey<ScaffoldState>();

/// The leading button on every section's app bar.
class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Menu',
      icon: const Icon(Icons.menu_rounded),
      onPressed: () => shellScaffoldKey.currentState?.openDrawer(),
    );
  }
}

/// Everything that is not the conversation: new chat, recent chats, the
/// Models and Server sections, and Settings.
///
/// Chat is the app; the rest is reached from here. A bottom bar gave three
/// equal tabs to things used very unequally, and took a permanent strip off
/// the screen the conversation needs most.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  /// Recent chats listed before "All chats".
  static const _recent = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final section = ref.watch(shellTabIndexProvider);
    final sessions = ref.watch(chatSessionsProvider);
    final activeId = ref.watch(activeModelIdProvider);
    final recent = sessions.conversations.take(_recent).toList();
    final busy = ref.watch(chatGeneratingProvider);

    /// Switching chats mid-reply would stream the rest of the answer into
    /// whichever conversation is open next.
    void whenIdle(VoidCallback action) {
      if (!busy) {
        action();
        return;
      }
      Navigator.of(context).pop();
      showToast(context, 'Wait for the reply to finish, or stop it first.');
    }

    void go(int index) {
      ref.read(shellTabIndexProvider.notifier).state = index;
      Navigator.of(context).pop();
    }

    void push(Widget page) {
      Navigator.of(context)
        ..pop()
        ..push(MaterialPageRoute(builder: (_) => page));
    }

    return Drawer(
      width: 308,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(Radii.xl)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.lg,
                Space.lg,
                Space.md,
              ),
              child: Row(
                children: [
                  const ThinaiMark(size: 36),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thinai', style: theme.textTheme.titleMedium),
                        Text(
                          activeId == null ? 'No model loaded' : 'On-device AI',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.xs,
                Space.lg,
                Space.md,
              ),
              child: FilledButton.icon(
                icon: const Icon(Icons.add_comment_outlined, size: 18),
                label: const Text('New chat'),
                onPressed: () => whenIdle(() {
                  ref.read(chatSessionsProvider.notifier).startNewChat();
                  go(0);
                }),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                children: [
                  _DrawerItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    selectedIcon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    selected: section == 0,
                    onTap: () => go(0),
                  ),
                  _DrawerItem(
                    icon: Icons.auto_awesome_outlined,
                    selectedIcon: Icons.auto_awesome_rounded,
                    label: 'Models',
                    selected: section == 1,
                    onTap: () => go(1),
                  ),
                  // A rack, not a cloud: the point of this server is that it
                  // runs on the phone, and a cloud glyph says the opposite.
                  _DrawerItem(
                    icon: Icons.dns_outlined,
                    selectedIcon: Icons.dns_rounded,
                    label: 'Server',
                    selected: section == 2,
                    onTap: () => go(2),
                  ),
                  if (recent.isNotEmpty) ...[
                    const SectionLabel(
                      'Recent chats',
                      padding: EdgeInsets.fromLTRB(
                        Space.md,
                        Space.xl,
                        Space.md,
                        Space.sm,
                      ),
                    ),
                    for (final c in recent)
                      _RecentChat(
                        title: c.title,
                        current: c.id == sessions.activeId && section == 0,
                        onTap: () => whenIdle(() {
                          ref.read(chatSessionsProvider.notifier).open(c.id);
                          go(0);
                        }),
                      ),
                    _DrawerItem(
                      icon: Icons.history_rounded,
                      label: 'All chats',
                      dense: true,
                      onTap: () => push(const ChatHistoryPage()),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: _DrawerItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => push(const SettingsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selectedIcon,
    this.selected = false,
    this.dense = false,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected
            ? scheme.onSurface.withValues(alpha: 0.07)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: dense ? 10 : Space.md,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? (selectedIcon ?? icon) : icon,
                  size: dense ? 18 : 21,
                  color: fg,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: dense ? 14 : 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? scheme.onSurface : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentChat extends StatelessWidget {
  const _RecentChat({
    required this.title,
    required this.current,
    required this.onTap,
  });

  final String title;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: current
          ? scheme.onSurface.withValues(alpha: 0.07)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: 10,
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: current ? FontWeight.w600 : FontWeight.w400,
              color: current ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
