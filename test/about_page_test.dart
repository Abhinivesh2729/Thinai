import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/about_page.dart';
import 'package:local_llm/ui/pages/contact_support_page.dart';

Future<void> _pump(
  WidgetTester tester, {
  Future<String> Function()? version,
  Brightness brightness = Brightness.light,
}) async {
  final container = ProviderContainer(
    overrides: [
      appVersionProvider.overrideWith(
        (ref) => version?.call() ?? Future.value('2.4.0 (13)'),
      ),
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
        theme: ThemeData(brightness: brightness),
        home: const AboutPage(),
      ),
    ),
  );
  await tester.pump();
}

Image _logo(WidgetTester tester) => tester.widget<Image>(find.byType(Image));

String _assetName(Image image) => (image.image as AssetImage).assetName;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the running version in the header', (tester) async {
    await _pump(tester);
    expect(find.text('v2.4.0 (13) · On-Device Sovereign AI'), findsOneWidget);
  });

  testWidgets('falls back to 1.0.0 while the version is unknown', (
    tester,
  ) async {
    await _pump(tester, version: () => Future.error('no platform'));
    expect(find.text('v1.0.0 · On-Device Sovereign AI'), findsOneWidget);
  });

  testWidgets('lists the pillars and the technical specs', (tester) async {
    await _pump(tester);

    for (final pillar in [
      '100% Private & Sovereign',
      'Hardware Accelerated',
      'Local OpenAI-Compatible API',
      'Multimodal Vision & Web',
    ]) {
      await tester.scrollUntilVisible(find.text(pillar), 200);
      expect(find.text(pillar), findsOneWidget);
    }

    await tester.scrollUntilVisible(find.text('Software License'), 200);
    for (final (label, value) in [
      ('Inference Engine', 'llama.cpp C++20 FFI'),
      ('Model Format', 'GGUF (Q4_K_M, Q8_0, BF16)'),
      ('Acceleration Backends', 'CPU, Vulkan, OpenCL'),
      ('Software License', 'Open Source (MIT)'),
    ]) {
      expect(find.text(label), findsOneWidget);
      expect(find.text(value), findsOneWidget);
    }
  });

  testWidgets('uses the light logo in light theme', (tester) async {
    await _pump(tester);
    expect(_assetName(_logo(tester)), 'assets/images/logo_transparent.png');
  });

  testWidgets('uses the dark logo in dark theme', (tester) async {
    await _pump(tester, brightness: Brightness.dark);
    expect(_assetName(_logo(tester)), 'assets/images/logo_dark.png');
  });

  testWidgets('Licenses opens the license page for Thinai', (tester) async {
    await _pump(tester);

    await tester.scrollUntilVisible(find.text('Licenses'), 200);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Licenses'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
    final page = tester.widget<LicensePage>(find.byType(LicensePage));
    expect(page.applicationName, 'Thinai');
    expect(page.applicationVersion, 'v2.4.0 (13)');
  });

  testWidgets('Contact Support opens the support page', (tester) async {
    await _pump(tester);

    await tester.scrollUntilVisible(find.text('Contact Support'), 200);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contact Support'));
    await tester.pumpAndSettle();

    expect(find.byType(ContactSupportPage), findsOneWidget);
  });
}
