import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';

/// Full-screen, light-themed onboarding guide for first-time app entry.
/// Features a pure white top slide deck (~75% height) with prominent 3D animated GIF graphics,
/// bold modern typography, one short line of copy, and a vibrant brand-green bottom navigation dock (~25% height)
/// with circular next/previous arrow controls and page indicator dots.
class OnboardingTourScreen extends StatefulWidget {
  /// Unique key for tracking whether the user has completed the full-screen onboarding tour.
  static const String tourSeenKey = 'thinai_has_completed_onboarding_v1';

  final VoidCallback? onComplete;
  final ValueChanged<int>? onNavigateTab;

  const OnboardingTourScreen({super.key, this.onComplete, this.onNavigateTab});

  /// Presents the Onboarding Tour as a full-screen, light-themed page.
  static Future<void> show({
    required BuildContext context,
    VoidCallback? onComplete,
    ValueChanged<int>? onNavigateTab,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (ctx, anim, secondaryAnim) => OnboardingTourScreen(
          onComplete: onComplete,
          onNavigateTab: onNavigateTab,
        ),
        transitionsBuilder: (ctx, anim, secondaryAnim, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<OnboardingTourScreen> createState() => _OnboardingTourScreenState();
}

class _OnboardingTourScreenState extends State<OnboardingTourScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  static const Color _brandGreen = Color(0xFF2CA048);
  static const Color _brandDark = Color(0xFF0F172A);
  static const Color _slateText = Color(0xFF475569);
  static const Color _slateMuted = Color(0xFF94A3B8);

  static const List<String> _onboardingAssets = [
    'assets/images/logo_transparent.png',
    'assets/onboarding/onboarding_offline.gif',
    'assets/onboarding/onboarding_models.gif',
    'assets/onboarding/onboarding_gpu.gif',
    'assets/onboarding/onboarding_rag.gif',
    'assets/onboarding/onboarding_server.gif',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in _onboardingAssets) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding({int? targetTab}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingTourScreen.tourSeenKey, true);
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    widget.onComplete?.call();
    if (targetTab != null) {
      widget.onNavigateTab?.call(targetTab);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  /// The local server port shown on the last slide. A number, not copy.
  static const String _serverPort = '11434';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _brandGreen,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ─── TOP BAR: Logo + Skip Action ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo_transparent.png',
                      height: 38,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: l10n.onboardingLogoLabel,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _finishOnboarding(),
                      style: TextButton.styleFrom(
                        foregroundColor: _slateMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      child: Text(l10n.commonSkip),
                    ),
                  ],
                ),
              ),

              // ─── 3/4 SECTION: SLIDE CAROUSEL (WHITE BACKGROUND) ─────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildSlide(
                      tag: l10n.onboardingPrivateTag,
                      headline: l10n.onboardingPrivateHeadline,
                      description: l10n.onboardingPrivateBody,
                      graphic: _buildGraphic(
                        'assets/onboarding/onboarding_offline.gif',
                        l10n.onboardingPrivateGraphic,
                      ),
                    ),
                    _buildSlide(
                      tag: l10n.onboardingCatalogTag,
                      headline: l10n.onboardingCatalogHeadline,
                      description: l10n.onboardingCatalogBody,
                      graphic: _buildGraphic(
                        'assets/onboarding/onboarding_models.gif',
                        l10n.onboardingCatalogGraphic,
                      ),
                    ),
                    _buildSlide(
                      tag: l10n.onboardingGpuTag,
                      headline: l10n.onboardingGpuHeadline,
                      description: l10n.onboardingGpuBody,
                      graphic: _buildGraphic(
                        'assets/onboarding/onboarding_gpu.gif',
                        l10n.onboardingGpuGraphic,
                      ),
                    ),
                    _buildSlide(
                      tag: l10n.onboardingStudioTag,
                      headline: l10n.onboardingStudioHeadline,
                      description: l10n.onboardingStudioBody,
                      graphic: _buildGraphic(
                        'assets/onboarding/onboarding_rag.gif',
                        l10n.onboardingStudioGraphic,
                      ),
                    ),
                    _buildSlide(
                      tag: l10n.onboardingServerTag,
                      headline: l10n.onboardingServerHeadline,
                      description: l10n.onboardingServerBody(_serverPort),
                      graphic: _buildGraphic(
                        'assets/onboarding/onboarding_server.gif',
                        l10n.onboardingServerGraphic(_serverPort),
                      ),
                      isFinal: true,
                    ),
                  ],
                ),
              ),

              // ─── BOTTOM SECTION: SOLID GREEN DOCK WITH CIRCULAR BUTTONS ────
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  28,
                  20,
                  28,
                  18 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(color: _brandGreen),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button (Circular White Button with Green Arrow)
                    AnimatedOpacity(
                      opacity: _currentPage > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: _currentPage == 0,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 3,
                          shadowColor: Colors.black.withValues(alpha: 0.25),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _prevPage,
                            child: const SizedBox(
                              width: 52,
                              height: 52,
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: _brandGreen,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Center: 5 Page Indicator Dots (Circular dots matching template)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_totalPages, (index) {
                        final isActive = _currentPage == index;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 360),
                              curve: Curves.easeInOutCubic,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: isActive ? 10 : 7,
                            height: isActive ? 10 : 7,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.42),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ),

                    // Next / Finish Button (Circular White Button with Green Arrow)
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _nextPage,
                        child: const SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: _brandGreen,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── GRAPHIC CONTAINER HELPER ───────────────────────────────────────────────

  Widget _buildGraphic(String assetPath, String semanticLabel) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Image.asset(
          assetPath,
          width: 235,
          height: 235,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }

  // ─── SLIDE LAYOUT HELPER ────────────────────────────────────────────────────

  Widget _buildSlide({
    required String tag,
    required String headline,
    required String description,
    required Widget graphic,
    bool isFinal = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Prominent 3D Animated Hero Graphic
                graphic,

                // Text Content Block
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tag Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _brandGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _brandGreen,
                          letterSpacing: context.tracking(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Headline
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: _brandDark,
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: _slateText,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),

                // The last slide's start button. Every slide keeps the slot so
                // the graphic and copy sit at the same height throughout. A
                // minimum rather than a fixed height, so a label that wraps in
                // a longer language grows the button instead of being clipped.
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    minHeight: 50,
                  ),
                  child: isFinal
                      ? FilledButton.icon(
                          icon: const Icon(
                            Icons.rocket_launch_rounded,
                            size: 18,
                          ),
                          label: Text(
                            context.l10n.onboardingStartButton,
                            textAlign: TextAlign.center,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _brandGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            textStyle: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          onPressed: () => _finishOnboarding(),
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
