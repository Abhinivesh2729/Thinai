# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added
- Open-source preparation: repository documentation, contribution guidelines, code of conduct, security policy, issue templates, and pull request template.
- Model switcher in the Chat header: see the active model at a glance and change it, or open its settings, in one tap.
- Starter prompts on an empty chat that fill the composer for editing.
- Copy action under every finished reply.
- Chat history grouped into Today, Previous 7 days, and Older.
- Edit any question: the conversation forks into versions you can switch between with ‹ 1/2 › arrows. Regenerate creates a new version of the latest answer.
- Three follow-up questions written by the model after each answer, one tap to ask. Can be turned off in Settings.
- Markdown tables render as real tables, and fenced code renders in a labelled block with its own copy button.
- Long-press any message for Copy, Select text, Edit, Regenerate, Share, and Delete. Share uses the Android share sheet.

### Changed
- Redesigned interface built on one design system (`lib/ui/theme/app_theme.dart`, `lib/ui/widgets/ui_kit.dart`): hand-tuned neutral light and dark palettes with brand navy as the single accent, the Inter typeface bundled offline (SIL OFL), and shared spacing, radius, card, list, and empty-state components across every screen.
- Settings reorganised into grouped sections: Appearance, Chat, Performance, Models, Help.
- Chat is the home screen. The bottom navigation bar is replaced by a side drawer with New chat, recent chats, Models, Server, and Settings, and Back from Models or Server returns to Chat.
- Opening the app after it was closed lands on a new chat instead of reopening the last conversation, which stays first under Recent chats in the drawer. Returning from the background keeps the open chat.
- The local server uses a server rack icon instead of a cloud.
- The missing-model state in Chat is a calm call to action instead of a red error banner.

### Fixed
- Server page no longer says LAN access needs no authentication, and its curl examples include the bearer token header while network sharing is on.

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
