import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/made_in_erode.dart';
import '../widgets/ui_kit.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
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
            child: Row(
              children: [
                const ThinaiMark(size: 56),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thinai', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: Space.xs),
                      Text(
                        'On-device LLM for Android, with a local API for '
                        'other apps.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _AboutSection(
            title: 'What Thinai does',
            icon: Icons.bolt_rounded,
            lines: [
              'Runs local GGUF models on your device.',
              'Lets you download, import, and switch models quickly.',
              'Provides a local endpoint for agentic Android apps.',
              'Searches the web when enabled, for up-to-date answers.',
            ],
          ),
          const _AboutSection(
            title: 'Design principles',
            icon: Icons.architecture_rounded,
            lines: [
              'Minimal UI that stays out of the way.',
              'On-device by default for privacy and speed.',
              'Simple controls for model lifecycle management.',
            ],
          ),
          const _AboutSection(
            title: 'Positioning',
            icon: Icons.layers_outlined,
            lines: [
              'An Android-first local LLM runtime layer.',
              'Serves intelligence to tools, assistants, and automations.',
            ],
          ),
          const SizedBox(height: Space.xxxl),
          const MadeInErode(),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.title,
    required this.icon,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(title),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == lines.length - 1 ? 0 : Space.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 17,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Text(
                          lines[i],
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
