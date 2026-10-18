/// Value types for the MCP client.
///
/// These are deliberately owned by the app rather than re-exported from the
/// `mcp_dart` package, so callers and tests never depend on its types and the
/// dependency can be swapped in one file.
library;

/// Identity this client reports to an MCP server during initialization.
class McpClientInfo {
  final String name;
  final String version;

  const McpClientInfo({required this.name, required this.version});
}

/// A tool an MCP server offers.
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

/// Which kind of content block a tool result carried.
enum McpContentType { text, image, audio, resourceLink, resource, other }

/// One content block from a tool result.
///
/// [raw] keeps the server's original JSON for this block so nothing is lost for
/// callers that need fields this type does not model.
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
/// [isError] is the server reporting that the tool itself failed — bad
/// arguments, a business error. That is a result the model can see and correct
/// against, not an exception.
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
