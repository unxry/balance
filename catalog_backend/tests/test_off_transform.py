from app.normalization import catalog_taxonomy, normalize_gtin, normalize_text, search_document
from app.off_transform import parse_quantity, transform_off_row


def test_gtin_validation_preserves_leading_zero():
    assert normalize_gtin("3017620422003") == "3017620422003"
    assert normalize_gtin("03017620422003") == "03017620422003"
    assert normalize_gtin("3017620422004") is None


def test_russian_search_document_contains_transliteration():
    document = search_document("Творог Простоквашино")
    assert normalize_text("ТВОРОГ") in document
    assert "prostokvashino" in document


def test_quantity_parsing_uses_explicit_unit():
    assert parse_quantity("Молоко 1 л", "1000") == (1000, "ml")
    assert parse_quantity("Творог 180 г", "180") == (180, "g")
    assert parse_quantity("0 г", "0") == (None, None)
    assert parse_quantity("", "180") == (None, None)


def test_off_product_is_good_but_not_verified():
    product = transform_off_row({
        "code": "4607119490010",
        "product_name": "Творог 5%",
        "brands": "Пример",
        "countries_tags": "en:russia",
        "stores": "Пятёрочка, Магнит",
        "quantity": "180 г",
        "energy-kcal_100g": "121",
        "proteins_100g": "17",
        "fat_100g": "5",
        "carbohydrates_100g": "3",
        "last_modified_t": "1700000000",
    })
    assert product is not None
    assert product.quality == "good"
    assert product.net_weight == 180
    assert set(product.retailer_slugs) == {"magnit", "pyaterochka"}


def test_missing_nutrition_stays_null_and_partial():
    product = transform_off_row({
        "code": "4607119490010",
        "product_name": "Редкий продукт",
        "countries": "Россия",
    })
    assert product is not None
    assert product.energy_kcal is None
    assert product.quality == "partial"


def test_retailer_taxonomy_covers_russian_and_english_aliases():
    assert catalog_taxonomy("Слойка с яблоком", "Свежая выпечка") == "hotBakery"
    assert catalog_taxonomy("Butter croissant", "Pastry") == "hotBakery"
    assert catalog_taxonomy("Салат с курицей", "Кулинария") == "preparedFood"
    assert catalog_taxonomy("Chicken sandwich", "Ready meals") == "preparedFood"
    assert catalog_taxonomy("Молоко", "Молочные продукты") == "other"
