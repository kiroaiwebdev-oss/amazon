import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/database/app_database.dart';
import '../core/platform/platform_services.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../features/badges/badge_service.dart';
import '../features/coloring/coloring_engine.dart';
import '../features/purchase/purchase_service.dart';

/// Result of initial startup checks (Splash, Screen 1).
enum InitResult { ready, repairNeeded }

/// Composition root and app-wide state: database, repositories, services,
/// settings, ownership, connectivity and storage warnings.
class AppState extends ChangeNotifier {
  AppState({
    required this.databasePath,
    required this.documentsDir,
    required this.purchaseService,
    required this.connectivity,
    required this.mediaExport,
    DocumentStore? documentStore,
  }) : documentStore = documentStore ?? FileDocumentStore();

  final String databasePath;

  /// App-private documents directory (artwork documents, thumbnails).
  final Directory documentsDir;
  final PurchaseService purchaseService;
  final ConnectivityService connectivity;
  final MediaExportService mediaExport;
  final DocumentStore documentStore;

  AppDatabase? _database;
  AppDatabase get db => _database!;

  late CatalogRepository catalog;
  late ArtworkRepository artworks;
  late SettingsRepository settingsRepo;
  late BadgeRepository badges;
  late EntitlementRepository entitlements;
  late RecentSearchRepository recentSearches;
  late BadgeService badgeService;

  AppSettings settings = const AppSettings();
  OwnershipState ownership = OwnershipState.unknown;
  bool initialized = false;
  bool isOnline = true;
  bool lowStorageWarning = false;

  /// Free space threshold below which the approved low-storage state shows.
  static const int lowStorageThresholdBytes = 300 * 1024 * 1024;

  /// Opens the database, validates integrity and the 20 free / 100 premium
  /// catalog invariants, and loads settings + cached entitlement.
  Future<InitResult> loadInitialState() async {
    _database ??= await AppDatabase.open(databasePath);
    var healthy = false;
    try {
      healthy = await db.integrityOk();
    } catch (_) {
      healthy = false;
    }
    if (!healthy) return InitResult.repairNeeded;

    _wireRepositories();
    try {
      settings = await settingsRepo.load();
      if (await catalog.freeCount() != 20 ||
          await catalog.premiumCount() != 100) {
        return InitResult.repairNeeded;
      }
      final cached = await entitlements.load(kUnlockAllSku);
      ownership = cached?.state ?? OwnershipState.notOwned;
    } catch (_) {
      return InitResult.repairNeeded;
    }

    initialized = true;
    notifyListeners();
    unawaited(refreshConnectivity());
    unawaited(refreshStorage());
    return InitResult.ready;
  }

  void _wireRepositories() {
    catalog = CatalogRepository(db);
    artworks = ArtworkRepository(db);
    settingsRepo = SettingsRepository(db);
    badges = BadgeRepository(db);
    entitlements = EntitlementRepository(db);
    recentSearches = RecentSearchRepository(db);
    badgeService = BadgeService(badges);
  }

  /// Local Data Repair (Screen 38): rebuilds the catalog table from the
  /// bundled seed. Artworks, settings and entitlement cache are preserved.
  Future<bool> repairLocalData() async {
    try {
      _database ??= await AppDatabase.open(databasePath);
      await db.repairCatalog();
      return await loadInitialState() == InitResult.ready;
    } catch (_) {
      return false;
    }
  }

  /// Entitlement guard: free items always open; premium items need the
  /// verified unlock.
  Future<bool> canOpenById(String catalogItemId) async {
    if (!initialized) return false;
    final item = await catalog.byId(catalogItemId);
    if (item == null) return false;
    if (!item.premium) return true;
    return ownership == OwnershipState.owned;
  }

  String documentPathFor(String artworkId) {
    final safe = artworkId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '${documentsDir.path}/artworks/$safe.json';
  }

  void setOwnership(OwnershipState next) {
    ownership = next;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings next) async {
    settings = next;
    notifyListeners();
    await settingsRepo.save(next);
  }

  Future<void> refreshConnectivity() async {
    final online = await connectivity.hasNetwork();
    if (online != isOnline) {
      isOnline = online;
      notifyListeners();
    }
  }

  Future<void> refreshStorage() async {
    try {
      final summary =
          await mediaExport.storageSummary(documentsDir: documentsDir);
      final low = summary.freeBytes > 0 &&
          summary.freeBytes < lowStorageThresholdBytes;
      if (low != lowStorageWarning) {
        lowStorageWarning = low;
        notifyListeners();
      }
    } catch (_) {
      // Storage summary is advisory only.
    }
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }
}
