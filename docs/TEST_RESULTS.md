# Test Results

## Honest environment disclosure

This project was authored in a sandbox **without** the Flutter SDK, Dart
SDK, Gradle, Android SDK, or network access. Therefore `dart format`,
`flutter analyze`, `flutter test`, and `flutter build apk` **could not be
executed here**, and no pass/fail evidence is claimed. What follows is the
exact, ready-to-run gate plan. Static structural checks that *were* run in
the sandbox are listed at the bottom.

## Commands to run (in order)

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze                       # gate: zero errors
flutter test                          # gate: all pass
flutter test integration_test/app_flow_test.dart   # on device/emulator
flutter build apk --debug
flutter build apk --release \
  --dart-define=TINYCANVAS_PURCHASE_BACKEND=amazon \
  --dart-define=TINYCANVAS_IAP_SKU=your_final_sku
```

## Test inventory

| File | Covers |
|---|---|
| test/catalog_invariants_test.dart | Exactly 120 items, 20 free / 100 premium, 8×15 categories, unique ids/seeds, difficulties, searchable keywords |
| test/coloring_document_test.dart | JSON round-trip, normalized (rotation-safe) coordinates, corrupt → FormatException recovery, clear semantics, 1.18 paper aspect |
| test/coloring_engine_test.dart | Undo/redo, undoable clear, point decimation (memory), idle autosave, failed-save → recover, 1–4× zoom + pan clamps, recent colors, deterministic splash |
| test/adult_gate_test.dart | 3s hold unlock, early release, progress, arithmetic path, failure counting, 3-fail → 30s cooldown + expiry |
| test/purchase_controller_test.dart | Offline, product-unavailable, success (+persisted entitlement), cached-owned offline, cancelled/failed, pending, restore success/none/error, restore offline, double-tap guard |
| test/badge_service_test.dart | All 4 badges, de-duplication, thresholds 20/4/8/24 |
| test/database_test.dart | Fresh-db integrity + seed, search, tampered-catalog repair, artwork CRUD + delete/undo restore, name validation, entitlement cache, recent searches, settings round-trip, erase-keeps-entitlement |
| test/responsive_test.dart | Breakpoints, 2/3/4 columns + large-text drop, orientation at all 8 Fire sizes, rail↔bottom nav, split collapse, rail widths |
| test/widget_smoke_test.dart | Welcome at all 8 Fire sizes (no overflow), 200% text, portrait+landscape How-to-Color, high-contrast theme |
| integration_test/app_flow_test.dart | First launch → onboarding → home critical journey |

## Critical journeys (manual, on device)

The 13 named journeys (first-launch coloring, resume draft, locked →
purchase → unlock, restore on reinstall, export incl. permission denial,
rename/delete/undo, badge earn, adult-gate failure/cooldown, offline
everything, low storage, corruption repair, 200% text pass, TalkBack pass)
are enumerated with expectations in FIRE_DEVICE_TEST_MATRIX.md.

## Static checks performed in-sandbox

- Relative-import resolution across all 38 `lib/` Dart files: **all resolve**.
- Catalog manifest generation cross-checked against `catalog_seed.dart`
  logic: 120 records, 20 free / 100 premium — matches.
- API cross-reference of every screen ↔ widget/controller/repository
  signature during authoring.
