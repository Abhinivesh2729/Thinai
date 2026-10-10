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
  final _scrollController = ScrollController();
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
    _scrollController.dispose();
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

  void _openModelManager(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModelManagerSheet(
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
                ? 'Downloading (${downloads.length}) · Model Manager'
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
              child: const Icon(
                Icons.layers_rounded,
              ),
            ),
            onPressed: () => _openModelManager(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _search,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            onClear: () {
              setState(() {
                _query = '';
                _search.clear();
              });
            },
          ),
          _DropdownFilterBar(
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
            onOpenGoalPicker: () => _openGoalPickerSheet(context),
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
      installedKeys.add(m.id.toLowerCase());
      installedKeys.add(m.displayName.toLowerCase());
    }

    bool isModelInstalled(CatalogModel m) =>
        installedKeys.contains(_normalizeModelKey(m.id)) ||
        installedKeys.contains(_normalizeModelKey(m.filename)) ||
        installedKeys.contains(_normalizeModelKey(m.displayName)) ||
        installedKeys.contains(m.id.toLowerCase()) ||
        installedKeys.contains(m.filename.toLowerCase()) ||
        installedKeys.contains(m.displayName.toLowerCase());

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
        controller: _scrollController,
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
          installed: isModelInstalled(m),
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
        if (isModelInstalled(m))
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

    final isBrowsingDefault =
        _filter == ModelFilter.all && _query.isEmpty && _selectedUseCase == null;

    final CatalogModel? featured =
        isBrowsingDefault && chatModels.isNotEmpty ? chatModels.first : null;

    final List<CatalogModel> regularChatModels = (featured != null && isBrowsingDefault)
        ? chatModels.sublist(1)
        : remainingChatModels;

    return ListView(
      controller: _scrollController,
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

        // Featured Models Hero Section
        if (featured != null) ...[
          _SectionHeader(
            icon: Icons.auto_awesome_rounded,
            title: 'Featured Models',
            subtitle: 'Handpicked for you',
            trailing: Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          _FeaturedHeroCard(
            model: featured,
            fit: fitFor(featured, device),
            runtimeBytes: runtimeBytesFor(featured),
            budgetBytes: device.modelBudgetBytes,
            installed: isModelInstalled(featured),
            needsVisionEncoder: missingEncoders.contains(featured.id),
            onAddVision: () =>
                ref.read(downloadsProvider.notifier).addVisionSupport(featured),
            download: downloads[featured.id],
            onDownload: () => ref.read(downloadsProvider.notifier).start(featured),
            onCancel: () => ref.read(downloadsProvider.notifier).cancel(featured.id),
            actionKey: CoachMarkTargets.firstCatalogAction,
          ),
          const SizedBox(height: 16),
        ],

        // Browse / Remaining Chat models
        if (regularChatModels.isNotEmpty) ...[
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
                        : (featured != null ? 'Explore Models' : 'Browse catalog'))),
            subtitle: _selectedUseCase != null
                ? 'All other available models'
                : (_filter == ModelFilter.vision
                    ? 'Multimodal · image & visual analysis'
                    : 'Curated GGUF models · one-tap download'),
          ),
          const SizedBox(height: 10),
          for (final m in regularChatModels) ...[
            catalogCard(
              m,
              actionKey: (featured == null && identical(m, regularChatModels.first))
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

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasText
                ? _brandGreen
                : (isDark ? const Color(0xFF263040) : const Color(0xFFCBD5E1)),
            width: hasText ? 1.5 : 1,
          ),
          boxShadow: isDark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0A000000),
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
              color: hasText
                  ? _brandGreen
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (hasText)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Clear search',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownFilterBar extends StatelessWidget {
  final ModelFilter selected;
  final UseCase? selectedUseCase;
  final int installedCount;
  final bool hasActiveFilter;
  final ValueChanged<ModelFilter> onSelected;
  final VoidCallback onOpenGoalPicker;
  final VoidCallback onClearGoal;
  final VoidCallback onResetAll;

  const _DropdownFilterBar({
    required this.selected,
    required this.selectedUseCase,
    required this.installedCount,
    required this.hasActiveFilter,
    required this.onSelected,
    required this.onOpenGoalPicker,
    required this.onClearGoal,
    required this.onResetAll,
  });

  String _filterLabel(ModelFilter filter) {
    switch (filter) {
      case ModelFilter.all:
        return 'All Models';
      case ModelFilter.chat:
        return 'Chat Models';
      case ModelFilter.vision:
        return 'Vision Models';
      case ModelFilter.embedding:
        return 'Embedding';
      case ModelFilter.installed:
        return installedCount > 0 ? 'Installed ($installedCount)' : 'Installed';
    }
  }

  IconData _filterIcon(ModelFilter filter) {
    switch (filter) {
      case ModelFilter.all:
        return Icons.grid_view_rounded;
      case ModelFilter.chat:
        return Icons.chat_bubble_outline_rounded;
      case ModelFilter.vision:
        return Icons.visibility_outlined;
      case ModelFilter.embedding:
        return Icons.hub_outlined;
      case ModelFilter.installed:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCategoryFiltered = selected != ModelFilter.all;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          // 1. Sleek Dropdown Styled Filter Picker
          PopupMenuButton<ModelFilter>(
            tooltip: 'Filter Category',
            initialValue: selected,
            onSelected: onSelected,
            offset: const Offset(0, 42),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark ? const Color(0xFF263040) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            color: isDark ? const Color(0xFF131722) : Colors.white,
            itemBuilder: (context) => [
              _buildMenuItem(ModelFilter.all, isDark),
              _buildMenuItem(ModelFilter.chat, isDark),
              _buildMenuItem(ModelFilter.vision, isDark),
              _buildMenuItem(ModelFilter.embedding, isDark),
              _buildMenuItem(ModelFilter.installed, isDark),
            ],
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isCategoryFiltered
                    ? const Color(0xFF2CA048).withValues(alpha: isDark ? 0.22 : 0.12)
                    : (isDark ? const Color(0xFF131722) : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCategoryFiltered
                      ? const Color(0xFF2CA048)
                      : (isDark ? const Color(0xFF263040) : const Color(0xFFCBD5E1)),
                  width: isCategoryFiltered ? 1.5 : 1,
                ),
                boxShadow: !isDark && !isCategoryFiltered
                    ? const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _filterIcon(selected),
                    size: 15,
                    color: isCategoryFiltered
                        ? const Color(0xFF2CA048)
                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _filterLabel(selected),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isCategoryFiltered ? FontWeight.w800 : FontWeight.w600,
                      color: isCategoryFiltered
                          ? const Color(0xFF2CA048)
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                    color: isCategoryFiltered
                        ? const Color(0xFF2CA048)
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 2. Classical Goals / Smart Match Button
          Material(
            color: selectedUseCase != null
                ? const Color(0xFF2CA048).withValues(alpha: isDark ? 0.22 : 0.12)
                : (isDark ? const Color(0xFF131722) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            elevation: !isDark && selectedUseCase == null ? 0.5 : 0,
            shadowColor: const Color(0x08000000),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onOpenGoalPicker,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selectedUseCase != null
                        ? const Color(0xFF2CA048)
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
                      size: 14.5,
                      color: selectedUseCase != null
                          ? const Color(0xFF2CA048)
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      selectedUseCase != null ? selectedUseCase!.label : 'Goals',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selectedUseCase != null ? FontWeight.w800 : FontWeight.w600,
                        color: selectedUseCase != null
                            ? const Color(0xFF2CA048)
                            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                      ),
                    ),
                    if (selectedUseCase != null) ...[
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: onClearGoal,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: Color(0xFF2CA048),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // 3. Reset Button (Appears if any filter, goal or search query is active)
          if (hasActiveFilter)
            Material(
              color: scheme.error.withValues(alpha: isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onResetAll,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
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
                        Icons.refresh_rounded,
                        size: 14,
                        color: scheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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

  PopupMenuItem<ModelFilter> _buildMenuItem(ModelFilter filter, bool isDark) {
    final isSelected = selected == filter;
    final label = _filterLabel(filter);
    final icon = _filterIcon(filter);

    return PopupMenuItem<ModelFilter>(
      value: filter,
      height: 42,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? const Color(0xFF2CA048)
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2CA048)
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_rounded,
              size: 17,
              color: Color(0xFF2CA048),
            ),
        ],
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

class _ModelManagerSheet extends ConsumerWidget {
  final ValueChanged<LocalModel> onActivate;
  final ValueChanged<LocalModel> onDelete;
  final ValueChanged<String> onCancelDownload;
  final VoidCallback onBrowseCatalog;

  const _ModelManagerSheet({
    required this.onActivate,
    required this.onDelete,
    required this.onCancelDownload,
    required this.onBrowseCatalog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final installed = ref.watch(modelListProvider).valueOrNull ?? const <LocalModel>[];
    final activeId = ref.watch(activeModelIdProvider);
    final downloads = ref.watch(downloadsProvider);
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
                  child: const Icon(
                    Icons.layers_rounded,
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
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBrand = isDark ? _brandGreen : const Color(0xFF1B8738);

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
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
                    fontSize: 15.5,
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
          ?trailing,
        ],
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
        final isDone = p?.done ?? false;
        final isCancelled = p?.cancelled ?? false;
        final hasError = p?.error != null;

        String statusText;
        if (isDone) {
          if (isCancelled) {
            statusText = 'Cancelled';
          } else if (hasError) {
            statusText = 'Failed';
          } else {
            statusText = '100% · Completed';
          }
        } else if (fraction != null) {
          statusText = '${(fraction * 100).toStringAsFixed(0)}%';
        } else {
          statusText = 'Starting…';
        }

        String sizeText = '';
        if (p != null) {
          if (p.total != null && p.total! > 0) {
            sizeText = '${_fmtSize(p.received)} / ${_fmtSize(p.total!)}';
          } else if (p.received > 0) {
            sizeText = _fmtSize(p.received);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: (isDone && hasError) ? scheme.error : primaryBrand,
                  ),
                ),
                const Spacer(),
                if (sizeText.isNotEmpty)
                  Text(
                    sizeText,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: isDone ? 1.0 : fraction,
                minHeight: 6,
                backgroundColor: isDark ? const Color(0xFF1E2533) : const Color(0xFFE2E8F0),
                color: (isDone && hasError) ? scheme.error : primaryBrand,
              ),
            ),
          ],
        );
      },
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
        ? (isDark ? const Color(0xFF111E1D) : const Color(0xFFF0FDF4))
        : (isDark ? const Color(0xFF111622) : Colors.white);
    final cardBorder = active
        ? primaryBrand
        : (isDark ? const Color(0xFF202A3C) : const Color(0xFFE2E8F0));
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
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
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
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A222E) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: active
                        ? primaryBrand.withValues(alpha: 0.45)
                        : (isDark ? const Color(0xFF2B3647) : const Color(0xFFE2E8F0)),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: ModelBrandLogo.local(model: model, size: 28),
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
                        fontSize: 15.5,
                        letterSpacing: -0.2,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _SpecPill(
                          label: _fmtSize(model.sizeBytes),
                          icon: Icons.storage_rounded,
                        ),
                        const SizedBox(width: 8),
                        if (active)
                          const _SpecPill(
                            label: 'Active in Chat',
                            icon: Icons.bolt_rounded,
                            color: Color(0xFF2CA048),
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

/// Visual taxonomy classification for catalog model cards
enum _ModelVisualKind {
  vision,
  embedding,
  reasoning,
  text,
}

_ModelVisualKind _classifyModel(CatalogModel model) {
  if (model.supportsVision || model.mmprojUrl != null) {
    return _ModelVisualKind.vision;
  }
  if (model.kind == ModelKind.embedding) {
    return _ModelVisualKind.embedding;
  }
  final lowerId = model.id.toLowerCase();
  final lowerDesc = model.description.toLowerCase();
  if (lowerId.contains('deepseek') ||
      lowerId.contains('coder') ||
      lowerId.contains('code') ||
      lowerId.contains('granite') ||
      lowerId.contains('math') ||
      lowerDesc.contains('reasoning') ||
      lowerDesc.contains('coding') ||
      lowerDesc.contains('code generation')) {
    return _ModelVisualKind.reasoning;
  }
  return _ModelVisualKind.text;
}

/// Category badge pill shown on model cards to instantly identify model type
class _CategoryBadge extends StatelessWidget {
  final _ModelVisualKind kind;
  final bool isDark;

  const _CategoryBadge({
    required this.kind,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (kind) {
      _ModelVisualKind.vision => (
          'VISION',
          Icons.visibility_rounded,
          const Color(0xFF6366F1),
        ),
      _ModelVisualKind.embedding => (
          'EMBED',
          Icons.hub_rounded,
          const Color(0xFFF59E0B),
        ),
      _ModelVisualKind.reasoning => (
          'REASON',
          Icons.psychology_rounded,
          const Color(0xFF0EA5E9),
        ),
      _ModelVisualKind.text => (
          'TEXT',
          Icons.chat_bubble_outline_rounded,
          const Color(0xFF2CA048),
        ),
    };

    final bg = color.withValues(alpha: isDark ? 0.16 : 0.10);
    final border = color.withValues(alpha: isDark ? 0.32 : 0.22);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9.5, color: color),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic celestial wave & sparkle pattern painter for the Featured Hero card
class _FeaturedPatternPainter extends CustomPainter {
  final bool isDark;

  const _FeaturedPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glowing harmonic emerald ribbons
    final ribbonPaint = Paint()
      ..color = (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981))
          .withValues(alpha: isDark ? 0.16 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..isAntiAlias = true;

    final secondaryPaint = Paint()
      ..color = (isDark ? const Color(0xFF10B981) : const Color(0xFF059669))
          .withValues(alpha: isDark ? 0.09 : 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    // Wave 1
    final p1 = Path();
    p1.moveTo(0, h * 0.40);
    p1.cubicTo(w * 0.28, h * 0.15, w * 0.65, h * 0.68, w, h * 0.32);
    canvas.drawPath(p1, ribbonPaint);

    // Wave 2
    final p2 = Path();
    p2.moveTo(0, h * 0.58);
    p2.cubicTo(w * 0.35, h * 0.85, w * 0.72, h * 0.30, w, h * 0.58);
    canvas.drawPath(p2, ribbonPaint);

    // Wave 3 (ambient echo)
    final p3 = Path();
    p3.moveTo(0, h * 0.74);
    p3.cubicTo(w * 0.40, h * 0.96, w * 0.78, h * 0.46, w, h * 0.78);
    canvas.drawPath(p3, secondaryPaint);

    // Sparkling 4-point starbursts (✦)
    final sparklePaint = Paint()
      ..color = (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669))
          .withValues(alpha: isDark ? 0.28 : 0.16)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    _drawSparkle(canvas, Offset(w * 0.80, h * 0.22), 6.0, sparklePaint);
    _drawSparkle(canvas, Offset(w * 0.92, h * 0.46), 4.5, sparklePaint);
    _drawSparkle(canvas, Offset(w * 0.68, h * 0.84), 5.0, sparklePaint);
    _drawSparkle(canvas, Offset(w * 0.14, h * 0.82), 4.0, sparklePaint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double r, Paint paint) {
    final p = Path();
    p.moveTo(center.dx, center.dy - r);
    p.quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy);
    p.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r);
    p.quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy);
    p.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r);
    p.close();
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant _FeaturedPatternPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}


/// Atmospheric hero card modeled directly after the user's featured models design
class _FeaturedHeroCard extends StatelessWidget {
  final CatalogModel model;
  final bool installed;
  final bool needsVisionEncoder;
  final VoidCallback? onAddVision;
  final DownloadHandle? download;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final Key? actionKey;
  final RamFit fit;
  final int runtimeBytes;
  final int? budgetBytes;

  const _FeaturedHeroCard({
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

  bool get blocked => !installed && fit == RamFit.tooBig;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final capTag = _capabilityTagFor(model);

    // Deep celestial emerald gradient in dark mode; fresh mint-emerald in light mode
    final cardGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E241B), Color(0xFF071510)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDF4), Color(0xFFE4F9EB)],
          );
    final cardBorder = isDark
        ? const Color(0xFF1E4D38)
        : const Color(0xFF86EFAC);
    final cardShadow = isDark
        ? const [
            BoxShadow(
              color: Color(0x60000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x2010B981),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x1215803D),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Celestial wave & sparkles background pattern
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FeaturedPatternPainter(isDark: isDark),
                ),
              ),
            ),
            // Glowing emerald corner wave aura in bottom right
            Positioned(
              right: -30,
              bottom: -30,
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.12),
                        const Color(0xFF059669).withValues(alpha: isDark ? 0.10 : 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Brand emblem + GOOGLE + Gemma 3 · 270M Instruct + Popular Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF132B20) : Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: isDark ? const Color(0xFF235A40) : const Color(0xFF86EFAC),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(7),
                        child: ModelBrandLogo.catalog(model: model, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  model.author.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2CA048).withValues(alpha: isDark ? 0.24 : 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
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
                                letterSpacing: -0.2,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // "🔥 Popular" pill badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF133624) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF225E3F) : const Color(0xFF86EFAC),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              'Popular',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  // Bottom Specs & Action Row (Clean, no redundant description clutter)
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _SpecPill(
                              label: model.parameters,
                              icon: Icons.bolt_rounded,
                              isDarkCard: isDark,
                            ),
                            _SpecPill(
                              label: '${model.contextLabel} ctx',
                              icon: Icons.receipt_long_outlined,
                              isDarkCard: isDark,
                            ),
                            _SpecPill(
                              label: capTag.$2,
                              icon: capTag.$1,
                              isDarkCard: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHeroAction(context, isDark: isDark),
                    ],
                  ),
                  if (download != null) ...[
                    const SizedBox(height: 12),
                    _DownloadProgressRow(handle: download!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroAction(BuildContext context, {required bool isDark}) {
    if (installed && needsVisionEncoder) {
      return OutlinedButton.icon(
        key: actionKey,
        onPressed: onAddVision,
        icon: const Icon(Icons.visibility_rounded, size: 13),
        label: Text('+ Vision (${model.mmprojSize})'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4ADE80),
          side: const BorderSide(color: Color(0xFF4ADE80), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (installed) {
      return Container(
        key: actionKey,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x282CA048),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0x552CA048),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF4ADE80)),
            SizedBox(width: 4),
            Text(
              'Installed',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4ADE80),
              ),
            ),
          ],
        ),
      );
    }
    if (download != null) {
      return SizedBox(
        height: 34,
        child: OutlinedButton.icon(
          key: actionKey,
          icon: Icon(
            Icons.close_rounded,
            size: 14,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
          label: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return Material(
      color: _brandGreen,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 1,
      shadowColor: const Color(0x302CA048),
      child: InkWell(
        key: actionKey,
        borderRadius: BorderRadius.circular(16),
        onTap: onDownload,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                model.approxSize,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white),
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
    final auraColor = _vendorAuraColor(model);
    final capTag = _capabilityTagFor(model);
    final visualKind = _classifyModel(model);

    final cardBg = isDark
        ? (isRecommended ? const Color(0xFF131A24) : const Color(0xFF111722))
        : Colors.white;
    final cardBorder = isRecommended
        ? primaryBrand
        : (isDark ? const Color(0xFF202A3C) : const Color(0xFFE2E8F0));
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
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardBorder,
          width: isRecommended ? 1.5 : 1,
        ),
        boxShadow: cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Atmospheric vendor-specific corner aura glow
            Positioned(
              right: -30,
              bottom: -30,
              child: IgnorePointer(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        auraColor.withValues(alpha: isDark ? 0.16 : 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Brand logo emblem
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A222E) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2A3648) : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(7),
                        child: ModelBrandLogo.catalog(model: model, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  model.author.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _CategoryBadge(
                                  kind: visualKind,
                                  isDark: isDark,
                                ),
                                if (isRecommended) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0x282CA048)
                                          : const Color(0x181B8738),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'TOP PICK',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
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
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3-dots details menu button
                      SizedBox(
                        height: 28,
                        width: 28,
                        child: IconButton(
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Model details',
                          onPressed: () => _openModelDetailsSheet(
                            context,
                            model: model,
                            installed: installed,
                            fit: fit,
                            runtimeBytes: runtimeBytes,
                            budgetBytes: budgetBytes,
                            onDownload: onDownload,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (blocked || (!installed && fit == RamFit.tight)) ...[
                    const SizedBox(height: 8),
                    _FitWarning(
                      blocked: blocked,
                      needs: runtimeBytes,
                      budget: budgetBytes,
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Specifications & Action Row (Clean, no repetitive description text)
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _SpecPill(
                              label: model.parameters,
                              icon: Icons.bolt_rounded,
                            ),
                            _SpecPill(
                              label: '${model.contextLabel} ctx',
                              icon: Icons.receipt_long_outlined,
                            ),
                            _SpecPill(
                              label: capTag.$2,
                              icon: capTag.$1,
                            ),
                            if (model.dimensions != null)
                              _SpecPill(
                                label: '${model.dimensions} dims',
                                icon: Icons.scatter_plot_rounded,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildAction(context),
                    ],
                  ),
                  if (download != null) ...[
                    const SizedBox(height: 10),
                    _DownloadProgressRow(handle: download!),
                  ],
                ],
              ),
            ),
          ],
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (installed) {
      return Container(
        key: actionKey,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x222CA048) : const Color(0x141B8738),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0x552CA048) : const Color(0x401B8738),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 13, color: primaryBrand),
            const SizedBox(width: 4),
            Text(
              'Installed',
              style: TextStyle(
                fontSize: 11.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2533) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2C374A) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory_rounded, size: 12, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Needs RAM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    if (download != null) {
      return SizedBox(
        height: 32,
        child: OutlinedButton.icon(
          key: actionKey,
          icon: const Icon(Icons.close_rounded, size: 14),
          label: const Text('Cancel'),
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    return Material(
      color: primaryBrand,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        key: actionKey,
        borderRadius: BorderRadius.circular(16),
        onTap: onDownload,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x251B8738),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_downward_rounded, size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                model.approxSize,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

void _openModelDetailsSheet(
  BuildContext context, {
  required CatalogModel model,
  required bool installed,
  required RamFit fit,
  required int runtimeBytes,
  required int? budgetBytes,
  required VoidCallback onDownload,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final capTag = _capabilityTagFor(model);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF263040) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A222E) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A3648) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: ModelBrandLogo.catalog(model: model, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 2),
                    Text(
                      model.displayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            model.description,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DetailSpecTile(
                title: 'Parameters',
                value: model.parameters,
                icon: Icons.bolt_rounded,
              ),
              _DetailSpecTile(
                title: 'Context Window',
                value: '${model.contextLabel} tokens',
                icon: Icons.receipt_long_outlined,
              ),
              _DetailSpecTile(
                title: 'Download Size',
                value: model.approxSize,
                icon: Icons.download_rounded,
              ),
              _DetailSpecTile(
                title: 'Capability',
                value: capTag.$2,
                icon: capTag.$1,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!installed)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                label: Text('Download ${model.approxSize}'),
                style: FilledButton.styleFrom(
                  backgroundColor: _brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onDownload();
                },
              ),
            ),
        ],
      ),
    ),
  );
}

class _DetailSpecTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DetailSpecTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181F2C) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF263345) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

Color _vendorAuraColor(CatalogModel model) {
  final author = model.author.toLowerCase();
  final id = model.id.toLowerCase();
  if (author.contains('liquid') || id.contains('lfm')) {
    return const Color(0xFF06B6D4);
  }
  if (author.contains('alibaba') || id.contains('qwen')) {
    return const Color(0xFF8B5CF6);
  }
  if (author.contains('meta') || id.contains('llama')) {
    return const Color(0xFF3B82F6);
  }
  if (author.contains('mistral') || id.contains('ministral')) {
    return const Color(0xFF10B981);
  }
  if (author.contains('google') || id.contains('gemma')) {
    return const Color(0xFF0EA5E9);
  }
  if (author.contains('microsoft') || id.contains('phi')) {
    return const Color(0xFF10B981);
  }
  if (author.contains('deepseek')) {
    return const Color(0xFF2563EB);
  }
  if (author.contains('ibm') || id.contains('granite')) {
    return const Color(0xFF3B82F6);
  }
  if (author.contains('hugging') || id.contains('smol')) {
    return const Color(0xFFF59E0B);
  }
  return model.accent;
}

(IconData, String) _capabilityTagFor(CatalogModel model) {
  if (model.supportsVision) {
    return (Icons.visibility_outlined, 'Vision Ready');
  }
  if (model.kind == ModelKind.embedding) {
    return (Icons.hub_outlined, 'Embeddings');
  }
  final id = model.id.toLowerCase();
  final params = model.parameters.toLowerCase();
  if (params.contains('270') ||
      params.contains('350') ||
      params.contains('0.5') ||
      params.contains('0.6') ||
      params.contains('0.8')) {
    if (id.contains('lfm') || id.contains('smol')) {
      return (Icons.eco_outlined, 'Lightweight');
    }
    return (Icons.bolt_rounded, 'Fast & Efficient');
  }
  if (id.contains('qwen') || id.contains('gemma-4') || id.contains('smollm3')) {
    return (Icons.public_outlined, 'Multilingual');
  }
  if (id.contains('mistral') ||
      id.contains('phi') ||
      id.contains('deepseek') ||
      id.contains('granite')) {
    return (Icons.code_rounded, 'Code · Reasoning');
  }
  return (Icons.navigation_outlined, 'Instruct');
}

enum _ChipTone { neutral, accent }

class _SpecPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isDarkCard;
  final _ChipTone tone;

  const _SpecPill({
    required this.label,
    this.icon,
    this.color,
    this.isDarkCard = false,
    this.tone = _ChipTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkCard || Theme.of(context).brightness == Brightness.dark;
    final isAccent = tone == _ChipTone.accent;

    final bg = isAccent
        ? (isDark ? const Color(0x282CA048) : const Color(0x161B8738))
        : (isDark ? const Color(0xFF17202C) : const Color(0xFFF1F5F9));
    final border = isAccent
        ? (isDark ? const Color(0x552CA048) : const Color(0x401B8738))
        : (isDark ? const Color(0xFF263345) : const Color(0xFFE2E8F0));
    final fg = color ??
        (isAccent
            ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.5, color: fg),
            const SizedBox(width: 4),
          ],
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

typedef _Chip = _SpecPill;

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
