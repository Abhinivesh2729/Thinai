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
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_errorMiddleware());

    if (config.lanMode) {
      pipeline = pipeline.addMiddleware(
        bearerAuthMiddleware(config.bearerToken!),
      );
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

/// Rejects any request that does not carry [token] as its bearer credential.
/// Mounted only in LAN mode; loopback trusts the device itself.
Middleware bearerAuthMiddleware(String token) {
  return (Handler inner) {
    return (Request req) async {
      if (bearerMatches(req.headers['authorization'], token)) {
        return inner(req);
      }

      // Say what is missing in the dialect the client parses, so a LAN user
      // sees "send the token from the Server page" instead of a bare 401.
      const message =
          'Missing or wrong API key. LAN mode needs the bearer token shown '
          'on the Thinai Server page: send "Authorization: Bearer <token>".';
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
