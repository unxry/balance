import base64
import json
from contextlib import asynccontextmanager
from datetime import datetime
from uuid import UUID

from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import RedirectResponse

from .db import pool
from .normalization import normalize_gtin, normalize_text


@asynccontextmanager
async def lifespan(_: FastAPI):
    pool.open()
    pool.wait()
    yield
    pool.close()


app = FastAPI(title="Balance Product Catalog", version="1.0", lifespan=lifespan)

PRODUCT_SELECT = """
SELECT p.id, p.barcode, p.external_key, p.kind, p.name, p.normalized_name,
  b.name AS brand, c.name AS category, p.net_weight, p.net_weight_unit,
  p.serving_size, p.serving_unit, p.ingredients, p.data_quality,
  p.needs_review, p.updated_at, p.last_verified_at,
  n.basis AS nutrition_basis, n.basis_amount, n.energy_kcal,
  n.protein, n.fat, n.carbohydrates, n.fiber, n.sugar, n.salt,
  n.verified AS nutrition_verified,
  i.url AS image_url, i.license_name AS image_license,
  i.attribution AS image_attribution,
  s.slug AS source, s.type AS source_type, ps.source_url, ps.source_revision,
  ARRAY(SELECT r.slug FROM product_retailers pr
        JOIN retailers r ON r.id = pr.retailer_id
        WHERE pr.product_id = p.id ORDER BY r.slug) AS retailer_tags
FROM products p
LEFT JOIN brands b ON b.id = p.brand_id
LEFT JOIN categories c ON c.id = p.category_id
LEFT JOIN product_nutrition n ON n.product_id = p.id
LEFT JOIN product_images i ON i.product_id = p.id AND i.is_primary
LEFT JOIN product_sources ps ON ps.product_id = p.id AND ps.is_primary
LEFT JOIN sources s ON s.id = ps.source_id
"""


def _json_row(row):
    if row is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return {key: _json_value(value) for key, value in row.items()}


def _json_value(value):
    if isinstance(value, (UUID, datetime)):
        return str(value)
    return float(value) if value.__class__.__name__ == "Decimal" else value


def _fts_query(query: str) -> str:
    return " & ".join(f"{token}:*" for token in normalize_text(query).split()[:8])


def _encode_cursor(updated_at: datetime, product_id: UUID) -> str:
    raw = f"{updated_at.isoformat()}|{product_id}".encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def _decode_cursor(cursor: str) -> tuple[datetime, UUID]:
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        timestamp, product_id = base64.urlsafe_b64decode(padded).decode().split("|", 1)
        return datetime.fromisoformat(timestamp), UUID(product_id)
    except (ValueError, TypeError):
        raise HTTPException(status_code=400, detail="Invalid cursor") from None


def _quality_rank(value: str) -> int:
    return {"verified": 5, "good": 4, "partial": 3, "unverified": 2}.get(value, 1)


def _encode_browse_cursor(row) -> str:
    raw = json.dumps(
        [
            _quality_rank(row["data_quality"]),
            bool(row["needs_review"]),
            row["updated_at"].isoformat(),
            str(row["id"]),
        ],
        separators=(",", ":"),
    ).encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def _decode_browse_cursor(cursor: str) -> tuple[int, bool, datetime, UUID]:
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        quality, needs_review, updated_at, product_id = json.loads(
            base64.urlsafe_b64decode(padded).decode()
        )
        if (
            not isinstance(quality, int)
            or isinstance(quality, bool)
            or not isinstance(needs_review, bool)
        ):
            raise ValueError
        return quality, needs_review, datetime.fromisoformat(updated_at), UUID(product_id)
    except (ValueError, TypeError, json.JSONDecodeError):
        raise HTTPException(status_code=400, detail="Invalid browse cursor") from None


@app.get("/health")
def health():
    with pool.connection() as connection:
        connection.execute("SELECT 1")
    return {"status": "ok"}


@app.get("/health/worker")
def worker_health():
    with pool.connection() as connection:
        row = connection.execute(
            """SELECT max(last_success_at) AS last_success_at,
                      count(*) AS configured_streams
               FROM sync_stream_state"""
        ).fetchone()
    last_success = row["last_success_at"] if row else None
    return {
        "status": "ok" if last_success else "pending",
        "database": "reachable",
        "configuredStreams": int(row["configured_streams"]) if row else 0,
        "lastSuccessAt": _json_value(last_success) if last_success else None,
    }


@app.get("/products/search")
def search_products(q: str = Query(min_length=2, max_length=120), limit: int = Query(20, ge=1, le=50), offset: int = Query(0, ge=0, le=5000)):
    normalized = normalize_text(q)
    barcode = normalize_gtin(q)
    fts = _fts_query(q)
    with pool.connection() as connection:
        rows = connection.execute(
            PRODUCT_SELECT + """
            WHERE p.status = 'active' AND (
              p.barcode = %(barcode)s OR p.normalized_name = %(normalized)s
              OR to_tsvector('simple', p.search_text) @@ to_tsquery('simple', %(fts)s)
              OR p.search_text %% %(normalized)s
            )
            ORDER BY (p.barcode = %(barcode)s) DESC,
              (p.normalized_name = %(normalized)s) DESC,
              CASE p.data_quality WHEN 'verified' THEN 5 WHEN 'good' THEN 4
                WHEN 'partial' THEN 3 WHEN 'unverified' THEN 2 ELSE 1 END DESC,
              similarity(p.search_text, %(normalized)s) DESC, p.updated_at DESC
            LIMIT %(limit)s OFFSET %(offset)s
            """,
            {"barcode": barcode, "normalized": normalized, "fts": fts, "limit": limit, "offset": offset},
        ).fetchall()
    return {"items": [_json_row(row) for row in rows], "limit": limit, "offset": offset}


@app.get("/products/browse")
def browse_products(
    retailer: str = Query(pattern=r"^[a-z0-9-]{2,40}$"),
    taxonomy: str = Query(default="all", pattern=r"^(all|preparedFood|hotBakery)$"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0, le=5000),
    cursor: str | None = Query(default=None, max_length=512),
):
    quality_sql = """CASE p.data_quality WHEN 'verified' THEN 5
      WHEN 'good' THEN 4 WHEN 'partial' THEN 3
      WHEN 'unverified' THEN 2 ELSE 1 END"""
    taxonomy_sql = (
        "" if taxonomy == "all"
        else " AND catalog_taxonomy(p.name, c.name) = %(taxonomy)s"
    )
    parameters = {
        "retailer": retailer,
        "taxonomy": taxonomy,
        "limit": limit + 1,
        "offset": 0 if cursor else offset,
    }
    cursor_sql = ""
    if cursor:
        quality, needs_review, updated_at, product_id = _decode_browse_cursor(cursor)
        parameters.update(
            cursor_quality=quality,
            cursor_needs_review=needs_review,
            cursor_needs_review_int=int(needs_review),
            cursor_updated_at=updated_at,
            cursor_product_id=product_id,
        )
        cursor_sql = f"""
          AND (
            {quality_sql} < %(cursor_quality)s
            OR ({quality_sql} = %(cursor_quality)s
                AND p.needs_review::int > %(cursor_needs_review_int)s)
            OR ({quality_sql} = %(cursor_quality)s
                AND p.needs_review = %(cursor_needs_review)s
                AND p.updated_at < %(cursor_updated_at)s)
            OR ({quality_sql} = %(cursor_quality)s
                AND p.needs_review = %(cursor_needs_review)s
                AND p.updated_at = %(cursor_updated_at)s
                AND p.id > %(cursor_product_id)s)
          )
        """
        parameters["offset"] = 0
    with pool.connection() as connection:
        rows = connection.execute(
            PRODUCT_SELECT + f"""
            WHERE p.status = 'active'
              AND EXISTS (
                SELECT 1 FROM product_retailers matched_pr
                JOIN retailers matched_r ON matched_r.id = matched_pr.retailer_id
                WHERE matched_pr.product_id = p.id
                  AND matched_r.slug = %(retailer)s
              )
              AND n.basis_amount > 0 AND n.energy_kcal IS NOT NULL
              {taxonomy_sql}
              {cursor_sql}
            ORDER BY
              {quality_sql} DESC,
              p.needs_review ASC, p.updated_at DESC, p.id
            LIMIT %(limit)s OFFSET %(offset)s
            """,
            parameters,
        ).fetchall()
    page = rows[:limit]
    return {
        "items": [_json_row(row) for row in page],
        "retailer": retailer,
        "taxonomy": taxonomy,
        "limit": limit,
        "offset": 0 if cursor else offset,
        "nextCursor": _encode_browse_cursor(page[-1]) if len(rows) > limit else None,
    }


@app.get("/products/barcode/{barcode}")
def product_by_barcode(barcode: str):
    normalized = normalize_gtin(barcode)
    if normalized is None:
        raise HTTPException(status_code=422, detail="Invalid GTIN")
    with pool.connection() as connection:
        row = connection.execute(PRODUCT_SELECT + " WHERE p.barcode = %s", (normalized,)).fetchone()
    return _json_row(row)


@app.get("/products/updates")
def product_updates(cursor: str | None = None, updatedSince: datetime | None = None, limit: int = Query(100, ge=1, le=500)):
    if cursor:
        timestamp, product_id = _decode_cursor(cursor)
    else:
        timestamp = updatedSince or datetime.fromtimestamp(0).astimezone()
        product_id = UUID(int=0)
    with pool.connection() as connection:
        rows = connection.execute(
            PRODUCT_SELECT + """
            WHERE (p.updated_at, p.id) > (%s, %s)
            ORDER BY p.updated_at, p.id LIMIT %s
            """,
            (timestamp, product_id, limit),
        ).fetchall()
    next_cursor = _encode_cursor(rows[-1]["updated_at"], rows[-1]["id"]) if rows else None
    return {"items": [_json_row(row) for row in rows], "nextCursor": next_cursor}


@app.get("/products/{product_id}")
def product_by_id(product_id: UUID):
    with pool.connection() as connection:
        row = connection.execute(PRODUCT_SELECT + " WHERE p.id = %s", (product_id,)).fetchone()
    return _json_row(row)


@app.get("/products/{product_id}/image")
def product_image(product_id: UUID):
    with pool.connection() as connection:
        row = connection.execute(
            "SELECT url FROM product_images WHERE product_id=%s ORDER BY is_primary DESC, id LIMIT 1",
            (product_id,),
        ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Image not found")
    return RedirectResponse(row["url"], status_code=307)


@app.get("/catalog/stats")
def catalog_stats():
    with pool.connection() as connection:
        totals = connection.execute("SELECT * FROM catalog_quality_stats").fetchone()
        retailers = connection.execute("SELECT * FROM retailer_coverage ORDER BY slug").fetchall()
    return {
        "totals": {key: int(value) for key, value in totals.items()},
        "retailers": [{key: int(value) if isinstance(value, int) else value for key, value in row.items()} for row in retailers],
    }
