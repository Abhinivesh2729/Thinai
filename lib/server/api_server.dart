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
        _authMiddleware(config.bearerToken!),
      );
    }

    final handler = pipeline.addHandler(root.call);

    final address = config.lanMode
        ? InternetAddress.anyIPv4
        : InternetAddress.loopbackIPv4;

    _server = await shelf_io.serve(
      handler,
      address,
      config.port,
    );
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

Middleware _authMiddleware(String token) {
  return (Handler inner) {
    return (Request req) async {
      final authorization = req.headers['authorization'];

      if (authorization != 'Bearer $token') {
        return Response.unauthorized(
          jsonEncode({
            'error': 'unauthorized',
          }),
          headers: {
            'content-type': 'application/json',
          },
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
