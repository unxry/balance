#!/usr/bin/env python3
"""Build the bundled Russian usable-product snapshot from OFF Search-a-licious."""

from __future__ import annotations

# Kept as a compatibility command: all builds now go through the guarded,
# multi-source pipeline below. The legacy implementation remains unreachable
# so existing developer commands cannot silently recreate the smaller snapshot.
if __name__ == "__main__":
    import sys as _sys
    from pathlib import Path as _Path

    _sys.path.insert(0, str(_Path(__file__).resolve().parents[1]))
    from tools.catalog_builder.cli import main as _catalog_main

    raise SystemExit(_catalog_main(["build", *_sys.argv[1:]]))

import argparse
import json
import re
import sqlite3
import time
import urllib.error
import urllib.parse
import urllib.request
import zlib
from datetime import datetime, timezone
from pathlib import Path


API = "https://search.openfoodfacts.org/search"
VERSION = datetime.now(timezone.utc).date().isoformat()
FIELDS = ",".join(
    (
        "code",
        "product_name",
        "brands",
        "categories",
        "categories_tags",
        "stores",
        "stores_tags",
        "lang",
        "quantity",
        "product_quantity",
        "product_quantity_unit",
        "nutriments",
        "image_url",
        "unique_scans_n",
        "last_modified_t",
        "data_quality_errors_tags",
    )
)
BASE_QUERY = (
    'countries_tags:"en:russia" '
    "AND nutriments.energy-kcal_100g:[0 TO 5000]"
)
RETAILERS = {
    "pyaterochka": ("пятероч", "пятёроч", "5ka", "5-ка", "pyateroch"),
    "magnit": ("магнит", "magnit"),
    "perekrestok": ("перекрест", "перекрёст", "perekrest"),
    "vkusvill": ("вкусвилл", "vkusvill"),
    "fix_price": ("fix price", "fix-price", "фикс прайс", "fixprice"),
    "pobeda": ("победа", "pobeda"),
}


def request_page(prefix: str, page_size: int, page: int = 1) -> dict:
    params = urllib.parse.urlencode(
        {
            "q": f'{BASE_QUERY} AND code:{prefix}*',
            "langs": "ru,en",
            "sort_by": "code",
            "page_size": page_size,
            "page": page,
            "fields": FIELDS if page_size > 1 else "code",
        }
    )
    request = urllib.request.Request(
        f"{API}?{params}",
        headers={"User-Agent": "Balance/1.0 (local catalog bootstrap builder)"},
    )
    for attempt in range(6):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.load(response)
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError):
            if attempt == 5:
                raise
            time.sleep(2**attempt)
    raise RuntimeError("OFF request failed")


def leaf_prefixes(prefix: str = ""):
    for digit in "0123456789":
        candidate = prefix + digit
        count = int(request_page(candidate, 1).get("count") or 0)
        if count >= 10_000:
            yield from leaf_prefixes(candidate)
        elif count:
            yield candidate, count


def normalize(value: str) -> str:
    return " ".join(re.sub(r"[^a-zа-я0-9]+", " ", value.lower().replace("ё", "е")).split())


def taxonomy(product: dict) -> str:
    value = normalize(
        " ".join(
            (
                str(product.get("product_name") or ""),
                str(product.get("categories") or ""),
                " ".join(product.get("categories_tags") or ()),
            )
        )
    )
    rules = (
        ("hotBakery", ("горячая выпеч", "свежая выпеч", "выпеч", "пекар", "слойк", "булоч", "пирож", "круассан", "ватруш", "пицца слайс", "pastry", "bakery", "croissant", "buns", "pies")),
        ("preparedFood", ("готовая еда", "готовые блюда", "кулинар", "салат", "суп", "вторые блюда", "сэндвич", "сендвич", "готовые завтраки", "ready meal", "prepared meal", "cooked food", "prepared dish")),
        ("bread", ("хлеб", "bread")),
        ("dairy", ("молоч", "milk", "dairy", "творог", "йогурт", "кефир")),
        ("meat", ("мяс", "meat", "колбас", "свинин", "говядин")),
        ("fish", ("рыб", "fish", "seafood")),
        ("frozen", ("заморож", "замороз", "frozen")),
        ("drinks", ("напит", "beverage", "drink", "water", "вода", "сок")),
        ("sweets", ("слад", "шоколад", "конфет", "dessert", "chocolate")),
        ("snacks", ("снек", "чипс", "cracker", "snack")),
        ("sauces", ("соус", "sauce", "condiment")),
        ("grains", ("круп", "макарон", "pasta", "grain", "rice", "рис")),
        ("canned", ("консерв", "canned")),
        ("breakfast", ("завтрак", "breakfast", "cereal")),
    )
    for name, aliases in rules:
        if any(alias in value for alias in aliases):
            return name
    return "other"


def retailer_slugs(product: dict) -> list[str]:
    stores = product.get("stores") or []
    if isinstance(stores, str):
        stores = [stores]
    value = normalize(" ".join((*stores, *(product.get("stores_tags") or ()))))
    return [slug for slug, aliases in RETAILERS.items() if any(alias in value for alias in aliases)]


def product_payload(product: dict) -> dict | None:
    code = str(product.get("code") or "").strip()
    name = str(product.get("product_name") or "").strip()
    nutrition = product.get("nutriments") or {}
    kcal = nutrition.get("energy-kcal_100g")
    if not code.isdigit() or not name or not isinstance(kcal, (int, float)):
        return None
    brands = product.get("brands") or []
    brand = brands[0].strip() if isinstance(brands, list) and brands else None
    macros = {
        "calories": float(kcal),
        "protein": nutrition.get("proteins_100g"),
        "fat": nutrition.get("fat_100g"),
        "carbs": nutrition.get("carbohydrates_100g"),
    }
    complete = all(isinstance(macros[key], (int, float)) for key in ("protein", "fat", "carbs"))
    updated = product.get("last_modified_t")
    updated_at = (
        datetime.fromtimestamp(float(updated), timezone.utc)
        if isinstance(updated, (int, float))
        else datetime.now(timezone.utc)
    )
    retailers = retailer_slugs(product)
    category = taxonomy(product)
    return {
        "id": f"off:{code}",
        "barcode": code,
        "name": name,
        "normalizedName": normalize(name),
        "brand": brand,
        "retailerTags": retailers,
        "category": str(product.get("categories") or "").strip() or None,
        "subcategory": None,
        "packageAmount": product.get("product_quantity"),
        "packageUnit": product.get("product_quantity_unit"),
        "netWeightGrams": None,
        "netVolumeMl": None,
        "servingSize": None,
        "servingUnit": None,
        "nutritionBasis": "per100g",
        "nutritionBasisAmount": 100.0,
        "nutrition": macros,
        "ingredients": None,
        "imageUrl": product.get("image_url"),
        "localImagePath": None,
        "source": "openFoodFacts",
        "sourceProductId": code,
        "sourceUrl": f"https://world.openfoodfacts.org/product/{code}",
        "nutritionSource": "openFoodFacts",
        "nutritionVerified": False,
        "dataQuality": "good" if complete else "partial",
        "imageLicense": "CC BY-SA 3.0",
        "imageAttribution": "Open Food Facts contributors",
        "lastUpdatedAt": updated_at.isoformat(),
        "lastFetchedAt": None,
        "lastVerifiedAt": None,
        "sourceRevision": str(updated or VERSION),
        "needsReview": bool(product.get("data_quality_errors_tags")),
        "favorite": False,
        "localCategory": category,
        "colorSeed": zlib.crc32(code.encode()),
    }


def create_database(path: Path) -> sqlite3.Connection:
    if path.exists():
        path.unlink()
    connection = sqlite3.connect(path)
    connection.executescript(
        """
        PRAGMA journal_mode=DELETE;
        PRAGMA synchronous=OFF;
        CREATE TABLE bootstrap_meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);
        CREATE TABLE bootstrap_products(
          product_id TEXT PRIMARY KEY,
          barcode TEXT NOT NULL UNIQUE,
          payload_json TEXT NOT NULL
        );
        CREATE TABLE bootstrap_retailers(
          product_id TEXT NOT NULL,
          retailer_slug TEXT NOT NULL,
          source TEXT NOT NULL,
          confidence REAL NOT NULL,
          PRIMARY KEY(product_id, retailer_slug)
        );
        CREATE INDEX bootstrap_retailers_slug_idx
          ON bootstrap_retailers(retailer_slug, product_id);
        """
    )
    connection.execute("INSERT INTO bootstrap_meta VALUES ('version', ?)", (VERSION,))
    connection.execute("INSERT INTO bootstrap_meta VALUES ('source', 'Open Food Facts')")
    connection.execute("INSERT INTO bootstrap_meta VALUES ('country', 'en:russia')")
    return connection


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path("assets/catalog/balance_ru_catalog.db"))
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    connection = create_database(args.output)
    fetched = imported = 0
    started = time.perf_counter()
    for prefix, count in leaf_prefixes():
        pages = (count + 999) // 1000
        for page in range(1, pages + 1):
            response = request_page(prefix, 1000, page)
            for raw in response.get("hits") or ():
                fetched += 1
                payload = product_payload(raw)
                if payload is None:
                    continue
                product_id = payload["id"]
                connection.execute(
                    "INSERT OR REPLACE INTO bootstrap_products VALUES (?, ?, ?)",
                    (product_id, payload["barcode"], json.dumps(payload, ensure_ascii=False, separators=(",", ":"))),
                )
                for retailer in payload["retailerTags"]:
                    connection.execute(
                        "INSERT OR REPLACE INTO bootstrap_retailers VALUES (?, ?, 'off_store_tag', 0.6)",
                        (product_id, retailer),
                    )
                imported += 1
            connection.commit()
            print(f"prefix={prefix} page={page}/{pages} imported={imported}", flush=True)
            time.sleep(0.08)
    connection.execute("INSERT INTO bootstrap_meta VALUES ('fetched', ?)", (str(fetched),))
    connection.execute("INSERT INTO bootstrap_meta VALUES ('products', ?)", (str(imported),))
    connection.commit()
    connection.execute("VACUUM")
    connection.close()
    print(f"built={args.output} products={imported} seconds={time.perf_counter()-started:.2f}")


if __name__ == "__main__":
    main()
