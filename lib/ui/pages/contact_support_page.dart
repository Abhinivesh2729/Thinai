import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Instagram link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Contact support')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: const Text(
                'Need help? Reach us on Instagram.',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openInstagram(context),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('@27_ai_27 on Instagram'),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _instagramUrl.toString(),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
