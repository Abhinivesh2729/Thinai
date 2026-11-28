import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/catalog.dart';
import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/downloader.dart';
import 'package:local_llm/models_repo/recommender.dart';
import 'package:local_llm/models_repo/use_cases.dart';
import 'package:local_llm/ui/widgets/model_advisor.dart';

DeviceProfile phone(double gb, {int cores = 8}) {
  final total = (gb * 1024 * 1024 * 1024).round();
  return DeviceProfile(
    totalRamBytes: total,
    availableRamBytes: (total * 0.6).round(),
    cores: cores,
  );
}

Future<void> pumpAdvisor(
  WidgetTester tester, {
  DeviceProfile? device,
  Set<String> installed = const {},
  void Function(CatalogModel)? onDownload,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ModelAdvisor(
            speed: SpeedKnowledge(device: device ?? phone(8)),
            installedCatalogIds: installed,
            onDownload: onDownload ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('asks the question before showing any model', (tester) async {
    await pumpAdvisor(tester);

    expect(find.text('What do you want to do?'), findsOneWidget);
    expect(find.text('Fast chat'), findsOneWidget);
    expect(find.text('Tamil'), findsOneWidget);
    // Nothing is recommended until the user says what they want.
    expect(find.text('Top pick'), findsNothing);
  });

  testWidgets('shows the phone it is recommending for', (tester) async {
    await pumpAdvisor(tester, device: phone(8));
    expect(find.textContaining('8.0 GB RAM'), findsOneWidget);
  });

  testWidgets('picking a job produces a named model with its numbers', (
    tester,
  ) async {
    await pumpAdvisor(tester);
    await tester.tap(find.text('Fast chat'));
    await tester.pump();

    expect(find.text('Top pick'), findsOneWidget);
    expect(find.textContaining('tok/s'), findsWidgets);
    expect(find.textContaining('RAM'), findsWidgets);
    expect(
      find.textContaining('Excellent for quick conversations'),
      findsOneWidget,
    );
    expect(find.textContaining('Download'), findsOneWidget);
  });

  testWidgets('tapping the same job again clears the answer', (tester) async {
    await pumpAdvisor(tester);
    await tester.tap(find.text('Coding'));
    await tester.pump();
    expect(find.text('Top pick'), findsOneWidget);

    await tester.tap(find.text('Coding'));
    await tester.pump();
    expect(find.text('Top pick'), findsNothing);
  });

  testWidgets('image understanding recommends a model that can see', (
    tester,
  ) async {
    await pumpAdvisor(tester, device: phone(12));
    await tester.tap(find.text('Images'));
    await tester.pump();

    expect(find.text('Top pick'), findsOneWidget);
    expect(find.textContaining('Download'), findsOneWidget);
  });

  testWidgets('offers download for a model that is not installed', (
    tester,
  ) async {
    CatalogModel? requested;
    await pumpAdvisor(tester, onDownload: (m) => requested = m);
    await tester.tap(find.text('Coding'));
    await tester.pump();

    await tester.tap(find.textContaining('Download'));
    await tester.pump();
    expect(requested, isNotNull);
  });

  testWidgets('says so rather than offering a second download', (tester) async {
    // Whatever it would recommend for coding, pretend that one is installed.
    final device = phone(8);
    final wouldPick = recommend(UseCase.coding, device).best!.model;

    await pumpAdvisor(tester, device: device, installed: {wouldPick.id});
    await tester.tap(find.text('Coding'));
    await tester.pump();

    expect(find.text('Installed'), findsOneWidget);
    expect(find.textContaining('Download '), findsNothing);
  });

  testWidgets('a phone whose memory cannot be read still gets advice', (
    tester,
  ) async {
    await pumpAdvisor(tester, device: DeviceProfile.unknownProfile);
    await tester.tap(find.text('Reasoning'));
    await tester.pump();

    expect(find.text('Top pick'), findsOneWidget);
    // No speed claim is made when there is nothing to base it on.
    expect(find.textContaining('tok/s'), findsNothing);
  });

  testWidgets('a small phone is warned rather than sold a model that fits', (
    tester,
  ) async {
    await pumpAdvisor(tester, device: phone(3, cores: 4));
    await tester.tap(find.text('Reasoning'));
    await tester.pump();

    // It must still answer, and the fit line must be honest about it.
    expect(find.text('Top pick'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data?.contains('Runs well') == true ||
                w.data?.contains('Tight fit') == true),
      ),
      findsOneWidget,
    );
  });

  collapsedAndDownloadTests();
}

Widget advisorApp({
  bool collapsed = false,
  UseCase? selected,
  ValueChanged<UseCase?>? onUseCaseChanged,
  VoidCallback? onToggleCollapse,
  Set<String> installed = const {},
  Map<String, DownloadHandle> downloads = const {},
  void Function(String)? onCancel,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ModelAdvisor(
          speed: SpeedKnowledge(device: phone(8)),
          installedCatalogIds: installed,
          onDownload: (_) {},
          downloads: downloads,
          onCancel: onCancel,
          selectedUseCase: selected,
          onUseCaseChanged: onUseCaseChanged,
          isCollapsed: collapsed,
          onToggleCollapse: onToggleCollapse,
        ),
      ),
    ),
  );
}

DownloadHandle handleWith(Stream<DownloadProgress> progress) => DownloadHandle(
  url: 'https://example.com/m.gguf',
  destPath: '/tmp/m.gguf',
  cancelToken: CancelToken(),
  progress: progress,
  label: 'm',
);

void collapsedAndDownloadTests() {
  group('collapsed bar', () {
    testWidgets('shows the prompt and expands on tap', (tester) async {
      var toggled = 0;
      await tester.pumpWidget(
        advisorApp(collapsed: true, onToggleCollapse: () => toggled++),
      );

      expect(find.text('What do you want to do?'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await tester.tap(find.text('What do you want to do?'));
      expect(toggled, 1);
    });

    testWidgets('names the chosen goal and clears it through the callback', (
      tester,
    ) async {
      final changes = <UseCase?>[];
      await tester.pumpWidget(
        advisorApp(
          collapsed: true,
          selected: UseCase.coding,
          onUseCaseChanged: changes.add,
        ),
      );

      expect(find.text('Goal: Coding'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(changes, [null]);
    });

    testWidgets('keeps its own goal when collapsed and can clear it', (
      tester,
    ) async {
      await tester.pumpWidget(advisorApp());
      await tester.tap(find.text('Coding'));
      await tester.pump();

      // Same widget, now collapsed: its local choice survives the rebuild.
      await tester.pumpWidget(advisorApp(collapsed: true));
      expect(find.text('Goal: Coding'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(find.text('What do you want to do?'), findsOneWidget);
      expect(find.text('Goal: Coding'), findsNothing);
    });
  });

  testWidgets('a controlled advisor reports the tap and leaves the choice up '
      'to its owner', (tester) async {
    final changes = <UseCase?>[];
    await tester.pumpWidget(advisorApp(onUseCaseChanged: changes.add));

    await tester.tap(find.text('Coding'));
    await tester.pump();

    expect(changes, [UseCase.coding]);
    expect(find.text('Top pick'), findsNothing);
  });

  group('download in progress', () {
    final wouldPick = recommend(UseCase.coding, phone(8)).best!.model;

    testWidgets('shows a percentage and cancels on tap', (tester) async {
      final ctrl = StreamController<DownloadProgress>();
      addTearDown(ctrl.close);
      final cancelled = <String>[];

      await tester.pumpWidget(
        advisorApp(
          selected: UseCase.coding,
          downloads: {wouldPick.id: handleWith(ctrl.stream)},
          onCancel: cancelled.add,
        ),
      );
      expect(find.text('Starting…'), findsOneWidget);

      ctrl.add(const DownloadProgress(received: 25, total: 100, done: false));
      await tester.pump();
      expect(find.text('25%'), findsOneWidget);

      await tester.tap(find.text('25%'));
      expect(cancelled, [wouldPick.id]);
    });

    testWidgets('stays on "Starting…" while the size is unknown', (
      tester,
    ) async {
      final ctrl = StreamController<DownloadProgress>();
      addTearDown(ctrl.close);

      await tester.pumpWidget(
        advisorApp(
          selected: UseCase.coding,
          downloads: {wouldPick.id: handleWith(ctrl.stream)},
        ),
      );
      ctrl.add(const DownloadProgress(received: 10, total: null, done: false));
      await tester.pump();

      expect(find.text('Starting…'), findsOneWidget);
    });
  });
}
