import os
import time
from datetime import timedelta

import psycopg

from .import_off_recent import DEFAULT_URL as RECENT_URL, import_recent_catalog
from .import_off_tsv import DEFAULT_URL as FULL_URL, import_catalog


def is_due(database_url: str, stream_key: str, interval: timedelta) -> bool:
    with psycopg.connect(database_url) as connection:
        row = connection.execute(
            """SELECT last_success_at < now() - %s::interval
               FROM sync_stream_state state JOIN sources s ON s.id=state.source_id
               WHERE s.slug='open-food-facts' AND state.stream_key=%s""",
            (str(interval), stream_key),
        ).fetchone()
    return row is None or bool(row[0])


def main() -> None:
    database_url = os.environ.get(
        "BALANCE_DATABASE_URL", "postgresql://localhost/balance_catalog"
    )
    full_url = os.environ.get("BALANCE_OFF_EXPORT_URL", FULL_URL)
    recent_url = os.environ.get("BALANCE_OFF_RECENT_URL", RECENT_URL)
    poll_seconds = max(300, int(os.environ.get("BALANCE_SYNC_POLL_SECONDS", "21600")))
    while True:
        try:
            if is_due(database_url, "full", timedelta(days=7)):
                print({"stream": "full", **import_catalog(database_url, full_url, None)}, flush=True)
            if is_due(database_url, "recent", timedelta(days=1)):
                print(
                    {"stream": "recent", **import_recent_catalog(database_url, recent_url, None)},
                    flush=True,
                )
        except Exception as error:
            print({"status": "failed", "error": str(error)[:2000]}, flush=True)
        time.sleep(poll_seconds)


if __name__ == "__main__":
    main()
