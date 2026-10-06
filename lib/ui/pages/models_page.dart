import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models_repo/catalog.dart';
import '../../models_repo/downloader.dart';
import '../../models_repo/model_store.dart';
import '../../models_repo/recommender.dart';
import '../../state/providers.dart';
import '../widgets/coach_mark_targets.dart';
import '../widgets/model_advisor.dart';
import 'benchmark_page.dart';
import 'settings_page.dart';

class ModelsPage extends ConsumerStatefulWidget {
  const ModelsPage({super.key});

  @override
  ConsumerState<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends ConsumerState<ModelsPage> {
  final _search = TextEditingController();
  String _query = '';
  StreamSubscription<DownloadOutcome>? _outcomes;

  @override
  void initState() {
    super.initState();
    // Downloads are owned above the widget tree so a transfer survives this
    // page being rebuilt; results come back on a stream rather than from the
    // call that started them.
    _outcomes = ref
        .read(downloadsProvider.notifier)
        .outcomes
        .listen(_reportOutcome);
  }

  @override
  void dispose() {
    _outcomes?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _reportOutcome(DownloadOutcome outcome) {
    if (!mounted) return;
    if (outcome.cancelled) {
      _toast('Download cancelled');
      return;
    }
    if (!outcome.ok) {
      _toast('Could not download ${outcome.label}: ${outcome.error}');
      return;
    }
    final loaded =
        outcome.installed != null &&
        outcome.catalogModel?.kind == ModelKind.chat;
    _toast(
      loaded
          ? 'Downloaded and loaded ${outcome.label}'
          : 'Downloaded ${outcome.label}',
    );
  }

  Future<void> _load(LocalModel m, {bool openChat = false}) async {
    await ref.read(activeModelIdProvider.notifier).set(m);
    if (!mounted) return;
    _toast('Loaded ${m.displayName}');
    if (openChat) {
      ref.read(shellTabIndexProvider.notifier).state = 0;
    }
  }

  Future<void> _delete(LocalModel m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete model?'),
        content: Text(m.displayName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(c).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(modelStoreProvider).delete(m);
    if (ref.read(activeModelIdProvider) == m.id) {
      await ref.read(activeModelIdProvider.notifier).set(null);
    }
    ref.read(modelsRefreshProvider.notifier).state++;
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

  /// True when [model] should be listed for the current search text. Matches
  /// on everything a user might type: name, maker, size, and the description,
  /// so "google", "1b" and "reasoning" all find something.
  bool _matchesCatalog(CatalogModel model) {
    if (_query.isEmpty) return true;
    return [
      model.displayName,
      model.author,
      model.description,
      model.parameters,
      model.approxSize,
      model.contextLabel,
      model.id,
    ].any((field) => field.toLowerCase().contains(_query));
  }

  bool _matchesInstalled(LocalModel model) {
    if (_query.isEmpty) return true;
    return model.displayName.toLowerCase().contains(_query) ||
        model.id.toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(modelListProvider);
    final activeId = ref.watch(activeModelIdProvider);
    final downloads = ref.watch(downloadsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Models'),
        actions: [
          IconButton(
            key: CoachMarkTargets.benchmarkButton,
            tooltip: 'Benchmark',
            icon: const Icon(Icons.speed_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BenchmarkPage()),
              );
            },
          ),
          IconButton(
            key: CoachMarkTargets.modelsTourButton,
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _SearchField(
            controller: _search,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          Expanded(
            child: modelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (installed) => _buildList(
                context: context,
                scheme: scheme,
                installed: installed,
                activeId: activeId,
                downloads: downloads,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required BuildContext context,
    required ColorScheme scheme,
    required List<LocalModel> installed,
    required String? activeId,
    required Map<String, DownloadHandle> downloads,
  }) {
    final installedKeys = <String>{};
    for (final m in installed) {
      installedKeys.add(_normalizeModelKey(m.id));
      installedKeys.add(_normalizeModelKey(m.displayName));
    }

    final yourModels = installed.where(_matchesInstalled).toList();
    final chatModels = chatCatalog.where(_matchesCatalog).toList();
    final embeddingModels = embeddingCatalog.where(_matchesCatalog).toList();

    if (yourModels.isEmpty && chatModels.isEmpty && embeddingModels.isEmpty) {
      return _NoResults(query: _search.text.trim());
    }

    final missingEncoders = ref.watch(missingProjectorsProvider).maybeWhen(
          data: (ids) => ids,
          orElse: () => const <String>{},
        );

    final device = ref.watch(speedKnowledgeProvider).device;

    Widget catalogCard(CatalogModel m, {Key? actionKey}) => _CatalogCard(
      model: m,
      fit: fitFor(m, device),
      runtimeBytes: runtimeBytesFor(m),
      budgetBytes: device.modelBudgetBytes,
      installed:
          installedKeys.contains(_normalizeModelKey(m.id)) ||
          installedKeys.contains(_normalizeModelKey(m.filename)),
      needsVisionEncoder: missingEncoders.contains(m.id),
      onAddVision: () =>
          ref.read(downloadsProvider.notifier).addVisionSupport(m),
      download: downloads[m.id],
      onDownload: () => ref.read(downloadsProvider.notifier).start(m),
      onCancel: () => ref.read(downloadsProvider.notifier).cancel(m.id),
      actionKey: actionKey,
    );

    // Installed catalog entries, by catalog id, so the advisor can prefer what
    // is already on disk over a fresh download.
    final installedCatalogIds = <String>{
      for (final m in chatCatalog)
        if (installedKeys.contains(_normalizeModelKey(m.id)) ||
            installedKeys.contains(_normalizeModelKey(m.filename)))
          m.id,
    };

    return ListView(
      controller: CoachMarkTargets.modelsScroll,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // A transfer in progress is the thing the user most wants to see when
        // they open this page; the card that started it may be far down a
        // thirty-model list, or filtered out by a search.
        if (downloads.isNotEmpty) ...[
          _ActiveDownloads(
            downloads: downloads,
            onCancel: (id) => ref.read(downloadsProvider.notifier).cancel(id),
          ),
          const SizedBox(height: 16),
        ],
        // Hidden while searching: someone typing a model name has already
        // decided what they want, and the advisor would just push the results
        // off the screen.
        if (_query.isEmpty) ...[
          ModelAdvisor(
            speed: ref.watch(speedKnowledgeProvider),
            installedCatalogIds: installedCatalogIds,
            downloads: downloads,
            onDownload: (m) => ref.read(downloadsProvider.notifier).start(m),
            onCancel: (id) => ref.read(downloadsProvider.notifier).cancel(id),
          ),
          const SizedBox(height: 18),
        ],
        if (yourModels.isNotEmpty) ...[
          const _SectionHeader(
            icon: Icons.inventory_2_rounded,
            title: 'Your models',
            subtitle: 'Tap one to make it active',
          ),
          const SizedBox(height: 12),
          for (final m in yourModels) ...[
            _InstalledCard(
              model: m,
              active: activeId == m.id,
              onTap: () => _load(m),
              onDelete: () => _delete(m),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
        ],
        if (chatModels.isNotEmpty) ...[
          const _SectionHeader(
            icon: Icons.explore_rounded,
            title: 'Browse catalog',
            subtitle: 'Curated GGUF models · one-tap download',
          ),
          const SizedBox(height: 12),
          for (final m in chatModels) ...[
            catalogCard(
              m,
              actionKey: identical(m, chatModels.first)
                  ? CoachMarkTargets.firstCatalogAction
                  : null,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
        ],
        if (embeddingModels.isNotEmpty) ...[
          const _SectionHeader(
            icon: Icons.hub_rounded,
            title: 'Embedding models',
            subtitle: 'For search and RAG · /api/embed · /v1/embeddings',
          ),
          const SizedBox(height: 12),
          for (final m in embeddingModels) ...[
            catalogCard(m),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: scheme.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Downloads save to app storage and stay on-device. '
                  'All models are open-weight GGUFs.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── widgets ───────────────────────────────────────────────────────────────

/// Search across installed models and the catalog. Sits above the list rather
/// than inside it so it stays reachable while scrolling a long catalog.
class _SearchField extends StatefulWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = widget.controller.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {});
                  widget.onChanged(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search models, makers, sizes',
                  hintStyle: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (hasText)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Clear search',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  widget.controller.clear();
                  setState(() {});
                  widget.onChanged('');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              'No models match "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a maker (Google, Alibaba), a size (1B, 4B), or a task '
              'such as embedding.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
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
    );
  }
}

class _InstalledCard extends StatelessWidget {
  final LocalModel model;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InstalledCard({
    required this.model,
    required this.active,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: active ? scheme.primary : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  active ? Icons.check_rounded : Icons.memory_rounded,
                  color: active ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      model.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(
                          label: _fmtSize(model.sizeBytes),
                          icon: Icons.storage_rounded,
                        ),
                        const SizedBox(width: 6),
                        if (active)
                          const _Chip(
                            label: 'Active',
                            icon: Icons.bolt_rounded,
                            tone: _ChipTone.accent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: onDelete,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final CatalogModel model;
  final bool installed;

  /// Installed, can see, but its image encoder was never downloaded.
  final bool needsVisionEncoder;

  /// Fetches just the encoder for an already-installed vision model.
  final VoidCallback? onAddVision;
  final DownloadHandle? download;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final Key? actionKey;

  /// How this model sits in the phone's memory.
  final RamFit fit;

  /// What the model needs once loaded, and what the phone can spare — the two
  /// numbers that make a refusal to download something other than a shrug.
  final int runtimeBytes;
  final int? budgetBytes;

  const _CatalogCard({
    required this.model,
    required this.installed,
    this.needsVisionEncoder = false,
    this.onAddVision,
    required this.download,
    required this.onDownload,
    required this.onCancel,
    this.actionKey,
    this.fit = RamFit.unknown,
    this.runtimeBytes = 0,
    this.budgetBytes,
  });

  /// True when this phone cannot run the model, so downloading it would only
  /// spend the user's data on something that gets killed on load.
  bool get blocked => !installed && fit == RamFit.tooBig;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: model.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: model.accent.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                child: Text(model.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      model.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      model.author,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildAction(context),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            model.description,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (blocked || (!installed && fit == RamFit.tight)) ...[
            const SizedBox(height: 10),
            _FitWarning(
              blocked: blocked,
              needs: runtimeBytes,
              budget: budgetBytes,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip(label: model.parameters, icon: Icons.tune_rounded),
              _Chip(
                label: model.approxSize,
                icon: Icons.cloud_download_outlined,
              ),
              // Context window, not quantisation: how much text the model can
              // hold is what a user chooses between, and every entry here is
              // a small quant anyway.
              _Chip(
                label: '${model.contextLabel} context',
                icon: Icons.article_rounded,
              ),
              if (model.dimensions != null)
                _Chip(
                  label: '${model.dimensions} dims',
                  icon: Icons.scatter_plot_rounded,
                ),
            ],
          ),
          if (download != null) ...[
            const SizedBox(height: 12),
            _DownloadProgressRow(handle: download!),
          ],
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    // An installed vision model with no image encoder is one download away
    // from being able to see. Saying "Installed" and leaving it there would
    // hide that.
    if (installed && needsVisionEncoder) {
      return FilledButton.tonalIcon(
        key: actionKey,
        onPressed: onAddVision,
        icon: const Icon(Icons.image_outlined, size: 16),
        label: Text('Add vision · ${model.mmprojSize}'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }
    if (installed) {
      final scheme = Theme.of(context).colorScheme;
      return Container(
        key: actionKey,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded,
              size: 16,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              'Installed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }
    if (blocked) {
      final scheme = Theme.of(context).colorScheme;
      return Container(
        key: actionKey,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Too big',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    if (download != null) {
      return IconButton(
        key: actionKey,
        icon: const Icon(Icons.close_rounded),
        onPressed: onCancel,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
      );
    }
    return FilledButton.tonalIcon(
      key: actionKey,
      icon: const Icon(Icons.download_rounded, size: 18),
      label: const Text('Get'),
      onPressed: onDownload,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

class _DownloadProgressRow extends StatelessWidget {
  final DownloadHandle handle;
  const _DownloadProgressRow({required this.handle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<DownloadProgress>(
      stream: handle.progress,
      builder: (context, snap) {
        final p = snap.data;
        final fraction = p?.fraction;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  fraction != null
                      ? '${(fraction * 100).toStringAsFixed(0)}%'
                      : 'Starting…',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                const Spacer(),
                if (p != null)
                  Text(
                    _fmtSize(p.received),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHigh,
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _ChipTone { neutral, accent }

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final _ChipTone tone;
  const _Chip({
    required this.label,
    required this.icon,
    this.tone = _ChipTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = tone == _ChipTone.accent
        ? scheme.primary.withValues(alpha: 0.1)
        : scheme.surfaceContainerHigh;
    final fg = tone == _ChipTone.accent
        ? scheme.primary
        : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

String _normalizeModelKey(String input) {
  var key = input.trim().toLowerCase();
  if (key.endsWith('.gguf')) {
    key = key.substring(0, key.length - 5);
  }
  return key;
}

String _fmtSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
}

/// Explains a fit verdict on a catalogue card.
///
/// A refusal to download needs numbers behind it. "Too big" on its own reads
/// as the app being cautious; "needs 5.2 GB, this phone can spare 3.1 GB" is a
/// fact the user can check against what they know about their device.
class _FitWarning extends StatelessWidget {
  const _FitWarning({
    required this.blocked,
    required this.needs,
    required this.budget,
  });

  final bool blocked;
  final int needs;
  final int? budget;

  static String _gb(int bytes) =>
      '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = budget;
    final color = blocked ? scheme.error : Colors.orange.shade800;

    final text = blocked
        ? available == null
            ? 'Too large for this phone.'
            : 'Needs ${_gb(needs)}, this phone has ${_gb(available)} to spare.'
        : 'A tight fit. Other apps may close while this runs.';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            blocked ? Icons.block_rounded : Icons.warning_amber_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.5, color: color, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every download in flight, pinned to the top of the Models page.
class _ActiveDownloads extends StatelessWidget {
  const _ActiveDownloads({required this.downloads, required this.onCancel});

  final Map<String, DownloadHandle> downloads;
  final void Function(String catalogId) onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = downloads.entries.toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                entries.length == 1
                    ? 'Downloading'
                    : 'Downloading ${entries.length} models',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final entry in entries)
            _ActiveDownloadRow(
              handle: entry.value,
              onCancel: () => onCancel(entry.key),
            ),
        ],
      ),
    );
  }
}

class _ActiveDownloadRow extends StatelessWidget {
  const _ActiveDownloadRow({required this.handle, required this.onCancel});

  final DownloadHandle handle;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<DownloadProgress>(
      stream: handle.progress,
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final fraction = progress?.fraction;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      handle.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fraction == null
                        ? 'Starting...'
                        : '${(fraction * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  IconButton(
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.only(left: 8),
                    constraints: const BoxConstraints(),
                    tooltip: 'Cancel download',
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 5,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
