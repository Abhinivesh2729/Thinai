import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../llm/generation_settings.dart';
import '../../llm/gpu_support.dart';
import '../../llm/llm_engine.dart';
import '../../models_repo/model_store.dart';
import '../../state/providers.dart';

/// GPU acceleration: off, or one of the backends this phone actually has, with
/// a speed test that runs the active model both ways.
///
/// The phone is not asked what GPUs it has until someone opens this card's
/// check, because asking loads the vendor's GPU driver, and a user who never
/// wanted the GPU should never run that code. The test exists because on many
/// phones — Mali especially — the GPU is slower than the CPU for the small
/// models this app runs, and the only honest way to know is to measure.
class GpuSettingsCard extends ConsumerStatefulWidget {
  final bool embedded;
  const GpuSettingsCard({super.key, this.embedded = false});

  @override
  ConsumerState<GpuSettingsCard> createState() => _GpuSettingsCardState();
}

class _Speed {
  final double? promptPerSecond;
  final double? generatePerSecond;
  const _Speed(this.promptPerSecond, this.generatePerSecond);
}

const _kTestPrompt =
    'Explain in a few sentences why the sky looks blue during the day and red '
    'at sunset.';
const _kTestTokens = 48;

class _GpuSettingsCardState extends ConsumerState<GpuSettingsCard> {
  final _store = GenerationSettingsStore.instance;
  StreamSubscription<GenerationSettings>? _sub;

  List<GpuDevice>? _devices;
  bool _probing = false;
  bool _testing = false;
  String? _testError;
  _Speed? _cpu;
  _Speed? _gpu;
  GpuBackend? _testedBackend;

  @override
  void initState() {
    super.initState();
    unawaited(_store.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    }));
    _sub = _store.changes.listen((_) {
      if (mounted) setState(() {});
    });
    // Someone who already turned GPU on has already accepted the driver, so
    // there is no reason to make them press "check" again.
    if (_store.settings.gpu != GpuBackend.none) unawaited(_probe());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _probe() async {
    if (_probing) return;
    setState(() => _probing = true);
    final devices = await probeGpuDevices();
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _probing = false;
    });
  }

  Future<LocalModel?> _activeModel() async {
    final id = ref.read(activeModelIdProvider);
    if (id == null) return null;
    return ref.read(modelStoreProvider).findById(id);
  }

  /// One backend's speed, from the second of two runs: the first pays for
  /// loading the model onto that backend, which is not what anyone asks when
  /// they ask which is faster.
  Future<_Speed> _measure(LocalModel model, GpuBackend backend) async {
    LlmStats last = const LlmStats();
    for (var run = 0; run < 2; run++) {
      final options = await _store.optionsFor(
        model,
        requestedTemperature: 0.2,
        maxTokens: _kTestTokens,
        gpu: backend,
      );
      await for (final token in ref
          .read(llmEngineProvider)
          .generate(_kTestPrompt, modelPath: model.path, options: options)) {
        if (token.isError) throw StateError(token.full);
        last = token.stats;
        if (token.done) break;
      }
    }
    final ttft = last.timeToFirstToken;
    final prompt = ttft == null || ttft == Duration.zero || last.promptTokens == 0
        ? null
        : last.promptTokens / (ttft.inMicroseconds / 1e6);
    return _Speed(prompt, last.tokensPerSecond);
  }

  Future<void> _speedTest() async {
    final model = await _activeModel();
    final devices = _devices ?? const [];
    if (model == null) {
      setState(() => _testError = 'Load a model first, then run the test.');
      return;
    }
    final saved = _store.settings.gpu;
    final backend =
        saved == GpuBackend.none ? recommendedBackend(devices) : saved;
    if (backend == GpuBackend.none) return;

    setState(() {
      _testing = true;
      _testError = null;
      _cpu = null;
      _gpu = null;
      _testedBackend = backend;
    });
    try {
      final cpu = await _measure(model, GpuBackend.none);
      if (mounted) setState(() => _cpu = cpu);
      final gpu = await _measure(model, backend);
      if (mounted) setState(() => _gpu = gpu);
    } catch (e) {
      if (mounted) setState(() => _testError = 'The test failed: $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final crashed = ref.watch(gpuCrashNoticeProvider);
    final devices = _devices;
    final current = _store.settings.gpu;

    final hasVulkan =
        devices?.any((d) => d.backend == GpuBackend.vulkan) ?? false;
    final hasOpenCl =
        devices?.any((d) => d.backend == GpuBackend.opencl) ?? false;

    final choices = <GpuBackend>[
      GpuBackend.none,
      if (hasVulkan || hasOpenCl) GpuBackend.auto,
      if (hasVulkan) GpuBackend.vulkan,
      if (hasOpenCl) GpuBackend.opencl,
      // A saved choice stays visible even if the probe no longer finds it.
      if (current != GpuBackend.none &&
          !(hasVulkan || hasOpenCl) &&
          devices != null)
        current,
    ];

    final content = Padding(
      padding: EdgeInsets.fromLTRB(16, widget.embedded ? 14 : 12, 16, widget.embedded ? 14 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory_rounded, size: 20, color: scheme.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GPU acceleration',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Offloads computation to hardware accelerator',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: current == GpuBackend.none
                      ? scheme.surfaceContainerHigh
                      : const Color(0xFF2CA048).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _label(current),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: current == GpuBackend.none
                        ? scheme.onSurfaceVariant
                        : const Color(0xFF2CA048),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Runs the model on the GPU instead of the CPU. Run the speed '
            'test to check if it helps on this phone.',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          if (crashed != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_label(crashed)} crashed the app last time, so GPU '
              'acceleration was turned off.',
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          if (devices == null)
            OutlinedButton.icon(
              onPressed: _probing ? null : _probe,
              icon: _probing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded, size: 18),
              label: const Text('Check this phone\'s GPU', style: TextStyle(fontSize: 13)),
            )
          else if (devices.isEmpty)
            Text(
              'No usable GPU found. Thinai will keep using the CPU.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
            )
          else ...[
            Text(
              'Found: ${devices.map((d) => '${d.name} (${_label(d.backend)})').join(', ')}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final choice in choices)
                  ChoiceChip(
                    label: Text(
                      choice == GpuBackend.auto
                          ? 'Auto (${_label(recommendedBackend(devices))})'
                          : _label(choice),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    selected: current == choice,
                    onSelected: _testing
                        ? null
                        : (_) => unawaited(_store.setGpu(choice)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _testing ? null : _speedTest,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.speed_rounded, size: 18),
                  label: Text(_testing ? 'Testing…' : 'Speed test', style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            if (_cpu != null || _testError != null) ...[
              const SizedBox(height: 8),
              if (_testError != null)
                Text(_testError!, style: TextStyle(color: scheme.error, fontSize: 12))
              else
                _results(theme),
            ],
          ],
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: content,
    );
  }

  Widget _results(ThemeData theme) {
    final scheme = theme.colorScheme;
    String rate(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)} tok/s';
    final cpu = _cpu;
    final gpu = _gpu;

    String verdict() {
      final c = cpu?.generatePerSecond;
      final g = gpu?.generatePerSecond;
      if (c == null || g == null) return '';
      if (g > c * 1.1) return 'The GPU is faster on this phone.';
      if (g < c * 0.9) {
        return 'The CPU is faster here. Leave GPU acceleration off.';
      }
      return 'About the same either way.';
    }

    TableRow row(String label, _Speed? s) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(label),
            ),
            Text(s == null ? '…' : rate(s.promptPerSecond)),
            Text(s == null ? '…' : rate(s.generatePerSecond)),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(1.2)},
          children: [
            TableRow(
              children: [
                const SizedBox.shrink(),
                Text('Reading prompt',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                Text('Writing reply',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            row('CPU', cpu),
            row(_label(_testedBackend ?? GpuBackend.auto), gpu),
          ],
        ),
        if (verdict().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(verdict(), style: TextStyle(color: scheme.onSurface)),
        ],
      ],
    );
  }

  static String _label(GpuBackend backend) => switch (backend) {
        GpuBackend.none => 'Off',
        GpuBackend.auto => 'Auto',
        GpuBackend.vulkan => 'Vulkan',
        GpuBackend.opencl => 'OpenCL',
      };
}
