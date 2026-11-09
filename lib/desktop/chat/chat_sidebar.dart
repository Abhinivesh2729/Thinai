/// Conversation history: new chat, search (full text on desktop), date groups,
/// hover and right-click actions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../l10n/desk_l10n.dart';
import '../shell/desk_nav.dart';
import '../storage/sqlite_chat_store.dart';
import '../theme/desk_theme.dart';
import '../widgets/hover.dart';

class ChatSidebar extends ConsumerStatefulWidget {
  const ChatSidebar({super.key});

  @override
  ConsumerState<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends ConsumerState<ChatSidebar> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  String _query = '';

  /// Ids matching [_query] in best-match order, from the full-text index.
  List<String>? _hits;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 160), () async {
      final q = value.trim();
      final notifier = ref.read(chatSessionsProvider.notifier);
      List<String>? hits;
      if (q.isNotEmpty && notifier is SqliteChatSessionsController) {
        hits = await notifier.search(q);
      }
      if (!mounted) return;
      setState(() {
        _query = q;
        _hits = hits;
      });
    });
  }

  List<ChatConversation> _filtered(List<ChatConversation> all) {
    if (_query.isEmpty) return all;
    final hits = _hits;
    if (hits != null) {
      final byId = {for (final c in all) c.id: c};
      return [
        for (final id in hits)
          if (byId[id] != null) byId[id]!,
      ];
    }
    final q = _query.toLowerCase();
    return [
      for (final c in all)
        if (c.title.toLowerCase().contains(q) ||
            c.preview.toLowerCase().contains(q))
          c,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = ShellStrings.of(context);
    final palette = DeskPalette.of(context);
    // Only the list's shape matters here; streaming text into the open chat
    // changes the active conversation every frame, so watch titles and order
    // rather than the whole state.
    final sessions = ref.watch(chatSessionsProvider.select(_SidebarView.from));
    final conversations = _filtered(sessions.conversations);
    ref.listen<int>(
      deskFocusSearchProvider,
      (_, _) => _searchFocus.requestFocus(),
    );

    return Container(
      width: DeskSize.sidebarWidth,
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border(right: BorderSide(color: palette.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: _NewChatButton(
              label: s.newChat,
              onTap: () {
                ref.read(chatSessionsProvider.notifier).startNewChat();
                ref.read(deskFocusComposerProvider.notifier).state++;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: TextField(
              controller: _search,
              focusNode: _searchFocus,
              onChanged: _onQuery,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: s.searchChats,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: palette.textFaint,
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 36),
                fillColor: palette.canvas,
                suffixIcon: _query.isEmpty
                    ? null
                    : DeskIconButton(
                        icon: Icons.close_rounded,
                        tooltip: '',
                        size: 28,
                        iconSize: 14,
                        onPressed: () {
                          _search.clear();
                          _onQuery('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: conversations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _query.isEmpty ? s.noChatsYet : s.noMatches,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textFaint,
                        ),
                      ),
                    ),
                  )
                : _GroupedList(
                    conversations: conversations,
                    activeId: sessions.activeId,
                    grouped: _query.isEmpty,
                  ),
          ),
        ],
      ),
    );
  }
}

/// The parts of [ChatSessions] the sidebar draws. Equal when titles, order and
/// the open chat are unchanged, so a streaming reply does not rebuild it.
class _SidebarView {
  _SidebarView(this.conversations, this.activeId, this._key);

  final List<ChatConversation> conversations;
  final String? activeId;
  final String _key;

  static _SidebarView from(ChatSessions s) {
    final key = StringBuffer(s.activeId ?? '-');
    for (final c in s.conversations) {
      key
        ..write('|')
        ..write(c.id)
        ..write(c.customTitle ?? '')
        ..write(c.turns.isEmpty ? '' : c.turns.first.content.length)
        ..write(c.updatedAt.millisecondsSinceEpoch ~/ 60000);
    }
    return _SidebarView(s.conversations, s.activeId, key.toString());
  }

  @override
  bool operator ==(Object other) => other is _SidebarView && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Hoverable(
      cursor: SystemMouseCursors.click,
      builder: (context, hovered) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DeskMotion.fast,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: hovered
                ? DeskColors.green.withValues(alpha: 0.12)
                : palette.canvas,
            borderRadius: BorderRadius.circular(DeskSize.radiusM),
            border: Border.all(
              color: hovered
                  ? DeskColors.green.withValues(alpha: 0.45)
                  : palette.hairline,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_square, size: 17, color: DeskColors.green),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                'Ctrl N',
                style: TextStyle(fontSize: 11, color: palette.textFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.conversations,
    required this.activeId,
    required this.grouped,
  });

  final List<ChatConversation> conversations;
  final String? activeId;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final s = ShellStrings.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String group(DateTime t) {
      final d = DateTime(t.year, t.month, t.day);
      final days = today.difference(d).inDays;
      if (days <= 0) return s.today;
      if (days == 1) return s.yesterday;
      if (days < 7) return s.previous7;
      if (t.year == now.year && t.month == now.month) return s.thisMonth;
      return s.older;
    }

    final items = <Object>[];
    String? last;
    for (final c in conversations) {
      if (grouped) {
        final g = group(c.updatedAt);
        if (g != last) {
          items.add(g);
          last = g;
        }
      }
      items.add(c);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: DeskPalette.of(context).textFaint,
              ),
            ),
          );
        }
        final c = item as ChatConversation;
        return _ChatTile(
          key: ValueKey(c.id),
          conversation: c,
          active: c.id == activeId,
        );
      },
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({
    super.key,
    required this.conversation,
    required this.active,
  });
  final ChatConversation conversation;
  final bool active;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final s = ShellStrings.of(context);
    final controller = TextEditingController(
      text: conversation.localizedTitle(context.l10n),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.rename),
        content: SizedBox(
          width: 380,
          child: TextField(
            controller: controller,
            autofocus: true,
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(s.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) {
      await ref
          .read(chatSessionsProvider.notifier)
          .rename(conversation.id, name);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final s = ShellStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteChatTitle),
        content: Text(s.deleteChatBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DeskColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(chatSessionsProvider.notifier).delete(conversation.id);
    }
  }

  void _menu(BuildContext context, WidgetRef ref, Offset at) {
    final s = ShellStrings.of(context);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      items: [
        PopupMenuItem(value: 'rename', child: Text(s.rename)),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            s.delete,
            style: const TextStyle(color: DeskColors.danger),
          ),
        ),
      ],
    ).then((v) {
      if (!context.mounted) return;
      if (v == 'rename') _rename(context, ref);
      if (v == 'delete') _delete(context, ref);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Hoverable(
      cursor: SystemMouseCursors.click,
      builder: (context, hovered) => GestureDetector(
        onTap: () =>
            ref.read(chatSessionsProvider.notifier).open(conversation.id),
        onSecondaryTapDown: (d) => _menu(context, ref, d.globalPosition),
        child: AnimatedContainer(
          duration: DeskMotion.fast,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
          decoration: BoxDecoration(
            color: active
                ? DeskColors.green.withValues(alpha: 0.12)
                : hovered
                ? scheme.onSurface.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DeskSize.radiusS + 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.localizedTitle(context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? scheme.onSurface : palette.textMuted,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: DeskMotion.fast,
                opacity: hovered || active ? 1 : 0,
                child: Builder(
                  builder: (context) => DeskIconButton(
                    icon: Icons.more_horiz_rounded,
                    tooltip: '',
                    size: 26,
                    iconSize: 16,
                    onPressed: () {
                      final box = context.findRenderObject() as RenderBox;
                      _menu(
                        context,
                        ref,
                        box.localToGlobal(box.size.bottomLeft(Offset.zero)),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
