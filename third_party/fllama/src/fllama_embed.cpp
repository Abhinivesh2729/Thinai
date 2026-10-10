// fllama_embed.cpp — embedding bridge over llama.cpp's server_context.
//
// Mirrors the structure of fllama.cpp's run_inference(), but posts
// SERVER_TASK_TYPE_EMBEDDING instead of SERVER_TASK_TYPE_COMPLETION. The
// reference implementation is server_routes::handle_embeddings_impl() in
// llama.cpp/tools/server/server-context.cpp; this is that flow with the HTTP
// layer removed.

#include "fllama_embed.h"
#include "fllama_inference_queue.h"

// server-context headers (no HTTP / httplib dependency)
#include "server-common.h"
#include "server-context.h"
#include "server-task.h"

#include "llama.cpp/common/common.h"
#include "llama.cpp/ggml/include/ggml.h"
#include "llama.cpp/include/llama.h"

#include "ggml-backend.h"

#include <cstdlib>
#include <cstring>
#include <mutex>
#include <new>
#include <string>
#include <vector>

// ── Process-wide state ───────────────────────────────────────────────────────
//
// A ServerManager of our own, separate from the one in fllama.cpp (which is
// file-static and so unreachable from here anyway). Keeping them separate is
// also what we want: an embedding context is loaded with embedding=true and a
// pooling layer, a chat context is not, so the two can never share a
// server_context. Two managers means chat and embeddings cannot evict each
// other, which is the behaviour the README documents.
static ServerManager &g_embed_mgr = *new ServerManager();
static std::once_flag g_embed_backend_init;

static void embed_backend_init_once() {
  std::call_once(g_embed_backend_init, [] {
    ggml_backend_load_all();
    llama_backend_init();
  });
}

// ── Result helpers ───────────────────────────────────────────────────────────

static fllama_embed_result *make_error(const std::string &message) {
  auto *out = static_cast<fllama_embed_result *>(
      std::calloc(1, sizeof(fllama_embed_result)));
  if (!out) {
    return nullptr;
  }
  out->error = strdup(message.c_str());
  return out;
}

// ── Entry point ──────────────────────────────────────────────────────────────

FFI_PLUGIN_EXPORT struct fllama_embed_result *
fllama_embed(struct fllama_embed_request *request) {
  if (!request || !request->model_path || !request->inputs ||
      request->n_inputs <= 0) {
    return make_error("Invalid embedding request");
  }

  try {
    embed_backend_init_once();

    // ── 1. Collect inputs ─────────────────────────────────────────────
    json prompt = json::array();
    for (int i = 0; i < request->n_inputs; i++) {
      const char *in = request->inputs[i];
      if (!in) {
        return make_error("Input content cannot be empty");
      }
      prompt.push_back(std::string(in));
    }

    // ── 2. Build common_params ────────────────────────────────────────
    const int n_ctx = request->context_size > 0 ? request->context_size : 2048;

    common_params params;
    params.model.path = request->model_path;
    params.n_ctx = n_ctx;
    // Embedding models are non-causal: a sequence has to fit in a single
    // ubatch, so batch sizes track the context window rather than the 2048/512
    // split fllama.cpp uses for generation.
    params.n_batch = n_ctx;
    params.n_ubatch = n_ctx;
    // Flash attention has no non-causal path here; AUTO can pick it and fail
    // at decode time, so pin it off.
    params.flash_attn_type = LLAMA_FLASH_ATTN_TYPE_DISABLED;
    params.n_parallel = 1;
    params.embedding = true;
    // Left UNSPECIFIED on purpose: llama.cpp then uses the pooling type the
    // model was trained with. A chat model has none, resolves to
    // LLAMA_POOLING_TYPE_NONE, and is rejected below — which is the documented
    // behaviour, and better than silently returning token-level vectors that
    // look valid and quietly break retrieval.
    params.pooling_type = LLAMA_POOLING_TYPE_UNSPECIFIED;
    params.n_gpu_layers = request->num_gpu_layers;
#ifdef FLLAMA_LAZY_GPU_REG
    // Android: once a chat request has registered a GPU backend, llama.cpp's
    // default device selection would pick it up here too, and op offload can
    // push large batches to it even with zero GPU layers. CPU means CPU: pass
    // an empty (nullptr-terminated) device list.
    if (params.n_gpu_layers <= 0) {
      params.n_gpu_layers = 0;
      params.devices = {nullptr};
    }
#endif
    params.cache_ram_mib = 0;

    // ── 3. Get or create the embedding server_context ─────────────────
    auto *srv =
        g_embed_mgr.get_or_create(request->model_path, params, nullptr);
    if (!srv || !srv->srv_ctx) {
      return make_error("Failed to load embedding model: " +
                        std::string(request->model_path));
    }
    struct Guard {
      ServerManager &m;
      std::string p;
      ~Guard() { m.release(p); }
    } guard{g_embed_mgr, request->model_path};

    const auto meta = srv->srv_ctx->get_meta();
    if (meta.pooling_type == LLAMA_POOLING_TYPE_NONE) {
      return make_error(
          "This model has no pooling layer, so it cannot produce sentence "
          "embeddings. Use an embedding model rather than a chat model.");
    }

    // ── 4. Tokenize ───────────────────────────────────────────────────
    llama_context *lctx = srv->srv_ctx->get_llama_context();
    if (!lctx) {
      return make_error("Embedding context unavailable");
    }
    const llama_model *model = llama_get_model(lctx);
    const llama_vocab *vocab = llama_model_get_vocab(model);

    // mctx is null: these are text embeddings, with no multimodal path.
    auto tokenized = tokenize_input_prompts(vocab, nullptr, prompt, true, true,
                                            mtmd_helper_init_opt_default());
    for (const auto &tokens : tokenized) {
      if (tokens.empty()) {
        return make_error("Input content cannot be empty");
      }
    }

    // ── 5. Post the tasks ─────────────────────────────────────────────
    auto reader = srv->srv_ctx->get_response_reader();
    {
      std::vector<server_task> tasks;
      tasks.reserve(tokenized.size());
      for (size_t i = 0; i < tokenized.size(); i++) {
        server_task task(SERVER_TASK_TYPE_EMBEDDING);
        task.id = reader.get_new_id();
        task.tokens = std::move(tokenized[i]);
        task.params.res_type = TASK_RESPONSE_TYPE_NONE;
        // 2 = Euclidean/L2, so cosine similarity is a plain dot product.
        task.params.embd_normalize = 2;
        tasks.push_back(std::move(task));
      }
      // post_tasks() assigns task.index in order, and wait_for_all() slots
      // results by that index — so results[i] belongs to inputs[i].
      reader.post_tasks(std::move(tasks));
    }

    // ── 6. Collect ────────────────────────────────────────────────────
    auto all = reader.wait_for_all([] { return false; });
    if (all.is_terminated) {
      return make_error("Embedding request was terminated");
    }
    if (all.error) {
      auto ej = all.error->to_json();
      return make_error(ej.contains("message")
                            ? ej["message"].get<std::string>()
                            : ej.dump());
    }

    const int32_t n_seq = static_cast<int32_t>(all.results.size());
    if (n_seq == 0) {
      return make_error("No embeddings returned");
    }

    int32_t n_embd = 0;
    for (auto &r : all.results) {
      auto *embd = dynamic_cast<server_task_result_embd *>(r.get());
      if (!embd || embd->embedding.empty() || embd->embedding[0].empty()) {
        return make_error("Model returned an empty embedding");
      }
      const int32_t dims = static_cast<int32_t>(embd->embedding[0].size());
      if (n_embd == 0) {
        n_embd = dims;
      } else if (dims != n_embd) {
        return make_error("Model returned embeddings of differing sizes");
      }
    }

    auto *out = static_cast<fllama_embed_result *>(
        std::calloc(1, sizeof(fllama_embed_result)));
    if (!out) {
      return nullptr;
    }
    out->embeddings = static_cast<float *>(
        std::calloc(static_cast<size_t>(n_seq) * n_embd, sizeof(float)));
    out->n_tokens =
        static_cast<int32_t *>(std::calloc(n_seq, sizeof(int32_t)));
    if (!out->embeddings || !out->n_tokens) {
      fllama_embed_free(out);
      return nullptr;
    }
    out->n_seq = n_seq;
    out->n_embd = n_embd;

    for (int32_t i = 0; i < n_seq; i++) {
      auto *embd =
          dynamic_cast<server_task_result_embd *>(all.results[i].get());
      // Pooled, so exactly one vector per sequence.
      std::memcpy(out->embeddings + static_cast<size_t>(i) * n_embd,
                  embd->embedding[0].data(), n_embd * sizeof(float));
      out->n_tokens[i] = embd->n_tokens;
    }

    return out;
  } catch (const std::exception &e) {
    return make_error(std::string("Embedding failed: ") + e.what());
  } catch (...) {
    return make_error("Embedding failed: unknown error");
  }
}

FFI_PLUGIN_EXPORT void fllama_embed_free(struct fllama_embed_result *result) {
  if (!result) {
    return;
  }
  std::free(result->embeddings);
  std::free(result->n_tokens);
  std::free(result->error);
  std::free(result);
}
