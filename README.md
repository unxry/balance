# Balance

Flutter nutrition and weight diary with an optional AI meal-photo flow. User
profile, daily food, water, streak, and weight history are stored locally with
Hive/SharedPreferences. Photos are normalized and stripped of metadata before
being sent to the configured HTTPS backend. The app contains no advertising or
tracking SDK.

## Architecture

- `lib/models`: validated local and API-facing domain models.
- `lib/providers`: app/session state and backward-compatible Hive persistence.
- `lib/services`: image sanitization, typed AI networking, Open Food Facts, and
  local storage initialization.
- `lib/screens` and `lib/widgets`: Provider-driven Material UI.
- `test`: unit and widget coverage for date boundaries, corrupt data, business
  calculations, networking failures, permissions/cancellation, and onboarding.

The activity screen intentionally reports that step data is unavailable. A
future HealthKit/CoreMotion implementation must add real permissions,
entitlements, privacy disclosures, and tests before showing step counts.

## Local quality gates

```sh
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build ios --debug --no-codesign
flutter build ios --release --no-codesign
```

The iOS project targets iOS 15 and uses Flutter's Swift Package Manager
integration. Every current iOS plugin ships an SPM package, so CocoaPods and a
`Podfile` are intentionally unnecessary.

## Release blockers owned outside this repository

- Set `BALANCE_SUPPORT_URL` to the confirmed `mailto:` or HTTPS support
  destination and publish a public privacy-policy URL.
- Confirm ownership/signing for `com.balancetracker.track` in the Apple
  Developer account.
- Document the legal identity, retention/deletion behavior, subprocessors, rate
  limits, request limits, logging, and abuse controls of the Cloudflare Worker
  and its upstream AI provider. Worker source is not included here.
- Complete App Store Connect privacy answers so they match
  `ios/Runner/PrivacyInfo.xcprivacy` and the in-app policy.
