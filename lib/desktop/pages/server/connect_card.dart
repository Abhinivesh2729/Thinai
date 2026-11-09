/// Connect card: base URLs, the API key a client needs, and quick-start
/// samples for the common clients.
library;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../l10n/server_strings.dart';
import '../../theme/desk_theme.dart';
import 'samples.dart';
import 'server_widgets.dart';

class ConnectCard extends StatefulWidget {
  const ConnectCard({
    super.key,
    required this.port,
    required this.lanShare,
    required this.lanIp,
    required this.apiKey,
    required this.modelId,
  });

  final int port;
  final bool lanShare;

  /// This PC's network address, when it has one.
  final String? lanIp;

  /// The bearer token clients must send, or null when none is checked.
  final String? apiKey;
  final String modelId;

  @override
  State<ConnectCard> createState() => _ConnectCardState();
}

class _ConnectCardState extends State<ConnectCard> {
  int _sample = 0;
  bool _remote = false;

  @override
  Widget build(BuildContext context) {
    final s = ServerStrings.of(context);
    final palette = DeskPalette.of(context);

    // "Other devices" only means something while LAN sharing is on.
    final remote = widget.lanShare && _remote;
    final host = remote ? (widget.lanIp ?? '<pc-address>') : '127.0.0.1';
    final base = 'http://$host:${widget.port}';
    final dim = remote && widget.lanIp == null;
    final key = widget.apiKey;
    final auth = key != null;

    final samples = quickStartSamples(
      base: base,
      model: widget.modelId,
      auth: auth,
    );
    final sample = samples[_sample.clamp(0, samples.length - 1)];

    return ServerCard(
      icon: Icons.cable_rounded,
      title: s.connectTitle,
      subtitle: s.connectSubtitle,
      trailing: AnimatedSwitcher(
        duration: DeskMotion.medium,
        child: widget.lanShare
            ? PillTabs(
                key: const ValueKey('target'),
                dense: true,
                labels: [s.fromThisPc, s.fromOtherDevices],
                index: remote ? 1 : 0,
                onChanged: (i) => setState(() => _remote = i == 1),
              )
            : const SizedBox.shrink(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final openAi = CopyField(
                label: s.openAiBaseUrl,
                value: dim ? s.noLanAddressShort : '$base/v1',
                dimmed: dim,
              );
              final ollama = CopyField(
                label: s.ollamaUrl,
                value: dim ? s.noLanAddressShort : base,
                dimmed: dim,
              );
              if (box.maxWidth < 560) {
                return Column(
                  children: [openAi, const SizedBox(height: 14), ollama],
                );
              }
              return Row(
                children: [
                  Expanded(child: openAi),
                  const SizedBox(width: 14),
                  Expanded(child: ollama),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: DeskMotion.medium,
            child: auth
                ? CopyField(
                    key: const ValueKey('key'),
                    label: '${s.apiKey}  ·  ${s.apiKeyToken}',
                    value: maskToken(key),
                    copyValue: key,
                    copyLabel: s.apiKey,
                  )
                : Row(
                    key: const ValueKey('nokey'),
                    children: [
                      Icon(
                        Icons.key_off_rounded,
                        size: 15,
                        color: palette.textFaint,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s.apiKey}: ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: palette.textMuted,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s.apiKeyNotNeeded,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Text(
                context.l10n.serverDevQuickStartTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: PillTabs(
                    dense: true,
                    labels: [for (final x in samples) x.label],
                    index: _sample,
                    onChanged: (i) => setState(() => _sample = i),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: DeskMotion.medium,
            curve: DeskMotion.ease,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: DeskMotion.medium,
              switchInCurve: DeskMotion.ease,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: CodeBlock(
                key: ValueKey(sample.label),
                filename: sample.filename,
                language: sample.language,
                code: sample.build(auth ? maskToken(key) : kLoopbackKey),
                copyCode: sample.build(key ?? kLoopbackKey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
