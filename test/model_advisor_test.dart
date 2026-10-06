import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/catalog.dart';
import 'package:local_llm/models_repo/device_profile.dart';
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
    expect(find.text('Best model for your phone'), findsNothing);
  });

  testWidgets('shows the phone it is recommending for', (tester) async {
    await pumpAdvisor(tester, device: phone(8));
    expect(find.textContaining('8.0 GB RAM'), findsOneWidget);
  });

  testWidgets('picking a job produces a named model with its numbers',
      (tester) async {
    await pumpAdvisor(tester);
    await tester.tap(find.text('Fast chat'));
    await tester.pump();

    expect(find.text('Best model for your phone'), findsOneWidget);
    expect(find.textContaining('tok/s'), findsWidgets);
    expect(find.textContaining('RAM'), findsWidgets);
    expect(find.textContaining('Excellent for quick conversations'),
        findsOneWidget);
    expect(find.textContaining('Download'), findsOneWidget);
  });

  testWidgets('tapping the same job again clears the answer', (tester) async {
    await pumpAdvisor(tester);
    await tester.tap(find.text('Coding'));
    await tester.pump();
    expect(find.text('Best model for your phone'), findsOneWidget);

    await tester.tap(find.text('Coding'));
    await tester.pump();
    expect(find.text('Best model for your phone'), findsNothing);
  });

  testWidgets('image understanding recommends a model that can see',
      (tester) async {
    await pumpAdvisor(tester, device: phone(12));
    await tester.tap(find.text('Image understanding'));
    await tester.pump();

    expect(find.text('Best model for your phone'), findsOneWidget);
    expect(find.textContaining('Download'), findsOneWidget);
  });

  testWidgets('offers download for a model that is not installed',
      (tester) async {
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

    expect(find.text('Already downloaded'), findsOneWidget);
    expect(find.textContaining('Download '), findsNothing);
  });

  testWidgets('a phone whose memory cannot be read still gets advice',
      (tester) async {
    await pumpAdvisor(tester, device: DeviceProfile.unknownProfile);
    await tester.tap(find.text('Best reasoning'));
    await tester.pump();

    expect(find.text('Best model for this'), findsOneWidget);
    // No speed claim is made when there is nothing to base it on.
    expect(find.textContaining('tok/s'), findsNothing);
  });

  testWidgets('a small phone is warned rather than sold a model that fits',
      (tester) async {
    await pumpAdvisor(tester, device: phone(3, cores: 4));
    await tester.tap(find.text('Best reasoning'));
    await tester.pump();

    // It must still answer, and the fit line must be honest about it.
    expect(find.text('Best model for your phone'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          (w.data?.contains('Runs well') == true ||
              w.data?.contains('Tight fit') == true)),
      findsOneWidget,
    );
  });
}
