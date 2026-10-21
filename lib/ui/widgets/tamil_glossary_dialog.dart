import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// The English words a Tamil user has most likely met elsewhere, next to the
/// Tamil the app uses for them. Not localized: the point is to show both.
const tamilGlossary = <(String, String)>[
  ('Chat', 'உரையாடல்'),
  ('Model', 'அறிவுரு'),
  ('Message', 'உரை'),
  ('Prompt', 'செய்தி'),
  ('System prompt', 'அமைப்பு செய்தி'),
  ('Server', 'சேவகம்'),
  ('Benchmark', 'அளவுகோல்'),
  ('Download', 'பதிவிறக்கம்'),
  ('Settings', 'அமைப்புகள்'),
];

/// Shows the glossary. Opened when the app switches to Tamil and from
/// Settings > Appearance.
Future<void> showTamilGlossary(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const TamilGlossaryDialog(),
  );
}

class TamilGlossaryDialog extends StatelessWidget {
  const TamilGlossaryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const green = Color(0xFF2CA048);

    return Dialog(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    size: 19,
                    color: green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'சொல்லகராதி',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        'Glossary',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final (i, (english, tamil)) in tamilGlossary.indexed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: i == 0
                                  ? scheme.outline
                                  : scheme.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                english,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tamil,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.commonOk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
