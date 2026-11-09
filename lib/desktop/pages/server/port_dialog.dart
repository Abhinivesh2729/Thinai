/// Port editor: presets, validation and a live "is it free?" check.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../../platform/platform_info.dart';
import '../../l10n/server_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import 'server_widgets.dart';

/// Returns the chosen port, already checked to be bindable, or null.
///
/// [runningPort] is the port our own server holds right now; it reads as
/// taken to the probe, so it is accepted without one.
Future<int?> showPortDialog(
  BuildContext context, {
  required int current,
  required bool lan,
  int? runningPort,
}) => showDialog<int>(
  context: context,
  builder: (_) =>
      _PortDialog(current: current, lan: lan, runningPort: runningPort),
);

class _PortDialog extends StatefulWidget {
  const _PortDialog({
    required this.current,
    required this.lan,
    required this.runningPort,
  });

  final int current;
  final bool lan;
  final int? runningPort;

  @override
  State<_PortDialog> createState() => _PortDialogState();
}

class _PortDialogState extends State<_PortDialog> {
  late final _controller = TextEditingController(text: '${widget.current}');
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _value => int.tryParse(_controller.text.trim());

  void _pick(int port) {
    _controller.text = '$port';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    setState(() => _error = null);
  }

  Future<void> _save() async {
    final s = ServerStrings.of(context);
    final port = _value;
    if (port == null || port < 1 || port > 65535) {
      setState(() => _error = s.portInvalid);
      return;
    }
    if (port == widget.runningPort || port == widget.current) {
      Navigator.pop(context, port);
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    final problem = await probePort(port, lan: widget.lan);
    if (!mounted) return;
    if (problem == null) {
      Navigator.pop(context, port);
      return;
    }
    setState(() {
      _checking = false;
      _error = problem == PortProblem.inUse
          ? s.portInUse(port)
          : s.portBlocked(port);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ServerStrings.of(context);
    final palette = DeskPalette.of(context);
    final value = _value;

    return AlertDialog(
      title: Text(context.l10n.serverPortDialogTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.portHelp,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              style: monoStyle(size: 16, weight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: context.l10n.serverPortNumberLabel,
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Preset(
                    port: kDesktopServerPort,
                    caption: s.presetDefault,
                    selected: value == kDesktopServerPort,
                    onTap: () => _pick(kDesktopServerPort),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Preset(
                    port: kMobileServerPort,
                    caption: s.presetOllama,
                    selected: value == kMobileServerPort,
                    onTap: () => _pick(kMobileServerPort),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: DeskMotion.medium,
              curve: DeskMotion.ease,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: DeskMotion.medium,
                child: _error != null
                    ? Padding(
                        key: ValueKey(_error),
                        padding: const EdgeInsets.only(top: 14),
                        child: InlineNote(
                          icon: Icons.error_outline_rounded,
                          text: _error!,
                          color: DeskColors.danger,
                        ),
                      )
                    : value == kMobileServerPort
                    ? Padding(
                        key: const ValueKey('ollama'),
                        padding: const EdgeInsets.only(top: 14),
                        child: InlineNote(
                          icon: Icons.info_outline_rounded,
                          text: s.ollamaClash,
                        ),
                      )
                    : const SizedBox(key: ValueKey('none'), width: 420),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _checking ? null : _save,
          child: AnimatedSwitcher(
            duration: DeskMotion.fast,
            child: _checking
                ? const SizedBox(
                    key: ValueKey('checking'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.commonSave, key: const ValueKey('save')),
          ),
        ),
      ],
    );
  }
}

class _Preset extends StatelessWidget {
  const _Preset({
    required this.port,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final int port;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Hoverable(
      cursor: SystemMouseCursors.click,
      builder: (context, hovered) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DeskMotion.fast,
          curve: DeskMotion.ease,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? DeskColors.green.withValues(alpha: 0.10)
                : hovered
                ? scheme.onSurface.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DeskSize.radiusM),
            border: Border.all(
              color: selected
                  ? DeskColors.green.withValues(alpha: 0.6)
                  : palette.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$port',
                style: monoStyle(
                  size: 15,
                  weight: FontWeight.w700,
                  color: selected ? DeskColors.green : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: palette.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
