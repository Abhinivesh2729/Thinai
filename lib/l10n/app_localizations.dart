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

  /// No description provided for @modelsToastDownloadPaused.
  ///
  /// In en, this message translates to:
  /// **'Download paused. Tap Resume to continue.'**
  String get modelsToastDownloadPaused;

  /// No description provided for @modelsToastDownloadStopped.
  ///
  /// In en, this message translates to:
  /// **'Download of {model} stopped: {error}. Progress is saved, tap Resume to continue.'**
  String modelsToastDownloadStopped(String model, String error);

  /// No description provided for @modelsToastDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download {model}: {error}'**
  String modelsToastDownloadFailed(String model, String error);

  /// No description provided for @modelsToastDownloadedAndLoaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded and loaded {model}'**
  String modelsToastDownloadedAndLoaded(String model);

  /// No description provided for @modelsToastDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {model}'**
  String modelsToastDownloaded(String model);

  /// No description provided for @modelsToastLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded {model}'**
  String modelsToastLoaded(String model);

  /// No description provided for @modelsToastResumeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resume {model}'**
  String modelsToastResumeFailed(String model);

  /// No description provided for @modelsConfirmDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download model?'**
  String get modelsConfirmDownloadTitle;

  /// No description provided for @modelsConfirmDownloadMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to download {model} ({size})?'**
  String modelsConfirmDownloadMessage(String model, String size);

  /// No description provided for @modelsConfirmDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard download?'**
  String get modelsConfirmDiscardTitle;

  /// No description provided for @modelsConfirmDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to discard the paused download of {model}? The {size} saved so far will be deleted.'**
  String modelsConfirmDiscardMessage(String model, String size);

  /// No description provided for @modelsDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get modelsDiscard;

  /// No description provided for @modelsConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete model?'**
  String get modelsConfirmDeleteTitle;

  /// No description provided for @modelsConfirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete {model}? This frees {size} of space.'**
  String modelsConfirmDeleteMessage(String model, String size);

  /// No description provided for @modelsBenchmark.
  ///
  /// In en, this message translates to:
  /// **'Benchmark'**
  String get modelsBenchmark;

  /// No description provided for @modelsManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Model Manager'**
  String get modelsManagerTitle;

  /// No description provided for @modelsManagerTooltipDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading ({count}) · Model Manager'**
  String modelsManagerTooltipDownloading(int count);

  /// No description provided for @modelsManagerTooltipInstalled.
  ///
  /// In en, this message translates to:
  /// **'Model Manager ({count} installed)'**
  String modelsManagerTooltipInstalled(int count);

  /// No description provided for @modelsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String modelsError(String error);

  /// No description provided for @modelsNoneInstalledYet.
  ///
  /// In en, this message translates to:
  /// **'No models installed yet'**
  String get modelsNoneInstalledYet;

  /// No description provided for @modelsNoneInstalledYetBody.
  ///
  /// In en, this message translates to:
  /// **'Browse and download GGUF models from the catalog to run offline on this device.'**
  String get modelsNoneInstalledYetBody;

  /// No description provided for @modelsBrowseCatalog.
  ///
  /// In en, this message translates to:
  /// **'Browse Catalog'**
  String get modelsBrowseCatalog;

  /// No description provided for @modelsInstalledSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Installed models ({count})'**
  String modelsInstalledSectionTitle(int count);

  /// No description provided for @modelsInstalledSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap a model to load it for chat'**
  String get modelsInstalledSectionSubtitle;

  /// No description provided for @modelsRecommendedFor.
  ///
  /// In en, this message translates to:
  /// **'Recommended for {goal}'**
  String modelsRecommendedFor(String goal);

  /// No description provided for @modelsRecommendedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optimal weights selected for your device specs'**
  String get modelsRecommendedSubtitle;

  /// No description provided for @modelsFeaturedTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured Models'**
  String get modelsFeaturedTitle;

  /// No description provided for @modelsFeaturedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Handpicked for you'**
  String get modelsFeaturedSubtitle;

  /// No description provided for @modelsOtherModels.
  ///
  /// In en, this message translates to:
  /// **'Other models'**
  String get modelsOtherModels;

  /// No description provided for @modelsVisionModelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vision models'**
  String get modelsVisionModelsTitle;

  /// No description provided for @modelsChatModelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat models'**
  String get modelsChatModelsTitle;

  /// No description provided for @modelsExploreModels.
  ///
  /// In en, this message translates to:
  /// **'Explore Models'**
  String get modelsExploreModels;

  /// No description provided for @modelsBrowseCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse catalog'**
  String get modelsBrowseCatalogTitle;

  /// No description provided for @modelsOtherModelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All other available models'**
  String get modelsOtherModelsSubtitle;

  /// No description provided for @modelsVisionModelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Multimodal · image & visual analysis'**
  String get modelsVisionModelsSubtitle;

  /// No description provided for @modelsCatalogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Curated GGUF models · one-tap download'**
  String get modelsCatalogSubtitle;

  /// No description provided for @modelsEmbeddingTitle.
  ///
  /// In en, this message translates to:
  /// **'Embedding models'**
  String get modelsEmbeddingTitle;

  /// No description provided for @modelsEmbeddingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For search and RAG · /api/embed · /v1/embeddings'**
  String get modelsEmbeddingSubtitle;

  /// No description provided for @modelsOfflineFooter.
  ///
  /// In en, this message translates to:
  /// **'Downloaded models stay 100% on-device and run entirely offline.'**
  String get modelsOfflineFooter;

  /// No description provided for @modelsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search models, makers, architectures…'**
  String get modelsSearchHint;

  /// No description provided for @modelsClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get modelsClearSearch;

  /// No description provided for @modelsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All Models'**
  String get modelsFilterAll;

  /// No description provided for @modelsFilterChat.
  ///
  /// In en, this message translates to:
  /// **'Chat Models'**
  String get modelsFilterChat;

  /// No description provided for @modelsFilterVision.
  ///
  /// In en, this message translates to:
  /// **'Vision Models'**
  String get modelsFilterVision;

  /// No description provided for @modelsFilterEmbedding.
  ///
  /// In en, this message translates to:
  /// **'Embedding'**
  String get modelsFilterEmbedding;

  /// No description provided for @modelsFilterInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get modelsFilterInstalled;

  /// No description provided for @modelsFilterInstalledCount.
  ///
  /// In en, this message translates to:
  /// **'Installed ({count})'**
  String modelsFilterInstalledCount(int count);

  /// No description provided for @modelsFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter Category'**
  String get modelsFilterCategory;

  /// No description provided for @modelsGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get modelsGoals;

  /// No description provided for @modelsResetFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset filters and search'**
  String get modelsResetFiltersTooltip;

  /// No description provided for @modelsTargeting.
  ///
  /// In en, this message translates to:
  /// **'Targeting: {goal}'**
  String modelsTargeting(String goal);

  /// No description provided for @modelsChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get modelsChange;

  /// No description provided for @modelsClearGoal.
  ///
  /// In en, this message translates to:
  /// **'Clear goal'**
  String get modelsClearGoal;

  /// No description provided for @modelsManagerSubtitleDownloading.
  ///
  /// In en, this message translates to:
  /// **'{installed} installed · {downloading} downloading · {size} used'**
  String modelsManagerSubtitleDownloading(
    int installed,
    int downloading,
    String size,
  );

  /// No description provided for @modelsManagerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} models · {size} storage used'**
  String modelsManagerSubtitle(int count, String size);

  /// No description provided for @modelsNoneInstalled.
  ///
  /// In en, this message translates to:
  /// **'No models installed'**
  String get modelsNoneInstalled;

  /// No description provided for @modelsNoneInstalledBody.
  ///
  /// In en, this message translates to:
  /// **'Download models from the catalog to run offline chat.'**
  String get modelsNoneInstalledBody;

  /// No description provided for @modelsActiveForChat.
  ///
  /// In en, this message translates to:
  /// **'Active for Chat: {model}'**
  String modelsActiveForChat(String model);

  /// No description provided for @modelsNoModelLoaded.
  ///
  /// In en, this message translates to:
  /// **'No model loaded in Chat'**
  String get modelsNoModelLoaded;

  /// No description provided for @modelsInstalledAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Installed models will appear here after download completes.'**
  String get modelsInstalledAppearHere;

  /// No description provided for @modelsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get modelsActive;

  /// No description provided for @modelsActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get modelsActivate;

  /// No description provided for @modelsDeleteModel.
  ///
  /// In en, this message translates to:
  /// **'Delete model'**
  String get modelsDeleteModel;

  /// No description provided for @modelsChooseGoal.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Goal'**
  String get modelsChooseGoal;

  /// No description provided for @modelsChooseGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thinai benchmarks & recommends models for your device'**
  String get modelsChooseGoalSubtitle;

  /// No description provided for @modelsClearActiveGoal.
  ///
  /// In en, this message translates to:
  /// **'Clear Active Goal'**
  String get modelsClearActiveGoal;

  /// No description provided for @modelsNoMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No models match current filters'**
  String get modelsNoMatchFilters;

  /// No description provided for @modelsNoMatchQuery.
  ///
  /// In en, this message translates to:
  /// **'No models match \"{query}\"'**
  String modelsNoMatchQuery(String query);

  /// No description provided for @modelsNoMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your selected filters or search terms.'**
  String get modelsNoMatchHint;

  /// No description provided for @modelsSearchHuggingFace.
  ///
  /// In en, this message translates to:
  /// **'Search Hugging Face'**
  String get modelsSearchHuggingFace;

  /// No description provided for @modelsResetFiltersAndSearch.
  ///
  /// In en, this message translates to:
  /// **'Reset filters & search'**
  String get modelsResetFiltersAndSearch;

  /// No description provided for @modelsStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get modelsStatusCancelled;

  /// No description provided for @modelsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get modelsStatusFailed;

  /// No description provided for @modelsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'100% · Completed'**
  String get modelsStatusCompleted;

  /// No description provided for @modelsStatusStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get modelsStatusStarting;

  /// No description provided for @modelsActiveInChat.
  ///
  /// In en, this message translates to:
  /// **'Active in Chat'**
  String get modelsActiveInChat;

  /// No description provided for @modelsTapToActivate.
  ///
  /// In en, this message translates to:
  /// **'Tap to activate'**
  String get modelsTapToActivate;

  /// No description provided for @modelsBadgeVision.
  ///
  /// In en, this message translates to:
  /// **'VISION'**
  String get modelsBadgeVision;

  /// No description provided for @modelsBadgeEmbed.
  ///
  /// In en, this message translates to:
  /// **'EMBED'**
  String get modelsBadgeEmbed;

  /// No description provided for @modelsBadgeReason.
  ///
  /// In en, this message translates to:
  /// **'REASON'**
  String get modelsBadgeReason;

  /// No description provided for @modelsBadgeText.
  ///
  /// In en, this message translates to:
  /// **'TEXT'**
  String get modelsBadgeText;

  /// No description provided for @modelsFeaturedBadge.
  ///
  /// In en, this message translates to:
  /// **'FEATURED'**
  String get modelsFeaturedBadge;

  /// No description provided for @modelsPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get modelsPopular;

  /// No description provided for @modelsAddVision.
  ///
  /// In en, this message translates to:
  /// **'+ Vision ({size})'**
  String modelsAddVision(String size);

  /// No description provided for @modelsInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get modelsInstalled;

  /// No description provided for @modelsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get modelsPause;

  /// No description provided for @modelsTopPick.
  ///
  /// In en, this message translates to:
  /// **'TOP PICK'**
  String get modelsTopPick;

  /// No description provided for @modelsModelDetails.
  ///
  /// In en, this message translates to:
  /// **'Model details'**
  String get modelsModelDetails;

  /// No description provided for @modelsDimensions.
  ///
  /// In en, this message translates to:
  /// **'{count} dims'**
  String modelsDimensions(String count);

  /// No description provided for @modelsNeedsRam.
  ///
  /// In en, this message translates to:
  /// **'Needs RAM'**
  String get modelsNeedsRam;

  /// No description provided for @modelsDetailParameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get modelsDetailParameters;

  /// No description provided for @modelsDetailContextWindow.
  ///
  /// In en, this message translates to:
  /// **'Context Window'**
  String get modelsDetailContextWindow;

  /// No description provided for @modelsTokensValue.
  ///
  /// In en, this message translates to:
  /// **'{count} tokens'**
  String modelsTokensValue(String count);

  /// No description provided for @modelsDetailDownloadSize.
  ///
  /// In en, this message translates to:
  /// **'Download Size'**
  String get modelsDetailDownloadSize;

  /// No description provided for @modelsDetailCapability.
  ///
  /// In en, this message translates to:
  /// **'Capability'**
  String get modelsDetailCapability;

  /// No description provided for @modelsDownloadSize.
  ///
  /// In en, this message translates to:
  /// **'Download {size}'**
  String modelsDownloadSize(String size);

  /// No description provided for @modelsCapVisionReady.
  ///
  /// In en, this message translates to:
  /// **'Vision Ready'**
  String get modelsCapVisionReady;

  /// No description provided for @modelsCapEmbeddings.
  ///
  /// In en, this message translates to:
  /// **'Embeddings'**
  String get modelsCapEmbeddings;

  /// No description provided for @modelsCapLightweight.
  ///
  /// In en, this message translates to:
  /// **'Lightweight'**
  String get modelsCapLightweight;

  /// No description provided for @modelsCapFast.
  ///
  /// In en, this message translates to:
  /// **'Fast & Efficient'**
  String get modelsCapFast;

  /// No description provided for @modelsCapMultilingual.
  ///
  /// In en, this message translates to:
  /// **'Multilingual'**
  String get modelsCapMultilingual;

  /// No description provided for @modelsCapCodeReasoning.
  ///
  /// In en, this message translates to:
  /// **'Code · Reasoning'**
  String get modelsCapCodeReasoning;

  /// No description provided for @modelsCapInstruct.
  ///
  /// In en, this message translates to:
  /// **'Instruct'**
  String get modelsCapInstruct;

  /// No description provided for @modelsFitTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Too large for this phone.'**
  String get modelsFitTooLarge;

  /// No description provided for @modelsFitNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs {needs}, this phone has {available} to spare.'**
  String modelsFitNeeds(String needs, String available);

  /// No description provided for @modelsFitTight.
  ///
  /// In en, this message translates to:
  /// **'A tight fit. Other apps may close while this runs.'**
  String get modelsFitTight;

  /// No description provided for @modelsDownloadingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Downloading model} other{Downloading {count} models}}'**
  String modelsDownloadingCount(int count);

  /// No description provided for @modelsPauseDownload.
  ///
  /// In en, this message translates to:
  /// **'Pause download'**
  String get modelsPauseDownload;

  /// No description provided for @modelsResumePercent.
  ///
  /// In en, this message translates to:
  /// **'Resume {percent}%'**
  String modelsResumePercent(String percent);

  /// No description provided for @modelsPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get modelsPaused;

  /// No description provided for @modelsPausedPercent.
  ///
  /// In en, this message translates to:
  /// **'Paused · {percent}%'**
  String modelsPausedPercent(String percent);

  /// No description provided for @modelsPausedDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Paused download} other{Paused downloads ({count})}}'**
  String modelsPausedDownloadsTitle(int count);

  /// No description provided for @modelsPausedDownloadsBody.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. Resume to continue where it stopped.'**
  String get modelsPausedDownloadsBody;

  /// No description provided for @modelsResumeDownload.
  ///
  /// In en, this message translates to:
  /// **'Resume download'**
  String get modelsResumeDownload;

  /// No description provided for @modelsDiscardDownload.
  ///
  /// In en, this message translates to:
  /// **'Discard download'**
  String get modelsDiscardDownload;

  /// No description provided for @modelsUseCaseFastChat.
  ///
  /// In en, this message translates to:
  /// **'Fast chat'**
  String get modelsUseCaseFastChat;

  /// No description provided for @modelsUseCaseFastChatBlurb.
  ///
  /// In en, this message translates to:
  /// **'Quick back-and-forth, answers as fast as you type'**
  String get modelsUseCaseFastChatBlurb;

  /// No description provided for @modelsUseCaseReasoning.
  ///
  /// In en, this message translates to:
  /// **'Best reasoning'**
  String get modelsUseCaseReasoning;

  /// No description provided for @modelsUseCaseReasoningBlurb.
  ///
  /// In en, this message translates to:
  /// **'Harder questions, maths, step-by-step thinking'**
  String get modelsUseCaseReasoningBlurb;

  /// No description provided for @modelsUseCaseCoding.
  ///
  /// In en, this message translates to:
  /// **'Coding'**
  String get modelsUseCaseCoding;

  /// No description provided for @modelsUseCaseCodingBlurb.
  ///
  /// In en, this message translates to:
  /// **'Writing and explaining code'**
  String get modelsUseCaseCodingBlurb;

  /// No description provided for @modelsUseCaseTamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get modelsUseCaseTamil;

  /// No description provided for @modelsUseCaseTamilBlurb.
  ///
  /// In en, this message translates to:
  /// **'Chatting and writing in Tamil'**
  String get modelsUseCaseTamilBlurb;

  /// No description provided for @modelsUseCaseEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get modelsUseCaseEnglish;

  /// No description provided for @modelsUseCaseEnglishBlurb.
  ///
  /// In en, this message translates to:
  /// **'Everyday English conversation and writing'**
  String get modelsUseCaseEnglishBlurb;

  /// No description provided for @modelsUseCaseVision.
  ///
  /// In en, this message translates to:
  /// **'Image understanding'**
  String get modelsUseCaseVision;

  /// No description provided for @modelsUseCaseVisionBlurb.
  ///
  /// In en, this message translates to:
  /// **'Asking questions about a photo or screenshot'**
  String get modelsUseCaseVisionBlurb;

  /// No description provided for @modelsUseCaseTranslation.
  ///
  /// In en, this message translates to:
  /// **'Offline translation'**
  String get modelsUseCaseTranslation;

  /// No description provided for @modelsUseCaseTranslationBlurb.
  ///
  /// In en, this message translates to:
  /// **'Translating between languages with no signal'**
  String get modelsUseCaseTranslationBlurb;

  /// No description provided for @modelsUseCaseSummarizing.
  ///
  /// In en, this message translates to:
  /// **'Summarization'**
  String get modelsUseCaseSummarizing;

  /// No description provided for @modelsUseCaseSummarizingBlurb.
  ///
  /// In en, this message translates to:
  /// **'Shortening long text into the gist'**
  String get modelsUseCaseSummarizingBlurb;

  /// No description provided for @modelsUseCaseDocuments.
  ///
  /// In en, this message translates to:
  /// **'Document analysis'**
  String get modelsUseCaseDocuments;

  /// No description provided for @modelsUseCaseDocumentsBlurb.
  ///
  /// In en, this message translates to:
  /// **'Reading long documents and answering about them'**
  String get modelsUseCaseDocumentsBlurb;

  /// No description provided for @modelsReasonNotSuited.
  ///
  /// In en, this message translates to:
  /// **'{task, select, fastChat{Not suited to quick conversations} reasoning{Not suited to step-by-step reasoning} coding{Not suited to code} tamil{Not suited to Tamil} english{Not suited to English} vision{Not suited to images} translation{Not suited to translation} summarizing{Not suited to summarising} documents{Not suited to long documents} other{Not suited to quick conversations}}'**
  String modelsReasonNotSuited(String task);

  /// No description provided for @modelsReasonLimited.
  ///
  /// In en, this message translates to:
  /// **'{task, select, fastChat{Limited for quick conversations} reasoning{Limited for step-by-step reasoning} coding{Limited for code} tamil{Limited for Tamil} english{Limited for English} vision{Limited for images} translation{Limited for translation} summarizing{Limited for summarising} documents{Limited for long documents} other{Limited for quick conversations}}'**
  String modelsReasonLimited(String task);

  /// No description provided for @modelsReasonUsable.
  ///
  /// In en, this message translates to:
  /// **'{task, select, fastChat{Usable for quick conversations} reasoning{Usable for step-by-step reasoning} coding{Usable for code} tamil{Usable for Tamil} english{Usable for English} vision{Usable for images} translation{Usable for translation} summarizing{Usable for summarising} documents{Usable for long documents} other{Usable for quick conversations}}'**
  String modelsReasonUsable(String task);

  /// No description provided for @modelsReasonGood.
  ///
  /// In en, this message translates to:
  /// **'{task, select, fastChat{Good for quick conversations} reasoning{Good for step-by-step reasoning} coding{Good for code} tamil{Good for Tamil} english{Good for English} vision{Good for images} translation{Good for translation} summarizing{Good for summarising} documents{Good for long documents} other{Good for quick conversations}}'**
  String modelsReasonGood(String task);

  /// No description provided for @modelsReasonExcellent.
  ///
  /// In en, this message translates to:
  /// **'{task, select, fastChat{Excellent for quick conversations} reasoning{Excellent for step-by-step reasoning} coding{Excellent for code} tamil{Excellent for Tamil} english{Excellent for English} vision{Excellent for images} translation{Excellent for translation} summarizing{Excellent for summarising} documents{Excellent for long documents} other{Excellent for quick conversations}}'**
  String modelsReasonExcellent(String task);

  /// No description provided for @modelsCaveatNoneFits.
  ///
  /// In en, this message translates to:
  /// **'{task, select, fastChat{No model in the catalogue fits this phone for quick conversations.} reasoning{No model in the catalogue fits this phone for step-by-step reasoning.} coding{No model in the catalogue fits this phone for code.} tamil{No model in the catalogue fits this phone for Tamil.} english{No model in the catalogue fits this phone for English.} vision{No model in the catalogue fits this phone for images.} translation{No model in the catalogue fits this phone for translation.} summarizing{No model in the catalogue fits this phone for summarising.} documents{No model in the catalogue fits this phone for long documents.} other{No model in the catalogue fits this phone for quick conversations.}}'**
  String modelsCaveatNoneFits(String task);

  /// No description provided for @modelsCaveatNothingFitsWell.
  ///
  /// In en, this message translates to:
  /// **'{task, select, fastChat{Nothing fits well for quick conversations. These are closest.} reasoning{Nothing fits well for step-by-step reasoning. These are closest.} coding{Nothing fits well for code. These are closest.} tamil{Nothing fits well for Tamil. These are closest.} english{Nothing fits well for English. These are closest.} vision{Nothing fits well for images. These are closest.} translation{Nothing fits well for translation. These are closest.} summarizing{Nothing fits well for summarising. These are closest.} documents{Nothing fits well for long documents. These are closest.} other{Nothing fits well for quick conversations. These are closest.}}'**
  String modelsCaveatNothingFitsWell(String task);

  /// No description provided for @modelsCaveatNothingStrong.
  ///
  /// In en, this message translates to:
  /// **'{task, select, fastChat{Nothing at this size is strong at quick conversations. Closest matches shown.} reasoning{Nothing at this size is strong at step-by-step reasoning. Closest matches shown.} coding{Nothing at this size is strong at code. Closest matches shown.} tamil{Nothing at this size is strong at Tamil. Closest matches shown.} english{Nothing at this size is strong at English. Closest matches shown.} vision{Nothing at this size is strong at images. Closest matches shown.} translation{Nothing at this size is strong at translation. Closest matches shown.} summarizing{Nothing at this size is strong at summarising. Closest matches shown.} documents{Nothing at this size is strong at long documents. Closest matches shown.} other{Nothing at this size is strong at quick conversations. Closest matches shown.}}'**
  String modelsCaveatNothingStrong(String task);

  /// No description provided for @modelsVisionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image understanding is not available in this build.'**
  String get modelsVisionUnavailable;

  /// No description provided for @modelsFitComfortable.
  ///
  /// In en, this message translates to:
  /// **'Runs well on your phone'**
  String get modelsFitComfortable;

  /// No description provided for @modelsFitTightShort.
  ///
  /// In en, this message translates to:
  /// **'Tight fit, may slow other apps'**
  String get modelsFitTightShort;

  /// No description provided for @modelsFitTooBig.
  ///
  /// In en, this message translates to:
  /// **'Too big for your phone'**
  String get modelsFitTooBig;

  /// No description provided for @modelsFitUnknown.
  ///
  /// In en, this message translates to:
  /// **'Fit unknown'**
  String get modelsFitUnknown;

  /// No description provided for @modelsSpeedUnknown.
  ///
  /// In en, this message translates to:
  /// **'speed unknown'**
  String get modelsSpeedUnknown;

  /// No description provided for @modelsAdvisorGoalCollapsed.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal} · tap to customize'**
  String modelsAdvisorGoalCollapsed(String goal);

  /// No description provided for @modelsAdvisorPromptCollapsed.
  ///
  /// In en, this message translates to:
  /// **'What do you want to do? · tap to pick a goal'**
  String get modelsAdvisorPromptCollapsed;

  /// No description provided for @modelsAdvisorPrompt.
  ///
  /// In en, this message translates to:
  /// **'What do you want to do?'**
  String get modelsAdvisorPrompt;

  /// No description provided for @modelsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get modelsClear;

  /// No description provided for @modelsAdvisorCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse guide'**
  String get modelsAdvisorCollapse;

  /// No description provided for @modelsAdvisorSubtitleKnown.
  ///
  /// In en, this message translates to:
  /// **'Thinai picks a model that fits your phone · {device}'**
  String modelsAdvisorSubtitleKnown(String device);

  /// No description provided for @modelsAdvisorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thinai picks a model for the job'**
  String get modelsAdvisorSubtitle;

  /// No description provided for @modelsAdvisorNothingFits.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the catalogue fits this one.'**
  String get modelsAdvisorNothingFits;

  /// No description provided for @modelsAdvisorBestForPhone.
  ///
  /// In en, this message translates to:
  /// **'Best model for your phone'**
  String get modelsAdvisorBestForPhone;

  /// No description provided for @modelsAdvisorBestForThis.
  ///
  /// In en, this message translates to:
  /// **'Best model for this'**
  String get modelsAdvisorBestForThis;

  /// No description provided for @modelsAdvisorAlsoConsider.
  ///
  /// In en, this message translates to:
  /// **'Also worth considering'**
  String get modelsAdvisorAlsoConsider;

  /// No description provided for @modelsAdvisorAuthorDownload.
  ///
  /// In en, this message translates to:
  /// **'{author} · {size} download'**
  String modelsAdvisorAuthorDownload(String author, String size);

  /// No description provided for @modelsAdvisorContext.
  ///
  /// In en, this message translates to:
  /// **'{context} context'**
  String modelsAdvisorContext(String context);

  /// No description provided for @modelsAdvisorAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Already downloaded'**
  String get modelsAdvisorAlreadyDownloaded;

  /// No description provided for @modelsAdvisorSpeedMeasured.
  ///
  /// In en, this message translates to:
  /// **'Speed measured on this phone by Benchmark.'**
  String get modelsAdvisorSpeedMeasured;

  /// No description provided for @modelsAdvisorSpeedEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated speed. Run Benchmark for the real number.'**
  String get modelsAdvisorSpeedEstimated;

  /// No description provided for @modelsAdvisorStartingCancel.
  ///
  /// In en, this message translates to:
  /// **'Starting… · tap to cancel'**
  String get modelsAdvisorStartingCancel;

  /// No description provided for @modelsAdvisorDownloadingCancel.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}% · tap to cancel'**
  String modelsAdvisorDownloadingCancel(String percent);

  /// No description provided for @modelsSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Model settings'**
  String get modelsSettingsTitle;

  /// No description provided for @modelsSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Used by chat and the API server. Requests can override these, up to the maximum.'**
  String get modelsSettingsBody;

  /// No description provided for @modelsSettingsResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get modelsSettingsResetDefaults;

  /// No description provided for @modelsSettingsContextWindow.
  ///
  /// In en, this message translates to:
  /// **'Context window'**
  String get modelsSettingsContextWindow;

  /// No description provided for @modelsSettingsContextHelp.
  ///
  /// In en, this message translates to:
  /// **'Longer windows remember more but use more RAM and run slower.'**
  String get modelsSettingsContextHelp;

  /// No description provided for @modelsSettingsTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get modelsSettingsTemperature;

  /// No description provided for @modelsSettingsPrecise.
  ///
  /// In en, this message translates to:
  /// **'Precise'**
  String get modelsSettingsPrecise;

  /// No description provided for @modelsSettingsCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get modelsSettingsCreative;

  /// No description provided for @modelsSettingsTopKHelp.
  ///
  /// In en, this message translates to:
  /// **'Picks each word from only the K likeliest. Lower is more focused; 0 turns the limit off.'**
  String get modelsSettingsTopKHelp;

  /// No description provided for @modelsSettingsTopPHelp.
  ///
  /// In en, this message translates to:
  /// **'Picks from the likeliest words that together make up this share of the probability. 1.00 keeps them all.'**
  String get modelsSettingsTopPHelp;

  /// No description provided for @modelsSettingsThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get modelsSettingsThinking;

  /// No description provided for @modelsSettingsThinkingHelp.
  ///
  /// In en, this message translates to:
  /// **'Reasons step by step before answering. Off answers sooner.'**
  String get modelsSettingsThinkingHelp;

  /// No description provided for @modelsSettingsCapPhoneRam.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max}, limited by this phone\'s RAM.'**
  String modelsSettingsCapPhoneRam(String max);

  /// No description provided for @modelsSettingsCapRam.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max}, limited by RAM (model supports {trained}).'**
  String modelsSettingsCapRam(String max, String trained);

  /// No description provided for @modelsSettingsCapTraining.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max}, this model\'s training limit.'**
  String modelsSettingsCapTraining(String max);

  /// No description provided for @modelsSettingsCap.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max}.'**
  String modelsSettingsCap(String max);
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
