import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../llm/generation_settings.dart';
import '../../llm/gpu_support.dart';
import '../../state/providers.dart';
import '../../update/app_updater.dart';
import '../widgets/gpu_settings_card.dart';
import '../widgets/made_in_erode.dart';
import '../widgets/model_settings_sheet.dart';
import 'about_page.dart';
import 'benchmark_page.dart';
import 'contact_support_page.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MAIN SETTINGS HUB PAGE (Apple-Inspired AI Cards Experience)
// ══════════════════════════════════════════════════════════════════════════════

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static String _startPageName(int index) => switch (index) {
        0 => 'Chat',
        1 => 'Models',
        2 => 'Server',
        3 => 'Settings',
        _ => 'Chat',
      };

  static String _gpuLabel(GpuBackend backend) => switch (backend) {
        GpuBackend.none => 'CPU',
        GpuBackend.auto => 'Auto',
        GpuBackend.vulkan => 'Vulkan',
        GpuBackend.opencl => 'OpenCL',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startPage = ref.watch(startPageProvider);
    final version = ref.watch(appVersionProvider).valueOrNull;

    final models = ref.watch(modelListProvider).valueOrNull ?? const [];
    final activeId = ref.watch(activeModelIdProvider);
    final activeModel = models.where((m) => m.id == activeId).firstOrNull;

    final serverStatus = ref.watch(serverControllerProvider);
    final serverPort = ref.watch(savedServerPortProvider).valueOrNull ?? 11434;

    final currentGpu = GenerationSettingsStore.instance.settings.gpu;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          // 1. Apple Intelligence Holographic / Glow Hero Card
          const _AiPrivacyBanner(),
          const SizedBox(height: 18),

          // 2. Apple AI Grouped Cards
          _SectionNavTile(
            icon: Icons.palette_rounded,
            title: 'Appearance',
            subtitle: 'Startup screen, Theme mode, Web search',
            valueBadge: _startPageName(startPage),
            gradientColors: const [
              Color(0xFF3B82F6),
              Color(0xFF6366F1),
            ],
            shadowColor: const Color(0xFF4F46E5),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AppearanceSettingsPage()),
              );
            },
          ),
          const SizedBox(height: 11),

          _SectionNavTile(
            icon: Icons.memory_rounded,
            title: 'Hardware & Acceleration',
            subtitle: 'GPU acceleration, Device benchmark & specs',
            valueBadge: _gpuLabel(currentGpu),
            gradientColors: const [
              Color(0xFFFF9500),
              Color(0xFFFF5E3A),
            ],
            shadowColor: const Color(0xFFFF9500),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HardwareSettingsPage()),
              );
            },
          ),
          const SizedBox(height: 11),

          _SectionNavTile(
            icon: Icons.tune_rounded,
            title: 'Model & Storage',
            subtitle: activeModel != null
                ? activeModel.displayName
                : 'Model parameters, GGUF import & cleanup',
            valueBadge: activeModel != null
                ? 'Active'
                : (models.isNotEmpty ? '${models.length} loaded' : 'None'),
            gradientColors: const [
              Color(0xFF10B981),
              Color(0xFF059669),
            ],
            shadowColor: const Color(0xFF10B981),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ModelStorageSettingsPage()),
              );
            },
          ),
          const SizedBox(height: 11),

          _SectionNavTile(
            icon: Icons.dns_rounded,
            title: 'Local Server & API',
            subtitle: 'LAN Wi-Fi sharing, Port :$serverPort, Endpoints',
            customBadge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: serverStatus.running
                    ? const Color(0xFF2CA048).withValues(alpha: 0.14)
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: serverStatus.running
                          ? const Color(0xFF2CA048)
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    serverStatus.running ? 'Active' : 'Offline',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: serverStatus.running
                          ? const Color(0xFF2CA048)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            gradientColors: const [
              Color(0xFF06B6D4),
              Color(0xFF2563EB),
            ],
            shadowColor: const Color(0xFF06B6D4),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LocalServerSettingsPage()),
              );
            },
          ),
          const SizedBox(height: 11),

          _SectionNavTile(
            icon: Icons.info_rounded,
            title: 'About & Guidance',
            subtitle: 'Interactive app tour, Updates & support',
            valueBadge: version != null ? 'v$version' : 'Guide',
            gradientColors: const [
              Color(0xFF8B5CF6),
              Color(0xFF6D28D9),
            ],
            shadowColor: const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutGuidanceSettingsPage()),
              );
            },
          ),

          const SizedBox(height: 24),
          const MadeInErode(compact: true),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APPLE INTELLIGENCE HERO GLOW BANNER
// ══════════════════════════════════════════════════════════════════════════════

class _AiPrivacyBanner extends StatelessWidget {
  const _AiPrivacyBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        // Apple Intelligence multi-color iridescent glow border
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2CA048).withValues(alpha: 0.50),
                  const Color(0xFF06B6D4).withValues(alpha: 0.35),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                  const Color(0xFF2CA048).withValues(alpha: 0.15),
                ]
              : [
                  const Color(0xFF2CA048).withValues(alpha: 0.35),
                  const Color(0xFF06B6D4).withValues(alpha: 0.25),
                  const Color(0xFF10B981).withValues(alpha: 0.20),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2CA048).withValues(alpha: isDark ? 0.14 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2), // Apple hairline border
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          color: isDark ? const Color(0xFF111520) : const Color(0xFFFCFDFD),
        ),
        child: Row(
          children: [
            // Apple Intelligence Glowing Aura Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2CA048),
                    Color(0xFF059669),
                    Color(0xFF0D9488),
                  ],
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2CA048).withValues(alpha: 0.40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.shield_rounded,
                  size: 23,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '100% Offline & Private',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2CA048).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ON-DEVICE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: Color(0xFF2CA048),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'All weights execute locally on device silicon. Zero telemetry or external accounts.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APPLE-STYLE SECTION NAVIGATION CARD WITH GLOW SQUIRCLE
// ══════════════════════════════════════════════════════════════════════════════

class _SectionNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? valueBadge;
  final Widget? customBadge;
  final List<Color> gradientColors;
  final Color shadowColor;
  final VoidCallback onTap;

  const _SectionNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.shadowColor,
    required this.onTap,
    this.valueBadge,
    this.customBadge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // iOS Gradient Squircle Icon with colored ambient glow
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withValues(alpha: isDark ? 0.35 : 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          letterSpacing: -0.1,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Value pill (iOS style indicator)
                if (customBadge != null)
                  customBadge!
                else if (valueBadge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.045),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      valueBadge!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                // iOS Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 1. APPEARANCE SETTINGS SUB-PAGE
// ══════════════════════════════════════════════════════════════════════════════

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final startPage = ref.watch(startPageProvider);
    final mode = ref.watch(themeModeProvider);
    final webSearchEnabled = ref.watch(webSearchEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // Section 1: Startup Screen
          _SettingsSectionCard(
            title: 'Startup & Navigation',
            icon: Icons.launch_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.start_rounded, size: 20, color: scheme.onSurface),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Open page on startup',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Choose which tab opens when launching Thinai',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          label: Text('Chat'),
                          icon: Icon(Icons.chat_bubble_rounded),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Models'),
                          icon: Icon(Icons.memory_rounded),
                        ),
                        ButtonSegment(
                          value: 2,
                          label: Text('Server'),
                          icon: Icon(Icons.dns_rounded),
                        ),
                        ButtonSegment(
                          value: 3,
                          label: Text('Settings'),
                          icon: Icon(Icons.settings_rounded),
                        ),
                      ],
                      selected: {startPage},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        ref.read(startPageProvider.notifier).set(selection.first);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 2: Visual Theme
          _SettingsSectionCard(
            title: 'Visual Theme',
            icon: Icons.contrast_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.brightness_4_rounded, size: 20, color: scheme.onSurface),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Theme mode',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Light, dark, or follow system default',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_rounded),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded),
                        ),
                      ],
                      selected: {mode},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        ref.read(themeModeProvider.notifier).set(selection.first);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 3: In-Chat Tools
          _SettingsSectionCard(
            title: 'In-Chat Capabilities',
            icon: Icons.chat_outlined,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                secondary: Icon(
                  Icons.travel_explore_rounded,
                  size: 20,
                  color: scheme.onSurface,
                ),
                title: const Text(
                  'Web search in chat',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Fetches current real-time facts for queries. Only the search query leaves the device.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                value: webSearchEnabled,
                onChanged: (value) {
                  unawaited(ref.read(webSearchEnabledProvider.notifier).set(value));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. HARDWARE & ACCELERATION SETTINGS SUB-PAGE
// ══════════════════════════════════════════════════════════════════════════════

class HardwareSettingsPage extends ConsumerWidget {
  const HardwareSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final deviceProfile = ref.watch(deviceProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware & Acceleration'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // Section 1: GPU Acceleration
          const _SettingsSectionCard(
            title: 'GPU Acceleration',
            icon: Icons.speed_rounded,
            children: [
              GpuSettingsCard(embedded: true),
            ],
          ),
          const SizedBox(height: 16),

          // Section 2: Performance & Diagnostics
          _SettingsSectionCard(
            title: 'Performance & Diagnostics',
            icon: Icons.query_stats_rounded,
            children: [
              _SettingsTile(
                icon: Icons.speed_rounded,
                title: 'Benchmark device',
                subtitle: 'Measure prompt evaluation and token generation speed',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BenchmarkPage()),
                  );
                },
              ),
              if (deviceProfile != null) ...[
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.developer_board_rounded,
                  title: 'Device hardware specs',
                  subtitle: 'Detected processor cores and total system memory',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deviceProfile.totalRamBytes != null
                          ? '${deviceProfile.cores} Cores • ${(deviceProfile.totalRamBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB RAM'
                          : '${deviceProfile.cores} CPU Cores',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  onTap: null,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. MODEL & STORAGE SETTINGS SUB-PAGE
// ══════════════════════════════════════════════════════════════════════════════

class ModelStorageSettingsPage extends ConsumerStatefulWidget {
  const ModelStorageSettingsPage({super.key});

  @override
  ConsumerState<ModelStorageSettingsPage> createState() =>
      _ModelStorageSettingsPageState();
}

class _ModelStorageSettingsPageState
    extends ConsumerState<ModelStorageSettingsPage> {
  bool _busy = false;

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _importModel() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final imported = await ref.read(modelImporterProvider).pickAndImport();
      ref.read(modelsRefreshProvider.notifier).state++;
      if (!mounted) return;
      if (imported != null) {
        _toast('Imported ${imported.displayName}');
      }
    } catch (e) {
      if (mounted) _toast('Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadByUrl() async {
    if (_busy) return;
    final spec = await showDialog<_DownloadSpec>(
      context: context,
      builder: (_) => const _DownloadDialog(),
    );
    if (spec == null) return;

    setState(() => _busy = true);
    try {
      final handle = await ref
          .read(modelDownloaderProvider)
          .start(
            spec.url,
            filename: spec.filename.isEmpty ? null : spec.filename,
            displayName: spec.filename.isEmpty ? null : spec.filename,
          );
      _toast('Download started');

      unawaited(
        handle.progress.firstWhere((p) => p.done).then((progress) {
          if (!mounted) return;
          ref.read(modelsRefreshProvider.notifier).state++;
          if (progress.error != null) {
            _toast('Download failed: ${progress.error}');
            return;
          }
          _toast('Download complete');
        }),
      );
    } catch (e) {
      if (mounted) _toast('Download failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearAllDownloads() async {
    if (_busy) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear all downloads?'),
        content: const Text(
          'This removes all downloaded or partial model files inside the app to free up device storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final removed = await ref.read(modelStoreProvider).clearAllDownloads();
      ref.read(modelsRefreshProvider.notifier).state++;
      await ref.read(activeModelIdProvider.notifier).set(null);
      if (!mounted) return;
      _toast(
        removed == 0
            ? 'No downloaded items found'
            : 'Cleared $removed downloaded item${removed == 1 ? '' : 's'}',
      );
    } catch (e) {
      if (mounted) _toast('Clear failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final models = ref.watch(modelListProvider).valueOrNull ?? const [];
    final activeId = ref.watch(activeModelIdProvider);
    final activeModel = models.where((m) => m.id == activeId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Model & Storage'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // Section 1: Active Model
          _SettingsSectionCard(
            title: 'Active Model Configuration',
            icon: Icons.auto_awesome_rounded,
            children: [
              if (activeModel != null)
                _SettingsTile(
                  icon: Icons.tune_rounded,
                  title: activeModel.displayName,
                  subtitle: 'Configure context window size and sampling temperature',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2CA048).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, size: 14, color: Color(0xFF2CA048)),
                        SizedBox(width: 4),
                        Text(
                          'Tune',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2CA048),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () => showModelSettingsSheet(context, activeModel),
                )
              else
                _SettingsTile(
                  icon: Icons.tune_rounded,
                  title: 'No active model loaded',
                  subtitle: 'Select or download a model to begin chatting',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Catalog',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    ref.read(shellTabIndexProvider.notifier).state = 1;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 2: Storage & Imports
          _SettingsSectionCard(
            title: 'Storage & Imports',
            icon: Icons.folder_zip_outlined,
            children: [
              _SettingsTile(
                icon: Icons.file_upload_outlined,
                title: 'Import local .gguf',
                subtitle: 'Load a quantized model file from device storage',
                onTap: _busy ? null : _importModel,
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.link_rounded,
                title: 'Download model from URL',
                subtitle: 'Fetch directly via Hugging Face or direct HTTP link',
                onTap: _busy ? null : _downloadByUrl,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 3: Storage Maintenance
          _SettingsSectionCard(
            title: 'Storage Maintenance',
            icon: Icons.cleaning_services_rounded,
            children: [
              _SettingsTile(
                icon: Icons.delete_outline_rounded,
                title: 'Clear downloaded models',
                subtitle: 'Remove cached and downloaded model files to free space',
                danger: true,
                onTap: _busy ? null : _clearAllDownloads,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. LOCAL SERVER & API SETTINGS SUB-PAGE
// ══════════════════════════════════════════════════════════════════════════════

class LocalServerSettingsPage extends ConsumerWidget {
  const LocalServerSettingsPage({super.key});

  Future<void> _showPortDialog(BuildContext context, WidgetRef ref) async {
    final currentPort = await ref.read(savedServerPortProvider.future);
    if (!context.mounted) return;
    final controller = TextEditingController(text: '$currentPort');
    final newPort = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Change Server Port'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Port number',
            hintText: '11434',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0 && val <= 65535) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newPort != null && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('server_port', newPort);
      ref.invalidate(savedServerPortProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server port set to $newPort'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final lanShare = ref.watch(lanShareProvider);
    final serverStatus = ref.watch(serverControllerProvider);
    final serverPort = ref.watch(savedServerPortProvider).valueOrNull ?? 11434;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Server & API'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // Section 1: Network & Connectivity
          _SettingsSectionCard(
            title: 'Network & Connectivity',
            icon: Icons.network_check_rounded,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                secondary: Icon(
                  Icons.wifi_tethering_rounded,
                  size: 20,
                  color: scheme.onSurface,
                ),
                title: const Text(
                  'Share API over Wi-Fi / LAN',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Allows laptops and apps on the local network to query Thinai API.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                value: lanShare,
                onChanged: (val) async {
                  await ref.read(lanShareProvider.notifier).set(val);
                },
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.lan_rounded,
                title: 'Server port',
                subtitle: 'HTTP port for OpenAI & Ollama compatible endpoints',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ':$serverPort',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_rounded, size: 14, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
                onTap: () => _showPortDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 2: Service Status
          _SettingsSectionCard(
            title: 'Service Status',
            icon: Icons.info_outline_rounded,
            children: [
              _SettingsTile(
                icon: Icons.power_settings_new_rounded,
                title: 'Server status',
                subtitle: serverStatus.running
                    ? 'Running at http://${serverStatus.lan && serverStatus.lanIp != null ? serverStatus.lanIp : "localhost"}:${serverStatus.port}'
                    : 'Offline (Tap to open Server tab)',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: serverStatus.running
                        ? const Color(0xFF2CA048).withValues(alpha: 0.15)
                        : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: serverStatus.running
                              ? const Color(0xFF2CA048)
                              : scheme.outline,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        serverStatus.running ? 'Active' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: serverStatus.running
                              ? const Color(0xFF2CA048)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  ref.read(shellTabIndexProvider.notifier).state = 2;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 5. ABOUT & GUIDANCE SETTINGS SUB-PAGE
// ══════════════════════════════════════════════════════════════════════════════

class AboutGuidanceSettingsPage extends ConsumerStatefulWidget {
  const AboutGuidanceSettingsPage({super.key});

  @override
  ConsumerState<AboutGuidanceSettingsPage> createState() =>
      _AboutGuidanceSettingsPageState();
}

class _AboutGuidanceSettingsPageState
    extends ConsumerState<AboutGuidanceSettingsPage> {
  bool _busy = false;

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    if (_busy) return;
    setState(() => _busy = true);
    final updater = ref.read(appUpdaterProvider);
    final status = await updater.check();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (status.state) {
      case UpdateState.upToDate:
        _toast('Thinai is up to date');
      case UpdateState.unavailable:
        _toast('Play Store could not check for updates');
      case UpdateState.downloading:
        _toast('An update is already downloading');
      case UpdateState.readyToInstall:
        await _promptInstall(updater);
      case UpdateState.available:
        await _downloadUpdate(updater);
    }
  }

  Future<void> _downloadUpdate(AppUpdater updater) async {
    _toast('Downloading update in the background');
    final result = await updater.download();
    if (!mounted) return;
    switch (result) {
      case AppUpdateResult.success:
        await _promptInstall(updater);
      case AppUpdateResult.userDeniedUpdate:
        break;
      case AppUpdateResult.inAppUpdateFailed:
        _toast('Update failed. Try again from Play Store.');
    }
  }

  Future<void> _promptInstall(AppUpdater updater) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update ready'),
        content: const Text(
          'The new version is downloaded. Thinai restarts to install it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (go == true) await updater.install();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final version = ref.watch(appVersionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Guidance'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // Section 1: Guidance
          _SettingsSectionCard(
            title: 'Interactive Guidance',
            icon: Icons.explore_outlined,
            children: [
              _SettingsTile(
                icon: Icons.explore_outlined,
                title: 'Start app tour',
                subtitle: 'Launch interactive step-by-step feature walkthrough',
                onTap: () {
                  ref.read(coachTourRequestProvider.notifier).state++;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 2: App Information
          _SettingsSectionCard(
            title: 'App Information',
            icon: Icons.apps_rounded,
            children: [
              _SettingsTile(
                icon: Icons.system_update_alt_rounded,
                title: 'Check for updates',
                subtitle: version == null
                    ? 'Check Play Store for newest build'
                    : 'Installed version: $version',
                trailing: version != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'v$version',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : null,
                onTap: _busy ? null : _checkForUpdates,
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Contact support',
                subtitle: 'Get help or share feedback with creators',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ContactSupportPage(),
                    ),
                  );
                },
              ),
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About Thinai',
                subtitle: 'Mission, sovereignty, and project details',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const MadeInErode(compact: true),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED UI HELPER COMPONENTS
// ══════════════════════════════════════════════════════════════════════════════

class _SettingsSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
          child: Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF2CA048)),
              const SizedBox(width: 7),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF2CA048),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 1,
      color: scheme.outlineVariant.withValues(alpha: 0.35),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = danger ? scheme.error : scheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: danger
              ? scheme.error.withValues(alpha: 0.12)
              : scheme.surfaceContainerHigh.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 19,
          color: danger ? scheme.error : scheme.onSurface,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: fg,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                )
              : null),
      onTap: onTap,
    );
  }
}

class _DownloadSpec {
  const _DownloadSpec(this.url, this.filename);

  final String url;
  final String filename;
}

class _DownloadDialog extends StatefulWidget {
  const _DownloadDialog();

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  final _url = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Download model by URL'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _url,
            decoration: const InputDecoration(
              labelText: 'Direct GGUF URL',
              hintText: 'https://huggingface.co/.../model.gguf',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Save as (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final url = _url.text.trim();
            if (url.isEmpty) return;
            Navigator.pop(context, _DownloadSpec(url, _name.text.trim()));
          },
          child: const Text('Download'),
        ),
      ],
    );
  }
}
