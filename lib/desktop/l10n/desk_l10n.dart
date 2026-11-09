/// Desktop-only UI text, English and Tamil.
///
/// Strings the phone app already has come from `context.l10n` (lib/l10n).
/// Text that exists only on desktop lives here, one small class per area,
/// so the ARB files stay the phone's. Tamil follows docs/TAMIL_GLOSSARY.md:
/// chat உரையாடல், model அறிவுரு, server சேவகம், message உரை,
/// prompt செய்தி, benchmark அளவுகோல். No em dashes.
library;

import 'package:flutter/widgets.dart';

/// True when the UI language is Tamil.
bool deskIsTamil(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ta';

/// Picks the English or Tamil value.
T deskPick<T>(BuildContext context, T en, T ta) =>
    deskIsTamil(context) ? ta : en;

/// Shell and chat text.
class ShellStrings {
  const ShellStrings._({
    required this.navChat,
    required this.navModels,
    required this.navLab,
    required this.navServer,
    required this.navSettings,
    required this.newChat,
    required this.searchChats,
    required this.noChatsYet,
    required this.noMatches,
    required this.today,
    required this.yesterday,
    required this.previous7,
    required this.thisMonth,
    required this.older,
    required this.rename,
    required this.delete,
    required this.deleteChatTitle,
    required this.deleteChatBody,
    required this.cancel,
    required this.save,
    required this.greeting,
    required this.greetingSub,
    required this.noModelTitle,
    required this.noModelBody,
    required this.getModel,
    required this.composerHint,
    required this.composerHintNoModel,
    required this.attach,
    required this.attachDocument,
    required this.attachImage,
    required this.webSearch,
    required this.webOn,
    required this.webOff,
    required this.dropToAttach,
    required this.copy,
    required this.copied,
    required this.thinking,
    required this.searching,
    required this.stopped,
    required this.tokPerSec,
    required this.firstToken,
    required this.switchModel,
    required this.modelSettings,
    required this.manageModels,
    required this.noModelsInstalled,
    required this.jumpToLatest,
    required this.collapseSidebar,
    required this.expandSidebar,
    required this.shortcutsHint,
    required this.sources,
    required this.minimize,
    required this.maximize,
    required this.close,
  });

  final String navChat, navModels, navLab, navServer, navSettings;
  final String newChat, searchChats, noChatsYet, noMatches;
  final String today, yesterday, previous7, thisMonth, older;
  final String rename, delete, deleteChatTitle, deleteChatBody, cancel, save;
  final String greeting, greetingSub;
  final String noModelTitle, noModelBody, getModel;
  final String composerHint, composerHintNoModel;
  final String attach, attachDocument, attachImage;
  final String webSearch, webOn, webOff, dropToAttach;
  final String copy, copied, thinking, searching, stopped;
  final String tokPerSec, firstToken;
  final String switchModel, modelSettings, manageModels, noModelsInstalled;
  final String jumpToLatest, collapseSidebar, expandSidebar, shortcutsHint;
  final String sources, minimize, maximize, close;

  static ShellStrings of(BuildContext context) => deskPick(context, en, ta);

  static const en = ShellStrings._(
    navChat: 'Chat',
    navModels: 'Models',
    navLab: 'Lab',
    navServer: 'Server',
    navSettings: 'Settings',
    newChat: 'New chat',
    searchChats: 'Search chats',
    noChatsYet: 'Your chats will appear here.',
    noMatches: 'No chats match.',
    today: 'Today',
    yesterday: 'Yesterday',
    previous7: 'Previous 7 days',
    thisMonth: 'This month',
    older: 'Older',
    rename: 'Rename',
    delete: 'Delete',
    deleteChatTitle: 'Delete chat?',
    deleteChatBody: 'This chat will be removed from this PC.',
    cancel: 'Cancel',
    save: 'Save',
    greeting: 'What shall we think about?',
    greetingSub: 'Private and offline. Everything stays on this PC.',
    noModelTitle: 'Pick a model to begin',
    noModelBody: 'Download one from the catalog. It runs fully on this PC.',
    getModel: 'Get a model',
    composerHint: 'Ask anything',
    composerHintNoModel: 'Load a model to start chatting',
    attach: 'Attach',
    attachDocument: 'Document',
    attachImage: 'Image',
    webSearch: 'Web search',
    webOn: 'Web search on',
    webOff: 'Web search off',
    dropToAttach: 'Drop to attach',
    copy: 'Copy',
    copied: 'Copied',
    thinking: 'Thinking',
    searching: 'Searching the web',
    stopped: 'Stopped',
    tokPerSec: 'tok/s',
    firstToken: 'first token',
    switchModel: 'Switch model',
    modelSettings: 'Model settings',
    manageModels: 'Manage models',
    noModelsInstalled: 'No models installed yet',
    jumpToLatest: 'Jump to latest',
    collapseSidebar: 'Hide chats',
    expandSidebar: 'Show chats',
    shortcutsHint: 'Enter to send · Shift+Enter for a new line',
    sources: 'Sources',
    minimize: 'Minimize',
    maximize: 'Maximize',
    close: 'Close',
  );

  static const ta = ShellStrings._(
    navChat: 'உரையாடல்',
    navModels: 'அறிவுருக்கள்',
    navLab: 'ஆய்வகம்',
    navServer: 'சேவகம்',
    navSettings: 'அமைப்புகள்',
    newChat: 'புதிய உரையாடல்',
    searchChats: 'உரையாடல்களைத் தேடு',
    noChatsYet: 'உங்கள் உரையாடல்கள் இங்கே தோன்றும்.',
    noMatches: 'பொருந்தும் உரையாடல் இல்லை.',
    today: 'இன்று',
    yesterday: 'நேற்று',
    previous7: 'கடந்த 7 நாட்கள்',
    thisMonth: 'இந்த மாதம்',
    older: 'பழையவை',
    rename: 'பெயர் மாற்று',
    delete: 'நீக்கு',
    deleteChatTitle: 'உரையாடலை நீக்கவா?',
    deleteChatBody: 'இந்த உரையாடல் இந்தக் கணினியிலிருந்து நீக்கப்படும்.',
    cancel: 'ரத்து',
    save: 'சேமி',
    greeting: 'எதைப் பற்றி யோசிக்கலாம்?',
    greetingSub: 'தனிப்பட்டது, இணையம் தேவையில்லை. எல்லாம் இந்தக் கணினியிலேயே.',
    noModelTitle: 'தொடங்க ஒரு அறிவுருவைத் தேர்ந்தெடுங்கள்',
    noModelBody:
        'பட்டியலிலிருந்து பதிவிறக்குங்கள். இது இந்தக் கணினியிலேயே இயங்கும்.',
    getModel: 'அறிவுரு பெறு',
    composerHint: 'எதையும் கேளுங்கள்',
    composerHintNoModel: 'உரையாட ஒரு அறிவுருவை ஏற்றுங்கள்',
    attach: 'இணை',
    attachDocument: 'ஆவணம்',
    attachImage: 'படம்',
    webSearch: 'இணையத் தேடல்',
    webOn: 'இணையத் தேடல் இயக்கத்தில்',
    webOff: 'இணையத் தேடல் நிறுத்தத்தில்',
    dropToAttach: 'இணைக்க இங்கே விடுங்கள்',
    copy: 'நகலெடு',
    copied: 'நகலெடுக்கப்பட்டது',
    thinking: 'யோசிக்கிறது',
    searching: 'இணையத்தில் தேடுகிறது',
    stopped: 'நிறுத்தப்பட்டது',
    tokPerSec: 'tok/s',
    firstToken: 'முதல் token',
    switchModel: 'அறிவுருவை மாற்று',
    modelSettings: 'அறிவுரு அமைப்புகள்',
    manageModels: 'அறிவுருக்களை நிர்வகி',
    noModelsInstalled: 'இன்னும் அறிவுரு நிறுவப்படவில்லை',
    jumpToLatest: 'சமீபத்தியதுக்குச் செல்',
    collapseSidebar: 'உரையாடல்களை மறை',
    expandSidebar: 'உரையாடல்களைக் காட்டு',
    shortcutsHint: 'அனுப்ப Enter · புதிய வரிக்கு Shift+Enter',
    sources: 'மூலங்கள்',
    minimize: 'சிறிதாக்கு',
    maximize: 'பெரிதாக்கு',
    close: 'மூடு',
  );
}
