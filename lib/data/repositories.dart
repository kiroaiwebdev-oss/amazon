import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import 'models.dart';

/// Repository layer: typed access over AppDatabase. UI layers never touch
/// SQL directly. All repositories are constructor-injected (see bootstrap).

class CatalogRepository {
  CatalogRepository(this._db);
  final AppDatabase _db;

  Future<List<CatalogItem>> all() async {
    final rows = await _db.db.query('catalog_items', orderBy: 'id');
    return rows.map(CatalogItem.fromRow).toList();
  }

  Future<CatalogItem?> byId(String id) async {
    final rows =
        await _db.db.query('catalog_items', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : CatalogItem.fromRow(rows.first);
  }

  Future<List<CatalogItem>> byCategory(String category) async {
    final rows = await _db.db.query('catalog_items',
        where: 'category = ?', whereArgs: [category], orderBy: 'id');
    return rows.map(CatalogItem.fromRow).toList();
  }

  Future<List<CatalogItem>> search(String query) async {
    final q = '%${query.trim().toLowerCase()}%';
    final rows = await _db.db.query(
      'catalog_items',
      where: 'LOWER(title) LIKE ? OR search_keywords LIKE ? OR LOWER(category) LIKE ?',
      whereArgs: [q, q, q],
      orderBy: 'id',
    );
    return rows.map(CatalogItem.fromRow).toList();
  }

  Future<int> freeCount() async =>
      Sqflite.firstIntValue(await _db.db
          .rawQuery('SELECT COUNT(*) FROM catalog_items WHERE premium = 0')) ??
      0;

  Future<int> premiumCount() async =>
      Sqflite.firstIntValue(await _db.db
          .rawQuery('SELECT COUNT(*) FROM catalog_items WHERE premium = 1')) ??
      0;

  Future<void> touchProgress(String catalogItemId) async {
    await _db.db.insert(
      'progress',
      {
        'catalog_item_id': catalogItemId,
        'last_opened_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class ArtworkRepository {
  ArtworkRepository(this._db);
  final AppDatabase _db;

  Future<List<Artwork>> all({bool favoritesOnly = false}) async {
    final rows = await _db.db.query(
      'artworks',
      where: favoritesOnly ? 'favorite = 1' : null,
      orderBy: 'updated_at DESC',
    );
    return rows.map(Artwork.fromRow).toList();
  }

  Future<Artwork?> byId(String id) async {
    final rows =
        await _db.db.query('artworks', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Artwork.fromRow(rows.first);
  }

  Future<Artwork?> latest() async {
    final rows =
        await _db.db.query('artworks', orderBy: 'updated_at DESC', limit: 1);
    return rows.isEmpty ? null : Artwork.fromRow(rows.first);
  }

  Future<Artwork?> latestForCatalogItem(String catalogItemId) async {
    final rows = await _db.db.query('artworks',
        where: 'catalog_item_id = ?',
        whereArgs: [catalogItemId],
        orderBy: 'updated_at DESC',
        limit: 1);
    return rows.isEmpty ? null : Artwork.fromRow(rows.first);
  }

  Future<void> upsert(Artwork artwork) async {
    await _db.db.insert('artworks', artwork.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> rename(String id, String newName) async {
    final name = sanitizeArtworkName(newName);
    if (!isValidArtworkName(name)) {
      throw ArgumentError('Name must be between 1 and 40 characters');
    }
    await _db.db.update(
      'artworks',
      {
        'display_name': name,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setFavorite(String id, bool favorite) async {
    await _db.db.update('artworks', {'favorite': favorite ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes the artwork row only. The caller (library controller) owns the
  /// five-second undo window and the document/preview file cleanup. Deleting
  /// an artwork never deletes the bundled source coloring page.
  Future<Artwork?> delete(String id) async {
    final existing = await byId(id);
    if (existing == null) return null;
    await _db.db.delete('artworks', where: 'id = ?', whereArgs: [id]);
    return existing;
  }

  Future<void> restore(Artwork artwork) => upsert(artwork);

  Future<int> count() async =>
      Sqflite.firstIntValue(
          await _db.db.rawQuery('SELECT COUNT(*) FROM artworks')) ??
      0;
}

class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Future<AppSettings> load() async {
    final rows = await _db.db.query('settings');
    final map = <String, String>{
      for (final row in rows) row['key']! as String: row['value']! as String,
    };
    return AppSettings.fromMap(map);
  }

  Future<void> save(AppSettings settings) async {
    await _db.db.transaction((txn) async {
      for (final entry in settings.toMap().entries) {
        await txn.insert(
          'settings',
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}

class BadgeRepository {
  BadgeRepository(this._db);
  final AppDatabase _db;

  Future<List<BadgeState>> all() async {
    final rows = await _db.db.query('badges');
    final byId = {for (final r in rows) r['badge_id'] as String: r};
    return kBadges.map((def) {
      final row = byId[def.id];
      return BadgeState(
        badgeId: def.id,
        progress: (row?['progress'] as int?) ?? 0,
        target: def.target,
        earnedAt: row?['earned_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row!['earned_at']! as int),
      );
    }).toList();
  }

  /// Adds [key] to the badge's distinct progress set. Returns the badge
  /// definition if this update newly earned the badge.
  Future<BadgeDef?> recordProgress(String badgeId, String key) async {
    final def = kBadges.firstWhere((b) => b.id == badgeId);
    BadgeDef? newlyEarned;
    await _db.db.transaction((txn) async {
      final rows = await txn
          .query('badges', where: 'badge_id = ?', whereArgs: [badgeId]);
      final existingData = rows.isEmpty
          ? <String>{}
          : ((jsonDecode((rows.first['progress_data'] as String?) ?? '[]')
                  as List<dynamic>)
              .cast<String>()
              .toSet());
      final wasEarned = rows.isNotEmpty && rows.first['earned_at'] != null;
      existingData.add(key);
      final progress = existingData.length;
      final earned = progress >= def.target;
      await txn.insert(
        'badges',
        {
          'badge_id': badgeId,
          'progress': progress,
          'progress_data': jsonEncode(existingData.toList()..sort()),
          'earned_at': earned
              ? (wasEarned
                  ? rows.first['earned_at']
                  : DateTime.now().millisecondsSinceEpoch)
              : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (earned && !wasEarned) newlyEarned = def;
    });
    return newlyEarned;
  }
}

class EntitlementRepository {
  EntitlementRepository(this._db);
  final AppDatabase _db;

  Future<EntitlementCache?> load(String productId) async {
    final rows = await _db.db.query('entitlement_cache',
        where: 'product_id = ?', whereArgs: [productId]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return EntitlementCache(
      productId: productId,
      state: OwnershipState.values.firstWhere(
        (s) => s.name == row['ownership_state'],
        orElse: () => OwnershipState.unknown,
      ),
      verifiedAt: row['verified_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['verified_at']! as int),
    );
  }

  Future<void> save(EntitlementCache cache) async {
    await _db.db.insert(
      'entitlement_cache',
      {
        'product_id': cache.productId,
        'ownership_state': cache.state.name,
        'verified_at': cache.verifiedAt?.millisecondsSinceEpoch,
        'pending': cache.state == OwnershipState.pending ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class RecentSearchRepository {
  RecentSearchRepository(this._db);
  final AppDatabase _db;

  static const int maxEntries = 8;

  Future<List<String>> recent() async {
    final rows = await _db.db.query('recent_searches',
        orderBy: 'searched_at DESC', limit: maxEntries);
    return rows.map((r) => r['query']! as String).toList();
  }

  Future<void> record(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    await _db.db.insert(
      'recent_searches',
      {'query': q, 'searched_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Trim to the max size.
    await _db.db.rawDelete('''
      DELETE FROM recent_searches WHERE query NOT IN (
        SELECT query FROM recent_searches ORDER BY searched_at DESC LIMIT ?
      )
    ''', [maxEntries]);
  }

  Future<void> clear() => _db.db.delete('recent_searches').then((_) {});
}

/// Erases all local creations atomically (artworks, progress, badges,
/// recent searches). Catalog, settings, and the Amazon entitlement cache
/// are preserved - erasing never claims to remove Amazon ownership.
Future<void> eraseLocalCreations(AppDatabase db) async {
  await db.db.transaction((txn) async {
    await txn.delete('artworks');
    await txn.delete('progress');
    await txn.delete('badges');
    await txn.delete('recent_searches');
  });
}
