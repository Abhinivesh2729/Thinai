import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/server/api_server.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/server_page.dart';

/// Reports a server running on the LAN without binding a socket.
class _LanServer extends ServerController {
  _LanServer() : super(ApiServer()) {
    state = const ServerStatus(
      running: true,
      port: 11434,
      lan: true,
      lanIp: '192.168.1.33',
    );
  }
}

const _oldToken = 'old-default-token-0123456789abcdefghijklmnop=';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool tunnelSupported = true,
  bool lanRunning = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      quickTunnelSupportedProvider.overrideWithValue(tunnelSupported),
      deviceLanIpProvider.overrideWith((ref) async => '192.168.1.33'),
      if (lanRunning)
        serverControllerProvider.overrideWith((ref) => _LanServer()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ServerPage()),
    ),
  );
  // The running hero card animates forever, so pumpAndSettle never settles.
  await tester.pump(const Duration(milliseconds: 500));
  return container;
}

void main() {
  testWidgets('Public URL is hidden where cloudflared cannot run', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester, tunnelSupported: false);
    expect(find.text('Public URL'), findsNothing);
    expect(find.text('Share on LAN'), findsOneWidget);
  });

  testWidgets('tapping the Share on LAN row, not just the switch, toggles it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = await _pump(tester);
    expect(container.read(lanShareProvider), isFalse);

    await tester.tap(find.text('Share on LAN'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(lanShareProvider), isTrue);
  });

  testWidgets('deleting the last token while sharing mints a new one', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'server_lan_share': true,
      'server_api_tokens': jsonEncode([
        {
          'id': 'default',
          'name': 'Default',
          'token': _oldToken,
          'createdAt': '2026-11-01T10:00:00.000',
        },
      ]),
    });
    final container = await _pump(tester, lanRunning: true);
    await tester.runAsync(
      () => container.read(apiTokensProvider.notifier).ready,
    );
    await tester.pump();

    final delete = find.byTooltip('Delete');
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final tokens = container.read(apiTokensProvider);
    expect(tokens, hasLength(1));
    expect(tokens.single.token, isNot(_oldToken));
    expect(
      find.text('No tokens yet. One is created when you share.'),
      findsNothing,
    );
  });

  testWidgets('deleting the last token while stopped leaves none', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'server_api_tokens': jsonEncode([
        {
          'id': 'default',
          'name': 'Default',
          'token': _oldToken,
          'createdAt': '2026-11-01T10:00:00.000',
        },
      ]),
    });
    final container = await _pump(tester);
    await tester.runAsync(
      () => container.read(apiTokensProvider.notifier).ready,
    );
    await tester.pump();

    final delete = find.byTooltip('Delete');
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(apiTokensProvider), isEmpty);
  });
}
