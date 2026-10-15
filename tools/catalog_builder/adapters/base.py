from __future__ import annotations

from typing import Any, Dict, Iterable, Optional

from ..models import ProductRecord, SourceReport


class BaseAdapter:
    slug = "base"

    def probe(self) -> SourceReport:
        raise NotImplementedError

    def list_stores(self) -> Iterable[Dict[str, Any]]:
        return ()

    def fetch_catalog(self) -> Iterable[ProductRecord]:
        return ()

    def fetch_product(self, product_id: str) -> Optional[ProductRecord]:
        return None

    def normalize(self, raw: Dict[str, Any]) -> Optional[ProductRecord]:
        raise NotImplementedError

    def source_metadata(self) -> Dict[str, Any]:
        return {}
