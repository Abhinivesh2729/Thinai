# 5. Server and API

Code: `lib/ui/pages/server_page.dart`, `lib/server/` (`api_server.dart`, `routes/ollama_routes.dart`, `routes/openai_routes.dart`, `routes/chat_format.dart`, `routes/embedding_format.dart`, `lan_address.dart`, `foreground_handler.dart`). Older reference: [docs/openai-api.md](../openai-api.md) (partly out of date, see [09-known-issues.md](09-known-issues.md#server-and-api)).

## 5.1 Server tab (seen on device)

| Section | What is on it |
|---|---|
| **Status card** | Dot + "Running"/"Stopped", port chip ":11434" (tap to change, only while stopped), the URL `http://127.0.0.1:11434` with a copy button, big **Start** (green) / **Stop** (red) button |
| **Serving model** | "SERVING MODEL <id>" + **Tune** (opens Model settings), or "No model loaded" + **Choose model** |
| **Share on LAN** | Switch: "This phone only" / "Devices on this Wi-Fi can connect". When on and running: the LAN URL and the **Token** row (masked, show, copy, regenerate). Turning it on/off restarts a running server |
| **Quick start** | Copyable samples in a code-editor style box. Tabs: **VS Code** (Continue `config.json`), **Python** (OpenAI SDK), **cURL**, **JSON** (request body), **Ollama** (`export OLLAMA_HOST=…`). Filled with the active model id |
| **API Endpoints** | 4 expandable rows with copy-cURL: `POST /v1/chat/completions`, `POST /api/chat`, `POST /v1/embeddings`, `GET /v1/models`. Each has curl / request / response samples |

There is no request log, client list, metrics or QR code.

**Port dialog:** "Server port", any value 1–65535, shortcut chips "11434 (Ollama)" and "8080". Applies on the next start.

**Start:** asks for notification permission (Android), starts the HTTP server, starts the background service. Toasts: "LAN is on, but no Wi-Fi address was found." or "Start failed: …" (e.g. port in use).

**Resume:** if the server was running when the app closed, it starts again on the next launch.

## 5.2 Network, auth, CORS

| | Behaviour |
|---|---|
| Port | 11434 by default (same as Ollama). User-settable |
| Bind | `127.0.0.1` only by default. `0.0.0.0` when LAN sharing is on. IPv4 only |
| Auth | **None on loopback** (any app on the device can call it). **Required in LAN mode:** `Authorization: Bearer <token>`. Wrong/missing → 401 `{"error":"unauthorized"}` |
| Token | 32 random bytes, base64url, created on the first LAN start, stored in app settings. "Regenerate token?" makes a new one and restarts the server |
| CORS | `*`; methods GET, POST, OPTIONS; headers Content-Type, Authorization. OPTIONS answers before auth |
| Root | `GET /` → "Thinai is running. See /api/tags or /v1/models." (seen on device) |
| Concurrency | Requests are accepted in parallel, but **generation runs one at a time** (FIFO queue shared with Chat). Embeddings do not wait in that queue |
| Client disconnect | Does **not** stop the generation |
| Model choice | By the request's `model` name = served id (file name, lower-case, no `.gguf`). Empty `model` → the alphabetically first installed file (not the active model) |

## 5.3 Endpoints

### Ollama-compatible

| Method & path | Request fields used | Response |
|---|---|---|
| `GET /api/tags` | — | `{models:[{name, model, modified_at, size, digest:"", details:{format:"gguf", family:"llama", …}}]}` (seen on device; `family` is always "llama") |
| `GET /api/ps` | — | The last model used by the engine |
| `POST /api/show` | `name` or `model` | Architecture, context length, layers, embedding size, and `thinai.context_cap` |
| `POST /api/generate` | `model`, `prompt`, `stream` (default **true**), `think`, `options.{num_ctx, temperature, top_k, top_p, num_predict, num_gpu, stop}` (also top-level `temperature`, `top_k`, `top_p`, `max_tokens`, `stop`) | NDJSON stream of `{model, created_at, response, done}`; the last line has `done_reason` and token counts/durations. `prompt` is sent as one user chat message (template applied) |
| `POST /api/chat` | Same as generate, plus `messages` and `tools` (no `tool_choice`) | NDJSON of `{message:{role, content}, done}`; tool calls on the last line with `arguments` as an object |
| `POST /api/embed` | `model`, `input` (string or array), `options.num_ctx` (default 8192), `options.num_gpu` | `{model, embeddings:[[…]], total_duration, prompt_eval_count}` |
| `POST /api/embeddings` | `model`, `prompt` (legacy) | `{embedding:[…]}` |

Ignored Ollama fields: `system`, `template`, `raw`, `context`, `images`, `format`, `keep_alive`, `suffix`. Missing endpoints: `/api/version`, `/api/pull`, `/api/delete`, `/api/copy`, `/api/create`.

### OpenAI-compatible

| Method & path | Request fields used | Response |
|---|---|---|
| `GET /v1/models` | — | `{object:"list", data:[{id, object:"model", created, owned_by:"local"}]}` (seen on device) |
| `POST /v1/chat/completions` | `model`, `messages`, `stream` (default **false**), `stream_options.include_usage`, `temperature`, `top_p`, `top_k`, `max_completion_tokens`/`max_tokens` (default unlimited), `stop` (≤ 4), `enable_thinking` or `chat_template_kwargs.enable_thinking`, `tools`, `tool_choice` (auto / none / required / a named function), `grammar` (GBNF, not with tools) | Standard `chat.completion` object with `usage` (seen on device). Streaming: SSE chunks, then `data: [DONE]` |
| `POST /v1/embeddings` | `model`, `input`, `encoding_format` (`float` or `base64`), `dimensions` (shortens and re-normalizes) | Standard embeddings list with `usage`. Context fixed at 2048 |

Ignored OpenAI fields: `n`, `seed`, penalties, `logit_bias`, `logprobs`, `response_format`, `user`. Missing: `/v1/completions`, `/v1/models/{id}`.

### Message format rules
- `content` may be a string or an array of parts (`text`, `input_text`, `output_text`).
- **Images:** `image_url` / `input_image` parts with a `data:image/...` URI only (no remote URLs). Rejected with 400 if the model has no vision support. Audio is always 400.
- Assistant `tool_calls` and `tool` messages are passed through. Unknown roles become `user`.

### Errors
| Code | When |
|---|---|
| 400 | Bad request fields, wrong embedding input, chat model used for embeddings ("no pooling layer") |
| 401 | LAN mode without the right bearer token |
| 404 | Unknown model or route |
| 500 | Engine failure, or any unexpected error (including malformed JSON). The body includes a stack trace |

OpenAI routes use `{"error":{"message","type"}}`; Ollama routes use `{"error":"…"}`. A failure mid-stream sends an error line/event and then ends the stream properly.

### Try it (from a computer, phone on USB/ADB)

```bash
adb forward tcp:11434 tcp:11434
```

```bash
curl http://127.0.0.1:11434/v1/chat/completions -H 'content-type: application/json' -d '{"model":"gemma-3-270m-it-q8_0","messages":[{"role":"user","content":"Say hi"}]}'
```

## 5.4 Background running

| Platform | Behaviour |
|---|---|
| Android | A foreground service (type `dataSync`) keeps the process alive while the server runs or a download is active. Notification: "Thinai server running / API at http://…:port", with a **Stop server** button. Holds wake and Wi-Fi locks |
| iOS | The server only runs while the app is open |
| Desktop | Not built yet. Needs a tray/menu-bar icon instead; see [10-desktop-prd.md](10-desktop-prd.md) |
