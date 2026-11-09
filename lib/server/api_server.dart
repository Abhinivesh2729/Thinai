import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../platform/platform_info.dart';
import 'routes/ollama_routes.dart';
import 'routes/openai_routes.dart';

class ApiServerConfig {
  final int port;
  final bool lanMode;

  /// Bearer tokens any client may authenticate with.
  final Set<String> tokens;

  const ApiServerConfig({
    this.port = kMobileServerPort,
    this.lanMode = false,
    this.tokens = const {},
  });

  ApiServerConfig copyWith({int? port, bool? lanMode, Set<String>? tokens}) {
    return ApiServerConfig(
      port: port ?? this.port,
      lanMode: lanMode ?? this.lanMode,
      tokens: tokens ?? this.tokens,
    );
  }
}

class ApiServer {
  HttpServer? _server;
  ApiServerConfig _config = const ApiServerConfig();
  Set<String> _tokens = const {};
  bool _tunnelAuth = false;

  bool get running => _server != null;
  int? get port => _server?.port;
  ApiServerConfig get config => _config;

  /// Whether [req] must carry a bearer token: everything on the LAN, and,
  /// while a public tunnel is open, requests that came through it. Cloudflare
  /// stamps those with `cf-connecting-ip`; apps on this phone calling
  /// 127.0.0.1 directly don't have it and stay open.
  bool authRequired(Request req) =>
      _config.lanMode ||
      (_tunnelAuth && req.headers.containsKey('cf-connecting-ip'));

  /// Replaces the accepted tokens without a restart, so deleting a token
  /// locks its client out immediately.
  void setTokens(Iterable<String> tokens) => _tokens = tokens.toSet();

  /// Turns auth on for a public tunnel. Refuses with no token, as LAN does.
  void setTunnelAuth(bool on) {
    if (on && _tokens.isEmpty) {
      throw StateError('A public tunnel cannot start without an API token.');
    }
    _tunnelAuth = on;
  }

  Future<void> start(ApiServerConfig config) async {
    if (_server != null) return;

    // LAN mode must never run without authentication.
    if (config.lanMode && config.tokens.isEmpty) {
      throw StateError(
        'LAN API cannot start without a bearer authentication token.',
      );
    }

    _config = config;
    _tokens = config.tokens;

    final address = config.lanMode
        ? InternetAddress.anyIPv4
        : InternetAddress.loopbackIPv4;

    _server = await shelf_io.serve(handler, address, config.port);
  }

  /// The full request pipeline, exposed so tests can drive it without
  /// binding a socket.
  Handler get handler {
    final root = Router();

    root.mount('/', ollamaRouter().call);
    root.mount('/', openAiRouter().call);

    root.get(
      '/',
      (Request req) =>
          Response.ok('Thinai is running. See /api/tags or /v1/models.'),
    );

    return const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_errorMiddleware())
        .addMiddleware(_authMiddleware(this))
        .addHandler(root.call);
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _tunnelAuth = false;
    await server?.close(force: true);
  }
}

Middleware _corsMiddleware() {
  return (Handler inner) {
    return (Request req) async {
      if (req.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final resp = await inner(req);
      return resp.change(headers: {...resp.headersAll, ..._corsHeaders});
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

Response _healthz() => Response.ok(
  jsonEncode({'status': 'ok'}),
  headers: {'content-type': 'application/json'},
);

Middleware _authMiddleware(ApiServer server) {
  return (Handler inner) {
    return (Request req) async {
      // Liveness only, no data: open so uptime checks work through a tunnel.
      if (req.url.path == 'healthz') return _healthz();

      if (!server.authRequired(req)) return inner(req);

      final authorization = req.headers['authorization'];
      if (server._tokens.any((t) => bearerMatches(authorization, t))) {
        return inner(req);
      }

      // Say what is missing in the dialect the client parses, so a LAN user
      // sees "send a token from the Server page" instead of a bare 401.
      const message =
          'Missing or wrong API key. Send "Authorization: Bearer <token>" '
          'with a token from API tokens on the Thinai Server page.';
      final openAi = req.url.path.startsWith('v1/');
      return Response.unauthorized(
        jsonEncode({
          'error': openAi
              ? {
                  'message': message,
                  'type': 'invalid_request_error',
                  'code': 'invalid_api_key',
                }
              : message,
        }),
        headers: {
          'content-type': 'application/json',
          'www-authenticate': 'Bearer realm="thinai"',
        },
      );
    };
  };
}

/// Whether an `Authorization` header carries [token] as a bearer credential.
///
/// The scheme is case-insensitive (RFC 7235) and surrounding whitespace is
/// ignored, since clients differ on both. The token itself is compared in
/// constant time so a LAN peer cannot recover it byte by byte from timings.
bool bearerMatches(String? authorization, String token) {
  if (authorization == null || token.isEmpty) return false;
  final parts = authorization.trim().split(RegExp(r'\s+'));
  if (parts.length != 2 || parts[0].toLowerCase() != 'bearer') return false;
  final given = utf8.encode(parts[1]);
  final expected = utf8.encode(token);
  if (given.length != expected.length) return false;
  var diff = 0;
  for (var i = 0; i < given.length; i++) {
    diff |= given[i] ^ expected[i];
  }
  return diff == 0;
}

Middleware _errorMiddleware() {
  return (Handler inner) {
    return (Request req) async {
      try {
        return await inner(req);
      } catch (e, st) {
        // The two surfaces spell an error differently, and a client parsing
        // the wrong shape is left with no message at all: OpenAI SDKs read
        // `error.message` off an object, Ollama clients read `error` as a
        // string. Answer each in its own dialect.
        final openAi = req.url.path.startsWith('v1/');
        return Response.internalServerError(
          body: jsonEncode({
            'error': openAi
                ? {'message': e.toString(), 'type': 'server_error'}
                : e.toString(),
            'stack': st.toString(),
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}
