import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/llm/generation_settings.dart';
import 'package:local_llm/llm/gpu_support.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/widgets/gpu_settings_card.dart';

const _checkLabel = 'Find GPU';

Future<void> _pump(
  WidgetTester tester, {
  bool embedded = false,
  GpuBackend? crashed,
}) async {
  final container = ProviderContainer(
    overrides: [gpuCrashNoticeProvider.overrideWith((ref) => crashed)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GpuSettingsCard(embedded: embedded),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _setGpu(WidgetTester tester, GpuBackend gpu) async {
  // The store was first loaded outside the fake clock, so its writes finish
  // on the real event loop.
  await tester.runAsync(() => GenerationSettingsStore.instance.setGpu(gpu));
}

// The device probe itself is not exercised: it loads the native library on
// another isolate, which never completes under the test host.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GenerationSettingsStore.instance.setGpu(GpuBackend.none);
  });

  testWidgets('starts off, explained, and waits to be asked to probe', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('GPU acceleration'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(find.textContaining('Run the speed test'), findsOneWidget);
    expect(find.text(_checkLabel), findsOneWidget);
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'no driver is touched until the user asks',
    );
  });

  testWidgets('sits in a card unless embedded', (tester) async {
    await _pump(tester);
    expect(find.byType(Card), findsOneWidget);

    await _pump(tester, embedded: true);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('says which backend crashed the app last time', (tester) async {
    await _pump(tester, crashed: GpuBackend.vulkan);
    expect(
      find.text('Vulkan crashed last time, so the GPU was turned off.'),
      findsOneWidget,
    );
  });

  testWidgets('follows a GPU choice made elsewhere', (tester) async {
    await _pump(tester);
    expect(find.text('Off'), findsOneWidget);

    await _setGpu(tester, GpuBackend.opencl);
    await tester.pump();
    await tester.pump();

    expect(find.text('OpenCL'), findsOneWidget);
    expect(find.text('Off'), findsNothing);
  });
}
