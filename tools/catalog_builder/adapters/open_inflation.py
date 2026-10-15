from __future__ import annotations

import sys
from typing import Any, Dict, Optional

from .base import BaseAdapter
from ..models import ProductRecord, SourceReport, SourceStatus, SourceType


PROJECTS = {
    "pyaterochka": {"package": "pyaterochka-api", "version": "0.2.2", "updated": "2026-03-08", "repository": "https://github.com/Open-Inflation/pyaterochka_api"},
    "fix_price": {"package": "fixprice-api", "version": "0.2.4.1", "updated": "2026-06-29", "repository": "https://github.com/Open-Inflation/fixprice_api"},
    "perekrestok": {"package": "perekrestok-api", "version": "0.2.2", "updated": "2026-03-08", "repository": "https://github.com/Open-Inflation/perekrestok_api"},
    "chizhik": {"package": "chizhik-api", "version": "0.2.5", "updated": "2026-05-18", "repository": "https://github.com/Open-Inflation/chizhik_api"},
}


class OpenInflationAdapter(BaseAdapter):
    """Safety-gated discovery adapter; it never calls private retailer endpoints."""

    def __init__(self, retailer: str):
        if retailer not in PROJECTS:
            raise ValueError("unsupported Open-Inflation retailer")
        self.retailer = retailer
        self.slug = "open_inflation_" + retailer

    def probe(self) -> SourceReport:
        project = PROJECTS[self.retailer]
        # Current documented clients require Camoufox, an anti-detect browser.
        # Balance deliberately refuses to install or execute that bypass layer.
        detail = {
            "package": project["package"],
            "requires_python": ">=3.10",
            "current_python": ".".join(map(str, sys.version_info[:3])),
            "requires_browser": True,
            "browser": "camoufox",
            "requires_login": False,
            "store_selection": self.retailer in {"pyaterochka", "fix_price"},
            "product_catalog": True,
            "barcode": "unknown_until_authorized_probe",
            "nutrition": "unknown_until_authorized_probe",
            "images": True,
            "prices": True,
            "availability": True,
            "client_license": "MIT",
            "data_use": "not established; personal snapshot must remain private",
            "reason": "Documented setup requires an anti-detect browser; no bypass is permitted.",
        }
        return SourceReport(
            source=self.slug,
            status=SourceStatus.ACCESS_BLOCKED,
            source_type=SourceType.OPEN_INFLATION,
            version=project["version"],
            repository=project["repository"],
            detail=detail,
        )

    def normalize(self, raw: Dict[str, Any]) -> Optional[ProductRecord]:
        return None

    def source_metadata(self) -> Dict[str, Any]:
        return dict(PROJECTS[self.retailer])
