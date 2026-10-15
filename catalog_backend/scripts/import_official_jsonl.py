import argparse
import json
import os
from decimal import Decimal, InvalidOperation
from pathlib import Path

import psycopg
from psycopg.types.json import Jsonb

from app.normalization import normalize_gtin, normalize_text, search_document

ALLOWED_SOURCE_TYPES = {"manufacturer", "official_retailer", "restaurant_menu"}
ALLOWED_BASES = {"per100g", "per100ml", "per_serving", "per_item"}
SOURCE_PRIORITIES = {
    "manufacturer": 1000,
    "restaurant_menu": 900,
    "official_retailer": 800,
}


def number(value, maximum: Decimal) -> Decimal | None:
    if value is None:
        return None
    try:
        result = Decimal(str(value).replace(",", "."))
    except InvalidOperation:
        return None
    return result if Decimal("0") <= result <= maximum else None


def import_feed(args) -> dict[str, int]:
    if args.source_type not in ALLOWED_SOURCE_TYPES:
        raise ValueError("source type must be official")
    if not args.license_url:
        raise ValueError("an explicit reuse/license URL is required")
    accepted = rejected = 0
    with psycopg.connect(args.database_url) as connection:
        source_id = connection.execute(
            """INSERT INTO sources(slug, type, name, url, license_name, license_url,
                 attribution, priority) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
               ON CONFLICT (slug) DO UPDATE SET type=EXCLUDED.type, name=EXCLUDED.name,
                 url=EXCLUDED.url, license_name=EXCLUDED.license_name,
                 license_url=EXCLUDED.license_url, attribution=EXCLUDED.attribution,
                 priority=EXCLUDED.priority
               RETURNING id""",
            (args.source_slug, args.source_type, args.source_name, args.source_url,
             args.license_name, args.license_url, args.attribution, args.priority),
        ).fetchone()[0]
        retailer_id = None
        if args.retailer:
            retailer_id = connection.execute(
                "SELECT id FROM retailers WHERE slug=%s", (args.retailer,)
            ).fetchone()
            if retailer_id is None:
                raise ValueError("unknown retailer slug")
            retailer_id = retailer_id[0]

        for line in Path(args.input).open(encoding="utf-8"):
            try:
                item = json.loads(line)
                name = str(item["name"]).strip()
                source_product_id = str(item["sourceProductId"]).strip()
            except (json.JSONDecodeError, KeyError, TypeError):
                rejected += 1
                continue
            barcode = normalize_gtin(item.get("barcode"))
            external_key = None if barcode else f"{args.source_slug}:{source_product_id}"
            if not name or (barcode is None and args.source_type != "restaurant_menu"):
                rejected += 1
                continue
            if args.retailer == "fix-price" and item.get("catalogType") not in {"food", "beverage"}:
                rejected += 1
                continue

            nutrition = item.get("nutrition") if isinstance(item.get("nutrition"), dict) else {}
            basis = nutrition.get("basis")
            if basis not in ALLOWED_BASES:
                basis = "per_item" if args.source_type == "restaurant_menu" else "per100g"
            kcal = number(nutrition.get("calories"), Decimal("2000"))
            protein = number(nutrition.get("protein"), Decimal("200"))
            fat = number(nutrition.get("fat"), Decimal("200"))
            carbs = number(nutrition.get("carbohydrates"), Decimal("200"))
            complete = all(value is not None for value in (kcal, protein, fat, carbs))
            verified = bool(item.get("verified")) and complete
            quality = "verified" if verified else ("good" if complete else "partial")
            brand = str(item.get("brand") or "").strip() or None
            normalized_brand = normalize_text(brand)
            brand_id = None
            if normalized_brand:
                brand_id = connection.execute(
                    """INSERT INTO brands(name, normalized_name) VALUES (%s,%s)
                       ON CONFLICT (normalized_name) DO UPDATE SET name=EXCLUDED.name RETURNING id""",
                    (brand, normalized_brand),
                ).fetchone()[0]

            product_id = None
            if barcode:
                product_id = connection.execute(
                """INSERT INTO products(
                     barcode, external_key, kind, name, normalized_name, search_text,
                     brand_id, net_weight, net_weight_unit, serving_size, serving_unit,
                     ingredients, data_quality, needs_review, source_priority, last_verified_at
                   ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,false,%s,%s)
                   ON CONFLICT (barcode) WHERE barcode IS NOT NULL DO UPDATE SET
                     name=EXCLUDED.name, normalized_name=EXCLUDED.normalized_name,
                     search_text=EXCLUDED.search_text, brand_id=EXCLUDED.brand_id,
                     net_weight=EXCLUDED.net_weight, net_weight_unit=EXCLUDED.net_weight_unit,
                     serving_size=EXCLUDED.serving_size, serving_unit=EXCLUDED.serving_unit,
                     ingredients=EXCLUDED.ingredients, data_quality=EXCLUDED.data_quality,
                     source_priority=EXCLUDED.source_priority,
                     last_verified_at=EXCLUDED.last_verified_at, updated_at=now()
                   WHERE products.source_priority <= EXCLUDED.source_priority
                   RETURNING id""",
                    (barcode, None, "restaurant" if args.source_type == "restaurant_menu" else "packaged",
                     name, normalize_text(name), search_document(name, brand, barcode), brand_id,
                     number(item.get("netWeight"), Decimal("100000")), item.get("netWeightUnit"),
                     number(item.get("servingSize"), Decimal("100000")), item.get("servingUnit"),
                     item.get("ingredients"), quality, args.priority,
                     item.get("verifiedAt") if verified else None),
                ).fetchone()
            if product_id is None and barcode:
                product_id = connection.execute("SELECT id FROM products WHERE barcode=%s", (barcode,)).fetchone()
            if product_id is None and external_key:
                product_id = connection.execute(
                    """INSERT INTO products(external_key, kind, name, normalized_name, search_text,
                         brand_id, serving_size, serving_unit, ingredients, data_quality,
                         source_priority, last_verified_at)
                       VALUES (%s,'restaurant',%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                       ON CONFLICT (external_key) WHERE external_key IS NOT NULL DO UPDATE SET
                         name=EXCLUDED.name, normalized_name=EXCLUDED.normalized_name,
                         search_text=EXCLUDED.search_text, serving_size=EXCLUDED.serving_size,
                         serving_unit=EXCLUDED.serving_unit, ingredients=EXCLUDED.ingredients,
                         data_quality=EXCLUDED.data_quality, source_priority=EXCLUDED.source_priority,
                         last_verified_at=EXCLUDED.last_verified_at, updated_at=now()
                       WHERE products.source_priority <= EXCLUDED.source_priority RETURNING id""",
                    (external_key, name, normalize_text(name), search_document(name, brand), brand_id,
                     number(item.get("servingSize"), Decimal("100000")), item.get("servingUnit"),
                     item.get("ingredients"), quality, args.priority,
                     item.get("verifiedAt") if verified else None),
                ).fetchone()
            if product_id is None:
                rejected += 1
                continue
            product_id = product_id[0]
            owns_primary_data = connection.execute(
                "SELECT source_priority <= %s FROM products WHERE id=%s",
                (args.priority, product_id),
            ).fetchone()[0]

            if owns_primary_data and any(value is not None for value in (kcal, protein, fat, carbs)):
                connection.execute(
                    """INSERT INTO product_nutrition(product_id,basis,basis_amount,energy_kcal,
                         protein,fat,carbohydrates,source_id,verified)
                       VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                       ON CONFLICT (product_id) DO UPDATE SET basis=EXCLUDED.basis,
                         basis_amount=EXCLUDED.basis_amount,energy_kcal=EXCLUDED.energy_kcal,
                         protein=EXCLUDED.protein,fat=EXCLUDED.fat,
                         carbohydrates=EXCLUDED.carbohydrates,source_id=EXCLUDED.source_id,
                         verified=EXCLUDED.verified,updated_at=now()""",
                    (product_id, basis, number(nutrition.get("basisAmount"), Decimal("100000")) or 100,
                     kcal, protein, fat, carbs, source_id, verified),
                )
            image = item.get("image")
            if isinstance(image, dict) and str(image.get("url") or "").startswith("https://"):
                if owns_primary_data:
                    connection.execute(
                        "UPDATE product_images SET is_primary=false WHERE product_id=%s AND is_primary",
                        (product_id,),
                    )
                connection.execute(
                    """INSERT INTO product_images(product_id,url,type,source_id,license_name,
                         license_url,attribution,is_primary) VALUES (%s,%s,'front',%s,%s,%s,%s,%s)
                       ON CONFLICT (product_id,url) DO UPDATE SET
                         source_id=EXCLUDED.source_id, license_name=EXCLUDED.license_name,
                         license_url=EXCLUDED.license_url, attribution=EXCLUDED.attribution,
                         is_primary=EXCLUDED.is_primary, updated_at=now()""",
                    (product_id, image["url"], source_id, image.get("license"),
                     image.get("licenseUrl") or args.license_url,
                     image.get("attribution") or args.attribution, owns_primary_data),
                )
            if owns_primary_data:
                connection.execute(
                    """UPDATE product_sources SET is_primary=false
                       WHERE product_id=%s AND source_id<>%s AND is_primary""",
                    (product_id, source_id),
                )
            connection.execute(
                """INSERT INTO product_sources(product_id,source_id,source_product_id,source_url,
                     source_revision,payload,is_primary) VALUES (%s,%s,%s,%s,%s,%s,%s)
                   ON CONFLICT (source_id,source_product_id) DO UPDATE SET
                     product_id=EXCLUDED.product_id,source_url=EXCLUDED.source_url,
                     source_revision=EXCLUDED.source_revision,payload=EXCLUDED.payload,
                     is_primary=EXCLUDED.is_primary,last_seen_at=now()""",
                (product_id, source_id, source_product_id, item.get("sourceUrl"),
                 str(item.get("revision") or ""), Jsonb(item), owns_primary_data),
            )
            if retailer_id:
                connection.execute(
                    """INSERT INTO product_retailers(product_id,retailer_id,source_id,confidence)
                       VALUES (%s,%s,%s,1) ON CONFLICT (product_id,retailer_id,source_id)
                       DO UPDATE SET confidence=1,last_seen_at=now()""",
                    (product_id, retailer_id, source_id),
                )
            connection.execute(
                """INSERT INTO product_versions(product_id,source_id,source_revision,changed_by,snapshot)
                   VALUES (%s,%s,%s,'official-feed',%s) ON CONFLICT DO NOTHING""",
                (product_id, source_id, str(item.get("revision") or ""), Jsonb(item)),
            )
            accepted += 1
        connection.execute("UPDATE sources SET last_sync_at=now() WHERE id=%s", (source_id,))
        connection.commit()
    return {"accepted": accepted, "rejected": rejected}


def main() -> None:
    parser = argparse.ArgumentParser(description="Import an explicitly licensed official JSONL feed")
    parser.add_argument("input")
    parser.add_argument("--database-url", default=os.environ.get("BALANCE_DATABASE_URL", "postgresql://localhost/balance_catalog"))
    parser.add_argument("--source-slug", required=True)
    parser.add_argument("--source-name", required=True)
    parser.add_argument("--source-type", choices=sorted(ALLOWED_SOURCE_TYPES), required=True)
    parser.add_argument("--source-url", required=True)
    parser.add_argument("--license-name", required=True)
    parser.add_argument("--license-url", required=True)
    parser.add_argument("--attribution", required=True)
    parser.add_argument("--retailer", choices=["magnit", "pyaterochka", "perekrestok", "vkusvill", "fix-price", "pobeda", "vkusno-i-tochka", "rostics"])
    args = parser.parse_args()
    args.priority = SOURCE_PRIORITIES[args.source_type]
    print(import_feed(args))


if __name__ == "__main__":
    main()
