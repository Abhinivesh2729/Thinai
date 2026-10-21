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
