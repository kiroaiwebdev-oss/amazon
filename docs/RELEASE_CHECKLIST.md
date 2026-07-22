# Release Checklist

## 1. Code gates (Flutter-equipped machine)
- [ ] `flutter pub get`
- [ ] `dart format --set-exit-if-changed .` — clean
- [ ] `flutter analyze` — zero errors/warnings
- [ ] `flutter test` — all pass
- [ ] `flutter test integration_test/app_flow_test.dart` on a Fire tablet
- [ ] Golden baselines generated and reviewed vs approved UI source

## 2. Identity & signing
- [ ] Final `applicationId` (replace `com.tinycanvas.adventures`)
- [ ] Release keystore + signingConfig; keystore backed up securely
- [ ] Version name/code bumped

## 3. Amazon configuration
- [ ] IAP entitlement created; final SKU set via `TINYCANVAS_IAP_SKU`
- [ ] Appstore SDK wired in MainActivity (AMAZON_IAP_SETUP.md)
- [ ] Amazon App Tester: all purchase/restore/pending/cancel states pass
- [ ] Live App Testing round complete

## 4. Content & legal (blockers)
- [ ] Replace Privacy Policy placeholder (counsel-approved, child-directed)
- [ ] Replace Terms placeholder
- [ ] Support contact + About details final
- [ ] Commercial rights review of all shipped content
- [ ] Bundle Inter font + OFL notice (or accept Roboto and log the decision)

## 5. Device passes (physical)
- [ ] Full FIRE_DEVICE_TEST_MATRIX.md pass on Fire 7, HD 8, HD 10, Max 11 —
      both orientations, 200% text, TalkBack/VoiceView, offline, low memory
- [ ] Performance: smooth brushing on Fire 7; no autosave jank

## 6. Build & submit
- [ ] `flutter build apk --release --dart-define=TINYCANVAS_PURCHASE_BACKEND=amazon --dart-define=TINYCANVAS_IAP_SKU=<final>`
- [ ] Install release APK fresh + upgrade-over-old-version test
- [ ] Amazon content rating questionnaire (children's category)
- [ ] Screenshots/feature graphic from real devices
- [ ] Submit; archive the exact source zip + pubspec.lock with the release tag
