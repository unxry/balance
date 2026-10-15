import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/models/food_product.dart';
import 'package:flutter_app/services/food_catalog_repository.dart';
import 'package:flutter_app/services/food_search_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _RetailerBrowseFake
    implements FoodProductSourceAdapter, RetailerBrowseSource {
  _RetailerBrowseFake(this.items);

  final List<FoodProduct> items;
  int browseCalls = 0;
  String? lastRetailer;
  String? lastTaxonomy;

  @override
  FoodSearchError? get lastBarcodeError => null;

  @override
  Future<FoodProduct?> findByBarcode(String barcode) async => null;

  @override
  Future<FoodSearchOutcome> search(String query, {int limit = 20}) async =>
      const FoodSearchOutcome([]);

  @override
  Future<FoodSearchOutcome> browseRetailer(
    String retailer, {
    String taxonomy = 'all',
    int limit = 20,
  }) async {
    browseCalls++;
    lastRetailer = retailer;
    lastTaxonomy = taxonomy;
    return FoodSearchOutcome(items.take(limit).toList());
  }
}

FoodProduct product({
  required String id,
  String? barcode,
  String name = 'Творог Вкуснотеево 5%',
  FoodProductSource source = FoodProductSource.openFoodFacts,
  bool verified = false,
  FoodNutritionBasis basis = FoodNutritionBasis.per100g,
  double basisAmount = 100,
  NutritionValues nutrition = const NutritionValues(
    calories: 157,
    protein: 16,
    fat: 9,
    carbs: 3,
  ),
  bool favorite = false,
  List<String> retailerTags = const [],
  String? category,
  String? imageUrl,
  String? brand,
}) => FoodProduct(
  id: id,
  barcode: barcode,
  name: name,
  source: source,
  nutritionVerified: verified,
  nutritionBasis: basis,
  nutritionBasisAmount: basisAmount,
  nutrition: nutrition,
  favorite: favorite,
  retailerTags: retailerTags,
  category: category,
  imageUrl: imageUrl,
  brand: brand,
);

void main() {
  test('decodes catalog HTML entities in user-visible fields', () {
    final item = FoodProduct.fromJson({
      'id': 'encoded',
      'name': 'Йогурт &quot;Густой&quot; &#39;2%&#39;',
      'brand': 'Milk &amp; More',
      'category': 'Молоко &#x26; сливки',
      'nutrition': const <String, Object?>{},
    });

    expect(item.name, 'Йогурт "Густой" \'2%\'');
    expect(item.brand, 'Milk & More');
    expect(item.category, 'Молоко & сливки');
  });

  test('built-in catalog does not create preset favorites', () async {
    final repository = FoodCatalogRepository(cache: MemoryProductCache());
    final favorites = await repository.search(
      '',
      online: false,
      category: 'favorite',
    );
    expect(favorites.items, isEmpty);
  });

  test('calculates all nutrition bases without hardcoded portions', () {
    for (final testCase in [
      (FoodNutritionBasis.per100g, 100.0, 60.0, 94.2),
      (FoodNutritionBasis.per100ml, 100.0, 250.0, 392.5),
      (FoodNutritionBasis.perServing, 30.0, 60.0, 314.0),
      (FoodNutritionBasis.perItem, 1.0, 2.0, 314.0),
    ]) {
      final values = product(
        id: testCase.$1.name,
        basis: testCase.$1,
        basisAmount: testCase.$2,
      ).nutritionForAmount(testCase.$3);
      expect(values.calories, closeTo(testCase.$4, 0.001));
    }
  });

  test('missing nutrition remains null and is not invented', () {
    final incomplete = product(
      id: 'partial',
      nutrition: const NutritionValues(calories: 42),
    );
    expect(incomplete.nutrition.protein, isNull);
    expect(incomplete.dataQuality, FoodDataQuality.partial);
  });

  test(
    'barcode deduplication keeps higher-priority nutrition and flags conflict',
    () async {
      final off = product(id: 'off', barcode: '4601234567890', verified: true);
      final retailer = product(
        id: 'retailer',
        barcode: '4601234567890',
        source: FoodProductSource.officialRetailer,
        nutrition: const NutritionValues(
          calories: 210,
          protein: 12,
          fat: 13,
          carbs: 8,
        ),
      );
      final merged = mergeProducts(off, retailer);
      expect(merged.source, FoodProductSource.officialRetailer);
      expect(merged.nutrition.calories, 210);
      expect(merged.needsReview, isTrue);
    },
  );

  test(
    'offline cache supports tolerant Russian and transliterated search',
    () async {
      final cache = MemoryProductCache();
      await cache.write(product(id: 'curd'));
      await cache.write(product(id: 'pasta', name: 'Макароны Barilla'));
      final repository = FoodCatalogRepository(
        cache: cache,
        localProducts: const [],
      );

      expect(
        (await repository.search('творог вкусн', online: false)).items,
        hasLength(1),
      );
      expect(
        (await repository.search('макороны', online: false)).items,
        hasLength(1),
      );
      expect(
        (await repository.search('barila', online: false)).items,
        hasLength(1),
      );
    },
  );

  test('a seeded favorite can be removed and added again', () async {
    final cache = MemoryProductCache();
    final seeded = product(id: 'favorite', favorite: true);
    final repository = FoodCatalogRepository(
      cache: cache,
      localProducts: [seeded],
    );

    expect(
      (await repository.search('', online: false, category: 'favorite')).items,
      hasLength(1),
    );
    await repository.setFavorite(seeded, false);
    expect(
      (await repository.search('', online: false, category: 'favorite')).items,
      isEmpty,
    );
    await repository.setFavorite(seeded, true);
    expect(
      (await repository.search('', online: false, category: 'favorite')).items,
      hasLength(1),
    );
  });

  test('retailer and taxonomy filters only return real linked SKUs', () async {
    final bakery = product(
      id: 'bakery',
      name: 'Слойка с яблоком',
      retailerTags: const ['pyaterochka'],
      category: 'Горячая выпечка',
    );
    final otherRetailer = product(
      id: 'other-retailer',
      retailerTags: const ['magnit'],
      category: 'Горячая выпечка',
    );
    final repository = FoodCatalogRepository(
      cache: MemoryProductCache(),
      localProducts: [bakery, otherRetailer],
    );

    final result = await repository.search(
      '',
      online: false,
      retailer: 'Пятёрочка',
      taxonomyCategory: 'hotBakery',
    );

    expect(result.items.map((item) => item.id), ['bakery']);
    expect(catalogTaxonomyOf(bakery), 'hotBakery');
  });

  test('retailer taxonomy normalizes prepared food and bakery aliases', () {
    expect(
      catalogTaxonomyOf(
        product(
          id: 'prepared',
          name: 'Салат с курицей',
          retailerTags: const ['magnit'],
        ),
      ),
      'preparedFood',
    );
    expect(
      catalogTaxonomyOf(
        product(
          id: 'bun',
          name: 'Булочка с корицей',
          retailerTags: const ['pyaterochka'],
        ),
      ),
      'hotBakery',
    );
  });

  test('all supported retailer names map to backend slugs', () {
    const expected = {
      'Пятёрочка': 'pyaterochka',
      'Магнит': 'magnit',
      'Перекрёсток': 'perekrestok',
      'ВкусВилл': 'vkusvill',
      'ПОБЕДА': 'pobeda',
      'Fix Price': 'fix_price',
    };
    for (final entry in expected.entries) {
      expect(canonicalRetailerId(entry.key), entry.value);
    }
  });

  test('empty retailer browse forwards preparedFood category', () async {
    final source = _RetailerBrowseFake([
      product(
        id: 'prepared',
        name: 'Салат с курицей',
        retailerTags: const ['magnit'],
      ),
    ]);
    final repository = FoodCatalogRepository(
      cache: MemoryProductCache(),
      sources: [source],
      localProducts: const [],
    );

    final result = await repository.search(
      '',
      retailer: 'Магнит',
      taxonomyCategory: 'preparedFood',
    );

    expect(source.lastRetailer, 'Магнит');
    expect(source.lastTaxonomy, 'preparedFood');
    expect(result.items.single.id, 'prepared');
  });

  test(
    'empty retailer browse keeps usable unverified GOOD and PARTIAL',
    () async {
      final source = _RetailerBrowseFake([
        product(
          id: 'good',
          name: 'Ready meal',
          retailerTags: const ['pyaterochka'],
        ),
        product(
          id: 'partial',
          name: 'Fresh bakery bun',
          retailerTags: const ['pyaterochka'],
          nutrition: const NutritionValues(calories: 210),
        ),
        product(
          id: 'unusable',
          retailerTags: const ['pyaterochka'],
          nutrition: const NutritionValues(protein: 2),
        ),
      ]);
      final cache = MemoryProductCache();
      final repository = FoodCatalogRepository(
        cache: cache,
        sources: [source],
        localProducts: const [],
      );

      final fetched = await repository.search(
        '',
        online: true,
        retailer: 'pyaterochka',
      );
      expect(source.browseCalls, 1);
      expect(
        fetched.items.map((item) => item.id),
        unorderedEquals(['good', 'partial']),
      );
      expect(fetched.items.every((item) => !item.nutritionVerified), isTrue);

      final cached = await repository.search(
        '',
        online: false,
        retailer: 'pyaterochka',
      );
      expect(
        cached.items.map((item) => item.id),
        unorderedEquals(['good', 'partial']),
      );
      expect(catalogTaxonomyOf(source.items[0]), 'preparedFood');
      expect(catalogTaxonomyOf(source.items[1]), 'hotBakery');
    },
  );

  test('meal selection changes ranking without hiding other foods', () async {
    final repository = FoodCatalogRepository(
      cache: MemoryProductCache(),
      localProducts: [
        product(id: 'soup', name: 'Куриный суп'),
        product(id: 'porridge', name: 'Овсяная каша'),
        product(id: 'apple', name: 'Яблоко'),
      ],
    );

    final breakfast = await repository.search(
      '',
      online: false,
      meal: MealType.breakfast,
    );
    final snack = await repository.search(
      '',
      online: false,
      meal: MealType.snack,
    );

    expect(breakfast.items.first.id, 'porridge');
    expect(snack.items.first.id, 'apple');
    expect(breakfast.items, hasLength(3));
    expect(snack.items, hasLength(3));
  });

  test('ordinary search hides unusable partial records', () async {
    final repository = FoodCatalogRepository(
      cache: MemoryProductCache(),
      localProducts: [
        product(id: 'usable'),
        product(
          id: 'partial',
          nutrition: const NutritionValues(protein: 2, fat: 1, carbs: 3),
        ),
      ],
    );

    final result = await repository.search('', online: false);

    expect(result.items.map((item) => item.id), ['usable']);
  });

  test('complete nutrition quality filter excludes partial macros', () async {
    final repository = FoodCatalogRepository(
      cache: MemoryProductCache(),
      localProducts: [
        product(id: 'complete'),
        product(
          id: 'calories-only',
          nutrition: const NutritionValues(calories: 88),
        ),
      ],
    );

    final result = await repository.search(
      '',
      online: false,
      onlyCompleteNutrition: true,
    );

    expect(result.items.map((item) => item.id), ['complete']);
  });

  test('brand, photo and complete nutrition are independent filters', () async {
    final repository = FoodCatalogRepository(
      cache: MemoryProductCache(),
      localProducts: [
        product(id: 'selected', brand: 'Danone', imageUrl: 'https://image'),
        product(id: 'wrong-brand', brand: 'Barilla', imageUrl: 'https://image'),
        product(id: 'no-photo', brand: 'Danone'),
        product(
          id: 'partial',
          brand: 'Danone',
          imageUrl: 'https://image',
          nutrition: const NutritionValues(calories: 80),
        ),
      ],
    );

    expect(ProductSort.values, hasLength(3));
    final result = await repository.search(
      '',
      online: false,
      brand: 'Danone',
      onlyPhoto: true,
      onlyCompleteNutrition: true,
      sort: ProductSort.name,
    );

    expect(result.items.map((item) => item.id), ['selected']);
  });

  test('catalog updates cannot mutate an existing diary snapshot', () {
    final original = product(id: 'sku', barcode: '4601234567890');
    final snapshotNutrition = original.nutritionForAmount(60);
    final entry = FoodEntry(
      id: 'entry',
      productId: original.id,
      productVersion: '1',
      productSource: original.source.name,
      name: original.name,
      grams: 60,
      kcal: snapshotNutrition.calories!.round(),
      proteinG: snapshotNutrition.protein!,
      fatG: snapshotNutrition.fat!,
      carbsG: snapshotNutrition.carbs!,
      meal: MealType.breakfast,
      time: DateTime(2026, 9, 4),
    );
    product(
      id: 'sku-v2',
      barcode: '4601234567890',
      nutrition: const NutritionValues(calories: 300),
    );
    expect(entry.kcal, 94);
    expect(entry.productVersion, '1');
  });

  test('recipe ingredient context prefers culinary potato forms', () async {
    final repository = FoodCatalogRepository(
      cache: MemoryProductCache(),
      localProducts: [
        product(id: 'raw', name: 'Картофель'),
        product(id: 'boiled', name: 'Картофель отварной'),
        product(id: 'baked', name: 'Картофель запечённый'),
        product(id: 'puree', name: 'Картофельное пюре'),
        product(id: 'fries', name: 'Картофель фри'),
        product(id: 'chips', name: 'Чипсы картофельные'),
        product(id: 'candy', name: 'Конфеты картошка'),
      ],
    );

    final result = await repository.search(
      'картофель',
      online: false,
      searchContext: FoodSearchContext.recipeIngredient,
    );

    expect(
      result.items.map((item) => item.id),
      containsAllInOrder(['raw', 'boiled', 'baked', 'puree', 'fries']),
    );
    expect(result.items.map((item) => item.id), isNot(contains('chips')));
    expect(result.items.map((item) => item.id), isNot(contains('candy')));
  });

  test(
    'recipe ingredient context keeps творог results semantically exact',
    () async {
      final repository = FoodCatalogRepository(
        cache: MemoryProductCache(),
        localProducts: [
          product(id: 'curd', name: 'Творог 5%'),
          product(id: 'dessert', name: 'Творожный десерт клубничный'),
          product(
            id: 'unrelated',
            name: 'Конфеты молочные',
            category: 'творог',
          ),
        ],
      );

      final result = await repository.search(
        'творог',
        online: false,
        searchContext: FoodSearchContext.recipeIngredient,
      );

      expect(result.items.first.id, 'curd');
      expect(result.items.map((item) => item.id), isNot(contains('unrelated')));
    },
  );

  test(
    'recipe ingredient ranking covers 50 realistic generic queries',
    () async {
      const cases = <(String, String, String)>[
        ('Картофель свежий', 'картофель', 'картофель свежий'),
        ('Морковь свежая', 'морковь', 'морковь свежая'),
        ('Лук репчатый', 'лук', 'лук репчатый'),
        ('Чеснок свежий', 'чеснок', 'чеснок свежий'),
        ('Рис сухой', 'рис', 'рис сухой'),
        ('Гречка сухая', 'гречка', 'гречка сухая'),
        ('Курица сырая', 'курица', 'курица сырая'),
        ('Куриная грудка', 'куриная грудка', 'грудка куриная'),
        ('Говядина сырая', 'говядина', 'говядина сырая'),
        ('Свинина сырая', 'свинина', 'свинина сырая'),
        ('Рыба белая', 'рыба', 'белая рыба'),
        ('Яйцо куриное', 'яйцо', 'яйцо куриное'),
        ('Молоко коровье', 'молоко', 'молоко коровье'),
        ('Масло сливочное', 'сливочное масло', 'масло сливочное'),
        ('Сыр твёрдый', 'сыр', 'твердый сыр'),
        ('Творог обычный', 'творог', 'творог обычный'),
        ('Мука пшеничная', 'мука', 'пшеничная мука'),
        ('Сахар белый', 'сахар', 'сахар белый'),
        ('Овсяные хлопья', 'овсяные хлопья', 'хлопья овсяные'),
        ('Помидор свежий', 'помидор', 'помидор свежий'),
        ('Огурец свежий', 'огурец', 'огурец свежий'),
        ('Яблоко свежее', 'яблоко', 'яблоко свежее'),
        ('Банан свежий', 'банан', 'банан свежий'),
        ('Кефир обычный', 'кефир', 'кефир обычный'),
        ('Капуста белокочанная', 'капуста', 'капуста белокочанная'),
      ];
      final foods = [
        for (var index = 0; index < cases.length; index++)
          product(id: 'ingredient-$index', name: cases[index].$1),
        product(
          id: 'dessert',
          name: 'Десерт Картошка шоколадный',
          category: 'Кондитерские изделия',
        ),
        product(
          id: 'branded-snack',
          name: 'Чипсы со вкусом курицы',
          category: 'Снеки',
        ),
      ];
      final repository = FoodCatalogRepository(
        cache: MemoryProductCache(),
        localProducts: foods,
      );

      for (var index = 0; index < cases.length; index++) {
        for (final query in [cases[index].$2, cases[index].$3]) {
          final result = await repository.search(
            query,
            online: false,
            searchContext: FoodSearchContext.recipeIngredient,
          );
          expect(result.items, isNotEmpty, reason: query);
          expect(result.items.first.id, 'ingredient-$index', reason: query);
          expect(
            result.items.map((item) => item.id),
            isNot(contains('dessert')),
          );
          expect(
            result.items.map((item) => item.id),
            isNot(contains('branded-snack')),
          );
          if (query == 'сыр') {
            expect(
              result.items.every(
                (item) => item.normalizedName.split(' ').contains('сыр'),
              ),
              isTrue,
            );
          }
        }
      }
    },
  );

  test('synthetic 50000-product offline search remains bounded', () async {
    final products = List.generate(
      50000,
      (index) => product(
        id: 'synthetic-$index',
        barcode: '${4600000000000 + index}',
        name: 'Synthetic food $index',
      ),
    );
    final repository = FoodCatalogRepository(
      cache: MemoryProductCache(),
      localProducts: products,
    );
    final stopwatch = Stopwatch()..start();
    final result = await repository.search(
      'Synthetic food 49999',
      online: false,
    );
    stopwatch.stop();
    expect(result.items.first.id, 'synthetic-49999');
    expect(result.items.length, lessThanOrEqualTo(30));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
  });
}
