import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models_repo/catalog.dart';
import '../../models_repo/model_store.dart';
import '../../server/foreground_handler.dart';
import '../../state/providers.dart';
import '../widgets/model_settings_sheet.dart';
import 'settings_page.dart';

/// Accent per protocol family, so a glance separates the app's own routes from
/// the OpenAI compatibility layer.
// On-brand blue accents (brand navy #0E4B75). Native routes use lighter blues;
// the OpenAI compatibility layer uses a deeper blue to set it apart.
const _nativeChat = Color(0xFF4A90D9);
const _nativeEmbed = Color(0xFF5FB0EE);
const _nativeModels = Color(0xFF7CA7DB);
const _openAi = Color(0xFF3564A8);

/// Brand navy for the primary CTA (Start/Stop button). Fixed (not scheme-
/// derived) so the button reads the same in both light and dark themes.
const _brandDeep = Color(0xFF0E4B75);

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
          const SizedBox(height: 20),
          _ApiReferenceHeader(base: base),
          const SizedBox(height: 12),
          _EndpointGroup(
            icon: Icons.chat_rounded,
            title: 'Chat',
            subtitle: 'Generate text, copy a curl to test',
            cards: [
              _EndpointCard(
                icon: Icons.chat_rounded,
                accent: _nativeChat,
                title: 'Chat',
                protocol: 'Thinai · streaming NDJSON',
                path: '/api/chat',
                curl:
                    'curl $base/api/chat -d \'{"model":"$chatId","messages":[{"role":"user","content":"hi"}]}\'',
              ),
              _EndpointCard(
                icon: Icons.edit_note_rounded,
                accent: _nativeChat,
                title: 'Generate',
                protocol: 'Thinai · single prompt',
                path: '/api/generate',
                curl:
                    'curl $base/api/generate -d \'{"model":"$chatId","prompt":"hi","stream":false}\'',
              ),
              _EndpointCard(
                icon: Icons.bolt_rounded,
                accent: _openAi,
                title: 'Chat completions',
                protocol: 'OpenAI-compatible',
                path: '/v1/chat/completions',
                curl:
                    'curl $base/v1/chat/completions -H "Content-Type: application/json" -d \'{"model":"$chatId","messages":[{"role":"user","content":"hi"}],"stream":false}\'',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _EndpointGroup(
            icon: Icons.scatter_plot_rounded,
            title: 'Embeddings',
            subtitle: 'Vectors for search and RAG',
            cards: [
              _EndpointCard(
                icon: Icons.scatter_plot_rounded,
                accent: _nativeEmbed,
                title: 'Embed',
                protocol: 'Thinai · batches input',
                path: '/api/embed',
                curl:
                    'curl $base/api/embed -d \'{"model":"$embedId","input":["hello","world"]}\'',
              ),
              _EndpointCard(
                icon: Icons.history_rounded,
                accent: _nativeEmbed,
                title: 'Embeddings',
                protocol: 'Thinai · legacy, single prompt',
                path: '/api/embeddings',
                curl:
                    'curl $base/api/embeddings -d \'{"model":"$embedId","prompt":"hello"}\'',
              ),
              _EndpointCard(
                icon: Icons.bolt_rounded,
                accent: _openAi,
                title: 'Embeddings',
                protocol: 'OpenAI-compatible · float or base64',
                path: '/v1/embeddings',
                curl:
                    'curl $base/v1/embeddings -H "Content-Type: application/json" -d \'{"model":"$embedId","input":"hello"}\'',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _EndpointGroup(
            icon: Icons.inventory_2_rounded,
            title: 'Models',
            subtitle: 'Discover what is installed and loaded',
            cards: [
              _EndpointCard(
                icon: Icons.list_alt_rounded,
                accent: _nativeModels,
                title: 'List models',
                protocol: 'Thinai',
                path: '/api/tags',
                curl: 'curl $base/api/tags',
              ),
              _EndpointCard(
                icon: Icons.memory_rounded,
                accent: _nativeModels,
                title: 'Loaded model',
                protocol: 'Thinai',
                path: '/api/ps',
                curl: 'curl $base/api/ps',
              ),
              _EndpointCard(
                icon: Icons.info_rounded,
                accent: _nativeModels,
                title: 'Show model',
                protocol: 'Thinai',
                path: '/api/show',
                curl: 'curl $base/api/show -d \'{"name":"$chatId"}\'',
              ),
              _EndpointCard(
                icon: Icons.bolt_rounded,
                accent: _openAi,
                title: 'List models',
                protocol: 'OpenAI-compatible',
                path: '/v1/models',
                curl: 'curl $base/v1/models',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            // Same tinted-gradient treatment as the Models page "Quick start"
            // card, so both pages read consistently. Flat surface tones look
            // muddy in dark mode.
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.alphaBlend(
                    scheme.primaryContainer.withValues(alpha: 0.72),
                    scheme.surface,
                  ),
                  Color.alphaBlend(
                    scheme.tertiaryContainer.withValues(alpha: 0.70),
                    scheme.surface,
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // Same tinted "Quick start" card in both stopped and running states
        // (matches the Models page; no teal), so the page reads as one design.
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(
              scheme.primaryContainer.withValues(alpha: 0.72),
              scheme.surface,
            ),
            Color.alphaBlend(
              scheme.tertiaryContainer.withValues(alpha: 0.70),
              scheme.surface,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                      horizontal: 10, vertical: 5),
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
            SelectableText(
              lan && lanIp != null
                  ? 'http://$lanIp:$port'
                  : 'http://127.0.0.1:$port',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
                fontFamily: 'monospace',
              ),
            ),
            if (lan && lanIp != null) ...[
              const SizedBox(height: 2),
              Text(
                'On this device · http://127.0.0.1:$port',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              activeId == null ? 'No model loaded' : 'Model · $activeId',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            Text(
              'Starts a local HTTP server other apps can call.',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activeId == null ? 'No model loaded' : 'Model · $activeId',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    // Frosted fill tinted to the Quick start card so the field
                    // belongs to the card instead of a grey box.
                    color: scheme.surface.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                  running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(running ? 'Stop' : 'Start'),
                style: FilledButton.styleFrom(
                  // Solid brand navy CTA in both states/themes so it matches
                  // the Quick start card's colour scheme (no teal).
                  backgroundColor: _brandDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 16),
                ),
                onPressed: running ? onStop : onStart,
              ),
            ],
          ),
        ],
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

// ─── endpoints ─────────────────────────────────────────────────────────────

class _EndpointCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String protocol;
  final String path;
  final String curl;

  const _EndpointCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.protocol,
    required this.path,
    required this.curl,
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
              IconButton(
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: curl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied curl command'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        ],
      ),
    );
  }
}
