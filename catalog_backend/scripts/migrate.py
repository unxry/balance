import os
from pathlib import Path

import psycopg


def main() -> None:
    database_url = os.environ.get("BALANCE_DATABASE_URL", "postgresql://localhost/balance_catalog")
    migrations = Path(__file__).resolve().parents[1] / "migrations"
    with psycopg.connect(database_url, autocommit=True) as connection:
        connection.execute(
            """CREATE TABLE IF NOT EXISTS schema_migrations (
                 name text PRIMARY KEY,
                 applied_at timestamptz NOT NULL DEFAULT now()
               )"""
        )
        for path in sorted(migrations.glob("*.sql")):
            if connection.execute(
                "SELECT 1 FROM schema_migrations WHERE name=%s", (path.name,)
            ).fetchone():
                continue
            with connection.transaction():
                connection.execute(path.read_text(encoding="utf-8"))
                connection.execute(
                    "INSERT INTO schema_migrations(name) VALUES (%s)", (path.name,)
                )
            print(f"applied {path.name}")


if __name__ == "__main__":
    main()
