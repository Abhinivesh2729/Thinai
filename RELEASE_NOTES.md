# Release notes

## v2.3.12 branch

### GPU inference that falls back instead of crashing

GPU offload crashed the app on most Android phones the moment inference
started: the Vulkan loader on several drivers throws during backend
registration, and parts of the Vulkan device code re-enumerate physical
devices without checking that the answer still matches the first one — so a
driver that reports fewer devices the second time was indexed straight past
the end of the list.

Both are fixed in the native layer: a backend whose registration throws is
remembered and the request runs on the CPU, and every device re-enumeration is
now guarded so a stale device reads as "no memory" or an error instead of a
segfault.

On top of that, two GPU load failures in a row now rest the backend for ten
minutes and serve requests on the CPU — the same model, the same answers, just
not on the broken driver. The saved GPU setting is left alone, an engine that
answers clears the count, and the speed test still genuinely tests the GPU.

## v2.3.11 branch

### Context window and temperature, per model

Each model now has its own context window and temperature, set from the tune
button on the Chat tab or the "Context & temperature" card on the Server page.
Chat and the API server use the same values, so a model tuned in one behaves
the same in the other.

The context slider stops at the largest window that actually works: the smaller
of what the model was trained for (read from the model file itself, so imported
models are covered too) and what this phone's RAM can hold beside the weights.
The sheet says which one is holding it down.

API requests that send their own `temperature` or `num_ctx` still override the
saved values, but `num_ctx` is clamped to that maximum instead of being passed
through for llama.cpp to clamp or the phone to run out of memory on.
`/api/show` now reports the model's real architecture and context length.

Long conversations no longer start failing once they outgrow the window: the
oldest exchanges are trimmed first so the current question always fits.

### Web search that answers the question asked

Testers reported answers that ignored or contradicted the search. Running 15
real questions through the live search showed why:
- DuckDuckGo was answering most of them with a challenge page, which looked
  like "no results".
- Bing was matching on the loudest word: "who is the CEO of Nvidia" returned
  Delhi's Chief Electoral Officer.
- Tamil questions skipped the relevance check entirely.
- Follow-ups like "what is its price" were searched as if they stood alone.

Now:
- Queries go to Bing as keywords.
- Follow-ups carry the earlier question's subject.
- Results must cover the question to be used, best match first.
- The page read for the answer is the part that mentions the question, not the
  site's cookie banner.
- Engines that refuse are rested for ten minutes instead of making every
  question wait.
- When every engine is rate-limiting the network, the app says so.
- Stop cancels a search in progress.
- The sources sheet shows exactly what was searched.

On the same 15 questions, answers on point went from 7 to 12.

### Prompt-injection hardening

Web results, page text and attached documents are third-party content, and
they used to reach the model raw. A page containing `<|im_end|>` or
`<start_of_turn>` could end the real turn and start its own, and an
`<img src="data:…">` in a snippet was decoded as an image.

That content is now:
- wrapped in markers with a random id that it cannot forge;
- stripped of chat-template control tokens and image tags, which are broken
  with an invisible character;
- introduced to the model with an instruction to treat it as quoted data, not
  instructions.

What you type and the images you attach are untouched.

### GPU acceleration (experimental, off by default)

Settings has a new GPU card. "Check this phone's GPU" lists what the model can
run on — Vulkan on nearly every phone, OpenCL on Qualcomm Adreno — and the
choice applies to chat, the API server and the benchmark. The phone's GPU
driver is never loaded until someone asks for it.

A speed test runs the active model on the CPU and on the GPU and says which is
faster, because on many phones it is the CPU: on a Mali-G68 test phone Vulkan
worked correctly but generated about 4× slower than the CPU with a small model.
Adreno phones are expected to do better with OpenCL, but that path has not yet
been run on real hardware.

If the GPU driver ever crashes the app, the next launch switches GPU back off
and says so. Ollama clients sending `num_gpu: 0` always get the CPU; other
`num_gpu` values only take effect when GPU is switched on in the app.

The APK is larger (about 62 MB for arm64, up from 30 MB): the Vulkan shaders
and OpenCL kernels are compiled into the native library.

## 2.3.0 (build 11)

Thinai answers about today. A model on a phone is frozen at its training
cut-off, so asked for the news it used to apologise or invent something; now
the app looks the question up and hands the results to the model, which still
does all of its thinking on the device.

### Web search

On by default and automatic. Each question is judged on whether it wants live
information — news, prices, dates, scores, releases, a year, "who is", "what
happened" — and only those go out. "Write me a poem", "translate this", and
"solve 12 x 34" never touch the network, and "search the web" forces a lookup
while "without searching" blocks one. Only the question itself leaves the
phone; the conversation and the model stay on it, and the whole feature can be
switched off in Settings or from the composer.

The top result's page is read as well as its summary, which is the difference
between "the models were ranked by benchmark data" and an answer that names
them with their scores. Results that do not match the question are discarded
rather than answered from: a page ranked on one word produces a confident wrong
answer, and "nothing found" is the better outcome.

Answers carry their sources. A row of site marks under the reply opens the full
list — site, headline, and the summary the search returned — and each one opens
the page. The results behind an answer stay available to the next question, so
a follow-up like "what is the model name" is still answerable.

### Camera, and one button for attachments

The composer's paperclip is now a speed dial holding four things: take a photo,
choose an image, attach a document, and web search. Camera capture is new — the
system camera app takes the shot, so the app declares no camera permission of
its own.

## 2.1.0 (build 5)

Thinai serves embeddings. The local API is no longer chat-only: it produces
vectors, so on-device RAG, semantic search, and clustering apps can run against
a phone with no network.

### Embeddings

Three new endpoints, covering both wire formats clients already speak:

| Endpoint | Shape |
| --- | --- |
| `POST /api/embed` | `input` takes a string or an array; always returns an array of vectors |
| `POST /api/embeddings` | Legacy single `prompt` in, single `embedding` out |
| `POST /v1/embeddings` | OpenAI-compatible, with `encoding_format` (`float` or `base64`) and `dimensions` shortening |

Embeddings run in their own llama context, so a batch neither disturbs nor
queues behind chat generation already in flight.

Chat models and embedding models are not interchangeable, and the app now
treats them as distinct. A chat model has no pooling layer, so the embedding
endpoints reject it rather than return meaningless vectors; an embedding model
cannot generate text, so the Chat tab hides it.

### New models

Five embedding models, from 24 MB to 609 MB:

| Model | Size | Dimensions |
| --- | --- | --- |
| All-MiniLM L6 v2 | 24 MB | 384 |
| BGE Small EN v1.5 | 35 MB | 384 |
| Nomic Embed Text v1.5 | 95 MB | 768 |
| EmbeddingGemma 300M | 318 MB | 768 |
| Qwen 3 Embedding 0.6B | 609 MB | 1024 |

Six new chat models, spanning the range from "runs on anything" to "flagship
only":

| Model | Params | Size |
| --- | --- | --- |
| Gemma 3 270M | 270 M | 278 MB |
| LFM2 1.2B | 1.2 B | 697 MB |
| SmolLM3 3B | 3 B | 1.8 GB |
| Granite 4.0 H Micro | 3 B | 1.8 GB |
| Qwen 3 4B Instruct 2507 | 4 B | 2.3 GB |
| Gemma 3n E2B | 5 B (2 B active) | 2.8 GB |

Both catalogs now list smallest first, so what fits your phone is what you see
first.

### Server screen

The screen documented 3 endpoints while the server answered 10. It now lists
all of them, grouped into Chat, Embeddings, and Models, each with a
copy-to-clipboard curl. The app's own routes are labelled Thinai; `/v1` keeps
the "OpenAI-compatible" label, which names a real compatibility layer rather
than a vendor.

### Fixes

- The app tour no longer bounces. Every step used to drop the panel to the top
  of the screen for a moment before snapping back to the control it was
  describing; the spotlight now glides straight to the next target.
- Embedding curl examples quote an installed embedding model instead of the
  active chat model. The latter would have returned 400 on paste.

### Compatibility

Unchanged: the API still binds to `127.0.0.1` and still defaults to port
11434, and the `/api` routes still follow the Ollama wire format, so existing
Ollama and OpenAI client libraries keep working without modification.

### Known issues

`pubspec.yaml` depends on the vendored fllama fork at `third_party/fllama` by
path, but `/third_party/` is gitignored. `flutter pub get` therefore fails on a
fresh clone. Push the fork and restore a `git:` URL before building this
release anywhere other than the original working machine.
