import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';

/// Entrance splash. Its first frame is drawn to match the Android launch
/// splash (`res/drawable*/splash_logo.png`: same logo, size and position), so
/// the hand-off from the OS splash is seamless and the intro animation simply
/// continues from it.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// Length of the intro animation; the shell waits at least this long.
  static const Duration introDuration = Duration(milliseconds: 500);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const Color _logoGreen = Color(0xFF2CA048);

  /// Stand-in for the place name inside the translated footer, so the place
  /// can be picked out and drawn in green whatever the word order.
  static const String _placeSlot = '\u{E001}';

  /// Width of the logo artwork (not the PNG canvas) in the launch splash.
  /// Keep in sync with the generated `splash_logo.png` drawables.
  static const double _launchLogoWidth = 168;

  /// The logo PNGs pad their artwork; this is canvas width / artwork width.
  static const double _logoCanvasRatio = 1910 / 1738;
  static const double _logoAspect = 906 / 1910;

  /// Longest the OS splash is held while the logo decodes.
  static const Duration _maxFirstFrameDelay = Duration(milliseconds: 400);

  late final AnimationController _animController;
  late final Animation<double> _revealAnimation;
  late final Animation<double> _scaleAnimation;

  ImageProvider? _logo;
  Timer? _firstFrameGuard;
  bool _firstFrameReleased = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: SplashPage.introDuration,
    );

    _revealAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    // Starts at the launch splash size, then settles slightly larger.
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_logo != null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final asset = isDark
        ? 'assets/images/logo_dark.png'
        : 'assets/images/logo_transparent.png';
    // Decode at display size rather than the 1910px source.
    _logo = ResizeImage(
      AssetImage(asset),
      width: (_launchLogoWidth * _logoCanvasRatio * 1.12 * dpr).round(),
    );

    // Hold the OS splash (which already shows this logo) until the logo is
    // decoded, so the first Flutter frame never shows an empty logo slot.
    final binding = WidgetsBinding.instance;
    if (!binding.firstFrameRasterized) {
      _firstFrameReleased = false;
      binding.deferFirstFrame();
      _firstFrameGuard = Timer(_maxFirstFrameDelay, _releaseFirstFrame);
      precacheImage(_logo!, context).whenComplete(_releaseFirstFrame);
    }
  }

  void _releaseFirstFrame() {
    if (_firstFrameReleased) return;
    _firstFrameReleased = true;
    _firstFrameGuard?.cancel();
    WidgetsBinding.instance.allowFirstFrame();
  }

  @override
  void dispose() {
    _releaseFirstFrame();
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
            letterSpacing: context.tracking(3.5),
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  /// The footer as spans: one translated sentence, cut at the place name.
  List<TextSpan> _footerSpans(AppLocalizations l10n) {
    final sentence = l10n.splashCraftedIn(_placeSlot);
    final at = sentence.indexOf(_placeSlot);
    const place = TextStyle(color: _logoGreen, fontWeight: FontWeight.w900);
    if (at < 0) return [TextSpan(text: sentence)];
    return [
      if (at > 0) TextSpan(text: sentence.substring(0, at)),
      TextSpan(text: l10n.splashPlace, style: place),
      if (at + _placeSlot.length < sentence.length)
        TextSpan(text: sentence.substring(at + _placeSlot.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF090A0C) : const Color(0xFFFFFFFF);
    const logoWidth = _launchLogoWidth * _logoCanvasRatio;
    const logoHeight = logoWidth * _logoAspect;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: bg,
        // Full-window stack: the OS splash centres its icon in the whole
        // window, so the logo is centred the same way, outside any SafeArea.
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image(
                  image: _logo!,
                  width: logoWidth,
                  height: logoHeight,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildBrandFallback(isDark),
                ),
              ),
            ),

            // Tagline and loader reveal below the logo.
            Center(
              child: FadeTransition(
                opacity: _revealAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(_revealAnimation),
                  child: Padding(
                    padding: const EdgeInsets.only(top: logoHeight * 1.12 + 56),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.splashTagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: context.tracking(1.8),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _logoGreen,
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

            // Bottom pinned footer with bold geometric typography
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: FadeTransition(
                  opacity: _revealAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w800,
                          letterSpacing: context.tracking(1.6),
                        ),
                        children: _footerSpans(l10n),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
