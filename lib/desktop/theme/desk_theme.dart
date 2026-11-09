/// Desktop design system: the phone app's colours, re-cut for a big screen.
///
/// Colours come from [buildAppTheme] (logo green, slate surfaces) so both apps
/// read as one brand. What changes is density, motion and depth: the desktop
/// UI is calmer and more spacious, with one accent (the orb) doing the
/// talking.
library;

import 'package:flutter/material.dart';

import '../../ui/app.dart' show buildAppTheme;

/// Brand colours shared by the orb, accents and focus rings.
abstract final class DeskColors {
  static const green = Color(0xFF2CA048);
  static const greenDeep = Color(0xFF1B8738);
  static const mint = Color(0xFF4ADE80);
  static const mintSoft = Color(0xFF86EFAC);
  static const night = Color(0xFF07090D);
  static const shadowGreen = Color(0xFF0A2E17);
  static const danger = Color(0xFFDC2626);
  static const amber = Color(0xFFF59E0B);
}

/// Motion: a few durations and curves used everywhere, so the whole app moves
/// with one rhythm. Anything a user waits on is under 300 ms.
abstract final class DeskMotion {
  static const fast = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 420);
  static const page = Duration(milliseconds: 320);

  /// Default ease for anything entering or changing.
  static const ease = Curves.easeOutCubic;

  /// For things that should feel physical (orb, panels sliding in).
  static const spring = Cubic(0.2, 0.9, 0.25, 1.05);

  /// Leaving the screen: quick and quiet.
  static const exit = Curves.easeInCubic;
}

/// Spacing and radii.
abstract final class DeskSize {
  static const radiusS = 8.0;
  static const radiusM = 12.0;
  static const radiusL = 18.0;
  static const radiusXL = 26.0;
  static const railWidth = 72.0;
  static const sidebarWidth = 280.0;
  static const titleBarHeight = 40.0;

  /// Reading width of the chat column.
  static const chatColumn = 780.0;
}

/// Extra colours the desktop UI needs beyond [ColorScheme].
@immutable
class DeskPalette extends ThemeExtension<DeskPalette> {
  const DeskPalette({
    required this.canvas,
    required this.panel,
    required this.panelRaised,
    required this.hairline,
    required this.glass,
    required this.textMuted,
    required this.textFaint,
    required this.userBubble,
    required this.codeBg,
    required this.isDark,
  });

  /// Window background behind everything.
  final Color canvas;

  /// Sidebars and cards.
  final Color panel;

  /// Popovers, menus, the composer.
  final Color panelRaised;

  /// 1 px dividers and card borders.
  final Color hairline;

  /// Translucent fill for floating surfaces.
  final Color glass;
  final Color textMuted;
  final Color textFaint;
  final Color userBubble;
  final Color codeBg;
  final bool isDark;

  static DeskPalette of(BuildContext context) =>
      Theme.of(context).extension<DeskPalette>()!;

  static const dark = DeskPalette(
    canvas: Color(0xFF07090D),
    panel: Color(0xFF0D1117),
    panelRaised: Color(0xFF141A23),
    hairline: Color(0xFF1C2430),
    glass: Color(0xCC10151D),
    textMuted: Color(0xFF94A3B8),
    textFaint: Color(0xFF5B6778),
    userBubble: Color(0xFF17201B),
    codeBg: Color(0xFF0A0E13),
    isDark: true,
  );

  static const light = DeskPalette(
    canvas: Color(0xFFF7F9FB),
    panel: Color(0xFFFFFFFF),
    panelRaised: Color(0xFFFFFFFF),
    hairline: Color(0xFFE3E8EF),
    glass: Color(0xE6FFFFFF),
    textMuted: Color(0xFF475569),
    textFaint: Color(0xFF94A3B8),
    userBubble: Color(0xFFE9F6EC),
    codeBg: Color(0xFFF1F5F9),
    isDark: false,
  );

  @override
  DeskPalette copyWith() => this;

  @override
  DeskPalette lerp(covariant DeskPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return DeskPalette(
      canvas: c(canvas, other.canvas),
      panel: c(panel, other.panel),
      panelRaised: c(panelRaised, other.panelRaised),
      hairline: c(hairline, other.hairline),
      glass: c(glass, other.glass),
      textMuted: c(textMuted, other.textMuted),
      textFaint: c(textFaint, other.textFaint),
      userBubble: c(userBubble, other.userBubble),
      codeBg: c(codeBg, other.codeBg),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// The phone theme with desktop density, motion and surfaces.
ThemeData buildDeskTheme(Brightness brightness, {bool tamil = false}) {
  final base = buildAppTheme(brightness, tamil: tamil);
  final palette = brightness == Brightness.dark
      ? DeskPalette.dark
      : DeskPalette.light;
  final scheme = base.colorScheme.copyWith(surface: palette.canvas);
  final text = base.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.canvas,
    canvasColor: palette.canvas,
    visualDensity: VisualDensity.standard,
    textTheme: text,
    extensions: [palette],
    splashFactory: InkSparkle.splashFactory,
    hoverColor: scheme.onSurface.withValues(alpha: 0.05),
    focusColor: DeskColors.green.withValues(alpha: 0.18),
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(6),
      thumbColor: WidgetStatePropertyAll(
        scheme.onSurface.withValues(alpha: 0.16),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 450),
      decoration: BoxDecoration(
        color: palette.isDark
            ? const Color(0xFF1E2633)
            : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(DeskSize.radiusS),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    cardTheme: base.cardTheme.copyWith(
      color: palette.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DeskSize.radiusL),
        side: BorderSide(color: palette.hairline),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.panelRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DeskSize.radiusXL),
        side: BorderSide(color: palette.hairline),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.panelRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        side: BorderSide(color: palette.hairline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.panel,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        borderSide: BorderSide(color: palette.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        borderSide: BorderSide(color: palette.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeskSize.radiusM),
        borderSide: const BorderSide(color: DeskColors.green, width: 1.4),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: palette.hairline,
      thickness: 1,
      space: 1,
    ),
  );
}
