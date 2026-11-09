/// Physical memory on Windows and macOS, which have no /proc/meminfo.
///
/// Without it every fit check on a PC said "Fit unknown" and the recommender
/// could not rule out models too big for the machine.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// (total, available) bytes, or null when the OS would not say.
typedef MemoryReading = ({int total, int available});

Future<MemoryReading?> readDesktopMemory() async {
  try {
    if (Platform.isWindows) return _windows();
    if (Platform.isMacOS) return await _macos();
  } on Object {
    // Unknown is a valid answer; callers degrade to "Fit unknown".
  }
  return null;
}

// GlobalMemoryStatusEx's MEMORYSTATUSEX.
final class _MemoryStatusEx extends Struct {
  @Uint32()
  external int dwLength;
  @Uint32()
  external int dwMemoryLoad;
  @Uint64()
  external int ullTotalPhys;
  @Uint64()
  external int ullAvailPhys;
  @Uint64()
  external int ullTotalPageFile;
  @Uint64()
  external int ullAvailPageFile;
  @Uint64()
  external int ullTotalVirtual;
  @Uint64()
  external int ullAvailVirtual;
  @Uint64()
  external int ullAvailExtendedVirtual;
}

typedef _GlobalMemoryStatusExC = Int32 Function(Pointer<_MemoryStatusEx>);
typedef _GlobalMemoryStatusExDart = int Function(Pointer<_MemoryStatusEx>);

MemoryReading? _windows() {
  final kernel32 = DynamicLibrary.open('kernel32.dll');
  final fn = kernel32
      .lookupFunction<_GlobalMemoryStatusExC, _GlobalMemoryStatusExDart>(
        'GlobalMemoryStatusEx',
      );
  final status = calloc<_MemoryStatusEx>();
  try {
    status.ref.dwLength = sizeOf<_MemoryStatusEx>();
    if (fn(status) == 0) return null;
    return (total: status.ref.ullTotalPhys, available: status.ref.ullAvailPhys);
  } finally {
    calloc.free(status);
  }
}

Future<MemoryReading?> _macos() async {
  final size = await Process.run('sysctl', ['-n', 'hw.memsize']);
  final total = int.tryParse('${size.stdout}'.trim());
  if (total == null) return null;
  // vm_stat counts pages; free + inactive + speculative is what macOS can
  // hand to a new allocation without swapping.
  final vm = await Process.run('vm_stat', const []);
  final text = '${vm.stdout}';
  final pageSize =
      int.tryParse(
        RegExp(r'page size of (\d+) bytes').firstMatch(text)?.group(1) ?? '',
      ) ??
      4096;
  int pages(String label) =>
      int.tryParse(
        RegExp('$label:\\s+(\\d+)').firstMatch(text)?.group(1) ?? '',
      ) ??
      0;
  final available =
      (pages('Pages free') +
          pages('Pages inactive') +
          pages('Pages speculative')) *
      pageSize;
  return (total: total, available: available > 0 ? available : total ~/ 2);
}
