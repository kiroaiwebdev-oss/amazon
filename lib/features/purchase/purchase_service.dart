import 'package:flutter/services.dart';

/// Amazon IAP integration surface.
///
/// The SKU is a build-time placeholder - override with:
///   flutter build apk --dart-define=TINYCANVAS_IAP_SKU=your_final_sku
const kUnlockAllSku = String.fromEnvironment(
  'TINYCANVAS_IAP_SKU',
  defaultValue: 'tinycanvas_unlock_all',
);

/// Reference price shown ONLY as supporting copy. The checkout-facing price
/// is always the localized price returned by Amazon product data.
const kReferencePrice = '\$4.99';

/// The 14 purchase/restore UI states (Screens 26-34 and their variants).
enum PurchasePhase {
  unknown,
  loading,
  offline,
  productUnavailable,
  notOwned,
  checkoutHandoff,
  pending,
  owned,
  alreadyOwned,
  cancelled,
  failed,
  restoreSuccess,
  noPurchaseFound,
  restoreError,
}

/// Localized product data from the store.
class ProductInfo {
  const ProductInfo({
    required this.sku,
    required this.title,
    required this.description,
    required this.price,
  });

  final String sku;
  final String title;
  final String description;

  /// Localized display price (e.g. "\u20b9419.00"). Never hard-coded.
  final String price;
}

enum PurchaseResult {
  success,
  alreadyOwned,
  pending,
  cancelled,
  failed,
  unavailable,
}

enum RestoreResult { restored, noPurchaseFound, error }

/// Store abstraction: the app depends only on this interface, so the mock
/// and the Amazon Appstore implementation are interchangeable.
abstract class PurchaseService {
  /// Localized product data, or null when the product is unavailable.
  Future<ProductInfo?> fetchProduct();

  Future<PurchaseResult> purchase();

  Future<RestoreResult> restore();
}

/// Fully scriptable mock used in development and tests. Every one of the
/// 14 phases can be exercised by adjusting the scripted results.
class MockPurchaseService implements PurchaseService {
  MockPurchaseService({
    this.initiallyOwned = false,
    this.scriptedPurchase = PurchaseResult.success,
    this.scriptedRestore,
    this.productAvailable = true,
    this.latency = const Duration(milliseconds: 600),
  });

  bool initiallyOwned;
  PurchaseResult scriptedPurchase;

  /// When null, restore reflects ownership state.
  RestoreResult? scriptedRestore;
  bool productAvailable;
  Duration latency;

  @override
  Future<ProductInfo?> fetchProduct() async {
    await Future<void>.delayed(latency);
    if (!productAvailable) return null;
    return const ProductInfo(
      sku: kUnlockAllSku,
      title: 'Unlock all 100 pictures',
      description:
          'One-time purchase. Opens every premium picture forever on this '
          'Amazon account.',
      price: kReferencePrice,
    );
  }

  @override
  Future<PurchaseResult> purchase() async {
    await Future<void>.delayed(latency);
    if (initiallyOwned) return PurchaseResult.alreadyOwned;
    final result = scriptedPurchase;
    if (result == PurchaseResult.success) initiallyOwned = true;
    return result;
  }

  @override
  Future<RestoreResult> restore() async {
    await Future<void>.delayed(latency);
    final scripted = scriptedRestore;
    if (scripted != null) return scripted;
    return initiallyOwned
        ? RestoreResult.restored
        : RestoreResult.noPurchaseFound;
  }
}

/// Amazon Appstore IAP bridge over the `tinycanvas/amazon_iap` platform
/// channel (Amazon Appstore SDK on the Android side). No secrets and no
/// prices live in the app; everything comes from Amazon at runtime.
class AmazonIapPurchaseService implements PurchaseService {
  AmazonIapPurchaseService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('tinycanvas/amazon_iap');

  final MethodChannel _channel;

  @override
  Future<ProductInfo?> fetchProduct() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'getProductData',
        {'sku': kUnlockAllSku},
      );
      if (res == null || res['available'] != true) return null;
      return ProductInfo(
        sku: kUnlockAllSku,
        title: (res['title'] as String?) ?? 'Unlock all 100 pictures',
        description: (res['description'] as String?) ?? '',
        price: (res['price'] as String?) ?? '',
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<PurchaseResult> purchase() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'purchase',
        {'sku': kUnlockAllSku},
      );
      return switch (res?['status'] as String?) {
        'success' => PurchaseResult.success,
        'already_owned' => PurchaseResult.alreadyOwned,
        'pending' => PurchaseResult.pending,
        'cancelled' => PurchaseResult.cancelled,
        'unavailable' => PurchaseResult.unavailable,
        _ => PurchaseResult.failed,
      };
    } on PlatformException {
      return PurchaseResult.failed;
    } on MissingPluginException {
      return PurchaseResult.failed;
    }
  }

  @override
  Future<RestoreResult> restore() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'restore',
        {'sku': kUnlockAllSku},
      );
      return switch (res?['status'] as String?) {
        'restored' => RestoreResult.restored,
        'not_found' => RestoreResult.noPurchaseFound,
        _ => RestoreResult.error,
      };
    } on PlatformException {
      return RestoreResult.error;
    } on MissingPluginException {
      return RestoreResult.error;
    }
  }
}
