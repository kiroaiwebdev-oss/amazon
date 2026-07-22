import 'package:flutter_test/flutter_test.dart';
import 'package:tinycanvas_adventures/data/catalog_seed.dart';
import 'package:tinycanvas_adventures/data/models.dart';

/// Automated business invariants: exactly 120 originals, exactly 20 free,
/// exactly 100 premium, 8 categories x 15 pictures, unique ids and seeds.
void main() {
  final items = buildCatalogSeed();

  test('catalog has exactly 120 items', () {
    expect(items.length, 120);
  });

  test('exactly 20 free and 100 premium', () {
    expect(items.where((i) => !i.premium).length, 20);
    expect(items.where((i) => i.premium).length, 100);
  });

  test('exactly 8 approved categories with 15 pictures each', () {
    final byCategory = <String, int>{};
    for (final item in items) {
      byCategory[item.category] = (byCategory[item.category] ?? 0) + 1;
    }
    expect(byCategory.keys.toSet(), kCategories.toSet());
    for (final entry in byCategory.entries) {
      expect(entry.value, 15, reason: '${entry.key} must bundle 15 pictures');
    }
  });

  test('every category offers at least one free picture', () {
    for (final category in kCategories) {
      expect(
        items.any((i) => i.category == category && !i.premium),
        isTrue,
        reason: '$category needs a free picture',
      );
    }
  });

  test('ids and asset seeds are unique and stable', () {
    expect(items.map((i) => i.id).toSet().length, 120);
    expect(items.map((i) => i.assetSeed).toSet().length, 120);
    expect(items.first.id, 'tc_01_01');
    expect(items.first.assetSeed, 1);
    expect(items.last.assetSeed, 120);
  });

  test('all three difficulties are represented in every category', () {
    for (final category in kCategories) {
      final difficulties =
          items.where((i) => i.category == category).map((i) => i.difficulty);
      expect(difficulties.toSet(), Difficulty.values.toSet());
    }
  });

  test('titles and keywords are non-empty and searchable', () {
    for (final item in items) {
      expect(item.title.trim(), isNotEmpty);
      expect(item.keywords.trim(), isNotEmpty);
    }
  });
}
