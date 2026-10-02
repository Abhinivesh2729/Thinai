import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../update/app_updater.dart';
import '../widgets/gpu_settings_card.dart';
import '../theme/app_theme.dart';
import '../widgets/made_in_erode.dart';
import '../widgets/ui_kit.dart';
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
    final confirm = await confirmAction(
      context,
      title: 'Clear all downloads?',
      message:
          'This removes all downloaded or partial model files inside the app.',
      confirmLabel: 'Clear all',
      destructive: true,
    );

    if (!confirm) return;

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
    final go = await confirmAction(
      context,
      title: 'Update ready',
      message: 'The new version is downloaded. Thinai restarts to install it.',
      confirmLabel: 'Restart',
      cancelLabel: 'Later',
    );
    if (go) await updater.install();
  }

  void _toast(String text) => showToast(context, text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final version = ref.watch(appVersionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xxxl),
        children: [
          const SectionLabel(
            'Appearance',
            padding: EdgeInsets.fromLTRB(
              Space.xs,
              Space.sm,
              Space.xs,
              Space.sm,
            ),
          ),
          const _ThemeModeCard(),
          const SettingsGroup(
            label: 'Chat',
            children: [_WebSearchRow(), _FollowUpsRow()],
          ),
          const SectionLabel('Performance'),
          const GpuSettingsCard(),
          const SizedBox(height: Space.md),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.speed_rounded,
                title: 'Benchmark this phone',
                subtitle: 'Measure tokens per second for any installed model',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BenchmarkPage()),
                  );
                },
              ),
            ],
          ),
          SettingsGroup(
            label: 'Models',
            children: [
              SettingsRow(
                icon: Icons.folder_open_rounded,
                title: 'Import .gguf model',
                subtitle: 'Pick a local model file from device storage',
                onTap: _busy ? null : _importModel,
              ),
              SettingsRow(
                icon: Icons.link_rounded,
                title: 'Download model by URL',
                subtitle: 'Add a direct model URL and download',
                onTap: _busy ? null : _downloadByUrl,
              ),
              SettingsRow(
                icon: Icons.delete_sweep_outlined,
                title: 'Clear all downloaded items',
                subtitle: 'Remove all downloaded and partial model files',
                danger: true,
                onTap: _busy ? null : _clearAllDownloads,
              ),
            ],
          ),
          SettingsGroup(
            label: 'Help',
            children: [
              SettingsRow(
                icon: Icons.tips_and_updates_outlined,
                title: 'Start app tour',
                subtitle: 'Run spotlight coach marks again',
                onTap: () {
                  ref.read(coachTourRequestProvider.notifier).state++;
                  Navigator.pop(context);
                },
              ),
              SettingsRow(
                icon: Icons.system_update_outlined,
                title: 'Check for updates',
                subtitle: version == null
                    ? 'Get the newest Thinai from Play Store'
                    : 'You are on $version',
                onTap: _busy ? null : _checkForUpdates,
              ),
              SettingsRow(
                icon: Icons.support_agent_rounded,
                title: 'Contact support',
                subtitle: 'Get help and connect with the team',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ContactSupportPage(),
                    ),
                  );
                },
              ),
              SettingsRow(
                icon: Icons.info_outline_rounded,
                title: 'About Thinai',
                subtitle: 'Mission, capabilities, and design intent',
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const AboutPage()));
                },
              ),
            ],
          ),
          const SizedBox(height: Space.xxxl),
          const MadeInErode(compact: true),
          if (version != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              'Thinai $version',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemeModeCard extends ConsumerWidget {
  const _ThemeModeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.brightness_auto_outlined, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_outlined, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_outlined, size: 18),
            ),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            ref.read(themeModeProvider.notifier).set(selection.first);
          },
        ),
      ),
    );
  }
}

/// The same switch the composer's dial toggles, kept here too because this is
/// where someone looks when they want to know what the app sends out — and the
/// subtitle is the answer, not just the label of a switch.
class _WebSearchRow extends ConsumerWidget {
  const _WebSearchRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(webSearchEnabledProvider);
    return SettingsSwitchRow(
      icon: Icons.travel_explore_rounded,
      title: 'Web search in chat',
      subtitle:
          'Looks up current info automatically. Only the question leaves '
          'the phone.',
      value: enabled,
      onChanged: (value) {
        unawaited(ref.read(webSearchEnabledProvider.notifier).set(value));
      },
    );
  }
}

/// Whether three next questions are written after each answer.
class _FollowUpsRow extends ConsumerWidget {
  const _FollowUpsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSwitchRow(
      icon: Icons.subdirectory_arrow_right_rounded,
      title: 'Suggest follow-up questions',
      subtitle:
          'Writes three questions to ask next after each answer. Uses a '
          'little extra battery.',
      value: ref.watch(followUpsEnabledProvider),
      onChanged: (value) {
        unawaited(ref.read(followUpsEnabledProvider.notifier).set(value));
      },
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
      title: const Text('Download model by URL'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Direct URL',
              hintText: 'https://…/model.gguf',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Save as (optional)'),
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
