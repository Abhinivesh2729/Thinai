import 'package:flutter/material.dart';

import '../../llm/context_limits.dart';
import '../../llm/generation_settings.dart';
import '../../models_repo/model_store.dart';

/// Opens the context window and temperature controls for [model].
///
/// The same sheet from the Chat tab and the Server page, writing to the one
/// [GenerationSettingsStore] both read, so a model tuned in either place
/// behaves that way in both.
Future<void> showModelSettingsSheet(BuildContext context, LocalModel model) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ModelSettingsSheet(model: model),
  );
}

class ModelSettingsSheet extends StatefulWidget {
  const ModelSettingsSheet({super.key, required this.model});

  final LocalModel model;

  @override
  State<ModelSettingsSheet> createState() => _ModelSettingsSheetState();
}

class _ModelSettingsSheetState extends State<ModelSettingsSheet> {
  final _store = GenerationSettingsStore.instance;

  ContextLimit? _limit;
  int _context = kMinContextSize;
  double _temperature = kDefaultTemperature;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final resolved = await _store.resolve(widget.model);
    if (!mounted) return;
    setState(() {
      _limit = resolved.limit;
      _context = resolved.contextSize;
      _temperature = resolved.temperature;
    });
  }

  Future<void> _reset() async {
    await _store.reset(widget.model.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final limit = _limit;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: limit == null
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Model settings', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    widget.model.id,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Used by chat and the API server. Requests can override '
                    'these, up to the maximum.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  _contextSection(theme, limit),
                  const SizedBox(height: 24),
                  _temperatureSection(theme),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurfaceVariant,
                      ),
                      onPressed: _reset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reset to defaults'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _contextSection(ThemeData theme, ContextLimit limit) {
    final scheme = theme.colorScheme;
    final steps = limit.steps;
    final index = steps.indexOf(_context).clamp(0, steps.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Context window', style: theme.textTheme.titleSmall),
            ),
            Text(
              '${_tokens(_context)} tokens',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ),
        if (steps.length > 1)
          Slider(
            value: index.toDouble(),
            min: 0,
            max: (steps.length - 1).toDouble(),
            divisions: steps.length - 1,
            label: _tokens(steps[index]),
            onChanged: (v) => setState(() => _context = steps[v.round()]),
            onChangeEnd: (v) =>
                _store.update(widget.model.id, contextSize: steps[v.round()]),
          ),
        Text(
          _capExplanation(limit),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Longer windows remember more but use more RAM and run slower.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _temperatureSection(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Temperature', style: theme.textTheme.titleSmall),
            ),
            Text(
              _temperature.toStringAsFixed(2),
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: _temperature,
          min: 0,
          max: kMaxTemperature,
          divisions: (kMaxTemperature / 0.05).round(),
          label: _temperature.toStringAsFixed(2),
          onChanged: (v) => setState(() => _temperature = v),
          onChangeEnd: (v) => _store.update(widget.model.id, temperature: v),
        ),
        Row(
          children: [
            Text(
              'Precise',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              'Creative',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Says which ceiling holds the window down, since "why can't I pick 32K"
  /// has a different answer for a small phone than for a small model.
  String _capExplanation(ContextLimit limit) {
    final max = 'Maximum ${_tokens(limit.cap)}';
    final trained = limit.trained;
    if (limit.ramLimited) {
      return trained == null
          ? '$max, limited by this phone\'s RAM.'
          : '$max, limited by RAM (model supports ${_tokens(trained)}).';
    }
    if (trained != null) {
      return '$max, this model\'s training limit.';
    }
    return '$max.';
  }

  static String _tokens(int n) {
    if (n >= 1024 * 1024 && n % (1024 * 1024) == 0) {
      return '${n ~/ (1024 * 1024)}M';
    }
    if (n >= 1024 && n % 1024 == 0) return '${n ~/ 1024}K';
    return '$n';
  }
}
