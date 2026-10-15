from __future__ import annotations

from dataclasses import replace
from typing import Dict, Iterable, Tuple

from .models import ProductRecord, RetailerRelation


FIELDS = ("name", "brand", "category", "package_text", "package_amount", "package_unit", "kcal", "protein", "fat", "carbs", "image_url", "ingredients")


def _richness(product: ProductRecord) -> int:
    return sum(getattr(product, field) not in (None, "") for field in FIELDS)


def merge_product(existing: ProductRecord, incoming: ProductRecord) -> ProductRecord:
    if existing.merge_key != incoming.merge_key:
        raise ValueError("GTIN mismatch")
    winner, other = (incoming, existing) if (incoming.source_priority, _richness(incoming), incoming.source_revision or "") > (existing.source_priority, _richness(existing), existing.source_revision or "") else (existing, incoming)
    merged = replace(winner, retailer_relations=list(winner.retailer_relations), field_sources=dict(winner.field_sources))
    for field in FIELDS:
        if getattr(merged, field) in (None, "") and getattr(other, field) not in (None, ""):
            setattr(merged, field, getattr(other, field))
            merged.field_sources[field] = other.field_sources.get(field, other.source.value)
    relations: Dict[Tuple[str, str, str], RetailerRelation] = {}
    for relation in (*existing.retailer_relations, *incoming.retailer_relations):
        key = (relation.product_id, relation.retailer_slug, relation.store_id or "")
        old = relations.get(key)
        if old is None or relation.confidence >= old.confidence:
            relations[key] = relation
    merged.retailer_relations = list(relations.values())
    merged.active = existing.active or incoming.active
    merged.last_seen = max(filter(None, (existing.last_seen, incoming.last_seen)), default=None)
    merged.needs_review = existing.needs_review or incoming.needs_review
    return merged


def merge_sources(sources: Iterable[Iterable[ProductRecord]]) -> tuple[Dict[str, ProductRecord], Dict[str, int]]:
    products: Dict[str, ProductRecord] = {}
    counts = {"seen": 0, "added": 0, "updated": 0, "unchanged": 0}
    for source in sources:
        for incoming in source:
            counts["seen"] += 1
            existing = products.get(incoming.merge_key)
            if existing is None:
                products[incoming.merge_key] = incoming
                counts["added"] += 1
            else:
                merged = merge_product(existing, incoming)
                counts["unchanged" if merged.to_dict() == existing.to_dict() else "updated"] += 1
                products[incoming.merge_key] = merged
    return products, counts
