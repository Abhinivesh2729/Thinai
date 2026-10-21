import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../llm/context_limits.dart';
import '../../llm/generation_settings.dart';
import '../../models_repo/model_store.dart';

/// Opens the context window, sampling and thinking controls for [model].
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
  int _topK = kDefaultTopK;
  double _topP = kDefaultTopP;
  bool _thinking = true;

  /// Null until the model file has been checked for a thinking mode; the
  /// switch only appears for a model that has one.
  bool? _canThink;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final resolved = await _store.resolve(widget.model);
    final canThink = await _store.supportsThinkingToggle(widget.model);
    if (!mounted) return;
    setState(() {
      _limit = resolved.limit;
      _context = resolved.contextSize;
      _temperature = resolved.temperature;
      _topK = resolved.topK.clamp(0, kMaxTopK).toInt();
      _topP = resolved.topP.clamp(kMinTopP, 1.0).toDouble();
      _thinking = resolved.thinking;
      _canThink = canThink;
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: limit == null
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            // Scrolls once the controls outgrow a short phone's sheet.
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.modelsSettingsTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.model.id,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.modelsSettingsBody,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _contextSection(theme, limit),
                    const SizedBox(height: 20),
                    _temperatureSection(theme),
                    const SizedBox(height: 20),
                    _topKSection(theme),
                    const SizedBox(height: 20),
                    _topPSection(theme),
                    if (_canThink == true) ...[
                      const SizedBox(height: 12),
                      _thinkingSection(theme),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: Text(context.l10n.modelsSettingsResetDefaults),
                      ),
                    ),
                  ],
                ),
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
              child: Text(
                context.l10n.modelsSettingsContextWindow,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              context.l10n.modelsTokensValue(_tokens(_context)),
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
          _capExplanation(context.l10n, limit),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          context.l10n.modelsSettingsContextHelp,
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
              child: Text(
                context.l10n.modelsSettingsTemperature,
                style: theme.textTheme.titleSmall,
              ),
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
              context.l10n.modelsSettingsPrecise,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              context.l10n.modelsSettingsCreative,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _topKSection(ThemeData theme) {
    final scheme = theme.colorScheme;
    final label = _topK == 0 ? context.l10n.commonOff : '$_topK';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Top-K', style: theme.textTheme.titleSmall)),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          key: const ValueKey('modelSettings.topK'),
          value: _topK.toDouble(),
          min: 0,
          max: kMaxTopK.toDouble(),
          divisions: kMaxTopK,
          label: label,
          onChanged: (v) => setState(() => _topK = v.round()),
          onChangeEnd: (v) => _store.update(widget.model.id, topK: v.round()),
        ),
        Text(
          context.l10n.modelsSettingsTopKHelp,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _topPSection(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Top-P', style: theme.textTheme.titleSmall)),
            Text(
              _topP.toStringAsFixed(2),
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          key: const ValueKey('modelSettings.topP'),
          value: _topP,
          min: kMinTopP,
          max: 1.0,
          divisions: ((1.0 - kMinTopP) / 0.05).round(),
          label: _topP.toStringAsFixed(2),
          onChanged: (v) => setState(() => _topP = v),
          onChangeEnd: (v) => _store.update(widget.model.id, topP: v),
        ),
        Text(
          context.l10n.modelsSettingsTopPHelp,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _thinkingSection(ThemeData theme) {
    final scheme = theme.colorScheme;
    return SwitchListTile(
      key: const ValueKey('modelSettings.thinking'),
      contentPadding: EdgeInsets.zero,
      title: Text(
        context.l10n.modelsSettingsThinking,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        context.l10n.modelsSettingsThinkingHelp,
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      value: _thinking,
      onChanged: (v) {
        setState(() => _thinking = v);
        _store.update(widget.model.id, thinking: v);
      },
    );
  }

  /// Says which ceiling holds the window down, since "why can't I pick 32K"
  /// has a different answer for a small phone than for a small model.
  String _capExplanation(AppLocalizations l, ContextLimit limit) {
    final max = _tokens(limit.cap);
    final trained = limit.trained;
    if (limit.ramLimited) {
      return trained == null
          ? l.modelsSettingsCapPhoneRam(max)
          : l.modelsSettingsCapRam(max, _tokens(trained));
    }
    if (trained != null) {
      return l.modelsSettingsCapTraining(max);
    }
    return l.modelsSettingsCap(max);
  }

  static String _tokens(int n) {
    if (n >= 1024 * 1024 && n % (1024 * 1024) == 0) {
      return '${n ~/ (1024 * 1024)}M';
    }
    if (n >= 1024 && n % 1024 == 0) return '${n ~/ 1024}K';
    return '$n';
  }
}
