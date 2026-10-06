/// Remembers what the Benchmark page measured, so the Models page can stop
/// guessing.
///
/// The point is not only to show a real number for a model that was
/// benchmarked. One measurement pins down how fast *this* phone actually
/// decodes, which makes the estimate for every other model in the catalogue
/// better — see [measuredBandwidthGBps].
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kBenchmarkResultsKey = 'benchmark_results_v1';

/// One measured run, kept per model.
class BenchmarkResult {
  /// The id the model store uses, which is [CatalogModel.servedId] for a
  /// catalogue download.
  final String modelId;

  final double tokensPerSecond;

  /// Size of the file that produced this rate. Kept alongside because it is
  /// what turns a rate into a bandwidth figure, and because a re-quantised
  /// model of the same name is not the same measurement.
  final int modelBytes;

  final DateTime measuredAt;

  const BenchmarkResult({
    required this.modelId,
    required this.tokensPerSecond,
    required this.modelBytes,
    required this.measuredAt,
  });

  Map<String, dynamic> toJson() => {
        'id': modelId,
        'tps': tokensPerSecond,
        'bytes': modelBytes,
        'at': measuredAt.toIso8601String(),
      };

  static BenchmarkResult? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final tps = raw['tps'];
    final bytes = raw['bytes'];
    if (id is! String || tps is! num || bytes is! num) return null;
    if (tps <= 0 || bytes <= 0) return null;
    return BenchmarkResult(
      modelId: id,
      tokensPerSecond: tps.toDouble(),
      modelBytes: bytes.toInt(),
      measuredAt:
          DateTime.tryParse(raw['at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Persisted benchmark results, newest per model.
class BenchmarkStore {
  const BenchmarkStore();

  Future<Map<String, BenchmarkResult>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(_kBenchmarkResultsKey));
  }

  /// Saves [result], replacing any earlier run of the same model.
  ///
  /// Only the latest is kept: a phone's speed changes with the OS, thermal
  /// state and what else is running, and an average over months of history
  /// would describe none of those.
  Future<void> record(BenchmarkResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final results = decode(prefs.getString(_kBenchmarkResultsKey))
      ..[result.modelId] = result;
    await prefs.setString(_kBenchmarkResultsKey, encode(results));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBenchmarkResultsKey);
  }
}

/// Parses stored results. Anything malformed is dropped rather than throwing:
/// a corrupt entry should cost the app an estimate, not a page.
Map<String, BenchmarkResult> decode(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return {};
    final results = <String, BenchmarkResult>{};
    for (final entry in decoded) {
      final result = BenchmarkResult.fromJson(entry);
      if (result != null) results[result.modelId] = result;
    }
    return results;
  } on FormatException {
    return {};
  }
}

String encode(Map<String, BenchmarkResult> results) =>
    jsonEncode([for (final r in results.values) r.toJson()]);

/// The memory bandwidth these measurements imply, in GB/s, or null when there
/// is nothing usable to go on.
///
/// Decode reads the whole weight set per token, so `rate × size` recovers the
/// bandwidth the phone actually sustained. Taking the median over the
/// available runs keeps one thermally throttled measurement from dragging
/// every estimate down with it.
double? measuredBandwidthGBps(Iterable<BenchmarkResult> results) {
  final samples = <double>[];
  for (final result in results) {
    final gb = result.modelBytes / (1024 * 1024 * 1024);
    if (gb <= 0) continue;
    final bandwidth = result.tokensPerSecond * gb;
    // A figure outside this range is not a phone decoding a model — it is a
    // bad measurement, a mislabelled file, or a run that never really started.
    if (bandwidth < 0.5 || bandwidth > 200) continue;
    samples.add(bandwidth);
  }
  if (samples.isEmpty) return null;
  samples.sort();
  final middle = samples.length ~/ 2;
  return samples.length.isOdd
      ? samples[middle]
      : (samples[middle - 1] + samples[middle]) / 2;
}
