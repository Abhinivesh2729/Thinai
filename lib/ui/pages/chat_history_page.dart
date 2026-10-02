import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// The list of saved conversations, reached from the Chat tab.
///
/// Tapping a row opens that chat and returns; the Chat tab is always showing
/// exactly one conversation, so switching is the only thing this page does
/// besides deleting.
class ChatHistoryPage extends ConsumerWidget {
  const ChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(chatSessionsProvider);
    final controller = ref.read(chatSessionsProvider.notifier);
    final groups = _groupByRecency(sessions.conversations);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat history'),
        actions: [
          if (sessions.conversations.isNotEmpty)
            IconButton(
              tooltip: 'Delete all chats',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Delete all chats?',
                  message:
                      'Every saved conversation is removed. This cannot be '
                      'undone.',
                  confirmLabel: 'Delete all',
                  destructive: true,
                );
                if (ok) await controller.deleteAll();
              },
            ),
          const SizedBox(width: Space.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('New chat'),
        onPressed: () {
          controller.startNewChat();
          Navigator.of(context).pop();
        },
      ),
      body: sessions.conversations.isEmpty
          ? const EmptyState(
              icon: Icons.forum_outlined,
              title: 'No saved chats yet',
              message: 'Conversations are saved on this device.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, 112),
              children: [
                for (final group in groups) ...[
                  SectionLabel(
                    group.label,
                    padding: EdgeInsets.fromLTRB(
                      Space.xs,
                      identical(group, groups.first) ? Space.sm : Space.xxl,
                      Space.xs,
                      Space.sm,
                    ),
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < group.items.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: Space.lg),
                          _ConversationRow(
                            conversation: group.items[i],
                            current: group.items[i].id == sessions.activeId,
                            onOpen: () {
                              controller.open(group.items[i].id);
                              Navigator.of(context).pop();
                            },
                            onDelete: () async {
                              final conversation = group.items[i];
                              final ok = await confirmAction(
                                context,
                                title: 'Delete this chat?',
                                message: conversation.title,
                                confirmLabel: 'Delete',
                                destructive: true,
                              );
                              if (ok) await controller.delete(conversation.id);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Group {
  _Group(this.label);

  final String label;
  final List<ChatConversation> items = [];
}

/// Buckets conversations the way people remember them: today, this week, and
/// everything before. Order within each bucket is kept as given.
List<_Group> _groupByRecency(
  List<ChatConversation> conversations, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final weekAgo = today.subtract(const Duration(days: 7));
  final groups = <String, _Group>{};
  for (final c in conversations) {
    final label = !c.updatedAt.isBefore(today)
        ? 'Today'
        : !c.updatedAt.isBefore(weekAgo)
        ? 'Previous 7 days'
        : 'Older';
    groups.putIfAbsent(label, () => _Group(label)).items.add(c);
  }
  return [
    for (final label in const ['Today', 'Previous 7 days', 'Older'])
      if (groups[label] != null) groups[label]!,
  ];
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conversation,
    required this.current,
    required this.onOpen,
    required this.onDelete,
  });

  final ChatConversation conversation;

  /// The conversation the Chat tab is already showing.
  final bool current;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final meta = theme.textTheme.bodySmall?.copyWith(fontSize: 11.5);
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 14, Space.xs, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 14.5),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    conversation.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      Text(
                        formatChatTimestamp(conversation.updatedAt),
                        style: meta,
                      ),
                      Text('  ·  ', style: meta),
                      Text(
                        conversation.turns.length == 1
                            ? '1 message'
                            : '${conversation.turns.length} messages',
                        style: meta,
                      ),
                      if (current) ...[
                        const SizedBox(width: Space.sm),
                        const Tag('OPEN', tone: TagTone.accent, dense: true),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete chat',
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: scheme.onSurfaceVariant,
              onPressed: onDelete,
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
