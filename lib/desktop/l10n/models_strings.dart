/// Desktop-only text for the Models page, English and Tamil.
///
/// Phone strings that already fit come from `context.l10n`. What lives here
/// either has no phone equivalent (drag and drop, the docked manager) or the
/// phone version says "phone" where a desktop has to say "PC". Tamil follows
/// docs/TAMIL_GLOSSARY.md: model அறிவுரு, benchmark அளவுகோல், no em dashes,
/// product and format names (Thinai, GGUF, RAM, Hugging Face) untranslated.
library;

import 'package:flutter/widgets.dart';

import 'desk_l10n.dart';

class ModelsStrings {
  const ModelsStrings._({
    required this.subtitle,
    required this.thisPc,
    required this.readingPc,
    required this.importGguf,
    required this.importing,
    required this.imported,
    required this.importFailed,
    required this.notGguf,
    required this.alreadyExists,
    required this.dropTitle,
    required this.dropBody,
    required this.searchHubFor,
    required this.searchHubBody,
    required this.findMoreHub,
    required this.searchHubTooltip,
    required this.findMoreHubBody,
    required this.offlineFooter,
    required this.fitTooLarge,
    required this.fitNeeds,
    required this.fitTooBig,
    required this.fitTight,
    required this.caveatNoneFits,
    required this.caveatNothingFitsWell,
    required this.caveatNothingStrong,
    required this.diskUse,
    required this.downloading,
    required this.installedTitle,
    required this.close,
    required this.openInLab,
    required this.needsRamAbout,
    required this.estimatedSpeed,
    required this.measuredSpeed,
    required this.memory,
    required this.dropHint,
    required this.noGoal,
    required this.loadAndChat,
    required this.downloadStopped,
  });

  final String subtitle;
  final String Function(String summary) thisPc;
  final String readingPc;
  final String importGguf;
  final String importing;
  final String Function(String name) imported;
  final String Function(String error) importFailed;
  final String notGguf;
  final String Function(String name) alreadyExists;
  final String dropTitle, dropBody;
  final String Function(String query) searchHubFor;
  final String searchHubBody, findMoreHub, findMoreHubBody;

  /// Tooltip on the Hugging Face button in the search box.
  final String searchHubTooltip;
  final String offlineFooter;
  final String fitTooLarge;
  final String Function(String needs, String available) fitNeeds;
  final String fitTooBig, fitTight;
  final String Function(String goal) caveatNoneFits;
  final String Function(String goal) caveatNothingFitsWell;
  final String Function(String goal) caveatNothingStrong;
  final String Function(String size) diskUse;
  final String downloading, installedTitle, close, openInLab;
  final String Function(String ram) needsRamAbout;
  final String estimatedSpeed, measuredSpeed, memory;
  final String dropHint, noGoal, loadAndChat;

  /// The phone says "Tap Resume"; a desktop clicks.
  final String Function(String model, String error) downloadStopped;

  static ModelsStrings of(BuildContext context) => deskPick(context, en, ta);

  static final en = ModelsStrings._(
    subtitle: 'Private models that run fully offline on this PC.',
    thisPc: (summary) => 'This PC: $summary',
    readingPc: 'Checking this PC…',
    importGguf: 'Import .gguf',
    importing: 'Importing…',
    imported: (name) => 'Imported $name',
    importFailed: (error) => 'Could not import: $error',
    notGguf: 'Only .gguf model files can be imported.',
    alreadyExists: (name) => 'A model named $name already exists.',
    dropTitle: 'Drop .gguf files to import',
    dropBody: "They are copied into Thinai's models folder.",
    searchHubFor: (query) => 'Search Hugging Face for "$query"',
    searchHubBody: 'Browse public GGUF models beyond the catalog.',
    findMoreHub: 'Find more on Hugging Face',
    searchHubTooltip: 'Search all of Hugging Face for GGUF models',
    findMoreHubBody: 'Thousands of public GGUF models, one search away.',
    offlineFooter: 'Models run fully offline on this PC.',
    fitTooLarge: 'Too large for this PC.',
    fitNeeds: (needs, available) =>
        'Needs $needs, this PC has $available to spare.',
    fitTooBig: 'Too big for this PC',
    fitTight: 'Tight fit. Other apps may slow down while it runs.',
    caveatNoneFits: (goal) => 'No model in the catalog fits this PC for $goal.',
    caveatNothingFitsWell: (goal) =>
        'Nothing fits well for $goal. These are the closest.',
    caveatNothingStrong: (goal) =>
        'Nothing at this size is strong at $goal. Closest matches shown.',
    diskUse: (size) => '$size on disk',
    downloading: 'Downloading',
    installedTitle: 'Installed',
    close: 'Close',
    openInLab: 'Opens in Lab',
    needsRamAbout: (ram) => 'Needs about $ram',
    estimatedSpeed: 'Estimated speed',
    measuredSpeed: 'Measured speed',
    memory: 'Memory',
    dropHint: 'Tip: drop .gguf files anywhere on this page.',
    noGoal: 'Any goal',
    loadAndChat: 'Load and chat',
    downloadStopped: (model, error) =>
        '$model stopped: $error. Click Resume to continue.',
  );

  static final ta = ModelsStrings._(
    subtitle:
        'இந்தக் கணினியில் முழுமையாக ஆஃப்லைனில் இயங்கும் தனிப்பட்ட அறிவுருக்கள்.',
    thisPc: (summary) => 'இந்தக் கணினி: $summary',
    readingPc: 'இந்தக் கணினியைச் சரிபார்க்கிறது…',
    importGguf: 'GGUF சேர்',
    importing: 'சேர்க்கிறது…',
    imported: (name) => '$name சேர்க்கப்பட்டது',
    importFailed: (error) => 'சேர்க்க முடியவில்லை: $error',
    notGguf: '.gguf அறிவுரு கோப்புகளை மட்டுமே சேர்க்க முடியும்.',
    alreadyExists: (name) => '$name என்ற பெயரில் ஏற்கனவே ஒரு அறிவுரு உள்ளது.',
    dropTitle: 'சேர்க்க .gguf கோப்புகளை இங்கே விடுங்கள்',
    dropBody: 'அவை Thinai அறிவுருக் கோப்புறைக்கு நகலெடுக்கப்படும்.',
    searchHubFor: (query) => 'Hugging Face இல் "$query" தேடு',
    searchHubBody:
        'பட்டியலுக்கு அப்பால் உள்ள பொது GGUF அறிவுருக்களைப் பாருங்கள்.',
    findMoreHub: 'Hugging Face இல் மேலும் தேடு',
    searchHubTooltip: 'Hugging Face முழுவதும் GGUF அறிவுருக்களைத் தேடு',
    findMoreHubBody: 'ஆயிரக்கணக்கான பொது GGUF அறிவுருக்கள், ஒரே தேடலில்.',
    offlineFooter:
        'அறிவுருக்கள் இந்தக் கணினியில் முழுமையாக ஆஃப்லைனில் இயங்கும்.',
    fitTooLarge: 'இந்தக் கணினிக்கு மிகப் பெரியது.',
    fitNeeds: (needs, available) =>
        '$needs தேவை, இந்தக் கணினியில் $available மட்டுமே உள்ளது.',
    fitTooBig: 'இந்தக் கணினிக்குப் பெரியது',
    fitTight:
        'நெருக்கமான பொருத்தம். இது இயங்கும்போது மற்ற செயலிகள் மெதுவாகலாம்.',
    caveatNoneFits: (goal) =>
        '$goal பணிக்கு இந்தக் கணினியில் பொருந்தும் அறிவுரு பட்டியலில் இல்லை.',
    caveatNothingFitsWell: (goal) =>
        '$goal பணிக்கு நன்றாகப் பொருந்துவது இல்லை. இவை அருகில் உள்ளவை.',
    caveatNothingStrong: (goal) =>
        'இந்த அளவில் $goal பணியில் வலுவானது இல்லை. அருகில் உள்ளவை காட்டப்படுகின்றன.',
    diskUse: (size) => 'சேமிப்பகத்தில் $size',
    downloading: 'பதிவிறக்குகிறது',
    installedTitle: 'நிறுவப்பட்டவை',
    close: 'மூடு',
    openInLab: 'ஆய்வகத்தில் திறக்கும்',
    needsRamAbout: (ram) => 'சுமார் $ram தேவை',
    estimatedSpeed: 'மதிப்பிடப்பட்ட வேகம்',
    measuredSpeed: 'அளவிடப்பட்ட வேகம்',
    memory: 'நினைவகம்',
    dropHint: 'குறிப்பு: .gguf கோப்புகளை இந்தப் பக்கத்தில் எங்கும் விடலாம்.',
    noGoal: 'எந்த இலக்கும்',
    loadAndChat: 'ஏற்றி உரையாடு',
    downloadStopped: (model, error) =>
        '$model நின்றது: $error. தொடர, தொடர் என்பதை அழுத்தவும்.',
  );
}
