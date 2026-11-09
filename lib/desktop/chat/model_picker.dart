/// The model chip in the chat header: shows what is loaded, switches models
/// from a popover, and opens per-model settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models_repo/model_store.dart';
import '../../state/providers.dart';
import '../../ui/widgets/model_settings_sheet.dart';
import '../l10n/desk_l10n.dart';
import '../shell/desk_nav.dart';
import '../theme/desk_theme.dart';
import '../widgets/hover.dart';

/// Shows the phone's model settings panel as a desktop dialog.
Future<void> showDeskModelSettings(BuildContext context, LocalModel model) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DeskSize.radiusXL),
          child: Material(child: ModelSettingsSheet(model: model)),
        ),
      ),
    ),
  );
}

class ModelPicker extends ConsumerWidget {
  const ModelPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ShellStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final activeId = ref.watch(activeModelIdProvider);
    final models =
        ref.watch(modelListProvider).valueOrNull ?? const <LocalModel>[];
    LocalModel? active;
    for (final m in models) {
      if (m.id == activeId) active = m;
    }

    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(palette.panelRaised),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DeskSize.radiusL),
            side: BorderSide(color: palette.hairline),
          ),
        ),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: Text(
            s.switchModel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: palette.textFaint,
            ),
          ),
        ),
        if (models.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Text(
              s.noModelsInstalled,
              style: TextStyle(color: palette.textMuted),
            ),
          ),
        for (final m in models)
          MenuItemButton(
            onPressed: () => ref.read(activeModelIdProvider.notifier).set(m),
            leadingIcon: Icon(
              m.id == activeId
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: m.id == activeId ? DeskColors.green : palette.textFaint,
            ),
            trailingIcon: Text(
              m.sizeFormatted,
              style: TextStyle(fontSize: 12, color: palette.textFaint),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
              child: Text(m.displayName, overflow: TextOverflow.ellipsis),
            ),
          ),
        const Divider(height: 12),
        if (active != null)
          MenuItemButton(
            leadingIcon: const Icon(Icons.tune_rounded, size: 18),
            onPressed: () => showDeskModelSettings(context, active!),
            child: Text(s.modelSettings),
          ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.view_in_ar_outlined, size: 18),
          onPressed: () =>
              ref.read(deskPageProvider.notifier).state = DeskPage.models,
          child: Text(s.manageModels),
        ),
      ],
      builder: (context, controller, _) => Hoverable(
        cursor: SystemMouseCursors.click,
        builder: (context, hovered) => GestureDetector(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: AnimatedContainer(
            duration: DeskMotion.fast,
            padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
            decoration: BoxDecoration(
              color: hovered ? palette.panelRaised : palette.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: DeskMotion.medium,
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active != null ? DeskColors.mint : DeskColors.amber,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (active != null
                                    ? DeskColors.mint
                                    : DeskColors.amber)
                                .withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    active?.displayName ?? s.switchModel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: palette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
