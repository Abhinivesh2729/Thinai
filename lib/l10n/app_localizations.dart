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

  /// No description provided for @serverToastLanNoAddress.
  ///
  /// In en, this message translates to:
  /// **'Sharing on, but no Wi-Fi/LAN address was found.'**
  String get serverToastLanNoAddress;

  /// No description provided for @serverToastStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Start failed: {error}'**
  String serverToastStartFailed(String error);

  /// No description provided for @serverPortDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Server Port'**
  String get serverPortDialogTitle;

  /// No description provided for @serverPortDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Select or enter the local TCP port Thinai binds to. Default is 11434 for Ollama, 8080 for standard.'**
  String get serverPortDialogBody;

  /// No description provided for @serverPortNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Port number'**
  String get serverPortNumberLabel;

  /// No description provided for @serverPortPresetStandard.
  ///
  /// In en, this message translates to:
  /// **'8080 (Standard)'**
  String get serverPortPresetStandard;

  /// No description provided for @serverSavePort.
  ///
  /// In en, this message translates to:
  /// **'Save Port'**
  String get serverSavePort;

  /// No description provided for @serverStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get serverStatusRunning;

  /// No description provided for @serverStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get serverStatusStopped;

  /// No description provided for @serverStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get serverStart;

  /// No description provided for @serverStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get serverStop;

  /// No description provided for @serverCopyAddressTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy Server Address'**
  String get serverCopyAddressTooltip;

  /// No description provided for @serverCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied {value} to clipboard'**
  String serverCopiedToClipboard(String value);

  /// No description provided for @serverCopiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Copied {label}'**
  String serverCopiedLabel(String label);

  /// No description provided for @serverServingModel.
  ///
  /// In en, this message translates to:
  /// **'SERVING MODEL'**
  String get serverServingModel;

  /// No description provided for @serverTune.
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get serverTune;

  /// No description provided for @serverNoModelLoaded.
  ///
  /// In en, this message translates to:
  /// **'No model loaded yet. Load one to enable completions.'**
  String get serverNoModelLoaded;

  /// No description provided for @serverBrowseModels.
  ///
  /// In en, this message translates to:
  /// **'Browse Models'**
  String get serverBrowseModels;

  /// No description provided for @serverRegenerateTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Regenerate API token?'**
  String get serverRegenerateTokenTitle;

  /// No description provided for @serverRegenerateTokenBody.
  ///
  /// In en, this message translates to:
  /// **'Existing LAN clients using the current token will lose access and must be updated.'**
  String get serverRegenerateTokenBody;

  /// No description provided for @serverRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get serverRegenerate;

  /// No description provided for @serverTokenRegenerated.
  ///
  /// In en, this message translates to:
  /// **'API token regenerated'**
  String get serverTokenRegenerated;

  /// No description provided for @serverLanShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share on Local Network (LAN)'**
  String get serverLanShareTitle;

  /// No description provided for @serverLanShareOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Other computers on this Wi-Fi can reach the API'**
  String get serverLanShareOnSubtitle;

  /// No description provided for @serverLanShareOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only apps running directly on this phone can reach 127.0.0.1'**
  String get serverLanShareOffSubtitle;

  /// No description provided for @serverCopyLanUrlTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy LAN URL'**
  String get serverCopyLanUrlTooltip;

  /// No description provided for @serverDevQuickStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer Quick Start'**
  String get serverDevQuickStartTitle;

  /// No description provided for @serverDevQuickStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct configuration snippets for coding assistants & scripts'**
  String get serverDevQuickStartSubtitle;

  /// No description provided for @serverTabChatJson.
  ///
  /// In en, this message translates to:
  /// **'Chat JSON'**
  String get serverTabChatJson;

  /// No description provided for @serverVsCodeIntro.
  ///
  /// In en, this message translates to:
  /// **'For Continue.dev or Cline extensions in VS Code:'**
  String get serverVsCodeIntro;

  /// No description provided for @serverPythonIntro.
  ///
  /// In en, this message translates to:
  /// **'Query with official OpenAI Python SDK:'**
  String get serverPythonIntro;

  /// No description provided for @serverCurlIntro.
  ///
  /// In en, this message translates to:
  /// **'Direct terminal HTTP request with standard JSON payload:'**
  String get serverCurlIntro;

  /// No description provided for @serverChatJsonIntro.
  ///
  /// In en, this message translates to:
  /// **'OpenAI standard chat payload (/v1/chat/completions):'**
  String get serverChatJsonIntro;

  /// No description provided for @serverOllamaIntro.
  ///
  /// In en, this message translates to:
  /// **'Point any Ollama client (Open-WebUI, Chatbox, CLI) to Thinai:'**
  String get serverOllamaIntro;

  /// No description provided for @serverCopyLabelVsCodeConfig.
  ///
  /// In en, this message translates to:
  /// **'VS Code Config'**
  String get serverCopyLabelVsCodeConfig;

  /// No description provided for @serverCopyLabelPythonScript.
  ///
  /// In en, this message translates to:
  /// **'Python Script'**
  String get serverCopyLabelPythonScript;

  /// No description provided for @serverCopyLabelCurlCommand.
  ///
  /// In en, this message translates to:
  /// **'cURL Command'**
  String get serverCopyLabelCurlCommand;

  /// No description provided for @serverCopyLabelChatJson.
  ///
  /// In en, this message translates to:
  /// **'Chat JSON Payload'**
  String get serverCopyLabelChatJson;

  /// No description provided for @serverCopyLabelOllamaEnv.
  ///
  /// In en, this message translates to:
  /// **'Ollama Host Env'**
  String get serverCopyLabelOllamaEnv;

  /// No description provided for @serverEndpointOpenAiChat.
  ///
  /// In en, this message translates to:
  /// **'OpenAI Chat Completions'**
  String get serverEndpointOpenAiChat;

  /// No description provided for @serverEndpointOllamaChat.
  ///
  /// In en, this message translates to:
  /// **'Ollama Native Chat'**
  String get serverEndpointOllamaChat;

  /// No description provided for @serverEndpointEmbeddings.
  ///
  /// In en, this message translates to:
  /// **'Vector Embeddings'**
  String get serverEndpointEmbeddings;

  /// No description provided for @serverEndpointModels.
  ///
  /// In en, this message translates to:
  /// **'Installed Models Catalog'**
  String get serverEndpointModels;

  /// No description provided for @serverApiEndpointsTitle.
  ///
  /// In en, this message translates to:
  /// **'API Endpoints'**
  String get serverApiEndpointsTitle;

  /// No description provided for @serverApiEndpointsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Standard OpenAI & Ollama compatible HTTP routes'**
  String get serverApiEndpointsSubtitle;

  /// No description provided for @serverCopyBaseUrlTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy Base URL'**
  String get serverCopyBaseUrlTooltip;

  /// No description provided for @serverBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL: {url}'**
  String serverBaseUrlLabel(String url);

  /// No description provided for @serverCopyCurlTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy cURL'**
  String get serverCopyCurlTooltip;

  /// No description provided for @serverCurlCommandLabel.
  ///
  /// In en, this message translates to:
  /// **'{path} cURL command'**
  String serverCurlCommandLabel(String path);

  /// No description provided for @serverSecurityLan.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Network Serving Active · Any device on this local subnet can query the API on port {port} with your Bearer token.'**
  String serverSecurityLan(String port);

  /// No description provided for @serverSecurityLocal.
  ///
  /// In en, this message translates to:
  /// **'Local Loopback Active · Only apps executing directly on this hardware can query localhost:{port}.'**
  String serverSecurityLocal(String port);

  /// No description provided for @hfSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search GGUF models on Hugging Face'**
  String get hfSearchHint;

  /// No description provided for @hfSearchFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Search did not work'**
  String get hfSearchFailedTitle;

  /// No description provided for @hfTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get hfTryAgain;

  /// No description provided for @hfEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Find any GGUF model'**
  String get hfEmptyTitle;

  /// No description provided for @hfEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Search by name or maker, like \"gemma\", \"phi\" or \"unsloth\". Results are public repos with GGUF files.'**
  String get hfEmptyMessage;

  /// No description provided for @hfNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No GGUF models match \"{query}\"'**
  String hfNoMatchTitle(String query);

  /// No description provided for @hfNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter name or a different spelling.'**
  String get hfNoMatchMessage;

  /// No description provided for @hfResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results ({count})'**
  String hfResultsTitle(int count);

  /// No description provided for @hfResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Most downloaded first'**
  String get hfResultsSubtitle;

  /// No description provided for @hfShowingUpTo.
  ///
  /// In en, this message translates to:
  /// **'Showing up to {limit} results.'**
  String hfShowingUpTo(int limit);

  /// No description provided for @hfDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download model?'**
  String get hfDownloadTitle;

  /// No description provided for @hfTooBigTitle.
  ///
  /// In en, this message translates to:
  /// **'Too big for this phone?'**
  String get hfTooBigTitle;

  /// No description provided for @hfDownloadAnyway.
  ///
  /// In en, this message translates to:
  /// **'Download anyway'**
  String get hfDownloadAnyway;

  /// No description provided for @hfDownloadMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to download {file} ({size}) from Hugging Face?'**
  String hfDownloadMessage(String file, String size);

  /// No description provided for @hfDownloadMessageTooBig.
  ///
  /// In en, this message translates to:
  /// **'Do you want to download {file} ({size}) from Hugging Face?\n\nThis is likely too large for this phone and may not load.'**
  String hfDownloadMessageTooBig(String file, String size);

  /// No description provided for @hfDownloadMessageTooBigBudget.
  ///
  /// In en, this message translates to:
  /// **'Do you want to download {file} ({size}) from Hugging Face?\n\nIt needs about {needs} of memory and this phone has {budget} to spare, so it will probably not load.'**
  String hfDownloadMessageTooBigBudget(
    String file,
    String size,
    String needs,
    String budget,
  );

  /// No description provided for @hfDownloadMessageTight.
  ///
  /// In en, this message translates to:
  /// **'Do you want to download {file} ({size}) from Hugging Face?\n\nA tight fit. Other apps may close while this runs.'**
  String hfDownloadMessageTight(String file, String size);

  /// No description provided for @hfOpenFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not open this model'**
  String get hfOpenFailedTitle;

  /// No description provided for @hfSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in required'**
  String get hfSignInTitle;

  /// No description provided for @hfSignInMessage.
  ///
  /// In en, this message translates to:
  /// **'This model needs a Hugging Face account to download, which Thinai does not support yet.'**
  String get hfSignInMessage;

  /// No description provided for @hfFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'GGUF files ({count})'**
  String hfFilesTitle(int count);

  /// No description provided for @hfFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smaller files load faster and use less memory'**
  String get hfFilesSubtitle;

  /// No description provided for @hfSkippedFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 other GGUF file is hidden: split files, image encoders and helper files cannot be loaded on their own.} other{{count} other GGUF files are hidden: split files, image encoders and helper files cannot be loaded on their own.}}'**
  String hfSkippedFiles(int count);

  /// No description provided for @hfNothingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to install here'**
  String get hfNothingTitle;

  /// No description provided for @hfNothingMessage.
  ///
  /// In en, this message translates to:
  /// **'This repo has no single-file GGUF models that Thinai can load.'**
  String get hfNothingMessage;

  /// No description provided for @hfNetworkNotice.
  ///
  /// In en, this message translates to:
  /// **'Search uses the internet. Thinai contacts huggingface.co only while you search here or open a model, never in the background. Your chats stay on this phone.'**
  String get hfNetworkNotice;

  /// No description provided for @hfAgoToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get hfAgoToday;

  /// No description provided for @hfAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String hfAgoDays(int count);

  /// No description provided for @hfAgoMonths.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String hfAgoMonths(int count);

  /// No description provided for @hfAgoYears.
  ///
  /// In en, this message translates to:
  /// **'{count}y ago'**
  String hfAgoYears(int count);

  /// No description provided for @hfByAuthor.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String hfByAuthor(String author);

  /// No description provided for @hfNoLicence.
  ///
  /// In en, this message translates to:
  /// **'No licence listed'**
  String get hfNoLicence;

  /// No description provided for @hfInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get hfInstalled;

  /// No description provided for @hfPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get hfPause;

  /// No description provided for @hfFindMore.
  ///
  /// In en, this message translates to:
  /// **'Find more on Hugging Face'**
  String get hfFindMore;

  /// No description provided for @hfSearchFor.
  ///
  /// In en, this message translates to:
  /// **'Search Hugging Face for \"{query}\"'**
  String hfSearchFor(String query);

  /// No description provided for @hfPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Any public GGUF model, installed into your library. Uses the internet.'**
  String get hfPromptSubtitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get settingsSystemPrompt;

  /// No description provided for @settingsHardware.
  ///
  /// In en, this message translates to:
  /// **'Hardware & Acceleration'**
  String get settingsHardware;

  /// No description provided for @settingsModelStorage.
  ///
  /// In en, this message translates to:
  /// **'Model & Storage'**
  String get settingsModelStorage;

  /// No description provided for @settingsLocalServer.
  ///
  /// In en, this message translates to:
  /// **'Local Server & API'**
  String get settingsLocalServer;

  /// No description provided for @settingsAboutGuidance.
  ///
  /// In en, this message translates to:
  /// **'About & Guidance'**
  String get settingsAboutGuidance;

  /// No description provided for @settingsStartPage.
  ///
  /// In en, this message translates to:
  /// **'Open page on startup'**
  String get settingsStartPage;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsWebSearch.
  ///
  /// In en, this message translates to:
  /// **'Web search in chat'**
  String get settingsWebSearch;

  /// No description provided for @settingsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settingsEnabled;

  /// No description provided for @settingsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsDisabled;

  /// No description provided for @settingsGpuAcceleration.
  ///
  /// In en, this message translates to:
  /// **'GPU acceleration'**
  String get settingsGpuAcceleration;

  /// No description provided for @settingsGpuAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsGpuAuto;

  /// No description provided for @settingsBenchmarkDevice.
  ///
  /// In en, this message translates to:
  /// **'Benchmark device'**
  String get settingsBenchmarkDevice;

  /// No description provided for @settingsGpuDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'GPU speed diagnostics'**
  String get settingsGpuDiagnostics;

  /// No description provided for @settingsDeviceSpecs.
  ///
  /// In en, this message translates to:
  /// **'Device hardware specs'**
  String get settingsDeviceSpecs;

  /// No description provided for @settingsDeviceSpecsWithRam.
  ///
  /// In en, this message translates to:
  /// **'{cores} Cores • {ramGb} GB RAM'**
  String settingsDeviceSpecsWithRam(int cores, String ramGb);

  /// No description provided for @settingsDeviceSpecsCores.
  ///
  /// In en, this message translates to:
  /// **'{cores} CPU Cores'**
  String settingsDeviceSpecsCores(int cores);

  /// No description provided for @settingsImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {name}'**
  String settingsImported(String name);

  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String settingsImportFailed(String error);

  /// No description provided for @settingsDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get settingsDownloadStarted;

  /// No description provided for @settingsDownloadStopped.
  ///
  /// In en, this message translates to:
  /// **'Download stopped: {error}. Progress is saved, resume it from the Model Manager.'**
  String settingsDownloadStopped(String error);

  /// No description provided for @settingsDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String settingsDownloadFailed(String error);

  /// No description provided for @settingsDownloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get settingsDownloadComplete;

  /// No description provided for @settingsClearDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all downloads?'**
  String get settingsClearDownloadsTitle;

  /// No description provided for @settingsClearDownloadsBody.
  ///
  /// In en, this message translates to:
  /// **'This removes all downloaded model files inside the app to free up device storage.'**
  String get settingsClearDownloadsBody;

  /// No description provided for @settingsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get settingsClearAll;

  /// No description provided for @settingsNoDownloadsFound.
  ///
  /// In en, this message translates to:
  /// **'No downloaded items found'**
  String get settingsNoDownloadsFound;

  /// No description provided for @settingsClearedDownloads.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Cleared 1 downloaded item} other{Cleared {count} downloaded items}}'**
  String settingsClearedDownloads(int count);

  /// No description provided for @settingsClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Clear failed: {error}'**
  String settingsClearFailed(String error);

  /// No description provided for @settingsTune.
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get settingsTune;

  /// No description provided for @settingsNoActiveModel.
  ///
  /// In en, this message translates to:
  /// **'No active model loaded'**
  String get settingsNoActiveModel;

  /// No description provided for @settingsCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get settingsCatalog;

  /// No description provided for @settingsImportGguf.
  ///
  /// In en, this message translates to:
  /// **'Import local .gguf'**
  String get settingsImportGguf;

  /// No description provided for @settingsDownloadFromUrl.
  ///
  /// In en, this message translates to:
  /// **'Download model from URL'**
  String get settingsDownloadFromUrl;

  /// No description provided for @settingsClearDownloadedModels.
  ///
  /// In en, this message translates to:
  /// **'Clear downloaded models'**
  String get settingsClearDownloadedModels;

  /// No description provided for @settingsChangePortTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Server Port'**
  String get settingsChangePortTitle;

  /// No description provided for @settingsPortNumber.
  ///
  /// In en, this message translates to:
  /// **'Port number'**
  String get settingsPortNumber;

  /// No description provided for @settingsPortSetRestart.
  ///
  /// In en, this message translates to:
  /// **'Server port set to {port}. Restart the server to apply.'**
  String settingsPortSetRestart(int port);

  /// No description provided for @settingsPortSet.
  ///
  /// In en, this message translates to:
  /// **'Server port set to {port}'**
  String settingsPortSet(int port);

  /// No description provided for @settingsShareApiWifi.
  ///
  /// In en, this message translates to:
  /// **'Share API over Wi-Fi'**
  String get settingsShareApiWifi;

  /// No description provided for @settingsServerPort.
  ///
  /// In en, this message translates to:
  /// **'Server port'**
  String get settingsServerPort;

  /// No description provided for @settingsServerStatus.
  ///
  /// In en, this message translates to:
  /// **'Server status'**
  String get settingsServerStatus;

  /// No description provided for @settingsServerActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get settingsServerActive;

  /// No description provided for @settingsServerOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get settingsServerOffline;

  /// No description provided for @settingsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Thinai is up to date'**
  String get settingsUpToDate;

  /// No description provided for @settingsUpdateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Play Store could not check for updates'**
  String get settingsUpdateUnavailable;

  /// No description provided for @settingsUpdateAlreadyDownloading.
  ///
  /// In en, this message translates to:
  /// **'An update is already downloading'**
  String get settingsUpdateAlreadyDownloading;

  /// No description provided for @settingsUpdateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading update in the background'**
  String get settingsUpdateDownloading;

  /// No description provided for @settingsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Try again from Play Store.'**
  String get settingsUpdateFailed;

  /// No description provided for @settingsUpdateReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Update ready'**
  String get settingsUpdateReadyTitle;

  /// No description provided for @settingsUpdateReadyBody.
  ///
  /// In en, this message translates to:
  /// **'The new version is downloaded. Thinai restarts to install it.'**
  String get settingsUpdateReadyBody;

  /// No description provided for @settingsRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get settingsRestart;

  /// No description provided for @settingsStartTour.
  ///
  /// In en, this message translates to:
  /// **'Start app tour'**
  String get settingsStartTour;

  /// No description provided for @settingsCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckUpdates;

  /// No description provided for @settingsContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get settingsContactSupport;

  /// No description provided for @settingsAboutThinai.
  ///
  /// In en, this message translates to:
  /// **'About Thinai'**
  String get settingsAboutThinai;

  /// No description provided for @settingsDownloadDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Download model by URL'**
  String get settingsDownloadDialogTitle;

  /// No description provided for @settingsDirectGgufUrl.
  ///
  /// In en, this message translates to:
  /// **'Direct GGUF URL'**
  String get settingsDirectGgufUrl;

  /// No description provided for @settingsSaveAsOptional.
  ///
  /// In en, this message translates to:
  /// **'Save as (optional)'**
  String get settingsSaveAsOptional;

  /// No description provided for @gpuAcceleration.
  ///
  /// In en, this message translates to:
  /// **'GPU acceleration'**
  String get gpuAcceleration;

  /// No description provided for @gpuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offloads computation to hardware accelerator'**
  String get gpuSubtitle;

  /// No description provided for @gpuDescription.
  ///
  /// In en, this message translates to:
  /// **'Runs the model on the GPU instead of the CPU. Run the speed test to check if it helps on this phone.'**
  String get gpuDescription;

  /// No description provided for @gpuCrashedNotice.
  ///
  /// In en, this message translates to:
  /// **'{backend} crashed the app last time, so GPU acceleration was turned off.'**
  String gpuCrashedNotice(String backend);

  /// No description provided for @gpuCheckPhone.
  ///
  /// In en, this message translates to:
  /// **'Check this phone\'s GPU'**
  String get gpuCheckPhone;

  /// No description provided for @gpuNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No usable GPU found. Thinai will keep using the CPU.'**
  String get gpuNoneFound;

  /// No description provided for @gpuFound.
  ///
  /// In en, this message translates to:
  /// **'Found: {devices}'**
  String gpuFound(String devices);

  /// No description provided for @gpuAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get gpuAuto;

  /// No description provided for @gpuAutoWith.
  ///
  /// In en, this message translates to:
  /// **'Auto ({backend})'**
  String gpuAutoWith(String backend);

  /// No description provided for @gpuTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get gpuTesting;

  /// No description provided for @gpuSpeedTest.
  ///
  /// In en, this message translates to:
  /// **'Speed test'**
  String get gpuSpeedTest;

  /// No description provided for @gpuLoadModelFirst.
  ///
  /// In en, this message translates to:
  /// **'Load a model first, then run the test.'**
  String get gpuLoadModelFirst;

  /// No description provided for @gpuTestFailed.
  ///
  /// In en, this message translates to:
  /// **'The test failed: {error}'**
  String gpuTestFailed(String error);

  /// No description provided for @gpuVerdictGpuFaster.
  ///
  /// In en, this message translates to:
  /// **'The GPU is faster on this phone.'**
  String get gpuVerdictGpuFaster;

  /// No description provided for @gpuVerdictCpuFaster.
  ///
  /// In en, this message translates to:
  /// **'The CPU is faster here. Leave GPU acceleration off.'**
  String get gpuVerdictCpuFaster;

  /// No description provided for @gpuVerdictSame.
  ///
  /// In en, this message translates to:
  /// **'About the same either way.'**
  String get gpuVerdictSame;

  /// No description provided for @gpuReadingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Reading prompt'**
  String get gpuReadingPrompt;

  /// No description provided for @gpuWritingReply.
  ///
  /// In en, this message translates to:
  /// **'Writing reply'**
  String get gpuWritingReply;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Thinai'**
  String get aboutTitle;

  /// No description provided for @aboutVersionBadge.
  ///
  /// In en, this message translates to:
  /// **'v{version} · On-Device Sovereign AI'**
  String aboutVersionBadge(String version);

  /// No description provided for @aboutHeroDescription.
  ///
  /// In en, this message translates to:
  /// **'Thinai executes modern open-weights neural models directly on your Android phone silicon. Zero internet required, zero cloud reliance, and 100% data sovereignty.'**
  String get aboutHeroDescription;

  /// No description provided for @aboutCorePillars.
  ///
  /// In en, this message translates to:
  /// **'Core Pillars'**
  String get aboutCorePillars;

  /// No description provided for @aboutPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'100% Private & Sovereign'**
  String get aboutPrivateTitle;

  /// No description provided for @aboutPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'Every model token and user prompt is computed strictly inside device RAM. No telemetry, no logs, and no cloud interception.'**
  String get aboutPrivateBody;

  /// No description provided for @aboutAcceleratedTitle.
  ///
  /// In en, this message translates to:
  /// **'Hardware Accelerated'**
  String get aboutAcceleratedTitle;

  /// No description provided for @aboutAcceleratedBody.
  ///
  /// In en, this message translates to:
  /// **'Built on a high-performance llama.cpp mobile runtime with Vulkan and OpenCL GPU acceleration, tuned for high speed on modern mobile chipsets.'**
  String get aboutAcceleratedBody;

  /// No description provided for @aboutApiTitle.
  ///
  /// In en, this message translates to:
  /// **'Local OpenAI-Compatible API'**
  String get aboutApiTitle;

  /// No description provided for @aboutApiBody.
  ///
  /// In en, this message translates to:
  /// **'Runs an embedded HTTP server on localhost:11434 with /v1/chat/completions, transforming your phone into an AI engine for other apps and automations.'**
  String get aboutApiBody;

  /// No description provided for @aboutVisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Multimodal Vision & Web'**
  String get aboutVisionTitle;

  /// No description provided for @aboutVisionBody.
  ///
  /// In en, this message translates to:
  /// **'Engage in visual reasoning with vision-enabled models (Gemma 3, MiniCPM), document summarization, and privacy-preserving live web search citations.'**
  String get aboutVisionBody;

  /// No description provided for @aboutTechSpecs.
  ///
  /// In en, this message translates to:
  /// **'Technical Specifications'**
  String get aboutTechSpecs;

  /// No description provided for @aboutSpecEngine.
  ///
  /// In en, this message translates to:
  /// **'Inference Engine'**
  String get aboutSpecEngine;

  /// No description provided for @aboutSpecModelFormat.
  ///
  /// In en, this message translates to:
  /// **'Model Format'**
  String get aboutSpecModelFormat;

  /// No description provided for @aboutSpecArchitecture.
  ///
  /// In en, this message translates to:
  /// **'Target Architecture'**
  String get aboutSpecArchitecture;

  /// No description provided for @aboutSpecBackends.
  ///
  /// In en, this message translates to:
  /// **'Acceleration Backends'**
  String get aboutSpecBackends;

  /// No description provided for @aboutSpecLicense.
  ///
  /// In en, this message translates to:
  /// **'Software License'**
  String get aboutSpecLicense;

  /// No description provided for @aboutSpecLicenseValue.
  ///
  /// In en, this message translates to:
  /// **'Open Source (MIT)'**
  String get aboutSpecLicenseValue;

  /// No description provided for @aboutCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community & Transparency'**
  String get aboutCommunity;

  /// No description provided for @aboutCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'Thinai is built on sovereign privacy and open-source principles. You can inspect all third-party licenses or contact support for help.'**
  String get aboutCommunityBody;

  /// No description provided for @aboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get aboutLicenses;

  /// No description provided for @aboutContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get aboutContactSupport;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get supportTitle;

  /// No description provided for @supportCouldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link: {url}'**
  String supportCouldNotOpenLink(String url);

  /// No description provided for @supportFailedToOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Failed to open link: {error}'**
  String supportFailedToOpenLink(String error);

  /// No description provided for @supportHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get supportHeroTitle;

  /// No description provided for @supportHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Need assistance running models, found a bug, or have a suggestion? We respond promptly to community queries.'**
  String get supportHeroBody;

  /// No description provided for @supportChannels.
  ///
  /// In en, this message translates to:
  /// **'Direct Support Channels'**
  String get supportChannels;

  /// No description provided for @supportInstagramTitle.
  ///
  /// In en, this message translates to:
  /// **'Instagram Support'**
  String get supportInstagramTitle;

  /// No description provided for @supportInstagramBody.
  ///
  /// In en, this message translates to:
  /// **'Direct messaging, quick feature sneak-peeks, troubleshooting, and announcements.'**
  String get supportInstagramBody;

  /// No description provided for @supportInstagramOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open Instagram link'**
  String get supportInstagramOpenFailed;

  /// No description provided for @supportOpenInstagram.
  ///
  /// In en, this message translates to:
  /// **'Open Instagram'**
  String get supportOpenInstagram;

  /// No description provided for @supportCopyHandle.
  ///
  /// In en, this message translates to:
  /// **'Copy Instagram handle'**
  String get supportCopyHandle;

  /// No description provided for @supportHandleCopied.
  ///
  /// In en, this message translates to:
  /// **'Instagram handle copied to clipboard'**
  String get supportHandleCopied;

  /// No description provided for @supportDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Device Diagnostics'**
  String get supportDiagnostics;

  /// No description provided for @supportDiagnosticsHint.
  ///
  /// In en, this message translates to:
  /// **'Copying this data makes troubleshooting 10x faster when contacting us.'**
  String get supportDiagnosticsHint;

  /// No description provided for @supportCpuCores.
  ///
  /// In en, this message translates to:
  /// **'{cores} CPU Cores'**
  String supportCpuCores(int cores);

  /// No description provided for @supportTier.
  ///
  /// In en, this message translates to:
  /// **'Tier: {tier}'**
  String supportTier(String tier);

  /// No description provided for @supportModel.
  ///
  /// In en, this message translates to:
  /// **'Model: {model}'**
  String supportModel(String model);

  /// No description provided for @supportNoActiveModel.
  ///
  /// In en, this message translates to:
  /// **'No active model'**
  String get supportNoActiveModel;

  /// No description provided for @supportServerActive.
  ///
  /// In en, this message translates to:
  /// **'Server: Active'**
  String get supportServerActive;

  /// No description provided for @supportServerStopped.
  ///
  /// In en, this message translates to:
  /// **'Server: Stopped'**
  String get supportServerStopped;

  /// No description provided for @supportCopyDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Copy Diagnostic Specs'**
  String get supportCopyDiagnostics;

  /// No description provided for @supportDiagnosticsCopied.
  ///
  /// In en, this message translates to:
  /// **'System diagnostics copied to clipboard'**
  String get supportDiagnosticsCopied;

  /// No description provided for @supportTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Quick Troubleshooting'**
  String get supportTroubleshooting;

  /// No description provided for @supportFaqLoadQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why does a model take long to load or download?'**
  String get supportFaqLoadQuestion;

  /// No description provided for @supportFaqLoadAnswer.
  ///
  /// In en, this message translates to:
  /// **'Models are large AI neural networks (1 GB to 4+ GB). Download speed depends on your Wi-Fi connection. Loading requires allocating RAM; ensure background apps are cleared before loading 7B+ models.'**
  String get supportFaqLoadAnswer;

  /// No description provided for @supportFaqPrivacyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Does Thinai leak or upload my chats to the cloud?'**
  String get supportFaqPrivacyQuestion;

  /// No description provided for @supportFaqPrivacyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Never. Thinai is built from the ground up to be 100% sovereign and offline. The neural weights run directly on your phone CPU/GPU silicon, and no conversational data leaves device memory.'**
  String get supportFaqPrivacyAnswer;

  /// No description provided for @supportFaqGpuQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I use GPU acceleration (Vulkan / OpenCL)?'**
  String get supportFaqGpuQuestion;

  /// No description provided for @supportFaqGpuAnswer.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Settings > Hardware & Acceleration, and select Vulkan or OpenCL. Vulkan works best on Qualcomm Snapdragon Adreno and modern MediaTek Dimensity GPUs.'**
  String get supportFaqGpuAnswer;

  /// No description provided for @systemPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get systemPromptTitle;

  /// No description provided for @systemPromptSaved.
  ///
  /// In en, this message translates to:
  /// **'System prompt saved. New messages will use it.'**
  String get systemPromptSaved;

  /// No description provided for @systemPromptResetDone.
  ///
  /// In en, this message translates to:
  /// **'System prompt reset to the default.'**
  String get systemPromptResetDone;

  /// No description provided for @systemPromptDescription.
  ///
  /// In en, this message translates to:
  /// **'Instructions sent to the model at the start of every chat. Changes apply from the next message you send. Leave it empty to use the model\'s own default.'**
  String get systemPromptDescription;

  /// No description provided for @systemPromptHint.
  ///
  /// In en, this message translates to:
  /// **'You are a helpful assistant…'**
  String get systemPromptHint;

  /// No description provided for @systemPromptCharacters.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 character} other{{count} characters}}'**
  String systemPromptCharacters(int count);

  /// No description provided for @systemPromptResetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get systemPromptResetToDefault;

  /// No description provided for @benchmarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Benchmark'**
  String get benchmarkTitle;

  /// No description provided for @benchmarkStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get benchmarkStop;

  /// No description provided for @benchmarkError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String benchmarkError(String error);

  /// No description provided for @benchmarkRunning.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get benchmarkRunning;

  /// No description provided for @benchmarkRun.
  ///
  /// In en, this message translates to:
  /// **'Run benchmark'**
  String get benchmarkRun;

  /// No description provided for @benchmarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Generates {tokens} tokens and measures decode speed. First token is reported separately.'**
  String benchmarkDescription(int tokens);

  /// No description provided for @benchmarkTokensPerSecond.
  ///
  /// In en, this message translates to:
  /// **'tokens / second'**
  String get benchmarkTokensPerSecond;

  /// No description provided for @benchmarkIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get benchmarkIdle;

  /// No description provided for @benchmarkMeasuring.
  ///
  /// In en, this message translates to:
  /// **'MEASURING'**
  String get benchmarkMeasuring;

  /// No description provided for @benchmarkThroughput.
  ///
  /// In en, this message translates to:
  /// **'Throughput over the run'**
  String get benchmarkThroughput;

  /// No description provided for @benchmarkPeak.
  ///
  /// In en, this message translates to:
  /// **'peak {value}'**
  String benchmarkPeak(String value);

  /// No description provided for @benchmarkWarmingUp.
  ///
  /// In en, this message translates to:
  /// **'Warming up…'**
  String get benchmarkWarmingUp;

  /// No description provided for @benchmarkPlotEmpty.
  ///
  /// In en, this message translates to:
  /// **'Run a benchmark to plot it'**
  String get benchmarkPlotEmpty;

  /// No description provided for @benchmarkFirstToken.
  ///
  /// In en, this message translates to:
  /// **'First token'**
  String get benchmarkFirstToken;

  /// No description provided for @benchmarkTokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get benchmarkTokens;

  /// No description provided for @benchmarkTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get benchmarkTotal;

  /// No description provided for @benchmarkSampleOutput.
  ///
  /// In en, this message translates to:
  /// **'Sample output'**
  String get benchmarkSampleOutput;

  /// No description provided for @benchmarkThisSession.
  ///
  /// In en, this message translates to:
  /// **'This session'**
  String get benchmarkThisSession;

  /// No description provided for @benchmarkRunSummary.
  ///
  /// In en, this message translates to:
  /// **'{tokens} tokens · first token {firstToken} · total {total}'**
  String benchmarkRunSummary(int tokens, String firstToken, String total);

  /// No description provided for @benchmarkEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No models to measure'**
  String get benchmarkEmptyTitle;

  /// No description provided for @benchmarkEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Download a model to measure its speed.'**
  String get benchmarkEmptyBody;

  /// No description provided for @benchmarkBestForHardware.
  ///
  /// In en, this message translates to:
  /// **'Best for your hardware'**
  String get benchmarkBestForHardware;

  /// No description provided for @benchmarkMeasuredWithDevice.
  ///
  /// In en, this message translates to:
  /// **'{device} · measured {bandwidth} GB/s effective'**
  String benchmarkMeasuredWithDevice(String device, String bandwidth);

  /// No description provided for @benchmarkMeasured.
  ///
  /// In en, this message translates to:
  /// **'measured {bandwidth} GB/s effective'**
  String benchmarkMeasured(String bandwidth);

  /// No description provided for @benchmarkEstimateWithDevice.
  ///
  /// In en, this message translates to:
  /// **'{device} · run a benchmark to replace the estimates below with measurements'**
  String benchmarkEstimateWithDevice(String device);

  /// No description provided for @benchmarkCalibratePrompt.
  ///
  /// In en, this message translates to:
  /// **'Run a benchmark to calibrate these'**
  String get benchmarkCalibratePrompt;

  /// No description provided for @benchmarkInstalled.
  ///
  /// In en, this message translates to:
  /// **'installed'**
  String get benchmarkInstalled;

  /// No description provided for @tourBadge.
  ///
  /// In en, this message translates to:
  /// **'THINAI TOUR'**
  String get tourBadge;

  /// No description provided for @tourCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close Tour'**
  String get tourCloseTooltip;

  /// No description provided for @tourStageLabel.
  ///
  /// In en, this message translates to:
  /// **'STAGE {current} OF {total}'**
  String tourStageLabel(int current, int total);

  /// No description provided for @tourPrivateTag.
  ///
  /// In en, this message translates to:
  /// **'100% PRIVATE & SOVEREIGN'**
  String get tourPrivateTag;

  /// No description provided for @tourPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Hardware.\nYour Intelligence.'**
  String get tourPrivateTitle;

  /// No description provided for @tourPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'Thinai executes large language models directly on your phone’s processor. Zero chat queries, images, or documents ever leave your device.'**
  String get tourPrivateBody;

  /// No description provided for @tourOnDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Thinai (On-Device)'**
  String get tourOnDeviceTitle;

  /// No description provided for @tourOnDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Runs offline in Airplane mode · Zero data collection · llama.cpp silicon execution · No subscription'**
  String get tourOnDeviceBody;

  /// No description provided for @tourCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Traditional Cloud AI'**
  String get tourCloudTitle;

  /// No description provided for @tourCloudBody.
  ///
  /// In en, this message translates to:
  /// **'Logs queries on remote servers · Requires high-speed internet · Subject to monthly API paywalls'**
  String get tourCloudBody;

  /// No description provided for @tourDeviceReady.
  ///
  /// In en, this message translates to:
  /// **'Device Ready: Hardware acceleration available for local GGUF models.'**
  String get tourDeviceReady;

  /// No description provided for @tourCatalogTag.
  ///
  /// In en, this message translates to:
  /// **'CURATED GGUF CATALOG'**
  String get tourCatalogTag;

  /// No description provided for @tourCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'World-Class Models,\nTailored to Your RAM.'**
  String get tourCatalogTitle;

  /// No description provided for @tourCatalogBody.
  ///
  /// In en, this message translates to:
  /// **'Explore open-weight models from Alibaba, Meta, Google, and Microsoft. Thinai automatically inspects your phone’s memory to advise what runs smoothly.'**
  String get tourCatalogBody;

  /// No description provided for @tourMemoryFitTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Memory Fit System'**
  String get tourMemoryFitTitle;

  /// No description provided for @tourFitEasyLabel.
  ///
  /// In en, this message translates to:
  /// **'Fits Easily'**
  String get tourFitEasyLabel;

  /// No description provided for @tourFitEasyBody.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed smooth response, low battery footprint.'**
  String get tourFitEasyBody;

  /// No description provided for @tourFitTightLabel.
  ///
  /// In en, this message translates to:
  /// **'Tight Fit'**
  String get tourFitTightLabel;

  /// No description provided for @tourFitTightBody.
  ///
  /// In en, this message translates to:
  /// **'Runs well, close other heavy background apps.'**
  String get tourFitTightBody;

  /// No description provided for @tourFitTooBigLabel.
  ///
  /// In en, this message translates to:
  /// **'Too Big'**
  String get tourFitTooBigLabel;

  /// No description provided for @tourFitTooBigBody.
  ///
  /// In en, this message translates to:
  /// **'Warns you so your operating system never crashes.'**
  String get tourFitTooBigBody;

  /// No description provided for @tourStarterTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended Starter: {model} (~{size})'**
  String tourStarterTitle(String model, String size);

  /// No description provided for @tourStarterBody.
  ///
  /// In en, this message translates to:
  /// **'Smallest and fastest chat model, runs instantly on any phone.'**
  String get tourStarterBody;

  /// No description provided for @tourChatTag.
  ///
  /// In en, this message translates to:
  /// **'CHAT STUDIO & VISION'**
  String get tourChatTag;

  /// No description provided for @tourChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Full Multimodal Studio\nWith Live Reasoning.'**
  String get tourChatTitle;

  /// No description provided for @tourChatBody.
  ///
  /// In en, this message translates to:
  /// **'Chat with zero lag, attach camera photos for vision models, and watch real-time generation speed right on the response bubbles.'**
  String get tourChatBody;

  /// No description provided for @tourDemoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Explain quantum superposition simply.'**
  String get tourDemoPrompt;

  /// No description provided for @tourDemoReply.
  ///
  /// In en, this message translates to:
  /// **'A particle can exist in multiple possible states at once until measured, like a spinning coin before it lands.'**
  String get tourDemoReply;

  /// No description provided for @tourDemoSpeed.
  ///
  /// In en, this message translates to:
  /// **'⚡ {speed} t/s · On-Device'**
  String tourDemoSpeed(String speed);

  /// No description provided for @tourFeatureReasoning.
  ///
  /// In en, this message translates to:
  /// **'Reasoning Traces'**
  String get tourFeatureReasoning;

  /// No description provided for @tourFeatureVision.
  ///
  /// In en, this message translates to:
  /// **'Camera & Vision'**
  String get tourFeatureVision;

  /// No description provided for @tourFeaturePersonas.
  ///
  /// In en, this message translates to:
  /// **'Custom Personas'**
  String get tourFeaturePersonas;

  /// No description provided for @tourServerTag.
  ///
  /// In en, this message translates to:
  /// **'OPENAI COMPATIBLE API'**
  String get tourServerTag;

  /// No description provided for @tourServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn Your Phone Into\nA Private AI Server.'**
  String get tourServerTitle;

  /// No description provided for @tourServerBody.
  ///
  /// In en, this message translates to:
  /// **'Thinai includes a built-in HTTP server. Run on-device inference as a drop-in replacement for OpenAI and Ollama APIs for external developer tools.'**
  String get tourServerBody;

  /// No description provided for @tourEndpointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Localhost Endpoints'**
  String get tourEndpointsTitle;

  /// No description provided for @tourPortBadge.
  ///
  /// In en, this message translates to:
  /// **'PORT {port}'**
  String tourPortBadge(String port);

  /// No description provided for @tourCompatibleWith.
  ///
  /// In en, this message translates to:
  /// **'Compatible with: {tools}'**
  String tourCompatibleWith(String tools);

  /// No description provided for @tourStartTag.
  ///
  /// In en, this message translates to:
  /// **'READY TO LAUNCH'**
  String get tourStartTag;

  /// No description provided for @tourStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your\nStarting Point.'**
  String get tourStartTitle;

  /// No description provided for @tourStartBody.
  ///
  /// In en, this message translates to:
  /// **'Select how you want to experience Thinai today:'**
  String get tourStartBody;

  /// No description provided for @tourOptionStarterTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Download Starter Model ({model})'**
  String tourOptionStarterTitle(String model);

  /// No description provided for @tourOptionStarterBody.
  ///
  /// In en, this message translates to:
  /// **'Smallest verified model (~{size}). Fast download, runs smoothly on any device.'**
  String tourOptionStarterBody(String size);

  /// No description provided for @tourOptionStarterButton.
  ///
  /// In en, this message translates to:
  /// **'Get Starter Model'**
  String get tourOptionStarterButton;

  /// No description provided for @tourOptionCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Browse Complete Catalog'**
  String get tourOptionCatalogTitle;

  /// No description provided for @tourOptionCatalogBody.
  ///
  /// In en, this message translates to:
  /// **'Explore 30+ GGUF models from Meta, Google, Microsoft, and Alibaba.'**
  String get tourOptionCatalogBody;

  /// No description provided for @tourOptionCatalogButton.
  ///
  /// In en, this message translates to:
  /// **'Open Models Catalog'**
  String get tourOptionCatalogButton;

  /// No description provided for @tourOptionLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Take Live In-App Guided Tour'**
  String get tourOptionLiveTitle;

  /// No description provided for @tourOptionLiveBody.
  ///
  /// In en, this message translates to:
  /// **'Follow our step-by-step floating guide through the live tabs.'**
  String get tourOptionLiveBody;

  /// No description provided for @tourOptionLiveButton.
  ///
  /// In en, this message translates to:
  /// **'Start Live Guide'**
  String get tourOptionLiveButton;

  /// No description provided for @tourCompleteTour.
  ///
  /// In en, this message translates to:
  /// **'Complete Tour'**
  String get tourCompleteTour;

  /// No description provided for @tourNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get tourNextStep;

  /// No description provided for @tourDockStep.
  ///
  /// In en, this message translates to:
  /// **'STEP {step} OF {total}'**
  String tourDockStep(int step, int total);

  /// No description provided for @tourExitTour.
  ///
  /// In en, this message translates to:
  /// **'Exit Tour'**
  String get tourExitTour;

  /// No description provided for @tourPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get tourPrevious;

  /// No description provided for @tourFinishTour.
  ///
  /// In en, this message translates to:
  /// **'Finish Tour'**
  String get tourFinishTour;

  /// No description provided for @tourDockModelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Models Catalog (Tab 2)'**
  String get tourDockModelsTitle;

  /// No description provided for @tourDockModelsBody.
  ///
  /// In en, this message translates to:
  /// **'Browse verified GGUF models. Check the RAM fit indicator (Safe / Tight) to choose a model that runs smoothly on your phone.'**
  String get tourDockModelsBody;

  /// No description provided for @tourDockManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Management & Benchmarking'**
  String get tourDockManageTitle;

  /// No description provided for @tourDockManageBody.
  ///
  /// In en, this message translates to:
  /// **'Use the top-right icons to manage downloads or tap the Speedometer icon to benchmark real token generation speed on your phone.'**
  String get tourDockManageBody;

  /// No description provided for @tourDockChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Studio (Tab 1)'**
  String get tourDockChatTitle;

  /// No description provided for @tourDockChatBody.
  ///
  /// In en, this message translates to:
  /// **'Chat with full privacy. Attach photos or documents for multimodal analysis, and watch live tokens-per-second streaming.'**
  String get tourDockChatBody;

  /// No description provided for @tourDockServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Local API Server (Tab 3)'**
  String get tourDockServerTitle;

  /// No description provided for @tourDockServerBody.
  ///
  /// In en, this message translates to:
  /// **'Turn your phone into a private OpenAI-compatible endpoint on {address} for Cursor, Continue, or your own developer scripts.'**
  String tourDockServerBody(String address);

  /// No description provided for @tourAppTour.
  ///
  /// In en, this message translates to:
  /// **'App Tour'**
  String get tourAppTour;

  /// No description provided for @tourLocatingControl.
  ///
  /// In en, this message translates to:
  /// **'Locating control…'**
  String get tourLocatingControl;

  /// No description provided for @tourWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Thinai'**
  String get tourWelcomeTitle;

  /// No description provided for @tourWelcomeOfflineBadge.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get tourWelcomeOfflineBadge;

  /// No description provided for @tourWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sovereign on-device intelligence'**
  String get tourWelcomeSubtitle;

  /// No description provided for @tourWelcomePrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'100% Private & On-Device'**
  String get tourWelcomePrivateTitle;

  /// No description provided for @tourWelcomePrivateBody.
  ///
  /// In en, this message translates to:
  /// **'Models execute directly on your phone hardware. Zero data leaves your device and no internet is required.'**
  String get tourWelcomePrivateBody;

  /// No description provided for @tourWelcomeCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Curated Open Weights Catalog'**
  String get tourWelcomeCatalogTitle;

  /// No description provided for @tourWelcomeCatalogBody.
  ///
  /// In en, this message translates to:
  /// **'Download verified GGUF models from Meta, Google, Microsoft, and Alibaba with one tap.'**
  String get tourWelcomeCatalogBody;

  /// No description provided for @tourWelcomeChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Rich Chat & Multimodal'**
  String get tourWelcomeChatTitle;

  /// No description provided for @tourWelcomeChatBody.
  ///
  /// In en, this message translates to:
  /// **'Chat with high speed, attach images or documents, and manage conversations with full control.'**
  String get tourWelcomeChatBody;

  /// No description provided for @tourWelcomeStartTour.
  ///
  /// In en, this message translates to:
  /// **'Start Interactive App Tour'**
  String get tourWelcomeStartTour;

  /// No description provided for @tourWelcomeBrowseCatalog.
  ///
  /// In en, this message translates to:
  /// **'Browse Catalog'**
  String get tourWelcomeBrowseCatalog;

  /// No description provided for @tourWelcomeSkipToChat.
  ///
  /// In en, this message translates to:
  /// **'Skip to Chat'**
  String get tourWelcomeSkipToChat;

  /// No description provided for @onboardingLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'Thinai App Logo'**
  String get onboardingLogoLabel;

  /// No description provided for @onboardingPrivateTag.
  ///
  /// In en, this message translates to:
  /// **'100% PRIVATE & OFFLINE'**
  String get onboardingPrivateTag;

  /// No description provided for @onboardingPrivateHeadline.
  ///
  /// In en, this message translates to:
  /// **'True Intelligence,\nEntirely On Your Phone'**
  String get onboardingPrivateHeadline;

  /// No description provided for @onboardingPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'Thinai executes high-parameter AI models directly on your mobile hardware. Zero data leaves your phone, zero telemetry, and zero cloud reliance.'**
  String get onboardingPrivateBody;

  /// No description provided for @onboardingPrivateGraphic.
  ///
  /// In en, this message translates to:
  /// **'100% Private and Offline AI'**
  String get onboardingPrivateGraphic;

  /// No description provided for @onboardingPrivateBullet1.
  ///
  /// In en, this message translates to:
  /// **'Zero data leaves your device RAM or storage'**
  String get onboardingPrivateBullet1;

  /// No description provided for @onboardingPrivateBullet2.
  ///
  /// In en, this message translates to:
  /// **'Fully functional offline & in Airplane mode'**
  String get onboardingPrivateBullet2;

  /// No description provided for @onboardingCatalogTag.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED GGUF CATALOG'**
  String get onboardingCatalogTag;

  /// No description provided for @onboardingCatalogHeadline.
  ///
  /// In en, this message translates to:
  /// **'Curated Open Weights\nIn a Single Tap'**
  String get onboardingCatalogHeadline;

  /// No description provided for @onboardingCatalogBody.
  ///
  /// In en, this message translates to:
  /// **'Download state-of-the-art open models directly from HuggingFace. Quantized with modern precision for smooth mobile execution.'**
  String get onboardingCatalogBody;

  /// No description provided for @onboardingCatalogGraphic.
  ///
  /// In en, this message translates to:
  /// **'Curated GGUF Model Catalog'**
  String get onboardingCatalogGraphic;

  /// No description provided for @onboardingCatalogBullet1.
  ///
  /// In en, this message translates to:
  /// **'DeepSeek, Meta Llama, Google Gemma & Qwen'**
  String get onboardingCatalogBullet1;

  /// No description provided for @onboardingCatalogBullet2.
  ///
  /// In en, this message translates to:
  /// **'Automatic background resume with foreground service'**
  String get onboardingCatalogBullet2;

  /// No description provided for @onboardingGpuTag.
  ///
  /// In en, this message translates to:
  /// **'HARDWARE ACCELERATION'**
  String get onboardingGpuTag;

  /// No description provided for @onboardingGpuHeadline.
  ///
  /// In en, this message translates to:
  /// **'Llama.cpp Engine\nWith Adreno & Mali GPU'**
  String get onboardingGpuHeadline;

  /// No description provided for @onboardingGpuBody.
  ///
  /// In en, this message translates to:
  /// **'Built with native llama.cpp compiled for ARM64 with Qualcomm Adreno OpenCL and ARM Mali Vulkan GPU layer offloading.'**
  String get onboardingGpuBody;

  /// No description provided for @onboardingGpuGraphic.
  ///
  /// In en, this message translates to:
  /// **'GPU Hardware Acceleration Rocket'**
  String get onboardingGpuGraphic;

  /// No description provided for @onboardingGpuBullet1.
  ///
  /// In en, this message translates to:
  /// **'Hardware GPU acceleration for instant response'**
  String get onboardingGpuBullet1;

  /// No description provided for @onboardingGpuBullet2.
  ///
  /// In en, this message translates to:
  /// **'Live tokens/sec metrics and thermal-safe limits'**
  String get onboardingGpuBullet2;

  /// No description provided for @onboardingStudioTag.
  ///
  /// In en, this message translates to:
  /// **'MULTIMODAL STUDIO'**
  String get onboardingStudioTag;

  /// No description provided for @onboardingStudioHeadline.
  ///
  /// In en, this message translates to:
  /// **'Vision, Documents\n& Live Web Synthesis'**
  String get onboardingStudioHeadline;

  /// No description provided for @onboardingStudioBody.
  ///
  /// In en, this message translates to:
  /// **'Engage in smart conversations with vision models, attach PDF & text files for instant summaries, and query live web results on-demand.'**
  String get onboardingStudioBody;

  /// No description provided for @onboardingStudioGraphic.
  ///
  /// In en, this message translates to:
  /// **'Multimodal Vision and Document QA'**
  String get onboardingStudioGraphic;

  /// No description provided for @onboardingStudioBullet1.
  ///
  /// In en, this message translates to:
  /// **'Multimodal vision image inspection (Gemma, MiniCPM)'**
  String get onboardingStudioBullet1;

  /// No description provided for @onboardingStudioBullet2.
  ///
  /// In en, this message translates to:
  /// **'Privacy-preserving web search & document QA'**
  String get onboardingStudioBullet2;

  /// No description provided for @onboardingServerTag.
  ///
  /// In en, this message translates to:
  /// **'LOCAL DEVELOPER API'**
  String get onboardingServerTag;

  /// No description provided for @onboardingServerHeadline.
  ///
  /// In en, this message translates to:
  /// **'Turn Your Phone\nInto a Local AI Server'**
  String get onboardingServerHeadline;

  /// No description provided for @onboardingServerBody.
  ///
  /// In en, this message translates to:
  /// **'Expose an OpenAI & Ollama compatible REST API on port {port}. Seamlessly connect VS Code extensions, Cline, Cursor, or terminal scripts.'**
  String onboardingServerBody(String port);

  /// No description provided for @onboardingServerGraphic.
  ///
  /// In en, this message translates to:
  /// **'Local AI Server on Port {port}'**
  String onboardingServerGraphic(String port);

  /// No description provided for @onboardingServerBullet1.
  ///
  /// In en, this message translates to:
  /// **'Compatible with OpenAI SDK & Ollama CLI'**
  String get onboardingServerBullet1;

  /// No description provided for @onboardingServerBullet2.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi LAN sharing to serve laptops on your network'**
  String get onboardingServerBullet2;

  /// No description provided for @onboardingStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Using Thinai Now'**
  String get onboardingStartButton;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'SOVEREIGN ON-DEVICE INTELLIGENCE'**
  String get splashTagline;

  /// Splash footer. {place} is splashPlace, drawn in brand green.
  ///
  /// In en, this message translates to:
  /// **'CRAFTED IN {place}'**
  String splashCraftedIn(String place);

  /// No description provided for @splashPlace.
  ///
  /// In en, this message translates to:
  /// **'ERODE, TAMIL NADU'**
  String get splashPlace;

  /// Credit line. {heart} is the heart emoji, {place} is brandPlace (drawn in brand green).
  ///
  /// In en, this message translates to:
  /// **'Made with {heart} in {place}'**
  String brandMadeWith(String heart, String place);

  /// Place name as it appears inside brandMadeWith; in Tamil it carries the locative case.
  ///
  /// In en, this message translates to:
  /// **'Erode, Tamilnadu'**
  String get brandPlace;

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
