import argparse
import csv
import gzip
import io
import os
import sys
import urllib.request
import urllib.error
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator, TextIO

import psycopg

from app.off_transform import CatalogRow, transform_off_row

DEFAULT_URL = "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz"
USER_AGENT = "BalanceCatalog/1.0 (com.arturovna01.balancetracker)"

STAGE_SQL = """
CREATE TEMP TABLE stage_off (
  barcode text PRIMARY KEY,
  name text NOT NULL,
  normalized_name text NOT NULL,
  search_text text NOT NULL,
  brand text,
  normalized_brand text,
  category text,
  normalized_category text,
  net_weight numeric,
  net_weight_unit text,
  ingredients text,
  energy_kcal numeric,
  protein numeric,
  fat numeric,
  carbohydrates numeric,
  fiber numeric,
  sugar numeric,
  salt numeric,
  image_url text,
  quality product_quality NOT NULL,
  needs_review boolean NOT NULL,
  source_url text NOT NULL,
  source_revision text,
  source_modified_at timestamptz,
  retailer_slugs text[] NOT NULL
) ON COMMIT DROP
"""

MERGE_SQL = """
INSERT INTO brands(name, normalized_name)
SELECT min(brand), normalized_brand FROM stage_off
WHERE normalized_brand IS NOT NULL GROUP BY normalized_brand
ON CONFLICT (normalized_name) DO NOTHING;

INSERT INTO categories(external_key, name, normalized_name)
SELECT 'off:' || normalized_category, min(category), normalized_category
FROM stage_off WHERE normalized_category IS NOT NULL GROUP BY normalized_category
ON CONFLICT (external_key) DO UPDATE SET name = EXCLUDED.name;

CREATE TEMP TABLE stage_changed ON COMMIT DROP AS
SELECT s.barcode
FROM stage_off s
LEFT JOIN products p ON p.barcode = s.barcode
LEFT JOIN brands b ON b.normalized_name = s.normalized_brand
LEFT JOIN categories c ON c.external_key = 'off:' || s.normalized_category
LEFT JOIN product_nutrition n ON n.product_id = p.id
LEFT JOIN product_images i ON i.product_id = p.id AND i.is_primary
WHERE p.id IS NULL OR (
  p.source_priority <= %(priority)s AND (
    (p.name, p.brand_id, p.category_id, p.net_weight, p.net_weight_unit,
     p.ingredients, p.data_quality, p.needs_review)
      IS DISTINCT FROM
    (s.name, b.id, c.id, s.net_weight, s.net_weight_unit,
     s.ingredients, s.quality, s.needs_review)
    OR ((s.energy_kcal IS NOT NULL OR s.protein IS NOT NULL OR s.fat IS NOT NULL
         OR s.carbohydrates IS NOT NULL OR s.fiber IS NOT NULL
         OR s.sugar IS NOT NULL OR s.salt IS NOT NULL)
        AND (n.basis, n.basis_amount, n.energy_kcal, n.protein, n.fat,
             n.carbohydrates, n.fiber, n.sugar, n.salt)
          IS DISTINCT FROM
           ('per100g'::nutrition_basis, 100::numeric, s.energy_kcal, s.protein,
            s.fat, s.carbohydrates, s.fiber, s.sugar, s.salt))
    OR (s.image_url IS NOT NULL AND i.url IS DISTINCT FROM s.image_url)
  )
);

INSERT INTO products(
  barcode, name, normalized_name, search_text, brand_id, category_id,
  net_weight, net_weight_unit, ingredients, data_quality, needs_review,
  source_priority, updated_at
)
SELECT s.barcode, s.name, s.normalized_name, s.search_text, b.id, c.id,
  s.net_weight, s.net_weight_unit, s.ingredients, s.quality, s.needs_review,
  %(priority)s, now()
FROM stage_off s JOIN stage_changed changed USING (barcode)
LEFT JOIN brands b ON b.normalized_name = s.normalized_brand
LEFT JOIN categories c ON c.external_key = 'off:' || s.normalized_category
ON CONFLICT (barcode) WHERE barcode IS NOT NULL DO UPDATE SET
  name = EXCLUDED.name,
  normalized_name = EXCLUDED.normalized_name,
  search_text = EXCLUDED.search_text,
  brand_id = EXCLUDED.brand_id,
  category_id = EXCLUDED.category_id,
  net_weight = EXCLUDED.net_weight,
  net_weight_unit = EXCLUDED.net_weight_unit,
  ingredients = EXCLUDED.ingredients,
  data_quality = EXCLUDED.data_quality,
  needs_review = EXCLUDED.needs_review,
  source_priority = EXCLUDED.source_priority,
  updated_at = now()
WHERE products.source_priority <= EXCLUDED.source_priority;

INSERT INTO product_nutrition(
  product_id, basis, basis_amount, energy_kcal, protein, fat, carbohydrates,
  fiber, sugar, salt, source_id, verified, updated_at
)
SELECT p.id, 'per100g', 100, s.energy_kcal, s.protein, s.fat, s.carbohydrates,
  s.fiber, s.sugar, s.salt, %(source_id)s, false,
  now()
FROM stage_off s JOIN products p ON p.barcode = s.barcode
WHERE s.energy_kcal IS NOT NULL OR s.protein IS NOT NULL OR s.fat IS NOT NULL
   OR s.carbohydrates IS NOT NULL
ON CONFLICT (product_id) DO UPDATE SET
  basis = EXCLUDED.basis,
  basis_amount = EXCLUDED.basis_amount,
  energy_kcal = EXCLUDED.energy_kcal,
  protein = EXCLUDED.protein,
  fat = EXCLUDED.fat,
  carbohydrates = EXCLUDED.carbohydrates,
  fiber = EXCLUDED.fiber,
  sugar = EXCLUDED.sugar,
  salt = EXCLUDED.salt,
  source_id = EXCLUDED.source_id,
  verified = false,
  updated_at = EXCLUDED.updated_at
WHERE (SELECT priority FROM sources WHERE id = product_nutrition.source_id) <= %(priority)s;

INSERT INTO product_images(
  product_id, url, type, source_id, license_name, license_url,
  attribution, is_primary, updated_at
)
SELECT p.id, s.image_url, 'front', %(source_id)s, 'CC BY-SA',
  'https://creativecommons.org/licenses/by-sa/4.0/',
  'Open Food Facts contributors',
  NOT EXISTS (SELECT 1 FROM product_images old WHERE old.product_id = p.id AND old.is_primary),
  now()
FROM stage_off s JOIN products p ON p.barcode = s.barcode
WHERE s.image_url IS NOT NULL
ON CONFLICT (product_id, url) DO UPDATE SET updated_at = EXCLUDED.updated_at;

UPDATE product_sources old
SET is_primary = false
FROM stage_off s JOIN products p ON p.barcode = s.barcode
WHERE old.product_id = p.id AND old.source_id <> %(source_id)s
  AND p.source_priority = %(priority)s AND old.is_primary;

INSERT INTO product_sources(
  product_id, source_id, source_product_id, source_url, source_revision,
  source_modified_at, is_primary, last_seen_at
)
SELECT p.id, %(source_id)s, s.barcode, s.source_url, s.source_revision,
  s.source_modified_at, p.source_priority = %(priority)s, now()
FROM stage_off s JOIN products p ON p.barcode = s.barcode
ON CONFLICT (source_id, source_product_id) DO UPDATE SET
  product_id = EXCLUDED.product_id,
  source_url = EXCLUDED.source_url,
  source_revision = EXCLUDED.source_revision,
  source_modified_at = EXCLUDED.source_modified_at,
  is_primary = EXCLUDED.is_primary,
  last_seen_at = now();

INSERT INTO product_retailers(product_id, retailer_id, source_id, confidence, last_seen_at)
SELECT p.id, r.id, %(source_id)s, 0.6, now()
FROM stage_off s
JOIN products p ON p.barcode = s.barcode
JOIN retailers r ON r.slug = ANY(s.retailer_slugs)
ON CONFLICT (product_id, retailer_id, source_id)
DO UPDATE SET confidence = EXCLUDED.confidence, last_seen_at = now();

INSERT INTO product_versions(product_id, source_id, source_revision, snapshot)
SELECT p.id, %(source_id)s, s.source_revision,
  jsonb_build_object(
    'barcode', s.barcode, 'name', s.name, 'brand', s.brand,
    'quality', s.quality, 'source', 'open-food-facts'
  )
FROM stage_off s JOIN products p ON p.barcode = s.barcode
WHERE s.source_revision IS NOT NULL
ON CONFLICT DO NOTHING;
"""


@contextmanager
def open_text_source(source: str) -> Iterator[TextIO]:
    if source.startswith(("https://", "http://")):
        request = urllib.request.Request(source, headers={"User-Agent": USER_AGENT})
        response = urllib.request.urlopen(request, timeout=90)
        gzip_stream = gzip.GzipFile(fileobj=response)
        text_stream = io.TextIOWrapper(gzip_stream, encoding="utf-8", newline="")
        try:
            yield text_stream
        finally:
            text_stream.close()
            response.close()
        return
    path = Path(source)
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt", encoding="utf-8", newline="") as stream:
        yield stream


def source_metadata(source: str) -> tuple[str | None, str | None]:
    if source.startswith(("https://", "http://")):
        try:
            request = urllib.request.Request(
                source, method="HEAD", headers={"User-Agent": USER_AGENT}
            )
            with urllib.request.urlopen(request, timeout=30) as response:
                return response.headers.get("ETag"), response.headers.get("Last-Modified")
        except (OSError, urllib.error.URLError):
            return None, None
    stat = Path(source).stat()
    return f'"{stat.st_size:x}-{stat.st_mtime_ns:x}"', str(stat.st_mtime_ns)


def copy_row(copy: psycopg.Copy, product: CatalogRow) -> None:
    copy.write_row((
        product.barcode, product.name, product.normalized_name, product.search_text,
        product.brand, product.normalized_brand, product.category,
        product.normalized_category, product.net_weight, product.net_weight_unit,
        product.ingredients, product.energy_kcal, product.protein, product.fat,
        product.carbohydrates, product.fiber, product.sugar, product.salt,
        product.image_url, product.quality, product.needs_review, product.source_url,
        product.source_revision, product.source_modified_at, list(product.retailer_slugs),
    ))


def import_rows(
    database_url: str,
    rows: Iterator[dict[str, str]],
    limit: int | None,
    mode: str,
    *,
    stream_key: str = "full",
    source_etag: str | None = None,
    source_last_modified: str | None = None,
    record_source_state: bool = False,
) -> dict[str, int]:
    csv.field_size_limit(16 * 1024 * 1024)
    scanned = accepted = rejected = 0
    seen: set[str] = set()
    with psycopg.connect(database_url) as connection:
        source_record = connection.execute(
            "SELECT id, priority FROM sources WHERE slug = 'open-food-facts'"
        ).fetchone()
        if source_record is None:
            raise RuntimeError("run migrations before importing")
        source_id, priority = source_record
        if record_source_state and source_etag:
            previous = connection.execute(
                """SELECT 1 FROM sync_stream_state
                   WHERE source_id=%s AND stream_key=%s AND etag=%s
                     AND last_success_at IS NOT NULL""",
                (source_id, stream_key, source_etag),
            ).fetchone()
            if previous:
                return {"scanned": 0, "accepted": 0, "rejected": 0, "skipped": 1}
        run_id = connection.execute(
            """INSERT INTO sync_runs(source_id, mode, status, source_etag, source_last_modified)
               VALUES (%s, %s, 'running', %s, %s) RETURNING id""",
            (source_id, mode, source_etag, source_last_modified),
        ).fetchone()[0]
        connection.commit()
        try:
            connection.execute(STAGE_SQL)
            with connection.cursor().copy("COPY stage_off FROM STDIN") as copy:
                for row in rows:
                    scanned += 1
                    product = transform_off_row(row)
                    if product is None or product.barcode in seen:
                        rejected += 1
                        continue
                    seen.add(product.barcode)
                    copy_row(copy, product)
                    accepted += 1
                    if accepted % 5000 == 0:
                        print(f"accepted={accepted} scanned={scanned}", flush=True)
                    if limit and accepted >= limit:
                        break
            parameters = {"source_id": source_id, "priority": priority}
            for statement in MERGE_SQL.split(";\n\n"):
                if statement.strip():
                    connection.execute(statement, parameters)
            connection.execute(
                "UPDATE sources SET last_sync_at = now() WHERE id = %s", (source_id,)
            )
            if record_source_state:
                connection.execute(
                    """INSERT INTO sync_stream_state(
                         source_id, stream_key, etag, last_modified, last_success_at)
                       VALUES (%s,%s,%s,%s,now())
                       ON CONFLICT (source_id,stream_key) DO UPDATE SET
                         etag=EXCLUDED.etag, last_modified=EXCLUDED.last_modified,
                         last_success_at=now(), updated_at=now()""",
                    (source_id, stream_key, source_etag, source_last_modified),
                )
            connection.execute(
                """UPDATE sync_runs SET status='succeeded', scanned_count=%s,
                   accepted_count=%s, rejected_count=%s, finished_at=now() WHERE id=%s""",
                (scanned, accepted, rejected, run_id),
            )
            connection.commit()
        except Exception as error:
            connection.rollback()
            connection.execute(
                """UPDATE sync_runs SET status='failed', error=%s,
                   scanned_count=%s, accepted_count=%s, rejected_count=%s,
                   finished_at=now() WHERE id=%s""",
                (str(error)[:2000], scanned, accepted, rejected, run_id),
            )
            connection.commit()
            raise
    return {"scanned": scanned, "accepted": accepted, "rejected": rejected}


def import_catalog(database_url: str, source: str, limit: int | None) -> dict[str, int]:
    csv.field_size_limit(16 * 1024 * 1024)
    etag, last_modified = source_metadata(source)
    with open_text_source(source) as stream:
        reader = csv.DictReader(stream, delimiter="\t")
        return import_rows(
            database_url,
            reader,
            limit,
            "full",
            stream_key="full",
            source_etag=etag,
            source_last_modified=last_modified,
            record_source_state=not limit,
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Import Russian-market products from the OFF bulk TSV export")
    parser.add_argument("--source", default=os.environ.get("BALANCE_OFF_EXPORT_URL", DEFAULT_URL))
    parser.add_argument("--database-url", default=os.environ.get("BALANCE_DATABASE_URL", "postgresql://localhost/balance_catalog"))
    parser.add_argument("--limit", type=int, default=int(os.environ.get("BALANCE_IMPORT_LIMIT", "100000")))
    args = parser.parse_args()
    print(import_catalog(args.database_url, args.source, args.limit))


if __name__ == "__main__":
    main()
