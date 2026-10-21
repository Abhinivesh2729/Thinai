import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// The "Made in Erode" credit, in one place so the splash, About and Settings
/// all show the same wording and green accent.
class MadeInErode extends StatelessWidget {
  const MadeInErode({super.key, this.compact = false});

  /// Smaller type for use as a page footer rather than a card.
  final bool compact;

  /// Brand green from the logo, fixed rather than scheme-derived so the
  /// credit reads the same in light and dark.
  static const _green = Color(0xFF2CA048);

  // Stand-ins handed to the translated sentence so the heart and the place
  // can be found again and styled; private-use code points never occur in
  // real copy.
  static const _heartSlot = '\u{E000}';
  static const _placeSlot = '\u{E001}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2EA043)
        : _green;

    final plain = TextStyle(
      fontSize: compact ? 12 : 14,
      color: scheme.onSurfaceVariant,
    );
    final heart = TextStyle(fontSize: compact ? 11 : 13);
    final place = TextStyle(
      fontSize: compact ? 13 : 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: accent,
    );

    // The whole sentence comes from one translation, so word order is the
    // translator's; it is only cut at the slots to style each piece. A Wrap
    // keeps the pieces on one line when they fit and lets a longer language
    // flow onto a second line instead of overflowing.
    final sentence = l10n.brandMadeWith(_heartSlot, _placeSlot);
    final pieces = <Widget>[];
    final pattern = RegExp('[$_heartSlot$_placeSlot]');
    var start = 0;
    for (final match in pattern.allMatches(sentence)) {
      if (match.start > start) {
        pieces.add(Text(sentence.substring(start, match.start), style: plain));
      }
      pieces.add(
        match.group(0) == _heartSlot
            ? Text('❤️', style: heart)
            : Text(l10n.brandPlace, style: place),
      );
      start = match.end;
    }
    if (start < sentence.length) {
      pieces.add(Text(sentence.substring(start), style: plain));
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: pieces,
    );
  }
}
