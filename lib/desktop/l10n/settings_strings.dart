/// Desktop Settings text that the phone's ARB files do not have, or have in
/// phone wording ("phone", "Wi-Fi", "Play Store").
///
/// Phone strings that already fit a PC come from `context.l10n`. Tamil follows
/// docs/TAMIL_GLOSSARY.md: model அறிவுரு, server சேவகம், system prompt
/// அமைப்பு செய்தி, benchmark அளவுகோல். Tech names stay in English. No em
/// dashes.
library;

import 'package:flutter/widgets.dart';

import 'desk_l10n.dart';

class SettingsStrings {
  const SettingsStrings._({
    required this.isTamil,
    required this.title,
    required this.subtitle,
    required this.secAppearance,
    required this.secChat,
    required this.secSystemPrompt,
    required this.secHardware,
    required this.secModels,
    required this.secServer,
    required this.secAbout,
    required this.blurbAppearance,
    required this.blurbChat,
    required this.blurbHardware,
    required this.blurbModels,
    required this.blurbServer,
    required this.blurbAbout,
    required this.languageHint,
    required this.startPageHint,
    required this.glossaryHint,
    required this.open,
    required this.webSearchHint,
    required this.unsaved,
    required this.isDefault,
    required this.emptyMeansNone,
    required this.chatOnly,
    required this.saveShortcut,
    required this.gpuHint,
    required this.thisComputer,
    required this.benchmarks,
    required this.benchmarksHint,
    required this.openLab,
    required this.activeModel,
    required this.noModelHint,
    required this.browseModels,
    required this.importHint,
    required this.importing,
    required this.chooseFile,
    required this.urlHint,
    required this.clearHint,
    required this.clearBody,
    required this.clear,
    required this.modelsFolder,
    required this.openFolder,
    required this.copyPath,
    required this.pathCopied,
    required this.folderOpenFailed,
    required this.lanTitle,
    required this.lanHint,
    required this.portInvalid,
    required this.change,
    required this.statusStoppedHint,
    required this.openServer,
    required this.version,
    required this.tagline,
    required this.supportHint,
    required this.sourceCode,
    required this.sourceCodeHint,
    required this.openGithub,
    required this.licensesHint,
    required this.view,
    required this.diagnostics,
    required this.diagnosticsHint,
    required this.openLogFolder,
    required this.copyDiagnostics,
    required this.diagnosticsCopied,
    required this.logUnavailable,
    required this.faqPrivacyQuestion,
    required this.faqPrivacyAnswer,
    required this.faqLoadAnswer,
    required this.faqGpuAnswer,
    required this.close,
    required this.linkOpenFailed,
  });

  final bool isTamil;
  final String title, subtitle;
  final String secAppearance, secChat, secSystemPrompt, secHardware;
  final String secModels, secServer, secAbout;
  final String blurbAppearance, blurbChat, blurbHardware;
  final String blurbModels, blurbServer, blurbAbout;
  final String languageHint, startPageHint, glossaryHint, open;
  final String webSearchHint;
  final String unsaved, isDefault, emptyMeansNone, chatOnly, saveShortcut;
  final String gpuHint, thisComputer, benchmarks, benchmarksHint, openLab;
  final String activeModel, noModelHint, browseModels;
  final String importHint, importing, chooseFile, urlHint;
  final String clearHint, clearBody, clear;
  final String modelsFolder, openFolder, copyPath, pathCopied;
  final String folderOpenFailed;
  final String lanTitle, lanHint, portInvalid, change;
  final String statusStoppedHint, openServer;
  final String version, tagline, supportHint;
  final String sourceCode, sourceCodeHint, openGithub, licensesHint, view;
  final String diagnostics, diagnosticsHint, openLogFolder, copyDiagnostics;
  final String diagnosticsCopied, logUnavailable;
  final String faqPrivacyQuestion, faqPrivacyAnswer, faqLoadAnswer;
  final String faqGpuAnswer;
  final String close, linkOpenFailed;

  /// "16 GB RAM · 8 cores · x64"; RAM left out when it could not be read.
  String deviceLine({double? ramGb, required int cores, required String arch}) {
    final parts = [
      if (ramGb != null) '${ramGb.toStringAsFixed(ramGb >= 10 ? 0 : 1)} GB RAM',
      isTamil ? '$cores கோர்கள்' : '$cores cores',
      arch,
    ];
    return parts.join(' · ');
  }

  String portHint(int defaultPort) => isTamil
      ? 'இயல்புநிலை $defaultPort. கணினியில் 11434-ஐ பொதுவாக Ollama பயன்படுத்தும்.'
      : 'Default $defaultPort. Ollama usually holds 11434 on a PC.';

  String runningOn(int port, {required bool lan}) => isTamil
      ? (lan
            ? 'port $port-இல் நெட்வொர்க்கில் இயங்குகிறது'
            : 'port $port-இல் இந்தக் கணினியில் மட்டும் இயங்குகிறது')
      : (lan
            ? 'Running on port $port, shared on your network'
            : 'Running on port $port, this computer only');

  static SettingsStrings of(BuildContext context) => deskPick(context, en, ta);

  static const en = SettingsStrings._(
    isTamil: false,
    title: 'Settings',
    subtitle: 'Thinai on this computer',
    secAppearance: 'Appearance',
    secChat: 'Chat',
    secSystemPrompt: 'System prompt',
    secHardware: 'Hardware',
    secModels: 'Models & storage',
    secServer: 'Local server',
    secAbout: 'About & help',
    blurbAppearance: 'Theme, language and where Thinai opens.',
    blurbChat: 'How chats behave.',
    blurbHardware: 'How this computer runs models.',
    blurbModels: 'The active model and the model files on this PC.',
    blurbServer: 'An OpenAI and Ollama compatible API served from this PC.',
    blurbAbout: 'Version, support and diagnostics.',
    languageHint:
        'Tamil also switches the default system prompt to Tamil replies.',
    startPageHint: 'The page Thinai opens on.',
    glossaryHint: 'The English and Tamil words the app uses, side by side.',
    open: 'Open',
    webSearchHint:
        'Looks up questions that need the live web. Only the question '
        'leaves this PC, never the chat.',
    unsaved: 'Unsaved changes',
    isDefault: 'Default',
    emptyMeansNone: "Empty: the model's own default applies.",
    chatOnly: 'Chat only. API clients send their own.',
    saveShortcut: 'Ctrl+S to save',
    gpuHint:
        'Vulkan can speed up larger models on a dedicated GPU. Run the speed '
        'test to check it helps on this PC.',
    thisComputer: 'This computer',
    benchmarks: 'Benchmarks',
    benchmarksHint: 'Measure speed and Tamil quality on this PC in the Lab.',
    openLab: 'Open Lab',
    activeModel: 'Active model',
    noModelHint: 'Pick one from the catalog to start chatting.',
    browseModels: 'Browse models',
    importHint: 'Copy a GGUF file from this PC into Thinai.',
    importing: 'Importing…',
    chooseFile: 'Choose file',
    urlHint: 'Any direct link to a .gguf file.',
    clearHint: 'Deletes every model file Thinai downloaded or imported.',
    clearBody:
        'Every downloaded model will be deleted from this PC. This cannot be '
        'undone.',
    clear: 'Clear',
    modelsFolder: 'Models folder',
    openFolder: 'Open folder',
    copyPath: 'Copy path',
    pathCopied: 'Path copied',
    folderOpenFailed: "Couldn't open the folder",
    lanTitle: 'Share on your network',
    lanHint:
        'Other devices on your network can call the API with a token. '
        'Applies the next time the server starts.',
    portInvalid: 'Enter a port from 1 to 65535.',
    change: 'Change',
    statusStoppedHint: 'Start it from the Server page.',
    openServer: 'Open Server',
    version: 'Version',
    tagline: 'Private AI that runs on this computer. No internet needed.',
    supportHint: 'Message us on Instagram for help or to report a bug.',
    sourceCode: 'Source code',
    sourceCodeHint: 'Thinai is open source on GitHub.',
    openGithub: 'Open GitHub',
    licensesHint: 'The open-source licenses Thinai is built on.',
    view: 'View',
    diagnostics: 'Diagnostics',
    diagnosticsHint:
        'A log of startup, model loads and errors. Never your chats. Copy it '
        'into a bug report.',
    openLogFolder: 'Open log folder',
    copyDiagnostics: 'Copy diagnostics',
    diagnosticsCopied: 'Diagnostics copied',
    logUnavailable: "The log isn't ready yet.",
    faqPrivacyQuestion: 'Do my chats leave this computer?',
    faqPrivacyAnswer:
        'No. Models run entirely on this PC and your chats stay on it. Web '
        'search sends only the question.',
    faqLoadAnswer:
        'Models are 1 to 8 GB. Downloads depend on your connection, and '
        'loading needs free RAM, so close heavy apps first.',
    faqGpuAnswer:
        'Settings > Hardware > GPU acceleration. Pick Vulkan, then run the '
        'speed test to check it is faster.',
    close: 'Close',
    linkOpenFailed: "Couldn't open the link",
  );

  static const ta = SettingsStrings._(
    isTamil: true,
    title: 'அமைப்புகள்',
    subtitle: 'இந்தக் கணினியில் Thinai',
    secAppearance: 'தோற்றம்',
    secChat: 'உரையாடல்',
    secSystemPrompt: 'அமைப்பு செய்தி',
    secHardware: 'வன்பொருள்',
    secModels: 'அறிவுருக்கள் & சேமிப்பகம்',
    secServer: 'லோக்கல் சேவகம்',
    secAbout: 'பற்றி & உதவி',
    blurbAppearance: 'தீம், மொழி, Thinai திறக்கும் பக்கம்.',
    blurbChat: 'உரையாடல்கள் எப்படி இயங்கும்.',
    blurbHardware: 'இந்தக் கணினி அறிவுருக்களை எப்படி இயக்குகிறது.',
    blurbModels:
        'இயங்கும் அறிவுருவும் இந்தக் கணினியிலுள்ள அறிவுருக் கோப்புகளும்.',
    blurbServer: 'இந்தக் கணினியிலிருந்து OpenAI, Ollama இணக்க API.',
    blurbAbout: 'பதிப்பு, ஆதரவு, கண்டறிதல்.',
    languageHint:
        'தமிழைத் தேர்ந்தால் இயல்பு அமைப்பு செய்தியும் தமிழ்ப் பதில்களுக்கு மாறும்.',
    startPageHint: 'Thinai திறக்கும் பக்கம்.',
    glossaryHint: 'ஆப் பயன்படுத்தும் ஆங்கில, தமிழ்ச் சொற்கள் அருகருகே.',
    open: 'திற',
    webSearchHint:
        'நேரடி இணையம் தேவைப்படும் கேள்விகளைத் தேடும். கேள்வி மட்டுமே '
        'இந்தக் கணினியை விட்டு வெளியேறும், உரையாடல் அல்ல.',
    unsaved: 'சேமிக்காத மாற்றங்கள்',
    isDefault: 'இயல்புநிலை',
    emptyMeansNone:
        'காலியாக இருந்தால் அறிவுருவின் சொந்த இயல்புநிலை பொருந்தும்.',
    chatOnly: 'உரையாடலுக்கு மட்டும். API பயன்பாடுகள் தங்களுடையதை அனுப்பும்.',
    saveShortcut: 'சேமிக்க Ctrl+S',
    gpuHint:
        'தனி GPU இருந்தால் பெரிய அறிவுருக்களை Vulkan வேகமாக்கலாம். இந்தக் '
        'கணினியில் உதவுகிறதா என வேகச் சோதனையில் பார்க்கவும்.',
    thisComputer: 'இந்தக் கணினி',
    benchmarks: 'அளவுகோல்கள்',
    benchmarksHint:
        'இந்தக் கணினியின் வேகத்தையும் தமிழ்த் தரத்தையும் ஆய்வகத்தில் அளவிடவும்.',
    openLab: 'ஆய்வகத்தைத் திற',
    activeModel: 'இயங்கும் அறிவுரு',
    noModelHint: 'உரையாடத் தொடங்க பட்டியலிலிருந்து ஒன்றைத் தேர்ந்தெடுக்கவும்.',
    browseModels: 'அறிவுருக்களைப் பார்',
    importHint: 'இந்தக் கணினியிலுள்ள GGUF கோப்பை Thinai-க்கு நகலெடுக்கும்.',
    importing: 'இறக்குமதியாகிறது…',
    chooseFile: 'கோப்பைத் தேர்',
    urlHint: '.gguf கோப்புக்கான எந்த நேரடி இணைப்பும்.',
    clearHint:
        'Thinai பதிவிறக்கிய அல்லது இறக்குமதி செய்த எல்லா அறிவுருக் கோப்புகளையும் நீக்கும்.',
    clearBody:
        'பதிவிறக்கிய எல்லா அறிவுருக்களும் இந்தக் கணினியிலிருந்து நீக்கப்படும். '
        'இதைத் திரும்பப் பெற முடியாது.',
    clear: 'நீக்கு',
    modelsFolder: 'அறிவுருக் கோப்புறை',
    openFolder: 'கோப்புறையைத் திற',
    copyPath: 'பாதையை நகலெடு',
    pathCopied: 'பாதை நகலெடுக்கப்பட்டது',
    folderOpenFailed: 'கோப்புறையைத் திறக்க முடியவில்லை',
    lanTitle: 'நெட்வொர்க்கில் பகிர்',
    lanHint:
        'உங்கள் நெட்வொர்க்கிலுள்ள மற்ற சாதனங்கள் token மூலம் API-ஐப் '
        'பயன்படுத்தலாம். அடுத்த முறை சேவகம் தொடங்கும்போது பொருந்தும்.',
    portInvalid: '1 முதல் 65535 வரை ஒரு port-ஐ உள்ளிடவும்.',
    change: 'மாற்று',
    statusStoppedHint: 'சேவகம் பக்கத்திலிருந்து தொடங்கவும்.',
    openServer: 'சேவகத்தைத் திற',
    version: 'பதிப்பு',
    tagline: 'இந்தக் கணினியிலேயே இயங்கும் தனிப்பட்ட AI. இணையம் தேவையில்லை.',
    supportHint:
        'உதவிக்கோ பிழையைத் தெரிவிக்கவோ Instagram-இல் எங்களுக்கு உரை அனுப்பவும்.',
    sourceCode: 'மூலக் குறியீடு',
    sourceCodeHint: 'Thinai, GitHub-இல் திறந்த மூலமாக உள்ளது.',
    openGithub: 'GitHub-ஐத் திற',
    licensesHint: 'Thinai கட்டமைக்கப்பட்டுள்ள திறந்த மூல உரிமங்கள்.',
    view: 'பார்',
    diagnostics: 'கண்டறிதல்',
    diagnosticsHint:
        'தொடக்கம், அறிவுரு ஏற்றம், பிழைகளின் பதிவு. உங்கள் உரையாடல்கள் இதில் '
        'இல்லை. பிழையைத் தெரிவிக்கும்போது இதை நகலெடுத்து அனுப்பவும்.',
    openLogFolder: 'பதிவுக் கோப்புறையைத் திற',
    copyDiagnostics: 'கண்டறிதலை நகலெடு',
    diagnosticsCopied: 'கண்டறிதல் நகலெடுக்கப்பட்டது',
    logUnavailable: 'பதிவு இன்னும் தயாராகவில்லை.',
    faqPrivacyQuestion: 'என் உரையாடல்கள் இந்தக் கணினியை விட்டு வெளியேறுமா?',
    faqPrivacyAnswer:
        'இல்லை. அறிவுருக்கள் முழுவதும் இந்தக் கணினியிலேயே இயங்கும், உங்கள் '
        'உரையாடல்களும் இங்கேயே இருக்கும். இணையத் தேடல் கேள்வியை மட்டுமே அனுப்பும்.',
    faqLoadAnswer:
        'அறிவுருக்கள் 1 முதல் 8 GB வரை இருக்கும். பதிவிறக்க வேகம் இணைப்பைப் '
        'பொறுத்தது. ஏற்ற RAM தேவை, எனவே முதலில் கனமான ஆப்களை மூடவும்.',
    faqGpuAnswer:
        'அமைப்புகள் > வன்பொருள் > GPU வேகமாக்கல். Vulkan-ஐத் தேர்ந்தெடுத்து, '
        'அது வேகமானதா என வேகச் சோதனையில் பார்க்கவும்.',
    close: 'மூடு',
    linkOpenFailed: 'இணைப்பைத் திறக்க முடியவில்லை',
  );
}
