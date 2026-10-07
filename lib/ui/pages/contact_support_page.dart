import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  static final Uri _instagramUrl = Uri.parse(
    'https://www.instagram.com/27_ai_27/',
  );

  Future<void> _openInstagram(BuildContext context) async {
    final ok = await launchUrl(
      _instagramUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      showToast(context, 'Unable to open Instagram link');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Contact support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.xxxl,
        ),
        children: [
          AppCard(
            padding: const EdgeInsets.all(Space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(
                  icon: Icons.support_agent_rounded,
                  size: 44,
                  background: scheme.primaryContainer,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(height: Space.lg),
                Text('Need help?', style: theme.textTheme.titleLarge),
                const SizedBox(height: Space.xs),
                Text(
                  'Reach the team on Instagram. Tell us your phone model and '
                  'what you were doing, and we will take it from there.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openInstagram(context),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('@27_ai_27 on Instagram'),
                  ),
                ),
                const SizedBox(height: Space.md),
                Center(
                  child: SelectableText(
                    _instagramUrl.toString(),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          const InlineNotice(
            icon: Icons.shield_outlined,
            text:
                'Found a security issue? Please report it privately, not in a '
                'public message. See SECURITY.md in the repository.',
          ),
        ],
      ),
    );
  }
}
