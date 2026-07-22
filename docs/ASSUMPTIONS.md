# Assumptions (production defaults)

Non-critical details missing from the prompt/UI source were resolved with
the defaults below. None are irreversible; all are easy to change.

## Identity & config
1. **Package id**: `com.tinycanvas.adventures` (owner supplies the final id).
2. **App name**: "TinyCanvas Adventures".
3. **SKU**: placeholder `tinycanvas_unlock_all` via `TINYCANVAS_IAP_SKU` dart-define.
4. **Version**: `1.0.0+1`.

## Catalog
5. **Per-category free distribution** (only the total "20 free" was specified):
   Going Places 3, Circus 2, Tiny Treasures 2, Home 3, Beach 2, City 2,
   Nature 4, Adorable Friends 2 — every category has at least 2 free pictures.
6. **Difficulty rotation**: Beginner/Explorer/Creator assigned round-robin
   within each category so all difficulties exist everywhere.
7. **Line art**: original procedural vector scenes generated from
   deterministic seeds (no bundled bitmaps), guaranteeing original art with
   no third-party rights issues.

## Coloring engine
8. **Named colors**: the UI source names 16 swatches; the spec requires 24.
   8 additional kid-friendly named colors were added (Berry, Grass, Honey,
   Flamingo, Sea Glass, Butter, Charcoal, plus White) in the same palette family.
9. **Completion heuristic**: an artwork is marked "completed" once it has
   ≥10 effective ops (used only for library sorting/labels).
10. **Fill tool**: vector radial flood approximation matching the prototype's
    look (see UI_FIDELITY_EXCEPTIONS.md).
11. **Autosave**: 2s idle debounce + on app background + before leaving canvas.
12. **Recent colors**: last 8, most recent first.

## Policies
13. **Low storage threshold**: warn below 300 MB free.
14. **Adult gate**: hold-both-stars 3s; arithmetic alternative uses sums
    (6..12) + (3..8); 3 failures → 30s cooldown.
15. **Delete undo window**: 5 seconds (single-level restore).
16. **Artwork names**: 1–40 characters, path-unsafe characters stripped.
17. **Sound**: sound modes and toggles are fully wired in settings; no audio
    files ship in v1 (no third-party audio rights), so modes gate future audio.
18. **Text scaling**: supported to 200% and clamped there (grids drop one
    column at ≥160% to preserve touch targets).
