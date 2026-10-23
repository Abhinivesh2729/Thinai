/// The jobs a person actually wants done, which is what they can answer about
/// themselves. "Qwen 3 1.7B Q8_0" is not — it asks the reader to already know
/// what a parameter count buys them.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

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
    UseCase.reasoning => 'Reasoning',
    UseCase.coding => 'Coding',
    UseCase.tamil => 'Tamil',
    UseCase.english => 'English',
    UseCase.vision => 'Images',
    UseCase.translation => 'Translation',
    UseCase.summarizing => 'Summaries',
    UseCase.documents => 'Documents',
  };

  /// What picking this actually optimises for, in the user's terms.
  String get blurb => switch (this) {
    UseCase.fastChat => 'Quick replies',
    UseCase.reasoning => 'Maths and hard questions',
    UseCase.coding => 'Write and explain code',
    UseCase.tamil => 'Chat and write in Tamil',
    UseCase.english => 'Everyday English',
    UseCase.vision => 'Ask about a photo',
    UseCase.translation => 'Translate with no internet',
    UseCase.summarizing => 'The gist of long text',
    UseCase.documents => 'Ask about long documents',
  };

  /// [label] in the app's language.
  String localizedLabel(AppLocalizations l) => switch (this) {
    UseCase.fastChat => l.modelsUseCaseFastChat,
    UseCase.reasoning => l.modelsUseCaseReasoning,
    UseCase.coding => l.modelsUseCaseCoding,
    UseCase.tamil => l.modelsUseCaseTamil,
    UseCase.english => l.modelsUseCaseEnglish,
    UseCase.vision => l.modelsUseCaseVision,
    UseCase.translation => l.modelsUseCaseTranslation,
    UseCase.summarizing => l.modelsUseCaseSummarizing,
    UseCase.documents => l.modelsUseCaseDocuments,
  };

  /// [blurb] in the app's language.
  String localizedBlurb(AppLocalizations l) => switch (this) {
    UseCase.fastChat => l.modelsUseCaseFastChatBlurb,
    UseCase.reasoning => l.modelsUseCaseReasoningBlurb,
    UseCase.coding => l.modelsUseCaseCodingBlurb,
    UseCase.tamil => l.modelsUseCaseTamilBlurb,
    UseCase.english => l.modelsUseCaseEnglishBlurb,
    UseCase.vision => l.modelsUseCaseVisionBlurb,
    UseCase.translation => l.modelsUseCaseTranslationBlurb,
    UseCase.summarizing => l.modelsUseCaseSummarizingBlurb,
    UseCase.documents => l.modelsUseCaseDocumentsBlurb,
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
