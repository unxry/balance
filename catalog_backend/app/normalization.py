import re
import unicodedata

_CYR_TO_LAT = str.maketrans({
    "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e",
    "ё": "e", "ж": "zh", "з": "z", "и": "i", "й": "i", "к": "k",
    "л": "l", "м": "m", "н": "n", "о": "o", "п": "p", "р": "r",
    "с": "s", "т": "t", "у": "u", "ф": "f", "х": "h", "ц": "ts",
    "ч": "ch", "ш": "sh", "щ": "sch", "ы": "y", "э": "e", "ю": "yu",
    "я": "ya", "ь": "", "ъ": "",
})


def normalize_text(value: str | None) -> str:
    if not value:
        return ""
    value = unicodedata.normalize("NFKC", value).casefold().replace("ё", "е")
    return re.sub(r"\s+", " ", re.sub(r"[^0-9a-zа-я]+", " ", value)).strip()


def search_document(*values: str | None) -> str:
    normalized = normalize_text(" ".join(v for v in values if v))
    transliterated = normalized.translate(_CYR_TO_LAT)
    return f"{normalized} {transliterated}".strip()


def catalog_taxonomy(name: str | None, category: str | None) -> str:
    value = normalize_text(f"{name or ''} {category or ''}")
    hot_bakery = (
        "горячая выпечка", "свежая выпечка", "выпечка", "пекарня",
        "bakery", "fresh bakery", "hot bakery", "pastry", "croissant",
        "buns", "pies", "слойка", "булочка", "пирожок", "круассан",
        "пицца слайс",
    )
    if any(term in value for term in hot_bakery):
        return "hotBakery"
    prepared = (
        "готовая еда", "готовые блюда", "кулинария", "салат", "суп",
        "вторые блюда", "ready meal", "prepared meal", "prepared food",
        "prepared dish", "cooked food", "culinary", "sandwich",
        "prepared salad",
    )
    if any(term in value for term in prepared):
        return "preparedFood"
    return "other"


def normalize_gtin(value: str | None) -> str | None:
    if not value:
        return None
    digits = re.sub(r"\D", "", value)
    if len(digits) not in {8, 12, 13, 14}:
        return None
    total = 0
    for offset, digit in enumerate(reversed(digits[:-1])):
        total += int(digit) * (3 if offset % 2 == 0 else 1)
    check = (10 - total % 10) % 10
    return digits if check == int(digits[-1]) else None
