# Run the Flutter mobile demo

Flutter 3.47.2 / Dart 3.13.2 was used for this milestone. Install Flutter and platform tooling, then from this repository:

```sh
flutter pub get
flutter run
flutter analyze
flutter test
flutter build web
```

Choose an Android emulator/device or an iOS simulator on macOS for the mobile app. Android/iOS scaffold exists, but native device builds were not validated in this Windows workspace: Android SDK is missing and iOS requires macOS/Xcode. Web is an optional test harness, not the selected product platform.

All records are fictional, held in memory and reset on app restart. No backend, identity provider, real sharing, medical file upload or notifications. Do not enter real medical data. See [milestone scope](MILESTONE.md) and [architecture decision](ADR-001-flutter-milestone.md).

Try Overview -> Add record; Records -> verified example (read-only); Care -> create and complete/cancel an appointment or log a medication slot; Sharing -> select exact records and recipient/expiry -> consent -> recipient preview -> revoke -> preview denied. Switch Milo/Luna to check per-pet separation. The demo uses current device time for expiry and fictional appointment dates; tests inject a clock for deterministic expiry boundaries.

`test/` contains Flutter domain/controller/widget tests. `tests/`, `src/`, `scripts/` and `pawverse-health-uiux.html` remain the previous web prototype and its checks. Flutter captures go into ignored `test-artifacts/`. Screenshot tests load fonts from the installed Flutter SDK via `FLUTTER_ROOT` or the test executable's ancestry; no fonts or SDK paths are copied into this repository.

Production follow-up: backend contracts and auth, durable consent/audit enforcement, clinical policy, localization, native device accessibility/performance tests, stable owned bundle IDs/signing and custom launcher assets. Generated example bundle IDs are development identifiers, not store registration.
