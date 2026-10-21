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
