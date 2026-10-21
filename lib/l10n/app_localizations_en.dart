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
      'Search engines are rate-limiting this network right now. Answering without the web.';

  @override
  String get chatSearchNoResults =>
      'No web results for that. Answering from the model itself.';

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
  String get chatBannerNoModelLoaded =>
      'No model loaded — tap to select or browse.';

  @override
  String get chatBannerNoModelDownloaded =>
      'No model downloaded — tap to download.';

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
      other: '$count installed on device',
    );
    return '$_temp0';
  }

  @override
  String get chatNoModelsDownloadedYet => 'No models downloaded yet';

  @override
  String get chatDownloadFromCatalogue =>
      'Download an open model from the catalogue to begin chatting.';

  @override
  String get chatBrowseModels => 'Browse Models';

  @override
  String get chatModelParameters => 'Model Parameters';

  @override
  String get chatDownloadMoreModels => 'Download More Models';

  @override
  String get chatEmptyTitle => 'Private Offline AI';

  @override
  String get chatEmptyBody =>
      'Chat privately with AI models that run 100% on your phone. No internet required, zero cloud tracking, and your data never leaves your device.';

  @override
  String get chatBrowseDownloadModels => 'Browse & Download Models';

  @override
  String get chatReadyWebSearchOn => 'AI Ready · Web Search On';

  @override
  String get chatReadyOffline => 'AI Ready · 100% Offline';

  @override
  String get chatRunningPrivately => 'Running privately on your phone silicon.';

  @override
  String get chatStarterBrainstorm => 'Brainstorm ideas';

  @override
  String get chatStarterPython => 'Write Python code';

  @override
  String get chatStarterSummarize => 'Summarize text';

  @override
  String get chatStarterSpeed => 'Measure speed';

  @override
  String chatAttachmentTrimmed(String size) {
    return '$size · trimmed';
  }

  @override
  String get chatInputHintGenerating => 'Generating…';

  @override
  String get chatInputHint => 'Message your model';

  @override
  String get chatStop => 'Stop';

  @override
  String get chatSend => 'Send';

  @override
  String get chatCopiedToClipboard => 'Copied to clipboard';

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
  String get chatDialWebSearchAuto => 'Automatic, on when needed';

  @override
  String get chatDialCamera => 'Camera';

  @override
  String get chatDialCameraDetail => 'Take a photo now';

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
  String get chatDrawerModelSettingsSubtitle => 'Context, sampling & thinking';

  @override
  String get chatDrawerNoModelSnack =>
      'No model downloaded yet. Download a model from the Models tab first.';

  @override
  String get chatDrawerAppSettings => 'App Settings';

  @override
  String get chatDrawerAppSettingsSubtitle => 'Theme, GPU, downloads & server';

  @override
  String get chatDrawerAbout => 'About Thinai';

  @override
  String get chatDrawerAboutSubtitle => 'Version, privacy & details';

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
  String chatDrawerDeleteManyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Are you sure you want to permanently delete $count selected conversations? This action cannot be undone.',
      one:
          'Are you sure you want to permanently delete 1 selected conversation? This action cannot be undone.',
    );
    return '$_temp0';
  }

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
  String get chatDrawerSelectManage => 'Select / Manage';

  @override
  String get chatDrawerRenameTitle => 'Rename title';

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
    return 'Are you sure you want to delete \"$title\"? This cannot be undone.';
  }

  @override
  String get chatDrawerNoHistory => 'No past conversations';

  @override
  String get chatDrawerNoHistoryHint => 'Start a chat to keep history here.';

  @override
  String chatDrawerNoResults(String query) {
    return 'No chats found for \"$query\"';
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
  String get chatHistoryTitle => 'Chat history';

  @override
  String get chatHistoryDeleteAllTooltip => 'Delete all chats';

  @override
  String get chatHistoryDeleteAllTitle => 'Delete all chats?';

  @override
  String get chatHistoryDeleteAllBody =>
      'Every saved conversation is removed. This cannot be undone.';

  @override
  String get chatHistoryDeleteAll => 'Delete all';

  @override
  String get chatHistoryDeleteOneTitle => 'Delete this chat?';

  @override
  String get chatHistorySearchHint => 'Search conversations…';

  @override
  String chatHistoryNoResults(String query) {
    return 'No chats matching \"$query\"';
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
  String get chatHistoryEmptyTitle => 'No saved chats yet';

  @override
  String get chatHistoryEmptyBody =>
      'Start a conversation and it will appear here.\nEverything stays on this device.';

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
      'A model is still downloading. Restarting pauses it, and you can resume it from the Models page.';

  @override
  String get chatAppRestart => 'Restart';

  @override
  String get chatAppUpdateReady => 'Update ready';

  @override
  String get chatAppUpdateAvailable => 'Update available';

  @override
  String get chatAppUpdateDownloading => 'Downloading in the background…';

  @override
  String get chatAppUpdateRestartToInstall =>
      'Restart Thinai to finish installing.';

  @override
  String get chatAppUpdateOnPlayStore =>
      'A newer version of Thinai is on Play Store.';
}
