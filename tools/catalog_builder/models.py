from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, Iterable, Optional, Protocol


class SourceType(str, Enum):
    OFF_BULK = "OFF_BULK"
    OFF_SEARCHALICIOUS = "OFF_SEARCHALICIOUS"
    OFF_REMOTE_LOOKUP = "OFF_REMOTE_LOOKUP"
    OPEN_INFLATION = "OPEN_INFLATION"
    OFFICIAL_RETAILER = "OFFICIAL_RETAILER"
    KUPER_AUTHORIZED = "KUPER_AUTHORIZED"
    USER_SCAN = "USER_SCAN"
    USER_MANUAL = "USER_MANUAL"


class SourceStatus(str, Enum):
    OK = "OK"
    DEGRADED = "DEGRADED"
    DISABLED = "DISABLED"
    AUTH_REQUIRED = "AUTH_REQUIRED"
    ACCESS_BLOCKED = "ACCESS_BLOCKED"
    FAILED = "FAILED"


@dataclass
class RetailerRelation:
    product_id: str
    retailer_slug: str
    source: str
    confidence: float
    store_id: Optional[str] = None
    availability: Optional[bool] = None
    price: Optional[float] = None
    currency: Optional[str] = None
    observed_at: Optional[str] = None


@dataclass
class ProductRecord:
    barcode: str
    name: str
    source: SourceType
    source_priority: int
    source_revision: Optional[str] = None
    last_seen: Optional[str] = None
    active: bool = True
    brand: Optional[str] = None
    category: Optional[str] = None
    package_text: Optional[str] = None
    package_amount: Optional[float] = None
    package_unit: Optional[str] = None
    kcal: Optional[float] = None
    protein: Optional[float] = None
    fat: Optional[float] = None
    carbs: Optional[float] = None
    image_url: Optional[str] = None
    ingredients: Optional[str] = None
    needs_review: bool = False
    retailer_relations: list[RetailerRelation] = field(default_factory=list)
    field_sources: Dict[str, str] = field(default_factory=dict)
    canonical_gtin: Optional[str] = None

    @property
    def product_id(self) -> str:
        return "off:" + self.barcode

    @property
    def merge_key(self) -> str:
        return "gtin:" + self.canonical_gtin if self.canonical_gtin else self.source.value + ":" + self.barcode

    @property
    def usable(self) -> bool:
        return self.kcal is not None and 0 <= self.kcal <= 5000

    @property
    def quality(self) -> str:
        if self.needs_review:
            return "needsReview"
        complete = all(value is not None for value in (self.kcal, self.protein, self.fat, self.carbs))
        return "good" if complete else "partial"

    def to_dict(self) -> Dict[str, Any]:
        data = dict(self.__dict__)
        data["source"] = self.source.value
        data["retailer_relations"] = [dict(item.__dict__) for item in self.retailer_relations]
        return data

    @classmethod
    def from_dict(cls, value: Dict[str, Any]) -> "ProductRecord":
        data = dict(value)
        data["source"] = SourceType(data["source"])
        data["retailer_relations"] = [RetailerRelation(**item) for item in data.get("retailer_relations", [])]
        return cls(**data)


@dataclass
class SourceReport:
    source: str
    status: SourceStatus
    source_type: SourceType
    version: Optional[str] = None
    repository: Optional[str] = None
    records_fetched: int = 0
    products_merged: int = 0
    relations_added: int = 0
    duration_seconds: float = 0
    last_successful_sync: Optional[str] = None
    detail: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        data = dict(self.__dict__)
        data["status"] = self.status.value
        data["source_type"] = self.source_type.value
        return data


class SourceAdapter(Protocol):
    slug: str

    def probe(self) -> SourceReport: ...
    def list_stores(self) -> Iterable[Dict[str, Any]]: ...
    def fetch_catalog(self) -> Iterable[ProductRecord]: ...
    def fetch_product(self, product_id: str) -> Optional[ProductRecord]: ...
    def normalize(self, raw: Dict[str, Any]) -> Optional[ProductRecord]: ...
    def source_metadata(self) -> Dict[str, Any]: ...
