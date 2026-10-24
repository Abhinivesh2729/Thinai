import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Fills the `{device}` select in strings that name the hardware: "computer"
/// on desktop, "phone" everywhere else.
String get deviceKind => switch (defaultTargetPlatform) {
  TargetPlatform.windows ||
  TargetPlatform.macOS ||
  TargetPlatform.linux => 'desktop',
  _ => 'phone',
};

extension AppLocalizationsX on BuildContext {
  /// The strings for the current locale. Falls back to English where no
  /// delegate is installed, so a widget pumped bare in a test still renders.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));

  /// [spacing] for Latin text, none for Tamil. Wide tracking pulls a Tamil
  /// word apart at its vowel signs, so caps-style labels read as loose
  /// letters.
  double tracking(double spacing) =>
      Localizations.maybeLocaleOf(this)?.languageCode == 'ta' ? 0 : spacing;
}
