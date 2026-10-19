import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/server/api_server.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/contact_support_page.dart';

const _gib = 1024 * 1024 * 1024;
const _urlChannel = MethodChannel('plugins.flutter.io/url_launcher');

/// Reports a server already running without binding a socket.
class _RunningServer extends ServerController {
  _RunningServer() : super(ApiServer()) {
    state = const ServerStatus(running: true, port: 11434);
  }
}

/// Captures what the page puts on the clipboard.
List<String> _captureClipboard() {
  final copied = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return copied;
}

/// Stands in for the platform's URL opener so no browser is launched.
List<String> _mockUrlLauncher({bool opens = true, bool throws = false}) {
  final opened = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_urlChannel, (call) async {
        if (call.method != 'launch') return null;
        if (throws) throw PlatformException(code: 'NO_ACTIVITY');
        opened.add((call.arguments as Map)['url'] as String);
        return opens;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlChannel, null),
  );
  return opened;
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  DeviceProfile? device = const DeviceProfile(
    cores: 8,
    totalRamBytes: 8 * _gib,
  ),
  List<Override> overrides = const [],
}) async {
  final container = ProviderContainer(
    overrides: [
      appVersionProvider.overrideWith((ref) async => '2.4.0 (13)'),
      deviceProfileProvider.overrideWith(
        (ref) => device == null
            ? Future<DeviceProfile>.error('no profile')
            : Future.value(device),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ContactSupportPage()),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

Future<void> _tapScrolled(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the support channel and the device diagnostics', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('How can we help?'), findsOneWidget);
    expect(find.text('Instagram Support'), findsOneWidget);
    expect(find.text('@27_ai_27'), findsOneWidget);
    expect(find.text('Thinai v2.4.0 (13)'), findsOneWidget);
    expect(find.text('8 CPU Cores'), findsOneWidget);
    expect(find.text('8.0 GB RAM'), findsOneWidget);
    expect(find.text('Tier: FLAGSHIP'), findsOneWidget);
    expect(find.text('No active model'), findsOneWidget);
    expect(find.text('Server: Stopped'), findsOneWidget);
  });

  testWidgets('names the loaded model and a running server', (tester) async {
    final container = await _pump(
      tester,
      overrides: [
        serverControllerProvider.overrideWith((ref) => _RunningServer()),
      ],
    );
    await container
        .read(activeModelIdProvider.notifier)
        .set(
          LocalModel(
            id: 'qwen-test',
            displayName: 'Qwen',
            path: '/nowhere/qwen.gguf',
            sizeBytes: 1,
            modifiedAt: DateTime(2026),
          ),
        );
    await tester.pump();

    expect(find.text('Model: qwen-test'), findsOneWidget);
    expect(find.text('Server: Active'), findsOneWidget);
  });

  testWidgets('leaves out RAM when the phone did not report it', (
    tester,
  ) async {
    await _pump(tester, device: const DeviceProfile(cores: 4));

    expect(find.text('4 CPU Cores'), findsOneWidget);
    expect(find.textContaining('GB RAM'), findsNothing);
    expect(find.text('Tier: UNKNOWN'), findsOneWidget);
  });

  testWidgets('shows only the version when the device could not be read', (
    tester,
  ) async {
    await _pump(tester, device: null);

    expect(find.textContaining('CPU Cores'), findsNothing);
    expect(find.textContaining('Tier:'), findsNothing);
    expect(find.text('Thinai v2.4.0 (13)'), findsOneWidget);
  });

  testWidgets('copies a diagnostics report to the clipboard', (tester) async {
    final copied = _captureClipboard();
    await _pump(tester);

    await _tapScrolled(tester, find.text('Copy Diagnostic Specs'));

    expect(copied, hasLength(1));
    expect(
      copied.single.split('\n'),
      containsAllInOrder([
        'Thinai Diagnostics Report:',
        '• App Version: v2.4.0 (13)',
        '• CPU Cores: 8',
        '• Total RAM: 8.0 GB',
        '• Hardware Tier: FLAGSHIP',
        '• Active Model: None',
        '• Local API Server: Stopped',
      ]),
    );
    expect(find.text('System diagnostics copied to clipboard'), findsOneWidget);
  });

  testWidgets('the report says Unknown for what could not be read', (
    tester,
  ) async {
    final copied = _captureClipboard();
    await _pump(tester, device: null);

    await _tapScrolled(tester, find.text('Copy Diagnostic Specs'));

    expect(copied.single, contains('• CPU Cores: Unknown'));
    expect(copied.single, contains('• Total RAM: Unknown'));
    expect(copied.single, contains('• Hardware Tier: Unknown'));
  });

  testWidgets('copies the Instagram handle', (tester) async {
    final copied = _captureClipboard();
    await _pump(tester);

    await tester.tap(find.byTooltip('Copy Instagram handle'));
    await tester.pump();

    expect(copied, ['@27_ai_27']);
    expect(find.text('Instagram handle copied to clipboard'), findsOneWidget);
  });

  testWidgets('Open Instagram hands the profile link to the platform', (
    tester,
  ) async {
    final opened = _mockUrlLauncher();
    await _pump(tester);

    await tester.tap(find.text('Open Instagram'));
    await tester.pump();
    await tester.pump();

    expect(opened, ['https://www.instagram.com/27_ai_27/']);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('says so when Instagram cannot be opened', (tester) async {
    _mockUrlLauncher(opens: false);
    await _pump(tester);

    await tester.tap(find.text('Open Instagram'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Unable to open Instagram link'), findsOneWidget);
  });

  testWidgets('reports an error from the platform link opener', (tester) async {
    _mockUrlLauncher(throws: true);
    await _pump(tester);

    await tester.tap(find.text('Open Instagram'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Failed to open link:'), findsOneWidget);
  });

  testWidgets('renders in dark theme too', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appVersionProvider.overrideWith((ref) async => '2.4.0 (13)'),
        deviceProfileProvider.overrideWith(
          (ref) async => const DeviceProfile(cores: 8),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const ContactSupportPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Contact Support'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
