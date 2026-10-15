import os

DATABASE_URL = os.environ.get("BALANCE_DATABASE_URL", "postgresql://localhost/balance_catalog")
API_KEY = os.environ.get("BALANCE_CATALOG_API_KEY", "")

