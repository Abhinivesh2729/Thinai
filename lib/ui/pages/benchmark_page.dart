import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../llm/generation_settings.dart';
import '../../llm/llm_engine.dart';
import '../../models_repo/benchmark_store.dart';
import '../../models_repo/catalog.dart';
import '../../models_repo/model_store.dart';
import '../../models_repo/recommender.dart';
import '../../models_repo/use_cases.dart';
import '../../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/markdown_text.dart';
import '../widgets/ui_kit.dart';

/// Prompt every benchmark run uses.
///
/// Fixed on purpose: throughput is only comparable between models if the work
/// is identical. It is short so prompt processing stays a small, steady part
/// of the measurement, and open-ended so no model stops early.
const _kBenchmarkPrompt =
    'Write a detailed paragraph explaining how a neural network learns from '
    'data. Cover training, weights, and prediction.';

/// Tokens to generate per run. Long enough for the rate to settle, short
/// enough that a run on a slow phone still finishes in well under a minute.
const _kBenchmarkTokens = 128;

/// One completed measurement, kept so runs can be compared in the session.
class _Run {
  final String modelName;
  final double tokensPerSecond;
  final Duration timeToFirstToken;
  final int tokens;
  final Duration total;

  const _Run({
    required this.modelName,
    required this.tokensPerSecond,
    required this.timeToFirstToken,
    required this.tokens,
    required this.total,
  });
}

class BenchmarkPage extends ConsumerStatefulWidget {
  const BenchmarkPage({super.key});

  @override
  ConsumerState<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends ConsumerState<BenchmarkPage> {
  LocalModel? _model;
  bool _running = false;
  String? _error;
  String _preview = '';

  LlmStats _stats = const LlmStats();

  /// Windowed throughput samples that drive the live graph.
  final List<double> _samples = [];
  int _sampledTokens = 0;
  Duration _sampledAt = Duration.zero;

  final List<_Run> _history = [];

  double get _peak =>
      _samples.isEmpty ? 0 : _samples.reduce((a, b) => a > b ? a : b);

  Future<void> _run() async {
    final model = _model;
    if (model == null || _running) return;

    setState(() {
      _running = true;
      _error = null;
      _preview = '';
      _stats = const LlmStats();
      _samples.clear();
      _sampledTokens = 0;
      _sampledAt = Duration.zero;
    });

    try {
      // The model's own context window and the saved GPU choice, so the number
      // measured here is the speed chat will actually get.
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
        setState(() {
          _stats = token.stats;
          _preview = token.full;
          _sample(token.stats);
        });
        if (token.done) break;
      }

      if (!mounted) return;
      final rate = _stats.tokensPerSecond;
      if (rate != null) {
        // Kept beyond this screen: one real measurement is what lets the
        // Models page stop guessing, both for this model and — via the
        // bandwidth it implies — for every other one in the catalogue.
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
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  /// Records throughput over the last window rather than the running average,
  /// so the graph shows the model speeding up as the cache warms instead of a
  /// flat line.
  void _sample(LlmStats stats) {
    const window = Duration(milliseconds: 200);
    final since = stats.decodeTime - _sampledAt;
    if (since < window) return;
    final produced = stats.tokens - _sampledTokens;
    final seconds = since.inMicroseconds / 1e6;
    if (produced <= 0 || seconds <= 0) return;
    _samples.add(produced / seconds);
    if (_samples.length > 90) _samples.removeAt(0);
    _sampledTokens = stats.tokens;
    _sampledAt = stats.decodeTime;
  }

  void _stop() {
    ref.read(llmEngineProvider).cancelCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final installed = ref.watch(modelListProvider);
    final activeId = ref.watch(activeModelIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmark'),
        actions: [
          if (_running)
            IconButton(
              tooltip: 'Stop',
              icon: const Icon(Icons.stop_circle_rounded),
              color: scheme.error,
              onPressed: _stop,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: installed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (models) {
          if (models.isEmpty) {
            return const _EmptyBenchmark();
          }
          // Default to whatever is loaded, so the page measures what the user
          // is actually chatting with.
          _model ??= models.firstWhere(
            (m) => m.id == activeId,
            orElse: () => models.first,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.xs,
              Space.lg,
              Space.xxxl,
            ),
            children: [
              _ModelPicker(
                models: models,
                selected: _model!,
                enabled: !_running,
                onChanged: (m) => setState(() => _model = m),
              ),
              const SizedBox(height: 18),
              _Gauge(
                tokensPerSecond: _stats.tokensPerSecond ?? 0,
                scaleMax: math.max(20, (_peak * 1.25).ceilToDouble()),
                running: _running,
              ),
              const SizedBox(height: 18),
              _ThroughputGraph(samples: _samples, running: _running),
              const SizedBox(height: 18),
              _StatGrid(stats: _stats),
              const SizedBox(height: 18),
              // What the measurement means for what to run next. A number on
              // its own leaves the reader to work out whether 9 tok/s is good
              // and what to do about it.
              _HardwareAdvice(
                speed: ref.watch(speedKnowledgeProvider),
                installedIds: {for (final m in models) m.id},
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                icon: Icon(
                  _running ? Icons.hourglass_top_rounded : Icons.speed_rounded,
                ),
                label: Text(_running ? 'Running…' : 'Run benchmark'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _running ? null : _run,
              ),
              const SizedBox(height: 10),
              Text(
                'Generates $_kBenchmarkTokens tokens and measures decode '
                'speed. First token is reported separately.',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _ErrorCard(message: _error!),
              ],
              if (_preview.isNotEmpty) ...[
                const SizedBox(height: 18),
                _OutputCard(text: _preview),
              ],
              if (_history.isNotEmpty) ...[
                const SizedBox(height: 18),
                _HistoryCard(runs: _history),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── gauge ─────────────────────────────────────────────────────────────────

/// Animated dial for the live token rate. The needle and arc tween to each new
/// reading rather than jumping, which keeps a noisy per-token measurement
/// readable.
class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.tokensPerSecond,
    required this.scaleMax,
    required this.running,
  });

  final double tokensPerSecond;
  final double scaleMax;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: tokensPerSecond),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.of(context).card,
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 172,
                width: double.infinity,
                child: CustomPaint(
                  painter: _GaugePainter(
                    value: value,
                    scaleMax: scaleMax,
                    track: scheme.onSurface.withValues(alpha: 0.10),
                    fill: scheme.primary,
                    tip: scheme.tertiary,
                  ),
                  // Sits on the dial's centre, which the painter places below
                  // the middle of the box to leave room for the open arc.
                  child: Align(
                    alignment: const Alignment(0, 0.28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                            height: 1,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'tokens / second',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _RunningPill(running: running),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.scaleMax,
    required this.track,
    required this.fill,
    required this.tip,
  });

  final double value;
  final double scaleMax;
  final Color track;
  final Color fill;
  final Color tip;

  // A 270 degree dial with the gap at the bottom.
  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    // The dial centre sits below the middle of the box because the arc opens
    // downwards: this keeps the top of the ring inside the box.
    final center = Offset(size.width / 2, size.height * 0.62);
    final radius = math.min(size.width / 2, size.height * 0.62) - 18;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final fraction = (value / scaleMax).clamp(0.0, 1.0);

    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, base);

    if (fraction > 0) {
      final progress = Paint()
        ..shader = SweepGradient(
          colors: [fill, tip],
          startAngle: _start,
          endAngle: _start + _sweep,
          transform: GradientRotation(_start),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, _start, _sweep * fraction, false, progress);
    }

    // Ticks every tenth of the scale, so the dial reads as a measurement
    // instead of a decoration.
    final tick = Paint()
      ..color = track
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i <= 10; i++) {
      final angle = _start + _sweep * (i / 10);
      final outer = radius - 16;
      final inner = outer - (i % 5 == 0 ? 9 : 5);
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        tick,
      );
    }

    // Marker on the arc rather than a needle from the centre: the centre is
    // where the number is, and a needle would run straight through it.
    final angle = _start + _sweep * fraction;
    final knob = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(knob, 11, Paint()..color = tip.withValues(alpha: 0.22));
    canvas.drawCircle(knob, 6, Paint()..color = tip);
    canvas.drawCircle(
      knob,
      2.5,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value ||
      old.scaleMax != scaleMax ||
      old.fill != fill ||
      old.tip != tip;
}

/// Breathing "measuring" indicator while a run is in flight.
class _RunningPill extends StatefulWidget {
  const _RunningPill({required this.running});

  final bool running;

  @override
  State<_RunningPill> createState() => _RunningPillState();
}

class _RunningPillState extends State<_RunningPill>
    with SingleTickerProviderStateMixin {
  // Built lazily: an idle repeating controller would drive frames forever for
  // an indicator nobody is looking at.
  AnimationController? _controller;

  AnimationController get _c => _controller ??= AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!widget.running) {
      return Text(
        'Idle',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.35 + 0.65 * _c.value),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'MEASURING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: scheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── live graph ────────────────────────────────────────────────────────────

/// Throughput over the run, drawn as a filled curve that animates in as
/// samples arrive.
class _ThroughputGraph extends StatelessWidget {
  const _ThroughputGraph({required this.samples, required this.running});

  final List<double> samples;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 116,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Throughput over the run',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (samples.isNotEmpty)
                Text(
                  'peak ${samples.reduce(math.max).toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: samples.length < 2
                ? Center(
                    child: Text(
                      running ? 'Warming up…' : 'Run a benchmark to plot it',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1),
                    duration: const Duration(milliseconds: 220),
                    builder: (context, t, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _GraphPainter(
                        samples: samples,
                        scale: t,
                        line: scheme.primary,
                        fill: scheme.primary.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.samples,
    required this.scale,
    required this.line,
    required this.fill,
  });

  final List<double> samples;
  final double scale;
  final Color line;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = samples.reduce(math.max);
    if (maxValue <= 0) return;
    final step = size.width / (samples.length - 1);

    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final x = step * i;
      final normalized = (samples[i] / maxValue) * scale;
      final y = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.samples.length != samples.length ||
      old.scale != scale ||
      old.line != line;
}

// ─── stats ─────────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final LlmStats stats;

  @override
  Widget build(BuildContext context) {
    final ttft = stats.timeToFirstToken;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.bolt_rounded,
            label: 'First token',
            value: ttft == null ? '-' : _fmtSeconds(ttft),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.numbers_rounded,
            label: 'Tokens',
            value: '${stats.tokens}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.timer_outlined,
            label: 'Total',
            value: stats.elapsed == Duration.zero
                ? '-'
                : _fmtSeconds(stats.elapsed),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── supporting cards ──────────────────────────────────────────────────────

class _ModelPicker extends StatelessWidget {
  const _ModelPicker({
    required this.models,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final List<LocalModel> models;
  final LocalModel selected;
  final bool enabled;
  final ValueChanged<LocalModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected.id,
          isExpanded: true,
          borderRadius: BorderRadius.circular(Radii.lg),
          icon: const Icon(Icons.expand_more_rounded),
          items: [
            for (final m in models)
              DropdownMenuItem(
                value: m.id,
                child: Row(
                  children: [
                    Icon(Icons.memory_rounded, size: 18, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: enabled
              ? (id) {
                  for (final m in models) {
                    if (m.id == id) {
                      onChanged(m);
                      return;
                    }
                  }
                }
              : null,
        ),
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sample output',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          MarkdownText(
            data: text,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: scheme.onSurface,
            ),
            codeBackground: scheme.surfaceContainerHighest,
            mutedColor: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.runs});

  final List<_Run> runs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final best = runs.map((r) => r.tokensPerSecond).reduce(math.max);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This session',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (final run in runs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          run.modelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${run.tokensPerSecond.toStringAsFixed(1)} tok/s',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Bars grow in on insert and are scaled against the fastest
                  // run, so a slower model is visibly slower.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: run.tokensPerSecond / best),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: t,
                        minHeight: 5,
                        backgroundColor: scheme.surfaceContainerHigh,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${run.tokens} tokens · first token '
                    '${_fmtSeconds(run.timeToFirstToken)} · total '
                    '${_fmtSeconds(run.total)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => InlineNotice(
    text: message,
    icon: Icons.error_outline_rounded,
    tone: TagTone.danger,
  );
}

class _EmptyBenchmark extends StatelessWidget {
  const _EmptyBenchmark();

  @override
  Widget build(BuildContext context) => const EmptyState(
    icon: Icons.speed_rounded,
    title: 'No models to measure',
    message: 'Download a model to measure its speed.',
  );
}

String _fmtSeconds(Duration d) {
  final seconds = d.inMilliseconds / 1000;
  if (seconds < 10) return '${seconds.toStringAsFixed(2)}s';
  if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
  final minutes = d.inMinutes;
  return '${minutes}m ${(seconds - minutes * 60).toStringAsFixed(0)}s';
}

/// What this phone's measured speed implies about which model to run.
///
/// The Benchmark page is where the hardware becomes a known quantity, so it is
/// the right place to say what that means: once one model has been measured,
/// the bandwidth it implies re-scales the estimate for the whole catalogue,
/// and the best model for a given job is a question that can finally be
/// answered with evidence rather than a rule of thumb.
class _HardwareAdvice extends StatelessWidget {
  const _HardwareAdvice({required this.speed, required this.installedIds});

  final SpeedKnowledge speed;

  /// Ids of models already on disk, so advice can say "you have this" instead
  /// of sending someone to the Models page for nothing.
  final Set<String> installedIds;

  /// The jobs worth answering here. Kept short: this is a footnote on a
  /// measurement page, not the Models page's full chooser.
  static const _jobs = [UseCase.fastChat, UseCase.reasoning];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final device = speed.device;

    final installedCatalogIds = <String>{
      for (final m in chatCatalog)
        if (installedIds.contains(m.servedId)) m.id,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Best for your hardware',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            speed.calibrated
                ? '${device.known ? '${device.summary} · ' : ''}'
                      'measured ${speed.bandwidthGBps.toStringAsFixed(1)} GB/s '
                      'effective'
                : device.known
                ? '${device.summary} · run a benchmark to replace the '
                      'estimates below with measurements'
                : 'Run a benchmark to calibrate these',
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
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
    final scheme = Theme.of(context).colorScheme;
    final pick = recommend(
      job,
      speed.device,
      installedIds: installedCatalogIds,
      speed: speed,
    ).best;
    if (pick == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(job.icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.label,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.3,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  pick.model.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pick.speedLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pick.speedIsMeasured
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ),
              Text(
                pick.installed ? 'installed' : pick.model.approxSize,
                style: TextStyle(
                  fontSize: 10.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
