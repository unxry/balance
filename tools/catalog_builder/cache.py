from __future__ import annotations

import gzip
import json
import os
import tempfile
from pathlib import Path
from typing import Iterable, Iterator

from .models import ProductRecord
from .normalization import normalize_gtin


def write_cache(path: Path, products: Iterable[ProductRecord]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    descriptor, temporary = tempfile.mkstemp(dir=str(path.parent), prefix=path.name, suffix=".tmp")
    os.close(descriptor)
    try:
        with gzip.open(temporary, "wt", encoding="utf-8", compresslevel=6) as stream:
            for product in products:
                stream.write(json.dumps(product.to_dict(), ensure_ascii=False, separators=(",", ":")) + "\n")
                count += 1
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    return count


def read_cache(path: Path) -> Iterator[ProductRecord]:
    with gzip.open(path, "rt", encoding="utf-8") as stream:
        for line in stream:
            if line.strip():
                product = ProductRecord.from_dict(json.loads(line))
                if product.canonical_gtin is None:
                    product.canonical_gtin = normalize_gtin(product.barcode)
                yield product
