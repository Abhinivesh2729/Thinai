/// Model details and model settings, as centred dialogs rather than the
/// phone's bottom sheets.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../models_repo/catalog.dart';
import '../../../models_repo/model_store.dart';
import '../../../models_repo/recommender.dart';
import '../../../state/providers.dart';
import '../../../ui/widgets/model_settings_sheet.dart';
import '../../l10n/models_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import 'model_bits.dart';
import 'models_common.dart';
import '../../l10n/desk_l10n.dart';

/// Scale-and-fade in, quicker than the default dialog transition.
Future<T?> _showDeskDialog<T>(BuildContext context, WidgetBuilder builder) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: DeskMotion.medium,
    pageBuilder: (ctx, _, _) => builder(ctx),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: DeskMotion.ease,
        reverseCurve: DeskMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Future<void> showModelDetails(BuildContext context, CatalogModel model) =>
    _showDeskDialog<void>(context, (_) => _DetailsDialog(model: model));

/// The phone's settings sheet, unchanged, inside a desktop dialog.
Future<void> showModelSettingsDialog(BuildContext context, LocalModel model) {
  final s = ModelsStrings.of(context);
  return _showDeskDialog<void>(
    context,
    (ctx) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.86,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: ModelSettingsSheet(model: model),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: DeskIconButton(
                icon: Icons.close_rounded,
                tooltip: s.close,
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailsDialog extends ConsumerWidget {
  const _DetailsDialog({required this.model});

  final CatalogModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ModelsStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    // Watches the same state as the card, so a download started, paused or
    // finished anywhere shows here too.
    final local = ref.watch(
      modelListProvider.select(
        (a) => localFor(model, a.valueOrNull ?? const <LocalModel>[]),
      ),
    );
    final handle = ref.watch(downloadsProvider.select((d) => d[model.id]));
    final partial = ref.watch(
      partialDownloadsProvider.select((a) => partialFor(model, a.valueOrNull)),
    );
    final active =
        local != null && ref.watch(activeModelIdProvider) == local.id;
    final speed = ref.watch(speedKnowledgeProvider);
    final device = speed.device;
    final fit = fitFor(model, device);
    final warning = local == null ? fitWarning(model, device, s) : null;
    final rate = model.kind == ModelKind.chat ? speed.rateFor(model) : null;
    final measured = speed.isMeasured(model);
    final tamil = local == null
        ? null
        : ref.watch(tamilScoreProvider(local.id));
    final cap = capabilityTag(model, l);
    final actions = ModelActions(context);

    final Widget primary;
    if (handle != null) {
      primary = Column(
        key: const ValueKey('dl'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LiveProgress(key: ValueKey(handle), handle: handle),
          const SizedBox(height: 14),
          DeskButton(
            label: l.modelsPause,
            icon: Icons.pause_rounded,
            style: DeskButtonStyle.quiet,
            height: 42,
            expand: true,
            onPressed: () => actions.pause(model.id),
          ),
        ],
      );
    } else if (local != null) {
      primary = Row(
        key: const ValueKey('installed'),
        children: [
          if (model.kind == ModelKind.chat) ...[
            Expanded(
              child: DeskButton(
                label: active ? l.modelsUseInChat : s.loadAndChat,
                icon: Icons.chat_bubble_outline_rounded,
                height: 42,
                expand: true,
                onPressed: () {
                  Navigator.pop(context);
                  actions.load(local, openChat: true);
                },
              ),
            ),
            const SizedBox(width: 10),
            DeskButton(
              label: l.modelsSettingsTitle,
              icon: Icons.tune_rounded,
              style: DeskButtonStyle.quiet,
              height: 42,
              onPressed: () => showModelSettingsDialog(context, local),
            ),
            const SizedBox(width: 10),
          ] else
            const Spacer(),
          DeskButton(
            label: l.commonDelete,
            icon: Icons.delete_outline_rounded,
            style: DeskButtonStyle.danger,
            height: 42,
            onPressed: () async {
              final nav = Navigator.of(context);
              if (await actions.delete(local)) nav.pop();
            },
          ),
        ],
      );
    } else if (partial != null) {
      primary = Column(
        key: const ValueKey('paused'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PausedProgress(partial: partial),
          const SizedBox(height: 14),
          DeskButton(
            label: resumeLabel(partial, l),
            icon: Icons.play_arrow_rounded,
            height: 42,
            expand: true,
            onPressed: () => actions.resume(model),
          ),
        ],
      );
    } else {
      primary = DeskButton(
        key: const ValueKey('get'),
        label: l.modelsDownloadSize(model.approxSize),
        icon: Icons.arrow_downward_rounded,
        height: 42,
        expand: true,
        // Allowed even when too big, as on the phone: the confirm dialog
        // spells out the RAM shortfall. Stays open to show progress.
        onPressed: () => actions.download(model),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  LogoTile(model: model, size: 58),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.author.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: context.tracking(1),
                            color: palette.textFaint,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          model.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DeskIconButton(
                    icon: Icons.close_rounded,
                    tooltip: s.close,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              AnimatedSize(
                duration: DeskMotion.medium,
                curve: DeskMotion.ease,
                alignment: Alignment.topCenter,
                child: local == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            SpecChip(
                              label: l.modelsInstalled,
                              icon: Icons.check_circle_rounded,
                              color: DeskColors.green,
                            ),
                            SpecChip(
                              label: fmtSize(local.sizeBytes),
                              icon: Icons.storage_rounded,
                            ),
                            if (active)
                              SpecChip(
                                label: l.modelsActiveInChat,
                                icon: Icons.bolt_rounded,
                                color: DeskColors.green,
                              ),
                            if (tamil != null)
                              SpecChip(
                                label: 'த ${tamil.round()}',
                                color: DeskColors.green,
                              ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                deskWording(model.description),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              _TileGrid(
                tiles: [
                  _Tile(
                    l.modelsDetailParameters,
                    model.parameters,
                    Icons.bolt_rounded,
                  ),
                  _Tile(
                    l.modelsDetailContextWindow,
                    l.modelsTokensValue(model.contextLabel),
                    Icons.receipt_long_outlined,
                  ),
                  _Tile(
                    l.modelsDetailDownloadSize,
                    model.supportsVision
                        ? '${model.approxSize} + ${model.mmprojSize}'
                        : model.approxSize,
                    Icons.download_rounded,
                  ),
                  _Tile(l.modelsDetailCapability, cap.$2, cap.$1),
                  _Tile(
                    s.memory,
                    '${fmtGb(runtimeBytesFor(model))} · ${fitLabel(fit, l, s)}',
                    Icons.memory_rounded,
                    color: fitColor(fit, scheme),
                  ),
                  if (rate != null)
                    _Tile(
                      measured ? s.measuredSpeed : s.estimatedSpeed,
                      '${measured ? '' : '~'}'
                      '${rate.toStringAsFixed(rate >= 10 ? 0 : 1)} tok/s',
                      measured ? Icons.speed_rounded : Icons.timer_outlined,
                    ),
                ],
              ),
              if (warning != null) ...[
                const SizedBox(height: 14),
                _Warning(text: warning, blocked: fit == RamFit.tooBig),
              ],
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: DeskMotion.medium,
                switchInCurve: DeskMotion.ease,
                transitionBuilder: (child, a) =>
                    FadeTransition(opacity: a, child: child),
                child: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile {
  const _Tile(this.title, this.value, this.icon, {this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});
  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final w = (c.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tiles)
              Container(
                width: w,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: palette.canvas,
                  borderRadius: BorderRadius.circular(DeskSize.radiusM),
                  border: Border.all(color: palette.hairline),
                ),
                child: Row(
                  children: [
                    Icon(t.icon, size: 17, color: t.color ?? palette.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text, required this.blocked});
  final String text;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final c = blocked ? DeskColors.danger : DeskColors.amber;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            blocked ? Icons.block_rounded : Icons.warning_amber_rounded,
            size: 16,
            color: c,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: c),
            ),
          ),
        ],
      ),
    );
  }
}
