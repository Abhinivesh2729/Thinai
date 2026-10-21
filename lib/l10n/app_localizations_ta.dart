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
}
