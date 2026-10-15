# Balance Product Catalog

Central PostgreSQL catalog and read-only API used by the existing Flutter
`FoodCatalogRepository`. The phone keeps a small SQLite cache and incrementally
pulls changed records; it does not bundle tens of thousands of products.

## Data policy

- Missing package size or nutrition remains `NULL`; importers never estimate it.
- Every record keeps source, source URL/revision, quality, verification time and
  version history.
- Fixed overwrite priority: official manufacturer/package (1000), official
  restaurant menu (900), official retailer (800), Open Food Facts (400).
- OFF records are never promoted to `verified` by ingestion alone. Complete
  records are `good`; incomplete records are `partial`; records carrying OFF
  quality errors are `needs_review`.
- Retailer labels inferred from OFF's `stores` field have confidence `0.6` and
  are not claims of complete chain assortment.
- Fix Price official feeds accept only `catalogType=food|beverage`.
- Magnit, Pyaterochka, Perekrestok, VkusVill, Fix Price, Pobeda, Vkusno i tochka
  and ROSTIC'S can be populated only from an explicitly licensed official feed.
  No private endpoint, authentication or anti-bot mechanism is bypassed.

## Local setup and OFF synchronization

```sh
createdb balance_catalog
uv sync --group dev
BALANCE_DATABASE_URL=postgresql://localhost/balance_catalog \
  uv run python -m scripts.migrate
BALANCE_DATABASE_URL=postgresql://localhost/balance_catalog \
  uv run python -m scripts.import_off_tsv --limit 0
```

The importer streams the official compressed TSV, filters Russian-market rows,
merges them atomically and stores the source ETag. An unchanged export is
skipped. `deploy/catalog.cron.example` runs daily recent-change reconciliation
and a weekly full reconciliation. In Docker Compose, the `sync` worker performs
the same daily/weekly schedule and safely retries after transient failures.

## Licensed official feed import

The input is UTF-8 JSONL. Required fields are `sourceProductId` and `name`;
packaged retail/manufacturer products also require a valid GTIN. Restaurant
items may use an external source ID without a barcode.

```json
{"sourceProductId":"sku-42","barcode":"4601234567893","name":"Product","brand":"Brand","netWeight":180,"netWeightUnit":"g","nutrition":{"basis":"per100g","basisAmount":100,"calories":121,"protein":17,"fat":5,"carbohydrates":3},"image":{"url":"https://cdn.example/item.jpg","license":"licensed","licenseUrl":"https://example/license","attribution":"Owner"},"verified":true,"verifiedAt":"2026-09-05T10:00:00Z","revision":"42","catalogType":"food"}
```

```sh
uv run python -m scripts.import_official_jsonl feed.jsonl \
  --source-slug retailer-feed --source-name "Retailer feed" \
  --source-type official_retailer --source-url https://example/feed \
  --license-name Contract --license-url https://example/license \
  --attribution Retailer --retailer magnit
```

## API and Flutter

Run the API with `uv run uvicorn app.main:app --host 0.0.0.0 --port 8080`.
Endpoints include exact barcode lookup, ranked search, cursor-based updates and
quality/retailer coverage metrics. Configure a release build with:

```sh
flutter build ios --release \
  --dart-define=BALANCE_CATALOG_API_URL=https://catalog.example.com
```

The URL must be HTTPS. If unavailable, the existing local SQLite cache and OFF
source continue to work.

Retailer browse is exposed by `GET /products/browse` with `retailer`,
`taxonomy=all|preparedFood|hotBakery`, `limit`, and either the opaque `cursor`
or legacy `offset`. Ordering is stable and the returned `nextCursor` prevents
page overlap. Results are real source records with a valid nutrition basis and
calories; `good` and usable `partial` rows are allowed, while
missing-nutrition rows stay hidden.

## Production deployment

No server or domain values are stored in the repository. Deployment needs a
Linux host with Docker Compose, an SSH user/key, a deploy directory, and a
domain whose A/AAAA record points to that host. On the host, copy
`.env.production.example` to `.env.production`, replace every placeholder,
open TCP 80/443 and UDP 443, then run:

```sh
chmod +x deploy/*.sh
./deploy/deploy.sh
./deploy/validate.sh
./deploy/initial_sync.sh
./deploy/smoke.sh "https://$CATALOG_DOMAIN"
```

`docker-compose.prod.yml` keeps PostgreSQL and Caddy data in named volumes,
runs migrations and schema validation before API/worker startup, restarts
long-lived services, health-checks PostgreSQL/API/worker, rotates container
logs, and lets Caddy provision and renew HTTPS automatically. Required private
values are `CATALOG_DOMAIN` and `POSTGRES_PASSWORD`; they stay only in the
gitignored `.env.production` file.

Before every later deployment, create a recoverable database dump and retain
the last known-good source revision or image tag:

```sh
./deploy/backup_db.sh
./deploy/deploy.sh
./deploy/validate.sh
./deploy/smoke.sh "https://$CATALOG_DOMAIN"
```

Rollback never deletes `balance_catalog_data`. Restore the last known-good
source revision/image, rerun `deploy.sh`, `validate.sh`, and `smoke.sh`. Current
migrations are additive and recorded in `schema_migrations`; do not downgrade
the schema or restore a dump unless a reviewed migration explicitly requires
it. If database restore is unavoidable, stop API/worker, restore the verified
dump into a new named volume/database, validate it, and only then switch over.
Never run `docker compose down -v` in production.

After smoke checks pass, build Flutter with
`--dart-define=BALANCE_CATALOG_API_URL=https://$CATALOG_DOMAIN`. Never use an
HTTP or localhost endpoint for a release build.

## Quality report

`GET /catalog/stats` returns the required totals and per-chain coverage. The
same report is available directly from the views:

```sql
SELECT * FROM catalog_quality_stats;
SELECT * FROM retailer_coverage ORDER BY slug;
```

These are coverage counts, not claims of complete retailer assortments. OFF
store tags are limited; official retailer ingestion is a separate licensed
feed. Never report fixtures or seed retailer rows as production products.
