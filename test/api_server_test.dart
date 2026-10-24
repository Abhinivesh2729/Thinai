import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

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

  group('browser access on loopback', () {
    Future<Response> call(
      Map<String, String> headers, {
      bool lanMode = false,
      Set<String> extraOrigins = const {},
      String method = 'POST',
    }) async {
      final handler = const Pipeline()
          .addMiddleware(
            corsMiddleware(lanMode: lanMode, extraOrigins: extraOrigins),
          )
          .addHandler((_) => Response.ok('reply'));
      return handler(
        Request(
          method,
          Uri.parse('http://127.0.0.1:11434/api/chat'),
          headers: headers,
        ),
      );
    }

    test('a website elsewhere cannot drive the models', () async {
      final res = await call({
        'host': '127.0.0.1:11434',
        'origin': 'https://evil.example',
      });
      expect(res.statusCode, 403);
    });

    test('its preflight is refused too', () async {
      final res = await call({
        'host': '127.0.0.1:11434',
        'origin': 'https://evil.example',
      }, method: 'OPTIONS');
      expect(res.statusCode, 403);
    });

    test('a rebound DNS name pointing at loopback is refused', () async {
      final res = await call({'host': 'attacker.example:11434'});
      expect(res.statusCode, 403);
    });

    test('clients without an Origin (curl, SDKs) still work', () async {
      final res = await call({'host': 'localhost:11434'});
      expect(res.statusCode, 200);
      expect(await res.readAsString(), 'reply');
    });

    test(
      'a page served from this machine may call, and is named back',
      () async {
        for (final origin in [
          'http://localhost:3000',
          'http://127.0.0.1:8080',
          'http://[::1]:5173',
        ]) {
          final res = await call({'host': '[::1]:11434', 'origin': origin});
          expect(res.statusCode, 200, reason: origin);
          expect(res.headers['access-control-allow-origin'], origin);
          expect(res.headers['vary'], 'Origin');
        }
      },
    );

    test('THINAI_ORIGINS lets a listed site in', () async {
      final res = await call({
        'host': '127.0.0.1:11434',
        'origin': 'https://my.tool',
      }, extraOrigins: parseOrigins(' https://my.tool , https://other '));
      expect(res.statusCode, 200);
    });

    test('THINAI_ORIGINS=* opens it to every site', () async {
      final res = await call({
        'host': '127.0.0.1:11434',
        'origin': 'https://evil.example',
      }, extraOrigins: parseOrigins('*'));
      expect(res.statusCode, 200);
    });

    test('LAN mode leaves origins to the bearer token', () async {
      final res = await call({
        'host': '192.168.1.20:11434',
        'origin': 'https://evil.example',
      }, lanMode: true);
      expect(res.statusCode, 200);
      expect(res.headers['access-control-allow-origin'], '*');
    });
  });

  group('unexpected errors', () {
    Future<Map<String, dynamic>> fail(String path) async {
      final handler = const Pipeline()
          .addMiddleware(errorMiddleware())
          .addHandler((_) => throw StateError('boom'));
      final res = await handler(
        Request('POST', Uri.parse('http://127.0.0.1:11434/$path')),
      );
      expect(res.statusCode, 500);
      return jsonDecode(await res.readAsString()) as Map<String, dynamic>;
    }

    test('answer OpenAI clients without leaking the stack trace', () async {
      final body = await fail('v1/chat/completions');
      expect(body['error']['message'], contains('boom'));
      expect(body.containsKey('stack'), isFalse);
      expect(jsonEncode(body), isNot(contains('.dart')));
    });

    test('answer Ollama clients without leaking the stack trace', () async {
      final body = await fail('api/chat');
      expect(body['error'], contains('boom'));
      expect(body.containsKey('stack'), isFalse);
    });
  });
}
