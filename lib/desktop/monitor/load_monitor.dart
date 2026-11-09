/// Live machine load and what each model costs to run.
///
/// Samples once a second for the life of the app (a few cheap native calls
/// on Windows). While the engine is running a request, the extra CPU, memory
/// and energy are charged to that model, so the Lab can show which model
/// costs what on this PC.
///
/// Power: measured from the battery's discharge rate when the PC is running
/// on battery and reports it; otherwise estimated from CPU load between an
/// idle floor and a TDP guess. CO2 uses India's grid average
/// (0.716 kg CO2 per kWh, CEA). Both are labelled as estimates in the UI.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../llm/llm_engine.dart';
import 'platform_probe.dart';

/// Grams of CO2 per kWh on India's grid.
const kGridCo2PerKwh = 716.0;

class LoadSample {
  const LoadSample({
    required this.at,
    required this.cpu,
    required this.appCpu,
    required this.ramUsed,
    required this.ramTotal,
    required this.appRss,
    required this.watts,
    required this.wattsMeasured,
    required this.appWatts,
    this.batteryPercent,
    this.onBattery,
    this.model,
  });

  final DateTime at;

  /// Whole-machine CPU use, 0..1.
  final double cpu;

  /// Thinai's CPU use as a share of the whole machine, 0..1.
  final double appCpu;
  final int ramUsed;
  final int ramTotal;
  final int appRss;

  /// Whole-system power, measured or estimated.
  final double watts;
  final bool wattsMeasured;

  /// Power above idle attributed to Thinai.
  final double appWatts;
  final int? batteryPercent;
  final bool? onBattery;

  /// Model running a request during this sample, if any (file name).
  final String? model;
}

/// What one model has cost this session.
class ModelLoad {
  ModelLoad(this.model);

  final String model;
  Duration active = Duration.zero;
  int tokens = 0;
  double energyJ = 0;
  double _cpuSum = 0;
  int _samples = 0;
  int peakRss = 0;

  double get avgCpu => _samples == 0 ? 0 : _cpuSum / _samples;
  double get wh => energyJ / 3600;
  double get co2g => energyJ / 3.6e6 * kGridCo2PerKwh;
  double? get tokensPerSecond => active.inMilliseconds < 500
      ? null
      : tokens / (active.inMilliseconds / 1000);
}

class LoadState {
  const LoadState({
    this.history = const [],
    this.models = const {},
    this.sessionEnergyJ = 0,
    this.batteryAtStart,
    this.started,
  });

  /// Newest last; the last two minutes.
  final List<LoadSample> history;
  final Map<String, ModelLoad> models;

  /// Energy attributed to Thinai since the app opened.
  final double sessionEnergyJ;
  final int? batteryAtStart;
  final DateTime? started;

  LoadSample? get latest => history.isEmpty ? null : history.last;
  double get sessionCo2g => sessionEnergyJ / 3.6e6 * kGridCo2PerKwh;
}

class LoadMonitor extends StateNotifier<LoadState> {
  LoadMonitor() : super(LoadState(started: DateTime.now())) {
    _timer = Timer.periodic(
      Platform.isMacOS
          ? const Duration(seconds: 2)
          : const Duration(seconds: 1),
      (_) => _tick(),
    );
    unawaited(_tick());
  }

  Timer? _timer;
  ProbeReading? _prev;
  bool _busy = false;
  EngineActivity? _lastActivity;
  int _lastTokens = 0;
  final Map<String, ModelLoad> _models = {};
  double _energyJ = 0;
  int? _batteryAtStart;

  // Rough laptop envelope when no battery reading exists.
  static final double _idleW = 6;
  static final double _maxW = Platform.numberOfProcessors >= 12
      ? 45
      : Platform.numberOfProcessors >= 8
      ? 35
      : 18;

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      final now = await PlatformProbe.read();
      final prev = _prev;
      _prev = now;
      if (!mounted) return;

      double cpu, appCpu;
      if (now.systemCpuNow != null) {
        cpu = now.systemCpuNow!;
        appCpu = now.appCpuNow ?? 0;
      } else if (prev != null &&
          now.systemTotal != null &&
          prev.systemTotal != null) {
        final total = (now.systemTotal! - prev.systemTotal!).toDouble();
        final busy = (now.systemBusy! - prev.systemBusy!).toDouble();
        final app = ((now.appCpu ?? 0) - (prev.appCpu ?? 0)).toDouble();
        cpu = total <= 0 ? 0 : (busy / total).clamp(0.0, 1.0);
        appCpu = total <= 0 ? 0 : (app / total).clamp(0.0, 1.0);
      } else {
        return; // First Windows reading only sets the baseline.
      }

      final dt = prev == null
          ? 1.0
          : math.max(0.2, now.at.difference(prev.at).inMilliseconds / 1000);
      final measured = now.batteryWatts != null && (now.onBattery ?? false);
      final watts = measured
          ? now.batteryWatts!
          : _idleW + (_maxW - _idleW) * cpu;
      final share = cpu <= 0.02 ? 0.0 : (appCpu / cpu).clamp(0.0, 1.0);
      final appWatts = math.max(0.0, (watts - _idleW) * share);
      _energyJ += appWatts * dt;
      _batteryAtStart ??= now.batteryPercent;

      final activity = LlmEngine.activity.value;
      String? model;
      if (activity != null) {
        model = activity.modelPath.split(RegExp(r'[\\/]')).last;
        final ledger = _models.putIfAbsent(model, () => ModelLoad(model!));
        if (!identical(activity, _lastActivity)) _lastTokens = 0;
        ledger
          ..active += Duration(milliseconds: (dt * 1000).round())
          ..tokens += math.max(0, activity.tokens - _lastTokens)
          ..energyJ += appWatts * dt
          ..peakRss = math.max(ledger.peakRss, now.appRss);
        ledger._cpuSum += appCpu;
        ledger._samples++;
        _lastTokens = activity.tokens;
      }
      _lastActivity = activity;

      final total = now.ramTotal ?? 0;
      final sample = LoadSample(
        at: now.at,
        cpu: cpu,
        appCpu: appCpu,
        ramUsed: total - (now.ramAvailable ?? total),
        ramTotal: total,
        appRss: now.appRss,
        watts: watts,
        wattsMeasured: measured,
        appWatts: appWatts,
        batteryPercent: now.batteryPercent,
        onBattery: now.onBattery,
        model: model,
      );
      final history = [...state.history, sample];
      final keep = Platform.isMacOS ? 60 : 120;
      state = LoadState(
        history: history.length > keep
            ? history.sublist(history.length - keep)
            : history,
        models: Map.unmodifiable(_models),
        sessionEnergyJ: _energyJ,
        batteryAtStart: _batteryAtStart,
        started: state.started,
      );
    } on Object {
      // A failed reading skips a beat; the next one tries again.
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final loadMonitorProvider = StateNotifierProvider<LoadMonitor, LoadState>(
  (ref) => LoadMonitor(),
);
