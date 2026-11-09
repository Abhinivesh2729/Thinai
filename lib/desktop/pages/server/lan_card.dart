/// LAN sharing switch and the API tokens other devices authenticate with.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../../server/api_tokens.dart';
import '../../../state/providers.dart';
import '../../l10n/server_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import '../../widgets/toast.dart';
import 'server_widgets.dart';

class LanCard extends ConsumerWidget {
  const LanCard({
    super.key,
    required this.enabled,
    required this.running,
    required this.busy,
    required this.lanIp,
    required this.port,
    required this.onChanged,
  });

  final bool enabled;
  final bool running;

  /// True while the server is starting or stopping; the switch waits.
  final bool busy;
  final String? lanIp;
  final int port;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ServerStrings.of(context);
    final l10n = context.l10n;
    final palette = DeskPalette.of(context);
    final windows = defaultTargetPlatform == TargetPlatform.windows;

    Widget details() {
      final ip = lanIp;
      return Column(
        key: const ValueKey('on'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          if (ip != null && running)
            CopyField(
              label: s.lanUrl,
              value: 'http://$ip:$port',
              copyLabel: s.lanUrl,
            )
          else
            InlineNote(
              icon: ip == null && running
                  ? Icons.wifi_off_rounded
                  : Icons.play_circle_outline_rounded,
              text: ip == null && running ? s.lanNoAddress : s.lanStartHint,
              color: ip == null && running ? DeskColors.amber : null,
            ),
          if (windows) ...[
            const SizedBox(height: 10),
            InlineNote(icon: Icons.shield_outlined, text: s.firewallNote),
          ],
        ],
      );
    }

    return ServerCard(
      icon: Icons.lan_outlined,
      title: l10n.serverLanShareTitle,
      subtitle: enabled ? s.lanOn : s.lanOff,
      trailing: Tooltip(
        message: s.lanRestarts,
        child: Switch(
          value: enabled,
          activeTrackColor: DeskColors.green,
          onChanged: busy ? null : onChanged,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: DeskMotion.medium,
            curve: DeskMotion.ease,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: DeskMotion.medium,
              child: enabled
                  ? details()
                  : const SizedBox(
                      key: ValueKey('off'),
                      width: double.infinity,
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Container(height: 1, color: palette.hairline),
          ),
          const _TokensSection(),
        ],
      ),
    );
  }
}

class _TokensSection extends ConsumerStatefulWidget {
  const _TokensSection();

  @override
  ConsumerState<_TokensSection> createState() => _TokensSectionState();
}

class _TokensSectionState extends ConsumerState<_TokensSection> {
  /// Ids of tokens shown in full; masked by default so a screen share or
  /// screenshot does not leak them.
  final _revealed = <String>{};

  Future<void> _create() async {
    final s = ServerStrings.of(context);
    // No controller: disposing one here would race the dialog's exit
    // animation, which still renders the TextField.
    var typed = '';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.serverTokenNew),
        content: SizedBox(
          width: 380,
          child: TextField(
            autofocus: true,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: context.l10n.serverTokenNameLabel,
            ),
            onChanged: (v) => typed = v,
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
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
    final token = await ref.read(apiTokensProvider.notifier).create(name);
    showDeskToast(s.tokenCreated(token.name), tone: DeskTone.success);
  }

  Future<void> _delete(ApiToken t) async {
    final s = ServerStrings.of(context);
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
            style: FilledButton.styleFrom(backgroundColor: DeskColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.serverTokenDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final tokens = ref.read(apiTokensProvider.notifier);
    await tokens.delete(t.id);
    _revealed.remove(t.id);
    // LAN never runs open, so a share left with no token would lock every
    // client out until a restart. Mint a fresh one instead: the deleted
    // token stays revoked and the list shows the new one.
    final status = ref.read(serverControllerProvider);
    if (status.running && status.lan) await tokens.ensureOne();
    showDeskToast(s.tokenDeleted(t.name));
  }

  @override
  Widget build(BuildContext context) {
    final s = ServerStrings.of(context);
    final l10n = context.l10n;
    final palette = DeskPalette.of(context);
    final tokens = ref.watch(apiTokensProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat('d MMM y, HH:mm', locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.serverTokensTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.tokensSubtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.serverTokenNew),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSize(
          duration: DeskMotion.medium,
          curve: DeskMotion.ease,
          alignment: Alignment.topCenter,
          child: tokens.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    l10n.serverTokensEmpty,
                    style: TextStyle(fontSize: 12.5, color: palette.textFaint),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final t in tokens)
                      EnterAnimation(
                        key: ValueKey(t.id),
                        duration: DeskMotion.medium,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TokenRow(
                            token: t,
                            created: l10n.serverTokenCreatedOn(
                              dateFmt.format(t.createdAt),
                            ),
                            revealed: _revealed.contains(t.id),
                            onReveal: () => setState(() {
                              if (!_revealed.remove(t.id)) _revealed.add(t.id);
                            }),
                            onDelete: () => _delete(t),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.token,
    required this.created,
    required this.revealed,
    required this.onReveal,
    required this.onDelete,
  });

  final ApiToken token;
  final String created;
  final bool revealed;
  final VoidCallback onReveal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = ServerStrings.of(context);
    return Hoverable(
      builder: (context, hovered) => AnimatedContainer(
        duration: DeskMotion.fast,
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: hovered ? palette.codeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(DeskSize.radiusM),
          border: Border.all(color: palette.hairline),
        ),
        child: Row(
          children: [
            Icon(Icons.key_rounded, size: 16, color: palette.textMuted),
            const SizedBox(width: 12),
            SizedBox(
              width: 170,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    token.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    created,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: palette.textFaint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: DeskMotion.medium,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, ?current],
                ),
                child: SelectableText(
                  revealed ? token.token : maskToken(token.token),
                  key: ValueKey(revealed),
                  maxLines: 1,
                  style: monoStyle(size: 12.5, color: palette.textMuted),
                ),
              ),
            ),
            DeskIconButton(
              icon: revealed
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              tooltip: revealed ? s.tokenHide : s.tokenShow,
              iconSize: 16,
              size: 30,
              onPressed: onReveal,
            ),
            DeskIconButton(
              icon: Icons.content_copy_rounded,
              tooltip: context.l10n.serverTokenCopyTooltip,
              iconSize: 15,
              size: 30,
              color: DeskColors.green,
              onPressed: () => copyWithToast(context, token.token, token.name),
            ),
            DeskIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: context.l10n.serverTokenDelete,
              iconSize: 16,
              size: 30,
              color: DeskColors.danger,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
