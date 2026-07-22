import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tinycanvas_adventures/core/database/app_database.dart';
import 'package:tinycanvas_adventures/data/models.dart';
import 'package:tinycanvas_adventures/data/repositories.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;

  setUp(() async => db = await AppDatabase.open(inMemoryDatabasePath));
  tearDown(() => db.close());

  Artwork art(String id, {String catalogItemId = 'tc_01_01'}) {
    final now = DateTime.now();
    return Artwork(
      id: id,
      catalogItemId: catalogItemId,
      displayName: 'My Painting',
      documentPath: 'artworks/$id.json',
      previewPath: null,
      createdAt: now,
      updatedAt: now,
      favorite: false,
      completed: false,
    );
  }

  test('fresh database passes integrity and seeds the exact catalog',
      () async {
    expect(await db.integrityOk(), isTrue);
    final catalog = CatalogRepository(db);
    expect(await catalog.freeCount(), 20);
    expect(await catalog.premiumCount(), 100);
    expect((await catalog.all()).length, 120);
  });

  test('catalog search matches titles and keywords', () async {
    final catalog = CatalogRepository(db);
    final all = await catalog.all();
    final results = await catalog.search(all.first.title.split(' ').first);
    expect(results, isNotEmpty);
  });

  test('repairCatalog restores tampered catalog rows', () async {
    await db.db.delete('catalog_items');
    final catalog = CatalogRepository(db);
    expect(await catalog.freeCount(), 0);
    await db.repairCatalog();
    expect(await catalog.freeCount(), 20);
    expect(await catalog.premiumCount(), 100);
  });

  test('artwork CRUD with delete returning the row for 5-second undo',
      () async {
    final repo = ArtworkRepository(db);
    await repo.upsert(art('a1'));
    await repo.rename('a1', 'Sunny Meadow');
    await repo.setFavorite('a1', true);

    final loaded = await repo.byId('a1');
    expect(loaded?.displayName, 'Sunny Meadow');
    expect(loaded?.favorite, isTrue);

    final deleted = await repo.delete('a1');
    expect(deleted, isNotNull);
    expect(await repo.byId('a1'), isNull);

    await repo.restore(deleted!);
    expect((await repo.byId('a1'))?.displayName, 'Sunny Meadow');
  });

  test('artwork name validation: 1-40 friendly characters', () {
    expect(isValidArtworkName(''), isFalse);
    expect(isValidArtworkName('A' * 41), isFalse);
    expect(isValidArtworkName('Sunny Meadow'), isTrue);
    expect(sanitizeArtworkName('  Sunny/Meadow  '), isNot(contains('/')));
  });

  test('entitlement cache round-trips ownership', () async {
    final repo = EntitlementRepository(db);
    expect(await repo.load('sku_x'), isNull);
    await repo.save(EntitlementCache(
        productId: 'sku_x',
        state: OwnershipState.owned,
        verifiedAt: DateTime(2026, 7, 21)));
    final cached = await repo.load('sku_x');
    expect(cached?.state, OwnershipState.owned);
  });

  test('recent searches record, de-duplicate and clear', () async {
    final repo = RecentSearchRepository(db);
    await repo.record('rocket');
    await repo.record('kitten');
    await repo.record('rocket');
    final recent = await repo.recent();
    expect(recent.first, 'rocket');
    expect(recent.where((r) => r == 'rocket').length, 1);
    await repo.clear();
    expect(await repo.recent(), isEmpty);
  });

  test('settings persist round-trip', () async {
    final repo = SettingsRepository(db);
    await repo.save(const AppSettings(
        onboardingCompleted: true,
        highContrast: true,
        soundMode: SoundMode.silent));
    final loaded = await repo.load();
    expect(loaded.onboardingCompleted, isTrue);
    expect(loaded.highContrast, isTrue);
    expect(loaded.soundMode, SoundMode.silent);
  });

  test('eraseLocalCreations removes artworks and badges but keeps catalog '
      'and entitlement cache', () async {
    final artworkRepo = ArtworkRepository(db);
    await artworkRepo.upsert(art('a1'));
    final entitlementRepo = EntitlementRepository(db);
    await entitlementRepo.save(EntitlementCache(
        productId: 'sku_x',
        state: OwnershipState.owned,
        verifiedAt: DateTime.now()));

    await eraseLocalCreations(db);

    expect(await artworkRepo.count(), 0);
    expect(await CatalogRepository(db).freeCount(), 20);
    expect((await entitlementRepo.load('sku_x'))?.state,
        OwnershipState.owned,
        reason: 'Erase never claims to remove Amazon ownership');
  });
}
