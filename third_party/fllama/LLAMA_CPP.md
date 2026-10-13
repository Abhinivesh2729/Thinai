# Vendored llama.cpp

`src/llama.cpp` is upstream [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)
at release **`b11452`** with the patches below on top. Nothing else differs, so
an upgrade is: replace the tree with a newer release, re-apply these, rebuild.

## Local patches

Each patched spot carries a comment explaining it; most are tagged `fllama`.

| File | Why |
| --- | --- |
| `ggml/src/ggml-opencl/CMakeLists.txt` | Android: link fllama's lazy `libOpenCL.so` shim instead of a hard dependency many phones cannot satisfy. |
| `ggml/src/ggml-opencl/ggml-opencl.cpp` | Register only GPUs ggml-opencl supports (Adreno, Intel), so e.g. Mali never reaches the "Unsupported GPU" asserts. |
| `ggml/src/ggml-backend-reg.cpp` | With `FLLAMA_LAZY_GPU_REG`, skip registering Vulkan/OpenCL at startup; fllama registers them on demand. |
| `ggml/src/ggml-vulkan/ggml-vulkan.cpp` | Route `vkGetPhysicalDeviceFeatures2` through the dynamic dispatcher (Android 7/8 link stubs), and bounds-check device re-enumeration (drivers that report fewer devices the second time). |

Also dropped from the tree, as before: `build-xcframework.sh`, the
`benches/dgx-spark` log, `docs/development/llama-star/idea-arch.key` and the
llama.swiftui `IDEWorkspaceChecks.plist`.

## Upgrading

1. Find the current patch set: diff `src/llama.cpp` against the upstream tag
   above.
2. Replace `src/llama.cpp` with the new release (`git archive <tag>`).
3. Re-apply the patch. Hunks that moved upstream need porting by hand.
4. Fix fllama's own sources (`src/fllama*.cpp`) against API changes, and
   check `src/CMakeLists.txt`: its `server-context` source list must match
   `tools/server/CMakeLists.txt` upstream.
5. Verify chat and embeddings on the host (build `src/` with CMake and drive
   `fllama_inference_sync` / `fllama_embed`), then on an arm64 device.
6. Update the tag at the top of this file.
