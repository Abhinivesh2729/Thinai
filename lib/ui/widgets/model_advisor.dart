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
    final scheme = Theme.of(context).colorScheme;
    final choice = _choice;
    final device = widget.speed.device;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'What do you want to do?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            device.known
                ? 'Thinai picks a model that fits your phone · ${device.summary}'
                : 'Thinai picks a model for the job',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          if (choice != null) ...[
            const SizedBox(height: 14),
            _Answer(
              key: ValueKey(choice),
              useCase: choice,
              speed: widget.speed,
              installedCatalogIds: widget.installedCatalogIds,
              downloads: widget.downloads,
              onDownload: widget.onDownload,
              onCancel: widget.onCancel,
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                useCase.icon,
                size: 15,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                useCase.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({
    super.key,
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
    final scheme = Theme.of(context).colorScheme;
    final device = speed.device;
    final result = recommend(
      useCase,
      device,
      installedIds: installedCatalogIds,
      speed: speed,
    );

    final unavailable = result.unavailable;
    if (unavailable != null) {
      return _Note(text: unavailable, icon: Icons.info_outline_rounded);
    }

    final best = result.best;
    if (best == null) {
      return _Note(
        text: result.caveat ?? 'Nothing in the catalogue fits this one.',
        icon: Icons.info_outline_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.caveat != null) ...[
          _Note(text: result.caveat!, icon: Icons.warning_amber_rounded),
          const SizedBox(height: 10),
        ],
        Text(
          device.known ? 'Best model for your phone' : 'Best model for this',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        _BestCard(
          pick: best,
          download: downloads[best.model.id],
          onDownload: () => onDownload(best.model),
          onCancel: () => onCancel?.call(best.model.id),
        ),
        if (result.alternatives.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Also worth considering',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
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
    final scheme = Theme.of(context).colorScheme;
    final model = pick.model;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: model.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(model.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${model.author} · ${model.approxSize} download',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Stat(icon: Icons.speed_rounded, label: pick.speedLabel),
              _Stat(icon: Icons.memory_rounded, label: pick.ramLabel),
              _Stat(
                icon: Icons.article_outlined,
                label: '${model.contextLabel} context',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FitLine(fit: pick.fit),
          const SizedBox(height: 8),
          for (final reason in pick.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: pick.installed
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Already downloaded'),
                  )
                : download != null
                    ? _DownloadingButton(
                        handle: download!,
                        onCancel: onCancel,
                      )
                    : FilledButton.icon(
                        onPressed: onDownload,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text('Download ${model.approxSize}'),
                      ),
          ),
          if (pick.estimatedTokensPerSecond != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                pick.speedIsMeasured
                    ? 'Speed measured on this phone by Benchmark.'
                    : 'Estimated speed. Run Benchmark for the real number.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: scheme.onSurfaceVariant,
                ),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(pick.model.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pick.model.displayName,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${pick.speedLabel} · ${pick.model.approxSize}',
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
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
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (fit) {
      RamFit.comfortable => (Icons.check_circle_rounded, Colors.green.shade600),
      RamFit.tight => (Icons.warning_amber_rounded, Colors.orange.shade700),
      RamFit.tooBig => (Icons.block_rounded, scheme.error),
      RamFit.unknown => (Icons.help_outline_rounded, scheme.onSurfaceVariant),
    };
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          fit.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
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
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<DownloadProgress>(
      stream: handle.progress,
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final fraction = progress?.fraction;
        final percent =
            fraction == null ? null : (fraction * 100).toStringAsFixed(0);

        return Material(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onCancel,
            child: Stack(
              children: [
                // The fill is the progress bar: the button itself carries how
                // far along the download is, rather than a separate bar the
                // eye has to find.
                if (fraction != null)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction.clamp(0.0, 1.0),
                      child: ColoredBox(
                        color: scheme.primary.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close_rounded, size: 16, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        percent == null
                            ? 'Starting… · tap to cancel'
                            : 'Downloading $percent% · tap to cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
