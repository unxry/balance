# Balance catalog builder

Mac-side, local-only pipeline. Flutter consumes only the normalized SQLite
snapshot and has no Python dependency.

```sh
python3 -m tools.catalog_builder probe
python3 -m tools.catalog_builder sync off_searchalicious
python3 -m tools.catalog_builder sync off
python3 -m tools.catalog_builder build --allow-degraded
python3 -m tools.catalog_builder verify
python3 -m tools.catalog_builder report
```

`sync off` streams the official daily OFF bulk export once and writes only a
small normalized, gitignored cache. Builds are atomic and reject a usable-count
regression below the current floor. `--allow-regression` is an explicit escape
hatch for an explained source change.

`--allow-degraded` permits a build from validated last-known-good caches when a
core source probe is temporarily unavailable; a missing or invalid cache still
fails the build. Retailer aliases such as `sync pyaterochka` are accepted.

Open-Inflation adapters are safety-gated. Their current documented setup uses
Camoufox, so Balance reports `ACCESS_BLOCKED` and performs no retailer request.
Kuper is disabled and requires authorized partner credentials.
