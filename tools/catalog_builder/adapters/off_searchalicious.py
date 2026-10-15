from __future__ import annotations

import json
import sqlite3
import gzip
from pathlib import Path
from typing import Any, Dict, Iterable, Optional

from .base import BaseAdapter
from ..models import ProductRecord, RetailerRelation, SourceReport, SourceStatus, SourceType
from ..normalization import normalize_gtin


class OffSearchaliciousAdapter(BaseAdapter):
    slug = "off_searchalicious"

    def __init__(self, snapshot: str = "assets/catalog/balance_ru_catalog.db", cache: str | None = None):
        self.snapshot = Path(snapshot)
        self.cache = Path(cache) if cache else None

    def probe(self) -> SourceReport:
        count = 0
        version = None
        if self.snapshot.exists():
            with sqlite3.connect(str(self.snapshot)) as db:
                count = db.execute("SELECT count(*) FROM bootstrap_products").fetchone()[0]
                row = db.execute("SELECT value FROM bootstrap_meta WHERE key='version'").fetchone()
                version = row[0] if row else None
        if not count and self.cache and self.cache.exists():
            with gzip.open(self.cache, "rt", encoding="utf-8") as stream:
                count = sum(1 for line in stream if line.strip())
            version = "2026-09-09-last-known-good"
        return SourceReport(self.slug, SourceStatus.OK if count else SourceStatus.FAILED, SourceType.OFF_SEARCHALICIOUS, version=version, records_fetched=count, repository="https://github.com/openfoodfacts/search-a-licious")

    def fetch_catalog(self) -> Iterable[ProductRecord]:
        if not self.snapshot.exists() and self.cache and self.cache.exists():
            from ..cache import read_cache
            yield from read_cache(self.cache)
            return
        with sqlite3.connect(str(self.snapshot)) as db:
            for payload, in db.execute("SELECT payload_json FROM bootstrap_products ORDER BY product_id"):
                raw = json.loads(payload)
                record = self.normalize(raw)
                if record:
                    yield record

    def normalize(self, raw: Dict[str, Any]) -> Optional[ProductRecord]:
        source_code = str(raw.get("barcode") or raw.get("sourceProductId") or "").strip()
        barcode = normalize_gtin(source_code)
        name = str(raw.get("name") or "").strip()
        if not source_code or not name:
            return None
        nutrition = raw.get("nutrition") or {}
        relations = [RetailerRelation("off:" + source_code, slug, "off_store_tag", 0.6) for slug in raw.get("retailerTags") or ()]
        return ProductRecord(
            barcode=source_code, canonical_gtin=barcode, name=name, brand=raw.get("brand"), category=raw.get("category"),
            package_amount=raw.get("packageAmount"), package_unit=raw.get("packageUnit"),
            kcal=nutrition.get("calories"), protein=nutrition.get("protein"), fat=nutrition.get("fat"), carbs=nutrition.get("carbs"),
            image_url=raw.get("imageUrl"), ingredients=raw.get("ingredients"), needs_review=bool(raw.get("needsReview")),
            source=SourceType.OFF_SEARCHALICIOUS, source_priority=400, source_revision=raw.get("sourceRevision"),
            last_seen=raw.get("lastFetchedAt") or raw.get("lastUpdatedAt"), retailer_relations=relations,
            field_sources={field: self.slug for field in ("name", "brand", "category", "package", "nutrition", "image")},
        )

    def source_metadata(self) -> Dict[str, Any]:
        return {"snapshot": str(self.snapshot), "exists": self.snapshot.exists(), "last_known_good_cache": str(self.cache) if self.cache else None, "cache_exists": bool(self.cache and self.cache.exists())}
