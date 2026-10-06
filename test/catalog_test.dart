import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/catalog.dart';

void main() {
  group('modelCatalog', () {
    test('ids are unique', () {
      final ids = modelCatalog.map((m) => m.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('filenames are unique (they share one download directory)', () {
      final names = modelCatalog.map((m) => m.filename).toList();
      expect(names.toSet(), hasLength(names.length));
    });

    test('every url is https and ends with the declared filename', () {
      for (final m in modelCatalog) {
        expect(m.url, startsWith('https://'), reason: m.id);
        // The downloader saves to `filename`; a mismatch means the installed
        // model would never be matched back to its catalog entry.
        expect(m.url, endsWith(m.filename), reason: m.id);
      }
    });

    test('sizes are plausible', () {
      for (final m in modelCatalog) {
        expect(m.approxBytes, greaterThan(1024 * 1024), reason: m.id);
        expect(m.approxBytes, lessThan(8 * 1024 * 1024 * 1024), reason: m.id);
      }
    });

    test('embedding models declare dimensions, chat models do not', () {
      for (final m in modelCatalog) {
        if (m.kind == ModelKind.embedding) {
          expect(m.dimensions, isNotNull, reason: m.id);
          expect(m.dimensions, greaterThan(0), reason: m.id);
        } else {
          expect(m.dimensions, isNull, reason: m.id);
        }
      }
    });

    test('chatCatalog and embeddingCatalog partition the catalog', () {
      expect(chatCatalog.every((m) => m.kind == ModelKind.chat), isTrue);
      expect(
        embeddingCatalog.every((m) => m.kind == ModelKind.embedding),
        isTrue,
      );
      expect(
        chatCatalog.length + embeddingCatalog.length,
        modelCatalog.length,
      );
    });

    test('both kinds are non-empty', () {
      // The Models page renders a section per kind and indexes .first for the
      // coach mark; an empty list would throw.
      expect(chatCatalog, isNotEmpty);
      expect(embeddingCatalog, isNotEmpty);
    });

    test('both catalogs are ordered smallest first', () {
      for (final list in [chatCatalog, embeddingCatalog]) {
        final sizes = list.map((m) => m.approxBytes).toList();
        expect(sizes, orderedEquals(sizes.toList()..sort()));
      }
    });

    test('approxSize renders MB below 1 GB and GB above', () {
      final small = modelCatalog.firstWhere((m) => m.approxBytes < 1024 * 1024 * 1024);
      expect(small.approxSize, endsWith('MB'));
      final large = modelCatalog.firstWhere((m) => m.approxBytes > 1024 * 1024 * 1024);
      expect(large.approxSize, endsWith('GB'));
    });
  });
}
