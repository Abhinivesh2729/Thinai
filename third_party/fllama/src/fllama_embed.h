#ifndef FLLAMA_EMBED_H
#define FLLAMA_EMBED_H

// fllama_embed — embedding FFI.
//
// Upstream fllama exposes no embedding entry point: fllama.cpp only ever posts
// SERVER_TASK_TYPE_COMPLETION. This adds the other half, posting
// SERVER_TASK_TYPE_EMBEDDING to the same llama.cpp server_context machinery
// that llama-server's /embedding endpoint uses.
//
// Synchronous by design. The Dart side already runs every FFI call on a helper
// isolate (see lib/io/fllama_io_embed.dart), so a callback here would buy
// nothing and cost a thread hop.

#include "fllama.h" // FFI_PLUGIN_EXPORT

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

struct fllama_embed_request {
  const char *model_path;  // Required: .gguf path
  const char **inputs;     // Required: n_inputs NUL-terminated UTF-8 strings
  int n_inputs;            // Required: > 0
  int context_size;        // Required
  int num_gpu_layers;      // 0 = pure CPU
};

// Returned by fllama_embed(). Always free with fllama_embed_free().
//
// On success `error` is NULL and `embeddings` holds n_seq * n_embd floats,
// row-major: sequence i occupies [i * n_embd, (i + 1) * n_embd).
// On failure `error` is a message and every other field is NULL/0.
struct fllama_embed_result {
  float *embeddings;
  int32_t n_seq;
  int32_t n_embd;
  int32_t *n_tokens; // n_seq entries: tokens consumed per input
  char *error;       // NULL on success
};

// Never returns NULL except on allocation failure. The caller owns the result.
FFI_PLUGIN_EXPORT struct fllama_embed_result *
fllama_embed(struct fllama_embed_request *request);

FFI_PLUGIN_EXPORT void fllama_embed_free(struct fllama_embed_result *result);

#ifdef __cplusplus
}
#endif

#endif // FLLAMA_EMBED_H
