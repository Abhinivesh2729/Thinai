/// The system prompt every chat opens with, as the user wrote it.
///
/// Chat only. API clients send their own system message, and one of ours
/// slipped in ahead of it would change answers a laptop script was tuned
/// against.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What chats are told when nobody has changed it. Short on purpose: the
/// small models this app runs follow a line or two well and drift on a page.
const String kDefaultSystemPrompt =
    'You are Thinai, a helpful AI assistant that runs privately on the '
    "user's phone. Answer clearly and concisely, and say so when you are not "
    'sure.';

const _kSystemPromptKey = 'chat_system_prompt_v1';

/// Holds the prompt. An empty prompt is allowed and means "send none", which
/// leaves the model's own template default in charge.
class SystemPromptController extends StateNotifier<String> {
  SystemPromptController() : super(kDefaultSystemPrompt) {
    _loading = _load();
  }

  late final Future<void> _loading;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Absent means never changed, so the default applies and follows any
    // later change to it rather than being frozen at first launch.
    final stored = prefs.getString(_kSystemPromptKey);
    if (stored != null) state = stored;
  }

  /// The prompt once the stored one has been read. A message sent in the
  /// first moments after launch must not go out with the default in place of
  /// the user's own.
  Future<String> current() async {
    await _loading;
    return state;
  }

  bool get isDefault => state == kDefaultSystemPrompt;

  Future<void> set(String value) async {
    await _loading;
    if (value == kDefaultSystemPrompt) return reset();
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSystemPromptKey, value);
  }

  Future<void> reset() async {
    await _loading;
    state = kDefaultSystemPrompt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSystemPromptKey);
  }
}

final systemPromptProvider =
    StateNotifierProvider<SystemPromptController, String>(
      (ref) => SystemPromptController(),
    );
