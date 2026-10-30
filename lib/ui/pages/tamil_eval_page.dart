import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinai_tamil_evals/thinai_tamil_evals.dart';

import '../../eval/engine_eval_generator.dart';
import '../../l10n/l10n.dart';
import '../../models_repo/catalog.dart';
import '../../models_repo/model_store.dart';
import '../../state/providers.dart';
import '../widgets/model_picker.dart';
import '../widgets/tamil_dial.dart';

/// Builds the generator a run uses. The page passes the real engine; tests
/// pass a fake.
typedef EvalGeneratorFactory = EvalGenerator Function(LocalModel model);

enum _Phase { idle, running, stopped, failed }

/// Measures how well a model understands and writes Tamil, on this phone.
///
/// The speed benchmark answers how fast; this answers how good. It runs the
/// bundled 60-item set from `thinai_tamil_evals`, shows progress on a dial,
/// and keeps the latest report per model so the score appears on the Models
/// page too.
class TamilEvalPage extends ConsumerStatefulWidget {
  const TamilEvalPage({super.key, this.generatorFor});

  /// Overrides the engine-backed generator, for tests.
  final EvalGeneratorFactory? generatorFor;

  @override
  ConsumerState<TamilEvalPage> createState() => _TamilEvalPageState();
}

class _TamilEvalPageState extends ConsumerState<TamilEvalPage> {
  final EvalDataset _dataset = tamilV1();

  LocalModel? _model;
  _Phase _phase = _Phase.idle;
  String? _error;

  StreamSubscription<EvalEvent>? _sub;
  EvalRunner? _runner;
  EvalStep? _current;
  String _live = '';

  /// Scored so far in this run, in run order.
  final List<ItemResult> _results = [];
  EvalReport? _partial;

  // Time estimate: the run's cost is known up front (see EvalStep.cost), so
  // the rate observed so far projects a finish time. A one-second tick counts
  // down to it between items.
  final Stopwatch _clock = Stopwatch();
  int _costDone = 0;
  DateTime? _finishAt;
  Timer? _tick;

  bool get _running => _phase == _Phase.running;

  @override
  void dispose() {
    _tick?.cancel();
    // Leaving the page stops the run; a partial score is never saved.
    unawaited(_sub?.cancel());
    super.dispose();
  }

  EvalGenerator _generatorFor(LocalModel model) =>
      widget.generatorFor?.call(model) ??
      EngineEvalGenerator.forModel(ref.read(llmEngineProvider), model);

  void _start() {
    final model = _model;
    if (model == null || _running) return;
    final runner = EvalRunner(
      dataset: _dataset,
      generator: _generatorFor(model),
    );
    setState(() {
      _phase = _Phase.running;
      _error = null;
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
          _onEvent,
          onError: (Object e) => _end(_Phase.failed, error: '$e'),
        );
  }

  void _onEvent(EvalEvent event) {
    if (!mounted) return;
    switch (event) {
      case ItemStarted(:final step):
        setState(() {
          _current = step;
          _live = '';
        });
      case ItemOutput(:final text):
        setState(() => _live = text);
      case ItemScored(:final step, :final result):
        _results.add(result);
        _costDone += step.cost;
        final runner = _runner!;
        // Too few items and the first one, which also loads the model, skews
        // the rate.
        if (_results.length >= 3) {
          final perCost = _clock.elapsedMicroseconds / _costDone;
          final left = (runner.totalCost - _costDone) * perCost;
          _finishAt = DateTime.now().add(Duration(microseconds: left.round()));
        }
        setState(() {
          _partial = EvalReport.score(
            dataset: _dataset,
            modelId: _model!.id,
            startedAt: DateTime.now(),
            elapsed: _clock.elapsed,
            items: _results,
          );
        });
      case RunCompleted(:final report):
        unawaited(ref.read(tamilEvalResultsProvider.notifier).record(report));
        _end(_Phase.idle);
    }
  }

  void _end(_Phase phase, {String? error}) {
    _tick?.cancel();
    _clock.stop();
    _sub = null;
    if (!mounted) return;
    setState(() {
      _phase = phase;
      _error = error;
      _current = null;
      _live = '';
      _partial = null;
      if (phase != _Phase.idle) _results.clear();
    });
  }

  void _stop() {
    final sub = _sub;
    if (sub == null) return;
    // Cancelling stops the engine synchronously; the future only reports
    // that the stream has been torn down, which nothing here waits on.
    unawaited(sub.cancel());
    _end(_Phase.stopped);
  }

  Future<bool> _confirmLeave() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.tamilEvalLeaveTitle),
        content: Text(context.l10n.tamilEvalLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.tamilEvalLeaveStay),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.tamilEvalLeaveStop),
          ),
        ],
      ),
    );
    return stop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final installed = ref.watch(modelListProvider);
    final activeId = ref.watch(activeModelIdProvider);
    final saved = ref.watch(tamilEvalResultsProvider);

    return PopScope(
      canPop: !_running,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) {
          _stop();
          // Popped after the rebuild that drops the guard: with the run still
          // marked as running, the pop would be refused.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(this.context).pop();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.tamilEvalTitle),
          actions: [
            if (_running)
              IconButton(
                tooltip: context.l10n.tamilEvalStop,
                icon: const Icon(Icons.stop_circle_rounded),
                color: scheme.error,
                onPressed: _stop,
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: installed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text(context.l10n.tamilEvalFailed('$e'))),
          data: (all) {
            // Only chat models can answer questions.
            final embedding = {for (final c in embeddingCatalog) c.servedId};
            final models = [
              for (final m in all)
                if (!embedding.contains(m.id)) m,
            ];
            if (models.isEmpty) return const _EmptyEval();
            _model ??= models.firstWhere(
              (m) => m.id == activeId,
              orElse: () => models.first,
            );
            final report = _shownReport(saved);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                ModelPicker(
                  models: models,
                  selected: _model!,
                  enabled: !_running,
                  onChanged: (m) => setState(() {
                    _model = m;
                    if (_phase != _Phase.running) _phase = _Phase.idle;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
                _DialCard(
                  running: _running,
                  done: _results.length,
                  total: _dataset.itemCount,
                  report: _running ? null : report,
                  currentTask: _current?.task,
                  timeLeft: _finishAt?.difference(DateTime.now()),
                  steps: _runner?.steps ?? const [],
                  results: _running ? _results : (report?.items ?? const []),
                  currentIndex: _current?.index,
                  itemCount: _dataset.itemCount,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: Icon(
                    _running
                        ? Icons.hourglass_top_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _running
                        ? context.l10n.tamilEvalRunning
                        : (report == null
                              ? context.l10n.tamilEvalRun
                              : context.l10n.tamilEvalRunAgain),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _running ? null : _start,
                ),
                if (_phase == _Phase.stopped || _phase == _Phase.failed) ...[
                  const SizedBox(height: 14),
                  _Notice(
                    error: _phase == _Phase.failed,
                    message: _phase == _Phase.failed
                        ? context.l10n.tamilEvalFailed(_error ?? '')
                        : context.l10n.tamilEvalStopped,
                  ),
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _running && _current != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _LiveReply(step: _current!, text: _live),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 16),
                _SkillsCard(
                  dataset: _dataset,
                  report: _running ? _partial : report,
                  running: _running,
                  current: _current?.task.id,
                  onOpenTask: report == null || _running
                      ? null
                      : (task) => _openTask(context, task, report),
                ),
                if (_compared(saved, models).length > 1) ...[
                  const SizedBox(height: 16),
                  _CompareCard(
                    entries: _compared(saved, models),
                    selectedId: _model!.id,
                    onSelect: _running
                        ? null
                        : (m) => setState(() {
                            _model = m;
                            _phase = _Phase.idle;
                          }),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  context.l10n.tamilEvalFootnote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The saved report for the selected model, if it is from this dataset
  /// version.
  EvalReport? _shownReport(Map<String, EvalReport> saved) {
    final r = saved[_model?.id];
    return r != null && r.datasetVersion == _dataset.version ? r : null;
  }

  List<(LocalModel, EvalReport)> _compared(
    Map<String, EvalReport> saved,
    List<LocalModel> models,
  ) {
    final out = [
      for (final m in models)
        if (saved[m.id] case final r? when r.datasetVersion == _dataset.version)
          (m, r),
    ]..sort((a, b) => b.$2.overall.compareTo(a.$2.overall));
    return out;
  }

  void _openTask(BuildContext context, EvalTask task, EvalReport report) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TaskItemsSheet(task: task, report: report),
    );
  }
}

// ─── dial card ─────────────────────────────────────────────────────────────

class _DialCard extends StatelessWidget {
  const _DialCard({
    required this.running,
    required this.done,
    required this.total,
    required this.report,
    required this.currentTask,
    required this.timeLeft,
    required this.steps,
    required this.results,
    required this.currentIndex,
    required this.itemCount,
  });

  final bool running;
  final int done;
  final int total;
  final EvalReport? report;
  final EvalTask? currentTask;
  final Duration? timeLeft;
  final List<EvalStep> steps;
  final List<ItemResult> results;
  final int? currentIndex;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final report = this.report;

    final TamilDialMode mode;
    final double value;
    final String readout;
    final String caption;
    if (running) {
      mode = TamilDialMode.progress;
      value = total == 0 ? 0 : done / total;
      readout = '$done/$total';
      caption = l10n.tamilEvalQuestions;
    } else if (report != null) {
      mode = TamilDialMode.score;
      value = report.overall / 100;
      readout = report.overall.round().toString();
      caption = l10n.tamilEvalScore;
    } else {
      mode = TamilDialMode.progress;
      value = 0;
      readout = '-';
      caption = l10n.tamilEvalNotRun;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          TamilDial(
            value: value,
            mode: mode,
            readout: readout,
            caption: caption,
          ),
          const SizedBox(height: 14),
          _ItemStrip(
            count: itemCount,
            results: results,
            current: running ? currentIndex : null,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey('${running}_${report?.overall}'),
              child: _status(context, report),
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(BuildContext context, EvalReport? report) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final muted = TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant);
    if (running) {
      final task = currentTask;
      final left = timeLeft;
      return Row(
        children: [
          const _Pulse(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task == null ? l10n.tamilEvalLoading : _taskLabel(context, task),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            left == null
                ? l10n.tamilEvalEstimating
                : l10n.tamilEvalTimeLeft(
                    _fmtDuration(left.isNegative ? Duration.zero : left),
                  ),
            style: muted,
          ),
        ],
      );
    }
    if (report != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _VerdictPill(score: report.overall),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              l10n.tamilEvalLastRun(_fmtDuration(report.elapsed)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
          ),
        ],
      );
    }
    return Text(
      l10n.tamilEvalIntro(total),
      textAlign: TextAlign.center,
      style: muted.copyWith(height: 1.45),
    );
  }
}

/// One segment per question, in run order, coloured by its score as it
/// lands. A run reads at a glance: where the model is, and where it fails.
class _ItemStrip extends StatelessWidget {
  const _ItemStrip({
    required this.count,
    required this.results,
    required this.current,
  });

  final int count;
  final List<ItemResult> results;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 6,
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 1.5),
            Expanded(
              child: i == current
                  ? const _CurrentSegment()
                  : AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: i < results.length
                            ? _scoreColor(scheme, results[i].score)
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrentSegment extends StatefulWidget {
  const _CurrentSegment();

  @override
  State<_CurrentSegment> createState() => _CurrentSegmentState();
}

class _CurrentSegmentState extends State<_CurrentSegment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.3 + 0.7 * _c.value),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Breathing dot beside the task in progress.
class _Pulse extends StatefulWidget {
  const _Pulse();

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary.withValues(alpha: 0.35 + 0.65 * _c.value),
        ),
      ),
    );
  }
}

class _VerdictPill extends StatelessWidget {
  const _VerdictPill({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final label = switch (score) {
      < kTamilLowEnd * 100 => l10n.tamilEvalVerdictNone,
      < kTamilMidEnd * 100 => l10n.tamilEvalVerdictBasic,
      < 70 => l10n.tamilEvalVerdictFair,
      _ => l10n.tamilEvalVerdictStrong,
    };
    final color = tamilScoreColor(scheme, score / 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── live reply ────────────────────────────────────────────────────────────

class _LiveReply extends StatelessWidget {
  const _LiveReply({required this.step, required this.text});

  final EvalStep step;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.tamilEvalLiveReply,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _question(step.item),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          // Plain text, never markdown: model output is shown as it is, and a
          // stray asterisk must not restyle the line.
          Text(
            text.isEmpty ? '…' : text.trim(),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── skills ────────────────────────────────────────────────────────────────

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({
    required this.dataset,
    required this.report,
    required this.running,
    required this.current,
    required this.onOpenTask,
  });

  final EvalDataset dataset;
  final EvalReport? report;
  final bool running;
  final String? current;
  final void Function(EvalTask task)? onOpenTask;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tamil = _isTamil(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.tamilEvalSkills,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          for (final axis in dataset.axes) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tamil ? axis.labelTa : axis.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _Score(value: report?.axes[axis.id], large: true),
              ],
            ),
            const SizedBox(height: 4),
            for (final task in dataset.tasks)
              if (task.axis == axis.id)
                _TaskRow(
                  label: tamil ? task.labelTa : task.label,
                  score: report?.task(task.id),
                  active: running && task.id == current,
                  onTap: onOpenTask == null || report?.task(task.id) == null
                      ? null
                      : () => onOpenTask!(task),
                ),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.label,
    required this.score,
    required this.active,
    required this.onTap,
  });

  final String label;
  final TaskScore? score;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final score = this.score;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (active) ...[const _Pulse(), const SizedBox(width: 6)],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: score == null && !active
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                ),
                if (score != null && score.format == EvalFormat.mcq) ...[
                  Text(
                    context.l10n.tamilEvalCorrect(score.correct, score.count),
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                _Score(value: score?.score),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(end: (score?.score ?? 0) / 100),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: t,
                  minHeight: 5,
                  color: _scoreColor(scheme, t),
                  backgroundColor: scheme.surfaceContainerHigh,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.value, this.large = false});

  final double? value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = value;
    return SizedBox(
      width: large ? 40 : 30,
      child: Text(
        v == null ? '-' : v.round().toString(),
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: large ? 16 : 13,
          fontWeight: FontWeight.w800,
          color: v == null ? scheme.onSurfaceVariant : scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ─── compare ───────────────────────────────────────────────────────────────

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.entries,
    required this.selectedId,
    required this.onSelect,
  });

  final List<(LocalModel, EvalReport)> entries;
  final String selectedId;
  final ValueChanged<LocalModel>? onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.tamilEvalOnThisPhone(deviceKind),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          for (final (model, report) in entries)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onSelect == null ? null : () => onSelect!(model),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        model.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: model.id == selectedId
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: report.overall / 100),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: t,
                            minHeight: 5,
                            color: _scoreColor(scheme, t),
                            backgroundColor: scheme.surfaceContainerHigh,
                          ),
                        ),
                      ),
                    ),
                    _Score(value: report.overall),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── drill-down ────────────────────────────────────────────────────────────

/// Every item of one task: what was asked, what the model said, what was
/// expected, and the score. This is what makes a number trustworthy, and how
/// a bad item gets noticed.
class _TaskItemsSheet extends StatelessWidget {
  const _TaskItemsSheet({required this.task, required this.report});

  final EvalTask task;
  final EvalReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final results = {
      for (final r in report.items)
        if (r.taskId == task.id) r.itemId: r,
    };
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            _isTamil(context) ? task.labelTa : task.label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final item in task.items)
            if (results[item.id] case final r?)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ItemMark(score: r.score),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _question(item),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _Labelled(
                            label: context.l10n.tamilEvalReply,
                            text: _reply(context, item, r.output),
                          ),
                          const SizedBox(height: 4),
                          _Labelled(
                            label: context.l10n.tamilEvalExpected,
                            text: _expected(context, item),
                          ),
                        ],
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

class _ItemMark extends StatelessWidget {
  const _ItemMark({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _scoreColor(scheme, score);
    return Container(
      width: 34,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${(score * 100).round()}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          TextSpan(text: text),
        ],
      ),
      style: TextStyle(fontSize: 12.5, height: 1.45, color: scheme.onSurface),
    );
  }
}

// ─── empty and notices ─────────────────────────────────────────────────────

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.error});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = error ? scheme.onErrorContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? scheme.errorContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 18,
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEval extends StatelessWidget {
  const _EmptyEval();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'த',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.tamilEvalEmptyTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.tamilEvalEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── helpers ───────────────────────────────────────────────────────────────

/// The dial's colour scale, for bars and item marks.
Color _scoreColor(ColorScheme scheme, double fraction) =>
    tamilScoreColor(scheme, fraction);

bool _isTamil(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ta';

String _taskLabel(BuildContext context, EvalTask task) =>
    _isTamil(context) ? task.labelTa : task.label;

/// What an item asks, in one or two lines.
String _question(EvalItem item) => switch (item) {
  McqItem() => item.question,
  TranslateItem() => item.source,
  QaItem() => item.question,
  WritingItem() => item.instruction,
  CorrectionItem() => item.source,
};

/// The reply as the scorer read it: for multiple choice, the chosen option
/// spelled out, since a bare letter means nothing without the options.
String _reply(BuildContext context, EvalItem item, String output) {
  final text = output.trim();
  if (text.isEmpty) return context.l10n.tamilEvalNoReply;
  if (item is McqItem) {
    final choice = parseChoice(text, item);
    if (choice != null) {
      return '${kOptionLetters[choice]}. ${item.options[choice]}';
    }
  }
  return text;
}

String _expected(BuildContext context, EvalItem item) => switch (item) {
  McqItem() => '${kOptionLetters[item.answer]}. ${item.options[item.answer]}',
  TranslateItem() => item.references.first,
  QaItem() => item.answers.join(' / '),
  WritingItem() => context.l10n.tamilEvalRules(
    [
      '${item.rules.minSentences}-${item.rules.maxSentences}',
      ...item.rules.mustUse,
    ].join(' · '),
  ),
  CorrectionItem() => item.reference,
};

String _fmtDuration(Duration d) {
  final s = d.inSeconds;
  if (s < 60) return '${s}s';
  return '${d.inMinutes}m ${(s % 60).toString().padLeft(2, '0')}s';
}
