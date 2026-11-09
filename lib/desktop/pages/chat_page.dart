/// Chat: history sidebar plus the conversation pane.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chat/chat_pane.dart';
import '../chat/chat_sidebar.dart';
import '../chat/desk_chat_controller.dart';
import '../shell/desk_nav.dart';
import '../theme/desk_theme.dart';
import '../widgets/toast.dart';
import '../../l10n/l10n.dart';
import '../../chat/attachment_error.dart';

class DeskChatPage extends ConsumerStatefulWidget {
  const DeskChatPage({super.key});

  @override
  ConsumerState<DeskChatPage> createState() => _DeskChatPageState();
}

class _DeskChatPageState extends ConsumerState<DeskChatPage> {
  @override
  void initState() {
    super.initState();
    // Turn controller notices into toasts, in the UI language.
    ref.read(deskChatProvider.notifier).notices.listen((n) {
      if (!mounted) return;
      final l10n = context.l10n;
      final controller = ref.read(deskChatProvider.notifier);
      final (text, tone) = switch (n.kind) {
        DeskNoticeKind.loadModelFirst => (
          l10n.chatLoadModelFirst,
          DeskTone.warning,
        ),
        DeskNoticeKind.modelMissing => (
          l10n.chatActiveModelMissing,
          DeskTone.error,
        ),
        DeskNoticeKind.engineError => (n.detail, DeskTone.error),
        DeskNoticeKind.searchBlocked => (
          l10n.chatSearchBlocked,
          DeskTone.warning,
        ),
        DeskNoticeKind.searchNoResults => (
          l10n.chatSearchNoResults,
          DeskTone.info,
        ),
        DeskNoticeKind.searchFailed => (
          l10n.chatSearchFailed,
          DeskTone.warning,
        ),
        DeskNoticeKind.searchError => (
          l10n.chatSearchErrorFallback(n.detail),
          DeskTone.warning,
        ),
        DeskNoticeKind.documentTrimmed => (
          l10n.chatDocumentTrimmed(n.detail),
          DeskTone.info,
        ),
        DeskNoticeKind.noVision => (l10n.chatErrorNoVision, DeskTone.warning),
        DeskNoticeKind.attachmentRefused => (
          switch (controller.takeLastRefusal()) {
            final FormatException e => attachmentErrorMessage(l10n, e),
            null => n.detail,
          },
          DeskTone.warning,
        ),
      };
      showDeskToast(
        text,
        tone: tone,
        lasting: tone == DeskTone.error
            ? const Duration(seconds: 6)
            : const Duration(seconds: 4),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final open = ref.watch(deskSidebarOpenProvider);
    return Row(
      children: [
        ClipRect(
          child: AnimatedContainer(
            duration: DeskMotion.medium,
            curve: DeskMotion.ease,
            width: open ? DeskSize.sidebarWidth : 0,
            child: const OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: DeskSize.sidebarWidth,
              maxWidth: DeskSize.sidebarWidth,
              child: ChatSidebar(),
            ),
          ),
        ),
        const Expanded(child: ChatPane()),
      ],
    );
  }
}
