/// Exceptions thrown by the MCP client.
///
/// Messages are short and safe to show a user, in the same style as the web
/// search feature's `WebSearchException`.
library;

/// Base for everything this module throws.
sealed class McpException implements Exception {
  final String message;

  const McpException(this.message);

  @override
  String toString() => message;
}

/// The connection could not be established, or the transport/protocol failed.
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
