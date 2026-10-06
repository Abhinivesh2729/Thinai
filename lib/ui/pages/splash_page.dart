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
          child: Stack(
            children: [
              Center(
                child: TweenAnimationBuilder<double>(
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tightly cropped high-res logo with transparent background
                        Image.asset(
                          'assets/images/logo_transparent.png',
                          width: 230,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'On-Device Sovereign Intelligence',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
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
                          fontSize: 12.5,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

