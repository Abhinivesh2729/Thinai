import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Entrance splash screen featuring the official Thinai logo with
/// smooth optical centering, zero-blank-screen immediate fallback rendering,
/// subtle brand breathing animation, and elegant dark/light theme adaptation.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const Color _logoGreen = Color(0xFF2CA048);

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildBrandFallback(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _logoGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.energy_savings_leaf_rounded,
            size: 52,
            color: _logoGreen,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'THINAI',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF090A0C) : const Color(0xFFFFFFFF);
    final logoAsset = isDark
        ? 'assets/images/logo_dark.png'
        : 'assets/images/logo_transparent.png';

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

              // Golden-ratio optical center brand group with smooth scale & fade
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // High-resolution Thinai logo with immediate frame fallback
                      Image.asset(
                        logoAsset,
                        width: 240,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded || frame != null) {
                            return child;
                          }
                          // Instant brand badge while decoding so screen is never blank
                          return _buildBrandFallback(isDark);
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildBrandFallback(isDark);
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'SOVEREIGN ON-DEVICE INTELLIGENCE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Elegant micro loading bar
                      SizedBox(
                        width: 64,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            minHeight: 2.5,
                            backgroundColor: Color(0x1F2CA048),
                            valueColor: AlwaysStoppedAnimation<Color>(_logoGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // Bottom pinned footer with bold geometric typography
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
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
                            color: _logoGreen,
                            fontWeight: FontWeight.w900,
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
    );
  }
}
