/// GPU backend choice with a CPU-vs-GPU speed test, the device summary, and a
/// way into the Lab for full benchmarks.
///
/// Built here rather than reusing the phone's GpuSettingsCard: that card
/// offers OpenCL (Adreno-only, absent on a PC) and says "phone". The logic is
/// the same: no GPU driver is touched until the user asks to look for one,
/// because a broken driver can take the process down during enumeration.
library;

import 'dart:async';
import 'dart:ffi' show Abi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../llm/generation_settings.dart';
import '../../../llm/gpu_support.dart';
import '../../../llm/llm_engine.dart';
import '../../../models_repo/model_store.dart';
import '../../../state/providers.dart';
import '../../l10n/settings_strings.dart';
import '../../shell/desk_nav.dart';
import '../../theme/desk_theme.dart';
import 'settings_widgets.dart';

class HardwareSection extends ConsumerWidget {
  const HardwareSection({super.key});

  static String _arch() {
    final abi = Abi.current().toString();
    if (abi.contains('arm64')) return 'ARM64';
    if (abi.contains('x64')) return 'x64';
    if (abi.contains('ia32')) return 'x86';
    return 'CPU';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SettingsStrings.of(context);
    final profile = ref.watch(deviceProfileProvider).valueOrNull;
    final ram = profile?.totalRamBytes;

    return SettingsCard(
      children: [
        const _GpuRow(),
        SettingsRow(
          icon: Icons.developer_board_rounded,
          title: context.l10n.settingsDeviceSpecs,
          subtitle: s.thisComputer,
          trailing: profile == null
              ? null
              : Pill(
                  label: s.deviceLine(
                    ramGb: ram == null ? null : ram / (1024 * 1024 * 1024),
                    cores: profile.cores,
                    arch: _arch(),
                  ),
                ),
        ),
        SettingsRow(
          icon: Icons.speed_rounded,
          title: s.benchmarks,
          subtitle: s.benchmarksHint,
          onTap: () => ref.read(deskPageProvider.notifier).state = DeskPage.lab,
          trailing: DeskButton(
            label: s.openLab,
            icon: Icons.arrow_forward_rounded,
            onPressed: () =>
                ref.read(deskPageProvider.notifier).state = DeskPage.lab,
          ),
        ),
      ],
    );
  }
}

class _Speed {
  const _Speed(this.promptPerSecond, this.generatePerSecond);
  final double? promptPerSecond;
  final double? generatePerSecond;
}

// Same prompt and length as the phone's test, so numbers compare across both.
const _kTestPrompt =
    'Explain in a few sentences why the sky looks blue during the day and red '
    'at sunset.';
const _kTestTokens = 48;

class _GpuRow extends ConsumerStatefulWidget {
  const _GpuRow();

  @override
  ConsumerState<_GpuRow> createState() => _GpuRowState();
}

class _GpuRowState extends ConsumerState<_GpuRow> {
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
        if (mounted) setState(() {});
      }),
    );
    _sub = _store.changes.listen((_) {
      if (mounted) setState(() {});
    });
    // Someone who already turned the GPU on has accepted the driver.
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
    final all = await probeGpuDevices();
    if (!mounted) return;
    setState(() {
      // OpenCL only registers Adreno GPUs, which a PC does not have; hide it
      // so the choice is CPU, Auto or Vulkan.
      _devices = [
        for (final d in all)
          if (d.backend != GpuBackend.opencl) d,
      ];
      _probing = false;
    });
  }

  Future<_Speed> _measure(LocalModel model, GpuBackend backend) async {
    // Second of two runs: the first pays for loading onto the backend.
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

  Future<void> _speedTest() async {
    final id = ref.read(activeModelIdProvider);
    final model = id == null
        ? null
        : await ref.read(modelStoreProvider).findById(id);
    if (!mounted) return;
    if (model == null) {
      setState(() => _testError = context.l10n.gpuLoadModelFirst);
      return;
    }
    final saved = _store.settings.gpu;
    final backend = saved == GpuBackend.none
        ? recommendedBackend(_devices ?? const [])
        : saved;
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
      if (mounted) {
        setState(() => _testError = context.l10n.gpuTestFailed('$e'));
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  String _label(AppLocalizations l10n, GpuBackend b) => switch (b) {
    GpuBackend.none => 'CPU',
    GpuBackend.auto => l10n.gpuAuto,
    GpuBackend.vulkan => 'Vulkan',
    GpuBackend.opencl => 'OpenCL',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = SettingsStrings.of(context);
    final palette = DeskPalette.of(context);
    final crashed = ref.watch(gpuCrashNoticeProvider);
    final devices = _devices;
    final current = _store.settings.gpu;
    final hasVulkan =
        devices?.any((d) => d.backend == GpuBackend.vulkan) ?? false;

    final Widget control;
    if (devices == null) {
      control = DeskButton(
        label: l10n.gpuCheckPhone,
        icon: Icons.search_rounded,
        busy: _probing,
        onPressed: _probe,
      );
    } else if (!hasVulkan) {
      control = Text(
        l10n.gpuNoneFound,
        style: TextStyle(fontSize: 12.5, color: palette.textMuted),
      );
    } else {
      control = DeskSegmented<GpuBackend>(
        value: current == GpuBackend.opencl ? GpuBackend.auto : current,
        onChanged: _testing ? null : (b) => unawaited(_store.setGpu(b)),
        segments: [
          const Segment(GpuBackend.none, 'CPU', icon: Icons.memory_rounded),
          Segment(
            GpuBackend.auto,
            l10n.gpuAuto,
            icon: Icons.auto_awesome_outlined,
          ),
          const Segment(GpuBackend.vulkan, 'Vulkan', icon: Icons.bolt_rounded),
        ],
      );
    }

    return SettingsRow(
      icon: Icons.memory_rounded,
      title: l10n.gpuAcceleration,
      subtitle: s.gpuHint,
      trailing: AnimatedSwitcher(
        duration: DeskMotion.medium,
        child: KeyedSubtree(
          key: ValueKey(devices == null ? 'probe' : 'chosen'),
          child: control,
        ),
      ),
      below: AnimatedSize(
        duration: DeskMotion.medium,
        curve: DeskMotion.ease,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (crashed != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: DeskColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.gpuCrashedNotice(_label(l10n, crashed)),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: DeskColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (devices != null && devices.isNotEmpty) ...[
              Text(
                l10n.gpuFound(devices.map((d) => d.name).toSet().join(', ')),
                style: TextStyle(fontSize: 12.5, color: palette.textMuted),
              ),
              const SizedBox(height: 10),
            ],
            if (hasVulkan)
              Row(
                children: [
                  DeskButton(
                    label: _testing ? l10n.gpuTesting : l10n.gpuSpeedTest,
                    icon: Icons.speed_rounded,
                    busy: _testing,
                    onPressed: _speedTest,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.gpuDescription,
                      style: TextStyle(fontSize: 12, color: palette.textFaint),
                    ),
                  ),
                ],
              ),
            if (_testError != null) ...[
              const SizedBox(height: 10),
              Text(
                _testError!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: DeskColors.danger,
                ),
              ),
            ] else if (_cpu != null || _testing) ...[
              const SizedBox(height: 12),
              _Results(
                cpu: _cpu,
                gpu: _gpu,
                gpuLabel: _label(l10n, _testedBackend ?? GpuBackend.auto),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// CPU vs GPU, reading the prompt and writing the reply, with a verdict.
class _Results extends StatelessWidget {
  const _Results({
    required this.cpu,
    required this.gpu,
    required this.gpuLabel,
  });

  final _Speed? cpu;
  final _Speed? gpu;
  final String gpuLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    String rate(double? v) => v == null ? '-' : '${v.toStringAsFixed(1)} tok/s';

    String? verdict() {
      final c = cpu?.generatePerSecond;
      final g = gpu?.generatePerSecond;
      if (c == null || g == null) return null;
      if (g > c * 1.1) return l10n.gpuVerdictGpuFaster;
      if (g < c * 0.9) return l10n.gpuVerdictCpuFaster;
      return l10n.gpuVerdictSame;
    }

    final head = TextStyle(fontSize: 11.5, color: palette.textFaint);
    final cell = TextStyle(
      fontSize: 12.5,
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    TableRow row(String label, _Speed? sp) => TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(label, style: cell.copyWith(fontWeight: FontWeight.w600)),
        ),
        Text(sp == null ? '…' : rate(sp.promptPerSecond), style: cell),
        Text(sp == null ? '…' : rate(sp.generatePerSecond), style: cell),
      ],
    );

    final v = verdict();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: palette.canvas,
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Table(
              columnWidths: const {0: FlexColumnWidth(0.8)},
              children: [
                TableRow(
                  children: [
                    const SizedBox.shrink(),
                    Text(l10n.gpuReadingPrompt, style: head),
                    Text(l10n.gpuWritingReply, style: head),
                  ],
                ),
                row('CPU', cpu),
                row(gpuLabel, gpu),
              ],
            ),
          ),
          if (v != null) ...[
            const SizedBox(height: 6),
            Text(
              v,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: DeskColors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
