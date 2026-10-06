import 'package:flutter/material.dart';

/// Pure white minimalist entrance screen featuring the official Thinai logo
/// with a smooth, lightweight 60fps fade-and-scale transition.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    const logoGreen = Color(0xFF2CA048);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.94 + (0.06 * value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // High-resolution official Thinai logo from store assets
                      Image.asset(
                        'store/icon-512.png',
                        width: 170,
                        height: 170,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'On-Device Sovereign Intelligence',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                        children: [
                          TextSpan(text: 'Crafted in '),
                          TextSpan(
                            text: 'Erode, Tamil Nadu',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: logoGreen,
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
    );
  }
}

