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
}
