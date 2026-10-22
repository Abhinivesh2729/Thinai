import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'routes/ollama_routes.dart';
import 'routes/openai_routes.dart';

class ApiServerConfig {
  final int port;
  final bool lanMode;

  /// Bearer tokens any client may authenticate with.
  final Set<String> tokens;

  const ApiServerConfig({
    this.port = 11434,
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

  /// Whether requests must carry a bearer token: on the LAN, or while a
  /// public tunnel forwards the internet to loopback.
  bool get authRequired => _config.lanMode || _tunnelAuth;

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

      if (!server.authRequired) return inner(req);

      final authorization = req.headers['authorization'];
      final token = authorization != null && authorization.startsWith('Bearer ')
          ? authorization.substring('Bearer '.length)
          : null;

      if (token == null || !server._tokens.contains(token)) {
        return Response.unauthorized(
          jsonEncode({'error': 'unauthorized'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return inner(req);
    };
  };
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
