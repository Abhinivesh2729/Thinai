# OpenAI-compatible API

Thinai serves an OpenAI-compatible API next to its Ollama-compatible one. Both
are mounted on the same listener, so any OpenAI client library works by pointing
its base URL at the phone.

Implementation: [`lib/server/routes/openai_routes.dart`](../lib/server/routes/openai_routes.dart)
and [`lib/server/routes/chat_format.dart`](../lib/server/routes/chat_format.dart),
mounted in [`lib/server/api_server.dart`](../lib/server/api_server.dart).

## Base URL

| Mode | URL |
| --- | --- |
| Same device (default) | `http://127.0.0.1:11434/v1` |
| Share on local network | `http://<phone-lan-ip>:11434/v1` |

The port is editable on the Server page; `11434` is the default. Without LAN
mode the socket binds to `127.0.0.1`, so only apps on the same phone can reach
it.

## Authentication

**There is none.** `ApiServerConfig.bearerToken` exists and the middleware
enforces `Authorization: Bearer <token>` when it is set, but nothing in the app
ever sets it — every request is accepted. Clients that require an API key can
send any placeholder (`"not-needed"`); the header is ignored.

This is why LAN mode is a network-trust decision: anyone on the Wi-Fi can use
the models, list them, and run generation on the device.

CORS is wide open (`Access-Control-Allow-Origin: *`, methods `GET, POST,
OPTIONS`, headers `Content-Type, Authorization`), so browser-based clients work
without a proxy.

## Model IDs

A model's ID is its GGUF filename with the `.gguf` extension removed and
lowercased — e.g. `qwen2.5-1.5b-instruct-q4_k_m`. Lookup lowercases the incoming
name, so IDs are case-insensitive.

If `model` is omitted or empty, the request falls back to the **first model in
the models directory** rather than returning an error. Always send an explicit
`model` if more than one is installed.

## Endpoints

### `GET /v1/models`

```bash
curl http://127.0.0.1:11434/v1/models
```

```json
{
  "object": "list",
  "data": [
    {
      "id": "qwen2.5-1.5b-instruct-q4_k_m",
      "object": "model",
      "created": 1740384000,
      "owned_by": "local"
    }
  ]
}
```

`created` is the file's modification time in epoch seconds.

There is no `GET /v1/models/{id}` retrieve endpoint.

### `POST /v1/chat/completions`

```bash
curl http://127.0.0.1:11434/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen2.5-1.5b-instruct-q4_k_m",
    "messages": [
      {"role": "system", "content": "You are terse."},
      {"role": "user", "content": "Why is the sky blue?"}
    ]
  }'
```

```json
{
  "id": "chatcmpl-<uuid>",
  "object": "chat.completion",
  "created": 1740384000,
  "model": "qwen2.5-1.5b-instruct-q4_k_m",
  "choices": [
    {
      "index": 0,
      "message": {"role": "assistant", "content": "Rayleigh scattering."},
      "finish_reason": "stop"
    }
  ],
  "usage": {"prompt_tokens": 31, "completion_tokens": 4, "total_tokens": 35}
}
```

`usage` carries llama.cpp's own counts, taken from the timings it reports beside
each token. `prompt_tokens` counts what was actually processed, so a follow-up
turn served from the prompt cache reports fewer than the full prompt — the same
semantics as llama.cpp and Ollama.

`finish_reason` is `stop` (EOS or a stop sequence), `length` (hit `max_tokens`
or filled the context), or `tool_calls`.

#### Message content

`content` is a string or an array of content parts:

```json
{"role": "user", "content": [{"type": "text", "text": "Why is the sky blue?"}]}
```

Text parts (`text`, `input_text`, `output_text`) are concatenated. Unknown part
types are skipped. **Image and audio parts return `400`** — this build loads no
multimodal projector, so there is nothing to send them to.

#### Streaming

With `"stream": true` the response is `text/event-stream` in the standard OpenAI
chunk format:

```
data: {"id":"chatcmpl-…","object":"chat.completion.chunk","created":…,"model":"…","choices":[{"index":0,"delta":{"role":"assistant"},"finish_reason":null}]}

data: {"id":"chatcmpl-…",…,"choices":[{"index":0,"delta":{"content":"Rayleigh"},"finish_reason":null}]}

data: {"id":"chatcmpl-…",…,"choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}

data: [DONE]
```

- The first chunk carries `delta.role` and no content.
- Empty deltas are skipped rather than emitted as empty-content chunks.
- `stream_options: {"include_usage": true}` appends a final chunk with an empty
  `choices` array and a `usage` object, before `[DONE]`.

#### Tool calling

`tools` and `tool_choice` are passed to llama.cpp, which selects the chat
template's tool syntax and constrains sampling to it — the model can only emit a
well-formed call.

```bash
curl http://127.0.0.1:11434/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen2.5-1.5b-instruct-q4_k_m",
    "messages": [{"role": "user", "content": "Weather in Chennai?"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Current weather for a city",
        "parameters": {
          "type": "object",
          "properties": {"city": {"type": "string"}},
          "required": ["city"]
        }
      }
    }]
  }'
```

```json
{
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": null,
      "tool_calls": [{
        "id": "call_…",
        "type": "function",
        "function": {"name": "get_weather", "arguments": "{\"city\":\"Chennai\"}"}
      }]
    },
    "finish_reason": "tool_calls"
  }]
}
```

- `tool_choice` accepts `auto`, `none`, `required`, or
  `{"type": "function", "function": {"name": "..."}}` to pin one tool. Naming a
  tool that is not in `tools` is a `400`.
- Streaming emits standard `delta.tool_calls` fragments — `arguments` arrives
  split across chunks and concatenates, as with OpenAI.
- Ids are generated locally when the model does not supply one, so a `tool`
  reply always has something to reference.
- Send the result back as a `tool` message with its `tool_call_id`; the assistant
  turn carrying the original `tool_calls` must be in `messages` too, or the reply
  reads as an answer to nothing.

**Tool calling depends on the model's chat template.** A GGUF whose template has
no tool section cannot call tools no matter what is sent — the request still
works, the model just answers in prose.

#### Supported parameters

| Parameter | Behavior |
| --- | --- |
| `model` | Resolved case-insensitively; falls back to first installed model |
| `messages` | `role` + `content`; roles `system`, `assistant`, `tool`, `user` (unknown roles become `user`) |
| `stream` | `false` (default) or `true` |
| `stream_options` | `include_usage` appends a usage chunk |
| `temperature` | Default `0.7` |
| `top_p` | Default `1.0` |
| `max_tokens` / `max_completion_tokens` | Default `-1` (generate until EOS or the context fills) |
| `stop` | String or up to 4 strings. Output is cut before the match and the match is never emitted |
| `tools` / `tool_choice` | See above |

Numeric fields also accept numeric **strings** (`"0.7"`), which the spec does
not require but some clients send.

Still ignored: `n`, `seed`, `presence_penalty`, `frequency_penalty`,
`logit_bias`, `logprobs`, `response_format` (no JSON mode), `user`.

Context size is fixed at 8192 tokens and generation runs CPU-only
(`numGpuLayers: 0`) — neither is settable per request.

### `POST /v1/embeddings`

```bash
curl http://127.0.0.1:11434/v1/embeddings \
  -H 'Content-Type: application/json' \
  -d '{"model":"nomic-embed-text-v1.5-q5_k_m","input":"hello"}'
```

```json
{
  "object": "list",
  "data": [{"object": "embedding", "index": 0, "embedding": [0.01, -0.03]}],
  "model": "nomic-embed-text-v1.5-q5_k_m",
  "usage": {"prompt_tokens": 7, "total_tokens": 7}
}
```

| Parameter | Behavior |
| --- | --- |
| `input` | String or array of strings. Token-array input (`[[1,2,3]]`) is rejected with `400` — detokenizing would be a guess |
| `model` | Must be an **embedding** model; a chat model returns `400` |
| `encoding_format` | `float` (default) or `base64` (little-endian float32) |
| `dimensions` | Positive int, ≤ the model's native size. Truncates and re-normalizes (Matryoshka) |

Vectors are L2-normalized, so cosine similarity is a plain dot product. See the
[README](../README.md#embeddings) for why `dimensions` is only meaningful on
`nomic-embed-text-v1.5`.

## Errors

Errors use the OpenAI envelope, including uncaught ones on `/v1` routes:

```json
{"error": {"message": "model not found: llama-3", "type": "not_found"}}
```

| Status | When |
| --- | --- |
| `400` | Malformed `messages`, image/audio content, bad `tools` or `tool_choice`, more than 4 `stop` sequences, bad embedding `input` / `encoding_format` / `dimensions`, chat model used for embeddings |
| `404` | `model` names something not installed |
| `500` | Generation failed (ex. the prompt exceeds the context window) or an uncaught exception |

A generation that fails after the SSE stream has opened cannot change the status
code — `200` is already sent. It arrives as
`data: {"error":{"message":"…","type":"server_error"}}` followed by `data:
[DONE]`, so a client watching only for the sentinel still terminates.

## Compatibility matrix

| Feature | Status |
| --- | --- |
| `GET /v1/models` | ✅ |
| `POST /v1/chat/completions` | ✅ |
| `POST /v1/chat/completions` (SSE) | ✅ |
| `POST /v1/embeddings` | ✅ |
| Tool / function calling | ✅ Streaming and non-streaming; template-dependent |
| `content` parts arrays (text) | ✅ |
| `stop` sequences | ✅ Up to 4 |
| Usage accounting | ✅ Real counts, chat and embeddings |
| `finish_reason` | ✅ `stop` / `length` / `tool_calls` |
| `stream_options.include_usage` | ✅ |
| Bearer auth | ⚠️ Enforced only if a token is configured; the app never sets one |
| Vision / audio content parts | ❌ `400` — no multimodal projector in this build |
| JSON mode / `response_format` | ❌ Ignored |
| `n`, `seed`, penalties, `logprobs` | ❌ Ignored |
| Request cancellation | ❌ Closing the connection does not stop generation |
| `POST /v1/completions` (legacy) | ❌ Not routed (`404`) |
| `GET /v1/models/{id}` | ❌ Not routed (`404`) |
| `/v1/audio/*`, `/v1/images/*`, `/v1/files`, Assistants, Responses API | ❌ Not implemented |

## Concurrency

`LlmEngine` runs a single job queue — one generation at a time. Concurrent chat
requests are serialized, not parallelized, and a second request waits for the
first to finish rather than failing. Embeddings use a separate llama context, so
they do not evict the chat model.

## Client examples

### Python (`openai`)

```python
from openai import OpenAI

client = OpenAI(base_url="http://127.0.0.1:11434/v1", api_key="not-needed")

resp = client.chat.completions.create(
    model="qwen2.5-1.5b-instruct-q4_k_m",
    messages=[{"role": "user", "content": "Why is the sky blue?"}],
    stream=True,
)
for chunk in resp:
    print(chunk.choices[0].delta.content or "", end="")
```

### Node (`openai`)

```js
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "http://127.0.0.1:11434/v1",
  apiKey: "not-needed",
});

const r = await client.chat.completions.create({
  model: "qwen2.5-1.5b-instruct-q4_k_m",
  messages: [{ role: "user", content: "Why is the sky blue?" }],
});
console.log(r.choices[0].message.content);
```

### Open WebUI / LibreChat

Add an OpenAI-compatible connection with base URL
`http://<phone-lan-ip>:11434/v1` and any non-empty API key. Requires LAN mode on
the Server page.
