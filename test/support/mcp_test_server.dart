import 'dart:io';

import 'package:mcp_dart/mcp_dart.dart';

/// A real MCP server, served over loopback HTTP on an ephemeral port.
///
/// The client under test therefore speaks the actual protocol, over an actual
/// socket, without touching the network or mocking our own code. Test-only, so
/// importing the MCP package here is fine — `lib/` code may not.
///
/// Tools must be registered from [configure], which runs before the server
/// connects to its transport: the SDK refuses to register tool handlers once
/// connected.
class TestMcpServer {
  TestMcpServer._(this._http, this._server, this.url);

  final HttpServer _http;
  final McpServer _server;
  final Uri url;

  static Future<TestMcpServer> start({
    void Function(McpServer server)? configure,
    bool jsonResponses = false,
  }) async {
    final server = McpServer(
      const Implementation(name: 'test-server', version: '9.9.9'),
      options: const McpServerOptions(
        capabilities: ServerCapabilities(tools: ServerCapabilitiesTools()),
      ),
    );
    configure?.call(server);

    final transport = StreamableHTTPServerTransport(
      options: StreamableHTTPServerTransportOptions(
        // A stateless-2026 server here; sessions only exist on legacy servers,
        // which the raw harness covers.
        sessionIdGenerator: null,
        enableJsonResponse: jsonResponses,
        // The server is bound to loopback on an ephemeral port; host allowlists
        // would only get in the way of the test.
        enableDnsRebindingProtection: false,
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

  Future<void> close() async {
    await _server.close();
    await _http.close(force: true);
  }
}

/// Registers a tool that returns a single text block.
void registerEchoTool(
  McpServer server, {
  required String name,
  String text = 'ok',
}) {
  server.registerTool(
    name,
    description: 'Returns a fixed string.',
    inputSchema: JsonSchema.object(properties: {'value': JsonSchema.string()}),
    callback: (args, extra) async =>
        CallToolResult(content: [TextContent(text: text)]),
  );
}

/// Registers a tool returning text, an image, then more text.
void registerMixedTool(McpServer server, String name) {
  server.registerTool(
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
void registerFailingTool(McpServer server, String name) {
  server.registerTool(
    name,
    description: 'Always fails.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async => const CallToolResult(
      isError: true,
      content: [TextContent(text: 'no such record')],
    ),
  );
}

/// Registers a tool returning an embedded blob resource.
void registerEmbeddedBlobTool(McpServer server, String name) {
  server.registerTool(
    name,
    description: 'Embeds a binary resource.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async => const CallToolResult(
      content: [
        EmbeddedResource(
          resource: BlobResourceContents(
            uri: 'https://example.com/pixel.png',
            mimeType: 'image/png',
            blob: 'aGk=',
          ),
        ),
      ],
    ),
  );
}

/// Registers a tool returning object-root structured content.
void registerStructuredTool(McpServer server, String name) {
  server.registerTool(
    name,
    description: 'Returns structured content.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async => const CallToolResult(
      content: [TextContent(text: '{"count":2}')],
      structuredContent: {'count': 2},
    ),
  );
}

/// Registers a tool returning an audio block.
void registerAudioTool(McpServer server, String name) {
  server.registerTool(
    name,
    description: 'Returns audio.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async => const CallToolResult(
      content: [AudioContent(data: 'AAAA', mimeType: 'audio/wav')],
    ),
  );
}

/// Registers a tool returning a link to a resource it does not inline.
void registerResourceLinkTool(McpServer server, String name) {
  server.registerTool(
    name,
    description: 'Links a resource.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async => const CallToolResult(
      content: [
        ResourceLink(
          uri: 'https://example.com/notes.txt',
          name: 'notes.txt',
          mimeType: 'text/plain',
        ),
      ],
    ),
  );
}

/// Registers a tool returning an embedded resource.
void registerEmbeddedResourceTool(McpServer server, String name) {
  server.registerTool(
    name,
    description: 'Embeds a resource.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async => const CallToolResult(
      content: [
        EmbeddedResource(
          resource: TextResourceContents(
            uri: 'https://example.com/notes.txt',
            mimeType: 'text/plain',
            text: 'hi',
          ),
        ),
      ],
    ),
  );
}
