# 7. Settings and app shell

Code: `lib/ui/app.dart`, `lib/ui/pages/settings_page.dart`, `splash_page.dart`, `about_page.dart`, `contact_support_page.dart`, `lib/ui/widgets/onboarding_tour_screen.dart`, `lib/update/app_updater.dart`, `lib/l10n/`.

## 7.1 Settings (seen on device)

The Settings tab has six rows and a "Made with ❤️ in Erode, Tamilnadu" footer.

### Appearance
| Setting | Options | Default | Effect |
|---|---|---|---|
| Start page | Chat / Models / Server / Settings | Chat | Tab shown at launch |
| Language | System / English / தமிழ் | System | Changes the UI language live. Switching to Tamil opens the glossary and switches the default system prompt and default model goal to Tamil |
| Glossary | — | — | English ↔ Tamil table of 9 key terms |
| Theme | System / Dark / Light | System | App theme |
| Web search | On / Off | **On** | Same toggle as in the chat + menu |

### System Prompt
See [03-chat.md §3.8](03-chat.md#38-system-prompt).

### Hardware
- **GPU acceleration:** CPU / Auto / Vulkan / OpenCL.
- **Benchmark:** opens the Benchmark page.
- **GPU speed test:** bottom sheet with Find GPU and CPU-vs-GPU test.
- **Device:** "8 cores · 5.4 GB RAM" (read-only).

### Model & Storage
- **Active model** row with **Tune** (opens Model settings), or "No model loaded" with **Catalog**.
- **Import .gguf**, **Download from URL**, **Clear downloads** (see [04-models.md §4.4](04-models.md#44-import-and-download-by-url)).

### Local Server
- **Share on Wi-Fi** switch (default off). Applies on the next server start; it does **not** restart a running server (the Server tab's switch does).
- **Port** ":11434" → dialog. Can be changed while running; the toast says "Restart the server to apply."
- **Status:** Running / Stopped; tap → Server tab.

### About & Help
- **App tour:** replays the onboarding.
- **Check for updates** "v2.5.0 (10006)": asks Google Play (see 7.5).
- **Help & support**, **About Thinai**.

## 7.2 First run: splash and onboarding

**Splash:** logo (dark or light variant), "PRIVATE ON-DEVICE AI", a small progress bar, "CRAFTED IN ERODE, TAMIL NADU". At least 0.5 s.

**Onboarding:** 5 slides, always in a light theme, with an animated GIF each, **Skip**, back/next buttons, dots, and **Get started** on the last slide. Finishing saves `thinai_has_completed_onboarding_v1 = true`.

| # | Tag | Headline | Text |
|---|---|---|---|
| 1 | PRIVATE & OFFLINE | AI that runs on your phone | Nothing leaves your device. Works in Airplane mode. |
| 2 | MODEL CATALOG | Open models, one tap away | Llama, Gemma, Qwen and more, sized for phones. |
| 3 | GPU ACCELERATION | Fast on your hardware | llama.cpp with Adreno and Mali GPU support. |
| 4 | IMAGES & DOCUMENTS | Photos, files and the web | Attach a photo or file. Search the web too. |
| 5 | LOCAL API | Your phone, an AI server | OpenAI and Ollama API on port 11434. |

## 7.3 About page (seen on device)

- Logo, "v2.5.0 (10006)", "Private AI that runs on your phone. No internet needed."
- Features: Private and offline · GPU acceleration · Local OpenAI-compatible API · Images, documents, web search.
- Specs (hard-coded): Engine "llama.cpp C++20 FFI", Format "GGUF (Q4_K_M, Q8_0, BF16)", Architecture "ARM64-v8a NEON / FP16", Backends "CPU, Vulkan, OpenCL", License "MIT".
- Buttons: **Licenses** (Flutter's licence page), **Support**.

## 7.4 Help & Support page (seen on device)

- **Instagram** `@27_ai_27`: Open Instagram, Copy handle. This is the only support channel.
- **Device info:** "Thinai v2.5.0 (10006) | 8 CPU cores | 5.4 GB RAM | Tier: ENTRY | Model: … | Server stopped", with **Copy device info** (English-only text).
- **Common questions:** Why is loading or downloading slow? · Do my chats leave the phone? · How do I use the GPU?

## 7.5 App updates (Android, Google Play only)

- 4 s after launch, the app asks Play if a newer version exists. Builds not installed from Play (debug, sideloaded) get "unavailable".
- **Critical** update (Play priority ≥ 4, or ignored ≥ 14 days): Play's full-screen update runs first.
- Otherwise a **banner** above the bottom bar: "New version" → **Download** → "Downloading…" → "Update ready" → **Restart**. If a model download is running, it asks first ("Restart now? A model download will pause"). ✕ hides it for this session.
- Settings → Check for updates gives toasts: "Thinai is up to date", "Couldn't check for updates", etc.

## 7.6 Language (English / Tamil)

- All UI text is in `lib/l10n/app_en.arb` and `app_ta.arb` (661 keys each, none missing). Generated classes are committed.
- "System" follows the phone language (Tamil if the phone is Tamil, else English).
- Tamil rules are in [docs/TAMIL_GLOSSARY.md](../TAMIL_GLOSSARY.md): plain modern Tamil, no em dashes, and technical names (Thinai, GGUF, API, GPU, model names, endpoints, code) are never translated. Examples: Chat = உரையாடல், Model = அறிவுரு, Server = சேவகம்.
- In Tamil, letter-spacing is turned off in labels so Tamil script renders correctly.
- A few strings are English-only today: web-search and download errors, Hugging Face errors and page title, notification text, the copied device info.

## 7.7 Theme and branding

- Material 3, seeded from the logo green `#2CA048`.

| Token | Light | Dark |
|---|---|---|
| Primary | `#1B8738` | `#2CA048` |
| Background (surface) | `#FFFFFF` | `#0B0E14` |
| Card / container | `#F1F5F9` | `#171C28` |
| Text | `#0F172A` | `#F8FAFC` |
| Secondary text | `#475569` | `#94A3B8` |
| Outline | `#CBD5E1` | `#273242` |
| Error | `#DC2626` | `#DC2626` |

- No custom font; the platform default is used (Roboto with Noto Tamil on Android). Monospace for code.
- Cards have 16 px corners; buttons 12 px; the bottom bar is 68 px tall.
- Assets: `assets/images/logo_*.png` (light, dark, white), `assets/branding/`, 12 vendor logos in `assets/logos/`, 5 onboarding GIFs in `assets/onboarding/`.
- Brand line: "Made with ❤️ in Erode, Tamilnadu" (footer) / "Crafted in Erode, Tamil Nadu" (splash).

## 7.8 Android permissions

INTERNET, ACCESS_NETWORK_STATE, WAKE_LOCK, FOREGROUND_SERVICE, FOREGROUND_SERVICE_DATA_SYNC, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED (unused). No camera permission: photos go through the system camera app. Backups are off (`allowBackup="false"`).
