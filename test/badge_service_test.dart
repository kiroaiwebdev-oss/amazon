import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tinycanvas_adventures/core/database/app_database.dart';
import 'package:tinycanvas_adventures/data/models.dart';
import 'package:tinycanvas_adventures/data/repositories.dart';
import 'package:tinycanvas_adventures/features/badges/badge_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late BadgeService service;
  late BadgeRepository repo;

  setUp(() async {
    db = await AppDatabase.open(inMemoryDatabasePath);
    repo = BadgeRepository(db);
    service = BadgeService(repo);
  });

  tearDown(() => db.close());

  test('tool taster is earned after 4 distinct tools, de-duplicated',
      () async {
    await service.recordColoringSession(
      catalogItemId: 'tc_01_01',
      category: 'Nature',
      toolsUsed: {'brush', 'fill'},
      colorNamesUsed: {'Coral'},
    );
    // Repeating the same tools never double-counts.
    await service.recordColoringSession(
      catalogItemId: 'tc_01_01',
      category: 'Nature',
      toolsUsed: {'brush', 'fill'},
      colorNamesUsed: {'Coral'},
    );
    var states = await repo.all();
    var taster = states.firstWhere((s) => s.badgeId == 'tool_taster');
    expect(taster.progress, 2);
    expect(taster.earned, isFalse);

    final earned = await service.recordColoringSession(
      catalogItemId: 'tc_01_02',
      category: 'Nature',
      toolsUsed: {'marker', 'stamps'},
      colorNamesUsed: {'Sky'},
    );
    expect(earned.map((d) => d.id), contains('tool_taster'));
    states = await repo.all();
    taster = states.firstWhere((s) => s.badgeId == 'tool_taster');
    expect(taster.earned, isTrue);
  });

  test('category adventurer needs all 8 categories', () async {
    for (final (index, category) in kCategories.indexed) {
      await service.recordColoringSession(
        catalogItemId: 'tc_0${(index % 8) + 1}_01',
        category: category,
        toolsUsed: {'brush'},
        colorNamesUsed: {'Coral'},
      );
    }
    final states = await repo.all();
    final adventurer =
        states.firstWhere((s) => s.badgeId == 'category_adventurer');
    expect(adventurer.earned, isTrue);
  });

  test('creative explorer counts 20 distinct pictures', () async {
    for (var i = 1; i <= 20; i++) {
      await service.recordColoringSession(
        catalogItemId: 'pic_$i',
        category: 'Nature',
        toolsUsed: {'brush'},
        colorNamesUsed: {'Coral'},
      );
    }
    final states = await repo.all();
    final explorer =
        states.firstWhere((s) => s.badgeId == 'creative_explorer');
    expect(explorer.earned, isTrue);
    expect(explorer.fraction, 1);
  });

  test('color collector tracks the 24 named colors', () async {
    final earned = await service.recordColoringSession(
      catalogItemId: 'tc_01_01',
      category: 'Beach',
      toolsUsed: {'brush'},
      colorNamesUsed: {
        for (var i = 0; i < 24; i++) 'Color $i',
      },
    );
    expect(earned.map((d) => d.id), contains('color_collector'));
  });
}
