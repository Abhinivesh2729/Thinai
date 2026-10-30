# 4. Models

Code: `lib/ui/pages/models_page.dart`, `hf_search_page.dart`, `benchmark_page.dart`, `tamil_eval_page.dart`, and `lib/models_repo/`.

## 4.1 Models tab

### Top bar (seen on device)
| Icon | Opens |
|---|---|
| **த** | Tamil eval page |
| ⏱ (speedometer) | Benchmark page |
| Layers with a green badge | **Model Manager** sheet. The badge shows active downloads, else the installed count |

### Search and filters
- **Search models:** live filter on name, author, description, size, context and id. When text is typed, a row "Search Hugging Face for "…"" appears at the top.
- **Category ▾:** All · Chat · Vision · Embedding · Installed (n).
- **Goal ▾:** opens "Choose a goal" with 9 goals: Fast chat, Reasoning, Coding, Tamil, English, Images, Translation, Summaries, Documents. If the UI language is Tamil, the goal starts as Tamil.
- **Reset** icon appears when any filter is on.

### List layout
| State | Sections |
|---|---|
| Default (All, no goal) | **Featured** (LFM2.5 350M hero card) → **More models** → **Embedding models** → "Find more on Hugging Face" |
| Goal chosen | "Goal: X" banner (Change / ✕) → **Top picks** (up to 3, green border) → **Other models** |
| Installed filter | "Installed (n)" cards: file name, size, **த score** chip if tested, "In use" or "Tap to load", delete |
| No match | "No models match …" with Search Hugging Face / Reset filters |

Footer: "Models run fully offline on this phone."

### Model card
- Brand logo, author, name, ⋯ (Model details).
- Chips: parameters (e.g. "0.5 B"), context ("32K ctx") or dimensions for embedding models, "Vision"/"Multilingual" tag, orange **Tight fit** if it will be close on RAM.
- **Action button** (first that applies):
  1. "+ Vision (size)": weights installed, projector missing
  2. "✓ Installed"
  3. "Needs RAM" (disabled): too big for this device
  4. "Pause": downloading
  5. "Resume n%": a partial download exists
  6. Green "↓ size": download
- Progress row under the card while downloading: "n% · X / Y".

### Model details sheet (seen on device)
Author, name, one-line description, and four tiles: **Parameters**, **Context Window**, **Download Size**, **Capability**. A **Download size** button if not installed.

### Model Manager sheet (seen on device)
"Model Manager", "3 models · 1.1 GB". Shows:
- Active downloads (with Pause) and paused downloads (Resume, Discard).
- "In use: <file>".
- Each installed file: name, size, **Load** (or "Active"), **Delete** (confirm: "Delete model? … freeing size").

## 4.2 Built-in catalog

Code: `lib/models_repo/catalog.dart`. 35 models: 30 chat, 5 embedding. All download from `https://huggingface.co/<repo>/resolve/main/<file>`.

| Display name | Author | Size | Params | Context | Notes |
|---|---|---|---|---|---|
| Gemma 3 · 270M Instruct | Google | 278 MB | 270 M | 32K | Smallest |
| **LFM2.5 · 350M** | Liquid AI | 362 MB | 350 M | 128K | **Featured** |
| Qwen 2.5 · 0.5B Instruct | Alibaba | 469 MB | 0.5 B | 32K | |
| Qwen 3 · 0.6B | Alibaba | 610 MB | 0.6 B | 32K | Thinking |
| TinyLlama · 1.1B Chat | TinyLlama | 638 MB | 1.1 B | 2K | |
| LFM2 · 1.2B | Liquid AI | 697 MB | 1.2 B | 32K | |
| LFM2.5 · 1.2B Instruct | Liquid AI | 697 MB | 1.2 B | 128K | |
| Gemma 3 · 1B Instruct | Google | 769 MB | 1 B | 32K | |
| Llama 3.2 · 1B Instruct | Meta | 770 MB | 1 B | 128K | |
| Qwen 3.5 · 0.8B | Alibaba | 795 MB | 0.8 B | 256K | |
| SmolLM2 · 1.7B Instruct | Hugging Face | 1.0 GB | 1.7 B | 8K | |
| Qwen 2.5 · 1.5B Instruct | Alibaba | 1.1 GB | 1.5 B | 32K | Code |
| Qwen 3.5 · 2B | Alibaba | 1.2 GB | 2 B | 256K | Tamil, code, tools |
| LFM2.5 · 2.6B | Liquid AI | 1.6 GB | 2.6 B | 128K | Tools |
| Gemma 2 · 2B Instruct | Google | 1.6 GB | 2 B | 8K | |
| Qwen 3 · 1.7B | Alibaba | 1.7 GB | 1.7 B | 32K | Tamil, thinking, code |
| SmolLM3 · 3B | Hugging Face | 1.8 GB | 3 B | 64K | Thinking |
| Granite 4.0 · H Micro | IBM | 1.8 GB | 3 B | 128K | Tools |
| Llama 3.2 · 3B Instruct | Meta | 1.9 GB | 3 B | 128K | Tools |
| Granite 4.1 · 3B | IBM | 2.0 GB | 3 B | 128K | Tools |
| Phi-3.5 · Mini Instruct | Microsoft | 2.2 GB | 3.8 B | 128K | Thinking, code |
| Gemma 3 · 4B Instruct | Google | 2.3 GB + 0.8 GB projector | 4 B | 128K | **Vision**, Tamil |
| Phi-4 · Mini Instruct | Microsoft | 2.3 GB | 3.8 B | 128K | Thinking, code, tools |
| Qwen 3 · 4B Instruct 2507 | Alibaba | 2.3 GB | 4 B | 256K | Tamil, code, tools |
| Qwen 3 · 4B | Alibaba | 2.3 GB | 4 B | 32K | Tamil, thinking, code, tools |
| Qwen 3.5 · 4B | Alibaba | 2.6 GB | 4 B | 256K | Tamil, thinking, code, tools |
| Nemotron 3 Nano · 4B | NVIDIA | 2.6 GB | 4 B | 1M | Thinking, tools |
| Gemma 4 · E2B Instruct | Google | 2.6 GB + 0.5 GB projector | 2.3 B eff. | 256K | **Vision**, Tamil |
| Gemma 3n · E2B Instruct | Google | 2.8 GB | 5 B (2 B active) | 32K | Tamil (no projector) |
| Gemma 4 · E4B Instruct | Google | 4.3 GB + 0.5 GB projector | 4.5 B eff. | 256K | **Vision**, Tamil |
| *Embedding:* All-MiniLM L6 v2 | Sentence-Transformers | 24 MB | 22 M | 512 | 384 dims |
| BGE Small EN v1.5 | BAAI | 35 MB | 33 M | 512 | 384 dims |
| Nomic Embed Text v1.5 | Nomic | 95 MB | 137 M | 8K | 768 dims |
| EmbeddingGemma · 300M | Google | 318 MB | 300 M | 2K | 768 dims |
| Qwen 3 Embedding · 0.6B | Alibaba | 609 MB | 600 M | 32K | 1024 dims |

Each entry also has a description, an accent colour and hand-set **traits** (`lib/models_repo/model_skills.dart`): language reach (English / broad / 140+ languages), Tamil, thinking, code, multimodal, tools, and a quality nudge (0–2).

## 4.3 Downloads

Code: `lib/models_repo/downloader.dart`, `DownloadsController` in `lib/state/providers.dart`.

| Rule | Detail |
|---|---|
| Where | `<app support dir>/models/<file>.gguf` |
| While downloading | Writes `<file>.gguf.part` plus `<file>.gguf.part.json` (url, label, total size, ETag) |
| Resume | HTTP `Range` request from the saved size; uses `If-Range` with strong ETags. Handles servers that ignore Range, changed files and already-complete parts |
| Pause | Cancels the request, keeps the `.part` file |
| Stall timeout | 30 s with no data |
| Integrity | Only checks the final size matches. **No checksum** |
| Parallel downloads | No limit |
| Vision models | After the weights, the projector downloads under the same progress bar. If the projector fails, the model still counts as installed and shows "+ Vision" |
| On finish | A chat model becomes the active model automatically. Toast "Downloaded and loaded X" |
| Confirm dialog | "Download? Model (size)", with a warning if it is a tight fit or too big |
| Errors | "No internet connection", "Connection timed out…", "That model is no longer available" (404), "…needs sign-in" (401/403), "Not enough storage on this phone", server error n |
| Background (Android) | A foreground-service notification shows progress and keeps the download alive when the app is in the background |

## 4.4 Import and download by URL

Both live in **Settings → Model & Storage**.
- **Import .gguf:** pick any file. Only the `.gguf` extension is checked; the GGUF header is read later. Fails if a model with the same name exists. The file is moved (if the picker already copied it) or copied into the models folder.
- **Download from URL:** fields "GGUF URL" (must end in `.gguf`) and "Name (optional)". Uses the downloader directly, without the in-list progress UI.
- **Clear downloads:** deletes every model, projector and partial download, and unloads the active model.

## 4.5 Hugging Face search

Code: `lib/models_repo/hf_hub.dart`, `lib/ui/pages/hf_search_page.dart`. No sign-in; public repos only.

| Step | Detail |
|---|---|
| Search | `GET huggingface.co/api/models?search=…&filter=gguf&sort=downloads&limit=30`. 450 ms debounce, min 2 chars. Gated and private repos are hidden |
| Results (seen on device) | "Results (30) · Most downloaded first". Each: repo name, author, downloads, likes, last updated |
| Repo page | Name, author, short description from the README, parameter count, context, licence, downloads. Lists single-file GGUFs, smallest first, with quant (Q4_K_M, Q8_0, …), size, and a fit line: "Runs well", "Tight fit", "Too big for your phone", or "Fit unknown" |
| Hidden files | Split shards, `mmproj*`, `mtp-*`, imatrix files (counted as "n hidden") |
| Download | Pinned to the repo's commit SHA. Too-big files ask "Too big for this phone?" with **Download anyway** |
| Gated repo | "Sign-in required … Not supported yet." |

Hugging Face downloads are always treated as chat models (no projector, no embedding detection).

## 4.6 Device profile, fit and recommendations

Code: `device_profile.dart`, `recommender.dart`, `use_cases.dart`, `model_skills.dart`.

**Device profile:** total and available RAM from `/proc/meminfo`, CPU cores from the OS. Read once per session. The test phone shows "8 cores · 5.4 GB RAM", tier ENTRY (seen on device).

| Device class | Rule | Assumed memory bandwidth |
|---|---|---|
| Flagship | ≥ 7.5 GB RAM and ≥ 8 cores | 26 GB/s |
| Mid | ≥ 5.5 GB | 12 GB/s |
| Entry | below that | 6 GB/s |
| Unknown | RAM unreadable | 12 GB/s |

**Memory budget for a model** = 55% of total RAM.

**RAM fit of a model:** needed memory = file size × 1.05 + KV cache for 8K tokens + projector.
- **Comfortable** if it fits in min(80% of available RAM, budget)
- **Tight** if it fits in the budget
- **Too big** otherwise

**Speed estimate:** a measured Benchmark result wins. Otherwise bandwidth ÷ model size (GB), clamped to 0.5–60 tok/s. Once any benchmark exists, the device's real bandwidth is calibrated from it.

**Skill per goal:** hand-written rules from parameter count and traits (e.g. Coding is "excellent" for code models ≥ 3.5 B; Tamil is unsupported without the Tamil trait).

**Ranking for a goal:** score = skill × 100 − 120 if tight + speed bonus (bigger for speed goals) + 60 if installed + quality × 20 − download GB × 8. Too-big and unsupported models are skipped. Top 3 are shown as **Top picks**.

Measured Tamil eval scores do **not** feed the ranking yet; the Tamil goal still uses the hand-set trait.

## 4.7 Benchmark

Code: `lib/ui/pages/benchmark_page.dart`, `lib/models_repo/benchmark_store.dart`. Reached from Models (⏱) or Settings → Hardware.

- Pick a model from the dropdown (defaults to the active one), tap **Run benchmark**.
- Fixed prompt about how neural networks learn; 128 tokens; temperature 0.2; uses the saved GPU choice.
- Shows (seen on device, Gemma 3 270M on the test phone): gauge **28.2 tokens/second**, speed graph (peak 30.2), **First token 2.50 s**, **Tokens 128**, **Total 7.00 s**, and the generated text.
- **Best for this phone** card: device RAM, cores, measured bandwidth (8.2 GB/s), and the best pick for **Fast chat** and **Reasoning** with estimated speed.
- History: last 6 runs this session (in memory). Only the latest result per model is saved.

The **CPU vs GPU speed test** is a separate card in Settings → Hardware (see [06-engine-and-hardware.md](06-engine-and-hardware.md)).

## 4.8 Tamil eval

Code: `lib/ui/pages/tamil_eval_page.dart`, `lib/eval/engine_eval_generator.dart`, library `thinai_tamil_evals`. Design doc: [docs/tamil-eval/PRD.md](../tamil-eval/PRD.md).

- **What it measures:** 60 short questions on the phone, fully offline. Three skills:
  - **Understanding (40%)**: Reading, Grammar, Context (multiple choice), Tamil → English
  - **Expression (40%)**: English → Tamil, Short answers, Writing, Correction
  - **Knowledge (20%)**: Tamil knowledge (multiple choice)
- **How it runs:** temperature 0, thinking off, multiple choice forced to one letter A–D by a grammar. Each item is retried once on error. Shows progress on a dial, a 60-segment strip, the live reply and time left.
- **Score:** 0–100, "skill above guessing" (random guessing scores 0). Verdicts: Little Tamil (< 20), Basic (< 45), Fair (< 70), Strong.
- **Seen on device:** Gemma 3 270M scored **3** ("Little Tamil", 28 s). "Tested on this phone": LFM2.5-350M 12, Qwen 2.5 0.5B 10, Gemma 3 270M 3. Footnote: "Guessing scores 0. Scores on small sets vary, so treat gaps under 10 points as a tie."
- Tap a skill row to see each question, the model's reply and the expected answer.
- Leaving or stopping mid-run asks to confirm and saves nothing.
- The latest report per model is saved; old reports are hidden if the dataset version changes.

## 4.9 Active model

- Set by tapping a model in the Switch Model sheet, Model Manager (**Load**), an Installed card, or automatically after a chat-model download.
- Saved and restored on launch; cleared if the file is gone.
- For a vision model, the projector path is attached when it exists.
- Loading a model does not happen at selection time; the engine loads it on the first request (see [06-engine-and-hardware.md](06-engine-and-hardware.md)).
