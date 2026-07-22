# TinyCanvas Adventures

An offline-first coloring studio for children ages 3–12, built exclusively for
**Amazon Fire OS tablets**. 120 original coloring pages across 8 categories,
a real multi-tool coloring engine, local-only artwork library, badges, a
caregiver Parent Zone, and one Amazon Appstore in-app purchase that unlocks
all 100 premium pictures.

- **No accounts. No ads. No tracking. No cloud.** Everything lives on the tablet.
- **Guest-first**: the child can color within seconds of first launch.
- **UI source of truth**: the approved 46-screen HTML/CSS prototype
  (`TinyCanvas-46-Screen-UI-Source.zip`) — recreated pixel-faithfully in
  Flutter, fully responsive in both portrait and landscape.

## Quick start

```bash
flutter pub get
flutter run            # uses the Mock purchase backend by default
```

### Build flavors (dart-defines)

| Define | Default | Purpose |
|---|---|---|
| `TINYCANVAS_PURCHASE_BACKEND` | `mock` | `mock` or `amazon` (Amazon IAP via platform channel) |
| `TINYCANVAS_IAP_SKU` | `tinycanvas_unlock_all` | Placeholder SKU; set the final SKU from the Amazon Developer Console |

```bash
# Release build against the Amazon IAP backend
flutter build apk --release \
  --dart-define=TINYCANVAS_PURCHASE_BACKEND=amazon \
  --dart-define=TINYCANVAS_IAP_SKU=your_final_sku
```

### Quality gates

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test/app_flow_test.dart   # on device/emulator
flutter build apk --debug && flutter build apk --release
```

## Project layout

```
lib/
  main.dart                  # entrypoint, DI composition root
  app/                       # app shell, routing, theme (design tokens)
  core/                      # database, graphics, platform channels,
                             # responsive system, shared widgets
  data/                      # models, repositories, catalog seed (120 items)
  features/                  # feature-first modules: home, catalog, preview,
                             # coloring, artwork library, badges, purchase,
                             # export, adult gate, parent zone, legal,
                             # onboarding, initialization/system screens
test/                        # unit + widget tests
integration_test/            # on-device critical journey
assets/catalog/              # generated catalog manifest (120 records)
docs/                        # all engineering & release documentation
android/                     # Fire OS host: MethodChannels for MediaStore
                             # export and Amazon IAP; no Google dependencies
```

## Documentation index

All engineering docs live in [`docs/`](docs/): architecture, assumptions,
UI source inventory, fidelity exceptions, implementation checklist, Amazon
IAP setup, Fire device test matrix, privacy implementation, security review,
asset review, test results, known limitations, and the release checklist.

## What the owner still supplies before submission

Final package id, final SKU + Amazon console configuration, final legal
content (privacy policy / terms), release signing, commercial-rights review,
physical Fire tablet testing, and Appstore submission. See
`docs/RELEASE_CHECKLIST.md`.
