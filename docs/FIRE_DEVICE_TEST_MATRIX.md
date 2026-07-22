# Fire Device Test Matrix

Representative logical sizes (dp) — each panel in both orientations. These
exact 8 sizes are asserted in `test/responsive_test.dart` and
`test/widget_smoke_test.dart`.

| Device class | Portrait | Landscape | Layout expectation |
|---|---|---|---|
| Fire 7 | 600×1024 | 1024×600 | Portrait: bottom nav, 2-col grids, stacked splits. Landscape: 74dp rail, 3-col |
| Fire HD 8 | 800×1280 | 1280×800 | Portrait: 74dp rail, 3-col. Landscape: rail, split layouts active |
| Fire HD 10 | 1200×1920 | 1920×1200 | 94dp rail, 4-col, full split layouts |
| Fire Max 11 | 1200×2000 | 2000×1200 | 94dp rail, 4-col, generous gutters |

## Per-device manual pass (owner, physical devices)

For each device, in **both orientations**, verify:

1. **Canvas**: landscape = left tool dock / centered paper / right color rail;
   portrait = paper top, swatch rail + tool dock below. Artwork coordinates
   stable across rotation mid-stroke. Zoom 1–4×, two-finger pan, visible
   zoom controls.
2. **Text at 200%** (Fire OS display settings): no clipped copy, no lost
   buttons, grids drop a column, splits stack.
3. **High contrast + reduced motion** from Parent Zone: celebration overlay
   becomes static, shimmer stops.
4. **Safe areas**: status bar/nav gesture areas never overlap touch targets.
5. **Low memory**: background the app mid-coloring (autosave fires), open
   several heavy apps, return — artwork restored, no data loss.
6. **Offline**: airplane mode — everything works except purchase/restore/
   external links, which show their friendly offline states.
7. **Export**: MediaStore PNG lands in Pictures/TinyCanvas; permission deny,
   permanent deny (→ OS settings guidance path: Apps & Notifications →
   TinyCanvas Adventures → Permissions → Allow Photos and media), and low
   storage states.
8. **IAP with Amazon App Tester**: all purchase/restore states in
   docs/AMAZON_IAP_SETUP.md.
9. **Performance**: 60fps target while brushing on Fire 7 (weakest device);
   no jank > 100ms during autosave.
10. **TalkBack (VoiceView)**: full journey Home → preview → canvas → save →
    library with coherent focus order and announcements.
