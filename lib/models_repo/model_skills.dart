/// What each catalog model is actually good at, and how that turns into a
/// rating per [UseCase].
///
/// The ratings here are **editorial**, not measured: they come from what the
/// model's makers claim, what its family is known for, and how big it is. They
/// exist so the Models page can answer "what do you want to do?" instead of
/// making someone infer capability from a parameter count. Treat a rating as a
/// starting recommendation, not a benchmark result.
///
/// Every chat model in [modelCatalog] must appear in [modelTraits]; a test
/// enforces that, so adding a model to the catalog without saying what it is
/// for fails loudly rather than silently dropping it out of every
/// recommendation.
library;

import 'catalog.dart';
import 'use_cases.dart';

/// How well a model does one job.
enum Skill { unsupported, weak, ok, good, excellent }

extension SkillInfo on Skill {
  /// Word used in the recommendation copy: "Excellent for quick
  /// conversations".
  String get word => switch (this) {
        Skill.unsupported => 'Not suited to',
        Skill.weak => 'Limited for',
        Skill.ok => 'Usable for',
        Skill.good => 'Good for',
        Skill.excellent => 'Excellent for',
      };

  int get score => switch (this) {
        Skill.unsupported => 0,
        Skill.weak => 1,
        Skill.ok => 2,
        Skill.good => 3,
        Skill.excellent => 4,
      };
}

/// How much of the world's languages a model was actually trained to handle.
enum LanguageReach {
  /// English (plus whatever leaked in). Other languages degrade fast.
  english,

  /// A published list, typically 8–30 languages, mostly European plus a few
  /// major Asian ones.
  broad,

  /// The 140+ language tier Gemma 3 and 4 claim, which is where Indic scripts
  /// stop being an afterthought.
  veryBroad,
}

/// The handful of facts about a model that decide what it is for.
class ModelTraits {
  /// Parameters that actually run per token, in billions. For mixture and
  /// matryoshka models this is the active count, not the download's headline
  /// number, because it is what governs speed.
  final double activeParamsB;

  final LanguageReach languages;

  /// Trained with enough Tamil to hold a conversation in it. Separate from
  /// [languages] because a long language list does not always include Indic
  /// scripts, and because it is the claim most worth being explicit about.
  final bool tamil;

  /// Tuned to reason step by step (a thinking mode, or a reasoning-heavy
  /// post-train).
  final bool thinking;

  /// Notably good at code *for its size*.
  final bool code;

  /// Ships vision weights. Note this does not mean the app can use them —
  /// see [visionUsable].
  final bool multimodal;

  /// Tuned for tool calling, which is what makes it useful behind an agent.
  final bool tools;

  /// How far this model punches above its weight: 0 typical for its size, 1
  /// notably strong, 2 best-in-class.
  ///
  /// Without this, two models of the same size are separated only by which
  /// download is smaller, which would put Phi-3.5 ahead of Phi-4 and the
  /// original Qwen 3 ahead of its refresh. It is a nudge, not an override —
  /// worth a fraction of a skill step.
  final int quality;

  const ModelTraits({
    required this.activeParamsB,
    this.languages = LanguageReach.english,
    this.tamil = false,
    this.thinking = false,
    this.code = false,
    this.multimodal = false,
    this.tools = false,
    this.quality = 0,
  });
}

/// Whether image understanding works in this build.
///
/// True since the catalogue carries each vision model's image encoder and the
/// app downloads it alongside the weights. A model whose encoder is missing
/// still loads and chats; it simply cannot be shown a picture.
const bool visionUsable = true;

/// Keyed by [CatalogModel.id].
const modelTraits = <String, ModelTraits>{
  'gemma-3-270m-it-q8_0': ModelTraits(activeParamsB: 0.27),
  'lfm2.5-350m-q8_0': ModelTraits(
    activeParamsB: 0.35,
    languages: LanguageReach.broad,
    quality: 1,
  ),
  'qwen2.5-0.5b-instruct-q4_k_m': ModelTraits(
    activeParamsB: 0.5,
    languages: LanguageReach.broad,
  ),
  'qwen3-0.6b-q8_0': ModelTraits(
    activeParamsB: 0.6,
    languages: LanguageReach.broad,
    thinking: true,
  ),
  'qwen3.5-0.8b-q8_0': ModelTraits(
    activeParamsB: 0.8,
    languages: LanguageReach.broad,
    quality: 1,
  ),
  // Gemma 3's 1B is the English-only member of the family; the 140-language
  // claim starts at 4B. Worth keeping straight, since the family name is what
  // a user would otherwise go by.
  'gemma-3-1b-it-q4_k_m': ModelTraits(activeParamsB: 1.0),
  'llama-3.2-1b-instruct-q4_k_m': ModelTraits(
    activeParamsB: 1.0,
    languages: LanguageReach.broad,
  ),
  'tinyllama-1.1b-chat-q4_k_m': ModelTraits(activeParamsB: 1.1),
  'lfm2-1.2b-q4_k_m': ModelTraits(
    activeParamsB: 1.2,
    languages: LanguageReach.broad,
  ),
  'lfm2.5-1.2b-instruct-q4_k_m': ModelTraits(
    activeParamsB: 1.2,
    languages: LanguageReach.broad,
    quality: 1,
  ),
  'qwen2.5-1.5b-instruct-q4_k_m': ModelTraits(
    activeParamsB: 1.5,
    languages: LanguageReach.broad,
    code: true,
  ),
  'qwen3-1.7b-q8_0': ModelTraits(
    activeParamsB: 1.7,
    languages: LanguageReach.broad,
    tamil: true,
    thinking: true,
    code: true,
    quality: 1,
  ),
  'smollm2-1.7b-instruct-q4_k_m': ModelTraits(activeParamsB: 1.7),
  'gemma-2-2b-it-q4_k_m': ModelTraits(activeParamsB: 2.0),
  'qwen3.5-2b-q4_k_m': ModelTraits(
    activeParamsB: 2.0,
    languages: LanguageReach.broad,
    tamil: true,
    code: true,
    tools: true,
    quality: 2,
  ),
  'gemma-3n-e2b-it-q4_k_m': ModelTraits(
    activeParamsB: 2.0,
    languages: LanguageReach.veryBroad,
    tamil: true,
    multimodal: true,
  ),
  'gemma-4-e2b-it-q4_0': ModelTraits(
    activeParamsB: 2.3,
    languages: LanguageReach.veryBroad,
    tamil: true,
    multimodal: true,
    quality: 2,
  ),
  'lfm2.5-2.6b-q4_k_m': ModelTraits(
    activeParamsB: 2.6,
    languages: LanguageReach.broad,
    tools: true,
    quality: 1,
  ),
  'granite-4.0-h-micro-q4_k_m': ModelTraits(
    activeParamsB: 3.0,
    languages: LanguageReach.broad,
    tools: true,
  ),
  'granite-4.1-3b-q4_k_m': ModelTraits(
    activeParamsB: 3.0,
    languages: LanguageReach.broad,
    tools: true,
    quality: 1,
  ),
  'llama-3.2-3b-instruct-q4_k_m': ModelTraits(
    activeParamsB: 3.0,
    languages: LanguageReach.broad,
    tools: true,
  ),
  'smollm3-3b-q4_k_m': ModelTraits(
    activeParamsB: 3.0,
    languages: LanguageReach.broad,
    thinking: true,
    quality: 1,
  ),
  'phi-3.5-mini-instruct-q4_k_m': ModelTraits(
    activeParamsB: 3.8,
    languages: LanguageReach.broad,
    thinking: true,
    code: true,
    quality: 1,
  ),
  'phi-4-mini-instruct-q4_k_m': ModelTraits(
    activeParamsB: 3.8,
    languages: LanguageReach.broad,
    thinking: true,
    code: true,
    tools: true,
    quality: 2,
  ),
  'qwen3-4b-q4_k_m': ModelTraits(
    activeParamsB: 4.0,
    languages: LanguageReach.broad,
    tamil: true,
    thinking: true,
    code: true,
    tools: true,
    quality: 1,
  ),
  'qwen3-4b-instruct-2507-q4_k_m': ModelTraits(
    activeParamsB: 4.0,
    languages: LanguageReach.broad,
    tamil: true,
    code: true,
    tools: true,
    quality: 2,
  ),
  'qwen3.5-4b-q4_k_m': ModelTraits(
    activeParamsB: 4.0,
    languages: LanguageReach.broad,
    tamil: true,
    thinking: true,
    code: true,
    tools: true,
    quality: 2,
  ),
  'gemma-3-4b-it-q4_k_m': ModelTraits(
    activeParamsB: 4.0,
    languages: LanguageReach.veryBroad,
    tamil: true,
    multimodal: true,
    quality: 1,
  ),
  'nemotron-3-nano-4b-q4_k_m': ModelTraits(
    activeParamsB: 4.0,
    languages: LanguageReach.broad,
    thinking: true,
    tools: true,
    quality: 1,
  ),
  'gemma-4-e4b-it-q4_0': ModelTraits(
    activeParamsB: 4.5,
    languages: LanguageReach.veryBroad,
    tamil: true,
    multimodal: true,
    quality: 2,
  ),
};

/// Traits for [model], or a conservative guess when the catalog has grown a
/// model nobody has rated yet.
///
/// The guess reads the size the catalog already declares and assumes nothing
/// else: an unrated model competes on speed alone rather than being credited
/// with abilities it may not have.
ModelTraits traitsFor(CatalogModel model) {
  final known = modelTraits[model.id];
  if (known != null) return known;
  return ModelTraits(activeParamsB: _paramsFromLabel(model.parameters));
}

double _paramsFromLabel(String label) {
  final match = RegExp(r'([\d.]+)\s*([BM])').firstMatch(label.toUpperCase());
  if (match == null) return 3.0;
  final value = double.tryParse(match.group(1)!) ?? 3.0;
  return match.group(2) == 'M' ? value / 1000 : value;
}

/// How well [model] does [useCase].
Skill skillFor(CatalogModel model, UseCase useCase) {
  if (model.kind != ModelKind.chat) return Skill.unsupported;
  final t = traitsFor(model);
  final b = t.activeParamsB;

  switch (useCase) {
    case UseCase.fastChat:
      // Speed is the whole ask, so size dominates. Thinking models are marked
      // down: a hidden reasoning preamble is exactly what someone asking for
      // fast chat does not want.
      var base = b <= 0.6
          ? Skill.excellent
          : b <= 1.3
              ? Skill.excellent
              : b <= 2.2
                  ? Skill.good
                  : b <= 3.2
                      ? Skill.ok
                      : Skill.weak;
      if (t.thinking) base = _down(base);
      // Below about half a billion parameters replies are instant but thin.
      if (b < 0.4) base = _down(base);
      return base;

    case UseCase.reasoning:
      if (b < 0.8) return Skill.weak;
      var base = b >= 3.5
          ? Skill.good
          : b >= 2.0
              ? Skill.ok
              : Skill.weak;
      if (t.thinking) base = _up(base);
      return base;

    case UseCase.coding:
      if (!t.code) return b >= 3.0 ? Skill.ok : Skill.weak;
      return b >= 3.5
          ? Skill.excellent
          : b >= 1.5
              ? Skill.good
              : Skill.ok;

    case UseCase.tamil:
      // Tamil is where a wrong recommendation is most obvious to the user, so
      // this stays strict: no declared Tamil training, no rating.
      if (!t.tamil) return Skill.unsupported;
      if (b < 1.5) return Skill.weak;
      var base = b >= 3.5 ? Skill.good : Skill.ok;
      if (t.languages == LanguageReach.veryBroad) base = _up(base);
      return base;

    case UseCase.english:
      return b >= 3.0
          ? Skill.excellent
          : b >= 1.5
              ? Skill.good
              : b >= 0.5
                  ? Skill.ok
                  : Skill.weak;

    case UseCase.vision:
      // Vision weights without a downloadable encoder are no use here, so the
      // catalogue entry has to carry the projector too.
      if (!t.multimodal || !visionUsable) return Skill.unsupported;
      if (!model.supportsVision) return Skill.unsupported;
      return b >= 3.5 ? Skill.excellent : Skill.good;

    case UseCase.translation:
      final reach = switch (t.languages) {
        LanguageReach.english => Skill.weak,
        LanguageReach.broad => Skill.ok,
        LanguageReach.veryBroad => Skill.good,
      };
      // Translation degrades badly below a couple of billion parameters
      // whatever the language list claims.
      if (b < 1.5) return _down(reach);
      if (b >= 3.5) return _up(reach);
      return reach;

    case UseCase.summarizing:
      // Needs enough context to hold the input and enough quality to compress
      // it without inventing.
      final room = model.contextTokens >= 32768;
      var base = b >= 2.0
          ? Skill.good
          : b >= 1.0
              ? Skill.ok
              : Skill.weak;
      if (!room) base = _down(base);
      if (b >= 3.5 && room) base = _up(base);
      return base;

    case UseCase.documents:
      // Context window is the binding constraint here: a sharp model with an
      // 8K window cannot read the document at all.
      if (model.contextTokens < 32768) return Skill.weak;
      var base = model.contextTokens >= 131072 ? Skill.good : Skill.ok;
      if (b < 1.5) base = _down(base);
      if (b >= 3.0 && model.contextTokens >= 131072) base = _up(base);
      if (t.tools) base = _up(base);
      return base;
  }
}

Skill _up(Skill s) => Skill.values[(s.index + 1).clamp(0, Skill.values.length - 1)];
Skill _down(Skill s) => Skill.values[(s.index - 1).clamp(0, Skill.values.length - 1)];

/// Short phrases describing what [model] is good at, best first. Used as the
/// "why this one" line under a recommendation.
List<String> highlightsFor(CatalogModel model, {int limit = 2}) {
  final rated = <(UseCase, Skill)>[
    for (final useCase in UseCase.values)
      if (useCase != UseCase.vision || visionUsable)
        (useCase, skillFor(model, useCase)),
  ]..sort((a, b) => b.$2.score.compareTo(a.$2.score));

  return [
    for (final (useCase, skill) in rated.take(limit))
      if (skill.score >= Skill.good.score)
        '${skill.word} ${useCase.blurbShort}',
  ];
}

extension on UseCase {
  /// The use case as it reads mid-sentence: "Excellent for quick
  /// conversations".
  String get blurbShort => switch (this) {
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
}
