/// Endpoints card: the four main routes with samples, then the rest at a
/// glance.
library;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../l10n/server_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import 'samples.dart';
import 'server_widgets.dart';

class EndpointsCard extends StatefulWidget {
  const EndpointsCard({
    super.key,
    required this.base,
    required this.modelId,
    required this.apiKey,
  });

  final String base;
  final String modelId;

  /// The bearer token, or null when none is checked.
  final String? apiKey;

  @override
  State<EndpointsCard> createState() => _EndpointsCardState();
}

class _EndpointsCardState extends State<EndpointsCard> {
  int? _open = 0;

  @override
  Widget build(BuildContext context) {
    final s = ServerStrings.of(context);
    final l10n = context.l10n;
    final palette = DeskPalette.of(context);
    final key = widget.apiKey;
    final samples = endpointSamples(
      base: widget.base,
      model: widget.modelId,
      auth: key != null,
    );
    final titles = [
      l10n.serverEndpointOpenAiChat,
      l10n.serverEndpointOllamaChat,
      l10n.serverEndpointEmbeddings,
      l10n.serverEndpointModels,
    ];
    final more = [
      ('GET', '/api/tags', s.epTags),
      ('GET', '/api/ps', s.epPs),
      ('POST', '/api/show', s.epShow),
      ('POST', '/api/generate', s.epGenerate),
      ('POST', '/api/embed', s.epEmbed),
      ('POST', '/api/embeddings', s.epEmbeddingsLegacy),
    ];

    return ServerCard(
      icon: Icons.route_rounded,
      title: l10n.serverApiEndpointsTitle,
      subtitle: s.endpointsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DeskSize.radiusM),
              border: Border.all(color: palette.hairline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < samples.length; i++) ...[
                  if (i > 0) Container(height: 1, color: palette.hairline),
                  _EndpointRow(
                    sample: samples[i],
                    title: titles[i],
                    apiKey: key,
                    open: _open == i,
                    onToggle: () =>
                        setState(() => _open = _open == i ? null : i),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          FieldLabel(s.alsoAvailable),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth >= 640 ? 2 : 1;
              final width = (box.maxWidth - (cols - 1) * 10) / cols;
              return Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  for (final (method, path, desc) in more)
                    SizedBox(
                      width: width,
                      child: _MiniEndpoint(
                        method: method,
                        path: path,
                        description: desc,
                        url: '${widget.base}$path',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EndpointRow extends StatefulWidget {
  const _EndpointRow({
    required this.sample,
    required this.title,
    required this.apiKey,
    required this.open,
    required this.onToggle,
  });

  final EndpointSample sample;
  final String title;
  final String? apiKey;
  final bool open;
  final VoidCallback onToggle;

  @override
  State<_EndpointRow> createState() => _EndpointRowState();
}

class _EndpointRowState extends State<_EndpointRow> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = ServerStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final sample = widget.sample;
    final key = widget.apiKey;
    final shownCurl = sample.curl(key == null ? '' : maskToken(key));
    final realCurl = sample.curl(key ?? '');

    final (code, copy, lang) = switch (_tab) {
      0 => (shownCurl, realCurl, 'bash'),
      1 => (sample.request ?? '', null, 'json'),
      _ => (sample.response, null, 'json'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Hoverable(
          cursor: SystemMouseCursors.click,
          builder: (context, hovered) => GestureDetector(
            onTap: widget.onToggle,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: DeskMotion.fast,
              color: hovered || widget.open
                  ? scheme.onSurface.withValues(alpha: 0.03)
                  : Colors.transparent,
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
              child: Row(
                children: [
                  MethodBadge(sample.method),
                  const SizedBox(width: 14),
                  Text(
                    sample.path,
                    style: monoStyle(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: palette.textMuted),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: DeskMotion.fast,
                    opacity: hovered || widget.open ? 1 : 0,
                    child: DeskIconButton(
                      icon: Icons.terminal_rounded,
                      tooltip: context.l10n.serverCopyCurlTooltip,
                      iconSize: 16,
                      size: 30,
                      onPressed: () => copyWithToast(context, realCurl, 'cURL'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: widget.open ? 0.5 : 0,
                    duration: DeskMotion.medium,
                    curve: DeskMotion.ease,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: DeskMotion.medium,
          curve: DeskMotion.ease,
          alignment: Alignment.topCenter,
          child: !widget.open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PillTabs(
                        dense: true,
                        labels: [
                          s.tabCurl,
                          if (sample.request != null) s.tabRequest,
                          s.tabResponse,
                        ],
                        index: sample.request == null && _tab == 2 ? 1 : _tab,
                        onChanged: (i) => setState(
                          // Without a request body the second pill is the
                          // response, so map it back to the response slot.
                          () => _tab = sample.request == null && i == 1 ? 2 : i,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: DeskMotion.medium,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, ?current],
                        ),
                        child: CodeBlock(
                          key: ValueKey('${sample.path}$_tab'),
                          code: code,
                          copyCode: copy,
                          language: lang,
                          filename: lang,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _MiniEndpoint extends StatelessWidget {
  const _MiniEndpoint({
    required this.method,
    required this.path,
    required this.description,
    required this.url,
  });

  final String method, path, description, url;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = ServerStrings.of(context);
    return Hoverable(
      builder: (context, hovered) => AnimatedContainer(
        duration: DeskMotion.fast,
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: hovered
              ? scheme.onSurface.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DeskSize.radiusS),
        ),
        child: Row(
          children: [
            MethodBadge(method),
            const SizedBox(width: 12),
            Text(path, style: monoStyle(size: 12.5, color: scheme.onSurface)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: palette.textMuted),
              ),
            ),
            AnimatedOpacity(
              duration: DeskMotion.fast,
              opacity: hovered ? 1 : 0,
              child: DeskIconButton(
                icon: Icons.content_copy_rounded,
                tooltip: s.copyUrl,
                iconSize: 14,
                size: 28,
                onPressed: () => copyWithToast(context, url, url),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
