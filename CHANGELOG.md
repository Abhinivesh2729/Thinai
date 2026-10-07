# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

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
