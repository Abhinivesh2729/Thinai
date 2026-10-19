import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/use_cases.dart';
import 'package:local_llm/ui/pages/models_page.dart';

import 'helpers/fonts.dart';

/// The Realme RMX3870 is 1080 px wide at 3x: 360 logical pixels, the width
/// the overflow was first seen at. 320 covers the narrowest phones Android
/// still supports.
const _widths = [320.0, 360.0, 411.0];

Future<void> _pumpBar(
  WidgetTester tester, {
  required double width,
  required ModelFilter filter,
  required UseCase? useCase,
}) async {
  tester.view.physicalSize = Size(width * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Roboto'),
      home: Scaffold(
        body: ModelsFilterBar(
          selected: filter,
          selectedUseCase: useCase,
          installedCount: 12,
          hasActiveFilter: true,
          onSelected: (_) {},
          onOpenGoalPicker: () {},
          onClearGoal: () {},
          onResetAll: () {},
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadRoboto);

  for (final width in _widths) {
    testWidgets('fits every goal and filter at ${width.toInt()} dp', (
      tester,
    ) async {
      for (final filter in ModelFilter.values) {
        for (final useCase in [null, ...UseCase.values]) {
          await _pumpBar(
            tester,
            width: width,
            filter: filter,
            useCase: useCase,
          );
          // An overflow is reported as a layout exception.
          expect(
            tester.takeException(),
            isNull,
            reason: '$filter with ${useCase?.label ?? 'no goal'}',
          );
          // Reset stays fully on screen.
          final reset = tester.getRect(
            find.byTooltip('Reset filters and search'),
          );
          expect(reset.right, lessThanOrEqualTo(width));
        }
      }
    });
  }

  testWidgets('a long goal name is shortened, not cut off', (tester) async {
    await _pumpBar(
      tester,
      width: 320,
      filter: ModelFilter.installed,
      useCase: UseCase.documents,
    );
    final label = tester.widget<Text>(find.text(UseCase.documents.label));
    expect(label.overflow, TextOverflow.ellipsis);
    expect(label.maxLines, 1);
  });
}
