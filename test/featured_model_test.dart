import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/catalog.dart';

void main() {
  test('the featured model is LFM2.5 350M', () {
    final featured = featuredModel!;
    expect(featured.id, featuredModelId);
    expect(featured.displayName, 'LFM2.5 · 350M');
  });

  test('the featured id names a chat model that is in the catalog', () {
    // A typo here would quietly fall back to the smallest model.
    expect(chatCatalog.where((m) => m.id == featuredModelId), hasLength(1));
  });

  test('featuring is a choice, not the smallest model', () {
    expect(featuredModel!.id, isNot(starterModel!.id));
  });
}
