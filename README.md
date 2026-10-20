# Balance

Balance is a Flutter/iOS wellness diary for food, water, weight, body measurements
and personal progress. It uses warm neutral colours, olive accents, Fraunces/Inter
typography and accessible light/dark themes. Russian and English are supported.

## Features

- Food diary, barcode search, offline food catalog and personal recipes.
- Water logging with a configurable goal and local reminders.
- Weight and chest/waist/hip measurement histories, calendar periods and synchronized
  comparison charts. Missing readings stay missing; no values are invented.
- Local profile, achievements, versioned backup/restore and automatic snapshots.
- Daily Tips: **150 practical bilingual action plans** in ten categories,
  saved ideas, dated history and explicitly checked optional tasks. All 180 legacy
  IDs remain readable through revised articles and 145 retired aliases.

Step data is unavailable in the current HealthService implementation. The UI and
tip selector never invent steps. An optional meal-photo recognition flow sends
sanitized images to the configured HTTPS service; this is separate from daily
tips and is not required for their operation.

## Daily Tips and weight insights

Each plan starts with one action, a usable example, a substitution, two or three
steps and a self-reported completion criterion. Background and sources are folded
below the practical content. Plans can open the existing food diary or real charts.

The original daily assignment stays in history. An explicitly chosen alternative
is stored alongside it for that date, with separate completion and version data.
Returning to the original or restarting does not discard either completion.
Library reading and saving never fabricate a visit or a completed task.

Tips work entirely offline, without an AI API or paid service. The service writes
the selected ID and the local calendar date together in one versioned Hive record
(`balance_user` → `dailyTipsV1`). A restart, language change, profile update or
personalization toggle cannot replace a tip already assigned to that date.
If safety or goal context changes, an unsuitable weight-management article is
replaced with general support under the same stored ID.
Returning to a previously visited date after timezone travel restores that date's
selection. Foreground civil-clock checks and resume handling cover day and
clock/timezone changes; the timer also fires at local midnight.

The catalog has **137 universal and 13 contextual plans**, with 119 universal
rotation topics. The selector excludes recorded IDs and related topics within
60 calendar days when an eligible alternative exists. Category changes take
priority over unseen content after that exclusion, preventing a large food
category from forming a long run. Same-day assignments and explicit choices
remain stable across restarts.
The actual filtered pool is exposed by `eligiblePlans`; tests verify 137 universal
plans for incomplete logs, unknown/minor safety context and all restriction flags.
A restricted repository or many explicit choices can exhaust fresh topics: the
finite fallback then uses older eligible content and avoids adjacent repeats when
possible. This is not an unconditional no-repeat guarantee. Manual choices remain
under the user’s control. Store operations are serialized across service instances
sharing a Hive box. A failed write is retryable and cannot poison the queue.

Personalization is **off by default**. Opting in allows only contextual tips backed
by actual food/water logs, available steps, body measurements or dated weight readings.
The displayed explanation records which kind of data informed selection.
A repetition signal requires at least three completed logged days, six entries and
at most three distinct logged foods. It describes records rather than the full
diet. Sparse-weight advice requires actual readings; missing records never prove
an absent habit. Lower
food logs are treated as potentially incomplete, with gentle reminders about
regular meals and no additional food restriction. No diagnostic inference is made.
All selection and history remain on the device; daily tips send no network requests.

History/favourites/completion live in the existing user box and are covered by its
backup format. Old installations need no destructive data migration. Stable catalog
IDs must be retained when editing copy; retired entries should remain readable.
`DailyTipsRepository` can be replaced later without changing the UI.

The “Why is weight stable?” page uses daily medians and a robust slope of actual
readings across up to 28 days. A possible plateau requires at least 21 well-covered
days, a losing goal and confirmed adult safety context. Forecasts never enter this
calculation. Short, sparse or noisy histories remain provisional or unclassified.
Thresholds are engineering heuristics, not clinically validated diagnostic criteria.

Sources, claim limits and remaining clinical review are recorded in
[DAILY_TIPS_EVIDENCE](docs/DAILY_TIPS_EVIDENCE.md). See the
[algorithm](docs/WEIGHT_PLATEAU_ALGORITHM.md),
[redesign report](docs/DAILY_TIPS_REDESIGN_REPORT.md) and
[validation results](docs/TEST_RESULTS.md) and
[3.1 semantic audit](docs/DAILY_TIPS_31_AUDIT.md),
[machine catalog](docs/daily_tips_catalog.json) and
[3.1 release report](docs/DAILY_TIPS_31_REPORT.md).

## Weight forecast and progress

Real weight and circumference readings use shape-preserving cubic interpolation
on actual local calendar coordinates. Drawing samples are never measurements,
markers or statistics. The approach follows [PCHIP](https://docs.scipy.org/doc/scipy/reference/generated/scipy.interpolate.PchipInterpolator.html);
the selected period filters records while the visible axis fits their actual span
with a small marker inset. A single reading stays a single point near the start;
intraday intervals retain their times. Comparison uses the union of real dates.
The visible forecast is shortened for sparse history, with an explicit explanation;
sub-day views show actual readings only. This never changes the fitted horizon.
Vertical scrolling remains available through the charts and Reduce Motion disables
entry/selection transitions. Comparison shares dates and selection with separate
kg/cm scales; missing body readings stay missing.

The existing analytics service fits daily weight medians from the latest 28 calendar
days using a [Theil–Sen slope](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.theilslopes.html)
and a median residual intercept. Eligibility requires four distinct measured days
spanning at least seven inclusive days. Residual MAD filters isolated outliers;
noise, reversals, excessive rejected readings and rates above 1.5 kg/week suppress
the forecast. These are conservative product heuristics, not clinical validation.
The horizon is seven days, or fourteen with at least eight measured days spanning
two weeks; the week view always shows at most seven future days. With eight
inliers, 200 deterministic paired bootstrap samples produce a shaded range of
trend estimates. This is **not** a calibrated prediction/confidence interval for
future weight and does not represent all biological variability.

`balance_user` → `weightForecastV2` persists algorithm version, true fit time,
source fingerprints/records, fitted rate and quality metadata. New daily readings
wait until four calendar days after the last fit; pending data is checked on
startup/resume. Edits, deletions, same-day and backdated additions invalidate
immediately, including records added since the previous fit. Unchanged data does
not change the fit date. Separate observed-record metadata survives restarts.
Within the cadence, only the visible continuation reanchors to the latest real
reading; the fitted rate/date stay fixed. Stale or newly inconsistent projections
are hidden. Forecast values never enter real history, deltas or daily snapshots.

## Technologies and layout

Flutter/Dart (Dart SDK `^3.9.2`), Provider, Hive, SharedPreferences, SQLite/sqflite,
fl_chart, local notifications and Flutter's iOS Swift Package Manager integration.

| Path | Contents |
| --- | --- |
| `lib/models` | Validated domain and persistence models |
| `lib/data/daily_tips_catalog.dart` | 150 action plans and 145 legacy aliases |
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
