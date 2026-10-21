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
  String get serverToastLanNoAddress =>
      'பகிர்வு ஆன், ஆனால் Wi-Fi/LAN முகவரி எதுவும் கிடைக்கவில்லை.';

  @override
  String serverToastStartFailed(String error) {
    return 'தொடங்குவது தோல்வியடைந்தது: $error';
  }

  @override
  String get serverPortDialogTitle => 'சர்வர் port-ஐ மாற்று';

  @override
  String get serverPortDialogBody =>
      'Thinai பயன்படுத்தும் உள்ளூர் TCP port-ஐத் தேர்ந்தெடுக்கவும் அல்லது உள்ளிடவும். Ollama-க்கு இயல்புநிலை 11434, வழக்கமான அமைப்புக்கு 8080.';

  @override
  String get serverPortNumberLabel => 'Port எண்';

  @override
  String get serverPortPresetStandard => '8080 (வழக்கமானது)';

  @override
  String get serverSavePort => 'Port-ஐச் சேமி';

  @override
  String get serverStatusRunning => 'இயங்குகிறது';

  @override
  String get serverStatusStopped => 'நிறுத்தப்பட்டது';

  @override
  String get serverStart => 'தொடங்கு';

  @override
  String get serverStop => 'நிறுத்து';

  @override
  String get serverCopyAddressTooltip => 'சர்வர் முகவரியை நகலெடு';

  @override
  String serverCopiedToClipboard(String value) {
    return '$value கிளிப்போர்டுக்கு நகலெடுக்கப்பட்டது';
  }

  @override
  String serverCopiedLabel(String label) {
    return '$label நகலெடுக்கப்பட்டது';
  }

  @override
  String get serverServingModel => 'இயங்கும் மாடல்';

  @override
  String get serverTune => 'சரிசெய்';

  @override
  String get serverNoModelLoaded =>
      'இன்னும் மாடல் எதுவும் ஏற்றப்படவில்லை. பதில்களைப் பெற ஒரு மாடலை ஏற்றவும்.';

  @override
  String get serverBrowseModels => 'மாடல்களைப் பார்';

  @override
  String get serverRegenerateTokenTitle => 'API token-ஐ மீண்டும் உருவாக்கவா?';

  @override
  String get serverRegenerateTokenBody =>
      'தற்போதைய token-ஐப் பயன்படுத்தும் LAN சாதனங்கள் அணுகலை இழக்கும். அவற்றைப் புதுப்பிக்க வேண்டும்.';

  @override
  String get serverRegenerate => 'மீண்டும் உருவாக்கு';

  @override
  String get serverTokenRegenerated => 'API token மீண்டும் உருவாக்கப்பட்டது';

  @override
  String get serverLanShareTitle => 'உள்ளூர் நெட்வொர்க்கில் பகிர் (LAN)';

  @override
  String get serverLanShareOnSubtitle =>
      'இந்த Wi-Fi-இல் உள்ள மற்ற கணினிகள் API-ஐ அணுகலாம்';

  @override
  String get serverLanShareOffSubtitle =>
      'இந்தக் கைப்பேசியில் இயங்கும் ஆப்ஸ் மட்டுமே 127.0.0.1-ஐ அணுக முடியும்';

  @override
  String get serverCopyLanUrlTooltip => 'LAN URL-ஐ நகலெடு';

  @override
  String get serverDevQuickStartTitle => 'டெவலப்பர் விரைவுத் தொடக்கம்';

  @override
  String get serverDevQuickStartSubtitle =>
      'கோடிங் உதவியாளர்கள், ஸ்கிரிப்ட்களுக்கான நேரடி அமைப்புக் குறியீடுகள்';

  @override
  String get serverTabChatJson => 'அரட்டை JSON';

  @override
  String get serverVsCodeIntro =>
      'VS Code-இல் Continue.dev அல்லது Cline நீட்டிப்புகளுக்கு:';

  @override
  String get serverPythonIntro =>
      'அதிகாரப்பூர்வ OpenAI Python SDK மூலம் கேள்வி அனுப்பவும்:';

  @override
  String get serverCurlIntro =>
      'நிலையான JSON payload உடன் டெர்மினலிலிருந்து நேரடி HTTP கோரிக்கை:';

  @override
  String get serverChatJsonIntro =>
      'OpenAI நிலையான அரட்டை payload (/v1/chat/completions):';

  @override
  String get serverOllamaIntro =>
      'எந்த Ollama client-ஐயும் (Open-WebUI, Chatbox, CLI) Thinai-உடன் இணைக்கவும்:';

  @override
  String get serverCopyLabelVsCodeConfig => 'VS Code அமைப்பு';

  @override
  String get serverCopyLabelPythonScript => 'Python ஸ்கிரிப்ட்';

  @override
  String get serverCopyLabelCurlCommand => 'cURL கட்டளை';

  @override
  String get serverCopyLabelChatJson => 'அரட்டை JSON payload';

  @override
  String get serverCopyLabelOllamaEnv => 'Ollama host மாறி';

  @override
  String get serverEndpointOpenAiChat => 'OpenAI அரட்டை completions';

  @override
  String get serverEndpointOllamaChat => 'Ollama நேரடி அரட்டை';

  @override
  String get serverEndpointEmbeddings => 'வெக்டர் embeddings';

  @override
  String get serverEndpointModels => 'நிறுவப்பட்ட மாடல்களின் பட்டியல்';

  @override
  String get serverApiEndpointsTitle => 'API endpoints';

  @override
  String get serverApiEndpointsSubtitle =>
      'OpenAI, Ollama உடன் இணக்கமான நிலையான HTTP routes';

  @override
  String get serverCopyBaseUrlTooltip => 'அடிப்படை URL-ஐ நகலெடு';

  @override
  String serverBaseUrlLabel(String url) {
    return 'அடிப்படை URL: $url';
  }

  @override
  String get serverCopyCurlTooltip => 'cURL-ஐ நகலெடு';

  @override
  String serverCurlCommandLabel(String path) {
    return '$path cURL கட்டளை';
  }

  @override
  String serverSecurityLan(String port) {
    return 'Wi-Fi நெட்வொர்க்கில் சேவை இயங்குகிறது · இந்த உள்ளூர் நெட்வொர்க்கில் உள்ள எந்தச் சாதனமும் உங்கள் Bearer token மூலம் port $port-இல் API-ஐ அணுகலாம்.';
  }

  @override
  String serverSecurityLocal(String port) {
    return 'உள்ளூர் loopback இயங்குகிறது · இந்தச் சாதனத்தில் இயங்கும் ஆப்ஸ் மட்டுமே localhost:$port-ஐ அணுக முடியும்.';
  }

  @override
  String get hfSearchHint => 'Hugging Face-இல் GGUF மாடல்களைத் தேடு';

  @override
  String get hfSearchFailedTitle => 'தேடல் தோல்வியடைந்தது';

  @override
  String get hfTryAgain => 'மீண்டும் முயல்';

  @override
  String get hfEmptyTitle => 'எந்த GGUF மாடலையும் தேடலாம்';

  @override
  String get hfEmptyMessage =>
      'பெயர் அல்லது உருவாக்கியவர் மூலம் தேடவும், எ.கா. \"gemma\", \"phi\" அல்லது \"unsloth\". GGUF கோப்புகள் உள்ள பொது repo-க்கள் மட்டுமே முடிவுகளில் வரும்.';

  @override
  String hfNoMatchTitle(String query) {
    return '\"$query\" உடன் பொருந்தும் GGUF மாடல்கள் இல்லை';
  }

  @override
  String get hfNoMatchMessage =>
      'சிறிய பெயர் அல்லது வேறு எழுத்துக்கூட்டலை முயலவும்.';

  @override
  String hfResultsTitle(int count) {
    return 'முடிவுகள் ($count)';
  }

  @override
  String get hfResultsSubtitle => 'அதிகம் பதிவிறக்கப்பட்டவை முதலில்';

  @override
  String hfShowingUpTo(int limit) {
    return 'அதிகபட்சம் $limit முடிவுகள் காட்டப்படுகின்றன.';
  }

  @override
  String get hfDownloadTitle => 'மாடலைப் பதிவிறக்கவா?';

  @override
  String get hfTooBigTitle => 'இந்தக் கைப்பேசிக்கு மிகப் பெரியதா?';

  @override
  String get hfDownloadAnyway => 'இருந்தாலும் பதிவிறக்கு';

  @override
  String hfDownloadMessage(String file, String size) {
    return 'Hugging Face-இலிருந்து $file ($size) பதிவிறக்க வேண்டுமா?';
  }

  @override
  String hfDownloadMessageTooBig(String file, String size) {
    return 'Hugging Face-இலிருந்து $file ($size) பதிவிறக்க வேண்டுமா?\n\nஇது இந்தக் கைப்பேசிக்கு மிகப் பெரியதாக இருக்கலாம், ஏற்றப்படாமல் போகலாம்.';
  }

  @override
  String hfDownloadMessageTooBigBudget(
    String file,
    String size,
    String needs,
    String budget,
  ) {
    return 'Hugging Face-இலிருந்து $file ($size) பதிவிறக்க வேண்டுமா?\n\nஇதற்குச் சுமார் $needs நினைவகம் தேவை. இந்தக் கைப்பேசியில் $budget மட்டுமே கிடைக்கிறது, எனவே இது ஏற்றப்படாமல் போகலாம்.';
  }

  @override
  String hfDownloadMessageTight(String file, String size) {
    return 'Hugging Face-இலிருந்து $file ($size) பதிவிறக்க வேண்டுமா?\n\nநினைவகம் போதுமானதாக இல்லாமல் இருக்கலாம். இது இயங்கும்போது மற்ற ஆப்ஸ் மூடப்படலாம்.';
  }

  @override
  String get hfOpenFailedTitle => 'இந்த மாடலைத் திறக்க முடியவில்லை';

  @override
  String get hfSignInTitle => 'உள்நுழைவு தேவை';

  @override
  String get hfSignInMessage =>
      'இந்த மாடலைப் பதிவிறக்க Hugging Face கணக்கு தேவை. Thinai இதை இன்னும் ஆதரிக்கவில்லை.';

  @override
  String hfFilesTitle(int count) {
    return 'GGUF கோப்புகள் ($count)';
  }

  @override
  String get hfFilesSubtitle =>
      'சிறிய கோப்புகள் வேகமாக ஏற்றப்படும், குறைந்த நினைவகத்தைப் பயன்படுத்தும்';

  @override
  String hfSkippedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'மேலும் $count GGUF கோப்புகள் மறைக்கப்பட்டுள்ளன: பிரிக்கப்பட்ட கோப்புகள், பட encoder-கள், உதவிக் கோப்புகளைத் தனியாக ஏற்ற முடியாது.',
      one:
          'மேலும் 1 GGUF கோப்பு மறைக்கப்பட்டுள்ளது: பிரிக்கப்பட்ட கோப்புகள், பட encoder-கள், உதவிக் கோப்புகளைத் தனியாக ஏற்ற முடியாது.',
    );
    return '$_temp0';
  }

  @override
  String get hfNothingTitle => 'இங்கே நிறுவ எதுவும் இல்லை';

  @override
  String get hfNothingMessage =>
      'Thinai ஏற்றக்கூடிய ஒற்றைக் கோப்பு GGUF மாடல்கள் இந்த repo-வில் இல்லை.';

  @override
  String get hfNetworkNotice =>
      'தேடலுக்கு இணையம் தேவை. நீங்கள் இங்கே தேடும்போதோ ஒரு மாடலைத் திறக்கும்போதோ மட்டுமே Thinai huggingface.co-ஐத் தொடர்புகொள்ளும், பின்னணியில் ஒருபோதும் இல்லை. உங்கள் அரட்டைகள் இந்தக் கைப்பேசியிலேயே இருக்கும்.';

  @override
  String get hfAgoToday => 'இன்று';

  @override
  String hfAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நாட்களுக்கு முன்',
      one: '1 நாளுக்கு முன்',
    );
    return '$_temp0';
  }

  @override
  String hfAgoMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மாதங்களுக்கு முன்',
      one: '1 மாதத்துக்கு முன்',
    );
    return '$_temp0';
  }

  @override
  String hfAgoYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ஆண்டுகளுக்கு முன்',
      one: '1 ஆண்டுக்கு முன்',
    );
    return '$_temp0';
  }

  @override
  String hfByAuthor(String author) {
    return '$author உருவாக்கியது';
  }

  @override
  String get hfNoLicence => 'உரிமம் குறிப்பிடப்படவில்லை';

  @override
  String get hfInstalled => 'நிறுவப்பட்டது';

  @override
  String get hfPause => 'இடைநிறுத்து';

  @override
  String get hfFindMore => 'Hugging Face-இல் மேலும் தேடு';

  @override
  String hfSearchFor(String query) {
    return 'Hugging Face-இல் \"$query\"-ஐத் தேடு';
  }

  @override
  String get hfPromptSubtitle =>
      'எந்தப் பொது GGUF மாடலையும் உங்கள் தொகுப்பில் நிறுவலாம். இணையம் தேவை.';

  @override
  String get settingsAppearance => 'தோற்றம்';

  @override
  String get settingsSystemPrompt => 'சிஸ்டம் ப்ராம்ப்ட்';

  @override
  String get settingsHardware => 'வன்பொருள் & வேகமாக்கல்';

  @override
  String get settingsModelStorage => 'மாடல் & சேமிப்பகம்';

  @override
  String get settingsLocalServer => 'லோக்கல் சர்வர் & API';

  @override
  String get settingsAboutGuidance => 'பற்றி & வழிகாட்டல்';

  @override
  String get settingsStartPage => 'தொடங்கும்போது திறக்கும் பக்கம்';

  @override
  String get settingsThemeMode => 'தீம்';

  @override
  String get settingsThemeSystem => 'சாதன அமைப்பு';

  @override
  String get settingsThemeDark => 'இருண்ட';

  @override
  String get settingsThemeLight => 'வெளிர்';

  @override
  String get settingsWebSearch => 'அரட்டையில் இணையத் தேடல்';

  @override
  String get settingsEnabled => 'இயக்கத்தில்';

  @override
  String get settingsDisabled => 'முடக்கத்தில்';

  @override
  String get settingsGpuAcceleration => 'GPU வேகமாக்கல்';

  @override
  String get settingsGpuAuto => 'தானியங்கி';

  @override
  String get settingsBenchmarkDevice => 'சாதனத்தை பெஞ்ச்மார்க் செய்';

  @override
  String get settingsGpuDiagnostics => 'GPU வேகச் சோதனை';

  @override
  String get settingsDeviceSpecs => 'சாதன வன்பொருள் விவரங்கள்';

  @override
  String settingsDeviceSpecsWithRam(int cores, String ramGb) {
    return '$cores கோர்கள் • $ramGb GB RAM';
  }

  @override
  String settingsDeviceSpecsCores(int cores) {
    return '$cores CPU கோர்கள்';
  }

  @override
  String settingsImported(String name) {
    return '$name இறக்குமதி செய்யப்பட்டது';
  }

  @override
  String settingsImportFailed(String error) {
    return 'இறக்குமதி தோல்வியடைந்தது: $error';
  }

  @override
  String get settingsDownloadStarted => 'பதிவிறக்கம் தொடங்கியது';

  @override
  String settingsDownloadStopped(String error) {
    return 'பதிவிறக்கம் நின்றது: $error. முன்னேற்றம் சேமிக்கப்பட்டது, மாடல் மேலாளரில் இருந்து தொடரவும்.';
  }

  @override
  String settingsDownloadFailed(String error) {
    return 'பதிவிறக்கம் தோல்வியடைந்தது: $error';
  }

  @override
  String get settingsDownloadComplete => 'பதிவிறக்கம் முடிந்தது';

  @override
  String get settingsClearDownloadsTitle => 'எல்லா பதிவிறக்கங்களையும் நீக்கவா?';

  @override
  String get settingsClearDownloadsBody =>
      'சாதனச் சேமிப்பகத்தில் இடம் விடுவிக்க, ஆப்பில் பதிவிறக்கப்பட்ட எல்லா மாடல் கோப்புகளும் நீக்கப்படும்.';

  @override
  String get settingsClearAll => 'எல்லாம் நீக்கு';

  @override
  String get settingsNoDownloadsFound => 'பதிவிறக்கப்பட்டவை எதுவும் இல்லை';

  @override
  String settingsClearedDownloads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'பதிவிறக்கப்பட்ட $count உருப்படிகள் நீக்கப்பட்டன',
      one: 'பதிவிறக்கப்பட்ட 1 உருப்படி நீக்கப்பட்டது',
    );
    return '$_temp0';
  }

  @override
  String settingsClearFailed(String error) {
    return 'நீக்குவது தோல்வியடைந்தது: $error';
  }

  @override
  String get settingsTune => 'சீரமை';

  @override
  String get settingsNoActiveModel => 'எந்த மாடலும் ஏற்றப்படவில்லை';

  @override
  String get settingsCatalog => 'பட்டியல்';

  @override
  String get settingsImportGguf => 'கைப்பேசியில் உள்ள .gguf-ஐ இறக்குமதி செய்';

  @override
  String get settingsDownloadFromUrl => 'URL மூலம் மாடலைப் பதிவிறக்கு';

  @override
  String get settingsClearDownloadedModels => 'பதிவிறக்கப்பட்ட மாடல்களை நீக்கு';

  @override
  String get settingsChangePortTitle => 'சர்வர் port-ஐ மாற்று';

  @override
  String get settingsPortNumber => 'Port எண்';

  @override
  String settingsPortSetRestart(int port) {
    return 'சர்வர் port $port ஆக அமைக்கப்பட்டது. மாற்றம் நடைமுறைக்கு வர சர்வரை மறுதொடக்கம் செய்யவும்.';
  }

  @override
  String settingsPortSet(int port) {
    return 'சர்வர் port $port ஆக அமைக்கப்பட்டது';
  }

  @override
  String get settingsShareApiWifi => 'Wi-Fi வழியாக API-ஐப் பகிர்';

  @override
  String get settingsServerPort => 'சர்வர் port';

  @override
  String get settingsServerStatus => 'சர்வர் நிலை';

  @override
  String get settingsServerActive => 'இயங்குகிறது';

  @override
  String get settingsServerOffline => 'நிறுத்தப்பட்டது';

  @override
  String get settingsUpToDate => 'Thinai சமீபத்திய பதிப்பில் உள்ளது';

  @override
  String get settingsUpdateUnavailable =>
      'Play Store-ஆல் புதுப்பிப்புகளைச் சரிபார்க்க முடியவில்லை';

  @override
  String get settingsUpdateAlreadyDownloading =>
      'ஒரு புதுப்பிப்பு ஏற்கனவே பதிவிறக்குகிறது';

  @override
  String get settingsUpdateDownloading =>
      'புதுப்பிப்பு பின்னணியில் பதிவிறக்குகிறது';

  @override
  String get settingsUpdateFailed =>
      'புதுப்பிப்பு தோல்வியடைந்தது. Play Store-இல் மீண்டும் முயலவும்.';

  @override
  String get settingsUpdateReadyTitle => 'புதுப்பிப்பு தயார்';

  @override
  String get settingsUpdateReadyBody =>
      'புதிய பதிப்பு பதிவிறக்கப்பட்டது. அதை நிறுவ Thinai மறுதொடக்கம் ஆகும்.';

  @override
  String get settingsRestart => 'மறுதொடக்கம்';

  @override
  String get settingsStartTour => 'ஆப் சுற்றுலாவைத் தொடங்கு';

  @override
  String get settingsCheckUpdates => 'புதுப்பிப்புகளைச் சரிபார்';

  @override
  String get settingsContactSupport => 'ஆதரவைத் தொடர்புகொள்';

  @override
  String get settingsAboutThinai => 'Thinai பற்றி';

  @override
  String get settingsDownloadDialogTitle => 'URL மூலம் மாடலைப் பதிவிறக்கு';

  @override
  String get settingsDirectGgufUrl => 'நேரடி GGUF URL';

  @override
  String get settingsSaveAsOptional => 'சேமிக்கும் பெயர் (விருப்பத்தேர்வு)';

  @override
  String get gpuAcceleration => 'GPU வேகமாக்கல்';

  @override
  String get gpuSubtitle => 'கணக்கீட்டை வன்பொருள் accelerator-க்கு மாற்றுகிறது';

  @override
  String get gpuDescription =>
      'மாடலை CPU-க்குப் பதிலாக GPU-வில் இயக்குகிறது. இந்தக் கைப்பேசியில் இது உதவுகிறதா என்று பார்க்க வேகச் சோதனையை இயக்கவும்.';

  @override
  String gpuCrashedNotice(String backend) {
    return 'கடந்த முறை $backend ஆப்பை செயலிழக்கச் செய்தது, எனவே GPU வேகமாக்கல் அணைக்கப்பட்டது.';
  }

  @override
  String get gpuCheckPhone => 'இந்தக் கைப்பேசியின் GPU-வைச் சரிபார்';

  @override
  String get gpuNoneFound =>
      'பயன்படுத்தக்கூடிய GPU எதுவும் இல்லை. Thinai தொடர்ந்து CPU-வைப் பயன்படுத்தும்.';

  @override
  String gpuFound(String devices) {
    return 'கண்டறியப்பட்டது: $devices';
  }

  @override
  String get gpuAuto => 'தானியங்கி';

  @override
  String gpuAutoWith(String backend) {
    return 'தானியங்கி ($backend)';
  }

  @override
  String get gpuTesting => 'சோதிக்கிறது…';

  @override
  String get gpuSpeedTest => 'வேகச் சோதனை';

  @override
  String get gpuLoadModelFirst =>
      'முதலில் ஒரு மாடலை ஏற்றி, பிறகு சோதனையை இயக்கவும்.';

  @override
  String gpuTestFailed(String error) {
    return 'சோதனை தோல்வியடைந்தது: $error';
  }

  @override
  String get gpuVerdictGpuFaster => 'இந்தக் கைப்பேசியில் GPU வேகமாக உள்ளது.';

  @override
  String get gpuVerdictCpuFaster =>
      'இங்கே CPU வேகமாக உள்ளது. GPU வேகமாக்கலை அணைத்தே வைக்கவும்.';

  @override
  String get gpuVerdictSame => 'இரண்டிலும் ஏறக்குறைய ஒரே வேகம்.';

  @override
  String get gpuReadingPrompt => 'ப்ராம்ப்ட் படித்தல்';

  @override
  String get gpuWritingReply => 'பதில் எழுதுதல்';

  @override
  String get aboutTitle => 'Thinai பற்றி';

  @override
  String aboutVersionBadge(String version) {
    return 'v$version · சாதனத்திலேயே இயங்கும் தனிப்பட்ட AI';
  }

  @override
  String get aboutHeroDescription =>
      'Thinai நவீன open-weights மாடல்களை உங்கள் Android கைப்பேசியிலேயே நேரடியாக இயக்குகிறது. இணையம் தேவையில்லை, கிளவுட் சார்பு இல்லை, உங்கள் தரவு 100% உங்களிடமே.';

  @override
  String get aboutCorePillars => 'அடிப்படைத் தூண்கள்';

  @override
  String get aboutPrivateTitle => '100% தனிப்பட்டது & சுயாதீனமானது';

  @override
  String get aboutPrivateBody =>
      'ஒவ்வொரு token-உம் ஒவ்வொரு ப்ராம்ப்ட்-உம் சாதனத்தின் RAM-க்குள் மட்டுமே கணக்கிடப்படுகின்றன. டெலிமெட்ரி இல்லை, பதிவுகள் இல்லை, கிளவுட் இடைமறிப்பும் இல்லை.';

  @override
  String get aboutAcceleratedTitle => 'வன்பொருள் வேகமாக்கல்';

  @override
  String get aboutAcceleratedBody =>
      'Vulkan, OpenCL GPU வேகமாக்கலுடன் கூடிய உயர் செயல்திறன் llama.cpp மொபைல் runtime-இல் உருவாக்கப்பட்டது; நவீன மொபைல் சிப்செட்களில் அதிக வேகத்திற்காகச் சீரமைக்கப்பட்டது.';

  @override
  String get aboutApiTitle => 'லோக்கல் OpenAI-இணக்க API';

  @override
  String get aboutApiBody =>
      'localhost:11434-இல் /v1/chat/completions உடன் உள்ளமைந்த HTTP சர்வரை இயக்கி, உங்கள் கைப்பேசியை மற்ற ஆப்களுக்கும் தானியங்கிச் செயல்களுக்கும் AI இயந்திரமாக மாற்றுகிறது.';

  @override
  String get aboutVisionTitle => 'படம் புரிதல் & இணையம்';

  @override
  String get aboutVisionBody =>
      'படம் புரியும் மாடல்கள் (Gemma 3, MiniCPM) மூலம் படங்களைப் பற்றி உரையாடலாம், ஆவணங்களைச் சுருக்கலாம், தனியுரிமையைக் காக்கும் நேரலை இணையத் தேடல் மேற்கோள்களைப் பெறலாம்.';

  @override
  String get aboutTechSpecs => 'தொழில்நுட்ப விவரங்கள்';

  @override
  String get aboutSpecEngine => 'Inference இயந்திரம்';

  @override
  String get aboutSpecModelFormat => 'மாடல் வடிவம்';

  @override
  String get aboutSpecArchitecture => 'இலக்கு கட்டமைப்பு';

  @override
  String get aboutSpecBackends => 'வேகமாக்கல் backends';

  @override
  String get aboutSpecLicense => 'மென்பொருள் உரிமம்';

  @override
  String get aboutSpecLicenseValue => 'திறந்த மூலம் (MIT)';

  @override
  String get aboutCommunity => 'சமூகம் & வெளிப்படைத்தன்மை';

  @override
  String get aboutCommunityBody =>
      'Thinai தனியுரிமை மற்றும் திறந்த மூலக் கொள்கைகளின் அடிப்படையில் உருவாக்கப்பட்டது. மூன்றாம் தரப்பு உரிமங்கள் அனைத்தையும் பார்க்கலாம் அல்லது உதவிக்கு ஆதரவைத் தொடர்புகொள்ளலாம்.';

  @override
  String get aboutLicenses => 'உரிமங்கள்';

  @override
  String get aboutContactSupport => 'ஆதரவைத் தொடர்புகொள்';

  @override
  String get supportTitle => 'ஆதரவைத் தொடர்புகொள்';

  @override
  String supportCouldNotOpenLink(String url) {
    return 'இணைப்பைத் திறக்க முடியவில்லை: $url';
  }

  @override
  String supportFailedToOpenLink(String error) {
    return 'இணைப்பைத் திறப்பது தோல்வியடைந்தது: $error';
  }

  @override
  String get supportHeroTitle => 'நாங்கள் எப்படி உதவலாம்?';

  @override
  String get supportHeroBody =>
      'மாடல்களை இயக்க உதவி வேண்டுமா, பிழை கண்டீர்களா, அல்லது ஏதேனும் பரிந்துரை உள்ளதா? சமூகக் கேள்விகளுக்கு விரைவில் பதிலளிக்கிறோம்.';

  @override
  String get supportChannels => 'நேரடி ஆதரவு வழிகள்';

  @override
  String get supportInstagramTitle => 'Instagram ஆதரவு';

  @override
  String get supportInstagramBody =>
      'நேரடிச் செய்திகள், புதிய வசதிகளின் முன்னோட்டம், சிக்கல் தீர்வு மற்றும் அறிவிப்புகள்.';

  @override
  String get supportInstagramOpenFailed =>
      'Instagram இணைப்பைத் திறக்க முடியவில்லை';

  @override
  String get supportOpenInstagram => 'Instagram-ஐத் திற';

  @override
  String get supportCopyHandle => 'Instagram பெயரை நகலெடு';

  @override
  String get supportHandleCopied =>
      'Instagram பெயர் கிளிப்போர்டுக்கு நகலெடுக்கப்பட்டது';

  @override
  String get supportDiagnostics => 'சாதனக் கண்டறிதல் தகவல்';

  @override
  String get supportDiagnosticsHint =>
      'எங்களைத் தொடர்புகொள்ளும்போது இந்தத் தகவலை நகலெடுத்து அனுப்பினால், சிக்கலைப் பத்து மடங்கு வேகமாகத் தீர்க்கலாம்.';

  @override
  String supportCpuCores(int cores) {
    return '$cores CPU கோர்கள்';
  }

  @override
  String supportTier(String tier) {
    return 'நிலை: $tier';
  }

  @override
  String supportModel(String model) {
    return 'மாடல்: $model';
  }

  @override
  String get supportNoActiveModel => 'செயலில் மாடல் இல்லை';

  @override
  String get supportServerActive => 'சர்வர்: இயங்குகிறது';

  @override
  String get supportServerStopped => 'சர்வர்: நிறுத்தப்பட்டது';

  @override
  String get supportCopyDiagnostics => 'கண்டறிதல் தகவலை நகலெடு';

  @override
  String get supportDiagnosticsCopied =>
      'கண்டறிதல் தகவல் கிளிப்போர்டுக்கு நகலெடுக்கப்பட்டது';

  @override
  String get supportTroubleshooting => 'விரைவுச் சிக்கல் தீர்வு';

  @override
  String get supportFaqLoadQuestion =>
      'மாடலை ஏற்றவோ பதிவிறக்கவோ ஏன் நீண்ட நேரம் ஆகிறது?';

  @override
  String get supportFaqLoadAnswer =>
      'மாடல்கள் பெரிய AI நியூரல் நெட்வொர்க்குகள் (1 GB முதல் 4+ GB வரை). பதிவிறக்க வேகம் உங்கள் Wi-Fi இணைப்பைப் பொறுத்தது. ஏற்றுவதற்கு RAM தேவை; 7B+ மாடல்களை ஏற்றும் முன் பின்னணி ஆப்களை மூடவும்.';

  @override
  String get supportFaqPrivacyQuestion =>
      'Thinai என் அரட்டைகளைக் கிளவுடுக்குக் கசியவிடுகிறதா அல்லது பதிவேற்றுகிறதா?';

  @override
  String get supportFaqPrivacyAnswer =>
      'ஒருபோதும் இல்லை. Thinai முழுக்க முழுக்க 100% தனிப்பட்டதாகவும் ஆஃப்லைனாகவும் உருவாக்கப்பட்டது. மாடல் உங்கள் கைப்பேசியின் CPU/GPU-விலேயே நேரடியாக இயங்குகிறது; எந்த உரையாடல் தரவும் சாதன நினைவகத்தை விட்டு வெளியேறாது.';

  @override
  String get supportFaqGpuQuestion =>
      'GPU வேகமாக்கலை (Vulkan / OpenCL) எப்படிப் பயன்படுத்துவது?';

  @override
  String get supportFaqGpuAnswer =>
      'அமைப்புகள் > வன்பொருள் & வேகமாக்கல் என்பதற்குச் சென்று Vulkan அல்லது OpenCL-ஐத் தேர்ந்தெடுக்கவும். Qualcomm Snapdragon Adreno மற்றும் நவீன MediaTek Dimensity GPU-களில் Vulkan சிறப்பாக இயங்கும்.';

  @override
  String get systemPromptTitle => 'சிஸ்டம் ப்ராம்ப்ட்';

  @override
  String get systemPromptSaved =>
      'சிஸ்டம் ப்ராம்ப்ட் சேமிக்கப்பட்டது. புதிய செய்திகள் இதைப் பயன்படுத்தும்.';

  @override
  String get systemPromptResetDone =>
      'சிஸ்டம் ப்ராம்ப்ட் இயல்புநிலைக்கு மீட்டமைக்கப்பட்டது.';

  @override
  String get systemPromptDescription =>
      'ஒவ்வொரு அரட்டையின் தொடக்கத்திலும் மாடலுக்கு அனுப்பப்படும் அறிவுறுத்தல்கள். நீங்கள் அனுப்பும் அடுத்த செய்தியிலிருந்து மாற்றங்கள் பொருந்தும். மாடலின் சொந்த இயல்புநிலையைப் பயன்படுத்த இதைக் காலியாக விடவும்.';

  @override
  String get systemPromptHint => 'நீங்கள் உதவிகரமான ஒரு உதவியாளர்…';

  @override
  String systemPromptCharacters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count எழுத்துகள்',
      one: '1 எழுத்து',
    );
    return '$_temp0';
  }

  @override
  String get systemPromptResetToDefault => 'இயல்புநிலைக்கு மீட்டமை';

  @override
  String get benchmarkTitle => 'பெஞ்ச்மார்க்';

  @override
  String get benchmarkStop => 'நிறுத்து';

  @override
  String benchmarkError(String error) {
    return 'பிழை: $error';
  }

  @override
  String get benchmarkRunning => 'இயங்குகிறது…';

  @override
  String get benchmarkRun => 'பெஞ்ச்மார்க் இயக்கு';

  @override
  String benchmarkDescription(int tokens) {
    return '$tokens tokens உருவாக்கி, decode வேகத்தை அளவிடுகிறது. முதல் token-க்கான நேரம் தனியாகக் காட்டப்படும்.';
  }

  @override
  String get benchmarkTokensPerSecond => 'tokens / வினாடி';

  @override
  String get benchmarkIdle => 'சும்மா உள்ளது';

  @override
  String get benchmarkMeasuring => 'அளவிடுகிறது';

  @override
  String get benchmarkThroughput => 'ஓட்டம் முழுவதும் வேகம்';

  @override
  String benchmarkPeak(String value) {
    return 'உச்சம் $value';
  }

  @override
  String get benchmarkWarmingUp => 'தயாராகிறது…';

  @override
  String get benchmarkPlotEmpty => 'வரைபடம் காண பெஞ்ச்மார்க் இயக்கவும்';

  @override
  String get benchmarkFirstToken => 'முதல் token';

  @override
  String get benchmarkTokens => 'Tokens';

  @override
  String get benchmarkTotal => 'மொத்தம்';

  @override
  String get benchmarkSampleOutput => 'மாதிரி வெளியீடு';

  @override
  String get benchmarkThisSession => 'இந்த அமர்வு';

  @override
  String benchmarkRunSummary(int tokens, String firstToken, String total) {
    return '$tokens tokens · முதல் token $firstToken · மொத்தம் $total';
  }

  @override
  String get benchmarkEmptyTitle => 'அளவிட மாடல்கள் இல்லை';

  @override
  String get benchmarkEmptyBody => 'வேகத்தை அளவிட ஒரு மாடலைப் பதிவிறக்கவும்.';

  @override
  String get benchmarkBestForHardware => 'உங்கள் வன்பொருளுக்குச் சிறந்தது';

  @override
  String benchmarkMeasuredWithDevice(String device, String bandwidth) {
    return '$device · அளவிடப்பட்ட பயனுள்ள வேகம் $bandwidth GB/s';
  }

  @override
  String benchmarkMeasured(String bandwidth) {
    return 'அளவிடப்பட்ட பயனுள்ள வேகம் $bandwidth GB/s';
  }

  @override
  String benchmarkEstimateWithDevice(String device) {
    return '$device · கீழே உள்ள மதிப்பீடுகளை உண்மையான அளவீடுகளாக மாற்ற பெஞ்ச்மார்க் இயக்கவும்';
  }

  @override
  String get benchmarkCalibratePrompt =>
      'இவற்றைத் துல்லியமாக்க பெஞ்ச்மார்க் இயக்கவும்';

  @override
  String get benchmarkInstalled => 'நிறுவப்பட்டது';

  @override
  String get tourBadge => 'Thinai அறிமுகம்';

  @override
  String get tourCloseTooltip => 'அறிமுகத்தை மூடு';

  @override
  String tourStageLabel(int current, int total) {
    return 'படி $current / $total';
  }

  @override
  String get tourPrivateTag => '100% தனிப்பட்டது, உங்கள் கட்டுப்பாட்டில்';

  @override
  String get tourPrivateTitle => 'உங்கள் சாதனம்.\nஉங்கள் நுண்ணறிவு.';

  @override
  String get tourPrivateBody =>
      'Thinai பெரிய மொழி மாடல்களை உங்கள் கைப்பேசியிலேயே நேரடியாக இயக்குகிறது. உங்கள் கேள்விகள், படங்கள், ஆவணங்கள் எதுவும் சாதனத்தை விட்டு வெளியே போவதில்லை.';

  @override
  String get tourOnDeviceTitle => 'Thinai (சாதனத்திலேயே)';

  @override
  String get tourOnDeviceBody =>
      'விமானப் பயன்முறையிலும் ஆஃப்லைனில் இயங்கும் · தரவு சேகரிப்பு இல்லை · llama.cpp மூலம் சாதனத்திலேயே இயக்கம் · சந்தா இல்லை';

  @override
  String get tourCloudTitle => 'வழக்கமான கிளவுட் AI';

  @override
  String get tourCloudBody =>
      'உங்கள் கேள்விகளைத் தொலைதூர சர்வர்களில் பதிவுசெய்யும் · அதிவேக இணையம் தேவை · மாதாந்திர API கட்டணம்';

  @override
  String get tourDeviceReady =>
      'சாதனம் தயார்: உள்ளூர் GGUF மாடல்களுக்கு வன்பொருள் வேகமூட்டல் கிடைக்கிறது.';

  @override
  String get tourCatalogTag => 'தேர்ந்தெடுத்த GGUF பட்டியல்';

  @override
  String get tourCatalogTitle => 'உலகத்தர மாடல்கள்,\nஉங்கள் RAM-க்கு ஏற்றபடி.';

  @override
  String get tourCatalogBody =>
      'Alibaba, Meta, Google, Microsoft வழங்கும் open-weight மாடல்களைப் பாருங்கள். எது சீராக இயங்கும் என்று சொல்ல, Thinai உங்கள் கைப்பேசியின் நினைவகத்தைத் தானாகவே சரிபார்க்கிறது.';

  @override
  String get tourMemoryFitTitle => 'நினைவகப் பொருத்த ஆலோசகர்';

  @override
  String get tourFitEasyLabel => 'எளிதில் பொருந்தும்';

  @override
  String get tourFitEasyBody => 'சீரான பதில், குறைந்த பேட்டரி செலவு.';

  @override
  String get tourFitTightLabel => 'நெருக்கம்';

  @override
  String get tourFitTightBody =>
      'நன்றாக இயங்கும்; பின்னணியில் உள்ள கனமான ஆப்களை மூடவும்.';

  @override
  String get tourFitTooBigLabel => 'மிகப் பெரியது';

  @override
  String get tourFitTooBigBody =>
      'உங்கள் கைப்பேசி செயலிழக்காமல் இருக்க முன்பே எச்சரிக்கும்.';

  @override
  String tourStarterTitle(String model, String size) {
    return 'பரிந்துரைக்கப்பட்ட தொடக்க மாடல்: $model (~$size)';
  }

  @override
  String get tourStarterBody =>
      'மிகச் சிறிய, மிக வேகமான அரட்டை மாடல்; எந்தக் கைப்பேசியிலும் உடனே இயங்கும்.';

  @override
  String get tourChatTag => 'அரட்டை ஸ்டுடியோ & படப் புரிதல்';

  @override
  String get tourChatTitle =>
      'முழுமையான மல்டிமோடல் ஸ்டுடியோ,\nநேரலைச் சிந்தனையுடன்.';

  @override
  String get tourChatBody =>
      'தாமதமின்றி அரட்டையடியுங்கள், vision மாடல்களுக்குக் கேமரா படங்களை இணையுங்கள், பதில் குமிழ்களிலேயே உருவாக்க வேகத்தை நேரலையில் பாருங்கள்.';

  @override
  String get tourDemoPrompt => 'குவாண்டம் சூப்பர்பொசிஷனை எளிமையாக விளக்கு.';

  @override
  String get tourDemoReply =>
      'அளக்கப்படும் வரை ஒரு துகள் ஒரே நேரத்தில் பல நிலைகளில் இருக்கலாம் — கீழே விழும் முன் சுழலும் நாணயம் போல.';

  @override
  String tourDemoSpeed(String speed) {
    return '⚡ $speed t/s · சாதனத்தில்';
  }

  @override
  String get tourFeatureReasoning => 'சிந்தனைப் படிகள்';

  @override
  String get tourFeatureVision => 'கேமரா & படப் புரிதல்';

  @override
  String get tourFeaturePersonas => 'தனிப்பயன் ஆளுமைகள்';

  @override
  String get tourServerTag => 'OpenAI-இணக்கமான API';

  @override
  String get tourServerTitle =>
      'உங்கள் கைப்பேசியை\nதனிப்பட்ட AI சர்வராக்குங்கள்.';

  @override
  String get tourServerBody =>
      'Thinai-இல் உள்ளமைந்த HTTP சர்வர் உண்டு. வெளிப்புற டெவலப்பர் கருவிகளுக்கு OpenAI, Ollama API-களுக்கு மாற்றாக, மாடலை உங்கள் சாதனத்திலேயே இயக்குங்கள்.';

  @override
  String get tourEndpointsTitle => 'Localhost endpoint-கள்';

  @override
  String tourPortBadge(String port) {
    return 'PORT $port';
  }

  @override
  String tourCompatibleWith(String tools) {
    return 'இவற்றுடன் இணக்கமானது: $tools';
  }

  @override
  String get tourStartTag => 'தொடங்கத் தயார்';

  @override
  String get tourStartTitle => 'எங்கிருந்து\nதொடங்கலாம்?';

  @override
  String get tourStartBody =>
      'இன்று Thinai-ஐ எப்படிப் பயன்படுத்த விரும்புகிறீர்கள்?';

  @override
  String tourOptionStarterTitle(String model) {
    return '1. தொடக்க மாடலைப் பதிவிறக்கவும் ($model)';
  }

  @override
  String tourOptionStarterBody(String size) {
    return 'சரிபார்க்கப்பட்ட மிகச் சிறிய மாடல் (~$size). விரைவாகப் பதிவிறக்கலாம், எந்தச் சாதனத்திலும் சீராக இயங்கும்.';
  }

  @override
  String get tourOptionStarterButton => 'மாடலைப் பெறு';

  @override
  String get tourOptionCatalogTitle => '2. முழுப் பட்டியலையும் பாருங்கள்';

  @override
  String get tourOptionCatalogBody =>
      'Meta, Google, Microsoft, Alibaba வழங்கும் 30+ GGUF மாடல்களைப் பாருங்கள்.';

  @override
  String get tourOptionCatalogButton => 'பட்டியலைத் திற';

  @override
  String get tourOptionLiveTitle => '3. ஆப்பிற்குள் நேரடி வழிகாட்டல்';

  @override
  String get tourOptionLiveBody =>
      'மிதக்கும் வழிகாட்டியுடன் ஒவ்வொரு தாவலையும் படிப்படியாகப் பாருங்கள்.';

  @override
  String get tourOptionLiveButton => 'வழிகாட்டு';

  @override
  String get tourCompleteTour => 'அறிமுகத்தை முடி';

  @override
  String get tourNextStep => 'அடுத்த படி';

  @override
  String tourDockStep(int step, int total) {
    return 'படி $step / $total';
  }

  @override
  String get tourExitTour => 'வெளியேறு';

  @override
  String get tourPrevious => 'முந்தையது';

  @override
  String get tourFinishTour => 'முடி';

  @override
  String get tourDockModelsTitle => 'மாடல் பட்டியல் (தாவல் 2)';

  @override
  String get tourDockModelsBody =>
      'சரிபார்க்கப்பட்ட GGUF மாடல்களைப் பாருங்கள். உங்கள் கைப்பேசியில் சீராக இயங்கும் மாடலைத் தேர்வுசெய்ய, RAM பொருத்தக் குறியைக் (பாதுகாப்பானது / நெருக்கம்) கவனியுங்கள்.';

  @override
  String get tourDockManageTitle => 'நிர்வாகம் & பெஞ்ச்மார்க்';

  @override
  String get tourDockManageBody =>
      'பதிவிறக்கங்களை நிர்வகிக்க மேல் வலது ஐகான்களைப் பயன்படுத்தவும். உங்கள் கைப்பேசியின் உண்மையான token உருவாக்க வேகத்தை அளக்க, வேகமானி ஐகானைத் தட்டவும்.';

  @override
  String get tourDockChatTitle => 'அரட்டை ஸ்டுடியோ (தாவல் 1)';

  @override
  String get tourDockChatBody =>
      'முழுத் தனியுரிமையுடன் அரட்டையடிக்கவும். படங்கள் அல்லது ஆவணங்களை இணைத்துப் பகுப்பாய்வு செய்யவும்; நொடிக்கு எத்தனை tokens என்பதை நேரலையில் பார்க்கவும்.';

  @override
  String get tourDockServerTitle => 'உள்ளூர் API சர்வர் (தாவல் 3)';

  @override
  String tourDockServerBody(String address) {
    return 'Cursor, Continue அல்லது உங்கள் சொந்த ஸ்கிரிப்ட்களுக்காக, உங்கள் கைப்பேசியை $address-இல் தனிப்பட்ட OpenAI-இணக்கமான endpoint ஆக மாற்றவும்.';
  }

  @override
  String get tourAppTour => 'ஆப் அறிமுகம்';

  @override
  String get tourLocatingControl => 'இடத்தைக் கண்டறிகிறது…';

  @override
  String get tourWelcomeTitle => 'Thinai-க்கு வரவேற்கிறோம்';

  @override
  String get tourWelcomeOfflineBadge => 'ஆஃப்லைன்';

  @override
  String get tourWelcomeSubtitle =>
      'உங்கள் சாதனத்திலேயே, உங்கள் கட்டுப்பாட்டில் நுண்ணறிவு';

  @override
  String get tourWelcomePrivateTitle => '100% தனிப்பட்டது, சாதனத்திலேயே';

  @override
  String get tourWelcomePrivateBody =>
      'மாடல்கள் உங்கள் கைப்பேசியிலேயே நேரடியாக இயங்குகின்றன. எந்தத் தரவும் சாதனத்தை விட்டு வெளியேறாது, இணையமும் தேவையில்லை.';

  @override
  String get tourWelcomeCatalogTitle =>
      'தேர்ந்தெடுத்த open-weight மாடல் பட்டியல்';

  @override
  String get tourWelcomeCatalogBody =>
      'Meta, Google, Microsoft, Alibaba வழங்கும் சரிபார்க்கப்பட்ட GGUF மாடல்களை ஒரே தட்டலில் பதிவிறக்கவும்.';

  @override
  String get tourWelcomeChatTitle => 'முழுமையான அரட்டை & மல்டிமோடல்';

  @override
  String get tourWelcomeChatBody =>
      'வேகமாக அரட்டையடிக்கவும், படங்களையோ ஆவணங்களையோ இணைக்கவும், உரையாடல்களை முழுக் கட்டுப்பாட்டுடன் நிர்வகிக்கவும்.';

  @override
  String get tourWelcomeStartTour => 'ஆப் அறிமுகத்தைத் தொடங்கு';

  @override
  String get tourWelcomeBrowseCatalog => 'பட்டியலைப் பார்';

  @override
  String get tourWelcomeSkipToChat => 'நேராக அரட்டைக்கு';

  @override
  String get onboardingLogoLabel => 'Thinai ஆப் லோகோ';

  @override
  String get onboardingPrivateTag => '100% தனிப்பட்டது & ஆஃப்லைன்';

  @override
  String get onboardingPrivateHeadline =>
      'உண்மையான நுண்ணறிவு,\nமுழுக்க உங்கள் கைப்பேசியில்';

  @override
  String get onboardingPrivateBody =>
      'Thinai பெரிய AI மாடல்களை உங்கள் கைப்பேசியிலேயே நேரடியாக இயக்குகிறது. எந்தத் தரவும் வெளியே போவதில்லை, கண்காணிப்பு இல்லை, கிளவுட் சார்பும் இல்லை.';

  @override
  String get onboardingPrivateGraphic => '100% தனிப்பட்ட, ஆஃப்லைன் AI';

  @override
  String get onboardingPrivateBullet1 =>
      'உங்கள் சாதனத்தின் RAM அல்லது சேமிப்பகத்தை விட்டு எந்தத் தரவும் வெளியேறாது';

  @override
  String get onboardingPrivateBullet2 =>
      'ஆஃப்லைனிலும் விமானப் பயன்முறையிலும் முழுமையாக இயங்கும்';

  @override
  String get onboardingCatalogTag => 'சரிபார்க்கப்பட்ட GGUF பட்டியல்';

  @override
  String get onboardingCatalogHeadline =>
      'சிறந்த open-weight மாடல்கள்\nஒரே தட்டலில்';

  @override
  String get onboardingCatalogBody =>
      'அதிநவீன open மாடல்களை Hugging Face-இலிருந்து நேரடியாகப் பதிவிறக்கவும். கைப்பேசியில் சீராக இயங்கும்படி நுட்பமாக quantize செய்யப்பட்டவை.';

  @override
  String get onboardingCatalogGraphic => 'தேர்ந்தெடுத்த GGUF மாடல் பட்டியல்';

  @override
  String get onboardingCatalogBullet1 =>
      'DeepSeek, Meta Llama, Google Gemma & Qwen';

  @override
  String get onboardingCatalogBullet2 =>
      'பின்னணியிலும் பதிவிறக்கம் தானாகத் தொடரும்';

  @override
  String get onboardingGpuTag => 'வன்பொருள் வேகமூட்டல்';

  @override
  String get onboardingGpuHeadline =>
      'Llama.cpp இயந்திரம்\nAdreno & Mali GPU உடன்';

  @override
  String get onboardingGpuBody =>
      'ARM64-க்காக compile செய்யப்பட்ட native llama.cpp-இல் உருவானது; Qualcomm Adreno OpenCL, ARM Mali Vulkan வழியாக GPU-க்கு layer-களை மாற்றி இயக்குகிறது.';

  @override
  String get onboardingGpuGraphic => 'GPU வன்பொருள் வேகமூட்டல் ராக்கெட்';

  @override
  String get onboardingGpuBullet1 => 'உடனடிப் பதிலுக்கு GPU வேகமூட்டல்';

  @override
  String get onboardingGpuBullet2 =>
      'நேரலை tokens/sec அளவீடுகள், சூடாகாமல் காக்கும் வரம்புகள்';

  @override
  String get onboardingStudioTag => 'மல்டிமோடல் ஸ்டுடியோ';

  @override
  String get onboardingStudioHeadline =>
      'படங்கள், ஆவணங்கள்\n& நேரலை இணையத் தேடல்';

  @override
  String get onboardingStudioBody =>
      'vision மாடல்களுடன் புத்திசாலித்தனமாக உரையாடுங்கள், உடனடிச் சுருக்கத்திற்கு PDF, உரைக் கோப்புகளை இணையுங்கள், தேவைப்படும்போது இணையத்தில் தேடுங்கள்.';

  @override
  String get onboardingStudioGraphic => 'படம் மற்றும் ஆவணக் கேள்வி-பதில்';

  @override
  String get onboardingStudioBullet1 =>
      'படங்களைப் புரிந்துகொள்ளும் vision மாடல்கள் (Gemma, MiniCPM)';

  @override
  String get onboardingStudioBullet2 =>
      'தனியுரிமை காக்கும் இணையத் தேடல் & ஆவணக் கேள்வி-பதில்';

  @override
  String get onboardingServerTag => 'உள்ளூர் டெவலப்பர் API';

  @override
  String get onboardingServerHeadline =>
      'உங்கள் கைப்பேசியை\nஉள்ளூர் AI சர்வராக்குங்கள்';

  @override
  String onboardingServerBody(String port) {
    return 'port $port-இல் OpenAI, Ollama-இணக்கமான REST API-ஐ இயக்குங்கள். VS Code extension-கள், Cline, Cursor அல்லது terminal ஸ்கிரிப்ட்களை எளிதாக இணைக்கலாம்.';
  }

  @override
  String onboardingServerGraphic(String port) {
    return 'port $port-இல் உள்ளூர் AI சர்வர்';
  }

  @override
  String get onboardingServerBullet1 =>
      'OpenAI SDK & Ollama CLI உடன் இணக்கமானது';

  @override
  String get onboardingServerBullet2 =>
      'உங்கள் Wi-Fi LAN-இல் உள்ள லேப்டாப்களுக்கும் பகிரலாம்';

  @override
  String get onboardingStartButton => 'இப்போதே Thinai-ஐத் தொடங்குங்கள்';

  @override
  String get splashTagline => 'உங்கள் சாதனத்திலேயே இயங்கும் நுண்ணறிவு';

  @override
  String splashCraftedIn(String place) {
    return 'உருவான இடம்: $place';
  }

  @override
  String get splashPlace => 'ஈரோடு, தமிழ்நாடு';

  @override
  String brandMadeWith(String heart, String place) {
    return '$place $heart உடன் உருவானது';
  }

  @override
  String get brandPlace => 'ஈரோடு, தமிழ்நாட்டில்';

  @override
  String get chatErrorReadFile => 'அந்தக் கோப்பைப் படிக்க முடியவில்லை.';

  @override
  String chatDocumentTrimmed(String size) {
    return 'முதல் $size இணைக்கப்பட்டது. மீதி context-இல் பொருந்தவில்லை.';
  }

  @override
  String chatErrorAttachFile(String error) {
    return 'அந்தக் கோப்பை இணைக்க முடியவில்லை: $error';
  }

  @override
  String get chatErrorNoVision =>
      'இந்த மாடலால் படங்களைப் படிக்க முடியாது. பதிலாக Gemma 3 4B-ஐ முயற்சிக்கவும்.';

  @override
  String chatErrorTakePhoto(String error) {
    return 'புகைப்படம் எடுக்க முடியவில்லை: $error';
  }

  @override
  String get chatErrorReadImage => 'அந்தப் படத்தைப் படிக்க முடியவில்லை.';

  @override
  String chatErrorAttachImage(String error) {
    return 'அந்தப் படத்தை இணைக்க முடியவில்லை: $error';
  }

  @override
  String get chatSearchBlocked =>
      'தேடுபொறிகள் இப்போது இந்த நெட்வொர்க்கைக் கட்டுப்படுத்துகின்றன. இணையம் இல்லாமல் பதிலளிக்கிறது.';

  @override
  String get chatSearchNoResults =>
      'இதற்கு இணைய முடிவுகள் இல்லை. மாடலே பதிலளிக்கிறது.';

  @override
  String chatSearchErrorFallback(String message) {
    return '$message அது இல்லாமல் பதிலளிக்கிறது.';
  }

  @override
  String get chatSearchFailed =>
      'இணையத் தேடல் தோல்வியடைந்தது. அது இல்லாமல் பதிலளிக்கிறது.';

  @override
  String get chatLoadModelFirst =>
      'முதலில் மாடல்கள் தாவலில் ஒரு மாடலை ஏற்றவும்.';

  @override
  String get chatActiveModelMissing =>
      'செயலில் உள்ள மாடல் சேமிப்பகத்தில் இல்லை.';

  @override
  String chatErrorGeneric(String error) {
    return 'பிழை: $error';
  }

  @override
  String get chatWebSearchOn => 'இணையத் தேடல் ஆன்.';

  @override
  String get chatWebSearchOff => 'இணையத் தேடல் ஆஃப்.';

  @override
  String get chatMenuTooltip => 'மெனு & அரட்டைகள்';

  @override
  String get chatBannerNoModelLoaded =>
      'மாடல் ஏற்றப்படவில்லை — தேர்ந்தெடுக்க அல்லது உலாவ தட்டவும்.';

  @override
  String get chatBannerNoModelDownloaded =>
      'மாடல் பதிவிறக்கப்படவில்லை — பதிவிறக்க தட்டவும்.';

  @override
  String get chatSelect => 'தேர்ந்தெடு';

  @override
  String chatActiveModelTooltip(String modelId) {
    return 'செயலில் உள்ள மாடல்: $modelId (மாற்ற தட்டவும்)';
  }

  @override
  String get chatNoModelTooltip =>
      'மாடல் ஏற்றப்படவில்லை (தேர்ந்தெடுக்க தட்டவும்)';

  @override
  String get chatSwitchModel => 'மாடலை மாற்று';

  @override
  String get chatNoModelsInstalled => 'மாடல்கள் எதுவும் நிறுவப்படவில்லை';

  @override
  String chatModelsInstalledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'சாதனத்தில் $count நிறுவப்பட்டுள்ளன',
      one: 'சாதனத்தில் 1 நிறுவப்பட்டுள்ளது',
    );
    return '$_temp0';
  }

  @override
  String get chatNoModelsDownloadedYet =>
      'இன்னும் மாடல்கள் பதிவிறக்கப்படவில்லை';

  @override
  String get chatDownloadFromCatalogue =>
      'அரட்டையைத் தொடங்க பட்டியலிலிருந்து ஒரு திறந்த மாடலைப் பதிவிறக்கவும்.';

  @override
  String get chatBrowseModels => 'மாடல்களை உலாவு';

  @override
  String get chatModelParameters => 'மாடல் அளவுருக்கள்';

  @override
  String get chatDownloadMoreModels => 'மேலும் மாடல்களைப் பதிவிறக்கு';

  @override
  String get chatEmptyTitle => 'தனிப்பட்ட ஆஃப்லைன் AI';

  @override
  String get chatEmptyBody =>
      'உங்கள் கைப்பேசியில் 100% இயங்கும் AI மாடல்களுடன் தனிப்பட்ட முறையில் அரட்டையடிக்கவும். இணையம் தேவையில்லை, கிளவுட் கண்காணிப்பு இல்லை, உங்கள் தரவு உங்கள் சாதனத்தை விட்டு வெளியேறாது.';

  @override
  String get chatBrowseDownloadModels => 'மாடல்களை உலாவிப் பதிவிறக்கு';

  @override
  String get chatReadyWebSearchOn => 'AI தயார் · இணையத் தேடல் ஆன்';

  @override
  String get chatReadyOffline => 'AI தயார் · 100% ஆஃப்லைன்';

  @override
  String get chatRunningPrivately =>
      'உங்கள் கைப்பேசியிலேயே தனிப்பட்ட முறையில் இயங்குகிறது.';

  @override
  String get chatStarterBrainstorm => 'யோசனைகளைச் சிந்தி';

  @override
  String get chatStarterPython => 'Python குறியீடு எழுது';

  @override
  String get chatStarterSummarize => 'உரையைச் சுருக்கு';

  @override
  String get chatStarterSpeed => 'வேகத்தை அளவிடு';

  @override
  String chatAttachmentTrimmed(String size) {
    return '$size · சுருக்கப்பட்டது';
  }

  @override
  String get chatInputHintGenerating => 'உருவாக்குகிறது…';

  @override
  String get chatInputHint => 'உங்கள் மாடலுக்குச் செய்தி அனுப்பவும்';

  @override
  String get chatStop => 'நிறுத்து';

  @override
  String get chatSend => 'அனுப்பு';

  @override
  String get chatCopiedToClipboard => 'கிளிப்போர்டுக்கு நகலெடுக்கப்பட்டது';

  @override
  String get chatCopyText => 'உரையை நகலெடு';

  @override
  String get chatShareText => 'உரையைப் பகிர்';

  @override
  String get chatStopped => 'நிறுத்தப்பட்டது';

  @override
  String get chatSearchingWeb => 'இணையத்தில் தேடுகிறது…';

  @override
  String get chatDialWebSearch => 'இணையத் தேடல்';

  @override
  String get chatDialWebSearchAuto => 'தானியங்கி, தேவைப்படும்போது ஆன்';

  @override
  String get chatDialCamera => 'கேமரா';

  @override
  String get chatDialCameraDetail => 'இப்போது புகைப்படம் எடு';

  @override
  String get chatDialNeedsVision => 'படங்களைப் படிக்கும் மாடல் தேவை';

  @override
  String get chatDialImage => 'படம்';

  @override
  String get chatDialDocument => 'ஆவணம்';

  @override
  String get chatDialDocumentDetail => 'உரை, Markdown, CSV, குறியீடு';

  @override
  String chatSourcesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ஆதாரங்கள்',
      one: 'ஆதாரம்',
    );
    return '$_temp0';
  }

  @override
  String get chatSourcesTitle => 'ஆதாரங்கள்';

  @override
  String chatSearchedQuery(String query) {
    return 'தேடியது: \"$query\"';
  }

  @override
  String get chatRemoveAttachment => 'அகற்று';

  @override
  String get chatAttachImageUnsupported =>
      'அந்தப் பட வடிவம் ஆதரிக்கப்படவில்லை. PNG, JPEG, WebP, BMP அல்லது GIF பயன்படுத்தவும்.';

  @override
  String get chatAttachImageEmpty => 'அந்தப் படம் காலியாக உள்ளது.';

  @override
  String chatAttachImageTooLarge(String size, int limit) {
    return 'அந்தப் படம் $size MB. $limit MB வரையிலான படங்களை மட்டுமே இணைக்க முடியும்.';
  }

  @override
  String get chatAttachPdfUnsupported =>
      'PDF இன்னும் ஆதரிக்கப்படவில்லை. உரையை நகலெடுத்து அதை இணைக்கவும்.';

  @override
  String chatAttachBinaryUnsupported(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'image': 'பட',
      'audio': 'ஆடியோ',
      'other': '$kind',
    });
    return '$_temp0 கோப்புகள் ஆதரிக்கப்படவில்லை. உரை ஆவணத்தை இணைக்கவும்.';
  }

  @override
  String get chatAttachFileEmpty => 'அந்தக் கோப்பு காலியாக உள்ளது.';

  @override
  String get chatAttachBinaryFile =>
      'இது உரை ஆவணம் அல்ல, பைனரி கோப்பு போலத் தெரிகிறது.';

  @override
  String get chatAttachNotUtf8 =>
      'அந்தக் கோப்பை உரையாகப் படிக்க முடியவில்லை. UTF-8 ஆவணங்கள் மட்டுமே.';

  @override
  String get chatAttachNoText => 'அந்தக் கோப்பில் உரை எதுவும் இல்லை.';

  @override
  String get chatDrawerExitManage => 'நிர்வாக முறையிலிருந்து வெளியேறு';

  @override
  String get chatDrawerManageChats => 'அரட்டைகளை நிர்வகி';

  @override
  String get chatDrawerTapToSelect => 'தேர்ந்தெடுக்க தட்டவும்';

  @override
  String chatDrawerSelectedCount(int selected, int total) {
    return '$total-இல் $selected தேர்ந்தெடுக்கப்பட்டன';
  }

  @override
  String get chatDrawerDeselectAll => 'தேர்வை நீக்கு';

  @override
  String get chatDrawerSelectAll => 'அனைத்தையும் தேர்ந்தெடு';

  @override
  String get chatDrawerCloseMenu => 'மெனுவை மூடு';

  @override
  String get chatNewChat => 'புதிய அரட்டை';

  @override
  String get chatDrawerSearchHint => 'அரட்டைகளைத் தேடு…';

  @override
  String chatDrawerDeleteCount(int count) {
    return 'நீக்கு ($count)';
  }

  @override
  String chatDrawerConversationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count உரையாடல்கள்',
      one: '1 உரையாடல்',
    );
    return '$_temp0';
  }

  @override
  String get chatDrawerModelSettings => 'மாடல் அமைப்புகள்';

  @override
  String get chatDrawerModelSettingsSubtitle => 'context, sampling & சிந்தனை';

  @override
  String get chatDrawerNoModelSnack =>
      'இன்னும் மாடல் பதிவிறக்கப்படவில்லை. முதலில் மாடல்கள் தாவலிலிருந்து ஒரு மாடலைப் பதிவிறக்கவும்.';

  @override
  String get chatDrawerAppSettings => 'ஆப் அமைப்புகள்';

  @override
  String get chatDrawerAppSettingsSubtitle =>
      'தீம், GPU, பதிவிறக்கங்கள் & சர்வர்';

  @override
  String get chatDrawerAbout => 'Thinai பற்றி';

  @override
  String get chatDrawerAboutSubtitle => 'பதிப்பு, தனியுரிமை & விவரங்கள்';

  @override
  String chatDrawerDeleteManyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count அரட்டைகளை நீக்கவா?',
      one: '1 அரட்டையை நீக்கவா?',
    );
    return '$_temp0';
  }

  @override
  String chatDrawerDeleteManyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'தேர்ந்தெடுத்த $count உரையாடல்களை நிரந்தரமாக நீக்க விரும்புகிறீர்களா? இதைத் திரும்பப் பெற முடியாது.',
      one:
          'தேர்ந்தெடுத்த 1 உரையாடலை நிரந்தரமாக நீக்க விரும்புகிறீர்களா? இதைத் திரும்பப் பெற முடியாது.',
    );
    return '$_temp0';
  }

  @override
  String chatDrawerDeletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count அரட்டைகள் நீக்கப்பட்டன',
      one: '1 அரட்டை நீக்கப்பட்டது',
    );
    return '$_temp0';
  }

  @override
  String get chatDrawerSelectManage => 'தேர்ந்தெடு / நிர்வகி';

  @override
  String get chatDrawerRenameTitle => 'தலைப்பை மாற்று';

  @override
  String get chatDeleteChat => 'அரட்டையை நீக்கு';

  @override
  String get chatRenameChat => 'அரட்டையின் பெயரை மாற்று';

  @override
  String get chatConversationTitleHint => 'உரையாடல் தலைப்பு';

  @override
  String get chatDrawerDeleteOneTitle => 'அரட்டையை நீக்கவா?';

  @override
  String chatDrawerDeleteOneBody(String title) {
    return '\"$title\"-ஐ நீக்க விரும்புகிறீர்களா? இதைத் திரும்பப் பெற முடியாது.';
  }

  @override
  String get chatDrawerNoHistory => 'முந்தைய உரையாடல்கள் இல்லை';

  @override
  String get chatDrawerNoHistoryHint =>
      'வரலாற்றை இங்கே வைத்திருக்க ஒரு அரட்டையைத் தொடங்கவும்.';

  @override
  String chatDrawerNoResults(String query) {
    return '\"$query\"-க்கு அரட்டைகள் எதுவும் இல்லை';
  }

  @override
  String get chatGroupToday => 'இன்று';

  @override
  String get chatGroupYesterday => 'நேற்று';

  @override
  String get chatGroupPrevious7Days => 'கடந்த 7 நாட்கள்';

  @override
  String get chatGroupThisMonth => 'இந்த மாதம்';

  @override
  String get chatGroupOlder => 'பழையவை';

  @override
  String get chatHistoryTitle => 'அரட்டை வரலாறு';

  @override
  String get chatHistoryDeleteAllTooltip => 'அனைத்து அரட்டைகளையும் நீக்கு';

  @override
  String get chatHistoryDeleteAllTitle => 'அனைத்து அரட்டைகளையும் நீக்கவா?';

  @override
  String get chatHistoryDeleteAllBody =>
      'சேமிக்கப்பட்ட அனைத்து உரையாடல்களும் நீக்கப்படும். இதைத் திரும்பப் பெற முடியாது.';

  @override
  String get chatHistoryDeleteAll => 'அனைத்தையும் நீக்கு';

  @override
  String get chatHistoryDeleteOneTitle => 'இந்த அரட்டையை நீக்கவா?';

  @override
  String get chatHistorySearchHint => 'உரையாடல்களைத் தேடு…';

  @override
  String chatHistoryNoResults(String query) {
    return '\"$query\"-உடன் பொருந்தும் அரட்டைகள் இல்லை';
  }

  @override
  String get chatHistoryActiveBadge => 'செயலில்';

  @override
  String chatHistoryMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count செய்திகள்',
      one: '1 செய்தி',
    );
    return '$_temp0';
  }

  @override
  String get chatHistoryEmptyTitle => 'இன்னும் சேமிக்கப்பட்ட அரட்டைகள் இல்லை';

  @override
  String get chatHistoryEmptyBody =>
      'ஒரு உரையாடலைத் தொடங்கினால் அது இங்கே தோன்றும்.\nஅனைத்தும் இந்தச் சாதனத்திலேயே இருக்கும்.';

  @override
  String get chatTimeJustNow => 'இப்போது';

  @override
  String chatTimeMinutesAgo(int minutes) {
    return '$minutes நிமி. முன்';
  }

  @override
  String chatTimeHoursAgo(int hours) {
    return '$hours மணி. முன்';
  }

  @override
  String chatTimeDaysAgo(int days) {
    return '$days நாட்களுக்கு முன்';
  }

  @override
  String get chatCodeBlockLabel => 'குறியீடு';

  @override
  String get chatCodeCopied => 'நகலெடுக்கப்பட்டது!';

  @override
  String get chatAppRestartTitle => 'இப்போது மறுதொடக்கம் செய்யவா?';

  @override
  String get chatAppRestartBody =>
      'ஒரு மாடல் இன்னும் பதிவிறக்குகிறது. மறுதொடக்கம் செய்தால் அது இடைநிறுத்தப்படும்; மாடல்கள் பக்கத்திலிருந்து அதைத் தொடரலாம்.';

  @override
  String get chatAppRestart => 'மறுதொடக்கம்';

  @override
  String get chatAppUpdateReady => 'புதுப்பிப்பு தயார்';

  @override
  String get chatAppUpdateAvailable => 'புதுப்பிப்பு கிடைக்கிறது';

  @override
  String get chatAppUpdateDownloading => 'பின்னணியில் பதிவிறக்குகிறது…';

  @override
  String get chatAppUpdateRestartToInstall =>
      'நிறுவலை முடிக்க Thinai-ஐ மறுதொடக்கம் செய்யவும்.';

  @override
  String get chatAppUpdateOnPlayStore =>
      'Thinai-இன் புதிய பதிப்பு Play Store-இல் உள்ளது.';

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
