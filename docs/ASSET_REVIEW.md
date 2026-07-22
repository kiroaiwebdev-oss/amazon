# Asset Review

## Line art & scenes (120 coloring pages)

- **All original.** Every coloring page, thumbnail, and hero illustration is
  generated at runtime by `LineArtPainter` / `ScenePainter`
  (`lib/core/graphics/scene_painter.dart`) from deterministic seeds 1–120.
  No bitmaps are bundled; no third-party art is used or referenced.
- Ports the approved prototype's procedural `scene(seed, line)` renderer, so
  the visual language matches the UI source.
- Deterministic seeds mean a picture always looks the same on every device
  and after reinstall.
- Full record: `ASSET_MANIFEST.json` (120 entries, ids `tc_CC_II`,
  20 free / 100 premium) + `assets/catalog/catalog_manifest.json`.

## Icons

- 26 original vector icons drawn as path data in
  `lib/core/widgets/tc_icons.dart`, matching the prototype's inline SVGs.
  No icon fonts, no third-party icon packs.

## Fonts

- Currently system Roboto fallback (see UI_FIDELITY_EXCEPTIONS.md #1).
  When the owner bundles Inter, it is licensed under SIL OFL 1.1 — add the
  license text to THIRD_PARTY_NOTICES.md.

## Audio

- None bundled in v1. Sound settings gate future original/licensed audio.

## Rights conclusion

No third-party creative assets ship in the app. The only third-party
material is code libraries (see THIRD_PARTY_NOTICES.md). Commercial-rights
final review remains with the owner per the definition of done.
