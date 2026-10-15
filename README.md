# Balance

Balance is a Flutter/iOS wellness diary for food, water, weight, body measurements
and personal progress. It uses warm neutral colours, olive accents, Fraunces/Inter
typography and accessible light/dark themes. Russian and English are supported.

## Features

- Food diary, barcode search, offline food catalog and personal recipes.
- Water logging with a configurable goal and local reminders.
- Weight and chest/hip measurement histories, calendar periods and synchronized
  comparison charts. Missing readings stay missing; no values are invented.
- Local profile, achievements, versioned backup/restore and automatic snapshots.
- Daily Tips 2.0: **180 authored bilingual tips**, 18 in each of ten categories,
  saved ideas, dated history and explicitly checked optional tasks.

Step data is unavailable in the current HealthService implementation. The UI and
tip selector never invent steps. An optional meal-photo recognition flow sends
sanitized images to the configured HTTPS service; this is separate from daily
tips and is not required for their operation.

## Daily Tips 2.0

Tips work entirely offline, without an AI API or paid service. The service writes
the selected ID and the local calendar date together in one versioned Hive record
(`balance_user` → `dailyTipsV1`). A restart, language change, profile update or
personalization toggle cannot replace a tip already assigned to that date.
Returning to a previously visited date after timezone travel restores that date's
selection. Foreground civil-clock checks and resume handling cover day and
clock/timezone changes; the timer also fires at local midnight.

The selector rotates categories, excludes IDs seen within 60 calendar days when
sufficient eligible tips exist, prefers unseen tips throughout a full cycle, and
then uses older eligible tips. Completed actions are deprioritized after the cycle.
Small catalogs use a finite fallback and avoid the immediately previous ID whenever
another eligible ID exists. Store operations are serialized across service instances
sharing a Hive box. A failed write is retryable and cannot poison the queue.

Personalization is **off by default**. Opting in allows only contextual tips backed
by actual food/water logs, available steps or multiple dated weight readings.
The displayed explanation records which kind of data informed selection. Lower
food logs are treated as potentially incomplete, with gentle reminders about
regular meals and no additional food restriction. No diagnostic inference is made.
All selection and history remain on the device; daily tips send no network requests.

History/favourites/completion live in the existing user box and are covered by its
backup format. Old installations need no destructive data migration. Stable catalog
IDs must be retained when editing copy; retired entries should remain readable.
`DailyTipsRepository` can be replaced later without changing the UI.

General guidance was checked against the [NHS balanced eating guide](https://www.nhs.uk/live-well/eat-well/how-to-eat-a-balanced-diet/eating-a-balanced-diet/),
[NHS hydration guidance](https://www.nhs.uk/Live-well/eat-well/food-guidelines-and-food-labels/water-drinks-nutrition/),
[WHO activity guidance](https://www.who.int/health-topics/physical-activity/physical-activity)
and [CDC sleep guidance](https://www.cdc.gov/sleep/about/). Tips are original,
general wellness suggestions, without diagnostic or guaranteed weight-loss claims.

## Technologies and layout

Flutter/Dart (Dart SDK `^3.9.2`), Provider, Hive, SharedPreferences, SQLite/sqflite,
fl_chart, local notifications and Flutter's iOS Swift Package Manager integration.

| Path | Contents |
| --- | --- |
| `lib/models` | Validated domain and persistence models |
| `lib/data/daily_tips_catalog.dart` | 180 stable RU/EN tip records |
| `lib/services` | Tip selection/storage, analytics, backup, catalog and networking |
| `lib/providers` | Session state and backward-compatible local persistence |
| `lib/screens`, `lib/widgets` | App screens and shared UI |
| `lib/theme` | Colours, typography, motion and translations |
| `assets` | Fonts, illustrations and safe bundled food catalog |
| `test` | Unit, persistence, widget, layout and visual regression coverage |
| `catalog_backend`, `tools/catalog_builder` | Optional catalog service and tooling |
| `tool/daily_tips_preview.dart` | Simulator preview using isolated synthetic data |

## Setup and iOS

Install Flutter with a compatible Dart SDK and Xcode with iOS simulator support.
The deployment target is iOS 15. Resolve dependencies and run:

```sh
flutter pub get
flutter run -d <ios-device-or-simulator-id>
```

The project uses Swift Package Manager for its iOS plugins; no CocoaPods Podfile
is required. A physical device needs your own Apple signing configuration. To build
without signing:

```sh
flutter build ios --release --no-codesign
```

To review chart/tip UI without accessing real user data:

```sh
flutter run -d <simulator-id> --target tool/daily_tips_preview.dart
```

The preview includes Flutter's SDK driver extension. To capture all chart modes,
the tip sheet, history and dark/English states in a simulator:

```sh
BALANCE_SCREENSHOT_DIR=/tmp/balance-preview flutter drive \
  -d <simulator-id> --target tool/daily_tips_preview.dart \
  --driver test_driver/balance_capture.dart
```

That entry point creates temporary Hive boxes with synthetic records. Production
continues to use `lib/main.dart` and the existing local data directory.

## Validation

```sh
dart format --output=none --set-exit-if-changed lib test tool/daily_tips_preview.dart
flutter analyze
flutter test
```

The focused tip tests cover first launch, empty data, 500-day rotation, concurrent
selection and edits, restart, calendar/year/month boundaries, civil-date timezone
travel, repeated hours, favourites, explicit tasks, context eligibility, failure
recovery, legacy stores and backup restoration. Widget tests cover RU/EN, both
palettes, reduced motion and 200% text at widths 320/414/430 points. Chart tests
verify actual touch selection and comparison alignment.

## Configuration and repository hygiene

No key is needed for daily tips or local tracking. Optional backend configuration
and safe example environment files are documented in `catalog_backend/README.md`.
Set `BALANCE_SUPPORT_URL` to a confirmed mailto/HTTPS support destination before
release. Configure Apple signing yourself; certificates and provisioning profiles
are excluded from Git. Dependency lockfiles are committed for reproducibility.

User Hive/SQLite stores, app containers, backup archives, local captures, real
`.env` files, private keys, certificates and build outputs are ignored. The bundled
compressed food database is a public catalog asset, not a personal database.

App Store release still requires confirmed support/privacy destinations, ownership
of the bundle ID `com.arturovna01.balancetracker`, a review of the optional photo backend's
privacy/retention practices, and matching App Store Connect disclosures. The source
for that photo backend is outside this repository. No advertising or tracking SDK
is included.
