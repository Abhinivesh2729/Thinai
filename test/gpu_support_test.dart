import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/llm/gpu_support.dart';

void main() {
  group('GpuBackend persistence and native mapping', () {
    test('maps every backend to its stable storage key and FFI value', () {
      expect(GpuBackend.none.storageKey, 'none');
      expect(GpuBackend.none.ffiValue, 0);
      expect(GpuBackend.auto.storageKey, 'auto');
      expect(GpuBackend.auto.ffiValue, 1);
      expect(GpuBackend.vulkan.storageKey, 'vulkan');
      expect(GpuBackend.vulkan.ffiValue, 2);
      expect(GpuBackend.opencl.storageKey, 'opencl');
      expect(GpuBackend.opencl.ffiValue, 3);

      for (final backend in GpuBackend.values) {
        expect(GpuBackend.fromStorageKey(backend.storageKey), backend);
      }
      expect(GpuBackend.fromStorageKey(null), isNull);
      expect(GpuBackend.fromStorageKey('cuda'), isNull);
    });

    test('only recognizes supported native registry backends', () {
      expect(GpuBackend.fromRegistryName('Vulkan'), GpuBackend.vulkan);
      expect(GpuBackend.fromRegistryName('vUlKaN'), GpuBackend.vulkan);
      expect(GpuBackend.fromRegistryName('OpenCL'), GpuBackend.opencl);
      expect(GpuBackend.fromRegistryName('Metal'), isNull);
      expect(GpuBackend.fromRegistryName(''), isNull);
    });
  });

  group('GpuDevice', () {
    test('identifies Qualcomm and Adreno devices case-insensitively', () {
      expect(
        const GpuDevice(
          backend: GpuBackend.vulkan,
          name: 'QUALCOMM Adreno(TM) 732',
          totalBytes: 1,
          freeBytes: 1,
        ).isAdreno,
        isTrue,
      );
      expect(
        const GpuDevice(
          backend: GpuBackend.opencl,
          name: 'qualcomm integrated graphics',
          totalBytes: 0,
          freeBytes: 0,
        ).isAdreno,
        isTrue,
      );
      expect(
        const GpuDevice(
          backend: GpuBackend.vulkan,
          name: 'Mali-G68',
          totalBytes: 1,
          freeBytes: 1,
        ).isAdreno,
        isFalse,
      );
    });

    test('renders backend and name in its diagnostic string', () {
      const device = GpuDevice(
        backend: GpuBackend.vulkan,
        name: 'Mali-G68',
        totalBytes: 10,
        freeBytes: 5,
      );
      expect(device.toString(), 'GpuDevice(vulkan, Mali-G68)');
    });
  });

  group('recommendedBackend', () {
    test('prefers Adreno OpenCL over Vulkan', () {
      final devices = [
        const GpuDevice(
          backend: GpuBackend.vulkan,
          name: 'Adreno Vulkan',
          totalBytes: 1,
          freeBytes: 1,
        ),
        const GpuDevice(
          backend: GpuBackend.opencl,
          name: 'Adreno OpenCL',
          totalBytes: 1,
          freeBytes: 1,
        ),
      ];
      expect(recommendedBackend(devices), GpuBackend.opencl);
    });

    test('uses Vulkan when no Adreno OpenCL device exists', () {
      expect(
        recommendedBackend([
          const GpuDevice(
            backend: GpuBackend.vulkan,
            name: 'Mali-G68',
            totalBytes: 1,
            freeBytes: 1,
          ),
          const GpuDevice(
            backend: GpuBackend.opencl,
            name: 'Mali OpenCL',
            totalBytes: 1,
            freeBytes: 1,
          ),
        ]),
        GpuBackend.vulkan,
      );
    });

    test('falls back to CPU when no supported GPU is available', () {
      expect(recommendedBackend(const []), GpuBackend.none);
    });
  });
}
