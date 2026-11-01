/// Remembers each model's latest Tamil eval, so the score outlives the page:
/// the Models page shows it on the model's card, and the eval page compares
/// every model measured on this phone.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinai_tamil_evals/thinai_tamil_evals.dart';

const _kTamilEvalKey = 'tamil_eval_v1';

/// Persisted Tamil eval reports, newest per model.
class TamilEvalStore {
  const TamilEvalStore();

  Future<Map<String, EvalReport>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(_kTamilEvalKey));
  }

  /// Saves [report], replacing any earlier run of the same model.
  ///
  /// Only the latest is kept, like the speed benchmark: a re-run is what the
  /// user believes now. The full report is kept, replies included, so the
  /// scores can be explained item by item.
  Future<void> record(EvalReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = decode(prefs.getString(_kTamilEvalKey))
      ..[report.modelId] = report;
    await prefs.setString(_kTamilEvalKey, encode(reports));
  }

  static String encode(Map<String, EvalReport> reports) =>
      jsonEncode([for (final r in reports.values) r.toJson()]);

  /// Reads what [encode] wrote. Anything unreadable is skipped rather than
  /// thrown: a report from an older format is worth less than a page that
  /// opens.
  static Map<String, EvalReport> decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final Object? list;
    try {
      list = jsonDecode(raw);
    } on FormatException {
      return {};
    }
    if (list is! List) return {};
    final out = <String, EvalReport>{};
    for (final entry in list) {
      if (entry is! Map<String, Object?>) continue;
      try {
        final report = EvalReport.fromJson(entry);
        out[report.modelId] = report;
      } on Object {
        continue;
      }
    }
    return out;
  }
}
