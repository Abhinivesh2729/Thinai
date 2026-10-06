import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/catalog.dart';
import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/model_skills.dart';
import 'package:local_llm/models_repo/recommender.dart';
import 'package:local_llm/models_repo/use_cases.dart';

/// A phone with [gb] of RAM, mostly free.
DeviceProfile phone(double gb, {int cores = 8, double freeFraction = 0.6}) {
  final total = (gb * 1024 * 1024 * 1024).round();
  return DeviceProfile(
    totalRamBytes: total,
    availableRamBytes: (total * freeFraction).round(),
    cores: cores,
  );
}

CatalogModel modelById(String id) =>
    chatCatalog.firstWhere((m) => m.id == id);

void main() {
  group('traits table', () {
    test('every chat model is rated', () {
      // A model added to the catalog without traits would silently compete on
      // size alone and never be recommended for anything it is actually good
      // at. Fail here instead, where the fix is obvious.
      final unrated = [
        for (final m in chatCatalog)
          if (!modelTraits.containsKey(m.id)) m.id,
      ];
      expect(unrated, isEmpty,
          reason: 'add these to modelTraits in model_skills.dart');
    });

    test('no traits entry names a model that no longer exists', () {
      final ids = {for (final m in chatCatalog) m.id};
      final orphans = [
        for (final id in modelTraits.keys)
          if (!ids.contains(id)) id,
      ];
      expect(orphans, isEmpty, reason: 'stale entries in modelTraits');
    });

    test('an unrated model still gets a size-based guess', () {
      // Reads the size the catalog declares rather than throwing.
      const stranger = CatalogModel(
        id: 'not-in-the-table',
        displayName: 'Stranger',
        author: 'nobody',
        url: 'https://example.invalid/x.gguf',
        filename: 'x.gguf',
        approxBytes: 900 * 1024 * 1024,
        parameters: '1.5 B',
        contextTokens: 32768,
        description: '',
        accent: Color(0xFF000000),
        emoji: '❓',
      );
      expect(traitsFor(stranger).activeParamsB, 1.5);
      expect(skillFor(stranger, UseCase.tamil), Skill.unsupported);
    });
  });

  group('skills', () {
    test('a tiny model is fast but not a reasoner', () {
      final tiny = modelById('gemma-3-270m-it-q8_0');
      expect(skillFor(tiny, UseCase.reasoning), Skill.weak);
      expect(skillFor(tiny, UseCase.fastChat).score,
          greaterThanOrEqualTo(Skill.good.score));
    });

    test('Tamil is only claimed where it was actually trained', () {
      // Llama 3.2's language list does not include Tamil, however capable the
      // model is otherwise.
      expect(skillFor(modelById('llama-3.2-3b-instruct-q4_k_m'), UseCase.tamil),
          Skill.unsupported);
      expect(skillFor(modelById('gemma-3-4b-it-q4_k_m'), UseCase.tamil).score,
          greaterThanOrEqualTo(Skill.good.score));
    });

    test('Gemma 3 1B is not credited with the family language list', () {
      // The 140-language claim starts at 4B; the 1B is English-only.
      expect(skillFor(modelById('gemma-3-1b-it-q4_k_m'), UseCase.tamil),
          Skill.unsupported);
    });

    test('a short context window disqualifies document work', () {
      final short = modelById('gemma-2-2b-it-q4_k_m'); // 8K
      expect(skillFor(short, UseCase.documents), Skill.weak);
      final long = modelById('nemotron-3-nano-4b-q4_k_m'); // 1M
      expect(skillFor(long, UseCase.documents).score,
          greaterThanOrEqualTo(Skill.good.score));
    });

    test('thinking models are marked down for fast chat', () {
      final thinking = modelById('qwen3-0.6b-q8_0');
      final plain = modelById('qwen3.5-0.8b-q8_0');
      expect(skillFor(thinking, UseCase.fastChat).score,
          lessThan(skillFor(plain, UseCase.fastChat).score));
    });
  });

  group('fit and speed', () {
    test('a 4 GB phone cannot hold the biggest model', () {
      final big = modelById('gemma-4-e4b-it-q4_0'); // 4.4 GB + encoder
      expect(fitFor(big, phone(4)), RamFit.tooBig);
      expect(fitFor(big, phone(12)), isNot(RamFit.tooBig));
      expect(fitFor(modelById('qwen3.5-2b-q4_k_m'), phone(12)),
          RamFit.comfortable);
    });

    test('a busy phone is not refused models it can actually run', () {
      // Taken from a real 8 GB device: Android keeps its cache full, so only
      // 2.2 GB reads as "available" while the phone is perfectly capable of
      // running a 4B model. Gating on the live figure blocked half the
      // catalogue here, including every model that can see images.
      final busy = parseMemInfo(
        'MemTotal:        7665508 kB\nMemAvailable:    2297988 kB\n',
        cores: 8,
      );
      final fourB = modelById('qwen3.5-4b-q4_k_m');
      expect(fitFor(fourB, busy), isNot(RamFit.tooBig));

      final vision = modelById('gemma-3-4b-it-q4_k_m');
      expect(fitFor(vision, busy), isNot(RamFit.tooBig),
          reason: 'image understanding would be unreachable on this phone');

      // It is still honest about the cost: with that little free, a model
      // this size is a tight fit rather than a comfortable one.
      expect(fitFor(fourB, busy), RamFit.tight);
    });

    test('runtime cost is more than the download size', () {
      // The KV cache is real memory, and a fit estimate that ignores it
      // recommends models that then get killed.
      final model = modelById('qwen2.5-1.5b-instruct-q4_k_m');
      expect(runtimeBytesFor(model), greaterThan(model.approxBytes));
    });

    test('speed estimate falls as the model grows', () {
      final device = phone(8);
      final small = estimateTokensPerSecond(
          modelById('qwen2.5-0.5b-instruct-q4_k_m'), device)!;
      final large =
          estimateTokensPerSecond(modelById('qwen3.5-4b-q4_k_m'), device)!;
      expect(small, greaterThan(large));
    });

    test('speed is unknown rather than guessed when RAM cannot be read', () {
      expect(
        estimateTokensPerSecond(
            modelById('qwen3.5-2b-q4_k_m'), DeviceProfile.unknownProfile),
        isNull,
      );
    });
  });

  group('recommend', () {
    test('never suggests a model the phone cannot hold', () {
      for (final useCase in UseCase.values) {
        final result = recommend(useCase, phone(3, cores: 4));
        for (final pick in result.picks) {
          expect(pick.fit, isNot(RamFit.tooBig),
              reason: '${pick.model.id} for ${useCase.label}');
        }
      }
    });

    test('a small phone and a flagship get different answers', () {
      final small = recommend(UseCase.reasoning, phone(4, cores: 4)).best;
      final big = recommend(UseCase.reasoning, phone(12)).best;
      expect(small, isNotNull);
      expect(big, isNotNull);
      expect(small!.model.approxBytes, lessThan(big!.model.approxBytes));
    });

    test('fast chat prefers speed, reasoning prefers depth', () {
      final device = phone(8);
      final fast = recommend(UseCase.fastChat, device).best!;
      final deep = recommend(UseCase.reasoning, device).best!;
      expect(fast.estimatedTokensPerSecond!,
          greaterThan(deep.estimatedTokensPerSecond!));
    });

    test('only Tamil-capable models are offered for Tamil', () {
      final result = recommend(UseCase.tamil, phone(8));
      expect(result.picks, isNotEmpty);
      for (final pick in result.picks) {
        expect(traitsFor(pick.model).tamil, isTrue);
      }
    });

    test('only models with a downloadable image encoder are offered for '
        'images', () {
      final result = recommend(UseCase.vision, phone(12));
      expect(result.picks, isNotEmpty);
      for (final pick in result.picks) {
        expect(pick.model.supportsVision, isTrue,
            reason: '${pick.model.id} has no projector to download');
      }
    });

    test('a phone too small for model plus encoder is not offered vision', () {
      // The encoder is half a gigabyte on top of the weights; costing only
      // the weights would recommend a model that cannot actually see here.
      final result = recommend(UseCase.vision, phone(3, cores: 4));
      for (final pick in result.picks) {
        expect(pick.fit, isNot(RamFit.tooBig));
      }
    });

    test('an installed model wins a close call', () {
      final device = phone(8);
      final baseline = recommend(UseCase.english, device).best!;
      final runnerUp = recommend(UseCase.english, device).alternatives.first;

      final withInstalled = recommend(
        UseCase.english,
        device,
        installedIds: {runnerUp.model.id},
      ).best!;
      expect(withInstalled.model.id, isNot(baseline.model.id));
      expect(withInstalled.installed, isTrue);
    });

    test('every recommendation explains itself', () {
      final result = recommend(UseCase.coding, phone(8));
      for (final pick in result.picks) {
        expect(pick.reasons, isNotEmpty);
        expect(pick.reasons.first, contains('code'));
        expect(pick.speedLabel, contains('tok/s'));
        expect(pick.ramLabel, anyOf(contains('GB RAM'), contains('MB RAM')));
      }
    });

    test('an unreadable device still gets recommendations', () {
      final result = recommend(UseCase.english, DeviceProfile.unknownProfile);
      expect(result.picks, isNotEmpty);
      expect(result.best!.fit, RamFit.unknown);
    });
  });

  group('device profile', () {
    test('parses the fields that matter from /proc/meminfo', () {
      const sample = '''
MemTotal:        7654321 kB
MemFree:          123456 kB
MemAvailable:    4321000 kB
Buffers:           12345 kB
''';
      final profile = parseMemInfo(sample, cores: 8);
      expect(profile.totalRamBytes, 7654321 * 1024);
      expect(profile.availableRamBytes, 4321000 * 1024);
      expect(profile.known, isTrue);
    });

    test('survives a meminfo without MemAvailable', () {
      // Older kernels omit it; the budget then falls back to a fraction of
      // total rather than reporting nothing.
      final profile = parseMemInfo('MemTotal: 4000000 kB\n', cores: 4);
      expect(profile.availableRamBytes, isNull);
      expect(profile.modelBudgetBytes, isNotNull);
    });

    test('garbage in meminfo is not fatal', () {
      final profile = parseMemInfo('not a meminfo at all', cores: 6);
      expect(profile.known, isFalse);
      expect(profile.deviceClass, DeviceClass.unknown);
      expect(profile.modelBudgetBytes, isNull);
    });

    test('classifies by memory and cores', () {
      expect(phone(12).deviceClass, DeviceClass.flagship);
      expect(phone(6).deviceClass, DeviceClass.mid);
      expect(phone(3, cores: 4).deviceClass, DeviceClass.entry);
      // Plenty of RAM but few cores is not a flagship.
      expect(phone(8, cores: 4).deviceClass, DeviceClass.mid);
    });

    test('the budget is a share of total RAM, not of what is free now', () {
      // llama.cpp mmaps the weights, so they are file-backed pages the kernel
      // can reclaim. A phone with its cache full can still run a big model,
      // and pinning the ceiling to the live figure would refuse it.
      final idle = phone(8, freeFraction: 0.95);
      final busy = phone(8, freeFraction: 0.15);
      expect(busy.modelBudgetBytes, idle.modelBudgetBytes);
      expect(idle.modelBudgetBytes!, lessThan(idle.totalRamBytes!));
    });

    test('what is free decides comfortable, not possible', () {
      final idle = phone(8, freeFraction: 0.95);
      final busy = phone(8, freeFraction: 0.15);
      expect(busy.comfortableBytes!, lessThan(idle.comfortableBytes!));
      // Comfort never claims more than the hard ceiling allows.
      for (final device in [idle, busy]) {
        expect(device.comfortableBytes!,
            lessThanOrEqualTo(device.modelBudgetBytes!));
      }
    });
  });
}
