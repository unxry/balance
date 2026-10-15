from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, Iterable

from .models import ProductRecord, SourceReport


STORES = ("pyaterochka", "magnit", "perekrestok", "vkusvill", "fix_price", "pobeda")


def retailer_report(products: Iterable[ProductRecord]) -> Dict[str, Any]:
    result = {slug: {"total": 0, "usable": 0, "sources": {}} for slug in STORES}
    seen = set()
    for product in products:
        for relation in product.retailer_relations:
            if relation.retailer_slug not in result:
                continue
            key = (product.barcode, relation.retailer_slug)
            if key not in seen:
                result[relation.retailer_slug]["total"] += 1
                result[relation.retailer_slug]["usable"] += int(product.usable)
                seen.add(key)
            sources = result[relation.retailer_slug]["sources"]
            sources[relation.source] = sources.get(relation.source, 0) + 1
    return result


def write_json(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_source_report(path: Path, reports: Iterable[SourceReport]) -> None:
    write_json(path, {"sources": [report.to_dict() for report in reports]})
