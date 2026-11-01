# 10. Thinai Desktop: PRD (draft for review)

| | |
|---|---|
| Status | **Draft.** Built from the mobile KB (docs 1–9). Decisions marked **Open** need the founder's call |
| Based on | Thinai mobile v2.5.0 |
| Date | 2026-10-30 |

## 1. Goal

Ship Thinai as a desktop GUI app with the same promise as mobile: **private, offline AI on your own machine**, a chat app and a local Ollama/OpenAI-compatible server in one.

Success looks like:
1. A user installs Thinai Desktop, downloads a model from the catalog, and chats offline in under 5 minutes.
2. A developer points the OpenAI SDK, VS Code Continue or an Ollama client at `http://127.0.0.1:11434` and it works exactly like the phone.
3. Chats, settings and the API behave the same as on mobile, so docs and support cover both.

## 2. Non-goals (v1)

- Cloud sync of chats between phone and desktop.
- Accounts or sign-in (including gated Hugging Face models).
- Multi-user or a hosted server.
- Training or fine-tuning.
- Speech, PDF/Office documents (mobile does not have them yet either).

## 3. Approach

**Recommended: same repo, same Flutter app, add desktop runners** (`macos/`, `windows/`, `linux/`). Reasons:
- All the logic is UI-independent and already portable: `state/`, `chat/`, `web/`, `models_repo/` (catalog, downloader, HF client, GGUF reader, recommender, stores), `server/` routes, `eval/`, `l10n/`. That is about 11K of the ~35K hand-written lines in `lib/`; the other ~24K are the mobile UI in `lib/ui/`, which is where the desktop work goes.
- `third_party/fllama`'s build hook already builds for macOS (Metal), Windows (Vulkan or CPU) and Linux (CPU).
- One codebase keeps the API and chat behaviour identical across platforms.

The work is mainly: a desktop layout, desktop replacements for Android-only pieces (§6), and hardware detection/tuning for big machines (§7).

> **Open – D1:** Is the repo layout fine as one app with adaptive layouts, or do you want a separate `apps/desktop` entry point sharing `lib/`?

## 4. Target platforms

| Platform | Priority | GPU path | Notes |
|---|---|---|---|
| macOS (Apple Silicon) | **Open – D2** | Metal | Best fit for local LLMs (unified memory). Needs signing + notarization |
| Windows x64 | **Open – D2** | Vulkan (CUDA not configured) | Needs code signing to avoid SmartScreen |
| Linux x64 | **Open – D2** | CPU only today | AppImage or .deb |

Suggestion: macOS first (Metal works with the least new native work), then Windows.

## 5. Feature scope

Legend: **Keep** = same behaviour; **Adapt** = same feature, desktop UI or mechanism; **New** = desktop only; **Drop** = not in desktop v1.

### 5.1 Layout and navigation

| Mobile | Desktop | Type |
|---|---|---|
| Bottom bar with 4 tabs | Left **navigation rail**: Chat, Models, Server, Settings | Adapt |
| Drawer with chat history | **Persistent, resizable chat sidebar** inside the Chat view | Adapt |
| Bottom sheets (model switch, model settings, sources, goal, manager, chat options) | Popovers, dialogs or a right-side panel | Adapt |
| Long-press menus | Right-click context menus + hover action buttons | Adapt |
| Snackbars | Non-blocking toasts (bottom-right) | Keep |
| Splash + 5-slide onboarding | Short first-run welcome (rewrite copy for desktop: no "phone", no Adreno/Mali) | Adapt |
| Android Back exits | Normal window behaviour | Drop |
| Min window size | **New**: e.g. 900×600, responsive down to that | New |

### 5.2 Chat ([03-chat.md](03-chat.md))

| Feature | Desktop | Type |
|---|---|---|
| Streaming chat, Stop, Copy, Markdown, code copy | Same | Keep |
| Model chip + Switch Model + Model settings | Same, as a popover from the top bar | Adapt |
| Starter chips | Keep; replace "Speed test" with something the model can answer | Adapt |
| Conversations: create, rename, delete, multi-delete, search, date groups | Same | Keep |
| Web search (DuckDuckGo/Bing, sources pill and sheet) | Same; use a desktop user agent | Keep |
| Document attach (text/code, 20K chars) | Same + **drag-and-drop** onto the chat | Adapt |
| Image attach (vision models) | Same + drag-and-drop + **paste image from clipboard** | Adapt |
| Camera | Drop for v1 (or webcam capture later) | Drop |
| Share | Replace with **Copy** and **Export chat as Markdown** | Adapt |
| Keyboard | **New**: Enter = send, Shift+Enter = newline, Esc = stop, Cmd/Ctrl+N new chat, Cmd/Ctrl+F search chats, Cmd/Ctrl+K switch model, Cmd/Ctrl+, settings | New |
| Clickable links in replies and `[n]` citations | **New** (mobile renders them as plain text) | New |
| Chat storage | **Open – D3:** keep SharedPreferences JSON (40-chat cap) or move to SQLite/JSON files with no cap and full-text search | Adapt |

### 5.3 Models ([04-models.md](04-models.md))

| Feature | Desktop | Type |
|---|---|---|
| Catalog (35 models), search, category filter, goals, Top picks | Same. **Open – D4:** add larger models for desktop (7B–14B+, e.g. Qwen 3 8B/14B, Gemma 3 12B, Llama 3.1 8B) | Keep / Adapt |
| Downloads with pause/resume/discard | Same; progress also in the dock/taskbar icon | Adapt |
| Hugging Face search and repo page | Same | Keep |
| Import .gguf | Same + drag-and-drop + **import by reference** (use the file where it is, no copy) | Adapt |
| Models folder | **New**: user can choose the folder; show free disk space and check it before download | New |
| Reuse models from other apps | **Open – D5:** detect LM Studio / Ollama / HF cache GGUFs | New |
| RAM fit, recommendations | Same logic, re-tuned for desktop (§7) | Adapt |
| Benchmark | Same | Keep |
| Tamil eval | Same | Keep |
| Model Manager | A full page or panel, not a sheet; show which models are loaded in memory | Adapt |

### 5.4 Server ([05-server-and-api.md](05-server-and-api.md))

| Feature | Desktop | Type |
|---|---|---|
| All Ollama and OpenAI endpoints, streaming, tools, embeddings | Same | Keep |
| Port setting, Start/Stop, copy URL, Quick start, endpoint samples | Same | Keep |
| LAN sharing with bearer token | Same; token stored in the **OS keychain**; interface picker (desktop machines have Docker/VPN adapters) | Adapt |
| Background service + notification | **Tray / menu-bar icon**: status, URL, Start/Stop, open window, quit. Closing the window keeps the server running | Adapt |
| Resume server on launch | Same + optional **launch at login** | Adapt |
| Keep awake while serving | Sleep inhibit (IOPMAssertion / SetThreadExecutionState / systemd-inhibit) | Adapt |
| Firewall | First LAN bind triggers the OS firewall prompt; macOS sandbox needs the network-server entitlement | New |
| Request log | **Open – D6:** simple live log of API calls (model, tokens, tok/s) | New |

### 5.5 Settings ([07-settings-and-app-shell.md](07-settings-and-app-shell.md))

| Feature | Desktop | Type |
|---|---|---|
| Appearance: start page, language, glossary, theme | Same | Keep |
| Web search toggle | Same, but move out of Appearance into a "Chat" section | Adapt |
| System prompt | Same | Keep |
| Hardware: GPU choice, Benchmark, GPU speed test, device info | Adapt to Metal / CUDA / Vulkan / CPU; add **CPU threads** and **GPU layers** | Adapt |
| Model & Storage | Same + models folder picker | Adapt |
| Local Server | Same + launch at login, start server on launch | Adapt |
| About & Help | Same; specs per platform (not "ARM64-v8a NEON") | Adapt |
| Google Play updates | Replace with Sparkle (macOS), WinSparkle/MSIX (Windows), or a GitHub-releases check; keep the same banner states | Adapt |

## 6. Android-only pieces and their desktop replacements

| Mobile piece | Desktop replacement |
|---|---|
| `flutter_foreground_task` service + notification | Tray icon (`tray_manager`/`system_tray`), `window_manager`, `launch_at_startup`, native notifications (`local_notifier`) |
| Wake / Wi-Fi locks | OS sleep inhibit |
| `POST_NOTIFICATIONS` permission | macOS notification permission; none on Windows/Linux |
| `in_app_update` (Play) | Sparkle / WinSparkle / MSIX / GitHub releases |
| `image_picker` camera | Drop (v1) |
| `share_plus` | Copy / Export |
| `/proc/meminfo` RAM | `sysctl hw.memsize` + `vm_stat` (macOS), `GlobalMemoryStatusEx` (Windows), `/proc/meminfo` (Linux) |
| Haptics, status bar styling, splash first-frame hold | No-op |
| Plain-text token in prefs | OS keychain / credential store |

## 7. Hardware and engine work

1. **GPU on desktop.** Add backends Metal, CUDA (needs `GGML_CUDA` build config), Vulkan, CPU to the GPU enum and probe. Today the probe filters Metal out, so macOS cannot use the GPU from the UI.
2. **Threads.** Expose a CPU-threads setting; default to physical cores (mobile is fixed at 2).
3. **GPU layers.** Allow partial offload (mobile is all-or-nothing).
4. **Re-tune constants** built for phones: device classes (by RAM), assumed bandwidth (6/12/26 GB/s), 55% memory budget, tok/s clamp (≤ 60), bandwidth sanity range (≤ 200 GB/s). Apple M-series Max/Ultra and discrete GPUs exceed these.
5. **Fit with VRAM.** When offloading to a discrete GPU, check VRAM, not only system RAM.
6. **Keep models loaded longer** (mobile unloads after 120 s idle). **Open – D7:** desktop idle timeout and a manual "Unload" button.

## 8. Fix before or during the port

These mobile bugs affect shared code, so the desktop inherits them unless fixed ([09-known-issues.md](09-known-issues.md)):

| Must fix | Why |
|---|---|
| C1, C2 context-trim crash and image corruption | Desktop users paste large text and images more often |
| C3 switching chats mid-stream | The persistent sidebar makes this much easier to hit |
| C4 attachments sticking to the composer | Same |
| S1 API vision drops the projector | Breaks vision for API and Chat |
| S2 samples missing the bearer header | LAN users copy samples |
| S5 stack traces in API errors | Desktop LAN servers are more exposed |
| E1 GPU build flags / probe | Needed for Metal/CUDA anyway |
| C5 thinking text | Desktop users will run bigger reasoning models |

## 9. Suggested milestones

| Phase | Scope | Done when |
|---|---|---|
| M0 Foundations | Add macOS runner; builds fllama with Metal; RAM detection; fix C1–C4, S1 | `flutter run -d macos` chats with a catalog model on Metal |
| M1 Desktop shell | Nav rail, chat sidebar, popovers, keyboard shortcuts, drag-and-drop, window sizing | All mobile chat + models features usable with mouse and keyboard |
| M2 Server | Tray icon, close-to-tray, launch at login, sleep inhibit, keychain token, firewall flow | API works with the window closed; LAN works after the firewall prompt |
| M3 Hardware | GPU backends, threads, layers, re-tuned fit and recommendations, desktop catalog | Benchmark and recommendations look right on a 16 GB and a 64 GB machine |
| M4 Ship macOS | Signing, notarization, auto-update, first-run copy | Signed DMG installs and updates itself |
| M5 Windows (then Linux) | Windows runner, Vulkan, installer, signing | Same acceptance as macOS |

## 10. Acceptance checklist (per platform)

- [ ] Fresh install → catalog download → offline chat works with Wi-Fi off.
- [ ] Every endpoint in [05-server-and-api.md](05-server-and-api.md) answers the same as on Android (same JSON shapes).
- [ ] VS Code Continue, OpenAI Python SDK and an Ollama client work with the Quick start samples.
- [ ] Server keeps serving with the window closed; tray Stop works.
- [ ] English and Tamil UI both complete; no phone-specific wording.
- [ ] Benchmark, Tamil eval, HF search, import, pause/resume download all work.
- [ ] RAM fit and context cap are correct on the target machine.

## 11. Open questions

| Id | Question |
|---|---|
| D1 | One app with adaptive layouts, or a separate desktop entry point? |
| D2 | Platform order: macOS → Windows → Linux? Intel Macs supported? |
| D3 | Move chat storage to SQLite (no 40-chat cap, full-text search)? |
| D4 | Add a desktop catalog tier (7B–14B+)? Which models? |
| D5 | Reuse GGUFs from LM Studio / Ollama / HF cache? |
| D6 | Add an API request log on the Server page? |
| D7 | Idle unload timeout on desktop, and a manual Unload button? |
| D8 | Positioning vs Ollama / LM Studio / Jan: what is Thinai Desktop's reason to exist (Tamil, phone + desktop pairing, privacy-first UX)? This decides what to build first |
| D9 | Distribution: website download, Mac App Store, Microsoft Store, winget/Homebrew? (Mac App Store sandbox limits the models folder and LAN server) |
| D10 | Free and open source like mobile (MIT), or a paid tier? |
