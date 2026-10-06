import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:fllama/fllama_io.dart';
import 'package:fllama/fllama_universal.dart';
import 'package:fllama/io/fllama_bindings_generated.dart';
import 'package:fllama/io/fllama_io_helpers.dart';

/// Returns the GPU memory information reported by ggml/llama.cpp.
///
/// On Metal, these numbers correspond to the backend's working-set budget and
/// currently available budget for this process, not literal PC-style VRAM.
///
/// The first call may be slow (several seconds) because it triggers
/// ggml/llama.cpp backend initialization.  This method runs the native
/// call on a separate [Isolate] so it never blocks the UI thread.
///
/// On Android this is also what loads the GPU drivers: the Vulkan and OpenCL
/// backends are registered on first use, and this call counts as a use. Each
/// entry's [FllamaGpuMemoryInfo.backend] names its backend ("Vulkan",
/// "OpenCL"). Safe to call before any model is loaded.
Future<List<FllamaGpuMemoryInfo>> fllamaGpuMemoryInfoGetAll() async {
  return Isolate.run(_queryGpuDevicesSync);
}

/// Size of the buffer for [FllamaBindings.fllama_get_gpu_device_backend].
const int _kBackendNameCapacity = 32;

List<FllamaGpuMemoryInfo> _queryGpuDevicesSync() {
  final count = fllamaBindings.fllama_get_gpu_device_count();
  if (count <= 0) {
    return const [];
  }

  final results = <FllamaGpuMemoryInfo>[];
  for (var i = 0; i < count; i++) {
    final ptr = pkg_ffi.calloc<fllama_gpu_memory_info>();
    final backendPtr = pkg_ffi.calloc<ffi.Char>(_kBackendNameCapacity);
    try {
      final status = fllamaBindings.fllama_get_gpu_memory_info(i, ptr);
      if (status != 0) {
        continue;
      }
      final info = ptr.ref;
      final backendStatus = fllamaBindings.fllama_get_gpu_device_backend(
        i,
        backendPtr,
        _kBackendNameCapacity,
      );
      results.add(
        FllamaGpuMemoryInfo(
          deviceIndex: info.device_index,
          totalBytes: info.total_bytes,
          freeBytes: info.free_bytes,
          name: charArrayToString(info.name, 128),
          description: charArrayToString(info.description, 256),
          deviceId: charArrayToString(info.device_id, 128),
          backend: backendStatus == 0 ? pointerCharToString(backendPtr) : '',
        ),
      );
    } finally {
      pkg_ffi.calloc.free(ptr);
      pkg_ffi.calloc.free(backendPtr);
    }
  }
  return results;
}
