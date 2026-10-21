import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/server/api_server.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/server_page.dart';
import 'package:local_llm/ui/pages/settings_page.dart';

/// Reports a server already running on [port] without binding a socket.
class _RunningServer extends ServerController {
  _RunningServer(int port) : super(ApiServer()) {
    state = ServerStatus(running: true, port: port);
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget page, {
  List<Override> overrides = const [],
}) async {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: page),
    ),
  );
  // Let the saved port load.
  await tester.pump();
  await tester.pump();
  return container;
}

Future<void> _enterPort(WidgetTester tester, String port, String save) async {
  await tester.enterText(find.byType(TextField), port);
  await tester.tap(find.text(save));
  await tester.pump();
  await tester.pump();
}

void main() {
  // #41: the port tag kept the old port until the server was started.
  testWidgets('server page shows a newly saved port while stopped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'server_port': 11434});
    final container = await _pump(tester, const ServerPage());
    expect(find.text(':11434'), findsOneWidget);

    await tester.tap(find.text(':11434'));
    await tester.pump();
    await _enterPort(tester, '8005', 'Save');

    expect(find.text(':8005'), findsOneWidget);
    expect(find.text(':11434'), findsNothing);
    expect(await container.read(savedServerPortProvider.future), 8005);
  });

  testWidgets('server page follows a port changed in settings', (tester) async {
    SharedPreferences.setMockInitialValues({'server_port': 11434});
    final container = await _pump(tester, const ServerPage());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('server_port', 9000);
    container.invalidate(savedServerPortProvider);
    // The settings page watching it is what reloads it in the app.
    await container.read(savedServerPortProvider.future);
    await tester.pump();

    expect(find.text(':9000'), findsOneWidget);
  });

  testWidgets('settings asks for a restart when the server is running', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'server_port': 11434});
    await _pump(
      tester,
      const LocalServerSettingsPage(),
      overrides: [
        serverControllerProvider.overrideWith((ref) => _RunningServer(11434)),
      ],
    );

    await tester.tap(find.text('Port'));
    await tester.pump();
    await tester.pump();
    await _enterPort(tester, '8005', 'Save');

    expect(
      find.text('Port set to 8005. Restart the server to apply.'),
      findsOneWidget,
    );
  });

  testWidgets('settings needs no restart while the server is stopped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'server_port': 11434});
    await _pump(tester, const LocalServerSettingsPage());

    await tester.tap(find.text('Port'));
    await tester.pump();
    await tester.pump();
    await _enterPort(tester, '8005', 'Save');

    expect(find.text('Port set to 8005'), findsOneWidget);
  });
}
