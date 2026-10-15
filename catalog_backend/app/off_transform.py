import re
from dataclasses import dataclass
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation

from .normalization import normalize_gtin, normalize_text, search_document

RETAILER_ALIASES = {
    "magnit": ("магнит", "magnit"),
    "pyaterochka": ("пятерочка", "пятёрочка", "pyaterochka", "5ka"),
    "perekrestok": ("перекресток", "перекрёсток", "perekrestok"),
    "vkusvill": ("вкусвилл", "vkusvill"),
    "fix-price": ("fix price", "fix-price", "фикс прайс"),
    "pobeda": ("магазин победа", "дискаунтер победа", "pobeda"),
}

_RUSSIA_MARKERS = (
    "en:russia", "ru:россия", "россия", "russia", "russie",
    "russian federation", "российская федерация",
)


@dataclass(slots=True)
class CatalogRow:
    barcode: str
    name: str
    normalized_name: str
    search_text: str
    brand: str | None
    normalized_brand: str | None
    category: str | None
    normalized_category: str | None
    net_weight: Decimal | None
    net_weight_unit: str | None
    ingredients: str | None
    energy_kcal: Decimal | None
    protein: Decimal | None
    fat: Decimal | None
    carbohydrates: Decimal | None
    fiber: Decimal | None
    sugar: Decimal | None
    salt: Decimal | None
    image_url: str | None
    quality: str
    needs_review: bool
    source_url: str
    source_revision: str | None
    source_modified_at: datetime | None
    retailer_slugs: tuple[str, ...]


def is_russian_market(row: dict[str, str], barcode: str) -> bool:
    context = normalize_text(" ".join(
        row.get(key, "") for key in (
            "countries", "countries_tags", "purchase_places",
            "manufacturing_places", "stores",
        )
    ))
    if any(normalize_text(marker) in context for marker in _RUSSIA_MARKERS):
        return True
    return len(barcode) == 13 and barcode[:3].isdigit() and 460 <= int(barcode[:3]) <= 469


def transform_off_row(row: dict[str, str]) -> CatalogRow | None:
    barcode = normalize_gtin(row.get("code"))
    name = _clean(row.get("product_name"))
    if barcode is None or not name or not is_russian_market(row, barcode):
        return None

    brand = _first(row.get("brands"))
    category = _first(row.get("categories")) or _clean(row.get("main_category_en"))
    weight, weight_unit = parse_quantity(row.get("quantity"), row.get("product_quantity"))
    nutrients = {
        key: _decimal(row.get(column), maximum)
        for key, column, maximum in (
            ("energy", "energy-kcal_100g", Decimal("2000")),
            ("protein", "proteins_100g", Decimal("200")),
            ("fat", "fat_100g", Decimal("200")),
            ("carbs", "carbohydrates_100g", Decimal("200")),
            ("fiber", "fiber_100g", Decimal("200")),
            ("sugar", "sugars_100g", Decimal("200")),
            ("salt", "salt_100g", Decimal("200")),
        )
    }
    errors = bool(_clean(row.get("data_quality_errors_tags")))
    complete = all(nutrients[key] is not None for key in ("energy", "protein", "fat", "carbs"))
    if errors:
        quality = "needs_review"
    elif complete:
        quality = "good"
    else:
        quality = "partial"

    stores = normalize_text(row.get("stores"))
    retailers = tuple(
        slug for slug, aliases in RETAILER_ALIASES.items()
        if any(normalize_text(alias) in stores for alias in aliases)
    )
    modified = _timestamp(row.get("last_modified_t"))
    source_url = _clean(row.get("url")) or f"https://world.openfoodfacts.org/product/{barcode}"
    return CatalogRow(
        barcode=barcode,
        name=name,
        normalized_name=normalize_text(name),
        search_text=search_document(name, brand, category, barcode),
        brand=brand,
        normalized_brand=normalize_text(brand) or None,
        category=category,
        normalized_category=normalize_text(category) or None,
        net_weight=weight,
        net_weight_unit=weight_unit,
        ingredients=_clean(row.get("ingredients_text")),
        energy_kcal=nutrients["energy"],
        protein=nutrients["protein"],
        fat=nutrients["fat"],
        carbohydrates=nutrients["carbs"],
        fiber=nutrients["fiber"],
        sugar=nutrients["sugar"],
        salt=nutrients["salt"],
        image_url=_clean(row.get("image_url")),
        quality=quality,
        needs_review=errors,
        source_url=source_url,
        source_revision=_clean(row.get("last_modified_t")),
        source_modified_at=modified,
        retailer_slugs=retailers,
    )


def parse_quantity(quantity: str | None, product_quantity: str | None) -> tuple[Decimal | None, str | None]:
    text = (quantity or "").casefold().replace(",", ".")
    match = re.search(r"(?<!\d)(\d+(?:\.\d+)?)\s*(kg|кг|g|гр|г|ml|мл|cl|л|l)\b", text)
    if not match:
        # OFF's legacy product_quantity field has no reliable unit on its own.
        # Keeping it empty is safer than presenting an invented package basis.
        return None, None
    value = Decimal(match.group(1))
    if value <= 0:
        return None, None
    unit = match.group(2)
    if unit in {"kg", "кг"}:
        value, unit = value * 1000, "g"
    elif unit in {"л", "l"}:
        value, unit = value * 1000, "ml"
    elif unit == "cl":
        value, unit = value * 10, "ml"
    else:
        unit = "ml" if unit in {"ml", "мл"} else "g"
    return (value, unit) if value <= 100000 else (None, None)


def _decimal(value: str | None, maximum: Decimal) -> Decimal | None:
    try:
        number = Decimal(str(value).strip().replace(",", "."))
    except (InvalidOperation, AttributeError):
        return None
    return number if Decimal("0") <= number <= maximum else None


def _clean(value: str | None) -> str | None:
    if not value:
        return None
    cleaned = re.sub(r"\s+", " ", value).strip()
    return cleaned or None


def _first(value: str | None) -> str | None:
    cleaned = _clean(value)
    return _clean(cleaned.split(",", 1)[0]) if cleaned else None


def _timestamp(value: str | None) -> datetime | None:
    try:
        return datetime.fromtimestamp(int(value or ""), tz=timezone.utc)
    except (ValueError, TypeError, OSError):
        return None
