/// How large a context window a model may be given on this phone.
///
/// Two ceilings, and the lower one wins. The model's own: it was trained on
/// windows of a certain length, and llama.cpp quietly clamps anything longer
/// to that, so offering more is offering nothing. And the phone's: every token
/// of context holds a slice of KV cache in RAM, so a window the model could
/// take can still be one the phone cannot hold beside the weights.
library;

import '../models_repo/device_profile.dart';
import '../models_repo/gguf_metadata.dart';

/// Smallest window offered. Below this a system prompt and one question do
/// not fit, and every reply would fail.
const int kMinContextSize = 512;

/// Room kept for llama.cpp's compute buffers and the app itself, beyond the
/// weights and the cache.
const int kContextOverheadBytes = 350 * 1024 * 1024;

/// The windows a user picks between. Powers of two, because that is how
/// models are trained and how everyone talks about context, and because a
/// slider of arbitrary numbers invites values that help nothing.
List<int> contextSteps({int upTo = 1 << 20}) => [
      for (var n = kMinContextSize; n <= upTo; n *= 2) n,
    ];

class ContextLimit {
  /// The largest window this model should be given on this phone.
  final int cap;

  /// What the model was trained for, when known.
  final int? trained;

  /// The most context RAM allows beside the weights, when it could be worked
  /// out.
  final int? ramCeiling;

  const ContextLimit({required this.cap, this.trained, this.ramCeiling});

  /// True when it is the phone, not the model, holding the window down —
  /// worth saying, since a bigger phone would lift it.
  bool get ramLimited =>
      ramCeiling != null && (trained == null || ramCeiling! < trained!);

  /// The steps up to [cap], for a slider.
  List<int> get steps => [
        for (final s in contextSteps(upTo: cap)) s,
      ];

  /// Clamps a requested window into what this model and phone can take,
  /// snapped down to a step.
  int clamp(int requested) {
    if (requested <= kMinContextSize) return kMinContextSize;
    if (requested >= cap) return cap;
    var chosen = kMinContextSize;
    for (final s in contextSteps(upTo: cap)) {
      if (s <= requested) chosen = s;
    }
    return chosen;
  }
}

/// Works out the cap for a model file of [fileBytes] with header [info].
///
/// [catalogTrained] is the catalogue's figure, used only when the header had
/// none. With nothing known about the model and nothing about the phone, the
/// cap is generous rather than absent: [fallbackCap] keeps a slider bounded.
ContextLimit contextLimitFor({
  GgufModelInfo? info,
  int? catalogTrained,
  required int fileBytes,
  required DeviceProfile device,
  int fallbackCap = 32768,
}) {
  final trained = info?.trainedContext ?? catalogTrained;

  int? ramCeiling;
  final perToken = info?.kvBytesPerToken;
  final budget = device.modelBudgetBytes;
  if (perToken != null && perToken > 0 && budget != null) {
    final spare = budget - fileBytes - kContextOverheadBytes;
    ramCeiling = spare > 0 ? spare ~/ perToken : 0;
  }

  var ceiling = trained ?? fallbackCap;
  if (ramCeiling != null && ramCeiling < ceiling) ceiling = ramCeiling;

  var cap = kMinContextSize;
  for (final s in contextSteps()) {
    if (s <= ceiling) cap = s;
  }
  return ContextLimit(cap: cap, trained: trained, ramCeiling: ramCeiling);
}
