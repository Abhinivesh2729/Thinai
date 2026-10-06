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
          'This removes all downloaded or partial model files inside the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
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

  /// Manual counterpart to the launch-time check in the shell. Same Play API,
  /// but this one always says something back — a check that answers nothing
  /// reads as broken.
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
        // Debug and sideloaded builds land here too: Play only serves updates
        // to installs it made itself.
        _toast('Play Store could not check for updates');
      case UpdateState.downloading:
        _toast('An update is already downloading');
      case UpdateState.readyToInstall:
        await _promptInstall(updater);
      case UpdateState.available:
        await _downloadUpdate(updater);
    }
  }

  /// Play puts up its own consent sheet, then downloads while the app stays
  /// usable. [_busy] is already cleared: this can take minutes and there is no
  /// reason to lock Settings for it.
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
    final version = ref.watch(appVersionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.alphaBlend(scheme.primaryContainer, scheme.surface),
                  Color.alphaBlend(scheme.tertiaryContainer, scheme.surface),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              'Thinai tools and app controls in one place.',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _ThemeModeCard(),
          const _WebSearchCard(),
          const GpuSettingsCard(),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.folder_open_rounded,
            title: 'Import .gguf model',
            subtitle: 'Pick a local model file from device storage',
            onTap: _busy ? null : _importModel,
          ),
          _SettingsTile(
            icon: Icons.link_rounded,
            title: 'Download model by URL',
            subtitle: 'Add a direct model URL and download',
            onTap: _busy ? null : _downloadByUrl,
          ),
          _SettingsTile(
            icon: Icons.speed_rounded,
            title: 'Benchmark this phone',
            subtitle: 'Measure tokens per second for any installed model',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BenchmarkPage()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.tips_and_updates_rounded,
            title: 'Start app tour',
            subtitle: 'Run spotlight coach marks again',
            onTap: () {
              ref.read(coachTourRequestProvider.notifier).state++;
              Navigator.pop(context);
            },
          ),
          _SettingsTile(
            icon: Icons.delete_sweep_rounded,
            title: 'Clear all downloaded items',
            subtitle: 'Remove all downloaded and partial model files',
            danger: true,
            onTap: _busy ? null : _clearAllDownloads,
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.system_update_rounded,
            title: 'Check for updates',
            subtitle: version == null
                ? 'Get the newest Thinai from Play Store'
                : 'You are on $version',
            onTap: _busy ? null : _checkForUpdates,
          ),
          _SettingsTile(
            icon: Icons.support_agent_rounded,
            title: 'Contact support',
            subtitle: 'Get help and connect with the team',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactSupportPage()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About Thinai',
            subtitle: 'Mission, capabilities, and design intent',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AboutPage()));
            },
          ),
          const SizedBox(height: 18),
          const MadeInErode(compact: true),
        ],
      ),
    );
  }
}

class _ThemeModeCard extends ConsumerWidget {
  const _ThemeModeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final mode = ref.watch(themeModeProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.brightness_6_rounded, color: scheme.onSurface),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Light, dark, or follow the system',
                        style: TextStyle(color: scheme.onSurfaceVariant),
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
    );
  }
}

/// The same switch the composer's globe toggles, kept here too because this is
/// where someone looks when they want to know what the app sends out — and the
/// subtitle is the answer, not just the label of a switch.
class _WebSearchCard extends ConsumerWidget {
  const _WebSearchCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = ref.watch(webSearchEnabledProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        secondary: Icon(Icons.travel_explore_rounded, color: scheme.onSurface),
        title: Text(
          'Web search in chat',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Looks up current info automatically. Only the question leaves '
          'the phone.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        value: enabled,
        onChanged: (value) {
          unawaited(ref.read(webSearchEnabledProvider.notifier).set(value));
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = danger ? scheme.error : scheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(icon, color: fg),
        title: Text(
          title,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
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
      title: const Text('Download model by URL'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _url,
            decoration: const InputDecoration(
              labelText: 'Direct URL',
              hintText: 'https://.../model.gguf',
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
