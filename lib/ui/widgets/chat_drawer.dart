import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models_repo/model_store.dart';
import '../../state/providers.dart';
import '../pages/about_page.dart';
import '../pages/settings_page.dart';
import 'model_settings_sheet.dart';

/// Global key for the shell scaffold so the drawer can be opened from
/// the top-left menu button in the chat screen.
final GlobalKey<ScaffoldState> shellScaffoldKey = GlobalKey<ScaffoldState>();

/// ChatGPT / Claude / Gemini styled side navigation drawer.
///
/// Features:
/// - Sleek "+ New chat" button at the top
/// - Instant live search across all past conversations
/// - Conversations grouped by relative date (Today, Yesterday, Previous 7 Days, etc.)
/// - Active chat visual indicator
/// - Long-press & 3-dots menu to Rename or Delete conversations
/// - Quick links in footer to Settings, Models, and About
class ChatDrawer extends ConsumerStatefulWidget {
  const ChatDrawer({super.key});

  @override
  ConsumerState<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<ChatDrawer> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(chatSessionsProvider);
    final controller = ref.read(chatSessionsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const logoGreen = Color(0xFF2CA048);

    // Apply search filter
    final allConversations = sessions.conversations;
    final filtered = _searchQuery.isEmpty
        ? allConversations
        : allConversations.where((c) {
            final q = _searchQuery.toLowerCase();
            return c.title.toLowerCase().contains(q) ||
                c.preview.toLowerCase().contains(q);
          }).toList();

    final groups = _groupByDate(filtered);

    return Drawer(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top branding & close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
              child: Row(
                children: [
                  Image.asset(
                    isDark
                        ? 'assets/images/logo_dark.png'
                        : 'assets/images/logo_transparent.png',
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: logoGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 18,
                            color: logoGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Thinai',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close menu',
                    color: scheme.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Prominent "+ New chat" button (ChatGPT / Claude style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Material(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    controller.startNewChat();
                    ref.read(shellTabIndexProvider.notifier).state = 0;
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: logoGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'New chat',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.edit_square,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Live Search Bar
            if (allConversations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: TextStyle(fontSize: 13, color: scheme.onSurface),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search chats…',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 9,
                        horizontal: 8,
                      ),
                    ),
                  ),
                ),
              ),

            // Conversation history list
            Expanded(
              child: allConversations.isEmpty
                  ? _EmptyDrawerHistory(
                      onNewChat: () {
                        controller.startNewChat();
                        ref.read(shellTabIndexProvider.notifier).state = 0;
                        Navigator.of(context).pop();
                      },
                    )
                  : filtered.isEmpty
                      ? _DrawerNoResults(query: _searchQuery)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          itemCount: _flatCount(groups),
                          itemBuilder: (context, index) {
                            final item = _flatItem(groups, index);
                            if (item is String) {
                              return _DrawerDateHeader(label: item);
                            }
                            final conv = item as ChatConversation;
                            final isActive = conv.id == sessions.activeId;
                            return _DrawerConversationTile(
                              conversation: conv,
                              isActive: isActive,
                              onTap: () {
                                controller.open(conv.id);
                                ref.read(shellTabIndexProvider.notifier).state = 0;
                                Navigator.of(context).pop();
                              },
                              onLongPress: () {
                                HapticFeedback.mediumImpact();
                                _showConversationOptions(context, ref, conv);
                              },
                              onOptionsTap: () {
                                _showConversationOptions(context, ref, conv);
                              },
                            );
                          },
                        ),
            ),

            const Divider(height: 1),

            // Footer options (Settings, Models, About)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DrawerFooterTile(
                    icon: Icons.tune_rounded,
                    label: 'Settings',
                    subtitle: 'Context window & temperature',
                    onTap: () => _openModelSettings(context),
                  ),
                  _DrawerFooterTile(
                    icon: Icons.memory_rounded,
                    label: 'Models',
                    onTap: () {
                      ref.read(shellTabIndexProvider.notifier).state = 1;
                      Navigator.of(context).pop();
                    },
                  ),
                  _DrawerFooterTile(
                    icon: Icons.settings_outlined,
                    label: 'App settings',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                  _DrawerFooterTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About Thinai',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the options bottom sheet for renaming or deleting a conversation.
  void _showConversationOptions(
    BuildContext context,
    WidgetRef ref,
    ChatConversation conversation,
  ) {
    final scheme = Theme.of(context).colorScheme;
    const logoGreen = Color(0xFF2CA048);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Conversation title header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: logoGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: logoGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 6),

                // Rename option
                ListTile(
                  leading: const Icon(Icons.edit_outlined, size: 21),
                  title: const Text(
                    'Rename title',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showRenameDialog(context, ref, conversation);
                  },
                ),

                // Delete option
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    size: 21,
                    color: scheme.error,
                  ),
                  title: Text(
                    'Delete chat',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.error,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showDeleteDialog(context, ref, conversation);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog to edit and rename the conversation title.
  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    ChatConversation conversation,
  ) {
    final scheme = Theme.of(context).colorScheme;
    const logoGreen = Color(0xFF2CA048);
    final renameController = TextEditingController(text: conversation.title);
    renameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: conversation.title.length,
    );

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Rename chat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: renameController,
                autofocus: true,
                style: TextStyle(fontSize: 14, color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Conversation title',
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: logoGreen, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) async {
                  final text = value.trim();
                  if (text.isNotEmpty) {
                    await ref
                        .read(chatSessionsProvider.notifier)
                        .rename(conversation.id, text);
                  }
                  if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: logoGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final text = renameController.text.trim();
                if (text.isNotEmpty) {
                  await ref
                      .read(chatSessionsProvider.notifier)
                      .rename(conversation.id, text);
                }
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog to confirm deletion of a conversation.
  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ChatConversation conversation,
  ) {
    final scheme = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete chat?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete "${conversation.title}"? This cannot be undone.',
            style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await ref
                    .read(chatSessionsProvider.notifier)
                    .delete(conversation.id);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// Opens the model settings sheet to configure context window and temperature.
  Future<void> _openModelSettings(BuildContext context) async {
    final activeId = ref.read(activeModelIdProvider);
    final store = ref.read(modelStoreProvider);
    LocalModel? target;

    if (activeId != null) {
      target = await store.findById(activeId);
    }

    if (target == null) {
      final list = await store.list();
      if (list.length == 1) {
        target = list.first;
      } else if (list.length > 1 && context.mounted) {
        target = await showDialog<LocalModel>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text(
              'Select model',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final m = list[i];
                  return ListTile(
                    leading: const Icon(Icons.memory_rounded),
                    title: Text(
                      m.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      m.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(dialogCtx).pop(m),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (target != null) {
      await showModelSettingsSheet(context, target);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No model loaded. Download or activate a model first.',
          ),
          action: SnackBarAction(
            label: 'Models',
            onPressed: () {
              ref.read(shellTabIndexProvider.notifier).state = 1;
            },
          ),
        ),
      );
    }
  }
}

/// A conversation row inside the side navigation drawer.
class _DrawerConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onOptionsTap;

  const _DrawerConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
    required this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const logoGreen = Color(0xFF2CA048);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive
            ? (Theme.of(context).brightness == Brightness.dark
                ? logoGreen.withValues(alpha: 0.16)
                : logoGreen.withValues(alpha: 0.10))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(
                      color: logoGreen.withValues(alpha: 0.35),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Active indicator line or subtle icon
                if (isActive)
                  Container(
                    width: 3,
                    height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: logoGreen,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                Icon(
                  isActive
                      ? Icons.chat_bubble_rounded
                      : Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: isActive ? logoGreen : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? scheme.onSurface : scheme.onSurface,
                    ),
                  ),
                ),
                // Trailing 3-dots button for easy access without long-pressing
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: onOptionsTap,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: isActive
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant.withValues(alpha: 0.7),
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

/// Date category header in the drawer (e.g. "TODAY", "YESTERDAY").
class _DrawerDateHeader extends StatelessWidget {
  final String label;

  const _DrawerDateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Footer navigation button (Models, Settings, About).
class _DrawerFooterTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _DrawerFooterTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: [
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state when no conversations have been created yet.
class _EmptyDrawerHistory extends StatelessWidget {
  final VoidCallback onNewChat;

  const _EmptyDrawerHistory({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 32,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Text(
              'No past conversations',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start a chat to keep history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// No search results view in drawer.
class _DrawerNoResults extends StatelessWidget {
  final String query;

  const _DrawerNoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No chats found for "$query"',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Date Grouping Helpers ──────────────────────────────────────────────────

List<_DrawerDateGroup> _groupByDate(List<ChatConversation> conversations) {
  if (conversations.isEmpty) return const [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekAgo = today.subtract(const Duration(days: 7));
  final monthAgo = today.subtract(const Duration(days: 30));

  final todayList = <ChatConversation>[];
  final yesterdayList = <ChatConversation>[];
  final weekList = <ChatConversation>[];
  final monthList = <ChatConversation>[];
  final olderList = <ChatConversation>[];

  for (final c in conversations) {
    final date = DateTime(c.updatedAt.year, c.updatedAt.month, c.updatedAt.day);
    if (!date.isBefore(today)) {
      todayList.add(c);
    } else if (!date.isBefore(yesterday)) {
      yesterdayList.add(c);
    } else if (!date.isBefore(weekAgo)) {
      weekList.add(c);
    } else if (!date.isBefore(monthAgo)) {
      monthList.add(c);
    } else {
      olderList.add(c);
    }
  }

  return [
    if (todayList.isNotEmpty) _DrawerDateGroup('Today', todayList),
    if (yesterdayList.isNotEmpty) _DrawerDateGroup('Yesterday', yesterdayList),
    if (weekList.isNotEmpty) _DrawerDateGroup('Previous 7 Days', weekList),
    if (monthList.isNotEmpty) _DrawerDateGroup('This Month', monthList),
    if (olderList.isNotEmpty) _DrawerDateGroup('Older', olderList),
  ];
}

class _DrawerDateGroup {
  final String label;
  final List<ChatConversation> conversations;
  const _DrawerDateGroup(this.label, this.conversations);
}

int _flatCount(List<_DrawerDateGroup> groups) {
  var count = 0;
  for (final g in groups) {
    count += 1 + g.conversations.length;
  }
  return count;
}

Object _flatItem(List<_DrawerDateGroup> groups, int index) {
  var offset = 0;
  for (final g in groups) {
    if (index == offset) return g.label;
    offset++;
    if (index < offset + g.conversations.length) {
      return g.conversations[index - offset];
    }
    offset += g.conversations.length;
  }
  return groups.last.label;
}
