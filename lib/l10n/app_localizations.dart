import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
  ];

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get languageTamil;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get commonCopied;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get commonDownload;

  /// No description provided for @commonResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get commonResume;

  /// No description provided for @commonDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get commonLater;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get commonRename;

  /// No description provided for @commonOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get commonOn;

  /// No description provided for @commonOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get commonOff;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navModels.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get navModels;

  /// No description provided for @navServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get navServer;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @chatErrorReadFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read that file.'**
  String get chatErrorReadFile;

  /// Snack bar after a long document was cut to fit. size is like ~1.2K tokens.
  ///
  /// In en, this message translates to:
  /// **'Attached the first {size}. The rest did not fit the context window.'**
  String chatDocumentTrimmed(String size);

  /// No description provided for @chatErrorAttachFile.
  ///
  /// In en, this message translates to:
  /// **'Could not attach that file: {error}'**
  String chatErrorAttachFile(String error);

  /// No description provided for @chatErrorNoVision.
  ///
  /// In en, this message translates to:
  /// **'This model cannot read images. Try Gemma 3 4B instead.'**
  String get chatErrorNoVision;

  /// No description provided for @chatErrorTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not take that photo: {error}'**
  String chatErrorTakePhoto(String error);

  /// No description provided for @chatErrorReadImage.
  ///
  /// In en, this message translates to:
  /// **'Could not read that image.'**
  String get chatErrorReadImage;

  /// No description provided for @chatErrorAttachImage.
  ///
  /// In en, this message translates to:
  /// **'Could not attach that image: {error}'**
  String chatErrorAttachImage(String error);

  /// No description provided for @chatSearchBlocked.
  ///
  /// In en, this message translates to:
  /// **'Search engines are rate-limiting this network right now. Answering without the web.'**
  String get chatSearchBlocked;

  /// No description provided for @chatSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No web results for that. Answering from the model itself.'**
  String get chatSearchNoResults;

  /// message is the web search error, which is not localized.
  ///
  /// In en, this message translates to:
  /// **'{message} Answering without it.'**
  String chatSearchErrorFallback(String message);

  /// No description provided for @chatSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Web search failed. Answering without it.'**
  String get chatSearchFailed;

  /// No description provided for @chatLoadModelFirst.
  ///
  /// In en, this message translates to:
  /// **'Load a model from the Models tab first.'**
  String get chatLoadModelFirst;

  /// No description provided for @chatActiveModelMissing.
  ///
  /// In en, this message translates to:
  /// **'Active model is missing from disk.'**
  String get chatActiveModelMissing;

  /// No description provided for @chatErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String chatErrorGeneric(String error);

  /// No description provided for @chatWebSearchOn.
  ///
  /// In en, this message translates to:
  /// **'Web search on.'**
  String get chatWebSearchOn;

  /// No description provided for @chatWebSearchOff.
  ///
  /// In en, this message translates to:
  /// **'Web search off.'**
  String get chatWebSearchOff;

  /// No description provided for @chatMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Menu & Chats'**
  String get chatMenuTooltip;

  /// No description provided for @chatBannerNoModelLoaded.
  ///
  /// In en, this message translates to:
  /// **'No model loaded — tap to select or browse.'**
  String get chatBannerNoModelLoaded;

  /// No description provided for @chatBannerNoModelDownloaded.
  ///
  /// In en, this message translates to:
  /// **'No model downloaded — tap to download.'**
  String get chatBannerNoModelDownloaded;

  /// No description provided for @chatSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get chatSelect;

  /// No description provided for @chatActiveModelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Active model: {modelId} (tap to switch)'**
  String chatActiveModelTooltip(String modelId);

  /// No description provided for @chatNoModelTooltip.
  ///
  /// In en, this message translates to:
  /// **'No model loaded (tap to choose)'**
  String get chatNoModelTooltip;

  /// No description provided for @chatSwitchModel.
  ///
  /// In en, this message translates to:
  /// **'Switch Model'**
  String get chatSwitchModel;

  /// No description provided for @chatNoModelsInstalled.
  ///
  /// In en, this message translates to:
  /// **'No models installed'**
  String get chatNoModelsInstalled;

  /// No description provided for @chatModelsInstalledCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} installed on device}}'**
  String chatModelsInstalledCount(int count);

  /// No description provided for @chatNoModelsDownloadedYet.
  ///
  /// In en, this message translates to:
  /// **'No models downloaded yet'**
  String get chatNoModelsDownloadedYet;

  /// No description provided for @chatDownloadFromCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Download an open model from the catalogue to begin chatting.'**
  String get chatDownloadFromCatalogue;

  /// No description provided for @chatBrowseModels.
  ///
  /// In en, this message translates to:
  /// **'Browse Models'**
  String get chatBrowseModels;

  /// No description provided for @chatModelParameters.
  ///
  /// In en, this message translates to:
  /// **'Model Parameters'**
  String get chatModelParameters;

  /// No description provided for @chatDownloadMoreModels.
  ///
  /// In en, this message translates to:
  /// **'Download More Models'**
  String get chatDownloadMoreModels;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Private Offline AI'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Chat privately with AI models that run 100% on your phone. No internet required, zero cloud tracking, and your data never leaves your device.'**
  String get chatEmptyBody;

  /// No description provided for @chatBrowseDownloadModels.
  ///
  /// In en, this message translates to:
  /// **'Browse & Download Models'**
  String get chatBrowseDownloadModels;

  /// No description provided for @chatReadyWebSearchOn.
  ///
  /// In en, this message translates to:
  /// **'AI Ready · Web Search On'**
  String get chatReadyWebSearchOn;

  /// No description provided for @chatReadyOffline.
  ///
  /// In en, this message translates to:
  /// **'AI Ready · 100% Offline'**
  String get chatReadyOffline;

  /// No description provided for @chatRunningPrivately.
  ///
  /// In en, this message translates to:
  /// **'Running privately on your phone silicon.'**
  String get chatRunningPrivately;

  /// Starter chip label. The prompt it inserts stays English.
  ///
  /// In en, this message translates to:
  /// **'Brainstorm ideas'**
  String get chatStarterBrainstorm;

  /// No description provided for @chatStarterPython.
  ///
  /// In en, this message translates to:
  /// **'Write Python code'**
  String get chatStarterPython;

  /// No description provided for @chatStarterSummarize.
  ///
  /// In en, this message translates to:
  /// **'Summarize text'**
  String get chatStarterSummarize;

  /// No description provided for @chatStarterSpeed.
  ///
  /// In en, this message translates to:
  /// **'Measure speed'**
  String get chatStarterSpeed;

  /// No description provided for @chatAttachmentTrimmed.
  ///
  /// In en, this message translates to:
  /// **'{size} · trimmed'**
  String chatAttachmentTrimmed(String size);

  /// No description provided for @chatInputHintGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get chatInputHintGenerating;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Message your model'**
  String get chatInputHint;

  /// No description provided for @chatStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get chatStop;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get chatCopiedToClipboard;

  /// No description provided for @chatCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get chatCopyText;

  /// No description provided for @chatShareText.
  ///
  /// In en, this message translates to:
  /// **'Share text'**
  String get chatShareText;

  /// No description provided for @chatStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get chatStopped;

  /// No description provided for @chatSearchingWeb.
  ///
  /// In en, this message translates to:
  /// **'Searching the web…'**
  String get chatSearchingWeb;

  /// No description provided for @chatDialWebSearch.
  ///
  /// In en, this message translates to:
  /// **'Web search'**
  String get chatDialWebSearch;

  /// No description provided for @chatDialWebSearchAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic, on when needed'**
  String get chatDialWebSearchAuto;

  /// No description provided for @chatDialCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get chatDialCamera;

  /// No description provided for @chatDialCameraDetail.
  ///
  /// In en, this message translates to:
  /// **'Take a photo now'**
  String get chatDialCameraDetail;

  /// No description provided for @chatDialNeedsVision.
  ///
  /// In en, this message translates to:
  /// **'Needs a vision model'**
  String get chatDialNeedsVision;

  /// No description provided for @chatDialImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get chatDialImage;

  /// No description provided for @chatDialDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get chatDialDocument;

  /// No description provided for @chatDialDocumentDetail.
  ///
  /// In en, this message translates to:
  /// **'Text, Markdown, CSV, code'**
  String get chatDialDocumentDetail;

  /// Label beside the source badges under a searched reply.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Source} other{Sources}}'**
  String chatSourcesCount(int count);

  /// No description provided for @chatSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get chatSourcesTitle;

  /// No description provided for @chatSearchedQuery.
  ///
  /// In en, this message translates to:
  /// **'Searched: \"{query}\"'**
  String chatSearchedQuery(String query);

  /// No description provided for @chatRemoveAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get chatRemoveAttachment;

  /// No description provided for @chatAttachImageUnsupported.
  ///
  /// In en, this message translates to:
  /// **'That image format is not supported. Use PNG, JPEG, WebP, BMP or GIF.'**
  String get chatAttachImageUnsupported;

  /// No description provided for @chatAttachImageEmpty.
  ///
  /// In en, this message translates to:
  /// **'That image is empty.'**
  String get chatAttachImageEmpty;

  /// No description provided for @chatAttachImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That image is {size} MB. Images up to {limit} MB can be attached.'**
  String chatAttachImageTooLarge(String size, int limit);

  /// No description provided for @chatAttachPdfUnsupported.
  ///
  /// In en, this message translates to:
  /// **'PDF is not supported yet. Copy the text and attach that instead.'**
  String get chatAttachPdfUnsupported;

  /// kind is a format name such as Word, PowerPoint, Excel, EPUB, or the words image/audio.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, image{image} audio{audio} other{{kind}}} files are not supported. Attach a text document.'**
  String chatAttachBinaryUnsupported(String kind);

  /// No description provided for @chatAttachFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'That file is empty.'**
  String get chatAttachFileEmpty;

  /// No description provided for @chatAttachBinaryFile.
  ///
  /// In en, this message translates to:
  /// **'That looks like a binary file, not a text document.'**
  String get chatAttachBinaryFile;

  /// No description provided for @chatAttachNotUtf8.
  ///
  /// In en, this message translates to:
  /// **'Could not read that file as text. UTF-8 documents only.'**
  String get chatAttachNotUtf8;

  /// No description provided for @chatAttachNoText.
  ///
  /// In en, this message translates to:
  /// **'That file has no text in it.'**
  String get chatAttachNoText;

  /// No description provided for @chatDrawerExitManage.
  ///
  /// In en, this message translates to:
  /// **'Exit manage mode'**
  String get chatDrawerExitManage;

  /// No description provided for @chatDrawerManageChats.
  ///
  /// In en, this message translates to:
  /// **'Manage chats'**
  String get chatDrawerManageChats;

  /// No description provided for @chatDrawerTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get chatDrawerTapToSelect;

  /// No description provided for @chatDrawerSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} selected'**
  String chatDrawerSelectedCount(int selected, int total);

  /// No description provided for @chatDrawerDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get chatDrawerDeselectAll;

  /// No description provided for @chatDrawerSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get chatDrawerSelectAll;

  /// No description provided for @chatDrawerCloseMenu.
  ///
  /// In en, this message translates to:
  /// **'Close menu'**
  String get chatDrawerCloseMenu;

  /// No description provided for @chatNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get chatNewChat;

  /// No description provided for @chatDrawerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search chats…'**
  String get chatDrawerSearchHint;

  /// No description provided for @chatDrawerDeleteCount.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String chatDrawerDeleteCount(int count);

  /// No description provided for @chatDrawerConversationCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 conversation} other{{count} conversations}}'**
  String chatDrawerConversationCount(int count);

  /// No description provided for @chatDrawerModelSettings.
  ///
  /// In en, this message translates to:
  /// **'Model Settings'**
  String get chatDrawerModelSettings;

  /// No description provided for @chatDrawerModelSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Context, sampling & thinking'**
  String get chatDrawerModelSettingsSubtitle;

  /// No description provided for @chatDrawerNoModelSnack.
  ///
  /// In en, this message translates to:
  /// **'No model downloaded yet. Download a model from the Models tab first.'**
  String get chatDrawerNoModelSnack;

  /// No description provided for @chatDrawerAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get chatDrawerAppSettings;

  /// No description provided for @chatDrawerAppSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, GPU, downloads & server'**
  String get chatDrawerAppSettingsSubtitle;

  /// No description provided for @chatDrawerAbout.
  ///
  /// In en, this message translates to:
  /// **'About Thinai'**
  String get chatDrawerAbout;

  /// No description provided for @chatDrawerAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, privacy & details'**
  String get chatDrawerAboutSubtitle;

  /// No description provided for @chatDrawerDeleteManyTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 chat?} other{Delete {count} chats?}}'**
  String chatDrawerDeleteManyTitle(int count);

  /// No description provided for @chatDrawerDeleteManyBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Are you sure you want to permanently delete 1 selected conversation? This action cannot be undone.} other{Are you sure you want to permanently delete {count} selected conversations? This action cannot be undone.}}'**
  String chatDrawerDeleteManyBody(int count);

  /// No description provided for @chatDrawerDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 chat} other{Deleted {count} chats}}'**
  String chatDrawerDeletedCount(int count);

  /// No description provided for @chatDrawerSelectManage.
  ///
  /// In en, this message translates to:
  /// **'Select / Manage'**
  String get chatDrawerSelectManage;

  /// No description provided for @chatDrawerRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename title'**
  String get chatDrawerRenameTitle;

  /// No description provided for @chatDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get chatDeleteChat;

  /// No description provided for @chatRenameChat.
  ///
  /// In en, this message translates to:
  /// **'Rename chat'**
  String get chatRenameChat;

  /// No description provided for @chatConversationTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Conversation title'**
  String get chatConversationTitleHint;

  /// No description provided for @chatDrawerDeleteOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete chat?'**
  String get chatDrawerDeleteOneTitle;

  /// No description provided for @chatDrawerDeleteOneBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This cannot be undone.'**
  String chatDrawerDeleteOneBody(String title);

  /// No description provided for @chatDrawerNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No past conversations'**
  String get chatDrawerNoHistory;

  /// No description provided for @chatDrawerNoHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Start a chat to keep history here.'**
  String get chatDrawerNoHistoryHint;

  /// No description provided for @chatDrawerNoResults.
  ///
  /// In en, this message translates to:
  /// **'No chats found for \"{query}\"'**
  String chatDrawerNoResults(String query);

  /// No description provided for @chatGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatGroupToday;

  /// No description provided for @chatGroupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatGroupYesterday;

  /// No description provided for @chatGroupPrevious7Days.
  ///
  /// In en, this message translates to:
  /// **'Previous 7 Days'**
  String get chatGroupPrevious7Days;

  /// No description provided for @chatGroupThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get chatGroupThisMonth;

  /// No description provided for @chatGroupOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get chatGroupOlder;

  /// No description provided for @chatHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get chatHistoryTitle;

  /// No description provided for @chatHistoryDeleteAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete all chats'**
  String get chatHistoryDeleteAllTooltip;

  /// No description provided for @chatHistoryDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all chats?'**
  String get chatHistoryDeleteAllTitle;

  /// No description provided for @chatHistoryDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'Every saved conversation is removed. This cannot be undone.'**
  String get chatHistoryDeleteAllBody;

  /// No description provided for @chatHistoryDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get chatHistoryDeleteAll;

  /// No description provided for @chatHistoryDeleteOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat?'**
  String get chatHistoryDeleteOneTitle;

  /// No description provided for @chatHistorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search conversations…'**
  String get chatHistorySearchHint;

  /// No description provided for @chatHistoryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No chats matching \"{query}\"'**
  String chatHistoryNoResults(String query);

  /// No description provided for @chatHistoryActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get chatHistoryActiveBadge;

  /// No description provided for @chatHistoryMessageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message} other{{count} messages}}'**
  String chatHistoryMessageCount(int count);

  /// No description provided for @chatHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved chats yet'**
  String get chatHistoryEmptyTitle;

  /// No description provided for @chatHistoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation and it will appear here.\nEverything stays on this device.'**
  String get chatHistoryEmptyBody;

  /// No description provided for @chatTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get chatTimeJustNow;

  /// No description provided for @chatTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String chatTimeMinutesAgo(int minutes);

  /// No description provided for @chatTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String chatTimeHoursAgo(int hours);

  /// Only used for 2 to 6 days.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String chatTimeDaysAgo(int days);

  /// Header of a code block whose language is unknown.
  ///
  /// In en, this message translates to:
  /// **'CODE'**
  String get chatCodeBlockLabel;

  /// No description provided for @chatCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get chatCodeCopied;

  /// No description provided for @chatAppRestartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart now?'**
  String get chatAppRestartTitle;

  /// No description provided for @chatAppRestartBody.
  ///
  /// In en, this message translates to:
  /// **'A model is still downloading. Restarting pauses it, and you can resume it from the Models page.'**
  String get chatAppRestartBody;

  /// No description provided for @chatAppRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get chatAppRestart;

  /// No description provided for @chatAppUpdateReady.
  ///
  /// In en, this message translates to:
  /// **'Update ready'**
  String get chatAppUpdateReady;

  /// No description provided for @chatAppUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get chatAppUpdateAvailable;

  /// No description provided for @chatAppUpdateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading in the background…'**
  String get chatAppUpdateDownloading;

  /// No description provided for @chatAppUpdateRestartToInstall.
  ///
  /// In en, this message translates to:
  /// **'Restart Thinai to finish installing.'**
  String get chatAppUpdateRestartToInstall;

  /// No description provided for @chatAppUpdateOnPlayStore.
  ///
  /// In en, this message translates to:
  /// **'A newer version of Thinai is on Play Store.'**
  String get chatAppUpdateOnPlayStore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
