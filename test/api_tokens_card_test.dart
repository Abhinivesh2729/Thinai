import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/ui/pages/server_page.dart';

void main() {
  testWidgets('creates a named token, lists it, then deletes it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ServerPage())),
    );
    await tester.pumpAndSettle();

    final newToken = find.text('New token');
    await tester.ensureVisible(newToken);
    await tester.tap(newToken);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Laptop');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Laptop'), findsOneWidget);
    expect(find.textContaining('Created '), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete "Laptop"?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Laptop'), findsNothing);
  });
}
