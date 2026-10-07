import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';

/// The list of saved conversations, reached from the Chat tab.
///
/// Tapping a row opens that chat and returns; the Chat tab is always showing
/// exactly one conversation, so switching is the only thing this page does
/// besides deleting.
class ChatHistoryPage extends ConsumerStatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  ConsumerState<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends ConsumerState<ChatHistoryPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(chatSessionsProvider);
    final controller = ref.read(chatSessionsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    // Apply search filter
    final allConversations = sessions.conversations;
    final filtered = _query.isEmpty
        ? allConversations
        : allConversations.where((c) {
            final q = _query.toLowerCase();
            return c.title.toLowerCase().contains(q) ||
                c.preview.toLowerCase().contains(q);
          }).toList();

    // Group by date sections
    final groups = _groupByDate(filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat history'),
        actions: [
          if (sessions.conversations.isNotEmpty)
            IconButton(
              tooltip: 'Delete all chats',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () async {
                final ok = await _confirm(
                  context,
                  title: 'Delete all chats?',
                  body:
                      'Every saved conversation is removed. This cannot be '
                      'undone.',
                  action: 'Delete all',
                );
                if (ok) await controller.deleteAll();
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('New chat'),
        backgroundColor: const Color(0xFF2CA048),
        foregroundColor: Colors.white,
        onPressed: () {
          controller.startNewChat();
          Navigator.of(context).pop();
        },
      ),
      body: sessions.conversations.isEmpty
          ? const _EmptyHistory()
          : Column(
              children: [
                // Live search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                  child: _SearchBar(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _NoSearchResults(query: _query)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: _flatCount(groups),
                          itemBuilder: (context, index) {
                            final item = _flatItem(groups, index);
                            if (item is String) {
                              return _DateHeader(label: item);
                            }
                            final conversation = item as ChatConversation;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _SwipeableConversationCard(
                                conversation: conversation,
                                current:
                                    conversation.id == sessions.activeId,
                                onOpen: () {
                                  controller.open(conversation.id);
                                  Navigator.of(context).pop();
                                },
                                onRename: () async {
                                  final newTitle = await _showRenameDialog(
                                    context,
                                    conversation.title,
                                  );
                                  if (newTitle != null &&
                                      newTitle.isNotEmpty) {
                                    await controller.rename(
                                      conversation.id,
                                      newTitle,
                                    );
                                  }
                                },
                                onDelete: () async {
                                  final ok = await _confirm(
                                    context,
                                    title: 'Delete this chat?',
                                    body: conversation.title,
                                    action: 'Delete',
                                  );
                                  if (ok) {
                                    await controller
                                        .delete(conversation.id);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      backgroundColor: scheme.surface,
    );
  }
}

// ─── Date grouping logic ──────────────────────────────────────────────────

/// Groups conversations by relative date buckets.
List<_DateGroup> _groupByDate(List<ChatConversation> conversations) {
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
    if (todayList.isNotEmpty) _DateGroup('Today', todayList),
    if (yesterdayList.isNotEmpty) _DateGroup('Yesterday', yesterdayList),
    if (weekList.isNotEmpty) _DateGroup('Previous 7 Days', weekList),
    if (monthList.isNotEmpty) _DateGroup('This Month', monthList),
    if (olderList.isNotEmpty) _DateGroup('Older', olderList),
  ];
}

class _DateGroup {
  final String label;
  final List<ChatConversation> conversations;
  const _DateGroup(this.label, this.conversations);
}

/// Total items for the flat list (headers + cards).
int _flatCount(List<_DateGroup> groups) {
  var count = 0;
  for (final g in groups) {
    count += 1 + g.conversations.length; // header + items
  }
  return count;
}

/// Returns either a `String` (date header) or `ChatConversation` (card data).
Object _flatItem(List<_DateGroup> groups, int index) {
  var offset = 0;
  for (final g in groups) {
    if (index == offset) return g.label;
    offset++;
    if (index < offset + g.conversations.length) {
      return g.conversations[index - offset];
    }
    offset += g.conversations.length;
  }
  return groups.last.label; // shouldn't reach here
}

// ─── Widgets ──────────────────────────────────────────────────────────────

/// Premium search bar sitting at the top of the history list.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(fontSize: 14, color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search conversations…',
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Section header for date grouping.
class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Wraps a conversation card with swipe-to-delete behaviour.
class _SwipeableConversationCard extends StatelessWidget {
  const _SwipeableConversationCard({
    required this.conversation,
    required this.current,
    required this.onOpen,
    required this.onDelete,
    this.onRename,
  });

  final ChatConversation conversation;
  final bool current;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(conversation.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return _confirm(
          context,
          title: 'Delete this chat?',
          body: conversation.title,
          action: 'Delete',
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      child: _ConversationCard(
        conversation: conversation,
        current: current,
        onOpen: onOpen,
        onRename: onRename,
        onDelete: onDelete,
      ),
    );
  }
}

/// No search results message.
class _NoSearchResults extends StatelessWidget {
  final String query;
  const _NoSearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No chats matching "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(c).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(c, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> _showRenameDialog(
  BuildContext context,
  String currentTitle,
) async {
  final controller = TextEditingController(text: currentTitle);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: currentTitle.length,
  );
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Rename chat'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Conversation title',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        onSubmitted: (v) => Navigator.pop(c, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2CA048),
          ),
          onPressed: () => Navigator.pop(c, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.current,
    required this.onOpen,
    required this.onDelete,
    this.onRename,
  });

  final ChatConversation conversation;

  /// The conversation the Chat tab is already showing.
  final bool current;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const logoGreen = Color(0xFF2CA048);
    return Material(
      color: current ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        onLongPress: onRename,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: current
                  ? logoGreen.withValues(alpha: 0.3)
                  : scheme.outline,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chat icon badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: current
                      ? logoGreen
                      : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  current
                      ? Icons.chat_rounded
                      : Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color:
                      current ? Colors.white : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row with active badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (current) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: logoGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: logoGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Preview
                    Text(
                      conversation.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Metadata row
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatChatTimestamp(conversation.updatedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${conversation.turns.length} messages',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onRename != null)
                IconButton(
                  tooltip: 'Rename chat',
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  color: scheme.onSurfaceVariant,
                  onPressed: onRename,
                ),
              // Delete button
              IconButton(
                tooltip: 'Delete chat',
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                color: scheme.onSurfaceVariant,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 30,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No saved chats yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Start a conversation and it will appear here.\nEverything stays on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Relative for anything recent, absolute once it stops being useful.
String formatChatTimestamp(DateTime when, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(when);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final date = '${when.day} ${months[when.month - 1]}';
  return when.year == reference.year ? date : '$date ${when.year}';
}
