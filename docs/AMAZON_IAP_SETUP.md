# Amazon IAP Setup

TinyCanvas uses **one non-consumable entitlement** that unlocks all 100
premium pictures. Reference price **$4.99** — the production UI always shows
the **localized price returned by Amazon**, never a hard-coded string.

## App-side design (already implemented)

- `lib/features/purchase/purchase_service.dart`
  - `PurchaseService` interface: `fetchProduct()`, `purchase()`, `restore()`.
  - `MockPurchaseService`: default backend (`TINYCANVAS_PURCHASE_BACKEND=mock`),
    scriptable for every state; used by tests and development.
  - `AmazonIapPurchaseService`: talks to MethodChannel `tinycanvas/amazon_iap`
    (`getProductData`, `purchase`, `restore`) implemented in `MainActivity.kt`.
- `PurchaseController` drives all 14 UI states: unknown, loading, offline,
  productUnavailable, notOwned, checkoutHandoff, pending, owned, alreadyOwned,
  cancelled, failed, restoreSuccess, noPurchaseFound, restoreError.
- Ownership is cached in the `entitlement_cache` table so the unlock works
  offline after first verification. "Erase my creations" never touches it
  (Amazon owns the receipt of record).
- Duplicate checkouts are impossible: the controller has a busy latch and
  buttons disable while a purchase is in flight.
- No secrets in the app. SKU comes from `--dart-define=TINYCANVAS_IAP_SKU=...`
  (placeholder `tinycanvas_unlock_all`).

## Console steps (owner)

1. Create the app in the Amazon Developer Console (Fire OS / Android).
2. In-App Items → add **Entitlement** — title "Unlock all pictures", your
   final SKU, base list price $4.99, localized pricing per marketplace.
3. Add the Amazon Appstore SDK (Appstore SDK 3.x) to `android/app/build.gradle`
   and complete the TODO hooks in `MainActivity.kt`:
   - `getProductData` → `PurchasingService.getProductData(setOf(sku))`
   - `purchase` → `PurchasingService.purchase(sku)`; map Amazon responses to
     the channel's status strings: `success`, `already_owned`, `pending`,
     `cancelled`, `unavailable`.
   - `restore` → `PurchasingService.getPurchaseUpdates(true)` → `restored` /
     `not_found`.
   - Always call `notifyFulfillment(receiptId, FulfillmentResult.FULFILLED)`
     after granting the entitlement.
4. Test with **Amazon App Tester** (mock receipts on device), then Live App
   Testing before submission.
5. Build the Amazon flavor:
   ```bash
   flutter build apk --release \
     --dart-define=TINYCANVAS_PURCHASE_BACKEND=amazon \
     --dart-define=TINYCANVAS_IAP_SKU=your_final_sku
   ```

## Behavioral guarantees to verify on device

- Paywall offline → friendly offline state, coloring unaffected.
- Product data unavailable → "try again later" state, no dead ends.
- Pending (Ask to Buy / slow processing) → pending state persists and
  resolves on next launch/restore.
- Cancel → returns to paywall without error scare.
- Restore on a re-installed device → restores without re-charging.
- Exactly 100 premium items unlock; the 20 free items never lock.
