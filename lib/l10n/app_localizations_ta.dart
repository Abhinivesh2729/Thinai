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
}
