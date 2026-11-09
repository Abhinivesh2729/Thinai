/// Desktop Server page text, English and Tamil.
///
/// Phone strings that read right on a PC come from `context.l10n`; this file
/// holds the rest, mostly where the phone copy says "phone" or mentions the
/// public tunnel, which the desktop build does not have. Tamil follows
/// docs/TAMIL_GLOSSARY.md: server சேவகம், PC கணினி, and API, URL, LAN,
/// token, port, endpoint paths stay in English. No em dashes.
library;

import 'package:flutter/widgets.dart';

import 'desk_l10n.dart';

class ServerStrings {
  const ServerStrings._({
    required this.pageSubtitle,
    required this.runningLocal,
    required this.runningLan,
    required this.stoppedHint,
    required this.starting,
    required this.stopping,
    required this.port,
    required this.changePort,
    required this.serving,
    required this.servingHint,
    required this.portHelp,
    required this.presetDefault,
    required this.presetOllama,
    required this.ollamaClash,
    required this.portInvalid,
    required this.portInUse,
    required this.portBlocked,
    required this.portSameAsRunning,
    required this.noNetworkAddress,
    required this.connectTitle,
    required this.connectSubtitle,
    required this.openAiBaseUrl,
    required this.ollamaUrl,
    required this.apiKey,
    required this.apiKeyNotNeeded,
    required this.apiKeyToken,
    required this.fromThisPc,
    required this.fromOtherDevices,
    required this.noLanAddressShort,
    required this.endpointsSubtitle,
    required this.tabCurl,
    required this.tabRequest,
    required this.tabResponse,
    required this.noRequestBody,
    required this.alsoAvailable,
    required this.epTags,
    required this.epPs,
    required this.epShow,
    required this.epGenerate,
    required this.epEmbed,
    required this.epEmbeddingsLegacy,
    required this.copyUrl,
    required this.lanOn,
    required this.lanOff,
    required this.lanUrl,
    required this.lanStartHint,
    required this.lanNoAddress,
    required this.lanRestarts,
    required this.firewallNote,
    required this.tokensSubtitle,
    required this.tokenShow,
    required this.tokenHide,
    required this.tokenCreated,
    required this.tokenDeleted,
  });

  final String pageSubtitle;
  final String runningLocal, runningLan, stoppedHint, starting, stopping;
  final String port, changePort, serving, servingHint;
  final String portHelp, presetDefault, presetOllama, ollamaClash;
  final String portInvalid;
  final String Function(int port) portInUse, portBlocked;
  final String portSameAsRunning;
  final String noNetworkAddress;
  final String connectTitle, connectSubtitle, openAiBaseUrl, ollamaUrl;
  final String apiKey, apiKeyNotNeeded, apiKeyToken;
  final String fromThisPc, fromOtherDevices, noLanAddressShort;
  final String endpointsSubtitle, tabCurl, tabRequest, tabResponse;
  final String noRequestBody, alsoAvailable;
  final String epTags, epPs, epShow, epGenerate, epEmbed, epEmbeddingsLegacy;
  final String copyUrl;
  final String lanOn, lanOff, lanUrl, lanStartHint, lanNoAddress, lanRestarts;
  final String firewallNote;
  final String tokensSubtitle, tokenShow, tokenHide;
  final String Function(String name) tokenCreated, tokenDeleted;

  static ServerStrings of(BuildContext context) => deskPick(context, en, ta);

  static final en = ServerStrings._(
    pageSubtitle: 'An OpenAI and Ollama compatible API, served from this PC.',
    runningLocal: 'Apps on this PC can connect.',
    runningLan: 'Apps on this PC and devices on your network can connect.',
    stoppedHint: 'Start the server to use your models from other apps.',
    starting: 'Starting',
    stopping: 'Stopping',
    port: 'Port',
    changePort: 'Change port',
    serving: 'Serving',
    servingHint: 'Requests can name any installed model by its id.',
    portHelp:
        'Clients connect on this port. A running server moves to it right '
        'away.',
    presetDefault: 'Thinai default',
    presetOllama: 'Ollama compatible',
    ollamaClash: 'If Ollama is running on this PC, it already uses 11434.',
    portInvalid: 'Enter a port from 1 to 65535.',
    portInUse: (p) =>
        'Port $p is already in use by another app. Pick another port, or '
        'close that app.',
    portBlocked: (p) =>
        'Port $p is blocked on this PC. Windows reserves some ports; pick '
        'another one.',
    portSameAsRunning: 'The server is already on this port.',
    noNetworkAddress:
        'LAN sharing is on, but this PC has no network address. Connect to '
        'Wi-Fi or Ethernet.',
    connectTitle: 'Connect',
    connectSubtitle: 'Point any OpenAI or Ollama client at these addresses.',
    openAiBaseUrl: 'OpenAI base URL',
    ollamaUrl: 'Ollama URL',
    apiKey: 'API key',
    apiKeyNotNeeded: 'Not needed on this PC. Use any text if a client asks.',
    apiKeyToken: 'Required while LAN sharing is on. Uses your first token.',
    fromThisPc: 'From this PC',
    fromOtherDevices: 'From other devices',
    noLanAddressShort: 'No network address',
    endpointsSubtitle:
        'OpenAI and Ollama compatible. Replies are generated one request at '
        'a time.',
    tabCurl: 'cURL',
    tabRequest: 'Request',
    tabResponse: 'Response',
    noRequestBody: 'No request body.',
    alsoAvailable: 'Also available',
    epTags: 'Installed models (Ollama)',
    epPs: 'Loaded model',
    epShow: 'Model details',
    epGenerate: 'Text generation (Ollama)',
    epEmbed: 'Embeddings (Ollama)',
    epEmbeddingsLegacy: 'Embeddings, legacy (Ollama)',
    copyUrl: 'Copy URL',
    lanOn: 'Devices on your network can connect with a token.',
    lanOff: 'Only apps on this PC can connect.',
    lanUrl: 'LAN URL',
    lanStartHint: 'Start the server to share it on your network.',
    lanNoAddress:
        'No network address found. Connect this PC to Wi-Fi or Ethernet.',
    lanRestarts: 'Switching this restarts a running server.',
    firewallNote:
        'Windows may ask to let Thinai through the firewall the first time '
        'LAN sharing starts. Allow it on private networks so other devices '
        'can connect.',
    tokensSubtitle:
        'Other devices send one as Authorization: Bearer <token>. Deleting a '
        'token locks its client out at once.',
    tokenShow: 'Show token',
    tokenHide: 'Hide token',
    tokenCreated: (n) => 'Token "$n" created',
    tokenDeleted: (n) => 'Token "$n" deleted',
  );

  static final ta = ServerStrings._(
    pageSubtitle:
        'OpenAI, Ollama உடன் இணக்கமான API, இந்தக் கணினியிலிருந்து இயங்குகிறது.',
    runningLocal: 'இந்தக் கணினியில் உள்ள செயலிகள் இணையலாம்.',
    runningLan:
        'இந்தக் கணினியின் செயலிகளும் உங்கள் நெட்வொர்க்கில் உள்ள சாதனங்களும் '
        'இணையலாம்.',
    stoppedHint:
        'பிற செயலிகளிலிருந்து உங்கள் அறிவுருக்களைப் பயன்படுத்த சேவகத்தைத் '
        'தொடங்குங்கள்.',
    starting: 'தொடங்குகிறது',
    stopping: 'நிறுத்துகிறது',
    port: 'Port',
    changePort: 'Port-ஐ மாற்று',
    serving: 'இயங்கும் அறிவுரு',
    servingHint:
        'கோரிக்கைகள் நிறுவிய எந்த அறிவுருவையும் அதன் id மூலம் குறிப்பிடலாம்.',
    portHelp:
        'Clients இந்த port-இல் இணையும். இயங்கும் சேவகம் உடனே இதற்கு மாறும்.',
    presetDefault: 'Thinai இயல்பு',
    presetOllama: 'Ollama இணக்கம்',
    ollamaClash:
        'இந்தக் கணினியில் Ollama இயங்கினால், அது ஏற்கனவே 11434-ஐப் '
        'பயன்படுத்தும்.',
    portInvalid: '1 முதல் 65535 வரையிலான port-ஐ உள்ளிடுங்கள்.',
    portInUse: (p) =>
        'Port $p-ஐ வேறொரு செயலி ஏற்கனவே பயன்படுத்துகிறது. வேறு port-ஐத் '
        'தேர்ந்தெடுங்கள், அல்லது அந்தச் செயலியை மூடுங்கள்.',
    portBlocked: (p) =>
        'இந்தக் கணினியில் port $p தடுக்கப்பட்டுள்ளது. Windows சில port-களை '
        'ஒதுக்கி வைக்கும்; வேறொன்றைத் தேர்ந்தெடுங்கள்.',
    portSameAsRunning: 'சேவகம் ஏற்கனவே இந்த port-இல் இயங்குகிறது.',
    noNetworkAddress:
        'LAN பகிர்வு இயக்கத்தில் உள்ளது, ஆனால் இந்தக் கணினிக்கு நெட்வொர்க் '
        'முகவரி இல்லை. Wi-Fi அல்லது Ethernet-உடன் இணையுங்கள்.',
    connectTitle: 'இணை',
    connectSubtitle:
        'எந்த OpenAI அல்லது Ollama client-ஐயும் இந்த முகவரிகளுக்குச் '
        'சுட்டுங்கள்.',
    openAiBaseUrl: 'OpenAI base URL',
    ollamaUrl: 'Ollama URL',
    apiKey: 'API key',
    apiKeyNotNeeded:
        'இந்தக் கணினியில் தேவையில்லை. Client கேட்டால் எந்த உரையையும் '
        'பயன்படுத்துங்கள்.',
    apiKeyToken:
        'LAN பகிர்வு இயக்கத்தில் இருக்கும்போது தேவை. உங்கள் முதல் token '
        'பயன்படுத்தப்படும்.',
    fromThisPc: 'இந்தக் கணினியிலிருந்து',
    fromOtherDevices: 'பிற சாதனங்களிலிருந்து',
    noLanAddressShort: 'நெட்வொர்க் முகவரி இல்லை',
    endpointsSubtitle:
        'OpenAI, Ollama இணக்கமானது. பதில்கள் ஒரு நேரத்தில் ஒரு கோரிக்கையாக '
        'உருவாகும்.',
    tabCurl: 'cURL',
    tabRequest: 'கோரிக்கை',
    tabResponse: 'பதில்',
    noRequestBody: 'கோரிக்கை உள்ளடக்கம் இல்லை.',
    alsoAvailable: 'மேலும் கிடைப்பவை',
    epTags: 'நிறுவிய அறிவுருக்கள் (Ollama)',
    epPs: 'ஏற்றப்பட்ட அறிவுரு',
    epShow: 'அறிவுரு விவரங்கள்',
    epGenerate: 'உரை உருவாக்கம் (Ollama)',
    epEmbed: 'Embeddings (Ollama)',
    epEmbeddingsLegacy: 'Embeddings, பழையது (Ollama)',
    copyUrl: 'URL-ஐ நகலெடு',
    lanOn: 'உங்கள் நெட்வொர்க்கில் உள்ள சாதனங்கள் token மூலம் இணையலாம்.',
    lanOff: 'இந்தக் கணினியின் செயலிகள் மட்டுமே இணையலாம்.',
    lanUrl: 'LAN URL',
    lanStartHint: 'நெட்வொர்க்கில் பகிர சேவகத்தைத் தொடங்குங்கள்.',
    lanNoAddress:
        'நெட்வொர்க் முகவரி கிடைக்கவில்லை. இந்தக் கணினியை Wi-Fi அல்லது '
        'Ethernet-உடன் இணையுங்கள்.',
    lanRestarts: 'இதை மாற்றினால் இயங்கும் சேவகம் மறுதொடக்கம் ஆகும்.',
    firewallNote:
        'LAN பகிர்வு முதல் முறை தொடங்கும்போது, firewall வழியாக Thinai-ஐ '
        'அனுமதிக்க Windows கேட்கலாம். பிற சாதனங்கள் இணைய, private '
        'நெட்வொர்க்குகளில் அனுமதியுங்கள்.',
    tokensSubtitle:
        'பிற சாதனங்கள் இதை Authorization: Bearer <token> ஆக அனுப்பும். '
        'Token-ஐ நீக்கினால் அதன் client உடனே அணுகலை இழக்கும்.',
    tokenShow: 'Token-ஐக் காட்டு',
    tokenHide: 'Token-ஐ மறை',
    tokenCreated: (n) => '"$n" token உருவாக்கப்பட்டது',
    tokenDeleted: (n) => '"$n" token நீக்கப்பட்டது',
  );
}
