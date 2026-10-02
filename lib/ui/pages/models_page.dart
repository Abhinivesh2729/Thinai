import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models_repo/catalog.dart';
import '../../models_repo/downloader.dart';
import '../../models_repo/model_store.dart';
import '../../models_repo/recommender.dart';
import '../../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/coach_mark_targets.dart';
import '../widgets/model_advisor.dart';
import '../widgets/app_drawer.dart';
import '../widgets/ui_kit.dart';
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
    _toast('Loaded ${_catalogFor(m)?.displayName ?? m.displayName}');
    if (openChat) {
      ref.read(shellTabIndexProvider.notifier).state = 0;
    }
  }

  Future<void> _delete(LocalModel m) async {
    final confirm = await confirmAction(
      context,
      title: 'Delete model?',
      message:
          '${m.displayName} is removed from this phone. '
          'You can download it again later.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirm) return;
    await ref.read(modelStoreProvider).delete(m);
    if (ref.read(activeModelIdProvider) == m.id) {
      await ref.read(activeModelIdProvider.notifier).set(null);
    }
    ref.read(modelsRefreshProvider.notifier).state++;
  }

  void _toast(String text) => showToast(context, text);

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

    return Scaffold(
      appBar: AppBar(
        leading: const MenuButton(),
        titleSpacing: Space.xs,
        title: const Text('Models'),
        actions: [
          IconButton(
            key: CoachMarkTargets.benchmarkButton,
            tooltip: 'Benchmark',
            icon: const Icon(Icons.speed_rounded),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BenchmarkPage()));
            },
          ),
          IconButton(
            key: CoachMarkTargets.modelsTourButton,
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
          const SizedBox(width: Space.xs),
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
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Could not read your models',
                message: '$e',
              ),
              data: (installed) => _buildList(
                context: context,
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
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No models match "${_search.text.trim()}"',
        message:
            'Try a maker (Google, Alibaba), a size (1B, 4B), or a task '
            'such as embedding.',
      );
    }

    final missingEncoders = ref
        .watch(missingProjectorsProvider)
        .maybeWhen(data: (ids) => ids, orElse: () => const <String>{});

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
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.xs,
        Space.lg,
        Space.xxxl,
      ),
      children: [
        // A transfer in progress is the thing the user most wants to see when
        // they open this page; the card that started it may be far down a
        // thirty-model list, or filtered out by a search.
        if (downloads.isNotEmpty) ...[
          _ActiveDownloads(
            downloads: downloads,
            onCancel: (id) => ref.read(downloadsProvider.notifier).cancel(id),
          ),
          const SizedBox(height: Space.md),
        ],
        // Hidden while searching: someone typing a model name has already
        // decided what they want, and the advisor would just push the results
        // off the screen.
        if (_query.isEmpty)
          ModelAdvisor(
            speed: ref.watch(speedKnowledgeProvider),
            installedCatalogIds: installedCatalogIds,
            downloads: downloads,
            onDownload: (m) => ref.read(downloadsProvider.notifier).start(m),
            onCancel: (id) => ref.read(downloadsProvider.notifier).cancel(id),
          ),
        if (yourModels.isNotEmpty) ...[
          SectionHeader(
            title: 'Your models',
            subtitle: 'Tap one to make it active',
            trailing: _Count(yourModels.length),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < yourModels.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 68),
                  _InstalledRow(
                    model: yourModels[i],
                    active: activeId == yourModels[i].id,
                    onTap: () => _load(yourModels[i]),
                    onDelete: () => _delete(yourModels[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (chatModels.isNotEmpty) ...[
          SectionHeader(
            title: 'Browse catalog',
            subtitle: 'Curated GGUF models · one-tap download',
            trailing: _Count(chatModels.length),
          ),
          for (final m in chatModels) ...[
            catalogCard(
              m,
              actionKey: identical(m, chatModels.first)
                  ? CoachMarkTargets.firstCatalogAction
                  : null,
            ),
            const SizedBox(height: Space.md),
          ],
        ],
        if (embeddingModels.isNotEmpty) ...[
          SectionHeader(
            title: 'Embedding models',
            subtitle: 'For search and RAG · /api/embed · /v1/embeddings',
            trailing: _Count(embeddingModels.length),
          ),
          for (final m in embeddingModels) ...[
            catalogCard(m),
            const SizedBox(height: Space.md),
          ],
        ],
        const SizedBox(height: Space.sm),
        const InlineNotice(
          icon: Icons.lock_outline_rounded,
          text:
              'Downloads save to app storage and stay on-device. '
              'All models are open-weight GGUFs.',
        ),
      ],
    );
  }
}

// ─── widgets ───────────────────────────────────────────────────────────────

class _Count extends StatelessWidget {
  const _Count(this.count);

  final int count;

  @override
  Widget build(BuildContext context) => Tag('$count', dense: true);
}

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasText = widget.controller.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.xs,
        Space.lg,
        Space.md,
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.of(context).card,
          borderRadius: BorderRadius.circular(Radii.md + 2),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.only(left: 14, right: Space.xs),
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
                style: theme.textTheme.bodyMedium,
                onChanged: (value) {
                  setState(() {});
                  widget.onChanged(value);
                },
                decoration: bareInputDecoration(
                  hintText: 'Search models, makers, sizes',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
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

/// The catalogue entry a downloaded file came from, if it came from one.
CatalogModel? _catalogFor(LocalModel model) {
  for (final m in [...chatCatalog, ...embeddingCatalog]) {
    if (m.servedId == model.id) return m;
  }
  return null;
}

class _InstalledRow extends StatelessWidget {
  final LocalModel model;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InstalledRow({
    required this.model,
    required this.active,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entry = _catalogFor(model);
    // A friendly name when the file came from the catalogue; the filename
    // otherwise, since that is the only name an imported model has.
    final title = entry?.displayName ?? model.displayName;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.md,
          Space.xs,
          Space.md,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: Motion.base,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: active ? scheme.primary : scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Radii.md - 1),
              ),
              alignment: Alignment.center,
              child: active
                  ? Icon(Icons.check_rounded, size: 20, color: scheme.onPrimary)
                  : entry != null
                  ? Text(entry.emoji, style: const TextStyle(fontSize: 18))
                  : Icon(
                      Icons.memory_rounded,
                      size: 19,
                      color: scheme.onSurface,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 14.5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (active) ...[
                        const Tag('Active', tone: TagTone.success, dense: true),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          entry == null
                              ? _fmtSize(model.sizeBytes)
                              : '${_fmtSize(model.sizeBytes)} · ${model.displayName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete model',
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: onDelete,
              color: scheme.onSurfaceVariant,
            ),
          ],
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(Space.lg, 14, Space.md, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: model.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Text(model.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      model.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.author,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              _buildAction(context),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(
            model.description,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Tag(model.parameters, icon: Icons.tune_rounded, dense: true),
              Tag(model.approxSize, icon: Icons.download_rounded, dense: true),
              // Context window, not quantisation: how much text the model can
              // hold is what a user chooses between, and every entry here is
              // a small quant anyway.
              Tag(
                '${model.contextLabel} context',
                icon: Icons.notes_rounded,
                dense: true,
              ),
              if (model.dimensions != null)
                Tag(
                  '${model.dimensions} dims',
                  icon: Icons.scatter_plot_outlined,
                  dense: true,
                ),
            ],
          ),
          if (blocked || (!installed && fit == RamFit.tight)) ...[
            const SizedBox(height: Space.md),
            _FitWarning(
              blocked: blocked,
              needs: runtimeBytes,
              budget: budgetBytes,
            ),
          ],
          if (download != null) ...[
            const SizedBox(height: 14),
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
        style: _compact,
      );
    }
    if (installed) {
      return Tag(
        'Installed',
        key: actionKey,
        icon: Icons.check_rounded,
        tone: TagTone.success,
      );
    }
    if (blocked) {
      return Tag('Too big', key: actionKey, icon: Icons.block_rounded);
    }
    if (download != null) {
      return IconButton(
        key: actionKey,
        tooltip: 'Cancel download',
        icon: const Icon(Icons.close_rounded, size: 20),
        onPressed: onCancel,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
      );
    }
    return FilledButton.tonalIcon(
      key: actionKey,
      icon: const Icon(Icons.download_rounded, size: 18),
      label: const Text('Get'),
      onPressed: onDownload,
      style: _compact,
    );
  }

  static final _compact = FilledButton.styleFrom(
    minimumSize: const Size(0, 38),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    shape: const StadiumBorder(),
  );
}

class _DownloadProgressRow extends StatelessWidget {
  final DownloadHandle handle;
  const _DownloadProgressRow({required this.handle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const Spacer(),
                if (p != null)
                  Text(
                    _fmtSize(p.received),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: Space.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.xs),
              child: LinearProgressIndicator(value: fraction, minHeight: 6),
            ),
          ],
        );
      },
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
    final available = budget;
    final text = blocked
        ? available == null
              ? 'Too large for this phone.'
              : 'Needs ${_gb(needs)}, this phone has ${_gb(available)} to spare.'
        : 'A tight fit. Other apps may close while this runs.';
    return InlineNotice(
      text: text,
      icon: blocked ? Icons.block_rounded : Icons.warning_amber_rounded,
      tone: blocked ? TagTone.danger : TagTone.warning,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = downloads.entries.toList();

    return AppCard(
      borderColor: scheme.primary.withValues(alpha: 0.35),
      padding: const EdgeInsets.fromLTRB(Space.lg, 14, Space.sm, Space.sm),
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
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: Space.md),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return StreamBuilder<DownloadProgress>(
      stream: handle.progress,
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final fraction = progress?.fraction;
        return Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: Row(
            children: [
              Expanded(
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
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.sm),
                        Text(
                          fraction == null
                              ? 'Starting…'
                              : '${(fraction * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.xs),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                tooltip: 'Cancel download',
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        );
      },
    );
  }
}
