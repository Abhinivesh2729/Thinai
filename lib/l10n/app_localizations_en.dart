// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageSetting => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonShare => 'Share';

  @override
  String get commonDownload => 'Download';

  @override
  String get commonResume => 'Resume';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonDone => 'Done';

  @override
  String get commonLater => 'Later';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonRename => 'Rename';

  @override
  String get commonOn => 'On';

  @override
  String get commonOff => 'Off';

  @override
  String get navChat => 'Chat';

  @override
  String get navModels => 'Models';

  @override
  String get navServer => 'Server';

  @override
  String get navSettings => 'Settings';

  @override
  String get modelsToastDownloadPaused =>
      'Download paused. Tap Resume to continue.';

  @override
  String modelsToastDownloadStopped(String model, String error) {
    return 'Download of $model stopped: $error. Progress is saved, tap Resume to continue.';
  }

  @override
  String modelsToastDownloadFailed(String model, String error) {
    return 'Could not download $model: $error';
  }

  @override
  String modelsToastDownloadedAndLoaded(String model) {
    return 'Downloaded and loaded $model';
  }

  @override
  String modelsToastDownloaded(String model) {
    return 'Downloaded $model';
  }

  @override
  String modelsToastLoaded(String model) {
    return 'Loaded $model';
  }

  @override
  String modelsToastResumeFailed(String model) {
    return 'Could not resume $model';
  }

  @override
  String get modelsConfirmDownloadTitle => 'Download model?';

  @override
  String modelsConfirmDownloadMessage(String model, String size) {
    return 'Do you want to download $model ($size)?';
  }

  @override
  String get modelsConfirmDiscardTitle => 'Discard download?';

  @override
  String modelsConfirmDiscardMessage(String model, String size) {
    return 'Do you want to discard the paused download of $model? The $size saved so far will be deleted.';
  }

  @override
  String get modelsDiscard => 'Discard';

  @override
  String get modelsConfirmDeleteTitle => 'Delete model?';

  @override
  String modelsConfirmDeleteMessage(String model, String size) {
    return 'Do you want to delete $model? This frees $size of space.';
  }

  @override
  String get modelsBenchmark => 'Benchmark';

  @override
  String get modelsManagerTitle => 'Model Manager';

  @override
  String modelsManagerTooltipDownloading(int count) {
    return 'Downloading ($count) · Model Manager';
  }

  @override
  String modelsManagerTooltipInstalled(int count) {
    return 'Model Manager ($count installed)';
  }

  @override
  String modelsError(String error) {
    return 'Error: $error';
  }

  @override
  String get modelsNoneInstalledYet => 'No models installed yet';

  @override
  String get modelsNoneInstalledYetBody =>
      'Browse and download GGUF models from the catalog to run offline on this device.';

  @override
  String get modelsBrowseCatalog => 'Browse Catalog';

  @override
  String modelsInstalledSectionTitle(int count) {
    return 'Installed models ($count)';
  }

  @override
  String get modelsInstalledSectionSubtitle =>
      'Tap a model to load it for chat';

  @override
  String modelsRecommendedFor(String goal) {
    return 'Recommended for $goal';
  }

  @override
  String get modelsRecommendedSubtitle =>
      'Optimal weights selected for your device specs';

  @override
  String get modelsFeaturedTitle => 'Featured Models';

  @override
  String get modelsFeaturedSubtitle => 'Handpicked for you';

  @override
  String get modelsOtherModels => 'Other models';

  @override
  String get modelsVisionModelsTitle => 'Vision models';

  @override
  String get modelsChatModelsTitle => 'Chat models';

  @override
  String get modelsExploreModels => 'Explore Models';

  @override
  String get modelsBrowseCatalogTitle => 'Browse catalog';

  @override
  String get modelsOtherModelsSubtitle => 'All other available models';

  @override
  String get modelsVisionModelsSubtitle =>
      'Multimodal · image & visual analysis';

  @override
  String get modelsCatalogSubtitle => 'Curated GGUF models · one-tap download';

  @override
  String get modelsEmbeddingTitle => 'Embedding models';

  @override
  String get modelsEmbeddingSubtitle =>
      'For search and RAG · /api/embed · /v1/embeddings';

  @override
  String get modelsOfflineFooter =>
      'Downloaded models stay 100% on-device and run entirely offline.';

  @override
  String get modelsSearchHint => 'Search models, makers, architectures…';

  @override
  String get modelsClearSearch => 'Clear search';

  @override
  String get modelsFilterAll => 'All Models';

  @override
  String get modelsFilterChat => 'Chat Models';

  @override
  String get modelsFilterVision => 'Vision Models';

  @override
  String get modelsFilterEmbedding => 'Embedding';

  @override
  String get modelsFilterInstalled => 'Installed';

  @override
  String modelsFilterInstalledCount(int count) {
    return 'Installed ($count)';
  }

  @override
  String get modelsFilterCategory => 'Filter Category';

  @override
  String get modelsGoals => 'Goals';

  @override
  String get modelsResetFiltersTooltip => 'Reset filters and search';

  @override
  String modelsTargeting(String goal) {
    return 'Targeting: $goal';
  }

  @override
  String get modelsChange => 'Change';

  @override
  String get modelsClearGoal => 'Clear goal';

  @override
  String modelsManagerSubtitleDownloading(
    int installed,
    int downloading,
    String size,
  ) {
    return '$installed installed · $downloading downloading · $size used';
  }

  @override
  String modelsManagerSubtitle(int count, String size) {
    return '$count models · $size storage used';
  }

  @override
  String get modelsNoneInstalled => 'No models installed';

  @override
  String get modelsNoneInstalledBody =>
      'Download models from the catalog to run offline chat.';

  @override
  String modelsActiveForChat(String model) {
    return 'Active for Chat: $model';
  }

  @override
  String get modelsNoModelLoaded => 'No model loaded in Chat';

  @override
  String get modelsInstalledAppearHere =>
      'Installed models will appear here after download completes.';

  @override
  String get modelsActive => 'Active';

  @override
  String get modelsActivate => 'Activate';

  @override
  String get modelsDeleteModel => 'Delete model';

  @override
  String get modelsChooseGoal => 'Choose Your Goal';

  @override
  String get modelsChooseGoalSubtitle =>
      'Thinai benchmarks & recommends models for your device';

  @override
  String get modelsClearActiveGoal => 'Clear Active Goal';

  @override
  String get modelsNoMatchFilters => 'No models match current filters';

  @override
  String modelsNoMatchQuery(String query) {
    return 'No models match \"$query\"';
  }

  @override
  String get modelsNoMatchHint =>
      'Try adjusting your selected filters or search terms.';

  @override
  String get modelsSearchHuggingFace => 'Search Hugging Face';

  @override
  String get modelsResetFiltersAndSearch => 'Reset filters & search';

  @override
  String get modelsStatusCancelled => 'Cancelled';

  @override
  String get modelsStatusFailed => 'Failed';

  @override
  String get modelsStatusCompleted => '100% · Completed';

  @override
  String get modelsStatusStarting => 'Starting…';

  @override
  String get modelsActiveInChat => 'Active in Chat';

  @override
  String get modelsTapToActivate => 'Tap to activate';

  @override
  String get modelsBadgeVision => 'VISION';

  @override
  String get modelsBadgeEmbed => 'EMBED';

  @override
  String get modelsBadgeReason => 'REASON';

  @override
  String get modelsBadgeText => 'TEXT';

  @override
  String get modelsFeaturedBadge => 'FEATURED';

  @override
  String get modelsPopular => 'Popular';

  @override
  String modelsAddVision(String size) {
    return '+ Vision ($size)';
  }

  @override
  String get modelsInstalled => 'Installed';

  @override
  String get modelsPause => 'Pause';

  @override
  String get modelsTopPick => 'TOP PICK';

  @override
  String get modelsModelDetails => 'Model details';

  @override
  String modelsDimensions(String count) {
    return '$count dims';
  }

  @override
  String get modelsNeedsRam => 'Needs RAM';

  @override
  String get modelsDetailParameters => 'Parameters';

  @override
  String get modelsDetailContextWindow => 'Context Window';

  @override
  String modelsTokensValue(String count) {
    return '$count tokens';
  }

  @override
  String get modelsDetailDownloadSize => 'Download Size';

  @override
  String get modelsDetailCapability => 'Capability';

  @override
  String modelsDownloadSize(String size) {
    return 'Download $size';
  }

  @override
  String get modelsCapVisionReady => 'Vision Ready';

  @override
  String get modelsCapEmbeddings => 'Embeddings';

  @override
  String get modelsCapLightweight => 'Lightweight';

  @override
  String get modelsCapFast => 'Fast & Efficient';

  @override
  String get modelsCapMultilingual => 'Multilingual';

  @override
  String get modelsCapCodeReasoning => 'Code · Reasoning';

  @override
  String get modelsCapInstruct => 'Instruct';

  @override
  String get modelsFitTooLarge => 'Too large for this phone.';

  @override
  String modelsFitNeeds(String needs, String available) {
    return 'Needs $needs, this phone has $available to spare.';
  }

  @override
  String get modelsFitTight =>
      'A tight fit. Other apps may close while this runs.';

  @override
  String modelsDownloadingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Downloading $count models',
      one: 'Downloading model',
    );
    return '$_temp0';
  }

  @override
  String get modelsPauseDownload => 'Pause download';

  @override
  String modelsResumePercent(String percent) {
    return 'Resume $percent%';
  }

  @override
  String get modelsPaused => 'Paused';

  @override
  String modelsPausedPercent(String percent) {
    return 'Paused · $percent%';
  }

  @override
  String modelsPausedDownloadsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Paused downloads ($count)',
      one: 'Paused download',
    );
    return '$_temp0';
  }

  @override
  String get modelsPausedDownloadsBody =>
      'Saved on this phone. Resume to continue where it stopped.';

  @override
  String get modelsResumeDownload => 'Resume download';

  @override
  String get modelsDiscardDownload => 'Discard download';

  @override
  String get modelsUseCaseFastChat => 'Fast chat';

  @override
  String get modelsUseCaseFastChatBlurb =>
      'Quick back-and-forth, answers as fast as you type';

  @override
  String get modelsUseCaseReasoning => 'Best reasoning';

  @override
  String get modelsUseCaseReasoningBlurb =>
      'Harder questions, maths, step-by-step thinking';

  @override
  String get modelsUseCaseCoding => 'Coding';

  @override
  String get modelsUseCaseCodingBlurb => 'Writing and explaining code';

  @override
  String get modelsUseCaseTamil => 'Tamil';

  @override
  String get modelsUseCaseTamilBlurb => 'Chatting and writing in Tamil';

  @override
  String get modelsUseCaseEnglish => 'English';

  @override
  String get modelsUseCaseEnglishBlurb =>
      'Everyday English conversation and writing';

  @override
  String get modelsUseCaseVision => 'Image understanding';

  @override
  String get modelsUseCaseVisionBlurb =>
      'Asking questions about a photo or screenshot';

  @override
  String get modelsUseCaseTranslation => 'Offline translation';

  @override
  String get modelsUseCaseTranslationBlurb =>
      'Translating between languages with no signal';

  @override
  String get modelsUseCaseSummarizing => 'Summarization';

  @override
  String get modelsUseCaseSummarizingBlurb =>
      'Shortening long text into the gist';

  @override
  String get modelsUseCaseDocuments => 'Document analysis';

  @override
  String get modelsUseCaseDocumentsBlurb =>
      'Reading long documents and answering about them';

  @override
  String modelsReasonNotSuited(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'Not suited to quick conversations',
      'reasoning': 'Not suited to step-by-step reasoning',
      'coding': 'Not suited to code',
      'tamil': 'Not suited to Tamil',
      'english': 'Not suited to English',
      'vision': 'Not suited to images',
      'translation': 'Not suited to translation',
      'summarizing': 'Not suited to summarising',
      'documents': 'Not suited to long documents',
      'other': 'Not suited to quick conversations',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonLimited(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'Limited for quick conversations',
      'reasoning': 'Limited for step-by-step reasoning',
      'coding': 'Limited for code',
      'tamil': 'Limited for Tamil',
      'english': 'Limited for English',
      'vision': 'Limited for images',
      'translation': 'Limited for translation',
      'summarizing': 'Limited for summarising',
      'documents': 'Limited for long documents',
      'other': 'Limited for quick conversations',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonUsable(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'Usable for quick conversations',
      'reasoning': 'Usable for step-by-step reasoning',
      'coding': 'Usable for code',
      'tamil': 'Usable for Tamil',
      'english': 'Usable for English',
      'vision': 'Usable for images',
      'translation': 'Usable for translation',
      'summarizing': 'Usable for summarising',
      'documents': 'Usable for long documents',
      'other': 'Usable for quick conversations',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonGood(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'Good for quick conversations',
      'reasoning': 'Good for step-by-step reasoning',
      'coding': 'Good for code',
      'tamil': 'Good for Tamil',
      'english': 'Good for English',
      'vision': 'Good for images',
      'translation': 'Good for translation',
      'summarizing': 'Good for summarising',
      'documents': 'Good for long documents',
      'other': 'Good for quick conversations',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonExcellent(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'Excellent for quick conversations',
      'reasoning': 'Excellent for step-by-step reasoning',
      'coding': 'Excellent for code',
      'tamil': 'Excellent for Tamil',
      'english': 'Excellent for English',
      'vision': 'Excellent for images',
      'translation': 'Excellent for translation',
      'summarizing': 'Excellent for summarising',
      'documents': 'Excellent for long documents',
      'other': 'Excellent for quick conversations',
    });
    return '$_temp0';
  }

  @override
  String modelsCaveatNoneFits(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat':
          'No model in the catalogue fits this phone for quick conversations.',
      'reasoning':
          'No model in the catalogue fits this phone for step-by-step reasoning.',
      'coding': 'No model in the catalogue fits this phone for code.',
      'tamil': 'No model in the catalogue fits this phone for Tamil.',
      'english': 'No model in the catalogue fits this phone for English.',
      'vision': 'No model in the catalogue fits this phone for images.',
      'translation':
          'No model in the catalogue fits this phone for translation.',
      'summarizing':
          'No model in the catalogue fits this phone for summarising.',
      'documents':
          'No model in the catalogue fits this phone for long documents.',
      'other':
          'No model in the catalogue fits this phone for quick conversations.',
    });
    return '$_temp0';
  }

  @override
  String modelsCaveatNothingFitsWell(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat':
          'Nothing fits well for quick conversations. These are closest.',
      'reasoning':
          'Nothing fits well for step-by-step reasoning. These are closest.',
      'coding': 'Nothing fits well for code. These are closest.',
      'tamil': 'Nothing fits well for Tamil. These are closest.',
      'english': 'Nothing fits well for English. These are closest.',
      'vision': 'Nothing fits well for images. These are closest.',
      'translation': 'Nothing fits well for translation. These are closest.',
      'summarizing': 'Nothing fits well for summarising. These are closest.',
      'documents': 'Nothing fits well for long documents. These are closest.',
      'other': 'Nothing fits well for quick conversations. These are closest.',
    });
    return '$_temp0';
  }

  @override
  String modelsCaveatNothingStrong(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat':
          'Nothing at this size is strong at quick conversations. Closest matches shown.',
      'reasoning':
          'Nothing at this size is strong at step-by-step reasoning. Closest matches shown.',
      'coding':
          'Nothing at this size is strong at code. Closest matches shown.',
      'tamil':
          'Nothing at this size is strong at Tamil. Closest matches shown.',
      'english':
          'Nothing at this size is strong at English. Closest matches shown.',
      'vision':
          'Nothing at this size is strong at images. Closest matches shown.',
      'translation':
          'Nothing at this size is strong at translation. Closest matches shown.',
      'summarizing':
          'Nothing at this size is strong at summarising. Closest matches shown.',
      'documents':
          'Nothing at this size is strong at long documents. Closest matches shown.',
      'other':
          'Nothing at this size is strong at quick conversations. Closest matches shown.',
    });
    return '$_temp0';
  }

  @override
  String get modelsVisionUnavailable =>
      'Image understanding is not available in this build.';

  @override
  String get modelsFitComfortable => 'Runs well on your phone';

  @override
  String get modelsFitTightShort => 'Tight fit, may slow other apps';

  @override
  String get modelsFitTooBig => 'Too big for your phone';

  @override
  String get modelsFitUnknown => 'Fit unknown';

  @override
  String get modelsSpeedUnknown => 'speed unknown';

  @override
  String modelsAdvisorGoalCollapsed(String goal) {
    return 'Goal: $goal · tap to customize';
  }

  @override
  String get modelsAdvisorPromptCollapsed =>
      'What do you want to do? · tap to pick a goal';

  @override
  String get modelsAdvisorPrompt => 'What do you want to do?';

  @override
  String get modelsClear => 'Clear';

  @override
  String get modelsAdvisorCollapse => 'Collapse guide';

  @override
  String modelsAdvisorSubtitleKnown(String device) {
    return 'Thinai picks a model that fits your phone · $device';
  }

  @override
  String get modelsAdvisorSubtitle => 'Thinai picks a model for the job';

  @override
  String get modelsAdvisorNothingFits =>
      'Nothing in the catalogue fits this one.';

  @override
  String get modelsAdvisorBestForPhone => 'Best model for your phone';

  @override
  String get modelsAdvisorBestForThis => 'Best model for this';

  @override
  String get modelsAdvisorAlsoConsider => 'Also worth considering';

  @override
  String modelsAdvisorAuthorDownload(String author, String size) {
    return '$author · $size download';
  }

  @override
  String modelsAdvisorContext(String context) {
    return '$context context';
  }

  @override
  String get modelsAdvisorAlreadyDownloaded => 'Already downloaded';

  @override
  String get modelsAdvisorSpeedMeasured =>
      'Speed measured on this phone by Benchmark.';

  @override
  String get modelsAdvisorSpeedEstimated =>
      'Estimated speed. Run Benchmark for the real number.';

  @override
  String get modelsAdvisorStartingCancel => 'Starting… · tap to cancel';

  @override
  String modelsAdvisorDownloadingCancel(String percent) {
    return 'Downloading $percent% · tap to cancel';
  }

  @override
  String get modelsSettingsTitle => 'Model settings';

  @override
  String get modelsSettingsBody =>
      'Used by chat and the API server. Requests can override these, up to the maximum.';

  @override
  String get modelsSettingsResetDefaults => 'Reset to defaults';

  @override
  String get modelsSettingsContextWindow => 'Context window';

  @override
  String get modelsSettingsContextHelp =>
      'Longer windows remember more but use more RAM and run slower.';

  @override
  String get modelsSettingsTemperature => 'Temperature';

  @override
  String get modelsSettingsPrecise => 'Precise';

  @override
  String get modelsSettingsCreative => 'Creative';

  @override
  String get modelsSettingsTopKHelp =>
      'Picks each word from only the K likeliest. Lower is more focused; 0 turns the limit off.';

  @override
  String get modelsSettingsTopPHelp =>
      'Picks from the likeliest words that together make up this share of the probability. 1.00 keeps them all.';

  @override
  String get modelsSettingsThinking => 'Thinking';

  @override
  String get modelsSettingsThinkingHelp =>
      'Reasons step by step before answering. Off answers sooner.';

  @override
  String modelsSettingsCapPhoneRam(String max) {
    return 'Maximum $max, limited by this phone\'s RAM.';
  }

  @override
  String modelsSettingsCapRam(String max, String trained) {
    return 'Maximum $max, limited by RAM (model supports $trained).';
  }

  @override
  String modelsSettingsCapTraining(String max) {
    return 'Maximum $max, this model\'s training limit.';
  }

  @override
  String modelsSettingsCap(String max) {
    return 'Maximum $max.';
  }
}
