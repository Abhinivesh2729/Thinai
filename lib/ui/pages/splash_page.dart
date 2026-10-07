import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pure white minimalist entrance screen featuring the official Thinai logo
/// with exact optical centering, transparent edge-to-edge system bars,
/// and bold geometric uppercase typography.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    const logoGreen = Color(0xFF2CA048);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF090A0C) : const Color(0xFFFFFFFF);
    final logoAsset = isDark
        ? 'assets/images/logo_dark.png'
        : 'assets/images/logo_white.png';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Golden-ratio optical center brand group
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        logoAsset,
                        width: 250,
                        cacheWidth: 500,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SOVEREIGN ON-DEVICE INTELLIGENCE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 4),
              // Bottom pinned footer with bold geometric Lemon-Milk typography
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                        children: [
                          TextSpan(text: 'CRAFTED IN '),
                          TextSpan(
                            text: 'ERODE, TAMIL NADU',
                            style: TextStyle(
                              color: logoGreen,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

