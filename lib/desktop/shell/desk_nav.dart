/// Which page the desktop shell shows, and the keyboard shortcuts around it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeskPage { chat, models, lab, server, settings }

final deskPageProvider = StateProvider<DeskPage>((ref) => DeskPage.chat);

/// Whether the chat history sidebar is open.
final deskSidebarOpenProvider = StateProvider<bool>((ref) => true);

/// Bumped to ask the chat pane to focus its composer.
final deskFocusComposerProvider = StateProvider<int>((ref) => 0);

/// Bumped to ask the sidebar to focus its search box.
final deskFocusSearchProvider = StateProvider<int>((ref) => 0);

class NewChatIntent extends Intent {
  const NewChatIntent();
}

class GoToPageIntent extends Intent {
  const GoToPageIntent(this.page);
  final DeskPage page;
}

class ToggleSidebarIntent extends Intent {
  const ToggleSidebarIntent();
}

class SearchChatsIntent extends Intent {
  const SearchChatsIntent();
}

/// Ctrl on Windows/Linux, Cmd on macOS.
SingleActivator deskShortcut(LogicalKeyboardKey key, {bool shift = false}) {
  final mac = defaultTargetPlatform == TargetPlatform.macOS;
  return SingleActivator(key, control: !mac, meta: mac, shift: shift);
}

Map<ShortcutActivator, Intent> deskShortcuts() => {
  deskShortcut(LogicalKeyboardKey.keyN): const NewChatIntent(),
  deskShortcut(LogicalKeyboardKey.digit1): const GoToPageIntent(DeskPage.chat),
  deskShortcut(LogicalKeyboardKey.digit2): const GoToPageIntent(
    DeskPage.models,
  ),
  deskShortcut(LogicalKeyboardKey.digit3): const GoToPageIntent(DeskPage.lab),
  deskShortcut(LogicalKeyboardKey.digit4): const GoToPageIntent(
    DeskPage.server,
  ),
  deskShortcut(LogicalKeyboardKey.comma): const GoToPageIntent(
    DeskPage.settings,
  ),
  deskShortcut(LogicalKeyboardKey.keyB): const ToggleSidebarIntent(),
  deskShortcut(LogicalKeyboardKey.keyF, shift: true): const SearchChatsIntent(),
};
