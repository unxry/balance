from __future__ import annotations

import re
import unicodedata
from typing import Optional, Tuple


def normalize_text(value: Optional[str]) -> str:
    if not value:
        return ""
    value = unicodedata.normalize("NFKC", value).casefold().replace("ё", "е")
    return re.sub(r"\s+", " ", re.sub(r"[^0-9a-zа-я]+", " ", value)).strip()


def normalize_gtin(value: Optional[str]) -> Optional[str]:
    digits = re.sub(r"\D", "", value or "")
    if len(digits) not in {8, 12, 13, 14}:
        return None
    total = sum(int(digit) * (3 if offset % 2 == 0 else 1) for offset, digit in enumerate(reversed(digits[:-1])))
    return digits if (10 - total % 10) % 10 == int(digits[-1]) else None


def number(value: object, maximum: float) -> Optional[float]:
    try:
        parsed = float(str(value).strip().replace(",", "."))
    except (TypeError, ValueError):
        return None
    return parsed if 0 <= parsed <= maximum else None


def package(value: Optional[str]) -> Tuple[Optional[float], Optional[str]]:
    text = (value or "").casefold().replace(",", ".")
    match = re.search(r"(?<!\d)(\d+(?:\.\d+)?)\s*(kg|кг|g|гр|г|ml|мл|cl|л|l)\b", text)
    if not match:
        return None, None
    amount, unit = float(match.group(1)), match.group(2)
    if unit in {"kg", "кг"}:
        return amount * 1000, "g"
    if unit in {"л", "l"}:
        return amount * 1000, "ml"
    if unit == "cl":
        return amount * 10, "ml"
    return amount, "ml" if unit in {"ml", "мл"} else "g"


RUSSIA_MARKERS = ("en:russia", "ru:россия", "россия", "russia", "russie", "russian federation", "российская федерация")


def russia_reasons(row: dict[str, str], barcode: str) -> tuple[bool, bool]:
    context = normalize_text(" ".join(row.get(key, "") for key in ("countries", "countries_tags", "purchase_places", "manufacturing_places", "stores")))
    explicit = any(normalize_text(marker) in context for marker in RUSSIA_MARKERS)
    prefix = len(barcode) == 13 and barcode[:3].isdigit() and 460 <= int(barcode[:3]) <= 469
    return explicit, prefix
