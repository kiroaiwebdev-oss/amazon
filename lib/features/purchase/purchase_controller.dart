import 'package:flutter/foundation.dart';

import '../../core/platform/platform_services.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import 'purchase_service.dart';

export 'purchase_service.dart';

/// Drives the paywall (Screens 26-31) and restore (Screens 32-34) UI.
///
/// Guards against duplicate checkouts and double taps via [busy]; persists
/// verified ownership in the entitlement cache so unlocks survive restarts
/// and work offline afterwards.
class PurchaseController extends ChangeNotifier {
  PurchaseController({
    required this.service,
    required this.connectivity,
    required this.entitlements,
    required this.onOwnershipChanged,
  });

  final PurchaseService service;
  final ConnectivityService connectivity;
  final EntitlementRepository entitlements;
  final void Function(OwnershipState state) onOwnershipChanged;

  PurchasePhase _phase = PurchasePhase.unknown;
  ProductInfo? _product;
  bool _busy = false;
  bool _disposed = false;

  PurchasePhase get phase => _phase;
  ProductInfo? get product => _product;
  bool get busy => _busy;

  void _set(PurchasePhase phase) {
    if (_disposed) return;
    _phase = phase;
    notifyListeners();
  }

  /// Loads paywall state: cached ownership first (works offline), then
  /// connectivity, then Amazon product data with its localized price.
  Future<void> loadPaywall() async {
    _set(PurchasePhase.loading);
    final cached = await entitlements.load(kUnlockAllSku);
    if (cached?.state == OwnershipState.owned) {
      _set(PurchasePhase.alreadyOwned);
      return;
    }
    if (!await connectivity.hasNetwork()) {
      _set(PurchasePhase.offline);
      return;
    }
    final product = await service.fetchProduct();
    if (_disposed) return;
    if (product == null) {
      _set(PurchasePhase.productUnavailable);
      return;
    }
    _product = product;
    if (cached?.state == OwnershipState.pending) {
      _set(PurchasePhase.pending);
      return;
    }
    _set(PurchasePhase.notOwned);
  }

  Future<void> startPurchase() async {
    if (_busy) return; // prevents duplicate checkout / double taps
    _busy = true;
    _set(PurchasePhase.checkoutHandoff);
    try {
      final result = await service.purchase();
      if (_disposed) return;
      switch (result) {
        case PurchaseResult.success:
          await _markOwned();
          _set(PurchasePhase.owned);
        case PurchaseResult.alreadyOwned:
          await _markOwned();
          _set(PurchasePhase.alreadyOwned);
        case PurchaseResult.pending:
          await _saveState(OwnershipState.pending);
          onOwnershipChanged(OwnershipState.pending);
          _set(PurchasePhase.pending);
        case PurchaseResult.cancelled:
          _set(PurchasePhase.cancelled);
        case PurchaseResult.unavailable:
          _set(PurchasePhase.productUnavailable);
        case PurchaseResult.failed:
          _set(PurchasePhase.failed);
      }
    } catch (_) {
      _set(PurchasePhase.failed);
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> restore() async {
    if (_busy) return;
    _busy = true;
    _set(PurchasePhase.loading);
    try {
      if (!await connectivity.hasNetwork()) {
        _set(PurchasePhase.offline);
        return;
      }
      final result = await service.restore();
      if (_disposed) return;
      switch (result) {
        case RestoreResult.restored:
          await _markOwned();
          _set(PurchasePhase.restoreSuccess);
        case RestoreResult.noPurchaseFound:
          await _saveState(OwnershipState.notOwned);
          onOwnershipChanged(OwnershipState.notOwned);
          _set(PurchasePhase.noPurchaseFound);
        case RestoreResult.error:
          _set(PurchasePhase.restoreError);
      }
    } catch (_) {
      _set(PurchasePhase.restoreError);
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _markOwned() async {
    await _saveState(OwnershipState.owned);
    onOwnershipChanged(OwnershipState.owned);
  }

  Future<void> _saveState(OwnershipState state) => entitlements.save(
        EntitlementCache(
          productId: kUnlockAllSku,
          state: state,
          verifiedAt: DateTime.now(),
        ),
      );

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
