import 'dart:convert';
import 'dart:io';

/// What the fake server should answer one request with.
class CannedResponse {
  const CannedResponse({
    this.body,
    this.contentType = 'application/json',
    this.status = 200,
    this.headers = const {},
  });

  final String? body;
  final String contentType;
  final int status;

  /// Extra response headers, e.g. `Mcp-Session-Id`.
  final Map<String, String> headers;
}

/// Answers a JSON-RPC request body with a canned response.
typedef RawHandler =
    Future<CannedResponse> Function(
      Map<String, dynamic> body,
      HttpRequest request,
    );

/// A loopback HTTP server that answers `/mcp` with whatever a test says, so the
/// client's handling of odd-but-real servers can be pinned down.
///
/// The MCP handshake is answered here, not by the test:
///
/// * `server/discover` gets a JSON-RPC "method not found" error. With
///   `McpProtocol.stable` that is what makes the client take its documented
///   legacy `initialize` fallback, which gives the tests a deterministic,
///   well-specified handshake. (The modern stateless handshake is exercised for
///   real by `TestMcpServer`.)
/// * `initialize` and `notifications/initialized` are answered per the spec.
///   With [sessionId] set, the legacy session is established the way a stateful
///   server does it.
///
/// Everything else goes to the handler the test supplies.
class RawMcpServer {
  RawMcpServer._(this._http, this.url, this._sessionId);

  final HttpServer _http;
  final Uri url;
  final String? _sessionId;

  /// Requests received, in order, for asserting on headers and reuse.
  final List<HttpRequest> received = [];

  /// The JSON-RPC `method` of each request, index-aligned with [received].
  /// Empty for requests that carried no JSON-RPC body (e.g. the session DELETE).
  final List<String> methods = [];

  static Future<RawMcpServer> start(
    RawHandler handler, {
    bool handshake = true,
    String? sessionId,
  }) async {
    final http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = RawMcpServer._(
      http,
      Uri.parse('http://127.0.0.1:${http.port}/mcp'),
      sessionId,
    );

    http.listen((request) async {
      server.received.add(request);

      final raw = await utf8.decoder.bind(request).join();
      final decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
      final body = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      server.methods.add(body['method'] as String? ?? '');

      final response = await server._respond(body, request, handler, handshake);

      request.response.statusCode = response.status;
      response.headers.forEach((name, value) {
        request.response.headers.set(name, value);
      });
      if (response.body != null) {
        request.response.headers.contentType = ContentType.parse(
          response.contentType,
        );
        request.response.write(response.body);
      }
      await request.response.close();
    });

    return server;
  }

  Future<CannedResponse> _respond(
    Map<String, dynamic> body,
    HttpRequest request,
    RawHandler handler,
    bool handshake,
  ) async {
    final id = body['id'];
    if (!handshake) return handler(body, request);
    switch (body['method']) {
      case 'server/discover':
        return CannedResponse(
          body: _jsonRpcError(id, -32601, 'Method not found'),
        );
      case 'initialize':
        return CannedResponse(
          headers: {if (_sessionId != null) 'Mcp-Session-Id': _sessionId},
          body: _jsonRpcResult(id, {
            'protocolVersion': '2025-11-25',
            'capabilities': {'tools': <String, dynamic>{}},
            'serverInfo': {'name': 'raw-server', 'version': '1.0.0'},
          }),
        );
      case 'notifications/initialized':
        return const CannedResponse(status: 202);
      default:
        return handler(body, request);
    }
  }

  static String _jsonRpcResult(Object? id, Map<String, dynamic> result) =>
      jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result});

  static String _jsonRpcError(Object? id, int code, String message) =>
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': code, 'message': message},
      });

  /// A `result` envelope for a handler to use.
  static String jsonRpcResult(Object? id, Map<String, dynamic> result) =>
      _jsonRpcResult(id, result);

  /// An `error` envelope for a handler to use.
  static String jsonRpcError(Object? id, int code, String message) =>
      _jsonRpcError(id, code, message);

  Future<void> close() => _http.close(force: true);
}
