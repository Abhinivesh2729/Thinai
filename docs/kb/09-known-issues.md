# 9. Known issues

Found while writing this KB (2026-10-30, v2.5.0). Nothing here has been fixed. **Confirmed** means it was reproduced on the device or with a script; the rest come from reading the code.

Severity: **High** = wrong results or a stuck UI for normal use. **Medium** = wrong in some cases or misleading. **Low** = polish or dead code.

## Chat

| # | Sev. | Issue | Status | Where |
|---|---|---|---|---|
| C1 | High | **Context trimming crashes** when one message is too big for the window (e.g. a ~20K-char paste or an image at the default 8K context) and a system prompt exists. `fitToContext` reads index `result.length - 1` after removing an item, causing a `RangeError`. The composer stays stuck on "Generating…" | Confirmed (script) | `lib/chat/prompt_budget.dart` step 2 |
| C2 | High | **Images get cut by trimming.** The base64 `<img>` tag is counted as text (3.2 chars/token), so a normal photo is middle-cut and the image is destroyed | Confirmed (script) | same |
| C3 | High | **Switching chats while a reply streams** writes the reply into the newly opened chat (or loses it on New chat). Nothing blocks switching | Code reading | `providers.dart` `updateLast` / `finishExchange` write to `state.active` |
| C4 | Medium | **Attachments stick to the composer.** They are not cleared after sending, on New chat, or on switching chats, so they are re-sent with every message and can leak into another chat | Confirmed (code) | `chat_page.dart` (`_document`, `_image`) |
| C5 | Medium | **Thinking text is not handled.** Reasoning output (`<think>…</think>`) is likely shown inline, saved, and sent back as history | Not verified | `markdown_text.dart`, `llm_engine.dart` |
| C6 | Medium | Stop in Chat cancels **whatever is running** in the shared queue, which may be an API request | Code reading | `llm_engine.dart` `cancelCurrent` |
| C7 | Low | Drawer "This Month" group really means 8–30 days ago | Code reading | `chat_drawer.dart` |
| C8 | Low | Rename cannot clear a custom title; the rename field is prefilled with the English fallback title | Code reading | `chat_drawer.dart` |
| C9 | Low | "Speed test" starter chip asks the model something it cannot know | Seen on device | `chat_page.dart` |
| C10 | Low | Drawer "Model Settings" with no active model opens the first installed model's settings | Code reading | `chat_drawer.dart` |
| C11 | Low | "This model cannot read images. Try Gemma 3 4B" is hard-coded; the Image menu hint omits BMP/GIF | Code reading | l10n, `chat_page.dart` |
| C12 | Low | `ChatHistoryPage` is dead code (only tests use it) and has a double-confirm delete bug | Code reading | `lib/ui/pages/chat_history_page.dart` |
| C13 | Low | Web-search privacy copy says only the question leaves the device, but the top result page is also fetched | Code reading | `providers.dart`, `web_search.dart` |

## Models

| # | Sev. | Issue | Status | Where |
|---|---|---|---|---|
| M1 | Medium | **Too-big blocking is inconsistent.** Catalog cards show "Needs RAM" (blocked), but the Featured card, the details sheet and Hugging Face ("Download anyway") still allow the download | Code reading | `models_page.dart`, `hf_search_page.dart` |
| M2 | Medium | **"Download from URL"** bypasses the downloads controller: no progress, no pause, and its `.part` shows as "Paused" in Model Manager; tapping Resume starts a second writer on the same file | Code reading | `settings_page.dart`, `providers.dart` |
| M3 | Medium | Hugging Face downloads are always treated as chat models: embedding GGUFs get auto-activated as the chat model; vision repos get no projector | Code reading | `hf_hub.dart` |
| M4 | Medium | Deleting a model leaves its projector, benchmark and eval records behind. Manual **Load** can activate an embedding model | Code reading | `model_store.dart`, `models_page.dart` |
| M5 | Medium | No checksum after download; an existing file with the same name is silently replaced | Code reading | `downloader.dart` |
| M6 | Medium | Tamil eval scores do not feed the Tamil recommendation (still a hand-set flag), against the eval PRD's goal | Code reading | `recommender.dart` |
| M7 | Low | Tamil score chip only shows on Installed-filter cards, not on catalog or manager cards | Code reading | `models_page.dart` |
| M8 | Low | Installed models show the raw file name, not the catalog's pretty name | Seen on device | `model_store.dart` |
| M9 | Low | `ModelAdvisor` widget (reasons, caveats, speed and RAM per pick) is dead code; the page shows picks without reasons | Code reading | `lib/ui/widgets/model_advisor.dart` |
| M10 | Low | Benchmark saves stopped/partial runs and can show an engine error as "Output" | Code reading | `benchmark_page.dart` |
| M11 | Low | LFM2.5 128,000-token context displays as "125K"; DeepSeek logo matches any id with "r1" | Seen on device / code | `catalog.dart`, `model_brand_logo.dart` |

## Server and API

| # | Sev. | Issue | Status | Where |
|---|---|---|---|---|
| S1 | High | **API vision likely broken.** Every chat route calls `setActiveModel(path)` with no projector, which clears the projector; image requests pass validation but run without the image encoder. This also turns off vision for Chat until the model is re-selected | Not verified | `openai_routes.dart`, `ollama_routes.dart`, `llm_engine.dart` |
| S2 | Medium | Code samples never include the `Authorization: Bearer` header, so copied samples fail with 401 in LAN mode | Code reading | `server_page.dart` |
| S3 | Medium | The token row may stay hidden after the first LAN start until the app restarts (provider not refreshed) | Code reading | `providers.dart` `serverBearerTokenProvider` |
| S4 | Medium | API requests change the engine's active model but not the UI's "SERVING MODEL"; an empty `model` uses the alphabetically first file, not the active one | Code reading | routes, `model_store.dart` |
| S5 | Medium | Malformed JSON returns 500 with a **stack trace** in the body instead of 400 | Code reading | `api_server.dart` |
| S6 | Medium | Client disconnect does not stop generation; one long request blocks everyone | Code reading | `llm_engine.dart` |
| S7 | Low | Settings' "Share on Wi-Fi" does not restart the server, the Server tab's switch does | Code reading | `settings_page.dart` vs `server_page.dart` |
| S8 | Low | Code box status bar always says "Thinai :11434"; sample `/v1/models` says `owned_by: "thinai-local"` but the server sends `"local"`; embeddings sample uses the chat model | Code reading | `server_page.dart` |
| S9 | Low | `/api/embed` defaults to an 8192 context, `/v1/embeddings` to 2048; `/api/embed` with `num_gpu > 0` can bypass the app's GPU-off setting | Code reading | routes, `fllama_embed.cpp` |
| S10 | Low | `docs/openai-api.md` is out of date: says no auth, fixed 8K context, CPU only, images always 400, `top_p` default 1.0; omits `top_k`, `enable_thinking`, `grammar` | Code reading | `docs/openai-api.md` |
| S11 | Low | Bearer token stored in plain text; compare is not constant-time | Code reading | `providers.dart`, `api_server.dart` |
| S12 | Low | Android 15 limits `dataSync` services to ~6 h/day; the timeout callback does nothing | Code reading | `foreground_handler.dart` |

## Engine and GPU

| # | Sev. | Issue | Status | Where |
|---|---|---|---|---|
| E1 | High | **GPU is compiled out on Android.** The build hook sets `GGML_VULKAN=OFF`, `GGML_OPENCL=OFF`, `FLLAMA_ANDROID_GPU=OFF`, contradicting the GPU UI, onboarding and release notes. The test phone shows "No usable GPU. Using the CPU." | Confirmed (device + code) | `third_party/fllama/hook/build.dart` |
| E2 | Medium | Inference uses **2 CPU threads**, never configured | Code reading | `fllama_universal.dart` |
| E3 | Low | Repeat penalty fixed at 1.1 | Code reading | `fllama/lib/misc/openai.dart` |
| E4 | Low | `GpuFailureTracker.reset()` is documented but never called | Code reading | `gpu_support.dart` |

## App shell and settings

| # | Sev. | Issue | Status | Where |
|---|---|---|---|---|
| A1 | Low | Dead tour code: `AppTourDialog`, `WelcomeTourSheet`, `SpotlightCoachMarks`, `LiveGuidedTourDock` (never shown). Its copy says port 8080 | Code reading | `lib/ui/widgets/` |
| A2 | Low | Onboarding is always light and hard-codes port 11434 | Code reading | `onboarding_tour_screen.dart` |
| A3 | Low | Invalid port in Settings silently does nothing | Code reading | `settings_page.dart` |
| A4 | Low | If the update install throws, the banner spinner stays forever | Code reading | `app_updater.dart`, `app.dart` |
| A5 | Low | Web search toggle sits under "Appearance" | Seen on device | `settings_page.dart` |
| A6 | Low | "Erode, Tamilnadu" vs "Erode, Tamil Nadu" spelling; About shows "1.0.0" while loading | Seen on device / code | `made_in_erode.dart`, `splash_page.dart` |
| A7 | Low | Unused: `RECEIVE_BOOT_COMPLETED` permission, `sharedPrefsProvider`, `canDrawOverlays` check, `starterModel`; tour text says Qwen 2.5 0.5B is 390 MB (catalog: 469 MB) | Code reading | various |
| A8 | Low | Pubspec name is still `local_llm` with description "A new Flutter project." | Code reading | `pubspec.yaml` |
