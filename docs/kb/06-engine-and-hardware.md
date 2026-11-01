# 6. Engine and hardware

Code: `lib/llm/llm_engine.dart`, `lib/llm/generation_settings.dart`, `lib/llm/context_limits.dart`, `lib/llm/gpu_support.dart`, `lib/models_repo/gguf_metadata.dart`, `third_party/fllama/`.

## 6.1 Layers

```
LlmEngine (Dart singleton)
  └─ fllama (vendored, FFI) ─ helper isolate ─ native thread per request
       └─ llama.cpp server_context (one per loaded model)
```

`third_party/fllama` is a fork of [Telosnex/fllama](https://github.com/Telosnex/fllama) committed in the repo. It adds: embeddings (`fllama_embed`), GBNF `grammar` pass-through, explicit GPU device selection, and lazy GPU driver loading on Android.

## 6.2 Loading and running models

| Topic | Behaviour |
|---|---|
| When a model loads | On the first request that needs it, not when you pick it |
| Cache | One loaded context per model file. Reused if context size, GPU layers, GPU backend and projector match; otherwise reloaded |
| Unload | Automatic after **120 s idle** (checked every 30 s). No manual unload |
| Several models | Chat and embedding models can be loaded at the same time (until idle eviction) |
| Queue | One generation at a time, first in, first out. Chat and API share it |
| Embeddings | Separate manager and context, so they never evict the chat model |
| Threads | **2 CPU threads**, fixed (fllama default, never configured) |
| Batch | `n_batch = min(ctx, 2048)`, `n_ubatch = min(n_batch, 512)`, flash attention auto, prompt caching on |
| Chat template | Taken from the GGUF (Jinja). Falls back to ChatML if it fails |
| Seed | Random per request |
| Repeat penalty | 1.1, fixed |
| Stop words | Checked in Dart; output is cut before the match, then the native job is cancelled |
| Tool calling | llama.cpp builds the tool format from the model template and constrains output with a grammar. Works only if the template supports tools |
| Thinking | Only `enable_thinking: false` is ever sent (when switched off). The text returned is the model's content; `<think>` blocks are not separated in Dart (not verified) |

## 6.3 Generation settings

Saved per model under `generation_settings_v1` and shared by Chat and the API. An API request's own values win over saved ones.

| Setting | Default | Allowed |
|---|---|---|
| Context window | min(8192, cap) | 512 … cap (powers of 2 in the UI) |
| Temperature | 0.7 | 0 – 2 |
| Top-K | 40 | 0 – 100 in UI (0 = off) |
| Top-P | 0.95 | 0.05 – 1.0 in UI |
| Thinking | On (template default) | On / Off |
| Max tokens | Unlimited (−1) | API only |
| GPU backend | Off (CPU) | Global, see 6.5 |

## 6.4 Context cap (how big the context window may be)

```
cap = min(trained context, RAM ceiling), rounded down to a power of 2, at least 512

trained context = from the GGUF header, else the catalog, else 32,768
RAM ceiling     = (55% of total RAM − model file size − 350 MB) ÷ KV bytes per token
KV bytes/token  = layers × KV heads × (key + value length) × 2   (f16 KV cache)
```

The Model settings sheet shows why the cap is what it is: "Max 32K, the model's limit." or "Max …, limited by RAM." (seen on device for Gemma 3 270M: "Max 32K, the model's limit.").

The GGUF header is read by a pure-Dart parser (`gguf_metadata.dart`) in a background isolate. It also reads the chat template to decide whether to show the Thinking switch.

## 6.5 GPU

**UI:** Settings → Hardware → **GPU acceleration**: CPU / Auto / Vulkan / OpenCL. Default CPU. The **GPU speed test** card has **Find GPU** and a **Speed test** that runs the active model twice on CPU and twice on GPU (48 tokens each) and says "GPU is faster here.", "CPU is faster here. Keep the GPU off." or "About the same."

**Rules:**
- Auto: OpenCL for Adreno GPUs, else the first Vulkan device, else CPU.
- When a GPU is used, all layers go to it (999).
- **Crash guard:** before a GPU load the app writes a flag; if the app dies, the next launch turns the GPU off and shows "{backend} crashed last time, so the GPU was turned off."
- Two load failures in a row rest that backend for 10 minutes (CPU is used meanwhile).

**Status today:** the build hook `third_party/fllama/hook/build.dart` turns Vulkan and OpenCL **off** for Android builds. On the test phone, **Find GPU** says "No usable GPU. Using the CPU." (seen on device). So in practice Android runs on CPU. See [09-known-issues.md](09-known-issues.md#engine-and-gpu).

**Desktop note:** the build hook already supports macOS (Metal), Windows (Vulkan if the SDK is found) and Linux (CPU). But the app's GPU enum and probe only know Vulkan/OpenCL and filter Metal out, so the UI cannot turn Metal on as written. CUDA is not configured anywhere.

## 6.6 Device detection

| What | How (Android) | Desktop status |
|---|---|---|
| Total / available RAM | `/proc/meminfo` | Works on Linux only. macOS and Windows need new code, otherwise RAM is "unknown" (no fit checks, no RAM cap) |
| CPU cores | `Platform.numberOfProcessors` (logical cores) | Works |
| GPU | fllama probe (`fllamaGpuMemoryInfoGetAll`) | Needs Metal/CUDA/Vulkan awareness |
| Bandwidth | Assumed from device class, then calibrated from Benchmark results (0.5–200 GB/s accepted) | Upper limit too low for Apple M-series Max/Ultra and discrete GPUs |
