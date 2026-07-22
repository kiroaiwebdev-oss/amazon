import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tinycanvas_adventures/core/database/app_database.dart';
import 'package:tinycanvas_adventures/core/platform/platform_services.dart';
import 'package:tinycanvas_adventures/data/models.dart';
import 'package:tinycanvas_adventures/data/repositories.dart';
import 'package:tinycanvas_adventures/features/purchase/purchase_controller.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late EntitlementRepository entitlements;
  OwnershipState? lastOwnership;

  setUp(() async {
    db = await AppDatabase.open(inMemoryDatabasePath);
    entitlements = EntitlementRepository(db);
    lastOwnership = null;
  });

  tearDown(() => db.close());

  PurchaseController controller(
    MockPurchaseService service, {
    bool online = true,
  }) =>
      PurchaseController(
        service: service,
        connectivity: MockConnectivityService(online: online),
        entitlements: entitlements,
        onOwnershipChanged: (s) => lastOwnership = s,
      );

  test('paywall offline state when there is no network', () async {
    final c = controller(MockPurchaseService(), online: false);
    await c.loadPaywall();
    expect(c.phase, PurchasePhase.offline);
  });

  test('paywall productUnavailable when Amazon has no product data', () async {
    final c = controller(
        MockPurchaseService(productAvailable: false, latency: Duration.zero));
    await c.loadPaywall();
    expect(c.phase, PurchasePhase.productUnavailable);
  });

  test('successful purchase persists verified ownership', () async {
    final c = controller(MockPurchaseService(latency: Duration.zero));
    await c.loadPaywall();
    expect(c.phase, PurchasePhase.notOwned);
    await c.startPurchase();
    expect(c.phase, PurchasePhase.owned);
    expect(lastOwnership, OwnershipState.owned);
    final cached = await entitlements.load(kUnlockAllSku);
    expect(cached?.state, OwnershipState.owned);
  });

  test('cached ownership short-circuits the paywall (works offline)',
      () async {
    await entitlements.save(EntitlementCache(
        productId: kUnlockAllSku,
        state: OwnershipState.owned,
        verifiedAt: DateTime.now()));
    final c = controller(MockPurchaseService(latency: Duration.zero),
        online: false);
    await c.loadPaywall();
    expect(c.phase, PurchasePhase.alreadyOwned);
  });

  test('cancelled and failed purchases do not grant ownership', () async {
    for (final (scripted, expected) in [
      (PurchaseResult.cancelled, PurchasePhase.cancelled),
      (PurchaseResult.failed, PurchasePhase.failed),
    ]) {
      final c = controller(MockPurchaseService(
          scriptedPurchase: scripted, latency: Duration.zero));
      await c.startPurchase();
      expect(c.phase, expected);
      final cached = await entitlements.load(kUnlockAllSku);
      expect(cached?.state, isNot(OwnershipState.owned));
    }
  });

  test('pending purchase is persisted as pending', () async {
    final c = controller(MockPurchaseService(
        scriptedPurchase: PurchaseResult.pending, latency: Duration.zero));
    await c.startPurchase();
    expect(c.phase, PurchasePhase.pending);
    expect(lastOwnership, OwnershipState.pending);
  });

  test('restore success, no-purchase-found and error phases', () async {
    final okService =
        MockPurchaseService(initiallyOwned: true, latency: Duration.zero);
    final c1 = controller(okService);
    await c1.restore();
    expect(c1.phase, PurchasePhase.restoreSuccess);
    expect(lastOwnership, OwnershipState.owned);

    final c2 = controller(MockPurchaseService(latency: Duration.zero));
    await c2.restore();
    expect(c2.phase, PurchasePhase.noPurchaseFound);

    final c3 = controller(MockPurchaseService(
        scriptedRestore: RestoreResult.error, latency: Duration.zero));
    await c3.restore();
    expect(c3.phase, PurchasePhase.restoreError);
  });

  test('restore offline state', () async {
    final c = controller(MockPurchaseService(latency: Duration.zero),
        online: false);
    await c.restore();
    expect(c.phase, PurchasePhase.offline);
  });

  test('double taps cannot start duplicate checkouts', () async {
    final service =
        MockPurchaseService(latency: const Duration(milliseconds: 50));
    final c = controller(service);
    final first = c.startPurchase();
    final second = c.startPurchase(); // ignored while busy
    await Future.wait([first, second]);
    expect(c.phase, PurchasePhase.owned);
  });
}
