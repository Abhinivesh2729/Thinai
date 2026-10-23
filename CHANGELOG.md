# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added
- Tamil eval: Models → த runs 60 short Tamil questions on the selected model and gives a Tamil score from 0 to 100, with Understanding, Expression and Knowledge scores and every reply behind them. A full run of LFM2.5-350M on a mid-range phone takes about 2.5 minutes. The latest score shows on the model's card. The dataset and scorers live in the [`thinai_tamil_evals`](https://github.com/Abhinivesh2729/thinai-tamil-evals) library (#3).
- The API server takes a GBNF `grammar` on `/v1/chat/completions`, like llama-server.

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
