import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// The first screen, held while session state is restored.
///
/// One composed moment rather than decoration: the app mark, the Tamil
/// wordmark, a single line on what Thinai is, and the credit. Fixed colours,
/// so it is the same brand screen whichever theme the phone is in.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: kBrandInk,
      ),
      child: Scaffold(
        backgroundColor: kBrandInk,
        // Expanded explicitly: a Scaffold body is laid out loose, and the
        // glow would otherwise shrink to the width of the widest line.
        body: SizedBox.expand(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.25),
                radius: 1.1,
                colors: [Color(0xFF12557F), Color(0xFF0A2C48), kBrandInk],
                stops: [0, 0.45, 1],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
                child: Column(
                  children: [
                    const Spacer(flex: 5),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 16 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: const _CenterBrand(),
                    ),
                    const Spacer(flex: 6),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      curve: const Interval(0.4, 1, curve: Curves.easeOut),
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, value, child) =>
                          Opacity(opacity: value, child: child),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Space.xl),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              color: Colors.white.withValues(alpha: 0.62),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                            children: const [
                              TextSpan(text: 'Made with '),
                              // An icon, not the emoji: Inter carries its own
                              // monochrome heart, which wins over the colour one.
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  Icons.favorite_rounded,
                                  size: 14,
                                  color: Color(0xFFE5484D),
                                ),
                              ),
                              TextSpan(text: ' in '),
                              TextSpan(
                                text: 'Erode, Tamilnadu',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: kBrandGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterBrand extends StatelessWidget {
  const _CenterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ThinaiMark(size: 76),
        const SizedBox(height: Space.xxl + 4),
        const Text(
          'திணை',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            height: 1.15,
            color: Color(0xFFF8FBFF),
          ),
        ),
        const SizedBox(height: Space.sm),
        Text(
          'THINAI',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 6,
            color: kBrandGold.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: Space.lg),
        Text(
          'Private AI that runs on your phone',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.1,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
