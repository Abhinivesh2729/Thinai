part of 'models_page.dart';

// ─── Hugging Face search ─────────────────────────────────────────────────────
//
// A part of the Models page rather than its own library so the cards, pills,
// fit warnings and progress rows are the same widgets the catalog uses.

/// Opens the Hugging Face search, starting with [query] when there is one.
void openHubSearch(BuildContext context, {String query = ''}) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => HfSearchPage(initialQuery: query)));
}

class HfSearchPage extends ConsumerStatefulWidget {
  const HfSearchPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<HfSearchPage> createState() => _HfSearchPageState();
}

class _HfSearchPageState extends ConsumerState<HfSearchPage> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  CancelToken? _inFlight;

  String _searched = '';
  bool _loading = false;
  String? _error;
  List<HfRepo> _results = const [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().length >= 2) {
      _search(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inFlight?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    // Only after typing stops: each keystroke would otherwise be a request,
    // and the Hub rate-limits anonymous callers.
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query == _searched && _error == null && !_loading) return;
    _inFlight?.cancel();
    if (query.length < 2) {
      setState(() {
        _searched = '';
        _results = const [];
        _error = null;
        _loading = false;
      });
      return;
    }

    final token = CancelToken();
    _inFlight = token;
    setState(() {
      _searched = query;
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(hfHubProvider)
          .search(query, cancelToken: token);
      if (!mounted || token.isCancelled) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || token.isCancelled) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hugging Face')),
      body: Column(
        children: [
          _SearchBar(
            controller: _controller,
            hintText: context.l10n.hfSearchHint,
            autofocus: widget.initialQuery.isEmpty,
            onChanged: _onChanged,
            onSubmitted: (v) {
              _debounce?.cancel();
              _search(v);
            },
            onClear: () {
              _controller.clear();
              _debounce?.cancel();
              _search('');
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _HubNetworkNotice(),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _brandGreen));
    }
    if (_error != null) {
      return _HubMessage(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.hfSearchFailedTitle,
        message: _error!,
        action: OutlinedButton.icon(
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(context.l10n.hfTryAgain),
          onPressed: () {
            final q = _searched;
            _searched = '';
            _search(q);
          },
        ),
      );
    }
    if (_searched.isEmpty) {
      return _HubMessage(
        icon: Icons.travel_explore_rounded,
        title: context.l10n.hfEmptyTitle,
        message: context.l10n.hfEmptyMessage,
      );
    }
    if (_results.isEmpty) {
      return _HubMessage(
        icon: Icons.search_off_rounded,
        title: context.l10n.hfNoMatchTitle(_searched),
        message: context.l10n.hfNoMatchMessage,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _SectionHeader(
          icon: Icons.travel_explore_rounded,
          title: context.l10n.hfResultsTitle(_results.length),
          subtitle: context.l10n.hfResultsSubtitle,
        ),
        const SizedBox(height: 10),
        for (final repo in _results) ...[
          _HfRepoTile(
            repo: repo,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HfRepoPage(repoId: repo.id)),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          context.l10n.hfShowingUpTo(HfHub.searchLimit),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// One repo's files, with the same download, pause and resume controls as the
/// catalog.
class HfRepoPage extends ConsumerStatefulWidget {
  const HfRepoPage({super.key, required this.repoId});

  final String repoId;

  @override
  ConsumerState<HfRepoPage> createState() => _HfRepoPageState();
}

class _HfRepoPageState extends ConsumerState<HfRepoPage> {
  late Future<HfRepoDetail> _detail = _load();
  final _cancel = CancelToken();

  Future<HfRepoDetail> _load() =>
      ref.read(hfHubProvider).detail(widget.repoId, cancelToken: _cancel);

  @override
  void dispose() {
    _cancel.cancel();
    super.dispose();
  }

  Future<void> _download(
    CatalogModel model, {
    required RamFit fit,
    required int needs,
    required int? budget,
  }) async {
    final tooBig = fit == RamFit.tooBig;
    final l10n = context.l10n;
    final file = model.filename;
    final size = _fmtSize(model.approxBytes);
    final message = switch (fit) {
      RamFit.tooBig =>
        budget == null
            ? l10n.hfDownloadMessageTooBig(file, size)
            : l10n.hfDownloadMessageTooBigBudget(
                file,
                size,
                _fmtSize(needs),
                _fmtSize(budget),
              ),
      RamFit.tight => l10n.hfDownloadMessageTight(file, size),
      _ => l10n.hfDownloadMessage(file, size),
    };
    final confirmed = await _confirmDialog(
      context,
      title: tooBig ? l10n.hfTooBigTitle : l10n.hfDownloadTitle,
      message: message,
      confirmLabel: tooBig ? l10n.hfDownloadAnyway : l10n.commonDownload,
      destructive: tooBig,
    );
    if (!confirmed || !mounted) return;
    await ref.read(downloadsProvider.notifier).start(model);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.repoId.contains('/')
        ? widget.repoId.substring(widget.repoId.indexOf('/') + 1)
        : widget.repoId;
    return Scaffold(
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<HfRepoDetail>(
        future: _detail,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: _brandGreen),
            );
          }
          if (snap.hasError) {
            return _HubMessage(
              icon: Icons.cloud_off_rounded,
              title: context.l10n.hfOpenFailedTitle,
              message: snap.error.toString(),
              action: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(context.l10n.hfTryAgain),
                // A block, not an arrow: an arrow would hand setState the Future,
                // which it rejects.
                onPressed: () => setState(() {
                  _detail = _load();
                }),
              ),
            );
          }
          return _buildDetail(context, snap.data!);
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, HfRepoDetail detail) {
    final scheme = Theme.of(context).colorScheme;
    final device = ref.watch(speedKnowledgeProvider).device;
    final downloads = ref.watch(downloadsProvider);
    final installedIds = {
      for (final m
          in ref.watch(modelListProvider).valueOrNull ?? const <LocalModel>[])
        m.id,
    };
    final paused = <String, PartialDownload>{
      for (final p
          in ref.watch(partialDownloadsProvider).valueOrNull ??
              const <PartialDownload>[])
        p.filename: p,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _HfRepoHeader(detail: detail),
        if (detail.gated)
          _HubMessage(
            icon: Icons.lock_outline_rounded,
            title: context.l10n.hfSignInTitle,
            message: context.l10n.hfSignInMessage,
          ),
        const SizedBox(height: 6),
        _SectionHeader(
          icon: Icons.inventory_2_rounded,
          title: context.l10n.hfFilesTitle(detail.files.length),
          subtitle: context.l10n.hfFilesSubtitle,
        ),
        if (detail.skippedFiles > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              context.l10n.hfSkippedFiles(detail.skippedFiles),
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
          ),
        if (detail.files.isEmpty && !detail.gated)
          _HubMessage(
            icon: Icons.inventory_2_outlined,
            title: context.l10n.hfNothingTitle,
            message: context.l10n.hfNothingMessage,
          ),
        for (final file in detail.gated ? const <HfFile>[] : detail.files) ...[
          () {
            final model = detail.toCatalogModel(file);
            final fit = fitFor(model, device);
            final needs = runtimeBytesFor(model);
            return _HfFileTile(
              file: file,
              model: model,
              fit: fit,
              runtimeBytes: needs,
              budgetBytes: device.modelBudgetBytes,
              installed: installedIds.contains(model.servedId),
              download: downloads[model.id],
              paused: paused[model.filename],
              onDownload: () => _download(
                model,
                fit: fit,
                needs: needs,
                budget: device.modelBudgetBytes,
              ),
              onResume: () => ref.read(downloadsProvider.notifier).start(model),
              onPause: () =>
                  ref.read(downloadsProvider.notifier).cancel(model.id),
            );
          }(),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        const _HubNetworkNotice(),
      ],
    );
  }
}

/// Says plainly that this screen goes online, and when.
class _HubNetworkNotice extends StatelessWidget {
  const _HubNetworkNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.public_rounded, color: scheme.onSurfaceVariant, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.hfNetworkNotice,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubMessage extends StatelessWidget {
  const _HubMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: scheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// The catalog card's frame, shared by the Hub tiles.
BoxDecoration _hubCardDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? const Color(0xFF111722) : Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: isDark ? const Color(0xFF202A3C) : const Color(0xFFE2E8F0),
    ),
    boxShadow: isDark
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
          ],
  );
}

/// Just enough of a catalog entry for [ModelBrandLogo] to pick a logo.
CatalogModel _logoStub(String repoId) {
  final author = repoId.contains('/') ? repoId.split('/').first : '';
  return CatalogModel(
    id: repoId.toLowerCase(),
    displayName: repoId,
    author: author,
    url: '',
    filename: '',
    approxBytes: 0,
    parameters: '',
    contextTokens: 0,
    description: '',
    accent: _brandGreen,
    emoji: '',
  );
}

Widget _logoBox(BuildContext context, String repoId) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A222E) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? const Color(0xFF2A3648) : const Color(0xFFE2E8F0),
      ),
    ),
    padding: const EdgeInsets.all(7),
    child: ModelBrandLogo.catalog(model: _logoStub(repoId), size: 28),
  );
}

String _compactCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _ago(AppLocalizations l10n, DateTime when) {
  final days = DateTime.now().difference(when).inDays;
  if (days < 1) return l10n.hfAgoToday;
  if (days < 30) return l10n.hfAgoDays(days);
  if (days < 365) return l10n.hfAgoMonths((days / 30).floor());
  return l10n.hfAgoYears((days / 365).floor());
}

class _HfRepoTile extends StatelessWidget {
  const _HfRepoTile({required this.repo, required this.onTap});

  final HfRepo repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final modified = repo.lastModified;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: _hubCardDecoration(context),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _logoBox(context, repo.id),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      repo.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _SpecPill(
                          label: _compactCount(repo.downloads),
                          icon: Icons.download_rounded,
                        ),
                        _SpecPill(
                          label: _compactCount(repo.likes),
                          icon: Icons.favorite_border_rounded,
                        ),
                        if (modified != null)
                          _SpecPill(
                            label: _ago(context.l10n, modified),
                            icon: Icons.update_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _HfRepoHeader extends StatelessWidget {
  const _HfRepoHeader({required this.detail});

  final HfRepoDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final description = detail.description;
    return Container(
      decoration: _hubCardDecoration(context),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _logoBox(context, detail.id),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      context.l10n.hfByAuthor(detail.author),
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
          if (description != null) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (detail.parametersLabel.isNotEmpty)
                _SpecPill(
                  label: detail.parametersLabel,
                  icon: Icons.bolt_rounded,
                ),
              if (detail.contextLength != null)
                _SpecPill(
                  label: '${_contextLabel(detail.contextLength!)} ctx',
                  icon: Icons.receipt_long_outlined,
                ),
              _SpecPill(
                label: detail.license ?? context.l10n.hfNoLicence,
                icon: Icons.gavel_rounded,
                tone: detail.license == null
                    ? _ChipTone.neutral
                    : _ChipTone.accent,
              ),
              _SpecPill(
                label: _compactCount(detail.downloads),
                icon: Icons.download_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _contextLabel(int tokens) {
  if (tokens < 1024) return '$tokens';
  if (tokens >= 1024 * 1024) return '${(tokens / (1024 * 1024)).round()}M';
  return '${(tokens / 1024).round()}K';
}

class _HfFileTile extends StatelessWidget {
  const _HfFileTile({
    required this.file,
    required this.model,
    required this.fit,
    required this.runtimeBytes,
    required this.budgetBytes,
    required this.installed,
    required this.download,
    required this.paused,
    required this.onDownload,
    required this.onResume,
    required this.onPause,
  });

  final HfFile file;
  final CatalogModel model;
  final RamFit fit;
  final int runtimeBytes;
  final int? budgetBytes;
  final bool installed;
  final DownloadHandle? download;
  final PartialDownload? paused;
  final VoidCallback onDownload;
  final VoidCallback onResume;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fitColor = switch (fit) {
      RamFit.comfortable => isDark ? _brandGreen : const Color(0xFF1B8738),
      RamFit.tight => Colors.orange.shade800,
      RamFit.tooBig => scheme.error,
      RamFit.unknown => scheme.onSurfaceVariant,
    };
    final quant = file.quant;

    return Container(
      decoration: _hubCardDecoration(context),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.filename,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (quant != null)
                          _SpecPill(
                            label: quant,
                            icon: Icons.tune_rounded,
                            tone: _ChipTone.accent,
                          ),
                        _SpecPill(
                          label: _fmtSize(file.size),
                          icon: Icons.sd_storage_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildAction(context),
            ],
          ),
          if (!installed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.memory_rounded, size: 13, color: fitColor),
                const SizedBox(width: 4),
                Text(
                  fit.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: fitColor,
                  ),
                ),
              ],
            ),
          ],
          if (!installed && fit == RamFit.tooBig) ...[
            const SizedBox(height: 8),
            _FitWarning(
              blocked: true,
              needs: runtimeBytes,
              budget: budgetBytes,
            ),
          ],
          if (download != null) ...[
            const SizedBox(height: 10),
            _DownloadProgressRow(handle: download!),
          ] else if (paused != null && !installed) ...[
            const SizedBox(height: 10),
            _PausedProgressRow(partial: paused!),
          ],
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBrand = isDark ? _brandGreen : const Color(0xFF1B8738);

    if (installed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x222CA048) : const Color(0x141B8738),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0x552CA048) : const Color(0x401B8738),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 13, color: primaryBrand),
            const SizedBox(width: 4),
            Text(
              context.l10n.hfInstalled,
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
    if (download != null) {
      return SizedBox(
        height: 32,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.pause_rounded, size: 14),
          label: Text(context.l10n.hfPause),
          onPressed: onPause,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    final p = paused;
    return Material(
      color: primaryBrand,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: p != null ? onResume : onDownload,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                p != null
                    ? Icons.play_arrow_rounded
                    : Icons.arrow_downward_rounded,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                p != null ? _resumeLabel(p) : context.l10n.commonDownload,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entry to the Hub from the Models page: under the catalog results, or in
/// place of them when nothing in the catalog matched.
class _HubSearchPrompt extends StatelessWidget {
  const _HubSearchPrompt({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBrand = isDark ? _brandGreen : const Color(0xFF1B8738);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x142CA048) : const Color(0x0D1B8738),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0x402CA048) : const Color(0x301B8738),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.travel_explore_rounded, color: primaryBrand, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      query.isEmpty
                          ? context.l10n.hfFindMore
                          : context.l10n.hfSearchFor(query),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: primaryBrand,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.hfPromptSubtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: primaryBrand),
            ],
          ),
        ),
      ),
    );
  }
}
