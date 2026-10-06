import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/benchmark_store.dart';
import 'package:local_llm/models_repo/catalog.dart';
import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/recommender.dart';
import 'package:local_llm/models_repo/use_cases.dart';

DeviceProfile phone(double gb, {int cores = 8}) {
  final total = (gb * 1024 * 1024 * 1024).round();
  return DeviceProfile(
    totalRamBytes: total,
    availableRamBytes: (total * 0.6).round(),
    cores: cores,
  );
}

BenchmarkResult run(String id, double tps, double sizeGb) => BenchmarkResult(
      modelId: id,
      tokensPerSecond: tps,
      modelBytes: (sizeGb * 1024 * 1024 * 1024).round(),
      measuredAt: DateTime(2026, 8, 25),
    );

CatalogModel modelById(String id) => chatCatalog.firstWhere((m) => m.id == id);

void main() {
  group('persistence', () {
    test('round-trips results', () {
      final results = {
        'a': run('a', 12.5, 1.0),
        'b': run('b', 4.0, 2.5),
      };
      final restored = decode(encode(results));
      expect(restored.keys, {'a', 'b'});
      expect(restored['a']!.tokensPerSecond, 12.5);
      expect(restored['b']!.modelBytes, run('b', 4, 2.5).modelBytes);
    });

    test('a corrupt store costs an estimate, not a crash', () {
      expect(decode('not json'), isEmpty);
      expect(decode('{"not":"a list"}'), isEmpty);
      expect(decode(null), isEmpty);
      expect(decode(''), isEmpty);
    });

    test('drops entries that could not have come from a real run', () {
      const raw = '[{"id":"ok","tps":10,"bytes":1000000000},'
          '{"id":"zero","tps":0,"bytes":1000000000},'
          '{"id":"nobytes","tps":10,"bytes":0},'
          '{"id":"wrongtype","tps":"fast","bytes":1000000000}]';
      expect(decode(raw).keys, {'ok'});
    });
  });

  group('calibration', () {
    test('recovers bandwidth from rate and size', () {
      // 10 tok/s on a 2 GB model is 20 GB/s sustained.
      expect(measuredBandwidthGBps([run('a', 10, 2.0)]), closeTo(20, 0.001));
    });

    test('takes the median so one throttled run does not skew everything', () {
      final bandwidth = measuredBandwidthGBps([
        run('a', 10, 2.0), // 20 GB/s
        run('b', 12, 2.0), // 24 GB/s
        run('c', 1, 2.0), // 2 GB/s — thermally throttled
      ]);
      expect(bandwidth, closeTo(20, 0.001));
    });

    test('ignores figures no phone could have produced', () {
      expect(measuredBandwidthGBps([run('a', 500, 2.0)]), isNull);
      expect(measuredBandwidthGBps([]), isNull);
    });
  });

  group('SpeedKnowledge', () {
    test('prefers a measurement over an estimate', () {
      final model = modelById('qwen2.5-1.5b-instruct-q4_k_m');
      final knowledge = SpeedKnowledge(
        device: phone(8),
        measurements: {model.servedId: run(model.servedId, 33.0, 1.0)},
      );
      expect(knowledge.rateFor(model), 33.0);
      expect(knowledge.isMeasured(model), isTrue);
    });

    test('one measurement re-scales every other model', () {
      // The point of calibrating: benchmarking one model should make the
      // numbers next to all the others better, not just its own.
      final measured = modelById('qwen2.5-1.5b-instruct-q4_k_m');
      final other = modelById('qwen3.5-4b-q4_k_m');

      final device = phone(8);
      final uncalibrated = SpeedKnowledge(device: device).rateFor(other)!;

      // Measured much faster than this device class would suggest.
      final knowledge = SpeedKnowledge(
        device: device,
        measurements: {
          measured.servedId: run(
            measured.servedId,
            40,
            measured.approxBytes / (1024 * 1024 * 1024),
          ),
        },
      );
      expect(knowledge.calibrated, isTrue);
      expect(knowledge.rateFor(other)!, greaterThan(uncalibrated));
      expect(knowledge.isMeasured(other), isFalse);
    });

    test('a measurement alone is enough when RAM cannot be read', () {
      final model = modelById('qwen3.5-2b-q4_k_m');
      final other = modelById('gemma-3-1b-it-q4_k_m');
      final knowledge = SpeedKnowledge(
        device: DeviceProfile.unknownProfile,
        measurements: {
          model.servedId: run(
            model.servedId,
            9,
            model.approxBytes / (1024 * 1024 * 1024),
          ),
        },
      );
      // Without measurements this device yields nothing; with one, both the
      // measured model and its neighbours get a figure.
      expect(SpeedKnowledge(device: DeviceProfile.unknownProfile).rateFor(other),
          isNull);
      expect(knowledge.rateFor(other), isNotNull);
    });
  });

  group('recommendations with measurements', () {
    test('label says whether the number was measured', () {
      final device = phone(8);
      final estimated = recommend(UseCase.fastChat, device).best!;
      expect(estimated.speedIsMeasured, isFalse);
      expect(estimated.speedLabel, startsWith('~'));

      final pickedModel = estimated.model;
      final measured = recommend(
        UseCase.fastChat,
        device,
        speed: SpeedKnowledge(
          device: device,
          measurements: {
            pickedModel.servedId: run(
              pickedModel.servedId,
              25,
              pickedModel.approxBytes / (1024 * 1024 * 1024),
            ),
          },
        ),
      ).best!;
      if (measured.model.id == pickedModel.id) {
        expect(measured.speedIsMeasured, isTrue);
        expect(measured.speedLabel, isNot(startsWith('~')));
        expect(measured.speedLabel, '25 tok/s');
      }
    });

    test('a phone measured slower than its class is ranked accordingly', () {
      // A flagship that actually decodes like a budget device should stop
      // being told it can run the big models comfortably fast.
      final device = phone(12);
      final anchor = modelById('qwen3.5-2b-q4_k_m');
      final slow = SpeedKnowledge(
        device: device,
        measurements: {
          anchor.servedId: run(
            anchor.servedId,
            2.0,
            anchor.approxBytes / (1024 * 1024 * 1024),
          ),
        },
      );

      final fastPick = recommend(UseCase.fastChat, device).best!;
      final slowPick =
          recommend(UseCase.fastChat, device, speed: slow).best!;
      expect(slowPick.estimatedTokensPerSecond!,
          lessThan(fastPick.estimatedTokensPerSecond!));
    });
  });
}
