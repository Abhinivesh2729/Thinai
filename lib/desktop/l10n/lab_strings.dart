/// Desktop-only text for the Lab page (speed benchmark, Tamil score, GPU).
///
/// Phone strings that already read right on a PC come from `context.l10n`;
/// only text that would otherwise say "phone", or that the phone app never
/// needed, lives here. Tamil follows docs/TAMIL_GLOSSARY.md: benchmark
/// அளவுகோல், model அறிவுரு, Tamil score தமிழ் மதிப்பெண். No em dashes.
library;

import 'package:flutter/widgets.dart';

import 'desk_l10n.dart';

class LabStrings {
  const LabStrings._({
    required this.title,
    required this.subtitle,
    required this.tabSpeed,
    required this.tabTamil,
    required this.tabGpu,
    required this.model,
    required this.runHint,
    required this.bestForThisPc,
    required this.savedResults,
    required this.savedResultsHint,
    required this.noSavedResults,
    required this.notMeasured,
    required this.fastest,
    required this.busy,
    required this.savedToast,
    required this.stoppedToast,
    required this.daysAgo,
    required this.tamilBoardTitle,
    required this.tamilBoardHint,
    required this.tamilBoardEmpty,
    required this.gpuIntro,
    required this.gpuDevicesTitle,
    required this.gpuProbeHint,
    required this.gpuNoneFound,
    required this.gpuMacNote,
    required this.vram,
    required this.sharedMemory,
    required this.runModelsOn,
    required this.gpuSet,
    required this.speedTestTitle,
    required this.speedTestHint,
    required this.findGpuFirst,
    required this.useBackend,
    required this.switchToCpu,
    required this.timesFaster,
  });

  final String title, subtitle;
  final String tabSpeed, tabTamil, tabGpu;
  final String model, runHint;
  final String bestForThisPc;
  final String savedResults, savedResultsHint, noSavedResults;
  final String notMeasured, fastest, busy;
  final String Function(String model, String tps) savedToast;
  final String stoppedToast;
  final String Function(int days) daysAgo;
  final String tamilBoardTitle, tamilBoardHint, tamilBoardEmpty;
  final String gpuIntro, gpuDevicesTitle, gpuProbeHint, gpuNoneFound;
  final String gpuMacNote;
  final String Function(String gb) vram;
  final String sharedMemory, runModelsOn;
  final String Function(String backend) gpuSet;
  final String speedTestTitle;
  final String Function(String model) speedTestHint;
  final String findGpuFirst;
  final String Function(String backend) useBackend;
  final String switchToCpu;
  final String Function(String times) timesFaster;

  static LabStrings of(BuildContext context) => deskPick(context, en, ta);

  static final en = LabStrings._(
    title: 'Lab',
    subtitle:
        'Measure how fast and how well each model runs on this PC. '
        'Everything stays offline.',
    tabSpeed: 'Speed',
    tabTamil: 'Tamil score',
    tabGpu: 'GPU',
    model: 'Model',
    runHint: 'Same prompt and 128 tokens every run, so models compare fairly.',
    bestForThisPc: 'Best for this PC',
    savedResults: 'Saved on this PC',
    savedResultsHint:
        'Latest run per model. Each one sharpens the speed estimates on the '
        'Models page.',
    noSavedResults: 'No runs yet. Run a benchmark to start the board.',
    notMeasured: 'Not measured',
    fastest: 'Fastest',
    busy: 'Another test is using the engine. Start this one when it ends.',
    savedToast: (model, tps) => '$model: $tps tok/s saved',
    stoppedToast: 'Benchmark stopped. Nothing was saved.',
    daysAgo: (days) => '$days days ago',
    tamilBoardTitle: 'Tamil scores on this PC',
    tamilBoardHint:
        'Latest Tamil eval for each installed model. Treat gaps under 10 '
        'points as a tie.',
    tamilBoardEmpty: 'No scores yet. Run the eval to rank your models.',
    gpuIntro:
        'On Windows, Thinai reaches your graphics card through Vulkan. Small '
        'models are often faster on the CPU, so measure before you switch.',
    gpuDevicesTitle: 'Graphics on this PC',
    gpuProbeHint:
        'Finding the GPU loads its driver, so Thinai only looks when you ask.',
    gpuNoneFound: 'No Vulkan GPU found. Thinai runs on the CPU.',
    gpuMacNote: 'Metal cannot be selected here yet. Models run on the CPU.',
    vram: (gb) => '$gb GB VRAM',
    sharedMemory: 'Shared memory',
    runModelsOn: 'Run models on',
    gpuSet: (backend) => 'Models now run on $backend',
    speedTestTitle: 'CPU vs GPU',
    speedTestHint: (model) =>
        'Runs $model twice on each, 48 tokens. The first run loads the '
        'model, so the second one counts.',
    findGpuFirst: 'Find the GPU first.',
    useBackend: (backend) => 'Use $backend',
    switchToCpu: 'Switch to CPU',
    timesFaster: (times) => '${times}x faster',
  );

  static final ta = LabStrings._(
    title: 'ஆய்வகம்',
    subtitle:
        'ஒவ்வொரு அறிவுருவும் இந்தக் கணினியில் எவ்வளவு வேகமாகவும் நன்றாகவும் '
        'இயங்குகிறது என்று அளவிடுங்கள். எல்லாம் ஆஃப்லைனில்.',
    tabSpeed: 'வேகம்',
    tabTamil: 'தமிழ் மதிப்பெண்',
    tabGpu: 'GPU',
    model: 'அறிவுரு',
    runHint:
        'ஒவ்வொரு முறையும் அதே செய்தி, 128 tokens. அதனால் அறிவுருக்களை '
        'நியாயமாக ஒப்பிடலாம்.',
    bestForThisPc: 'இந்தக் கணினிக்குச் சிறந்தவை',
    savedResults: 'இந்தக் கணினியில் சேமித்தவை',
    savedResultsHint:
        'ஒவ்வொரு அறிவுருவின் கடைசி அளவீடு. இது அறிவுருக்கள் பக்கத்தின் வேக '
        'மதிப்பீடுகளைத் துல்லியமாக்கும்.',
    noSavedResults: 'இன்னும் அளவீடு இல்லை. தொடங்க அளவுகோலை இயக்கவும்.',
    notMeasured: 'அளவிடவில்லை',
    fastest: 'வேகமானது',
    busy: 'வேறொரு சோதனை இயங்குகிறது. அது முடிந்ததும் இதைத் தொடங்கலாம்.',
    savedToast: (model, tps) => '$model: $tps tok/s சேமிக்கப்பட்டது',
    stoppedToast: 'அளவுகோல் நிறுத்தப்பட்டது. எதுவும் சேமிக்கப்படவில்லை.',
    daysAgo: (days) => '$days நாட்களுக்கு முன்',
    tamilBoardTitle: 'இந்தக் கணினியில் தமிழ் மதிப்பெண்கள்',
    tamilBoardHint:
        'நிறுவிய ஒவ்வொரு அறிவுருவின் கடைசி தமிழ் மதிப்பீடு. 10 புள்ளிக்குக் '
        'குறைவான வேறுபாடு சமம்.',
    tamilBoardEmpty:
        'இன்னும் மதிப்பெண் இல்லை. அறிவுருக்களை வரிசைப்படுத்த மதிப்பீட்டை '
        'இயக்கவும்.',
    gpuIntro:
        'Windows-இல் Thinai உங்கள் கிராஃபிக்ஸ் கார்டை Vulkan வழியாகப் '
        'பயன்படுத்தும். சிறிய அறிவுருக்கள் பெரும்பாலும் CPU-வில் வேகமாக '
        'இயங்கும். மாற்றும் முன் அளந்து பாருங்கள்.',
    gpuDevicesTitle: 'இந்தக் கணினியின் GPU',
    gpuProbeHint:
        'GPU-வைக் கண்டறியும்போது அதன் driver ஏற்றப்படும். அதனால் நீங்கள் '
        'கேட்கும்போது மட்டுமே Thinai தேடும்.',
    gpuNoneFound: 'Vulkan GPU கிடைக்கவில்லை. Thinai CPU-வில் இயங்கும்.',
    gpuMacNote:
        'Metal-ஐ இங்கே இன்னும் தேர்ந்தெடுக்க முடியாது. அறிவுருக்கள் '
        'CPU-வில் இயங்கும்.',
    vram: (gb) => '$gb GB VRAM',
    sharedMemory: 'பகிர்ந்த நினைவகம்',
    runModelsOn: 'அறிவுருக்களை இயக்குவது',
    gpuSet: (backend) => 'அறிவுருக்கள் இனி $backend-இல் இயங்கும்',
    speedTestTitle: 'CPU vs GPU',
    speedTestHint: (model) =>
        '$model இரண்டிலும் இரு முறை இயங்கும், 48 tokens. முதல் ஓட்டம் '
        'அறிவுருவை ஏற்றும், இரண்டாவதே கணக்கில் வரும்.',
    findGpuFirst: 'முதலில் GPU-வைக் கண்டறியவும்.',
    useBackend: (backend) => '$backend பயன்படுத்து',
    switchToCpu: 'CPU-க்கு மாற்று',
    timesFaster: (times) => '$times மடங்கு வேகம்',
  );
}
