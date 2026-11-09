/// Pieces shared by the Lab tabs: the card, the model picker, the empty
/// state, and the lock that keeps two measurements off the engine at once.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../models_repo/catalog.dart';
import '../../../models_repo/model_store.dart';
import '../../l10n/desk_l10n.dart';
import '../../l10n/lab_strings.dart';
import '../../shell/desk_nav.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';

/// A measurement that owns the engine.
enum LabJob { speed, gpu }

/// Which Lab measurement is running, if any.
///
/// The tabs stay alive while hidden, so without this a speed run and a GPU
/// test could be queued on the one engine together and each would measure
/// the other's load.
final labBusyProvider = StateProvider<LabJob?>((ref) => null);

/// The model the Speed and GPU tabs measure. Shared so picking a model once
/// carries over between them.
final labModelIdProvider = StateProvider<String?>((ref) => null);

/// Installed models that can generate text. Embedding models cannot answer a
/// prompt, so measuring one would only produce an error.
List<LocalModel> chatModelsOf(List<LocalModel> all) {
  final embedding = {for (final c in embeddingCatalog) c.servedId};
  return [
    for (final m in all)
      if (!embedding.contains(m.id)) m,
  ];
}

/// The picked model, else the loaded one, else the first installed.
LocalModel? resolveLabModel(
  List<LocalModel> models,
  String? pickedId,
  String? activeId,
) {
  if (models.isEmpty) return null;
  for (final id in [pickedId, activeId]) {
    if (id == null) continue;
    for (final m in models) {
      if (m.id == id) return m;
    }
  }
  return models.first;
}

String fmtSeconds(Duration d) {
  final seconds = d.inMilliseconds / 1000;
  if (seconds < 10) return '${seconds.toStringAsFixed(2)}s';
  if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
  final minutes = d.inMinutes;
  return '${minutes}m ${(seconds - minutes * 60).toStringAsFixed(0)}s';
}

String relativeDay(BuildContext context, DateTime at) {
  final now = DateTime.now();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(at.year, at.month, at.day)).inDays;
  final shell = ShellStrings.of(context);
  if (days <= 0) return shell.today;
  if (days == 1) return shell.yesterday;
  return LabStrings.of(context).daysAgo(days);
}

const tabularFigures = [FontFeature.tabularFigures()];

/// The Lab's surface: a panel with a hairline border and an optional header.
class LabCard extends StatelessWidget {
  const LabCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(18),
    this.height,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsets padding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final header = title == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: DeskColors.green),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          );
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(DeskSize.radiusL),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          ?header,
          if (height == null) child else Expanded(child: child),
        ],
      ),
    );
  }
}

/// Desktop model dropdown: a hoverable field that opens a menu under itself.
class LabModelPicker extends StatelessWidget {
  const LabModelPicker({
    super.key,
    required this.models,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    this.badgeFor,
  });

  final List<LocalModel> models;
  final LocalModel selected;
  final bool enabled;
  final ValueChanged<LocalModel> onChanged;

  /// Short note shown beside a model in the menu, e.g. its saved speed.
  final String? Function(LocalModel model)? badgeFor;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      enabled: enabled,
      tooltip: LabStrings.of(context).model,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 460),
      onSelected: (id) => onChanged(models.firstWhere((m) => m.id == id)),
      itemBuilder: (context) => [
        for (final m in models)
          PopupMenuItem(
            value: m.id,
            height: 44,
            child: Row(
              children: [
                Icon(
                  m.id == selected.id
                      ? Icons.check_rounded
                      : Icons.memory_rounded,
                  size: 16,
                  color: m.id == selected.id
                      ? DeskColors.green
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    m.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  badgeFor?.call(m) ?? m.sizeFormatted,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: palette.textMuted,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Hoverable(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        builder: (context, hovered) => AnimatedContainer(
          duration: DeskMotion.fast,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: hovered && enabled
                ? scheme.onSurface.withValues(alpha: 0.05)
                : palette.canvas,
            borderRadius: BorderRadius.circular(DeskSize.radiusM),
            border: Border.all(
              color: hovered && enabled
                  ? DeskColors.green.withValues(alpha: 0.5)
                  : palette.hairline,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.memory_rounded,
                size: 17,
                color: DeskColors.green,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                selected.sizeFormatted,
                style: TextStyle(fontSize: 11.5, color: palette.textFaint),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.unfold_more_rounded,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Green filled action with an icon; switches to a quiet red Stop.
class LabRunButton extends StatelessWidget {
  const LabRunButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? DeskColors.danger : DeskColors.green;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: danger ? color.withValues(alpha: 0.12) : color,
        foregroundColor: danger ? color : Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.25),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DeskSize.radiusM),
        ),
      ),
    );
  }
}

/// Small rounded label, e.g. "Fastest" or "Vulkan".
class LabTag extends StatelessWidget {
  const LabTag({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DeskColors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: context.tracking(0.3),
          color: c,
        ),
      ),
    );
  }
}

/// One-line inline notice (busy, error, info).
class LabNotice extends StatelessWidget {
  const LabNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color,
  });

  final String message;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DeskPalette.of(context).textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        border: Border.all(color: c.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              message,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: c),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when nothing is installed: says so and offers the Models page.
class LabEmpty extends ConsumerWidget {
  const LabEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DeskPalette.of(context);
    return Center(
      child: EnterAnimation(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DeskColors.green.withValues(alpha: 0.12),
                ),
                child: Icon(icon, size: 30, color: DeskColors.green),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              LabRunButton(
                label: ShellStrings.of(context).getModel,
                icon: Icons.download_rounded,
                onPressed: () =>
                    ref.read(deskPageProvider.notifier).state = DeskPage.models,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
