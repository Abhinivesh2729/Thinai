/// The message box: grows with the text, Enter sends, Shift+Enter breaks the
/// line, attachments show as chips above it, and the send button morphs into
/// stop while a reply streams.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/document_attachment.dart';
import '../../chat/image_attachment.dart';
import '../../state/providers.dart';
import '../l10n/desk_l10n.dart';
import '../shell/desk_nav.dart';
import '../theme/desk_theme.dart';
import '../widgets/hover.dart';
import '../widgets/toast.dart';
import 'desk_chat_controller.dart';

class DeskComposer extends ConsumerStatefulWidget {
  const DeskComposer({super.key, this.autofocus = true});
  final bool autofocus;

  @override
  ConsumerState<DeskComposer> createState() => _DeskComposerState();
}

class _DeskComposerState extends ConsumerState<DeskComposer> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final value = _text.text;
    if (value.trim().isEmpty) return;
    _text.clear();
    ref.read(deskChatProvider.notifier).send(value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final enter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (enter && !HardwareKeyboard.instance.isShiftPressed) {
      // An IME (Tamil keyboards) uses Enter to commit what is being composed.
      if (_text.value.composing.isValid) return KeyEventResult.ignored;
      if (ref.read(deskChatProvider).generating) return KeyEventResult.handled;
      _send();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        ref.read(deskChatProvider).generating) {
      ref.read(deskChatProvider.notifier).stop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _pickDocument() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: kTextExtensions.toList(),
    );
    if (file == null) return;
    ref
        .read(deskChatProvider.notifier)
        .attachDocument(file.name, await file.readAsBytes());
  }

  Future<void> _pickImage() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: kImageExtensions.toList(),
    );
    if (file == null) return;
    ref
        .read(deskChatProvider.notifier)
        .attachImage(file.name, await file.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    final s = ShellStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final chat = ref.watch(deskChatProvider);
    final hasModel = ref.watch(activeModelIdProvider) != null;
    final web = ref.watch(webSearchEnabledProvider);
    final canSend =
        hasModel && _text.text.trim().isNotEmpty && !chat.generating;

    ref.listen<int>(deskFocusComposerProvider, (_, _) => _focus.requestFocus());

    return AnimatedContainer(
      duration: DeskMotion.medium,
      curve: DeskMotion.ease,
      decoration: BoxDecoration(
        color: palette.panelRaised,
        borderRadius: BorderRadius.circular(DeskSize.radiusXL),
        border: Border.all(
          color: _focused
              ? DeskColors.green.withValues(alpha: 0.55)
              : palette.hairline,
          width: _focused ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (_focused ? DeskColors.green : Colors.black).withValues(
              alpha: palette.isDark
                  ? (_focused ? 0.16 : 0.35)
                  : (_focused ? 0.10 : 0.06),
            ),
            blurRadius: _focused ? 28 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: DeskMotion.medium,
            curve: DeskMotion.ease,
            alignment: Alignment.topCenter,
            child: (chat.document == null && chat.image == null)
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (chat.image != null)
                          _Chip(
                            icon: Icons.image_outlined,
                            label: chat.image!.name,
                            detail: chat.image!.sizeLabel,
                            onRemove: () => ref
                                .read(deskChatProvider.notifier)
                                .removeImage(),
                          ),
                        if (chat.document != null)
                          _Chip(
                            icon: Icons.description_outlined,
                            label: chat.document!.name,
                            detail: chat.document!.sizeLabel,
                            onRemove: () => ref
                                .read(deskChatProvider.notifier)
                                .removeDocument(),
                          ),
                      ],
                    ),
                  ),
          ),
          Focus(
            onKeyEvent: _onKey,
            child: TextField(
              controller: _text,
              focusNode: _focus,
              autofocus: widget.autofocus,
              enabled: hasModel,
              minLines: 1,
              maxLines: 9,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                fontSize: 15.5,
                height: 1.5,
                color: scheme.onSurface,
              ),
              cursorColor: DeskColors.green,
              decoration: InputDecoration(
                hintText: hasModel ? s.composerHint : s.composerHintNoModel,
                hintStyle: TextStyle(color: palette.textFaint),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                MenuAnchor(
                  style: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      palette.panelRaised,
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DeskSize.radiusM),
                        side: BorderSide(color: palette.hairline),
                      ),
                    ),
                  ),
                  menuChildren: [
                    MenuItemButton(
                      leadingIcon: const Icon(
                        Icons.description_outlined,
                        size: 18,
                      ),
                      onPressed: _pickDocument,
                      child: Text(s.attachDocument),
                    ),
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.image_outlined, size: 18),
                      onPressed: ref.watch(visionReadyProvider)
                          ? _pickImage
                          : null,
                      child: Text(s.attachImage),
                    ),
                  ],
                  builder: (context, controller, _) => DeskIconButton(
                    icon: Icons.add_rounded,
                    tooltip: s.attach,
                    iconSize: 20,
                    onPressed: hasModel
                        ? () => controller.isOpen
                              ? controller.close()
                              : controller.open()
                        : null,
                  ),
                ),
                const SizedBox(width: 4),
                _WebModeChip(
                  web: web,
                  always: ref.watch(deskWebAlwaysProvider),
                  onPick: (mode) async {
                    await ref
                        .read(webSearchEnabledProvider.notifier)
                        .set(mode != _WebMode.off);
                    await ref
                        .read(deskWebAlwaysProvider.notifier)
                        .set(mode == _WebMode.always);
                    showDeskToast(switch (mode) {
                      _WebMode.off => s.webOff,
                      _WebMode.auto => s.webOn,
                      _WebMode.always => s.webAlwaysOn,
                    });
                  },
                ),
                // One expanding slot between the left controls and the send
                // button, so the button always sits at the right edge.
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedOpacity(
                      duration: DeskMotion.fast,
                      opacity: _focused && _text.text.isNotEmpty ? 1 : 0,
                      child: Text(
                        s.shortcutsHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.textFaint,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _SendButton(
                  generating: chat.generating,
                  enabled: canSend,
                  onSend: _send,
                  onStop: () => ref.read(deskChatProvider.notifier).stop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _WebMode { off, auto, always }

/// Web search mode: Off, Auto (searches when the question needs fresh
/// facts) or Always (every message). A menu, so the choice is explicit.
class _WebModeChip extends StatelessWidget {
  const _WebModeChip({
    required this.web,
    required this.always,
    required this.onPick,
  });

  final bool web;
  final bool always;
  final ValueChanged<_WebMode> onPick;

  @override
  Widget build(BuildContext context) {
    final s = ShellStrings.of(context);
    final palette = DeskPalette.of(context);
    final mode = !web
        ? _WebMode.off
        : (always ? _WebMode.always : _WebMode.auto);
    final on = mode != _WebMode.off;
    final label = switch (mode) {
      _WebMode.off => s.webModeOff,
      _WebMode.auto => s.webModeAuto,
      _WebMode.always => s.webModeAlways,
    };
    Widget item(_WebMode m, String title, String detail) => MenuItemButton(
      onPressed: () => onPick(m),
      leadingIcon: Icon(
        m == mode
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        size: 18,
        color: m == mode ? DeskColors.green : palette.textFaint,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            Text(
              detail,
              style: TextStyle(fontSize: 11.5, color: palette.textMuted),
            ),
          ],
        ),
      ),
    );
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(palette.panelRaised),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DeskSize.radiusM),
            side: BorderSide(color: palette.hairline),
          ),
        ),
      ),
      menuChildren: [
        item(_WebMode.auto, s.webModeAuto, s.webModeAutoDetail),
        item(_WebMode.always, s.webModeAlways, s.webModeAlwaysDetail),
        item(_WebMode.off, s.webModeOff, s.webModeOffDetail),
      ],
      builder: (context, controller, _) => Hoverable(
        cursor: SystemMouseCursors.click,
        builder: (context, hovered) => GestureDetector(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: AnimatedContainer(
            duration: DeskMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: on
                  ? DeskColors.green.withValues(alpha: 0.13)
                  : hovered
                  ? palette.panel
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: on
                    ? DeskColors.green.withValues(alpha: 0.4)
                    : palette.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  on ? Icons.public_rounded : Icons.public_off_rounded,
                  size: 15,
                  color: on ? DeskColors.green : palette.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: on ? DeskColors.green : palette.textMuted,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.expand_more_rounded,
                  size: 15,
                  color: on ? DeskColors.green : palette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.generating,
    required this.enabled,
    required this.onSend,
    required this.onStop,
  });

  final bool generating;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final active = generating || enabled;
    return Hoverable(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      builder: (context, hovered) => GestureDetector(
        onTap: generating ? onStop : (enabled ? onSend : null),
        child: AnimatedScale(
          duration: DeskMotion.fast,
          scale: hovered && active ? 1.06 : 1,
          child: AnimatedContainer(
            duration: DeskMotion.medium,
            curve: DeskMotion.ease,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: generating
                  ? palette.panel
                  : enabled
                  ? DeskColors.green
                  : palette.hairline,
              border: generating ? Border.all(color: palette.hairline) : null,
              boxShadow: enabled && !generating
                  ? [
                      BoxShadow(
                        color: DeskColors.green.withValues(alpha: 0.45),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSwitcher(
              duration: DeskMotion.medium,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: generating
                  ? Container(
                      key: const ValueKey('stop'),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )
                  : Icon(
                      Icons.arrow_upward_rounded,
                      key: const ValueKey('send'),
                      size: 20,
                      color: enabled ? Colors.white : palette.textFaint,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onRemove,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return EnterAnimation(
      duration: DeskMotion.medium,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(DeskSize.radiusM),
          border: Border.all(color: palette.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: DeskColors.green),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: scheme.onSurface),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              detail,
              style: TextStyle(fontSize: 11.5, color: palette.textFaint),
            ),
            const SizedBox(width: 2),
            DeskIconButton(
              icon: Icons.close_rounded,
              tooltip: '',
              size: 24,
              iconSize: 14,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
