/// Tamil score tab: runs the Tamil eval on the Lab's shared meter and ranks
/// every installed model.
///
/// Same runner, dataset, scoring and storage as the phone's Tamil eval page;
/// only the presentation is desktop: the score reads on [LabGauge], like the
/// speed benchmark, so every measurement in the Lab looks the same.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinai_tamil_evals/thinai_tamil_evals.dart';

import '../../../eval/engine_eval_generator.dart';
import '../../../l10n/l10n.dart';
import '../../../models_repo/model_store.dart';
import '../../../state/providers.dart';
import '../../../ui/widgets/tamil_dial.dart';
import '../../diagnostics.dart';
import '../../l10n/desk_l10n.dart';
import '../../l10n/lab_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import '../../widgets/orb.dart';
import '../../widgets/toast.dart';
import 'lab_common.dart';
import 'speed_instruments.dart';

class LabTamilTab extends ConsumerStatefulWidget {
  const LabTamilTab({super.key});

  @override
  ConsumerState<LabTamilTab> createState() => _LabTamilTabState();
}

class _LabTamilTabState extends ConsumerState<LabTamilTab> {
  final EvalDataset _dataset = tamilV1();
  final _orb = OrbController();

  StreamSubscription<EvalEvent>? _sub;
  EvalRunner? _runner;
  EvalStep? _current;
  String _live = '';
  final List<ItemResult> _results = [];
  EvalReport? _partial;
  final Stopwatch _clock = Stopwatch();
  int _costDone = 0;
  DateTime? _finishAt;
  Timer? _tick;

  bool get _running => _sub != null;

  @override
  void dispose() {
    _tick?.cancel();
    // Leaving stops the run; a partial score is never saved.
    unawaited(_sub?.cancel());
    _orb.dispose();
    super.dispose();
  }

  void _start(LocalModel model) {
    if (_running || ref.read(labBusyProvider) != null) return;
    final runner = EvalRunner(
      dataset: _dataset,
      generator: EngineEvalGenerator.forModel(
        ref.read(llmEngineProvider),
        model,
      ),
    );
    Diagnostics.log('lab: tamil eval start on ${model.id}');
    ref.read(labBusyProvider.notifier).state = LabJob.tamil;
    _orb.mood = OrbMood.thinking;
    setState(() {
      _runner = runner;
      _current = null;
      _live = '';
      _results.clear();
      _partial = null;
      _costDone = 0;
      _finishAt = null;
    });
    _clock
      ..reset()
      ..start();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _finishAt != null) setState(() {});
    });
    _sub = runner
        .run(modelId: model.id)
        .listen(
          (e) => _onEvent(e, model),
          onError: (Object e) {
            Diagnostics.log('lab: tamil eval failed: $e');
            if (mounted) {
              showDeskToast(
                context.l10n.tamilEvalFailed('$e'),
                tone: DeskTone.error,
              );
            }
            _end();
          },
        );
  }

  void _onEvent(EvalEvent event, LocalModel model) {
    if (!mounted) return;
    switch (event) {
      case ItemStarted(:final step):
        setState(() {
          _current = step;
          _live = '';
        });
      case ItemOutput(:final text):
        _orb
          ..mood = OrbMood.speaking
          ..pulse(0.04);
        setState(() => _live = text);
      case ItemScored(:final step, :final result):
        _results.add(result);
        _costDone += step.cost;
        // The first items also load the model; too few skew the rate.
        if (_results.length >= 3) {
          final perCost = _clock.elapsedMicroseconds / _costDone;
          final left = (_runner!.totalCost - _costDone) * perCost;
          _finishAt = DateTime.now().add(Duration(microseconds: left.round()));
        }
        setState(() {
          _partial = EvalReport.score(
            dataset: _dataset,
            modelId: model.id,
            startedAt: DateTime.now(),
            elapsed: _clock.elapsed,
            items: _results,
          );
        });
      case RunCompleted(:final report):
        Diagnostics.log(
          'lab: tamil eval done, ${report.overall.toStringAsFixed(1)} '
          'in ${_clock.elapsed.inSeconds} s',
        );
        unawaited(ref.read(tamilEvalResultsProvider.notifier).record(report));
        showDeskToast(
          '${model.displayName}: ${report.overall.round()}',
          tone: DeskTone.success,
        );
        _end(keepScore: true);
    }
  }

  void _end({bool keepScore = false}) {
    _tick?.cancel();
    _clock.stop();
    _sub = null;
    _orb.mood = OrbMood.idle;
    if (!mounted) return;
    if (ref.read(labBusyProvider) == LabJob.tamil) {
      ref.read(labBusyProvider.notifier).state = null;
    }
    setState(() {
      _current = null;
      _live = '';
      if (!keepScore) {
        _partial = null;
        _results.clear();
      }
    });
  }

  void _stop() {
    final sub = _sub;
    if (sub == null) return;
    unawaited(sub.cancel());
    showDeskToast(context.l10n.tamilEvalStopped);
    _end();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LabJob?>(labRunRequestProvider, (_, next) {
      if (next != LabJob.tamil) return;
      ref.read(labRunRequestProvider.notifier).state = null;
      final models = chatModelsOf(
        ref.read(modelListProvider).valueOrNull ?? const [],
      );
      final model = resolveLabModel(
        models,
        ref.read(labModelIdProvider),
        ref.read(activeModelIdProvider),
      );
      if (model != null) _start(model);
    });
    final installed = ref.watch(modelListProvider);
    return installed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(context.l10n.tamilEvalFailed('$e'))),
      data: (all) {
        final models = chatModelsOf(all);
        final model = resolveLabModel(
          models,
          ref.watch(labModelIdProvider),
          ref.watch(activeModelIdProvider),
        );
        if (model == null) {
          return LabEmpty(
            icon: Icons.translate_rounded,
            title: context.l10n.tamilEvalEmptyTitle,
            body: context.l10n.tamilEvalEmptyBody,
          );
        }
        return LayoutBuilder(
          builder: (context, c) =>
              _layout(context, models, model, c.maxWidth >= 1040),
        );
      },
    );
  }

  Widget _layout(
    BuildContext context,
    List<LocalModel> models,
    LocalModel model,
    bool wide,
  ) {
    final l10n = context.l10n;
    final palette = DeskPalette.of(context);
    final busyElsewhere = ref.watch(labBusyProvider) != null && !_running;
    final saved = ref.watch(tamilScoreProvider(model.id));
    // Live score while running; otherwise this model's saved score.
    final score = _partial?.overall ?? saved ?? 0;
    final total =
        _runner?.steps.length ??
        _dataset.tasks.fold<int>(0, (n, t) => n + t.items.length);
    final done = _results.length;

    final controls = LabCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: LabModelPicker(
                models: models,
                selected: model,
                enabled: !_running,
                onChanged: (m) =>
                    ref.read(labModelIdProvider.notifier).state = m.id,
                badgeFor: (m) {
                  final s = ref.read(tamilScoreProvider(m.id));
                  return s == null ? null : 'த ${s.round()}';
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              l10n.tamilEvalIntro(total),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: palette.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: DeskMotion.medium,
            child: _running
                ? Padding(
                    key: const ValueKey('orb'),
                    padding: const EdgeInsets.only(right: 12),
                    child: Orb(size: 40, controller: _orb),
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
          AnimatedSwitcher(
            duration: DeskMotion.fast,
            child: _running
                ? LabRunButton(
                    key: const ValueKey('stop'),
                    label: l10n.tamilEvalStop,
                    icon: Icons.stop_rounded,
                    danger: true,
                    onPressed: _stop,
                  )
                : LabRunButton(
                    key: const ValueKey('run'),
                    label: saved == null
                        ? l10n.tamilEvalRun
                        : l10n.tamilEvalRunAgain,
                    icon: Icons.play_arrow_rounded,
                    onPressed: busyElsewhere ? null : () => _start(model),
                  ),
          ),
        ],
      ),
    );

    final gauge = LabCard(
      height: wide ? 460 : 420,
      child: Column(
        children: [
          Expanded(
            child: LabGauge(
              value: score,
              unit: l10n.tamilEvalScore,
              running: _running,
              fixedMax: 100,
              decimals: 0,
              status: _running
                  ? null
                  : (_partial == null && saved == null)
                  ? _Pill(text: l10n.tamilEvalNotRun, color: palette.textMuted)
                  : _Pill(
                      text: _verdictText(l10n, score),
                      color: _verdictColor(score),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          _Progress(
            done: done,
            total: total,
            running: _running,
            finishAt: _finishAt,
          ),
        ],
      ),
    );

    final live = LabCard(
      title: _current == null
          ? l10n.tamilEvalLiveReply
          : (deskIsTamil(context)
                ? _current!.task.labelTa
                : _current!.task.label),
      icon: Icons.short_text_rounded,
      height: wide ? 210 : 200,
      child: SingleChildScrollView(
        reverse: true,
        child: SizedBox(
          width: double.infinity,
          child: Text(
            _live.isEmpty
                ? (_running ? l10n.tamilEvalLoading : l10n.tamilEvalFootnote)
                : _live,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: _live.isEmpty
                  ? palette.textMuted
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );

    final skills = _SkillsCard(
      dataset: _dataset,
      axes:
          _partial?.axes ??
          ref.watch(tamilEvalResultsProvider)[model.id]?.axes ??
          const {},
      height: wide ? 234 : null,
    );

    final board = _TamilBoard(models: models);

    const gap = SizedBox(height: 16, width: 16);
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 4, 32, 32),
      children: [
        EnterAnimation(child: controls),
        gap,
        if (wide)
          EnterAnimation(
            delay: const Duration(milliseconds: 60),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: gauge),
                gap,
                Expanded(flex: 6, child: Column(children: [live, gap, skills])),
              ],
            ),
          )
        else ...[
          gauge,
          gap,
          live,
          gap,
          skills,
        ],
        gap,
        EnterAnimation(delay: const Duration(milliseconds: 120), child: board),
      ],
    );
  }

  static String _verdictText(AppLocalizations l10n, double score) =>
      switch (score) {
        < kTamilLowEnd * 100 => l10n.tamilEvalVerdictNone,
        < kTamilMidEnd * 100 => l10n.tamilEvalVerdictBasic,
        < 70 => l10n.tamilEvalVerdictFair,
        _ => l10n.tamilEvalVerdictStrong,
      };

  static Color _verdictColor(double score) => switch (score) {
    < kTamilLowEnd * 100 => DeskColors.danger,
    < kTamilMidEnd * 100 => DeskColors.amber,
    _ => DeskColors.green,
  };
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

/// Items done out of the total, with a smooth bar and the time left.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.done,
    required this.total,
    required this.running,
    required this.finishAt,
  });

  final int done;
  final int total;
  final bool running;
  final DateTime? finishAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = DeskPalette.of(context);
    final fraction = total == 0 ? 0.0 : done / total;
    String right;
    if (!running) {
      right = '';
    } else if (finishAt == null) {
      right = l10n.tamilEvalEstimating;
    } else {
      final left = finishAt!.difference(DateTime.now());
      right = l10n.tamilEvalTimeLeft(
        fmtSeconds(left.isNegative ? Duration.zero : left),
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Text(
              '${l10n.tamilEvalProgress(done, total)} ${l10n.tamilEvalQuestions}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.textMuted,
                fontFeatures: tabularFigures,
              ),
            ),
            const Spacer(),
            Text(
              right,
              style: TextStyle(fontSize: 12, color: palette.textFaint),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: fraction),
            duration: DeskMotion.medium,
            curve: DeskMotion.ease,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: palette.hairline,
              valueColor: const AlwaysStoppedAnimation(DeskColors.green),
            ),
          ),
        ),
      ],
    );
  }
}

/// The three skill axes as bars, live while running.
class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.dataset, required this.axes, this.height});

  final EvalDataset dataset;
  final Map<String, double> axes;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tamil = deskIsTamil(context);
    return LabCard(
      title: context.l10n.tamilEvalSkills,
      icon: Icons.insights_rounded,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final axis in dataset.axes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      tamil ? axis.labelTa : axis.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: scheme.onSurface),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          end: ((axes[axis.id] ?? 0) / 100).clamp(0.0, 1.0),
                        ),
                        duration: DeskMotion.slow,
                        curve: DeskMotion.ease,
                        builder: (context, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 8,
                          backgroundColor: palette.hairline,
                          valueColor: const AlwaysStoppedAnimation(
                            DeskColors.green,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 34,
                    child: Text(
                      axes[axis.id] == null
                          ? '-'
                          : axes[axis.id]!.round().toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TamilBoard extends ConsumerWidget {
  const _TamilBoard({required this.models});

  final List<LocalModel> models;

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
              showAxes: true,
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
