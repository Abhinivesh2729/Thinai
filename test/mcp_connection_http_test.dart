import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/mcp/mcp_connection.dart';
import 'package:local_llm/mcp/mcp_exceptions.dart';

import 'support/raw_mcp_server.dart';

String _toolsList(Object? id, List<String> names, {String? nextCursor}) =>
    RawMcpServer.jsonRpcResult(id, {
      'tools': [
        for (final name in names)
          {
            'name': name,
            'description': 'd',
            'inputSchema': {'type': 'object'},
          },
      ],
      'nextCursor': ?nextCursor,
    });

void main() {
  test('listTools follows pagination across pages', () async {
    var page = 0;
    final server = await RawMcpServer.start((body, request) async {
      if (body['method'] == 'tools/list') {
        page++;
        return CannedResponse(
          body: page == 1
              ? _toolsList(body['id'], ['a'], nextCursor: 'page-2')
              : _toolsList(body['id'], ['b']),
        );
      }
      return const CannedResponse(status: 202);
    });

    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );
    await connection.connect();

    final tools = await connection.listTools();

    expect(tools.map((tool) => tool.name), ['a', 'b']);
    expect(page, 2);

    await connection.disconnect();
    await server.close();
  });

  test(
    'listTools stops with McpConnectionException on a repeated cursor',
    () async {
      final server = await RawMcpServer.start((body, request) async {
        if (body['method'] == 'tools/list') {
          return CannedResponse(
            body: _toolsList(body['id'], ['a'], nextCursor: 'same'),
          );
        }
        return const CannedResponse(status: 202);
      });

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
    },
  );

  test(
    'a JSON-RPC error from tools/call raises McpToolCallException',
    () async {
      final server = await RawMcpServer.start((body, request) async {
        if (body['method'] == 'tools/call') {
          return CannedResponse(
            body: RawMcpServer.jsonRpcError(body['id'], -32601, 'Unknown tool'),
          );
        }
        return const CannedResponse(status: 202);
      });

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
    },
  );

  test('a 401 during connect raises McpAuthException', () async {
    final server = await RawMcpServer.start(
      (body, request) async =>
          const CannedResponse(status: 401, body: 'unauthorized'),
      handshake: false,
    );
    final connection = McpConnection(
      config: McpConnectionConfig(
        endpoint: server.url,
        accessToken: 'stale-token',
      ),
    );

    await expectLater(connection.connect(), throwsA(isA<McpAuthException>()));

    await server.close();
  });

  test('a 401 with no token configured reports the status', () async {
    final server = await RawMcpServer.start(
      (body, request) async =>
          const CannedResponse(status: 401, body: 'unauthorized'),
      handshake: false,
    );
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );

    // Without a token there is no provider, so the transport only reports the
    // status. The message must still name it, or a user cannot tell a missing
    // credential from an unreachable server.
    await expectLater(
      connection.connect(),
      throwsA(
        isA<McpConnectionException>().having(
          (e) => e.message,
          'message',
          contains('401'),
        ),
      ),
    );

    await server.close();
  });

  test('a 500 during connect raises McpConnectionException', () async {
    final server = await RawMcpServer.start(
      (body, request) async => const CannedResponse(status: 500, body: 'boom'),
      handshake: false,
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
    final server = await RawMcpServer.start((body, request) async {
      return CannedResponse(
        body: RawMcpServer.jsonRpcResult(body['id'], {
          'content': [
            {'type': 'text', 'text': 'ok'},
          ],
        }),
      );
    });
    final connection = McpConnection(
      config: McpConnectionConfig(
        endpoint: server.url,
        accessToken: 'secret',
        headers: const {'X-Client': 'thinai'},
      ),
    );
    await connection.connect();
    await connection.callTool('echo');

    expect(server.received, isNotEmpty);
    for (final request in server.received) {
      expect(request.headers.value('authorization'), 'Bearer secret');
      expect(request.headers.value('x-client'), 'thinai');
    }

    await connection.disconnect();
    await server.close();
  });

  test('a slow tool call raises McpTimeoutException', () async {
    final server = await RawMcpServer.start((body, request) async {
      if (body['method'] == 'tools/call') {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      return CannedResponse(
        body: RawMcpServer.jsonRpcResult(body['id'], {
          'content': [
            {'type': 'text', 'text': 'late'},
          ],
        }),
      );
    });

    final connection = McpConnection(
      config: McpConnectionConfig(
        endpoint: server.url,
        requestTimeout: const Duration(milliseconds: 50),
      ),
    );
    await connection.connect();

    await expectLater(
      connection.callTool('slow'),
      throwsA(isA<McpTimeoutException>()),
    );

    await connection.disconnect();
    await server.close();
  });

  test('listTools honours the configured request timeout', () async {
    final server = await RawMcpServer.start((body, request) async {
      if (body['method'] == 'tools/list') {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      return CannedResponse(
        body: RawMcpServer.jsonRpcResult(body['id'], {'tools': []}),
      );
    });
    final connection = McpConnection(
      config: McpConnectionConfig(
        endpoint: server.url,
        requestTimeout: const Duration(milliseconds: 50),
      ),
    );
    await connection.connect();

    await expectLater(
      connection.listTools(),
      throwsA(isA<McpTimeoutException>()),
    );

    await connection.disconnect();
    await server.close();
  });

  test('connect honours the configured request timeout', () async {
    final server = await RawMcpServer.start((body, request) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return const CannedResponse(status: 200);
    }, handshake: false);
    final connection = McpConnection(
      config: McpConnectionConfig(
        endpoint: server.url,
        requestTimeout: const Duration(milliseconds: 50),
      ),
    );

    await expectLater(
      connection.connect(),
      throwsA(isA<McpTimeoutException>()),
    );

    await server.close();
  });

  test(
    'the session id from initialization is sent on later requests',
    () async {
      final server = await RawMcpServer.start(
        (body, request) async => CannedResponse(
          body: RawMcpServer.jsonRpcResult(body['id'], {'tools': []}),
        ),
        sessionId: 'sess-1',
      );
      final connection = McpConnection(
        config: McpConnectionConfig(endpoint: server.url),
      );
      await connection.connect();
      await connection.listTools();

      final index = server.methods.indexOf('tools/list');
      expect(index, isNonNegative);
      expect(server.received[index].headers.value('mcp-session-id'), 'sess-1');

      await connection.disconnect();
      await server.close();
    },
  );

  test('a 404 on a live session surfaces as a connection error', () async {
    final server = await RawMcpServer.start((body, request) async {
      if (body['method'] == 'tools/list') {
        return const CannedResponse(status: 404, body: 'session gone');
      }
      return const CannedResponse(status: 200);
    }, sessionId: 'sess-1');
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

  test('disconnect terminates the session', () async {
    final server = await RawMcpServer.start(
      (body, request) async => const CannedResponse(status: 200),
      sessionId: 'sess-1',
    );
    final connection = McpConnection(
      config: McpConnectionConfig(endpoint: server.url),
    );
    await connection.connect();

    await connection.disconnect();

    final deletes = server.received
        .where((request) => request.method == 'DELETE')
        .toList();
    expect(deletes, hasLength(1));
    expect(deletes.single.headers.value('mcp-session-id'), 'sess-1');

    await server.close();
  });

  test(
    'disconnect tolerates a server that refuses to end the session',
    () async {
      final server = await RawMcpServer.start(
        (body, request) async => request.method == 'DELETE'
            ? const CannedResponse(status: 500, body: 'cannot terminate')
            : const CannedResponse(status: 200),
        sessionId: 'sess-1',
      );
      final connection = McpConnection(
        config: McpConnectionConfig(endpoint: server.url),
      );
      await connection.connect();

      await connection.disconnect();

      expect(connection.isConnected, isFalse);
      await server.close();
    },
  );
}
