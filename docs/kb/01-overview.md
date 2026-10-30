# 1. Overview

## What Thinai is

Thinai is a private AI app that runs language models **on the device**. You download an open model once, and after that you can chat with it with no internet and no account. Nothing you type leaves the phone, unless you turn on web search.

It does two jobs:
1. **A chat app.** Talk to a local model, attach a photo or a text file, and optionally let it search the web.
2. **A local AI server.** The app runs an HTTP API on `http://127.0.0.1:11434` that speaks both the **Ollama** and the **OpenAI** formats. Other apps on the same phone (for example Thoogai) or, with LAN sharing, other devices on the same Wi-Fi, can use the phone's model as their AI backend.

## Who uses it

| User | What they want |
|---|---|
| Privacy-minded person | A ChatGPT-style chat that works offline and keeps data on the device |
| Tamil speaker | A model that understands and writes Tamil, and a UI in Tamil |
| Developer | A free local endpoint for their app, scripts or IDE (VS Code Continue, OpenAI SDK, Ollama clients) |
| Tinkerer | Try many open models, compare speed and Tamil skill on their own hardware |

## Core ideas (keep these in the desktop version)

1. **Offline first.** Chat, the API and model management work with no network once a model is downloaded.
2. **One model file, many uses.** The same downloaded model serves the Chat tab and the API.
3. **Fit the hardware.** The app reads the device's RAM and recommends models that fit, warns about ones that do not, and caps the context window to what memory allows.
4. **Measure, don't guess.** The Benchmark measures real speed; the Tamil eval measures real Tamil skill. Measurements feed the speed estimates.
5. **Bilingual.** Every UI string exists in English and Tamil.

## The four tabs

The app has a bottom bar with four tabs, plus a side drawer for chat history.

| Tab | Purpose | Detail doc |
|---|---|---|
| **Chat** | Talk to the active model | [03-chat.md](03-chat.md) |
| **Models** | Find, download, manage and test models | [04-models.md](04-models.md) |
| **Server** | Start/stop the local API, copy code samples | [05-server-and-api.md](05-server-and-api.md) |
| **Settings** | Appearance, system prompt, hardware, storage, server, help | [07-settings-and-app-shell.md](07-settings-and-app-shell.md) |

## How the code is laid out

```
lib/
  main.dart            App entry. Warms settings, sets up the Android background service
  ui/
    app.dart           Theme, splash → onboarding → 4-tab shell, update banner
    pages/             One file per screen (chat, models, server, settings, benchmark, ...)
    widgets/           Reusable pieces (drawer, model settings sheet, markdown, dial, ...)
  state/providers.dart All app state (Riverpod): chats, active model, downloads, server, settings
  chat/                Attachments, system prompt, context trimming, prompt-injection guard
  web/web_search.dart  Keyless web search (DuckDuckGo, Bing) and prompt building
  llm/                 Engine wrapper over fllama, generation settings, context limits, GPU
  models_repo/         Catalog, downloader, Hugging Face client, importer, model store,
                       device profile, recommender, skills, GGUF reader, result stores
  server/              HTTP server, Ollama + OpenAI routes, LAN address, Android service
  eval/                Adapter that runs the Tamil eval on the engine
  update/              Google Play in-app update wrapper
  l10n/                English and Tamil strings (.arb) and generated classes
third_party/fllama/    Vendored llama.cpp binding (adds embeddings, grammar, GPU selection)
```

External library: the Tamil eval dataset and scoring live in a separate pure-Dart package, [`thinai_tamil_evals`](https://github.com/Abhinivesh2729/thinai-tamil-evals) (v0.1.0).

## How a chat message flows

```
User types → Chat page builds the prompt (system prompt + history + attachments + web results)
          → trims it to fit the context window
          → LlmEngine.chat() → fllama (FFI) → llama.cpp on a native thread
          → tokens stream back → shown live → saved when the reply ends
```

## How an API call flows

```
Client → HTTP (shelf) on 127.0.0.1:11434 (or 0.0.0.0 with LAN + bearer token)
       → Ollama or OpenAI route parses the request
       → finds the model file by name → LlmEngine (same queue as Chat)
       → streams NDJSON (Ollama) or SSE (OpenAI) back
```

Chat and API requests share **one engine queue**: only one generation runs at a time. Embedding requests use a separate path and do not wait in that queue.

## What is Android-only today

The foreground service and its notification, Google Play in-app updates, the system camera, and RAM detection through `/proc/meminfo`. [10-desktop-prd.md](10-desktop-prd.md) lists the desktop replacement for each.
