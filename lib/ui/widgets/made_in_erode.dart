import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The "Made in Erode" credit, in one place so the splash, About and Settings
/// all show the same wording and gold accent.
class MadeInErode extends StatelessWidget {
  const MadeInErode({super.key, this.compact = false});

  /// Smaller type for use as a page footer rather than a card.
  final bool compact;

  /// Gold from the splash wordmark, fixed rather than scheme-derived so the
  /// credit reads the same in light and dark.
  static const _gold = Color(0xFFB8860B);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? kBrandGold
        : _gold;
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
        // An icon, not the emoji: Inter carries its own monochrome heart,
        // which wins over the colour one.
        Icon(
          Icons.favorite_rounded,
          size: compact ? 12 : 14,
          color: const Color(0xFFE5484D),
        ),
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
