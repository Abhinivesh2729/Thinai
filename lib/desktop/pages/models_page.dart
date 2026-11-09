/// The desktop Models page: catalog grid, goal-based Top picks, Hugging Face
/// search, .gguf import (picker or drag and drop) and the Model Manager.
///
/// Feature parity with the phone's Models tab (docs/kb/04-models.md); the
/// state and logic are the phone's providers, only the layout is new.
library;

import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models_repo/catalog.dart';
import '../../models_repo/model_store.dart';
import '../../models_repo/recommender.dart';
import '../../models_repo/use_cases.dart';
import '../../state/providers.dart';
import '../../ui/pages/models_page.dart' show HfSearchPage;
import '../../ui/widgets/tamil_glyph_icon.dart';
import '../l10n/models_strings.dart';
import '../shell/desk_nav.dart';
import '../theme/desk_theme.dart';
import '../widgets/hover.dart';
import '../widgets/toast.dart';
import 'models/model_bits.dart';
import 'models/model_card.dart';
import 'models/model_manager_panel.dart';
import 'models/models_common.dart';
import 'models/models_toolbar.dart';

class DeskModelsPage extends StatelessWidget {
  const DeskModelsPage({super.key});

  // A nested navigator so the Hugging Face pages open inside the content
  // area, keeping the rail and title bar in place.
  @override
  Widget build(BuildContext context) => HeroControllerScope.none(
    child: Navigator(
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const _ModelsHome(),
        transitionDuration: Duration.zero,
      ),
    ),
  );
}

class _ModelsHome extends ConsumerStatefulWidget {
  const _ModelsHome();

  @override
  ConsumerState<_ModelsHome> createState() => _ModelsHomeState();
}

class _ModelsHomeState extends ConsumerState<_ModelsHome> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _scroll = ScrollController();
  final _gate = EntranceGate();
  StreamSubscription<DownloadOutcome>? _outcomes;

  String _query = '';
  ModelFilter _filter = ModelFilter.all;
  UseCase? _goal;

  bool _managerOpen = false;

  /// Kept built through the closing slide, then dropped so its live progress
  /// rows stop ticking off screen.
  bool _managerMounted = false;

  /// A notifier rather than state so dragging over the page repaints only
  /// the overlay, not the grid.
  final _dragging = ValueNotifier(false);
  bool _importing = false;

  /// The Hub page is pushed over this one; drops must not land underneath.
  bool _hubOpen = false;

  @override
  void initState() {
    super.initState();
    // In Tamil the catalog opens on Tamil-capable models, as on the phone:
    // most of the catalog cannot hold a conversation in Tamil.
    if (ref.read(isTamilUiProvider)) _goal = UseCase.tamil;
    _outcomes = ref
        .read(downloadsProvider.notifier)
        .outcomes
        .listen(_reportOutcome);
  }

  @override
  void dispose() {
    _outcomes?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    _dragging.dispose();
    super.dispose();
  }

  void _reportOutcome(DownloadOutcome outcome) {
    if (!mounted) return;
    final l = context.l10n;
    final s = ModelsStrings.of(context);
    if (outcome.cancelled) {
      showDeskToast(l.modelsToastDownloadPaused);
      return;
    }
    if (!outcome.ok) {
      final error = deskError('${outcome.error}');
      showDeskToast(
        outcome.keptBytes > 0
            ? s.downloadStopped(outcome.label, error)
            : l.modelsToastDownloadFailed(outcome.label, error),
        tone: DeskTone.error,
        lasting: const Duration(seconds: 6),
      );
      return;
    }
    final loaded =
        outcome.installed != null &&
        outcome.catalogModel?.kind == ModelKind.chat;
    showDeskToast(
      loaded
          ? l.modelsToastDownloadedAndLoaded(outcome.label)
          : l.modelsToastDownloaded(outcome.label),
      tone: DeskTone.success,
    );
  }

  // ── state changes ──────────────────────────────────────────────────────

  /// Filter and goal changes re-run the staggered entrance; typing in the
  /// search box does not, or every keystroke would replay it.
  void _setFilter(ModelFilter f) {
    if (f == _filter) return;
    setState(() {
      _filter = f;
      if (f == ModelFilter.installed || f == ModelFilter.embedding) {
        _goal = null;
      }
      _gate.reveal();
    });
    _jumpToTop();
  }

  void _setGoal(UseCase? goal) {
    setState(() {
      _goal = goal;
      if (goal != null &&
          (_filter == ModelFilter.installed ||
              _filter == ModelFilter.embedding)) {
        _filter = ModelFilter.all;
      }
      _gate.reveal();
    });
    _jumpToTop();
  }

  void _resetAll() {
    setState(() {
      _filter = ModelFilter.all;
      _goal = null;
      _query = '';
      _search.clear();
      _gate.reveal();
    });
    _jumpToTop();
  }

  void _jumpToTop() {
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(0, duration: DeskMotion.medium, curve: DeskMotion.ease);
    }
  }

  void _setManager(bool open) {
    setState(() {
      _managerOpen = open;
      if (open) _managerMounted = true;
    });
  }

  Future<void> _openHub([String query = '']) async {
    setState(() => _hubOpen = true);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HfSearchPage(initialQuery: query),
      ),
    );
    if (mounted) setState(() => _hubOpen = false);
  }

  Future<void> _import({List<String>? paths}) async {
    if (_importing) return;
    setState(() => _importing = true);
    final actions = ModelActions(context);
    try {
      if (paths == null) {
        await actions.importPicked();
      } else {
        await actions.importPaths(paths);
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _onDrop(DropDoneDetails details) {
    _dragging.value = false;
    final paths = [
      for (final f in details.files)
        if (f is! DropItemDirectory && f.path.isNotEmpty) f.path,
    ];
    if (paths.isNotEmpty) _import(paths: paths);
  }

  void _openLab() => ref.read(deskPageProvider.notifier).state = DeskPage.lab;

  // ── filtering ──────────────────────────────────────────────────────────

  bool _matchesCatalog(CatalogModel m) {
    if (_query.isEmpty) return true;
    return [
      m.displayName,
      m.author,
      m.description,
      m.parameters,
      m.approxSize,
      m.contextLabel,
      m.id,
    ].any((f) => f.toLowerCase().contains(_query));
  }

  bool _matchesInstalled(LocalModel m) =>
      _query.isEmpty ||
      m.displayName.toLowerCase().contains(_query) ||
      m.id.toLowerCase().contains(_query);

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    final active = ref.watch(
      deskPageProvider.select((p) => p == DeskPage.models),
    );

    return Material(
      type: MaterialType.transparency,
      child: CallbackShortcuts(
        bindings: {
          SingleActivator(
            LogicalKeyboardKey.keyF,
            control: !mac,
            meta: mac,
          ): () =>
              _searchFocus.requestFocus(),
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (_managerOpen) _setManager(false);
          },
        },
        child: Focus(
          autofocus: true,
          child: DropTarget(
            // The shell keeps visited pages alive underneath the current one,
            // and drop targets hit-test by bounds alone, so a hidden Models
            // page would otherwise catch files dropped on Chat.
            enable: !_hubOpen && active,
            onDragEntered: (_) => _dragging.value = true,
            onDragExited: (_) => _dragging.value = false,
            onDragDone: _onDrop,
            child: ColoredBox(
              color: palette.canvas,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final hpad = c.maxWidth > 1424
                            ? (c.maxWidth - 1360) / 2
                            : 32.0;
                        return Column(
                          children: [
                            _buildHeader(context, hpad),
                            Expanded(child: _buildBody(context, c, hpad)),
                          ],
                        );
                      },
                    ),
                  ),
                  _buildScrim(),
                  if (_managerMounted)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: kManagerWidth,
                      child: _SlidePanel(
                        open: _managerOpen,
                        onClosed: () {
                          if (mounted) setState(() => _managerMounted = false);
                        },
                        child: RepaintBoundary(
                          child: ModelManagerPanel(
                            importing: _importing,
                            onClose: () => _setManager(false),
                            onImport: _import,
                            onBrowse: () {
                              _setManager(false);
                              _resetAll();
                            },
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _dragging,
                        builder: (context, dragging, child) => AnimatedOpacity(
                          duration: DeskMotion.fast,
                          opacity: dragging ? 1 : 0,
                          child: child,
                        ),
                        child: const _DropOverlay(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrim() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_managerOpen,
        child: GestureDetector(
          onTap: () => _setManager(false),
          child: AnimatedOpacity(
            duration: DeskMotion.medium,
            curve: DeskMotion.ease,
            opacity: _managerOpen ? 1 : 0,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double hpad) {
    final l = context.l10n;
    final s = ModelsStrings.of(context);
    final palette = DeskPalette.of(context);
    final device = ref.watch(deviceProfileProvider);
    final installedCount = ref.watch(
      modelListProvider.select((a) => a.valueOrNull?.length ?? 0),
    );
    final downloading = ref.watch(downloadsProvider.select((d) => d.length));
    final hasFilter =
        _filter != ModelFilter.all || _query.isNotEmpty || _goal != null;

    final deviceLine = device.when(
      data: (d) => s.thisPc(d.localizedSummary(l)),
      loading: () => s.readingPc,
      error: (_, _) => s.readingPc,
    );

    final segments = [
      Segment(ModelFilter.all, l.modelsFilterAll, Icons.apps_rounded),
      Segment(
        ModelFilter.chat,
        l.modelsFilterChat,
        Icons.chat_bubble_outline_rounded,
      ),
      Segment(
        ModelFilter.vision,
        l.modelsFilterVision,
        Icons.visibility_outlined,
      ),
      Segment(
        ModelFilter.embedding,
        l.modelsFilterEmbedding,
        Icons.hub_outlined,
      ),
      Segment(
        ModelFilter.installed,
        installedCount > 0
            ? l.modelsFilterInstalledCount(installedCount)
            : l.modelsFilterInstalled,
        Icons.inventory_2_outlined,
      ),
    ];

    final search = ModelSearchField(
      controller: _search,
      focusNode: _searchFocus,
      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
      onClear: () => setState(() {
        _query = '';
        _search.clear();
      }),
    );
    final filters = [
      SegmentedTabs<ModelFilter>(
        segments: segments,
        selected: _filter,
        onChanged: _setFilter,
      ),
      const SizedBox(width: 10),
      GoalButton(selected: _goal, onChanged: _setGoal),
      const SizedBox(width: 4),
      AnimatedScale(
        duration: DeskMotion.medium,
        curve: DeskMotion.spring,
        scale: hasFilter ? 1 : 0.6,
        child: AnimatedOpacity(
          duration: DeskMotion.fast,
          opacity: hasFilter ? 1 : 0,
          child: IgnorePointer(
            ignoring: !hasFilter,
            child: DeskIconButton(
              icon: Icons.filter_alt_off_outlined,
              tooltip: l.modelsResetFiltersTooltip,
              size: 38,
              onPressed: _resetAll,
            ),
          ),
        ),
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(hpad, 26, hpad, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.navModels,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.memory_rounded,
                          size: 15,
                          color: palette.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: DeskMotion.medium,
                            child: Text(
                              deviceLine,
                              key: ValueKey(deviceLine),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _GlyphButton(
                tooltip: '${l.tamilEvalTooltip} · ${s.openInLab}',
                onPressed: _openLab,
                child: const TamilGlyphIcon(size: 18),
              ),
              const SizedBox(width: 2),
              DeskIconButton(
                icon: Icons.speed_rounded,
                tooltip: '${l.modelsBenchmark} · ${s.openInLab}',
                size: 38,
                onPressed: _openLab,
              ),
              const SizedBox(width: 10),
              DeskButton(
                label: _importing ? s.importing : s.importGguf,
                icon: Icons.file_open_outlined,
                style: DeskButtonStyle.quiet,
                height: 38,
                busy: _importing,
                onPressed: _import,
              ),
              const SizedBox(width: 10),
              _ManagerButton(
                installed: installedCount,
                downloading: downloading,
                open: _managerOpen,
                onPressed: () => _setManager(!_managerOpen),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              // Side by side when there is room; otherwise search gets its
              // own line and the filters scroll sideways.
              if (c.maxWidth >= 1060) {
                return Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: search,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ...filters,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: filters),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, BoxConstraints c, double hpad) {
    final l = context.l10n;
    final modelsAsync = ref.watch(modelListProvider);
    if (modelsAsync.hasError && !modelsAsync.hasValue) {
      return Center(child: Text(l.modelsError('${modelsAsync.error}')));
    }
    if (!modelsAsync.hasValue) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: DeskColors.green,
          ),
        ),
      );
    }

    const gap = 16.0;
    final content = c.maxWidth - hpad * 2;
    final cols = ((content + gap) / (300 + gap)).floor().clamp(1, 4);

    return Scrollbar(
      controller: _scroll,
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          ..._buildSlivers(context, modelsAsync.value!, hpad, cols, gap),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  List<Widget> _buildSlivers(
    BuildContext context,
    List<LocalModel> installed,
    double hpad,
    int cols,
    double gap,
  ) {
    final l = context.l10n;
    final s = ModelsStrings.of(context);
    final pad = EdgeInsets.symmetric(horizontal: hpad);
    final rawQuery = _search.text.trim();

    Widget box(Widget child, {double top = 0, double bottom = 0}) =>
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hpad, top, hpad, bottom),
          sliver: SliverToBoxAdapter(child: child),
        );

    Widget header(String id, IconData icon, String title) => box(
      GatedEntrance(
        key: ValueKey('h:$id'),
        gate: _gate,
        id: 'h:$id',
        child: SectionHeader(icon: icon, title: title),
      ),
      top: 26,
      bottom: 16,
    );

    Widget grid<T>(
      String section,
      List<T> items,
      String Function(T) idOf,
      Widget Function(T) build, {
      double extent = kCatalogCardHeight,
    }) {
      final keys = {
        for (var i = 0; i < items.length; i++) '$section:${idOf(items[i])}': i,
      };
      return SliverPadding(
        padding: pad,
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisExtent: extent,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final id = '$section:${idOf(items[i])}';
              return GatedEntrance(
                key: ValueKey(id),
                gate: _gate,
                id: id,
                child: build(items[i]),
              );
            },
            childCount: items.length,
            // Lets a card keep its element when filtering moves it, rather
            // than being torn down and rebuilt at its new index.
            findChildIndexCallback: (key) =>
                key is ValueKey<String> ? keys[key.value] : null,
          ),
        ),
      );
    }

    Widget catalogGrid(
      String section,
      List<CatalogModel> models, {
      Map<String, Recommendation> picks = const {},
    }) => grid<CatalogModel>(
      section,
      models,
      (m) => m.id,
      (m) => CatalogCard(model: m, pick: picks[m.id]),
    );

    final hubTop = _query.isEmpty
        ? null
        : box(
            _HubBanner(
              title: s.searchHubFor(rawQuery),
              body: s.searchHubBody,
              onTap: () => _openHub(rawQuery),
            ),
            bottom: 4,
          );

    // ── Installed
    if (_filter == ModelFilter.installed) {
      final mine = installed.where(_matchesInstalled).toList();
      if (mine.isEmpty) {
        return [
          ?hubTop,
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              icon: Icons.inventory_2_outlined,
              title: _query.isEmpty
                  ? l.modelsNoneInstalledYet
                  : l.modelsNoMatchQuery(rawQuery),
              body: _query.isEmpty
                  ? l.modelsNoneInstalledYetBody
                  : l.modelsNoMatchHint,
              actions: [
                DeskButton(
                  label: l.modelsBrowseCatalog,
                  icon: Icons.explore_rounded,
                  onPressed: _resetAll,
                ),
                DeskButton(
                  label: s.importGguf,
                  icon: Icons.file_open_outlined,
                  style: DeskButtonStyle.quiet,
                  onPressed: _import,
                ),
              ],
            ),
          ),
        ];
      }
      return [
        ?hubTop,
        header(
          'installed',
          Icons.inventory_2_rounded,
          l.modelsInstalledSectionTitle(mine.length),
        ),
        grid<LocalModel>(
          'inst',
          mine,
          (m) => m.path,
          (m) => InstalledCard(model: m),
          extent: kInstalledCardHeight,
        ),
      ];
    }

    // ── Catalog
    final List<CatalogModel> chat;
    final List<CatalogModel> embedding;
    switch (_filter) {
      case ModelFilter.chat:
        chat = chatCatalog
            .where((m) => !m.supportsVision && _matchesCatalog(m))
            .toList();
        embedding = const [];
      case ModelFilter.vision:
        chat = chatCatalog
            .where((m) => m.supportsVision && _matchesCatalog(m))
            .toList();
        embedding = const [];
      case ModelFilter.embedding:
        chat = const [];
        embedding = embeddingCatalog.where(_matchesCatalog).toList();
      case ModelFilter.all:
      case ModelFilter.installed:
        chat = chatCatalog.where(_matchesCatalog).toList();
        embedding = embeddingCatalog.where(_matchesCatalog).toList();
    }

    if (chat.isEmpty && embedding.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            icon: Icons.search_off_rounded,
            title: rawQuery.isEmpty
                ? l.modelsNoMatchFilters
                : l.modelsNoMatchQuery(rawQuery),
            body: l.modelsNoMatchHint,
            actions: [
              if (rawQuery.isNotEmpty)
                DeskButton(
                  label: l.modelsSearchHuggingFace,
                  icon: Icons.travel_explore_rounded,
                  onPressed: () => _openHub(rawQuery),
                ),
              DeskButton(
                label: l.modelsResetFiltersAndSearch,
                icon: Icons.filter_alt_off_outlined,
                style: DeskButtonStyle.quiet,
                onPressed: _resetAll,
              ),
            ],
          ),
        ),
      ];
    }

    final installedCatalogIds = {
      for (final m in chatCatalog)
        if (localFor(m, installed) != null) m.id,
    };

    final goal = _goal;
    RecommendationResult? rec;
    if (goal != null) {
      final speed = ref.watch(speedKnowledgeProvider);
      rec = recommend(
        goal,
        speed.device,
        installedIds: installedCatalogIds,
        speed: speed,
      );
    }
    final picks = <String, Recommendation>{
      for (final p in rec?.picks ?? const <Recommendation>[]) p.model.id: p,
    };
    final topPicks = [
      for (final p in rec?.picks ?? const <Recommendation>[])
        if (chat.any((m) => m.id == p.model.id)) p.model,
    ];
    final rest = chat.where((m) => !picks.containsKey(m.id)).toList();

    final browsingDefault =
        _filter == ModelFilter.all && _query.isEmpty && goal == null;
    final featured = browsingDefault ? featuredModel : null;
    final regular = featured == null
        ? rest
        : rest.where((m) => m.id != featured.id).toList();

    final restTitle = goal != null
        ? l.modelsOtherModels
        : switch (_filter) {
            ModelFilter.vision => l.modelsVisionModelsTitle,
            ModelFilter.chat => l.modelsChatModelsTitle,
            _ =>
              featured != null
                  ? l.modelsExploreModels
                  : l.modelsBrowseCatalogTitle,
          };
    final restIcon = switch (_filter) {
      ModelFilter.vision => Icons.visibility_rounded,
      ModelFilter.chat => Icons.chat_bubble_outline_rounded,
      _ => Icons.explore_rounded,
    };

    String? caveat;
    if (rec != null && goal != null) {
      final g = goal.localizedLabel(l);
      caveat = rec.unavailable != null
          ? rec.localizedUnavailable(l)
          : switch (rec.caveatKind) {
              RecommendationCaveat.noneFits => s.caveatNoneFits(g),
              RecommendationCaveat.nothingFitsWell => s.caveatNothingFitsWell(
                g,
              ),
              RecommendationCaveat.nothingStrong => s.caveatNothingStrong(g),
              null => null,
            };
    }

    return [
      ?hubTop,
      if (goal != null) ...[
        box(
          _GoalBanner(
            goal: goal,
            caveat: caveat,
            onClear: () => _setGoal(null),
          ),
          top: 4,
        ),
        if (topPicks.isNotEmpty) ...[
          header('picks', goal.icon, l.modelsTopPicks),
          catalogGrid('pick', topPicks, picks: picks),
        ],
      ],
      if (featured != null) ...[
        box(
          GatedEntrance(
            key: const ValueKey('featured'),
            gate: _gate,
            id: 'featured',
            child: SizedBox(
              height: kFeaturedCardHeight,
              child: CatalogCard(model: featured, featured: true),
            ),
          ),
          top: 4,
        ),
      ],
      if (regular.isNotEmpty) ...[
        header('rest$_filter', restIcon, restTitle),
        catalogGrid('cat', regular),
      ],
      if (embedding.isNotEmpty) ...[
        header('emb', Icons.hub_rounded, l.modelsEmbeddingTitle),
        catalogGrid('emb', embedding),
      ],
      if (_query.isEmpty)
        box(
          _HubBanner(
            title: s.findMoreHub,
            body: s.findMoreHubBody,
            onTap: _openHub,
          ),
          top: 32,
        ),
      box(_OfflineFooter(text: s.offlineFooter), top: 20),
    ];
  }
}

/// Slides the Model Manager in from the right edge on first build and out
/// again when [open] turns false, then reports [onClosed] so the page can
/// drop it.
class _SlidePanel extends StatefulWidget {
  const _SlidePanel({
    required this.open,
    required this.onClosed,
    required this.child,
  });

  final bool open;
  final VoidCallback onClosed;
  final Widget child;

  @override
  State<_SlidePanel> createState() => _SlidePanelState();
}

class _SlidePanelState extends State<_SlidePanel>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: DeskMotion.medium)
    ..forward();
  late final _position = Tween(begin: const Offset(1.08, 0), end: Offset.zero)
      .animate(
        CurvedAnimation(
          parent: _c,
          curve: DeskMotion.ease,
          reverseCurve: DeskMotion.exit,
        ),
      );

  @override
  void didUpdateWidget(_SlidePanel old) {
    super.didUpdateWidget(old);
    if (widget.open == old.open) return;
    if (widget.open) {
      _c.forward();
    } else {
      // A TickerFuture never completes if reopened mid-slide, so this only
      // fires once it is fully out.
      _c.reverse().then((_) {
        if (mounted && !widget.open) widget.onClosed();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !widget.open,
    child: SlideTransition(position: _position, child: widget.child),
  );
}

// ─── header pieces ──────────────────────────────────────────────────────────

/// Opens the Model Manager. The badge shows live downloads (pulsing green)
/// or, when idle, how many models are installed.
class _ManagerButton extends StatelessWidget {
  const _ManagerButton({
    required this.installed,
    required this.downloading,
    required this.open,
    required this.onPressed,
  });

  final int installed;
  final int downloading;
  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final count = downloading > 0 ? downloading : installed;
    return Tooltip(
      message: downloading > 0
          ? l.modelsManagerTooltipDownloading(downloading)
          : installed > 0
          ? l.modelsManagerTooltipInstalled(installed)
          : l.modelsManagerTitle,
      child: Hoverable(
        cursor: SystemMouseCursors.click,
        builder: (context, hovered) => GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: DeskMotion.fast,
            height: 38,
            padding: const EdgeInsets.only(left: 12, right: 8),
            decoration: BoxDecoration(
              color: open
                  ? DeskColors.green.withValues(alpha: 0.14)
                  : hovered
                  ? scheme.onSurface.withValues(alpha: 0.07)
                  : scheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: open
                    ? DeskColors.green.withValues(alpha: 0.45)
                    : palette.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.layers_rounded,
                  size: 17,
                  color: open ? DeskColors.green : scheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  l.modelsManagerTitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: DeskMotion.medium,
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: count == 0
                      ? const SizedBox(key: ValueKey('none'), width: 4)
                      : Container(
                          key: ValueKey('$downloading/$installed'),
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: downloading > 0
                                ? DeskColors.green
                                : palette.hairline,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (downloading > 0) ...[
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.6,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: downloading > 0
                                      ? Colors.white
                                      : scheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [DeskIconButton] for a widget glyph rather than an [IconData].
class _GlyphButton extends StatelessWidget {
  const _GlyphButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Hoverable(
        cursor: SystemMouseCursors.click,
        builder: (context, hovered) => GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: DeskMotion.fast,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hovered
                  ? scheme.onSurface.withValues(alpha: 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(DeskSize.radiusS + 2),
            ),
            child: IconTheme(
              data: IconThemeData(color: scheme.onSurfaceVariant, size: 18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── body pieces ────────────────────────────────────────────────────────────

class _HubBanner extends StatelessWidget {
  const _HubBanner({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return Hoverable(
      cursor: SystemMouseCursors.click,
      builder: (context, hovered) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DeskMotion.medium,
          curve: DeskMotion.ease,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: hovered
                ? Color.alphaBlend(
                    const Color(0xFFFFB000).withValues(alpha: 0.07),
                    palette.panel,
                  )
                : palette.panel,
            borderRadius: BorderRadius.circular(DeskSize.radiusL),
            border: Border.all(
              color: hovered
                  ? const Color(0xFFFFB000).withValues(alpha: 0.45)
                  : palette.hairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB000).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(DeskSize.radiusM),
                ),
                child: const Text('🤗', style: TextStyle(fontSize: 19)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSlide(
                duration: DeskMotion.fast,
                offset: Offset(hovered ? 0.2 : 0, 0),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalBanner extends StatelessWidget {
  const _GoalBanner({
    required this.goal,
    required this.caveat,
    required this.onClear,
  });

  final UseCase goal;
  final String? caveat;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = DeskPalette.of(context);
    return AnimatedSize(
      duration: DeskMotion.medium,
      curve: DeskMotion.ease,
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DeskColors.green.withValues(alpha: palette.isDark ? 0.16 : 0.10),
              DeskColors.green.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(DeskSize.radiusL),
          border: Border.all(color: DeskColors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(goal.icon, size: 22, color: DeskColors.green),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.modelsTargeting(goal.localizedLabel(l)),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caveat ?? goal.localizedBlurb(l),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: caveat != null
                          ? DeskColors.amber
                          : palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            DeskIconButton(
              icon: Icons.close_rounded,
              tooltip: l.modelsClearGoal,
              onPressed: onClear,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return Center(
      child: EnterAnimation(
        duration: DeskMotion.page,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: palette.panel,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.hairline),
                ),
                child: Icon(icon, size: 32, color: palette.textMuted),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: palette.textMuted),
              ),
              const SizedBox(height: 22),
              Wrap(spacing: 10, runSpacing: 10, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineFooter extends StatelessWidget {
  const _OfflineFooter({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.offline_pin_rounded,
          size: 15,
          color: DeskColors.green,
        ),
        const SizedBox(width: 7),
        Text(text, style: TextStyle(fontSize: 12, color: palette.textMuted)),
      ],
    );
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    final s = ModelsStrings.of(context);
    final palette = DeskPalette.of(context);
    return ColoredBox(
      color: palette.canvas.withValues(alpha: 0.82),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DeskColors.green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(DeskSize.radiusXL),
            border: Border.all(
              color: DeskColors.green.withValues(alpha: 0.7),
              width: 2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: DeskColors.green.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    size: 36,
                    color: DeskColors.green,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  s.dropTitle,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.dropBody,
                  style: TextStyle(fontSize: 13.5, color: palette.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
