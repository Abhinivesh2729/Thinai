/// Local server: network sharing, port, and a status row into the Server page.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/l10n.dart';
import '../../../platform/platform_info.dart';
import '../../../state/providers.dart';
import '../../l10n/settings_strings.dart';
import '../../shell/desk_nav.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/toast.dart';
import 'settings_widgets.dart';

// The key ServerController and savedServerPortProvider use; private there.
const _kServerPortKey = 'server_port';

class ServerSection extends ConsumerWidget {
  const ServerSection({super.key});

  Future<void> _changePort(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = await ref.read(savedServerPortProvider.future);
    if (!context.mounted) return;
    final port = await showDialog<int>(
      context: context,
      builder: (_) => _PortDialog(initial: current),
    );
    if (port == null || port == current) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kServerPortKey, port);
    ref.invalidate(savedServerPortProvider);
    final status = ref.read(serverControllerProvider);
    final restart = status.running && status.port != port;
    showDeskToast(
      restart ? l10n.settingsPortSetRestart(port) : l10n.settingsPortSet(port),
      tone: restart ? DeskTone.warning : DeskTone.success,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = SettingsStrings.of(context);
    final palette = DeskPalette.of(context);
    final lan = ref.watch(lanShareProvider);
    final status = ref.watch(serverControllerProvider);
    final port =
        ref.watch(savedServerPortProvider).valueOrNull ?? defaultServerPort;
    void setLan(bool v) =>
        unawaited(ref.read(lanShareProvider.notifier).set(v));
    void openServer() =>
        ref.read(deskPageProvider.notifier).state = DeskPage.server;

    return SettingsCard(
      children: [
        SettingsRow(
          icon: Icons.lan_outlined,
          title: s.lanTitle,
          subtitle: s.lanHint,
          onTap: () => setLan(!lan),
          trailing: DeskToggle(
            value: lan,
            onChanged: setLan,
            semanticLabel: s.lanTitle,
          ),
        ),
        SettingsRow(
          icon: Icons.numbers_rounded,
          title: l10n.settingsServerPort,
          subtitle: s.portHint(defaultServerPort),
          onTap: () => _changePort(context, ref),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ':$port',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 12),
              DeskButton(
                label: s.change,
                icon: Icons.edit_outlined,
                onPressed: () => _changePort(context, ref),
              ),
            ],
          ),
        ),
        SettingsRow(
          icon: Icons.power_settings_new_rounded,
          title: l10n.settingsServerStatus,
          subtitle: status.running
              ? s.runningOn(status.port, lan: status.lan)
              : s.statusStoppedHint,
          onTap: openServer,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Pill(
                label: status.running
                    ? l10n.settingsServerActive
                    : l10n.settingsServerOffline,
                color: status.running ? DeskColors.green : null,
                dot: true,
              ),
              const SizedBox(width: 12),
              DeskButton(
                label: s.openServer,
                icon: Icons.arrow_forward_rounded,
                onPressed: openServer,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PortDialog extends StatefulWidget {
  const _PortDialog({required this.initial});
  final int initial;

  @override
  State<_PortDialog> createState() => _PortDialogState();
}

class _PortDialogState extends State<_PortDialog> {
  late final _text = TextEditingController(text: '${widget.initial}');
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final v = int.tryParse(_text.text.trim());
    if (v == null || v < 1 || v > 65535) {
      setState(() => _error = SettingsStrings.of(context).portInvalid);
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = SettingsStrings.of(context);
    return AlertDialog(
      titleTextStyle: deskDialogTitle(context),
      title: Text(l10n.settingsChangePortTitle),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.portHint(defaultServerPort),
              style: TextStyle(
                fontSize: 12.5,
                color: DeskPalette.of(context).textMuted,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _text,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: '$defaultServerPort',
                errorText: _error,
                prefixText: ':',
              ),
            ),
          ],
        ),
      ),
      actions: [
        DeskButton(
          label: l10n.commonCancel,
          kind: DeskButtonKind.ghost,
          onPressed: () => Navigator.pop(context),
        ),
        DeskButton(
          label: l10n.commonSave,
          kind: DeskButtonKind.primary,
          onPressed: _submit,
        ),
      ],
    );
  }
}
