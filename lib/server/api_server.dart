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
  final String? bearerToken;

  const ApiServerConfig({
    this.port = 11434,
    this.lanMode = false,
    this.bearerToken,
  });

  ApiServerConfig copyWith({int? port, bool? lanMode, String? bearerToken}) {
    return ApiServerConfig(
      port: port ?? this.port,
      lanMode: lanMode ?? this.lanMode,
      bearerToken: bearerToken ?? this.bearerToken,
    );
  }
}

class ApiServer {
  HttpServer? _server;
  ApiServerConfig _config = const ApiServerConfig();

  bool get running => _server != null;
  int? get port => _server?.port;
  ApiServerConfig get config => _config;

  Future<void> start(ApiServerConfig config) async {
    if (_server != null) return;

    // LAN mode must never run without authentication.
    if (config.lanMode &&
        (config.bearerToken == null || config.bearerToken!.isEmpty)) {
      throw StateError(
        'LAN API cannot start without a bearer authentication token.',
      );
    }

    _config = config;

    final root = Router();

    root.mount('/', ollamaRouter().call);
    root.mount('/', openAiRouter().call);

    root.get(
      '/',
      (Request req) =>
          Response.ok('Thinai is running. See /api/tags or /v1/models.'),
    );

    var pipeline = const Pipeline()
        .addMiddleware(
          corsMiddleware(
            lanMode: config.lanMode,
            extraOrigins: parseOrigins(Platform.environment['THINAI_ORIGINS']),
          ),
        )
        .addMiddleware(errorMiddleware());

    if (config.lanMode) {
      pipeline = pipeline.addMiddleware(_authMiddleware(config.bearerToken!));
    }

    final handler = pipeline.addHandler(root.call);

    final address = config.lanMode
        ? InternetAddress.anyIPv4
        : InternetAddress.loopbackIPv4;

    _server = await shelf_io.serve(handler, address, config.port);
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }
}

/// Origins listed in `THINAI_ORIGINS`: comma-separated, `*` for any, the way
/// Ollama's OLLAMA_ORIGINS works.
Set<String> parseOrigins(String? value) => {
  for (final o in (value ?? '').split(','))
    if (o.trim().isNotEmpty) o.trim(),
};

const _loopbackHosts = {'localhost', '127.0.0.1', '::1'};

String? _hostOf(String url) {
  final uri = Uri.tryParse(url);
  // Uri keeps IPv6 hosts without brackets.
  return uri == null || uri.host.isEmpty ? null : uri.host.toLowerCase();
}

/// Whether a browser page at [origin] may call the loopback API: pages on
/// this machine, and anything in [extraOrigins].
bool isAllowedOrigin(String origin, Set<String> extraOrigins) =>
    extraOrigins.contains('*') ||
    extraOrigins.contains(origin) ||
    _loopbackHosts.contains(_hostOf(origin));

/// Browser access control. On loopback there is no token, so without this any
/// website open on the machine could drive the models and read the replies:
/// only pages from this machine (or [extraOrigins]) are let through, and a
/// Host that is not loopback is refused, which stops DNS rebinding. Clients
/// that send no Origin (curl, SDKs, editors) are unaffected. In LAN mode
/// every request needs the bearer token anyway, so any origin may call.
Middleware corsMiddleware({
  required bool lanMode,
  Set<String> extraOrigins = const {},
}) {
  return (Handler inner) {
    return (Request req) async {
      final origin = req.headers['origin'];
      if (!lanMode) {
        final host = req.headers['host'];
        if (host != null && !_loopbackHosts.contains(_hostOf('http://$host'))) {
          return Response.forbidden('Host not allowed');
        }
        if (origin != null && !isAllowedOrigin(origin, extraOrigins)) {
          return Response.forbidden(
            'Origin not allowed. Add it to THINAI_ORIGINS to permit it.',
          );
        }
      }
      final cors = {
        'Access-Control-Allow-Origin': lanMode || origin == null ? '*' : origin,
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        if (!lanMode && origin != null) 'Vary': 'Origin',
      };
      if (req.method == 'OPTIONS') return Response.ok('', headers: cors);
      final resp = await inner(req);
      return resp.change(headers: {...resp.headersAll, ...cors});
    };
  };
}

Middleware _authMiddleware(String token) {
  return (Handler inner) {
    return (Request req) async {
      final authorization = req.headers['authorization'];

      if (authorization != 'Bearer $token') {
        return Response.unauthorized(
          jsonEncode({'error': 'unauthorized'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return inner(req);
    };
  };
}

/// Turns an unexpected exception into a 500 the client can parse. The stack
/// trace goes to stderr only: it names files and internals no client needs.
Middleware errorMiddleware() {
  return (Handler inner) {
    return (Request req) async {
      try {
        return await inner(req);
      } catch (e, st) {
        stderr.writeln('API error on ${req.method} /${req.url.path}: $e\n$st');
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
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}
