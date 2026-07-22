# Architecture

## Goals

- Offline-first, local-only, accountless children's app for Amazon Fire OS tablets.
- Pixel-faithful recreation of the approved 46-screen UI source, fully
  responsive in portrait and landscape.
- Testable seams around every platform boundary (database, filesystem,
  connectivity, MediaStore export, Amazon IAP).

## Stack

- **Flutter** (stable channel, Dart 3.3+), Material 3 disabled in favor of a
  fully token-driven custom theme.
- **State management**: `provider` + `ChangeNotifier` (small, stable,
  license-friendly BSD-3). `AppState` is the composition root state;
  feature controllers (`ColoringEngine`, `PurchaseController`,
  `AdultGateController`) are scoped ChangeNotifiers.
- **Storage**: `sqflite` (SQLite, works on Fire OS; MIT) with explicit
  migrations and `PRAGMA integrity_check`; artwork documents are JSON files
  written atomically (temp file + rename) under app-private storage.
- **Routing**: `Navigator 1.0` with a single typed `onGenerateRoute` table
  (`app/routing/app_router.dart`), route guards (onboarding, entitlement,
  adult gate) and named routes for all 46 screens. Every route has a valid
  return path.
- **DI**: constructor injection from `main.dart`. Platform backends chosen by
  `TINYCANVAS_PURCHASE_BACKEND` dart-define (mock | amazon).

### Package license / Fire OS compatibility review

| Package | License | Fire OS note |
|---|---|---|
| sqflite | MIT | Plain Android SQLite, no Google services |
| path | BSD-3 | Pure Dart |
| path_provider | BSD-3 | Standard Android storage dirs |
| provider | MIT | Pure Dart |
| flutter_lints (dev) | BSD-3 | dev only |
| sqflite_common_ffi (dev) | MIT | test only |

No Google Play Services, Google Billing, Firebase, or Google-only
dependencies anywhere in the dependency graph.

## Layering

```
widgets (features/*) ──> controllers (ChangeNotifier)
        │                     │
        ▼                     ▼
  core/widgets + theme   repositories (data/) ──> AppDatabase (sqflite)
        │                     │
        ▼                     ▼
  core/responsive       platform services (core/platform)
                          ├─ ConnectivityService (Io | Mock)
                          ├─ MediaExportService (Channel | Mock)
                          └─ PurchaseService (AmazonIap | Mock)
```

- **Typed failures**: platform boundaries return sealed-style result enums
  (`ExportOutcome`, `PurchaseResult`, `RestoreResult`, `SaveState`,
  `InitResult`) instead of throwing across layers.
- **Repositories** (`data/repositories.dart`): catalog, artworks, settings,
  badges, entitlement cache, recent searches. All raw SQL lives here.

## Coloring engine

- `ColoringDocument`: ordered op list (`StrokeOp`, `FillOp`, `StampOp`,
  `SplashOp`, `ClearOp`) with **normalized 0..1 coordinates**, so artwork is
  rotation- and resolution-independent (portrait ⇄ landscape safe).
- `ColoringEngine`: tool state, undo/redo (memory-aware: point decimation,
  bounded redo), zoom 1×–4× with clamped pan, autosave ~2s after inactivity,
  on background, and before leaving the canvas; atomic saves via
  `DocumentStore` (file or in-memory for tests) with
  Saving/Saved/Save-failed states and corruption recovery.
- `CanvasPainter`: paints ops under the line art (multiply blend), so strokes
  never cover outlines. Line art is original procedural vector art
  (`LineArtPainter`) generated from deterministic seeds.
- PNG export renders the document at 1680px wide off-screen, then hands bytes
  to the MediaStore channel.

## Responsive system

`core/responsive/responsive.dart` mirrors the approved CSS breakpoints:
compact <720dp (bottom nav, single column), medium <1080dp (74dp rail,
2–3 columns), expanded ≥1080dp (94dp rail, 4 columns). Split layouts
(1.15fr/0.85fr) collapse when compact or at ≥170% text. The canvas uses a
dedicated orientation layout: landscape = left tool dock / centered paper /
right color rail; portrait = paper on top, horizontal color rail and tool
dock below. No hard-coded coordinates anywhere.

## Android host (Fire OS)

- `MainActivity.kt` implements two MethodChannels:
  - `tinycanvas/media_export`: `exportPng` (MediaStore, Pictures/TinyCanvas),
    `getFreeBytes`.
  - `tinycanvas/amazon_iap`: `getProductData`, `purchase`, `restore`
    (wired for Amazon Appstore SDK integration; see docs/AMAZON_IAP_SETUP.md).
- `minSdk 25`, `targetSdk 34`, portrait+landscape, `android:resizeableActivity`,
  low-memory callbacks flow into Flutter lifecycle handling.
