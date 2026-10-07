import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models_repo/catalog.dart';
import '../../models_repo/model_store.dart';
import '../../server/foreground_handler.dart';
import '../../state/providers.dart';
import '../widgets/floating_lines_background.dart';
import '../widgets/model_settings_sheet.dart';
import 'settings_page.dart';

/// Accent per protocol family, so a glance separates the app's own routes from
/// the OpenAI compatibility layer.
// On-brand green accents (brand green #2A8C4A). Native routes use green shades;
// the OpenAI compatibility layer uses a deeper green to set it apart.
const _nativeChat = Color(0xFF2CA048);
const _nativeEmbed = Color(0xFF2EA043);
const _nativeModels = Color(0xFF16A34A);
const _openAi = Color(0xFF15803D);

/// Brand green for the primary CTA (Start/Stop button). Fixed (not scheme-
/// derived) so the button reads the same in both light and dark themes.
const _brandDeep = Color(0xFF2CA048);

/// The model id to quote in embedding examples.
///
/// Deliberately not the active model: the active model is a chat model, and
/// the embedding endpoints reject those (no pooling layer), so pasting it
/// would hand the user a curl that 400s. Prefer an embedding model they have
/// actually installed; fall back to a placeholder when they have none.
String _embeddingIdFor(List<LocalModel>? installed) {
  final known = {for (final m in embeddingCatalog) m.servedId};
  for (final m in installed ?? const <LocalModel>[]) {
    if (known.contains(m.id)) return m.id;
  }
  return 'embedding-model-id';
}

class ServerPage extends ConsumerStatefulWidget {
  const ServerPage({super.key});

  @override
  ConsumerState<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends ConsumerState<ServerPage> {
  final _portController = TextEditingController(text: '11434');

  @override
  void initState() {
    super.initState();
    // Show the port the server is actually on. After an auto-resume the
    // running server may be on a port the user set in an earlier session, and
    // a field reading 11434 next to a server on 8080 is just wrong.
    _restorePort();
  }

  Future<void> _restorePort() async {
    final port = await ref.read(savedServerPortProvider.future);
    if (!mounted) return;
    _portController.text = '$port';
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final port = int.tryParse(_portController.text.trim()) ?? 11434;
    final lan = ref.read(lanShareProvider);
    await _ensurePermissions();
    await ref
        .read(serverControllerProvider.notifier)
        .start(port: port, lanMode: lan);
    final status = ref.read(serverControllerProvider);
    if (status.running) {
      await ForegroundServiceManager.serverStarted(
        port: status.port,
        lan: status.lan,
        ip: status.lanIp,
      );
      if (mounted && status.lan && status.lanIp == null) {
        _toast('Sharing on, but no Wi-Fi/LAN address was found.');
      }
    } else if (status.error != null && mounted) {
      _toast('Start failed: ${status.error}');
    }
  }

  Future<void> _stop() async {
    await ForegroundServiceManager.serverStopped();
    await ref.read(serverControllerProvider.notifier).stop();
  }

  /// Flips network sharing. If the server is already running, rebind it so the
  /// new binding (loopback vs LAN) takes effect immediately.
  Future<void> _setLanShare(bool value) async {
    await ref.read(lanShareProvider.notifier).set(value);
    if (ref.read(serverControllerProvider).running) {
      await _stop();
      await _start();
    }
  }

  Future<void> _ensurePermissions() async {
    await Permission.notification.request();
    await FlutterForegroundTask.canDrawOverlays;
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = ref.watch(serverControllerProvider);
    final activeId = ref.watch(activeModelIdProvider);
    final installed = ref.watch(modelListProvider).valueOrNull;
    final lanShare = ref.watch(lanShareProvider);
    final deviceIp = ref.watch(deviceLanIpProvider).valueOrNull;

    // When sharing on the network, quote the LAN IP in the copyable examples
    // so they work from other devices; otherwise keep them on loopback.
    final apiHost =
        lanShare ? (status.lanIp ?? deviceIp ?? '127.0.0.1') : '127.0.0.1';
    final base = 'http://$apiHost:${status.port}';
    final chatId = activeId ?? 'model-id';
    final embedId = _embeddingIdFor(installed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _HeroCard(
            running: status.running,
            port: status.port,
            lan: status.lan,
            lanIp: status.lanIp,
            activeId: activeId,
            portController: _portController,
            onStart: _start,
            onStop: _stop,
          ),
          if (activeId != null) ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.tune_rounded, color: scheme.onSurface),
                title: const Text('Context & temperature'),
                subtitle: Text(
                  'What $activeId is served with. Requests can override it.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final model =
                      await ref.read(modelStoreProvider).findById(activeId);
                  if (model == null || !context.mounted) return;
                  await showModelSettingsSheet(context, model);
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          _NetworkShareCard(
            enabled: lanShare,
            running: status.running,
            lanIp: status.running ? status.lanIp : null,
            deviceIp: deviceIp,
            port: status.port,
            onChanged: _setLanShare,
          ),
          if (lanShare) ...[
            const SizedBox(height: 12),
            const _LanApiTokenCard(),
          ],
          const SizedBox(height: 14),
          _DeveloperQuickStartCard(
            base: base,
            apiHost: apiHost,
            port: status.port,
            chatId: chatId,
            lanShare: lanShare,
          ),
          const SizedBox(height: 20),
          _ApiReferenceHeader(base: base),
          const SizedBox(height: 12),
          _EndpointGroup(
            icon: Icons.chat_rounded,
            title: 'Chat & Completions',
            subtitle: 'Generate text, chat completions, or streaming responses',
            cards: [
              _EndpointCard(
                icon: Icons.bolt_rounded,
                accent: _openAi,
                title: 'OpenAI Chat Completions',
                protocol: 'OpenAI-compatible',
                path: '/v1/chat/completions',
                fullUrl: '$base/v1/chat/completions',
                description:
                    'Standard OpenAI endpoint. Connects directly to Continue, Cursor, Cline, and Python.',
                curl:
                    'curl $base/v1/chat/completions -H "Content-Type: application/json" -d \'{"model":"$chatId","messages":[{"role":"user","content":"hi"}],"stream":false}\'',
              ),
              _EndpointCard(
                icon: Icons.chat_rounded,
                accent: _nativeChat,
                title: 'Ollama Streaming Chat',
                protocol: 'Thinai / Ollama · NDJSON stream',
                path: '/api/chat',
                fullUrl: '$base/api/chat',
                description:
                    'Streams token responses line-by-line for interactive chat applications.',
                curl:
                    'curl $base/api/chat -d \'{"model":"$chatId","messages":[{"role":"user","content":"hi"}]}\'',
              ),
              _EndpointCard(
                icon: Icons.edit_note_rounded,
                accent: _nativeChat,
                title: 'Single Prompt Generation',
                protocol: 'Thinai / Ollama · single prompt',
                path: '/api/generate',
                fullUrl: '$base/api/generate',
                description:
                    'Sends a raw text prompt and returns the generated continuation.',
                curl:
                    'curl $base/api/generate -d \'{"model":"$chatId","prompt":"hi","stream":false}\'',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _EndpointGroup(
            icon: Icons.scatter_plot_rounded,
            title: 'Text Embeddings',
            subtitle: 'Convert text into vector embeddings for semantic search and RAG',
            cards: [
              _EndpointCard(
                icon: Icons.bolt_rounded,
                accent: _openAi,
                title: 'OpenAI Embeddings',
                protocol: 'OpenAI-compatible',
                path: '/v1/embeddings',
                fullUrl: '$base/v1/embeddings',
                description:
                    'Standard format for LangChain, LlamaIndex, and vector databases.',
                curl:
                    'curl $base/v1/embeddings -H "Content-Type: application/json" -d \'{"model":"$embedId","input":"hello"}\'',
              ),
              _EndpointCard(
                icon: Icons.scatter_plot_rounded,
                accent: _nativeEmbed,
                title: 'Batch Embeddings',
                protocol: 'Thinai / Ollama · array input',
                path: '/api/embed',
                fullUrl: '$base/api/embed',
                description:
                    'Computes vector embeddings for multiple input texts in one call.',
                curl:
                    'curl $base/api/embed -d \'{"model":"$embedId","input":["hello","world"]}\'',
              ),
              _EndpointCard(
                icon: Icons.history_rounded,
                accent: _nativeEmbed,
                title: 'Legacy Embeddings',
                protocol: 'Thinai · single prompt',
                path: '/api/embeddings',
                fullUrl: '$base/api/embeddings',
                description:
                    'Computes embeddings for a single prompt string.',
                curl:
                    'curl $base/api/embeddings -d \'{"model":"$embedId","prompt":"hello"}\'',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _EndpointGroup(
            icon: Icons.inventory_2_rounded,
            title: 'Model Discovery',
            subtitle: 'Inspect loaded models, status, and system resources',
            cards: [
              _EndpointCard(
                icon: Icons.bolt_rounded,
                accent: _openAi,
                title: 'List Models (OpenAI)',
                protocol: 'OpenAI-compatible',
                path: '/v1/models',
                fullUrl: '$base/v1/models',
                description:
                    'Returns installed and loaded models in OpenAI model object format.',
                curl: 'curl $base/v1/models',
              ),
              _EndpointCard(
                icon: Icons.list_alt_rounded,
                accent: _nativeModels,
                title: 'List Models (Ollama)',
                protocol: 'Thinai / Ollama tags',
                path: '/api/tags',
                fullUrl: '$base/api/tags',
                description:
                    'Returns models formatted for Ollama CLI and Open-WebUI model selector.',
                curl: 'curl $base/api/tags',
              ),
              _EndpointCard(
                icon: Icons.memory_rounded,
                accent: _nativeModels,
                title: 'Loaded Model & VRAM',
                protocol: 'Thinai / Ollama ps',
                path: '/api/ps',
                fullUrl: '$base/api/ps',
                description:
                    'Checks which model is currently resident in phone memory.',
                curl: 'curl $base/api/ps',
              ),
              _EndpointCard(
                icon: Icons.info_rounded,
                accent: _nativeModels,
                title: 'Model Architecture Info',
                protocol: 'Thinai / Ollama show',
                path: '/api/show',
                fullUrl: '$base/api/show',
                description:
                    'Shows model parameters, context length, and system details.',
                curl: 'curl $base/api/show -d \'{"name":"$chatId"}\'',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  lanShare ? Icons.public_rounded : Icons.lock_rounded,
                  size: 18,
                  color: lanShare ? scheme.error : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lanShare
                        ? 'Sharing is on. Any device on this Wi-Fi can reach the API with no authentication. Ollama-compatible on port 11434.'
                        : 'Only this phone can reach the API. Enable sharing to reach it from other devices. Ollama-compatible on port 11434.',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
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

class _LanApiTokenCard extends ConsumerStatefulWidget {
  const _LanApiTokenCard();

  @override
  ConsumerState<_LanApiTokenCard> createState() => _LanApiTokenCardState();
}

class _LanApiTokenCardState extends ConsumerState<_LanApiTokenCard> {
  bool _showToken = false;
  bool _regenerating = false;

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('API token copied'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _regenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate API token?'),
        content: const Text(
          'Existing LAN clients using the current token will lose access. '
          'You will need to give them the new token.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _regenerating = true);

    try {
      final controller = ref.read(serverControllerProvider.notifier);
      final status = ref.read(serverControllerProvider);
      final lan = ref.read(lanShareProvider);

      if (status.running && lan) {
        await controller.stop();
      }

      await regenerateServerBearerToken();

      if (status.running && lan) {
        await controller.start(
          port: status.port,
          lanMode: true,
        );
      }

      ref.invalidate(serverBearerTokenProvider);

      if (mounted) {
        setState(() => _showToken = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('API token regenerated'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _regenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokenAsync = ref.watch(serverBearerTokenProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: tokenAsync.when(
          loading: () => const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading API token...'),
            ],
          ),
          error: (error, _) => Text(
            'Unable to load API token',
            style: TextStyle(color: scheme.error),
          ),
          data: (token) {
            if (token == null || token.isEmpty) {
              return const Text(
                'LAN authentication token has not been generated yet.',
              );
            }

            final masked =
                '${token.substring(0, 6)}••••••••••••••••${token.substring(token.length - 6)}';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.key_rounded,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'LAN API authentication',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Use this bearer token when connecting from another device.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    _showToken ? token : masked,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _showToken = !_showToken);
                      },
                      icon: Icon(
                        _showToken
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      label: Text(_showToken ? 'Hide' : 'Show'),
                    ),

                    const SizedBox(width: 8),

                    FilledButton.icon(
                      onPressed: () => _copyToken(token),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                    ),

                    const Spacer(),

                    IconButton(
                      tooltip: 'Regenerate token',
                      onPressed: _regenerating ? null : _regenerate,
                      icon: _regenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  'Anyone with this token can access the LAN API.',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.error,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Introduces the API reference and keeps the base URL one tap from the
/// clipboard, so the reference itself can stay folded away.
class _ApiReferenceHeader extends StatelessWidget {
  const _ApiReferenceHeader({required this.base});

  final String base;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.terminal_rounded,
            size: 18,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'API reference',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Tap a section for paths and curl examples',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copy base URL',
          icon: const Icon(Icons.content_copy_rounded, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: base));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Copied base URL'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// One protocol family, folded to a single row until tapped.
///
/// Expanded by default the three groups filled several screens of curl
/// snippets, which buried the controls a user actually comes to this page
/// for. Collapsed, the page is the server plus a short index.
class _EndpointGroup extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_EndpointCard> cards;

  const _EndpointGroup({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cards,
  });

  @override
  State<_EndpointGroup> createState() => _EndpointGroupState();
}

class _EndpointGroupState extends State<_EndpointGroup> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 16,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.cards.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: [
                        for (var i = 0; i < widget.cards.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          widget.cards[i],
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ─── hero ──────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final bool running;
  final int port;
  final bool lan;
  final String? lanIp;
  final String? activeId;
  final TextEditingController portController;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _HeroCard({
    required this.running,
    required this.port,
    required this.lan,
    required this.lanIp,
    required this.activeId,
    required this.portController,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: running
              ? const Color(0xFF2CA048).withValues(alpha: isDark ? 0.55 : 0.40)
              : scheme.outline,
          width: running ? 1.5 : 1,
        ),
        boxShadow: running
            ? [
                BoxShadow(
                  color: const Color(0xFF2CA048).withValues(
                    alpha: isDark ? 0.20 : 0.12,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // FloatingLines Background: Flowing harmonic waves clipped strictly inside top card
            Positioned.fill(
              child: FloatingLinesBackground(
                animated: running,
                isDark: isDark,
                animationSpeed: 1.0,
                enabledWaves: const ['top', 'middle', 'bottom'],
                lineCount: const [5, 6, 5],
                lineDistance: const [4.0, 4.5, 4.0],
                topWavePosition: const WavePosition(x: 8.0, y: 0.45, rotate: -0.35),
                middleWavePosition: const WavePosition(x: 4.0, y: 0.0, rotate: 0.18),
                bottomWavePosition: const WavePosition(x: 1.8, y: -0.55, rotate: 0.35),
                interactive: true,
                bendRadius: 4.0,
                bendStrength: -0.45,
                mouseDamping: 0.08,
                parallax: true,
                parallaxStrength: 0.15,
              ),
            ),
            // Subtle frosted readability tint so FloatingLines waves shine through vividly while keeping text crisp
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF090E14).withValues(alpha: 0.22),
                            const Color(0xFF0D141C).withValues(alpha: 0.42),
                          ]
                        : [
                            const Color(0xFFFFFFFF).withValues(alpha: 0.35),
                            const Color(0xFFF3F7F5).withValues(alpha: 0.50),
                          ],
                  ),
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusDot(running: running),
                      const SizedBox(width: 10),
                      Text(
                        running ? 'Running' : 'Stopped',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: scheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (running)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (running) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF090E13).withValues(alpha: 0.82)
                            : Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              const Color(0xFF2CA048).withValues(alpha: 0.45),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SERVER ADDRESS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                SelectableText(
                                  lan && lanIp != null
                                      ? 'http://$lanIp:$port'
                                      : 'http://127.0.0.1:$port',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2CA048),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                if (lan && lanIp != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Local loopback: http://127.0.0.1:$port',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurfaceVariant,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: const Text('Copy'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2CA048),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () async {
                              final url = lan && lanIp != null
                                  ? 'http://$lanIp:$port'
                                  : 'http://127.0.0.1:$port';
                              await Clipboard.setData(ClipboardData(text: url));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied $url to clipboard'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      activeId == null
                          ? 'No model loaded yet'
                          : 'Active Model · $activeId',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Run an on-device OpenAI & Ollama compatible HTTP server to connect apps, scripts, or coding assistants on your Wi-Fi.',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activeId == null
                          ? 'No model loaded yet'
                          : 'Active Model · $activeId',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF090E13).withValues(alpha: 0.78)
                                : Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          child: TextField(
                            controller: portController,
                            enabled: !running,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Port',
                              labelStyle: TextStyle(
                                color: scheme.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        icon: Icon(
                          running
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(running ? 'Stop' : 'Start'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _brandDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                        ),
                        onPressed: running ? onStop : onStart,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggles LAN sharing and, when the server is running and reachable, shows
/// the address other devices on the same network can call.
class _NetworkShareCard extends StatelessWidget {
  final bool enabled;
  final bool running;
  final String? lanIp;
  final String? deviceIp;
  final int port;
  final ValueChanged<bool> onChanged;

  const _NetworkShareCard({
    required this.enabled,
    required this.running,
    required this.lanIp,
    required this.deviceIp,
    required this.port,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The address other devices would use: the live bound IP when running,
    // otherwise the detected device IP so the URL is visible before starting.
    final shareIp = lanIp ?? deviceIp;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            secondary: Icon(
              enabled ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: enabled ? scheme.primary : scheme.onSurfaceVariant,
            ),
            title: const Text(
              'Share on local network',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              enabled
                  ? 'Other devices on this Wi-Fi can reach the API.'
                  : 'Off. Only apps on this phone can reach the API.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            value: enabled,
            onChanged: onChanged,
          ),
          // Device IP is always shown (when known) so the address is never a
          // mystery, regardless of the toggle or whether the server is up.
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          //   child: Row(
          //     children: [
          //       Icon(Icons.smartphone_rounded,
          //           size: 16, color: scheme.onSurfaceVariant),
          //       const SizedBox(width: 8),
          //       Expanded(
          //         child: Text(
          //           deviceIp != null
          //               ? 'This device: $deviceIp'
          //               : 'Not connected to Wi-Fi/LAN.',
          //           style: TextStyle(
          //             fontSize: 12,
          //             color: scheme.onSurfaceVariant,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          if (enabled && running && shareIp != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _shareRow(context, scheme, 'http://$shareIp:$port'),
            ),
          if (enabled && running && shareIp == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 16, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No Wi-Fi/LAN address found. Connect to Wi-Fi and restart the server.',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (enabled && !running)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Start the server to expose it at this address.',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _shareRow(BuildContext context, ColorScheme scheme, String url) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              url,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy_rounded, size: 18),
            tooltip: 'Copy address',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Copied network address'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  final bool running;
  const _StatusDot({required this.running});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  // Created on first use: build() only needs a ticker while the server is
  // running, and an idle repeating controller would drive frames forever.
  AnimationController? _controller;

  AnimationController get _c =>
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat();

  @override
  void dispose() {
    // Must not go through the _c getter: if the dot was never shown in the
    // running state the controller was never created, and creating one here
    // would build a Ticker against an already-deactivated element
    // ("Looking up a deactivated widget's ancestor is unsafe").
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.running) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          shape: BoxShape.circle,
        ),
      );
    }
    return SizedBox(
      width: 16,
      height: 16,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 16 * (0.6 + _c.value * 0.4),
                height: 16 * (0.6 + _c.value * 0.4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3 * (1 - _c.value)),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── developer quick start ─────────────────────────────────────────────────

class _DeveloperQuickStartCard extends StatefulWidget {
  final String base;
  final String apiHost;
  final int port;
  final String chatId;
  final bool lanShare;

  const _DeveloperQuickStartCard({
    required this.base,
    required this.apiHost,
    required this.port,
    required this.chatId,
    required this.lanShare,
  });

  @override
  State<_DeveloperQuickStartCard> createState() =>
      _DeveloperQuickStartCardState();
}

class _DeveloperQuickStartCardState extends State<_DeveloperQuickStartCard> {
  int _tabIndex = 0;

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $label to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const logoGreen = Color(0xFF2CA048);
    final openAiBase = 'http://${widget.apiHost}:${widget.port}/v1';
    final ollamaBase = 'http://${widget.apiHost}:${widget.port}';

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: logoGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.hub_rounded, size: 16, color: logoGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect External Tools',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Zero-config setup for IDEs, scripts, and AI agents',
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
          const SizedBox(height: 14),
          // Clean 3-tab selector
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTab(0, 'VS Code / Cursor', Icons.code_rounded),
                _buildTab(1, 'Python SDK', Icons.terminal_rounded),
                _buildTab(2, 'Ollama / Web-UI', Icons.dns_rounded),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_tabIndex == 0) ...[
            Text(
              'Use Thinai with Continue.dev, Cline, or Cursor as an OpenAI-compatible provider:',
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            _buildCredentialRow(
              scheme,
              label: 'Provider',
              value: 'OpenAI Compatible',
            ),
            const SizedBox(height: 6),
            _buildCredentialRow(
              scheme,
              label: 'Base URL',
              value: openAiBase,
              isMonospace: true,
              onCopy: () => _copy(openAiBase, 'Base URL'),
            ),
            const SizedBox(height: 6),
            _buildCredentialRow(
              scheme,
              label: 'Model ID',
              value: widget.chatId,
              isMonospace: true,
              onCopy: () => _copy(widget.chatId, 'Model ID'),
            ),
            const SizedBox(height: 6),
            _buildCredentialRow(
              scheme,
              label: 'API Key',
              value: 'thinai (or any text)',
            ),
          ] else if (_tabIndex == 1) ...[
            Text(
              'Call this phone using the standard OpenAI Python package:',
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: SelectableText(
                'from openai import OpenAI\n\n'
                'client = OpenAI(\n'
                '    base_url="$openAiBase",\n'
                '    api_key="thinai",\n'
                ')\n\n'
                'response = client.chat.completions.create(\n'
                '    model="${widget.chatId}",\n'
                '    messages=[{"role": "user", "content": "Hello!"}],\n'
                ')\n'
                'print(response.choices[0].message.content)',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: scheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy Python Code'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _copy(
                  'from openai import OpenAI\n\n'
                  'client = OpenAI(\n'
                  '    base_url="$openAiBase",\n'
                  '    api_key="thinai",\n'
                  ')\n\n'
                  'response = client.chat.completions.create(\n'
                  '    model="${widget.chatId}",\n'
                  '    messages=[{"role": "user", "content": "Hello!"}],\n'
                  ')\n'
                  'print(response.choices[0].message.content)',
                  'Python code',
                ),
              ),
            ),
          ] else ...[
            Text(
              'Connect Open-WebUI or Ollama-compatible tools directly:',
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            _buildCredentialRow(
              scheme,
              label: 'Ollama Host',
              value: ollamaBase,
              isMonospace: true,
              onCopy: () => _copy(ollamaBase, 'Ollama Host'),
            ),
            const SizedBox(height: 6),
            _buildCredentialRow(
              scheme,
              label: 'Model Name',
              value: widget.chatId,
              isMonospace: true,
              onCopy: () => _copy(widget.chatId, 'Model Name'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final selected = _tabIndex == index;
    final scheme = Theme.of(context).colorScheme;
    const logoGreen = Color(0xFF2CA048);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: selected ? logoGreen : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(
    ColorScheme scheme, {
    required String label,
    required String value,
    bool isMonospace = false,
    VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 14),
              tooltip: 'Copy $label',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}

// ─── endpoints ─────────────────────────────────────────────────────────────

class _EndpointCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String protocol;
  final String path;
  final String curl;
  final String? description;
  final String? fullUrl;

  const _EndpointCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.protocol,
    required this.path,
    required this.curl,
    this.description,
    this.fullUrl,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accent),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              path,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: accent,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            protocol,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (fullUrl != null)
                IconButton(
                  tooltip: 'Copy URL',
                  icon: const Icon(Icons.link_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: fullUrl!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied URL: $fullUrl'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
              IconButton(
                tooltip: 'Copy cURL',
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: curl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied cURL command'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              curl,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: scheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (fullUrl != null) ...[
                TextButton.icon(
                  icon: const Icon(Icons.link_rounded, size: 13),
                  label: const Text('Copy URL',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: fullUrl!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied URL: $fullUrl'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              TextButton.icon(
                icon: const Icon(Icons.terminal_rounded, size: 13),
                label: const Text('Copy cURL',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: curl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied cURL command'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
