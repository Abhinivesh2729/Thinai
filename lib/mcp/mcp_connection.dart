import 'dart:async';

import 'package:meta/meta.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;

import 'mcp_exceptions.dart';
import 'mcp_types.dart';

/// Where to reach an MCP server and how to authenticate to it.
class McpConnectionConfig {
  /// The MCP endpoint, e.g. `https://example.com/mcp`.
  final Uri endpoint;

  /// Extra headers sent on every request, e.g. `{'X-Client': 'Thinai'}`.
  final Map<String, String> headers;

  /// Static bearer token, when the server wants one.
  ///
  /// Sent as `Authorization: Bearer <token>` on every request. Supplying it
  /// also makes the transport treat an HTTP 401 as an auth failure rather than
  /// a generic protocol error, which is what lets [McpAuthException] be raised
  /// precisely.
  final String? accessToken;

  final Duration requestTimeout;

  McpConnectionConfig({
    required this.endpoint,
    this.headers = const {},
    this.accessToken,
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
///
/// Owns exactly one session: call [connect] before [listTools] or [callTool],
/// and [disconnect] when finished. Nothing here runs on its own — connecting is
/// the single point at which this module touches the network, so the eventual
/// consent gate belongs in front of [connect].
class McpConnection {
  McpConnection({
    required McpConnectionConfig config,
    McpClientInfo? clientInfo,
  }) : _config = config,
       _clientInfo = clientInfo ?? defaultClientInfo;

  /// What we tell a server we are, when the caller does not say.
  static const McpClientInfo defaultClientInfo = McpClientInfo(
    name: 'Thinai',
    version: '2.4.0',
  );

  final McpConnectionConfig _config;
  final McpClientInfo _clientInfo;

  mcp.McpClient? _client;

  /// Kept so [disconnect] can end a stateful session, which needs the concrete
  /// transport rather than the [Transport] interface.
  mcp.StreamableHttpClientTransport? _transport;

  bool get isConnected => _client != null;

  String? get serverName => _client?.getServerVersion()?.name;
  String? get serverVersion => _client?.getServerVersion()?.version;
  String? get protocolVersion => _client?.getProtocolVersion();

  /// Opens the session, negotiating protocol version and capabilities.
  ///
  /// Does nothing if already connected.
  Future<void> connect() async {
    if (_client != null) return;
    final client = mcp.McpClient(
      mcp.Implementation(name: _clientInfo.name, version: _clientInfo.version),
      options: mcp.McpClientOptions(protocol: mcp.McpProtocol.stable),
    );
    final transport = mcp.StreamableHttpClientTransport(
      _config.endpoint,
      opts: mcp.StreamableHttpClientTransportOptions(
        requestInit: {'headers': _config.headers},
        authProvider: switch (_config.accessToken) {
          final token? => _StaticTokenProvider(token),
          null => null,
        },
      ),
    );
    try {
      await _guard(
        () => client.connect(transport).timeout(_config.requestTimeout),
        'Could not reach the MCP server.',
      );
    } catch (_) {
      // Our timeout leaves the handshake running on the transport; close it so
      // a stalled server cannot leave a live connection behind.
      await client.close();
      rethrow;
    }
    _client = client;
    _transport = transport;
  }

  /// Ends the session. Safe to call more than once.
  ///
  /// A stateful server is told the session is over before the socket closes,
  /// because that is the only way the *server* learns to release it. A server
  /// that refuses — or already dropped it — is not a reason to fail.
  Future<void> disconnect() async {
    final client = _client;
    final transport = _transport;
    _client = null;
    _transport = null;
    if (transport != null) {
      try {
        await transport.terminateSession();
      } catch (_) {
        // Best effort: the connection is going away regardless.
      }
    }
    await client?.close();
  }

  /// The tools the server offers, following pagination to the end.
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
          options: mcp.RequestOptions(timeout: _config.requestTimeout),
        ),
        "Could not list the MCP server's tools.",
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
    inputSchema: Map<String, Object?>.from(tool.inputSchema.toJson()),
  );

  /// Calls a tool and normalizes what it returned.
  ///
  /// A tool that reports its own failure comes back as an [McpToolResult] with
  /// `isError` set, not as an exception — the caller (and, later, the model)
  /// gets to see what the tool said. Only protocol and transport failures
  /// throw.
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
        mcp.CallToolRequest(
          name: name,
          arguments: arguments == null
              ? const {}
              : Map<String, dynamic>.from(arguments),
        ),
        options: mcp.RequestOptions(timeout: _config.requestTimeout),
      ),
      'Could not call the MCP tool.',
      duringToolCall: true,
    );
    final structured = result.structuredContent;
    return McpToolResult(
      isError: result.isError,
      content: result.content.map(_contentFrom).toList(),
      structuredContent: structured == null
          ? null
          : Map<String, Object?>.from(structured),
    );
  }

  /// Maps one content block, keeping the server's original JSON in [McpContent.raw].
  ///
  /// Exhaustive over the protocol's content types. The SDK refuses unknown
  /// types at parse time, so a block it does not model can only be constructed
  /// directly — which is why [mapContent] exists for tests to pin the
  /// [McpContentType.other] mapping.
  static McpContent _contentFrom(mcp.Content content) {
    final raw = Map<String, Object?>.from(content.toJson());
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
        uri: Uri.tryParse(uri),
        mimeType: mimeType,
        raw: raw,
      ),
      mcp.EmbeddedResource(:final resource) => McpContent(
        type: McpContentType.resource,
        uri: Uri.tryParse(resource.uri),
        mimeType: resource.mimeType,
        // An inlined resource is either text or base64 bytes; text stays in
        // `raw` rather than being flattened into `data`, which is for bytes.
        data: switch (resource) {
          mcp.BlobResourceContents(:final blob) => blob,
          _ => null,
        },
        raw: raw,
      ),
      mcp.UnknownContent() => McpContent(type: McpContentType.other, raw: raw),
    };
  }

  /// Maps a single content block. Exposed so tests can pin the handling of
  /// blocks the SDK does not model, which a conforming server cannot send.
  @visibleForTesting
  static McpContent mapContent(mcp.Content content) => _contentFrom(content);

  /// Runs [body], translating MCP and transport failures into our exceptions.
  ///
  /// [duringToolCall] distinguishes a failed `tools/call` (a JSON-RPC error the
  /// caller may want to report per tool) from a failed connection.
  Future<T> _guard<T>(
    Future<T> Function() body,
    String fallbackMessage, {
    bool duringToolCall = false,
  }) async {
    try {
      return await body();
    } on McpException {
      // One of ours, already precise — never rewrap it.
      rethrow;
    } on TimeoutException {
      throw const McpTimeoutException(
        'The MCP server took too long to respond.',
      );
    } on mcp.McpError catch (error) {
      if (error.code == mcp.ErrorCode.requestTimeout.value) {
        throw const McpTimeoutException(
          'The MCP server took too long to respond.',
        );
      }
      final message = _describe(error.message, fallbackMessage);
      if (duringToolCall) {
        throw McpToolCallException(message: message, code: error.code);
      }
      throw McpConnectionException(message);
    } catch (error) {
      throw McpConnectionException('$fallbackMessage $error');
    }
  }

  /// A failure's own message when it has one worth showing, else [fallback].
  static String _describe(String message, String fallback) =>
      message.isEmpty ? fallback : message;
}

/// Presents a fixed bearer token to the transport.
///
/// This is the SDK's own hook for credentials, so the authorization header is
/// applied by the transport rather than by hand, and a server that rejects the
/// token is reported as an auth failure rather than a generic protocol error.
///
/// It is only supplied when a token exists: a provider that returns no token
/// makes the transport demand authorization before *every* request, which would
/// break servers that need none.
///
/// Nothing here participates in OAuth. There is no authorization server to send
/// the user to, so the redirect step reports the rejection and stops.
class _StaticTokenProvider implements mcp.OAuthClientProvider {
  _StaticTokenProvider(this.token);

  final String token;

  @override
  Future<mcp.OAuthTokens?> tokens() async =>
      mcp.OAuthTokens(accessToken: token);

  @override
  Future<void> redirectToAuthorization() async {
    throw const McpAuthException('The MCP server rejected our credentials.');
  }
}
