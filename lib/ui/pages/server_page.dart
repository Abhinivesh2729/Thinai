import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../server/foreground_handler.dart';
import '../../state/providers.dart';
import '../widgets/floating_lines_background.dart';
import '../widgets/model_settings_sheet.dart';

const _brandDeep = Color(0xFF2CA048);


class ServerPage extends ConsumerStatefulWidget {
  const ServerPage({super.key});

  @override
  ConsumerState<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends ConsumerState<ServerPage> {
  final _portController = TextEditingController(text: '11434');
  bool _isTransitioning = false;

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
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    try {
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
    } finally {
      if (mounted) setState(() => _isTransitioning = false);
    }
  }

  Future<void> _stop() async {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    try {
      await ForegroundServiceManager.serverStopped();
      await ref.read(serverControllerProvider.notifier).stop();
    } finally {
      if (mounted) setState(() => _isTransitioning = false);
    }
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
    final lanShare = ref.watch(lanShareProvider);
    final deviceIp = ref.watch(deviceLanIpProvider).valueOrNull;

    final apiHost =
        lanShare ? (status.lanIp ?? deviceIp ?? '127.0.0.1') : '127.0.0.1';
    final base = 'http://$apiHost:${status.port}';
    final chatId = activeId ?? 'model-id';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Server',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          // 1. Compact High-Density Server Control Deck
          _HeroCard(
            running: status.running,
            isTransitioning: _isTransitioning,
            port: status.port,
            lan: status.lan,
            lanIp: status.lanIp,
            onStart: _start,
            onStop: _stop,
            onEditPort: _showPortDialog,
          ),

          // 2. Full-Width Active Model Serving Strip (No decorative icon badges)
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

          // 3. Full-Width Network Sharing (LAN) & Token
          _NetworkShareCard(
            enabled: lanShare,
            running: status.running,
            lanIp: status.running ? status.lanIp : null,
            deviceIp: deviceIp,
            port: status.port,
            onChanged: _setLanShare,
          ),

          // 4. Full-Width Developer Quick Connect
          _DeveloperQuickStartCard(
            base: base,
            apiHost: apiHost,
            port: status.port,
            chatId: chatId,
            lanShare: lanShare,
          ),

          // 5. Full-Width Clean API Endpoints List (No bloated categories)
          _ApiEndpointsSection(
            base: base,
            chatId: chatId,
          ),

          // 6. Full-Width Security Notice
          _SecurityNoticeBanner(
            lanShare: lanShare,
            port: status.port,
          ),
        ],
      ),
    );
  }
}

// ─── 1. FULL-WIDTH HERO SERVER CARD ──────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final bool running;
  final bool isTransitioning;
  final int port;
  final bool lan;
  final String? lanIp;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onEditPort;

  const _HeroCard({
    required this.running,
    required this.isTransitioning,
    required this.port,
    required this.lan,
    required this.lanIp,
    required this.onStart,
    required this.onStop,
    required this.onEditPort,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final serverUrl =
        lan && lanIp != null ? 'http://$lanIp:$port' : 'http://127.0.0.1:$port';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1522) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: running
                ? const Color(0xFF2CA048).withValues(alpha: isDark ? 0.35 : 0.25)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Background Pattern (Runs smoothly when active, static when stopped)
          Positioned.fill(
            child: FloatingLinesBackground(
              animated: running,
              isDark: isDark,
              animationSpeed: 0.9,
              linesGradient: running
                  ? (isDark
                      ? const [
                          Color(0xFF2CA048),
                          Color(0xFF4ADE80),
                          Color(0xFF10B981),
                          Color(0xFF6EE7B7),
                          Color(0xFFA7F3D0),
                        ]
                      : const [
                          Color(0xFF15803D),
                          Color(0xFF2CA048),
                          Color(0xFF059669),
                          Color(0xFF16A34A),
                          Color(0xFF34D399),
                        ])
                  : (isDark
                      ? const [
                          Color(0xFF14532D),
                          Color(0xFF15803D),
                          Color(0xFF2CA048),
                          Color(0xFF16A34A),
                          Color(0xFF22C55E),
                        ]
                      : const [
                          Color(0xFF166534),
                          Color(0xFF15803D),
                          Color(0xFF2CA048),
                          Color(0xFF4ADE80),
                          Color(0xFF86EFAC),
                        ]),
              backgroundColor: isDark
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

          // Readability gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF090E17).withValues(alpha: 0.65),
                          const Color(0xFF0E1624).withValues(alpha: 0.80),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withValues(alpha: 0.70),
                          const Color(0xFFF1F5F9).withValues(alpha: 0.85),
                        ],
                ),
              ),
            ),
          ),

          // Spacious server control content - Identical fixed size in both Start and Stop
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Status Dot + State Title + Port Tag + Spacer + Fixed-Size Tactile Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _StatusDot(running: running),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            running ? 'Running' : 'Stopped',
                            key: ValueKey(running),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Port Configuration Tag
                    InkWell(
                      onTap: running ? null : onEditPort,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF162030)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF263650) : const Color(0xFFCBD5E1),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ':$port',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Fixed Size Tactile Start / Stop Button with smooth transition animation
                    SizedBox(
                      width: 92,
                      height: 38,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        decoration: BoxDecoration(
                          color: running ? const Color(0xFFE11D48) : _brandDeep,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: (running ? const Color(0xFFE11D48) : _brandDeep)
                                  .withValues(alpha: 0.30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: isTransitioning
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    if (running) {
                                      onStop();
                                    } else {
                                      onStart();
                                    }
                                  },
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.85, end: 1.0)
                                          .animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: isTransitioning
                                    ? const SizedBox(
                                        key: ValueKey('loading'),
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Row(
                                        key: ValueKey(running),
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            running
                                                ? Icons.stop_rounded
                                                : Icons.play_arrow_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            running ? 'Stop' : 'Start',
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom Row: Fixed-Height Endpoint / Port Strip (Identical size in both Start and Stop)
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0B111A).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: running
                          ? const Color(0xFF2CA048).withValues(alpha: isDark ? 0.40 : 0.30)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: running
                            ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      // URL Address
                      Expanded(
                        child: SelectableText(
                          serverUrl,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: running
                                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy Server Address',
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
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
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF151D2A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          lan ? 'LAN' : 'Localhost',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
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

// ─── 2. FULL-WIDTH ACTIVE MODEL SERVING STRIP ────────────────────────────────

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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: activeId != null
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 2),
                      Text(
                        activeId!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: onConfigure,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Tune'),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    'No model loaded yet. Load one to enable completions.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onBrowseModels,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Browse Models'),
                ),
              ],
            ),
    );
  }
}

// ─── 3. FULL-WIDTH NETWORK SHARE & TOKEN SECTION ─────────────────────────────

class _NetworkShareCard extends ConsumerStatefulWidget {
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
  ConsumerState<_NetworkShareCard> createState() => _NetworkShareCardState();
}

class _NetworkShareCardState extends ConsumerState<_NetworkShareCard> {
  bool _showToken = false;
  bool _regenerating = false;

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $label'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shareIp = widget.lanIp ?? widget.deviceIp;
    final tokenAsync = ref.watch(serverBearerTokenProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share on Local Network (LAN)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.enabled
                          ? 'Other computers on this Wi-Fi can reach the API'
                          : 'Only apps running directly on this phone can reach 127.0.0.1',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.enabled,
                activeThumbColor: const Color(0xFF2CA048),
                onChanged: widget.onChanged,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            child: widget.enabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        if (widget.running && shareIp != null) ...[
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF131722)
                                  : scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : scheme.outlineVariant.withValues(alpha: 0.4),
                              ),
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
                                    'http://$shareIp:${widget.port}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded,
                                      size: 15, color: Color(0xFF2CA048)),
                                  tooltip: 'Copy LAN URL',
                                  padding: EdgeInsets.zero,
                                  constraints:
                                      const BoxConstraints(minWidth: 28, minHeight: 28),
                                  onPressed: () => _copy(
                                      'http://$shareIp:${widget.port}', 'LAN URL'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        tokenAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (token) {
                            if (token == null || token.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final masked =
                                '${token.substring(0, 6)}••••••••••••${token.substring(token.length - 6)}';

                            return Container(
                              padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF131722)
                                    : scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : scheme.outlineVariant.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Token: ',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Expanded(
                                    child: SelectableText(
                                      _showToken ? token : masked,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _showToken
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 15,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints:
                                        const BoxConstraints(minWidth: 26, minHeight: 26),
                                    onPressed: () =>
                                        setState(() => _showToken = !_showToken),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 15, color: Color(0xFF2CA048)),
                                    padding: EdgeInsets.zero,
                                    constraints:
                                        const BoxConstraints(minWidth: 26, minHeight: 26),
                                    onPressed: () => _copy(token, 'Bearer token'),
                                  ),
                                  IconButton(
                                    icon: _regenerating
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(strokeWidth: 1.5),
                                          )
                                        : const Icon(Icons.refresh_rounded, size: 15),
                                    padding: EdgeInsets.zero,
                                    constraints:
                                        const BoxConstraints(minWidth: 26, minHeight: 26),
                                    onPressed: _regenerating ? null : _regenerate,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── 4. FULL-WIDTH DEVELOPER QUICK CONNECT ───────────────────────────────────

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final openAiBase = 'http://${widget.apiHost}:${widget.port}/v1';
    final ollamaBase = 'http://${widget.apiHost}:${widget.port}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Developer Quick Start',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Direct configuration snippets for coding assistants & scripts',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Structured Assistant Switcher Tabs (Freely scrollable edge-to-edge without UI limits)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTab(0, 'VS Code', Icons.code_rounded),
                const SizedBox(width: 8),
                _buildTab(1, 'Python', Icons.terminal_rounded),
                const SizedBox(width: 8),
                _buildTab(2, 'cURL', Icons.alt_route_rounded),
                const SizedBox(width: 8),
                _buildTab(3, 'Chat JSON', Icons.data_object_rounded),
                const SizedBox(width: 8),
                _buildTab(4, 'Ollama', Icons.cloud_sync_rounded),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Active Structured View
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: switch (_tabIndex) {
              0 => _buildVsCodeTab(scheme, openAiBase, isDark),
              1 => _buildPythonTab(scheme, openAiBase, isDark),
              2 => _buildCurlTab(scheme, openAiBase, isDark),
              3 => _buildChatJsonTab(scheme, openAiBase, isDark),
              _ => _buildOllamaTab(scheme, ollamaBase, isDark),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final selected = _tabIndex == index;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _tabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2CA048)
              : (isDark ? const Color(0xFF131926) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF2CA048)
                : (isDark ? const Color(0xFF1E2838) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x352CA048),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? Colors.white : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVsCodeTab(ColorScheme scheme, String openAiBase, bool isDark) {
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
        const SizedBox(height: 8),
        _VsCodeTerminalBox(
          tabs: [
            _VsCodeFileTab(
              filename: 'config.json',
              language: 'json',
              code: configJson,
              icon: Icons.data_object_rounded,
            ),
          ],
          onCopy: () => _copy(configJson, 'VS Code Config'),
        ),
      ],
    );
  }

  Widget _buildPythonTab(ColorScheme scheme, String openAiBase, bool isDark) {
    final pyCode = '''from openai import OpenAI

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
          'Query with official OpenAI Python SDK:',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        _VsCodeTerminalBox(
          tabs: [
            _VsCodeFileTab(
              filename: 'client.py',
              language: 'python',
              code: pyCode,
              icon: Icons.code_rounded,
            ),
          ],
          onCopy: () => _copy(pyCode, 'Python Script'),
        ),
      ],
    );
  }

  Widget _buildCurlTab(ColorScheme scheme, String openAiBase, bool isDark) {
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
        const SizedBox(height: 8),
        _VsCodeTerminalBox(
          tabs: [
            _VsCodeFileTab(
              filename: 'request.sh',
              language: 'bash',
              code: curlCode,
              icon: Icons.terminal_rounded,
            ),
          ],
          onCopy: () => _copy(curlCode, 'cURL Command'),
        ),
      ],
    );
  }

  Widget _buildChatJsonTab(ColorScheme scheme, String openAiBase, bool isDark) {
    final chatJson = '''{
  "model": "${widget.chatId}",
  "messages": [
    {
      "role": "user",
      "content": "Hello on-device AI!"
    }
  ],
  "temperature": 0.7,
  "stream": false
}''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OpenAI standard chat payload (/v1/chat/completions):',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        _VsCodeTerminalBox(
          tabs: [
            _VsCodeFileTab(
              filename: 'payload.json',
              language: 'json',
              code: chatJson,
              icon: Icons.data_object_rounded,
            ),
          ],
          onCopy: () => _copy(chatJson, 'Chat JSON Payload'),
        ),
      ],
    );
  }

  Widget _buildOllamaTab(ColorScheme scheme, String ollamaBase, bool isDark) {
    final envCmd = 'export OLLAMA_HOST=$ollamaBase';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Point any Ollama client (Open-WebUI, Chatbox, CLI) to Thinai:',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        _VsCodeTerminalBox(
          tabs: [
            _VsCodeFileTab(
              filename: 'env.sh',
              language: 'bash',
              code: envCmd,
              icon: Icons.terminal_rounded,
            ),
          ],
          onCopy: () => _copy(envCmd, 'Ollama Host Env'),
        ),
      ],
    );
  }
}

// ─── 5. FULL-WIDTH CLEAN API ENDPOINTS SECTION ───────────────────────────────

class _ApiEndpointsSection extends StatefulWidget {
  final String base;
  final String chatId;

  const _ApiEndpointsSection({
    required this.base,
    required this.chatId,
  });

  @override
  State<_ApiEndpointsSection> createState() => _ApiEndpointsSectionState();
}

class _ApiEndpointsSectionState extends State<_ApiEndpointsSection> {
  int? _expandedIndex;
  final Map<int, int> _endpointFormatIndices = {};

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $label'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final endpoints = [
      _EndpointItem(
        method: 'POST',
        path: '/v1/chat/completions',
        title: 'OpenAI Chat Completions',
        curl: 'curl ${widget.base}/v1/chat/completions \\\n'
            '  -H "Content-Type: application/json" \\\n'
            '  -d \'{\n'
            '    "model": "${widget.chatId}",\n'
            '    "messages": [{"role": "user", "content": "Hello!"}],\n'
            '    "stream": false\n'
            '  }\'',
        requestJson: '{\n'
            '  "model": "${widget.chatId}",\n'
            '  "messages": [\n'
            '    {"role": "system", "content": "You are a helpful assistant."},\n'
            '    {"role": "user", "content": "Hello!"}\n'
            '  ],\n'
            '  "temperature": 0.7,\n'
            '  "stream": false\n'
            '}',
        responseJson: '{\n'
            '  "id": "chatcmpl-thinai",\n'
            '  "object": "chat.completion",\n'
            '  "created": 1728400000,\n'
            '  "model": "${widget.chatId}",\n'
            '  "choices": [\n'
            '    {\n'
            '      "index": 0,\n'
            '      "message": {\n'
            '        "role": "assistant",\n'
            '        "content": "Hello! How can I assist you today?"\n'
            '      },\n'
            '      "finish_reason": "stop"\n'
            '    }\n'
            '  ],\n'
            '  "usage": {\n'
            '    "prompt_tokens": 12,\n'
            '    "completion_tokens": 9,\n'
            '    "total_tokens": 21\n'
            '  }\n'
            '}',
      ),
      _EndpointItem(
        method: 'POST',
        path: '/api/chat',
        title: 'Ollama Native Chat',
        curl: 'curl ${widget.base}/api/chat \\\n'
            '  -H "Content-Type: application/json" \\\n'
            '  -d \'{\n'
            '    "model": "${widget.chatId}",\n'
            '    "messages": [{"role": "user", "content": "Why is the sky blue?"}],\n'
            '    "stream": false\n'
            '  }\'',
        requestJson: '{\n'
            '  "model": "${widget.chatId}",\n'
            '  "messages": [\n'
            '    {"role": "user", "content": "Why is the sky blue?"}\n'
            '  ],\n'
            '  "stream": false\n'
            '}',
        responseJson: '{\n'
            '  "model": "${widget.chatId}",\n'
            '  "created_at": "2026-10-08T17:30:00Z",\n'
            '  "message": {\n'
            '    "role": "assistant",\n'
            '    "content": "The sky is blue due to Rayleigh scattering."\n'
            '  },\n'
            '  "done": true,\n'
            '  "total_duration": 482000000,\n'
            '  "eval_count": 28\n'
            '}',
      ),
      _EndpointItem(
        method: 'POST',
        path: '/v1/embeddings',
        title: 'Vector Embeddings',
        curl: 'curl ${widget.base}/v1/embeddings \\\n'
            '  -H "Content-Type: application/json" \\\n'
            '  -d \'{\n'
            '    "model": "${widget.chatId}",\n'
            '    "input": "Search query text"\n'
            '  }\'',
        requestJson: '{\n'
            '  "model": "${widget.chatId}",\n'
            '  "input": "Search query text"\n'
            '}',
        responseJson: '{\n'
            '  "object": "list",\n'
            '  "data": [\n'
            '    {\n'
            '      "object": "embedding",\n'
            '      "index": 0,\n'
            '      "embedding": [0.01248, -0.04582, 0.08912, -0.01734]\n'
            '    }\n'
            '  ],\n'
            '  "model": "${widget.chatId}",\n'
            '  "usage": {\n'
            '    "prompt_tokens": 4,\n'
            '    "total_tokens": 4\n'
            '  }\n'
            '}',
      ),
      _EndpointItem(
        method: 'GET',
        path: '/v1/models',
        title: 'Installed Models Catalog',
        curl: 'curl ${widget.base}/v1/models',
        requestJson: null,
        responseJson: '{\n'
            '  "object": "list",\n'
            '  "data": [\n'
            '    {\n'
            '      "id": "${widget.chatId}",\n'
            '      "object": "model",\n'
            '      "created": 1728400000,\n'
            '      "owned_by": "thinai-local"\n'
            '    }\n'
            '  ]\n'
            '}',
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'API Endpoints',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Standard OpenAI & Ollama compatible HTTP routes',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy Base URL',
                  icon: const Icon(Icons.link_rounded, size: 18),
                  color: const Color(0xFF2CA048),
                  onPressed: () => _copy(widget.base, 'Base URL: ${widget.base}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < endpoints.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
            _buildEndpointRow(scheme, isDark, endpoints[i], i),
          ],
        ],
      ),
    );
  }

  Widget _buildEndpointRow(
      ColorScheme scheme, bool isDark, _EndpointItem item, int index) {
    final expanded = _expandedIndex == index;
    final isPost = item.method == 'POST';

    final tabs = [
      _VsCodeFileTab(
        filename: 'curl.sh',
        language: 'bash',
        code: item.curl,
        icon: Icons.terminal_rounded,
      ),
      if (item.requestJson != null)
        _VsCodeFileTab(
          filename: 'request.json',
          language: 'json',
          code: item.requestJson!,
          icon: Icons.data_object_rounded,
        ),
      _VsCodeFileTab(
        filename: 'response.json',
        language: 'json',
        code: item.responseJson,
        icon: Icons.data_object_rounded,
      ),
    ];

    final maxTabIndex = tabs.length - 1;
    final activeTabIndex = (_endpointFormatIndices[index] ?? 0).clamp(0, maxTabIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedIndex = expanded ? null : index),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isPost
                          ? const Color(0xFF2CA048).withValues(alpha: 0.14)
                          : Colors.blueAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item.method,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: isPost
                            ? const Color(0xFF2CA048)
                            : (isDark ? Colors.lightBlueAccent : Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.path,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy cURL',
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    color: scheme.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => _copy(item.curl, '${item.path} cURL command'),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: _VsCodeTerminalBox(
                      tabs: tabs,
                      initialTabIndex: activeTabIndex,
                      onTabChanged: (newIdx) {
                        setState(() => _endpointFormatIndices[index] = newIdx);
                      },
                      onCopy: () {
                        final tab = tabs[(_endpointFormatIndices[index] ?? 0).clamp(0, maxTabIndex)];
                        _copy(tab.code, '${item.path} ${tab.filename}');
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EndpointItem {
  final String method;
  final String path;
  final String title;
  final String curl;
  final String? requestJson;
  final String responseJson;

  const _EndpointItem({
    required this.method,
    required this.path,
    required this.title,
    required this.curl,
    this.requestJson,
    required this.responseJson,
  });
}

// ─── VS CODE TERMINAL & EDITOR WIDGETS ───────────────────────────────────────

class _VsCodeFileTab {
  final String filename;
  final String language; // 'bash', 'json', 'python', 'text'
  final String code;
  final IconData? icon;

  const _VsCodeFileTab({
    required this.filename,
    required this.language,
    required this.code,
    this.icon,
  });
}

class _VsCodeSyntaxHighlighter {
  static const Color background = Color(0xFF1E1E1E);
  static const Color defaultText = Color(0xFFD4D4D4);

  // VS Code Dark+ Color Palette
  static const Color keywordColor = Color(0xFF569CD6);     // VS Code blue (curl, export)
  static const Color pyKeywordColor = Color(0xFFC586C0);   // VS Code purple (from, import)
  static const Color stringColor = Color(0xFFCE9178);      // VS Code orange
  static const Color jsonKeyColor = Color(0xFF9CDCFE);     // VS Code light blue property
  static const Color numberColor = Color(0xFFB5CEA8);      // VS Code number light green
  static const Color functionColor = Color(0xFFDCDCAA);    // VS Code function yellow
  static const Color urlColor = Color(0xFF4EC9B0);         // VS Code teal
  static const Color commentColor = Color(0xFF6A9955);     // VS Code comment green
  static const Color backslashColor = Color(0xFF808080);   // Gray

  static List<TextSpan> highlight(String code, String language) {
    switch (language.toLowerCase()) {
      case 'json':
        return _highlightJson(code);
      case 'bash':
      case 'sh':
      case 'curl':
        return _highlightBash(code);
      case 'python':
      case 'py':
        return _highlightPython(code);
      default:
        return [TextSpan(text: code, style: const TextStyle(color: defaultText))];
    }
  }

  static List<TextSpan> _highlightJson(String code) {
    final pattern = RegExp(
      r'''("(?:\\.|[^"\\])*")(?=\s*:)|("(?:\\.|[^"\\])*")|(-?\b\d+(?:\.\d+)?\b)|(\b(?:true|false|null)\b)|([{}[\],:])''',
    );
    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in pattern.allMatches(code)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: code.substring(lastIndex, match.start),
          style: const TextStyle(color: defaultText),
        ));
      }

      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(color: jsonKeyColor, fontWeight: FontWeight.w600),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(color: stringColor),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(color: numberColor),
        ));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(color: keywordColor, fontWeight: FontWeight.w600),
        ));
      } else if (match.group(5) != null) {
        spans.add(TextSpan(
          text: match.group(5),
          style: const TextStyle(color: defaultText),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < code.length) {
      spans.add(TextSpan(
        text: code.substring(lastIndex),
        style: const TextStyle(color: defaultText),
      ));
    }
    return spans;
  }

  static List<TextSpan> _highlightBash(String code) {
    final pattern = RegExp(
      r'''(#[^\r\n]*)|(\b(?:curl|export)\b)|(-[A-Za-z0-9_-]+|--[A-Za-z0-9_-]+)|(https?://[^\s\\'"\)]+)|("(?:\\.|[^"\\])*")|('(?:\\.|[^'\\])*')|(\\[\r\n]?)|(\$[A-Za-z0-9_]+)''',
    );
    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in pattern.allMatches(code)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: code.substring(lastIndex, match.start),
          style: const TextStyle(color: defaultText),
        ));
      }

      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(color: commentColor, fontStyle: FontStyle.italic),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(color: keywordColor, fontWeight: FontWeight.w700),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(color: jsonKeyColor),
        ));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(color: urlColor),
        ));
      } else if (match.group(5) != null) {
        spans.add(TextSpan(
          text: match.group(5),
          style: const TextStyle(color: stringColor),
        ));
      } else if (match.group(6) != null) {
        final text = match.group(6)!;
        if (text.startsWith("'{") || text.contains('"')) {
          spans.add(const TextSpan(text: "'", style: TextStyle(color: stringColor)));
          spans.addAll(_highlightJson(text.substring(1, text.length - 1)));
          spans.add(const TextSpan(text: "'", style: TextStyle(color: stringColor)));
        } else {
          spans.add(TextSpan(
            text: text,
            style: const TextStyle(color: stringColor),
          ));
        }
      } else if (match.group(7) != null) {
        spans.add(TextSpan(
          text: match.group(7),
          style: const TextStyle(color: backslashColor),
        ));
      } else if (match.group(8) != null) {
        spans.add(TextSpan(
          text: match.group(8),
          style: const TextStyle(color: functionColor),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < code.length) {
      spans.add(TextSpan(
        text: code.substring(lastIndex),
        style: const TextStyle(color: defaultText),
      ));
    }
    return spans;
  }

  static List<TextSpan> _highlightPython(String code) {
    final pattern = RegExp(
      r'''(#[^\r\n]*)|(\b(?:from|import|def|class|return|if|else|elif|for|in|while|as|with|try|except)\b)|(\b(?:print|OpenAI|create)\b)|("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|(\b\d+(?:\.\d+)?\b)|(\b[a-zA-Z_][a-zA-Z0-9_]*(?=\s*=))''',
    );
    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in pattern.allMatches(code)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: code.substring(lastIndex, match.start),
          style: const TextStyle(color: defaultText),
        ));
      }

      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(color: commentColor, fontStyle: FontStyle.italic),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(color: pyKeywordColor, fontWeight: FontWeight.w600),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(color: functionColor),
        ));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(color: stringColor),
        ));
      } else if (match.group(5) != null) {
        spans.add(TextSpan(
          text: match.group(5),
          style: const TextStyle(color: numberColor),
        ));
      } else if (match.group(6) != null) {
        spans.add(TextSpan(
          text: match.group(6),
          style: const TextStyle(color: jsonKeyColor),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < code.length) {
      spans.add(TextSpan(
        text: code.substring(lastIndex),
        style: const TextStyle(color: defaultText),
      ));
    }
    return spans;
  }
}

class _VsCodeTerminalBox extends StatefulWidget {
  final List<_VsCodeFileTab> tabs;
  final int initialTabIndex;
  final ValueChanged<int>? onTabChanged;
  final VoidCallback? onCopy;

  const _VsCodeTerminalBox({
    required this.tabs,
    this.initialTabIndex = 0,
    this.onTabChanged,
    this.onCopy,
  });

  @override
  State<_VsCodeTerminalBox> createState() => _VsCodeTerminalBoxState();
}

class _VsCodeTerminalBoxState extends State<_VsCodeTerminalBox> {
  late int _activeTabIndex;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex.clamp(0, widget.tabs.length - 1);
  }

  @override
  void didUpdateWidget(_VsCodeTerminalBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _activeTabIndex = widget.initialTabIndex.clamp(0, widget.tabs.length - 1);
    }
  }

  void _handleCopy() {
    final activeTab = widget.tabs[_activeTabIndex.clamp(0, widget.tabs.length - 1)];
    Clipboard.setData(ClipboardData(text: activeTab.code));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    widget.onCopy?.call();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  IconData _getDefaultTabIcon(String language) {
    switch (language.toLowerCase()) {
      case 'json':
        return Icons.data_object_rounded;
      case 'python':
      case 'py':
        return Icons.code_rounded;
      case 'bash':
      case 'sh':
      case 'curl':
      default:
        return Icons.terminal_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTab = widget.tabs[_activeTabIndex.clamp(0, widget.tabs.length - 1)];
    final lines = activeTab.code.split('\n');
    const double codeFontSize = 11.5;
    const double codeLineHeight = 1.48;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _VsCodeSyntaxHighlighter.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFF334155),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── VS Code Tab Bar / Window Header ─────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF181818),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(color: Color(0xFF2B2B2B), width: 1),
              ),
            ),
            child: Row(
              children: [
                // macOS Traffic Light Dots
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5F56),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFBD2E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF27C93F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 18,
                  width: 1,
                  color: const Color(0xFF2E2E2E),
                ),
                // File Tabs
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: List.generate(widget.tabs.length, (idx) {
                        final tab = widget.tabs[idx];
                        final isActive = idx == _activeTabIndex;
                        return InkWell(
                          onTap: () {
                            setState(() => _activeTabIndex = idx);
                            widget.onTabChanged?.call(idx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7.5,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFF252526),
                              border: Border(
                                top: BorderSide(
                                  color: isActive
                                      ? const Color(0xFF2CA048)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                right: const BorderSide(
                                  color: Color(0xFF2B2B2B),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tab.icon ?? _getDefaultTabIcon(tab.language),
                                  size: 13,
                                  color: isActive
                                      ? (tab.language == 'bash'
                                          ? const Color(0xFF4ADE80)
                                          : const Color(0xFF9CDCFE))
                                      : const Color(0xFF858585),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tab.filename,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isActive
                                        ? Colors.white
                                        : const Color(0xFF858585),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                // Copy Button with Animated Feedback
                InkWell(
                  onTap: _handleCopy,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: _copied
                          ? const Color(0xFF2CA048).withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: _copied
                            ? const Color(0xFF2CA048)
                            : Colors.white.withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 12,
                          color: _copied
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied' : 'Copy',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _copied
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Code Editor Body: Line Numbers + Syntax Highlighted Code ───
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line Number Gutter
                Container(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Color(0xFF2D2D2D), width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 1; i <= lines.length; i++)
                        Text(
                          '$i',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: codeFontSize,
                            color: Color(0xFF6E7681),
                            height: codeLineHeight,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Code View (Horizontally Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SelectableText.rich(
                        TextSpan(
                          children: _VsCodeSyntaxHighlighter.highlight(
                            activeTab.code,
                            activeTab.language,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: codeFontSize,
                          height: codeLineHeight,
                          color: Color(0xFFD4D4D4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── VS Code Mini Status Bar ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF141A17),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
              border: Border(
                top: BorderSide(color: Color(0xFF252E28), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, size: 10, color: Color(0xFF2CA048)),
                const SizedBox(width: 4),
                Text(
                  'Ln ${lines.length}, Col 1',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                const SizedBox(width: 8),
                Text(
                  activeTab.language.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4ADE80),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2CA048),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Thinai :11434',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    color: Color(0xFF94A3B8),
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



// ─── 6. STATUS DOT ───────────────────────────────────────────────────────────

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
    return SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: widget.running
              ? AnimatedBuilder(
                  key: const ValueKey('running_dot'),
                  animation: _c,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 20 * (0.65 + _c.value * 0.35),
                          height: 20 * (0.65 + _c.value * 0.35),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.35 * (1 - _c.value)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.25),
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
                )
              : Container(
                  key: const ValueKey('stopped_dot'),
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── 7. FULL-WIDTH SECURITY NOTICE BANNER ────────────────────────────────────

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }
}
