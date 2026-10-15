from contextlib import contextmanager
from datetime import datetime, timezone
from uuid import UUID

from fastapi.testclient import TestClient

from app import main as catalog_api


class _Result:
    def __init__(self, *, one=None, many=()):
        self.one = one
        self.many = list(many)

    def fetchone(self):
        return self.one

    def fetchall(self):
        return self.many


class _Connection:
    def __init__(self, rows=(), one=None):
        self.rows = rows
        self.one = one
        self.calls = []

    def execute(self, query, parameters=None):
        self.calls.append((query, parameters))
        if query.strip() == "SELECT 1":
            return _Result(one={"value": 1})
        if "max(last_success_at)" in query:
            return _Result(one=self.one)
        return _Result(many=self.rows)


class _Pool:
    def __init__(self, connection):
        self.value = connection

    @contextmanager
    def connection(self):
        yield self.value


def test_health_checks_database(monkeypatch):
    connection = _Connection()
    monkeypatch.setattr(catalog_api, "pool", _Pool(connection))
    assert catalog_api.health() == {"status": "ok"}
    assert "SELECT 1" in connection.calls[0][0]


def test_retailer_browse_filters_taxonomy_and_usable_rows(monkeypatch):
    row = {
        "id": "product-1",
        "name": "Слойка с яблоком",
        "data_quality": "partial",
        "nutrition_basis": "per100g",
        "basis_amount": 100,
        "energy_kcal": 280,
        "retailer_tags": ["pyaterochka"],
    }
    connection = _Connection(rows=[row])
    monkeypatch.setattr(catalog_api, "pool", _Pool(connection))

    response = catalog_api.browse_products(
        retailer="pyaterochka",
        taxonomy="hotBakery",
        limit=50,
        offset=0,
        cursor=None,
    )

    assert response["items"] == [row]
    query, parameters = connection.calls[0]
    assert "catalog_taxonomy(p.name, c.name)" in query
    assert "n.basis_amount > 0" in query
    assert parameters["retailer"] == "pyaterochka"
    assert parameters["taxonomy"] == "hotBakery"


def test_retailer_browse_cursor_is_stable_and_prevents_page_duplicates(monkeypatch):
    timestamp = datetime(2026, 9, 9, tzinfo=timezone.utc)
    rows = [
        {
            "id": UUID(int=index),
            "name": f"Product {index}",
            "data_quality": "good",
            "needs_review": False,
            "updated_at": timestamp,
        }
        for index in (1, 2, 3)
    ]
    first_connection = _Connection(rows=rows)
    monkeypatch.setattr(catalog_api, "pool", _Pool(first_connection))
    first = catalog_api.browse_products(
        retailer="magnit", taxonomy="all", limit=2, offset=0, cursor=None
    )

    assert [item["id"] for item in first["items"]] == [str(rows[0]["id"]), str(rows[1]["id"])]
    assert first["nextCursor"]
    assert first_connection.calls[0][1]["limit"] == 3

    second_connection = _Connection(rows=[rows[2]])
    monkeypatch.setattr(catalog_api, "pool", _Pool(second_connection))
    second = catalog_api.browse_products(
        retailer="magnit",
        taxonomy="all",
        limit=2,
        offset=99,
        cursor=first["nextCursor"],
    )
    assert second["items"][0]["id"] == str(rows[2]["id"])
    assert second["items"][0]["id"] not in {item["id"] for item in first["items"]}
    query, parameters = second_connection.calls[0]
    assert "cursor_product_id" in parameters
    assert parameters["offset"] == 0
    assert "p.id > %(cursor_product_id)s" in query


def test_worker_health_reports_database_and_pending_sync(monkeypatch):
    connection = _Connection(one={"last_success_at": None, "configured_streams": 0})
    monkeypatch.setattr(catalog_api, "pool", _Pool(connection))
    assert catalog_api.worker_health() == {
        "status": "pending",
        "database": "reachable",
        "configuredStreams": 0,
        "lastSuccessAt": None,
    }


def test_http_smoke_health_and_retailer_browse(monkeypatch):
    connection = _Connection(
        rows=[
            {
                "id": "prepared-1",
                "name": "Салат с курицей",
                "data_quality": "good",
                "nutrition_basis": "per100g",
                "basis_amount": 100,
                "energy_kcal": 140,
                "retailer_tags": ["magnit"],
            }
        ]
    )
    monkeypatch.setattr(catalog_api, "pool", _Pool(connection))
    client = TestClient(catalog_api.app)

    assert client.get("/health").json() == {"status": "ok"}
    response = client.get(
        "/products/browse",
        params={"retailer": "magnit", "taxonomy": "preparedFood"},
    )
    assert response.status_code == 200
    assert response.json()["items"][0]["id"] == "prepared-1"

    invalid_cursor = client.get(
        "/products/browse",
        params={"retailer": "magnit", "cursor": "not-a-cursor"},
    )
    assert invalid_cursor.status_code == 400
