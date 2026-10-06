/// The jobs a person actually wants done, which is what they can answer about
/// themselves. "Qwen 3 1.7B Q8_0" is not — it asks the reader to already know
/// what a parameter count buys them.
library;

import 'package:flutter/material.dart';

enum UseCase {
  fastChat,
  reasoning,
  coding,
  tamil,
  english,
  vision,
  translation,
  summarizing,
  documents,
}

extension UseCaseInfo on UseCase {
  /// Short label for a chip.
  String get label => switch (this) {
        UseCase.fastChat => 'Fast chat',
        UseCase.reasoning => 'Best reasoning',
        UseCase.coding => 'Coding',
        UseCase.tamil => 'Tamil',
        UseCase.english => 'English',
        UseCase.vision => 'Image understanding',
        UseCase.translation => 'Offline translation',
        UseCase.summarizing => 'Summarization',
        UseCase.documents => 'Document analysis',
      };

  /// What picking this actually optimises for, in the user's terms.
  String get blurb => switch (this) {
        UseCase.fastChat => 'Quick back-and-forth, answers as fast as you type',
        UseCase.reasoning => 'Harder questions, maths, step-by-step thinking',
        UseCase.coding => 'Writing and explaining code',
        UseCase.tamil => 'Chatting and writing in Tamil',
        UseCase.english => 'Everyday English conversation and writing',
        UseCase.vision => 'Asking questions about a photo or screenshot',
        UseCase.translation => 'Translating between languages with no signal',
        UseCase.summarizing => 'Shortening long text into the gist',
        UseCase.documents => 'Reading long documents and answering about them',
      };

  IconData get icon => switch (this) {
        UseCase.fastChat => Icons.bolt_outlined,
        UseCase.reasoning => Icons.psychology_outlined,
        UseCase.coding => Icons.code,
        UseCase.tamil => Icons.translate_outlined,
        UseCase.english => Icons.chat_bubble_outline,
        UseCase.vision => Icons.image_outlined,
        UseCase.translation => Icons.g_translate_outlined,
        UseCase.summarizing => Icons.short_text,
        UseCase.documents => Icons.description_outlined,
      };

  /// Speed matters more than depth for these: the reply arriving while you are
  /// still looking at the screen is the whole point.
  bool get favoursSpeed =>
      this == UseCase.fastChat ||
      this == UseCase.english ||
      this == UseCase.summarizing;
}
