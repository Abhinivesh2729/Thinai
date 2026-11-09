/// The system prompt, edited in place rather than on a page of its own.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/system_prompt.dart';
import '../../../l10n/l10n.dart';
import '../../l10n/settings_strings.dart';
import '../../shell/desk_nav.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/toast.dart';
import 'settings_widgets.dart';

class SystemPromptSection extends ConsumerStatefulWidget {
  const SystemPromptSection({super.key});

  @override
  ConsumerState<SystemPromptSection> createState() =>
      _SystemPromptSectionState();
}

class _SystemPromptSectionState extends ConsumerState<SystemPromptSection> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final prompt = await ref.read(systemPromptProvider.notifier).current();
    if (!mounted) return;
    _text.text = prompt;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _dirty => _loaded && _text.text != ref.read(systemPromptProvider);

  Future<void> _save({bool announce = true}) async {
    if (!_dirty) return;
    await ref.read(systemPromptProvider.notifier).set(_text.text);
    if (!mounted) return;
    setState(() {});
    if (announce) {
      showDeskToast(context.l10n.systemPromptSaved, tone: DeskTone.success);
    }
  }

  Future<void> _reset() async {
    await ref.read(systemPromptProvider.notifier).reset();
    if (!mounted) return;
    setState(
      () => _text.text = ref.read(systemPromptProvider.notifier).defaultPrompt,
    );
    showDeskToast(context.l10n.systemPromptResetDone, tone: DeskTone.success);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = SettingsStrings.of(context);
    final palette = DeskPalette.of(context);

    // Pages stay alive in the desktop shell, so "leaving" means switching
    // away from Settings; the phone saves on leave and so does this.
    ref.listen(deskPageProvider, (prev, next) {
      if (prev == DeskPage.settings && next != DeskPage.settings && _dirty) {
        unawaited(_save(announce: false));
      }
    });
    // The provider rebuilds with a new default when the UI language changes.
    // Follow it unless the user is midway through an edit.
    ref.listen(systemPromptProvider, (prev, next) {
      if (_loaded && _text.text == prev && _text.text != next) {
        setState(() => _text.text = next);
      }
    });

    final notifier = ref.read(systemPromptProvider.notifier);
    final isDefault = _text.text == notifier.defaultPrompt;
    final dirty = _dirty;

    return SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: DeskMotion.medium,
                child: !_loaded
                    ? const SizedBox(
                        height: 160,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : CallbackShortcuts(
                        bindings: {
                          const SingleActivator(
                            LogicalKeyboardKey.keyS,
                            control: true,
                          ): () =>
                              unawaited(_save()),
                          const SingleActivator(
                            LogicalKeyboardKey.keyS,
                            meta: true,
                          ): () =>
                              unawaited(_save()),
                        },
                        child: TextField(
                          controller: _text,
                          focusNode: _focus,
                          minLines: 6,
                          maxLines: 14,
                          keyboardType: TextInputType.multiline,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 13.5, height: 1.5),
                          decoration: InputDecoration(
                            hintText: l10n.systemPromptHint,
                            fillColor: palette.canvas,
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: DeskMotion.medium,
                    transitionBuilder: (child, a) =>
                        FadeTransition(opacity: a, child: child),
                    child: dirty
                        ? Pill(
                            key: const ValueKey('dirty'),
                            label: s.unsaved,
                            color: DeskColors.amber,
                            dot: true,
                          )
                        : isDefault
                        ? Pill(
                            key: const ValueKey('default'),
                            label: s.isDefault,
                          )
                        : const SizedBox.shrink(key: ValueKey('none')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _text.text.isEmpty ? s.emptyMeansNone : s.chatOnly,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    ),
                  ),
                  Text(
                    l10n.systemPromptCharacters(_text.text.length),
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textFaint,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  DeskButton(
                    label: l10n.systemPromptResetToDefault,
                    icon: Icons.restart_alt_rounded,
                    kind: DeskButtonKind.ghost,
                    onPressed: isDefault || !_loaded ? null : _reset,
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: DeskMotion.fast,
                    opacity: dirty ? 1 : 0,
                    child: Text(
                      s.saveShortcut,
                      style: TextStyle(fontSize: 12, color: palette.textFaint),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DeskButton(
                    label: l10n.commonSave,
                    icon: Icons.check_rounded,
                    kind: DeskButtonKind.primary,
                    onPressed: dirty ? _save : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
