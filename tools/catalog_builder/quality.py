from __future__ import annotations

from .models import ProductRecord


def validate_nutrition(product: ProductRecord) -> ProductRecord:
    limits = {"kcal": 5000, "protein": 200, "fat": 200, "carbs": 200}
    for field, maximum in limits.items():
        value = getattr(product, field)
        if value is not None and not 0 <= value <= maximum:
            setattr(product, field, None)
            product.needs_review = True
    if all(value is not None for value in (product.kcal, product.protein, product.fat, product.carbs)):
        estimated = product.protein * 4 + product.carbs * 4 + product.fat * 9
        if product.kcal > 0 and abs(estimated - product.kcal) > max(200, product.kcal * 0.8):
            product.needs_review = True
    return product
