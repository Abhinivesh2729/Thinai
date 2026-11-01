import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/server/api_server.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/server_page.dart';

/// A running server whose tunnel opens instantly on a fixed URL.
class _FakeServer extends ServerController {
  _FakeServer() : super(ApiServer()) {
    state = const ServerStatus(running: true, port: 11434);
  }

  int tunnelStarts = 0;

  @override
  Future<void> startTunnel() async {
    tunnelStarts++;
    state = const ServerStatus(
      running: true,
      port: 11434,
      publicUrl: 'https://calm-river.trycloudflare.com',
    );
  }

  @override
  Future<void> stopTunnel() async {
    state = const ServerStatus(running: true, port: 11434);
  }
}

// The running hero card animates forever, so pumpAndSettle never settles.
void main() {
  testWidgets('tapping the Public URL row, not just the switch, toggles it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'tunnel_privacy_ack': true});
    final server = _FakeServer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [serverControllerProvider.overrideWith((ref) => server)],
        child: const MaterialApp(home: ServerPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final title = find.text('Public URL');
    await tester.ensureVisible(title);
    await tester.tap(title);
    await tester.pump(const Duration(milliseconds: 500));

    expect(server.tunnelStarts, 1);
    expect(find.text('https://calm-river.trycloudflare.com'), findsOneWidget);
    // The examples now point at the public URL instead of loopback.
    expect(
      find.textContaining('calm-river.trycloudflare.com/', findRichText: true),
      findsWidgets,
    );

    await tester.tap(title);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('https://calm-river.trycloudflare.com'), findsNothing);
  });

  testWidgets('the first turn-on warns about Cloudflare and can be cancelled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final server = _FakeServer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [serverControllerProvider.overrideWith((ref) => server)],
        child: const MaterialApp(home: ServerPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final title = find.text('Public URL');
    expect(find.text('Beta'), findsOneWidget);
    await tester.ensureVisible(title);
    await tester.tap(title);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Cloudflare can read them'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(server.tunnelStarts, 0);

    await tester.tap(title);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Turn on'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(server.tunnelStarts, 1);

    // Accepted once, so the next turn-on goes straight through.
    await tester.tap(title);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(title);
    await tester.pump(const Duration(milliseconds: 500));
    expect(server.tunnelStarts, 2);
  });
}
