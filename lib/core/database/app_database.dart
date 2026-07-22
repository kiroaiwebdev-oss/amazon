import 'package:sqflite/sqflite.dart';

import '../../data/catalog_seed.dart';

/// Local structured storage. Schema versioned with forward-only migrations.
/// All writes that span rows/files use transactions; corruption is handled
/// by the Local Repair flow (see InitializationController).
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const int schemaVersion = 1;

  static Future<AppDatabase> open(String path) async {
    final db = await openDatabase(
      path,
      version: schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return AppDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE catalog_items (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          difficulty TEXT NOT NULL,
          premium INTEGER NOT NULL,
          asset_path TEXT NOT NULL,
          thumbnail_path TEXT NOT NULL,
          search_keywords TEXT NOT NULL,
          content_version INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await txn.execute('''
        CREATE TABLE artworks (
          id TEXT PRIMARY KEY,
          catalog_item_id TEXT NOT NULL REFERENCES catalog_items(id),
          display_name TEXT NOT NULL,
          document_path TEXT NOT NULL,
          preview_path TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          favorite INTEGER NOT NULL DEFAULT 0,
          completed INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await txn.execute('''
        CREATE TABLE progress (
          catalog_item_id TEXT PRIMARY KEY REFERENCES catalog_items(id),
          last_opened_at INTEGER NOT NULL,
          completion_data TEXT
        )
      ''');
      await txn.execute('''
        CREATE TABLE badges (
          badge_id TEXT PRIMARY KEY,
          progress INTEGER NOT NULL DEFAULT 0,
          progress_data TEXT,
          earned_at INTEGER
        )
      ''');
      await txn.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE entitlement_cache (
          product_id TEXT PRIMARY KEY,
          ownership_state TEXT NOT NULL,
          verified_at INTEGER,
          pending INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await txn.execute('''
        CREATE TABLE recent_searches (
          query TEXT PRIMARY KEY,
          searched_at INTEGER NOT NULL
        )
      ''');
      await txn.execute(
          'CREATE INDEX idx_artworks_updated ON artworks(updated_at DESC)');
      await txn.execute(
          'CREATE INDEX idx_catalog_category ON catalog_items(category)');

      // Seed the bundled catalog inside the same transaction (atomic).
      final batch = txn.batch();
      for (final item in buildCatalogSeed()) {
        batch.insert('catalog_items', item.toRow(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  static Future<void> _onUpgrade(Database db, int from, int to) async {
    // Forward-only migrations. Example shape for future versions:
    // if (from < 2) { await db.execute('ALTER TABLE ...'); }
    for (var v = from + 1; v <= to; v++) {
      switch (v) {
        default:
          break;
      }
    }
  }

  /// Integrity check used by Splash; a failure routes to Local Repair.
  Future<bool> integrityOk() async {
    try {
      final rows = await db.rawQuery('PRAGMA integrity_check');
      final result = rows.isNotEmpty ? rows.first.values.first : null;
      if (result != 'ok') return false;
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM catalog_items'));
      return count == 120;
    } catch (_) {
      return false;
    }
  }

  /// Local Repair: re-seeds missing bundled catalog rows without touching
  /// artworks. Returns the number of repaired rows.
  Future<int> repairCatalog() async {
    var repaired = 0;
    await db.transaction((txn) async {
      for (final item in buildCatalogSeed()) {
        final updated = await txn.insert('catalog_items', item.toRow(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
        if (updated != 0) repaired++;
      }
    });
    return repaired;
  }

  Future<void> close() => db.close();
}
