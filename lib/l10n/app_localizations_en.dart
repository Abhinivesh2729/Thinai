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
  String get serverToastLanNoAddress =>
      'Sharing on, but no Wi-Fi/LAN address was found.';

  @override
  String serverToastStartFailed(String error) {
    return 'Start failed: $error';
  }

  @override
  String get serverPortDialogTitle => 'Change Server Port';

  @override
  String get serverPortDialogBody =>
      'Select or enter the local TCP port Thinai binds to. Default is 11434 for Ollama, 8080 for standard.';

  @override
  String get serverPortNumberLabel => 'Port number';

  @override
  String get serverPortPresetStandard => '8080 (Standard)';

  @override
  String get serverSavePort => 'Save Port';

  @override
  String get serverStatusRunning => 'Running';

  @override
  String get serverStatusStopped => 'Stopped';

  @override
  String get serverStart => 'Start';

  @override
  String get serverStop => 'Stop';

  @override
  String get serverCopyAddressTooltip => 'Copy Server Address';

  @override
  String serverCopiedToClipboard(String value) {
    return 'Copied $value to clipboard';
  }

  @override
  String serverCopiedLabel(String label) {
    return 'Copied $label';
  }

  @override
  String get serverServingModel => 'SERVING MODEL';

  @override
  String get serverTune => 'Tune';

  @override
  String get serverNoModelLoaded =>
      'No model loaded yet. Load one to enable completions.';

  @override
  String get serverBrowseModels => 'Browse Models';

  @override
  String get serverRegenerateTokenTitle => 'Regenerate API token?';

  @override
  String get serverRegenerateTokenBody =>
      'Existing LAN clients using the current token will lose access and must be updated.';

  @override
  String get serverRegenerate => 'Regenerate';

  @override
  String get serverTokenRegenerated => 'API token regenerated';

  @override
  String get serverLanShareTitle => 'Share on Local Network (LAN)';

  @override
  String get serverLanShareOnSubtitle =>
      'Other computers on this Wi-Fi can reach the API';

  @override
  String get serverLanShareOffSubtitle =>
      'Only apps running directly on this phone can reach 127.0.0.1';

  @override
  String get serverCopyLanUrlTooltip => 'Copy LAN URL';

  @override
  String get serverDevQuickStartTitle => 'Developer Quick Start';

  @override
  String get serverDevQuickStartSubtitle =>
      'Direct configuration snippets for coding assistants & scripts';

  @override
  String get serverTabChatJson => 'Chat JSON';

  @override
  String get serverVsCodeIntro =>
      'For Continue.dev or Cline extensions in VS Code:';

  @override
  String get serverPythonIntro => 'Query with official OpenAI Python SDK:';

  @override
  String get serverCurlIntro =>
      'Direct terminal HTTP request with standard JSON payload:';

  @override
  String get serverChatJsonIntro =>
      'OpenAI standard chat payload (/v1/chat/completions):';

  @override
  String get serverOllamaIntro =>
      'Point any Ollama client (Open-WebUI, Chatbox, CLI) to Thinai:';

  @override
  String get serverCopyLabelVsCodeConfig => 'VS Code Config';

  @override
  String get serverCopyLabelPythonScript => 'Python Script';

  @override
  String get serverCopyLabelCurlCommand => 'cURL Command';

  @override
  String get serverCopyLabelChatJson => 'Chat JSON Payload';

  @override
  String get serverCopyLabelOllamaEnv => 'Ollama Host Env';

  @override
  String get serverEndpointOpenAiChat => 'OpenAI Chat Completions';

  @override
  String get serverEndpointOllamaChat => 'Ollama Native Chat';

  @override
  String get serverEndpointEmbeddings => 'Vector Embeddings';

  @override
  String get serverEndpointModels => 'Installed Models Catalog';

  @override
  String get serverApiEndpointsTitle => 'API Endpoints';

  @override
  String get serverApiEndpointsSubtitle =>
      'Standard OpenAI & Ollama compatible HTTP routes';

  @override
  String get serverCopyBaseUrlTooltip => 'Copy Base URL';

  @override
  String serverBaseUrlLabel(String url) {
    return 'Base URL: $url';
  }

  @override
  String get serverCopyCurlTooltip => 'Copy cURL';

  @override
  String serverCurlCommandLabel(String path) {
    return '$path cURL command';
  }

  @override
  String serverSecurityLan(String port) {
    return 'Wi-Fi Network Serving Active · Any device on this local subnet can query the API on port $port with your Bearer token.';
  }

  @override
  String serverSecurityLocal(String port) {
    return 'Local Loopback Active · Only apps executing directly on this hardware can query localhost:$port.';
  }

  @override
  String get hfSearchHint => 'Search GGUF models on Hugging Face';

  @override
  String get hfSearchFailedTitle => 'Search did not work';

  @override
  String get hfTryAgain => 'Try again';

  @override
  String get hfEmptyTitle => 'Find any GGUF model';

  @override
  String get hfEmptyMessage =>
      'Search by name or maker, like \"gemma\", \"phi\" or \"unsloth\". Results are public repos with GGUF files.';

  @override
  String hfNoMatchTitle(String query) {
    return 'No GGUF models match \"$query\"';
  }

  @override
  String get hfNoMatchMessage => 'Try a shorter name or a different spelling.';

  @override
  String hfResultsTitle(int count) {
    return 'Results ($count)';
  }

  @override
  String get hfResultsSubtitle => 'Most downloaded first';

  @override
  String hfShowingUpTo(int limit) {
    return 'Showing up to $limit results.';
  }

  @override
  String get hfDownloadTitle => 'Download model?';

  @override
  String get hfTooBigTitle => 'Too big for this phone?';

  @override
  String get hfDownloadAnyway => 'Download anyway';

  @override
  String hfDownloadMessage(String file, String size) {
    return 'Do you want to download $file ($size) from Hugging Face?';
  }

  @override
  String hfDownloadMessageTooBig(String file, String size) {
    return 'Do you want to download $file ($size) from Hugging Face?\n\nThis is likely too large for this phone and may not load.';
  }

  @override
  String hfDownloadMessageTooBigBudget(
    String file,
    String size,
    String needs,
    String budget,
  ) {
    return 'Do you want to download $file ($size) from Hugging Face?\n\nIt needs about $needs of memory and this phone has $budget to spare, so it will probably not load.';
  }

  @override
  String hfDownloadMessageTight(String file, String size) {
    return 'Do you want to download $file ($size) from Hugging Face?\n\nA tight fit. Other apps may close while this runs.';
  }

  @override
  String get hfOpenFailedTitle => 'Could not open this model';

  @override
  String get hfSignInTitle => 'Sign-in required';

  @override
  String get hfSignInMessage =>
      'This model needs a Hugging Face account to download, which Thinai does not support yet.';

  @override
  String hfFilesTitle(int count) {
    return 'GGUF files ($count)';
  }

  @override
  String get hfFilesSubtitle => 'Smaller files load faster and use less memory';

  @override
  String hfSkippedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count other GGUF files are hidden: split files, image encoders and helper files cannot be loaded on their own.',
      one:
          '1 other GGUF file is hidden: split files, image encoders and helper files cannot be loaded on their own.',
    );
    return '$_temp0';
  }

  @override
  String get hfNothingTitle => 'Nothing to install here';

  @override
  String get hfNothingMessage =>
      'This repo has no single-file GGUF models that Thinai can load.';

  @override
  String get hfNetworkNotice =>
      'Search uses the internet. Thinai contacts huggingface.co only while you search here or open a model, never in the background. Your chats stay on this phone.';

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
  String get hfNoLicence => 'No licence listed';

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
  String get hfPromptSubtitle =>
      'Any public GGUF model, installed into your library. Uses the internet.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsSystemPrompt => 'System Prompt';

  @override
  String get settingsHardware => 'Hardware & Acceleration';

  @override
  String get settingsModelStorage => 'Model & Storage';

  @override
  String get settingsLocalServer => 'Local Server & API';

  @override
  String get settingsAboutGuidance => 'About & Guidance';

  @override
  String get settingsStartPage => 'Open page on startup';

  @override
  String get settingsThemeMode => 'Theme mode';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsWebSearch => 'Web search in chat';

  @override
  String get settingsEnabled => 'Enabled';

  @override
  String get settingsDisabled => 'Disabled';

  @override
  String get settingsGpuAcceleration => 'GPU acceleration';

  @override
  String get settingsGpuAuto => 'Auto';

  @override
  String get settingsBenchmarkDevice => 'Benchmark device';

  @override
  String get settingsGpuDiagnostics => 'GPU speed diagnostics';

  @override
  String get settingsDeviceSpecs => 'Device hardware specs';

  @override
  String settingsDeviceSpecsWithRam(int cores, String ramGb) {
    return '$cores Cores • $ramGb GB RAM';
  }

  @override
  String settingsDeviceSpecsCores(int cores) {
    return '$cores CPU Cores';
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
    return 'Download stopped: $error. Progress is saved, resume it from the Model Manager.';
  }

  @override
  String settingsDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get settingsDownloadComplete => 'Download complete';

  @override
  String get settingsClearDownloadsTitle => 'Clear all downloads?';

  @override
  String get settingsClearDownloadsBody =>
      'This removes all downloaded model files inside the app to free up device storage.';

  @override
  String get settingsClearAll => 'Clear all';

  @override
  String get settingsNoDownloadsFound => 'No downloaded items found';

  @override
  String settingsClearedDownloads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cleared $count downloaded items',
      one: 'Cleared 1 downloaded item',
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
  String get settingsNoActiveModel => 'No active model loaded';

  @override
  String get settingsCatalog => 'Catalog';

  @override
  String get settingsImportGguf => 'Import local .gguf';

  @override
  String get settingsDownloadFromUrl => 'Download model from URL';

  @override
  String get settingsClearDownloadedModels => 'Clear downloaded models';

  @override
  String get settingsChangePortTitle => 'Change Server Port';

  @override
  String get settingsPortNumber => 'Port number';

  @override
  String settingsPortSetRestart(int port) {
    return 'Server port set to $port. Restart the server to apply.';
  }

  @override
  String settingsPortSet(int port) {
    return 'Server port set to $port';
  }

  @override
  String get settingsShareApiWifi => 'Share API over Wi-Fi';

  @override
  String get settingsServerPort => 'Server port';

  @override
  String get settingsServerStatus => 'Server status';

  @override
  String get settingsServerActive => 'Active';

  @override
  String get settingsServerOffline => 'Offline';

  @override
  String get settingsUpToDate => 'Thinai is up to date';

  @override
  String get settingsUpdateUnavailable =>
      'Play Store could not check for updates';

  @override
  String get settingsUpdateAlreadyDownloading =>
      'An update is already downloading';

  @override
  String get settingsUpdateDownloading =>
      'Downloading update in the background';

  @override
  String get settingsUpdateFailed =>
      'Update failed. Try again from Play Store.';

  @override
  String get settingsUpdateReadyTitle => 'Update ready';

  @override
  String get settingsUpdateReadyBody =>
      'The new version is downloaded. Thinai restarts to install it.';

  @override
  String get settingsRestart => 'Restart';

  @override
  String get settingsStartTour => 'Start app tour';

  @override
  String get settingsCheckUpdates => 'Check for updates';

  @override
  String get settingsContactSupport => 'Contact support';

  @override
  String get settingsAboutThinai => 'About Thinai';

  @override
  String get settingsDownloadDialogTitle => 'Download model by URL';

  @override
  String get settingsDirectGgufUrl => 'Direct GGUF URL';

  @override
  String get settingsSaveAsOptional => 'Save as (optional)';

  @override
  String get gpuAcceleration => 'GPU acceleration';

  @override
  String get gpuSubtitle => 'Offloads computation to hardware accelerator';

  @override
  String get gpuDescription =>
      'Runs the model on the GPU instead of the CPU. Run the speed test to check if it helps on this phone.';

  @override
  String gpuCrashedNotice(String backend) {
    return '$backend crashed the app last time, so GPU acceleration was turned off.';
  }

  @override
  String get gpuCheckPhone => 'Check this phone\'s GPU';

  @override
  String get gpuNoneFound =>
      'No usable GPU found. Thinai will keep using the CPU.';

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
  String get gpuLoadModelFirst => 'Load a model first, then run the test.';

  @override
  String gpuTestFailed(String error) {
    return 'The test failed: $error';
  }

  @override
  String get gpuVerdictGpuFaster => 'The GPU is faster on this phone.';

  @override
  String get gpuVerdictCpuFaster =>
      'The CPU is faster here. Leave GPU acceleration off.';

  @override
  String get gpuVerdictSame => 'About the same either way.';

  @override
  String get gpuReadingPrompt => 'Reading prompt';

  @override
  String get gpuWritingReply => 'Writing reply';

  @override
  String get aboutTitle => 'About Thinai';

  @override
  String aboutVersionBadge(String version) {
    return 'v$version · On-Device Sovereign AI';
  }

  @override
  String get aboutHeroDescription =>
      'Thinai executes modern open-weights neural models directly on your Android phone silicon. Zero internet required, zero cloud reliance, and 100% data sovereignty.';

  @override
  String get aboutCorePillars => 'Core Pillars';

  @override
  String get aboutPrivateTitle => '100% Private & Sovereign';

  @override
  String get aboutPrivateBody =>
      'Every model token and user prompt is computed strictly inside device RAM. No telemetry, no logs, and no cloud interception.';

  @override
  String get aboutAcceleratedTitle => 'Hardware Accelerated';

  @override
  String get aboutAcceleratedBody =>
      'Built on a high-performance llama.cpp mobile runtime with Vulkan and OpenCL GPU acceleration, tuned for high speed on modern mobile chipsets.';

  @override
  String get aboutApiTitle => 'Local OpenAI-Compatible API';

  @override
  String get aboutApiBody =>
      'Runs an embedded HTTP server on localhost:11434 with /v1/chat/completions, transforming your phone into an AI engine for other apps and automations.';

  @override
  String get aboutVisionTitle => 'Multimodal Vision & Web';

  @override
  String get aboutVisionBody =>
      'Engage in visual reasoning with vision-enabled models (Gemma 3, MiniCPM), document summarization, and privacy-preserving live web search citations.';

  @override
  String get aboutTechSpecs => 'Technical Specifications';

  @override
  String get aboutSpecEngine => 'Inference Engine';

  @override
  String get aboutSpecModelFormat => 'Model Format';

  @override
  String get aboutSpecArchitecture => 'Target Architecture';

  @override
  String get aboutSpecBackends => 'Acceleration Backends';

  @override
  String get aboutSpecLicense => 'Software License';

  @override
  String get aboutSpecLicenseValue => 'Open Source (MIT)';

  @override
  String get aboutCommunity => 'Community & Transparency';

  @override
  String get aboutCommunityBody =>
      'Thinai is built on sovereign privacy and open-source principles. You can inspect all third-party licenses or contact support for help.';

  @override
  String get aboutLicenses => 'Licenses';

  @override
  String get aboutContactSupport => 'Contact Support';

  @override
  String get supportTitle => 'Contact Support';

  @override
  String supportCouldNotOpenLink(String url) {
    return 'Could not open link: $url';
  }

  @override
  String supportFailedToOpenLink(String error) {
    return 'Failed to open link: $error';
  }

  @override
  String get supportHeroTitle => 'How can we help?';

  @override
  String get supportHeroBody =>
      'Need assistance running models, found a bug, or have a suggestion? We respond promptly to community queries.';

  @override
  String get supportChannels => 'Direct Support Channels';

  @override
  String get supportInstagramTitle => 'Instagram Support';

  @override
  String get supportInstagramBody =>
      'Direct messaging, quick feature sneak-peeks, troubleshooting, and announcements.';

  @override
  String get supportInstagramOpenFailed => 'Unable to open Instagram link';

  @override
  String get supportOpenInstagram => 'Open Instagram';

  @override
  String get supportCopyHandle => 'Copy Instagram handle';

  @override
  String get supportHandleCopied => 'Instagram handle copied to clipboard';

  @override
  String get supportDiagnostics => 'Device Diagnostics';

  @override
  String get supportDiagnosticsHint =>
      'Copying this data makes troubleshooting 10x faster when contacting us.';

  @override
  String supportCpuCores(int cores) {
    return '$cores CPU Cores';
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
  String get supportNoActiveModel => 'No active model';

  @override
  String get supportServerActive => 'Server: Active';

  @override
  String get supportServerStopped => 'Server: Stopped';

  @override
  String get supportCopyDiagnostics => 'Copy Diagnostic Specs';

  @override
  String get supportDiagnosticsCopied =>
      'System diagnostics copied to clipboard';

  @override
  String get supportTroubleshooting => 'Quick Troubleshooting';

  @override
  String get supportFaqLoadQuestion =>
      'Why does a model take long to load or download?';

  @override
  String get supportFaqLoadAnswer =>
      'Models are large AI neural networks (1 GB to 4+ GB). Download speed depends on your Wi-Fi connection. Loading requires allocating RAM; ensure background apps are cleared before loading 7B+ models.';

  @override
  String get supportFaqPrivacyQuestion =>
      'Does Thinai leak or upload my chats to the cloud?';

  @override
  String get supportFaqPrivacyAnswer =>
      'Never. Thinai is built from the ground up to be 100% sovereign and offline. The neural weights run directly on your phone CPU/GPU silicon, and no conversational data leaves device memory.';

  @override
  String get supportFaqGpuQuestion =>
      'How do I use GPU acceleration (Vulkan / OpenCL)?';

  @override
  String get supportFaqGpuAnswer =>
      'Navigate to Settings > Hardware & Acceleration, and select Vulkan or OpenCL. Vulkan works best on Qualcomm Snapdragon Adreno and modern MediaTek Dimensity GPUs.';

  @override
  String get systemPromptTitle => 'System Prompt';

  @override
  String get systemPromptSaved =>
      'System prompt saved. New messages will use it.';

  @override
  String get systemPromptResetDone => 'System prompt reset to the default.';

  @override
  String get systemPromptDescription =>
      'Instructions sent to the model at the start of every chat. Changes apply from the next message you send. Leave it empty to use the model\'s own default.';

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
  String benchmarkDescription(int tokens) {
    return 'Generates $tokens tokens and measures decode speed. First token is reported separately.';
  }

  @override
  String get benchmarkTokensPerSecond => 'tokens / second';

  @override
  String get benchmarkIdle => 'Idle';

  @override
  String get benchmarkMeasuring => 'MEASURING';

  @override
  String get benchmarkThroughput => 'Throughput over the run';

  @override
  String benchmarkPeak(String value) {
    return 'peak $value';
  }

  @override
  String get benchmarkWarmingUp => 'Warming up…';

  @override
  String get benchmarkPlotEmpty => 'Run a benchmark to plot it';

  @override
  String get benchmarkFirstToken => 'First token';

  @override
  String get benchmarkTokens => 'Tokens';

  @override
  String get benchmarkTotal => 'Total';

  @override
  String get benchmarkSampleOutput => 'Sample output';

  @override
  String get benchmarkThisSession => 'This session';

  @override
  String benchmarkRunSummary(int tokens, String firstToken, String total) {
    return '$tokens tokens · first token $firstToken · total $total';
  }

  @override
  String get benchmarkEmptyTitle => 'No models to measure';

  @override
  String get benchmarkEmptyBody => 'Download a model to measure its speed.';

  @override
  String get benchmarkBestForHardware => 'Best for your hardware';

  @override
  String benchmarkMeasuredWithDevice(String device, String bandwidth) {
    return '$device · measured $bandwidth GB/s effective';
  }

  @override
  String benchmarkMeasured(String bandwidth) {
    return 'measured $bandwidth GB/s effective';
  }

  @override
  String benchmarkEstimateWithDevice(String device) {
    return '$device · run a benchmark to replace the estimates below with measurements';
  }

  @override
  String get benchmarkCalibratePrompt => 'Run a benchmark to calibrate these';

  @override
  String get benchmarkInstalled => 'installed';

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
