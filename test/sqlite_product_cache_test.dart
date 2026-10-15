import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/models/food_product.dart';
import 'package:flutter_app/services/food_catalog_repository.dart';
import 'package:flutter_app/services/remote_catalog_source.dart';
import 'package:flutter_app/services/sqlite_product_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

FoodProduct _product(int index, {String? barcode}) => FoodProduct(
  id: 'product-$index',
  barcode: barcode,
  name: 'Тестовый продукт $index',
  brand: 'Бренд ${index % 20}',
  nutrition: const NutritionValues(calories: 100),
  source: FoodProductSource.openFoodFacts,
);

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late SqliteProductCache cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('balance_catalog_');
    cache = await SqliteProductCache.open(
      factory: databaseFactoryFfi,
      databasePath: '${directory.path}/catalog.db',
    );
  });

  tearDown(() async {
    await cache.close();
    await directory.delete(recursive: true);
  });

  test('schema has independent version and required indexes', () async {
    expect(await cache.database.getVersion(), SqliteProductCache.schemaVersion);
    final indexes = await cache.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index'",
    );
    final names = indexes.map((row) => row['name']).toSet();
    expect(names, contains('products_barcode_unique'));
    expect(names, contains('products_normalized_name_idx'));
    expect(names, contains('products_brand_idx'));
    expect(names, contains('products_updated_at_idx'));
    expect(names, contains('products_product_id_idx'));
  });

  test('cached barcode lookup and FTS pagination work offline', () async {
    await cache.write(_product(1, barcode: '4006381333931'));
    final repository = FoodCatalogRepository(
      cache: cache,
      localProducts: const [],
    );
    expect((await repository.findByBarcode('4006381333931'))?.id, 'product-1');
    final result = await repository.search(
      'тестовый продукт',
      online: false,
      limit: 1,
    );
    expect(result.items, hasLength(1));
  });

  test('catalog sync cursor survives cache writes', () async {
    await cache.writeSyncCursor('remote-catalog', 'cursor-1');
    await cache.write(_product(1));
    expect(await cache.readSyncCursor('remote-catalog'), 'cursor-1');
  });

  test('remote catalog sync persists every completed cursor page', () async {
    final requestedCursors = <String?>[];
    final source = RemoteCatalogSource(
      baseUrl: 'https://catalog.balance.test',
      client: MockClient((request) async {
        final cursor = request.url.queryParameters['cursor'];
        requestedCursors.add(cursor);
        final page = cursor == null ? 1 : 2;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'items': [
                {
                  'id': 'remote-$page',
                  'name': 'Удалённый продукт $page',
                  'nutrition_basis': 'per100g',
                  'basis_amount': 100,
                  'energy_kcal': 100 + page,
                  'source_type': 'open_food_facts',
                  'data_quality': 'good',
                  'updated_at': '2026-09-08T10:00:00Z',
                },
              ],
              'nextCursor': 'cursor-$page',
            }),
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    expect(await source.syncCatalog(cache, maxPages: 2, pageSize: 1), 2);
    expect(requestedCursors, [null, 'cursor-1']);
    expect(await cache.readSyncCursor('remote-catalog'), 'cursor-2');
    expect(await cache.count(), 2);
    source.dispose();
  });

  test('favorite survives SQLite reopen and updates immediately', () async {
    final product = _product(7);
    await cache.write(product);
    await cache.setFavorite(product.id, true);
    await cache.close();
    cache = await SqliteProductCache.open(
      factory: databaseFactoryFfi,
      databasePath: '${directory.path}/catalog.db',
    );
    final repository = FoodCatalogRepository(
      cache: cache,
      localProducts: const [],
    );

    var result = await repository.search(
      '',
      online: false,
      category: 'favorite',
    );
    expect(result.items.single.id, product.id);
    await repository.setFavorite(result.items.single, false);
    result = await repository.search('', online: false, category: 'favorite');
    expect(result.items, isEmpty);
  });

  test('catalog updates preserve a local product favorite', () async {
    final original = _product(8);
    await cache.write(original);
    await cache.setFavorite(original.id, true);

    final updated = FoodProduct(
      id: original.id,
      barcode: original.barcode,
      name: 'Обновлённый товар',
      nutrition: const NutritionValues(calories: 120),
      source: FoodProductSource.openFoodFacts,
      lastUpdatedAt: DateTime(2026, 9, 9),
    );
    await cache.writeAll([updated]);

    final restored = await cache.read(original.id);
    expect(restored?.name, 'Обновлённый товар');
    expect(restored?.favorite, isTrue);
    expect(await cache.count(), 1);
  });

  test('product favorites export and restore without clearing cache', () async {
    await cache.writeAll([_product(9), _product(10)]);
    await cache.setFavorite('product-9', true);
    final favorites = await cache.exportFavoriteProductIds();
    await cache.setFavorite('product-9', false);

    await cache.restoreFavoriteProductIds(favorites);

    expect(await cache.exportFavoriteProductIds(), ['product-9']);
    expect(await cache.count(), 2);
  });

  test('retailer browsing includes cached products before first use', () async {
    await cache.write(
      FoodProduct(
        id: 'retailer-bakery',
        name: 'Слойка с яблоком',
        retailerTags: const ['Пятёрочка'],
        category: 'Горячая выпечка',
        nutrition: const NutritionValues(calories: 290),
        source: FoodProductSource.officialRetailer,
      ),
    );
    final repository = FoodCatalogRepository(
      cache: cache,
      localProducts: const [],
    );

    final result = await repository.search(
      '',
      online: false,
      retailer: 'Пятёрочка',
      taxonomyCategory: 'hotBakery',
    );

    expect(result.items.single.id, 'retailer-bakery');
  });

  test('retailer and brand counts use the same usable catalog scope', () async {
    await cache.writeAll([
      FoodProduct(
        id: 'milk-a',
        name: 'Молоко A',
        brand: 'Danone',
        retailerTags: const ['pyaterochka'],
        localCategory: 'dairy',
        nutrition: const NutritionValues(calories: 50),
        source: FoodProductSource.openFoodFacts,
      ),
      FoodProduct(
        id: 'milk-b',
        name: 'Молоко B',
        brand: 'Другой бренд',
        retailerTags: const ['pyaterochka'],
        localCategory: 'dairy',
        nutrition: const NutritionValues(calories: 60),
        source: FoodProductSource.openFoodFacts,
      ),
    ]);

    final stores = await cache.retailerCategoryCounts();
    final brands = await cache.brandCounts(
      retailerSlug: 'pyaterochka',
      taxonomyCategory: 'dairy',
    );
    expect(stores['pyaterochka']?['all'], 2);
    expect(brands['Danone'], 1);
    expect(brands['Другой бренд'], 1);
  });

  test('100000 synthetic SKU remain paginated and searchable', () async {
    final products = List.generate(100000, _product);
    final ingest = Stopwatch()..start();
    await cache.writeAll(products);
    ingest.stop();
    final search = Stopwatch()..start();
    final result = await cache.searchCandidates(
      'тестовый продукт 99999',
      limit: 30,
      offset: 0,
      category: 'all',
    );
    search.stop();
    expect(await cache.count(), 100000);
    expect(result, isNotEmpty);
    expect(result.length, lessThanOrEqualTo(30));
    // ignore: avoid_print
    print(
      'SQLite 100k: ingest=${ingest.elapsedMilliseconds}ms, '
      'search=${search.elapsedMicroseconds / 1000}ms',
    );
    expect(search.elapsed, lessThan(const Duration(seconds: 2)));
    // Generous CI guard: this is performance verification, not a real catalog count.
    expect(ingest.elapsed, lessThan(const Duration(minutes: 2)));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
