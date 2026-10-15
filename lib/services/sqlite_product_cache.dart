import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/food_product.dart';
import '../models/product_retailer_relation.dart';
import 'food_catalog_repository.dart';

class SqliteProductCache implements ProductCache, RetailerAwareProductCache {
  static const schemaVersion = 4;
  static VoidCallback? onUserMutation;
  static const databaseName = 'balance_product_catalog.db';

  final Database database;

  static const _retailerUpsertSql = '''
    INSERT INTO product_retailers(
      product_id, retailer_slug, source, confidence, user_confirmed,
      first_seen_at, last_seen_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(product_id, retailer_slug) DO UPDATE SET
      source=CASE
        WHEN product_retailers.user_confirmed = 1 OR
             product_retailers.confidence > excluded.confidence
        THEN product_retailers.source ELSE excluded.source END,
      confidence=max(product_retailers.confidence, excluded.confidence),
      user_confirmed=max(product_retailers.user_confirmed, excluded.user_confirmed),
      first_seen_at=min(product_retailers.first_seen_at, excluded.first_seen_at),
      last_seen_at=max(product_retailers.last_seen_at, excluded.last_seen_at)
  ''';

  const SqliteProductCache._(this.database);

  static Future<Map<String, dynamic>> readUserBackup() async {
    final path = p.join(await getDatabasesPath(), databaseName);
    if (!await File(path).exists()) {
      return const {
        'catalogFavorites': <String>[],
        'catalogRetailerRelations': <Map<String, dynamic>>[],
        'catalogUserProducts': <Map<String, dynamic>>[],
      };
    }
    final database = await openDatabase(
      path,
      readOnly: true,
      singleInstance: false,
    );
    try {
      return await database.transaction((transaction) async {
        final favorites = await transaction.query(
          'products',
          columns: ['product_id'],
          where: 'favorite = 1',
          orderBy: 'product_id',
        );
        final relations = await transaction.query(
          'product_retailers',
          where:
              "source IN ('user_scan', 'user_manual', 'userScan', 'userManual') OR user_confirmed = 1",
          orderBy: 'product_id, retailer_slug',
        );
        final products = await transaction.query(
          'products',
          columns: ['payload_json'],
          where: "product_id LIKE 'manual:%'",
          orderBy: 'product_id',
        );
        return <String, dynamic>{
          'catalogFavorites': favorites
              .map((row) => row['product_id'])
              .toList(),
          'catalogRetailerRelations': relations
              .map((row) => _relationFromRow(row).toJson())
              .toList(),
          'catalogUserProducts': products
              .map((row) => jsonDecode(row['payload_json'] as String))
              .toList(),
        };
      });
    } finally {
      await database.close();
    }
  }

  static Future<SqliteProductCache> open({
    DatabaseFactory? factory,
    String? databasePath,
  }) async {
    final selectedFactory = factory ?? databaseFactory;
    final path =
        databasePath ??
        p.join(await selectedFactory.getDatabasesPath(), databaseName);
    final database = await selectedFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode=WAL');
          await db.execute('PRAGMA foreign_keys=ON');
        },
        onCreate: (db, version) async => _createSchema(db),
        onUpgrade: _migrate,
      ),
    );
    final cache = SqliteProductCache._(database);
    await cache._backfillLegacyRetailers();
    return cache;
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE products (
        cache_key TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        barcode TEXT,
        normalized_name TEXT NOT NULL,
        brand TEXT,
        search_text TEXT NOT NULL,
        local_category TEXT NOT NULL DEFAULT 'all',
        favorite INTEGER NOT NULL DEFAULT 0,
        use_count INTEGER NOT NULL DEFAULT 0,
        last_used_at INTEGER,
        updated_at INTEGER NOT NULL,
        payload_json TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX products_barcode_unique ON products(barcode) '
      'WHERE barcode IS NOT NULL',
    );
    await db.execute(
      'CREATE INDEX products_normalized_name_idx ON products(normalized_name)',
    );
    await db.execute('CREATE INDEX products_brand_idx ON products(brand)');
    await db.execute(
      'CREATE INDEX products_updated_at_idx ON products(updated_at)',
    );
    await db.execute(
      'CREATE INDEX products_product_id_idx ON products(product_id)',
    );
    await db.execute(
      'CREATE INDEX products_recent_idx ON products(last_used_at DESC)',
    );
    await db.execute('''
      CREATE VIRTUAL TABLE product_search USING fts5(
        cache_key UNINDEXED,
        normalized_name,
        brand,
        search_text,
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');
    await _createSyncSchema(db);
    await _createRetailerSchema(db);
  }

  static Future<void> _migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _createSyncSchema(db);
    if (oldVersion < 3) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS products_product_id_idx '
        'ON products(product_id)',
      );
    }
    if (oldVersion < 4) await _createRetailerSchema(db);
  }

  static Future<void> _createSyncSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS catalog_sync_state (
        source_key TEXT PRIMARY KEY,
        cursor TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createRetailerSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_retailers (
        product_id TEXT NOT NULL,
        retailer_slug TEXT NOT NULL,
        source TEXT NOT NULL,
        confidence REAL NOT NULL,
        user_confirmed INTEGER NOT NULL DEFAULT 0,
        first_seen_at INTEGER NOT NULL,
        last_seen_at INTEGER NOT NULL,
        PRIMARY KEY(product_id, retailer_slug)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS product_retailers_slug_idx '
      'ON product_retailers(retailer_slug, product_id)',
    );
  }

  Future<String?> readSyncCursor(String sourceKey) async {
    final rows = await database.query(
      'catalog_sync_state',
      columns: ['cursor'],
      where: 'source_key = ?',
      whereArgs: [sourceKey],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['cursor'] as String?;
  }

  Future<void> writeSyncCursor(String sourceKey, String cursor) async {
    await database.insert('catalog_sync_state', {
      'source_key': sourceKey,
      'cursor': cursor,
      'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<FoodProduct>> searchCandidates(
    String normalizedQuery, {
    required int limit,
    required int offset,
    required String category,
    bool browseAll = false,
    String? brand,
    bool onlyCompleteNutrition = false,
    bool onlyPhoto = false,
  }) async {
    final safeLimit = limit.clamp(1, 50000);
    final safeOffset = offset < 0 ? 0 : offset;
    final categorySql = category == 'all'
        ? ''
        : category == 'favorite'
        ? ' AND p.favorite = 1'
        : ' AND p.local_category = ?';
    final categoryArgs = category == 'all' || category == 'favorite'
        ? <Object?>[]
        : <Object?>[category];
    const usableClause =
        r" AND json_extract(p.payload_json, '$.nutrition.calories') IS NOT NULL";
    final brandSql = brand == null ? '' : ' AND p.brand = ?';
    final brandArgs = brand == null
        ? <Object?>[]
        : <Object?>[normalizeFoodText(brand)];
    final completeSql = onlyCompleteNutrition
        ? r" AND json_extract(p.payload_json, '$.nutrition.protein') IS NOT NULL"
              r" AND json_extract(p.payload_json, '$.nutrition.fat') IS NOT NULL"
              r" AND json_extract(p.payload_json, '$.nutrition.carbs') IS NOT NULL"
        : '';
    final photoSql = onlyPhoto
        ? r" AND (coalesce(json_extract(p.payload_json, '$.imageUrl'), '') <> ''"
              r" OR coalesce(json_extract(p.payload_json, '$.localImagePath'), '') <> '')"
        : '';
    List<Map<String, Object?>> rows;
    if (normalizedQuery.isEmpty) {
      final browseClause = browseAll
          ? '1 = 1'
          : '(p.favorite = 1 OR p.use_count > 0)';
      rows = await database.rawQuery(
        'SELECT p.payload_json FROM products p '
        'WHERE $browseClause$categorySql$usableClause$brandSql$completeSql$photoSql '
        'ORDER BY p.favorite DESC, p.last_used_at DESC '
        'LIMIT ? OFFSET ?',
        [...categoryArgs, ...brandArgs, safeLimit, safeOffset],
      );
    } else {
      final match = _ftsQuery(normalizedQuery);
      rows = await database.rawQuery(
        'SELECT p.payload_json FROM product_search f '
        'JOIN products p ON p.cache_key = f.cache_key '
        'WHERE product_search MATCH ?$categorySql$usableClause$brandSql$completeSql$photoSql '
        'ORDER BY bm25(product_search), p.use_count DESC '
        'LIMIT ? OFFSET ?',
        [match, ...categoryArgs, ...brandArgs, safeLimit, safeOffset],
      );
    }
    return _withRetailerRelations(
      rows.map(_productFromRow).whereType<FoodProduct>().toList(),
    );
  }

  @override
  Future<List<FoodProduct>> searchRetailerCandidates(
    String normalizedQuery, {
    required String retailerSlug,
    required String taxonomyCategory,
    required int limit,
    required int offset,
    String? brand,
    bool onlyCompleteNutrition = false,
    bool onlyPhoto = false,
  }) async {
    final safeLimit = limit.clamp(1, 50000);
    final safeOffset = offset < 0 ? 0 : offset;
    final taxonomySql = taxonomyCategory == 'all'
        ? ''
        : ' AND p.local_category = ?';
    final taxonomyArgs = taxonomyCategory == 'all'
        ? <Object?>[]
        : <Object?>[taxonomyCategory];
    const usableClause =
        r" AND json_extract(p.payload_json, '$.nutrition.calories') IS NOT NULL";
    final brandSql = brand == null ? '' : ' AND p.brand = ?';
    final brandArgs = brand == null
        ? <Object?>[]
        : <Object?>[normalizeFoodText(brand)];
    final completeSql = onlyCompleteNutrition
        ? r" AND json_extract(p.payload_json, '$.nutrition.protein') IS NOT NULL"
              r" AND json_extract(p.payload_json, '$.nutrition.fat') IS NOT NULL"
              r" AND json_extract(p.payload_json, '$.nutrition.carbs') IS NOT NULL"
        : '';
    final photoSql = onlyPhoto
        ? r" AND (coalesce(json_extract(p.payload_json, '$.imageUrl'), '') <> ''"
              r" OR coalesce(json_extract(p.payload_json, '$.localImagePath'), '') <> '')"
        : '';
    final List<Map<String, Object?>> rows;
    if (normalizedQuery.isEmpty) {
      rows = await database.rawQuery(
        'SELECT p.payload_json FROM products p '
        'JOIN product_retailers pr ON pr.product_id = p.product_id '
        'WHERE pr.retailer_slug = ?$taxonomySql$usableClause$brandSql$completeSql$photoSql '
        'ORDER BY pr.user_confirmed DESC, pr.confidence DESC, '
        'p.favorite DESC, p.last_used_at DESC, p.normalized_name ASC '
        'LIMIT ? OFFSET ?',
        [retailerSlug, ...taxonomyArgs, ...brandArgs, safeLimit, safeOffset],
      );
    } else {
      rows = await database.rawQuery(
        'SELECT p.payload_json FROM product_search f '
        'JOIN products p ON p.cache_key = f.cache_key '
        'JOIN product_retailers pr ON pr.product_id = p.product_id '
        'WHERE product_search MATCH ? AND pr.retailer_slug = ?'
        '$taxonomySql$usableClause$brandSql$completeSql$photoSql '
        'ORDER BY pr.user_confirmed DESC, pr.confidence DESC, '
        'bm25(product_search), p.use_count DESC '
        'LIMIT ? OFFSET ?',
        [
          _ftsQuery(normalizedQuery),
          retailerSlug,
          ...taxonomyArgs,
          ...brandArgs,
          safeLimit,
          safeOffset,
        ],
      );
    }
    return _withRetailerRelations(
      rows.map(_productFromRow).whereType<FoodProduct>().toList(),
    );
  }

  @override
  Future<FoodProduct?> read(String id) async {
    final rows = await database.query(
      'products',
      columns: ['payload_json'],
      where: 'product_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty
        ? null
        : (await _withRetailerRelations(
            [_productFromRow(rows.first)].whereType<FoodProduct>().toList(),
          )).firstOrNull;
  }

  @override
  Future<FoodProduct?> findByBarcode(String barcode) async {
    final rows = await database.query(
      'products',
      columns: ['payload_json'],
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    return rows.isEmpty
        ? null
        : (await _withRetailerRelations(
            [_productFromRow(rows.first)].whereType<FoodProduct>().toList(),
          )).firstOrNull;
  }

  @override
  Future<FoodProduct?> findMatching(FoodProduct product) async {
    if (product.barcode != null) return findByBarcode(product.barcode!);
    final rows = await database.query(
      'products',
      columns: ['payload_json'],
      where: 'cache_key = ?',
      whereArgs: [foodProductIdentity(product)],
      limit: 1,
    );
    return rows.isEmpty
        ? null
        : (await _withRetailerRelations(
            [_productFromRow(rows.first)].whereType<FoodProduct>().toList(),
          )).firstOrNull;
  }

  @override
  Future<void> write(FoodProduct product) async {
    await database.transaction((transaction) async {
      await _write(transaction, product);
    });
    if (product.source == FoodProductSource.manual) onUserMutation?.call();
  }

  Future<void> writeAll(
    Iterable<FoodProduct> products, {
    bool rebuildSearchIndex = true,
  }) async {
    await database.transaction((transaction) async {
      final favoriteRows = await transaction.query(
        'products',
        columns: ['cache_key', 'product_id'],
        where: 'favorite = 1',
      );
      final favoriteKeys = {
        for (final row in favoriteRows) row['cache_key'] as String,
      };
      final favoriteProductIds = {
        for (final row in favoriteRows) row['product_id'] as String,
      };
      final usageRows = await transaction.query(
        'products',
        columns: ['cache_key', 'product_id', 'use_count', 'last_used_at'],
        where: 'use_count > 0 OR last_used_at IS NOT NULL',
      );
      final usageByKey = {
        for (final row in usageRows) row['cache_key'] as String: row,
      };
      final usageByProductId = {
        for (final row in usageRows) row['product_id'] as String: row,
      };
      final hasExistingRows = (await transaction.query(
        'products',
        columns: ['product_id'],
        limit: 1,
      )).isNotEmpty;
      var batch = transaction.batch();
      var pending = 0;
      for (final product in products) {
        final key = foodProductIdentity(product);
        final localCategory = catalogTaxonomyOf(product);
        final priorUsage = usageByKey[key] ?? usageByProductId[product.id];
        final effectiveProduct =
            favoriteKeys.contains(key) ||
                favoriteProductIds.contains(product.id)
            ? product.withFavorite(true)
            : product;
        if (hasExistingRows) {
          batch.delete(
            'products',
            where: 'product_id = ? AND cache_key <> ?',
            whereArgs: [product.id, key],
          );
        }
        batch.rawInsert(
          '''INSERT INTO products(
            cache_key, product_id, barcode, normalized_name, brand,
            search_text, local_category, favorite, use_count, last_used_at,
            updated_at, payload_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
          ) ON CONFLICT(cache_key) DO UPDATE SET
            product_id=excluded.product_id, barcode=excluded.barcode,
            normalized_name=excluded.normalized_name, brand=excluded.brand,
            search_text=excluded.search_text,
            local_category=excluded.local_category, favorite=excluded.favorite,
            use_count=max(products.use_count, excluded.use_count),
            last_used_at=CASE
              WHEN products.last_used_at IS NULL THEN excluded.last_used_at
              WHEN excluded.last_used_at IS NULL THEN products.last_used_at
              ELSE max(products.last_used_at, excluded.last_used_at) END,
            updated_at=excluded.updated_at, payload_json=excluded.payload_json''',
          [
            key,
            product.id,
            product.barcode,
            product.normalizedName,
            normalizeFoodText(product.brand ?? ''),
            foodProductSearchText(product),
            localCategory,
            effectiveProduct.favorite ? 1 : 0,
            priorUsage?['use_count'] ?? 0,
            priorUsage?['last_used_at'],
            effectiveProduct.lastUpdatedAt.millisecondsSinceEpoch,
            jsonEncode(effectiveProduct.toJson()),
          ],
        );
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        for (final retailer in product.retailerTags) {
          final relation = _catalogRelation(product, retailer, now);
          batch.rawInsert(_retailerUpsertSql, _relationArgs(relation));
        }
        pending++;
        if (pending == 2000) {
          await batch.commit(noResult: true);
          batch = transaction.batch();
          pending = 0;
        }
      }
      if (pending > 0) await batch.commit(noResult: true);
      if (rebuildSearchIndex) await _rebuildSearchIndex(transaction);
    });
  }

  Future<void> _write(DatabaseExecutor executor, FoodProduct product) async {
    final key = foodProductIdentity(product);
    final localCategory = catalogTaxonomyOf(product);
    final existing = await executor.query(
      'products',
      columns: ['favorite', 'use_count', 'last_used_at'],
      where: 'cache_key = ? OR product_id = ?',
      whereArgs: [key, product.id],
      limit: 1,
    );
    final effectiveProduct =
        existing.isNotEmpty && existing.first['favorite'] == 1
        ? product.withFavorite(true)
        : product;
    await executor.delete(
      'products',
      where: 'product_id = ? AND cache_key <> ?',
      whereArgs: [product.id, key],
    );
    await executor.insert('products', {
      'cache_key': key,
      'product_id': product.id,
      'barcode': product.barcode,
      'normalized_name': product.normalizedName,
      'brand': normalizeFoodText(product.brand ?? ''),
      'search_text': foodProductSearchText(product),
      'local_category': localCategory,
      'favorite': effectiveProduct.favorite ? 1 : 0,
      'use_count': existing.isEmpty ? 0 : existing.first['use_count'],
      'last_used_at': existing.isEmpty ? null : existing.first['last_used_at'],
      'updated_at': product.lastUpdatedAt.millisecondsSinceEpoch,
      'payload_json': jsonEncode(effectiveProduct.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await executor.delete(
      'product_search',
      where: 'cache_key = ?',
      whereArgs: [key],
    );
    await executor.insert('product_search', {
      'cache_key': key,
      'normalized_name': product.normalizedName,
      'brand': normalizeFoodText(product.brand ?? ''),
      'search_text': foodProductSearchText(product),
    });
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final retailer in product.retailerTags) {
      final relation = _catalogRelation(product, retailer, now);
      await executor.rawInsert(_retailerUpsertSql, _relationArgs(relation));
    }
  }

  @override
  Future<Map<String, int>> usageCounts(Iterable<String> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) return const {};
    final placeholders = List.filled(unique.length, '?').join(',');
    final rows = await database.rawQuery(
      'SELECT product_id, use_count FROM products '
      'WHERE product_id IN ($placeholders)',
      unique,
    );
    return {
      for (final row in rows)
        row['product_id'] as String: (row['use_count'] as num).toInt(),
    };
  }

  @override
  Future<Map<String, bool>> favoriteStates(Iterable<String> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) return const {};
    final placeholders = List.filled(unique.length, '?').join(',');
    final rows = await database.rawQuery(
      'SELECT product_id, favorite FROM products '
      'WHERE product_id IN ($placeholders)',
      unique,
    );
    return {
      for (final row in rows) row['product_id'] as String: row['favorite'] == 1,
    };
  }

  @override
  Future<void> markUsed(String id) async {
    await database.rawUpdate(
      'UPDATE products SET use_count = use_count + 1, last_used_at = ? '
      'WHERE product_id = ?',
      [DateTime.now().toUtc().millisecondsSinceEpoch, id],
    );
  }

  @override
  Future<void> setFavorite(String id, bool favorite) async {
    final rows = await database.query(
      'products',
      columns: ['cache_key', 'payload_json'],
      where: 'product_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final product = _productFromRow(rows.first);
    if (product == null) return;
    await database.update(
      'products',
      {
        'favorite': favorite ? 1 : 0,
        'payload_json': jsonEncode(product.withFavorite(favorite).toJson()),
      },
      where: 'cache_key = ?',
      whereArgs: [rows.first['cache_key']],
    );
    onUserMutation?.call();
  }

  @override
  Future<void> saveRetailerRelation(ProductRetailerRelation relation) async {
    await database.rawInsert(_retailerUpsertSql, _relationArgs(relation));
    onUserMutation?.call();
  }

  Future<List<ProductRetailerRelation>> exportUserRetailerRelations() async {
    final rows = await database.query(
      'product_retailers',
      where:
          "source IN ('user_scan', 'user_manual', 'userScan', 'userManual') "
          'OR user_confirmed = 1',
      orderBy: 'product_id, retailer_slug',
    );
    return rows.map(_relationFromRow).toList();
  }

  Future<void> restoreUserRetailerRelations(
    Iterable<ProductRetailerRelation> relations,
  ) async {
    await database.transaction((transaction) async {
      for (final relation in relations) {
        await transaction.rawInsert(
          _retailerUpsertSql,
          _relationArgs(relation),
        );
      }
    });
  }

  Future<String?> readBootstrapVersion() async =>
      readSyncCursor('catalog-bootstrap');

  Future<void> writeBootstrapVersion(String version) =>
      writeSyncCursor('catalog-bootstrap', version);

  Future<void> _backfillLegacyRetailers() async {
    const marker = 'retailer-relations-v1';
    if (await readSyncCursor(marker) != null) return;
    final rows = await database.query(
      'products',
      columns: ['cache_key', 'local_category', 'payload_json'],
    );
    await database.transaction((transaction) async {
      for (final row in rows) {
        final product = _productFromRow(row);
        if (product == null) continue;
        final category = catalogTaxonomyOf(product);
        if (row['local_category'] != category) {
          await transaction.update(
            'products',
            {'local_category': category},
            where: 'cache_key = ?',
            whereArgs: [row['cache_key']],
          );
        }
        if (product.retailerTags.isEmpty) continue;
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        for (final retailer in product.retailerTags) {
          await transaction.rawInsert(
            _retailerUpsertSql,
            _relationArgs(_catalogRelation(product, retailer, now)),
          );
        }
      }
    });
    await writeSyncCursor(marker, '1');
  }

  Future<void> rebuildSearchIndex() async {
    await database.transaction(_rebuildSearchIndex);
  }

  Future<Map<String, Object>> localCatalogStats() async {
    final totals = (await database.rawQuery(r'''
      SELECT count(*) AS total,
        sum(CASE WHEN json_extract(payload_json, '$.nutrition.calories')
          IS NOT NULL THEN 1 ELSE 0 END) AS usable,
        sum(CASE WHEN barcode IS NOT NULL THEN 1 ELSE 0 END) AS barcode,
        sum(CASE WHEN json_extract(payload_json, '$.imageUrl')
          IS NOT NULL THEN 1 ELSE 0 END) AS image,
        sum(CASE WHEN json_extract(payload_json, '$.dataQuality') = 'good'
          THEN 1 ELSE 0 END) AS good,
        sum(CASE WHEN json_extract(payload_json, '$.dataQuality') = 'partial'
          THEN 1 ELSE 0 END) AS partial
      FROM products
    ''')).single;
    final retailers = await database.rawQuery('''
      SELECT retailer_slug, count(*) AS total,
        sum(CASE WHEN p.local_category = 'preparedFood' THEN 1 ELSE 0 END)
          AS prepared_food,
        sum(CASE WHEN p.local_category = 'hotBakery' THEN 1 ELSE 0 END)
          AS hot_bakery,
        sum(CASE WHEN pr.source IN ('user_scan', 'user_manual',
          'userScan', 'userManual') OR
          pr.user_confirmed = 1 THEN 1 ELSE 0 END) AS personal
      FROM product_retailers pr
      JOIN products p ON p.product_id = pr.product_id
      GROUP BY retailer_slug ORDER BY retailer_slug
    ''');
    int value(Object? raw) => raw is num ? raw.toInt() : 0;
    return {
      'total': value(totals['total']),
      'usable': value(totals['usable']),
      'barcode': value(totals['barcode']),
      'image': value(totals['image']),
      'good': value(totals['good']),
      'partial': value(totals['partial']),
      'retailers': {
        for (final row in retailers)
          row['retailer_slug'] as String: {
            'total': value(row['total']),
            'preparedFood': value(row['prepared_food']),
            'hotBakery': value(row['hot_bakery']),
            'personal': value(row['personal']),
          },
      },
    };
  }

  Future<Map<String, Map<String, int>>> retailerCategoryCounts() async {
    final rows = await database.rawQuery(r'''
      SELECT retailer_slug, p.local_category, count(*) AS total
      FROM product_retailers pr
      JOIN products p ON p.product_id = pr.product_id
      WHERE json_extract(p.payload_json, '$.nutrition.calories') IS NOT NULL
      GROUP BY retailer_slug, p.local_category
    ''');
    final result = <String, Map<String, int>>{};
    for (final row in rows) {
      result.putIfAbsent(
        row['retailer_slug'] as String,
        () => <String, int>{},
      )[row['local_category'] as String] = (row['total'] as num)
          .toInt();
    }
    for (final categories in result.values) {
      categories['all'] = categories.values.fold(
        0,
        (sum, value) => sum + value,
      );
    }
    return result;
  }

  Future<Map<String, int>> brandCounts({
    String? retailerSlug,
    String taxonomyCategory = 'all',
  }) async {
    final retailerJoin = retailerSlug == null
        ? ''
        : ' JOIN product_retailers pr ON pr.product_id = p.product_id';
    final conditions = <String>[
      r"json_extract(p.payload_json, '$.nutrition.calories') IS NOT NULL",
      r"coalesce(json_extract(p.payload_json, '$.brand'), '') <> ''",
      if (retailerSlug != null) 'pr.retailer_slug = ?',
      if (taxonomyCategory != 'all') 'p.local_category = ?',
    ];
    final args = <Object?>[
      if (retailerSlug != null) canonicalRetailerId(retailerSlug),
      if (taxonomyCategory != 'all') taxonomyCategory,
    ];
    final rows = await database.rawQuery(
      "SELECT json_extract(p.payload_json, '\$.brand') AS display_brand, "
      'count(*) AS total FROM products p$retailerJoin '
      'WHERE ${conditions.join(' AND ')} '
      'GROUP BY display_brand ORDER BY total DESC, display_brand COLLATE NOCASE',
      args,
    );
    return {
      for (final row in rows)
        if (row['display_brand'] case final String brand)
          brand: (row['total'] as num).toInt(),
    };
  }

  Future<int> count() async =>
      Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM products'),
      ) ??
      0;

  Future<List<String>> exportFavoriteProductIds() async {
    final rows = await database.query(
      'products',
      columns: ['product_id'],
      where: 'favorite = 1',
      orderBy: 'product_id ASC',
    );
    return rows.map((row) => row['product_id'] as String).toList();
  }

  Future<void> restoreFavoriteProductIds(Iterable<String> productIds) async {
    final unique = productIds.toSet();
    if (unique.isEmpty) return;
    await database.transaction((transaction) async {
      for (final id in unique) {
        final rows = await transaction.query(
          'products',
          columns: ['cache_key', 'payload_json'],
          where: 'product_id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (rows.isEmpty) continue;
        final product = _productFromRow(rows.first);
        if (product == null) continue;
        await transaction.update(
          'products',
          {
            'favorite': 1,
            'payload_json': jsonEncode(product.withFavorite(true).toJson()),
          },
          where: 'cache_key = ?',
          whereArgs: [rows.first['cache_key']],
        );
      }
    });
  }

  Future<void> close() => database.close();

  Future<List<FoodProduct>> _withRetailerRelations(
    List<FoodProduct> products,
  ) async {
    if (products.isEmpty) return products;
    final ids = products.map((product) => product.id).toSet().toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await database.rawQuery(
      'SELECT product_id, retailer_slug FROM product_retailers '
      'WHERE product_id IN ($placeholders)',
      ids,
    );
    final retailers = <String, Set<String>>{};
    for (final row in rows) {
      retailers
          .putIfAbsent(row['product_id'] as String, () => <String>{})
          .add(row['retailer_slug'] as String);
    }
    return [
      for (final product in products)
        product.withRetailerTags({
          ...product.retailerTags,
          ...?retailers[product.id],
        }),
    ];
  }

  static Future<void> _rebuildSearchIndex(DatabaseExecutor executor) async {
    await executor.delete('product_search');
    await executor.execute('''
      INSERT INTO product_search(cache_key, normalized_name, brand, search_text)
      SELECT cache_key, normalized_name, brand, search_text FROM products
    ''');
  }

  static ProductRetailerRelation _catalogRelation(
    FoodProduct product,
    String retailer,
    int now,
  ) {
    final official = product.source == FoodProductSource.officialRetailer;
    return ProductRetailerRelation(
      productId: product.id,
      retailerSlug: canonicalRetailerId(retailer),
      source: official
          ? RetailerRelationSource.officialFeed
          : RetailerRelationSource.offStoreTag,
      confidence: official ? 1 : 0.6,
      userConfirmed: false,
      firstSeenAt: DateTime.fromMillisecondsSinceEpoch(now, isUtc: true),
      lastSeenAt: DateTime.fromMillisecondsSinceEpoch(now, isUtc: true),
    );
  }

  static List<Object?> _relationArgs(ProductRetailerRelation relation) => [
    relation.productId,
    relation.retailerSlug,
    relation.source.storageValue,
    relation.confidence,
    relation.userConfirmed ? 1 : 0,
    relation.firstSeenAt.millisecondsSinceEpoch,
    relation.lastSeenAt.millisecondsSinceEpoch,
  ];

  static ProductRetailerRelation _relationFromRow(Map<String, Object?> row) =>
      ProductRetailerRelation(
        productId: row['product_id'] as String,
        retailerSlug: row['retailer_slug'] as String,
        source: RetailerRelationSourceStorage.parse(row['source']),
        confidence: (row['confidence'] as num).toDouble(),
        userConfirmed: row['user_confirmed'] == 1,
        firstSeenAt: DateTime.fromMillisecondsSinceEpoch(
          (row['first_seen_at'] as num).toInt(),
          isUtc: true,
        ),
        lastSeenAt: DateTime.fromMillisecondsSinceEpoch(
          (row['last_seen_at'] as num).toInt(),
          isUtc: true,
        ),
      );

  static String _ftsQuery(String normalized) => normalized
      .split(' ')
      .where((token) => token.isNotEmpty)
      .map((token) {
        final prefix = token.length > 3 ? token.substring(0, 3) : token;
        return '"${prefix.replaceAll('"', '')}"*';
      })
      .join(' AND ');

  static FoodProduct? _productFromRow(Map<String, Object?> row) {
    final payload = row['payload_json'];
    if (payload is! String) return null;
    try {
      return FoodProduct.tryFromJson(jsonDecode(payload));
    } on FormatException {
      return null;
    }
  }
}
