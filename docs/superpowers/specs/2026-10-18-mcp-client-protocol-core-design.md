# MCP Client — Protocol Core (Phase 1) Design

**Date:** 2026-10-18
**Issue:** [Abhinivesh2729/Thinai#15 — Add MCP (Model Context Protocol) support](https://github.com/Abhinivesh2729/Thinai/issues/15)
**Status:** Approved (design), pending written-spec review

## 1. Problem and context

Thinai is an offline-first Android app that runs GGUF models locally and exposes an
Ollama/OpenAI-compatible API. Issue #15 asks for MCP support: connect to MCP servers,
let users manage them, and feed their tool schemas into the chat tool-calling flow.

This document specifies **phase 1 only**: the MCP *protocol core* — a Dart client that can
talk to a remote MCP server over Streamable HTTP, list its tools, and call them. It has no
UI, no persistence, and no chat integration; those are separate phases with their own specs.

### What already exists (and constrains the design)

- **Tool calling already exists at the engine layer.** `lib/llm/llm_engine.dart` exposes
  `ToolSpec { name, description, parameters }` (OpenAI `tools[].function` shape) and
  `chat(..., {List<ToolSpec> tools, String? toolChoice})`. llama.cpp constrains sampling to
  the template's tool syntax and streams `toolCallDeltas` / final `toolCalls` with
  `finishReason: 'tool_calls'`. The `/v1/chat/completions` route already accepts `tools` and
  `tool_choice` from external clients. The app's own chat UI simply never passes tools.
  Phase 1 therefore does **not** need new inference plumbing — it needs a well-typed source
  of tools that phase 3 will map onto `ToolSpec`.
- **Network-feature precedent:** `lib/web/web_search.dart` with `WebSearchController`
  (Riverpod `StateNotifier` over `SharedPreferences`) and a user-facing toggle. Its exception
  style (`WebSearchException` with short, human-readable messages) is mirrored here.
- **CI enforces 100% line coverage** (`tool/check_coverage.sh`) plus `dart format` and
  `flutter analyze` on changed files. Every line of new `lib/` code must be exercised by
  tests.
- Android cannot spawn subprocesses, so **stdio is not viable**. Remote **Streamable HTTP**
  (MCP `2025-06-18` and later) is the practical transport. The issue's "HTTP/SSE" phrasing
  refers to the deprecated 2024-11-05 two-endpoint SSE transport, which Streamable HTTP
  supersedes while still using SSE for streamed responses.

## 2. Goal

A self-contained, fully-unit-tested library that can:

1. Connect to an MCP server over Streamable HTTP, with optional static auth headers.
2. List the server's tools, following pagination.
3. Call a tool with arguments and return a normalized result.

Nothing outside the module changes, and nothing in the app calls it yet.

## 3. Non-goals (explicit)

Phase 1 ships **no** settings UI, persistence, secure token storage, Riverpod providers,
consent flow, chat/`ToolSpec` wiring, resources, prompts, notifications, OAuth, stdio
transport, MCP *server*, auto-reconnect, or multi-server connection registry. The only
observable change to the app is a new dependency and a new `lib/mcp/` module.

## 4. Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Build vs. depend | Depend on `mcp_dart: ^2.4.3` | MIT, pub 160/160 points, active (published 2026-10-14), wraps the full protocol including version negotiation. Hand-rolling buys nothing here. |
| New transitive deps | None | `mcp_dart` needs `crypto ^3.0.7`, `http ^1.5.0`, `meta ^1.16.0`; the lockfile already pins `crypto 3.0.7`, `http 1.6.0`, `meta 1.19.0`. Adding `mcp_dart` pulls in **no new packages**. |
| Interface types | Own normalized types | No file outside `lib/mcp/mcp_connection.dart` imports `mcp_dart`. Callers and tests depend only on our types; the dependency can be swapped or dropped in one file. |
| Protocol surface | Tools only | Matches the issue's core need. Resources/prompts are later phases. |
| Auth | Static bearer token + custom headers | Covers API-key MCP endpoints cheaply. OAuth 2.1 is a later phase. |

### Alternatives considered

- **Hand-rolled JSON-RPC + Streamable HTTP client.** Rejected: reimplements version
  negotiation, session handling, SSE framing, and OAuth hooks that `mcp_dart` already
  provides and maintains.
- **Pass `mcp_dart` types straight through.** Rejected: couples every caller and test to the
  package's types and error shapes.
- **A `McpProtocolClient` layer beneath `McpConnection`.** Rejected: `mcp_dart` *is* that
  layer; wrapping it twice adds indirection with no benefit.
- **A multi-server session registry in phase 1.** Rejected: that is phase 2's concern.

## 5. Architecture

```
lib/mcp/
  mcp_types.dart       Value types: McpClientInfo, McpTool, McpToolResult, McpContent(+Type)
  mcp_exceptions.dart  McpException and its subtypes
  mcp_connection.dart  McpConnectionConfig + McpConnection (the only file importing mcp_dart)

test/
  mcp_types_test.dart            Pure type behaviour (text joining, content mapping)
  mcp_connection_test.dart       Our client vs. a real mcp_dart server over loopback HTTP
  mcp_connection_http_test.dart  Our client vs. a raw HttpServer returning canned responses
```

Data flow: caller builds a `McpConnectionConfig` → `McpConnection.connect()` negotiates with
the server → `listTools()` / `callTool()` map `mcp_dart` results into our types →
`disconnect()` ends the session.

### Public API

```dart
// mcp_types.dart
class McpClientInfo {
  final String name;
  final String version;
}

class McpTool {
  final String name;
  final String? description;
  final Map<String, Object?> inputSchema; // {} when the server omits it
}

enum McpContentType { text, image, audio, resourceLink, resource, other }

class McpContent {
  final McpContentType type;
  final String? text;        // text blocks
  final String? data;        // image/audio base64, resource blob
  final String? mimeType;
  final Uri? uri;            // resource links / embedded resources
  final Map<String, Object?> raw; // the server's original JSON for this block
}

class McpToolResult {
  final bool isError;                        // tool-reported failure, not a protocol error
  final List<McpContent> content;
  final Map<String, Object?>? structuredContent;
  String get text;                           // text blocks joined by '\n'
}

// mcp_exceptions.dart
sealed class McpException implements Exception { String get message; }
class McpConnectionException extends McpException { ... }  // connect/transport/protocol failure
class McpAuthException       extends McpException { ... }  // 401 / UnauthorizedError
class McpTimeoutException    extends McpException { ... }  // request timeout
class McpToolCallException   extends McpException { final int? code; ... } // JSON-RPC error

// mcp_connection.dart
class McpConnectionConfig {
  final Uri endpoint;                 // http or https; validated in the constructor
  final Map<String, String> headers;  // arbitrary extra headers, e.g. {'X-Client': '…'}
  final String? accessToken;          // sent as `Authorization: Bearer …` when set
  final Duration requestTimeout;      // default 30s
}

class McpConnection {
  McpConnection({required McpConnectionConfig config, McpClientInfo? clientInfo});

  bool get isConnected;
  String? get serverName;
  String? get serverVersion;
  String? get protocolVersion;

  Future<void> connect();
  Future<void> disconnect();                       // idempotent
  Future<List<McpTool>> listTools();               // follows nextCursor
  Future<McpToolResult> callTool(String name, {Map<String, Object?>? arguments});
}
```

## 6. Behaviour

- **Lifecycle.** `connect()` is explicit. `listTools()` / `callTool()` before a successful
  connect throw `McpConnectionException('Not connected to an MCP server.')`.
  `disconnect()` is idempotent and always closes the session transport (which sends the
  session `DELETE` where the server allows it).
- **Client identity.** `McpClientInfo` defaults to `Thinai` / the app version, sent in the
  MCP `initialize` request.
- **Auth and headers.** `config.headers` are attached to every request through
  `StreamableHttpClientTransportOptions.requestInit['headers']`. When
  `config.accessToken` is set it is presented through the SDK's own credential
  hook (`OAuthClientProvider`), which is what makes the transport apply the
  bearer header and what lets an HTTP 401 be distinguished from an unreachable
  server. The provider is supplied only when a token exists: one that returns no
  token makes the transport demand authorization before *every* request. No
  OAuth in phase 1.
- **Version negotiation.** We pass `McpProtocol.stable`; whatever version the server
  negotiates is read back and exposed via `protocolVersion`. We never pin a version
  ourselves, so newer server revisions work without changes.
- **Timeouts.** `config.requestTimeout` bounds every request: `listTools` and
  `callTool` through `RequestOptions(timeout:)`, and `connect` through an
  explicit timeout on the handshake, which the SDK's options do not expose. The
  default is 30s, against the SDK's own 60s default.
- **Pagination.** `listTools()` loops while `nextCursor != null`. A repeated cursor throws
  `McpConnectionException` rather than looping forever.
- **No reconnect.** `mcp_dart`'s SSE reconnection options keep their defaults.

## 7. Error handling

A tool-reported failure is **not** an exception: when the server returns
`CallToolResult.isError == true` (bad arguments, business failure) that is a valid
`McpToolResult` the model can react to in phase 3. Only protocol and transport failures
throw.

| Condition | Thrown |
|---|---|
| Connect/transport failure, non-2xx, malformed body, not connected | `McpConnectionException` |
| HTTP 401 when a token is configured and rejected | `McpAuthException` |
| HTTP 401 when no token is configured | `McpConnectionException` whose message names the status — the transport only reports the code, and matching on that text would break silently on an SDK reword |
| `McpError` with `ErrorCode.requestTimeout` | `McpTimeoutException` |
| Any other `McpError` from `callTool` (`methodNotFound`, `invalidParams`, …) | `McpToolCallException(code, message)` |
| Any other `McpError` during connect/list | `McpConnectionException` |
| Repeated `nextCursor` from `tools/list` | `McpConnectionException` |

Messages are one short sentence, user-safe enough to show in a toast in phase 2, styled after
`WebSearchException`.

## 8. Testing strategy

Two harnesses, both running against real code paths so every branch in `lib/mcp/` is
reachable (the CI gate is 100% line coverage).

1. **Real MCP server over loopback HTTP** (`mcp_connection_test.dart`). A helper binds a
   `dart:io` `HttpServer` on `127.0.0.1:0`, wires it to `mcp_dart`'s
   `StreamableHTTPServerTransport` (`transport.handleRequest(request)`), and backs it with a
   real `McpServer` with registered tools. Our `McpConnection` then connects to
   `http://127.0.0.1:<port>/mcp`. This exercises `initialize`/negotiation, `tools/list`,
   `tools/call`, text and multi-block results, `isError` results, session id handling, and
   `disconnect`. The ephemeral port keeps tests parallel-safe.
2. **Raw HTTP server with canned responses** (`mcp_connection_http_test.dart`). A raw
   `dart:io` `HttpServer` returns hand-written JSON-RPC / SSE bodies. This covers what a
   well-behaved server cannot produce: pagination via `nextCursor` and the repeated-cursor
   guard, JSON vs. `text/event-stream` responses, header propagation (`Authorization`,
   custom headers, `MCP-Protocol-Version`), 401 → `McpAuthException`, 500, truncated/
   malformed bodies → `McpConnectionException`, JSON-RPC error objects →
   `McpToolCallException`/`McpTimeoutException`.

`mcp_types_test.dart` covers the pure type behaviour: `McpToolResult.text` joining and empty
case, content-type mapping, and `inputSchema` defaults.

Verification before the PR: `dart format .`, `flutter analyze`, and
`flutter test --exclude-tags native --coverage` followed by `./tool/check_coverage.sh`, all
clean.

### Implementation unknowns (resolved during implementation)

- `Tool.inputSchema` is a `JsonSchema`; `toJson()` normalizes it to a map.
- `StreamableHttpClientTransportOptions` exposes no injectable `http.Client`, so
  the loopback-server harness carries the HTTP-level cases.
- `Content.fromJson` **rejects** content types the SDK does not model, so a
  server cannot in practice send one. The `McpContentType.other` fallback is
  therefore unreachable over the wire and is pinned by a test through a
  `@visibleForTesting` seam rather than being left as dead code.

## 9. Privacy and security

`connect()` is the single network egress point of this module. Phase 1 has no callers, so
nothing connects on its own — but the eventual consent gate belongs to phase 2, and the PR
description should say so explicitly rather than leave it looking like an oversight.

A stored bearer token is a secret: phase 2 must keep it out of plain `SharedPreferences`
(which the app currently uses for preferences) and in platform secure storage. Phase 1 only
passes headers through in memory and persists nothing.

## 10. Android notes

`INTERNET` is already declared and `android:usesCleartextTraffic="true"` is already set, so
both `https://` remote endpoints and `http://127.0.0.1:` local endpoints work. **No manifest
change is required.**

## 11. Follow-up phases (out of scope here)

- **Phase 2 — server registry and UI.** Persist configured servers, store tokens in secure
  storage, add/enable/disable in Settings behind an explicit consent prompt, expose
  connection state through Riverpod providers, and gate `connect()` on user consent.
- **Phase 3 — chat integration.** Map `McpTool` → `ToolSpec`, pass enabled servers' tools to
  `LlmEngine.chat`, run the tool-call loop, return results to the model, and require a
  per-tool permission prompt.
- **Phase 4 — Thinai as an MCP server.** Expose the on-device model via MCP alongside the
  existing OpenAI/Ollama routes (`lib/server/`, `lib/ui/pages/server_page.dart`).

## 12. Risks

- **Test-harness complexity.** Wiring `mcp_dart`'s server transport to a `dart:io` server is
  the one piece with no precedent in this repo. It is a test-only concern; if it proves
  awkward, the fallback is the in-memory `IOStreamTransport` behind a test-only seam in
  `mcp_connection.dart`.
- **Dependency drift.** `mcp_dart` moves fast (2.4.3 published days ago). Types are pinned at
  `^2.4.3`; a future breaking change is contained to `mcp_connection.dart` by the normalized-
  types decision.
- **Protocol drift.** MCP revisions are moving quickly; using `McpProtocol.stable` and
  reading back the negotiated version avoids pinning an obsolete one.
