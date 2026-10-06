/// Turns "what do you want to do?" plus the phone in the user's hand into a
/// specific model to download.
///
/// The two halves matter equally. The best Tamil model in the catalog is the
/// wrong answer on a 4 GB phone that cannot hold it, and the fastest model is
/// the wrong answer to "best reasoning". So a recommendation is scored on the
/// job first, then filtered by what the device can actually run.
library;

import 'benchmark_store.dart';
import 'catalog.dart';
import 'device_profile.dart';
import 'model_skills.dart';
import 'use_cases.dart';

/// How comfortably a model fits in memory.
enum RamFit {
  /// Fits with room for the context window and the rest of the phone.
  comfortable,

  /// Will load, but expect the system to push back — other apps evicted,
  /// slower first token, a real chance of being killed in the background.
  tight,

  /// Beyond what this device can hold.
  tooBig,

  /// Device memory could not be read, so this is unknown rather than fine.
  unknown,
}

extension RamFitInfo on RamFit {
  String get label => switch (this) {
        RamFit.comfortable => 'Runs well on your phone',
        RamFit.tight => 'Tight fit, may slow other apps',
        RamFit.tooBig => 'Too big for your phone',
        RamFit.unknown => 'Fit unknown',
      };
}

class Recommendation {
  final CatalogModel model;

  /// Rating for the job that was asked about.
  final Skill skill;

  final RamFit fit;

  /// Decode speed in tokens per second: measured when [speedIsMeasured],
  /// otherwise derived from file size and what the phone has been observed to
  /// sustain.
  final double? estimatedTokensPerSecond;

  /// True when this rate came from an actual run on this phone rather than
  /// from the model. Worth saying out loud — the two deserve different levels
  /// of trust.
  final bool speedIsMeasured;

  /// Memory the model needs once loaded, weights plus a working context.
  final int runtimeBytes;

  /// Already downloaded.
  final bool installed;

  /// Why this one, in the user's terms.
  final List<String> reasons;

  const Recommendation({
    required this.model,
    required this.skill,
    required this.fit,
    required this.estimatedTokensPerSecond,
    this.speedIsMeasured = false,
    required this.runtimeBytes,
    required this.installed,
    required this.reasons,
  });

  String get speedLabel {
    final rate = estimatedTokensPerSecond;
    if (rate == null) return 'speed unknown';
    final number = rate.toStringAsFixed(rate >= 10 ? 0 : 1);
    // No tilde on a measured rate: the squiggle is what tells the reader the
    // number is a guess, so keeping it on a real measurement would undersell
    // it.
    return speedIsMeasured ? '$number tok/s' : '~$number tok/s';
  }

  String get ramLabel {
    final gb = runtimeBytes / (1024 * 1024 * 1024);
    if (gb < 1) return '${(runtimeBytes / (1024 * 1024)).round()} MB RAM';
    return '${gb.toStringAsFixed(1)} GB RAM';
  }
}

class RecommendationResult {
  /// Best first. Empty when nothing in the catalog can do the job.
  final List<Recommendation> picks;

  /// Set when the job cannot be done at all right now, with the reason to show
  /// instead of a list.
  final String? unavailable;

  /// Set when the picks are the closest available rather than genuinely good
  /// at the job — typically because the models that would do it well do not
  /// fit in this phone's memory. Shown above the picks so nobody downloads two
  /// gigabytes expecting something the model cannot do.
  final String? caveat;

  const RecommendationResult({
    this.picks = const [],
    this.unavailable,
    this.caveat,
  });

  Recommendation? get best => picks.isEmpty ? null : picks.first;
  List<Recommendation> get alternatives => picks.skip(1).toList();
}

/// Memory a model occupies once running: the weights, plus the KV cache for a
/// working context, plus llama.cpp's own overhead.
///
/// The context assumed here is 8K ([kRecommendationContext]) rather than the
/// model's full window — nobody runs a 256K context on a phone, and costing it
/// that way would rule out every long-context model for no reason.
int runtimeBytesFor(CatalogModel model) {
  final kvBytes = (kRecommendationContext * _kvBytesPerToken(model)).round();
  // The image encoder is loaded alongside the weights on a vision model, and
  // leaving it out would recommend a model that does not fit once it is
  // actually doing the job it was recommended for.
  final projectorBytes = model.mmprojBytes ?? 0;
  return (model.approxBytes * 1.05).round() + kvBytes + projectorBytes;
}

/// The context the fit estimate assumes, in tokens.
const int kRecommendationContext = 8192;

/// KV cache cost per token, in bytes. Scales with model depth and width, which
/// track parameter count closely enough for a fit estimate.
double _kvBytesPerToken(CatalogModel model) {
  final b = traitsFor(model).activeParamsB;
  // ~65 KB/token at 4B down to ~10 KB/token at sub-billion, F16 cache.
  return (16000 * b).clamp(8000, 80000);
}

/// What is known about decode speed on this phone: the measurements the
/// Benchmark page has taken, and the device class to fall back on.
///
/// One measurement does more than label one model. `rate × size` recovers the
/// bandwidth the phone actually sustained, and that number re-scales the
/// estimate for every other model in the catalogue — so benchmarking one model
/// makes the whole page more accurate.
class SpeedKnowledge {
  final DeviceProfile device;

  /// Measured runs, keyed by [CatalogModel.servedId].
  final Map<String, BenchmarkResult> measurements;

  SpeedKnowledge({required this.device, this.measurements = const {}})
      : _calibrated = measuredBandwidthGBps(measurements.values);

  final double? _calibrated;

  /// True once a measurement exists to calibrate against.
  bool get calibrated => _calibrated != null;

  double get bandwidthGBps => _calibrated ?? device.effectiveBandwidthGBps;

  BenchmarkResult? measurementFor(CatalogModel model) =>
      measurements[model.servedId];

  /// Speed for [model]: the measured rate where there is one, otherwise an
  /// estimate.
  ///
  /// Null only when there is nothing to go on at all — no measurement and no
  /// readable device — because a made-up number is worse than an honest blank.
  double? rateFor(CatalogModel model) {
    final measured = measurementFor(model);
    if (measured != null) return measured.tokensPerSecond;
    if (!device.known && _calibrated == null) return null;

    final gb = model.approxBytes / (1024 * 1024 * 1024);
    if (gb <= 0) return null;
    // Small models stop being bandwidth-bound and start being compute-bound;
    // without that ceiling a 270M model reads as 100 tok/s, which no phone
    // does.
    return (bandwidthGBps / gb).clamp(0.5, 60.0);
  }

  bool isMeasured(CatalogModel model) => measurements.containsKey(model.servedId);
}

/// Decode speed estimate with no measurements to go on.
double? estimateTokensPerSecond(CatalogModel model, DeviceProfile device) =>
    SpeedKnowledge(device: device).rateFor(model);

RamFit fitFor(CatalogModel model, DeviceProfile device) {
  final budget = device.modelBudgetBytes;
  final comfortable = device.comfortableBytes;
  if (budget == null || comfortable == null) return RamFit.unknown;

  final needed = runtimeBytesFor(model);
  if (needed <= comfortable) return RamFit.comfortable;
  // Between the two: it loads and runs, at the cost of the kernel reclaiming
  // cache and Android dropping background apps.
  if (needed <= budget) return RamFit.tight;
  return RamFit.tooBig;
}

/// Ranks the catalog for [useCase] on [device].
///
/// [installedIds] are [CatalogModel.id]s already downloaded; they get a nudge
/// up the order because "you already have this" beats a 2 GB download when the
/// two are otherwise close.
RecommendationResult recommend(
  UseCase useCase,
  DeviceProfile device, {
  Set<String> installedIds = const {},
  SpeedKnowledge? speed,
  int limit = 3,
}) {
  final knowledge = speed ?? SpeedKnowledge(device: device);
  if (useCase == UseCase.vision && !visionUsable) {
    return const RecommendationResult(
      unavailable: 'Image understanding is not available in this build.',
    );
  }

  final scored = <(Recommendation, double)>[];
  for (final model in chatCatalog) {
    final skill = skillFor(model, useCase);
    if (skill == Skill.unsupported) continue;

    final fit = fitFor(model, device);
    if (fit == RamFit.tooBig) continue;

    final rate = knowledge.rateFor(model);
    final installed = installedIds.contains(model.id);

    var score = skill.score * 100.0;

    // A tight fit is a real cost, not a footnote: it is the difference between
    // a model that works and one that gets killed in the background.
    if (fit == RamFit.tight) score -= 120;

    // Speed counts everywhere, and counts double where the user asked for it.
    if (rate != null) {
      score += rate.clamp(0, 40) * (useCase.favoursSpeed ? 2.5 : 0.8);
    }

    if (installed) score += 60;

    // Separates same-size models that the skill ratings score identically:
    // a newer generation at 3.8B should beat the one it replaced.
    score += traitsFor(model).quality * 20;

    // Between two models that are otherwise equal, prefer the smaller
    // download — counting the image encoder, which is not a rounding error at
    // half a gigabyte.
    score -= model.totalDownloadBytes / (1024 * 1024 * 1024) * 8;

    scored.add((
      Recommendation(
        model: model,
        skill: skill,
        fit: fit,
        estimatedTokensPerSecond: rate,
        speedIsMeasured: knowledge.isMeasured(model),
        runtimeBytes: runtimeBytesFor(model),
        installed: installed,
        reasons: _reasonsFor(model, useCase, skill),
      ),
      score,
    ));
  }

  scored.sort((a, b) => b.$2.compareTo(a.$2));

  // A model rated "limited for" the job is not a recommendation, it is the
  // least bad option. Offering one as the answer is how a user ends up
  // downloading a 270M model because they asked for reasoning. Prefer the
  // models that can actually do it, and only fall back with the reason said
  // out loud.
  final capable = [
    for (final (rec, _) in scored)
      if (rec.skill.score >= Skill.ok.score) rec,
  ];
  if (capable.isNotEmpty) {
    return RecommendationResult(picks: capable.take(limit).toList());
  }

  final fallback = [for (final (rec, _) in scored.take(limit)) rec];
  if (fallback.isEmpty) {
    return RecommendationResult(
      caveat: 'No model in the catalogue fits this phone for '
          '${_phrase(useCase)}.',
    );
  }
  return RecommendationResult(
    picks: fallback,
    caveat: device.known
        ? 'Nothing fits well for ${_phrase(useCase)}. These are closest.'
        : 'Nothing at this size is strong at ${_phrase(useCase)}. Closest '
            'matches shown.',
  );
}

/// The "why this one" lines: the job that was asked about first, then whatever
/// else the model is good at.
List<String> _reasonsFor(CatalogModel model, UseCase useCase, Skill skill) {
  final reasons = <String>['${skill.word} ${_phrase(useCase)}'];
  for (final extra in highlightsFor(model, limit: 3)) {
    if (reasons.length >= 3) break;
    if (!reasons.contains(extra)) reasons.add(extra);
  }
  return reasons;
}

String _phrase(UseCase useCase) => switch (useCase) {
      UseCase.fastChat => 'quick conversations',
      UseCase.reasoning => 'step-by-step reasoning',
      UseCase.coding => 'code',
      UseCase.tamil => 'Tamil',
      UseCase.english => 'English',
      UseCase.vision => 'images',
      UseCase.translation => 'translation',
      UseCase.summarizing => 'summarising',
      UseCase.documents => 'long documents',
    };
