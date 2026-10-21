// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get languageSetting => 'மொழி';

  @override
  String get languageSystem => 'சாதன மொழி';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get commonCancel => 'ரத்துசெய்';

  @override
  String get commonSave => 'சேமி';

  @override
  String get commonDelete => 'நீக்கு';

  @override
  String get commonRetry => 'மீண்டும் முயல்';

  @override
  String get commonClose => 'மூடு';

  @override
  String get commonOk => 'சரி';

  @override
  String get commonCopy => 'நகலெடு';

  @override
  String get commonCopied => 'நகலெடுக்கப்பட்டது';

  @override
  String get commonShare => 'பகிர்';

  @override
  String get commonDownload => 'பதிவிறக்கு';

  @override
  String get commonResume => 'தொடர்';

  @override
  String get commonDismiss => 'மூடு';

  @override
  String get commonNext => 'அடுத்து';

  @override
  String get commonBack => 'பின்செல்';

  @override
  String get commonSkip => 'தவிர்';

  @override
  String get commonDone => 'முடிந்தது';

  @override
  String get commonLater => 'பிறகு';

  @override
  String get commonReset => 'மீட்டமை';

  @override
  String get commonRename => 'பெயர்மாற்று';

  @override
  String get commonOn => 'ஆன்';

  @override
  String get commonOff => 'ஆஃப்';

  @override
  String get navChat => 'அரட்டை';

  @override
  String get navModels => 'மாடல்கள்';

  @override
  String get navServer => 'சர்வர்';

  @override
  String get navSettings => 'அமைப்புகள்';

  @override
  String get modelsToastDownloadPaused =>
      'பதிவிறக்கம் இடைநிறுத்தப்பட்டது. தொடர, தொடர் என்பதைத் தட்டவும்.';

  @override
  String modelsToastDownloadStopped(String model, String error) {
    return '$model பதிவிறக்கம் நின்றது: $error. முன்னேற்றம் சேமிக்கப்பட்டது, தொடர, தொடர் என்பதைத் தட்டவும்.';
  }

  @override
  String modelsToastDownloadFailed(String model, String error) {
    return '$model மாடலைப் பதிவிறக்க முடியவில்லை: $error';
  }

  @override
  String modelsToastDownloadedAndLoaded(String model) {
    return '$model பதிவிறக்கப்பட்டு ஏற்றப்பட்டது';
  }

  @override
  String modelsToastDownloaded(String model) {
    return '$model பதிவிறக்கப்பட்டது';
  }

  @override
  String modelsToastLoaded(String model) {
    return '$model ஏற்றப்பட்டது';
  }

  @override
  String modelsToastResumeFailed(String model) {
    return '$model பதிவிறக்கத்தைத் தொடர முடியவில்லை';
  }

  @override
  String get modelsConfirmDownloadTitle => 'மாடலைப் பதிவிறக்கவா?';

  @override
  String modelsConfirmDownloadMessage(String model, String size) {
    return '$model ($size) மாடலைப் பதிவிறக்க விரும்புகிறீர்களா?';
  }

  @override
  String get modelsConfirmDiscardTitle => 'பதிவிறக்கத்தை நீக்கவா?';

  @override
  String modelsConfirmDiscardMessage(String model, String size) {
    return 'இடைநிறுத்தப்பட்ட $model பதிவிறக்கத்தை நீக்க விரும்புகிறீர்களா? இதுவரை சேமிக்கப்பட்ட $size நீக்கப்படும்.';
  }

  @override
  String get modelsDiscard => 'நீக்கு';

  @override
  String get modelsConfirmDeleteTitle => 'மாடலை நீக்கவா?';

  @override
  String modelsConfirmDeleteMessage(String model, String size) {
    return '$model மாடலை நீக்க விரும்புகிறீர்களா? இதனால் $size இடம் காலியாகும்.';
  }

  @override
  String get modelsBenchmark => 'பெஞ்ச்மார்க்';

  @override
  String get modelsManagerTitle => 'மாடல் மேலாளர்';

  @override
  String modelsManagerTooltipDownloading(int count) {
    return 'பதிவிறக்குகிறது ($count) · மாடல் மேலாளர்';
  }

  @override
  String modelsManagerTooltipInstalled(int count) {
    return 'மாடல் மேலாளர் ($count நிறுவப்பட்டது)';
  }

  @override
  String modelsError(String error) {
    return 'பிழை: $error';
  }

  @override
  String get modelsNoneInstalledYet => 'இன்னும் எந்த மாடலும் நிறுவப்படவில்லை';

  @override
  String get modelsNoneInstalledYetBody =>
      'இந்தச் சாதனத்தில் ஆஃப்லைனில் இயக்க, பட்டியலிலிருந்து GGUF மாடல்களைப் பார்த்துப் பதிவிறக்கவும்.';

  @override
  String get modelsBrowseCatalog => 'பட்டியலைப் பார்';

  @override
  String modelsInstalledSectionTitle(int count) {
    return 'நிறுவப்பட்ட மாடல்கள் ($count)';
  }

  @override
  String get modelsInstalledSectionSubtitle =>
      'அரட்டைக்கு ஏற்ற ஒரு மாடலைத் தட்டவும்';

  @override
  String modelsRecommendedFor(String goal) {
    return '$goal — பரிந்துரைக்கப்பட்டவை';
  }

  @override
  String get modelsRecommendedSubtitle =>
      'உங்கள் சாதனத்துக்கு ஏற்ற weights தேர்ந்தெடுக்கப்பட்டன';

  @override
  String get modelsFeaturedTitle => 'சிறப்பு மாடல்கள்';

  @override
  String get modelsFeaturedSubtitle => 'உங்களுக்காகத் தேர்ந்தெடுக்கப்பட்டவை';

  @override
  String get modelsOtherModels => 'பிற மாடல்கள்';

  @override
  String get modelsVisionModelsTitle => 'பட மாடல்கள்';

  @override
  String get modelsChatModelsTitle => 'அரட்டை மாடல்கள்';

  @override
  String get modelsExploreModels => 'மாடல்களை ஆராய்';

  @override
  String get modelsBrowseCatalogTitle => 'பட்டியலைப் பார்';

  @override
  String get modelsOtherModelsSubtitle => 'கிடைக்கும் மற்ற எல்லா மாடல்களும்';

  @override
  String get modelsVisionModelsSubtitle =>
      'மல்டிமோடல் · படம் & காட்சிப் பகுப்பாய்வு';

  @override
  String get modelsCatalogSubtitle =>
      'தேர்ந்தெடுத்த GGUF மாடல்கள் · ஒரே தட்டலில் பதிவிறக்கம்';

  @override
  String get modelsEmbeddingTitle => 'Embedding மாடல்கள்';

  @override
  String get modelsEmbeddingSubtitle =>
      'தேடல் மற்றும் RAG-க்கு · /api/embed · /v1/embeddings';

  @override
  String get modelsOfflineFooter =>
      'பதிவிறக்கப்பட்ட மாடல்கள் 100% சாதனத்திலேயே இருக்கும், முழுவதும் ஆஃப்லைனில் இயங்கும்.';

  @override
  String get modelsSearchHint =>
      'மாடல்கள், தயாரிப்பாளர்கள், கட்டமைப்புகளைத் தேடு…';

  @override
  String get modelsClearSearch => 'தேடலை அழி';

  @override
  String get modelsFilterAll => 'எல்லா மாடல்களும்';

  @override
  String get modelsFilterChat => 'அரட்டை மாடல்கள்';

  @override
  String get modelsFilterVision => 'பட மாடல்கள்';

  @override
  String get modelsFilterEmbedding => 'Embedding';

  @override
  String get modelsFilterInstalled => 'நிறுவப்பட்டவை';

  @override
  String modelsFilterInstalledCount(int count) {
    return 'நிறுவப்பட்டவை ($count)';
  }

  @override
  String get modelsFilterCategory => 'வகையை வடிகட்டு';

  @override
  String get modelsGoals => 'இலக்குகள்';

  @override
  String get modelsResetFiltersTooltip => 'வடிகட்டிகளையும் தேடலையும் மீட்டமை';

  @override
  String modelsTargeting(String goal) {
    return 'இலக்கு: $goal';
  }

  @override
  String get modelsChange => 'மாற்று';

  @override
  String get modelsClearGoal => 'இலக்கை அழி';

  @override
  String modelsManagerSubtitleDownloading(
    int installed,
    int downloading,
    String size,
  ) {
    return '$installed நிறுவப்பட்டது · $downloading பதிவிறக்குகிறது · $size பயன்பாட்டில்';
  }

  @override
  String modelsManagerSubtitle(int count, String size) {
    return '$count மாடல்கள் · $size சேமிப்பகம் பயன்பாட்டில்';
  }

  @override
  String get modelsNoneInstalled => 'எந்த மாடலும் நிறுவப்படவில்லை';

  @override
  String get modelsNoneInstalledBody =>
      'ஆஃப்லைனில் அரட்டையடிக்க, பட்டியலிலிருந்து மாடல்களைப் பதிவிறக்கவும்.';

  @override
  String modelsActiveForChat(String model) {
    return 'அரட்டையில் செயலில்: $model';
  }

  @override
  String get modelsNoModelLoaded => 'அரட்டையில் எந்த மாடலும் ஏற்றப்படவில்லை';

  @override
  String get modelsInstalledAppearHere =>
      'பதிவிறக்கம் முடிந்ததும் நிறுவப்பட்ட மாடல்கள் இங்கே தோன்றும்.';

  @override
  String get modelsActive => 'செயலில்';

  @override
  String get modelsActivate => 'செயல்படுத்து';

  @override
  String get modelsDeleteModel => 'மாடலை நீக்கு';

  @override
  String get modelsChooseGoal => 'உங்கள் இலக்கைத் தேர்ந்தெடுக்கவும்';

  @override
  String get modelsChooseGoalSubtitle =>
      'Thinai உங்கள் சாதனத்துக்கு மாடல்களைச் சோதித்துப் பரிந்துரைக்கிறது';

  @override
  String get modelsClearActiveGoal => 'தற்போதைய இலக்கை அழி';

  @override
  String get modelsNoMatchFilters =>
      'தற்போதைய வடிகட்டிகளுக்குப் பொருந்தும் மாடல்கள் இல்லை';

  @override
  String modelsNoMatchQuery(String query) {
    return '\"$query\" உடன் பொருந்தும் மாடல்கள் இல்லை';
  }

  @override
  String get modelsNoMatchHint =>
      'தேர்ந்தெடுத்த வடிகட்டிகளையோ தேடல் சொற்களையோ மாற்றிப் பார்க்கவும்.';

  @override
  String get modelsSearchHuggingFace => 'Hugging Face-இல் தேடு';

  @override
  String get modelsResetFiltersAndSearch => 'வடிகட்டிகள் & தேடலை மீட்டமை';

  @override
  String get modelsStatusCancelled => 'ரத்துசெய்யப்பட்டது';

  @override
  String get modelsStatusFailed => 'தோல்வியடைந்தது';

  @override
  String get modelsStatusCompleted => '100% · முடிந்தது';

  @override
  String get modelsStatusStarting => 'தொடங்குகிறது…';

  @override
  String get modelsActiveInChat => 'அரட்டையில் செயலில்';

  @override
  String get modelsTapToActivate => 'செயல்படுத்தத் தட்டவும்';

  @override
  String get modelsBadgeVision => 'படம்';

  @override
  String get modelsBadgeEmbed => 'EMBED';

  @override
  String get modelsBadgeReason => 'பகுத்தறிவு';

  @override
  String get modelsBadgeText => 'உரை';

  @override
  String get modelsFeaturedBadge => 'சிறப்பு';

  @override
  String get modelsPopular => 'பிரபலம்';

  @override
  String modelsAddVision(String size) {
    return '+ படம் ($size)';
  }

  @override
  String get modelsInstalled => 'நிறுவப்பட்டது';

  @override
  String get modelsPause => 'இடைநிறுத்து';

  @override
  String get modelsTopPick => 'சிறந்த தேர்வு';

  @override
  String get modelsModelDetails => 'மாடல் விவரங்கள்';

  @override
  String modelsDimensions(String count) {
    return '$count பரிமாணங்கள்';
  }

  @override
  String get modelsNeedsRam => 'RAM தேவை';

  @override
  String get modelsDetailParameters => 'அளவுருக்கள்';

  @override
  String get modelsDetailContextWindow => 'Context window';

  @override
  String modelsTokensValue(String count) {
    return '$count tokens';
  }

  @override
  String get modelsDetailDownloadSize => 'பதிவிறக்க அளவு';

  @override
  String get modelsDetailCapability => 'திறன்';

  @override
  String modelsDownloadSize(String size) {
    return 'பதிவிறக்கு $size';
  }

  @override
  String get modelsCapVisionReady => 'படம் தயார்';

  @override
  String get modelsCapEmbeddings => 'Embeddings';

  @override
  String get modelsCapLightweight => 'இலகுவானது';

  @override
  String get modelsCapFast => 'வேகமானது & திறமையானது';

  @override
  String get modelsCapMultilingual => 'பல மொழி';

  @override
  String get modelsCapCodeReasoning => 'நிரல் · பகுத்தறிவு';

  @override
  String get modelsCapInstruct => 'Instruct';

  @override
  String get modelsFitTooLarge => 'இந்தக் கைப்பேசிக்கு மிகப் பெரியது.';

  @override
  String modelsFitNeeds(String needs, String available) {
    return '$needs தேவை, இந்தக் கைப்பேசியில் $available மட்டுமே காலியாக உள்ளது.';
  }

  @override
  String get modelsFitTight =>
      'நெருக்கமான பொருத்தம். இது இயங்கும்போது மற்ற ஆப்கள் மூடப்படலாம்.';

  @override
  String modelsDownloadingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மாடல்கள் பதிவிறக்குகின்றன',
      one: 'மாடல் பதிவிறக்குகிறது',
    );
    return '$_temp0';
  }

  @override
  String get modelsPauseDownload => 'பதிவிறக்கத்தை இடைநிறுத்து';

  @override
  String modelsResumePercent(String percent) {
    return 'தொடர் $percent%';
  }

  @override
  String get modelsPaused => 'இடைநிறுத்தப்பட்டது';

  @override
  String modelsPausedPercent(String percent) {
    return 'இடைநிறுத்தப்பட்டது · $percent%';
  }

  @override
  String modelsPausedDownloadsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'இடைநிறுத்தப்பட்ட பதிவிறக்கங்கள் ($count)',
      one: 'இடைநிறுத்தப்பட்ட பதிவிறக்கம்',
    );
    return '$_temp0';
  }

  @override
  String get modelsPausedDownloadsBody =>
      'இந்தக் கைப்பேசியில் சேமிக்கப்பட்டது. நின்ற இடத்திலிருந்து தொடர, தொடர் என்பதைத் தட்டவும்.';

  @override
  String get modelsResumeDownload => 'பதிவிறக்கத்தைத் தொடர்';

  @override
  String get modelsDiscardDownload => 'பதிவிறக்கத்தை நீக்கு';

  @override
  String get modelsUseCaseFastChat => 'வேகமான அரட்டை';

  @override
  String get modelsUseCaseFastChatBlurb =>
      'விரைவான உரையாடல், நீங்கள் தட்டச்சு செய்யும் வேகத்தில் பதில்கள்';

  @override
  String get modelsUseCaseReasoning => 'சிறந்த பகுத்தறிவு';

  @override
  String get modelsUseCaseReasoningBlurb =>
      'கடினமான கேள்விகள், கணிதம், படிப்படியான சிந்தனை';

  @override
  String get modelsUseCaseCoding => 'நிரலாக்கம்';

  @override
  String get modelsUseCaseCodingBlurb => 'code எழுதுதல், விளக்குதல்';

  @override
  String get modelsUseCaseTamil => 'தமிழ்';

  @override
  String get modelsUseCaseTamilBlurb => 'தமிழில் அரட்டையடித்தல், எழுதுதல்';

  @override
  String get modelsUseCaseEnglish => 'ஆங்கிலம்';

  @override
  String get modelsUseCaseEnglishBlurb => 'அன்றாட ஆங்கில உரையாடல், எழுத்து';

  @override
  String get modelsUseCaseVision => 'படப் புரிதல்';

  @override
  String get modelsUseCaseVisionBlurb =>
      'புகைப்படம் அல்லது ஸ்கிரீன்ஷாட் பற்றிக் கேள்வி கேட்டல்';

  @override
  String get modelsUseCaseTranslation => 'ஆஃப்லைன் மொழிபெயர்ப்பு';

  @override
  String get modelsUseCaseTranslationBlurb =>
      'சிக்னல் இல்லாமலும் மொழிகளுக்கிடையே மொழிபெயர்த்தல்';

  @override
  String get modelsUseCaseSummarizing => 'சுருக்கம்';

  @override
  String get modelsUseCaseSummarizingBlurb => 'நீண்ட உரையைச் சுருக்கமாக்குதல்';

  @override
  String get modelsUseCaseDocuments => 'ஆவணப் பகுப்பாய்வு';

  @override
  String get modelsUseCaseDocumentsBlurb =>
      'நீண்ட ஆவணங்களைப் படித்து அவை பற்றிப் பதிலளித்தல்';

  @override
  String modelsReasonNotSuited(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'விரைவான உரையாடல்களுக்குப் பொருந்தாது',
      'reasoning': 'படிப்படியான பகுத்தறிவுக்குப் பொருந்தாது',
      'coding': 'நிரல் எழுதுவதற்குப் பொருந்தாது',
      'tamil': 'தமிழுக்குப் பொருந்தாது',
      'english': 'ஆங்கிலத்துக்குப் பொருந்தாது',
      'vision': 'படங்களுக்குப் பொருந்தாது',
      'translation': 'மொழிபெயர்ப்புக்குப் பொருந்தாது',
      'summarizing': 'சுருக்கி எழுதுவதற்குப் பொருந்தாது',
      'documents': 'நீண்ட ஆவணங்களுக்குப் பொருந்தாது',
      'other': 'விரைவான உரையாடல்களுக்குப் பொருந்தாது',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonLimited(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'விரைவான உரையாடல்களுக்குக் குறைந்த அளவே ஏற்றது',
      'reasoning': 'படிப்படியான பகுத்தறிவுக்குக் குறைந்த அளவே ஏற்றது',
      'coding': 'நிரல் எழுதுவதற்குக் குறைந்த அளவே ஏற்றது',
      'tamil': 'தமிழுக்குக் குறைந்த அளவே ஏற்றது',
      'english': 'ஆங்கிலத்துக்குக் குறைந்த அளவே ஏற்றது',
      'vision': 'படங்களுக்குக் குறைந்த அளவே ஏற்றது',
      'translation': 'மொழிபெயர்ப்புக்குக் குறைந்த அளவே ஏற்றது',
      'summarizing': 'சுருக்கி எழுதுவதற்குக் குறைந்த அளவே ஏற்றது',
      'documents': 'நீண்ட ஆவணங்களுக்குக் குறைந்த அளவே ஏற்றது',
      'other': 'விரைவான உரையாடல்களுக்குக் குறைந்த அளவே ஏற்றது',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonUsable(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'விரைவான உரையாடல்களுக்குப் பயன்படுத்தலாம்',
      'reasoning': 'படிப்படியான பகுத்தறிவுக்குப் பயன்படுத்தலாம்',
      'coding': 'நிரல் எழுதுவதற்குப் பயன்படுத்தலாம்',
      'tamil': 'தமிழுக்குப் பயன்படுத்தலாம்',
      'english': 'ஆங்கிலத்துக்குப் பயன்படுத்தலாம்',
      'vision': 'படங்களுக்குப் பயன்படுத்தலாம்',
      'translation': 'மொழிபெயர்ப்புக்குப் பயன்படுத்தலாம்',
      'summarizing': 'சுருக்கி எழுதுவதற்குப் பயன்படுத்தலாம்',
      'documents': 'நீண்ட ஆவணங்களுக்குப் பயன்படுத்தலாம்',
      'other': 'விரைவான உரையாடல்களுக்குப் பயன்படுத்தலாம்',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonGood(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'விரைவான உரையாடல்களுக்கு நல்லது',
      'reasoning': 'படிப்படியான பகுத்தறிவுக்கு நல்லது',
      'coding': 'நிரல் எழுதுவதற்கு நல்லது',
      'tamil': 'தமிழுக்கு நல்லது',
      'english': 'ஆங்கிலத்துக்கு நல்லது',
      'vision': 'படங்களுக்கு நல்லது',
      'translation': 'மொழிபெயர்ப்புக்கு நல்லது',
      'summarizing': 'சுருக்கி எழுதுவதற்கு நல்லது',
      'documents': 'நீண்ட ஆவணங்களுக்கு நல்லது',
      'other': 'விரைவான உரையாடல்களுக்கு நல்லது',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonExcellent(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'விரைவான உரையாடல்களுக்கு மிகச் சிறந்தது',
      'reasoning': 'படிப்படியான பகுத்தறிவுக்கு மிகச் சிறந்தது',
      'coding': 'நிரல் எழுதுவதற்கு மிகச் சிறந்தது',
      'tamil': 'தமிழுக்கு மிகச் சிறந்தது',
      'english': 'ஆங்கிலத்துக்கு மிகச் சிறந்தது',
      'vision': 'படங்களுக்கு மிகச் சிறந்தது',
      'translation': 'மொழிபெயர்ப்புக்கு மிகச் சிறந்தது',
      'summarizing': 'சுருக்கி எழுதுவதற்கு மிகச் சிறந்தது',
      'documents': 'நீண்ட ஆவணங்களுக்கு மிகச் சிறந்தது',
      'other': 'விரைவான உரையாடல்களுக்கு மிகச் சிறந்தது',
    });
    return '$_temp0';
  }

  @override
  String modelsCaveatNoneFits(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat':
          'விரைவான உரையாடல்களுக்கு இந்தக் கைப்பேசியில் பொருந்தும் மாடல் எதுவும் பட்டியலில் இல்லை.',
      'reasoning':
          'படிப்படியான பகுத்தறிவுக்கு இந்தக் கைப்பேசியில் பொருந்தும் மாடல் எதுவும் பட்டியலில் இல்லை.',
      'coding':
          'நிரல் எழுதுவதற்கு இந்தக் கைப்பேசியில் பொருந்தும் மாடல் எதுவும் பட்டியலில் இல்லை.',
      'tamil':
          'தமிழுக்கு இந்தக் கைப்பேசியில் பொருந்தும் மாடல் எதுவும் பட்டியலில் இல்லை.',
      'english':
          'ஆங்கிலத்துக்கு இந்தக் கைப்பேசியில் பொருந்தும் மாடல் எதுவும் பட்டியலில் இல்லை.',
      'vision':
          'படங்களுக்கு இந்தக் கைப்பேசியில் பொருந்தும் மாடல் எதுவும் பட்டியலில் இல்லை.',
      'translation':
          'மொழிபெயர்ப்புக்கு இந்தக் கைப்பேசியில் பொருந்தும் மாடல் எதுவும் பட்டியலில் இல்லை.',
      'summarizing':
          'சுருக்கி எழுதுவதற்கு இந்தக் கைப்பேசியில் பொருந்தும் மாடல் எதுவும் பட்டியலில் இல்லை.',
      'documents':
          'நீண்ட ஆவணங்களுக்கு இந்தக் கைப்பேசியில் பொருந்தும் மாடல் எதுவும் பட்டியலில் இல்லை.',
      'other':
          'விரைவான உரையாடல்களுக்கு இந்தக் கைப்பேசியில் பொருந்தும் மாடல் எதுவும் பட்டியலில் இல்லை.',
    });
    return '$_temp0';
  }

  @override
  String modelsCaveatNothingFitsWell(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat':
          'விரைவான உரையாடல்களுக்கு நன்றாகப் பொருந்துவது எதுவும் இல்லை. இவையே மிக அருகில் உள்ளவை.',
      'reasoning':
          'படிப்படியான பகுத்தறிவுக்கு நன்றாகப் பொருந்துவது எதுவும் இல்லை. இவையே மிக அருகில் உள்ளவை.',
      'coding':
          'நிரல் எழுதுவதற்கு நன்றாகப் பொருந்துவது எதுவும் இல்லை. இவையே மிக அருகில் உள்ளவை.',
      'tamil':
          'தமிழுக்கு நன்றாகப் பொருந்துவது எதுவும் இல்லை. இவையே மிக அருகில் உள்ளவை.',
      'english':
          'ஆங்கிலத்துக்கு நன்றாகப் பொருந்துவது எதுவும் இல்லை. இவையே மிக அருகில் உள்ளவை.',
      'vision':
          'படங்களுக்கு நன்றாகப் பொருந்துவது எதுவும் இல்லை. இவையே மிக அருகில் உள்ளவை.',
      'translation':
          'மொழிபெயர்ப்புக்கு நன்றாகப் பொருந்துவது எதுவும் இல்லை. இவையே மிக அருகில் உள்ளவை.',
      'summarizing':
          'சுருக்கி எழுதுவதற்கு நன்றாகப் பொருந்துவது எதுவும் இல்லை. இவையே மிக அருகில் உள்ளவை.',
      'documents':
          'நீண்ட ஆவணங்களுக்கு நன்றாகப் பொருந்துவது எதுவும் இல்லை. இவையே மிக அருகில் உள்ளவை.',
      'other':
          'விரைவான உரையாடல்களுக்கு நன்றாகப் பொருந்துவது எதுவும் இல்லை. இவையே மிக அருகில் உள்ளவை.',
    });
    return '$_temp0';
  }

  @override
  String modelsCaveatNothingStrong(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat':
          'இந்த அளவில் உள்ள எந்த மாடலும் விரைவான உரையாடல்களுக்கு வலுவானது அல்ல. மிக அருகில் உள்ளவை காட்டப்படுகின்றன.',
      'reasoning':
          'இந்த அளவில் உள்ள எந்த மாடலும் படிப்படியான பகுத்தறிவுக்கு வலுவானது அல்ல. மிக அருகில் உள்ளவை காட்டப்படுகின்றன.',
      'coding':
          'இந்த அளவில் உள்ள எந்த மாடலும் நிரல் எழுதுவதற்கு வலுவானது அல்ல. மிக அருகில் உள்ளவை காட்டப்படுகின்றன.',
      'tamil':
          'இந்த அளவில் உள்ள எந்த மாடலும் தமிழுக்கு வலுவானது அல்ல. மிக அருகில் உள்ளவை காட்டப்படுகின்றன.',
      'english':
          'இந்த அளவில் உள்ள எந்த மாடலும் ஆங்கிலத்துக்கு வலுவானது அல்ல. மிக அருகில் உள்ளவை காட்டப்படுகின்றன.',
      'vision':
          'இந்த அளவில் உள்ள எந்த மாடலும் படங்களுக்கு வலுவானது அல்ல. மிக அருகில் உள்ளவை காட்டப்படுகின்றன.',
      'translation':
          'இந்த அளவில் உள்ள எந்த மாடலும் மொழிபெயர்ப்புக்கு வலுவானது அல்ல. மிக அருகில் உள்ளவை காட்டப்படுகின்றன.',
      'summarizing':
          'இந்த அளவில் உள்ள எந்த மாடலும் சுருக்கி எழுதுவதற்கு வலுவானது அல்ல. மிக அருகில் உள்ளவை காட்டப்படுகின்றன.',
      'documents':
          'இந்த அளவில் உள்ள எந்த மாடலும் நீண்ட ஆவணங்களுக்கு வலுவானது அல்ல. மிக அருகில் உள்ளவை காட்டப்படுகின்றன.',
      'other':
          'இந்த அளவில் உள்ள எந்த மாடலும் விரைவான உரையாடல்களுக்கு வலுவானது அல்ல. மிக அருகில் உள்ளவை காட்டப்படுகின்றன.',
    });
    return '$_temp0';
  }

  @override
  String get modelsVisionUnavailable => 'இந்தப் பதிப்பில் படப் புரிதல் இல்லை.';

  @override
  String get modelsFitComfortable => 'உங்கள் கைப்பேசியில் நன்றாக இயங்கும்';

  @override
  String get modelsFitTightShort =>
      'நெருக்கமான பொருத்தம், மற்ற ஆப்களை மெதுவாக்கலாம்';

  @override
  String get modelsFitTooBig => 'உங்கள் கைப்பேசிக்கு மிகப் பெரியது';

  @override
  String get modelsFitUnknown => 'பொருத்தம் தெரியவில்லை';

  @override
  String get modelsSpeedUnknown => 'வேகம் தெரியவில்லை';

  @override
  String modelsAdvisorGoalCollapsed(String goal) {
    return 'இலக்கு: $goal · மாற்றத் தட்டவும்';
  }

  @override
  String get modelsAdvisorPromptCollapsed =>
      'நீங்கள் என்ன செய்ய விரும்புகிறீர்கள்? · இலக்கைத் தேர்வுசெய்யத் தட்டவும்';

  @override
  String get modelsAdvisorPrompt => 'நீங்கள் என்ன செய்ய விரும்புகிறீர்கள்?';

  @override
  String get modelsClear => 'அழி';

  @override
  String get modelsAdvisorCollapse => 'வழிகாட்டியைச் சுருக்கு';

  @override
  String modelsAdvisorSubtitleKnown(String device) {
    return 'உங்கள் கைப்பேசிக்குப் பொருந்தும் மாடலை Thinai தேர்ந்தெடுக்கிறது · $device';
  }

  @override
  String get modelsAdvisorSubtitle =>
      'இந்த வேலைக்கான மாடலை Thinai தேர்ந்தெடுக்கிறது';

  @override
  String get modelsAdvisorNothingFits =>
      'இதற்குப் பொருந்துவது எதுவும் பட்டியலில் இல்லை.';

  @override
  String get modelsAdvisorBestForPhone => 'உங்கள் கைப்பேசிக்குச் சிறந்த மாடல்';

  @override
  String get modelsAdvisorBestForThis => 'இதற்குச் சிறந்த மாடல்';

  @override
  String get modelsAdvisorAlsoConsider => 'இவற்றையும் பரிசீலிக்கலாம்';

  @override
  String modelsAdvisorAuthorDownload(String author, String size) {
    return '$author · $size பதிவிறக்கம்';
  }

  @override
  String modelsAdvisorContext(String context) {
    return '$context context';
  }

  @override
  String get modelsAdvisorAlreadyDownloaded => 'ஏற்கெனவே பதிவிறக்கப்பட்டது';

  @override
  String get modelsAdvisorSpeedMeasured =>
      'இந்தக் கைப்பேசியில் பெஞ்ச்மார்க் அளந்த வேகம்.';

  @override
  String get modelsAdvisorSpeedEstimated =>
      'மதிப்பிடப்பட்ட வேகம். உண்மையான எண்ணுக்குப் பெஞ்ச்மார்க்கை இயக்கவும்.';

  @override
  String get modelsAdvisorStartingCancel =>
      'தொடங்குகிறது… · ரத்துசெய்யத் தட்டவும்';

  @override
  String modelsAdvisorDownloadingCancel(String percent) {
    return 'பதிவிறக்குகிறது $percent% · ரத்துசெய்யத் தட்டவும்';
  }

  @override
  String get modelsSettingsTitle => 'மாடல் அமைப்புகள்';

  @override
  String get modelsSettingsBody =>
      'அரட்டையும் API சர்வரும் இவற்றைப் பயன்படுத்துகின்றன. கோரிக்கைகள் அதிகபட்ச வரம்பு வரை இவற்றை மாற்றலாம்.';

  @override
  String get modelsSettingsResetDefaults => 'இயல்புநிலைக்கு மீட்டமை';

  @override
  String get modelsSettingsContextWindow => 'Context window';

  @override
  String get modelsSettingsContextHelp =>
      'நீண்ட window அதிகம் நினைவில் வைக்கும், ஆனால் அதிக RAM எடுத்து மெதுவாக இயங்கும்.';

  @override
  String get modelsSettingsTemperature => 'Temperature';

  @override
  String get modelsSettingsPrecise => 'துல்லியம்';

  @override
  String get modelsSettingsCreative => 'படைப்பாற்றல்';

  @override
  String get modelsSettingsTopKHelp =>
      'ஒவ்வொரு சொல்லையும் மிக வாய்ப்புள்ள K சொற்களிலிருந்து மட்டுமே தேர்ந்தெடுக்கும். குறைவாக இருந்தால் அதிகக் கவனம்; 0 வரம்பை அணைக்கும்.';

  @override
  String get modelsSettingsTopPHelp =>
      'மொத்த நிகழ்தகவில் இந்தப் பங்கை உருவாக்கும் மிக வாய்ப்புள்ள சொற்களிலிருந்து தேர்ந்தெடுக்கும். 1.00 எல்லாவற்றையும் வைத்திருக்கும்.';

  @override
  String get modelsSettingsThinking => 'சிந்தனை';

  @override
  String get modelsSettingsThinkingHelp =>
      'பதிலளிக்கும் முன் படிப்படியாகச் சிந்திக்கும். ஆஃப் செய்தால் விரைவில் பதிலளிக்கும்.';

  @override
  String modelsSettingsCapPhoneRam(String max) {
    return 'அதிகபட்சம் $max, இந்தக் கைப்பேசியின் RAM-ஆல் வரம்பிடப்பட்டது.';
  }

  @override
  String modelsSettingsCapRam(String max, String trained) {
    return 'அதிகபட்சம் $max, RAM-ஆல் வரம்பிடப்பட்டது (மாடல் $trained வரை ஆதரிக்கும்).';
  }

  @override
  String modelsSettingsCapTraining(String max) {
    return 'அதிகபட்சம் $max, இந்த மாடலின் பயிற்சி வரம்பு.';
  }

  @override
  String modelsSettingsCap(String max) {
    return 'அதிகபட்சம் $max.';
  }
}
