/// The desktop window: rail, title bar and the current page.
///
/// Pages are built the first time they are opened and then kept alive, so
/// switching is instant and keeps scroll positions and half-typed text.
/// Hidden pages get TickerMode off, so their animations cost nothing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../pages/chat_page.dart';
import '../pages/lab_page.dart';
import '../pages/models_page.dart';
import '../pages/server_page.dart';
import '../pages/settings/desk_start_page.dart';
import '../pages/settings_page.dart';
import '../theme/desk_theme.dart';
import 'desk_nav.dart';
import 'desk_rail.dart';
import 'title_bar.dart';

class DeskShell extends ConsumerStatefulWidget {
  const DeskShell({super.key});

  @override
  ConsumerState<DeskShell> createState() => _DeskShellState();
}

class _DeskShellState extends ConsumerState<DeskShell> {
  final _visited = <DeskPage>{DeskPage.chat};

  @override
  void initState() {
    super.initState();
    // Open on the page chosen in Settings. Read after the first frame so a
    // slow disk never delays the window.
    DeskStartPageController.readSaved().then((page) {
      if (!mounted || page == DeskPage.chat) return;
      if (ref.read(deskPageProvider) == DeskPage.chat) {
        ref.read(deskPageProvider.notifier).state = page;
      }
    });
  }

  Widget _pageFor(DeskPage page) => switch (page) {
    DeskPage.chat => const DeskChatPage(),
    DeskPage.models => const DeskModelsPage(),
    DeskPage.lab => const DeskLabPage(),
    DeskPage.server => const DeskServerPage(),
    DeskPage.settings => const DeskSettingsPage(),
  };

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(deskPageProvider);
    _visited.add(current);
    final palette = DeskPalette.of(context);

    return Actions(
      actions: {
        NewChatIntent: CallbackAction<NewChatIntent>(
          onInvoke: (_) {
            ref.read(chatSessionsProvider.notifier).startNewChat();
            ref.read(deskPageProvider.notifier).state = DeskPage.chat;
            ref.read(deskFocusComposerProvider.notifier).state++;
            return null;
          },
        ),
        GoToPageIntent: CallbackAction<GoToPageIntent>(
          onInvoke: (i) {
            ref.read(deskPageProvider.notifier).state = i.page;
            return null;
          },
        ),
        ToggleSidebarIntent: CallbackAction<ToggleSidebarIntent>(
          onInvoke: (_) {
            ref.read(deskSidebarOpenProvider.notifier).update((v) => !v);
            return null;
          },
        ),
        SearchChatsIntent: CallbackAction<SearchChatsIntent>(
          onInvoke: (_) {
            ref.read(deskPageProvider.notifier).state = DeskPage.chat;
            ref.read(deskSidebarOpenProvider.notifier).state = true;
            ref.read(deskFocusSearchProvider.notifier).state++;
            return null;
          },
        ),
      },
      child: ColoredBox(
        color: palette.canvas,
        child: Row(
          children: [
            const DeskRail(),
            Expanded(
              child: Column(
                children: [
                  const DeskTitleBar(),
                  Expanded(
                    child: Stack(
                      children: [
                        for (final page in DeskPage.values)
                          if (_visited.contains(page))
                            _PageLayer(
                              key: ValueKey(page),
                              active: page == current,
                              child: _pageFor(page),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageLayer extends StatelessWidget {
  const _PageLayer({super.key, required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !active,
        // The fade itself must keep ticking while the page leaves, so only
        // the page's own content is put to sleep.
        child: AnimatedOpacity(
          duration: DeskMotion.medium,
          curve: DeskMotion.ease,
          opacity: active ? 1 : 0,
          child: AnimatedSlide(
            duration: DeskMotion.page,
            curve: DeskMotion.ease,
            offset: active ? Offset.zero : const Offset(0, 0.012),
            child: TickerMode(
              enabled: active,
              child: ExcludeFocus(
                excluding: !active,
                child: Material(type: MaterialType.transparency, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
