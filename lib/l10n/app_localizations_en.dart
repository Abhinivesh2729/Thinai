// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageSetting => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonShare => 'Share';

  @override
  String get commonDownload => 'Download';

  @override
  String get commonResume => 'Resume';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonDone => 'Done';

  @override
  String get commonLater => 'Later';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonRename => 'Rename';

  @override
  String get commonOn => 'On';

  @override
  String get commonOff => 'Off';

  @override
  String get navChat => 'Chat';

  @override
  String get navModels => 'Models';

  @override
  String get navServer => 'Server';

  @override
  String get navSettings => 'Settings';

  @override
  String get tourBadge => 'THINAI TOUR';

  @override
  String get tourCloseTooltip => 'Close Tour';

  @override
  String tourStageLabel(int current, int total) {
    return 'STAGE $current OF $total';
  }

  @override
  String get tourPrivateTag => '100% PRIVATE & SOVEREIGN';

  @override
  String get tourPrivateTitle => 'Your Hardware.\nYour Intelligence.';

  @override
  String get tourPrivateBody =>
      'Thinai executes large language models directly on your phone’s processor. Zero chat queries, images, or documents ever leave your device.';

  @override
  String get tourOnDeviceTitle => 'Thinai (On-Device)';

  @override
  String get tourOnDeviceBody =>
      'Runs offline in Airplane mode · Zero data collection · llama.cpp silicon execution · No subscription';

  @override
  String get tourCloudTitle => 'Traditional Cloud AI';

  @override
  String get tourCloudBody =>
      'Logs queries on remote servers · Requires high-speed internet · Subject to monthly API paywalls';

  @override
  String get tourDeviceReady =>
      'Device Ready: Hardware acceleration available for local GGUF models.';

  @override
  String get tourCatalogTag => 'CURATED GGUF CATALOG';

  @override
  String get tourCatalogTitle => 'World-Class Models,\nTailored to Your RAM.';

  @override
  String get tourCatalogBody =>
      'Explore open-weight models from Alibaba, Meta, Google, and Microsoft. Thinai automatically inspects your phone’s memory to advise what runs smoothly.';

  @override
  String get tourMemoryFitTitle => 'Smart Memory Fit System';

  @override
  String get tourFitEasyLabel => 'Fits Easily';

  @override
  String get tourFitEasyBody =>
      'Guaranteed smooth response, low battery footprint.';

  @override
  String get tourFitTightLabel => 'Tight Fit';

  @override
  String get tourFitTightBody =>
      'Runs well, close other heavy background apps.';

  @override
  String get tourFitTooBigLabel => 'Too Big';

  @override
  String get tourFitTooBigBody =>
      'Warns you so your operating system never crashes.';

  @override
  String tourStarterTitle(String model, String size) {
    return 'Recommended Starter: $model (~$size)';
  }

  @override
  String get tourStarterBody =>
      'Smallest and fastest chat model, runs instantly on any phone.';

  @override
  String get tourChatTag => 'CHAT STUDIO & VISION';

  @override
  String get tourChatTitle => 'Full Multimodal Studio\nWith Live Reasoning.';

  @override
  String get tourChatBody =>
      'Chat with zero lag, attach camera photos for vision models, and watch real-time generation speed right on the response bubbles.';

  @override
  String get tourDemoPrompt => 'Explain quantum superposition simply.';

  @override
  String get tourDemoReply =>
      'A particle can exist in multiple possible states at once until measured, like a spinning coin before it lands.';

  @override
  String tourDemoSpeed(String speed) {
    return '⚡ $speed t/s · On-Device';
  }

  @override
  String get tourFeatureReasoning => 'Reasoning Traces';

  @override
  String get tourFeatureVision => 'Camera & Vision';

  @override
  String get tourFeaturePersonas => 'Custom Personas';

  @override
  String get tourServerTag => 'OPENAI COMPATIBLE API';

  @override
  String get tourServerTitle => 'Turn Your Phone Into\nA Private AI Server.';

  @override
  String get tourServerBody =>
      'Thinai includes a built-in HTTP server. Run on-device inference as a drop-in replacement for OpenAI and Ollama APIs for external developer tools.';

  @override
  String get tourEndpointsTitle => 'Localhost Endpoints';

  @override
  String tourPortBadge(String port) {
    return 'PORT $port';
  }

  @override
  String tourCompatibleWith(String tools) {
    return 'Compatible with: $tools';
  }

  @override
  String get tourStartTag => 'READY TO LAUNCH';

  @override
  String get tourStartTitle => 'Choose Your\nStarting Point.';

  @override
  String get tourStartBody => 'Select how you want to experience Thinai today:';

  @override
  String tourOptionStarterTitle(String model) {
    return '1. Download Starter Model ($model)';
  }

  @override
  String tourOptionStarterBody(String size) {
    return 'Smallest verified model (~$size). Fast download, runs smoothly on any device.';
  }

  @override
  String get tourOptionStarterButton => 'Get Starter Model';

  @override
  String get tourOptionCatalogTitle => '2. Browse Complete Catalog';

  @override
  String get tourOptionCatalogBody =>
      'Explore 30+ GGUF models from Meta, Google, Microsoft, and Alibaba.';

  @override
  String get tourOptionCatalogButton => 'Open Models Catalog';

  @override
  String get tourOptionLiveTitle => '3. Take Live In-App Guided Tour';

  @override
  String get tourOptionLiveBody =>
      'Follow our step-by-step floating guide through the live tabs.';

  @override
  String get tourOptionLiveButton => 'Start Live Guide';

  @override
  String get tourCompleteTour => 'Complete Tour';

  @override
  String get tourNextStep => 'Next Step';

  @override
  String tourDockStep(int step, int total) {
    return 'STEP $step OF $total';
  }

  @override
  String get tourExitTour => 'Exit Tour';

  @override
  String get tourPrevious => 'Previous';

  @override
  String get tourFinishTour => 'Finish Tour';

  @override
  String get tourDockModelsTitle => 'Models Catalog (Tab 2)';

  @override
  String get tourDockModelsBody =>
      'Browse verified GGUF models. Check the RAM fit indicator (Safe / Tight) to choose a model that runs smoothly on your phone.';

  @override
  String get tourDockManageTitle => 'Management & Benchmarking';

  @override
  String get tourDockManageBody =>
      'Use the top-right icons to manage downloads or tap the Speedometer icon to benchmark real token generation speed on your phone.';

  @override
  String get tourDockChatTitle => 'Chat Studio (Tab 1)';

  @override
  String get tourDockChatBody =>
      'Chat with full privacy. Attach photos or documents for multimodal analysis, and watch live tokens-per-second streaming.';

  @override
  String get tourDockServerTitle => 'Local API Server (Tab 3)';

  @override
  String tourDockServerBody(String address) {
    return 'Turn your phone into a private OpenAI-compatible endpoint on $address for Cursor, Continue, or your own developer scripts.';
  }

  @override
  String get tourAppTour => 'App Tour';

  @override
  String get tourLocatingControl => 'Locating control…';

  @override
  String get tourWelcomeTitle => 'Welcome to Thinai';

  @override
  String get tourWelcomeOfflineBadge => 'OFFLINE';

  @override
  String get tourWelcomeSubtitle => 'Sovereign on-device intelligence';

  @override
  String get tourWelcomePrivateTitle => '100% Private & On-Device';

  @override
  String get tourWelcomePrivateBody =>
      'Models execute directly on your phone hardware. Zero data leaves your device and no internet is required.';

  @override
  String get tourWelcomeCatalogTitle => 'Curated Open Weights Catalog';

  @override
  String get tourWelcomeCatalogBody =>
      'Download verified GGUF models from Meta, Google, Microsoft, and Alibaba with one tap.';

  @override
  String get tourWelcomeChatTitle => 'Rich Chat & Multimodal';

  @override
  String get tourWelcomeChatBody =>
      'Chat with high speed, attach images or documents, and manage conversations with full control.';

  @override
  String get tourWelcomeStartTour => 'Start Interactive App Tour';

  @override
  String get tourWelcomeBrowseCatalog => 'Browse Catalog';

  @override
  String get tourWelcomeSkipToChat => 'Skip to Chat';

  @override
  String get onboardingLogoLabel => 'Thinai App Logo';

  @override
  String get onboardingPrivateTag => '100% PRIVATE & OFFLINE';

  @override
  String get onboardingPrivateHeadline =>
      'True Intelligence,\nEntirely On Your Phone';

  @override
  String get onboardingPrivateBody =>
      'Thinai executes high-parameter AI models directly on your mobile hardware. Zero data leaves your phone, zero telemetry, and zero cloud reliance.';

  @override
  String get onboardingPrivateGraphic => '100% Private and Offline AI';

  @override
  String get onboardingPrivateBullet1 =>
      'Zero data leaves your device RAM or storage';

  @override
  String get onboardingPrivateBullet2 =>
      'Fully functional offline & in Airplane mode';

  @override
  String get onboardingCatalogTag => 'VERIFIED GGUF CATALOG';

  @override
  String get onboardingCatalogHeadline =>
      'Curated Open Weights\nIn a Single Tap';

  @override
  String get onboardingCatalogBody =>
      'Download state-of-the-art open models directly from HuggingFace. Quantized with modern precision for smooth mobile execution.';

  @override
  String get onboardingCatalogGraphic => 'Curated GGUF Model Catalog';

  @override
  String get onboardingCatalogBullet1 =>
      'DeepSeek, Meta Llama, Google Gemma & Qwen';

  @override
  String get onboardingCatalogBullet2 =>
      'Automatic background resume with foreground service';

  @override
  String get onboardingGpuTag => 'HARDWARE ACCELERATION';

  @override
  String get onboardingGpuHeadline =>
      'Llama.cpp Engine\nWith Adreno & Mali GPU';

  @override
  String get onboardingGpuBody =>
      'Built with native llama.cpp compiled for ARM64 with Qualcomm Adreno OpenCL and ARM Mali Vulkan GPU layer offloading.';

  @override
  String get onboardingGpuGraphic => 'GPU Hardware Acceleration Rocket';

  @override
  String get onboardingGpuBullet1 =>
      'Hardware GPU acceleration for instant response';

  @override
  String get onboardingGpuBullet2 =>
      'Live tokens/sec metrics and thermal-safe limits';

  @override
  String get onboardingStudioTag => 'MULTIMODAL STUDIO';

  @override
  String get onboardingStudioHeadline =>
      'Vision, Documents\n& Live Web Synthesis';

  @override
  String get onboardingStudioBody =>
      'Engage in smart conversations with vision models, attach PDF & text files for instant summaries, and query live web results on-demand.';

  @override
  String get onboardingStudioGraphic => 'Multimodal Vision and Document QA';

  @override
  String get onboardingStudioBullet1 =>
      'Multimodal vision image inspection (Gemma, MiniCPM)';

  @override
  String get onboardingStudioBullet2 =>
      'Privacy-preserving web search & document QA';

  @override
  String get onboardingServerTag => 'LOCAL DEVELOPER API';

  @override
  String get onboardingServerHeadline =>
      'Turn Your Phone\nInto a Local AI Server';

  @override
  String onboardingServerBody(String port) {
    return 'Expose an OpenAI & Ollama compatible REST API on port $port. Seamlessly connect VS Code extensions, Cline, Cursor, or terminal scripts.';
  }

  @override
  String onboardingServerGraphic(String port) {
    return 'Local AI Server on Port $port';
  }

  @override
  String get onboardingServerBullet1 =>
      'Compatible with OpenAI SDK & Ollama CLI';

  @override
  String get onboardingServerBullet2 =>
      'Wi-Fi LAN sharing to serve laptops on your network';

  @override
  String get onboardingStartButton => 'Start Using Thinai Now';

  @override
  String get splashTagline => 'SOVEREIGN ON-DEVICE INTELLIGENCE';

  @override
  String splashCraftedIn(String place) {
    return 'CRAFTED IN $place';
  }

  @override
  String get splashPlace => 'ERODE, TAMIL NADU';

  @override
  String brandMadeWith(String heart, String place) {
    return 'Made with $heart in $place';
  }

  @override
  String get brandPlace => 'Erode, Tamilnadu';
}
