#!/usr/bin/env bash
set -euo pipefail

base_url="${1:?usage: smoke.sh https://catalog.example.com}"
base_url="${base_url%/}"

if [[ "$base_url" != https://* ]]; then
  echo "Production smoke requires an HTTPS URL" >&2
  exit 2
fi

health="$(curl --fail --silent --show-error "$base_url/health")"
worker="$(curl --fail --silent --show-error "$base_url/health/worker")"
stats="$(curl --fail --silent --show-error "$base_url/catalog/stats")"
browse="$(curl --fail --silent --show-error \
  "$base_url/products/browse?retailer=pyaterochka&taxonomy=all&limit=1")"
curl --fail --silent --show-error \
  "$base_url/products/browse?retailer=magnit&taxonomy=preparedFood&limit=1" >/dev/null
curl --fail --silent --show-error \
  "$base_url/products/browse?retailer=magnit&taxonomy=hotBakery&limit=1" >/dev/null
python - "$health" "$worker" "$stats" "$browse" <<'PY'
import json
import sys

health, worker, stats, browse = map(json.loads, sys.argv[1:])
assert health == {"status": "ok"}
assert worker["status"] in {"ok", "pending"}
assert worker["database"] == "reachable"
required_totals = {
    "total_products", "products_with_barcode", "products_with_image",
    "products_with_complete_kbju", "good_products", "partial_products",
    "needs_review", "usable_products",
}
assert required_totals <= stats["totals"].keys()
required_retailers = {
    "pyaterochka", "magnit", "perekrestok", "vkusvill", "fix-price", "pobeda",
}
assert required_retailers <= {item["slug"] for item in stats["retailers"]}
for item in stats["retailers"]:
    assert {"total_products", "with_barcode", "with_image",
            "with_complete_kbju", "usable", "prepared_food", "hot_bakery"} <= item.keys()
assert isinstance(browse["items"], list)
assert "nextCursor" in browse
PY
echo "Catalog API smoke checks passed"
