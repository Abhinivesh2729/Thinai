/// Active model and its settings, import, download by URL, clear downloads,
/// and where the model files live on disk.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/l10n.dart';
import '../../../models_repo/model_store.dart';
import '../../../state/providers.dart';
import '../../../ui/widgets/model_settings_sheet.dart';
import '../../l10n/desk_l10n.dart';
import '../../l10n/settings_strings.dart';
import '../../shell/desk_nav.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import '../../widgets/toast.dart';
import 'settings_widgets.dart';

/// The phone's model settings sheet, in a dialog sized for a desktop window.
Future<void> showDeskModelSettings(BuildContext context, LocalModel model) {
  final s = SettingsStrings.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, right: 8),
              child: ModelSettingsSheet(model: model),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: DeskIconButton(
                icon: Icons.close_rounded,
                tooltip: s.close,
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ModelsSection extends ConsumerStatefulWidget {
  const ModelsSection({super.key});

  @override
  ConsumerState<ModelsSection> createState() => _ModelsSectionState();
}

class _ModelsSectionState extends ConsumerState<ModelsSection> {
  bool _importing = false;
  bool _starting = false;
  bool _clearing = false;
  String? _folder;

  bool get _busy => _importing || _starting || _clearing;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(modelStoreProvider).modelsDir().then((dir) {
        if (mounted) setState(() => _folder = dir.path);
      }),
    );
  }

  Future<void> _import() async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() => _importing = true);
    try {
      final imported = await ref.read(modelImporterProvider).pickAndImport();
      ref.read(modelsRefreshProvider.notifier).state++;
      if (imported != null) {
        showDeskToast(
          l10n.settingsImported(imported.displayName),
          tone: DeskTone.success,
        );
      }
    } catch (e) {
      showDeskToast(l10n.settingsImportFailed('$e'), tone: DeskTone.error);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _downloadByUrl() async {
    if (_busy) return;
    final l10n = context.l10n;
    final spec = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _UrlDialog(),
    );
    if (spec == null || !mounted) return;
    final (url, name) = spec;

    setState(() => _starting = true);
    try {
      final handle = await ref
          .read(modelDownloaderProvider)
          .start(
            url,
            filename: name.isEmpty ? null : name,
            displayName: name.isEmpty ? null : name,
          );
      showDeskToast(l10n.settingsDownloadStarted);
      // Toasts need no context, so the outcome is reported even if the user
      // has moved to another page by the time it lands.
      unawaited(
        handle.progress.firstWhere((p) => p.done).then((p) {
          ref.read(modelsRefreshProvider.notifier).state++;
          if (p.error != null) {
            showDeskToast(
              p.received > 0
                  ? l10n.settingsDownloadStopped('${p.error}')
                  : l10n.settingsDownloadFailed('${p.error}'),
              tone: DeskTone.error,
            );
          } else {
            showDeskToast(
              l10n.settingsDownloadComplete,
              tone: DeskTone.success,
            );
          }
        }),
      );
    } catch (e) {
      showDeskToast(l10n.settingsDownloadFailed('$e'), tone: DeskTone.error);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _clear() async {
    if (_busy) return;
    final l10n = context.l10n;
    final s = SettingsStrings.of(context);
    final ok = await confirmDanger(
      context,
      title: l10n.settingsClearDownloadsTitle,
      body: s.clearBody,
      confirm: l10n.commonDelete,
      cancel: l10n.commonCancel,
    );
    if (!ok || !mounted) return;

    setState(() => _clearing = true);
    try {
      final removed = await ref.read(modelStoreProvider).clearAllDownloads();
      ref.read(modelsRefreshProvider.notifier).state++;
      await ref.read(activeModelIdProvider.notifier).set(null);
      showDeskToast(
        removed == 0
            ? l10n.settingsNoDownloadsFound
            : l10n.settingsClearedDownloads(removed),
        tone: removed == 0 ? DeskTone.info : DeskTone.success,
      );
    } catch (e) {
      showDeskToast(l10n.settingsClearFailed('$e'), tone: DeskTone.error);
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _openFolder() async {
    final path = _folder;
    if (path == null) return;
    final failed = SettingsStrings.of(context).folderOpenFailed;
    try {
      if (!await launchUrl(Uri.file(path))) {
        showDeskToast(failed, tone: DeskTone.error);
      }
    } catch (_) {
      showDeskToast(failed, tone: DeskTone.error);
    }
  }

  void _goTo(DeskPage page) => ref.read(deskPageProvider.notifier).state = page;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = SettingsStrings.of(context);
    final shell = ShellStrings.of(context);
    final models = ref.watch(modelListProvider).valueOrNull ?? const [];
    final activeId = ref.watch(activeModelIdProvider);
    final active = models.where((m) => m.id == activeId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActiveModelCard(
          model: active,
          onSettings: active == null
              ? null
              : () => showDeskModelSettings(context, active),
          onManage: () => _goTo(DeskPage.models),
        ),
        const SizedBox(height: 14),
        SettingsCard(
          children: [
            SettingsRow(
              icon: Icons.file_upload_outlined,
              title: l10n.settingsImportGguf,
              subtitle: _importing ? s.importing : s.importHint,
              trailing: DeskButton(
                label: s.chooseFile,
                icon: Icons.folder_open_rounded,
                busy: _importing,
                onPressed: _busy ? null : _import,
              ),
            ),
            SettingsRow(
              icon: Icons.link_rounded,
              title: l10n.settingsDownloadFromUrl,
              subtitle: s.urlHint,
              trailing: DeskButton(
                label: l10n.commonDownload,
                icon: Icons.download_rounded,
                busy: _starting,
                onPressed: _busy ? null : _downloadByUrl,
              ),
            ),
            SettingsRow(
              icon: Icons.folder_outlined,
              title: s.modelsFolder,
              below: _PathBox(path: _folder),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DeskIconButton(
                    icon: Icons.copy_rounded,
                    tooltip: s.copyPath,
                    onPressed: _folder == null
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: _folder!));
                            showDeskToast(s.pathCopied, tone: DeskTone.success);
                          },
                  ),
                  const SizedBox(width: 6),
                  DeskButton(
                    label: s.openFolder,
                    icon: Icons.open_in_new_rounded,
                    onPressed: _folder == null ? null : _openFolder,
                  ),
                ],
              ),
            ),
            SettingsRow(
              icon: Icons.delete_outline_rounded,
              title: l10n.settingsClearDownloadedModels,
              subtitle: s.clearHint,
              trailing: DeskButton(
                label: s.clear,
                kind: DeskButtonKind.danger,
                busy: _clearing,
                onPressed: _busy ? null : _clear,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: DeskButton(
              label: shell.manageModels,
              icon: Icons.arrow_forward_rounded,
              kind: DeskButtonKind.ghost,
              onPressed: () => _goTo(DeskPage.models),
            ),
          ),
        ),
      ],
    );
  }
}

/// The loaded model as a small hero: name, size, id, and its settings.
class _ActiveModelCard extends StatelessWidget {
  const _ActiveModelCard({
    required this.model,
    required this.onSettings,
    required this.onManage,
  });

  final LocalModel? model;
  final VoidCallback? onSettings;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = SettingsStrings.of(context);
    final shell = ShellStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final m = model;

    return AnimatedContainer(
      duration: DeskMotion.medium,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DeskSize.radiusL),
        border: Border.all(
          color: m == null
              ? palette.hairline
              : DeskColors.green.withValues(alpha: 0.3),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            m == null
                ? palette.panel
                : DeskColors.green.withValues(
                    alpha: palette.isDark ? 0.10 : 0.07,
                  ),
            palette.panel,
          ],
        ),
      ),
      child: AnimatedSwitcher(
        duration: DeskMotion.medium,
        child: Row(
          key: ValueKey(m?.id),
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: m == null
                    ? scheme.onSurface.withValues(alpha: 0.06)
                    : DeskColors.green.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(DeskSize.radiusM),
              ),
              child: Icon(
                m == null
                    ? Icons.view_in_ar_outlined
                    : Icons.view_in_ar_rounded,
                size: 22,
                color: m == null ? palette.textMuted : DeskColors.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.activeModel,
                    style: TextStyle(fontSize: 11.5, color: palette.textFaint),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m?.displayName ?? l10n.settingsNoActiveModel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m == null ? s.noModelHint : '${m.sizeFormatted} · ${m.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: palette.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (m != null)
              DeskButton(
                label: shell.modelSettings,
                icon: Icons.tune_rounded,
                kind: DeskButtonKind.primary,
                onPressed: onSettings,
              )
            else
              DeskButton(
                label: s.browseModels,
                icon: Icons.arrow_forward_rounded,
                kind: DeskButtonKind.primary,
                onPressed: onManage,
              ),
          ],
        ),
      ),
    );
  }
}

/// The models folder path, selectable, in a monospace well.
class _PathBox extends StatelessWidget {
  const _PathBox({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return Hoverable(
      builder: (context, hovered) => AnimatedContainer(
        duration: DeskMotion.fast,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: palette.codeBg,
          borderRadius: BorderRadius.circular(DeskSize.radiusS + 2),
          border: Border.all(
            color: hovered
                ? DeskColors.green.withValues(alpha: 0.3)
                : palette.hairline,
          ),
        ),
        child: SelectableText(
          path ?? '…',
          maxLines: 2,
          style: TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Consolas', 'Menlo', 'Courier New'],
            fontSize: 12,
            color: palette.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Asks for a direct .gguf URL and an optional file name.
class _UrlDialog extends StatefulWidget {
  const _UrlDialog();

  @override
  State<_UrlDialog> createState() => _UrlDialogState();
}

class _UrlDialogState extends State<_UrlDialog> {
  final _url = TextEditingController();
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _url.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _valid {
    final uri = Uri.tryParse(_url.text.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  void _submit() {
    if (!_valid) return;
    Navigator.pop(context, (_url.text.trim(), _name.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = SettingsStrings.of(context);
    return AlertDialog(
      titleTextStyle: deskDialogTitle(context),
      title: Text(l10n.settingsDownloadFromUrl),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.urlHint,
              style: TextStyle(
                fontSize: 12.5,
                color: DeskPalette.of(context).textMuted,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _url,
              autofocus: true,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.settingsDirectGgufUrl,
                hintText: 'https://huggingface.co/.../model.gguf',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.settingsSaveAsOptional,
              ),
            ),
          ],
        ),
      ),
      actions: [
        DeskButton(
          label: l10n.commonCancel,
          kind: DeskButtonKind.ghost,
          onPressed: () => Navigator.pop(context),
        ),
        DeskButton(
          label: l10n.commonDownload,
          icon: Icons.download_rounded,
          kind: DeskButtonKind.primary,
          onPressed: _valid ? _submit : null,
        ),
      ],
    );
  }
}
