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
}
