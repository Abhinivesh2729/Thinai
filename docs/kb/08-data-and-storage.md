# 8. Data and storage

Thinai has no backend and no account. Everything lives on the device in two places: **app settings** (Flutter `SharedPreferences`) and the **models folder**.

## 8.1 Saved settings and data (SharedPreferences)

| Key | Type | Default | Holds | Owner |
|---|---|---|---|---|
| `chat_sessions_v1` | JSON | — | All conversations (see 8.3) | `lib/state/providers.dart` |
| `chat_history_v1` | JSON | — | Old single-chat format. Migrated once, then deleted | same |
| `chat_system_prompt_v1` | string | absent = language default | Custom system prompt | `lib/chat/system_prompt.dart` |
| `generation_settings_v1` | JSON | GPU `none` | GPU backend + per-model settings (see 8.4) | `lib/llm/generation_settings.dart` |
| `active_model_id` | string | absent | Active model's served id | providers |
| `web_search_enabled` | bool | **true** | Web search toggle | providers |
| `theme_mode` | `system` / `light` / `dark` | system | Theme | providers |
| `app_language` | `system` / `english` / `tamil` | system | UI language | providers |
| `default_start_page` | int 0–3 | 0 (Chat) | Start tab | providers |
| `server_port` | int | 11434 | API port | providers |
| `server_lan_share` | bool | false | LAN sharing | providers |
| `server_was_running` | bool | false | Restart server on next launch | providers |
| `server_bearer_token` | string | created on first LAN start | LAN API token (plain text) | providers |
| `benchmark_results_v1` | JSON list | — | Latest speed per model: `{id, tps, bytes, at}` | `lib/models_repo/benchmark_store.dart` |
| `tamil_eval_v1` | JSON list | — | Latest full Tamil eval report per model, including replies | `lib/models_repo/tamil_eval_store.dart` |
| `gpu_trial_pending_backend` | string | absent | GPU crash guard flag | `lib/llm/gpu_support.dart` |
| `thinai_has_completed_onboarding_v1` | bool | false | Onboarding seen | `onboarding_tour_screen.dart` |

Corrupt JSON in any store is dropped, never crashes the app.

## 8.2 Files

| Path | What |
|---|---|
| `<app support dir>/models/*.gguf` | Model weights. File name = what the user sees in Model Manager |
| `<app support dir>/models/mmproj-*.gguf` | Vision projectors. Hidden from model lists |
| `<app support dir>/models/*.gguf.part` | Partial download |
| `<app support dir>/models/*.gguf.part.json` | Partial download info: `{url, label, total, etag}` |
| temp dir | Staging for imports |

On desktop, `path_provider` gives `~/Library/Application Support/<bundle>/models` (macOS), `%APPDATA%\…` (Windows), `~/.local/share/…` (Linux).

## 8.3 Conversation format

```json
{
  "conversations": [
    {
      "id": "uuid-v4",
      "updatedAt": 1793331778000,
      "customTitle": "optional",
      "turns": [
        { "role": "user", "content": "What is the latest Flutter release?" },
        { "role": "assistant", "content": "…",
          "sources": [ { "title": "…", "url": "https://…", "snippet": "≤200 chars", "query": "…" } ] }
      ]
    }
  ]
}
```

- Saved when a message is sent and when the reply ends, plus on rename/delete. Not saved per token: a reply in progress is lost if the app is killed.
- Limits: 40 conversations, 200 turns and 120,000 characters per conversation.
- **Not saved:** attachments, the exact prompt sent (web results, document text), timing, which model answered.

## 8.4 Generation settings format

```json
{
  "gpu": "none",
  "perModel": {
    "gemma-3-270m-it-q8_0": { "contextSize": 8192, "temperature": 0.7, "topK": 40, "topP": 0.95, "thinking": true }
  }
}
```

Only values different from the default are stored. Missing means "use the default".

## 8.5 Main data types

| Type | Fields | File |
|---|---|---|
| `ChatConversation` | id, turns, updatedAt, customTitle | `lib/state/providers.dart` |
| `ChatTurn` | role (user/assistant), content, sources | same |
| `WebResult` | title, url, snippet, query | `lib/web/web_search.dart` |
| `CatalogModel` | id, displayName, author, url, filename, approxBytes, parameters, contextTokens, description, kind (chat/embedding), dimensions, mmproj url/filename/bytes | `lib/models_repo/catalog.dart` |
| `LocalModel` | id (served id), displayName (file name), path, sizeBytes, modifiedAt | `lib/models_repo/model_store.dart` |
| `ModelTraits` | activeParamsB, languages, tamil, thinking, code, multimodal, tools, quality | `lib/models_repo/model_skills.dart` |
| `DeviceProfile` | totalRam, availableRam, cores → class, budget, bandwidth | `lib/models_repo/device_profile.dart` |
| `ModelGenerationSettings` | contextSize, temperature, topK, topP, thinking | `lib/llm/generation_settings.dart` |
| `BenchmarkResult` | modelId, tokensPerSecond, modelBytes, measuredAt | `lib/models_repo/benchmark_store.dart` |
| `EvalReport` | modelId, datasetVersion, overall, axes, tasks, items | `thinai_tamil_evals` package |

## 8.6 State management

All state is in Riverpod providers in `lib/state/providers.dart` (≈1,400 lines). Main ones: `chatSessionsProvider`, `activeModelIdProvider`, `modelListProvider`, `downloadsProvider`, `serverControllerProvider`, `deviceProfileProvider`, `speedKnowledgeProvider`, `themeModeProvider`, `appLanguageProvider`, `webSearchEnabledProvider`, `startPageProvider`, `appBootstrapProvider` (startup restore). This file is UI-independent and can be reused by a desktop app.
