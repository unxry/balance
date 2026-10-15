from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CACHE_DIR = ROOT / ".tools" / "cache" / "catalog_sources"
ASSET_DB = ROOT / "assets" / "catalog" / "balance_ru_catalog.db"
ARTIFACT_DIR = ROOT / ".tools" / "catalog_output"
BUILD_DB = ARTIFACT_DIR / "balance_ru_catalog.db"
ASSET_GZIP = ROOT / "assets" / "catalog" / "balance_ru_catalog.db.gz"
OFF_BULK_CACHE = CACHE_DIR / "off_bulk.jsonl.gz"
OFF_SEARCH_CACHE = CACHE_DIR / "off_searchalicious.jsonl.gz"
CURRENT_USABLE_FLOOR = 14941
