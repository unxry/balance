import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/models/food_product.dart';
import 'package:flutter_app/models/product_retailer_relation.dart';
import 'package:flutter_app/services/food_catalog_repository.dart';
import 'package:flutter_app/services/local_catalog_bootstrap.dart';
import 'package:flutter_app/services/sqlite_product_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

FoodProduct product(
  String id,
  String name, {
  String? barcode,
  List<String> retailers = const [],
  String category = 'dairy',
}) => FoodProduct(
  id: id,
  barcode: barcode,
  name: name,
  retailerTags: retailers,
  nutrition: const NutritionValues(
    calories: 100,
    protein: 4,
    fat: 3,
    carbs: 12,
  ),
  source: FoodProductSource.openFoodFacts,
  localCategory: category,
);

Future<void> createBootstrap(String path, List<FoodProduct> products) async {
  final database = await databaseFactoryFfi.openDatabase(path);
  await database.execute(
    'CREATE TABLE bootstrap_meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
  );
  await database.execute('''
    CREATE TABLE bootstrap_products(
      product_id TEXT PRIMARY KEY,
      barcode TEXT UNIQUE,
      payload_json TEXT NOT NULL
    )
  ''');
  await database.insert('bootstrap_meta', {
    'key': 'version',
    'value': 'test-v1',
  });
  for (final item in products) {
    await database.insert('bootstrap_products', {
      'product_id': item.id,
      'barcode': item.barcode,
      'payload_json': jsonEncode(item.toJson()),
    });
  }
  await database.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('bundled snapshot exposes non-zero usable retailer counts', () async {
    final directory = await Directory.systemTemp.createTemp(
      'balance_bundled_counts_',
    );
    final cache = await SqliteProductCache.open(
      factory: databaseFactoryFfi,
      databasePath: '${directory.path}/target.db',
    );
    try {
      await LocalCatalogBootstrap(
        cache: cache,
        factory: databaseFactoryFfi,
      ).ensureImported();
      expect(await cache.count(), 42561);
      final integrity = await cache.database.rawQuery('PRAGMA integrity_check');
      expect(integrity.single.values.single, 'ok');
      final counts = await cache.retailerCategoryCounts();
      expect(
        counts.values.any((categories) => (categories['all'] ?? 0) > 0),
        isTrue,
      );
      expect(counts['pyaterochka']?['all'], 157);
      expect(counts['magnit']?['all'], 131);
      expect(counts['perekrestok']?['all'], 51);
      expect(counts['vkusvill']?['all'], 83);
      expect(counts['fix_price']?['all'], 15);
      expect(counts['pobeda']?['all'] ?? 0, 0);
      for (final retailer in const [
        'pyaterochka',
        'magnit',
        'perekrestok',
        'vkusvill',
        'fix_price',
      ]) {
        expect(
          await cache.searchRetailerCandidates(
            '',
            retailerSlug: retailer,
            taxonomyCategory: 'all',
            limit: 1,
            offset: 0,
          ),
          isNotEmpty,
          reason: '$retailer must open into real local results',
        );
      }
    } finally {
      await cache.close();
      await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    'empty cache imports bootstrap and exposes full paginated browse',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'balance_bootstrap_',
      );
      final sourcePath = '${directory.path}/source.db';
      await createBootstrap(sourcePath, [
        product(
          'milk',
          'Молоко',
          barcode: '4601234567893',
          retailers: const ['pyaterochka', 'magnit'],
        ),
        product(
          'bread',
          'Хлеб',
          barcode: '4601234567886',
          retailers: const ['magnit'],
          category: 'bread',
        ),
      ]);
      final cache = await SqliteProductCache.open(
        factory: databaseFactoryFfi,
        databasePath: '${directory.path}/target.db',
      );

      final result = await LocalCatalogBootstrap(
        cache: cache,
        factory: databaseFactoryFfi,
        bootstrapDatabasePath: sourcePath,
      ).ensureImported();

      expect(result.importedProducts, 2);
      expect(await cache.count(), 2);
      expect(
        await cache.searchCandidates(
          '',
          limit: 1,
          offset: 1,
          category: 'all',
          browseAll: true,
        ),
        hasLength(1),
      );
      expect(
        await cache.searchRetailerCandidates(
          '',
          retailerSlug: 'pyaterochka',
          taxonomyCategory: 'all',
          limit: 50,
          offset: 0,
        ),
        hasLength(1),
      );
      expect(
        await cache.searchRetailerCandidates(
          '',
          retailerSlug: 'magnit',
          taxonomyCategory: 'all',
          limit: 50,
          offset: 0,
        ),
        hasLength(2),
      );
      final skipped = await LocalCatalogBootstrap(
        cache: cache,
        factory: databaseFactoryFfi,
        bootstrapDatabasePath: sourcePath,
      ).ensureImported();
      expect(skipped.skipped, isTrue);
      await cache.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'bootstrap merge preserves favorite recent and personal retailer',
    () async {
      final directory = await Directory.systemTemp.createTemp('balance_merge_');
      final sourcePath = '${directory.path}/source.db';
      final updated = product(
        'milk',
        'Молоко обновлённое',
        barcode: null,
        retailers: const ['magnit'],
      );
      await createBootstrap(sourcePath, [updated]);
      final cache = await SqliteProductCache.open(
        factory: databaseFactoryFfi,
        databasePath: '${directory.path}/target.db',
      );
      final original = product('milk', 'Молоко', barcode: '4601234567893');
      await cache.write(original);
      await cache.setFavorite(original.id, true);
      for (var i = 0; i < 5; i++) {
        await cache.markUsed(original.id);
      }
      await cache.saveRetailerRelation(
        ProductRetailerRelation(
          productId: original.id,
          retailerSlug: 'pyaterochka',
          source: RetailerRelationSource.userScan,
          confidence: .95,
          userConfirmed: false,
        ),
      );

      await LocalCatalogBootstrap(
        cache: cache,
        factory: databaseFactoryFfi,
        bootstrapDatabasePath: sourcePath,
      ).ensureImported();

      expect((await cache.read('milk'))?.favorite, isTrue);
      expect((await cache.usageCounts(['milk']))['milk'], 5);
      expect(
        (await cache.exportUserRetailerRelations()).single.retailerSlug,
        'pyaterochka',
      );
      expect(
        await cache.searchRetailerCandidates(
          'молоко',
          retailerSlug: 'pyaterochka',
          taxonomyCategory: 'dairy',
          limit: 50,
          offset: 0,
        ),
        hasLength(1),
      );
      await cache.close();
      final reopened = await SqliteProductCache.open(
        factory: databaseFactoryFfi,
        databasePath: '${directory.path}/target.db',
      );
      final persisted = await reopened.exportUserRetailerRelations();
      expect(persisted.single.retailerSlug, 'pyaterochka');
      expect(persisted.single.source, RetailerRelationSource.userScan);
      await reopened.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'real bundled catalog imports and serves relevant offline search',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'balance_real_catalog_',
      );
      final cache = await SqliteProductCache.open(
        factory: databaseFactoryFfi,
        databasePath: '${directory.path}/target.db',
      );
      final result = await LocalCatalogBootstrap(
        cache: cache,
        factory: databaseFactoryFfi,
      ).ensureImported();
      final stats = await cache.localCatalogStats();

      expect(result.importedProducts, greaterThan(10000));
      expect(stats['total'], result.importedProducts);
      expect(stats['usable'], 17955);
      expect(stats['barcode'], 32744);
      expect(stats['image'], 24357);
      expect(
        await cache.searchCandidates(
          '',
          limit: 150,
          offset: 0,
          category: 'all',
          browseAll: true,
        ),
        hasLength(150),
      );
      expect(
        await cache.searchRetailerCandidates(
          '',
          retailerSlug: 'pyaterochka',
          taxonomyCategory: 'all',
          limit: 200,
          offset: 0,
        ),
        hasLength(157),
      );
      final storeStopwatch = Stopwatch()..start();
      final storePage = await cache.searchRetailerCandidates(
        '',
        retailerSlug: 'pyaterochka',
        taxonomyCategory: 'all',
        limit: 50,
        offset: 100,
      );
      storeStopwatch.stop();
      expect(storePage, hasLength(50));
      expect(storeStopwatch.elapsedMilliseconds, lessThan(150));

      final repository = FoodCatalogRepository(
        cache: cache,
        localProducts: const [],
      );
      for (final check in const [
        ('pyaterochka', 'молоко'),
        ('pyaterochka', 'творог'),
        ('pyaterochka', 'кефир'),
        ('pyaterochka', 'сыр'),
        ('pyaterochka', 'хлеб'),
        ('pyaterochka', 'булочка'),
        ('fix_price', 'шоколад'),
        ('fix_price', 'напиток'),
        ('fix_price', 'печенье'),
      ]) {
        final outcome = await repository.search(
          check.$2,
          retailer: check.$1,
          online: false,
          limit: 20,
        );
        expect(outcome.items, isNotEmpty, reason: '${check.$1}: ${check.$2}');
      }

      final barcodeRow = (await cache.database.rawQuery(
        'SELECT barcode FROM products WHERE barcode IS NOT NULL LIMIT 1',
      )).single;
      final barcodeStopwatch = Stopwatch()..start();
      expect(
        await cache.findByBarcode(barcodeRow['barcode'] as String),
        isNotNull,
      );
      barcodeStopwatch.stop();
      expect(barcodeStopwatch.elapsedMilliseconds, lessThan(150));

      var slowestMs = 0;
      for (final query in const [
        'молоко',
        'творог',
        'кефир',
        'хлеб',
        'булочка',
        'курица',
        'сыр',
        'йогурт',
        'колбаса',
        'макароны',
        'шоколад',
        'вода',
      ]) {
        final stopwatch = Stopwatch()..start();
        final found = await cache.searchCandidates(
          normalizeFoodText(query),
          limit: 20,
          offset: 0,
          category: 'all',
          browseAll: true,
        );
        stopwatch.stop();
        if (stopwatch.elapsedMilliseconds > slowestMs) {
          slowestMs = stopwatch.elapsedMilliseconds;
        }
        final prefix = normalizeFoodText(query).substring(0, 3);
        expect(found, isNotEmpty, reason: query);
        expect(
          found.any(
            (product) => foodProductSearchText(product).contains(prefix),
          ),
          isTrue,
          reason: query,
        );
      }
      debugPrint('[local-catalog] slowestSearchMs=$slowestMs');
      debugPrint(
        '[local-catalog] storeBrowseMs=${storeStopwatch.elapsedMilliseconds} '
        'barcodeLookupMs=${barcodeStopwatch.elapsedMilliseconds}',
      );
      expect(slowestMs, lessThan(150));

      await cache.close();
      await directory.delete(recursive: true);
    },
  );
}
