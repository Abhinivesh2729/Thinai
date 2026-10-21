import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../widgets/made_in_erode.dart';

/// Where to reach us, device info to send along, and common questions.
class ContactSupportPage extends ConsumerWidget {
  const ContactSupportPage({super.key});

  static final Uri _instagramUrl = Uri.parse(
    'https://www.instagram.com/27_ai_27/',
  );
  static const String _instagramHandle = '@27_ai_27';

  Future<void> _launch(
    BuildContext context,
    Uri uri, {
    String? failureMessage,
  }) async {
    HapticFeedback.lightImpact();
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failureMessage ?? context.l10n.supportCouldNotOpenLink('$uri'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.supportFailedToOpenLink('$e')),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    final appVersion = ref.watch(appVersionProvider).valueOrNull ?? '1.0.0';
    final deviceProfile = ref.watch(deviceProfileProvider).valueOrNull;
    final activeId = ref.watch(activeModelIdProvider);
    final serverStatus = ref.watch(serverControllerProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _ChannelCard(
            badgeColor: const Color(0xFFE1306C),
            icon: Icons.camera_alt_rounded,
            title: 'Instagram',
            handle: _instagramHandle,
            description: l10n.supportInstagramBody,
            action: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _launch(
                      context,
                      _instagramUrl,
                      failureMessage: l10n.supportInstagramOpenFailed,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(l10n.supportOpenInstagram),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE1306C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: l10n.supportCopyHandle,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () => _copyToClipboard(
                    context,
                    _instagramHandle,
                    l10n.supportHandleCopied,
                  ),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: l10n.supportDiagnostics),
          const SizedBox(height: 6),
          Text(
            l10n.supportDiagnosticsHint,
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DiagnosticChip(
                      label: 'Thinai v$appVersion',
                      icon: Icons.info_outline_rounded,
                    ),
                    if (deviceProfile != null) ...[
                      _DiagnosticChip(
                        label: l10n.supportCpuCores(deviceProfile.cores),
                        icon: Icons.memory_rounded,
                      ),
                      if (deviceProfile.totalRamBytes != null)
                        _DiagnosticChip(
                          label:
                              '${(deviceProfile.totalRamBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB RAM',
                          icon: Icons.storage_rounded,
                        ),
                      _DiagnosticChip(
                        label: l10n.supportTier(
                          deviceProfile.deviceClass.name.toUpperCase(),
                        ),
                        icon: Icons.speed_rounded,
                      ),
                    ],
                    _DiagnosticChip(
                      label: activeId != null
                          ? l10n.supportModel(activeId)
                          : l10n.supportNoActiveModel,
                      icon: Icons.smart_toy_outlined,
                    ),
                    _DiagnosticChip(
                      label: serverStatus.running
                          ? l10n.supportServerActive
                          : l10n.supportServerStopped,
                      icon: Icons.dns_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      final ramStr = deviceProfile?.totalRamBytes != null
                          ? '${(deviceProfile!.totalRamBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
                          : 'Unknown';
                      final diagText = [
                        'Thinai Diagnostics Report:',
                        '• App Version: v$appVersion',
                        '• CPU Cores: ${deviceProfile?.cores ?? "Unknown"}',
                        '• Total RAM: $ramStr',
                        '• Hardware Tier: ${deviceProfile?.deviceClass.name.toUpperCase() ?? "Unknown"}',
                        '• Active Model: ${activeId ?? "None"}',
                        '• Local API Server: ${serverStatus.running ? "Active" : "Stopped"}',
                      ].join('\n');
                      _copyToClipboard(
                        context,
                        diagText,
                        l10n.supportDiagnosticsCopied,
                      );
                    },
                    icon: const Icon(Icons.copy_all_rounded, size: 18),
                    label: Text(l10n.supportCopyDiagnostics),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: l10n.supportTroubleshooting),
          const SizedBox(height: 12),

          _FaqCard(
            question: l10n.supportFaqLoadQuestion,
            answer: l10n.supportFaqLoadAnswer,
          ),
          const SizedBox(height: 10),
          _FaqCard(
            question: l10n.supportFaqPrivacyQuestion,
            answer: l10n.supportFaqPrivacyAnswer,
          ),
          const SizedBox(height: 10),
          _FaqCard(
            question: l10n.supportFaqGpuQuestion,
            answer: l10n.supportFaqGpuAnswer,
          ),

          const SizedBox(height: 28),
          const MadeInErode(compact: true),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final Color badgeColor;
  final IconData icon;
  final String title;
  final String handle;
  final String description;
  final Widget action;

  const _ChannelCard({
    required this.badgeColor,
    required this.icon,
    required this.title,
    required this.handle,
    required this.description,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      handle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          action,
        ],
      ),
    );
  }
}

class _DiagnosticChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _DiagnosticChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2CA048)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqCard({required this.question, required this.answer});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _expanded = !_expanded);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.answer,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
