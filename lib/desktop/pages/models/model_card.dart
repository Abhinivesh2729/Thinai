/// Catalog, featured and installed cards for the desktop Models page.
///
/// Each card watches only its own slice of state (its download handle, its
/// partial, whether it is installed), so a download starting or finishing
/// rebuilds one card, and progress ticks rebuild only the bar inside it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../models_repo/catalog.dart';
import '../../../models_repo/model_store.dart';
import '../../../models_repo/recommender.dart';
import '../../../state/providers.dart';
import '../../l10n/models_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import 'model_bits.dart';
import 'model_details_dialog.dart';
import 'models_common.dart';
import '../../l10n/desk_l10n.dart';

/// Heights the grid lays cards out at. Fixed so the grid never measures its
/// children, which keeps scrolling and resizing cheap.
const kCatalogCardHeight = 232.0;
const kFeaturedCardHeight = 212.0;
const kInstalledCardHeight = 176.0;

/// The hoverable surface every card sits on: lifts 3 px, deepens its shadow
/// and warms its border on hover.
class CardShell extends StatelessWidget {
  const CardShell({
    super.key,
    required this.child,
    this.onTap,
    this.highlighted = false,
    this.glow,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Green border, for Top picks and the active model.
  final bool highlighted;

  /// Vendor colour washed into the background, for the featured card.
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return RepaintBoundary(
      child: Hoverable(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        builder: (context, hovered) {
          final border = highlighted
              ? DeskColors.green.withValues(alpha: hovered ? 0.95 : 0.7)
              : hovered
              ? Color.lerp(palette.hairline, DeskColors.green, 0.35)!
              : palette.hairline;
          final g = glow;
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: DeskMotion.medium,
              curve: DeskMotion.ease,
              transform: Matrix4.translationValues(0, hovered ? -3 : 0, 0),
              decoration: BoxDecoration(
                color: palette.panel,
                gradient: g == null
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.alphaBlend(
                            g.withValues(alpha: palette.isDark ? 0.16 : 0.09),
                            palette.panel,
                          ),
                          palette.panel,
                          Color.alphaBlend(
                            DeskColors.green.withValues(
                              alpha: palette.isDark ? 0.10 : 0.06,
                            ),
                            palette.panel,
                          ),
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                borderRadius: BorderRadius.circular(DeskSize.radiusL),
                border: Border.all(color: border, width: highlighted ? 1.4 : 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: palette.isDark
                          ? (hovered ? 0.45 : 0.22)
                          : (hovered ? 0.10 : 0.04),
                    ),
                    blurRadius: hovered ? 26 : 10,
                    offset: Offset(0, hovered ? 10 : 3),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// ─── catalog card ───────────────────────────────────────────────────────────

class CatalogCard extends ConsumerWidget {
  const CatalogCard({
    super.key,
    required this.model,
    this.pick,
    this.featured = false,
  });

  final CatalogModel model;

  /// Set when this card is a Top pick for the chosen goal.
  final Recommendation? pick;

  /// The wide hero layout at the top of the default catalog.
  final bool featured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ModelsStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    final local = ref.watch(
      modelListProvider.select(
        (a) => localFor(model, a.valueOrNull ?? const <LocalModel>[]),
      ),
    );
    final handle = ref.watch(downloadsProvider.select((d) => d[model.id]));
    final partial = ref.watch(
      partialDownloadsProvider.select((a) => partialFor(model, a.valueOrNull)),
    );
    final needsEncoder = ref.watch(
      missingProjectorsProvider.select(
        (a) => a.valueOrNull?.contains(model.id) ?? false,
      ),
    );
    final activeId = ref.watch(activeModelIdProvider);
    final device = watchDevice(ref);
    final fit = fitFor(model, device);
    final installed = local != null;
    final blocked = !installed && fit == RamFit.tooBig;

    void details() => showModelDetails(context, model);
    final actions = ModelActions(context);

    // ── footer: progress while downloading, the saved part while paused,
    // otherwise a status line and the one action that applies.
    final Widget footer;
    final String footerKey;
    if (handle != null) {
      footerKey = 'dl';
      footer = Row(
        children: [
          Expanded(
            child: LiveProgress(key: ValueKey(handle), handle: handle),
          ),
          const SizedBox(width: 14),
          DeskButton(
            label: l.modelsPause,
            icon: Icons.pause_rounded,
            style: DeskButtonStyle.quiet,
            onPressed: () => actions.pause(model.id),
          ),
        ],
      );
    } else if (!installed && partial != null) {
      footerKey = 'paused';
      footer = Row(
        children: [
          Expanded(child: PausedProgress(partial: partial)),
          const SizedBox(width: 14),
          DeskButton(
            label: resumeLabel(partial, l),
            icon: Icons.play_arrow_rounded,
            onPressed: () => actions.resume(model),
          ),
        ],
      );
    } else {
      final Widget meta;
      final Widget action;
      if (installed && needsEncoder) {
        footerKey = 'vision';
        meta = _MetaLine(
          icon: Icons.check_circle_rounded,
          color: DeskColors.green,
          text: l.modelsInstalled,
        );
        action = DeskButton(
          label: l.modelsAddVision(model.mmprojSize),
          icon: Icons.visibility_rounded,
          style: DeskButtonStyle.outlined,
          onPressed: () => actions.addVision(model),
        );
      } else if (local != null) {
        final active = activeId == local.id;
        footerKey = active ? 'active' : 'installed';
        meta = _MetaLine(
          icon: Icons.storage_rounded,
          color: palette.textMuted,
          text: fmtSize(local.sizeBytes),
        );
        action = model.kind != ModelKind.chat
            ? StatusPill(
                label: l.modelsInstalled,
                icon: Icons.check_circle_rounded,
                color: DeskColors.green,
              )
            : active
            ? StatusPill(
                label: l.modelsActiveInChat,
                icon: Icons.bolt_rounded,
                color: DeskColors.green,
              )
            : DeskButton(
                label: l.modelsActivate,
                icon: Icons.play_circle_outline_rounded,
                style: DeskButtonStyle.outlined,
                onPressed: () => actions.load(local),
              );
      } else if (blocked) {
        footerKey = 'blocked';
        meta = _MetaLine(
          icon: Icons.block_rounded,
          color: DeskColors.danger,
          text: s.fitTooBig,
        );
        action = StatusPill(
          label: l.modelsNeedsRam,
          icon: Icons.memory_rounded,
        );
      } else {
        footerKey = 'get';
        final p = pick;
        meta = p != null && p.estimatedTokensPerSecond != null
            ? _MetaLine(
                icon: p.speedIsMeasured
                    ? Icons.speed_rounded
                    : Icons.timer_outlined,
                color: DeskColors.green,
                text: '${p.localizedSpeedLabel(l)} · ${fitLabel(fit, l, s)}',
              )
            : _MetaLine(dot: fitColor(fit, scheme), text: fitLabel(fit, l, s));
        action = DeskButton(
          label: model.approxSize,
          icon: Icons.arrow_downward_rounded,
          onPressed: () => actions.download(model),
        );
      }
      footer = Row(
        children: [
          Expanded(child: meta),
          const SizedBox(width: 12),
          action,
        ],
      );
    }

    final footerSwitcher = SizedBox(
      height: 38,
      child: AnimatedSwitcher(
        duration: DeskMotion.medium,
        switchInCurve: DeskMotion.ease,
        switchOutCurve: DeskMotion.exit,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.center,
          children: [...previous, ?current],
        ),
        child: KeyedSubtree(key: ValueKey(footerKey), child: footer),
      ),
    );

    final chips = SizedBox(
      height: 24,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        clipBehavior: Clip.hardEdge,
        children: [
          if (pick != null)
            SpecChip(
              label: l.modelsTopPick,
              icon: Icons.star_rounded,
              color: DeskColors.green,
            ),
          ...cardChips(model, l, tightFit: !installed && fit == RamFit.tight),
        ],
      ),
    );

    final header = Row(
      children: [
        LogoTile(model: model, size: featured ? 56 : 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (featured)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: DeskColors.green,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l.modelsFeaturedTitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: DeskColors.green,
                        ),
                      ),
                      Text(
                        '  ·  ${model.author}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  model.author.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: context.tracking(0.9),
                    color: palette.textFaint,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                model.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: featured ? 21 : 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: featured ? -0.4 : -0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        DeskIconButton(
          icon: Icons.more_horiz_rounded,
          tooltip: l.modelsModelDetails,
          onPressed: details,
        ),
      ],
    );

    final Widget blurb;
    final p = pick;
    if (p != null) {
      final reasons = p.localizedReasons(l).take(2).toList();
      blurb = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: DeskColors.green,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      blurb = Text(
        deskWording(model.description),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: featured ? 13.5 : 12.5,
          height: 1.45,
          color: palette.textMuted,
        ),
      );
    }

    if (featured) {
      return CardShell(
        onTap: details,
        glow: vendorColor(model),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [blurb, const Spacer(), chips],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: footerSwitcher),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CardShell(
      onTap: details,
      highlighted: pick != null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 12),
            blurb,
            const Spacer(),
            chips,
            const SizedBox(height: 12),
            footerSwitcher,
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.text, this.icon, this.color, this.dot});

  final String text;
  final IconData? icon;
  final Color? color;

  /// A small status dot instead of an icon.
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return Row(
      children: [
        if (dot != null)
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 7),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          )
        else if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── installed card ─────────────────────────────────────────────────────────

class InstalledCard extends ConsumerWidget {
  const InstalledCard({super.key, required this.model});

  final LocalModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final palette = DeskPalette.of(context);
    final active = ref.watch(activeModelIdProvider) == model.id;
    final tamil = ref.watch(tamilScoreProvider(model.id));
    final catalog = catalogFor(model);
    final actions = ModelActions(context);

    return CardShell(
      highlighted: active,
      onTap: active ? null : () => actions.load(model),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                LogoTile(local: model),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catalog?.displayName ?? model.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        model.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (catalog != null)
                  DeskIconButton(
                    icon: Icons.more_horiz_rounded,
                    tooltip: l.modelsModelDetails,
                    onPressed: () => showModelDetails(context, catalog),
                  ),
              ],
            ),
            const Spacer(),
            Wrap(
              spacing: 6,
              children: [
                SpecChip(
                  label: fmtSize(model.sizeBytes),
                  icon: Icons.storage_rounded,
                ),
                if (catalog != null)
                  SpecChip(label: catalog.parameters, icon: Icons.bolt_rounded),
                if (tamil != null)
                  SpecChip(
                    label: 'த ${tamil.round()}',
                    color: DeskColors.green,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AnimatedSwitcher(
                  duration: DeskMotion.medium,
                  child: active
                      ? StatusPill(
                          key: const ValueKey('active'),
                          label: l.modelsActiveInChat,
                          icon: Icons.bolt_rounded,
                          color: DeskColors.green,
                        )
                      : DeskButton(
                          key: const ValueKey('load'),
                          label: l.modelsActivate,
                          icon: Icons.play_circle_outline_rounded,
                          style: DeskButtonStyle.outlined,
                          onPressed: () => actions.load(model),
                        ),
                ),
                const Spacer(),
                DeskIconButton(
                  icon: Icons.tune_rounded,
                  tooltip: l.modelsSettingsTitle,
                  onPressed: () => showModelSettingsDialog(context, model),
                ),
                const SizedBox(width: 2),
                DeskIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: l.modelsDeleteModel,
                  onPressed: () => actions.delete(model),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
