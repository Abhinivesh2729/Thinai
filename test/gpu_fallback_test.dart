import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/llm/generation_settings.dart';
import 'package:local_llm/llm/gpu_support.dart';
import 'package:local_llm/llm/llm_engine.dart';
import 'package:local_llm/models_repo/model_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LlmEngine.instance.gpuFailures.reset();
  });

  group('GpuFailureTracker', () {
    test('does not rest on the first failure', () {
      final tracker = GpuFailureTracker();
      expect(tracker.recordFailure(GpuBackend.vulkan), isFalse);
      expect(tracker.isRested(GpuBackend.vulkan), isFalse);
    });

    test('rests after two consecutive failures', () {
      final tracker = GpuFailureTracker();
      expect(tracker.recordFailure(GpuBackend.vulkan), isFalse);
      expect(tracker.recordFailure(GpuBackend.vulkan), isTrue);
      expect(tracker.isRested(GpuBackend.vulkan), isTrue);
    });

    test('a success clears the count', () {
      final tracker = GpuFailureTracker();
      tracker.recordFailure(GpuBackend.vulkan);
      tracker.recordSuccess(GpuBackend.vulkan);
      expect(tracker.recordFailure(GpuBackend.vulkan), isFalse);
      expect(tracker.isRested(GpuBackend.vulkan), isFalse);
    });

    test('cooldown expiry lifts the rest', () {
      final tracker = GpuFailureTracker();
      final at = DateTime(2026, 1, 1);
      tracker.recordFailure(GpuBackend.vulkan);
      expect(
        tracker.recordFailure(GpuBackend.vulkan, now: at),
        isTrue,
      );
      // Just inside the cooldown window.
      expect(
        tracker.isRested(GpuBackend.vulkan, now: at.add(gpuCooldown)),
        isTrue,
      );
      // One microsecond past it.
      expect(
        tracker.isRested(
          GpuBackend.vulkan,
          now: at.add(gpuCooldown).add(const Duration(microseconds: 1)),
        ),
        isFalse,
      );
    });

    test('backends rest independently and none never rests', () {
      final tracker = GpuFailureTracker();
      tracker.recordFailure(GpuBackend.vulkan);
      tracker.recordFailure(GpuBackend.vulkan);
      expect(tracker.isRested(GpuBackend.opencl), isFalse);
      expect(tracker.recordFailure(GpuBackend.none), isFalse);
      expect(tracker.isRested(GpuBackend.none), isFalse);
    });

    test('reset clears failures and rests', () {
      final tracker = GpuFailureTracker();
      tracker.recordFailure(GpuBackend.auto);
      tracker.recordFailure(GpuBackend.auto);
      tracker.reset();
      expect(tracker.isRested(GpuBackend.auto), isFalse);
      expect(tracker.recordFailure(GpuBackend.auto), isFalse);
    });
  });

  group('optionsFor CPU fallback', () {
    test('falls back to CPU while the saved backend is rested', () async {
      final store = GenerationSettingsStore.instance;
      await store.ensureLoaded();
      final saved = store.settings.gpu;
      addTearDown(() async {
        await store.setGpu(saved);
        LlmEngine.instance.gpuFailures.reset();
      });
      await store.setGpu(GpuBackend.vulkan);

      LlmEngine.instance.gpuFailures.recordFailure(GpuBackend.vulkan);
      LlmEngine.instance.gpuFailures.recordFailure(GpuBackend.vulkan);

      final options = await store.optionsFor(
        _fakeModel,
        maxTokens: 8,
      );
      expect(options.gpuBackend, GpuBackend.none);
      expect(options.numGpuLayers, 0);
    });

    test('an explicit gpu argument still tests the rested backend', () async {
      final store = GenerationSettingsStore.instance;
      await store.ensureLoaded();
      final saved = store.settings.gpu;
      addTearDown(() async {
        await store.setGpu(saved);
        LlmEngine.instance.gpuFailures.reset();
      });
      await store.setGpu(GpuBackend.vulkan);

      LlmEngine.instance.gpuFailures.recordFailure(GpuBackend.vulkan);
      LlmEngine.instance.gpuFailures.recordFailure(GpuBackend.vulkan);

      final options = await store.optionsFor(
        _fakeModel,
        maxTokens: 8,
        gpu: GpuBackend.vulkan,
      );
      expect(options.gpuBackend, GpuBackend.vulkan);
      expect(options.numGpuLayers, kAllGpuLayers);
    });

    test('stays on GPU when nothing has failed', () async {
      final store = GenerationSettingsStore.instance;
      await store.ensureLoaded();
      final saved = store.settings.gpu;
      addTearDown(() => store.setGpu(saved));
      await store.setGpu(GpuBackend.vulkan);

      final options = await store.optionsFor(_fakeModel, maxTokens: 8);
      expect(options.gpuBackend, GpuBackend.vulkan);
    });
  });
}

final _fakeModel = LocalModel(
  id: 'test-model',
  displayName: 'test-model.gguf',
  path: '/tmp/test-model.gguf',
  sizeBytes: 1,
  modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
);
