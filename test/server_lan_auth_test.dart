import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/server/api_server.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/server_page.dart';

const _token = 'D5HTu_mwQtLAN-test-token-0123456789abcdef94s=';
const _masked = 'D5HT••••••94s=';

/// A server controller whose status a test sets directly, without a socket.
class _FakeServer extends ServerController {
  _FakeServer({bool running = false, bool lan = false}) : super(ApiServer()) {
    state = ServerStatus(
      running: running,
      port: 11434,
      lan: lan,
      lanIp: lan ? '192.168.1.33' : null,
    );
  }
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ServerPage()),
    ),
  );
  await tester.pump();
  await tester.pump();
  // The tunnel and token cards push Quick start below the fold of a lazy
  // ListView; bring the snippet into view so it is built.
  await tester.scrollUntilVisible(
    find.text('config.json'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
}

/// Opens a Quick start tab, scrolling it clear of the app bar first.
Future<void> _tab(WidgetTester tester, String name) async {
  await tester.scrollUntilVisible(
    find.text('Quick start'),
    -100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text(name));
}

/// Records what the app puts on the clipboard.
List<String> _captureClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

void main() {
  // #86: on a fresh install the token is only created by the first LAN start,
  // after the Server page has built; the snippets must pick it up then.
  testWidgets('snippets pick up the token a LAN start creates', (tester) async {
    SharedPreferences.setMockInitialValues({'server_lan_share': true});
    final container = ProviderContainer(
      overrides: [
        serverControllerProvider.overrideWith(
          (ref) => _FakeServer(running: true, lan: true),
        ),
        deviceLanIpProvider.overrideWith((ref) async => '192.168.1.33'),
      ],
    );
    addTearDown(container.dispose);
    await _pump(tester, container);
    expect(container.read(apiTokensProvider), isEmpty);

    await tester.runAsync(
      () => container.read(apiTokensProvider.notifier).ensureOne(),
    );
    await tester.pump();

    final token = container.read(apiTokensProvider).single.token;
    final masked =
        '${token.substring(0, 4)}••••••${token.substring(token.length - 4)}';
    expect(
      find.textContaining('"apiKey": "$masked"', findRichText: true),
      findsOneWidget,
    );
  });

  group('LAN snippets', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'server_lan_share': true,
        'server_bearer_token': _token,
      });
      container = ProviderContainer(
        overrides: [
          serverControllerProvider.overrideWith(
            (ref) => _FakeServer(running: true, lan: true),
          ),
          deviceLanIpProvider.overrideWith((ref) async => '192.168.1.33'),
        ],
      );
      addTearDown(container.dispose);
    });

    testWidgets('show the token masked and copy it in full', (tester) async {
      final copied = _captureClipboard(tester);
      await _pump(tester, container);

      // VS Code tab, the default.
      expect(
        find.textContaining('"apiKey": "$_masked"', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('"thinai"', findRichText: true), findsNothing);

      await _tab(tester, 'Python');
      await tester.pump();
      expect(
        find.textContaining('api_key="$_masked"', findRichText: true),
        findsOneWidget,
      );

      await _tab(tester, 'cURL');
      await tester.pump();
      expect(
        find.textContaining(
          'Authorization: Bearer $_masked',
          findRichText: true,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Copy').first);
      await tester.pump();
      expect(copied.last, contains('-H "Authorization: Bearer $_token"'));
      expect(copied.last, isNot(contains('•')));

      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('endpoint cURL copy carries the real token', (tester) async {
      final copied = _captureClipboard(tester);
      await _pump(tester, container);

      // The endpoint list sits below the fold of a lazy ListView.
      await tester.scrollUntilVisible(
        find.text('/v1/models'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Copy cURL').first);
      await tester.pump();
      expect(copied.last, contains('-H "Authorization: Bearer $_token" \\'));

      await tester.tap(find.byTooltip('Copy cURL').last);
      await tester.pump();

      expect(
        copied.last,
        startsWith('curl http://192.168.1.33:11434/v1/models'),
      );
      expect(copied.last, contains('Authorization: Bearer $_token'));
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('the Ollama tab warns that OLLAMA_HOST alone cannot auth', (
      tester,
    ) async {
      await _pump(tester, container);
      await _tab(tester, 'Ollama');
      await tester.pump();
      expect(
        find.textContaining('ollama CLI cannot send it', findRichText: true),
        findsOneWidget,
      );
    });
  });

  testWidgets('loopback snippets keep the placeholder key and no auth header', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'server_bearer_token': _token});
    final container = ProviderContainer(
      overrides: [
        serverControllerProvider.overrideWith(
          (ref) => _FakeServer(running: true),
        ),
        deviceLanIpProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);
    final copied = _captureClipboard(tester);
    await _pump(tester, container);

    expect(
      find.textContaining('"apiKey": "thinai"', findRichText: true),
      findsOneWidget,
    );
    await _tab(tester, 'cURL');
    await tester.pump();
    await tester.tap(find.text('Copy').first);
    await tester.pump();
    expect(copied.last, isNot(contains('Authorization')));
    await tester.pump(const Duration(seconds: 2));

    await _tab(tester, 'Ollama');
    await tester.pump();
    expect(
      find.textContaining('export OLLAMA_HOST=', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Bearer', findRichText: true), findsNothing);
  });
}
