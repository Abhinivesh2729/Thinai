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
  String get commonOk => 'OK';

  @override
  String get commonCopy => 'Copy';

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
  String get serverToastLanNoAddress =>
      'LAN is on, but no Wi-Fi address was found.';

  @override
  String serverToastStartFailed(String error) {
    return 'Start failed: $error';
  }

  @override
  String get serverPortDialogTitle => 'Server port';

  @override
  String get serverPortNumberLabel => 'Port number';

  @override
  String get serverStatusRunning => 'Running';

  @override
  String get serverStatusStopped => 'Stopped';

  @override
  String get serverStart => 'Start';

  @override
  String get serverStop => 'Stop';

  @override
  String get serverCopyAddressTooltip => 'Copy address';

  @override
  String serverCopiedLabel(String label) {
    return 'Copied $label';
  }

  @override
  String get serverServingModel => 'SERVING MODEL';

  @override
  String get serverTune => 'Tune';

  @override
  String get serverNoModelLoaded => 'No model loaded';

  @override
  String get serverBrowseModels => 'Choose model';

  @override
  String get serverRegenerateTokenTitle => 'Regenerate token?';

  @override
  String get serverRegenerateTokenBody =>
      'LAN devices will need the new token.';

  @override
  String get serverRegenerate => 'Regenerate';

  @override
  String get serverTokenRegenerated => 'Token regenerated';

  @override
  String get serverLanShareTitle => 'Share on LAN';

  @override
  String get serverLanShareOnSubtitle => 'Devices on this Wi-Fi can connect';

  @override
  String serverLanShareOffSubtitle(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'This $_temp0 only';
  }

  @override
  String get serverCopyLanUrlTooltip => 'Copy LAN URL';

  @override
  String get serverDevQuickStartTitle => 'Quick start';

  @override
  String get serverEndpointOpenAiChat => 'OpenAI chat';

  @override
  String get serverEndpointOllamaChat => 'Ollama chat';

  @override
  String get serverEndpointEmbeddings => 'Embeddings';

  @override
  String get serverEndpointModels => 'Installed models';

  @override
  String get serverApiEndpointsTitle => 'API Endpoints';

  @override
  String get serverCopyCurlTooltip => 'Copy cURL';

  @override
  String get hfSearchHint => 'Search GGUF models';

  @override
  String get hfSearchFailedTitle => 'Search did not work';

  @override
  String get hfTryAgain => 'Try again';

  @override
  String get hfEmptyTitle => 'Find any GGUF model';

  @override
  String get hfEmptyMessage => 'Try \"gemma\", \"phi\" or \"unsloth\".';

  @override
  String hfNoMatchTitle(String query) {
    return 'No GGUF models match \"$query\"';
  }

  @override
  String get hfNoMatchMessage => 'Try a shorter name.';

  @override
  String hfResultsTitle(int count) {
    return 'Results ($count)';
  }

  @override
  String get hfResultsSubtitle => 'Most downloaded first';

  @override
  String get hfDownloadTitle => 'Download model?';

  @override
  String hfTooBigTitle(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Too big for this $_temp0?';
  }

  @override
  String get hfDownloadAnyway => 'Download anyway';

  @override
  String hfDownloadMessage(String file, String size) {
    return 'Download $file ($size)?';
  }

  @override
  String hfDownloadMessageTooBig(String device, String file, String size) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Download $file ($size)?\n\nLikely too big to load on this $_temp0.';
  }

  @override
  String hfDownloadMessageTooBigBudget(
    String device,
    String file,
    String size,
    String needs,
    String budget,
  ) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Download $file ($size)?\n\nNeeds about $needs of memory, this $_temp0 has $budget. It will probably not load.';
  }

  @override
  String hfDownloadMessageTight(String file, String size) {
    return 'Download $file ($size)?\n\nA tight fit. Other apps may close.';
  }

  @override
  String get hfOpenFailedTitle => 'Could not open this model';

  @override
  String get hfSignInTitle => 'Sign-in required';

  @override
  String get hfSignInMessage =>
      'Needs a Hugging Face account. Not supported yet.';

  @override
  String hfFilesTitle(int count) {
    return 'GGUF files ($count)';
  }

  @override
  String get hfFilesSubtitle => 'Smaller files run faster';

  @override
  String hfSkippedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count split or helper files hidden',
      one: '1 split or helper file hidden',
    );
    return '$_temp0';
  }

  @override
  String get hfNothingTitle => 'Nothing to install here';

  @override
  String get hfNothingMessage => 'No single-file GGUF that Thinai can load.';

  @override
  String get hfNetworkNotice => 'Search uses the internet. Chats stay private.';

  @override
  String get hfAgoToday => 'today';

  @override
  String hfAgoDays(int count) {
    return '${count}d ago';
  }

  @override
  String hfAgoMonths(int count) {
    return '${count}mo ago';
  }

  @override
  String hfAgoYears(int count) {
    return '${count}y ago';
  }

  @override
  String hfByAuthor(String author) {
    return 'by $author';
  }

  @override
  String get hfNoLicence => 'No licence';

  @override
  String get hfInstalled => 'Installed';

  @override
  String get hfPause => 'Pause';

  @override
  String get hfFindMore => 'Find more on Hugging Face';

  @override
  String hfSearchFor(String query) {
    return 'Search Hugging Face for \"$query\"';
  }

  @override
  String get hfPromptSubtitle => 'Any public GGUF model. Uses the internet.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsSystemPrompt => 'System Prompt';

  @override
  String get settingsHardware => 'Hardware';

  @override
  String get settingsModelStorage => 'Model & Storage';

  @override
  String get settingsLocalServer => 'Local Server';

  @override
  String get settingsAboutGuidance => 'About & Help';

  @override
  String get settingsStartPage => 'Start page';

  @override
  String get settingsThemeMode => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsWebSearch => 'Web search';

  @override
  String get settingsGpuAcceleration => 'GPU acceleration';

  @override
  String get settingsGpuAuto => 'Auto';

  @override
  String get settingsBenchmarkDevice => 'Benchmark';

  @override
  String get settingsGpuDiagnostics => 'GPU speed test';

  @override
  String get settingsDeviceSpecs => 'Device';

  @override
  String settingsDeviceSpecsWithRam(int cores, String ramGb) {
    return '$cores cores · $ramGb GB RAM';
  }

  @override
  String settingsDeviceSpecsCores(int cores) {
    return '$cores CPU cores';
  }

  @override
  String settingsImported(String name) {
    return 'Imported $name';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get settingsDownloadStarted => 'Download started';

  @override
  String settingsDownloadStopped(String error) {
    return 'Download stopped: $error. Resume it from Models.';
  }

  @override
  String settingsDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get settingsDownloadComplete => 'Download complete';

  @override
  String get settingsClearDownloadsTitle => 'Delete all downloads?';

  @override
  String get settingsClearDownloadsBody =>
      'Deletes every downloaded model to free up space.';

  @override
  String get settingsNoDownloadsFound => 'Nothing to clear';

  @override
  String settingsClearedDownloads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cleared $count downloads',
      one: 'Cleared 1 download',
    );
    return '$_temp0';
  }

  @override
  String settingsClearFailed(String error) {
    return 'Clear failed: $error';
  }

  @override
  String get settingsTune => 'Tune';

  @override
  String get settingsNoActiveModel => 'No model loaded';

  @override
  String get settingsCatalog => 'Catalog';

  @override
  String get settingsImportGguf => 'Import .gguf';

  @override
  String get settingsDownloadFromUrl => 'Download from URL';

  @override
  String get settingsClearDownloadedModels => 'Clear downloads';

  @override
  String get settingsChangePortTitle => 'Server port';

  @override
  String settingsPortSetRestart(int port) {
    return 'Port set to $port. Restart the server to apply.';
  }

  @override
  String settingsPortSet(int port) {
    return 'Port set to $port';
  }

  @override
  String get settingsShareApiWifi => 'Share on Wi-Fi';

  @override
  String get settingsServerPort => 'Port';

  @override
  String get settingsServerStatus => 'Status';

  @override
  String get settingsServerActive => 'Running';

  @override
  String get settingsServerOffline => 'Stopped';

  @override
  String get settingsUpToDate => 'Thinai is up to date';

  @override
  String get settingsUpdateUnavailable => 'Couldn\'t check for updates';

  @override
  String get settingsUpdateAlreadyDownloading => 'Update already downloading';

  @override
  String get settingsUpdateDownloading => 'Downloading update…';

  @override
  String get settingsUpdateFailed => 'Update failed. Try Play Store.';

  @override
  String get settingsUpdateReadyTitle => 'Update ready';

  @override
  String get settingsUpdateReadyBody => 'Restart Thinai to install it.';

  @override
  String get settingsRestart => 'Restart';

  @override
  String get settingsStartTour => 'App tour';

  @override
  String get settingsCheckUpdates => 'Check for updates';

  @override
  String get settingsContactSupport => 'Help & support';

  @override
  String get settingsAboutThinai => 'About Thinai';

  @override
  String get settingsDirectGgufUrl => 'GGUF URL';

  @override
  String get settingsSaveAsOptional => 'Name (optional)';

  @override
  String get gpuAcceleration => 'GPU acceleration';

  @override
  String get gpuDescription => 'Run the speed test to see if it helps.';

  @override
  String gpuCrashedNotice(String backend) {
    return '$backend crashed last time, so the GPU was turned off.';
  }

  @override
  String get gpuCheckPhone => 'Find GPU';

  @override
  String get gpuNoneFound => 'No usable GPU. Using the CPU.';

  @override
  String gpuFound(String devices) {
    return 'Found: $devices';
  }

  @override
  String get gpuAuto => 'Auto';

  @override
  String gpuAutoWith(String backend) {
    return 'Auto ($backend)';
  }

  @override
  String get gpuTesting => 'Testing…';

  @override
  String get gpuSpeedTest => 'Speed test';

  @override
  String get gpuLoadModelFirst => 'Load a model first.';

  @override
  String gpuTestFailed(String error) {
    return 'Test failed: $error';
  }

  @override
  String get gpuVerdictGpuFaster => 'GPU is faster here.';

  @override
  String get gpuVerdictCpuFaster => 'CPU is faster here. Keep the GPU off.';

  @override
  String get gpuVerdictSame => 'About the same.';

  @override
  String get gpuReadingPrompt => 'Prompt';

  @override
  String get gpuWritingReply => 'Reply';

  @override
  String get aboutTitle => 'About Thinai';

  @override
  String aboutHeroDescription(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Private AI that runs on your $_temp0. No internet needed.';
  }

  @override
  String get aboutPrivateTitle => 'Private and offline';

  @override
  String get aboutAcceleratedTitle => 'GPU acceleration';

  @override
  String get aboutApiTitle => 'Local OpenAI-compatible API';

  @override
  String get aboutVisionTitle => 'Images, documents, web search';

  @override
  String get aboutSpecEngine => 'Engine';

  @override
  String get aboutSpecModelFormat => 'Format';

  @override
  String get aboutSpecArchitecture => 'Architecture';

  @override
  String get aboutSpecBackends => 'Backends';

  @override
  String get aboutSpecLicense => 'License';

  @override
  String get aboutSpecLicenseValue => 'MIT';

  @override
  String get aboutLicenses => 'Licenses';

  @override
  String get aboutContactSupport => 'Support';

  @override
  String get supportTitle => 'Help & Support';

  @override
  String supportCouldNotOpenLink(String url) {
    return 'Could not open link: $url';
  }

  @override
  String supportFailedToOpenLink(String error) {
    return 'Failed to open link: $error';
  }

  @override
  String get supportInstagramBody => 'Message us for help or to report a bug.';

  @override
  String get supportInstagramOpenFailed => 'Couldn\'t open Instagram';

  @override
  String get supportOpenInstagram => 'Open Instagram';

  @override
  String get supportCopyHandle => 'Copy handle';

  @override
  String get supportHandleCopied => 'Handle copied';

  @override
  String get supportDiagnostics => 'Device info';

  @override
  String get supportDiagnosticsHint => 'Include this when you contact us.';

  @override
  String supportCpuCores(int cores) {
    return '$cores CPU cores';
  }

  @override
  String supportTier(String tier) {
    return 'Tier: $tier';
  }

  @override
  String supportModel(String model) {
    return 'Model: $model';
  }

  @override
  String get supportNoActiveModel => 'No model loaded';

  @override
  String get supportServerActive => 'Server running';

  @override
  String get supportServerStopped => 'Server stopped';

  @override
  String get supportCopyDiagnostics => 'Copy device info';

  @override
  String get supportDiagnosticsCopied => 'Device info copied';

  @override
  String get supportTroubleshooting => 'Common questions';

  @override
  String get supportFaqLoadQuestion => 'Why is loading or downloading slow?';

  @override
  String get supportFaqLoadAnswer =>
      'Models are 1 to 4 GB. Downloads depend on your connection, and loading needs free RAM, so close other apps first.';

  @override
  String supportFaqPrivacyQuestion(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Do my chats leave the $_temp0?';
  }

  @override
  String supportFaqPrivacyAnswer(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'No. Models run entirely on your $_temp0, and your chats stay on it.';
  }

  @override
  String get supportFaqGpuQuestion => 'How do I use the GPU?';

  @override
  String get supportFaqGpuAnswer =>
      'Go to Settings > Hardware > GPU acceleration. Run the speed test to check it is faster.';

  @override
  String get systemPromptTitle => 'System Prompt';

  @override
  String get systemPromptSaved => 'System prompt saved';

  @override
  String get systemPromptResetDone => 'Reset to default';

  @override
  String get systemPromptDescription =>
      'Sent to the model at the start of every chat. Leave empty to use the model\'s default.';

  @override
  String get systemPromptHint => 'You are a helpful assistant…';

  @override
  String systemPromptCharacters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters',
      one: '1 character',
    );
    return '$_temp0';
  }

  @override
  String get systemPromptResetToDefault => 'Reset to default';

  @override
  String get benchmarkTitle => 'Benchmark';

  @override
  String get benchmarkStop => 'Stop';

  @override
  String benchmarkError(String error) {
    return 'Error: $error';
  }

  @override
  String get benchmarkRunning => 'Running…';

  @override
  String get benchmarkRun => 'Run benchmark';

  @override
  String get benchmarkTokensPerSecond => 'tokens / second';

  @override
  String get benchmarkIdle => 'Ready';

  @override
  String get benchmarkMeasuring => 'MEASURING';

  @override
  String get benchmarkThroughput => 'Speed';

  @override
  String benchmarkPeak(String value) {
    return 'peak $value';
  }

  @override
  String get benchmarkWarmingUp => 'Warming up…';

  @override
  String get benchmarkPlotEmpty => 'No data yet';

  @override
  String get benchmarkFirstToken => 'First token';

  @override
  String get benchmarkTokens => 'Tokens';

  @override
  String get benchmarkTotal => 'Total';

  @override
  String get benchmarkSampleOutput => 'Output';

  @override
  String get benchmarkThisSession => 'This session';

  @override
  String benchmarkRunSummary(int tokens, String firstToken, String total) {
    return '$tokens tokens · first $firstToken · total $total';
  }

  @override
  String get benchmarkEmptyTitle => 'No models to measure';

  @override
  String get benchmarkEmptyBody => 'Download a model to measure its speed.';

  @override
  String benchmarkBestForHardware(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Best for this $_temp0';
  }

  @override
  String benchmarkMeasuredWithDevice(String device, String bandwidth) {
    return '$device · $bandwidth GB/s measured';
  }

  @override
  String benchmarkMeasured(String bandwidth) {
    return '$bandwidth GB/s measured';
  }

  @override
  String benchmarkEstimateWithDevice(String device) {
    return '$device · estimated';
  }

  @override
  String get benchmarkCalibratePrompt => 'Estimated';

  @override
  String get benchmarkInstalled => 'installed';

  @override
  String get tourBadge => 'THINAI TOUR';

  @override
  String get tourCloseTooltip => 'Close tour';

  @override
  String tourStageLabel(int current, int total) {
    return 'STAGE $current OF $total';
  }

  @override
  String get tourPrivateTag => 'PRIVATE BY DESIGN';

  @override
  String tourPrivateTitle(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Your $_temp0.\nYour AI.';
  }

  @override
  String tourPrivateBody(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Models run on your $_temp0. Nothing leaves it.';
  }

  @override
  String get tourOnDeviceTitle => 'Thinai, on device';

  @override
  String get tourOnDeviceBody => 'Offline · No tracking · No subscription';

  @override
  String get tourCloudTitle => 'Cloud AI';

  @override
  String get tourCloudBody => 'Logs chats · Needs internet · Paid';

  @override
  String get tourCatalogTag => 'MODEL CATALOG';

  @override
  String get tourCatalogTitle => 'Great models,\nsized for your RAM.';

  @override
  String get tourCatalogBody =>
      'Thinai checks your memory and shows what runs well.';

  @override
  String get tourMemoryFitTitle => 'Memory fit';

  @override
  String get tourFitEasyLabel => 'Fits';

  @override
  String get tourFitEasyBody => 'Smooth, light on battery.';

  @override
  String get tourFitTightLabel => 'Tight';

  @override
  String get tourFitTightBody => 'Close heavy apps first.';

  @override
  String get tourFitTooBigLabel => 'Too big';

  @override
  String get tourFitTooBigBody => 'You are warned first.';

  @override
  String tourStarterTitle(String model, String size) {
    return 'Start with $model (~$size)';
  }

  @override
  String tourStarterBody(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Small and fast on any $_temp0.';
  }

  @override
  String get tourChatTag => 'CHAT & VISION';

  @override
  String get tourChatTitle => 'Chat with\nyour photos.';

  @override
  String get tourChatBody => 'Attach a photo and watch the speed live.';

  @override
  String get tourDemoPrompt => 'Explain superposition simply.';

  @override
  String get tourDemoReply =>
      'A particle can be in many states until measured, like a spinning coin.';

  @override
  String tourDemoSpeed(String speed) {
    return '⚡ $speed t/s · On-Device';
  }

  @override
  String get tourFeatureReasoning => 'Reasoning';

  @override
  String get tourFeatureVision => 'Vision';

  @override
  String get tourFeaturePersonas => 'Personas';

  @override
  String get tourServerTag => 'LOCAL API';

  @override
  String tourServerTitle(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Your $_temp0,\na private AI server.';
  }

  @override
  String get tourServerBody => 'Use it from any OpenAI or Ollama tool.';

  @override
  String get tourEndpointsTitle => 'Endpoints';

  @override
  String tourPortBadge(String port) {
    return 'PORT $port';
  }

  @override
  String tourCompatibleWith(String tools) {
    return 'Works with $tools';
  }

  @override
  String get tourStartTag => 'GET STARTED';

  @override
  String get tourStartTitle => 'Where to start?';

  @override
  String get tourOptionStarterTitle => 'Starter model';

  @override
  String tourOptionStarterBody(String model, String size) {
    return '$model, ~$size';
  }

  @override
  String get tourOptionCatalogTitle => 'Full catalog';

  @override
  String get tourOptionCatalogBody => '30+ GGUF models';

  @override
  String get tourOptionLiveTitle => 'Guided tour';

  @override
  String get tourOptionLiveBody => 'Tab by tab';

  @override
  String get tourCompleteTour => 'Finish';

  @override
  String get tourNextStep => 'Next';

  @override
  String tourDockStep(int step, int total) {
    return 'STEP $step OF $total';
  }

  @override
  String get tourExitTour => 'Exit';

  @override
  String get tourPrevious => 'Back';

  @override
  String get tourFinishTour => 'Finish';

  @override
  String get tourDockModelsTitle => 'Models';

  @override
  String get tourDockModelsBody => 'Pick a model that fits your RAM.';

  @override
  String get tourDockManageTitle => 'Downloads & speed';

  @override
  String get tourDockManageBody => 'Top-right icons: downloads and speed test.';

  @override
  String get tourDockChatTitle => 'Chat';

  @override
  String get tourDockChatBody => 'Chat privately. Attach photos or documents.';

  @override
  String get tourDockServerTitle => 'Local API server';

  @override
  String tourDockServerBody(String address) {
    return 'An OpenAI-compatible endpoint at $address.';
  }

  @override
  String get tourAppTour => 'App Tour';

  @override
  String get tourLocatingControl => 'Finding…';

  @override
  String get tourWelcomeTitle => 'Welcome to Thinai';

  @override
  String tourWelcomeSubtitle(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Private AI on your $_temp0';
  }

  @override
  String get tourWelcomePrivateTitle => 'Private and offline';

  @override
  String tourWelcomePrivateBody(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Runs on your $_temp0. No internet needed.';
  }

  @override
  String get tourWelcomeCatalogTitle => 'Open models';

  @override
  String get tourWelcomeCatalogBody =>
      'Get Llama, Gemma, Qwen and more in one tap.';

  @override
  String get tourWelcomeChatTitle => 'Chat with files';

  @override
  String get tourWelcomeChatBody => 'Attach images or documents.';

  @override
  String get tourWelcomeStartTour => 'Take the tour';

  @override
  String get tourWelcomeBrowseCatalog => 'Models';

  @override
  String get tourWelcomeSkipToChat => 'Chat';

  @override
  String get onboardingLogoLabel => 'Thinai App Logo';

  @override
  String get onboardingPrivateTag => 'PRIVATE & OFFLINE';

  @override
  String onboardingPrivateHeadline(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'AI that runs\non your $_temp0';
  }

  @override
  String get onboardingPrivateBody =>
      'Nothing leaves your device. Works in Airplane mode.';

  @override
  String get onboardingPrivateGraphic => '100% Private and Offline AI';

  @override
  String get onboardingCatalogTag => 'MODEL CATALOG';

  @override
  String get onboardingCatalogHeadline => 'Open models,\none tap away';

  @override
  String onboardingCatalogBody(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computers',
      'other': 'phones',
    });
    return 'Llama, Gemma, Qwen and more, sized for $_temp0.';
  }

  @override
  String get onboardingCatalogGraphic => 'Curated GGUF Model Catalog';

  @override
  String get onboardingGpuTag => 'GPU ACCELERATION';

  @override
  String get onboardingGpuHeadline => 'Fast on\nyour hardware';

  @override
  String get onboardingGpuBody => 'llama.cpp with Adreno and Mali GPU support.';

  @override
  String get onboardingGpuGraphic => 'GPU Hardware Acceleration Rocket';

  @override
  String get onboardingStudioTag => 'IMAGES & DOCUMENTS';

  @override
  String get onboardingStudioHeadline => 'Photos, files\nand the web';

  @override
  String get onboardingStudioBody =>
      'Attach a photo or file. Search the web too.';

  @override
  String get onboardingStudioGraphic => 'Multimodal Vision and Document QA';

  @override
  String get onboardingServerTag => 'LOCAL API';

  @override
  String onboardingServerHeadline(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Your $_temp0,\nan AI server';
  }

  @override
  String onboardingServerBody(String port) {
    return 'OpenAI and Ollama API on port $port.';
  }

  @override
  String onboardingServerGraphic(String port) {
    return 'Local AI Server on Port $port';
  }

  @override
  String get onboardingStartButton => 'Get started';

  @override
  String get splashTagline => 'PRIVATE ON-DEVICE AI';

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

  @override
  String get chatErrorReadFile => 'Could not read that file.';

  @override
  String chatDocumentTrimmed(String size) {
    return 'Attached the first $size. The rest did not fit the context window.';
  }

  @override
  String chatErrorAttachFile(String error) {
    return 'Could not attach that file: $error';
  }

  @override
  String get chatErrorNoVision =>
      'This model cannot read images. Try Gemma 3 4B instead.';

  @override
  String chatErrorTakePhoto(String error) {
    return 'Could not take that photo: $error';
  }

  @override
  String get chatErrorReadImage => 'Could not read that image.';

  @override
  String chatErrorAttachImage(String error) {
    return 'Could not attach that image: $error';
  }

  @override
  String get chatSearchBlocked =>
      'Web search is blocked right now. Answering without it.';

  @override
  String get chatSearchNoResults => 'No web results. Answering without them.';

  @override
  String chatSearchErrorFallback(String message) {
    return '$message Answering without it.';
  }

  @override
  String get chatSearchFailed => 'Web search failed. Answering without it.';

  @override
  String get chatLoadModelFirst => 'Load a model from the Models tab first.';

  @override
  String get chatActiveModelMissing => 'Active model is missing from disk.';

  @override
  String chatErrorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get chatWebSearchOn => 'Web search on.';

  @override
  String get chatWebSearchOff => 'Web search off.';

  @override
  String get chatMenuTooltip => 'Menu & Chats';

  @override
  String get chatBannerNoModelLoaded => 'No model loaded.';

  @override
  String get chatBannerNoModelDownloaded => 'No model yet.';

  @override
  String chatBannerNoModelLoadedDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count models downloaded.',
      one: 'You have 1 model downloaded.',
    );
    return '$_temp0 Select one to load it and start chatting.';
  }

  @override
  String get chatBannerNoModelDownloadedDetail =>
      'Thinai needs a language model to chat. Download one from Models: small ones (1-2 GB) are a good start, and they run fully offline once downloaded.';

  @override
  String get chatSelect => 'Select';

  @override
  String chatActiveModelTooltip(String modelId) {
    return 'Active model: $modelId (tap to switch)';
  }

  @override
  String get chatNoModelTooltip => 'No model loaded (tap to choose)';

  @override
  String get chatSwitchModel => 'Switch Model';

  @override
  String get chatNoModelsInstalled => 'No models installed';

  @override
  String chatModelsInstalledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count installed',
    );
    return '$_temp0';
  }

  @override
  String get chatNoModelsDownloadedYet => 'No models downloaded yet';

  @override
  String get chatDownloadFromCatalogue => 'Download a model to start.';

  @override
  String get chatBrowseModels => 'Browse Models';

  @override
  String get chatModelParameters => 'Model Parameters';

  @override
  String get chatDownloadMoreModels => 'Download More Models';

  @override
  String get chatEmptyTitle => 'Private Offline AI';

  @override
  String get chatGreeting => 'Welcome';

  @override
  String chatGreetingName(String name) {
    return 'Welcome, $name';
  }

  @override
  String chatEmptyBody(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Runs fully on your $_temp0. Your data stays here.';
  }

  @override
  String get chatBrowseDownloadModels => 'Get a model';

  @override
  String get chatReadyWebSearchOn => 'Ready · Web search on';

  @override
  String get chatReadyOffline => 'Ready · Offline';

  @override
  String get chatStarterBrainstorm => 'Ideas';

  @override
  String get chatStarterPython => 'Python code';

  @override
  String get chatStarterSummarize => 'Summarize';

  @override
  String get chatStarterSpeed => 'Speed test';

  @override
  String chatAttachmentTrimmed(String size) {
    return '$size · trimmed';
  }

  @override
  String get chatInputHintGenerating => 'Generating…';

  @override
  String get chatInputHint => 'Ask anything';

  @override
  String get chatStop => 'Stop';

  @override
  String get chatSend => 'Send';

  @override
  String get chatCopiedToClipboard => 'Copied';

  @override
  String get chatCopyText => 'Copy text';

  @override
  String get chatShareText => 'Share text';

  @override
  String get chatStopped => 'Stopped';

  @override
  String get chatSearchingWeb => 'Searching the web…';

  @override
  String get chatDialWebSearch => 'Web search';

  @override
  String get chatDialWebSearchAuto => 'When needed';

  @override
  String get chatDialCamera => 'Camera';

  @override
  String get chatDialCameraDetail => 'Take a photo';

  @override
  String get chatDialNeedsVision => 'Needs a vision model';

  @override
  String get chatDialImage => 'Image';

  @override
  String get chatDialDocument => 'Document';

  @override
  String get chatDialDocumentDetail => 'Text, Markdown, CSV, code';

  @override
  String chatSourcesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sources',
      one: 'Source',
    );
    return '$_temp0';
  }

  @override
  String get chatSourcesTitle => 'Sources';

  @override
  String chatSearchedQuery(String query) {
    return 'Searched: \"$query\"';
  }

  @override
  String get chatRemoveAttachment => 'Remove';

  @override
  String get chatAttachImageUnsupported =>
      'That image format is not supported. Use PNG, JPEG, WebP, BMP or GIF.';

  @override
  String get chatAttachImageEmpty => 'That image is empty.';

  @override
  String chatAttachImageTooLarge(String size, int limit) {
    return 'That image is $size MB. Images up to $limit MB can be attached.';
  }

  @override
  String get chatAttachPdfUnsupported =>
      'PDF is not supported yet. Copy the text and attach that instead.';

  @override
  String chatAttachBinaryUnsupported(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'image': 'image',
      'audio': 'audio',
      'other': '$kind',
    });
    return '$_temp0 files are not supported. Attach a text document.';
  }

  @override
  String get chatAttachFileEmpty => 'That file is empty.';

  @override
  String get chatAttachBinaryFile =>
      'That looks like a binary file, not a text document.';

  @override
  String get chatAttachNotUtf8 =>
      'Could not read that file as text. UTF-8 documents only.';

  @override
  String get chatAttachNoText => 'That file has no text in it.';

  @override
  String get chatDrawerExitManage => 'Exit manage mode';

  @override
  String get chatDrawerManageChats => 'Manage chats';

  @override
  String get chatDrawerTapToSelect => 'Tap to select';

  @override
  String chatDrawerSelectedCount(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String get chatDrawerDeselectAll => 'Deselect all';

  @override
  String get chatDrawerSelectAll => 'Select all';

  @override
  String get chatDrawerCloseMenu => 'Close menu';

  @override
  String get chatNewChat => 'New chat';

  @override
  String get chatDrawerSearchHint => 'Search chats…';

  @override
  String chatDrawerDeleteCount(int count) {
    return 'Delete ($count)';
  }

  @override
  String chatDrawerConversationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conversations',
      one: '1 conversation',
    );
    return '$_temp0';
  }

  @override
  String get chatDrawerModelSettings => 'Model Settings';

  @override
  String get chatDrawerModelSettingsSubtitle => 'Context, sampling, thinking';

  @override
  String get chatDrawerNoModelSnack => 'Download a model first.';

  @override
  String get chatDrawerAppSettings => 'App Settings';

  @override
  String get chatDrawerAppSettingsSubtitle => 'Theme, GPU, server';

  @override
  String get chatDrawerAbout => 'About Thinai';

  @override
  String get chatDrawerAboutSubtitle => 'Version, privacy';

  @override
  String chatDrawerDeleteManyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count chats?',
      one: 'Delete 1 chat?',
    );
    return '$_temp0';
  }

  @override
  String get chatDrawerDeleteManyBody => 'This cannot be undone.';

  @override
  String chatDrawerDeletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count chats',
      one: 'Deleted 1 chat',
    );
    return '$_temp0';
  }

  @override
  String get chatDrawerSelectManage => 'Select';

  @override
  String get chatDrawerRenameTitle => 'Rename';

  @override
  String get chatDeleteChat => 'Delete chat';

  @override
  String get chatRenameChat => 'Rename chat';

  @override
  String get chatConversationTitleHint => 'Conversation title';

  @override
  String get chatDrawerDeleteOneTitle => 'Delete chat?';

  @override
  String chatDrawerDeleteOneBody(String title) {
    return '\"$title\" will be deleted for good.';
  }

  @override
  String get chatDrawerNoHistory => 'No chats yet';

  @override
  String get chatDrawerNoHistoryHint => 'Your chats show up here.';

  @override
  String chatDrawerNoResults(String query) {
    return 'No chats for \"$query\"';
  }

  @override
  String get chatGroupToday => 'Today';

  @override
  String get chatGroupYesterday => 'Yesterday';

  @override
  String get chatGroupPrevious7Days => 'Previous 7 Days';

  @override
  String get chatGroupThisMonth => 'This Month';

  @override
  String get chatGroupOlder => 'Older';

  @override
  String get chatHistoryTitle => 'History';

  @override
  String get chatHistoryDeleteAllTooltip => 'Delete all chats';

  @override
  String get chatHistoryDeleteAllTitle => 'Delete all chats?';

  @override
  String get chatHistoryDeleteAllBody =>
      'Every saved chat is deleted for good.';

  @override
  String get chatHistoryDeleteAll => 'Delete all';

  @override
  String get chatHistoryDeleteOneTitle => 'Delete this chat?';

  @override
  String get chatHistorySearchHint => 'Search chats…';

  @override
  String chatHistoryNoResults(String query) {
    return 'No chats for \"$query\"';
  }

  @override
  String get chatHistoryActiveBadge => 'ACTIVE';

  @override
  String chatHistoryMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String get chatHistoryEmptyTitle => 'No chats yet';

  @override
  String get chatHistoryEmptyBody =>
      'Your chats show up here, on this device only.';

  @override
  String get chatTimeJustNow => 'Just now';

  @override
  String chatTimeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String chatTimeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String chatTimeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get chatCodeBlockLabel => 'CODE';

  @override
  String get chatCodeCopied => 'Copied!';

  @override
  String get chatAppRestartTitle => 'Restart now?';

  @override
  String get chatAppRestartBody =>
      'A model download will pause. You can resume it later.';

  @override
  String get chatAppRestart => 'Restart';

  @override
  String get chatAppUpdateReady => 'Update ready';

  @override
  String get chatAppUpdateAvailable => 'New version';

  @override
  String get chatAppUpdateDownloading => 'Downloading…';

  @override
  String get modelsToastDownloadPaused => 'Download paused';

  @override
  String modelsToastDownloadStopped(String model, String error) {
    return '$model stopped: $error. Tap Resume to continue.';
  }

  @override
  String modelsToastDownloadFailed(String model, String error) {
    return 'Could not download $model: $error';
  }

  @override
  String modelsToastDownloadedAndLoaded(String model) {
    return 'Downloaded and loaded $model';
  }

  @override
  String modelsToastDownloaded(String model) {
    return 'Downloaded $model';
  }

  @override
  String modelsToastLoaded(String model) {
    return 'Loaded $model';
  }

  @override
  String modelsToastResumeFailed(String model) {
    return 'Could not resume $model';
  }

  @override
  String get modelsConfirmDownloadTitle => 'Download?';

  @override
  String modelsConfirmDownloadMessage(String model, String size) {
    return '$model ($size)';
  }

  @override
  String get modelsConfirmDiscardTitle => 'Discard download?';

  @override
  String modelsConfirmDiscardMessage(String model, String size) {
    return '$model ($size saved) will be deleted.';
  }

  @override
  String get modelsDiscard => 'Discard';

  @override
  String get modelsConfirmDeleteTitle => 'Delete model?';

  @override
  String modelsConfirmDeleteMessage(String model, String size) {
    return '$model will be removed, freeing $size.';
  }

  @override
  String get modelsBenchmark => 'Benchmark';

  @override
  String get modelsManagerTitle => 'Model Manager';

  @override
  String modelsManagerTooltipDownloading(int count) {
    return 'Downloading ($count) · Model Manager';
  }

  @override
  String modelsManagerTooltipInstalled(int count) {
    return 'Model Manager ($count installed)';
  }

  @override
  String modelsError(String error) {
    return 'Error: $error';
  }

  @override
  String get modelsNoneInstalledYet => 'No models installed yet';

  @override
  String get modelsNoneInstalledYetBody => 'Download a model to chat offline.';

  @override
  String get modelsBrowseCatalog => 'Browse Catalog';

  @override
  String modelsInstalledSectionTitle(int count) {
    return 'Installed ($count)';
  }

  @override
  String get modelsFeaturedTitle => 'Featured';

  @override
  String get modelsOtherModels => 'Other models';

  @override
  String get modelsVisionModelsTitle => 'Vision models';

  @override
  String get modelsChatModelsTitle => 'Chat models';

  @override
  String get modelsExploreModels => 'More models';

  @override
  String get modelsBrowseCatalogTitle => 'Results';

  @override
  String get modelsEmbeddingTitle => 'Embedding models';

  @override
  String modelsOfflineFooter(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Models run fully offline on this $_temp0.';
  }

  @override
  String get modelsSearchHint => 'Search models';

  @override
  String get modelsClearSearch => 'Clear search';

  @override
  String get modelsFilterAll => 'All';

  @override
  String get modelsFilterChat => 'Chat';

  @override
  String get modelsFilterVision => 'Vision';

  @override
  String get modelsFilterEmbedding => 'Embedding';

  @override
  String get modelsFilterInstalled => 'Installed';

  @override
  String modelsFilterInstalledCount(int count) {
    return 'Installed ($count)';
  }

  @override
  String get modelsFilterCategory => 'Filter Category';

  @override
  String get modelsGoals => 'Goal';

  @override
  String get modelsResetFiltersTooltip => 'Reset filters and search';

  @override
  String modelsTargeting(String goal) {
    return 'Goal: $goal';
  }

  @override
  String get modelsChange => 'Change';

  @override
  String get modelsClearGoal => 'Clear goal';

  @override
  String modelsManagerSubtitle(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count models',
      one: '1 model',
    );
    return '$_temp0 · $size';
  }

  @override
  String get modelsNoneInstalled => 'No models installed';

  @override
  String get modelsNoneInstalledBody => 'Download one from the catalog.';

  @override
  String modelsActiveForChat(String model) {
    return 'In use: $model';
  }

  @override
  String get modelsNoModelLoaded => 'No model loaded';

  @override
  String get modelsInstalledAppearHere => 'Finished downloads show up here.';

  @override
  String get modelsActive => 'Active';

  @override
  String get modelsActivate => 'Load';

  @override
  String get modelsDeleteModel => 'Delete model';

  @override
  String get modelsChooseGoal => 'Choose a goal';

  @override
  String get modelsClearActiveGoal => 'Clear Active Goal';

  @override
  String get modelsNoMatchFilters => 'No models match current filters';

  @override
  String modelsNoMatchQuery(String query) {
    return 'No models match \"$query\"';
  }

  @override
  String get modelsNoMatchHint => 'Try another search or filter.';

  @override
  String get modelsSearchHuggingFace => 'Search Hugging Face';

  @override
  String get modelsResetFiltersAndSearch => 'Reset filters';

  @override
  String get modelsStatusCancelled => 'Cancelled';

  @override
  String get modelsStatusFailed => 'Failed';

  @override
  String get modelsStatusCompleted => 'Done';

  @override
  String get modelsStatusStarting => 'Starting…';

  @override
  String get modelsActiveInChat => 'In use';

  @override
  String get modelsTapToActivate => 'Tap to load';

  @override
  String modelsAddVision(String size) {
    return '+ Vision ($size)';
  }

  @override
  String get modelsInstalled => 'Installed';

  @override
  String get modelsPause => 'Pause';

  @override
  String get modelsTopPick => 'Top pick';

  @override
  String get modelsModelDetails => 'Model details';

  @override
  String modelsDimensions(String count) {
    return '$count dims';
  }

  @override
  String get modelsNeedsRam => 'Needs RAM';

  @override
  String get modelsDetailParameters => 'Parameters';

  @override
  String get modelsDetailContextWindow => 'Context Window';

  @override
  String modelsTokensValue(String count) {
    return '$count tokens';
  }

  @override
  String get modelsDetailDownloadSize => 'Download Size';

  @override
  String get modelsDetailCapability => 'Capability';

  @override
  String modelsDownloadSize(String size) {
    return 'Download $size';
  }

  @override
  String get modelsCapVisionReady => 'Vision';

  @override
  String get modelsCapEmbeddings => 'Embeddings';

  @override
  String get modelsCapLightweight => 'Lightweight';

  @override
  String get modelsCapFast => 'Fast';

  @override
  String get modelsCapMultilingual => 'Multilingual';

  @override
  String get modelsCapCodeReasoning => 'Code · Reasoning';

  @override
  String get modelsCapInstruct => 'Instruct';

  @override
  String modelsFitTooLarge(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Too large for this $_temp0.';
  }

  @override
  String modelsFitNeeds(String device, String needs, String available) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Needs $needs, this $_temp0 has $available to spare.';
  }

  @override
  String get modelsFitTight => 'Tight fit. Other apps may close while it runs.';

  @override
  String modelsDownloadingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Downloading $count models',
      one: 'Downloading model',
    );
    return '$_temp0';
  }

  @override
  String get modelsPauseDownload => 'Pause download';

  @override
  String modelsResumePercent(String percent) {
    return 'Resume $percent%';
  }

  @override
  String get modelsPaused => 'Paused';

  @override
  String modelsPausedPercent(String percent) {
    return 'Paused · $percent%';
  }

  @override
  String modelsPausedDownloadsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Paused downloads ($count)',
      one: 'Paused download',
    );
    return '$_temp0';
  }

  @override
  String get modelsResumeDownload => 'Resume download';

  @override
  String get modelsDiscardDownload => 'Discard download';

  @override
  String get modelsUseCaseFastChat => 'Fast chat';

  @override
  String get modelsUseCaseFastChatBlurb => 'Quick replies';

  @override
  String get modelsUseCaseReasoning => 'Reasoning';

  @override
  String get modelsUseCaseReasoningBlurb => 'Maths and hard questions';

  @override
  String get modelsUseCaseCoding => 'Coding';

  @override
  String get modelsUseCaseCodingBlurb => 'Write and explain code';

  @override
  String get modelsUseCaseTamil => 'Tamil';

  @override
  String get modelsUseCaseTamilBlurb => 'Chat and write in Tamil';

  @override
  String get modelsUseCaseEnglish => 'English';

  @override
  String get modelsUseCaseEnglishBlurb => 'Everyday English';

  @override
  String get modelsUseCaseVision => 'Images';

  @override
  String get modelsUseCaseVisionBlurb => 'Ask about a photo';

  @override
  String get modelsUseCaseTranslation => 'Translation';

  @override
  String get modelsUseCaseTranslationBlurb => 'Translate with no internet';

  @override
  String get modelsUseCaseSummarizing => 'Summaries';

  @override
  String get modelsUseCaseSummarizingBlurb => 'The gist of long text';

  @override
  String get modelsUseCaseDocuments => 'Documents';

  @override
  String get modelsUseCaseDocumentsBlurb => 'Ask about long documents';

  @override
  String modelsReasonNotSuited(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'Not suited to quick conversations',
      'reasoning': 'Not suited to step-by-step reasoning',
      'coding': 'Not suited to code',
      'tamil': 'Not suited to Tamil',
      'english': 'Not suited to English',
      'vision': 'Not suited to images',
      'translation': 'Not suited to translation',
      'summarizing': 'Not suited to summarising',
      'documents': 'Not suited to long documents',
      'other': 'Not suited to quick conversations',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonLimited(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'Limited for quick conversations',
      'reasoning': 'Limited for step-by-step reasoning',
      'coding': 'Limited for code',
      'tamil': 'Limited for Tamil',
      'english': 'Limited for English',
      'vision': 'Limited for images',
      'translation': 'Limited for translation',
      'summarizing': 'Limited for summarising',
      'documents': 'Limited for long documents',
      'other': 'Limited for quick conversations',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonUsable(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'Usable for quick conversations',
      'reasoning': 'Usable for step-by-step reasoning',
      'coding': 'Usable for code',
      'tamil': 'Usable for Tamil',
      'english': 'Usable for English',
      'vision': 'Usable for images',
      'translation': 'Usable for translation',
      'summarizing': 'Usable for summarising',
      'documents': 'Usable for long documents',
      'other': 'Usable for quick conversations',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonGood(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'Good for quick conversations',
      'reasoning': 'Good for step-by-step reasoning',
      'coding': 'Good for code',
      'tamil': 'Good for Tamil',
      'english': 'Good for English',
      'vision': 'Good for images',
      'translation': 'Good for translation',
      'summarizing': 'Good for summarising',
      'documents': 'Good for long documents',
      'other': 'Good for quick conversations',
    });
    return '$_temp0';
  }

  @override
  String modelsReasonExcellent(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat': 'Excellent for quick conversations',
      'reasoning': 'Excellent for step-by-step reasoning',
      'coding': 'Excellent for code',
      'tamil': 'Excellent for Tamil',
      'english': 'Excellent for English',
      'vision': 'Excellent for images',
      'translation': 'Excellent for translation',
      'summarizing': 'Excellent for summarising',
      'documents': 'Excellent for long documents',
      'other': 'Excellent for quick conversations',
    });
    return '$_temp0';
  }

  @override
  String modelsCaveatNoneFits(String device, String task) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    String _temp1 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    String _temp2 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    String _temp3 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    String _temp4 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    String _temp5 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    String _temp6 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    String _temp7 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    String _temp8 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    String _temp9 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    String _temp10 = intl.Intl.selectLogic(task, {
      'fastChat':
          'No model in the catalogue fits this $_temp0 for quick conversations.',
      'reasoning':
          'No model in the catalogue fits this $_temp1 for step-by-step reasoning.',
      'coding': 'No model in the catalogue fits this $_temp2 for code.',
      'tamil': 'No model in the catalogue fits this $_temp3 for Tamil.',
      'english': 'No model in the catalogue fits this $_temp4 for English.',
      'vision': 'No model in the catalogue fits this $_temp5 for images.',
      'translation':
          'No model in the catalogue fits this $_temp6 for translation.',
      'summarizing':
          'No model in the catalogue fits this $_temp7 for summarising.',
      'documents':
          'No model in the catalogue fits this $_temp8 for long documents.',
      'other':
          'No model in the catalogue fits this $_temp9 for quick conversations.',
    });
    return '$_temp10';
  }

  @override
  String modelsCaveatNothingFitsWell(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat':
          'Nothing fits well for quick conversations. These are closest.',
      'reasoning':
          'Nothing fits well for step-by-step reasoning. These are closest.',
      'coding': 'Nothing fits well for code. These are closest.',
      'tamil': 'Nothing fits well for Tamil. These are closest.',
      'english': 'Nothing fits well for English. These are closest.',
      'vision': 'Nothing fits well for images. These are closest.',
      'translation': 'Nothing fits well for translation. These are closest.',
      'summarizing': 'Nothing fits well for summarising. These are closest.',
      'documents': 'Nothing fits well for long documents. These are closest.',
      'other': 'Nothing fits well for quick conversations. These are closest.',
    });
    return '$_temp0';
  }

  @override
  String modelsCaveatNothingStrong(String task) {
    String _temp0 = intl.Intl.selectLogic(task, {
      'fastChat':
          'Nothing at this size is strong at quick conversations. Closest matches shown.',
      'reasoning':
          'Nothing at this size is strong at step-by-step reasoning. Closest matches shown.',
      'coding':
          'Nothing at this size is strong at code. Closest matches shown.',
      'tamil':
          'Nothing at this size is strong at Tamil. Closest matches shown.',
      'english':
          'Nothing at this size is strong at English. Closest matches shown.',
      'vision':
          'Nothing at this size is strong at images. Closest matches shown.',
      'translation':
          'Nothing at this size is strong at translation. Closest matches shown.',
      'summarizing':
          'Nothing at this size is strong at summarising. Closest matches shown.',
      'documents':
          'Nothing at this size is strong at long documents. Closest matches shown.',
      'other':
          'Nothing at this size is strong at quick conversations. Closest matches shown.',
    });
    return '$_temp0';
  }

  @override
  String get modelsVisionUnavailable =>
      'Image understanding is not available in this build.';

  @override
  String get modelsFitComfortable => 'Runs well';

  @override
  String get modelsFitTightShort => 'Tight fit';

  @override
  String modelsFitTooBig(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Too big for your $_temp0';
  }

  @override
  String get modelsFitUnknown => 'Fit unknown';

  @override
  String get modelsSpeedUnknown => 'speed unknown';

  @override
  String get modelsAdvisorPrompt => 'What do you want to do?';

  @override
  String get modelsClear => 'Clear';

  @override
  String get modelsAdvisorCollapse => 'Collapse guide';

  @override
  String modelsAdvisorNothingFits(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'Nothing fits this $_temp0.';
  }

  @override
  String get modelsAdvisorAlsoConsider => 'Also good';

  @override
  String get modelsSettingsTitle => 'Model settings';

  @override
  String get modelsSettingsBody => 'Applies to chat and the server.';

  @override
  String get modelsSettingsResetDefaults => 'Reset to defaults';

  @override
  String get modelsSettingsContextWindow => 'Context window';

  @override
  String get modelsSettingsContextHelp =>
      'Longer remembers more but uses more RAM.';

  @override
  String get modelsSettingsTemperature => 'Temperature';

  @override
  String get modelsSettingsPrecise => 'Precise';

  @override
  String get modelsSettingsCreative => 'Creative';

  @override
  String get modelsSettingsTopKHelp => 'Lower is more focused. 0 turns it off.';

  @override
  String get modelsSettingsTopPHelp =>
      'Lower is more focused. 1.00 turns it off.';

  @override
  String get modelsSettingsThinking => 'Thinking';

  @override
  String get modelsSettingsThinkingHelp =>
      'Thinks before answering. Off is faster.';

  @override
  String modelsSettingsCapPhoneRam(String max) {
    return 'Max $max, limited by RAM.';
  }

  @override
  String modelsSettingsCapTraining(String max) {
    return 'Max $max, the model\'s limit.';
  }

  @override
  String modelsSettingsCap(String max) {
    return 'Max $max.';
  }

  @override
  String chatPreviewYou(String text) {
    return 'You: $text';
  }

  @override
  String get chatNoMessagesYet => 'No messages yet';

  @override
  String get chatStarterBrainstormPrompt =>
      'Give me 5 creative ideas to build an on-device AI app';

  @override
  String get chatStarterPythonPrompt =>
      'Write a Python script to sort and deduplicate a list of items';

  @override
  String get chatStarterSummarizePrompt =>
      'Summarize the key takeaways from the following:\n\n';

  @override
  String chatStarterSpeedPrompt(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'desktop': 'computer',
      'other': 'phone',
    });
    return 'What is your generation speed on this $_temp0?';
  }

  @override
  String deviceSummaryRam(String ram, int cores) {
    return '$ram GB RAM · $cores cores';
  }

  @override
  String deviceSummaryCores(int cores) {
    return '$cores cores';
  }

  @override
  String get settingsGlossary => 'Glossary';

  @override
  String get modelsTopPicks => 'Top picks';
}
