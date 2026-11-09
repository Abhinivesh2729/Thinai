/// GPU tab: find the graphics card, choose CPU or Vulkan, and measure which
/// is faster on this PC.
///
/// Rebuilt from the phone's GpuSettingsCard rather than embedded, because
/// that card's copy and choices are phone-shaped (OpenCL is an Adreno path
/// and means nothing on a PC). The logic is the same: the driver is never
/// loaded until asked, the choice is the global GenerationSettingsStore
/// setting, and the test runs the same prompt twice per backend and keeps the
/// second run.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../llm/generation_settings.dart';
import '../../../llm/gpu_support.dart';
import '../../../llm/llm_engine.dart';
import '../../../models_repo/model_store.dart';
import '../../../state/providers.dart';
import '../../l10n/lab_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import '../../widgets/toast.dart';
import 'lab_common.dart';

const _kTestPrompt =
    'Explain in a few sentences why the sky looks blue during the day and red '
    'at sunset.';
const _kTestTokens = 48;

class _Speed {
  const _Speed(this.promptPerSecond, this.generatePerSecond);
  final double? promptPerSecond;
  final double? generatePerSecond;
}

class LabGpuTab extends ConsumerStatefulWidget {
  const LabGpuTab({super.key, this.probe = probeGpuDevices});

  /// Lists GPUs. Replaceable so tests can skip the native probe.
  final Future<List<GpuDevice>> Function() probe;

  @override
  ConsumerState<LabGpuTab> createState() => _LabGpuTabState();
}

class _LabGpuTabState extends ConsumerState<LabGpuTab> {
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
    unawaited(
      _store.ensureLoaded().then((_) {
        if (!mounted) return;
        setState(() {});
        // Someone who already turned the GPU on has already accepted the
        // driver, so there is no reason to make them press Find again.
        if (_store.settings.gpu != GpuBackend.none) unawaited(_probe());
      }),
    );
    _sub = _store.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Vulkan devices only: OpenCL is registered solely for Adreno phones, so
  /// on a PC it would be a choice that does nothing useful.
  List<GpuDevice>? get _vulkan => _devices
      ?.where((d) => d.backend == GpuBackend.vulkan)
      .toList(growable: false);

  Future<void> _probe() async {
    if (_probing) return;
    setState(() => _probing = true);
    final devices = await widget.probe();
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _probing = false;
    });
  }

  Future<void> _setBackend(GpuBackend backend) async {
    await _store.setGpu(backend);
    if (!mounted) return;
    showDeskToast(
      LabStrings.of(context).gpuSet(_label(context.l10n, backend)),
      tone: DeskTone.success,
    );
  }

  /// One backend's speed from the second of two runs: the first pays for
  /// loading the model onto that backend, which is not what anyone means by
  /// "which is faster".
  Future<_Speed> _measure(LocalModel model, GpuBackend backend) async {
    LlmStats last = const LlmStats();
    for (var run = 0; run < 2; run++) {
      final options = await _store.optionsFor(
        model,
        requestedTemperature: 0.2,
        maxTokens: _kTestTokens,
        gpu: backend,
      );
      await for (final token
          in ref
              .read(llmEngineProvider)
              .generate(
                _kTestPrompt,
                modelPath: model.path,
                options: options,
              )) {
        if (token.isError) throw StateError(token.full);
        last = token.stats;
        if (token.done) break;
      }
    }
    final ttft = last.timeToFirstToken;
    final prompt =
        ttft == null || ttft == Duration.zero || last.promptTokens == 0
        ? null
        : last.promptTokens / (ttft.inMicroseconds / 1e6);
    return _Speed(prompt, last.tokensPerSecond);
  }

  Future<void> _speedTest(LocalModel model) async {
    if (_testing || ref.read(labBusyProvider) != null) return;
    final l10n = context.l10n;
    final saved = _store.settings.gpu;
    final backend = saved == GpuBackend.none
        ? recommendedBackend(_vulkan ?? const [])
        : saved;
    if (backend == GpuBackend.none) return;

    ref.read(labBusyProvider.notifier).state = LabJob.gpu;
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
      if (mounted) {
        setState(() => _testError = l10n.gpuTestFailed('$e'));
        showDeskToast(l10n.gpuTestFailed('$e'), tone: DeskTone.error);
      }
    } finally {
      if (mounted) {
        ref.read(labBusyProvider.notifier).state = null;
        setState(() => _testing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final installed = ref.watch(modelListProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final models = chatModelsOf(installed.valueOrNull ?? const []);
        final model = resolveLabModel(
          models,
          ref.watch(labModelIdProvider),
          ref.watch(activeModelIdProvider),
        );
        final devicesCard = _devicesCard(context);
        final testCard = _testCard(context, models, model);
        const gap = SizedBox(width: 16, height: 16);
        return ListView(
          padding: const EdgeInsets.fromLTRB(32, 4, 32, 32),
          children: [
            if (wide)
              EnterAnimation(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: devicesCard),
                    gap,
                    Expanded(
                      flex: 6,
                      child: EnterAnimation(
                        delay: const Duration(milliseconds: 60),
                        child: testCard,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              EnterAnimation(child: devicesCard),
              gap,
              EnterAnimation(
                delay: const Duration(milliseconds: 60),
                child: testCard,
              ),
            ],
          ],
        );
      },
    );
  }

  // ─── devices and choice ─────────────────────────────────────────────────

  Widget _devicesCard(BuildContext context) {
    final strings = LabStrings.of(context);
    final l10n = context.l10n;
    final palette = DeskPalette.of(context);
    final crashed = ref.watch(gpuCrashNoticeProvider);
    final current = _store.settings.gpu;
    final vulkan = _vulkan;
    final hasVulkan = vulkan?.isNotEmpty ?? false;
    final mac = defaultTargetPlatform == TargetPlatform.macOS;

    final choices = <GpuBackend>[
      GpuBackend.none,
      if (hasVulkan) GpuBackend.auto,
      if (hasVulkan) GpuBackend.vulkan,
      // A saved choice stays visible even if the probe no longer finds it, so
      // it can still be switched off.
      if (current != GpuBackend.none &&
          current != GpuBackend.auto &&
          current != GpuBackend.vulkan)
        current,
      if (!hasVulkan && current == GpuBackend.auto) GpuBackend.auto,
    ];

    return LabCard(
      title: strings.gpuDevicesTitle,
      icon: Icons.developer_board_rounded,
      trailing: LabTag(
        label: _label(l10n, current),
        color: current == GpuBackend.none ? palette.textMuted : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.gpuIntro,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: palette.textMuted,
            ),
          ),
          if (mac) ...[
            const SizedBox(height: 10),
            LabNotice(message: strings.gpuMacNote),
          ],
          if (crashed != null) ...[
            const SizedBox(height: 10),
            LabNotice(
              message: l10n.gpuCrashedNotice(_label(l10n, crashed)),
              icon: Icons.warning_amber_rounded,
              color: DeskColors.danger,
            ),
          ],
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: DeskMotion.medium,
            switchInCurve: DeskMotion.ease,
            child: vulkan == null
                ? Column(
                    key: const ValueKey('probe'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabRunButton(
                        label: l10n.gpuCheckPhone,
                        icon: Icons.search_rounded,
                        onPressed: _probing ? null : _probe,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.gpuProbeHint,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.textFaint,
                        ),
                      ),
                    ],
                  )
                : vulkan.isEmpty
                ? LabNotice(
                    key: const ValueKey('none'),
                    message: strings.gpuNoneFound,
                    icon: Icons.memory_rounded,
                  )
                : Column(
                    key: const ValueKey('list'),
                    children: [for (final d in vulkan) _DeviceRow(device: d)],
                  ),
          ),
          if (vulkan != null) ...[
            const SizedBox(height: 18),
            Text(
              strings.runModelsOn,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: context.tracking(0.4),
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            _BackendSelector(
              choices: choices,
              current: current,
              labelFor: (b) => b == GpuBackend.auto && hasVulkan
                  ? l10n.gpuAutoWith(_label(l10n, recommendedBackend(vulkan)))
                  : _label(l10n, b),
              onSelect: _testing ? null : (b) => unawaited(_setBackend(b)),
            ),
          ],
        ],
      ),
    );
  }

  // ─── speed test ─────────────────────────────────────────────────────────

  Widget _testCard(
    BuildContext context,
    List<LocalModel> models,
    LocalModel? model,
  ) {
    final strings = LabStrings.of(context);
    final l10n = context.l10n;
    final palette = DeskPalette.of(context);
    final busy = ref.watch(labBusyProvider);
    final busyElsewhere = busy != null && busy != LabJob.gpu;
    final hasVulkan = _vulkan?.isNotEmpty ?? false;
    final canTest =
        model != null &&
        !_testing &&
        !busyElsewhere &&
        (hasVulkan || _store.settings.gpu != GpuBackend.none);

    return LabCard(
      title: strings.speedTestTitle,
      icon: Icons.compare_arrows_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (model == null)
            LabNotice(message: l10n.benchmarkEmptyBody)
          else ...[
            Row(
              children: [
                Expanded(
                  child: LabModelPicker(
                    models: models,
                    selected: model,
                    enabled: !_testing,
                    onChanged: (m) =>
                        ref.read(labModelIdProvider.notifier).state = m.id,
                  ),
                ),
                const SizedBox(width: 12),
                LabRunButton(
                  label: _testing ? l10n.gpuTesting : l10n.gpuSpeedTest,
                  icon: _testing
                      ? Icons.hourglass_top_rounded
                      : Icons.speed_rounded,
                  onPressed: canTest ? () => _speedTest(model) : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _devices == null
                  ? strings.findGpuFirst
                  : strings.speedTestHint(model.displayName),
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: palette.textMuted,
              ),
            ),
          ],
          if (busyElsewhere) ...[
            const SizedBox(height: 12),
            LabNotice(
              message: strings.busy,
              icon: Icons.hourglass_top_rounded,
              color: DeskColors.amber,
            ),
          ],
          AnimatedSize(
            duration: DeskMotion.medium,
            curve: DeskMotion.ease,
            alignment: Alignment.topCenter,
            child: _testError != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: LabNotice(
                      message: _testError!,
                      icon: Icons.error_outline_rounded,
                      color: DeskColors.danger,
                    ),
                  )
                : (_cpu != null || _testing)
                ? Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: _results(context),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _results(BuildContext context) {
    final l10n = context.l10n;
    final strings = LabStrings.of(context);
    final gpuName = _label(l10n, _testedBackend ?? GpuBackend.auto);
    final cpu = _cpu;
    final gpu = _gpu;

    final c = cpu?.generatePerSecond;
    final g = gpu?.generatePerSecond;
    Widget? verdict;
    if (c != null && g != null && !_testing) {
      final current = _store.settings.gpu;
      final tested = _testedBackend ?? GpuBackend.vulkan;
      final (text, color, action) = g > c * 1.1
          ? (
              '${l10n.gpuVerdictGpuFaster} '
                  '${strings.timesFaster((g / c).toStringAsFixed(1))}',
              DeskColors.green,
              current == GpuBackend.none
                  ? (strings.useBackend(_label(l10n, tested)), tested)
                  : null,
            )
          : g < c * 0.9
          ? (
              l10n.gpuVerdictCpuFaster,
              DeskColors.amber,
              current != GpuBackend.none
                  ? (strings.switchToCpu, GpuBackend.none)
                  : null,
            )
          : (l10n.gpuVerdictSame, DeskPalette.of(context).textMuted, null);
      verdict = Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(DeskSize.radiusM),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 17, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (action != null)
              TextButton(
                onPressed: () => unawaited(_setBackend(action.$2)),
                child: Text(action.$1),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompareBars(
          label: l10n.gpuWritingReply,
          cpu: cpu?.generatePerSecond,
          gpu: gpu?.generatePerSecond,
          cpuPending: cpu == null,
          gpuPending: gpu == null,
          gpuName: gpuName,
        ),
        const SizedBox(height: 14),
        _CompareBars(
          label: l10n.gpuReadingPrompt,
          cpu: cpu?.promptPerSecond,
          gpu: gpu?.promptPerSecond,
          cpuPending: cpu == null,
          gpuPending: gpu == null,
          gpuName: gpuName,
        ),
        ?verdict,
      ],
    );
  }

  static String _label(AppLocalizations l10n, GpuBackend backend) =>
      switch (backend) {
        GpuBackend.none => 'CPU',
        GpuBackend.auto => l10n.gpuAuto,
        GpuBackend.vulkan => 'Vulkan',
        GpuBackend.opencl => 'OpenCL',
      };
}

// ─── pieces ────────────────────────────────────────────────────────────────

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device});

  final GpuDevice device;

  @override
  Widget build(BuildContext context) {
    final strings = LabStrings.of(context);
    final palette = DeskPalette.of(context);
    final gb = device.totalBytes / (1024 * 1024 * 1024);
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DeskColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DeskSize.radiusS),
            ),
            child: const Icon(
              Icons.memory_rounded,
              size: 18,
              color: DeskColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Zero means the driver did not say; integrated GPUs share
                  // system RAM, so "unknown" there reads as shared memory.
                  device.totalBytes > 0
                      ? strings.vram(gb.toStringAsFixed(gb >= 10 ? 0 : 1))
                      : strings.sharedMemory,
                  style: TextStyle(fontSize: 11.5, color: palette.textMuted),
                ),
              ],
            ),
          ),
          const LabTag(label: 'Vulkan'),
        ],
      ),
    );
  }
}

/// Segmented choice with a sliding highlight.
class _BackendSelector extends StatelessWidget {
  const _BackendSelector({
    required this.choices,
    required this.current,
    required this.labelFor,
    required this.onSelect,
  });

  final List<GpuBackend> choices;
  final GpuBackend current;
  final String Function(GpuBackend) labelFor;
  final ValueChanged<GpuBackend>? onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final b in choices)
          Hoverable(
            cursor: onSelect == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            builder: (context, hovered) {
              final selected = b == current;
              return GestureDetector(
                onTap: onSelect == null || selected ? null : () => onSelect!(b),
                child: AnimatedContainer(
                  duration: DeskMotion.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? DeskColors.green.withValues(alpha: 0.14)
                        : hovered
                        ? scheme.onSurface.withValues(alpha: 0.05)
                        : palette.canvas,
                    borderRadius: BorderRadius.circular(DeskSize.radiusM),
                    border: Border.all(
                      color: selected
                          ? DeskColors.green.withValues(alpha: 0.6)
                          : palette.hairline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: DeskMotion.fast,
                        child: Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          key: ValueKey(selected),
                          size: 15,
                          color: selected
                              ? DeskColors.green
                              : palette.textFaint,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        labelFor(b),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? DeskColors.green : scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// CPU and GPU rates for one phase of generation as two bars on one scale.
class _CompareBars extends StatelessWidget {
  const _CompareBars({
    required this.label,
    required this.cpu,
    required this.gpu,
    required this.cpuPending,
    required this.gpuPending,
    required this.gpuName,
  });

  final String label;
  final double? cpu;
  final double? gpu;
  final bool cpuPending;
  final bool gpuPending;
  final String gpuName;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final top = math.max(cpu ?? 0, gpu ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: context.tracking(0.4),
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        _bar(context, 'CPU', cpu, cpuPending, top, palette.textMuted),
        const SizedBox(height: 6),
        _bar(context, gpuName, gpu, gpuPending, top, DeskColors.green),
      ],
    );
  }

  Widget _bar(
    BuildContext context,
    String name,
    double? value,
    bool pending,
    double top,
    Color color,
  ) {
    final palette = DeskPalette.of(context);
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: pending
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    color: color.withValues(alpha: 0.5),
                    backgroundColor: palette.hairline,
                  ),
                )
              : TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: value == null || top <= 0 ? 0 : value / top,
                  ),
                  duration: const Duration(milliseconds: 600),
                  curve: DeskMotion.ease,
                  builder: (context, t, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: t,
                      minHeight: 10,
                      color: color,
                      backgroundColor: palette.hairline,
                    ),
                  ),
                ),
        ),
        SizedBox(
          width: 92,
          child: Text(
            pending
                ? '…'
                : value == null
                ? '-'
                : '${value.toStringAsFixed(1)} tok/s',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: pending ? palette.textFaint : color,
              fontFeatures: tabularFigures,
            ),
          ),
        ),
      ],
    );
  }
}
