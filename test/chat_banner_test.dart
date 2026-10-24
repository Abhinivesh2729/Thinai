import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/l10n/l10n.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:local_llm/state/providers.dart';
import 'package:local_llm/ui/pages/chat_page.dart';

import 'helpers/fonts.dart';

/// Model store holding [models], never touching the file system.
class _FakeModelStore implements ModelStore {
  final List<LocalModel> models;
  _FakeModelStore(this.models);

  @override
  Future<List<LocalModel>> list() async => models;

  @override
  Future<LocalModel?> findById(String id) async => null;

  @override
  Future<String?> projectorPathFor(String? filename) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LocalModel _model(String id) => LocalModel(
  id: id,
  displayName: id,
  path: '/models/$id.gguf',
  sizeBytes: 400 * 1024 * 1024,
  modifiedAt: DateTime(2026),
);

Future<void> _pumpChat(WidgetTester tester, List<LocalModel> models) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});

  final container = ProviderContainer(
    overrides: [
      modelStoreProvider.overrideWithValue(_FakeModelStore(models)),
      appVersionProvider.overrideWith((ref) async => '1.2.3'),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChatPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRoboto);

  testWidgets('with nothing downloaded, it says how to get a model', (
    tester,
  ) async {
    await _pumpChat(tester, const []);

    expect(find.text('No model yet.'), findsOneWidget);
    expect(
      find.textContaining('Thinai needs a language model to chat.'),
      findsOneWidget,
    );
    expect(find.textContaining('models downloaded'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with models downloaded but none loaded, it says to pick one', (
    tester,
  ) async {
    await _pumpChat(tester, [_model('a'), _model('b')]);

    expect(find.text('No model loaded.'), findsOneWidget);
    expect(
      find.text(
        'You have 2 models downloaded. Select one to load it and start '
        'chatting.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('needs a language model'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
