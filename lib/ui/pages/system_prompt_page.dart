import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/system_prompt.dart';

/// Views, edits and resets the system prompt chats are sent with.
///
/// Leaving the page keeps what was typed, the way Android settings screens
/// behave, so Save is there for reassurance rather than being the only way not
/// to lose an edit.
class SystemPromptPage extends ConsumerStatefulWidget {
  const SystemPromptPage({super.key});

  @override
  ConsumerState<SystemPromptPage> createState() => _SystemPromptPageState();
}

class _SystemPromptPageState extends ConsumerState<SystemPromptPage> {
  final _text = TextEditingController();
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final prompt = await ref.read(systemPromptProvider.notifier).current();
    if (!mounted) return;
    _text.text = prompt;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _dirty => _loaded && _text.text != ref.read(systemPromptProvider);

  Future<void> _save({bool announce = true}) async {
    if (!_dirty) return;
    await ref.read(systemPromptProvider.notifier).set(_text.text);
    if (!mounted) return;
    setState(() {});
    if (announce) _toast('System prompt saved. New messages will use it.');
  }

  Future<void> _reset() async {
    await ref.read(systemPromptProvider.notifier).reset();
    if (!mounted) return;
    setState(() => _text.text = kDefaultSystemPrompt);
    _toast('System prompt reset to the default.');
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDefault = _text.text == kDefaultSystemPrompt;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _dirty) unawaited(_save(announce: false));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('System Prompt'),
          actions: [
            TextButton(
              onPressed: _dirty ? _save : null,
              child: const Text('Save'),
            ),
          ],
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Text(
                    'Instructions sent to the model at the start of every '
                    'chat. Changes apply from the next message you send. '
                    'Leave it empty to use the model\'s own default.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('systemPrompt.field'),
                    controller: _text,
                    minLines: 6,
                    maxLines: 16,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'You are a helpful assistant…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_text.text.length} characters',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: isDefault ? null : _reset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reset to default'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
