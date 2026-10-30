# MCP Client — Protocol Core Implementation Plan

> **Status:** Complete (2026-10-30). Implemented on `feature/mcp-client-protocol-core` and open as PR #40. Verified after rebasing onto `main` (2.5.0): `dart format` clean, `flutter analyze` clean, 757 tests pass, coverage gate PASS with `lib/mcp/` at 100% (86/86, 8/8, 8/8). Every step below is checked off; the "Amendments after implementation" section records where the shipped code diverges from the plan.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Dart client that connects to an MCP server over Streamable HTTP, lists its tools, and calls them — with normalized app-owned types and no UI or chat wiring.

**Architecture:** A single module, `lib/mcp/`, wrapping the `mcp_dart` package behind three small files: value types, exceptions, and one `McpConnection` class that is the only file importing `mcp_dart`. Tests drive the client against a real MCP server (and a raw canned-response server) bound to loopback, so no network and no mocks of our own code are needed.

**Tech Stack:** Dart 3.11 / Flutter 3.47.4, `mcp_dart ^2.4.3`, `flutter_test`, `dart:io` `HttpServer`.

**Spec:** `docs/superpowers/specs/2026-10-18-mcp-client-protocol-core-design.md`

## Global Constraints

- Flutter `3.47.4` / Dart SDK `^3.11.0` (matches CI).
- Add exactly one dependency: `mcp_dart: ^2.4.3`. It must introduce **no new transitive packages** (`crypto`, `http`, `meta` are already pinned).
- **Only `lib/mcp/mcp_connection.dart` may import `package:mcp_dart/mcp_dart.dart`.** No other file under `lib/` and no exported signature may reference an `mcp_dart` type.
- Phase 1 ships no UI, no `SharedPreferences`, no Riverpod providers, no consent flow, no chat/`ToolSpec` wiring, no resources/prompts, no OAuth, no stdio, and no MCP server.
- CI gate: `dart format` (changed Dart files), `flutter analyze` (no warnings), `flutter test --exclude-tags native --coverage`, then `./tool/check_coverage.sh` — **100% line coverage of `lib/`**.
- Tests must not touch the public internet; all test servers bind `127.0.0.1` on port `0`.
- No AndroidManifest change (`INTERNET` and cleartext are already configured).
- Branch: `feature/mcp-client-protocol-core`. Commit style follows the repo: `type(scope): imperative subject`.

## Review Focus

The spec describes behaviour on the happy path; these are the inputs most likely to bite a real user that no single task's nominal test covers. Each is pinned by a test in the task noted.

1. **A server answering `application/json` instead of `text/event-stream`** (or vice versa) for the same request — both must work. (Task 2/3)
2. **A session id** (`Mcp-Session-Id`) the server assigns at initialize — it must be sent on every later request, and a `404` on it must surface as a new-session condition rather than a hard failure. (Task 2)
3. **A tool result with non-text blocks** (image, resource link) — must not throw, and the text parts must still be available. (Task 4)
4. **A tool that reports failure with `isError: true`** — must come back as a normal result, not an exception. (Task 4)
5. **`tools/list` paging** — a repeated `nextCursor` must not loop forever. (Task 3)

Also pinned: a `401` maps to `McpAuthException`, a timeout to `McpTimeoutException`, and any other JSON-RPC error from `tools/call` to `McpToolCallException`.

---

## File Structure

| File | Responsibility |
|---|---|
| `pubspec.yaml` | Add the `mcp_dart` dependency. |
| `lib/mcp/mcp_types.dart` | `McpClientInfo`, `McpTool`, `McpContentType`, `McpContent`, `McpToolResult`. No `mcp_dart` import. |
| `lib/mcp/mcp_exceptions.dart` | `McpException` and `McpConnectionException` / `McpAuthException` / `McpTimeoutException` / `McpToolCallException`. No `mcp_dart` import. |
| `lib/mcp/mcp_connection.dart` | `McpConnectionConfig` + `McpConnection`. **The only file importing `mcp_dart`.** |
| `test/support/mcp_test_server.dart` | Test helper: a real `mcp_dart` `McpServer` behind a loopback `HttpServer` on an ephemeral port. |
| `test/support/raw_mcp_server.dart` | Test helper: a loopback `HttpServer` returning canned JSON-RPC / SSE bodies. |
| `test/mcp_types_test.dart` | Type behaviour. |
| `test/mcp_exceptions_test.dart` | Exception behaviour. |
| `test/mcp_connection_test.dart` | Our client against the real test server. |
| `test/mcp_connection_http_test.dart` | Our client against canned HTTP responses. |

---

## Task 1: Dependency, value types, and exceptions

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/mcp/mcp_types.dart`
- Create: `lib/mcp/mcp_exceptions.dart`
- Test: `test/mcp_types_test.dart`
- Test: `test/mcp_exceptions_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `McpClientInfo({String name, String version})`; `McpTool({String name, String? description, Map<String, Object?> inputSchema})`; `enum McpContentType { text, image, audio, resourceLink, resource, other }`; `McpContent({McpContentType type, String? text, String? data, String? mimeType, Uri? uri, Map<String, Object?> raw})`; `McpToolResult({bool isError, List<McpContent> content, Map<String, Object?>? structuredContent})` with `String get text`; `sealed class McpException implements Exception { String get message; }` and subclasses `McpConnectionException`, `McpAuthException`, `McpTimeoutException`, `McpToolCallException({int? code, String message})`.

- [x] **Step 1: Add the dependency**

Edit `pubspec.yaml`, adding under `dependencies:` (alphabetical neighbours: after `dio`, before `flutter_riverpod`):

```yaml
  # MCP client protocol support (JSON-RPC over Streamable HTTP).
  # Pulls in no new transitive packages: crypto, http and meta are already
  # pinned in pubspec.lock.
  mcp_dart: ^2.4.3
```

Then run:

```bash
flutter pub get
```

Expected: resolves with no new packages added.

- [x] **Step 2: Write the failing type tests**

Create `test/mcp_types_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/mcp/mcp_types.dart';

void main() {
  group('McpToolResult.text', () {
    test('joins text blocks with newlines', () {
      const result = McpToolResult(
        content: [
          McpContent(type: McpContentType.text, text: 'first'),
          McpContent(type: McpContentType.image, data: 'AAAA', mimeType: 'image/png'),
          McpContent(type: McpContentType.text, text: 'second'),
        ],
      );

      expect(result.text, 'first\nsecond');
    });

    test('is empty when there are no text blocks', () {
      const result = McpToolResult(
        content: [McpContent(type: McpContentType.image, data: 'AAAA')],
      );

      expect(result.text, isEmpty);
    });

    test('defaults to a non-error result with no content', () {
      const result = McpToolResult();

      expect(result.isError, isFalse);
      expect(result.content, isEmpty);
      expect(result.structuredContent, isNull);
    });
  });

  test('McpTool defaults its input schema to an empty map', () {
    const tool = McpTool(name: 'ping');

    expect(tool.inputSchema, isEmpty);
    expect(tool.description, isNull);
  });
}
```

- [x] **Step 3: Run the type tests to verify they fail**

Run: `flutter test test/mcp_types_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:local_llm/mcp/mcp_types.dart'`.

- [x] **Step 4: Write the failing exception tests**

Create `test/mcp_exceptions_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/mcp/mcp_exceptions.dart';

void main() {
  test('every exception carries a message and is an McpException', () {
    final errors = <McpException>[
      const McpConnectionException('boom'),
      const McpAuthException('nope'),
      const McpTimeoutException('slow'),
      const McpToolCallException(message: 'bad', code: -32601),
    ];

    for (final error in errors) {
      expect(error.message, isNotEmpty);
      expect(error, isA<McpException>());
      expect(error.toString(), contains(error.message));
    }
  });

  test('McpToolCallException exposes the JSON-RPC code', () {
    const error = McpToolCallException(message: 'unknown tool', code: -32601);

    expect(error.code, -32601);
  });

  test('McpToolCallException tolerates a null code', () {
    const error = McpToolCallException(message: 'failed');

    expect(error.code, isNull);
  });
}
```

- [x] **Step 5: Run the exception tests to verify they fail**

Run: `flutter test test/mcp_exceptions_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:local_llm/mcp/mcp_exceptions.dart'`.

- [x] **Step 6: Implement the types**

Create `lib/mcp/mcp_types.dart`:

```dart
/// Identity this client reports to an MCP server during `initialize`.
class McpClientInfo {
  final String name;
  final String version;

  const McpClientInfo({required this.name, required this.version});
}

/// A tool an MCP server offers, normalized away from the package's types.
class McpTool {
  final String name;
  final String? description;

  /// JSON Schema for the tool's arguments. Empty when the server omits it.
  final Map<String, Object?> inputSchema;

  const McpTool({
    required this.name,
    this.description,
    this.inputSchema = const {},
  });
}

/// Which kind of content block a result carried.
enum McpContentType { text, image, audio, resourceLink, resource, other }

/// One content block from a tool result.
///
/// [raw] keeps the server's original JSON so nothing is lost for later phases.
class McpContent {
  final McpContentType type;
  final String? text;
  final String? data;
  final String? mimeType;
  final Uri? uri;
  final Map<String, Object?> raw;

  const McpContent({
    required this.type,
    this.text,
    this.data,
    this.mimeType,
    this.uri,
    this.raw = const {},
  });
}

/// What a tool call returned.
///
/// [isError] is the server reporting that the tool failed (bad arguments, a
/// business error). That is a result the model can react to, not an exception.
class McpToolResult {
  final bool isError;
  final List<McpContent> content;
  final Map<String, Object?>? structuredContent;

  const McpToolResult({
    this.isError = false,
    this.content = const [],
    this.structuredContent,
  });

  /// The text blocks joined by newlines, ready to hand back to a model.
  String get text => content
      .where((block) => block.type == McpContentType.text && block.text != null)
      .map((block) => block.text!)
      .join('\n');
}
```

- [x] **Step 7: Implement the exceptions**

Create `lib/mcp/mcp_exceptions.dart`:

```dart
/// Base for everything this module throws.
///
/// Messages are short and safe to show a user, mirroring [WebSearchException].
sealed class McpException implements Exception {
  final String message;

  const McpException(this.message);

  @override
  String toString() => message;
}

/// The connection could not be established, or the protocol/transport failed.
class McpConnectionException extends McpException {
  const McpConnectionException(super.message);
}

/// The server rejected our credentials (HTTP 401 / MCP unauthorized).
class McpAuthException extends McpException {
  const McpAuthException(super.message);
}

/// A request did not complete in time.
class McpTimeoutException extends McpException {
  const McpTimeoutException(super.message);
}

/// A JSON-RPC error came back from `tools/call`.
class McpToolCallException extends McpException {
  /// The JSON-RPC error code, when the server sent one.
  final int? code;

  const McpToolCallException({required String message, this.code})
    : super(message);
}
```

Note: the `sealed` base needs its subclasses in the same library — they are, since all four live in this one file.

- [x] **Step 8: Run all Task 1 tests to verify they pass**

Run: `flutter test test/mcp_types_test.dart test/mcp_exceptions_test.dart`
Expected: PASS (both files).

- [x] **Step 9: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/mcp/mcp_types.dart lib/mcp/mcp_exceptions.dart test/mcp_types_test.dart test/mcp_exceptions_test.dart
git commit -m "feat(mcp): add MCP value types and exceptions"
```

---

## Task 2: Connect, disconnect, and server info

**Files:**
- Create: `lib/mcp/mcp_connection.dart`
- Create: `test/support/mcp_test_server.dart`
- Test: `test/mcp_connection_test.dart`

**Interfaces:**
- Consumes: `McpClientInfo`, `McpTool*` from `mcp_types.dart`; all exceptions from `mcp_exceptions.dart`.
- Produces: `McpConnectionConfig({Uri endpoint, Map<String, String> headers, Duration requestTimeout})`; `McpConnection({required McpConnectionConfig config, McpClientInfo? clientInfo})` with `bool get isConnected`, `String? get serverName`, `String? get serverVersion`, `String? get protocolVersion`, `Future<void> connect()`, `Future<void> disconnect()`.

- [x] **Step 1: Write the test-server helper**

Create `test/support/mcp_test_server.dart`. This is test-only, so importing `mcp_dart` here is fine.

```dart
import 'dart:io';

import 'package:mcp_dart/mcp_dart.dart';

/// A real MCP server, served over loopback HTTP on an ephemeral port, so the
/// client under test speaks the actual protocol without touching the network.
class TestMcpServer {
  TestMcpServer._(this._http, this._server, this.url);

  final HttpServer _http;
  final McpServer _server;
  final Uri url;

  static Future<TestMcpServer> start({
    List<Tool> Function()? tools,
    bool withSession = false,
  }) async {
    final server = McpServer(
      const Implementation(name: 'test-server', version: '9.9.9'),
      options: const McpServerOptions(
        capabilities: ServerCapabilities(tools: ServerCapabilitiesTools()),
      ),
    );

    for (final tool in tools?.call() ?? const <Tool>[]) {
      // Registered below via registerTool in tests that need it.
    }

    final transport = StreamableHTTPServerTransport(
      options: StreamableHTTPServerTransportOptions(
        sessionIdGenerator: withSession ? () => 'test-session-id' : null,
      ),
    );
    await server.connect(transport);

    final http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    http.listen((request) async {
      if (request.uri.path != '/mcp') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      await transport.handleRequest(request);
    });

    return TestMcpServer._(
      http,
      server,
      Uri.parse('http://127.0.0.1:${http.port}/mcp'),
    );
  }

  /// Registers a tool that always returns [text].
  void registerEchoTool({required String name, String text = 'ok'}) {
    _server.registerTool(
      name,
      description: 'Returns a fixed string.',
      inputSchema: JsonSchema.object(
        properties: {'value': JsonSchema.string()},
      ),
      callback: (args, extra) async =>
          CallToolResult(content: [TextContent(text: text)]),
    );
  }

  Future<void> close() async {
    await _server.close();
    await _http.close(force: true);
  }
}
```

**Implementation note for the engineer:** the `tools` factory parameter above is a placeholder for the registration the tests need; if `McpServer.registerTool` can only be called before `connect`, expose registration through `registerEchoTool` and call it inside `start()` before `server.connect(transport)`. Verify against the installed `mcp_dart` version and simplify to whatever the API actually allows — the tests below only require `registerEchoTool` to work on a started server *or* the helper to accept a registration callback. Do not leave the empty loop in the final file.

- [x] **Step 2: Write the failing connect tests**

Create `test/mcp_connection_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/mcp/mcp_connection.dart';
import 'package:local_llm/mcp/mcp_exceptions.dart';

import 'support/mcp_test_server.dart';

void main() {
  late TestMcpServer server;

  setUp(() async {
    server = await TestMcpServer.start();
  });

  tearDown(() => server.close());

  McpConnection connectionFor(Uri endpoint, {Map<String, String>? headers}) =>
      McpConnection(
        config: McpConnectionConfig(
          endpoint: endpoint,
          headers: headers ?? const {},
        ),
      );

  group('McpConnectionConfig', () {
    test('rejects a non-http scheme', () {
      expect(
        () => McpConnectionConfig(endpoint: Uri.parse('ftp://x/mcp')),
        throwsA(isA<McpConnectionException>()),
      );
    });

    test('defaults the request timeout to 30 seconds', () {
      final config = McpConnectionConfig(endpoint: Uri.parse('http://x/mcp'));

      expect(config.requestTimeout, const Duration(seconds: 30));
    });
  });

  test('connect negotiates and exposes the server identity', () async {
    final connection = connectionFor(server.url);

    await connection.connect();

    expect(connection.isConnected, isTrue);
    expect(connection.serverName, 'test-server');
    expect(connection.serverVersion, '9.9.9');
    expect(connection.protocolVersion, isNotNull);

    await connection.disconnect();
  });

  test('disconnect is idempotent', () async {
    final connection = connectionFor(server.url);
    await connection.connect();

    await connection.disconnect();
    await connection.disconnect();

    expect(connection.isConnected, isFalse);
  });

  test('connect to an unreachable endpoint raises McpConnectionException', () async {
    // Port 1 is reserved and never listening.
    final connection = connectionFor(Uri.parse('http://127.0.0.1:1/mcp'));

    await expectLater(
      connection.connect(),
      throwsA(isA<McpConnectionException>()),
    );
  });
}
```

- [x] **Step 3: Run the connect tests to verify they fail**

Run: `flutter test test/mcp_connection_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:local_llm/mcp/mcp_connection.dart'`.

- [x] **Step 4: Implement `McpConnectionConfig` and the connect lifecycle**

Create `lib/mcp/mcp_connection.dart`:

```dart
import 'dart:async';

import 'package:mcp_dart/mcp_dart.dart' as mcp;

import 'mcp_exceptions.dart';
import 'mcp_types.dart';

/// Where to reach an MCP server and how to authenticate to it.
class McpConnectionConfig {
  final Uri endpoint;

  /// Sent on every request, e.g. `{'Authorization': 'Bearer …'}`.
  final Map<String, String> headers;

  final Duration requestTimeout;

  McpConnectionConfig({
    required this.endpoint,
    this.headers = const {},
    this.requestTimeout = const Duration(seconds: 30),
  }) {
    if (endpoint.scheme != 'http' && endpoint.scheme != 'https') {
      throw const McpConnectionException(
        'MCP server addresses must start with http:// or https://.',
      );
    }
  }
}

/// A live connection to one MCP server.
class McpConnection {
  McpConnection({required McpConnectionConfig config, McpClientInfo? clientInfo})
    : _config = config,
      _clientInfo = clientInfo ??
          const McpClientInfo(name: 'Thinai', version: '2.4.0');

  final McpConnectionConfig _config;
  final McpClientInfo _clientInfo;

  mcp.McpClient? _client;

  bool get isConnected => _client != null;
  String? get serverName => _client?.getServerVersion()?.name;
  String? get serverVersion => _client?.getServerVersion()?.version;
  String? get protocolVersion => _client?.getProtocolVersion();

  Future<void> connect() async {
    if (_client != null) return;
    final client = mcp.McpClient(
      mcp.Implementation(name: _clientInfo.name, version: _clientInfo.version),
      options: const mcp.McpClientOptions(protocol: mcp.McpProtocol.stable),
    );
    final transport = mcp.StreamableHttpClientTransport(
      _config.endpoint,
      opts: mcp.StreamableHttpClientTransportOptions(
        requestInit: {'headers': _config.headers},
      ),
    );
    try {
      await client.connect(transport);
    } on mcp.UnauthorizedError catch (error) {
      throw McpAuthException(_describe(error, 'The MCP server rejected our credentials.'));
    } on mcp.McpError catch (error) {
      throw McpConnectionException(_describe(error, 'Could not reach the MCP server.'));
    } catch (error) {
      throw McpConnectionException('Could not reach the MCP server: $error');
    }
    _client = client;
  }

  Future<void> disconnect() async {
    final client = _client;
    _client = null;
    await client?.close();
  }

  static String _describe(Object error, String fallback) {
    final text = error is mcp.McpError ? error.message : '$error';
    return text.isEmpty ? fallback : text;
  }
}
```

**Implementation notes:**
- `McpError`, `UnauthorizedError`, `McpProtocol`, `McpClientOptions`, `getServerVersion()`, `getProtocolVersion()` and `StreamableHttpClientTransportOptions.requestInit` are the names confirmed from `mcp_dart`'s docs; verify each against the installed version and adjust. If `McpError.message` is not a `String`, fall back to `error.toString()`.
- If the client throws the same class for 401 as for other protocol errors, detect the HTTP status another way (the transport may expose it) — the `McpAuthException` mapping must be provable by a test in Task 4's HTTP suite. If it cannot be distinguished, move the auth mapping test there and map 401 by status.
- Do not add `listTools`/`callTool` yet.

- [x] **Step 5: Run the connect tests to verify they pass**

Run: `flutter test test/mcp_connection_test.dart`
Expected: PASS.

- [x] **Step 6: Commit**

```bash
git add lib/mcp/mcp_connection.dart test/support/mcp_test_server.dart test/mcp_connection_test.dart
git commit -m "feat(mcp): connect to an MCP server and expose its identity"
```

---

## Task 3: `listTools` with pagination

**Files:**
- Modify: `lib/mcp/mcp_connection.dart`
- Create: `test/support/raw_mcp_server.dart`
- Modify: `test/mcp_connection_test.dart`
- Create: `test/mcp_connection_http_test.dart`

**Interfaces:**
- Consumes: `McpConnection` from Task 2, `McpTool` from Task 1.
- Produces: `Future<List<McpTool>> McpConnection.listTools()`.

- [x] **Step 1: Write the raw-server helper**

Create `test/support/raw_mcp_server.dart`:

```dart
import 'dart:convert';
import 'dart:io';

/// What the fake server should answer one POST with.
class CannedResponse {
  const CannedResponse({
    this.body,
    this.contentType = 'application/json',
    this.status = 200,
  });

  final String? body;
  final String contentType;
  final int status;
}

/// A loopback HTTP server that answers `/mcp` with whatever an individual test
/// says, so the client's handling of odd-but-real servers can be pinned down.
class RawMcpServer {
  RawMcpServer._(this._http, this.url);

  final HttpServer _http;
  final Uri url;

  /// Requests received, in order, for asserting on headers and reuse.
  final List<HttpRequest> received = [];

  static Future<RawMcpServer> start(
    Future<CannedResponse> Function(Map<String, dynamic> body, HttpRequest request)
    handler,
  ) async {
    final http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = RawMcpServer._(
      http,
      Uri.parse('http://127.0.0.1:${http.port}/mcp'),
    );
    http.listen((request) async {
      server.received.add(request);
      final raw = await utf8.decoder.bind(request).join();
      final body = raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      final response = await handler(body, request);
      request.response
        ..statusCode = response.status
        ..headers.contentType = ContentType.parse(response.contentType);
      if (response.body != null) request.response.write(response.body);
      await request.response.close();
    });
    return server;
  }

  Future<void> close() => _http.close(force: true);
}
```

- [x] **Step 2: Write the failing `listTools` tests**

Append to `test/mcp_connection_test.dart`:

```dart
  test('listTools returns the server tools with their schemas', () async {
    final server = await TestMcpServer.start();
    server.registerEchoTool(name: 'echo');
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );
    await connection.connect();

    final tools = await connection.listTools();

    expect(tools.map((tool) => tool.name), contains('echo'));
    expect(tools.firstWhere((tool) => tool.name == 'echo').inputSchema, isNotEmpty);

    await connection.disconnect();
    await server.close();
  });

  test('listTools before connect throws McpConnectionException', () async {
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );

    await expectLater(
      connection.listTools(),
      throwsA(isA<McpConnectionException>()),
    );
  });
```

Create `test/mcp_connection_http_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/mcp/mcp_connection.dart';
import 'package:local_llm/mcp/mcp_exceptions.dart';

import 'support/raw_mcp_server.dart';

/// Answers the MCP handshake, then delegates to [onRequest] for everything else.
Future<CannedResponse> Function(Map<String, dynamic>, dynamic) handshakeThen(
  Future<CannedResponse> Function(Map<String, dynamic> body) onRequest,
) {
  return (body, request) async {
    if (body['method'] == 'initialize') {
      return CannedResponse(
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': body['id'],
          'result': {
            'protocolVersion': '2025-06-18',
            'capabilities': {'tools': {}},
            'serverInfo': {'name': 'raw', 'version': '1.0.0'},
          },
        }),
      );
    }
    if (body['method'] == 'notifications/initialized') {
      return const CannedResponse(status: 202, body: null);
    }
    return onRequest(body);
  };
}

String _toolsList(List<String> names, {String? nextCursor}) => jsonEncode({
  'jsonrpc': '2.0',
  'id': 2,
  'result': {
    'tools': [
      for (final name in names)
        {'name': name, 'description': 'd', 'inputSchema': {'type': 'object'}},
    ],
    if (nextCursor != null) 'nextCursor': nextCursor,
  },
});

void main() {
  test('listTools follows pagination across pages', () async {
    var page = 0;
    final server = await RawMcpServer.start(
      handshakeThen((body) async {
        if (body['method'] == 'tools/list') {
          page++;
          return CannedResponse(
            body: page == 1
                ? _toolsList(['a'], nextCursor: 'page-2')
                : _toolsList(['b']),
          );
        }
        return const CannedResponse(status: 202);
      }),
    );
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );
    await connection.connect();

    final tools = await connection.listTools();

    expect(tools.map((tool) => tool.name), ['a', 'b']);
    await connection.disconnect();
    await server.close();
  });

  test('listTools stops with McpConnectionException on a repeated cursor', () async {
    final server = await RawMcpServer.start(
      handshakeThen((body) async {
        if (body['method'] == 'tools/list') {
          return CannedResponse(body: _toolsList(['a'], nextCursor: 'same'));
        }
        return const CannedResponse(status: 202);
      }),
    );
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );
    await connection.connect();

    await expectLater(
      connection.listTools(),
      throwsA(isA<McpConnectionException>()),
    );
    await connection.disconnect();
    await server.close();
  });
}
```

- [x] **Step 3: Run the new tests to verify they fail**

Run: `flutter test test/mcp_connection_test.dart test/mcp_connection_http_test.dart`
Expected: FAIL — `The method 'listTools' isn't defined for the class 'McpConnection'`.

- [x] **Step 4: Implement `listTools`**

Add to `McpConnection` in `lib/mcp/mcp_connection.dart`:

```dart
  Future<List<McpTool>> listTools() async {
    final client = _client;
    if (client == null) {
      throw const McpConnectionException('Not connected to an MCP server.');
    }
    final collected = <McpTool>[];
    final seenCursors = <String>{};
    String? cursor;
    do {
      final page = await _guard(
        () => client.listTools(
          params: cursor == null ? null : mcp.ListToolsRequest(cursor: cursor),
        ),
        'Could not list the MCP server\'s tools.',
      );
      collected.addAll(page.tools.map(_toolFrom));
      cursor = page.nextCursor;
      if (cursor != null && !seenCursors.add(cursor)) {
        throw const McpConnectionException(
          'The MCP server kept repeating a tools cursor.',
        );
      }
    } while (cursor != null);
    return collected;
  }

  static McpTool _toolFrom(mcp.Tool tool) => McpTool(
    name: tool.name,
    description: tool.description,
    inputSchema: _schemaToMap(tool.inputSchema),
  );

  static Map<String, Object?> _schemaToMap(Object? schema) {
    if (schema == null) return const {};
    if (schema is Map) return Map<String, Object?>.from(schema);
    // JsonSchema (and friends) serialize themselves.
    final toJson = (schema as dynamic).toJson;
    if (toJson is Function) {
      final json = toJson() as Map;
      return Map<String, Object?>.from(json);
    }
    return const {};
  }

  Future<T> _guard<T>(Future<T> Function() body, String fallbackMessage) async {
    try {
      return await body();
    } on mcp.UnauthorizedError catch (error) {
      throw McpAuthException(_describe(error, 'The MCP server rejected our credentials.'));
    } on mcp.McpError catch (error) {
      if (error.code == mcp.ErrorCode.requestTimeout.value) {
        throw McpTimeoutException('The MCP server took too long to respond.');
      }
      throw McpConnectionException(_describe(error, fallbackMessage));
    } catch (error) {
      throw McpConnectionException('$fallbackMessage $error');
    }
  }
```

**Implementation notes:**
- The exact signature of `client.listTools(params:)` (`ListToolsRequest` vs `ListToolsRequestParams`, and whether `cursor` is a named field) must be checked against the installed version; adjust the call, keep the public signature of `listTools()` unchanged.
- `tool.inputSchema`'s concrete type is the spec's flagged unknown: normalize whatever it is (a `Map`, or a `JsonSchema` with `toJson()`) into `Map<String, Object?>`.
- Refactor the Task 2 `connect()` body to use `_guard` too, so auth/timeout mapping lives in one place.

- [x] **Step 5: Run the new tests to verify they pass**

Run: `flutter test test/mcp_connection_test.dart test/mcp_connection_http_test.dart`
Expected: PASS.

- [x] **Step 6: Commit**

```bash
git add lib/mcp/mcp_connection.dart test/support/raw_mcp_server.dart test/mcp_connection_test.dart test/mcp_connection_http_test.dart
git commit -m "feat(mcp): list tools with pagination"
```

---

## Task 4: `callTool`, result mapping, and error mapping

**Files:**
- Modify: `lib/mcp/mcp_connection.dart`
- Modify: `test/mcp_connection_test.dart`
- Modify: `test/mcp_connection_http_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1–3.
- Produces: `Future<McpToolResult> McpConnection.callTool(String name, {Map<String, Object?>? arguments})`.

- [x] **Step 1: Write the failing `callTool` tests**

Append to `test/mcp_connection_test.dart`:

```dart
  test('callTool returns the text a tool produced', () async {
    final server = await TestMcpServer.start();
    server.registerEchoTool(name: 'echo', text: 'hello there');
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );
    await connection.connect();

    final result = await connection.callTool('echo', arguments: {'value': 'x'});

    expect(result.isError, isFalse);
    expect(result.text, 'hello there');

    await connection.disconnect();
    await server.close();
  });

  test('callTool before connect throws McpConnectionException', () async {
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );

    await expectLater(
      connection.callTool('echo'),
      throwsA(isA<McpConnectionException>()),
    );
  });
```

Add a tool that mixes blocks and one that fails. In `test/support/mcp_test_server.dart`, add:

```dart
  /// Registers a tool returning text, an image and more text.
  void registerMixedTool(String name) {
    _server.registerTool(
      name,
      description: 'Returns several content blocks.',
      inputSchema: JsonSchema.object(properties: {}),
      callback: (args, extra) async => CallToolResult(
        content: [
          const TextContent(text: 'before'),
          const ImageContent(data: 'AAAA', mimeType: 'image/png'),
          const TextContent(text: 'after'),
        ],
      ),
    );
  }

  /// Registers a tool that reports a business failure.
  void registerFailingTool(String name) {
    _server.registerTool(
      name,
      description: 'Always fails.',
      inputSchema: JsonSchema.object(properties: {}),
      callback: (args, extra) async => const CallToolResult(
        isError: true,
        content: [TextContent(text: 'no such record')],
      ),
    );
  }
```

Then append:

```dart
  test('callTool keeps non-text blocks without losing the text', () async {
    final server = await TestMcpServer.start();
    server.registerMixedTool('mixed');
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );
    await connection.connect();

    final result = await connection.callTool('mixed');

    expect(result.text, 'before\nafter');
    expect(result.content.map((block) => block.type), contains(McpContentType.image));

    await connection.disconnect();
    await server.close();
  });

  test('a tool-reported failure is a result, not an exception', () async {
    final server = await TestMcpServer.start();
    server.registerFailingTool('fails');
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );
    await connection.connect();

    final result = await connection.callTool('fails');

    expect(result.isError, isTrue);
    expect(result.text, 'no such record');

    await connection.disconnect();
    await server.close();
  });
```

Append to `test/mcp_connection_http_test.dart`:

```dart
  test('a JSON-RPC error from tools/call raises McpToolCallException', () async {
    final server = await RawMcpServer.start(
      handshakeThen((body) async {
        if (body['method'] == 'tools/call') {
          return CannedResponse(
            body: jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'error': {'code': -32601, 'message': 'Unknown tool'},
            }),
          );
        }
        return const CannedResponse(status: 202);
      }),
    );
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );
    await connection.connect();

    await expectLater(
      connection.callTool('nope'),
      throwsA(
        isA<McpToolCallException>()
            .having((e) => e.code, 'code', -32601)
            .having((e) => e.message, 'message', contains('Unknown tool')),
      ),
    );
    await connection.disconnect();
    await server.close();
  });

  test('a 401 during connect raises McpAuthException', () async {
    final server = await RawMcpServer.start(
      (body, request) async =>
          const CannedResponse(status: 401, body: 'unauthorized'),
    );
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );

    await expectLater(
      connection.connect(),
      throwsA(isA<McpAuthException>()),
    );
    await server.close();
  });

  test('a 500 during connect raises McpConnectionException', () async {
    final server = await RawMcpServer.start(
      (body, request) async => const CannedResponse(status: 500, body: 'boom'),
    );
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );

    await expectLater(
      connection.connect(),
      throwsA(isA<McpConnectionException>()),
    );
    await server.close();
  });

  test('configured headers are sent on every request', () async {
    late RawMcpServer server;
    server = await RawMcpServer.start(
      handshakeThen((body) async => CannedResponse(
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': body['id'],
          'result': {'content': [{'type': 'text', 'text': 'ok'}]},
        }),
      )),
    );
    final connection = McpConnection(
      config: McpConnectionConfig(
        endpoint: server.url,
        headers: const {'Authorization': 'Bearer secret', 'X-Client': 'thinai'},
      ),
    );
    await connection.connect();
    await connection.callTool('echo');

    for (final request in server.received) {
      expect(request.headers.value('authorization'), 'Bearer secret');
      expect(request.headers.value('x-client'), 'thinai');
    }
    await connection.disconnect();
    await server.close();
  });
```

- [x] **Step 2: Run the new tests to verify they fail**

Run: `flutter test test/mcp_connection_test.dart test/mcp_connection_http_test.dart`
Expected: FAIL — `The method 'callTool' isn't defined for the class 'McpConnection'`.

- [x] **Step 3: Implement `callTool` and content mapping**

Add to `McpConnection`:

```dart
  Future<McpToolResult> callTool(
    String name, {
    Map<String, Object?>? arguments,
  }) async {
    final client = _client;
    if (client == null) {
      throw const McpConnectionException('Not connected to an MCP server.');
    }
    final result = await _guard(
      () => client.callTool(
        mcp.CallToolRequest(name: name, arguments: arguments ?? const {}),
        options: mcp.RequestOptions(timeout: _config.requestTimeout),
      ),
      'Could not call the MCP tool.',
      duringToolCall: true,
    );
    return McpToolResult(
      isError: result.isError ?? false,
      content: result.content.map(_contentFrom).toList(),
      structuredContent: result.structuredContent == null
          ? null
          : Map<String, Object?>.from(result.structuredContent!),
    );
  }

  static McpContent _contentFrom(mcp.Content content) {
    final raw = Map<String, Object?>.from(content.toJson() as Map);
    return switch (content) {
      mcp.TextContent(:final text) => McpContent(
        type: McpContentType.text,
        text: text,
        raw: raw,
      ),
      mcp.ImageContent(:final data, :final mimeType) => McpContent(
        type: McpContentType.image,
        data: data,
        mimeType: mimeType,
        raw: raw,
      ),
      mcp.AudioContent(:final data, :final mimeType) => McpContent(
        type: McpContentType.audio,
        data: data,
        mimeType: mimeType,
        raw: raw,
      ),
      mcp.ResourceLink(:final uri, :final mimeType) => McpContent(
        type: McpContentType.resourceLink,
        uri: uri,
        mimeType: mimeType,
        raw: raw,
      ),
      _ => McpContent(type: McpContentType.other, raw: raw),
    };
  }
```

Update `_guard` so a tool-call `McpError` becomes `McpToolCallException`:

```dart
  Future<T> _guard<T>(
    Future<T> Function() body,
    String fallbackMessage, {
    bool duringToolCall = false,
  }) async {
    try {
      return await body();
    } on mcp.UnauthorizedError catch (error) {
      throw McpAuthException(_describe(error, 'The MCP server rejected our credentials.'));
    } on mcp.McpError catch (error) {
      if (error.code == mcp.ErrorCode.requestTimeout.value) {
        throw McpTimeoutException('The MCP server took too long to respond.');
      }
      final message = _describe(error, fallbackMessage);
      if (duringToolCall) {
        throw McpToolCallException(message: message, code: error.code);
      }
      throw McpConnectionException(message);
    } catch (error) {
      throw McpConnectionException('$fallbackMessage $error');
    }
  }
```

**Implementation notes:**
- `CallToolRequest.arguments`, `CallToolResult.isError` (nullable?), `structuredContent`, `Content.toJson()`, and the concrete content class names (`TextContent`, `ImageContent`, `AudioContent`, `ResourceLink`) must all be checked against the installed version; `ResourceLink` and `AudioContent` may not exist — drop or rename the arms to match, and keep the `_` default so unknown blocks never throw.
- `ImageContent.data` / `AudioContent.data` may be `String` or bytes; normalize to `String` (base64) and adjust the pattern accordingly.
- A `404` on a request carrying a session id (server expired the session) should surface as `McpConnectionException` with a message saying the session ended — the `_` catch in `_guard` already covers it; add a test only if the transport does not retry internally.

- [x] **Step 4: Run the callTool tests to verify they pass**

Run: `flutter test test/mcp_connection_test.dart test/mcp_connection_http_test.dart`
Expected: PASS.

- [x] **Step 5: Run the whole suite, analyzer, formatter, and the coverage gate**

```bash
dart format .
flutter analyze
flutter test --exclude-tags native --coverage
./tool/check_coverage.sh
```

Expected: formatting reports no changes needed; analyze reports no issues; tests pass; coverage prints `100.00%` and `PASS`. If `check_coverage.sh` names any `lib/mcp/` line as missed, add the test that reaches it (do not lower the gate).

- [x] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(mcp): call tools and map results and errors"
```

---

## Self-Review

**Spec coverage**

| Spec section | Task |
|---|---|
| §2 goal 1 — connect with static auth headers | Task 2 (headers wired; propagation pinned in Task 4) |
| §2 goal 2 — list tools with pagination | Task 3 |
| §2 goal 3 — call a tool, normalized result | Task 4 |
| §5 file layout and public API | Tasks 1–4 |
| §6 lifecycle, client identity, auth, negotiation, timeouts, pagination, no reconnect | Tasks 2–4 |
| §7 error table (all six rows) | Tasks 2–4 (401/500 in Task 4; timeout and JSON-RPC error in Task 4; repeated cursor in Task 3; not-connected in Tasks 3–4) |
| §8 two harnesses + `mcp_types_test` | Tasks 2 (real server), 3 (raw server), 1 (types) |
| §9 privacy, §10 Android | No code; PR description |
| §11 phases 2–4 | Explicitly out of scope |

**Placeholders:** the only loose ends are deliberate *implementation unknowns* the spec already flags (the exact `mcp_dart` method/type names, `inputSchema`'s concrete type). Every such spot names what to verify and the fallback, rather than saying "TBD".

**Type consistency:** `McpConnectionConfig`, `McpConnection`, `McpClientInfo`, `McpTool`, `McpContent`, `McpContentType`, `McpToolResult`, and the four exception types are defined once in Tasks 1–2 and used with the same names and shapes in Tasks 3–4.

**Review Focus:** all five inputs have a named test in the task cited next to them, plus the auth/timeout/JSON-RPC mapping assertions.

---

## Amendments after implementation

Written after the whole-branch review, so the next phase does not inherit these.

1. **Dependencies.** The Global Constraint said "add exactly one dependency".
   `meta` is also a direct dependency now (already transitive), for
   `@visibleForTesting` on the `mapContent` seam.
2. **Auth.** `McpConnectionConfig` carries `accessToken` rather than expecting an
   `Authorization` header in `headers`. A 401 with no token configured stays a
   `McpConnectionException` naming the status.
3. **Timeouts.** `requestTimeout` is applied to `listTools` as well — the Task 3
   snippet omitted `options:`, so the SDK's own 60s default leaked through — and
   to `connect`, which needs an explicit timeout because `McpClientOptions`
   exposes none.
4. **Session ids.** The Task 2 harness cannot establish a session: the server
   negotiates stateless `2026-07-28` and the transport strips session headers for
   stateless requests. Session behaviour is pinned instead through
   `RawMcpServer(sessionId:)`, which drives the legacy `initialize` path; that
   also covers `disconnect` issuing the session `DELETE`.
5. **Sealed content types.** The SDK's `Content.fromJson` rejects types it does
   not model, so the `McpContentType.other` arm is unreachable over the wire and
   is pinned through the `mapContent` seam instead of being left as dead code
   (which the 100% line-coverage gate would reject).
6. **Embedded resources.** `EmbeddedResource` is unwrapped to
   `uri`/`mimeType`/`data`, not just passed through as `raw`.
