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
