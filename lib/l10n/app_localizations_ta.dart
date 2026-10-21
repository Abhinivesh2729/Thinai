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
}
