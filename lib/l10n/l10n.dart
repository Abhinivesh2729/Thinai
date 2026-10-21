import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  /// The strings for the current locale. Falls back to English where no
  /// delegate is installed, so a widget pumped bare in a test still renders.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}
