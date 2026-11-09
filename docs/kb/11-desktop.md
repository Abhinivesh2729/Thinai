# 11. Thinai Desktop (Windows first)

| | |
|---|---|
| Status | **In development** on branch `windows`. One merge into `main` when features are final |
| Started | 2026-11-09 |
| Target | Windows 10/11 x64. macOS builds exist only as a developer harness |
| Entry point | `lib/main_desktop.dart` (the phone app stays on `lib/main.dart`) |

## 1. Decisions

| Decision | Why |
|---|---|
| Same repo, same Flutter app, separate desktop entry point and UI in `lib/desktop/` | Engine, models, chat logic and API server are shared; the phone UI is untouched, so Play releases carry no desktop risk |
| API port **2727** on desktop | Ollama usually owns 11434 on a PC (`lib/platform/platform_info.dart`) |
| No Cloudflare tunnel on desktop | Founder decision; LAN sharing with tokens stays |
| Chat history in **SQLite** with FTS5 search, no cap | People keep months of chats on a PC and search them (`lib/desktop/storage/sqlite_chat_store.dart`) |
| Close to tray while the API server runs; otherwise close quits | Desktop stand-in for Android's foreground service (`lib/desktop/desk_window.dart`) |
| Signing, installer polish, auto-update, crash reporting | Deferred until features are final |

## 2. Code layout (`lib/desktop/`)

| Path | What it is |
|---|---|
| `desktop_app.dart` | MaterialApp, theme, shortcuts, toast layer |
| `desk_window.dart` | Frameless window, minimum size, tray icon, close-to-tray |
| `shell/` | Rail, custom title bar (own min/max/close on Windows), page stack (pages stay alive; hidden pages stop ticking), keyboard shortcuts |
| `theme/desk_theme.dart` | Desktop design system on top of the phone colours: `DeskColors`, `DeskMotion`, `DeskSize`, `DeskPalette` |
| `widgets/orb.dart` + `shaders/orb.frag` | The orb: one GPU fragment shader; mood (idle, thinking, speaking, error) and per-token pulses |
| `chat/` | `DeskChatController` (send/stop/search/attachments, text pushed to the transcript once per frame), composer, transcript (block-cached streaming Markdown), sidebar, model picker |
| `pages/models*`, `pages/lab*`, `pages/server*`, `pages/settings*` | The other four pages |
| `l10n/` | Desktop-only strings, English and Tamil, one file per area. Phone strings still come from `context.l10n` |
| `storage/` | SQLite chat store |
| `monitor/` | Load monitor: CPU, RAM, power (battery discharge rate when unplugged, else estimated), battery; per-model busy time, tokens, energy and CO2 (India grid 716 g/kWh). Lab > Load and the live strip in chat |
| `diagnostics.dart` | Log file `<app data>/logs/thinai.log` (startup timings, model loads, engine errors, uncaught exceptions; never chat text) |
| `smoke_test.dart` | `thinai.exe --smoke --model=x.gguf --out=r.json` self-test used by CI |
| `dev_snapshots.dart` | `THINAI_SNAPSHOT_DIR=...` renders every page to PNG and quits (visual checks without screen access) |

Shared code moved out of phone widgets so both apps use it: `lib/chat/prompt_builder.dart`, `attachmentErrorMessage` in `lib/chat/attachment_error.dart`. `ChatSessionsController` storage is overridable (`load`, `persist`, `clearStorage`, `maxConversations`).

## 3. Engine on Windows (`third_party/fllama`)

- `GGML_NATIVE=OFF`: CI-built DLLs target AVX2/FMA/F16C (Haswell, 2013+), not the CI machine's CPU. `LLAMA_NATIVE=OFF` alone did nothing.
- Vulkan is compiled in, registered only on demand (`FLLAMA_LAZY_GPU_REG`), and `vulkan-1.dll` is **delay-loaded**. fllama checks `LoadLibraryExW("vulkan-1.dll")` before registering, so a PC without a Vulkan driver runs on the CPU instead of failing to start.
- No OpenMP on Windows (no `vcomp140.dll` dependency). The installer bundles `msvcp140`/`vcruntime140`.
- The hook's library pattern is anchored: MSBuild leaves `fllama.dll.recipe` next to the build tree and an unanchored pattern shipped that instead of the DLL.
- RAM on Windows comes from `GlobalMemoryStatusEx`, on macOS from `sysctl`/`vm_stat` (`lib/models_repo/desktop_memory.dart`).

## 4. Build, test and debug

You cannot build a Windows app on macOS. The loop is:

| Where | What |
|---|---|
| Mac | `flutter run -d macos -t lib/main_desktop.dart` for UI work with hot reload (CPU/Metal). `THINAI_SNAPSHOT_DIR=/tmp/s ./build/macos/Build/Products/Debug/Thinai.app/Contents/MacOS/Thinai` renders every page; add `THINAI_SNAPSHOT_PROMPT="..."` to also run a chat with the first installed model |
| CI | `.github/workflows/windows.yml` on every push to `windows`: Vulkan SDK, `flutter build windows --release -t lib/main_desktop.dart`, bundle checks (DLLs present, `vulkan-1.dll` delay-loaded), the `--smoke` self-test with LFM2.5 350M, then `ThinaiSetup-<version>.exe` (Inno Setup, per-user, no admin) uploaded as an artifact |
| CI UI run | After the self-test, CI launches the real app with `THINAI_SNAPSHOT_DIR` + `THINAI_SNAPSHOT_LAB_RUN`: it visits every page and Lab tab, presses Run on the speed benchmark and Tamil eval, and uploads the PNGs as the `ui-screenshots-<n>` artifact. A crash fails the job and prints `crash.txt` |
| Native crashes | The runner writes `logs/crash.txt` (exception code + module/offset/function stack; fllama is built with a PDB) and `logs/native.log` (llama.cpp stderr). The next launch folds both into `thinai.log` and shows a toast |
| Boot Camp | Install `ThinaiSetup-*.exe` from the Actions run. SmartScreen: More info → Run anyway (unsigned). Problems: Settings → About & help → **Copy diagnostics**, paste it to the developer |

Startup is logged (`startup: runApp`, `first frame`, `restored session`), as are first-token time and tok/s for every chat reply.

## 5. Known gaps (as of 2026-11-09)

- Tray icon, title bar and resize behaviour not yet seen on real Windows.
- Hugging Face search pages and the Tamil eval page are the phone widgets embedded in the desktop shell.
- Metal can't be selected in GPU settings on macOS (dev harness only).
- Phone-worded strings remain in a few shared places (download errors, `tamilEvalOnThisPhone`).
