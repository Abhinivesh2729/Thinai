import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/mcp/mcp_types.dart';

void main() {
  group('McpToolResult.text', () {
    test('joins text blocks with newlines', () {
      const result = McpToolResult(
        content: [
          McpContent(type: McpContentType.text, text: 'first'),
          McpContent(
            type: McpContentType.image,
            data: 'AAAA',
            mimeType: 'image/png',
          ),
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
