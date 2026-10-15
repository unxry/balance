import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from tools.catalog_builder.adapters.base import BaseAdapter
from tools.catalog_builder.adapters.kuper import KuperAdapter
from tools.catalog_builder.adapters.open_inflation import OpenInflationAdapter
from tools.catalog_builder.db_writer import atomic_build, integrity
from tools.catalog_builder.merge import merge_product, merge_sources
from tools.catalog_builder.models import ProductRecord, RetailerRelation, SourceStatus, SourceType


def product(barcode="4601234567893", **values):
    defaults = dict(barcode=barcode, canonical_gtin=barcode, name="Молоко", source=SourceType.OFF_BULK, source_priority=400, kcal=61)
    defaults.update(values)
    return ProductRecord(**defaults)


class BuilderTests(unittest.TestCase):
    def test_adapter_contract(self):
        for adapter in (OpenInflationAdapter("pyaterochka"), KuperAdapter()):
            for method in ("probe", "list_stores", "fetch_catalog", "fetch_product", "normalize", "source_metadata"):
                self.assertTrue(callable(getattr(adapter, method)))

    def test_field_level_priority_and_gtin_dedup(self):
        low = product(name="Молоко OFF", protein=3, image_url="off.jpg", field_sources={"name": "off", "protein": "off", "image": "off"})
        high = product(name="Молоко retailer", source=SourceType.OFFICIAL_RETAILER, source_priority=900, package_amount=930, package_unit="ml", field_sources={"name": "retailer", "package": "retailer"})
        merged = merge_product(low, high)
        self.assertEqual(merged.name, "Молоко retailer")
        self.assertEqual(merged.protein, 3)
        self.assertEqual(merged.image_url, "off.jpg")
        self.assertEqual(merged.package_amount, 930)
        products, _ = merge_sources(([low], [high]))
        self.assertEqual(len(products), 1)

    def test_retailer_relation_priority_and_stale_preservation(self):
        old = product(active=True, retailer_relations=[RetailerRelation("off:4601234567893", "pyaterochka", "off_store_tag", .6)])
        new = product(active=False, retailer_relations=[RetailerRelation("off:4601234567893", "pyaterochka", "official_retailer", 1)])
        merged = merge_product(old, new)
        self.assertTrue(merged.active)
        self.assertEqual(merged.retailer_relations[0].confidence, 1)

    def test_failed_and_auth_sources_do_not_emit_fake_products(self):
        self.assertEqual(OpenInflationAdapter("fix_price").probe().status, SourceStatus.ACCESS_BLOCKED)
        self.assertEqual(list(OpenInflationAdapter("fix_price").fetch_catalog()), [])
        self.assertEqual(KuperAdapter(enabled=True).probe().status, SourceStatus.AUTH_REQUIRED)

    def test_atomic_build_manifest_integrity_and_regression_guard(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "catalog.db"
            result = atomic_build(output, [product()], "test", minimum_usable=1)
            self.assertTrue(output.exists())
            self.assertEqual(result["manifest"]["productCount"], 1)
            self.assertTrue(integrity(output, 1)["valid"])
            previous = output.read_bytes()
            with self.assertRaises(RuntimeError):
                atomic_build(output, [product(kcal=None)], "bad", minimum_usable=1)
            self.assertEqual(output.read_bytes(), previous)


if __name__ == "__main__":
    unittest.main()
