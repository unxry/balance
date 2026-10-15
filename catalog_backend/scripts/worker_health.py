import os

import psycopg


def main() -> None:
    database_url = os.environ.get(
        "BALANCE_DATABASE_URL", "postgresql://localhost/balance_catalog"
    )
    with psycopg.connect(database_url, connect_timeout=5) as connection:
        row = connection.execute(
            """SELECT to_regclass('sync_stream_state'),
                      max(last_success_at)
               FROM sync_stream_state"""
        ).fetchone()
    if row is None or row[0] is None:
        raise SystemExit("sync schema unavailable")
    print("worker database health ok")


if __name__ == "__main__":
    main()
