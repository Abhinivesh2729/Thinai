# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## [2.6.2]

### Added
- Tap any model in the catalog to open its details in a bottom sheet that opens half-way and drags up or down. Installed models get Use in chat and Delete model, and deleting always asks first (#94, #95).

### Fixed
- The details sheet shows the model's live download state: progress and Pause while downloading, Resume when paused, instead of a Download button that restarted the download from zero (#95).

## [2.6.1]

### Fixed
- Running a model rated "Tight fit" could make the phone thrash, close other apps and then close Thinai. The context window is now sized at load time against the memory actually free, counting the model's weights, its context cache and llama.cpp's working buffers; on a tight phone a smaller window is picked automatically (#91).
- Switching models kept the old one in memory for up to two and a half minutes. It is now unloaded the moment you switch, and a new model never loads beside an idle one (#91).

## [2.6.0]

### Added
- Public URL (Beta): a temporary `https://…trycloudflare.com` link to the local API through a free Cloudflare quick tunnel, with Rotate URL. The first turn-on warns that requests and replies pass through Cloudflare. Shown on arm64 phones, where the bundled cloudflared (Apache-2.0) runs (#71, #72).
- Named API tokens: create one per client and delete it to cut that client off at once, without a restart. LAN and the public URL always need one; the old single LAN token carries over as "Default" (#72).
- `GET /healthz` for uptime checks; it needs no token and returns no data (#72).

### Fixed
- LAN clients got 401 on every request: the Server page never showed the token on a fresh install, and every example sent the placeholder key "thinai". The VS Code, Python, cURL and endpoint examples now carry the real token, masked on screen and copied in full; the Ollama tab says `OLLAMA_HOST` alone cannot authenticate (#86).
- The API accepts the `Bearer` scheme in any case, compares tokens in constant time, and answers a missing or wrong key with `WWW-Authenticate` and a message that says where the token is, in the OpenAI or Ollama error shape (#86).
- Deleting the last API token while sharing no longer locks every client out until a restart: a new token replaces it at once.
- The whole Share on LAN row toggles it, like Public URL, not just the switch.

### Changed
- Dependencies: file_picker 13.3.0, share_plus 13, package_info_plus 10, in_app_update 5.0.0, plus patch updates (#81, #82, #83, #85).
- Groundwork for MCP tools: an MCP client that connects to a server over Streamable HTTP, lists its tools and calls them. Nothing in the app uses it yet (#15, #40).

## [2.5.0]

### Added
- Search Hugging Face from the Models page and install any public single-file GGUF. Repo pages show the licence, context length, quantisation, size and RAM fit for each file; downloads are pinned to the listed commit. The app goes online only while you search or open a repo (#58).
- Downloads resume where they stopped after a pause, a lost connection or the app closing, using HTTP Range with If-Range on the ETag. Cancel is now Pause; the Model Manager lists paused downloads with Resume and Discard (#62).
- Thinai in English and Tamil: every screen is translated, with a language picker and a glossary in Settings → Appearance. In Tamil, the model answers in Tamil (#67).
- Tamil eval: Models → த runs 60 short Tamil questions on the selected model and gives a Tamil score from 0 to 100, with Understanding, Expression and Knowledge scores and every reply behind them. A full run of LFM2.5-350M on a mid-range phone takes about 2.5 minutes. The latest score shows on the model's card. The dataset and scorers live in the [`thinai_tamil_evals`](https://github.com/Abhinivesh2729/thinai-tamil-evals) library (#3).
- The API server takes a GBNF `grammar` on `/v1/chat/completions`, like llama-server.

### Changed
- LFM2.5 350M is the featured model on the Models page.
- Dependencies: dio 5.11.1, flutter_foreground_task 11.0.3, permission_handler 13.0.2, cupertino_icons 2.0.0, plus patch updates (#64).
- Test coverage raised from 41% to 77%; the CI coverage gate is now 50%.
- Faster launch: no fixed 2.8 s splash wait, and the Android 12+ system splash shows the logo (#73).

### Fixed
- Qwen3.5 GGUFs re-converted with an MTP block failed to load (#60).
- The Server tab shows the saved port before the server starts (#41).
- The LAN switch is visible in dark theme (#54).
- A long goal name no longer pushes the Reset button off the Models filter row.
- Chats, attachments and API requests got a quarter of the context window set in the app; each request now gets all of it. The Ollama routes report a native failure as an error instead of a 200 reply (#75).

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
