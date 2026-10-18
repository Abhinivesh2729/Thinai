import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/mcp/mcp_connection.dart';
import 'package:local_llm/mcp/mcp_exceptions.dart';
import 'package:local_llm/mcp/mcp_types.dart';
// Only for the unmodelled-content fallback, which cannot arrive over the wire.
import 'package:mcp_dart/mcp_dart.dart' show UnknownContent;

import 'support/mcp_test_server.dart';

void main() {
  late TestMcpServer server;

  setUp(() async {
    server = await TestMcpServer.start(
      configure: (mcp) {
        registerEchoTool(mcp, name: 'echo', text: 'hello there');
        registerMixedTool(mcp, 'mixed');
        registerFailingTool(mcp, 'fails');
        registerAudioTool(mcp, 'audio');
        registerResourceLinkTool(mcp, 'link');
        registerEmbeddedResourceTool(mcp, 'embedded');
        registerEmbeddedBlobTool(mcp, 'embedded-blob');
        registerStructuredTool(mcp, 'structured');
      },
    );
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

  test(
    'connect to an unreachable endpoint raises McpConnectionException',
    () async {
      // Port 1 is reserved and never listening.
      final connection = connectionFor(Uri.parse('http://127.0.0.1:1/mcp'));

      await expectLater(
        connection.connect(),
        throwsA(isA<McpConnectionException>()),
      );
    },
  );

  test('listTools returns the server tools with their schemas', () async {
    final connection = connectionFor(server.url);
    await connection.connect();

    final tools = await connection.listTools();

    expect(
      tools.map((tool) => tool.name),
      containsAll(<String>['echo', 'mixed', 'fails']),
    );
    expect(
      tools.firstWhere((tool) => tool.name == 'echo').inputSchema,
      isNotEmpty,
    );

    await connection.disconnect();
  });

  test('listTools before connect throws McpConnectionException', () async {
    final connection = connectionFor(server.url);

    await expectLater(
      connection.listTools(),
      throwsA(isA<McpConnectionException>()),
    );
  });

  test('callTool returns the text a tool produced', () async {
    final connection = connectionFor(server.url);
    await connection.connect();

    final result = await connection.callTool('echo', arguments: {'value': 'x'});

    expect(result.isError, isFalse);
    expect(result.text, 'hello there');

    await connection.disconnect();
  });

  test('callTool before connect throws McpConnectionException', () async {
    final connection = connectionFor(server.url);

    await expectLater(
      connection.callTool('echo'),
      throwsA(isA<McpConnectionException>()),
    );
  });

  test('callTool keeps non-text blocks without losing the text', () async {
    final connection = connectionFor(server.url);
    await connection.connect();

    final result = await connection.callTool('mixed');

    expect(result.text, 'before\nafter');
    expect(
      result.content.map((block) => block.type),
      contains(McpContentType.image),
    );
    expect(
      result.content.firstWhere((b) => b.type == McpContentType.image).mimeType,
      'image/png',
    );

    await connection.disconnect();
  });

  test('a tool-reported failure is a result, not an exception', () async {
    final connection = connectionFor(server.url);
    await connection.connect();

    final result = await connection.callTool('fails');

    expect(result.isError, isTrue);
    expect(result.text, 'no such record');

    await connection.disconnect();
  });

  test('callTool passes arguments through to the tool', () async {
    final connection = connectionFor(server.url);
    await connection.connect();

    // The echo tool's schema declares `value`; sending it must not be rejected.
    final result = await connection.callTool('echo', arguments: {'value': 'y'});

    expect(result.isError, isFalse);

    await connection.disconnect();
  });

  test('callTool maps an audio block', () async {
    final connection = connectionFor(server.url);
    await connection.connect();

    final result = await connection.callTool('audio');

    final block = result.content.single;
    expect(block.type, McpContentType.audio);
    expect(block.data, 'AAAA');
    expect(block.mimeType, 'audio/wav');

    await connection.disconnect();
  });

  test('callTool maps a resource link', () async {
    final connection = connectionFor(server.url);
    await connection.connect();

    final result = await connection.callTool('link');

    final block = result.content.single;
    expect(block.type, McpContentType.resourceLink);
    expect(block.uri, Uri.parse('https://example.com/notes.txt'));
    expect(block.mimeType, 'text/plain');

    await connection.disconnect();
  });

  test('callTool maps an embedded resource', () async {
    final connection = connectionFor(server.url);
    await connection.connect();

    final result = await connection.callTool('embedded');

    final block = result.content.single;
    expect(block.type, McpContentType.resource);
    expect(block.uri, Uri.parse('https://example.com/notes.txt'));
    expect(block.mimeType, 'text/plain');
    expect(block.data, isNull);
    expect(block.raw, contains('resource'));

    await connection.disconnect();
  });

  test('callTool maps an embedded binary resource', () async {
    final connection = connectionFor(server.url);
    await connection.connect();

    final result = await connection.callTool('embedded-blob');

    final block = result.content.single;
    expect(block.type, McpContentType.resource);
    expect(block.uri, Uri.parse('https://example.com/pixel.png'));
    expect(block.mimeType, 'image/png');
    expect(block.data, 'aGk=');

    await connection.disconnect();
  });

  test('a server answering with JSON rather than SSE still works', () async {
    final jsonServer = await TestMcpServer.start(
      jsonResponses: true,
      configure: (mcp) => registerEchoTool(mcp, name: 'echo', text: 'json'),
    );

    try {
      final connection = connectionFor(jsonServer.url);
      await connection.connect();

      final tools = await connection.listTools();
      final result = await connection.callTool('echo');

      expect(tools.map((tool) => tool.name), contains('echo'));
      expect(result.text, 'json');

      await connection.disconnect();
    } finally {
      await jsonServer.close();
    }
  });

  test('callTool keeps structured content', () async {
    final connection = connectionFor(server.url);
    await connection.connect();

    final result = await connection.callTool('structured');

    expect(result.structuredContent, {'count': 2});
    expect(result.text, '{"count":2}');

    await connection.disconnect();
  });

  test('a block the SDK does not model maps to other', () {
    // The SDK rejects unknown types before they reach us, so the fallback is
    // only reachable by constructing the block directly.
    final block = McpConnection.mapContent(const UnknownContent(type: 'video'));

    expect(block.type, McpContentType.other);
    expect(block.raw, containsPair('type', 'video'));
  });
}
