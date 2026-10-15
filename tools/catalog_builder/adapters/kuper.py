from __future__ import annotations

from typing import Any, Dict, Optional

from .base import BaseAdapter
from ..models import ProductRecord, SourceReport, SourceStatus, SourceType


class KuperAdapter(BaseAdapter):
    slug = "kuper"

    def __init__(self, credentials: Optional[Dict[str, str]] = None, enabled: bool = False):
        self.credentials = credentials or {}
        self.enabled = enabled

    def probe(self) -> SourceReport:
        authorized = bool(self.credentials)
        return SourceReport(
            source=self.slug,
            status=SourceStatus.OK if self.enabled and authorized else SourceStatus.AUTH_REQUIRED if self.enabled else SourceStatus.DISABLED,
            source_type=SourceType.KUPER_AUTHORIZED,
            repository="https://docs.kuper.ru/",
            detail={
                "docs_reviewed": True,
                "partner_credentials_required": True,
                "authorized_access_present": authorized,
                "assortment": "partner/merchant integration only",
                "auth_bypass_attempted": False,
            },
        )

    def normalize(self, raw: Dict[str, Any]) -> Optional[ProductRecord]:
        if not self.enabled or not self.credentials:
            return None
        raise NotImplementedError("Implement only after authorized partner schema is supplied")

    def source_metadata(self) -> Dict[str, Any]:
        return {"official_docs": "https://docs.kuper.ru/", "enabled": self.enabled}
