from __future__ import annotations

from .normalization import normalize_text


RULES = (
    ("hotBakery", ("горячая выпеч", "свежая выпеч", "выпеч", "пекар", "слойк", "булоч", "пирож", "круассан", "pastry", "bakery", "croissant", "buns", "pies")),
    ("preparedFood", ("готовая еда", "готовые блюда", "кулинар", "салат", "суп", "вторые блюда", "сэндвич", "сендвич", "ready meal", "prepared meal", "cooked food")),
    ("bread", ("хлеб", "bread")),
    ("dairy", ("молоч", "milk", "dairy", "творог", "йогурт", "кефир")),
    ("meat", ("мяс", "meat", "колбас", "свинин", "говядин")),
    ("fish", ("рыб", "fish", "seafood")),
    ("frozen", ("заморож", "замороз", "frozen")),
    ("drinks", ("напит", "beverage", "drink", "water", "вода", "сок")),
    ("sweets", ("слад", "шоколад", "конфет", "козинак", "халва", "арахисовая паста", "dessert", "chocolate")),
    ("snacks", ("снек", "чипс", "cracker", "snack")),
    ("sauces", ("соус", "sauce", "condiment")),
    ("grains", ("круп", "макарон", "pasta", "grain", "rice", "рис")),
    ("canned", ("консерв", "canned")),
    ("breakfast", ("завтрак", "breakfast", "cereal")),
)


def taxonomy(name: str, category: str | None) -> str:
    name_value = normalize_text(name)
    for canonical, aliases in RULES:
        if any(alias in name_value for alias in aliases):
            return canonical
    value = normalize_text(f"{name} {category or ''}")
    for canonical, aliases in RULES:
        if any(alias in value for alias in aliases):
            return canonical
    return "other"
