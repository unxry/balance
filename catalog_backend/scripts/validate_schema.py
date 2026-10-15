import os

import psycopg


REQUIRED_RELATIONS = (
    "products",
    "product_nutrition",
    "product_images",
    "product_sources",
    "product_retailers",
    "sync_stream_state",
    "catalog_quality_stats",
    "retailer_coverage",
)


def validate_schema(database_url: str) -> list[str]:
    missing: list[str] = []
    with psycopg.connect(database_url) as connection:
        for relation in REQUIRED_RELATIONS:
            value = connection.execute(
                "SELECT to_regclass(%s)", (relation,)
            ).fetchone()[0]
            if value is None:
                missing.append(relation)
        taxonomy = connection.execute(
            "SELECT to_regprocedure('catalog_taxonomy(text,text)')"
        ).fetchone()[0]
        if taxonomy is None:
            missing.append("catalog_taxonomy(text,text)")
    return missing


def main() -> None:
    database_url = os.environ.get(
        "BALANCE_DATABASE_URL", "postgresql://localhost/balance_catalog"
    )
    missing = validate_schema(database_url)
    if missing:
        raise SystemExit(f"catalog schema incomplete: {', '.join(missing)}")
    print("catalog schema validated")


if __name__ == "__main__":
    main()
