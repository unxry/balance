from __future__ import annotations

import gzip
import hashlib
import json
import os
import shutil
import sqlite3
import tempfile
import time
import zlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable

from . import SCHEMA_VERSION
from .models import ProductRecord
from .normalization import normalize_text
from .taxonomy import taxonomy


def flutter_payload(product: ProductRecord) -> Dict[str, Any]:
    now = product.last_seen or datetime.now(timezone.utc).isoformat()
    return {
        "id": product.product_id,
        "barcode": product.canonical_gtin,
        "name": product.name,
        "normalizedName": normalize_text(product.name),
        "brand": product.brand,
        "retailerTags": sorted({item.retailer_slug for item in product.retailer_relations}),
        "category": product.category,
        "subcategory": None,
        "packageAmount": product.package_amount,
        "packageUnit": product.package_unit,
        "netWeightGrams": product.package_amount if product.package_unit == "g" else None,
        "netVolumeMl": product.package_amount if product.package_unit == "ml" else None,
        "servingSize": None,
        "servingUnit": None,
        "nutritionBasis": "per100g",
        "nutritionBasisAmount": 100.0,
        "nutrition": {"calories": product.kcal, "protein": product.protein, "fat": product.fat, "carbs": product.carbs},
        "ingredients": product.ingredients,
        "imageUrl": product.image_url,
        "localImagePath": None,
        "source": "openFoodFacts",
        "sourceProductId": product.barcode,
        "sourceUrl": "https://world.openfoodfacts.org/product/" + product.barcode,
        "nutritionSource": "openFoodFacts",
        "nutritionVerified": False,
        "dataQuality": product.quality,
        "imageLicense": "CC BY-SA 3.0",
        "imageAttribution": "Open Food Facts contributors",
        "lastUpdatedAt": now,
        "lastFetchedAt": None,
        "lastVerifiedAt": None,
        "sourceRevision": product.source_revision,
        "needsReview": product.needs_review,
        "favorite": False,
        "localCategory": taxonomy(product.name, product.category),
        "colorSeed": zlib.crc32(product.barcode.encode()),
    }


def write_database(path: Path, products: Iterable[ProductRecord], version: str) -> Dict[str, int]:
    db = sqlite3.connect(str(path))
    db.executescript("""
      PRAGMA journal_mode=DELETE;
      PRAGMA synchronous=OFF;
      CREATE TABLE bootstrap_meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);
      CREATE TABLE bootstrap_products(product_id TEXT PRIMARY KEY, barcode TEXT UNIQUE, payload_json TEXT NOT NULL);
      CREATE TABLE bootstrap_retailers(
        product_id TEXT NOT NULL, retailer_slug TEXT NOT NULL, store_id TEXT,
        source TEXT NOT NULL, confidence REAL NOT NULL, availability INTEGER,
        price REAL, currency TEXT, observed_at TEXT,
        PRIMARY KEY(product_id, retailer_slug, source, store_id)
      );
      CREATE TABLE bootstrap_provenance(product_id TEXT NOT NULL, field_name TEXT NOT NULL, source TEXT NOT NULL, PRIMARY KEY(product_id, field_name));
      CREATE INDEX bootstrap_retailers_slug_idx ON bootstrap_retailers(retailer_slug, product_id);
    """)
    created = datetime.now(timezone.utc).isoformat()
    meta = {"version": version, "schema_version": str(SCHEMA_VERSION), "created_at": created, "source": "Balance multi-source builder"}
    db.executemany("INSERT INTO bootstrap_meta VALUES (?,?)", meta.items())
    counts = {"products": 0, "usable": 0, "barcode": 0, "image": 0, "good": 0, "partial": 0, "needsReview": 0, "relations": 0}
    for product in sorted(products, key=lambda item: item.barcode):
        payload = flutter_payload(product)
        db.execute("INSERT INTO bootstrap_products VALUES (?,?,?)", (product.product_id, product.canonical_gtin, json.dumps(payload, ensure_ascii=False, separators=(",", ":"))))
        counts["products"] += 1
        counts["usable"] += int(product.usable)
        counts["barcode"] += int(product.canonical_gtin is not None)
        counts["image"] += int(bool(product.image_url))
        counts[product.quality] += 1
        for relation in product.retailer_relations:
            db.execute("INSERT OR REPLACE INTO bootstrap_retailers VALUES (?,?,?,?,?,?,?,?,?)", (
                product.product_id, relation.retailer_slug, relation.store_id, relation.source,
                relation.confidence, None if relation.availability is None else int(relation.availability),
                relation.price, relation.currency, relation.observed_at,
            ))
            counts["relations"] += 1
        db.executemany("INSERT OR REPLACE INTO bootstrap_provenance VALUES (?,?,?)", ((product.product_id, field, source) for field, source in product.field_sources.items()))
    db.executemany("INSERT OR REPLACE INTO bootstrap_meta VALUES (?,?)", ((key, str(value)) for key, value in counts.items()))
    db.commit()
    db.execute("VACUUM")
    db.close()
    return counts


def integrity(path: Path, minimum_usable: int = 1) -> Dict[str, Any]:
    with sqlite3.connect(str(path)) as db:
        result = db.execute("PRAGMA integrity_check").fetchone()[0]
        products, barcode_count, unique_barcodes = db.execute("SELECT count(*), count(barcode), count(DISTINCT barcode) FROM bootstrap_products").fetchone()
        usable = db.execute("SELECT count(*) FROM bootstrap_products WHERE json_extract(payload_json,'$.nutrition.calories') IS NOT NULL").fetchone()[0]
        orphans = db.execute("SELECT count(*) FROM bootstrap_retailers r LEFT JOIN bootstrap_products p USING(product_id) WHERE p.product_id IS NULL").fetchone()[0]
        schema = int(db.execute("SELECT value FROM bootstrap_meta WHERE key='schema_version'").fetchone()[0])
    valid = result == "ok" and barcode_count == unique_barcodes and usable >= minimum_usable and not orphans and schema == SCHEMA_VERSION
    return {"valid": valid, "integrity_check": result, "schema_version": schema, "products": products, "usable": usable, "barcode_count": barcode_count, "unique_barcodes": unique_barcodes, "orphan_relations": orphans}


def atomic_build(output: Path, products: Iterable[ProductRecord], version: str, minimum_usable: int, allow_regression: bool = False) -> Dict[str, Any]:
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=str(output.parent), prefix="catalog-build-") as temporary:
        candidate = Path(temporary) / output.name
        started = time.monotonic()
        counts = write_database(candidate, products, version)
        check = integrity(candidate, minimum_usable=minimum_usable if not allow_regression else 1)
        if not check["valid"]:
            raise RuntimeError("catalog integrity or coverage guard failed: " + json.dumps(check))
        compressed = candidate.with_suffix(candidate.suffix + ".gz")
        with candidate.open("rb") as source, compressed.open("wb") as raw_target:
            with gzip.GzipFile(fileobj=raw_target, mode="wb", compresslevel=9, mtime=0) as target:
                shutil.copyfileobj(source, target)
        digest = hashlib.sha256(candidate.read_bytes()).hexdigest()
        manifest = {
            "version": version, "createdAt": datetime.now(timezone.utc).isoformat(), "schemaVersion": SCHEMA_VERSION,
            "productCount": counts["products"], "usableCount": counts["usable"], "barcodeCount": counts["barcode"],
            "retailerRelationCount": counts["relations"], "sha256": digest, "size": candidate.stat().st_size,
            "compressedSize": compressed.stat().st_size, "buildDurationSeconds": round(time.monotonic() - started, 3),
        }
        os.replace(candidate, output)
        os.replace(compressed, Path(str(output) + ".gz"))
    return {"counts": counts, "integrity": check, "manifest": manifest}
