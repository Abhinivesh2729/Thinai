import 'package:flutter/material.dart';

import '../../models_repo/model_store.dart';

/// Dropdown of installed models, shared by the pages that measure one: the
/// speed benchmark and the Tamil eval.
class ModelPicker extends StatelessWidget {
  const ModelPicker({
    super.key,
    required this.models,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final List<LocalModel> models;
  final LocalModel selected;
  final bool enabled;
  final ValueChanged<LocalModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected.id,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.expand_more_rounded),
          items: [
            for (final m in models)
              DropdownMenuItem(
                value: m.id,
                child: Row(
                  children: [
                    Icon(Icons.memory_rounded, size: 18, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: enabled
              ? (id) {
                  for (final m in models) {
                    if (m.id == id) {
                      onChanged(m);
                      return;
                    }
                  }
                }
              : null,
        ),
      ),
    );
  }
}
