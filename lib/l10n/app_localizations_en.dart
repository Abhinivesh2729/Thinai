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
}
