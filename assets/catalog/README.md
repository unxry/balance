# Balance Russian catalog snapshot

- Version: `2026-09-09-multi`
- Sources: official Open Food Facts daily bulk export plus the previous
  Search-a-licious last-known-good snapshot
- Total real records: `42,561`
- Diary-usable records with kcal: `17,955`
- Canonical checksum-valid GTINs: `32,744`
- Image URLs: `24,357`
- App format: gzip-compressed SQLite bootstrap (`bootstrap_meta`,
  `bootstrap_products`, `bootstrap_retailers`, `bootstrap_provenance`)
- Images: URLs only; image binaries are not bundled

Retailer membership is included only when the source record contains a matching
store tag. These counts are coverage of Open Food Facts, not claims of a complete
retailer assortment. User-confirmed store membership is stored separately in the
app database and survives later snapshot merges.

The previous `14,941` snapshot required an explicit Russia country tag and
kcal, but did not validate GTIN checksums. The older `32,691` report used the
bulk export and accepted an explicit Russia marker **or** a 460–469 GTIN prefix,
without requiring kcal. The current bulk measurement reproduced exactly 32,691;
29,181 lacked kcal and only 3,510 were directly usable in the Diary. The merged
snapshot carries forward all 14,941 records and adds 27,620 unique bulk records,
including 3,014 additional usable products. No previous record was removed.

Open Food Facts data is available under the Open Database License. Rebuild with:

```sh
./tools/update_catalog.sh
```

Sources:

- https://world.openfoodfacts.org/data
- https://github.com/openfoodfacts/openfoodfacts-exports
- https://github.com/openfoodfacts/search-a-licious
