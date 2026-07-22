# UI Fidelity Exceptions

Every known deviation from the approved HTML/CSS source, with reasons.
Everything not listed here follows the source exactly (tokens, radii,
shadows, gradients, spacing, microcopy, navigation model, tablet-first
responsive behavior in both orientations).

1. **Inter font not bundled.** The build sandbox has no network access, so
   the Inter font files could not be downloaded. The theme keeps the exact
   size/weight scale but falls back to Roboto. *Fix before release*: drop
   Inter (SIL OFL 1.1) into `assets/fonts/`, register in `pubspec.yaml`, set
   `TcType.fontFamily = 'Inter'`, and add the OFL text to THIRD_PARTY_NOTICES.

2. **`backdrop-filter` blur behind modals** → replaced with a solid dark
   scrim (`rgba(17,28,52,0.55)`). Real-time blur is expensive on low-end
   Fire tablets; the scrim preserves contrast and focus.

3. **CSS radial background washes** (multi-stop `radial-gradient` page
   backgrounds) → approximated with layered linear/radial gradients tuned by
   eye to the same hues. Difference is subtle at tablet DPI.

4. **Fill tool** — the prototype fakes fills with a radial pool; production
   implements the same *visual* (radial pool with tolerance-driven radius,
   multiplied under line art) as a vector op rather than a raster flood fill.
   This keeps fills resolution-independent, rotation-safe, undoable, and
   memory-cheap on 1–2 GB Fire tablets.

5. **Procedural scene art** — thumbnails/heroes/line art are Flutter
   `CustomPainter` ports of the prototype's `scene(seed, line)` JS renderer.
   Compositions match in structure/palette but are not stroke-identical,
   since the JS uses canvas APIs with different curve tessellation.

6. **Hover states** from the desktop prototype are mapped to pressed/focus
   states (tablets have no hover). Focus rings follow the source's gold
   outline.

7. **200% text**: the prototype does not define large-text layouts; grids
   drop one column at ≥160% scale and split layouts stack at ≥170% to keep
   the 56dp child touch targets — recorded as an accessibility-driven
   extension, not a redesign.
