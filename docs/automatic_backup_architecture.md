# Automatic Backup architecture

## Scope

The backup is a versioned, encrypted snapshot of user-owned data:

- Profile and Goals, including Calorie Goal History;
- WeightHistory, DiaryHistory and WaterHistory;
- Recipes and RecipeVersions;
- Favorites;
- reminder settings and theme;
- achievements metadata.

The downloaded product catalog is excluded because it is rebuildable from the central catalog; diary entries retain their immutable food snapshots.

## Format and security

- Canonical JSON envelope with `schemaVersion`, `createdAt`, installation ID and per-section checksums.
- Payload encrypted on-device with an authenticated cipher; the key is stored in Keychain/Keystore and is never uploaded with the backup.
- Cloud adapters are replaceable: iCloud Drive first on iOS, then an authenticated account-backed provider if cross-platform restore is required.
- No analytics, catalog cache, access tokens or raw health-provider credentials are included.

## Backup flow

1. Read a transactionally consistent local snapshot.
2. Serialize and validate it in a temporary file.
3. Encrypt, upload to a temporary remote object and verify size/checksum.
4. Atomically promote it to the current backup and retain a short rollback history.
5. Record only completion metadata locally; failures leave the last valid backup untouched.

Automatic runs should be coalesced after meaningful writes, require suitable connectivity/power, and use exponential backoff. Manual “Back up now” remains available.

## Restore flow

Restore first decrypts and validates into memory, migrates a copy to the current schema, and shows a preview with date and item counts. The user chooses replace or merge. The import then runs in one local transaction with deterministic IDs and conflict rules; any failure rolls back completely. Existing local data is never cleared before the candidate snapshot has passed validation.

## Compatibility and rollout

- Every schema migration must be forward-tested against saved fixtures from older versions.
- Unknown future fields are ignored; unsupported future schema versions are rejected without mutation.
- Ship behind a feature flag, then validate local export/import before enabling a cloud adapter.
- Restore, corruption, interrupted-upload and key-loss scenarios require automated tests and physical-device QA before release.
