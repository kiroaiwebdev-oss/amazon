# Known Limitations

1. **No compiled verification yet.** The authoring sandbox had no Flutter/
   Dart/Gradle/Android SDK and no network, so analysis, tests, and APK
   builds have not been executed. Expect a normal first-compile pass
   (typos/analyzer nits possible) on a Flutter-equipped machine. All gates
   and commands are in docs/TEST_RESULTS.md.
2. **Amazon Appstore SDK not wired.** `AmazonIapPurchaseService` and the
   `MainActivity.kt` channel are implemented, but the actual Appstore SDK
   calls are TODO hooks (SDK unavailable offline). Mock backend is complete.
   See docs/AMAZON_IAP_SETUP.md.
3. **Inter font not bundled** (no network) — Roboto fallback. UI_FIDELITY_EXCEPTIONS #1.
4. **Legal placeholders.** Privacy Policy and Terms screens ship with clearly
   marked placeholder copy — release blockers.
5. **Golden baselines not generated.** Golden tests require a first run with
   `flutter test --update-goldens` on the reference machine; the smoke/
   responsive suites cover layout regressions until then.
6. **Fill is a vector approximation** of raster flood fill (intentional;
   documented in UI_FIDELITY_EXCEPTIONS #4).
7. **No audio files in v1** — sound settings are wired but silent (ASSUMPTIONS #17).
8. **Procedural art variance**: line art matches the prototype's generator
   family, not stroke-for-stroke (UI_FIDELITY_EXCEPTIONS #5).
9. **Single-level delete undo** (5s window) rather than a full trash can —
   matches the approved UI.
10. **Thumbnails regenerate lazily** after cache clears; first library open
    after a clear may show skeletons briefly on low-end devices.
