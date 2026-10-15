#!/bin/sh
set -eu

python3 -m tools.catalog_builder probe
python3 -m tools.catalog_builder sync off_searchalicious || true
python3 -m tools.catalog_builder sync off || true
if [ "${BALANCE_ALLOW_CATALOG_REGRESSION:-false}" = "true" ]; then
  python3 -m tools.catalog_builder build --allow-degraded --allow-regression
else
  python3 -m tools.catalog_builder build --allow-degraded
fi
python3 -m tools.catalog_builder verify
python3 -m tools.catalog_builder report
