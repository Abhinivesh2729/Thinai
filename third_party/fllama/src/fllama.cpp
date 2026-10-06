// fllama.cpp — Phase 3: thin adapter over llama.cpp's server_context
//
// fllama_inference() spawns a reader thread that posts a server_task and
// streams results back via the Dart callback.  Multiple concurrent calls
// are batched automatically by server_context::update_slots().

#include "fllama.h"
#include "fllama_inference_queue.h"
#include "fllama_mtmd.h"

// server-context headers (no HTTP / httplib dependency)
#include "server-context.h"
#include "server-task.h"
#include "server-common.h"

#include "llama.cpp/common/chat.h"
#include "llama.cpp/common/common.h"
#include "llama.cpp/ggml/include/ggml.h"
#include "llama.cpp/include/llama.h"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstring>
#include <deque>
#include <iostream>
#include <mutex>
#include <random>
#include <string>
#include <thread>
#include <vector>

#include "ggml-backend.h"

// ── Logging ──────────────────────────────────────────────────────────────────

static void log_message(const char *msg,
                        fllama_log_callback logger = nullptr) {
  if (!logger) {
    fprintf(stderr, "%s\n", msg);
    fflush(stderr);
    return;
  }
  static std::mutex mtx;
  static std::deque<std::string> q;
  std::string s(msg);
  for (size_t p = 0; (p = s.find('\n', p)) != std::string::npos; p += 4)
    s.replace(p, 1, "[NL]");
  std::lock_guard<std::mutex> lk(mtx);
  q.push_back(std::move(s));
  while (q.size() > 1000)
    q.pop_front();
  logger(q.back().c_str());
}
static void log_message(const std::string &m,
                        fllama_log_callback l = nullptr) {
  log_message(m.c_str(), l);
}

// ── Globals ──────────────────────────────────────────────────────────────────

#ifdef GGML_USE_VULKAN
#include "ggml-vulkan.h"
#endif
#ifdef GGML_USE_OPENCL
#include "ggml-opencl.h"
#endif

// Intentionally leaked — avoids static destruction order crash on exit.
// (ggml Metal statics may be destroyed before g_mgr's destructor runs,
//  causing ggml_abort when server_context tries to free Metal resources.)
static ServerManager &g_mgr = *new ServerManager();
static std::once_flag  g_backend_init;

static void fllama_backend_init_once() {
  std::call_once(g_backend_init, [] {
    ggml_backend_load_all();
    llama_backend_init();
  });
}

// ── GPU backends ─────────────────────────────────────────────────────────────
//
// On Android (FLLAMA_LAZY_GPU_REG) ggml's registry does not register Vulkan or
// OpenCL at startup, so a CPU-only user never loads a vendor GPU driver (a
// broken one can crash during enumeration). They are registered here, once
// each, the first time a request or a device probe asks for them.

static const char *const FLLAMA_REG_VULKAN = "Vulkan"; // GGML_VK_NAME
static const char *const FLLAMA_REG_OPENCL = "OpenCL"; // ggml_backend_opencl_reg_get_name

#ifdef FLLAMA_LAZY_GPU_REG
// Serialises registrations: register_backend() appends to the registry's
// vectors, which must not happen concurrently.
static std::mutex g_gpu_reg_mutex;
#endif

static void fllama_register_gpu_backends(int32_t kind) {
  fllama_backend_init_once();
#ifdef FLLAMA_LAZY_GPU_REG
#  ifdef GGML_USE_VULKAN
  if (kind == FLLAMA_GPU_BACKEND_AUTO || kind == FLLAMA_GPU_BACKEND_VULKAN) {
    static std::once_flag once;
    std::call_once(once, [] {
      std::lock_guard<std::mutex> lk(g_gpu_reg_mutex);
      if (getenv("GGML_DISABLE_VULKAN") != nullptr) {
        return;
      }
      // nullptr when there is no Vulkan 1.2 loader/driver; register ignores it.
      ggml_backend_register(ggml_backend_vk_reg());
    });
  }
#  endif
#  ifdef GGML_USE_OPENCL
  if (kind == FLLAMA_GPU_BACKEND_AUTO || kind == FLLAMA_GPU_BACKEND_OPENCL) {
    static std::once_flag once;
    std::call_once(once, [] {
      std::lock_guard<std::mutex> lk(g_gpu_reg_mutex);
      // Probes via the lazy libOpenCL.so shim; only Adreno devices survive
      // (see fllama_opencl_device_supported in ggml-opencl.cpp).
      ggml_backend_register(ggml_backend_opencl_reg());
    });
  }
#  endif
#else
  (void) kind;
#endif
}

static bool fllama_dev_is_backend(ggml_backend_dev_t dev, const char *reg_name) {
  ggml_backend_reg_t reg = ggml_backend_dev_backend_reg(dev);
  return reg != nullptr && std::strcmp(ggml_backend_reg_name(reg), reg_name) == 0;
}

// GPU (discrete or integrated) devices currently registered. Mobile GPUs report
// as integrated (IGPU) under Vulkan, so both types count.
static std::vector<ggml_backend_dev_t> fllama_list_gpu_devices() {
  std::vector<ggml_backend_dev_t> devices;
  for (size_t i = 0; i < ggml_backend_dev_count(); ++i) {
    auto * dev = ggml_backend_dev_get(i);
    if (dev == nullptr) {
      continue;
    }
    const auto type = ggml_backend_dev_type(dev);
    if (type != GGML_BACKEND_DEVICE_TYPE_GPU &&
        type != GGML_BACKEND_DEVICE_TYPE_IGPU) {
      continue;
    }
    devices.push_back(dev);
  }
  return devices;
}

// Registers every GPU backend, then lists devices. Used by the FFI probes.
static std::vector<ggml_backend_dev_t> fllama_get_gpu_devices() {
  fllama_register_gpu_backends(FLLAMA_GPU_BACKEND_AUTO);
  return fllama_list_gpu_devices();
}

static const char *fllama_gpu_backend_label(int32_t kind) {
  switch (kind) {
    case FLLAMA_GPU_BACKEND_NONE:   return "none";
    case FLLAMA_GPU_BACKEND_AUTO:   return "auto";
    case FLLAMA_GPU_BACKEND_VULKAN: return "vulkan";
    case FLLAMA_GPU_BACKEND_OPENCL: return "opencl";
    default:                        return "unknown";
  }
}

// Picks exactly one device for [requested] (FLLAMA_GPU_BACKEND_*), or nullptr
// for CPU. [*out_kind] receives the concrete backend used (NONE on fallback).
//   auto   -> OpenCL device on an Adreno GPU, else first Vulkan device, else CPU
//   vulkan -> first Vulkan device, else CPU
//   opencl -> first OpenCL device, else CPU
static ggml_backend_dev_t fllama_select_gpu_device(int32_t requested,
                                                   int32_t *out_kind,
                                                   fllama_log_callback logger) {
  *out_kind = FLLAMA_GPU_BACKEND_NONE;
  if (requested == FLLAMA_GPU_BACKEND_NONE) {
    return nullptr;
  }
  if (requested < FLLAMA_GPU_BACKEND_NONE || requested > FLLAMA_GPU_BACKEND_OPENCL) {
    log_message("[fllama] Unknown gpu_backend " + std::to_string(requested) +
                    ", using CPU",
                logger);
    return nullptr;
  }

  fllama_register_gpu_backends(requested);

  ggml_backend_dev_t vulkan = nullptr;
  ggml_backend_dev_t opencl = nullptr;
  for (auto *dev : fllama_list_gpu_devices()) {
    if (!vulkan && fllama_dev_is_backend(dev, FLLAMA_REG_VULKAN)) vulkan = dev;
    if (!opencl && fllama_dev_is_backend(dev, FLLAMA_REG_OPENCL)) opencl = dev;
  }

  ggml_backend_dev_t chosen = nullptr;
  switch (requested) {
    case FLLAMA_GPU_BACKEND_AUTO: {
      const char *desc = opencl ? ggml_backend_dev_description(opencl) : nullptr;
      if (desc && std::strstr(desc, "Adreno")) {
        chosen = opencl;
        *out_kind = FLLAMA_GPU_BACKEND_OPENCL;
      } else if (vulkan) {
        chosen = vulkan;
        *out_kind = FLLAMA_GPU_BACKEND_VULKAN;
      }
      break;
    }
    case FLLAMA_GPU_BACKEND_VULKAN:
      chosen = vulkan;
      if (chosen) *out_kind = FLLAMA_GPU_BACKEND_VULKAN;
      break;
    case FLLAMA_GPU_BACKEND_OPENCL:
      chosen = opencl;
      if (chosen) *out_kind = FLLAMA_GPU_BACKEND_OPENCL;
      break;
  }

  if (chosen == nullptr) {
    log_message(std::string("[fllama] gpu_backend=") +
                    fllama_gpu_backend_label(requested) +
                    ": no usable GPU device, falling back to CPU",
                logger);
  } else {
    log_message(std::string("[fllama] gpu_backend=") +
                    fllama_gpu_backend_label(requested) + ": using " +
                    ggml_backend_dev_name(chosen) + " (" +
                    ggml_backend_dev_description(chosen) + ")",
                logger);
  }
  return chosen;
}

// The device mtmd's clip would pick on its own (first GPU, else first IGPU),
// used to allow the projector on the GPU only when that is the chosen device.
static ggml_backend_dev_t fllama_clip_default_device() {
  ggml_backend_dev_t dev = ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_GPU);
  return dev ? dev : ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_IGPU);
}

static void fllama_copy_cstr(char * dst, size_t cap, const char * src) {
  if (dst == nullptr || cap == 0) {
    return;
  }
  std::snprintf(dst, cap, "%s", src ? src : "");
}

// ── The actual inference logic (runs on per-request thread) ──────────────────

static void run_inference(fllama_inference_request request,
                          fllama_inference_callback callback) {
  try {
    int64_t t0 = ggml_time_ms();
    log_message("[fllama] Inference start", request.dart_logger);

    // One-time backend init.
    fllama_backend_init_once();

    // ── 1. Build common_params ────────────────────────────────────────

    common_params params;
    params.model.path       = request.model_path;
    params.n_ctx            = request.context_size;
    // Match llama.cpp server defaults more closely instead of tying batch
    // sizes to the full context window.
    params.n_batch          = std::min<int32_t>(request.context_size, 2048);
    params.n_ubatch         = std::min<int32_t>(params.n_batch, 512);
    params.flash_attn_type  = LLAMA_FLASH_ATTN_TYPE_AUTO;
    params.n_parallel       = ServerManager::DEFAULT_N_PARALLEL;
    params.n_predict        = request.max_tokens;
    params.sampling.temp    = request.temperature;
    params.sampling.top_p   = request.top_p;
    params.sampling.penalty_freq   = request.penalty_freq;
    params.sampling.penalty_repeat = request.penalty_repeat;
    params.cpuparams.n_threads     = request.num_threads;
    params.use_jinja = true;
    params.reasoning_format = COMMON_REASONING_FORMAT_AUTO;

    // Default is 8192 MiB — way too much for mobile/embedded.
    // 0 = disable host-memory prompt caching entirely.
    // The KV cache in the llama_context still handles prompt reuse;
    // this only controls the EXTRA host-RAM cache from PR #16391.
    params.cache_ram_mib = 0;

    // Concrete GPU backend this load uses (NONE on CPU / fallback). Part of
    // the context-cache key.
    int32_t gpu_backend_used = FLLAMA_GPU_BACKEND_NONE;
#if TARGET_IPHONE_SIMULATOR
    params.n_gpu_layers = 0;
#elif defined(FLLAMA_LAZY_GPU_REG)
    // Android: GPU offload is opt-in per request, and llama.cpp is handed
    // exactly one device. Left to its default selection with both Vulkan and
    // OpenCL registered, it would split layers across the two backends.
    {
      ggml_backend_dev_t gpu_dev = nullptr;
      if (request.num_gpu_layers != 0) {
        gpu_dev = fllama_select_gpu_device(request.gpu_backend,
                                           &gpu_backend_used,
                                           request.dart_logger);
      }
      if (gpu_dev != nullptr) {
        params.devices      = {gpu_dev, nullptr}; // llama.cpp wants a nullptr terminator
        params.n_gpu_layers = request.num_gpu_layers;
      } else {
        // Empty, terminated list: CPU only, including op offload.
        params.devices      = {nullptr};
        params.n_gpu_layers = 0;
      }
      // clip picks its own GPU; only let it when that is the chosen device.
      params.mmproj_use_gpu =
          gpu_dev != nullptr && fllama_clip_default_device() == gpu_dev;
    }
#else
    params.n_gpu_layers = request.num_gpu_layers;
#endif

    if (request.model_mmproj_path && strlen(request.model_mmproj_path) > 0)
      params.mmproj.path = request.model_mmproj_path;

    // ── 2. Get or create server_context ───────────────────────────────

    auto *srv = g_mgr.get_or_create(
        request.model_path, params, request.dart_logger, gpu_backend_used);
    if (!srv || !srv->srv_ctx) {
      callback("Error: Failed to create inference context", "", true);
      return;
    }
    // RAII — release when we leave scope.
    struct Guard {
      ServerManager &m; std::string p;
      ~Guard() { m.release(p); }
    } guard{g_mgr, request.model_path};

    log_message("[fllama] Model ready (" +
                    std::to_string(ggml_time_ms() - t0) + " ms)",
                request.dart_logger);

    // ── 3. Build the prompt ───────────────────────────────────────────

    std::string prompt = request.input ? request.input : "";
    common_chat_parser_params parser_params;
    bool is_oai = false;

    if (request.openai_request_json_string) {
      is_oai = true;
      try {
        auto body = nlohmann::ordered_json::parse(
            request.openai_request_json_string);

        std::string jinja_tmpl;
        if (body.contains("jinja_template") &&
            body["jinja_template"].is_string()) {
          jinja_tmpl = body["jinja_template"].get<std::string>();
          body.erase("jinja_template");
        }

        auto *lctx  = srv->srv_ctx->get_llama_context();
        auto *model  = llama_get_model(lctx);
        auto  tmpls  = common_chat_templates_init(model, jinja_tmpl);

        try {
          std::map<std::string, std::string> empty;
          common_chat_format_example(tmpls.get(), true, empty);
        } catch (...) {
          tmpls = common_chat_templates_init(model, "chatml");
        }

        if (body.contains("messages") && body["messages"].is_array()) {
          common_chat_templates_inputs inputs;
          inputs.use_jinja = true;
          inputs.add_generation_prompt = true;
          inputs.messages =
              common_chat_msgs_parse_oaicompat(body["messages"]);

          // Default to automatic reasoning extraction for modern reasoning/
          // channel-based templates (Qwen, GPT-OSS/Harmony, etc). Allow the
          // request body to override explicitly.
          inputs.reasoning_format = COMMON_REASONING_FORMAT_AUTO;
          inputs.enable_thinking = true;
          if (body.contains("reasoning_format") && body["reasoning_format"].is_string()) {
            inputs.reasoning_format = common_reasoning_format_from_name(
                body["reasoning_format"].get<std::string>());
          }

          if (body.contains("tools")) {
            inputs.tools =
                common_chat_tools_parse_oaicompat(body["tools"]);
            inputs.tool_choice =
                body.contains("tool_choice")
                    ? common_chat_tool_choice_parse_oaicompat(
                          body["tool_choice"]
                              .template get<std::string>())
                    : COMMON_CHAT_TOOL_CHOICE_AUTO;
          }

          auto result =
              common_chat_templates_apply(tmpls.get(), inputs);
          prompt = result.prompt;
          parser_params = common_chat_parser_params(result);
          parser_params.reasoning_format = inputs.reasoning_format;
          parser_params.reasoning_in_content =
              (inputs.reasoning_format == COMMON_REASONING_FORMAT_DEEPSEEK_LEGACY);
          if (!result.parser.empty()) {
            parser_params.parser.load(result.parser);
          }

          log_message("[JPZ] fllama inputs.reasoning_format=" +
                          std::string(common_reasoning_format_name(inputs.reasoning_format)),
                      request.dart_logger);
          log_message("[fllama] Chat format: " +
                          std::string(common_chat_format_name(
                              result.format)),
                      request.dart_logger);
          log_message("[JPZ] PROMPT (" +
                          std::to_string(prompt.size()) + " chars):\n" +
                          prompt,
                      request.dart_logger);
        }
      } catch (const std::exception &e) {
        log_message(std::string("[fllama] OAI parse error: ") + e.what(),
                    request.dart_logger);
        is_oai = false;
      }
    }

    // ── 4. Multimodal — extract base64 → raw bytes ───────────────────

    std::vector<raw_buffer> files;
    if (fllama_prompt_contains_image(prompt)) {
      auto img = fllama_extract_images(prompt);
      prompt = std::move(img.text_with_markers);
      for (auto &fb : img.file_bytes)
        files.push_back(std::move(fb));
      log_message("[fllama] Extracted " +
                      std::to_string(files.size()) + " image(s)",
                  request.dart_logger);
    }

    // ── 5. Create & post the server task ──────────────────────────────

    auto reader = srv->srv_ctx->get_response_reader();

    server_task task(SERVER_TASK_TYPE_COMPLETION);
    task.id         = reader.get_new_id();
    task.index      = 0;
    task.cli        = true;
    task.cli_prompt = prompt;
    task.cli_files  = std::move(files);

    task.params.stream       = true;
    task.params.cache_prompt = true;
    task.params.n_predict    = request.max_tokens;
    task.params.sampling.temp           = request.temperature;
    task.params.sampling.top_p          = request.top_p;
    task.params.sampling.penalty_freq   = request.penalty_freq;
    task.params.sampling.penalty_repeat = request.penalty_repeat;

    std::random_device rd;
    task.params.sampling.seed = rd();

    if (is_oai) {
      task.params.res_type           = TASK_RESPONSE_TYPE_OAI_CHAT;
      task.params.oaicompat_model    = request.model_path;
      task.params.oaicompat_cmpl_id  = gen_chatcmplid();
      task.params.chat_parser_params = parser_params;
    }

    reader.post_task(std::move(task));

    // ── 6. Read results, invoke callbacks ─────────────────────────────

    int rid = request.request_id;
    auto should_stop = [&] { return g_mgr.is_cancelled(rid); };

    std::string full_content;
    std::string last_json;

    while (reader.has_next()) {
      server_task_result_ptr res;
      try {
        res = reader.next(should_stop);
      } catch (const std::exception &e) {
        // Final parse can fail (e.g. doubled generated_text in update_chat_msg).
        // Log and break — we still have the accumulated text + last good JSON.
        log_message(std::string("[JPZ] reader.next() threw: ") + e.what(),
                    request.dart_logger);
        break;
      }
      if (!res) break;

      if (res->is_error()) {
        auto ej = res->to_json();
        std::string msg = ej.contains("message")
                              ? ej["message"].get<std::string>()
                              : ej.dump();
        callback(msg.c_str(), "", true);
        g_mgr.clear_cancel(rid);
        g_mgr.unregister_request_thread(rid);
        return;
      }

      auto *partial =
          dynamic_cast<server_task_result_cmpl_partial *>(res.get());
      if (partial) {
        full_content += partial->content;
        log_message("[fllama] token: \"" + partial->content +
                    "\"  cumulative(" + std::to_string(full_content.size()) +
                    " chars)",
                    request.dart_logger);
        auto j = res->to_json();
        if (!j.is_null()) {
          last_json = j.dump();
          callback(full_content.c_str(), last_json.c_str(), false);
        }
        continue;
      }

      auto *final_r =
          dynamic_cast<server_task_result_cmpl_final *>(res.get());
      if (final_r) {
        // Keep accumulated full_content — final_r->content can be
        // empty or corrupted for tool-call / reasoning completions.
        try {
          auto j = res->to_json();
          last_json = j.is_null() ? "" : j.dump();
          log_message("[JPZ] final to_json() is_null=" +
                          std::to_string(j.is_null()) +
                          " type=" + std::to_string((int)j.type()) +
                          " size=" + std::to_string(j.size()) +
                          " dump=" + last_json.substr(0, 200),
                      request.dart_logger);
        } catch (const std::exception &e) {
          log_message(std::string("[JPZ] final to_json() THREW: ") + e.what(),
                      request.dart_logger);
          last_json = "";
        }
        log_message("[JPZ] final_r->content(" +
                        std::to_string(final_r->content.size()) +
                        ")=\"" + final_r->content.substr(0, 100) + "\"",
                    request.dart_logger);
        callback(full_content.c_str(), last_json.c_str(), true);

        log_message("[fllama] Done. " +
                        std::to_string(final_r->n_decoded) + " tok, " +
                        std::to_string(ggml_time_ms() - t0) + " ms",
                    request.dart_logger);
        g_mgr.clear_cancel(rid);
        g_mgr.unregister_request_thread(rid);
        return;
      }
    }

    // Cancelled or exhausted without final result.
    callback(full_content.c_str(), last_json.c_str(), true);
    g_mgr.clear_cancel(rid);
    g_mgr.unregister_request_thread(rid);

  } catch (const std::exception &e) {
    std::string msg = "Error: " + std::string(e.what());
    callback(msg.c_str(), "", true);
    g_mgr.clear_cancel(request.request_id);
    g_mgr.unregister_request_thread(request.request_id);
  } catch (...) {
    callback("Error: Unknown exception", "", true);
    g_mgr.clear_cancel(request.request_id);
    g_mgr.unregister_request_thread(request.request_id);
  }
}

// ── FFI entry points ─────────────────────────────────────────────────────────

extern "C" {

EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT int fllama_get_gpu_device_count(void) {
  return static_cast<int>(fllama_get_gpu_devices().size());
}

EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT int fllama_get_gpu_device_backend(
    int gpu_index,
    char * out_backend,
    size_t out_backend_size) {
  if (out_backend == nullptr || out_backend_size == 0) {
    return 1;
  }
  out_backend[0] = '\0';
  if (gpu_index < 0) {
    return 2;
  }
  auto devices = fllama_get_gpu_devices();
  if (static_cast<size_t>(gpu_index) >= devices.size()) {
    return 3;
  }
  ggml_backend_reg_t reg =
      ggml_backend_dev_backend_reg(devices[static_cast<size_t>(gpu_index)]);
  fllama_copy_cstr(out_backend, out_backend_size,
                   reg ? ggml_backend_reg_name(reg) : "");
  return 0;
}

EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT int fllama_get_gpu_memory_info(
    int gpu_index,
    struct fllama_gpu_memory_info * out_info) {
  if (out_info == nullptr) {
    return 1;
  }

  std::memset(out_info, 0, sizeof(*out_info));

  if (gpu_index < 0) {
    return 2;
  }

  auto devices = fllama_get_gpu_devices();
  if (static_cast<size_t>(gpu_index) >= devices.size()) {
    return 3;
  }

  auto * dev = devices[static_cast<size_t>(gpu_index)];
  ggml_backend_dev_props props{};
  ggml_backend_dev_get_props(dev, &props);

  size_t total = props.memory_total;
  size_t free = props.memory_free;

  // Metal reports free as recommendedMaxWorkingSetSize - currentAllocatedSize.
  // If currentAllocatedSize exceeds the recommendation, the backend can
  // underflow the unsigned subtraction. Clamp that to zero here.
  if (total == 0) {
    free = 0;
  } else if (free > total) {
    free = 0;
  }

  out_info->device_index = gpu_index;
  out_info->total_bytes = static_cast<uint64_t>(total);
  out_info->free_bytes = static_cast<uint64_t>(free);
  fllama_copy_cstr(out_info->name, sizeof(out_info->name), props.name);
  fllama_copy_cstr(
      out_info->description,
      sizeof(out_info->description),
      props.description);
  fllama_copy_cstr(
      out_info->device_id,
      sizeof(out_info->device_id),
      props.device_id);
  return 0;
}

EMSCRIPTEN_KEEPALIVE void fllama_inference(fllama_inference_request request,
                                           fllama_inference_callback callback) {
  int rid = request.request_id;
  std::thread t([request, callback] { run_inference(request, callback); });
  g_mgr.register_request_thread(rid, std::move(t));
}

EMSCRIPTEN_KEEPALIVE void
fllama_inference_sync(fllama_inference_request request,
                      fllama_inference_callback callback) {
  // Synchronous variant — blocks the calling thread.
  run_inference(request, callback);
}

EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT void
fllama_inference_cancel(int request_id) {
  g_mgr.cancel(request_id);
}

} // extern "C"
