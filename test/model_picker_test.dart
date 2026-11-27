import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/ui/widgets/model_picker.dart';

LocalModel _model(String id, String name, {int sizeBytes = 0}) => LocalModel(
  id: id,
  displayName: name,
  path: '/models/$id.gguf',
  sizeBytes: sizeBytes,
  modifiedAt: DateTime(2026),
);

final _qwen = _model('qwen', 'Qwen 0.5B');
final _gemma = _model('gemma', 'Gemma 1B');

Future<void> _pump(
  WidgetTester tester, {
  required LocalModel selected,
  bool enabled = true,
  ValueChanged<LocalModel>? onChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ModelPicker(
          models: [_qwen, _gemma],
          selected: selected,
          enabled: enabled,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('ModelPicker', () {
    testWidgets('shows the selected model', (tester) async {
      await _pump(tester, selected: _gemma);
      expect(find.text('Gemma 1B'), findsOneWidget);
      expect(find.text('Qwen 0.5B'), findsNothing);
    });

    testWidgets('picking another model reports that model', (tester) async {
      LocalModel? picked;
      await _pump(tester, selected: _qwen, onChanged: (m) => picked = m);

      await tester.tap(find.text('Qwen 0.5B'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gemma 1B').last);
      await tester.pumpAndSettle();

      expect(picked, same(_gemma));
    });

    testWidgets('disabled picker does not open or report', (tester) async {
      LocalModel? picked;
      await _pump(
        tester,
        selected: _qwen,
        enabled: false,
        onChanged: (m) => picked = m,
      );

      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dropdown.onChanged, isNull);

      await tester.tap(find.text('Qwen 0.5B'));
      await tester.pumpAndSettle();
      expect(find.text('Gemma 1B'), findsNothing);
      expect(picked, isNull);
    });

    testWidgets('an id not in the list is ignored', (tester) async {
      LocalModel? picked;
      await _pump(tester, selected: _qwen, onChanged: (m) => picked = m);

      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      dropdown.onChanged!('missing');
      expect(picked, isNull);
    });
  });

  group('LocalModel.sizeFormatted', () {
    test('uses B, KB, MB and GB', () {
      expect(_model('a', 'a', sizeBytes: 512).sizeFormatted, '512 B');
      expect(_model('a', 'a', sizeBytes: 1536).sizeFormatted, '1.5 KB');
      expect(
        _model('a', 'a', sizeBytes: 5 * 1024 * 1024).sizeFormatted,
        '5.0 MB',
      );
      expect(
        _model('a', 'a', sizeBytes: 3 * 1024 * 1024 * 1024 ~/ 2).sizeFormatted,
        '1.50 GB',
      );
    });

    test('switches unit at each 1024 boundary', () {
      expect(_model('a', 'a', sizeBytes: 1023).sizeFormatted, '1023 B');
      expect(_model('a', 'a', sizeBytes: 1024).sizeFormatted, '1.0 KB');
      expect(_model('a', 'a', sizeBytes: 1024 * 1024).sizeFormatted, '1.0 MB');
      expect(
        _model('a', 'a', sizeBytes: 1024 * 1024 * 1024).sizeFormatted,
        '1.00 GB',
      );
    });
  });
}
