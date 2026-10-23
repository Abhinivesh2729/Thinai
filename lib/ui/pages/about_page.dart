import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../widgets/made_in_erode.dart';
import 'contact_support_page.dart';

/// About Thinai: version, what it does, and the technical facts.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  static const Color _brandGreen = Color(0xFF2CA048);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final version = ref.watch(appVersionProvider).valueOrNull ?? '1.0.0';
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  isDark
                      ? 'assets/images/logo_dark.png'
                      : 'assets/images/logo_transparent.png',
                  width: 190,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _brandGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _brandGreen.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'v$version',
                    style: const TextStyle(
                      color: _brandGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.aboutHeroDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _Group(
            children: [
              _FeatureRow(
                icon: Icons.shield_outlined,
                title: l10n.aboutPrivateTitle,
              ),
              _FeatureRow(
                icon: Icons.bolt_rounded,
                title: l10n.aboutAcceleratedTitle,
              ),
              _FeatureRow(icon: Icons.dns_rounded, title: l10n.aboutApiTitle),
              _FeatureRow(
                icon: Icons.auto_awesome_rounded,
                title: l10n.aboutVisionTitle,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _Group(
            children: [
              _SpecRow(
                label: l10n.aboutSpecEngine,
                value: 'llama.cpp C++20 FFI',
              ),
              _SpecRow(
                label: l10n.aboutSpecModelFormat,
                value: 'GGUF (Q4_K_M, Q8_0, BF16)',
              ),
              _SpecRow(
                label: l10n.aboutSpecArchitecture,
                value: 'ARM64-v8a NEON / FP16',
              ),
              _SpecRow(
                label: l10n.aboutSpecBackends,
                value: 'CPU, Vulkan, OpenCL',
              ),
              _SpecRow(
                label: l10n.aboutSpecLicense,
                value: l10n.aboutSpecLicenseValue,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'Thinai',
                    applicationVersion: 'v$version',
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        isDark
                            ? 'assets/images/logo_dark.png'
                            : 'assets/images/logo_transparent.png',
                        width: 80,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: Text(l10n.aboutLicenses),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ContactSupportPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text(l10n.aboutContactSupport),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          const MadeInErode(compact: false),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// A rounded card holding rows separated by hairlines.
class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const _SpecDivider(),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureRow({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AboutPage._brandGreen),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecDivider extends StatelessWidget {
  const _SpecDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05),
    );
  }
}
