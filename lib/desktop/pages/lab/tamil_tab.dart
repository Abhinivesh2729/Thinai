/// Tamil score tab: a desktop leaderboard of saved Tamil scores beside the
/// phone's Tamil eval page.
///
/// The eval itself (runner, dial, live reply, skill drill-down, leave guard)
/// is the phone's [TamilEvalPage] embedded as-is; rebuilding 1,200 lines of
/// run logic for v1 would only fork it. What desktop adds is the board: every
/// installed model ranked, with the three skill axes, readable at a glance.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinai_tamil_evals/thinai_tamil_evals.dart';

import '../../../l10n/l10n.dart';
import '../../../models_repo/model_store.dart';
import '../../../state/providers.dart';
import '../../../ui/pages/tamil_eval_page.dart';
import '../../../ui/widgets/tamil_dial.dart';
import '../../l10n/desk_l10n.dart';
import '../../l10n/lab_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import 'lab_common.dart';

class LabTamilTab extends ConsumerWidget {
  const LabTamilTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installed = ref.watch(modelListProvider);
    return installed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(context.l10n.tamilEvalFailed('$e'))),
      data: (all) {
        final models = chatModelsOf(all);
        if (models.isEmpty) {
          return LabEmpty(
            icon: Icons.translate_rounded,
            title: context.l10n.tamilEvalEmptyTitle,
            body: context.l10n.tamilEvalEmptyBody,
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1180;
            const eval = _EmbeddedEval();
            if (wide) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(32, 4, 32, 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: const EnterAnimation(child: eval),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 380,
                      child: EnterAnimation(
                        delay: const Duration(milliseconds: 80),
                        child: SingleChildScrollView(
                          child: _TamilBoard(models: models),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(32, 4, 32, 32),
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: _TamilBoard(models: models, compact: true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: eval,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// The phone page in a desktop frame. Its Scaffold and AppBar are re-skinned
/// to the panel colour so it reads as a card rather than a phone screen.
class _EmbeddedEval extends StatelessWidget {
  const _EmbeddedEval();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = DeskPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(DeskSize.radiusL),
        border: Border.all(color: palette.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: palette.panel,
          appBarTheme: theme.appBarTheme.copyWith(
            backgroundColor: palette.panel,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            centerTitle: false,
          ),
        ),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: const TamilEvalPage(),
        ),
      ),
    );
  }
}

// ─── leaderboard ───────────────────────────────────────────────────────────

class _TamilBoard extends ConsumerWidget {
  const _TamilBoard({required this.models, this.compact = false});

  final List<LocalModel> models;

  /// Hides the per-skill bars when the board sits above the eval and space
  /// is short.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = LabStrings.of(context);
    final palette = DeskPalette.of(context);
    final reports = ref.watch(tamilEvalResultsProvider);

    final rows = <(LocalModel, double?, EvalReport?)>[
      for (final m in models)
        (m, ref.watch(tamilScoreProvider(m.id)), reports[m.id]),
    ]..sort((a, b) => (b.$2 ?? -1).compareTo(a.$2 ?? -1));
    final scored = rows.where((r) => r.$2 != null).length;

    return LabCard(
      title: strings.tamilBoardTitle,
      icon: Icons.emoji_events_rounded,
      trailing: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DeskColors.green.withValues(alpha: 0.14),
        ),
        child: const Text(
          'த',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: DeskColors.green,
            height: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            scored == 0 ? strings.tamilBoardEmpty : strings.tamilBoardHint,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++)
            _BoardRow(
              rank: rows[i].$2 == null ? null : i + 1,
              model: rows[i].$1,
              score: rows[i].$2,
              report: rows[i].$3,
              showAxes: !compact,
              delay: Duration(milliseconds: 40 * i),
            ),
        ],
      ),
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.rank,
    required this.model,
    required this.score,
    required this.report,
    required this.showAxes,
    required this.delay,
  });

  final int? rank;
  final LocalModel model;
  final double? score;
  final EvalReport? report;
  final bool showAxes;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = score;
    final color = s == null
        ? palette.textFaint
        : tamilScoreColor(scheme, s / 100);
    // tamilScoreProvider already hides reports from an older dataset, so the
    // axes are only shown alongside a score that is shown.
    final axes = s == null ? null : report?.axes;

    return EnterAnimation(
      delay: delay,
      child: Hoverable(
        builder: (context, hovered) => AnimatedContainer(
          duration: DeskMotion.fast,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            color: hovered
                ? scheme.onSurface.withValues(alpha: 0.04)
                : rank == 1
                ? DeskColors.green.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DeskSize.radiusM),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _RankBadge(rank: rank),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s == null
                              ? context.l10n.tamilEvalNotRun
                              : _verdict(context.l10n, s),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: s == null ? palette.textFaint : color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: s ?? 0),
                    duration: const Duration(milliseconds: 700),
                    curve: DeskMotion.ease,
                    builder: (context, v, _) => Text(
                      s == null ? '-' : v.round().toString(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: s == null ? palette.textFaint : color,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Bar(fraction: (s ?? 0) / 100, color: color, height: 7),
              if (showAxes && axes != null && axes.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final axis in tamilV1().axes)
                  if (axes[axis.id] case final a?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 112,
                            child: Text(
                              deskPick(context, axis.label, axis.labelTa),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _Bar(
                              fraction: a / 100,
                              color: tamilScoreColor(scheme, a / 100),
                              height: 4,
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              a.round().toString(),
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: palette.textMuted,
                                fontFeatures: tabularFigures,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Same thresholds as the phone's verdict pill.
  static String _verdict(AppLocalizations l10n, double score) =>
      switch (score) {
        < kTamilLowEnd * 100 => l10n.tamilEvalVerdictNone,
        < kTamilMidEnd * 100 => l10n.tamilEvalVerdictBasic,
        < 70 => l10n.tamilEvalVerdictFair,
        _ => l10n.tamilEvalVerdictStrong,
      };
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int? rank;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final first = rank == 1;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: first ? DeskColors.green : palette.canvas,
        border: first ? null : Border.all(color: palette.hairline),
      ),
      child: Text(
        rank?.toString() ?? '·',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: first ? Colors.white : palette.textMuted,
          fontFeatures: tabularFigures,
        ),
      ),
    );
  }
}

/// A score bar that grows in from zero and eases to new values.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.color,
    required this.height,
  });

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: DeskMotion.ease,
      builder: (context, t, _) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: t,
          minHeight: height,
          color: color,
          backgroundColor: palette.hairline,
        ),
      ),
    );
  }
}
