import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models_repo/catalog.dart';
import '../../models_repo/model_store.dart';
import '../../server/foreground_handler.dart';
import '../../state/providers.dart';
import '../widgets/floating_lines_background.dart';
import '../widgets/model_settings_sheet.dart';

const _nativeChat = Color(0xFF2CA048);
const _nativeEmbed = Color(0xFF2EA043);
const _nativeModels = Color(0xFF16A34A);
const _openAi = Color(0xFF15803D);
const _brandDeep = Color(0xFF2CA048);

/// The model id to quote in embedding examples.
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showPortDialog() async {
    final controller = TextEditingController(text: _portController.text);
    final scheme = Theme.of(context).colorScheme;
    final newPort = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Server Port'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select or enter the local TCP port Thinai binds to. Default is 11434 for Ollama, 8080 for standard.',
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Port number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('11434 (Ollama)'),
                  onPressed: () => controller.text = '11434',
                ),
                ActionChip(
                  label: const Text('8080 (Standard)'),
                  onPressed: () => controller.text = '8080',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final p = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, p);
            },
            child: const Text('Save Port'),
          ),
        ],
      ),
    );

    if (newPort != null && newPort > 0 && newPort <= 65535) {
      setState(() => _portController.text = '$newPort');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('server_port', newPort);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(serverControllerProvider);
    final activeId = ref.watch(activeModelIdProvider);
    final installed = ref.watch(modelListProvider).valueOrNull;
    final lanShare = ref.watch(lanShareProvider);
    final deviceIp = ref.watch(deviceLanIpProvider).valueOrNull;

    final apiHost =
        lanShare ? (status.lanIp ?? deviceIp ?? '127.0.0.1') : '127.0.0.1';
    final base = 'http://$apiHost:${status.port}';
    final chatId = activeId ?? 'model-id';
    final embedId = _embeddingIdFor(installed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          // 1. Sleek Hero Server Card (Zero unwanted text: Status, Link, Control Button)
          _HeroCard(
            running: status.running,
            port: status.port,
            lan: status.lan,
            lanIp: status.lanIp,
            onStart: _start,
            onStop: _stop,
            onEditPort: _showPortDialog,
          ),

          const SizedBox(height: 12),

          // 2. Active Model Serving Strip
          _ActiveModelBanner(
            activeId: activeId,
            onConfigure: () async {
              if (activeId == null) return;
              final model =
                  await ref.read(modelStoreProvider).findById(activeId);
              if (model == null || !context.mounted) return;
              await showModelSettingsSheet(context, model);
            },
            onBrowseModels: () {
              ref.read(shellTabIndexProvider.notifier).state = 1;
            },
          ),

          const SizedBox(height: 14),

          // 3. Network Sharing & Security Card
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

          const SizedBox(height: 18),

          // 4. Developer Quick Start & Tools Integration (Clean, non-laggy structured cards)
          _DeveloperQuickStartCard(
            base: base,
            apiHost: apiHost,
            port: status.port,
            chatId: chatId,
            lanShare: lanShare,
          ),

          const SizedBox(height: 22),

          // 5. API Reference Header & Aligned Endpoints
          _ApiReferenceHeader(base: base),
          const SizedBox(height: 12),

          _EndpointGroup(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat & Text Generation',
            subtitle: 'OpenAI completions, Ollama streaming NDJSON, and raw generation',
            cards: [
              _EndpointCard(
                icon: Icons.bolt_rounded,
                accent: _openAi,
                title: 'OpenAI Chat Completions',
                protocol: 'OpenAI Compatible',
                path: '/v1/chat/completions',
                method: 'POST',
                fullUrl: '$base/v1/chat/completions',
                description:
                    'Standard OpenAI endpoint. Connects with Continue, Cursor, Python, and LangChain.',
                curl:
                    'curl $base/v1/chat/completions \\\n  -H "Content-Type: application/json" \\\n  -d \'{"model":"$chatId","messages":[{"role":"user","content":"Hello!"}],"stream":false}\'',
              ),
              _EndpointCard(
                icon: Icons.stream_rounded,
                accent: _nativeChat,
                title: 'Ollama Streaming Chat',
                protocol: 'Ollama Format',
                path: '/api/chat',
                method: 'POST',
                fullUrl: '$base/api/chat',
                description:
                    'Streams token responses line-by-line for interactive chat applications.',
                curl:
                    'curl $base/api/chat \\\n  -H "Content-Type: application/json" \\\n  -d \'{"model":"$chatId","messages":[{"role":"user","content":"Hello!"}]}\'',
              ),
              _EndpointCard(
                icon: Icons.edit_note_rounded,
                accent: _nativeChat,
                title: 'Single Prompt Generation',
                protocol: 'Ollama Format',
                path: '/api/generate',
                method: 'POST',
                fullUrl: '$base/api/generate',
                description:
                    'Sends raw prompt string and returns model output continuation.',
                curl:
                    'curl $base/api/generate \\\n  -H "Content-Type: application/json" \\\n  -d \'{"model":"$chatId","prompt":"Why is the sky blue?","stream":false}\'',
              ),
            ],
          ),

          const SizedBox(height: 12),

          _EndpointGroup(
            icon: Icons.scatter_plot_rounded,
            title: 'Text Embeddings',
            subtitle: 'Vector embeddings for semantic search, retrieval and RAG pipelines',
            cards: [
              _EndpointCard(
                icon: Icons.bolt_rounded,
                accent: _openAi,
                title: 'OpenAI Embeddings',
                protocol: 'OpenAI Compatible',
                path: '/v1/embeddings',
                method: 'POST',
                fullUrl: '$base/v1/embeddings',
                description:
                    'Vector embeddings compatible with LangChain, LlamaIndex, and vector databases.',
                curl:
                    'curl $base/v1/embeddings \\\n  -H "Content-Type: application/json" \\\n  -d \'{"model":"$embedId","input":"Search query text"}\'',
              ),
              _EndpointCard(
                icon: Icons.layers_rounded,
                accent: _nativeEmbed,
                title: 'Batch Embeddings',
                protocol: 'Ollama Format',
                path: '/api/embed',
                method: 'POST',
                fullUrl: '$base/api/embed',
                description:
                    'Computes vector embeddings for multiple input texts in a single batch request.',
                curl:
                    'curl $base/api/embed \\\n  -H "Content-Type: application/json" \\\n  -d \'{"model":"$embedId","input":["Document 1","Document 2"]}\'',
              ),
              _EndpointCard(
                icon: Icons.history_rounded,
                accent: _nativeEmbed,
                title: 'Legacy Embeddings',
                protocol: 'Thinai Native',
                path: '/api/embeddings',
                method: 'POST',
                fullUrl: '$base/api/embeddings',
                description:
                    'Computes embeddings for a single prompt string.',
                curl:
                    'curl $base/api/embeddings \\\n  -H "Content-Type: application/json" \\\n  -d \'{"model":"$embedId","prompt":"Hello world"}\'',
              ),
            ],
          ),

          const SizedBox(height: 12),

          _EndpointGroup(
            icon: Icons.inventory_2_rounded,
            title: 'Model Discovery & System',
            subtitle: 'Query loaded models, VRAM usage, and model architectures',
            cards: [
              _EndpointCard(
                icon: Icons.bolt_rounded,
                accent: _openAi,
                title: 'List Models (OpenAI)',
                protocol: 'OpenAI Compatible',
                path: '/v1/models',
                method: 'GET',
                fullUrl: '$base/v1/models',
                description:
                    'Lists installed and active models in standard OpenAI model list JSON format.',
                curl: 'curl $base/v1/models',
              ),
              _EndpointCard(
                icon: Icons.list_alt_rounded,
                accent: _nativeModels,
                title: 'List Models (Ollama)',
                protocol: 'Ollama Format',
                path: '/api/tags',
                method: 'GET',
                fullUrl: '$base/api/tags',
                description:
                    'Returns models formatted for Ollama CLI and Open-WebUI model selector.',
                curl: 'curl $base/api/tags',
              ),
              _EndpointCard(
                icon: Icons.memory_rounded,
                accent: _nativeModels,
                title: 'Running Model & Memory',
                protocol: 'Ollama Format',
                path: '/api/ps',
                method: 'GET',
                fullUrl: '$base/api/ps',
                description:
                    'Inspects which model is currently resident in phone RAM.',
                curl: 'curl $base/api/ps',
              ),
              _EndpointCard(
                icon: Icons.info_outline_rounded,
                accent: _nativeModels,
                title: 'Model Architecture Info',
                protocol: 'Ollama Format',
                path: '/api/show',
                method: 'POST',
                fullUrl: '$base/api/show',
                description:
                    'Shows model parameters, context length, and system details.',
                curl: 'curl $base/api/show -d \'{"name":"$chatId"}\'',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 6. Symmetrical Security / Network Pill
          _SecurityNoticeBanner(lanShare: lanShare, port: status.port),
        ],
      ),
    );
  }
}

// ─── 1. SERVER HERO CARD ───────────────────────────────────────────────────

/// Minimalist, high-tech server card featuring:
/// - Light theme: Dark pattern on clean surface
/// - Dark theme: Light shimmering pattern on dark surface
/// - Text on patterns 100% readable without visual conflict
/// - Content ONLY: Stop/Running status, link with copy, control button. Zero unwanted text.
class _HeroCard extends StatelessWidget {
  final bool running;
  final int port;
  final bool lan;
  final String? lanIp;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onEditPort;

  const _HeroCard({
    required this.running,
    required this.port,
    required this.lan,
    required this.lanIp,
    required this.onStart,
    required this.onStop,
    required this.onEditPort,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Inverted top hero card: for dark theme use light colored bg, for light theme use dark color bg
    final cardIsDark = !isDark;
    final serverUrl = lan && lanIp != null ? 'http://$lanIp:$port' : 'http://127.0.0.1:$port';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: running
              ? const Color(0xFF2CA048).withValues(alpha: cardIsDark ? 0.6 : 0.45)
              : (cardIsDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
          width: running ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: running
                ? const Color(0xFF2CA048).withValues(alpha: cardIsDark ? 0.18 : 0.10)
                : Colors.black.withValues(alpha: cardIsDark ? 0.35 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Background Pattern:
            // For dark theme uses light surface with dark lines
            // For light theme uses dark surface with luminous neon lines
            Positioned.fill(
              child: FloatingLinesBackground(
                animated: running,
                isDark: cardIsDark,
                animationSpeed: 1.0,
                linesGradient: running
                    ? (cardIsDark
                        ? const [
                            Color(0xFF2CA048), // Brand leaf emerald
                            Color(0xFF4ADE80), // Neon light emerald
                            Color(0xFF10B981), // Emerald
                            Color(0xFF6EE7B7), // Mint
                            Color(0xFFA7F3D0), // Soft luminous core
                          ]
                        : const [
                            Color(0xFF15803D), // Forest green
                            Color(0xFF2CA048), // Brand green
                            Color(0xFF059669), // Emerald
                            Color(0xFF16A34A), // Rich green
                            Color(0xFF34D399), // Mint glow
                          ])
                    : (cardIsDark
                        ? const [
                            Color(0xFF334155),
                            Color(0xFF1E293B),
                            Color(0xFF475569),
                          ]
                        : const [
                            Color(0xFFCBD5E1),
                            Color(0xFF94A3B8),
                            Color(0xFFE2E8F0),
                          ]),
                backgroundColor: cardIsDark
                    ? const Color(0xFF080D14)
                    : const Color(0xFFF8FAFC),
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

            // High-contrast frosted readability layer:
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: cardIsDark
                        ? [
                            const Color(0xFF090E17).withValues(alpha: 0.68),
                            const Color(0xFF0E1624).withValues(alpha: 0.82),
                          ]
                        : [
                            const Color(0xFFFFFFFF).withValues(alpha: 0.82),
                            const Color(0xFFF1F5F9).withValues(alpha: 0.90),
                          ],
                  ),
                ),
              ),
            ),

            // Card Content - ONLY: Status, Link, Button. Zero unwanted text.
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Running / Stopped Status & Port Pill
                  Row(
                    children: [
                      _StatusDot(running: running),
                      const SizedBox(width: 10),
                      Text(
                        running ? 'Running' : 'Stopped',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: cardIsDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (running) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0x2810B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Compact Port Badge
                      InkWell(
                        onTap: running ? null : onEditPort,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: cardIsDark
                                ? const Color(0xFF141C2A).withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: cardIsDark ? const Color(0xFF24334C) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                running ? Icons.lock_outline_rounded : Icons.tune_rounded,
                                size: 12,
                                color: cardIsDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'PORT $port',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: cardIsDark ? Colors.white : const Color(0xFF1E293B),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              if (!running) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit_rounded,
                                  size: 11,
                                  color: cardIsDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Row 2: High-contrast Server URL Link with Copy Button
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    decoration: BoxDecoration(
                      color: cardIsDark
                          ? const Color(0xFF0F1522).withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: running
                            ? const Color(0xFF2CA048).withValues(alpha: cardIsDark ? 0.45 : 0.35)
                            : (cardIsDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: cardIsDark ? 0.30 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            serverUrl,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: running
                                  ? (cardIsDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                                  : (cardIsDark ? Colors.white70 : const Color(0xFF334155)),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy Server Address',
                          icon: const Icon(Icons.copy_rounded, size: 17),
                          color: cardIsDark ? Colors.white70 : const Color(0xFF475569),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: serverUrl));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Copied $serverUrl to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Row 3: Prominent Start / Stop Control Button
                  FilledButton.icon(
                    icon: Icon(
                      running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 20,
                    ),
                    label: Text(
                      running ? 'Stop Server' : 'Start Server',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: running ? const Color(0xFFE11D48) : _brandDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: running ? onStop : onStart,
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

// ─── 2. ACTIVE MODEL SERVING STRIP ─────────────────────────────────────────

class _ActiveModelBanner extends StatelessWidget {
  final String? activeId;
  final VoidCallback onConfigure;
  final VoidCallback onBrowseModels;

  const _ActiveModelBanner({
    required this.activeId,
    required this.onConfigure,
    required this.onBrowseModels,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activeId != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _brandDeep.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.memory_rounded,
                color: Color(0xFF10B981),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SERVING MODEL',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    activeId!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: onConfigure,
              icon: const Icon(Icons.tune_rounded, size: 14),
              label: const Text('Tuning'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x18F59E0B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x44F59E0B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No model loaded yet. Load one to enable completions.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton.tonal(
            onPressed: onBrowseModels,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Browse Models'),
          ),
        ],
      ),
    );
  }
}

// ─── 3. NETWORK SHARE CARD ─────────────────────────────────────────────────

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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            secondary: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: (enabled ? scheme.primary : scheme.outlineVariant)
                    .withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                enabled ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                size: 18,
                color: enabled ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            title: const Text(
              'Share on Local Wi-Fi Network',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            subtitle: Text(
              enabled
                  ? 'Other computers and phones on this Wi-Fi can reach the API.'
                  : 'Only apps running directly on this phone can reach 127.0.0.1.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
            ),
            value: enabled,
            onChanged: onChanged,
          ),
          if (enabled && running && shareIp != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      'LAN URL: ',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        'http://$shareIp:$port',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Copy LAN URL',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: 'http://$shareIp:$port'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied http://$shareIp:$port'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── 4. LAN TOKEN CARD ──────────────────────────────────────────────────────

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
        content: const Text('API Bearer token copied'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _regenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate API token?'),
        content: const Text(
          'Existing LAN clients using the current token will lose access and must be updated.',
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
        await controller.start(port: status.port, lanMode: true);
      }

      ref.invalidate(serverBearerTokenProvider);

      if (mounted) {
        setState(() => _showToken = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('API token regenerated'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: tokenAsync.when(
          loading: () => const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Loading API token...', style: TextStyle(fontSize: 12)),
            ],
          ),
          error: (error, _) => Text(
            'Unable to load API token',
            style: TextStyle(color: scheme.error, fontSize: 12),
          ),
          data: (token) {
            if (token == null || token.isEmpty) {
              return const Text(
                'LAN token has not been generated yet.',
                style: TextStyle(fontSize: 12),
              );
            }

            final masked =
                '${token.substring(0, 6)}••••••••••••${token.substring(token.length - 6)}';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'LAN Bearer Authentication',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Regenerate token',
                      icon: _regenerating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16),
                      onPressed: _regenerating ? null : _regenerate,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _showToken ? token : masked,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showToken ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 16,
                        ),
                        onPressed: () => setState(() => _showToken = !_showToken),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        onPressed: () => _copyToken(token),
                      ),
                    ],
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

// ─── 5. DEVELOPER USE CASES & QUICK START ──────────────────────────────────

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
    final openAiBase = 'http://${widget.apiHost}:${widget.port}/v1';
    final ollamaBase = 'http://${widget.apiHost}:${widget.port}';

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
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
                  color: _brandDeep.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.code_rounded, size: 16, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Developer Quick Start',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Direct configuration snippets for coding assistants & scripts',
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

          // Structured Assistant Switcher
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTab(0, 'Cursor', Icons.bolt_rounded),
                const SizedBox(width: 6),
                _buildTab(1, 'VS Code', Icons.code_rounded),
                const SizedBox(width: 6),
                _buildTab(2, 'Python', Icons.terminal_rounded),
                const SizedBox(width: 6),
                _buildTab(3, 'cURL', Icons.data_object_rounded),
                const SizedBox(width: 6),
                _buildTab(4, 'Ollama', Icons.dns_rounded),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Active Structured View
          switch (_tabIndex) {
            0 => _buildCursorTab(scheme, openAiBase),
            1 => _buildVsCodeTab(scheme, openAiBase),
            2 => _buildPythonTab(scheme, openAiBase),
            3 => _buildCurlTab(scheme, openAiBase),
            _ => _buildOllamaTab(scheme, ollamaBase),
          },
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final selected = _tabIndex == index;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _tabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2CA048)
              : scheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2CA048).withValues(alpha: 0.32),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCursorTab(ColorScheme scheme, String openAiBase) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2CA048).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2CA048).withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFF2CA048)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configure in Cursor Settings',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '1. Open Cursor Settings (Ctrl+, / Cmd+,) → Models\n2. Add custom model: ${widget.chatId}\n3. Check "Override OpenAI Base URL" & paste URL\n4. Set API Key to thinai',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildCredentialRow(
          scheme,
          label: 'Override Base URL',
          value: openAiBase,
          isMonospace: true,
          onCopy: () => _copy(openAiBase, 'Base URL'),
        ),
        const SizedBox(height: 6),
        _buildCredentialRow(
          scheme,
          label: 'Model Name',
          value: widget.chatId,
          isMonospace: true,
          onCopy: () => _copy(widget.chatId, 'Model Name'),
        ),
        const SizedBox(height: 6),
        _buildCredentialRow(
          scheme,
          label: 'API Key',
          value: 'thinai',
          onCopy: () => _copy('thinai', 'API Key'),
        ),
      ],
    );
  }

  Widget _buildVsCodeTab(ColorScheme scheme, String openAiBase) {
    final configJson = '''{
  "models": [
    {
      "title": "Thinai Local",
      "provider": "openai",
      "model": "${widget.chatId}",
      "apiBase": "$openAiBase",
      "apiKey": "thinai"
    }
  ]
}''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'For Continue.dev or Cline extensions in VS Code:',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
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
          value: 'thinai',
          onCopy: () => _copy('thinai', 'API Key'),
        ),
        const SizedBox(height: 10),
        _buildCodeBox(scheme, configJson, 'Copy config.json for Continue', lang: 'JSON'),
      ],
    );
  }

  Widget _buildPythonTab(ColorScheme scheme, String openAiBase) {
    final pythonCode = '''from openai import OpenAI

client = OpenAI(
    base_url="$openAiBase",
    api_key="thinai",
)

response = client.chat.completions.create(
    model="${widget.chatId}",
    messages=[{"role": "user", "content": "Hello on-device AI!"}],
)

print(response.choices[0].message.content)''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Run on-device inference with the official OpenAI Python package:',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        _buildCodeBox(scheme, pythonCode, 'Copy Python Code', lang: 'PYTHON'),
      ],
    );
  }

  Widget _buildCurlTab(ColorScheme scheme, String openAiBase) {
    final curlCode = '''curl $openAiBase/chat/completions \\
  -H "Content-Type: application/json" \\
  -d '{
    "model": "${widget.chatId}",
    "messages": [{"role": "user", "content": "Hello on-device AI!"}],
    "stream": false
  }' ''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Direct terminal HTTP request with standard JSON payload:',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        _buildCodeBox(scheme, curlCode, 'Copy cURL Command', lang: 'BASH'),
      ],
    );
  }

  Widget _buildOllamaTab(ColorScheme scheme, String ollamaBase) {
    final envCmd = 'export OLLAMA_HOST=$ollamaBase';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect Open-WebUI, Chatbox, or point Ollama CLI to Thinai:',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
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
        const SizedBox(height: 6),
        _buildCredentialRow(
          scheme,
          label: 'Env Variable',
          value: envCmd,
          isMonospace: true,
          onCopy: () => _copy(envCmd, 'Environment Variable'),
        ),
      ],
    );
  }

  Widget _buildCredentialRow(
    ColorScheme scheme, {
    required String label,
    required String value,
    bool isMonospace = false,
    VoidCallback? onCopy,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
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
              icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2CA048)),
              tooltip: 'Copy $label',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  Widget _buildCodeBox(ColorScheme scheme, String code, String copyLabel, {String lang = 'CODE'}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF090E17) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111726) : const Color(0xFF0F172A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF334155),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2CA048).withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    lang,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4ADE80),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _copy(code, copyLabel),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF4ADE80)),
                        const SizedBox(width: 5),
                        Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: Color(0xFFE2E8F0),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 6. API REFERENCE HEADER & CARDS ───────────────────────────────────────

class _ApiReferenceHeader extends StatelessWidget {
  final String base;
  const _ApiReferenceHeader({required this.base});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _brandDeep.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.terminal_rounded,
            size: 18,
            color: Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'API Endpoints Reference',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Tap categories to inspect routes and copy cURL requests',
                style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copy Base URL',
          icon: const Icon(Icons.link_rounded, size: 19),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: base));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied base URL: $base'),
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
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 16,
                      color: scheme.primary,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.cards.length}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
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
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
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

class _EndpointCard extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String protocol;
  final String path;
  final String method;
  final String curl;
  final String? description;
  final String? fullUrl;

  const _EndpointCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.protocol,
    required this.path,
    required this.method,
    required this.curl,
    this.description,
    this.fullUrl,
  });

  @override
  State<_EndpointCard> createState() => _EndpointCardState();
}

class _EndpointCardState extends State<_EndpointCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPost = widget.method.toUpperCase() == 'POST';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Method Badge + Route Path + Protocol Tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isPost
                      ? const Color(0x2810B981)
                      : const Color(0x280284C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.method,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: isPost
                        ? const Color(0xFF10B981)
                        : const Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.path,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.protocol,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: widget.accent,
                  ),
                ),
              ),
            ],
          ),

          if (widget.description != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.description!,
              style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Actions Row: Expand cURL & Copy Button
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'Hide Example' : 'View cURL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 14,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (widget.fullUrl != null)
                IconButton(
                  tooltip: 'Copy Full URL',
                  icon: const Icon(Icons.link_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.fullUrl!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied ${widget.fullUrl}'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              IconButton(
                tooltip: 'Copy cURL Command',
                icon: const Icon(Icons.copy_rounded, size: 15),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.curl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied cURL command'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // Collapsible cURL Snippet Container
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: SelectableText(
                widget.curl,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  color: scheme.onSurface,
                  height: 1.38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 7. STATUS DOT ─────────────────────────────────────────────────────────

class _StatusDot extends StatefulWidget {
  final bool running;
  const _StatusDot({required this.running});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  AnimationController get _c =>
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat();

  @override
  void dispose() {
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
                  color: const Color(0xFF10B981)
                      .withValues(alpha: 0.3 * (1 - _c.value)),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
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

// ─── 8. SECURITY & NETWORK NOTICE BANNER ───────────────────────────────────

class _SecurityNoticeBanner extends StatelessWidget {
  final bool lanShare;
  final int port;

  const _SecurityNoticeBanner({
    required this.lanShare,
    required this.port,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            lanShare ? Icons.wifi_protected_setup_rounded : Icons.lock_outline_rounded,
            size: 17,
            color: lanShare ? const Color(0xFF10B981) : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lanShare
                  ? 'Wi-Fi Network Serving Active · Any device on this local subnet can query the API on port $port with your Bearer token.'
                  : 'Local Loopback Active · Only apps executing directly on this hardware can query localhost:$port.',
              style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
