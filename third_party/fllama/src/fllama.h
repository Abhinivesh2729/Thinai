#ifndef FLLAMA_H
#define FLLAMA_H

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#else
#define EMSCRIPTEN_KEEPALIVE
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#include <stddef.h> // For size_t
#include <stdint.h> // For uint8_t

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*fllama_inference_callback)(const char *response, const char * openai_response_json_string, uint8_t done);
typedef void (*fllama_log_callback)(const char *);

struct fllama_gpu_memory_info {
  int32_t device_index;
  uint64_t total_bytes;
  uint64_t free_bytes;
  char name[128];
  char description[256];
  char device_id[128];
};

struct fllama_inference_request {
  int request_id; // Required: unique ID for the request. Used for cancellation.
  int context_size;        // Required: context size
  char *input;             // Required: input text
  int max_tokens;          // Required: max tokens to generate
  char *model_path;        // Required: .ggml model file path
  char *model_mmproj_path; // Optional: .mmproj file for multimodal models.
  int num_gpu_layers; // Required: number of GPU layers. 0 for CPU only. 99 for
                      // all layers. Automatically 0 on iOS simulator.
  int num_threads; // Required: 2 recommended. Platforms can be highly sensitive
                   // to this, ex. Android stopped working with 4 suddenly.
  float
      temperature; // Optional: temperature. Defaults to 0. (llama.cpp behavior)
  float top_p; // Optional: 0 < top_p <= 1. Defaults to 1. (llama.cpp behavior)
  float penalty_freq;   // Optional: 0 <= penalty_freq <= 1. Defaults to 0.0,
                        // which means disabled. (llama.cpp behavior)
  float penalty_repeat; // Optional: 0 <= penalty_repeat <= 1. Defaults to 1.0,
                        // which means disabled. (llama.cpp behavior)
  char *
      grammar; // Optional: BNF-like grammar to constrain sampling. Defaults to
               // "" (llama.cpp behavior). See
               // https://github.com/ggerganov/llama.cpp/blob/master/grammars/README.md
  char *eos_token; // Optional: end of sequence token. Defaults to one in model file. (llama.cpp behavior)
                   // For example, in ChatML / OpenAI, <|im_end|> means the message is complete.
                   // Often times GGUF files were created incorrectly, and this should be overridden.
                   // Using fllamaChat from Dart handles this automatically.
  fllama_log_callback
      dart_logger; // Optional: Dart caller logger. Defaults to NULL.
  char * openai_request_json_string; // Optional: OpenAI JSON string. Defaults to NULL.
  // ── Appended fields: keep new fields at the END (Dart FFI layout). ──
  int32_t gpu_backend; // Optional: FLLAMA_GPU_BACKEND_*. Defaults to 0 (none).
                       // Android only: selects exactly one GPU device and
                       // registers its backend on first use. none => CPU,
                       // num_gpu_layers ignored. If the requested backend has
                       // no usable device, falls back to CPU. Ignored on other
                       // platforms (num_gpu_layers behaves as before).
};

// Values for fllama_inference_request.gpu_backend.
#define FLLAMA_GPU_BACKEND_NONE   0 // CPU only
#define FLLAMA_GPU_BACKEND_AUTO   1 // OpenCL on Adreno, else Vulkan, else CPU
#define FLLAMA_GPU_BACKEND_VULKAN 2
#define FLLAMA_GPU_BACKEND_OPENCL 3

EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT void fllama_inference(struct fllama_inference_request request,
                                        fllama_inference_callback callback);
EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT void fllama_inference_sync(struct fllama_inference_request request,
                           fllama_inference_callback callback);
EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT void fllama_inference_cancel(int request_id);

// GPU device information.
// Returns the number of GPU devices visible to ggml/llama.cpp.
EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT int fllama_get_gpu_device_count(void);

// Fills [out_info] for the GPU at [gpu_index].
// Returns 0 on success, non-zero on failure.
EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT int fllama_get_gpu_memory_info(
    int gpu_index,
    struct fllama_gpu_memory_info * out_info);

// Writes the ggml backend registry name of the GPU at [gpu_index] ("Vulkan",
// "OpenCL", "Metal", ...) into [out_backend], NUL-terminated and truncated to
// [out_backend_size]. Indices match fllama_get_gpu_memory_info. Safe before
// any model is loaded (registers the GPU backends on Android).
// Returns 0 on success, non-zero on failure.
EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT int fllama_get_gpu_device_backend(
    int gpu_index,
    char * out_backend,
    size_t out_backend_size);
#ifdef __cplusplus
}
#endif

#endif // FLLAMA_H