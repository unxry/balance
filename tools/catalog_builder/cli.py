from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import os
import shutil
import sqlite3
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

from .adapters import KuperAdapter, OffBulkAdapter, OffSearchaliciousAdapter, OpenInflationAdapter
from .cache import read_cache, write_cache
from .config import ARTIFACT_DIR, ASSET_DB, ASSET_GZIP, BUILD_DB, CURRENT_USABLE_FLOOR, OFF_BULK_CACHE, OFF_SEARCH_CACHE
from .db_writer import atomic_build, integrity
from .merge import merge_sources
from .models import ProductRecord, SourceReport, SourceStatus, SourceType
from .reports import retailer_report, write_json, write_source_report


SOURCE_ALIASES = {
    "off": "off_bulk",
    "search": "off_searchalicious",
    "pyaterochka": "open_inflation_pyaterochka",
    "fix_price": "open_inflation_fix_price",
    "fixprice": "open_inflation_fix_price",
    "perekrestok": "open_inflation_perekrestok",
    "chizhik": "open_inflation_chizhik",
}


def adapters() -> list:
    return [
        OffBulkAdapter(),
        OffSearchaliciousAdapter(str(ASSET_DB), str(OFF_SEARCH_CACHE)),
        OpenInflationAdapter("pyaterochka"),
        OpenInflationAdapter("fix_price"),
        OpenInflationAdapter("perekrestok"),
        OpenInflationAdapter("chizhik"),
        KuperAdapter(),
    ]


def _enrich_from_last_sync(report: SourceReport) -> SourceReport:
    sync_files = {
        "off_bulk": (ARTIFACT_DIR / "off_sync.json", OFF_BULK_CACHE),
        "off_searchalicious": (ARTIFACT_DIR / "off_searchalicious_sync.json", OFF_SEARCH_CACHE),
    }
    paths = sync_files.get(report.source)
    if paths is None or not paths[0].exists():
        return report
    sync_report = json.loads(paths[0].read_text(encoding="utf-8"))
    coverage = sync_report.get("coverage") or {}
    report.records_fetched = int(coverage.get("scanned", sync_report.get("recordsCached", 0)))
    report.products_merged = int(sync_report.get("recordsCached", 0))
    report.duration_seconds = float(sync_report.get("durationSeconds", report.duration_seconds))
    report.last_successful_sync = sync_report.get("lastSuccessfulSync")
    if paths[1].exists():
        report.relations_added = sum(
            len(product.retailer_relations) for product in read_cache(paths[1])
        )
    report.detail["last_sync"] = sync_report
    return report


def probe(selected: str = "all") -> list[SourceReport]:
    selected = SOURCE_ALIASES.get(selected, selected)
    reports = []
    for adapter in adapters():
        if selected != "all" and adapter.slug != selected:
            continue
        try:
            reports.append(_enrich_from_last_sync(adapter.probe()))
        except Exception as error:
            reports.append(SourceReport(adapter.slug, SourceStatus.FAILED, SourceType.OFF_BULK if adapter.slug == "off_bulk" else SourceType.OPEN_INFLATION, detail={"error": str(error)}))
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    write_source_report(ARTIFACT_DIR / "source_report.json", reports)
    return reports


def sync(source: str, bulk_source: str | None = None) -> dict:
    started = time.monotonic()
    source = SOURCE_ALIASES.get(source, source)
    if source in {"off", "off_bulk"}:
        adapter = OffBulkAdapter(bulk_source or OffBulkAdapter().source)
        count = write_cache(OFF_BULK_CACHE, adapter.fetch_catalog())
        report = {"source": adapter.slug, "status": "OK", "recordsCached": count, "durationSeconds": round(time.monotonic() - started, 3), "coverage": adapter.counters, "metadata": adapter.source_metadata(), "lastSuccessfulSync": datetime.now(timezone.utc).isoformat()}
    elif source in {"off_searchalicious", "search"}:
        adapter = OffSearchaliciousAdapter(str(ASSET_DB), str(OFF_SEARCH_CACHE))
        count = write_cache(OFF_SEARCH_CACHE, adapter.fetch_catalog())
        report = {"source": adapter.slug, "status": "OK", "recordsCached": count, "durationSeconds": round(time.monotonic() - started, 3), "metadata": adapter.source_metadata(), "lastSuccessfulSync": datetime.now(timezone.utc).isoformat()}
    else:
        match = next((item for item in adapters() if item.slug == source), None)
        if match is None:
            raise SystemExit("unknown source: " + source)
        source_report = match.probe()
        report = source_report.to_dict()
        if source_report.status not in {SourceStatus.OK, SourceStatus.DEGRADED}:
            ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
            write_json(ARTIFACT_DIR / (source + "_probe.json"), report)
            return report
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    write_json(ARTIFACT_DIR / (source + "_sync.json"), report)
    return report


def _available_sources() -> list[Iterable[ProductRecord]]:
    sources = []
    if OFF_SEARCH_CACHE.exists():
        sources.append(read_cache(OFF_SEARCH_CACHE))
    else:
        sources.append(OffSearchaliciousAdapter(str(ASSET_DB), str(OFF_SEARCH_CACHE)).fetch_catalog())
    if OFF_BULK_CACHE.exists():
        sources.append(read_cache(OFF_BULK_CACHE))
    return sources


def build(allow_regression: bool = False, allow_degraded: bool = False) -> dict:
    if not OFF_SEARCH_CACHE.exists():
        raise RuntimeError("run sync off_searchalicious before build")
    source_report_path = ARTIFACT_DIR / "source_report.json"
    degraded_sources = []
    if source_report_path.exists():
        source_reports = json.loads(source_report_path.read_text(encoding="utf-8")).get("sources", [])
        degraded_sources = [
            item["source"] for item in source_reports
            if item["source"] in {"off_bulk", "off_searchalicious"}
            and item["status"] in {SourceStatus.DEGRADED.value, SourceStatus.FAILED.value}
        ]
    if degraded_sources and not allow_degraded:
        raise RuntimeError(
            "core source probe is degraded; pass --allow-degraded to use validated last-known-good caches: "
            + ", ".join(degraded_sources)
        )
    current = {item.merge_key: item for item in read_cache(OFF_SEARCH_CACHE)}
    products, merge_counts = merge_sources(_available_sources())
    bulk = {item.merge_key: item for item in read_cache(OFF_BULK_CACHE)} if OFF_BULK_CACHE.exists() else {}
    current_keys, new_keys = set(current), set(products)
    bulk_keys = set(bulk)
    overlap = current_keys & bulk_keys
    comparison = {
        "current": len(current), "new": len(products), "added": len(new_keys - current_keys),
        "matchedByBulk": len(overlap), "carriedForwardFromSearchSnapshot": len(current_keys - bulk_keys),
        "removed": len(current_keys - new_keys), "bulkUniqueAdditions": len(bulk_keys - current_keys),
        "bulkUniqueUsableAdditions": sum(bulk[key].usable for key in bulk_keys - current_keys),
    }
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    result = atomic_build(BUILD_DB, products.values(), datetime.now(timezone.utc).date().isoformat() + "-multi", CURRENT_USABLE_FLOOR, allow_regression)
    gzip_path = Path(str(BUILD_DB) + ".gz")
    ASSET_GZIP.parent.mkdir(parents=True, exist_ok=True)
    if gzip_path.exists():
        os.replace(gzip_path, ASSET_GZIP)
    result["manifest"]["databaseArtifact"] = str(BUILD_DB.relative_to(ASSET_DB.parents[2]))
    result["manifest"]["compressedArtifact"] = str(ASSET_GZIP.relative_to(ASSET_DB.parents[2]))
    off_sync_path = ARTIFACT_DIR / "off_sync.json"
    bulk_metadata = json.loads(off_sync_path.read_text(encoding="utf-8")).get("metadata", {}) if off_sync_path.exists() else {}
    result["manifest"]["sourceVersions"] = {
        "off_bulk": bulk_metadata.get("etag", "local-cache" if OFF_BULK_CACHE.exists() else "unavailable"),
        "off_bulk_last_modified": bulk_metadata.get("last_modified"),
        "off_searchalicious": "2026-09-09-last-known-good",
    }
    coverage = json.loads(off_sync_path.read_text(encoding="utf-8")).get("coverage", {}) if off_sync_path.exists() else {}
    result.update({
        "comparison": comparison,
        "coverage": coverage,
        "merge": merge_counts,
        "retailers": retailer_report(products.values()),
        "degradedSources": degraded_sources,
        "allowDegraded": allow_degraded,
    })
    write_json(ASSET_DB.parent / "catalog_manifest.json", result["manifest"])
    write_json(ASSET_DB.parent / "catalog_report.json", result)
    return result


def verify() -> dict:
    result = integrity(BUILD_DB, minimum_usable=CURRENT_USABLE_FLOOR)
    manifest_path = ASSET_DB.parent / "catalog_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}

    def digest(stream) -> str:
        value = hashlib.sha256()
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(chunk)
        return value.hexdigest()

    with BUILD_DB.open("rb") as stream:
        database_hash = digest(stream)
    gzip_hash = None
    if ASSET_GZIP.exists():
        with gzip.open(ASSET_GZIP, "rb") as stream:
            gzip_hash = digest(stream)
    expected_hash = manifest.get("sha256")
    result.update({
        "manifest_hash_matches": bool(expected_hash) and database_hash == expected_hash,
        "compressed_hash_matches": gzip_hash == database_hash,
        "compressed_size_matches": ASSET_GZIP.exists() and ASSET_GZIP.stat().st_size == manifest.get("compressedSize"),
    })
    result["valid"] = result["valid"] and all(
        result[key] for key in ("manifest_hash_matches", "compressed_hash_matches", "compressed_size_matches")
    )
    return result


def report() -> dict:
    path = ASSET_DB.parent / "catalog_report.json"
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {"integrity": integrity(BUILD_DB, minimum_usable=1)}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="catalog", description="Balance multi-source local catalog builder")
    sub = parser.add_subparsers(dest="command", required=True)
    probe_parser = sub.add_parser("probe")
    probe_parser.add_argument("source", nargs="?", default="all")
    sync_parser = sub.add_parser("sync")
    sync_parser.add_argument("source")
    sync_parser.add_argument("--bulk-source")
    build_parser = sub.add_parser("build")
    build_parser.add_argument("--allow-regression", action="store_true")
    build_parser.add_argument(
        "--allow-degraded",
        action="store_true",
        help="build from validated last-known-good caches when optional sources are unavailable",
    )
    sub.add_parser("verify")
    sub.add_parser("report")
    args = parser.parse_args(argv)
    if args.command == "probe":
        value = {"sources": [item.to_dict() for item in probe(args.source)]}
    elif args.command == "sync":
        value = sync(args.source, args.bulk_source)
    elif args.command == "build":
        value = build(args.allow_regression, args.allow_degraded)
    elif args.command == "verify":
        value = verify()
        if not value["valid"]:
            print(json.dumps(value, indent=2))
            return 1
    else:
        value = report()
    print(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
