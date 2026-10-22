# Thinai

[![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FAbhinivesh2729/Thinai%2Fmain%2Fpubspec.yaml&query=%24.version&label=version&color=blue)](pubspec.yaml)
[![CI](https://github.com/Abhinivesh2729/Thinai/actions/workflows/ci.yml/badge.svg)](https://github.com/Abhinivesh2729/Thinai/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/github/license/Abhinivesh2729/Thinai)](LICENSE)

[![Flutter](https://img.shields.io/badge/Flutter-3.41%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.11-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-7.0%2B%20(API%2024)-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![llama.cpp](https://img.shields.io/badge/llama.cpp-GGUF-000000)](https://github.com/ggml-org/llama.cpp)
[![API](https://img.shields.io/badge/API-Ollama%20%7C%20OpenAI-412991)](#api-surface)

On-device LLM server and companion chat application for Android. Thinai wraps [llama.cpp](https://github.com/ggml-org/llama.cpp) (via a vendored fork of [fllama](https://github.com/Telosnex/fllama)) and exposes a local Ollama- and OpenAI-compatible HTTP API on `127.0.0.1:11434`.

Once Thinai is running with a downloaded model, any local client or companion app (such as Thoogai AF) can point to `http://127.0.0.1:11434` for fully offline, private on-device inference.

---

## Key Features

- **On-Device Inference**: Run GGUF models locally on your Android phone using llama.cpp with no cloud dependency.
- **Dual API Compatibility**: Exposes both Ollama (`/api/*`) and OpenAI (`/v1/*`) HTTP endpoints.
- **Vector Embeddings**: Dedicated on-device embedding endpoints (`/api/embed`, `/v1/embeddings`) for local RAG and semantic search.
- **Built-in Chat Interface**: Clean mobile UI with model downloader, context slider, and generation temperature settings.
- **On-Device Web Search**: Optional web search capability to answer questions needing current information, citing sources while keeping chats local.
- **Multimodal Attachments**: Take photos via the system camera, attach images, or analyze documents directly in chat.
- **Background Service**: Android foreground service ensures the local HTTP server continues running when the app is backgrounded.
- **Hardware Acceleration**: Experimental GPU offload (Vulkan / OpenCL) with built-in CPU vs. GPU benchmark, and automatic fallback to the CPU when a device's GPU driver misbehaves.

---

## API Surface

### Health
- `GET /healthz`: Liveness check, `{"status":"ok"}`. Needs no token, so uptime monitors can use it through the public URL.

### Ollama-Compatible
- `GET /api/tags`: List downloaded models
- `GET /api/ps`: Currently loaded model status
- `POST /api/show`: Model metadata and context length
- `POST /api/generate`: Text generation (NDJSON stream)
- `POST /api/chat`: Chat completion (NDJSON stream)
- `POST /api/embed`: Embeddings (`input` = string or array)
- `POST /api/embeddings`: Legacy single-`prompt` embeddings

### OpenAI-Compatible ([Full Reference](docs/openai-api.md))
- `GET /v1/models`: List available models
- `POST /v1/chat/completions`: Chat completion (SSE stream, tool calling, `stop` sequences, usage metrics)
- `POST /v1/embeddings`: Vector embeddings with `encoding_format` (`float` | `base64`) and `dimensions` shortening

Point any standard OpenAI SDK or HTTP client at `http://127.0.0.1:11434/v1` with any placeholder API key.

---

## Public URL & API Tokens

Turn on **Public URL** in the Server tab to reach the API from anywhere through a free [Cloudflare quick tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/do-more-with-tunnels/trycloudflare/). It needs no account or sign-up. Each start gets a random `https://<words>.trycloudflare.com` URL. **Rotate URL** opens a new one, and the old URL stops working at once.

Every request through the public URL (and over the LAN) needs a bearer token. Create named tokens under **API tokens**, one per client. The list shows when each was created, and deleting a token cuts off that client immediately, without restarting the server.

```bash
curl https://<words>.trycloudflare.com/api/tags   -H "Authorization: Bearer <token>"
```

The tunnel is run by the open-source [`cloudflared`](https://github.com/cloudflare/cloudflared) (Apache-2.0). The Gradle build downloads it at a pinned version, checks its SHA-256, and bundles it as `lib/arm64-v8a/libcloudflared.so`, so it isn't committed to git. `cloudflared` can't resolve DNS on Android (Go finds no `/etc/resolv.conf`), so `lib/server/quick_tunnel.dart` does both lookups in Dart: it requests the tunnel from `api.trycloudflare.com` and passes the resolved edge IPs with `--edge`.

---

## Embeddings

Embeddings run fully on-device. Download an embedding model from the **Models** tab ("Embedding models" section), then query it:

```bash
curl http://127.0.0.1:11434/api/embed \
  -d '{"model":"nomic-embed-text-v1.5-q5_k_m","input":["hello","world"]}'
```

```bash
curl http://127.0.0.1:11434/v1/embeddings \
  -d '{"model":"nomic-embed-text-v1.5-q5_k_m","input":"hello"}'
```

### Notes
- **Use an embedding model, not a chat model:** Chat models lack pooling layers. Calling an embedding endpoint with a chat model returns HTTP `400` rather than degraded token-level vectors.
- Vectors are L2-normalized; cosine similarity is a plain dot product.
- `dimensions` truncates and re-normalizes (Matryoshka representation).
- Embeddings use a separate llama context from chat, so inference calls do not evict each other.

### How It Works

Upstream fllama exposes no embedding FFI, so `third_party/fllama` is a vendored fork that provides it:

| Layer | File |
| --- | --- |
| Native bridge | `third_party/fllama/src/fllama_embed.{h,cpp}` |
| Dart FFI | `third_party/fllama/lib/io/fllama_io_embed.dart` |
| Engine | `lib/llm/llm_engine.dart` (`embedBatch`) |
| Routes | `lib/server/routes/{ollama,openai}_routes.dart` |

`fllama_embed.cpp` posts `SERVER_TASK_TYPE_EMBEDDING` tasks to llama.cpp's `server_context`: the same mechanism `llama-server` uses for its `/embedding` endpoint. `third_party/fllama` is committed in-tree so a clean checkout and CI can both build without an external private remote.

---

## Requirements

- **Flutter SDK**: 3.41+ (Dart `^3.11.0`)
- **Android SDK**: API level 24 (Android 7.0 Nougat) or higher
- **Android NDK & CMake**: CMake `3.22.1` installed via Android SDK Manager
- **Device**: Android device with 64-bit ARM architecture (`arm64-v8a`) recommended for adequate RAM and LLM performance.

---

## Getting Started

### 1. Clone and Install Dependencies

```bash
git clone https://github.com/Abhinivesh2729/Thinai.git
cd Thinai
flutter pub get
```

### 2. Run Locally

Connect an Android device or launch an emulator:

```bash
flutter run
```

> **Note:** The first build compiles the native `llama.cpp` C++ engine from source and takes several minutes.

### 3. Start the Server

Open the **Server** tab in the app to start the HTTP listener and select an installed model.

---

## Testing & Quality Assurance

Run static analysis:
```bash
flutter analyze
```

Format code:
```bash
dart format --set-exit-if-changed .
```

Run unit and integration tests (excluding native on-device tests):
```bash
flutter test --exclude-tags native
```

> **Note:** Tests marked `@Tags(['native'])` require an on-device environment with downloaded model weights.

---

## Contributing

We welcome community contributions! Please read our contributing guide and code of conduct before getting started:

- See [CONTRIBUTING.md](CONTRIBUTING.md) for branch guidelines, workflows, and PR expectations.
- See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community standards.

---

## Security

Please report vulnerabilities responsibly. Do NOT report security issues via public GitHub issues.

- See [SECURITY.md](SECURITY.md) for reporting instructions via private security advisories.

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

The vendored `third_party/fllama` package and its bundled `llama.cpp` sources are licensed under their respective licenses (see `third_party/fllama/LICENSE`).
