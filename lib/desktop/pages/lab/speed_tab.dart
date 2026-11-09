/// Speed tab: the desktop benchmark.
///
/// Same measurement as the phone's Benchmark page (fixed prompt, 128 tokens,
/// temperature 0.2, the saved GPU choice, the latest result per model stored
/// through [benchmarkResultsProvider]) so numbers from either app feed the
/// same estimates. Only the layout is new.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../llm/generation_settings.dart';
import '../../../llm/llm_engine.dart';
import '../../../models_repo/benchmark_store.dart';
import '../../../models_repo/catalog.dart';
import '../../../models_repo/model_store.dart';
import '../../../models_repo/recommender.dart';
import '../../../models_repo/use_cases.dart';
import '../../../state/providers.dart';
import '../../l10n/desk_l10n.dart';
import '../../l10n/lab_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import '../../widgets/orb.dart';
import '../../widgets/toast.dart';
import 'lab_common.dart';
import 'speed_instruments.dart';

/// Identical to the phone's prompt on purpose: throughput is only comparable
/// between models, and between the two apps, if the work is identical.
const _kBenchmarkPrompt =
    'Write a detailed paragraph explaining how a neural network learns from '
    'data. Cover training, weights, and prediction.';

const _kBenchmarkTokens = 128;

class _Run {
  const _Run({
    required this.modelName,
    required this.tokensPerSecond,
    required this.timeToFirstToken,
    required this.tokens,
    required this.total,
  });

  final String modelName;
  final double tokensPerSecond;
  final Duration timeToFirstToken;
  final int tokens;
  final Duration total;
}

class LabSpeedTab extends ConsumerStatefulWidget {
  const LabSpeedTab({super.key});

  @override
  ConsumerState<LabSpeedTab> createState() => _LabSpeedTabState();
}

class _LabSpeedTabState extends ConsumerState<LabSpeedTab> {
  bool _running = false;
  bool _stopRequested = false;
  String? _error;
  String _preview = '';
  LlmStats _stats = const LlmStats();

  final List<double> _samples = [];
  int _sampledTokens = 0;
  Duration _sampledAt = Duration.zero;
  double _peak = 0;

  final List<_Run> _history = [];
  final _orb = OrbController();
  final _outputScroll = ScrollController();

  @override
  void dispose() {
    _orb.dispose();
    _outputScroll.dispose();
    super.dispose();
  }

  Future<void> _run(LocalModel model) async {
    if (_running || ref.read(labBusyProvider) != null) return;
    final strings = LabStrings.of(context);
    final l10n = context.l10n;
    ref.read(labBusyProvider.notifier).state = LabJob.speed;
    _orb.mood = OrbMood.thinking;
    setState(() {
      _running = true;
      _stopRequested = false;
      _error = null;
      _preview = '';
      _stats = const LlmStats();
      _samples.clear();
      _sampledTokens = 0;
      _sampledAt = Duration.zero;
      _peak = 0;
    });

    try {
      // The model's own context window and the saved GPU choice, so the
      // number measured here is the speed chat will actually get.
      final options = await GenerationSettingsStore.instance.optionsFor(
        model,
        requestedTemperature: 0.2,
        maxTokens: _kBenchmarkTokens,
      );
      final stream = ref
          .read(llmEngineProvider)
          .generate(_kBenchmarkPrompt, modelPath: model.path, options: options);

      await for (final token in stream) {
        if (!mounted) return;
        if (token.isError) throw StateError(token.full);
        _orb
          ..mood = OrbMood.speaking
          ..pulse(0.05);
        setState(() {
          _stats = token.stats;
          _preview = token.full;
          _sample(token.stats);
        });
        _followOutput();
        if (token.done) break;
      }

      if (!mounted) return;
      final rate = _stats.tokensPerSecond;
      if (_stopRequested) {
        // A cut-short run measures mostly warm-up; saving it would drag the
        // bandwidth estimate for every model down.
        showDeskToast(strings.stoppedToast);
      } else if (rate != null) {
        unawaited(
          ref
              .read(benchmarkResultsProvider.notifier)
              .record(
                BenchmarkResult(
                  modelId: model.id,
                  tokensPerSecond: rate,
                  modelBytes: model.sizeBytes,
                  measuredAt: DateTime.now(),
                ),
              ),
        );
        showDeskToast(
          strings.savedToast(model.displayName, rate.toStringAsFixed(1)),
          tone: DeskTone.success,
        );
        setState(() {
          _history.insert(
            0,
            _Run(
              modelName: model.displayName,
              tokensPerSecond: rate,
              timeToFirstToken: _stats.timeToFirstToken ?? Duration.zero,
              tokens: _stats.tokens,
              total: _stats.elapsed,
            ),
          );
          if (_history.length > 6) _history.removeLast();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = l10n.benchmarkError('$e'));
        showDeskToast(l10n.benchmarkError('$e'), tone: DeskTone.error);
      }
    } finally {
      _orb.mood = OrbMood.idle;
      if (mounted) {
        ref.read(labBusyProvider.notifier).state = null;
        setState(() => _running = false);
      }
    }
  }

  /// Throughput over the last window rather than the running average, so the
  /// line shows the model speeding up as the cache warms instead of a flat
  /// line.
  void _sample(LlmStats stats) {
    const window = Duration(milliseconds: 200);
    final since = stats.decodeTime - _sampledAt;
    if (since < window) return;
    final produced = stats.tokens - _sampledTokens;
    final seconds = since.inMicroseconds / 1e6;
    if (produced <= 0 || seconds <= 0) return;
    final rate = produced / seconds;
    _samples.add(rate);
    if (_samples.length > 90) _samples.removeAt(0);
    _peak = math.max(_peak, rate);
    _sampledTokens = stats.tokens;
    _sampledAt = stats.decodeTime;
  }

  void _followOutput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_outputScroll.hasClients) return;
      _outputScroll.jumpTo(_outputScroll.position.maxScrollExtent);
    });
  }

  void _stop() {
    setState(() => _stopRequested = true);
    ref.read(llmEngineProvider).cancelCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final installed = ref.watch(modelListProvider);
    return installed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(context.l10n.benchmarkError('$e'))),
      data: (all) {
        final models = chatModelsOf(all);
        final model = resolveLabModel(
          models,
          ref.watch(labModelIdProvider),
          ref.watch(activeModelIdProvider),
        );
        if (model == null) {
          return LabEmpty(
            icon: Icons.speed_rounded,
            title: context.l10n.benchmarkEmptyTitle,
            body: context.l10n.benchmarkEmptyBody,
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) =>
              _layout(context, models, model, constraints.maxWidth >= 1040),
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
    final saved = ref.watch(benchmarkResultsProvider);
    final busyElsewhere = ref.watch(labBusyProvider) != null && !_running;

    final controls = _ControlBar(
      models: models,
      model: model,
      running: _running,
      busyElsewhere: busyElsewhere,
      orb: _orb,
      saved: saved,
      onPick: (m) => ref.read(labModelIdProvider.notifier).state = m.id,
      onRun: () => _run(model),
      onStop: _stop,
    );

    final gauge = LabCard(
      height: wide ? 460 : 420,
      child: Column(
        children: [
          Expanded(
            child: SpeedGauge(
              tokensPerSecond: _stats.tokensPerSecond ?? 0,
              peak: _peak,
              running: _running,
            ),
          ),
          const SizedBox(height: 12),
          _StatRow(stats: _stats),
        ],
      ),
    );

    final spark = LabCard(
      title: context.l10n.benchmarkThroughput,
      icon: Icons.show_chart_rounded,
      height: wide ? 210 : 200,
      trailing: _peak > 0
          ? Text(
              context.l10n.benchmarkPeak(_peak.toStringAsFixed(1)),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DeskColors.amber,
                fontFeatures: tabularFigures,
              ),
            )
          : null,
      child: SpeedSparkline(
        samples: List.unmodifiable(_samples),
        running: _running,
      ),
    );

    final output = _OutputCard(
      text: _preview,
      error: _error,
      controller: _outputScroll,
      height: wide ? 234 : 220,
    );

    final board = _ResultsBoard(
      models: models,
      saved: saved,
      selectedId: model.id,
      history: _history,
      onSelect: _running
          ? null
          : (m) => ref.read(labModelIdProvider.notifier).state = m.id,
    );

    final advice = _BestForPc(installedIds: {for (final m in models) m.id});

    const gap = SizedBox(height: 16, width: 16);
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 4, 32, 32),
      children: [
        EnterAnimation(child: controls),
        gap,
        if (wide) ...[
          EnterAnimation(
            delay: const Duration(milliseconds: 60),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: gauge),
                gap,
                Expanded(
                  flex: 6,
                  child: Column(children: [spark, gap, output]),
                ),
              ],
            ),
          ),
          gap,
          EnterAnimation(
            delay: const Duration(milliseconds: 120),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: board),
                gap,
                Expanded(flex: 5, child: advice),
              ],
            ),
          ),
        ] else ...[
          gauge,
          gap,
          spark,
          gap,
          output,
          gap,
          board,
          gap,
          advice,
        ],
      ],
    );
  }
}

// ─── control bar ───────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.models,
    required this.model,
    required this.running,
    required this.busyElsewhere,
    required this.orb,
    required this.saved,
    required this.onPick,
    required this.onRun,
    required this.onStop,
  });

  final List<LocalModel> models;
  final LocalModel model;
  final bool running;
  final bool busyElsewhere;
  final OrbController orb;
  final Map<String, BenchmarkResult> saved;
  final ValueChanged<LocalModel> onPick;
  final VoidCallback onRun;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final strings = LabStrings.of(context);
    final palette = DeskPalette.of(context);
    final l10n = context.l10n;
    return LabCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                flex: 3,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: LabModelPicker(
                    models: models,
                    selected: model,
                    enabled: !running,
                    onChanged: onPick,
                    badgeFor: (m) {
                      final r = saved[m.id];
                      return r == null
                          ? null
                          : '${r.tokensPerSecond.toStringAsFixed(1)} tok/s';
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Text(
                  strings.runHint,
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
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: a, child: child),
                ),
                child: running
                    ? Padding(
                        key: const ValueKey('orb'),
                        padding: const EdgeInsets.only(right: 12),
                        child: Orb(size: 40, controller: orb),
                      )
                    : const SizedBox.shrink(key: ValueKey('none')),
              ),
              AnimatedSwitcher(
                duration: DeskMotion.fast,
                child: running
                    ? LabRunButton(
                        key: const ValueKey('stop'),
                        label: l10n.benchmarkStop,
                        icon: Icons.stop_rounded,
                        danger: true,
                        onPressed: onStop,
                      )
                    : LabRunButton(
                        key: const ValueKey('run'),
                        label: l10n.benchmarkRun,
                        icon: Icons.play_arrow_rounded,
                        onPressed: busyElsewhere ? null : onRun,
                      ),
              ),
            ],
          ),
          AnimatedSize(
            duration: DeskMotion.medium,
            curve: DeskMotion.ease,
            alignment: Alignment.topCenter,
            child: busyElsewhere
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LabNotice(
                      message: strings.busy,
                      icon: Icons.hourglass_top_rounded,
                      color: DeskColors.amber,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ─── stats ─────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stats});

  final LlmStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ttft = stats.timeToFirstToken;
    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: Icons.bolt_rounded,
            label: l10n.benchmarkFirstToken,
            value: ttft == null ? '-' : fmtSeconds(ttft),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.numbers_rounded,
            label: l10n.benchmarkTokens,
            value: '${stats.tokens} / $_kBenchmarkTokens',
            progress: stats.tokens / _kBenchmarkTokens,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.timer_outlined,
            label: l10n.benchmarkTotal,
            value: stats.elapsed == Duration.zero
                ? '-'
                : fmtSeconds(stats.elapsed),
          ),
        ),
      ],
    );
  }
}

// ─── output ────────────────────────────────────────────────────────────────

class _OutputCard extends StatelessWidget {
  const _OutputCard({
    required this.text,
    required this.error,
    required this.controller,
    required this.height,
  });

  final String text;
  final String? error;
  final ScrollController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final shell = ShellStrings.of(context);
    return LabCard(
      title: context.l10n.benchmarkSampleOutput,
      icon: Icons.notes_rounded,
      height: height,
      trailing: text.isEmpty
          ? null
          : DeskIconButton(
              icon: Icons.copy_rounded,
              tooltip: shell.copy,
              size: 28,
              iconSize: 15,
              onPressed: () {
                unawaited(Clipboard.setData(ClipboardData(text: text)));
                showDeskToast(shell.copied, tone: DeskTone.success);
              },
            ),
      child: error != null
          ? SingleChildScrollView(
              child: LabNotice(
                message: error!,
                icon: Icons.error_outline_rounded,
                color: DeskColors.danger,
              ),
            )
          : text.isEmpty
          ? Center(
              child: Text(
                context.l10n.benchmarkPlotEmpty,
                style: TextStyle(fontSize: 12.5, color: palette.textFaint),
              ),
            )
          : Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: palette.codeBg,
                borderRadius: BorderRadius.circular(DeskSize.radiusM),
              ),
              child: Scrollbar(
                controller: controller,
                child: SingleChildScrollView(
                  controller: controller,
                  child: SelectableText(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ─── results board ─────────────────────────────────────────────────────────

/// Every installed model with its saved speed, fastest first. Clicking a row
/// picks that model for the next run.
class _ResultsBoard extends StatelessWidget {
  const _ResultsBoard({
    required this.models,
    required this.saved,
    required this.selectedId,
    required this.history,
    required this.onSelect,
  });

  final List<LocalModel> models;
  final Map<String, BenchmarkResult> saved;
  final String selectedId;
  final List<_Run> history;
  final ValueChanged<LocalModel>? onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = LabStrings.of(context);
    final palette = DeskPalette.of(context);
    final rows = [...models]
      ..sort((a, b) {
        final ra = saved[a.id]?.tokensPerSecond ?? -1;
        final rb = saved[b.id]?.tokensPerSecond ?? -1;
        return rb.compareTo(ra);
      });
    final best = rows
        .map((m) => saved[m.id]?.tokensPerSecond ?? 0)
        .fold<double>(0, math.max);

    return LabCard(
      title: strings.savedResults,
      icon: Icons.leaderboard_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            best == 0 ? strings.noSavedResults : strings.savedResultsHint,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          for (final m in rows)
            _BoardRow(
              model: m,
              result: saved[m.id],
              best: best,
              selected: m.id == selectedId,
              onTap: onSelect == null ? null : () => onSelect!(m),
            ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              context.l10n.benchmarkThisSession,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: context.tracking(0.4),
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            for (final run in history)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        run.modelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.benchmarkRunSummary(
                        run.tokens,
                        fmtSeconds(run.timeToFirstToken),
                        fmtSeconds(run.total),
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: palette.textFaint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 78,
                      child: Text(
                        '${run.tokensPerSecond.toStringAsFixed(1)} tok/s',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: DeskColors.green,
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
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.model,
    required this.result,
    required this.best,
    required this.selected,
    required this.onTap,
  });

  final LocalModel model;
  final BenchmarkResult? result;
  final double best;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = LabStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final r = result;
    final isBest = r != null && best > 0 && r.tokensPerSecond == best;
    return Hoverable(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      builder: (context, hovered) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DeskMotion.fast,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          decoration: BoxDecoration(
            color: selected
                ? DeskColors.green.withValues(alpha: 0.08)
                : hovered && onTap != null
                ? scheme.onSurface.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DeskSize.radiusM),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      model.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isBest) ...[
                    LabTag(label: strings.fastest),
                    const SizedBox(width: 8),
                  ],
                  if (r != null)
                    Text(
                      relativeDay(context, r.measuredAt),
                      style: TextStyle(fontSize: 11, color: palette.textFaint),
                    ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 84,
                    child: Text(
                      r == null
                          ? strings.notMeasured
                          : '${r.tokensPerSecond.toStringAsFixed(1)} tok/s',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: r == null ? 11.5 : 13,
                        fontWeight: r == null
                            ? FontWeight.w500
                            : FontWeight.w800,
                        color: r == null ? palette.textFaint : DeskColors.green,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              // Scaled against the fastest model, so a slower model is
              // visibly slower; grows in when a result lands.
              TweenAnimationBuilder<double>(
                tween: Tween(
                  end: r == null || best == 0 ? 0 : r.tokensPerSecond / best,
                ),
                duration: const Duration(milliseconds: 600),
                curve: DeskMotion.ease,
                builder: (context, t, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: t,
                    minHeight: 6,
                    color: isBest ? DeskColors.green : DeskColors.greenDeep,
                    backgroundColor: palette.hairline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── best for this PC ──────────────────────────────────────────────────────

/// What the measured speed implies about which model to run.
///
/// Once one model has been measured, the bandwidth it implies re-scales the
/// estimate for the whole catalogue, so the advice here gets better with
/// every run. Tamil is included because it is the job Thinai exists for.
class _BestForPc extends ConsumerWidget {
  const _BestForPc({required this.installedIds});

  final Set<String> installedIds;

  static const _jobs = [UseCase.fastChat, UseCase.reasoning, UseCase.tamil];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(speedKnowledgeProvider);
    final device = speed.device;
    final l10n = context.l10n;
    final palette = DeskPalette.of(context);

    final installedCatalogIds = <String>{
      for (final m in chatCatalog)
        if (installedIds.contains(m.servedId)) m.id,
    };

    final basis = speed.calibrated
        ? device.known
              ? l10n.benchmarkMeasuredWithDevice(
                  device.localizedSummary(l10n),
                  speed.bandwidthGBps.toStringAsFixed(1),
                )
              : l10n.benchmarkMeasured(speed.bandwidthGBps.toStringAsFixed(1))
        : device.known
        ? l10n.benchmarkEstimateWithDevice(device.localizedSummary(l10n))
        : l10n.benchmarkCalibratePrompt;

    return LabCard(
      title: LabStrings.of(context).bestForThisPc,
      icon: Icons.auto_awesome_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                speed.calibrated
                    ? Icons.verified_rounded
                    : Icons.insights_rounded,
                size: 14,
                color: speed.calibrated ? DeskColors.green : palette.textFaint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  basis,
                  style: TextStyle(fontSize: 12, color: palette.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final job in _jobs)
            _AdviceRow(
              job: job,
              speed: speed,
              installedCatalogIds: installedCatalogIds,
            ),
        ],
      ),
    );
  }
}

class _AdviceRow extends StatelessWidget {
  const _AdviceRow({
    required this.job,
    required this.speed,
    required this.installedCatalogIds,
  });

  final UseCase job;
  final SpeedKnowledge speed;
  final Set<String> installedCatalogIds;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final pick = recommend(
      job,
      speed.device,
      installedIds: installedCatalogIds,
      speed: speed,
    ).best;
    if (pick == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: palette.canvas,
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DeskColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DeskSize.radiusS),
            ),
            child: Icon(job.icon, size: 16, color: DeskColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.localizedLabel(context.l10n),
                  style: TextStyle(fontSize: 11.5, color: palette.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  pick.model.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pick.localizedSpeedLabel(context.l10n),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: pick.speedIsMeasured
                      ? DeskColors.green
                      : palette.textMuted,
                  fontFeatures: tabularFigures,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                pick.installed
                    ? context.l10n.benchmarkInstalled
                    : pick.model.approxSize,
                style: TextStyle(fontSize: 11, color: palette.textFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
