import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF041C3A), Color(0xFF0C3E7B), Color(0xFF1D7A88)],
          ),
        ),
        child: Stack(
          children: [
            const _Orb(
              top: -90,
              left: -50,
              size: 250,
              color: Color(0x33F5D07A),
            ),
            const _Orb(
              top: 90,
              right: -70,
              size: 210,
              color: Color(0x2247C7BE),
            ),
            const _Orb(
              bottom: 120,
              left: -80,
              size: 240,
              color: Color(0x223B82F6),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 24 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: const _CenterBrand(),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFFE5EDF8),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                          children: [
                            TextSpan(text: 'Made with ❤️ in '),
                            TextSpan(
                              text: 'Erode, Tamilnadu',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF8D88A),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 56, height: 1.2, color: const Color(0x88EED08A)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: Color(0xFFEED08A),
              ),
            ),
            Container(width: 56, height: 1.2, color: const Color(0x88EED08A)),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'திணை',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 58,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: Color(0xFFF8FBFF),
            shadows: [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 180,
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x00F8D88A), Color(0xFFF8D88A), Color(0x00F8D88A)],
            ),
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
