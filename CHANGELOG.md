# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added
- Desktop app for Windows, Linux and macOS from the same codebase (#56). See [docs/DESKTOP.md](docs/DESKTOP.md) and [ADR-001](docs/decisions/ADR-001-desktop-from-flutter-codebase.md).
- Desktop packages: Windows `-setup.exe`, `.msi` and `.zip`; Linux `.deb` and `.tar.gz`; macOS `.dmg` and `.zip` (`packaging/`, plus a manual `Desktop Build` workflow).
- Windows installers add Start menu and desktop shortcuts, offer to launch Thinai when they finish, and upgrade an existing install in place.
- The landing screen greets you ("Welcome" / "வணக்கம்") and, on desktop, uses the signed-in account's name.

### Changed
- Text that names the hardware says "computer" (கணினி) on desktop and "phone" (கைப்பேசி) on Android.
- "No model yet" / "No model loaded" is shown as an amber warning with a line explaining the next step, instead of a red error.
- Desktop windows open maximized (a shortcut set to "Run: Minimized" is honoured).
- Desktop runs one copy at a time: launching Thinai again brings the open window forward instead of starting a second server on the same port.
- **Security:** the local API (loopback mode) only answers browser pages served from this machine, and refuses requests whose `Host` is not loopback (DNS rebinding). Before, any website open in a browser could run your models and read the replies. Clients that send no `Origin` (curl, SDKs) are unaffected; list other sites in `THINAI_ORIGINS` (`*` for any), like Ollama's `OLLAMA_ORIGINS`. LAN mode is unchanged (token required).
- **Security:** API errors no longer include the server's stack trace; it goes to the app's log instead.
- Windows: models, settings and chats live in `%LOCALAPPDATA%\in.atmega\Thinai`, not the Roaming profile that managed PCs copy to a server.

### Fixed
- Windows: the first chat no longer crashes the app. fllama read ggml's clock before initialising it, and on Windows that clock divides by a timer frequency that is still 0 at that point (`0xC0000094` in `fllama.dll`).
- All platforms: streamed replies are no longer read from freed memory. llama.cpp handed Dart pointers to strings that changed or were destroyed before the asynchronous callback read them, which could crash the app at random or garble text and token counts. The callback now receives copies it owns.
- All platforms: log lines sent to a Dart logger are no longer read from freed memory (same class of bug as streamed replies), and each chat no longer leaks its native callback.
- All platforms: fllama's own timings ("Model ready", "Done") no longer come out negative; they used ggml's clock, which model loading resets.
- All platforms: `tool_choice: "required"` now forces a tool call. fllama built the chat template's grammar but never passed it to the sampler. (A `grammar` set through fllama's Dart API now applies too; the HTTP API has no `grammar` parameter.)
- Windows: `fllama.dll` and the Visual C++ runtime (with OpenMP) are now bundled with the app, so it starts on PCs without the VC++ redistributable. The build hook's library-name match also caught MSBuild's `fllama.dll.recipe`.

## [2.4.0]

### Added
- Confirmation dialogs before downloading a model (names the model and size), cancelling a download (progress is lost), and deleting a model (#28).
- Settings → System Prompt: view, edit and reset the system prompt every chat starts with. Persisted, works offline, chat only (#30).
- Per-model Top-K, Top-P and a Thinking on/off switch in the model settings sheet. The switch appears only for models whose chat template has a thinking mode; the API server honours the same settings, and a client's own `top_k` / `top_p` / thinking flag still wins (#31).

### Changed
- The app opens a new, empty chat on launch instead of resuming the last one; past chats stay in history (#29).
- Default Top-P is now 0.95 (llama.cpp's default), was 1.0.

### Fixed
- GPU inference no longer crashes the app on most Android devices: GPU backend registration failures are caught and fall back to CPU, Vulkan device re-enumeration is bounds-checked, and a backend that fails two loads in a row rests for ten minutes while requests run on the CPU.

### Added
- Open-source preparation: repository documentation, contribution guidelines, code of conduct, security policy, issue templates, and pull request template.

## [2.3.11]

### Added
- Per-model context window and temperature controls (configurable via Chat tab and Server page).
- Hardware-constrained context window slider based on trained context length and device RAM limits.
- `/api/show` endpoint now reports real architecture and context length.
- Experimental GPU acceleration (Vulkan / OpenCL) in Settings with CPU vs. GPU speed benchmark.
- Prompt-injection hardening: untrusted third-party web results and attached documents are isolated with randomized markers and stripped of control tokens.

### Changed
- Web search pipeline upgraded with Bing keyword fallback, conversation history tracking, and strict relevance validation.
- Long conversation history automatically trimmed from oldest exchanges to avoid context window overflows.

## [2.3.0]

### Added
- Automatic on-device web search integration with source attribution.
- Camera capture support via system camera intent without requiring direct camera permissions.
- Unified composer attachment menu (photo capture, image selection, document attachment, web search toggle).

## [2.1.0]

### Added
- On-device embeddings API support:
  - `POST /api/embed` (Ollama-compatible batch embeddings)
  - `POST /api/embeddings` (Ollama legacy single-prompt endpoint)
  - `POST /v1/embeddings` (OpenAI-compatible embeddings with truncation and encoding support)
- Independent llama context for embedding tasks to avoid blocking chat generation.
- Expanded model catalog with dedicated embedding models and compact chat models.
- Updated Server screen with endpoint testing examples and curl commands.
