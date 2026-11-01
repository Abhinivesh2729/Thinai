import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/server/api_server.dart';
import 'package:local_llm/server/api_tokens.dart';
import 'package:local_llm/state/providers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ApiTokenStore', () {
    test('starts empty', () async {
      expect(await ApiTokenStore().load(), isEmpty);
    });

    test('creates named tokens with a date, oldest first', () async {
      final store = ApiTokenStore();
      final before = DateTime.now();
      final a = await store.create('Laptop');
      final b = await store.create('  Phone  ');

      final tokens = await store.load();
      expect(tokens.map((t) => t.name), ['Laptop', 'Phone']);
      expect(a.token, isNot(b.token));
      expect(a.token.length, greaterThanOrEqualTo(43)); // 32 bytes, base64url
      expect(a.createdAt.isBefore(before), isFalse);
    });

    test('a blank name falls back to a numbered one', () async {
      final store = ApiTokenStore();
      await store.create('x');
      expect((await store.create('   ')).name, 'Token 2');
    });

    test('deletes only the token asked for', () async {
      final store = ApiTokenStore();
      final a = await store.create('A');
      final b = await store.create('B');
      await store.delete(a.id);
      expect((await store.load()).map((t) => t.id), [b.id]);
    });

    test('migrates the old single LAN token as "Default"', () async {
      SharedPreferences.setMockInitialValues({'server_bearer_token': 'old'});
      final tokens = await ApiTokenStore().load();
      expect(tokens.single.name, 'Default');
      expect(tokens.single.token, 'old');

      // Migrated once: deleting it does not bring it back.
      await ApiTokenStore().delete(tokens.single.id);
      expect(await ApiTokenStore().load(), isEmpty);
    });
  });

  group('ApiTokensController', () {
    test('pushes tokens to the server as they change', () async {
      final server = ApiServer();
      final controller = ApiTokensController(server);
      await controller.ready;

      final t = await controller.create('Laptop');
      server.setTunnelAuth(true); // only allowed once a token exists

      await controller.delete(t.id);
      expect(controller.state, isEmpty);
      expect(() => server.setTunnelAuth(true), throwsStateError);
    });

    test('ensureOne creates a Default token only when none exist', () async {
      final controller = ApiTokensController(ApiServer());
      final first = await controller.ensureOne();
      final again = await controller.ensureOne();
      expect(first, again);
      expect(controller.state.single.name, 'Default');
    });
  });
}
