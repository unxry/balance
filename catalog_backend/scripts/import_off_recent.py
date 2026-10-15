import argparse
import json
import os
from typing import Iterator

from .import_off_tsv import import_rows, open_text_source, source_metadata

DEFAULT_URL = "https://openfoodfacts-ds.s3.eu-west-3.amazonaws.com/openfoodfacts_recent_changes.jsonl.gz"


def flattened_rows(lines) -> Iterator[dict[str, str]]:
    for line in lines:
        try:
            product = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(product, dict):
            continue
        nutriments = product.get("nutriments") or {}
        if not isinstance(nutriments, dict):
            nutriments = {}

        def text(value) -> str:
            if isinstance(value, list):
                return ",".join(str(item) for item in value)
            return str(value) if value is not None else ""

        yield {
            "code": text(product.get("code")),
            "url": text(product.get("url")),
            "product_name": text(product.get("product_name_ru") or product.get("product_name")),
            "quantity": text(product.get("quantity")),
            "product_quantity": text(product.get("product_quantity")),
            "brands": text(product.get("brands")),
            "categories": text(product.get("categories")),
            "main_category_en": text(product.get("main_category_en")),
            "countries": text(product.get("countries")),
            "countries_tags": text(product.get("countries_tags")),
            "purchase_places": text(product.get("purchase_places")),
            "manufacturing_places": text(product.get("manufacturing_places")),
            "stores": text(product.get("stores")),
            "ingredients_text": text(product.get("ingredients_text_ru") or product.get("ingredients_text")),
            "image_url": text(product.get("image_front_url") or product.get("image_url")),
            "energy-kcal_100g": text(nutriments.get("energy-kcal_100g")),
            "proteins_100g": text(nutriments.get("proteins_100g")),
            "fat_100g": text(nutriments.get("fat_100g")),
            "carbohydrates_100g": text(nutriments.get("carbohydrates_100g")),
            "fiber_100g": text(nutriments.get("fiber_100g")),
            "sugars_100g": text(nutriments.get("sugars_100g")),
            "salt_100g": text(nutriments.get("salt_100g")),
            "data_quality_errors_tags": text(product.get("data_quality_errors_tags")),
            "last_modified_t": text(product.get("last_modified_t")),
        }


def import_recent_catalog(database_url: str, source: str, limit: int | None):
    etag, last_modified = source_metadata(source)
    with open_text_source(source) as stream:
        return import_rows(
            database_url,
            flattened_rows(stream),
            limit,
            "incremental",
            stream_key="recent",
            source_etag=etag,
            source_last_modified=last_modified,
            record_source_state=not limit,
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Apply the OFF recent-changes export")
    parser.add_argument("--source", default=os.environ.get("BALANCE_OFF_RECENT_URL", DEFAULT_URL))
    parser.add_argument("--database-url", default=os.environ.get("BALANCE_DATABASE_URL", "postgresql://localhost/balance_catalog"))
    parser.add_argument("--limit", type=int, default=0)
    args = parser.parse_args()
    print(import_recent_catalog(args.database_url, args.source, args.limit))


if __name__ == "__main__":
    main()
