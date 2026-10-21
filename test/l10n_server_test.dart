import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/l10n/l10n.dart';
import 'package:local_llm/models_repo/hf_hub.dart';
import 'package:local_llm/server/api_server.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/models_page.dart';
import 'package:local_llm/ui/pages/server_page.dart';

import 'helpers/fonts.dart';

/// Reports a server already running on [port] without binding a socket.
class _RunningServer extends ServerController {
  _RunningServer(int port) : super(ApiServer()) {
    state = ServerStatus(running: true, port: port);
  }
}

/// Answers every Hub request with [body].
class _FakeHub implements HttpClientAdapter {
  _FakeHub(this.body);

  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

final _searchReply = [
  {
    'id': 'unsloth/Qwen3-1.7B-GGUF',
    'gated': false,
    'private': false,
    'downloads': 1200000,
    'likes': 340,
    'lastModified': DateTime.now()
        .subtract(const Duration(days: 3))
        .toUtc()
        .toIso8601String(),
    'pipeline_tag': 'text-generation',
  },
];

Widget _tamil(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('ta'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

/// A phone-width screen tall enough to build the whole server page.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(412 * 3, 3200 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(loadRoboto);

  group('Server page in Tamil', () {
    testWidgets('renders Tamil copy while stopped', (tester) async {
      _phone(tester);
      SharedPreferences.setMockInitialValues({'server_port': 11434});
      await tester.pumpWidget(_tamil(const ServerPage()));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('சேவகம்'), findsOneWidget);
      expect(find.text('நிறுத்தப்பட்டது'), findsOneWidget);
      expect(find.text('தொடங்கு'), findsOneWidget);
      expect(find.text('உள்ளூர் நெட்வொர்க்கில் பகிர் (LAN)'), findsOneWidget);
      expect(find.text('டெவலப்பர் விரைவுத் தொடக்கம்'), findsOneWidget);
      expect(find.text('API endpoints'), findsOneWidget);
      expect(find.text('நிறுவப்பட்ட அறிவுருக்களின் பட்டியல்'), findsOneWidget);
      expect(
        find.textContaining('இந்தச் சாதனத்தில் இயங்கும் ஆப்ஸ் மட்டுமே'),
        findsOneWidget,
      );
      // Code samples and endpoint paths stay as they are.
      expect(find.text('/v1/chat/completions'), findsOneWidget);
      expect(find.text('Running'), findsNothing);
      expect(find.text('Developer Quick Start'), findsNothing);
    });

    testWidgets('renders Tamil copy while running', (tester) async {
      _phone(tester);
      SharedPreferences.setMockInitialValues({'server_port': 11434});
      await tester.pumpWidget(
        _tamil(
          const ServerPage(),
          overrides: [
            serverControllerProvider.overrideWith(
              (ref) => _RunningServer(11434),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('இயங்குகிறது'), findsOneWidget);
      expect(find.text('நிறுத்து'), findsOneWidget);
    });

    testWidgets('port dialog is in Tamil', (tester) async {
      _phone(tester);
      SharedPreferences.setMockInitialValues({'server_port': 11434});
      await tester.pumpWidget(_tamil(const ServerPage()));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text(':11434'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('சேவகம் port-ஐ மாற்று'), findsOneWidget);
      expect(find.text('Port-ஐச் சேமி'), findsOneWidget);
      expect(find.text('ரத்துசெய்'), findsOneWidget);
    });
  });

  group('Hugging Face search in Tamil', () {
    List<Override> hub() => [
      hfHubProvider.overrideWithValue(
        HfHub(dio: Dio()..httpClientAdapter = _FakeHub(_searchReply)),
      ),
    ];

    testWidgets('empty state and network notice', (tester) async {
      await tester.pumpWidget(_tamil(const HfSearchPage(), overrides: hub()));

      expect(tester.takeException(), isNull);
      expect(find.text('எந்த GGUF அறிவுருவையும் தேடலாம்'), findsOneWidget);
      expect(find.textContaining('தேடலுக்கு இணையம் தேவை'), findsOneWidget);
      expect(find.text('Find any GGUF model'), findsNothing);
    });

    testWidgets('results list', (tester) async {
      await tester.pumpWidget(
        _tamil(const HfSearchPage(initialQuery: 'qwen'), overrides: hub()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('முடிவுகள் (1)'), findsOneWidget);
      expect(find.text('அதிகம் பதிவிறக்கப்பட்டவை முதலில்'), findsOneWidget);
      expect(find.text('3 நாட்களுக்கு முன்'), findsOneWidget);
      expect(find.text('Qwen3-1.7B-GGUF'), findsOneWidget);
    });
  });
}
