import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models_repo/catalog.dart';
import '../../models_repo/downloader.dart';
import '../../models_repo/model_store.dart';
import '../../models_repo/recommender.dart';
import '../../models_repo/use_cases.dart';
import '../../state/providers.dart';
import '../widgets/coach_mark_targets.dart';
import '../widgets/model_brand_logo.dart';
import 'benchmark_page.dart';

enum ModelFilter { all, chat, vision, embedding, installed }

const _brandGreen = Color(0xFF2CA048);


class ModelsPage extends ConsumerStatefulWidget {
  const ModelsPage({super.key});

  @override
  ConsumerState<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends ConsumerState<ModelsPage> {
  final _search = TextEditingController();
  String _query = '';
  ModelFilter _filter = ModelFilter.all;
  UseCase? _selectedUseCase;
  StreamSubscription<DownloadOutcome>? _outcomes;

  @override
  void initState() {
    super.initState();
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
        content: Text(
          'Are you sure you want to delete ${m.displayName}? This frees ${_fmtSize(m.sizeBytes)} of space.',
        ),
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

  void _openModelManager(
    BuildContext context, {
    required List<LocalModel> installed,
    required String? activeId,
    required Map<String, DownloadHandle> downloads,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModelManagerSheet(
        installed: installed,
        activeId: activeId,
        downloads: downloads,
        onActivate: (m) {
          _load(m);
          Navigator.pop(ctx);
        },
        onDelete: (m) => _delete(m),
        onCancelDownload: (id) =>
            ref.read(downloadsProvider.notifier).cancel(id),
        onBrowseCatalog: () {
          Navigator.pop(ctx);
          setState(() {
            _filter = ModelFilter.all;
            _query = '';
            _search.clear();
          });
        },
      ),
    );
  }

  void _openGoalPickerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoalPickerSheet(
        selected: _selectedUseCase,
        onSelect: (uc) {
          setState(() {
            _selectedUseCase = uc;
            if (_filter == ModelFilter.installed ||
                _filter == ModelFilter.embedding) {
              _filter = ModelFilter.all;
            }
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(modelListProvider);
    final activeId = ref.watch(activeModelIdProvider);
    final downloads = ref.watch(downloadsProvider);
    final scheme = Theme.of(context).colorScheme;
    final installed = modelsAsync.valueOrNull ?? const <LocalModel>[];
    final installedCount = installed.length;
    final isDownloading = downloads.isNotEmpty;

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
            tooltip: isDownloading
                ? 'Downloading (${downloads.length}) · Manage Models'
                : (installedCount > 0
                    ? 'Model Manager ($installedCount installed)'
                    : 'Model Manager'),
            icon: Badge(
              isLabelVisible: isDownloading || installedCount > 0,
              label: Text(
                isDownloading ? '${downloads.length}' : '$installedCount',
              ),
              backgroundColor: _brandGreen,
              textColor: Colors.white,
              child: Icon(
                isDownloading
                    ? Icons.downloading_rounded
                    : Icons.inventory_2_rounded,
                color: isDownloading ? _brandGreen : null,
              ),
            ),
            onPressed: () => _openModelManager(
              context,
              installed: installed,
              activeId: activeId,
              downloads: downloads,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _search,
            selectedUseCase: _selectedUseCase,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            onClear: () {
              setState(() {
                _query = '';
                _search.clear();
              });
            },
            onOpenGoalPicker: () => _openGoalPickerSheet(context),
          ),
          _UnifiedFilterBar(
            selected: _filter,
            selectedUseCase: _selectedUseCase,
            installedCount: installedCount,
            hasActiveFilter:
                _filter != ModelFilter.all ||
                _query.isNotEmpty ||
                _selectedUseCase != null,
            onSelected: (filter) {
              setState(() {
                _filter = filter;
                if (filter == ModelFilter.installed ||
                    filter == ModelFilter.embedding) {
                  _selectedUseCase = null;
                }
              });
            },
            onClearGoal: () => setState(() => _selectedUseCase = null),
            onResetAll: () {
              setState(() {
                _filter = ModelFilter.all;
                _selectedUseCase = null;
                _query = '';
                _search.clear();
              });
            },
          ),
          const SizedBox(height: 6),
          Expanded(
            child: modelsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _brandGreen),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (installedList) => _buildCatalogView(
                context: context,
                scheme: scheme,
                installed: installedList,
                activeId: activeId,
                downloads: downloads,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogView({
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

    // Filter models based on selection
    final List<CatalogModel> chatModels;
    final List<CatalogModel> embeddingModels;
    final bool showInstalledOnly = _filter == ModelFilter.installed;

    switch (_filter) {
      case ModelFilter.all:
        chatModels = chatCatalog.where(_matchesCatalog).toList();
        embeddingModels = embeddingCatalog.where(_matchesCatalog).toList();
        break;
      case ModelFilter.chat:
        chatModels = chatCatalog
            .where((m) => m.mmprojUrl == null)
            .where(_matchesCatalog)
            .toList();
        embeddingModels = const [];
        break;
      case ModelFilter.vision:
        chatModels = chatCatalog
            .where((m) => m.mmprojUrl != null)
            .where(_matchesCatalog)
            .toList();
        embeddingModels = const [];
        break;
      case ModelFilter.embedding:
        chatModels = const [];
        embeddingModels = embeddingCatalog.where(_matchesCatalog).toList();
        break;
      case ModelFilter.installed:
        chatModels = const [];
        embeddingModels = const [];
        break;
    }

    // Installed empty view
    if (showInstalledOnly) {
      if (yourModels.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 40,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No models installed yet',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse and download GGUF models from the catalog to run offline on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.explore_rounded, size: 16),
                  label: const Text('Browse Catalog'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => setState(() => _filter = ModelFilter.all),
                ),
              ],
            ),
          ),
        );
      }

      return ListView(
        controller: CoachMarkTargets.modelsScroll,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SectionHeader(
            icon: Icons.inventory_2_rounded,
            title: 'Installed models (${yourModels.length})',
            subtitle: 'Tap a model to load it for chat',
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
        ],
      );
    }

    if (chatModels.isEmpty && embeddingModels.isEmpty) {
      return _NoResults(
        query: _search.text.trim(),
        onClear: () {
          setState(() {
            _filter = ModelFilter.all;
            _selectedUseCase = null;
            _query = '';
            _search.clear();
          });
        },
      );
    }

    final missingEncoders = ref.watch(missingProjectorsProvider).maybeWhen(
          data: (ids) => ids,
          orElse: () => const <String>{},
        );

    final device = ref.watch(speedKnowledgeProvider).device;

    Widget catalogCard(
      CatalogModel m, {
      Key? actionKey,
      bool isRecommended = false,
    }) =>
        _CatalogCard(
          model: m,
          fit: fitFor(m, device),
          runtimeBytes: runtimeBytesFor(m),
          budgetBytes: device.modelBudgetBytes,
          installed:
              installedKeys.contains(_normalizeModelKey(m.id)) ||
              installedKeys.contains(_normalizeModelKey(m.filename)),
          needsVisionEncoder: missingEncoders.contains(m.id),
          isRecommended: isRecommended,
          onAddVision: () =>
              ref.read(downloadsProvider.notifier).addVisionSupport(m),
          download: downloads[m.id],
          onDownload: () => ref.read(downloadsProvider.notifier).start(m),
          onCancel: () => ref.read(downloadsProvider.notifier).cancel(m.id),
          actionKey: actionKey,
        );

    final installedCatalogIds = <String>{
      for (final m in chatCatalog)
        if (installedKeys.contains(_normalizeModelKey(m.id)) ||
            installedKeys.contains(_normalizeModelKey(m.filename)))
          m.id,
    };

    final Set<String> recommendedModelIds;
    if (_selectedUseCase != null) {
      final rec = recommend(
        _selectedUseCase!,
        device,
        installedIds: installedCatalogIds,
        speed: ref.watch(speedKnowledgeProvider),
      );
      recommendedModelIds = {for (final p in rec.picks) p.model.id};
    } else {
      recommendedModelIds = const {};
    }

    final recommendedChatModels = _selectedUseCase != null
        ? chatModels.where((m) => recommendedModelIds.contains(m.id)).toList()
        : const <CatalogModel>[];
    final remainingChatModels = _selectedUseCase != null
        ? chatModels.where((m) => !recommendedModelIds.contains(m.id)).toList()
        : chatModels;

    return ListView(
      controller: CoachMarkTargets.modelsScroll,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [

        // Active Goal recommendations section
        if (_selectedUseCase != null) ...[
          _ActiveGoalBanner(
            useCase: _selectedUseCase!,
            onClear: () => setState(() => _selectedUseCase = null),
            onChange: () => _openGoalPickerSheet(context),
          ),
          const SizedBox(height: 14),
          if (recommendedChatModels.isNotEmpty) ...[
            _SectionHeader(
              icon: _selectedUseCase!.icon,
              title: 'Recommended for ${_selectedUseCase!.label}',
              subtitle: 'Optimal weights selected for your device specs',
            ),
            const SizedBox(height: 10),
            for (final m in recommendedChatModels) ...[
              catalogCard(m, isRecommended: true),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
          ],
        ],

        // Browse / Remaining Chat models
        if (remainingChatModels.isNotEmpty) ...[
          _SectionHeader(
            icon: _filter == ModelFilter.vision
                ? Icons.visibility_rounded
                : (_filter == ModelFilter.chat
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.explore_rounded),
            title: _selectedUseCase != null
                ? 'Other models'
                : (_filter == ModelFilter.vision
                    ? 'Vision models'
                    : (_filter == ModelFilter.chat
                        ? 'Chat models'
                        : 'Browse catalog')),
            subtitle: _selectedUseCase != null
                ? 'All other available models'
                : (_filter == ModelFilter.vision
                    ? 'Multimodal · image & visual analysis'
                    : 'Curated GGUF models · one-tap download'),
          ),
          const SizedBox(height: 10),
          for (final m in remainingChatModels) ...[
            catalogCard(
              m,
              actionKey: identical(m, remainingChatModels.first)
                  ? CoachMarkTargets.firstCatalogAction
                  : null,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
        ],

        // Embedding models
        if (embeddingModels.isNotEmpty) ...[
          const _SectionHeader(
            icon: Icons.hub_rounded,
            title: 'Embedding models',
            subtitle: 'For search and RAG · /api/embed · /v1/embeddings',
          ),
          const SizedBox(height: 10),
          for (final m in embeddingModels) ...[
            catalogCard(m),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
        ],

        // Storage & Offline guarantee footer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.offline_pin_rounded,
                color: _brandGreen,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Downloaded models stay 100% on-device and run entirely offline.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
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

// ─── Search & Unified Filter Header ──────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final UseCase? selectedUseCase;
  final VoidCallback onOpenGoalPicker;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.selectedUseCase,
    required this.onOpenGoalPicker,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = controller.text.isNotEmpty;
    final primaryBrand = isDark ? _brandGreen : const Color(0xFF1B8738);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131722) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF263040) : const Color(0xFFCBD5E1),
                  width: 1,
                ),
                boxShadow: isDark
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.search,
                      onChanged: onChanged,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Search models, makers, architectures…',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  if (hasText)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Clear search',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onClear,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Classical Goals / Smart Match shortcut button
          Material(
            color: selectedUseCase != null
                ? (isDark ? const Color(0x282CA048) : const Color(0x181B8738))
                : (isDark ? const Color(0xFF131722) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            elevation: !isDark && selectedUseCase == null ? 0.5 : 0,
            shadowColor: const Color(0x10000000),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onOpenGoalPicker,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedUseCase != null
                        ? primaryBrand
                        : (isDark ? const Color(0xFF263040) : const Color(0xFFCBD5E1)),
                    width: selectedUseCase != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selectedUseCase != null
                          ? selectedUseCase!.icon
                          : Icons.auto_awesome_rounded,
                      size: 17,
                      color: selectedUseCase != null
                          ? primaryBrand
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      selectedUseCase != null
                          ? selectedUseCase!.label
                          : 'Goals',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selectedUseCase != null
                          ? primaryBrand
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnifiedFilterBar extends StatelessWidget {
  final ModelFilter selected;
  final UseCase? selectedUseCase;
  final int installedCount;
  final bool hasActiveFilter;
  final ValueChanged<ModelFilter> onSelected;
  final VoidCallback onClearGoal;
  final VoidCallback onResetAll;

  const _UnifiedFilterBar({
    required this.selected,
    required this.selectedUseCase,
    required this.installedCount,
    required this.hasActiveFilter,
    required this.onSelected,
    required this.onClearGoal,
    required this.onResetAll,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final categories = [
      (ModelFilter.all, 'All', Icons.grid_view_rounded),
      (ModelFilter.chat, 'Chat', Icons.chat_bubble_outline_rounded),
      (ModelFilter.vision, 'Vision', Icons.visibility_outlined),
      (ModelFilter.embedding, 'Embedding', Icons.hub_outlined),
      (
        ModelFilter.installed,
        installedCount > 0 ? 'Installed ($installedCount)' : 'Installed',
        Icons.inventory_2_outlined,
      ),
    ];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final (filter, label, icon) in categories) ...[
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterPill(
                label: label,
                icon: icon,
                selected: selected == filter,
                onTap: () => onSelected(filter),
              ),
            ),
          ],
          if (selectedUseCase != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterPill(
                label: selectedUseCase!.label,
                icon: selectedUseCase!.icon,
                selected: true,
                trailing: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: Colors.white,
                ),
                onTap: onClearGoal,
              ),
            ),
          if (hasActiveFilter)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onResetAll,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: scheme.error.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_alt_off_rounded,
                        size: 13,
                        color: scheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Widget? trailing;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark
        ? const Color(0xFF2CA048)
        : const Color(0xFF0F172A);
    final unselectedBg = isDark
        ? const Color(0xFF131722)
        : Colors.white;
    final selectedFg = Colors.white;
    final unselectedFg = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF334155);
    final borderColor = selected
        ? (isDark ? const Color(0xFF2CA048) : const Color(0xFF0F172A))
        : (isDark ? const Color(0xFF263040) : const Color(0xFFCBD5E1));

    return Material(
      color: selected ? selectedBg : unselectedBg,
      borderRadius: BorderRadius.circular(10),
      elevation: !isDark && !selected ? 0.5 : 0,
      shadowColor: const Color(0x10000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? selectedFg : unselectedFg,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? selectedFg : unselectedFg,
                  letterSpacing: -0.1,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveGoalBanner extends StatelessWidget {
  final UseCase useCase;
  final VoidCallback onClear;
  final VoidCallback onChange;

  const _ActiveGoalBanner({
    required this.useCase,
    required this.onClear,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBrand = isDark ? _brandGreen : const Color(0xFF1B8738);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x1F2CA048) : const Color(0x101B8738),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryBrand.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primaryBrand.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(useCase.icon, size: 18, color: primaryBrand),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Targeting: ${useCase.label}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryBrand,
                  ),
                ),
                Text(
                  useCase.blurb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: primaryBrand,
            ),
            child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            tooltip: 'Clear goal',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _ModelManagerSheet extends StatelessWidget {
  final List<LocalModel> installed;
  final String? activeId;
  final Map<String, DownloadHandle> downloads;
  final ValueChanged<LocalModel> onActivate;
  final ValueChanged<LocalModel> onDelete;
  final ValueChanged<String> onCancelDownload;
  final VoidCallback onBrowseCatalog;

  const _ModelManagerSheet({
    required this.installed,
    required this.activeId,
    required this.downloads,
    required this.onActivate,
    required this.onDelete,
    required this.onCancelDownload,
    required this.onBrowseCatalog,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalBytes = installed.fold<int>(0, (sum, m) => sum + m.sizeBytes);
    final activeModel = installed.cast<LocalModel?>().firstWhere(
          (m) => m?.id == activeId,
          orElse: () => null,
        );

    final subtitle = downloads.isNotEmpty
        ? '${installed.length} installed · ${downloads.length} downloading · ${_fmtSize(totalBytes)} used'
        : '${installed.length} models · ${_fmtSize(totalBytes)} storage used';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Sheet Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _brandGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    downloads.isNotEmpty
                        ? Icons.downloading_rounded
                        : Icons.inventory_2_rounded,
                    color: _brandGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Model Manager',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: installed.isEmpty && downloads.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 44,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No models installed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Download models from the catalog to run offline chat.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.explore_rounded, size: 16),
                            label: const Text('Browse Catalog'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _brandGreen,
                            ),
                            onPressed: onBrowseCatalog,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      // Active Downloads at the top of the manager
                      if (downloads.isNotEmpty) ...[
                        _ActiveDownloads(
                          downloads: downloads,
                          onCancel: onCancelDownload,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Active model summary banner
                      if (installed.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 18,
                                color: activeModel != null
                                    ? _brandGreen
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activeModel != null
                                      ? 'Active for Chat: ${activeModel.displayName}'
                                      : 'No model loaded in Chat',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: activeModel != null
                                        ? _brandGreen
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final m in installed) ...[
                          _ManagerModelTile(
                            model: m,
                            isActive: m.id == activeId,
                            onActivate: () => onActivate(m),
                            onDelete: () => onDelete(m),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ] else ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Installed models will appear here after download completes.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
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

class _ManagerModelTile extends StatelessWidget {
  final LocalModel model;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const _ManagerModelTile({
    required this.model,
    required this.isActive,
    required this.onActivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? _brandGreen.withValues(alpha: 0.08)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? _brandGreen.withValues(alpha: 0.4)
              : scheme.outlineVariant.withValues(alpha: 0.5),
          width: isActive ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? _brandGreen.withValues(alpha: 0.4)
                    : scheme.outlineVariant.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: ModelBrandLogo.local(model: model, size: 24),
          ),
          const SizedBox(width: 12),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _Chip(
                      label: _fmtSize(model.sizeBytes),
                      icon: Icons.storage_rounded,
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      const _Chip(
                        label: 'Active',
                        icon: Icons.bolt_rounded,
                        tone: _ChipTone.accent,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isActive)
            FilledButton.tonal(
              onPressed: onActivate,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHigh,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Activate',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            tooltip: 'Delete model',
            color: scheme.error,
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── Goal Picker Sheet ───────────────────────────────────────────────────────

class _GoalPickerSheet extends StatelessWidget {
  final UseCase? selected;
  final ValueChanged<UseCase?> onSelect;

  const _GoalPickerSheet({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _brandGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: _brandGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Your Goal',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Thinai benchmarks & recommends models for your device',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                if (selected != null) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Clear Active Goal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
                    ),
                    onPressed: () => onSelect(null),
                  ),
                  const SizedBox(height: 10),
                ],
                for (final uc in UseCase.values) ...[
                  _GoalOptionCard(
                    useCase: uc,
                    isSelected: selected == uc,
                    onTap: () => onSelect(selected == uc ? null : uc),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOptionCard extends StatelessWidget {
  final UseCase useCase;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalOptionCard({
    required this.useCase,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? _brandGreen.withValues(alpha: 0.1)
          : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? _brandGreen
                  : scheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _brandGreen
                      : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  useCase.icon,
                  size: 20,
                  color: isSelected ? Colors.white : scheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      useCase.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? _brandGreen : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      useCase.blurb,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: _brandGreen,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cards & Components ──────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final String query;
  final VoidCallback? onClear;

  const _NoResults({required this.query, this.onClear});

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
              query.isEmpty
                  ? 'No models match current filters'
                  : 'No models match "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your selected filters or search terms.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            if (onClear != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Reset filters & search'),
                onPressed: onClear,
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBrand = isDark ? _brandGreen : const Color(0xFF1B8738);

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x242CA048) : const Color(0x141B8738),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0x402CA048) : const Color(0x301B8738),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 15, color: primaryBrand),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: scheme.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11.5,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBrand = isDark ? _brandGreen : const Color(0xFF1B8738);

    final cardBg = active
        ? (isDark ? const Color(0xFF121B24) : const Color(0xFFF0FDF4))
        : (isDark ? const Color(0xFF131722) : Colors.white);
    final cardBorder = active
        ? primaryBrand
        : (isDark ? const Color(0xFF263040) : const Color(0xFFCBD5E1));
    final cardShadow = isDark
        ? const [
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cardBorder,
              width: active ? 1.5 : 1,
            ),
            boxShadow: cardShadow,
          ),
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A222E) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? primaryBrand.withValues(alpha: 0.45)
                        : (isDark ? const Color(0xFF2B3647) : const Color(0xFFE2E8F0)),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: ModelBrandLogo.local(model: model, size: 30),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Chip(
                          label: _fmtSize(model.sizeBytes),
                          icon: Icons.storage_rounded,
                        ),
                        const SizedBox(width: 8),
                        if (active)
                          const _Chip(
                            label: 'Active in Chat',
                            icon: Icons.bolt_rounded,
                            tone: _ChipTone.accent,
                          )
                        else
                          Text(
                            'Tap to activate',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                tooltip: 'Delete model',
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
  final bool needsVisionEncoder;
  final bool isRecommended;
  final VoidCallback? onAddVision;
  final DownloadHandle? download;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final Key? actionKey;
  final RamFit fit;
  final int runtimeBytes;
  final int? budgetBytes;

  const _CatalogCard({
    required this.model,
    required this.installed,
    this.needsVisionEncoder = false,
    this.isRecommended = false,
    this.onAddVision,
    required this.download,
    required this.onDownload,
    required this.onCancel,
    this.actionKey,
    this.fit = RamFit.unknown,
    this.runtimeBytes = 0,
    this.budgetBytes,
  });

  bool get blocked => !installed && fit == RamFit.tooBig;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBrand = isDark ? _brandGreen : const Color(0xFF1B8738);

    final cardBg = isDark
        ? (isRecommended ? const Color(0xFF131A22) : const Color(0xFF131722))
        : Colors.white;
    final cardBorder = isRecommended
        ? primaryBrand
        : (isDark ? const Color(0xFF263040) : const Color(0xFFCBD5E1));
    final cardShadow = isDark
        ? const [
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorder,
          width: isRecommended ? 1.5 : 1,
        ),
        boxShadow: cardShadow,
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Classical brand logo emblem
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A222E) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2B3647) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: ModelBrandLogo.catalog(model: model, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Author label in classical uppercase tracked format
                    Row(
                      children: [
                        Text(
                          model.author.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0x282CA048)
                                  : const Color(0x181B8738),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0x552CA048)
                                    : const Color(0x401B8738),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'TOP PICK',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildAction(context),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            model.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              height: 1.4,
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
          const SizedBox(height: 12),
          // Classical Specifications Bar
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip(label: model.parameters, icon: Icons.tune_rounded),
              _Chip(
                label: '${model.contextLabel} ctx',
                icon: Icons.short_text_rounded,
              ),
              if (model.mmprojUrl != null)
                const _Chip(
                  label: 'Vision Ready',
                  icon: Icons.visibility_outlined,
                  tone: _ChipTone.accent,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBrand = isDark ? _brandGreen : const Color(0xFF1B8738);

    if (installed && needsVisionEncoder) {
      return OutlinedButton.icon(
        key: actionKey,
        onPressed: onAddVision,
        icon: const Icon(Icons.visibility_rounded, size: 13),
        label: Text('+ Vision (${model.mmprojSize})'),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBrand,
          side: BorderSide(color: primaryBrand, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (installed) {
      return Container(
        key: actionKey,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x1F2CA048) : const Color(0x121B8738),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0x402CA048) : const Color(0x351B8738),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 14, color: primaryBrand),
            const SizedBox(width: 5),
            Text(
              'Installed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primaryBrand,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2533) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF2C374A) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory_rounded, size: 13, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Needs RAM',
              style: TextStyle(
                fontSize: 11.5,
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
        icon: const Icon(Icons.close_rounded, size: 18),
        tooltip: 'Cancel download',
        onPressed: onCancel,
        style: IconButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E2533) : const Color(0xFFF1F5F9),
          side: BorderSide(
            color: isDark ? const Color(0xFF2C374A) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
      );
    }
    return FilledButton.icon(
      key: actionKey,
      icon: const Icon(Icons.arrow_downward_rounded, size: 13),
      label: Text(model.approxSize),
      onPressed: onDownload,
      style: FilledButton.styleFrom(
        backgroundColor: primaryBrand,
        foregroundColor: Colors.white,
        elevation: isDark ? 0 : 1,
        shadowColor: const Color(0x301B8738),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBrand = isDark ? _brandGreen : const Color(0xFF1B8738);

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
                    fontWeight: FontWeight.w700,
                    color: primaryBrand,
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
                backgroundColor: isDark ? const Color(0xFF1E2533) : const Color(0xFFE2E8F0),
                color: primaryBrand,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isAccent = tone == _ChipTone.accent;
    final bg = isAccent
        ? (isDark ? const Color(0x242CA048) : const Color(0x141B8738))
        : (isDark ? const Color(0xFF1A222F) : const Color(0xFFF1F5F9));
    final border = isAccent
        ? (isDark ? const Color(0x552CA048) : const Color(0x401B8738))
        : (isDark ? const Color(0xFF273243) : const Color(0xFFE2E8F0));
    final fg = isAccent
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: -0.1,
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
        color: _brandGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _brandGreen,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                entries.length == 1
                    ? 'Downloading model'
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
                        ? 'Starting…'
                        : '${(fraction * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _brandGreen,
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
                  color: _brandGreen,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
