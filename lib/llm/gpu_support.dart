/// GPU offload support: what the phone has, what to suggest, and how to back
/// out safely when a driver takes the app down.
///
/// Thinai runs every model on the CPU by default. The native library also
/// carries two GPU backends, and both are opt-in:
///
/// * **Vulkan** — present on practically every Android 7+ phone. Works on
///   Mali, PowerVR, Xclipse and Adreno, with quality that varies by driver.
/// * **OpenCL** — llama.cpp's Adreno-tuned kernels. Only Qualcomm Adreno GPUs
///   register a device; everything else is filtered out natively, because the
///   upstream backend asserts on GPUs it does not recognise.
///
/// Nothing here touches a GPU driver until [probeGpuDevices] is called or a
/// request is sent with a [GpuBackend] other than [GpuBackend.none]. That
/// matters: a broken vendor driver can crash the process during device
/// enumeration, and a user who never asked for the GPU should never pay for
/// that.
///
/// A driver crash cannot be caught from Dart — the process simply dies. The
/// trial helpers at the bottom exist for that case: mark the trial before the
/// first GPU load, clear it once a reply has come back, and on the next launch
/// [takeCrashedGpuTrial] tells you the previous attempt never finished, so the
/// setting can be reverted to CPU before it crashes again.
library;

import 'package:fllama/fllama.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which GPU backend a model load should use.
///
/// The order and [ffiValue]s are part of the native contract
/// (`fllama_inference_request.gpu_backend`); do not reorder.
enum GpuBackend {
  /// CPU only. Layers stay on the CPU regardless of the requested layer
  /// count, and no GPU driver is loaded.
  none,

  /// Let the native side choose: OpenCL on an Adreno GPU, otherwise Vulkan,
  /// otherwise CPU.
  auto,

  /// Vulkan, on the first Vulkan device.
  vulkan,

  /// OpenCL, on the first OpenCL device (Adreno only in practice).
  opencl;

  /// Value sent through FFI as `gpu_backend`.
  int get ffiValue => switch (this) {
    GpuBackend.none => 0,
    GpuBackend.auto => 1,
    GpuBackend.vulkan => 2,
    GpuBackend.opencl => 3,
  };

  /// Stable string for persistence. [name] is stable too, but spelling it out
  /// keeps a future rename of an enum value from silently orphaning settings.
  String get storageKey => switch (this) {
    GpuBackend.none => 'none',
    GpuBackend.auto => 'auto',
    GpuBackend.vulkan => 'vulkan',
    GpuBackend.opencl => 'opencl',
  };

  /// Inverse of [storageKey]. Unknown or missing values read as null so the
  /// caller decides the fallback, which should normally be [GpuBackend.none].
  static GpuBackend? fromStorageKey(String? value) {
    for (final backend in GpuBackend.values) {
      if (backend.storageKey == value) return backend;
    }
    return null;
  }

  /// Maps the registry name ggml reports for a device ("Vulkan", "OpenCL") to
  /// a backend. Anything else — Metal, CPU, an unknown future backend — is
  /// null and is left out of [probeGpuDevices].
  static GpuBackend? fromRegistryName(String name) {
    switch (name.toLowerCase()) {
      case 'vulkan':
        return GpuBackend.vulkan;
      case 'opencl':
        return GpuBackend.opencl;
    }
    return null;
  }
}

/// One GPU device the native library can offload to.
class GpuDevice {
  /// The backend this device belongs to. Always [GpuBackend.vulkan] or
  /// [GpuBackend.opencl]; the same physical GPU can appear once per backend.
  final GpuBackend backend;

  /// Human-readable device name, e.g. "Mali-G68" or
  /// "QUALCOMM Adreno(TM) 732". Falls back to ggml's internal id ("Vulkan0")
  /// when the driver offers no description.
  final String name;

  /// Memory the backend says it can use, in bytes. Zero means unknown: the
  /// OpenCL backend never reports memory, and mobile GPUs share system RAM
  /// anyway, so do not treat zero as "no memory".
  final int totalBytes;

  /// Currently free memory, in bytes. Zero means unknown; see [totalBytes].
  final int freeBytes;

  const GpuDevice({
    required this.backend,
    required this.name,
    required this.totalBytes,
    required this.freeBytes,
  });

  /// Whether this is a Qualcomm Adreno GPU, the one family llama.cpp's OpenCL
  /// kernels are tuned for.
  bool get isAdreno {
    final lower = name.toLowerCase();
    return lower.contains('adreno') || lower.contains('qualcomm');
  }

  @override
  String toString() => 'GpuDevice(${backend.storageKey}, $name)';
}

Future<List<GpuDevice>>? _probe;

/// Lists the GPU devices available for offload.
///
/// The first call loads the GPU drivers (Vulkan instance creation and OpenCL
/// platform discovery) on a background isolate, which can take a second or
/// two on a cold start; the result is cached for the life of the process.
/// Only call this once the user has shown interest in GPU offload — opening
/// the setting is a good moment — for the reason given in the library docs.
///
/// Never throws. Any failure yields an empty list, which callers should read
/// as "CPU only". A failed probe is not cached, so a later call can retry.
Future<List<GpuDevice>> probeGpuDevices() {
  return _probe ??= _probeUncached().then(
    (devices) => devices,
    onError: (Object _) {
      _probe = null;
      return const <GpuDevice>[];
    },
  );
}

Future<List<GpuDevice>> _probeUncached() async {
  final infos = await fllamaGpuMemoryInfoGetAll();
  final devices = <GpuDevice>[];
  for (final info in infos) {
    final backend = GpuBackend.fromRegistryName(info.backend);
    if (backend == null) continue;
    devices.add(
      GpuDevice(
        backend: backend,
        name: info.description.isNotEmpty ? info.description : info.name,
        totalBytes: info.totalBytes,
        freeBytes: info.freeBytes,
      ),
    );
  }
  return List.unmodifiable(devices);
}

/// The backend worth suggesting for [devices], mirroring what
/// [GpuBackend.auto] resolves to natively: OpenCL when an Adreno GPU is
/// present, else Vulkan when any Vulkan device is, else [GpuBackend.none].
///
/// This is a suggestion, not a guarantee of speed. On many Mali and PowerVR
/// phones Vulkan offload is slower than the CPU for small models; benchmark
/// before turning it on by default.
GpuBackend recommendedBackend(List<GpuDevice> devices) {
  if (devices.any((d) => d.backend == GpuBackend.opencl && d.isAdreno)) {
    return GpuBackend.opencl;
  }
  if (devices.any((d) => d.backend == GpuBackend.vulkan)) {
    return GpuBackend.vulkan;
  }
  return GpuBackend.none;
}

// ── Crash guard ─────────────────────────────────────────────────────────────

/// SharedPreferences key holding the backend of a GPU load that has started
/// but not yet been confirmed to work.
const String _kGpuTrialPendingKey = 'gpu_trial_pending_backend';

/// Records that a model load with [backend] is about to be attempted.
///
/// Call this before the first request that uses a newly chosen backend, and
/// await it: the write has to reach disk before the driver gets a chance to
/// kill the process. Calling it with [GpuBackend.none] clears the flag
/// instead, since a CPU load cannot be the thing that crashes.
Future<void> markGpuTrialPending(GpuBackend backend) async {
  if (backend == GpuBackend.none) return clearGpuTrialPending();
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGpuTrialPendingKey, backend.storageKey);
  } catch (_) {
    // Losing the guard is better than failing the request over it.
  }
}

/// Clears the pending trial. Call it once the GPU load has produced output
/// (the first streamed token is proof enough that the driver survived model
/// load and a forward pass), or when the load failed cleanly with an error.
Future<void> clearGpuTrialPending() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGpuTrialPendingKey);
  } catch (_) {
    // Nothing sensible to do; worst case the next launch reverts to CPU.
  }
}

/// Returns the backend of a GPU trial that was still pending when the app
/// last died, and clears the flag so it is reported only once.
///
/// Call it early in startup, before any model is loaded. A non-null result
/// means the previous launch most likely crashed inside the GPU driver: switch
/// the setting back to [GpuBackend.none] and tell the user why. Returns null
/// when there was no pending trial or the flag could not be read.
Future<GpuBackend?> takeCrashedGpuTrial() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(_kGpuTrialPendingKey);
    if (pending == null) return null;
    await prefs.remove(_kGpuTrialPendingKey);
    return GpuBackend.fromStorageKey(pending);
  } catch (_) {
    return null;
  }
}

/// How many consecutive GPU loads must fail before a backend is rested.
const int kGpuFailureThreshold = 2;

/// How long a rested backend stays on the CPU, even without a restart.
const Duration gpuCooldown = Duration(minutes: 10);

/// Counts consecutive GPU load failures per backend and rests a backend that
/// fails [kGpuFailureThreshold] times in a row.
///
/// A vendor driver can fail below the crash guard's radar: a load error that
/// comes back as a normal failure, or a device that disappears between
/// enumerations. Retrying such a backend on every request costs the user the
/// full load time and then an error; resting it keeps the session usable and
/// the saved setting untouched.
class GpuFailureTracker {
  final _failures = <GpuBackend, int>{};
  final _restedUntil = <GpuBackend, DateTime>{};

  /// Records a failed load. Returns true when the backend just crossed the
  /// threshold and is now rested.
  bool recordFailure(GpuBackend backend, {DateTime? now}) {
    if (backend == GpuBackend.none) return false;
    final count = (_failures[backend] ?? 0) + 1;
    _failures[backend] = count;
    if (count >= kGpuFailureThreshold) {
      _restedUntil[backend] =
          (now ?? DateTime.now()).add(gpuCooldown);
      _failures[backend] = 0;
      return true;
    }
    return false;
  }

  /// Clears the count after a load that produced a token.
  void recordSuccess(GpuBackend backend) => _failures.remove(backend);

  /// True while the backend is rested after repeated failures.
  bool isRested(GpuBackend backend, {DateTime? now}) {
    final until = _restedUntil[backend];
    if (until == null) return false;
    if ((now ?? DateTime.now()).isAfter(until)) {
      _restedUntil.remove(backend);
      return false;
    }
    return true;
  }

  /// Resets everything; used when the user picks a backend themselves.
  void reset() {
    _failures.clear();
    _restedUntil.clear();
  }
}
