/// The Model Manager: installed files, live and paused downloads, disk use.
/// Slides in over the right edge of the Models page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../models_repo/catalog.dart';
import '../../../models_repo/downloader.dart';
import '../../../models_repo/model_store.dart';
import '../../../state/providers.dart';
import '../../l10n/models_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import 'model_bits.dart';
import 'model_details_dialog.dart';
import 'models_common.dart';

const kManagerWidth = 400.0;

class ModelManagerPanel extends ConsumerWidget {
  const ModelManagerPanel({
    super.key,
    required this.onClose,
    required this.onBrowse,
    required this.onImport,
    required this.importing,
  });

  final VoidCallback onClose;
  final VoidCallback onBrowse;
  final VoidCallback onImport;
  final bool importing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ModelsStrings.of(context);
    final palette = DeskPalette.of(context);

    final installed =
        ref.watch(modelListProvider).valueOrNull ?? const <LocalModel>[];
    final activeId = ref.watch(activeModelIdProvider);
    final downloads = ref.watch(downloadsProvider);
    // A download in flight has a part on disk too; show it once, live.
    final inFlight = {for (final h in downloads.values) '${h.destPath}.part'};
    final paused = [
      for (final p
          in ref.watch(partialDownloadsProvider).valueOrNull ??
              const <PartialDownload>[])
        if (!inFlight.contains(p.path)) p,
    ];
    final totalBytes = installed.fold<int>(0, (sum, m) => sum + m.sizeBytes);
    LocalModel? active;
    for (final m in installed) {
      if (m.id == activeId) active = m;
    }
    final actions = ModelActions(context);

    return Material(
      color: palette.panelRaised,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: palette.hairline)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.isDark ? 0.5 : 0.12,
              ),
              blurRadius: 40,
              offset: const Offset(-8, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── header
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: DeskColors.green.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(DeskSize.radiusM),
                    ),
                    child: const Icon(
                      Icons.layers_rounded,
                      size: 20,
                      color: DeskColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.modelsManagerTitle,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          l.modelsManagerSubtitle(
                            installed.length,
                            fmtSize(totalBytes),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DeskIconButton(
                    icon: Icons.close_rounded,
                    tooltip: s.close,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                children: [
                  _InUse(model: active),
                  _Section(
                    visible: downloads.isNotEmpty,
                    title: s.downloading,
                    icon: Icons.downloading_rounded,
                    children: [
                      for (final e in downloads.entries)
                        _DownloadRow(
                          key: ValueKey(e.value),
                          handle: e.value,
                          onPause: () => actions.pause(e.key),
                        ),
                    ],
                  ),
                  _Section(
                    visible: paused.isNotEmpty,
                    title: l.modelsPausedDownloadsTitle(paused.length),
                    icon: Icons.pause_circle_outline_rounded,
                    children: [
                      for (final p in paused)
                        _PausedRow(
                          key: ValueKey(p.path),
                          partial: p,
                          onResume: () => actions.resumePartial(p),
                          onDiscard: () => actions.discardPartial(p),
                        ),
                    ],
                  ),
                  _Section(
                    visible: installed.isNotEmpty,
                    title: s.installedTitle,
                    icon: Icons.inventory_2_outlined,
                    children: [
                      for (final m in installed)
                        _InstalledRow(
                          key: ValueKey(m.path),
                          model: m,
                          active: m.id == activeId,
                          actions: actions,
                        ),
                    ],
                  ),
                  if (installed.isEmpty && downloads.isEmpty)
                    _Empty(onBrowse: onBrowse),
                ],
              ),
            ),
            const Divider(),
            // ── footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storage_rounded,
                        size: 15,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          s.diskUse(fmtSize(totalBytes)),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                      DeskButton(
                        label: importing ? s.importing : s.importGguf,
                        icon: Icons.file_open_outlined,
                        style: DeskButtonStyle.quiet,
                        busy: importing,
                        onPressed: onImport,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.dropHint,
                    style: TextStyle(fontSize: 11.5, color: palette.textFaint),
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

/// A titled group that grows and shrinks smoothly as it fills and empties.
class _Section extends StatelessWidget {
  const _Section({
    required this.visible,
    required this.title,
    required this.icon,
    required this.children,
  });

  final bool visible;
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return AnimatedSize(
      duration: DeskMotion.medium,
      curve: DeskMotion.ease,
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 14, color: palette.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final c in children)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: c,
                    ),
                ],
              ),
            ),
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({required this.child, this.highlighted = false});
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return Hoverable(
      builder: (context, hovered) => AnimatedContainer(
        duration: DeskMotion.fast,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: hovered
              ? Color.alphaBlend(
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.03),
                  palette.panel,
                )
              : palette.panel,
          borderRadius: BorderRadius.circular(DeskSize.radiusM),
          border: Border.all(
            color: highlighted
                ? DeskColors.green.withValues(alpha: 0.6)
                : palette.hairline,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _InUse extends StatelessWidget {
  const _InUse({required this.model});
  final LocalModel? model;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = DeskPalette.of(context);
    final m = model;
    return AnimatedSwitcher(
      duration: DeskMotion.medium,
      child: Container(
        key: ValueKey(m?.id),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: m == null
              ? palette.canvas
              : DeskColors.green.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(DeskSize.radiusM),
          border: Border.all(
            color: m == null
                ? palette.hairline
                : DeskColors.green.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            if (m != null)
              LogoTile(local: m, size: 36)
            else
              Icon(
                Icons.power_settings_new_rounded,
                size: 20,
                color: palette.textFaint,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                m == null
                    ? l.modelsNoModelLoaded
                    : l.modelsActiveForChat(m.displayName),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: m == null ? palette.textMuted : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({super.key, required this.handle, required this.onPause});
  final DownloadHandle handle;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      child: Row(
        children: [
          Expanded(
            child: LiveProgress(handle: handle, title: handle.label),
          ),
          const SizedBox(width: 6),
          DeskIconButton(
            icon: Icons.pause_rounded,
            tooltip: context.l10n.modelsPauseDownload,
            onPressed: onPause,
          ),
        ],
      ),
    );
  }
}

class _PausedRow extends StatelessWidget {
  const _PausedRow({
    super.key,
    required this.partial,
    required this.onResume,
    required this.onDiscard,
  });
  final PartialDownload partial;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _RowShell(
      child: Row(
        children: [
          Expanded(
            child: PausedProgress(partial: partial, title: partial.label),
          ),
          const SizedBox(width: 6),
          DeskIconButton(
            icon: Icons.play_arrow_rounded,
            tooltip: l.modelsResumeDownload,
            color: DeskColors.green,
            onPressed: onResume,
          ),
          DeskIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: l.modelsDiscardDownload,
            onPressed: onDiscard,
          ),
        ],
      ),
    );
  }
}

class _InstalledRow extends ConsumerWidget {
  const _InstalledRow({
    super.key,
    required this.model,
    required this.active,
    required this.actions,
  });
  final LocalModel model;
  final bool active;
  final ModelActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final palette = DeskPalette.of(context);
    final tamil = ref.watch(tamilScoreProvider(model.id));
    final catalog = catalogFor(model);
    final isChat = catalog == null || catalog.kind == ModelKind.chat;

    return _RowShell(
      highlighted: active,
      child: Row(
        children: [
          LogoTile(local: model, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  catalog?.displayName ?? model.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    fmtSize(model.sizeBytes),
                    if (tamil != null) 'த ${tamil.round()}',
                  ].join(' · '),
                  style: TextStyle(fontSize: 11.5, color: palette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (isChat)
            AnimatedSwitcher(
              duration: DeskMotion.medium,
              child: active
                  ? Padding(
                      key: const ValueKey('active'),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        l.modelsActive,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DeskColors.green,
                        ),
                      ),
                    )
                  : DeskButton(
                      key: const ValueKey('load'),
                      label: l.modelsActivate,
                      style: DeskButtonStyle.outlined,
                      height: 30,
                      onPressed: () => actions.load(model),
                    ),
            ),
          if (isChat)
            DeskIconButton(
              icon: Icons.tune_rounded,
              tooltip: l.modelsSettingsTitle,
              onPressed: () => showModelSettingsDialog(context, model),
            ),
          DeskIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: l.modelsDeleteModel,
            onPressed: () => actions.delete(model),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = DeskPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 40, color: palette.textFaint),
          const SizedBox(height: 14),
          Text(
            l.modelsNoneInstalled,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l.modelsNoneInstalledBody,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: palette.textMuted),
          ),
          const SizedBox(height: 18),
          DeskButton(
            label: l.modelsBrowseCatalog,
            icon: Icons.explore_rounded,
            onPressed: onBrowse,
          ),
        ],
      ),
    );
  }
}
