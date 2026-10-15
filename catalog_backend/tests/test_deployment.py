import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_migrations_are_versioned_and_non_destructive():
    migrations = sorted((ROOT / "migrations").glob("*.sql"))
    assert migrations
    assert len({path.name for path in migrations}) == len(migrations)
    destructive = re.compile(r"\bDROP\s+(?:TABLE|SCHEMA|DATABASE)\b", re.IGNORECASE)
    for path in migrations:
        assert not destructive.search(path.read_text(encoding="utf-8")), path.name

    runner = (ROOT / "scripts" / "migrate.py").read_text(encoding="utf-8")
    assert "schema_migrations" in runner
    assert "if connection.execute" in runner


def test_production_stack_validates_schema_and_keeps_persistent_data():
    compose = (ROOT / "docker-compose.prod.yml").read_text(encoding="utf-8")
    assert "balance_catalog_data:/var/lib/postgresql/data" in compose
    assert "scripts.validate_schema" in compose
    assert "condition: service_completed_successfully" in compose
    assert "scripts.worker_health" in compose
    assert 'max-size: "10m"' in compose
