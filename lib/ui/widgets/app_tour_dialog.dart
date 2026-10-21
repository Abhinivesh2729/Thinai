import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Redesigned comprehensive App Tour dialog featuring an interactive 5-stage
/// showcase of Thinai's on-device AI capabilities, zero cloud dependencies,
/// model catalog, chat studio, and local server.
class AppTourDialog extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onStartLiveWalkthrough;
  final VoidCallback? onSelectStarterModel;

  const AppTourDialog({
    super.key,
    this.onNavigateTab,
    this.onStartLiveWalkthrough,
    this.onSelectStarterModel,
  });

  /// Presents the App Tour as a beautiful, high-contrast modal dialog.
  static Future<void> show({
    required BuildContext context,
    ValueChanged<int>? onNavigateTab,
    VoidCallback? onStartLiveWalkthrough,
    VoidCallback? onSelectStarterModel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => AppTourDialog(
        onNavigateTab: onNavigateTab,
        onStartLiveWalkthrough: onStartLiveWalkthrough,
        onSelectStarterModel: onSelectStarterModel,
      ),
    );
  }

  @override
  State<AppTourDialog> createState() => _AppTourDialogState();
}

class _AppTourDialogState extends State<AppTourDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  static const Color _brandGreen = Color(0xFF2CA048);
  static const Color _emeraldAccent = Color(0xFF10B981);
  static const Color _surfaceDark = Color(0xFF0F141E);
  static const Color _cardDark = Color(0xFF161E2E);
  static const Color _borderDark = Color(0xFF222E46);

  // Model names and sizes are never translated.
  static const String _starterModel = 'Qwen 2.5 0.5B';
  static const String _starterSize = '390 MB';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 400 || media.size.height < 700;
    final dialogWidth = math.min(media.size.width - 32, 540.0);
    final dialogHeight = math.min(media.size.height - 64, 680.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: _surfaceDark,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _borderDark, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: _emeraldAccent.withValues(alpha: 0.08),
                blurRadius: 48,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              children: [
                // 1. Top Header Bar with Progress Dots and Close Button
                _buildHeader(isCompact),

                // 2. Interactive Slides PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: [
                      _buildSlideSovereignAi(isCompact),
                      _buildSlideModelCatalog(isCompact),
                      _buildSlideChatStudio(isCompact),
                      _buildSlideLocalServer(isCompact),
                      _buildSlideGetStarted(isCompact),
                    ],
                  ),
                ),

                // 3. Bottom Controls & Action Buttons
                _buildBottomNavigation(isCompact),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, isCompact ? 14 : 18, 16, 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
        ),
      ),
      child: Row(
        children: [
          // App Logo Icon Pill. Takes the free space and scales down rather
          // than overflowing when the label runs long (Tamil).
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _brandGreen.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _brandGreen.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.energy_savings_leaf_rounded,
                        color: _emeraldAccent,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.tourBadge,
                        style: const TextStyle(
                          color: _emeraldAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Dot Indicators
          Row(
            children: List.generate(_totalPages, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? _emeraldAccent
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(width: 10),
          // Close button
          IconButton(
            tooltip: context.l10n.tourCloseTooltip,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: Colors.white70,
            splashRadius: 18,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // --- SLIDE 1: 100% PRIVATE & SOVEREIGN AI ---
  Widget _buildSlideSovereignAi(bool isCompact) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStagePill(1, l10n.tourPrivateTag),
          const SizedBox(height: 12),
          Text(
            l10n.tourPrivateTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tourPrivateBody,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          // Visual Comparison Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderDark),
            ),
            child: Column(
              children: [
                _buildComparisonRow(
                  icon: Icons.shield_rounded,
                  iconColor: _emeraldAccent,
                  title: l10n.tourOnDeviceTitle,
                  subtitle: l10n.tourOnDeviceBody,
                  highlight: true,
                ),
                const Divider(color: Color(0x1AFFFFFF), height: 24),
                _buildComparisonRow(
                  icon: Icons.cloud_off_rounded,
                  iconColor: Colors.white60,
                  title: l10n.tourCloudTitle,
                  subtitle: l10n.tourCloudBody,
                  highlight: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x1410B981),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x3310B981)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: _emeraldAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.tourDeviceReady,
                    style: const TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SLIDE 2: CURATED OPEN WEIGHTS & RAM ADVISOR ---
  Widget _buildSlideModelCatalog(bool isCompact) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStagePill(2, l10n.tourCatalogTag),
          const SizedBox(height: 12),
          Text(
            l10n.tourCatalogTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tourCatalogBody,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          // RAM Fit Engine Guide Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.memory_rounded,
                      color: _emeraldAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.tourMemoryFitTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRamFitBadge(
                  label: l10n.tourFitEasyLabel,
                  color: const Color(0xFF4ADE80),
                  desc: l10n.tourFitEasyBody,
                ),
                const SizedBox(height: 8),
                _buildRamFitBadge(
                  label: l10n.tourFitTightLabel,
                  color: const Color(0xFFFACC15),
                  desc: l10n.tourFitTightBody,
                ),
                const SizedBox(height: 8),
                _buildRamFitBadge(
                  label: l10n.tourFitTooBigLabel,
                  color: const Color(0xFFF87171),
                  desc: l10n.tourFitTooBigBody,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Starter Model Suggestion
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: _emeraldAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tourStarterTitle(_starterModel, _starterSize),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.tourStarterBody,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SLIDE 3: CHAT STUDIO & MULTIMODAL ---
  Widget _buildSlideChatStudio(bool isCompact) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStagePill(3, l10n.tourChatTag),
          const SizedBox(height: 12),
          Text(
            l10n.tourChatTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tourChatBody,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          // Interactive Chat Simulation Mockup
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Prompt Mockup
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _brandGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      l10n.tourDemoPrompt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // AI Response Mockup with Live Speed
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E283C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x334ADE80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tourDemoReply,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x2810B981),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.tourDemoSpeed('31.4'),
                                  style: const TextStyle(
                                    color: Color(0xFF4ADE80),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Feature tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeaturePill(
                Icons.psychology_rounded,
                l10n.tourFeatureReasoning,
              ),
              _buildFeaturePill(
                Icons.photo_camera_rounded,
                l10n.tourFeatureVision,
              ),
              _buildFeaturePill(Icons.tune_rounded, l10n.tourFeaturePersonas),
            ],
          ),
        ],
      ),
    );
  }

  // --- SLIDE 4: LOCAL DEVELOPER SERVER ---
  Widget _buildSlideLocalServer(bool isCompact) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStagePill(4, l10n.tourServerTag),
          const SizedBox(height: 12),
          Text(
            l10n.tourServerTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tourServerBody,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          // Server preview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.dns_rounded,
                      color: _emeraldAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.tourEndpointsTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      l10n.tourPortBadge('8080'),
                      style: const TextStyle(
                        color: _emeraldAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildEndpointRow('POST', '/v1/chat/completions'),
                _buildEndpointRow('GET', '/v1/models'),
                _buildEndpointRow('POST', '/v1/embeddings'),
                const Divider(color: Color(0x1AFFFFFF), height: 20),
                Text(
                  l10n.tourCompatibleWith(
                    'Cursor · Continue · VS Code · Python SDK · LangChain · cURL',
                  ),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SLIDE 5: READY TO GET STARTED ---
  Widget _buildSlideGetStarted(bool isCompact) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStagePill(5, l10n.tourStartTag),
          const SizedBox(height: 12),
          Text(
            l10n.tourStartTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tourStartBody,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 18),
          // Option 1: Starter Model Download
          _buildLaunchOption(
            icon: Icons.download_rounded,
            title: l10n.tourOptionStarterTitle(_starterModel),
            subtitle: l10n.tourOptionStarterBody(_starterSize),
            buttonText: l10n.tourOptionStarterButton,
            onTap: () {
              Navigator.of(context).pop();
              widget.onSelectStarterModel?.call();
            },
          ),
          const SizedBox(height: 10),
          // Option 2: Explore Catalog
          _buildLaunchOption(
            icon: Icons.explore_rounded,
            title: l10n.tourOptionCatalogTitle,
            subtitle: l10n.tourOptionCatalogBody,
            buttonText: l10n.tourOptionCatalogButton,
            onTap: () {
              Navigator.of(context).pop();
              widget.onNavigateTab?.call(1);
            },
          ),
          const SizedBox(height: 10),
          // Option 3: Live Interactive Guided Walkthrough
          _buildLaunchOption(
            icon: Icons.navigation_rounded,
            title: l10n.tourOptionLiveTitle,
            subtitle: l10n.tourOptionLiveBody,
            buttonText: l10n.tourOptionLiveButton,
            highlight: true,
            onTap: () {
              Navigator.of(context).pop();
              widget.onStartLiveWalkthrough?.call();
            },
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildStagePill(int stage, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _emeraldAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            context.l10n.tourStageLabel(stage, _totalPages),
            style: const TextStyle(
              color: _emeraldAccent,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool highlight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: highlight ? const Color(0xFF4ADE80) : Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRamFitBadge({
    required String label,
    required Color color,
    required String desc,
  }) {
    return Row(
      children: [
        // Capped so a long translated label wraps inside the pill instead of
        // pushing the description off the card.
        Container(
          constraints: const BoxConstraints(maxWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _emeraldAccent, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointRow(String method, String path) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x3310B981),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              method,
              style: const TextStyle(
                color: Color(0xFF4ADE80),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              path,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? _brandGreen.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? _brandGreen.withValues(alpha: 0.4)
              : const Color(0x1FFFFFFF),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (highlight ? _brandGreen : Colors.white).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: highlight ? _emeraldAccent : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Capped so a long translated label wraps rather than squeezing the
          // description to nothing; English labels sit inside the cap.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: highlight ? _brandGreen : const Color(0xFF1E283C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onTap,
              child: Text(buttonText, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isCompact) {
    final l10n = context.l10n;
    final isLast = _currentPage == _totalPages - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, isCompact ? 14 : 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x22FFFFFF), width: 1),
        ),
      ),
      // An OverflowBar lays the two buttons out like a spaced row and only
      // stacks them when longer translations no longer fit side by side.
      child: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.end,
        overflowSpacing: 8,
        children: [
          if (_currentPage > 0)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Color(0x33FFFFFF)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _prevPage,
              child: Text(l10n.commonBack),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.commonSkip,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _brandGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: Icon(
              isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
              size: 16,
            ),
            label: Text(isLast ? l10n.tourCompleteTour : l10n.tourNextStep),
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }
}

/// Floating interactive Dock navigator shown on top of the main shell for live guided tours.
class LiveGuidedTourDock extends StatelessWidget {
  final int step;
  final ValueChanged<int> onStepChanged;
  final VoidCallback onDismiss;

  const LiveGuidedTourDock({
    super.key,
    required this.step,
    required this.onStepChanged,
    required this.onDismiss,
  });

  static const Color _brandGreen = Color(0xFF2CA048);
  static const Color _surfaceDark = Color(0xFF101725);
  static const Color _borderDark = Color(0xFF22304A);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = math.min(media.size.width - 24, 460.0);

    final l10n = context.l10n;
    final info = _stepInfo(l10n, step);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          width: width,
          margin: const EdgeInsets.only(bottom: 74),
          decoration: BoxDecoration(
            color: _surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderDark, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _brandGreen.withValues(alpha: 0.12),
                blurRadius: 36,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Step counter + dismiss button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _brandGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.tourDockStep(step + 1, 4),
                      style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.tourExitTour,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: Colors.white54,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDismiss,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Step Title & Body
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x224ADE80),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(info.icon, color: const Color(0xFF4ADE80), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          info.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Navigation Buttons. OverflowBar keeps the row layout and only
              // stacks when longer translations no longer fit.
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                overflowSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: TextButton(
                          onPressed: onDismiss,
                          child: Text(
                            l10n.tourExitTour,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                      if (step > 0)
                        Flexible(
                          child: TextButton(
                            onPressed: () => onStepChanged(step - 1),
                            child: Text(
                              l10n.tourPrevious,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                    ],
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _brandGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () {
                      if (step < 3) {
                        onStepChanged(step + 1);
                      } else {
                        onDismiss();
                      }
                    },
                    child: Text(
                      step == 3 ? l10n.tourFinishTour : l10n.tourNextStep,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _GuidedStepInfo _stepInfo(AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return _GuidedStepInfo(
          icon: Icons.memory_rounded,
          title: l10n.tourDockModelsTitle,
          description: l10n.tourDockModelsBody,
        );
      case 1:
        return _GuidedStepInfo(
          icon: Icons.speed_rounded,
          title: l10n.tourDockManageTitle,
          description: l10n.tourDockManageBody,
        );
      case 2:
        return _GuidedStepInfo(
          icon: Icons.chat_bubble_outline_rounded,
          title: l10n.tourDockChatTitle,
          description: l10n.tourDockChatBody,
        );
      case 3:
      default:
        return _GuidedStepInfo(
          icon: Icons.dns_rounded,
          title: l10n.tourDockServerTitle,
          description: l10n.tourDockServerBody('localhost:8080'),
        );
    }
  }
}

class _GuidedStepInfo {
  final IconData icon;
  final String title;
  final String description;

  const _GuidedStepInfo({
    required this.icon,
    required this.title,
    required this.description,
  });
}
