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
      expect(config.tokens, isEmpty);
    });

    test('copyWith replaces only the fields given', () {
      const base = ApiServerConfig(port: 8000, tokens: {'secret'});

      final lan = base.copyWith(lanMode: true);
      expect(lan.port, 8000);
      expect(lan.lanMode, isTrue);
      expect(lan.tokens, {'secret'});

      final moved = base.copyWith(port: 9000, tokens: {'other'});
      expect(moved.port, 9000);
      expect(moved.lanMode, isFalse);
      expect(moved.tokens, {'other'});
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
        server.start(const ApiServerConfig(lanMode: true, tokens: {})),
        throwsStateError,
      );
      expect(server.running, isFalse);
    });

    test('stopping a server that never started is a no-op', () async {
      final server = ApiServer();
      await server.stop();
      expect(server.running, isFalse);
    });

    test('refuses tunnel auth without a token', () {
      final server = ApiServer();
      expect(() => server.setTunnelAuth(true), throwsStateError);
      expect(
        server.authRequired(
          Request(
            'GET',
            Uri.parse('http://localhost/'),
            headers: {'cf-connecting-ip': '203.0.113.7'},
          ),
        ),
        isFalse,
      );
    });
  });

  group('ApiServer.handler', () {
    // Requests through the tunnel carry Cloudflare's cf-connecting-ip.
    Future<Response> get(
      ApiServer server,
      String path, {
      String? token,
      bool viaTunnel = true,
    }) => Future.value(
      server.handler(
        Request(
          'GET',
          Uri.parse('http://localhost/$path'),
          headers: {
            if (token != null) 'authorization': 'Bearer $token',
            if (viaTunnel) 'cf-connecting-ip': '203.0.113.7',
          },
        ),
      ),
    );

    ApiServer tunneled(Set<String> tokens) => ApiServer()
      ..setTokens(tokens)
      ..setTunnelAuth(true);

    test('/healthz answers ok without a token, even when auth is on', () async {
      final res = await get(tunneled({'a'}), 'healthz');
      expect(res.statusCode, 200);
      expect(jsonDecode(await res.readAsString()), {'status': 'ok'});
    });

    test('/healthz can be called repeatedly', () async {
      final server = ApiServer();
      expect((await get(server, 'healthz')).statusCode, 200);
      expect((await get(server, 'healthz')).statusCode, 200);
    });

    test('loopback without tunnel needs no token', () async {
      expect((await get(ApiServer(), '')).statusCode, 200);
    });

    test('tunnel auth rejects a missing or unknown token', () async {
      final server = tunneled({'a', 'b'});
      expect((await get(server, '')).statusCode, 401);
      expect((await get(server, '', token: 'nope')).statusCode, 401);
    });

    test('apps on the phone need no token while the tunnel is open', () async {
      final server = tunneled({'a'});
      expect((await get(server, '', viaTunnel: false)).statusCode, 200);
    });

    test('tunnel auth accepts any listed token', () async {
      final server = tunneled({'a', 'b'});
      expect((await get(server, '', token: 'a')).statusCode, 200);
      expect((await get(server, '', token: 'b')).statusCode, 200);
    });

    test('a removed token stops working without a restart', () async {
      final server = tunneled({'a', 'b'});
      server.setTokens({'b'});
      expect((await get(server, '', token: 'a')).statusCode, 401);
      expect((await get(server, '', token: 'b')).statusCode, 200);
    });

    test('turning the tunnel off drops the auth requirement', () async {
      final server = tunneled({'a'})..setTunnelAuth(false);
      expect((await get(server, '')).statusCode, 200);
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

  group('auth rejection', () {
    // Through the tunnel, so the middleware demands a token.
    final server = ApiServer()
      ..setTokens({'first-token', 'lan-token-123'})
      ..setTunnelAuth(true);

    Request get(String path, {String? auth}) => Request(
      'GET',
      Uri.parse('http://127.0.0.1:11434/$path'),
      headers: {'cf-connecting-ip': '203.0.113.7', 'authorization': ?auth},
    );

    test('accepts any listed token, scheme case-insensitively', () async {
      final resp = await server.handler(get('', auth: 'bearer lan-token-123'));
      expect(resp.statusCode, 200);
    });

    test('answers an OpenAI path with an OpenAI-shaped 401', () async {
      final resp = await server.handler(
        get('v1/models', auth: 'Bearer thinai'),
      );
      expect(resp.statusCode, 401);
      expect(resp.headers['www-authenticate'], 'Bearer realm="thinai"');
      final body = jsonDecode(await resp.readAsString()) as Map;
      final error = body['error'] as Map;
      expect(error['code'], 'invalid_api_key');
      expect(error['message'], contains('Server page'));
    });

    test('answers an Ollama path with a string error', () async {
      final resp = await server.handler(get('api/tags'));
      expect(resp.statusCode, 401);
      final body = jsonDecode(await resp.readAsString()) as Map;
      expect(body['error'], isA<String>());
      expect(body['error'], contains('Authorization: Bearer'));
    });
  });
}
