import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Full-screen, light-themed onboarding guide for first-time app entry.
/// Features a pure white top slide deck (~75% height) with animated graphics,
/// bold modern typography, and a vibrant brand-green bottom navigation dock (~25% height)
/// with circular next/previous arrow controls and page indicator dots.
class OnboardingTourScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final ValueChanged<int>? onNavigateTab;

  const OnboardingTourScreen({
    super.key,
    this.onComplete,
    this.onNavigateTab,
  });

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
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
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

class _OnboardingTourScreenState extends State<OnboardingTourScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  static const Color _brandGreen = Color(0xFF2CA048);
  static const Color _brandDark = Color(0xFF0F172A);
  static const Color _slateText = Color(0xFF475569);
  static const Color _slateMuted = Color(0xFF94A3B8);

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding({int? targetTab}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_tour_seen_v2', true);
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

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _brandGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.energy_savings_leaf_rounded,
                        color: _brandGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'THINAI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        color: _brandDark,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _finishOnboarding(),
                      style: TextButton.styleFrom(
                        foregroundColor: _slateMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      child: const Text('Skip'),
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
                      tag: '100% PRIVATE & OFFLINE',
                      headline: 'True Intelligence,\nEntirely On Your Phone',
                      description:
                          'Thinai executes high-parameter AI models directly on your mobile hardware. Zero data transmission, zero telemetry, and zero cloud reliance.',
                      graphic: _buildPrivacyGraphic(),
                      bullets: const [
                        'Zero data leaves your phone RAM',
                        'Fully functional offline & in Airplane mode',
                      ],
                    ),
                    _buildSlide(
                      tag: 'VERIFIED GGUF CATALOG',
                      headline: 'Curated Open Weights\nIn a Single Tap',
                      description:
                          'Download state-of-the-art open models directly from HuggingFace. Quantized with modern precision for smooth mobile execution.',
                      graphic: _buildCatalogGraphic(),
                      bullets: const [
                        'DeepSeek, Meta Llama, Google Gemma & Qwen',
                        'Automatic background resume with foreground service',
                      ],
                    ),
                    _buildSlide(
                      tag: 'HARDWARE ACCELERATION',
                      headline: 'Llama.cpp Engine\nWith Adreno & Mali GPU',
                      description:
                          'Built with native llama.cpp compiled for ARM64 with Qualcomm Adreno OpenCL and ARM Mali Vulkan GPU layer offloading.',
                      graphic: _buildEngineGraphic(),
                      bullets: const [
                        'Hardware GPU acceleration for instant response',
                        'Live tokens/sec metrics and thermal-safe limits',
                      ],
                    ),
                    _buildSlide(
                      tag: 'MULTIMODAL STUDIO',
                      headline: 'Vision, Documents\n& Live Web Synthesis',
                      description:
                          'Engage in smart conversations with vision models, attach PDF & text files for instant summaries, and query live web results on-demand.',
                      graphic: _buildMultimodalGraphic(),
                      bullets: const [
                        'Multimodal vision image inspection (Gemma, MiniCPM)',
                        'Privacy-preserving web search & document QA',
                      ],
                    ),
                    _buildSlide(
                      tag: 'LOCAL DEVELOPER API',
                      headline: 'Turn Your Phone\nInto a Local AI Server',
                      description:
                          'Expose an OpenAI & Ollama compatible REST API on port 11434. Seamlessly connect VS Code extensions, Cline, Cursor, or terminal scripts.',
                      graphic: _buildServerGraphic(),
                      bullets: const [
                        'Compatible with OpenAI SDK & Ollama CLI',
                        'Wi-Fi LAN sharing to serve laptops on your network',
                      ],
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
                  22,
                  28,
                  18 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: _brandGreen,
                ),
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
                            margin: const EdgeInsets.symmetric(horizontal: 4.5),
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

  // ─── SLIDE LAYOUT HELPER ────────────────────────────────────────────────────

  Widget _buildSlide({
    required String tag,
    required String headline,
    required String description,
    required Widget graphic,
    required List<String> bullets,
    bool isFinal = false,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Graphic container
          SizedBox(
            height: 180,
            child: Center(child: graphic),
          ),
          const SizedBox(height: 16),

          // Tag badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _brandGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: _brandGreen,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Headline
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: _brandDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: _slateText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // Bullets
          Column(
            children: bullets.map((text) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: _brandGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _brandDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          if (isFinal) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              icon: const Icon(Icons.rocket_launch_rounded, size: 16),
              label: const Text('Start Using Thinai Now'),
              style: FilledButton.styleFrom(
                backgroundColor: _brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              onPressed: () => _finishOnboarding(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── ANIMATED GRAPHIC 1: PRIVACY & OFFLINE ──────────────────────────────────

  Widget _buildPrivacyGraphic() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glowing pulse ring
            Container(
              width: 150 + (pulse * 18),
              height: 150 + (pulse * 18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brandGreen.withValues(alpha: 0.08 * (1 - pulse)),
                border: Border.all(
                  color: _brandGreen.withValues(alpha: 0.25 * (1 - pulse)),
                  width: 1.5,
                ),
              ),
            ),
            // Middle ring
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brandGreen.withValues(alpha: 0.08),
                border: Border.all(
                  color: _brandGreen.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
            ),
            // Center shield container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _brandGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _brandGreen.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            // Offline Tag Badge floating top right
            Positioned(
              right: 18,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _brandDark,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 8),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'OFFLINE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── ANIMATED GRAPHIC 2: CATALOG & MODELS ───────────────────────────────────

  Widget _buildCatalogGraphic() {
    return SizedBox(
      width: 260,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background card (Qwen)
          Positioned(
            top: 12,
            right: 18,
            child: Transform.rotate(
              angle: 0.08,
              child: _buildMiniModelCard('Qwen 2.5 1.5B', 'Alibaba', '1.1 GB', const Color(0xFF6366F1)),
            ),
          ),
          // Left card (DeepSeek)
          Positioned(
            top: 20,
            left: 18,
            child: Transform.rotate(
              angle: -0.09,
              child: _buildMiniModelCard('DeepSeek R1', 'Reasoning', '1.2 GB', const Color(0xFF0284C7)),
            ),
          ),
          // Center hero card (Llama 3.2)
          Positioned(
            top: 36,
            child: Container(
              width: 190,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _brandGreen, width: 1.8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x202CA048),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _brandGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.memory_rounded,
                      color: _brandGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Llama 3.2 1B',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _brandDark,
                          ),
                        ),
                        Text(
                          'Meta AI · Ready',
                          style: TextStyle(fontSize: 10, color: _slateText),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _brandGreen,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniModelCard(String name, String org, String size, Color accent) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _brandDark),
          ),
          const SizedBox(height: 2),
          Text(
            '$org · $size',
            style: TextStyle(fontSize: 9, color: accent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─── ANIMATED GRAPHIC 3: HARDWARE ACCELERATION ───────────────────────────────

  Widget _buildEngineGraphic() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final speed = 34 + (_pulseController.value * 6.8);
        return Container(
          width: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _brandGreen.withValues(alpha: 0.5), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x28000000), blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LLAMA.CPP ACCELERATION',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    speed.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'tokens/sec',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Adreno OpenCL / Vulkan GPU Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── ANIMATED GRAPHIC 4: MULTIMODAL & WEB SEARCH ────────────────────────────

  Widget _buildMultimodalGraphic() {
    return SizedBox(
      width: 240,
      height: 160,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User query bubble
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _brandGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Analyze this photo',
                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // AI response bubble with search badge
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.travel_explore_rounded, size: 11, color: Color(0xFF0284C7)),
                            SizedBox(width: 3),
                            Text(
                              'Web Verified',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Identified plant: Monstera Deliciosa with healthy aerial roots.',
                    style: TextStyle(fontSize: 11.5, color: _brandDark, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ANIMATED GRAPHIC 5: DEVELOPER LOCAL SERVER ─────────────────────────────

  Widget _buildServerGraphic() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x28000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Terminal bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 10),
                const Text(
                  'http://127.0.0.1:11434',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Terminal code content
          const Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'curl http://127.0.0.1:11434/v1/chat \\',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Color(0xFF4ADE80),
                  ),
                ),
                Text(
                  '  -H "Content-Type: application/json" \\',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Color(0xFFFBBF24),
                  ),
                ),
                Text(
                  '  -d \'{"model": "llama-3.2"}\'',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
