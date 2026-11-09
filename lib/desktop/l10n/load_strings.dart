/// Text for the load monitor (Lab > Load and the live strip in chat).
library;

import 'package:flutter/widgets.dart';

import 'desk_l10n.dart';

class LoadStrings {
  const LoadStrings._({
    required this.tab,
    required this.cpu,
    required this.cpuThinai,
    required this.memory,
    required this.memoryThinai,
    required this.power,
    required this.measured,
    required this.estimated,
    required this.battery,
    required this.pluggedIn,
    required this.noBattery,
    required this.sinceOpened,
    required this.liveTitle,
    required this.liveLegendSystem,
    required this.liveLegendThinai,
    required this.liveLegendRam,
    required this.modelsTitle,
    required this.modelsEmpty,
    required this.colModel,
    required this.colTime,
    required this.colTokens,
    required this.colCpu,
    required this.colRam,
    required this.colEnergy,
    required this.colCo2,
    required this.footprintTitle,
    required this.footprintEnergy,
    required this.footprintCo2,
    required this.phoneCharge,
    required this.method,
    required this.idle,
  });

  final String tab, cpu, cpuThinai, memory, memoryThinai, power;
  final String measured, estimated, battery, pluggedIn, noBattery;
  final String sinceOpened, liveTitle, liveLegendSystem, liveLegendThinai;
  final String liveLegendRam, modelsTitle, modelsEmpty;
  final String colModel, colTime, colTokens, colCpu, colRam, colEnergy, colCo2;
  final String footprintTitle, footprintEnergy, footprintCo2;
  final String Function(String percent) phoneCharge;
  final String method, idle;

  static LoadStrings of(BuildContext context) => deskPick(context, en, ta);

  static final en = LoadStrings._(
    tab: 'Load',
    cpu: 'CPU',
    cpuThinai: 'Thinai',
    memory: 'Memory',
    memoryThinai: 'Thinai uses',
    power: 'Power',
    measured: 'measured',
    estimated: 'estimated',
    battery: 'Battery',
    pluggedIn: 'Plugged in',
    noBattery: 'No battery',
    sinceOpened: 'since Thinai opened',
    liveTitle: 'Live load',
    liveLegendSystem: 'All apps',
    liveLegendThinai: 'Thinai',
    liveLegendRam: 'Memory',
    modelsTitle: 'What each model costs',
    modelsEmpty:
        'Chat, benchmark or call the API and each model\'s load shows up here.',
    colModel: 'Model',
    colTime: 'Busy',
    colTokens: 'Tokens',
    colCpu: 'Avg CPU',
    colRam: 'Peak RAM',
    colEnergy: 'Energy',
    colCo2: 'CO₂',
    footprintTitle: 'Footprint this session',
    footprintEnergy: 'Energy used by Thinai',
    footprintCo2: 'Carbon emitted',
    phoneCharge: (p) => 'About $p% of one phone charge',
    method:
        'Power is read from the battery while unplugged, otherwise estimated '
        'from CPU load. CO₂ uses India\'s grid average of 716 g per kWh.',
    idle: 'Idle',
  );

  static final ta = LoadStrings._(
    tab: 'சுமை',
    cpu: 'CPU',
    cpuThinai: 'Thinai',
    memory: 'நினைவகம்',
    memoryThinai: 'Thinai பயன்பாடு',
    power: 'மின்சக்தி',
    measured: 'அளந்தது',
    estimated: 'மதிப்பீடு',
    battery: 'மின்கலம்',
    pluggedIn: 'மின் இணைப்பில்',
    noBattery: 'மின்கலம் இல்லை',
    sinceOpened: 'Thinai திறந்ததிலிருந்து',
    liveTitle: 'நேரலைச் சுமை',
    liveLegendSystem: 'எல்லா செயலிகளும்',
    liveLegendThinai: 'Thinai',
    liveLegendRam: 'நினைவகம்',
    modelsTitle: 'ஒவ்வொரு அறிவுருவின் செலவு',
    modelsEmpty:
        'உரையாடுங்கள், அளவுகோல் ஓட்டுங்கள் அல்லது API ஐ அழையுங்கள்; ஒவ்வொரு அறிவுருவின் சுமையும் இங்கே தோன்றும்.',
    colModel: 'அறிவுரு',
    colTime: 'இயங்கிய நேரம்',
    colTokens: 'Tokens',
    colCpu: 'சராசரி CPU',
    colRam: 'உச்ச RAM',
    colEnergy: 'ஆற்றல்',
    colCo2: 'CO₂',
    footprintTitle: 'இந்த அமர்வின் தடம்',
    footprintEnergy: 'Thinai பயன்படுத்திய ஆற்றல்',
    footprintCo2: 'வெளியான கார்பன்',
    phoneCharge: (p) => 'ஒரு கைபேசி சார்ஜின் சுமார் $p%',
    method:
        'இணைப்பில்லாதபோது மின்கலத்திலிருந்து மின்சக்தி அளக்கப்படுகிறது; '
        'இல்லையெனில் CPU சுமையிலிருந்து மதிப்பிடப்படுகிறது. CO₂ இந்திய மின்வலை '
        'சராசரியான ஒரு kWh க்கு 716 g ஐப் பயன்படுத்துகிறது.',
    idle: 'ஓய்வில்',
  );
}
