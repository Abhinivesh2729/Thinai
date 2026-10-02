/// Thinai's design tokens and Material theme.
///
/// One accent (brand navy), true-neutral surfaces, hairline borders instead of
/// shadows, and a single type family. Every screen builds from these values
/// rather than inventing its own, which is most of what makes an interface
/// feel considered: the same radius, the same grey, the same gap, everywhere.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── brand ─────────────────────────────────────────────────────────────────

/// Brand navy. The splash, the app mark, and the light-theme accent.
const kBrandNavy = Color(0xFF0E4B75);

/// Deepest navy, for the splash background and the app mark's gradient.
const kBrandInk = Color(0xFF061B2E);

/// Brand gold from the Tamil wordmark. Reserved for brand moments: the mark,
/// the splash, the "Made in Erode" credit. Never a UI state colour.
const kBrandGold = Color(0xFFF2C66D);

// ─── scales ────────────────────────────────────────────────────────────────

/// Spacing on a 4 dp grid. Pages use [gutter] as their side margin.
abstract final class Space {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Horizontal page margin.
  static const double gutter = 20;
}

/// Corner radii. Cards are [lg]; anything that floats (sheets, dialogs) is
/// rounder, anything nested inside a card is tighter.
abstract final class Radii {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
}

/// Motion durations. Short enough to never be waited on.
abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;
}

// ─── semantic colours ──────────────────────────────────────────────────────

/// Colours Material's [ColorScheme] has no slot for.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.card,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.codeSurface,
    required this.onCodeSurface,
    required this.userBubble,
    required this.onUserBubble,
  });

  /// Fill for cards and grouped lists, one step off the page background.
  final Color card;

  /// Running, installed, fits comfortably.
  final Color success;
  final Color successContainer;

  /// Tight fits and caveats: worth reading, not an error.
  final Color warning;
  final Color warningContainer;

  /// Code blocks, curl examples, tokens.
  final Color codeSurface;
  final Color onCodeSurface;

  /// The user's own chat messages.
  final Color userBubble;
  final Color onUserBubble;

  static const light = AppColors(
    card: Color(0xFFFFFFFF),
    success: Color(0xFF15803D),
    successContainer: Color(0xFFE7F6EC),
    warning: Color(0xFFB45309),
    warningContainer: Color(0xFFFEF3E2),
    codeSurface: Color(0xFFF4F4F5),
    onCodeSurface: Color(0xFF27272A),
    userBubble: Color(0xFFEDEEF1),
    onUserBubble: Color(0xFF17181C),
  );

  static const dark = AppColors(
    card: Color(0xFF16171A),
    success: Color(0xFF4ADE80),
    successContainer: Color(0xFF12291B),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF2E2310),
    codeSurface: Color(0xFF0B0C0E),
    onCodeSurface: Color(0xFFE4E4E7),
    userBubble: Color(0xFF26272C),
    onUserBubble: Color(0xFFECECEE),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? card,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? codeSurface,
    Color? onCodeSurface,
    Color? userBubble,
    Color? onUserBubble,
  }) {
    return AppColors(
      card: card ?? this.card,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      codeSurface: codeSurface ?? this.codeSurface,
      onCodeSurface: onCodeSurface ?? this.onCodeSurface,
      userBubble: userBubble ?? this.userBubble,
      onUserBubble: onUserBubble ?? this.onUserBubble,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      card: Color.lerp(card, other.card, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      codeSurface: Color.lerp(codeSurface, other.codeSurface, t)!,
      onCodeSurface: Color.lerp(onCodeSurface, other.onCodeSurface, t)!,
      userBubble: Color.lerp(userBubble, other.userBubble, t)!,
      onUserBubble: Color.lerp(onUserBubble, other.onUserBubble, t)!,
    );
  }
}

// ─── colour schemes ────────────────────────────────────────────────────────

/// Hand-tuned rather than seeded: `ColorScheme.fromSeed` tints every surface
/// with the seed hue, which is what made the old screens read as blue-grey
/// mush. Neutrals here are neutral, and the navy only appears where it means
/// something.
const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: kBrandNavy,
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE4EEF7),
  onPrimaryContainer: Color(0xFF0A3557),
  secondary: Color(0xFF52606D),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFEEF0F3),
  onSecondaryContainer: Color(0xFF1F2933),
  tertiary: Color(0xFF2F80C4),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFDDEBF8),
  onTertiaryContainer: Color(0xFF0B3A63),
  error: Color(0xFFD92D20),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFDECEA),
  onErrorContainer: Color(0xFF7A271A),
  surface: Color(0xFFF7F7F8),
  onSurface: Color(0xFF17181C),
  onSurfaceVariant: Color(0xFF63666E),
  surfaceDim: Color(0xFFE8E8EB),
  surfaceBright: Color(0xFFFFFFFF),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF2F2F4),
  surfaceContainer: Color(0xFFEDEDF0),
  surfaceContainerHigh: Color(0xFFE8E8EB),
  surfaceContainerHighest: Color(0xFFE1E1E5),
  outline: Color(0xFFC6C7CD),
  outlineVariant: Color(0xFFE4E4E8),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF1E1F23),
  onInverseSurface: Color(0xFFF4F4F5),
  inversePrimary: Color(0xFF8CC4F2),
  surfaceTint: Color(0x00000000),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF8CC4F2),
  onPrimary: Color(0xFF062A47),
  primaryContainer: Color(0xFF143A5A),
  onPrimaryContainer: Color(0xFFD3E6F8),
  secondary: Color(0xFFAAB4C0),
  onSecondary: Color(0xFF1B2530),
  secondaryContainer: Color(0xFF252A31),
  onSecondaryContainer: Color(0xFFDDE3EA),
  tertiary: Color(0xFF64B0EE),
  onTertiary: Color(0xFF032B4A),
  tertiaryContainer: Color(0xFF103552),
  onTertiaryContainer: Color(0xFFD1E7FA),
  error: Color(0xFFF97066),
  onError: Color(0xFF4A120B),
  errorContainer: Color(0xFF3A1714),
  onErrorContainer: Color(0xFFFECDCA),
  surface: Color(0xFF0E0F11),
  onSurface: Color(0xFFECECEE),
  onSurfaceVariant: Color(0xFF9C9FA7),
  surfaceDim: Color(0xFF0E0F11),
  surfaceBright: Color(0xFF2A2B30),
  surfaceContainerLowest: Color(0xFF0A0B0C),
  surfaceContainerLow: Color(0xFF16171A),
  surfaceContainer: Color(0xFF1B1C20),
  surfaceContainerHigh: Color(0xFF222328),
  surfaceContainerHighest: Color(0xFF2A2B31),
  outline: Color(0xFF41434A),
  outlineVariant: Color(0xFF26272C),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFECECEE),
  onInverseSurface: Color(0xFF17181C),
  inversePrimary: kBrandNavy,
  surfaceTint: Color(0x00000000),
);

// ─── typography ────────────────────────────────────────────────────────────

/// Inter, with tracking tightened as size grows: the optical adjustment that
/// separates a set type scale from a default one.
TextTheme _textTheme(ColorScheme scheme) {
  const family = 'Inter';
  final on = scheme.onSurface;
  final muted = scheme.onSurfaceVariant;
  TextStyle s(
    double size,
    FontWeight weight, {
    double tracking = 0,
    double height = 1.3,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: tracking,
      height: height,
      color: color ?? on,
    );
  }

  return TextTheme(
    displayLarge: s(44, FontWeight.w700, tracking: -1.4, height: 1.05),
    displayMedium: s(38, FontWeight.w700, tracking: -1.2, height: 1.08),
    displaySmall: s(32, FontWeight.w700, tracking: -0.9, height: 1.1),
    headlineLarge: s(30, FontWeight.w700, tracking: -0.8, height: 1.12),
    headlineMedium: s(26, FontWeight.w700, tracking: -0.6, height: 1.15),
    headlineSmall: s(22, FontWeight.w700, tracking: -0.45, height: 1.2),
    titleLarge: s(20, FontWeight.w600, tracking: -0.35, height: 1.25),
    titleMedium: s(16, FontWeight.w600, tracking: -0.2, height: 1.3),
    titleSmall: s(14, FontWeight.w600, tracking: -0.1, height: 1.3),
    bodyLarge: s(16, FontWeight.w400, tracking: -0.15, height: 1.5),
    bodyMedium: s(14, FontWeight.w400, tracking: -0.05, height: 1.45),
    bodySmall: s(12.5, FontWeight.w400, height: 1.4, color: muted),
    labelLarge: s(14, FontWeight.w600, tracking: -0.1, height: 1.2),
    labelMedium: s(12.5, FontWeight.w500, height: 1.2),
    labelSmall: s(11, FontWeight.w600, tracking: 0.6, height: 1.2),
  );
}

// ─── theme ─────────────────────────────────────────────────────────────────

ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = dark ? _darkScheme : _lightScheme;
  final colors = dark ? AppColors.dark : AppColors.light;
  final text = _textTheme(scheme);
  final hairline = BorderSide(color: scheme.outlineVariant);

  RoundedRectangleBorder rounded(
    double r, [
    BorderSide side = BorderSide.none,
  ]) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(r),
    side: side,
  );

  final overlay = dark
      ? SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: scheme.surface,
          systemNavigationBarIconBrightness: Brightness.light,
        )
      : SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: scheme.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    textTheme: text,
    extensions: [colors],
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    splashFactory: InkRipple.splashFactory,
    splashColor: scheme.onSurface.withValues(alpha: 0.06),
    highlightColor: scheme.onSurface.withValues(alpha: 0.04),
    hoverColor: scheme.onSurface.withValues(alpha: 0.04),
    dividerColor: scheme.outlineVariant,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: Space.gutter,
      toolbarHeight: 60,
      systemOverlayStyle: overlay,
      titleTextStyle: text.headlineSmall,
      iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 22),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.card,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: rounded(Radii.lg, hairline),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        shape: rounded(Radii.md + 2),
        textStyle: text.labelLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        shape: rounded(Radii.md + 2),
        side: BorderSide(color: scheme.outline),
        foregroundColor: scheme.onSurface,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        shape: rounded(Radii.md),
        textStyle: text.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.card,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: 14,
      ),
      hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      floatingLabelStyle: text.bodyMedium?.copyWith(color: scheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md + 2),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md + 2),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md + 2),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md + 2),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.card,
      selectedColor: scheme.primaryContainer,
      disabledColor: scheme.surfaceContainerLow,
      // No colour here on purpose: the chip resolves its own per state, and a
      // fixed one would paint selected labels the same as their fill.
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
      side: hairline,
      shape: const StadiumBorder(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 6),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: colors.card,
        foregroundColor: scheme.onSurfaceVariant,
        selectedBackgroundColor: scheme.onSurface,
        selectedForegroundColor: scheme.surface,
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 44),
        shape: rounded(Radii.md),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.outlineVariant;
        }
        return states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : (dark ? scheme.onSurfaceVariant : Colors.white);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: const WidgetStatePropertyAll(null),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.surfaceContainerHighest,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.10),
      valueIndicatorColor: scheme.inverseSurface,
      valueIndicatorTextStyle: text.labelMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
      iconColor: scheme.onSurfaceVariant,
      titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      subtitleTextStyle: text.bodySmall,
      minVerticalPadding: Space.md,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: rounded(Radii.xl + 4),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        Space.xl,
        0,
        Space.xl,
        Space.xl,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.card,
      modalBackgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: scheme.outline,
      dragHandleSize: const Size(36, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      actionTextColor: scheme.inversePrimary,
      elevation: 0,
      shape: rounded(Radii.md + 2),
      insetPadding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.md),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.onSurface.withValues(alpha: dark ? 0.12 : 0.07),
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return text.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
        );
      }),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 3,
      shape: rounded(Radii.lg + 2),
      extendedTextStyle: text.labelLarge,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHigh,
      circularTrackColor: Colors.transparent,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      textStyle: text.labelMedium?.copyWith(color: scheme.onInverseSurface),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: dark ? 0.6 : 0.18),
      shape: rounded(Radii.md + 2, hairline),
      textStyle: text.bodyMedium,
      labelTextStyle: WidgetStatePropertyAll(text.bodyMedium),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.outline;
      }),
    ),
  );
}
