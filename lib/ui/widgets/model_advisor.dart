/// "What do you want to do?" — the top of the Models page.
///
/// A catalogue of thirty GGUF files asks the reader to already know what
/// "Qwen 3.5 · 2B Q4_K_M" buys them over "Phi-4 · Mini". This asks the one
/// question they can answer about themselves and does the translating.
library;

import 'package:flutter/material.dart';

import '../../models_repo/catalog.dart';
import '../../models_repo/downloader.dart';
import '../../models_repo/recommender.dart';
import '../../models_repo/use_cases.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

class ModelAdvisor extends StatefulWidget {
  const ModelAdvisor({
    super.key,
    required this.speed,
    required this.installedCatalogIds,
    required this.onDownload,
    this.downloads = const {},
    this.onCancel,
  });

  /// What is known about this phone's speed: its class, plus any benchmark
  /// measurements taken on it.
  final SpeedKnowledge speed;

  /// [CatalogModel.id]s already on disk.
  final Set<String> installedCatalogIds;

  final void Function(CatalogModel model) onDownload;

  /// Downloads in flight, by catalog id, so the card can show real progress
  /// rather than an inert "Downloading...".
  final Map<String, DownloadHandle> downloads;

  /// Cancels the download for a catalog id.
  final void Function(String catalogId)? onCancel;

  @override
  State<ModelAdvisor> createState() => _ModelAdvisorState();
}

class _ModelAdvisorState extends State<ModelAdvisor> {
  UseCase? _choice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final choice = _choice;
    final device = widget.speed.device;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.lg,
        Space.lg,
        Space.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                icon: Icons.auto_awesome_rounded,
                size: 36,
                background: scheme.primaryContainer,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What do you want to do?',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.known
                          ? 'Thinai picks a model that fits your phone · ${device.summary}'
                          : 'Thinai picks a model for the job',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final useCase in UseCase.values)
                _ChoiceChip(
                  useCase: useCase,
                  selected: useCase == choice,
                  onTap: () => setState(
                    () => _choice = useCase == choice ? null : useCase,
                  ),
                ),
            ],
          ),
          if (choice != null)
            // Faded in rather than grown: the answer is at full size from its
            // first frame, so its button is where it will stay the moment it
            // appears.
            TweenAnimationBuilder<double>(
              key: ValueKey(choice),
              tween: Tween(begin: 0, end: 1),
              duration: Motion.base,
              curve: Motion.curve,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 6 * (1 - t)),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: Space.lg),
                child: _Answer(
                  useCase: choice,
                  speed: widget.speed,
                  installedCatalogIds: widget.installedCatalogIds,
                  downloads: widget.downloads,
                  onDownload: widget.onDownload,
                  onCancel: widget.onCancel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.useCase,
    required this.selected,
    required this.onTap,
  });

  final UseCase useCase;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.surface : scheme.onSurface;
    return AnimatedContainer(
      duration: Motion.fast,
      decoration: ShapeDecoration(
        color: selected ? scheme.onSurface : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? scheme.onSurface : scheme.outlineVariant,
          ),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  useCase.icon,
                  size: 15,
                  color: selected ? fg : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  useCase.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({
    required this.useCase,
    required this.speed,
    required this.installedCatalogIds,
    required this.downloads,
    required this.onDownload,
    required this.onCancel,
  });

  final UseCase useCase;
  final SpeedKnowledge speed;
  final Set<String> installedCatalogIds;
  final Map<String, DownloadHandle> downloads;
  final void Function(CatalogModel model) onDownload;
  final void Function(String catalogId)? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final device = speed.device;
    final result = recommend(
      useCase,
      device,
      installedIds: installedCatalogIds,
      speed: speed,
    );

    final unavailable = result.unavailable;
    if (unavailable != null) {
      return InlineNotice(text: unavailable);
    }

    final best = result.best;
    if (best == null) {
      return InlineNotice(
        text: result.caveat ?? 'Nothing in the catalogue fits this one.',
      );
    }

    final overline = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.caveat != null) ...[
          InlineNotice(
            text: result.caveat!,
            icon: Icons.warning_amber_rounded,
            tone: TagTone.warning,
          ),
          const SizedBox(height: Space.md),
        ],
        Text(
          device.known ? 'Best model for your phone' : 'Best model for this',
          style: overline,
        ),
        const SizedBox(height: Space.sm),
        _BestCard(
          pick: best,
          download: downloads[best.model.id],
          onDownload: () => onDownload(best.model),
          onCancel: () => onCancel?.call(best.model.id),
        ),
        if (result.alternatives.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          Text('Also worth considering', style: overline),
          const SizedBox(height: Space.sm),
          for (final alt in result.alternatives) _AlternativeRow(pick: alt),
        ],
      ],
    );
  }
}

class _BestCard extends StatelessWidget {
  const _BestCard({
    required this.pick,
    required this.download,
    required this.onDownload,
    required this.onCancel,
  });

  final Recommendation pick;
  final DownloadHandle? download;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final model = pick.model;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: model.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(Radii.md - 1),
                ),
                child: Text(model.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${model.author} · ${model.approxSize} download',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Stat(icon: Icons.speed_rounded, label: pick.speedLabel),
              _Stat(icon: Icons.memory_rounded, label: pick.ramLabel),
              _Stat(
                icon: Icons.notes_rounded,
                label: '${model.contextLabel} context',
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          _FitLine(fit: pick.fit),
          const SizedBox(height: Space.sm),
          for (final reason in pick.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Space.md),
          SizedBox(
            width: double.infinity,
            child: pick.installed
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Already downloaded'),
                  )
                : download != null
                ? _DownloadingButton(handle: download!, onCancel: onCancel)
                : FilledButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text('Download ${model.approxSize}'),
                  ),
          ),
          if (pick.estimatedTokensPerSecond != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(
                pick.speedIsMeasured
                    ? 'Speed measured on this phone by Benchmark.'
                    : 'Estimated speed. Run Benchmark for the real number.',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlternativeRow extends StatelessWidget {
  const _AlternativeRow({required this.pick});

  final Recommendation pick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(pick.model.emoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              pick.model.displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${pick.speedLabel} · ${pick.model.approxSize}',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(Radii.xs),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: Space.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 11.5,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _FitLine extends StatelessWidget {
  const _FitLine({required this.fit});

  final RamFit fit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final app = AppColors.of(context);
    final (icon, color) = switch (fit) {
      RamFit.comfortable => (Icons.check_circle_rounded, app.success),
      RamFit.tight => (Icons.warning_amber_rounded, app.warning),
      RamFit.tooBig => (Icons.block_rounded, scheme.error),
      RamFit.unknown => (Icons.help_outline_rounded, scheme.onSurfaceVariant),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          fit.label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// The download button while a transfer is running: how far along it is, and a
/// way to stop it.
///
/// An inert "Downloading…" leaves the reader with no idea whether a 2 GB
/// transfer is nearly done or barely started, and no way out of one they
/// started by mistake.
class _DownloadingButton extends StatelessWidget {
  const _DownloadingButton({required this.handle, required this.onCancel});

  final DownloadHandle handle;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return StreamBuilder<DownloadProgress>(
      stream: handle.progress,
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final fraction = progress?.fraction;
        final percent = fraction == null
            ? null
            : (fraction * 100).toStringAsFixed(0);

        return Material(
          color: AppColors.of(context).card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md + 2),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onCancel,
            child: SizedBox(
              height: 48,
              child: Stack(
                children: [
                  // The fill is the progress bar: the button itself carries
                  // how far along the download is, rather than a separate bar
                  // the eye has to find.
                  if (fraction != null)
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fraction.clamp(0.0, 1.0),
                        child: ColoredBox(
                          color: scheme.primary.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: Space.sm),
                        Text(
                          percent == null
                              ? 'Starting… · tap to cancel'
                              : 'Downloading $percent% · tap to cancel',
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
