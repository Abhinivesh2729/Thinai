import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models_repo/catalog.dart';
import '../../models_repo/model_store.dart';
import '../../server/foreground_handler.dart';
import '../../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/model_settings_sheet.dart';
import '../widgets/app_drawer.dart';
import '../widgets/ui_kit.dart';

/// The shell variable the curl examples read the LAN token from, so a copied
/// command works after one `export` instead of needing the secret pasted into
/// every line.
const _tokenVar = r'$THINAI_TOKEN';

/// A copyable curl for one route.
///
/// While sharing is on, every request needs the bearer token, loopback
/// included, so an example without it would only ever answer 401.
@visibleForTesting
String curlExample(
  String base,
  String path, {
  String? body,
  bool lan = false,
  bool json = false,
}) {
  final auth = lan ? ' -H "Authorization: Bearer $_tokenVar"' : '';
  final type = json ? ' -H "Content-Type: application/json"' : '';
  final data = body == null ? '' : " -d '$body'";
  return 'curl $base$path$auth$type$data';
}

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

  void _toast(String text) => showToast(context, text);

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(serverControllerProvider);
    final activeId = ref.watch(activeModelIdProvider);
    final installed = ref.watch(modelListProvider).valueOrNull;
    final lanShare = ref.watch(lanShareProvider);
    final deviceIp = ref.watch(deviceLanIpProvider).valueOrNull;

    // When sharing on the network, quote the LAN IP in the copyable examples
    // so they work from other devices; otherwise keep them on loopback.
    final apiHost = lanShare
        ? (status.lanIp ?? deviceIp ?? '127.0.0.1')
        : '127.0.0.1';
    final base = 'http://$apiHost:${status.port}';
    final chatId = activeId ?? 'model-id';
    final embedId = _embeddingIdFor(installed);

    String get(String path) => curlExample(base, path, lan: lanShare);
    String post(String path, String body, {bool jsonHeader = false}) =>
        curlExample(base, path, body: body, lan: lanShare, json: jsonHeader);

    return Scaffold(
      appBar: AppBar(
        leading: const MenuButton(),
        titleSpacing: Space.xs,
        title: const Text('Server'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.xs,
          Space.lg,
          Space.xxxl,
        ),
        children: [
          _StatusCard(
            running: status.running,
            port: status.port,
            lan: status.lan,
            lanIp: status.lanIp,
            activeId: activeId,
            portController: _portController,
            onStart: _start,
            onStop: _stop,
          ),
          SettingsGroup(
            label: 'Configuration',
            children: [
              if (activeId != null)
                SettingsRow(
                  icon: Icons.tune_rounded,
                  title: 'Context & temperature',
                  subtitle:
                      'What $activeId is served with. Requests can override it.',
                  onTap: () async {
                    final model = await ref
                        .read(modelStoreProvider)
                        .findById(activeId);
                    if (model == null || !context.mounted) return;
                    await showModelSettingsSheet(context, model);
                  },
                ),
              _NetworkShareRow(
                enabled: lanShare,
                running: status.running,
                lanIp: status.running ? status.lanIp : null,
                deviceIp: deviceIp,
                port: status.port,
                onChanged: _setLanShare,
              ),
            ],
          ),
          if (lanShare) ...[
            const SizedBox(height: Space.md),
            const _LanApiTokenCard(),
          ],
          SectionHeader(
            title: 'API reference',
            subtitle: 'Ollama- and OpenAI-compatible. Tap a group for curl.',
          ),
          CodeBlock(
            text: base,
            fontSize: 13,
            copyTooltip: 'Copy base URL',
            onCopy: () =>
                copyWithToast(context, base, message: 'Copied base URL'),
          ),
          const SizedBox(height: Space.md),
          _EndpointGroup(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat',
            subtitle: 'Generate text, copy a curl to test',
            endpoints: [
              _Endpoint(
                method: 'POST',
                title: 'Chat',
                protocol: 'Thinai · streaming NDJSON',
                path: '/api/chat',
                curl: post(
                  '/api/chat',
                  '{"model":"$chatId","messages":[{"role":"user","content":"hi"}]}',
                ),
              ),
              _Endpoint(
                method: 'POST',
                title: 'Generate',
                protocol: 'Thinai · single prompt',
                path: '/api/generate',
                curl: post(
                  '/api/generate',
                  '{"model":"$chatId","prompt":"hi","stream":false}',
                ),
              ),
              _Endpoint(
                method: 'POST',
                title: 'Chat completions',
                protocol: 'OpenAI-compatible',
                path: '/v1/chat/completions',
                curl: post(
                  '/v1/chat/completions',
                  '{"model":"$chatId","messages":[{"role":"user","content":"hi"}],"stream":false}',
                  jsonHeader: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          _EndpointGroup(
            icon: Icons.scatter_plot_outlined,
            title: 'Embeddings',
            subtitle: 'Vectors for search and RAG',
            endpoints: [
              _Endpoint(
                method: 'POST',
                title: 'Embed',
                protocol: 'Thinai · batches input',
                path: '/api/embed',
                curl: post(
                  '/api/embed',
                  '{"model":"$embedId","input":["hello","world"]}',
                ),
              ),
              _Endpoint(
                method: 'POST',
                title: 'Embeddings',
                protocol: 'Thinai · legacy, single prompt',
                path: '/api/embeddings',
                curl: post(
                  '/api/embeddings',
                  '{"model":"$embedId","prompt":"hello"}',
                ),
              ),
              _Endpoint(
                method: 'POST',
                title: 'Embeddings',
                protocol: 'OpenAI-compatible · float or base64',
                path: '/v1/embeddings',
                curl: post(
                  '/v1/embeddings',
                  '{"model":"$embedId","input":"hello"}',
                  jsonHeader: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          _EndpointGroup(
            icon: Icons.inventory_2_outlined,
            title: 'Models',
            subtitle: 'Discover what is installed and loaded',
            endpoints: [
              _Endpoint(
                method: 'GET',
                title: 'List models',
                protocol: 'Thinai',
                path: '/api/tags',
                curl: get('/api/tags'),
              ),
              _Endpoint(
                method: 'GET',
                title: 'Loaded model',
                protocol: 'Thinai',
                path: '/api/ps',
                curl: get('/api/ps'),
              ),
              _Endpoint(
                method: 'POST',
                title: 'Show model',
                protocol: 'Thinai',
                path: '/api/show',
                curl: post('/api/show', '{"name":"$chatId"}'),
              ),
              _Endpoint(
                method: 'GET',
                title: 'List models',
                protocol: 'OpenAI-compatible',
                path: '/v1/models',
                curl: get('/v1/models'),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          InlineNotice(
            icon: lanShare ? Icons.wifi_rounded : Icons.lock_outline_rounded,
            tone: lanShare ? TagTone.warning : TagTone.neutral,
            text: lanShare
                ? 'Sharing is on. Devices on this Wi-Fi can reach the API on '
                      'port ${status.port}, and every request must carry the '
                      'API token above.'
                : 'Only this phone can reach the API, on port ${status.port}. '
                      'Turn on sharing to reach it from other devices.',
          ),
        ],
      ),
    );
  }
}

// ─── status ────────────────────────────────────────────────────────────────

/// Whether the server is up, where to reach it, and the one control that
/// changes that.
class _StatusCard extends StatelessWidget {
  final bool running;
  final int port;
  final bool lan;
  final String? lanIp;
  final String? activeId;
  final TextEditingController portController;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _StatusCard({
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final app = AppColors.of(context);
    final url = lan && lanIp != null
        ? 'http://$lanIp:$port'
        : 'http://127.0.0.1:$port';

    return AppCard(
      borderColor: running ? app.success.withValues(alpha: 0.45) : null,
      padding: const EdgeInsets.all(Space.lg + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusDot(
                color: running ? app.success : scheme.outline,
                pulsing: running,
                size: 9,
              ),
              const SizedBox(width: 6),
              Text(
                running ? 'Running' : 'Stopped',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Tag(
                lan ? 'Local network' : 'This phone only',
                icon: lan ? Icons.wifi_rounded : Icons.lock_outline_rounded,
                tone: running
                    ? (lan ? TagTone.warning : TagTone.success)
                    : TagTone.neutral,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          AnimatedSwitcher(
            duration: Motion.base,
            child: running
                ? Column(
                    key: const ValueKey('running'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              url,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy address',
                            iconSize: 18,
                            color: scheme.onSurfaceVariant,
                            icon: const Icon(Icons.content_copy_rounded),
                            onPressed: () => copyWithToast(
                              context,
                              url,
                              message: 'Copied server address',
                            ),
                          ),
                        ],
                      ),
                      if (lan && lanIp != null)
                        Text(
                          'On this device · http://127.0.0.1:$port',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  )
                : Text(
                    key: const ValueKey('stopped'),
                    'Starts a local HTTP server other apps can call.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Icon(
                Icons.memory_rounded,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  activeId == null ? 'No model loaded' : 'Model · $activeId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          const Divider(height: 1),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              SizedBox(
                width: 112,
                child: TextField(
                  controller: portController,
                  enabled: !running,
                  keyboardType: TextInputType.number,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: running
                    ? FilledButton.tonalIcon(
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Stop server'),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.errorContainer,
                          foregroundColor: scheme.error,
                        ),
                        onPressed: onStop,
                      )
                    : FilledButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start server'),
                        onPressed: onStart,
                      ),
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
class _NetworkShareRow extends StatelessWidget {
  final bool enabled;
  final bool running;
  final String? lanIp;
  final String? deviceIp;
  final int port;
  final ValueChanged<bool> onChanged;

  const _NetworkShareRow({
    required this.enabled,
    required this.running,
    required this.lanIp,
    required this.deviceIp,
    required this.port,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // The address other devices would use: the live bound IP when running,
    // otherwise the detected device IP so the URL is visible before starting.
    final shareIp = lanIp ?? deviceIp;
    final Widget? detail = !enabled
        ? null
        : running && shareIp != null
        ? CodeBlock(
            text: 'http://$shareIp:$port',
            fontSize: 13,
            copyTooltip: 'Copy address',
            onCopy: () => copyWithToast(
              context,
              'http://$shareIp:$port',
              message: 'Copied network address',
            ),
          )
        : running
        ? const InlineNotice(
            icon: Icons.error_outline_rounded,
            tone: TagTone.danger,
            text:
                'No Wi-Fi/LAN address found. Connect to Wi-Fi and restart the '
                'server.',
          )
        : const InlineNotice(
            text: 'Start the server to expose it at this address.',
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsSwitchRow(
          icon: enabled ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          title: 'Share on local network',
          subtitle: enabled
              ? 'Other devices on this Wi-Fi can reach the API with the token.'
              : 'Off. Only apps on this phone can reach the API.',
          value: enabled,
          onChanged: onChanged,
        ),
        if (detail != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 0, Space.lg, Space.md),
            child: detail,
          ),
      ],
    );
  }
}

// ─── LAN token ─────────────────────────────────────────────────────────────

class _LanApiTokenCard extends ConsumerStatefulWidget {
  const _LanApiTokenCard();

  @override
  ConsumerState<_LanApiTokenCard> createState() => _LanApiTokenCardState();
}

class _LanApiTokenCardState extends ConsumerState<_LanApiTokenCard> {
  bool _showToken = false;
  bool _regenerating = false;

  Future<void> _regenerate() async {
    final confirmed = await confirmAction(
      context,
      title: 'Regenerate API token?',
      message:
          'Existing LAN clients using the current token will lose access. '
          'You will need to give them the new token.',
      confirmLabel: 'Regenerate',
    );

    if (!confirmed || !mounted) return;

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
        await controller.start(port: status.port, lanMode: true);
      }

      ref.invalidate(serverBearerTokenProvider);

      if (mounted) {
        setState(() => _showToken = false);
        showToast(context, 'API token regenerated');
      }
    } finally {
      if (mounted) {
        setState(() => _regenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokenAsync = ref.watch(serverBearerTokenProvider);

    return AppCard(
      child: tokenAsync.when(
        loading: () => const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: Space.md),
            Text('Loading API token…'),
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
                  IconTile(
                    icon: Icons.key_rounded,
                    size: 34,
                    background: scheme.primaryContainer,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LAN API authentication',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Send as a bearer token from other devices.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Regenerate token',
                    onPressed: _regenerating ? null : _regenerate,
                    icon: _regenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CodeBlock(text: _showToken ? token : masked, selectable: true),
              const SizedBox(height: Space.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showToken = !_showToken),
                      icon: Icon(
                        _showToken
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                      ),
                      label: Text(_showToken ? 'Hide' : 'Show'),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => copyWithToast(
                        context,
                        token,
                        message: 'API token copied',
                      ),
                      icon: const Icon(Icons.content_copy_rounded, size: 18),
                      label: const Text('Copy'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              Text(
                'The curl examples below read it from $_tokenVar. '
                'Anyone with this token can use the API.',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── endpoints ─────────────────────────────────────────────────────────────

/// One route in the API reference.
class _Endpoint {
  const _Endpoint({
    required this.method,
    required this.title,
    required this.protocol,
    required this.path,
    required this.curl,
  });

  final String method;
  final String title;
  final String protocol;
  final String path;
  final String curl;
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
  final List<_Endpoint> endpoints;

  const _EndpointGroup({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.endpoints,
  });

  @override
  State<_EndpointGroup> createState() => _EndpointGroupState();
}

class _EndpointGroupState extends State<_EndpointGroup> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.md,
                Space.md,
                Space.md,
              ),
              child: Row(
                children: [
                  IconTile(icon: widget.icon, size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Tag('${widget.endpoints.length}', dense: true),
                  const SizedBox(width: Space.xs),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: Motion.base,
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
            duration: Motion.base,
            curve: Motion.curve,
            alignment: Alignment.topCenter,
            child: _open
                ? Column(
                    children: [
                      for (final endpoint in widget.endpoints) ...[
                        const Divider(height: 1),
                        _EndpointTile(endpoint: endpoint),
                      ],
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({required this.endpoint});

  final _Endpoint endpoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, 14, Space.lg, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(
                endpoint.method,
                tone: endpoint.method == 'GET'
                    ? TagTone.success
                    : TagTone.accent,
                dense: true,
                monospace: true,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  endpoint.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${endpoint.title} · ${endpoint.protocol}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          CodeBlock(
            text: endpoint.curl,
            fontSize: 11.5,
            copyTooltip: 'Copy curl command',
            onCopy: () => copyWithToast(
              context,
              endpoint.curl,
              message: 'Copied curl command',
            ),
          ),
        ],
      ),
    );
  }
}
