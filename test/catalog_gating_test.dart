import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/catalog.dart';
import 'package:local_llm/models_repo/device_profile.dart';
import 'package:local_llm/models_repo/recommender.dart';

DeviceProfile phone(double gb, {int cores = 8, double freeFraction = 0.6}) {
  final total = (gb * 1024 * 1024 * 1024).round();
  return DeviceProfile(
    totalRamBytes: total,
    availableRamBytes: (total * freeFraction).round(),
    cores: cores,
  );
}

/// Mirrors the rule the catalogue card applies: an uninstalled model that
/// cannot fit is not offered for download.
bool blocked(CatalogModel model, DeviceProfile device) =>
    fitFor(model, device) == RamFit.tooBig;

void main() {
  group('download gating', () {
    test('a small phone is not offered models it cannot run', () {
      final device = phone(3, cores: 4);
      final refused = [
        for (final m in chatCatalog)
          if (blocked(m, device)) m.id,
      ];
      expect(refused, isNotEmpty,
          reason: 'a 3 GB phone cannot run the whole catalogue');

      // Everything refused really is beyond the budget, not merely large.
      final budget = device.modelBudgetBytes!;
      for (final id in refused) {
        final model = chatCatalog.firstWhere((m) => m.id == id);
        expect(runtimeBytesFor(model), greaterThan(budget));
      }
    });

    test('a flagship is offered nearly everything', () {
      final device = phone(12);
      final refused = [
        for (final m in chatCatalog)
          if (blocked(m, device)) m.id,
      ];
      expect(refused, isEmpty);
    });

    test('nothing is blocked when the phone cannot be measured', () {
      // Refusing a download on a guess would be worse than allowing one: the
      // user knows their own device, and an unreadable /proc/meminfo is our
      // problem, not theirs.
      for (final m in chatCatalog) {
        expect(blocked(m, DeviceProfile.unknownProfile), isFalse);
      }
    });

    test('a tight fit is still allowed', () {
      // Tight means "works, with consequences", and that is the user's call to
      // make. Only tooBig is refused.
      final device = phone(6);
      final tight = [
        for (final m in chatCatalog)
          if (fitFor(m, device) == RamFit.tight) m,
      ];
      for (final m in tight) {
        expect(blocked(m, device), isFalse);
      }
    });

    test('every phone can still run something', () {
      // A catalogue where the smallest phone is offered nothing at all would
      // be a dead end rather than a safeguard.
      for (final gb in [2.0, 3.0, 4.0, 6.0, 8.0, 12.0]) {
        final device = phone(gb, cores: gb < 4 ? 4 : 8);
        final runnable = [
          for (final m in chatCatalog)
            if (!blocked(m, device)) m.id,
        ];
        expect(runnable, isNotEmpty, reason: 'nothing runs on a ${gb}GB phone');
      }
    });

    test('embedding models are gated by the same rule', () {
      // They are small enough to pass everywhere, which is worth pinning: a
      // phone that cannot embed cannot use the /api/embed endpoints at all.
      final device = phone(3, cores: 4);
      for (final m in embeddingCatalog) {
        expect(blocked(m, device), isFalse, reason: m.id);
      }
    });
  });
}
