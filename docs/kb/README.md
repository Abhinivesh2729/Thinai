# Thinai Knowledge Base

This folder explains how the Thinai mobile app works today, screen by screen and feature by feature. It is the starting point for building **Thinai Desktop**, a GUI version for macOS, Windows and Linux.

Two kinds of reader use it:
- **People** (founder, team, reviewers) who want to know what the app does.
- **Coding agents** taking over the project, who need exact rules, limits and file locations.

Everything here comes from the code in this repo (v2.5.0, commit `513e0b7`) and from a walkthrough of the running app on a Realme RMX3870 phone over ADB on 2026-10-30.

## How to read it

| # | Doc | What it covers |
|---|---|---|
| 1 | [01-overview.md](01-overview.md) | What Thinai is, who it is for, the main ideas, how the code is laid out |
| 2 | [02-navigation-and-screens.md](02-navigation-and-screens.md) | Every screen, how you reach it, and a screenshot of each |
| 3 | [03-chat.md](03-chat.md) | Chat, conversations, attachments, web search, system prompt |
| 4 | [04-models.md](04-models.md) | Model catalog, downloads, import, Hugging Face search, recommendations, Benchmark, Tamil eval |
| 5 | [05-server-and-api.md](05-server-and-api.md) | The local HTTP server, every API endpoint, LAN sharing and tokens |
| 6 | [06-engine-and-hardware.md](06-engine-and-hardware.md) | How models load and run, context size, sampling, GPU, device detection |
| 7 | [07-settings-and-app-shell.md](07-settings-and-app-shell.md) | Settings, first-run onboarding, About, Support, updates, language, theme |
| 8 | [08-data-and-storage.md](08-data-and-storage.md) | Everything the app saves, where, and in what shape |
| 9 | [09-known-issues.md](09-known-issues.md) | Bugs, dead code and inconsistencies found while writing this KB |
| 10 | [10-desktop-prd.md](10-desktop-prd.md) | **Draft PRD for Thinai Desktop**: scope, what to reuse, what to replace, open questions |

Screenshots are in [screens/](screens/).

## Quick facts

| | |
|---|---|
| App name | Thinai (திணை) |
| Package | `in.atmega.thinai` (Android). The Dart package is still named `local_llm` |
| Version | 2.5.0 (pubspec `2.5.0+14`; the build on the test phone reports code 10006) |
| Stack | Flutter (Dart ^3.11), Riverpod for state, `shelf` for the HTTP server |
| AI runtime | llama.cpp through a vendored fork of `fllama` in `third_party/fllama` |
| Model format | GGUF files |
| Platforms today | Android 7.0+ (main), iOS 15+ (early). No desktop runners exist yet |
| Languages | English and Tamil, switchable in Settings |
| Network use | Only for model downloads, Hugging Face search, web search and Play updates. Chat itself is offline |

## Words used in this KB

| Term | Meaning |
|---|---|
| Model | A GGUF file with the weights of a language model |
| Chat model | A model that writes text replies |
| Embedding model | A model that turns text into vectors (for search and RAG). It cannot chat |
| Vision model | A chat model that can also read images. It needs a second file, the **projector** (`mmproj-*.gguf`) |
| Active model | The model the Chat tab and the server use by default |
| Served id | A model's id in the app and API: the file name, lower-cased, without `.gguf`. Example: `gemma-3-270m-it-q8_0` |
| Context window | How many tokens the model can see at once (question, history and answer together) |
| Quant | How much the weights are compressed, e.g. `Q4_K_M`, `Q8_0` |
| Catalog | The built-in list of 35 models the app knows how to download |
| Server | The local HTTP API the app runs on port 11434 (Ollama- and OpenAI-compatible) |

## Confidence labels

Statements in this KB are **from code** unless marked otherwise:
- **(seen on device)**: checked on the running app.
- **(not verified)**: read from the code but not tested; treat it as likely, not certain.
