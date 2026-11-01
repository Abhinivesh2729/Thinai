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

  group('bearerMatches', () {
    const token = 'D5HTu_mwQt-abc123_XYZ=';

    test('accepts the exact bearer token', () {
      expect(bearerMatches('Bearer $token', token), isTrue);
    });

    test('reads the scheme case-insensitively and ignores padding', () {
      expect(bearerMatches('bearer $token', token), isTrue);
      expect(bearerMatches('BEARER $token', token), isTrue);
      expect(bearerMatches('  Bearer   $token  ', token), isTrue);
    });

    test('rejects a missing, wrong or placeholder key', () {
      expect(bearerMatches(null, token), isFalse);
      expect(bearerMatches('', token), isFalse);
      expect(bearerMatches('Bearer thinai', token), isFalse);
      expect(bearerMatches('Bearer ${token}x', token), isFalse);
      expect(bearerMatches('Bearer ${token.substring(1)}', token), isFalse);
    });

    test('rejects other schemes and malformed headers', () {
      expect(bearerMatches('Basic $token', token), isFalse);
      expect(bearerMatches(token, token), isFalse);
      expect(bearerMatches('Bearer', token), isFalse);
      expect(bearerMatches('Bearer $token extra', token), isFalse);
    });

    test('never matches an empty server token', () {
      expect(bearerMatches('Bearer ', ''), isFalse);
    });
  });

  group('bearerAuthMiddleware', () {
    const token = 'lan-token-123';
    final handler = const Pipeline()
        .addMiddleware(bearerAuthMiddleware(token))
        .addHandler((_) => Response.ok('ok'));

    Request get(String path, {String? auth}) => Request(
      'GET',
      Uri.parse('http://192.168.1.33:11434/$path'),
      headers: {'authorization': ?auth},
    );

    test('lets a request with the token through', () async {
      final resp = await handler(get('v1/models', auth: 'Bearer $token'));
      expect(resp.statusCode, 200);
    });

    test('answers an OpenAI path with an OpenAI-shaped 401', () async {
      final resp = await handler(get('v1/models', auth: 'Bearer thinai'));
      expect(resp.statusCode, 401);
      expect(resp.headers['www-authenticate'], 'Bearer realm="thinai"');
      final body = jsonDecode(await resp.readAsString()) as Map;
      final error = body['error'] as Map;
      expect(error['code'], 'invalid_api_key');
      expect(error['message'], contains('Server page'));
    });

    test('answers an Ollama path with a string error', () async {
      final resp = await handler(get('api/tags'));
      expect(resp.statusCode, 401);
      final body = jsonDecode(await resp.readAsString()) as Map;
      expect(body['error'], isA<String>());
      expect(body['error'], contains('Authorization: Bearer'));
    });
  });
}
