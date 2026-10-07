import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../update/app_updater.dart';
import '../widgets/gpu_settings_card.dart';
import '../widgets/made_in_erode.dart';
import 'about_page.dart';
import 'benchmark_page.dart';
import 'contact_support_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _busy = false;

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
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
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

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mode = ref.watch(themeModeProvider);
    final webSearchEnabled = ref.watch(webSearchEnabledProvider);
    final version = ref.watch(appVersionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // 1. Sovereign On-Device Privacy Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2CA048).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 20,
                    color: Color(0xFF2CA048),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '100% Offline & Private',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'All inference executes locally on device silicon. No cloud telemetry or accounts.',
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
          const SizedBox(height: 8),

          // 2. APPEARANCE & CHAT SECTION
          _SettingsGroup(
            title: 'APPEARANCE & CHAT',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, size: 20, color: scheme.onSurface),
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
                    const SizedBox(height: 12),
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
              const _TileDivider(),
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
                  'Fetches current facts when answering questions. Only the search query leaves the device.',
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

          // 3. HARDWARE & ACCELERATION SECTION
          _SettingsGroup(
            title: 'HARDWARE & ACCELERATION',
            children: [
              const GpuSettingsCard(),
              const _TileDivider(),
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
            ],
          ),

          // 4. MODEL MANAGEMENT SECTION
          _SettingsGroup(
            title: 'MODEL STORAGE & MANAGEMENT',
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
              const _TileDivider(),
              _SettingsTile(
                icon: Icons.delete_outline_rounded,
                title: 'Clear downloaded models',
                subtitle: 'Remove cached and downloaded model files to free space',
                danger: true,
                onTap: _busy ? null : _clearAllDownloads,
              ),
            ],
          ),

          // 5. ABOUT & GUIDANCE SECTION
          _SettingsGroup(
            title: 'ABOUT & GUIDANCE',
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
              const _TileDivider(),
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

          const SizedBox(height: 10),
          const MadeInErode(compact: true),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF2CA048),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        icon,
        size: 20,
        color: danger ? scheme.error : scheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: fg,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
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
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
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
