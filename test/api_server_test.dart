import 'package:flutter_test/flutter_test.dart';

import 'package:local_llm/server/api_server.dart';

/// What ApiServer does without binding a socket. Starting it for real opens a
/// listening port, which no test in this suite does, so the routing and
/// middleware it assembles are covered through the routers' own tests.
void main() {
  group('ApiServerConfig', () {
    test('defaults to Ollama\'s port on loopback with no token', () {
      const config = ApiServerConfig();
      expect(config.port, 11434);
      expect(config.lanMode, isFalse);
      expect(config.bearerToken, isNull);
    });

    test('copyWith replaces only the fields given', () {
      const base = ApiServerConfig(port: 8000, bearerToken: 'secret');

      final lan = base.copyWith(lanMode: true);
      expect(lan.port, 8000);
      expect(lan.lanMode, isTrue);
      expect(lan.bearerToken, 'secret');

      final moved = base.copyWith(port: 9000, bearerToken: 'other');
      expect(moved.port, 9000);
      expect(moved.lanMode, isFalse);
      expect(moved.bearerToken, 'other');
    });
  });

  group('ApiServer', () {
    test('starts out stopped with the default config', () {
      final server = ApiServer();
      expect(server.running, isFalse);
      expect(server.port, isNull);
      expect(server.config.port, 11434);
    });

    test('refuses LAN mode without a token', () async {
      final server = ApiServer();
      await expectLater(
        server.start(const ApiServerConfig(lanMode: true)),
        throwsStateError,
      );
      expect(server.running, isFalse);
      // The rejected config is not kept either.
      expect(server.config.lanMode, isFalse);
    });

    test('refuses LAN mode with an empty token', () async {
      final server = ApiServer();
      await expectLater(
        server.start(const ApiServerConfig(lanMode: true, bearerToken: '')),
        throwsStateError,
      );
      expect(server.running, isFalse);
    });

    test('stopping a server that never started is a no-op', () async {
      final server = ApiServer();
      await server.stop();
      expect(server.running, isFalse);
    });
  });
}
