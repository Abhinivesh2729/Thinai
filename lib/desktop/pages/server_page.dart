/// Desktop Server page: run Thinai's OpenAI / Ollama compatible API from
/// this PC, share it on the LAN with tokens, and copy client samples.
///
/// Same controllers as the phone's Server tab (lib/state/providers.dart);
/// the desktop leaves out the Android foreground service and the public
/// Cloudflare tunnel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../../platform/platform_info.dart';
import '../../state/providers.dart';
import '../../ui/widgets/model_settings_sheet.dart';
import '../l10n/server_strings.dart';
import '../shell/desk_nav.dart';
import '../theme/desk_theme.dart';
import '../widgets/hover.dart';
import '../widgets/toast.dart';
import 'server/connect_card.dart';
import 'server/endpoints_card.dart';
import 'server/hero_card.dart';
import 'server/lan_card.dart';
import 'server/port_dialog.dart';
import 'server/server_widgets.dart';

/// Same key [ServerController] persists the port under; it is private
/// there, and the port editor saves before any start happens.
const _kServerPortKey = 'server_port';

class DeskServerPage extends ConsumerStatefulWidget {
  const DeskServerPage({super.key});

  @override
  ConsumerState<DeskServerPage> createState() => _DeskServerPageState();
}

class _DeskServerPageState extends ConsumerState<DeskServerPage> {
  /// The port the next start binds to. A running server keeps its own.
  int _port = defaultServerPort;
  ServerPhase? _transition;

  /// The last start failure; cleared by the next start or a port change.
  String? _error;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _restorePort();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _restorePort() async {
    final port = await ref.read(savedServerPortProvider.future);
    if (mounted) setState(() => _port = port);
  }

  Future<void> _start() async {
    if (_transition != null) return;
    final s = ServerStrings.of(context);
    final l10n = context.l10n;
    setState(() {
      _transition = ServerPhase.starting;
      _error = null;
    });
    try {
      await ref
          .read(serverControllerProvider.notifier)
          .start(port: _port, lanMode: ref.read(lanShareProvider));
      final status = ref.read(serverControllerProvider);
      if (status.running) {
        if (status.lan && status.lanIp == null) {
          showDeskToast(s.noNetworkAddress, tone: DeskTone.warning);
        }
      } else if (status.error != null) {
        final error = status.error!;
        if (mounted) setState(() => _error = error);
        showDeskToast(switch (portProblemOf(error)) {
          PortProblem.inUse => s.portInUse(status.port),
          PortProblem.blocked => s.portBlocked(status.port),
          null => l10n.serverToastStartFailed(error),
        }, tone: DeskTone.error);
      }
    } finally {
      if (mounted) setState(() => _transition = null);
    }
  }

  Future<void> _stop() async {
    if (_transition != null) return;
    setState(() => _transition = ServerPhase.stopping);
    try {
      await ref.read(serverControllerProvider.notifier).stop();
    } finally {
      if (mounted) setState(() => _transition = null);
    }
  }

  Future<void> _restart() async {
    await _stop();
    await _start();
  }

  Future<void> _setLanShare(bool value) async {
    await ref.read(lanShareProvider.notifier).set(value);
    if (ref.read(serverControllerProvider).running) await _restart();
  }

  Future<void> _editPort() async {
    final status = ref.read(serverControllerProvider);
    final port = await showPortDialog(
      context,
      current: status.running ? status.port : _port,
      lan: ref.read(lanShareProvider),
      runningPort: status.running ? status.port : null,
    );
    if (port == null || !mounted) return;
    setState(() {
      _port = port;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kServerPortKey, port);
    ref.invalidate(savedServerPortProvider);
    // Apply at once rather than leaving the shown URL out of step with the
    // one actually serving.
    if (ref.read(serverControllerProvider).running && port != status.port) {
      await _restart();
    }
  }

  Future<void> _tune(String modelId) async {
    final model = await ref.read(modelStoreProvider).findById(modelId);
    if (model == null || !mounted) return;
    // The phone's settings sheet, hosted in a dialog: a bottom sheet across
    // a wide window reads as a mistake.
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: ModelSettingsSheet(model: model),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Settings can change the port too; follow it.
    ref.listen(savedServerPortProvider, (_, next) {
      final saved = next.valueOrNull;
      if (saved != null && saved != _port) setState(() => _port = saved);
    });

    final s = ServerStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    final status = ref.watch(serverControllerProvider);
    final activeId = ref.watch(activeModelIdProvider);
    final lanShare = ref.watch(lanShareProvider);
    final deviceIp = ref.watch(deviceLanIpProvider).valueOrNull;
    final tokens = ref.watch(apiTokensProvider);

    final phase =
        _transition ??
        (status.running ? ServerPhase.running : ServerPhase.stopped);
    final port = status.running ? status.port : _port;
    final lanIp = status.lanIp ?? deviceIp;
    final modelId = activeId ?? 'model-id';
    // With LAN sharing on, every request (loopback included) must carry a
    // token, so the samples use the first one.
    final apiKey = lanShare && tokens.isNotEmpty ? tokens.first.token : null;

    void toggle() => status.running ? _stop() : _start();

    final sections = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.navServer,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: context.tracking(-0.6),
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.pageSubtitle,
            style: TextStyle(fontSize: 14, color: palette.textMuted),
          ),
        ],
      ),
      ServerHeroCard(
        phase: phase,
        port: port,
        lan: status.running ? status.lan : lanShare,
        error: _error,
        activeModelId: activeId,
        onToggle: toggle,
        onEditPort: _editPort,
        onTune: () {
          if (activeId != null) _tune(activeId);
        },
        onChooseModel: () =>
            ref.read(deskPageProvider.notifier).state = DeskPage.models,
      ),
      ConnectCard(
        port: port,
        lanShare: lanShare,
        lanIp: lanIp,
        apiKey: apiKey,
        modelId: modelId,
      ),
      LanCard(
        enabled: lanShare,
        // A server still bound to loopback has no LAN URL to show yet.
        running: status.running && status.lan,
        busy: _transition != null,
        lanIp: status.running ? status.lanIp : deviceIp,
        port: port,
        onChanged: _setLanShare,
      ),
      EndpointsCard(
        base: 'http://127.0.0.1:$port',
        modelId: modelId,
        apiKey: apiKey,
      ),
    ];

    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(40, 36, 40, 56),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  if (i > 0) SizedBox(height: i == 1 ? 28 : 20),
                  EnterAnimation(
                    delay: Duration(milliseconds: 50 * i),
                    child: sections[i],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
