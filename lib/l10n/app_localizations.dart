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
