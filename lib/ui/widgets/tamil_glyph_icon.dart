import 'package:flutter/material.dart';

/// The letter த drawn at the size and weight of a Material icon, so it can
/// sit in an app bar beside icons as their peer.
///
/// It takes its colour from the ambient [IconTheme] and ignores the text
/// scale setting, as icons do: a glyph that grew with the font size would
/// crowd the bar.
class TamilGlyphIcon extends StatelessWidget {
  const TamilGlyphIcon({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Text(
          'த',
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: size * 0.86,
            fontWeight: FontWeight.w700,
            height: 1,
            color: icon.color,
          ),
        ),
      ),
    );
  }
}
