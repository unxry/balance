from __future__ import annotations

import csv
import gzip
import io
import time
import urllib.request
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, Iterator, Optional, TextIO

from .base import BaseAdapter
from ..models import ProductRecord, RetailerRelation, SourceReport, SourceStatus, SourceType
from ..normalization import normalize_gtin, normalize_text, number, package, russia_reasons
from ..quality import validate_nutrition


DEFAULT_URL = "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz"
USER_AGENT = "BalanceCatalogBuilder/2.0 (personal local catalog)"
RETAILERS = {
    "pyaterochka": ("пятерочка", "пятёрочка", "pyaterochka", "5ka"),
    "magnit": ("магнит", "magnit"),
    "perekrestok": ("перекресток", "перекрёсток", "perekrestok"),
    "vkusvill": ("вкусвилл", "vkusvill"),
    "fix_price": ("fix price", "fix-price", "фикс прайс"),
    "pobeda": ("магазин победа", "дискаунтер победа", "pobeda"),
}


@contextmanager
def open_source(source: str) -> Iterator[TextIO]:
    if source.startswith(("https://", "http://")):
        response = urllib.request.urlopen(urllib.request.Request(source, headers={"User-Agent": USER_AGENT}), timeout=120)
        stream = io.TextIOWrapper(gzip.GzipFile(fileobj=response), encoding="utf-8", newline="")
        try:
            yield stream
        finally:
            stream.close()
            response.close()
    else:
        path = Path(source)
        opener = gzip.open if path.suffix == ".gz" else open
        with opener(path, "rt", encoding="utf-8", newline="") as stream:
            yield stream


class OffBulkAdapter(BaseAdapter):
    slug = "off_bulk"

    def __init__(self, source: str = DEFAULT_URL):
        self.source = source
        self.counters: Dict[str, int] = {}

    def probe(self) -> SourceReport:
        started = time.monotonic()
        metadata = self.source_metadata()
        return SourceReport(
            source=self.slug,
            status=SourceStatus.OK,
            source_type=SourceType.OFF_BULK,
            version=metadata.get("etag") or metadata.get("last_modified"),
            repository="https://github.com/openfoodfacts/openfoodfacts-exports",
            duration_seconds=time.monotonic() - started,
            detail=metadata,
        )

    def source_metadata(self) -> Dict[str, Any]:
        if not self.source.startswith(("https://", "http://")):
            stat = Path(self.source).stat()
            return {"path": self.source, "bytes": stat.st_size, "modified_ns": stat.st_mtime_ns}
        request = urllib.request.Request(self.source, method="HEAD", headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(request, timeout=30) as response:
            return {
                "url": self.source,
                "bytes": int(response.headers.get("Content-Length", "0")),
                "etag": response.headers.get("ETag"),
                "last_modified": response.headers.get("Last-Modified"),
            }

    def fetch_catalog(self) -> Iterable[ProductRecord]:
        csv.field_size_limit(16 * 1024 * 1024)
        counts = {key: 0 for key in ("scanned", "valid_identity", "explicit_russia", "prefix_460_469", "russia_union", "usable", "missing_kcal", "invalid_gtin_or_name")}
        seen: set[str] = set()
        with open_source(self.source) as stream:
            for raw in csv.DictReader(stream, delimiter="\t"):
                counts["scanned"] += 1
                barcode = normalize_gtin(raw.get("code"))
                name = (raw.get("product_name") or "").strip()
                if not barcode or not name:
                    counts["invalid_gtin_or_name"] += 1
                    continue
                counts["valid_identity"] += 1
                explicit, prefix = russia_reasons(raw, barcode)
                counts["explicit_russia"] += int(explicit)
                counts["prefix_460_469"] += int(prefix)
                if not (explicit or prefix) or barcode in seen:
                    continue
                seen.add(barcode)
                counts["russia_union"] += 1
                product = self.normalize(raw)
                if product is None:
                    continue
                if product.usable:
                    counts["usable"] += 1
                else:
                    counts["missing_kcal"] += 1
                yield product
        self.counters = counts

    def normalize(self, raw: Dict[str, Any]) -> Optional[ProductRecord]:
        barcode = normalize_gtin(raw.get("code"))
        name = (raw.get("product_name") or "").strip()
        if not barcode or not name:
            return None
        amount, unit = package(raw.get("quantity"))
        stores = normalize_text(raw.get("stores"))
        relations = [
            RetailerRelation("off:" + barcode, slug, "off_store_tag", 0.6)
            for slug, aliases in RETAILERS.items()
            if any(normalize_text(alias) in stores for alias in aliases)
        ]
        categories = (raw.get("categories") or raw.get("main_category_en") or "").strip() or None
        record = ProductRecord(
            barcode=barcode,
            canonical_gtin=barcode,
            name=name,
            brand=((raw.get("brands") or "").split(",", 1)[0].strip() or None),
            category=categories,
            package_text=(raw.get("quantity") or "").strip() or None,
            package_amount=amount,
            package_unit=unit,
            kcal=number(raw.get("energy-kcal_100g"), 5000),
            protein=number(raw.get("proteins_100g"), 200),
            fat=number(raw.get("fat_100g"), 200),
            carbs=number(raw.get("carbohydrates_100g"), 200),
            image_url=(raw.get("image_url") or "").strip() or None,
            ingredients=(raw.get("ingredients_text") or "").strip() or None,
            needs_review=bool((raw.get("data_quality_errors_tags") or "").strip()),
            source=SourceType.OFF_BULK,
            source_priority=400,
            source_revision=(raw.get("last_modified_t") or "").strip() or None,
            last_seen=datetime.now(timezone.utc).isoformat(),
            retailer_relations=relations,
        )
        record.field_sources = {field: self.slug for field in ("name", "brand", "category", "package", "nutrition", "image") if getattr(record, "kcal" if field == "nutrition" else "package_text" if field == "package" else "image_url" if field == "image" else field) is not None}
        return validate_nutrition(record)
