import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:fllama/fllama_io.dart';

/// Unloads every model that is not running a request, except [keepModelPath].
///
/// Freeing a model terminates its server loop and returns gigabytes to the
/// system, so the native call runs on a separate [Isolate] and never blocks
/// the UI thread. Returns how many models were unloaded.
Future<int> fllamaReleaseIdleModels({String? keepModelPath}) {
  return Isolate.run(() => _releaseIdleModelsSync(keepModelPath));
}

int _releaseIdleModelsSync(String? keepModelPath) {
  final keep = keepModelPath == null
      ? ffi.nullptr.cast<ffi.Char>()
      : keepModelPath.toNativeUtf8().cast<ffi.Char>();
  try {
    return fllamaBindings.fllama_release_idle_models(keep);
  } finally {
    if (keep != ffi.nullptr) pkg_ffi.malloc.free(keep);
  }
}
