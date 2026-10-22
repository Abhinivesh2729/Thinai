import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../../server/api_tokens.dart';
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
  /// The port the next start binds to. The running server keeps its own.
  int _port = 11434;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _restorePort();
  }

  Future<void> _restorePort() async {
    final port = await ref.read(savedServerPortProvider.future);
    if (!mounted) return;
    setState(() => _port = port);
  }

  Future<void> _start() async {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    try {
      final port = _port;
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
          _toast(context.l10n.serverToastLanNoAddress);
        }
      } else if (status.error != null && mounted) {
        _toast(context.l10n.serverToastStartFailed('${status.error}'));
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
    final controller = TextEditingController(text: '$_port');
    final newPort = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.serverPortDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.serverPortNumberLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  label: const Text('8080'),
                  onPressed: () => controller.text = '8080',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final p = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, p);
            },
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );

    if (newPort != null && newPort > 0 && newPort <= 65535) {
      setState(() => _port = newPort);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('server_port', newPort);
      ref.invalidate(savedServerPortProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Settings can change the port too; follow it.
    ref.listen(savedServerPortProvider, (_, next) {
      final saved = next.valueOrNull;
      if (saved != null && saved != _port) setState(() => _port = saved);
    });
    final status = ref.watch(serverControllerProvider);
    // A new port only applies on the next start, so show it until then.
    final port = status.running ? status.port : _port;
    final activeId = ref.watch(activeModelIdProvider);
    final lanShare = ref.watch(lanShareProvider);
    final deviceIp = ref.watch(deviceLanIpProvider).valueOrNull;

    final apiHost = lanShare
        ? (status.lanIp ?? deviceIp ?? '127.0.0.1')
        : '127.0.0.1';
    final base = 'http://$apiHost:$port';
    final chatId = activeId ?? 'model-id';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.navServer,
          style: const TextStyle(
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
            port: port,
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
              final model = await ref
                  .read(modelStoreProvider)
                  .findById(activeId);
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
            port: port,
            onChanged: _setLanShare,
          ),

          // 3b. Temporary public URL through a free Cloudflare quick tunnel
          _PublicTunnelCard(status: status),

          // 3c. Named API tokens for LAN and tunnel clients
          const _ApiTokensCard(),

          // 4. Full-Width Developer Quick Connect
          _DeveloperQuickStartCard(
            base: base,
            apiHost: apiHost,
            port: port,
            chatId: chatId,
            lanShare: lanShare,
          ),

          // 5. Full-Width Clean API Endpoints List (No bloated categories)
          _ApiEndpointsSection(base: base, chatId: chatId),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final serverUrl = lan && lanIp != null
        ? 'http://$lanIp:$port'
        : 'http://127.0.0.1:$port';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B111A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: running
              ? const Color(0xFF2CA048).withValues(alpha: isDark ? 0.45 : 0.35)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: running
                ? const Color(
                    0xFF2CA048,
                  ).withValues(alpha: isDark ? 0.16 : 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Background Pattern (Contained within card, high contrast in light theme)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
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
                              Color(0xFF16A34A),
                              Color(0xFF2CA048),
                              Color(0xFF059669),
                              Color(0xFF047857),
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
                              Color(0xFF16A34A),
                              Color(0xFF22C55E),
                            ]),
                backgroundColor: isDark
                    ? const Color(0xFF080D14)
                    : const Color(0xFFF8FAFC),
                enabledWaves: const ['top', 'middle', 'bottom'],
                lineCount: const [5, 6, 5],
                lineDistance: const [4.0, 4.5, 4.0],
                topWavePosition: const WavePosition(
                  x: 8.0,
                  y: 0.45,
                  rotate: -0.35,
                ),
                middleWavePosition: const WavePosition(
                  x: 4.0,
                  y: 0.0,
                  rotate: 0.18,
                ),
                bottomWavePosition: const WavePosition(
                  x: 1.8,
                  y: -0.55,
                  rotate: 0.35,
                ),
                interactive: true,
                bendRadius: 4.0,
                bendStrength: -0.45,
                mouseDamping: 0.08,
                parallax: true,
                parallaxStrength: 0.15,
              ),
            ),
          ),

          // Readability gradient overlay (Subtle so light theme pattern is punchy & visible)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF090E17).withValues(alpha: 0.55),
                          const Color(0xFF0E1624).withValues(alpha: 0.72),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withValues(alpha: 0.12),
                          const Color(0xFFF1F5F9).withValues(alpha: 0.28),
                        ],
                ),
              ),
            ),
          ),

          // Status, URL and the start/stop button, stacked so long labels
          // (Tamil) always get the full width.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _StatusDot(running: running),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          key: ValueKey(running),
                          child: Text(
                            running
                                ? context.l10n.serverStatusRunning
                                : context.l10n.serverStatusStopped,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: context.tracking(-0.4),
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PortChip(port: port, onTap: running ? null : onEditPort),
                  ],
                ),
                const SizedBox(height: 14),
                _UrlStrip(url: serverUrl, running: running),
                const SizedBox(height: 12),
                _StartStopButton(
                  running: running,
                  busy: isTransitioning,
                  onStart: onStart,
                  onStop: onStop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortChip extends StatelessWidget {
  final int port;
  final VoidCallback? onTap;

  const _PortChip({required this.port, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162030) : const Color(0xFFF1F5F9),
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
    );
  }
}

class _UrlStrip extends StatelessWidget {
  final String url;
  final bool running;

  const _UrlStrip({required this.url, required this.running});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final live = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0B111A).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: running
              ? const Color(0xFF2CA048).withValues(alpha: isDark ? 0.40 : 0.30)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_rounded,
            size: 14,
            color: running ? live : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              url,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: running
                    ? live
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.serverCopyAddressTooltip,
            icon: const Icon(Icons.copy_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.serverCopiedLabel(url)),
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
    );
  }
}

/// Full width, so the label never has to shrink to fit.
class _StartStopButton extends StatelessWidget {
  final bool running;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _StartStopButton({
    required this.running,
    required this.busy,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final color = running ? const Color(0xFFE11D48) : _brandDeep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      constraints: const BoxConstraints(minHeight: 46),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: busy
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  if (running) {
                    onStop();
                  } else {
                    onStart();
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: busy
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        key: ValueKey(running),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            running
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              running
                                  ? context.l10n.serverStop
                                  : context.l10n.serverStart,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
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
                        context.l10n.serverServingModel,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                          letterSpacing: context.tracking(0.6),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(context.l10n.serverTune),
                ),
              ],
            )
          // Wraps the button under the text when both do not fit.
          : Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  context.l10n.serverNoModelLoaded,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onBrowseModels,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(context.l10n.serverBrowseModels),
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
  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.serverCopiedLabel(label)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shareIp = widget.lanIp ?? widget.deviceIp;

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
                    Text(
                      context.l10n.serverLanShareTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.enabled
                          ? context.l10n.serverLanShareOnSubtitle
                          : context.l10n.serverLanShareOffSubtitle,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: widget.enabled, onChanged: widget.onChanged),
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
                                  : scheme.surfaceContainerHigh.withValues(
                                      alpha: 0.5,
                                    ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : scheme.outlineVariant.withValues(
                                        alpha: 0.4,
                                      ),
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
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 15,
                                    color: Color(0xFF2CA048),
                                  ),
                                  tooltip: context.l10n.serverCopyLanUrlTooltip,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  onPressed: () => _copy(
                                    'http://$shareIp:${widget.port}',
                                    'LAN URL',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
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

// ─── 3b. PUBLIC URL (CLOUDFLARE QUICK TUNNEL) ────────────────────────────────

class _PublicTunnelCard extends ConsumerStatefulWidget {
  final ServerStatus status;

  const _PublicTunnelCard({required this.status});

  @override
  ConsumerState<_PublicTunnelCard> createState() => _PublicTunnelCardState();
}

class _PublicTunnelCardState extends ConsumerState<_PublicTunnelCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function(ServerController c) action) async {
    setState(() => _busy = true);
    final controller = ref.read(serverControllerProvider.notifier);
    try {
      await action(controller);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    final error = ref.read(serverControllerProvider).error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.serverTunnelFailed(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = widget.status;
    final url = status.publicUrl;

    return _SectionCard(
      title: context.l10n.serverTunnelTitle,
      subtitle: !status.running
          ? context.l10n.serverTunnelStartServerFirst
          : url != null
          ? context.l10n.serverTunnelOnSubtitle
          : context.l10n.serverTunnelOffSubtitle,
      trailing: _busy
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Switch(
              value: url != null,
              onChanged: status.running
                  ? (on) => _run((c) => on ? c.startTunnel() : c.stopTunnel())
                  : null,
            ),
      child: url == null
          ? null
          : Row(
              children: [
                Expanded(child: _UrlStrip(url: url, running: true)),
                IconButton(
                  icon: Icon(
                    Icons.autorenew_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  tooltip: context.l10n.serverTunnelRotate,
                  onPressed: _busy ? null : () => _run((c) => c.startTunnel()),
                ),
              ],
            ),
    );
  }
}

// ─── 3c. NAMED API TOKENS ────────────────────────────────────────────────────

class _ApiTokensCard extends ConsumerWidget {
  const _ApiTokensCard();

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    // No controller: disposing one here would race the dialog's exit
    // animation, which still renders the TextField.
    var typed = '';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.serverTokenNew),
        content: TextField(
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(
            labelText: context.l10n.serverTokenNameLabel,
          ),
          onChanged: (v) => typed = v,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, typed),
            child: Text(context.l10n.serverTokenCreate),
          ),
        ],
      ),
    );
    if (name == null) return;
    await ref.read(apiTokensProvider.notifier).create(name);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, ApiToken t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.serverTokenDeleteTitle(t.name)),
        content: Text(context.l10n.serverTokenDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.serverTokenDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(apiTokensProvider.notifier).delete(t.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = ref.watch(apiTokensProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat('d MMM y, HH:mm', locale);

    return _SectionCard(
      title: context.l10n.serverTokensTitle,
      subtitle: context.l10n.serverTokensSubtitle,
      trailing: TextButton.icon(
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(context.l10n.serverTokenNew),
        onPressed: () => _create(context, ref),
      ),
      child: tokens.isEmpty
          ? Text(
              context.l10n.serverTokensEmpty,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            )
          : Column(
              children: [
                for (final t in tokens) ...[
                  _ValueRow(
                    label: t.name,
                    sublabel: context.l10n.serverTokenCreatedOn(
                      dateFmt.format(t.createdAt),
                    ),
                    value:
                        '${t.token.substring(0, 4)}••••••${t.token.substring(t.token.length - 4)}',
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 15,
                          color: Color(0xFF2CA048),
                        ),
                        tooltip: context.l10n.serverTokenCopyTooltip,
                        onPressed: () => _copyText(context, t.token, t.name),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: scheme.error,
                        ),
                        tooltip: context.l10n.serverTokenDelete,
                        onPressed: () => _delete(context, ref, t),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

void _copyText(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.serverCopiedLabel(label)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// The bordered full-width section the Server page stacks: a title,
/// subtitle and trailing control, with optional content below.
class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final Widget? child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}

/// A labelled monospace value in the page's tinted pill, with trailing
/// actions.
class _ValueRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final String value;
  final List<Widget> actions;

  const _ValueRow({
    required this.label,
    required this.value,
    required this.actions,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    final valueText = SelectableText(
      value,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    );
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                valueText,
              ],
            ),
          ),
          ...actions,
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
                Text(
                  context.l10n.serverDevQuickStartTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
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
                _buildTab(3, 'JSON', Icons.data_object_rounded),
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
    final configJson =
        '''{
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

    return _VsCodeTerminalBox(
      tabs: [
        _VsCodeFileTab(
          filename: 'config.json',
          language: 'json',
          code: configJson,
          icon: Icons.data_object_rounded,
        ),
      ],
    );
  }

  Widget _buildPythonTab(ColorScheme scheme, String openAiBase, bool isDark) {
    final pyCode =
        '''from openai import OpenAI

client = OpenAI(
    base_url="$openAiBase",
    api_key="thinai",
)

response = client.chat.completions.create(
    model="${widget.chatId}",
    messages=[{"role": "user", "content": "Hello on-device AI!"}],
)
print(response.choices[0].message.content)''';

    return _VsCodeTerminalBox(
      tabs: [
        _VsCodeFileTab(
          filename: 'client.py',
          language: 'python',
          code: pyCode,
          icon: Icons.code_rounded,
        ),
      ],
    );
  }

  Widget _buildCurlTab(ColorScheme scheme, String openAiBase, bool isDark) {
    final curlCode =
        '''curl $openAiBase/chat/completions \\
  -H "Content-Type: application/json" \\
  -d '{
    "model": "${widget.chatId}",
    "messages": [{"role": "user", "content": "Hello on-device AI!"}],
    "stream": false
  }' ''';

    return _VsCodeTerminalBox(
      tabs: [
        _VsCodeFileTab(
          filename: 'request.sh',
          language: 'bash',
          code: curlCode,
          icon: Icons.terminal_rounded,
        ),
      ],
    );
  }

  Widget _buildChatJsonTab(ColorScheme scheme, String openAiBase, bool isDark) {
    final chatJson =
        '''{
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

    return _VsCodeTerminalBox(
      tabs: [
        _VsCodeFileTab(
          filename: 'payload.json',
          language: 'json',
          code: chatJson,
          icon: Icons.data_object_rounded,
        ),
      ],
    );
  }

  Widget _buildOllamaTab(ColorScheme scheme, String ollamaBase, bool isDark) {
    final envCmd = 'export OLLAMA_HOST=$ollamaBase';

    return _VsCodeTerminalBox(
      tabs: [
        _VsCodeFileTab(
          filename: 'env.sh',
          language: 'bash',
          code: envCmd,
          icon: Icons.terminal_rounded,
        ),
      ],
    );
  }
}

// ─── 5. FULL-WIDTH CLEAN API ENDPOINTS SECTION ───────────────────────────────

class _ApiEndpointsSection extends StatefulWidget {
  final String base;
  final String chatId;

  const _ApiEndpointsSection({required this.base, required this.chatId});

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
        content: Text(context.l10n.serverCopiedLabel(label)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    final endpoints = [
      _EndpointItem(
        method: 'POST',
        path: '/v1/chat/completions',
        title: l10n.serverEndpointOpenAiChat,
        curl:
            'curl ${widget.base}/v1/chat/completions \\\n'
            '  -H "Content-Type: application/json" \\\n'
            '  -d \'{\n'
            '    "model": "${widget.chatId}",\n'
            '    "messages": [{"role": "user", "content": "Hello!"}],\n'
            '    "stream": false\n'
            '  }\'',
        requestJson:
            '{\n'
            '  "model": "${widget.chatId}",\n'
            '  "messages": [\n'
            '    {"role": "system", "content": "You are a helpful assistant."},\n'
            '    {"role": "user", "content": "Hello!"}\n'
            '  ],\n'
            '  "temperature": 0.7,\n'
            '  "stream": false\n'
            '}',
        responseJson:
            '{\n'
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
        title: l10n.serverEndpointOllamaChat,
        curl:
            'curl ${widget.base}/api/chat \\\n'
            '  -H "Content-Type: application/json" \\\n'
            '  -d \'{\n'
            '    "model": "${widget.chatId}",\n'
            '    "messages": [{"role": "user", "content": "Why is the sky blue?"}],\n'
            '    "stream": false\n'
            '  }\'',
        requestJson:
            '{\n'
            '  "model": "${widget.chatId}",\n'
            '  "messages": [\n'
            '    {"role": "user", "content": "Why is the sky blue?"}\n'
            '  ],\n'
            '  "stream": false\n'
            '}',
        responseJson:
            '{\n'
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
        title: l10n.serverEndpointEmbeddings,
        curl:
            'curl ${widget.base}/v1/embeddings \\\n'
            '  -H "Content-Type: application/json" \\\n'
            '  -d \'{\n'
            '    "model": "${widget.chatId}",\n'
            '    "input": "Search query text"\n'
            '  }\'',
        requestJson:
            '{\n'
            '  "model": "${widget.chatId}",\n'
            '  "input": "Search query text"\n'
            '}',
        responseJson:
            '{\n'
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
        title: l10n.serverEndpointModels,
        curl: 'curl ${widget.base}/v1/models',
        requestJson: null,
        responseJson:
            '{\n'
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
            child: Text(
              l10n.serverApiEndpointsTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
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
    ColorScheme scheme,
    bool isDark,
    _EndpointItem item,
    int index,
  ) {
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
    final activeTabIndex = (_endpointFormatIndices[index] ?? 0).clamp(
      0,
      maxTabIndex,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _expandedIndex = expanded ? null : index),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2.5,
                    ),
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
                    tooltip: context.l10n.serverCopyCurlTooltip,
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    color: scheme.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () => _copy(item.curl, '${item.path} cURL'),
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
  static const Color keywordColor = Color(
    0xFF569CD6,
  ); // VS Code blue (curl, export)
  static const Color pyKeywordColor = Color(
    0xFFC586C0,
  ); // VS Code purple (from, import)
  static const Color stringColor = Color(0xFFCE9178); // VS Code orange
  static const Color jsonKeyColor = Color(
    0xFF9CDCFE,
  ); // VS Code light blue property
  static const Color numberColor = Color(
    0xFFB5CEA8,
  ); // VS Code number light green
  static const Color functionColor = Color(
    0xFFDCDCAA,
  ); // VS Code function yellow
  static const Color urlColor = Color(0xFF4EC9B0); // VS Code teal
  static const Color commentColor = Color(0xFF6A9955); // VS Code comment green
  static const Color backslashColor = Color(0xFF808080); // Gray

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
        return [
          TextSpan(
            text: code,
            style: const TextStyle(color: defaultText),
          ),
        ];
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
        spans.add(
          TextSpan(
            text: code.substring(lastIndex, match.start),
            style: const TextStyle(color: defaultText),
          ),
        );
      }

      if (match.group(1) != null) {
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(
              color: jsonKeyColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: const TextStyle(color: stringColor),
          ),
        );
      } else if (match.group(3) != null) {
        spans.add(
          TextSpan(
            text: match.group(3),
            style: const TextStyle(color: numberColor),
          ),
        );
      } else if (match.group(4) != null) {
        spans.add(
          TextSpan(
            text: match.group(4),
            style: const TextStyle(
              color: keywordColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else if (match.group(5) != null) {
        spans.add(
          TextSpan(
            text: match.group(5),
            style: const TextStyle(color: defaultText),
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < code.length) {
      spans.add(
        TextSpan(
          text: code.substring(lastIndex),
          style: const TextStyle(color: defaultText),
        ),
      );
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
        spans.add(
          TextSpan(
            text: code.substring(lastIndex, match.start),
            style: const TextStyle(color: defaultText),
          ),
        );
      }

      if (match.group(1) != null) {
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(
              color: commentColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: const TextStyle(
              color: keywordColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      } else if (match.group(3) != null) {
        spans.add(
          TextSpan(
            text: match.group(3),
            style: const TextStyle(color: jsonKeyColor),
          ),
        );
      } else if (match.group(4) != null) {
        spans.add(
          TextSpan(
            text: match.group(4),
            style: const TextStyle(color: urlColor),
          ),
        );
      } else if (match.group(5) != null) {
        spans.add(
          TextSpan(
            text: match.group(5),
            style: const TextStyle(color: stringColor),
          ),
        );
      } else if (match.group(6) != null) {
        final text = match.group(6)!;
        if (text.startsWith("'{") || text.contains('"')) {
          spans.add(
            const TextSpan(
              text: "'",
              style: TextStyle(color: stringColor),
            ),
          );
          spans.addAll(_highlightJson(text.substring(1, text.length - 1)));
          spans.add(
            const TextSpan(
              text: "'",
              style: TextStyle(color: stringColor),
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: text,
              style: const TextStyle(color: stringColor),
            ),
          );
        }
      } else if (match.group(7) != null) {
        spans.add(
          TextSpan(
            text: match.group(7),
            style: const TextStyle(color: backslashColor),
          ),
        );
      } else if (match.group(8) != null) {
        spans.add(
          TextSpan(
            text: match.group(8),
            style: const TextStyle(color: functionColor),
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < code.length) {
      spans.add(
        TextSpan(
          text: code.substring(lastIndex),
          style: const TextStyle(color: defaultText),
        ),
      );
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
        spans.add(
          TextSpan(
            text: code.substring(lastIndex, match.start),
            style: const TextStyle(color: defaultText),
          ),
        );
      }

      if (match.group(1) != null) {
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(
              color: commentColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: const TextStyle(
              color: pyKeywordColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else if (match.group(3) != null) {
        spans.add(
          TextSpan(
            text: match.group(3),
            style: const TextStyle(color: functionColor),
          ),
        );
      } else if (match.group(4) != null) {
        spans.add(
          TextSpan(
            text: match.group(4),
            style: const TextStyle(color: stringColor),
          ),
        );
      } else if (match.group(5) != null) {
        spans.add(
          TextSpan(
            text: match.group(5),
            style: const TextStyle(color: numberColor),
          ),
        );
      } else if (match.group(6) != null) {
        spans.add(
          TextSpan(
            text: match.group(6),
            style: const TextStyle(color: jsonKeyColor),
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < code.length) {
      spans.add(
        TextSpan(
          text: code.substring(lastIndex),
          style: const TextStyle(color: defaultText),
        ),
      );
    }
    return spans;
  }
}

class _VsCodeTerminalBox extends StatefulWidget {
  final List<_VsCodeFileTab> tabs;
  final int initialTabIndex;
  final ValueChanged<int>? onTabChanged;

  const _VsCodeTerminalBox({
    required this.tabs,
    this.initialTabIndex = 0,
    this.onTabChanged,
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
    final activeTab =
        widget.tabs[_activeTabIndex.clamp(0, widget.tabs.length - 1)];
    Clipboard.setData(ClipboardData(text: activeTab.code));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
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
    final activeTab =
        widget.tabs[_activeTabIndex.clamp(0, widget.tabs.length - 1)];
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
                Container(height: 18, width: 1, color: const Color(0xFF2E2E2E)),
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
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
                        // Just the tick once copied: the long Tamil
                        // "copied" would crowd out the file tabs.
                        if (!_copied) ...[
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.commonCopy,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ],
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
                const Icon(
                  Icons.code_rounded,
                  size: 10,
                  color: Color(0xFF2CA048),
                ),
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
                const Text(
                  '•',
                  style: TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                ),
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

  AnimationController get _c => _controller ??= AnimationController(
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
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.35 * (1 - _c.value)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.25),
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
