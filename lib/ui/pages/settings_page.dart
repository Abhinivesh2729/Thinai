import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
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
import 'system_prompt_page.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MAIN SETTINGS HUB PAGE (Apple-Inspired AI Cards Experience)
// ══════════════════════════════════════════════════════════════════════════════

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.navSettings,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        children: [
          // Ruled Settings List Group (Full-width, clean hairline rules, no card borders)
          Container(
            width: double.infinity,
            color: Colors.transparent,
            child: Column(
              children: [
                _SectionNavTile(
                  icon: Icons.palette_rounded,
                  title: context.l10n.settingsAppearance,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AppearanceSettingsPage(),
                      ),
                    );
                  },
                ),
                const _TileDivider(),
                _SectionNavTile(
                  icon: Icons.edit_note_rounded,
                  title: context.l10n.settingsSystemPrompt,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SystemPromptPage(),
                      ),
                    );
                  },
                ),
                const _TileDivider(),
                _SectionNavTile(
                  icon: Icons.memory_rounded,
                  title: context.l10n.settingsHardware,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HardwareSettingsPage(),
                      ),
                    );
                  },
                ),
                const _TileDivider(),
                _SectionNavTile(
                  icon: Icons.tune_rounded,
                  title: context.l10n.settingsModelStorage,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ModelStorageSettingsPage(),
                      ),
                    );
                  },
                ),
                const _TileDivider(),
                _SectionNavTile(
                  icon: Icons.dns_rounded,
                  title: context.l10n.settingsLocalServer,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LocalServerSettingsPage(),
                      ),
                    );
                  },
                ),
                const _TileDivider(),
                _SectionNavTile(
                  icon: Icons.info_rounded,
                  title: context.l10n.settingsAboutGuidance,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AboutGuidanceSettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const MadeInErode(compact: true),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION NAVIGATION TILE (Green Icon Only, No Tags/Badges)
// ══════════════════════════════════════════════════════════════════════════════

class _SectionNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SectionNavTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF2CA048).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Icon(icon, size: 20, color: const Color(0xFF2CA048)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 1. APPEARANCE SETTINGS SUB-PAGE (Simple List, Dropdowns on Right, No Subtitles)
// ══════════════════════════════════════════════════════════════════════════════

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startPage = ref.watch(startPageProvider);
    final mode = ref.watch(themeModeProvider);
    final webSearchEnabled = ref.watch(webSearchEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsAppearance)),
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          Container(
            width: double.infinity,
            color: Colors.transparent,
            child: Column(
              children: [
                _DropdownListRow<int>(
                  icon: Icons.start_rounded,
                  title: context.l10n.settingsStartPage,
                  value: startPage,
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(
                        context.l10n.navChat,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Text(
                        context.l10n.navModels,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(
                        context.l10n.navServer,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text(
                        context.l10n.navSettings,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(startPageProvider.notifier).set(val);
                    }
                  },
                ),
                const _TileDivider(),
                _DropdownListRow<AppLanguage>(
                  icon: Icons.translate_rounded,
                  title: context.l10n.languageSetting,
                  value: ref.watch(appLanguageProvider),
                  items: [
                    for (final (language, label) in [
                      (AppLanguage.system, context.l10n.languageSystem),
                      (AppLanguage.english, context.l10n.languageEnglish),
                      (AppLanguage.tamil, context.l10n.languageTamil),
                    ])
                      DropdownMenuItem(
                        value: language,
                        child: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(appLanguageProvider.notifier).set(val);
                    }
                  },
                ),
                const _TileDivider(),
                _DropdownListRow<ThemeMode>(
                  icon: Icons.brightness_4_rounded,
                  title: context.l10n.settingsThemeMode,
                  value: mode,
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(
                        context.l10n.settingsThemeSystem,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(
                        context.l10n.settingsThemeDark,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(
                        context.l10n.settingsThemeLight,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(themeModeProvider.notifier).set(val);
                    }
                  },
                ),
                const _TileDivider(),
                _DropdownListRow<bool>(
                  icon: Icons.travel_explore_rounded,
                  title: context.l10n.settingsWebSearch,
                  value: webSearchEnabled,
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text(
                        context.l10n.settingsEnabled,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text(
                        context.l10n.settingsDisabled,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      unawaited(
                        ref.read(webSearchEnabledProvider.notifier).set(val),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DROPDOWN LIST ROW HELPER (Compact, Green Icon, Dropdown on Right)
// ══════════════════════════════════════════════════════════════════════════════

class _DropdownListRow<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownListRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2CA048).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: const Color(0xFF2CA048)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161C26) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF273244)
                    : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isDense: true,
                elevation: 3,
                icon: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                    size: 16,
                  ),
                ),
                dropdownColor: isDark ? const Color(0xFF161C26) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. HARDWARE & ACCELERATION SETTINGS SUB-PAGE
// ══════════════════════════════════════════════════════════════════════════════

class HardwareSettingsPage extends ConsumerStatefulWidget {
  const HardwareSettingsPage({super.key});

  @override
  ConsumerState<HardwareSettingsPage> createState() =>
      _HardwareSettingsPageState();
}

class _HardwareSettingsPageState extends ConsumerState<HardwareSettingsPage> {
  StreamSubscription<GenerationSettings>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = GenerationSettingsStore.instance.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final deviceProfile = ref.watch(deviceProfileProvider).valueOrNull;
    final currentGpu = GenerationSettingsStore.instance.settings.gpu;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsHardware)),
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          Container(
            width: double.infinity,
            color: Colors.transparent,
            child: Column(
              children: [
                _DropdownListRow<GpuBackend>(
                  icon: Icons.memory_rounded,
                  title: context.l10n.settingsGpuAcceleration,
                  value: currentGpu,
                  items: [
                    DropdownMenuItem(
                      value: GpuBackend.none,
                      child: const Text(
                        'CPU',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem(
                      value: GpuBackend.auto,
                      child: Text(
                        context.l10n.settingsGpuAuto,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem(
                      value: GpuBackend.vulkan,
                      child: const Text(
                        'Vulkan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem(
                      value: GpuBackend.opencl,
                      child: const Text(
                        'OpenCL',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      unawaited(GenerationSettingsStore.instance.setGpu(val));
                    }
                  },
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.speed_rounded,
                  title: context.l10n.settingsBenchmarkDevice,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BenchmarkPage()),
                    );
                  },
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.query_stats_rounded,
                  title: context.l10n.settingsGpuDiagnostics,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: isDark
                          ? const Color(0xFF131722)
                          : Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => const SafeArea(
                        child: SingleChildScrollView(
                          child: GpuSettingsCard(embedded: true),
                        ),
                      ),
                    );
                  },
                ),
                if (deviceProfile != null) ...[
                  const _TileDivider(),
                  _SettingsTile(
                    icon: Icons.developer_board_rounded,
                    title: context.l10n.settingsDeviceSpecs,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.045),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        deviceProfile.totalRamBytes != null
                            ? context.l10n.settingsDeviceSpecsWithRam(
                                deviceProfile.cores,
                                (deviceProfile.totalRamBytes! /
                                        (1024 * 1024 * 1024))
                                    .toStringAsFixed(1),
                              )
                            : context.l10n.settingsDeviceSpecsCores(
                                deviceProfile.cores,
                              ),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    onTap: null,
                  ),
                ],
              ],
            ),
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
        _toast(context.l10n.settingsImported(imported.displayName));
      }
    } catch (e) {
      if (mounted) _toast(context.l10n.settingsImportFailed('$e'));
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
      if (!mounted) return;
      _toast(context.l10n.settingsDownloadStarted);

      unawaited(
        handle.progress.firstWhere((p) => p.done).then((progress) {
          if (!mounted) return;
          ref.read(modelsRefreshProvider.notifier).state++;
          if (progress.error != null) {
            _toast(
              progress.received > 0
                  ? context.l10n.settingsDownloadStopped('${progress.error}')
                  : context.l10n.settingsDownloadFailed('${progress.error}'),
            );
            return;
          }
          _toast(context.l10n.settingsDownloadComplete);
        }),
      );
    } catch (e) {
      if (mounted) _toast(context.l10n.settingsDownloadFailed('$e'));
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
        title: Text(context.l10n.settingsClearDownloadsTitle),
        content: Text(context.l10n.settingsClearDownloadsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.settingsClearAll),
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
            ? context.l10n.settingsNoDownloadsFound
            : context.l10n.settingsClearedDownloads(removed),
      );
    } catch (e) {
      if (mounted) _toast(context.l10n.settingsClearFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final models = ref.watch(modelListProvider).valueOrNull ?? const [];
    final activeId = ref.watch(activeModelIdProvider);
    final activeModel = models.where((m) => m.id == activeId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsModelStorage)),
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          Container(
            width: double.infinity,
            color: Colors.transparent,
            child: Column(
              children: [
                if (activeModel != null)
                  _SettingsTile(
                    icon: Icons.tune_rounded,
                    title: activeModel.displayName,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2CA048).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: Color(0xFF2CA048),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.settingsTune,
                            style: const TextStyle(
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
                    title: context.l10n.settingsNoActiveModel,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.045),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.settingsCatalog,
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
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.file_upload_outlined,
                  title: context.l10n.settingsImportGguf,
                  onTap: _busy ? null : _importModel,
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.link_rounded,
                  title: context.l10n.settingsDownloadFromUrl,
                  onTap: _busy ? null : _downloadByUrl,
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: context.l10n.settingsClearDownloadedModels,
                  onTap: _busy ? null : _clearAllDownloads,
                ),
              ],
            ),
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
        title: Text(context.l10n.settingsChangePortTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.settingsPortNumber,
            hintText: '11434',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0 && val <= 65535) {
                Navigator.pop(ctx, val);
              }
            },
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
    if (newPort != null && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('server_port', newPort);
      ref.invalidate(savedServerPortProvider);
      if (!context.mounted) return;
      final status = ref.read(serverControllerProvider);
      final restart = status.running && status.port != newPort;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            restart
                ? context.l10n.settingsPortSetRestart(newPort)
                : context.l10n.settingsPortSet(newPort),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final lanShare = ref.watch(lanShareProvider);
    final serverStatus = ref.watch(serverControllerProvider);
    final serverPort = ref.watch(savedServerPortProvider).valueOrNull ?? 11434;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsLocalServer)),
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          Container(
            width: double.infinity,
            color: Colors.transparent,
            child: Column(
              children: [
                _DropdownListRow<bool>(
                  icon: Icons.wifi_tethering_rounded,
                  title: context.l10n.settingsShareApiWifi,
                  value: lanShare,
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text(
                        context.l10n.settingsEnabled,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text(
                        context.l10n.settingsDisabled,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await ref.read(lanShareProvider.notifier).set(val);
                    }
                  },
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.lan_rounded,
                  title: context.l10n.settingsServerPort,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.045),
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
                        Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  onTap: () => _showPortDialog(context, ref),
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.power_settings_new_rounded,
                  title: context.l10n.settingsServerStatus,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: serverStatus.running
                          ? const Color(0xFF2CA048).withValues(alpha: 0.15)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : Colors.black.withValues(alpha: 0.045)),
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
                          serverStatus.running
                              ? context.l10n.settingsServerActive
                              : context.l10n.settingsServerOffline,
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
        _toast(context.l10n.settingsUpToDate);
      case UpdateState.unavailable:
        _toast(context.l10n.settingsUpdateUnavailable);
      case UpdateState.downloading:
        _toast(context.l10n.settingsUpdateAlreadyDownloading);
      case UpdateState.readyToInstall:
        await _promptInstall(updater);
      case UpdateState.available:
        await _downloadUpdate(updater);
    }
  }

  Future<void> _downloadUpdate(AppUpdater updater) async {
    _toast(context.l10n.settingsUpdateDownloading);
    final result = await updater.download();
    if (!mounted) return;
    switch (result) {
      case AppUpdateResult.success:
        await _promptInstall(updater);
      case AppUpdateResult.userDeniedUpdate:
        break;
      case AppUpdateResult.inAppUpdateFailed:
        _toast(context.l10n.settingsUpdateFailed);
    }
  }

  Future<void> _promptInstall(AppUpdater updater) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.settingsUpdateReadyTitle),
        content: Text(context.l10n.settingsUpdateReadyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonLater),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.settingsRestart),
          ),
        ],
      ),
    );
    if (go == true) await updater.install();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final version = ref.watch(appVersionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsAboutGuidance)),
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          Container(
            width: double.infinity,
            color: Colors.transparent,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.explore_outlined,
                  title: context.l10n.settingsStartTour,
                  onTap: () {
                    ref.read(coachTourRequestProvider.notifier).state++;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.system_update_alt_rounded,
                  title: context.l10n.settingsCheckUpdates,
                  trailing: version != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : Colors.black.withValues(alpha: 0.045),
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
                  title: context.l10n.settingsContactSupport,
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
                  title: context.l10n.settingsAboutThinai,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const MadeInErode(compact: true),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED UI HELPER COMPONENTS
// ══════════════════════════════════════════════════════════════════════════════

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2CA048).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: const Color(0xFF2CA048)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        ),
      ),
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
      title: Text(context.l10n.settingsDownloadDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _url,
            decoration: InputDecoration(
              labelText: context.l10n.settingsDirectGgufUrl,
              hintText: 'https://huggingface.co/.../model.gguf',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: context.l10n.settingsSaveAsOptional,
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            final url = _url.text.trim();
            if (url.isEmpty) return;
            Navigator.pop(context, _DownloadSpec(url, _name.text.trim()));
          },
          child: Text(context.l10n.commonDownload),
        ),
      ],
    );
  }
}
