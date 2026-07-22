# Implementation Checklist

Status legend: [x] done in source · [ ] owner action / needs SDK-equipped machine

## Screens (46/46)
- [x] 01 Splash · 02 Local Data Repair · 03 Welcome · 04 How to Color · 05 Sound Choice
- [x] 06 Home (hero, fresh picks, categories, badges strip, offline banner, low-storage)
- [x] 07 Explore · 08 Category Results (filter/sort/empty) · 09 Search (recents, empty)
- [x] 10/11 Page Preview (free, draft-resume, locked)
- [x] 12–17 Canvas + tool settings + palette + stickers + clear + save-failure
- [x] 18–22 My Art grid/empty/detail/rename/delete+5s-undo
- [x] 23/24 Badges + earned overlay (reduced-motion aware)
- [x] 25/26 Adult gate + cooldown
- [x] 27–35 Paywall (normal/offline/unavailable), checkout handoff, pending,
      success, failure, restore (+offline/results)
- [x] 36–38 Parent Zone, Sound & Motion, Storage & Erase (5s hold)
- [x] 39/40 Export flow + permission/OS-settings guidance
- [x] 41–44 Privacy, Terms, Licenses, About
- [x] 45/46 Update available / forced update / unsupported device / OS settings guidance

## Systems
- [x] Design tokens → ThemeData + ThemeExtension (TcThemeX)
- [x] Responsive system (compact/medium/expanded, rail↔bottom-nav, split collapse)
- [x] Canvas dual-orientation layout (landscape docks left/right, portrait stacked)
- [x] SQLite schema + migrations + integrity check + repair (catalog_items,
      artworks, progress, badges, settings, entitlement_cache, recent_searches)
- [x] 120-item catalog seed; 20 free / 100 premium invariant + tests
- [x] Coloring engine: fill/brush/marker/pencil/stamps/splash/eraser/clear,
      undo/redo, 1–4× zoom + pan, 24 named colors + recents, size/opacity/
      tolerance, stamp move/resize/rotate, autosave, atomic recoverable saves,
      PNG export, thumbnails
- [x] Artwork library: resume/rename/duplicate/favorite/delete+undo/sort/
      filter/storage usage/missing-file handling
- [x] Adult gate (hold 3s, arithmetic fallback, 3-fail 30s cooldown) guarding
      purchase/restore/export/external links/erase
- [x] PurchaseService interface + Mock + Amazon channel backend; all 14 states;
      duplicate-checkout prevention; unlocks exactly 100
- [x] MediaStore export with full permission/low-storage/cancel states
- [x] Badges (4) with de-duplicated progress
- [x] Offline-first behavior + connectivity gating of Amazon-only features
- [x] Accessibility: semantics, focus order, 48/56dp targets, 200% text,
      high contrast, reduced motion, named colors
- [x] Tests: catalog invariants, document serialization, engine, adult gate,
      purchase controller, badges, database/repair, responsive, widget smoke
      at 8 Fire sizes, integration journey
- [x] Docs suite + THIRD_PARTY_NOTICES + .env.example + ASSET_MANIFEST.json

## Owner actions
- [ ] Final package id + release signing
- [ ] Amazon console: create IAP, final SKU, tester accounts, App Tester runs
- [ ] Final legal content (placeholders are release blockers)
- [ ] Run quality gates on a Flutter-equipped machine (see TEST_RESULTS.md)
- [ ] Physical Fire tablet passes (FIRE_DEVICE_TEST_MATRIX.md)
- [ ] Bundle Inter font (UI_FIDELITY_EXCEPTIONS.md #1)
