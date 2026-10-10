import 'package:flutter/material.dart';

/// The "Made in Erode" credit, in one place so the splash, About and Settings
/// all show the same wording and green accent.
class MadeInErode extends StatelessWidget {
  const MadeInErode({super.key, this.compact = false});

  /// Smaller type for use as a page footer rather than a card.
  final bool compact;

  /// Brand green from the logo, fixed rather than scheme-derived so the
  /// credit reads the same in light and dark.
  static const _green = Color(0xFF2CA048);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2EA043)
        : _green;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Made with ',
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text('\u2764\ufe0f', style: TextStyle(fontSize: compact ? 11 : 13)),
        Text(
          ' in ',
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          'Erode, Tamilnadu',
          style: TextStyle(
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: accent,
          ),
        ),
      ],
    );
  }
}
