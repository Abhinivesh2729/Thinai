# ADR-001: Build the desktop app from the existing Flutter codebase

## Status
Accepted

## Date
2026-10-23

## Context
Issue #56 asks for Thinai on macOS, Windows and Linux with the same core features as Android: the model catalog and downloads, chat, and the local OpenAI/Ollama-compatible API server.

Relevant facts at the time of the decision:
- The Android app is about 33,000 lines of Dart (UI, model manager, downloader, HTTP server, chat).
- llama.cpp is reached through `third_party/fllama`, whose native-assets build hook (`hook/build.dart`) already had branches for macOS (Metal), Windows (Vulkan, falling back to CPU without the SDK) and Linux.
- Memory is the scarcest resource on the target machines: the model takes most of the RAM, so the app itself should stay small.

## Decision
Add the `windows`, `macos` and `linux` Flutter platform targets to this repository and ship the desktop app from the same codebase as Android. Android-only pieces are skipped at runtime, not forked:
- `hasForegroundService` (`lib/server/foreground_handler.dart`) turns off the foreground service, its notification and the notification permission prompt outside Android.
- The camera attachment is hidden off Android, because `image_picker` has no camera source on desktop.
- Strings that name the hardware take a `{device}` select (`deviceKind` in `lib/l10n/l10n.dart`): "phone" on Android, "computer" on desktop, in English and Tamil.

## Alternatives Considered

### Electron (JavaScript)
- Pros: very mature packaging and auto-update tooling (electron-builder); large hiring pool.
- Cons: a full rewrite of the UI, downloader and server; a second llama.cpp integration (`node-llama-cpp`); bundles Chromium, adding roughly 150 MB and its RAM use, which competes with the model.
- Rejected: two apps to maintain, and the runtime overhead lands on the resource the product depends on.

### Python (Qt or similar)
- Pros: `llama-cpp-python` is a solid binding.
- Cons: also a full rewrite; packaging (PyInstaller and similar) is fragile across three OSes; no shared code with Android.
- Rejected: highest packaging risk and no code reuse.

### Tauri (Rust core, web UI)
- Pros: much lighter than Electron.
- Cons: still a UI rewrite plus a new native integration.
- Rejected: a rewrite either way; reusing the Flutter code is cheaper.

### Running the Android app in an emulator
- Rejected in the issue itself: slow, and no GPU access.

## Consequences
- One codebase and one test suite cover Android and desktop; the first Windows build needed only small changes (platform guards, two native build fixes).
- Some Flutter plugins are Android-first and need per-platform care. Known so far: `permission_handler_windows` needs an MSVC opt-out to compile with Visual Studio 2026 (`windows/CMakeLists.txt`); the camera picker does not exist on desktop.
- Desktop-only concerns still to be addressed: a layout for large windows (the UI is phone-shaped), a desktop updater, and code signing / notarisation.
- Packaging is per OS and lives in `packaging/` (see [DESKTOP.md](../DESKTOP.md)).
