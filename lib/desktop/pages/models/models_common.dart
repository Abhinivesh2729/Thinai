/// Helpers and user actions shared by the desktop Models page, its cards, the
/// details dialog and the Model Manager panel.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../models_repo/catalog.dart';
import '../../../models_repo/device_profile.dart';
import '../../../models_repo/model_store.dart';
import '../../../models_repo/recommender.dart';
import '../../../state/providers.dart';
import '../../l10n/models_strings.dart';
import '../../shell/desk_nav.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/toast.dart';

/// Catalog filter, as on the phone.
enum ModelFilter { all, chat, vision, embedding, installed }

const _gib = 1024 * 1024 * 1024;

String fmtSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
}

String fmtGb(int bytes) => '${(bytes / _gib).toStringAsFixed(1)} GB';

String _normalizeKey(String input) {
  var key = input.trim().toLowerCase();
  if (key.endsWith('.gguf')) key = key.substring(0, key.length - 5);
  return key;
}

/// The installed file for a catalog entry, matched the same loose way the
/// phone does (id, file name or display name), so both apps agree on what
/// counts as installed.
LocalModel? localFor(CatalogModel m, List<LocalModel> installed) {
  final keys = {
    _normalizeKey(m.id),
    _normalizeKey(m.filename),
    _normalizeKey(m.displayName),
  };
  for (final l in installed) {
    if (keys.contains(_normalizeKey(l.id)) ||
        keys.contains(_normalizeKey(l.displayName))) {
      return l;
    }
  }
  return null;
}

PartialDownload? partialFor(CatalogModel m, List<PartialDownload>? partials) {
  if (partials == null) return null;
  for (final p in partials) {
    if (p.filename == m.filename) return p;
  }
  return null;
}

/// Catalog entry for an installed file, when there is one; used to pick a
/// logo and a vendor colour for imported or Hub files too.
CatalogModel? catalogFor(LocalModel local) {
  for (final m in modelCatalog) {
    if (localFor(m, [local]) != null) return m;
  }
  return null;
}

/// The one-word capability the details dialog and chips show.
(IconData, String) capabilityTag(CatalogModel model, AppLocalizations l) {
  if (model.supportsVision) {
    return (Icons.visibility_outlined, l.modelsCapVisionReady);
  }
  if (model.kind == ModelKind.embedding) {
    return (Icons.hub_outlined, l.modelsCapEmbeddings);
  }
  final id = model.id.toLowerCase();
  final params = model.parameters.toLowerCase();
  if (['270', '350', '0.5', '0.6', '0.8'].any(params.contains)) {
    if (id.contains('lfm') || id.contains('smol')) {
      return (Icons.eco_outlined, l.modelsCapLightweight);
    }
    return (Icons.bolt_rounded, l.modelsCapFast);
  }
  if (id.contains('qwen') || id.contains('gemma-4') || id.contains('smollm3')) {
    return (Icons.public_outlined, l.modelsCapMultilingual);
  }
  if (['mistral', 'phi', 'deepseek', 'granite'].any(id.contains)) {
    return (Icons.code_rounded, l.modelsCapCodeReasoning);
  }
  return (Icons.navigation_outlined, l.modelsCapInstruct);
}

/// A soft brand tint per vendor, for the logo tile and the featured glow.
Color vendorColor(CatalogModel model) {
  final a = model.author.toLowerCase();
  final id = model.id.toLowerCase();
  bool any(String author, String idPart) =>
      a.contains(author) || id.contains(idPart);
  if (any('liquid', 'lfm')) return const Color(0xFF06B6D4);
  if (any('alibaba', 'qwen')) return const Color(0xFF8B5CF6);
  if (any('meta', 'llama')) return const Color(0xFF3B82F6);
  if (any('google', 'gemma')) return const Color(0xFF0EA5E9);
  if (any('microsoft', 'phi')) return const Color(0xFF10B981);
  if (any('ibm', 'granite')) return const Color(0xFF3B82F6);
  if (any('nvidia', 'nemotron')) return const Color(0xFF76B900);
  if (any('hugging', 'smol')) return const Color(0xFFF59E0B);
  return model.accent;
}

/// The short fit label, with the phone's "your phone" wording replaced.
String fitLabel(RamFit fit, AppLocalizations l, ModelsStrings s) =>
    switch (fit) {
      RamFit.tooBig => s.fitTooBig,
      _ => fit.localizedLabel(l),
    };

Color fitColor(RamFit fit, ColorScheme scheme) => switch (fit) {
  RamFit.comfortable => DeskColors.green,
  RamFit.tight => DeskColors.amber,
  RamFit.tooBig => DeskColors.danger,
  RamFit.unknown => scheme.onSurfaceVariant,
};

/// The full fit warning for the confirm dialog and details, or null when the
/// model fits comfortably.
String? fitWarning(CatalogModel m, DeviceProfile device, ModelsStrings s) {
  final budget = device.modelBudgetBytes;
  return switch (fitFor(m, device)) {
    RamFit.tight => s.fitTight,
    RamFit.tooBig =>
      budget == null
          ? s.fitTooLarge
          : s.fitNeeds(fmtGb(runtimeBytesFor(m)), fmtGb(budget)),
    _ => null,
  };
}

/// Download errors are worded for the phone in the shared downloader; say
/// "PC" here rather than fork the wording.
String deskError(String error) => error
    .replaceAll('on this phone', 'on this PC')
    .replaceAll('check your signal', 'check your connection');

String resumeLabel(PartialDownload p, AppLocalizations l) {
  final f = p.fraction;
  return f == null
      ? l.commonResume
      : l.modelsResumePercent((f * 100).toStringAsFixed(0));
}

DeviceProfile watchDevice(WidgetRef ref) =>
    ref.watch(deviceProfileProvider.select((a) => a.valueOrNull)) ??
    DeviceProfile.unknownProfile;

/// Asks before anything a stray click should not do. Dismissing counts as no.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final palette = DeskPalette.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: palette.textMuted,
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text(c.l10n.commonCancel),
        ),
        FilledButton(
          autofocus: true,
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? DeskColors.danger : DeskColors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// The Models page's verbs, usable from any widget that has a context under
/// the ProviderScope.
///
/// Reads through the container rather than a WidgetRef so an action that
/// outlives the widget that started it (a card scrolled away mid-confirm, a
/// dialog closed while a delete runs) still completes.
class ModelActions {
  ModelActions(this.context)
    : _c = ProviderScope.containerOf(context, listen: false),
      _l = context.l10n,
      _s = ModelsStrings.of(context);

  final BuildContext context;
  final ProviderContainer _c;
  final AppLocalizations _l;
  final ModelsStrings _s;

  void _refresh() => _c.read(modelsRefreshProvider.notifier).state++;

  Future<void> download(CatalogModel m) async {
    // A vision model fetches its image encoder too, so the size asked about
    // is what actually lands on disk.
    final encoder = m.supportsVision ? (m.mmprojBytes ?? 0) : 0;
    final size = encoder > 0 ? fmtSize(m.approxBytes + encoder) : m.approxSize;
    final device = _c.read(speedKnowledgeProvider).device;
    final warning = fitWarning(m, device, _s);
    final message = _l.modelsConfirmDownloadMessage(m.displayName, size);
    if (!context.mounted) return;
    final ok = await confirmDialog(
      context,
      title: _l.modelsConfirmDownloadTitle,
      message: warning == null ? message : '$message\n\n$warning',
      confirmLabel: _l.commonDownload,
    );
    if (!ok) return;
    await _c.read(downloadsProvider.notifier).start(m);
  }

  /// Pausing loses nothing (the part stays on disk), so it is not asked about.
  void pause(String catalogId) =>
      _c.read(downloadsProvider.notifier).cancel(catalogId);

  /// The user agreed to this download when it started; not asked again.
  Future<void> resume(CatalogModel m) =>
      _c.read(downloadsProvider.notifier).start(m);

  Future<void> resumePartial(PartialDownload p) async {
    final ok = await _c.read(downloadsProvider.notifier).resumePartial(p);
    if (!ok) {
      showDeskToast(_l.modelsToastResumeFailed(p.label), tone: DeskTone.error);
    }
  }

  Future<void> addVision(CatalogModel m) =>
      _c.read(downloadsProvider.notifier).addVisionSupport(m);

  Future<void> discardPartial(PartialDownload p) async {
    final ok = await confirmDialog(
      context,
      title: _l.modelsConfirmDiscardTitle,
      message: _l.modelsConfirmDiscardMessage(p.label, fmtSize(p.bytes)),
      confirmLabel: _l.modelsDiscard,
      destructive: true,
    );
    if (!ok) return;
    await _c.read(modelStoreProvider).discardPartial(p);
    _refresh();
  }

  /// Returns whether it was deleted, so a dialog that asked can close.
  Future<bool> delete(LocalModel m) async {
    final ok = await confirmDialog(
      context,
      title: _l.modelsConfirmDeleteTitle,
      message: _l.modelsConfirmDeleteMessage(
        m.displayName,
        fmtSize(m.sizeBytes),
      ),
      confirmLabel: _l.commonDelete,
      destructive: true,
    );
    if (!ok) return false;
    await _c.read(modelStoreProvider).delete(m);
    if (_c.read(activeModelIdProvider) == m.id) {
      await _c.read(activeModelIdProvider.notifier).set(null);
    }
    _refresh();
    return true;
  }

  Future<void> load(LocalModel m, {bool openChat = false}) async {
    await _c.read(activeModelIdProvider.notifier).set(m);
    showDeskToast(_l.modelsToastLoaded(m.displayName), tone: DeskTone.success);
    if (openChat) _c.read(deskPageProvider.notifier).state = DeskPage.chat;
  }

  /// Import through the system file picker, using the phone's importer.
  Future<void> importPicked() async {
    try {
      final m = await _c.read(modelImporterProvider).pickAndImport();
      _refresh();
      if (m != null) {
        showDeskToast(_s.imported(m.displayName), tone: DeskTone.success);
      }
    } on FormatException {
      showDeskToast(_s.notGguf, tone: DeskTone.warning);
    } on Object catch (e) {
      showDeskToast(_s.importFailed(_message(e)), tone: DeskTone.error);
    }
  }

  /// Imports files dropped on the page. The shared importer only knows the
  /// picker, so this does the same copy for a path the user already has.
  Future<void> importPaths(List<String> paths) async {
    final store = _c.read(modelStoreProvider);
    var rejected = false;
    for (final path in paths) {
      final name = File(path).uri.pathSegments.last;
      if (!name.toLowerCase().endsWith('.gguf')) {
        rejected = true;
        continue;
      }
      try {
        final dest = await store.pathForNewFile(name);
        if (await File(dest).exists()) {
          showDeskToast(_s.alreadyExists(name), tone: DeskTone.warning);
          continue;
        }
        // Copied under a temporary name first, so a half-written file never
        // shows up in the list as a model that will fail to load.
        final temp = File('$dest.importing');
        try {
          await File(path).copy(temp.path);
          await temp.rename(dest);
        } on Object {
          // A failed copy (disk full, file locked) must not leave gigabytes
          // of half-written temp file behind.
          if (await temp.exists()) await temp.delete();
          rethrow;
        }
        store.notifyChanged();
        _refresh();
        showDeskToast(_s.imported(name), tone: DeskTone.success);
      } on Object catch (e) {
        showDeskToast(_s.importFailed(_message(e)), tone: DeskTone.error);
      }
    }
    if (rejected) showDeskToast(_s.notGguf, tone: DeskTone.warning);
  }

  static String _message(Object e) => switch (e) {
    StateError(:final message) => message,
    FileSystemException(:final message, :final osError) =>
      osError == null ? message : '$message (${osError.message})',
    _ => '$e',
  };
}
