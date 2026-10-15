import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/food_catalog.dart';
import '../models/food_models.dart';
import '../models/food_product.dart';
import '../models/product_retailer_relation.dart';
import '../utils/gtin.dart';
import 'food_search_service.dart';

enum ProductSort { relevance, recentlyUsed, name }

enum FoodSearchContext { diary, recipeIngredient }

abstract interface class ProductCache {
  Future<List<FoodProduct>> searchCandidates(
    String normalizedQuery, {
    required int limit,
    required int offset,
    required String category,
    bool browseAll = false,
    String? brand,
    bool onlyCompleteNutrition = false,
    bool onlyPhoto = false,
  });
  Future<FoodProduct?> read(String id);
  Future<FoodProduct?> findByBarcode(String barcode);
  Future<FoodProduct?> findMatching(FoodProduct product);
  Future<void> write(FoodProduct product);
  Future<Map<String, int>> usageCounts(Iterable<String> ids);
  Future<Map<String, bool>> favoriteStates(Iterable<String> ids);
  Future<void> markUsed(String id);
  Future<void> setFavorite(String id, bool favorite);
}

abstract interface class RetailerAwareProductCache {
  Future<List<FoodProduct>> searchRetailerCandidates(
    String normalizedQuery, {
    required String retailerSlug,
    required String taxonomyCategory,
    required int limit,
    required int offset,
    String? brand,
    bool onlyCompleteNutrition = false,
    bool onlyPhoto = false,
  });

  Future<void> saveRetailerRelation(ProductRetailerRelation relation);
}

class MemoryProductCache implements ProductCache {
  final Map<String, FoodProduct> products = {};
  final Map<String, int> usage = {};

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
    final prefix = normalizedQuery.length > 3
        ? normalizedQuery.substring(0, 3)
        : normalizedQuery;
    return products.values
        .where(
          (product) =>
              normalizedQuery.isEmpty ||
              foodProductSearchText(product).contains(normalizedQuery) ||
              (prefix.length >= 3 &&
                  foodProductSearchText(product).contains(prefix)),
        )
        .where(
          (product) =>
              brand == null ||
              normalizeFoodText(product.brand ?? '') ==
                  normalizeFoodText(brand),
        )
        .where(
          (product) => !onlyCompleteNutrition || product.hasCompleteNutrition,
        )
        .where((product) => !onlyPhoto || _hasPhoto(product))
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<FoodProduct?> findByBarcode(String barcode) async {
    for (final product in products.values) {
      if (product.barcode == barcode) return product;
    }
    return null;
  }

  @override
  Future<FoodProduct?> read(String id) async {
    for (final product in products.values) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<FoodProduct?> findMatching(FoodProduct incoming) async =>
      products[foodProductIdentity(incoming)];

  @override
  Future<void> write(FoodProduct product) async {
    products[foodProductIdentity(product)] = product;
  }

  @override
  Future<Map<String, int>> usageCounts(Iterable<String> ids) async => {
    for (final id in ids) id: usage[id] ?? 0,
  };

  @override
  Future<Map<String, bool>> favoriteStates(Iterable<String> ids) async {
    final wanted = ids.toSet();
    return {
      for (final product in products.values)
        if (wanted.contains(product.id)) product.id: product.favorite,
    };
  }

  @override
  Future<void> markUsed(String id) async => usage[id] = (usage[id] ?? 0) + 1;

  @override
  Future<void> setFavorite(String id, bool favorite) async {
    String? matchingKey;
    FoodProduct? matchingProduct;
    for (final entry in products.entries) {
      if (entry.value.id == id) {
        matchingKey = entry.key;
        matchingProduct = entry.value;
        break;
      }
    }
    if (matchingKey != null && matchingProduct != null) {
      products[matchingKey] = matchingProduct.withFavorite(favorite);
    }
  }
}

class FoodCatalogRepository {
  FoodCatalogRepository({
    required this.cache,
    List<FoodProductSourceAdapter>? sources,
    List<FoodProduct>? localProducts,
  }) : sources = sources ?? const [],
       localProducts = localProducts ?? legacyLocalProducts();

  final ProductCache cache;
  final List<FoodProductSourceAdapter> sources;
  final List<FoodProduct> localProducts;
  FoodSearchError? lastBarcodeLookupError;

  Future<FoodSearchOutcome> search(
    String query, {
    int limit = 30,
    int offset = 0,
    bool online = true,
    String category = 'all',
    String? retailer,
    String taxonomyCategory = 'all',
    ProductSort sort = ProductSort.relevance,
    bool onlyCompleteNutrition = false,
    bool onlyPhoto = false,
    String? brand,
    bool usableOnly = true,
    MealType? meal,
    FoodSearchContext searchContext = FoodSearchContext.diary,
  }) async {
    final normalized = normalizeFoodText(query);
    final retailerAware =
        retailer != null && cache is RetailerAwareProductCache;
    final cached = retailerAware
        ? await (cache as RetailerAwareProductCache).searchRetailerCandidates(
            normalized,
            retailerSlug: canonicalRetailerId(retailer),
            taxonomyCategory: taxonomyCategory == 'prepared'
                ? 'preparedFood'
                : taxonomyCategory,
            limit: limit,
            offset: offset,
            brand: brand,
            onlyCompleteNutrition: onlyCompleteNutrition,
            onlyPhoto: onlyPhoto,
          )
        : await cache.searchCandidates(
            normalized,
            limit: normalized.isEmpty ? limit + offset : max(200, limit * 4),
            offset: 0,
            category: category,
            browseAll: normalized.isEmpty || retailer != null,
            brand: brand,
            onlyCompleteNutrition: onlyCompleteNutrition,
            onlyPhoto: onlyPhoto,
          );
    var merged = _deduplicate([...localProducts, ...cached]);
    FoodSearchError? error;

    var fetchedItems = 0;
    var backendResults = 0;
    if (online && (normalized.length >= 2 || retailer != null)) {
      for (final source in sources) {
        final gtin = normalizeGtin(normalized);
        final outcome = gtin != null
            ? FoodSearchOutcome([
                if (await source.findByBarcode(gtin) case final found?) found,
              ])
            : normalized.length >= 2
            ? await source.search(query, limit: limit)
            : retailer != null && source is RetailerBrowseSource
            ? await (source as RetailerBrowseSource).browseRetailer(
                retailer,
                taxonomy: taxonomyCategory == 'prepared'
                    ? 'preparedFood'
                    : taxonomyCategory,
                limit: limit < 50 ? 50 : limit,
              )
            : const FoodSearchOutcome([]);
        error ??= outcome.error;
        fetchedItems += outcome.items.length;
        if (source is CentralCatalogSource) {
          backendResults += outcome.items.length;
        }
        for (final product in outcome.items) {
          await _cacheMerged(product);
        }
        merged = _deduplicate([...merged, ...outcome.items]);
      }
    }

    final favoriteStates = await cache.favoriteStates(
      merged.map((product) => product.id),
    );
    merged = _applyCachedFavoriteState(merged, favoriteStates);

    final usage = await cache.usageCounts(merged.map((product) => product.id));
    final scored = <(FoodProduct, int)>[];
    var retailerMatches = 0;
    var taxonomyMatches = 0;
    var usableMatches = 0;
    for (final product in merged) {
      if (!_matchesCategory(product, category)) continue;
      if (retailer != null && !_matchesRetailer(product, retailer)) continue;
      retailerMatches++;
      final requestedTaxonomy = taxonomyCategory == 'prepared'
          ? 'preparedFood'
          : taxonomyCategory;
      if (requestedTaxonomy != 'all' &&
          catalogTaxonomyOf(product) != requestedTaxonomy) {
        continue;
      }
      taxonomyMatches++;
      if (usableOnly && !isUsableCatalogProduct(product)) continue;
      usableMatches++;
      if (onlyCompleteNutrition && !product.hasCompleteNutrition) continue;
      if (onlyPhoto && !_hasPhoto(product)) continue;
      if (brand != null &&
          normalizeFoodText(product.brand ?? '') != normalizeFoodText(brand)) {
        continue;
      }
      final score =
          _score(product, normalized, usage[product.id] ?? 0) +
          (meal == null ? 0 : mealAffinityScore(product, meal)) +
          (searchContext == FoodSearchContext.recipeIngredient
              ? _ingredientSearchScore(product, normalized)
              : 0);
      final threshold =
          searchContext == FoodSearchContext.recipeIngredient &&
              normalized.isNotEmpty
          ? 3000
          : 1;
      if (normalized.isEmpty || score >= threshold) {
        scored.add((product, score));
      }
    }
    scored.sort((a, b) {
      final result = switch (sort) {
        ProductSort.relevance => b.$2.compareTo(a.$2),
        ProductSort.recentlyUsed => (usage[b.$1.id] ?? 0).compareTo(
          usage[a.$1.id] ?? 0,
        ),
        ProductSort.name => a.$1.name.compareTo(b.$1.name),
      };
      return result != 0 ? result : a.$1.name.compareTo(b.$1.name);
    });
    assert(() {
      if (retailer != null) {
        debugPrint(
          '[food-search] retailer=$retailer local=${localProducts.length} '
          'sqlite=${cached.length} merged=${merged.length} '
          'backendResults=$backendResults fetched=$fetchedItems '
          'retailerMatches=$retailerMatches taxonomy=$taxonomyCategory:'
          '$taxonomyMatches '
          'usable=$usableMatches final=${scored.length}',
        );
      }
      final top = scored.take(10).map((item) {
        if (searchContext != FoodSearchContext.recipeIngredient) {
          return '${item.$2}:${item.$1.name}';
        }
        final tokens = normalized
            .split(' ')
            .where(item.$1.normalizedName.contains)
            .join(',');
        return 'candidate=${item.$1.name};score=${item.$2};'
            'type=${item.$1.source.name};matchedTokens=$tokens;'
            'category=${item.$1.category ?? item.$1.localCategory}';
      });
      if (retailer != null || normalized.contains('картоф')) {
        debugPrint(
          '[food-search] context=${searchContext.name} query="$normalized" '
          'top10=${top.join(' | ')}',
        );
      }
      return true;
    }());
    return FoodSearchOutcome(
      scored
          .skip(retailerAware ? 0 : max(0, offset))
          .take(limit.clamp(1, 50000))
          .map((e) => e.$1)
          .toList(),
      error: error,
    );
  }

  Future<FoodProduct?> findByBarcode(String barcode) async {
    lastBarcodeLookupError = null;
    final normalized = normalizeGtin(barcode);
    if (normalized == null) return null;
    for (final product in localProducts) {
      if (product.barcode == normalized) return product;
    }
    final cached = await cache.findByBarcode(normalized);
    final fetchedAt = cached?.lastFetchedAt ?? cached?.lastUpdatedAt;
    final fresh =
        fetchedAt != null &&
        DateTime.now().toUtc().difference(fetchedAt).inDays < 30;
    if (cached != null && fresh) return cached;
    for (final source in sources) {
      final found = await source.findByBarcode(normalized);
      if (found != null) {
        await _cacheMerged(found);
        return await cache.read(found.id) ?? found;
      }
      lastBarcodeLookupError ??= source.lastBarcodeError;
    }
    return cached;
  }

  Future<void> saveManual(FoodProduct product) async {
    if (product.source != FoodProductSource.manual) {
      throw const FormatException('Manual product must have manual source');
    }
    await _cacheMerged(product);
  }

  Future<void> markUsed(FoodProduct product) => cache.markUsed(product.id);

  Future<void> setFavorite(FoodProduct product, bool favorite) async {
    await cache.write(product);
    await cache.setFavorite(product.id, favorite);
  }

  Future<int> useCount(FoodProduct product) async =>
      (await cache.usageCounts([product.id]))[product.id] ?? 0;

  Future<void> rememberRetailer(
    FoodProduct product,
    String retailerSlug, {
    RetailerRelationSource source = RetailerRelationSource.userScan,
    bool userConfirmed = false,
  }) async {
    final selectedCache = cache;
    if (selectedCache is! RetailerAwareProductCache) return;
    await (selectedCache as RetailerAwareProductCache).saveRetailerRelation(
      ProductRetailerRelation(
        productId: product.id,
        retailerSlug: canonicalRetailerId(retailerSlug),
        source: source,
        confidence: userConfirmed ? 1 : 0.95,
        userConfirmed: userConfirmed,
      ),
    );
  }

  Future<void> _cacheMerged(FoodProduct incoming) async {
    final existing = await cache.findMatching(incoming);
    await cache.write(
      existing == null
          ? incoming
          : mergeProducts(existing, incoming).withFavorite(existing.favorite),
    );
  }

  List<FoodProduct> _applyCachedFavoriteState(
    Iterable<FoodProduct> products,
    Map<String, bool> favorites,
  ) {
    return [
      for (final product in products)
        favorites.containsKey(product.id)
            ? product.withFavorite(favorites[product.id]!)
            : product,
    ];
  }

  List<FoodProduct> _deduplicate(Iterable<FoodProduct> products) {
    final result = <String, FoodProduct>{};
    for (final product in products) {
      final key = foodProductIdentity(product);
      result[key] = result[key] == null
          ? product
          : mergeProducts(result[key]!, product);
    }
    return result.values.toList();
  }

  int _score(FoodProduct product, String query, int useCount) {
    if (query.isEmpty) {
      return (product.favorite ? 1000 : 0) + useCount * 100;
    }
    if (product.barcode == query) return 100000;
    final name = product.normalizedName;
    final brand = normalizeFoodText(product.brand ?? '');
    final category = normalizeFoodText(product.category ?? '');
    final retailers = normalizeFoodText(product.retailerTags.join(' '));
    final queryTokens = query.split(' ').where((token) => token.isNotEmpty);
    final contentTokens = '$name $brand'.split(' ');
    final directContentMatch =
        name.contains(query) ||
        brand.contains(query) ||
        queryTokens.every(
          (token) => contentTokens.any(
            (word) =>
                word.startsWith(token) ||
                (token.length >= 5 && _editDistanceAtMostTwo(word, token)),
          ),
        );
    final semanticCategory = _semanticCategoryQuery(query);
    if (!directContentMatch &&
        (semanticCategory == null ||
            catalogTaxonomyOf(product) != semanticCategory)) {
      return -10000;
    }
    var score = 0;
    if (name == query) score += 20000;
    if (name.startsWith(query)) score += 12000;
    if (name.contains(query)) score += 8000;
    if (brand == query) score += 7000;
    if ('$name $brand $category $retailers'.contains(query)) score += 4000;
    final haystackTokens = '$name $brand $category $retailers'.split(' ');
    for (final token in queryTokens) {
      if (haystackTokens.any((word) => word.startsWith(token))) {
        score += 1200;
      } else if (haystackTokens.any(
        (word) => _editDistanceAtMostTwo(word, token),
      )) {
        score += 400;
      }
    }
    score += min(2000, useCount * 250);
    score += switch (product.dataQuality) {
      FoodDataQuality.verified => 1500,
      FoodDataQuality.good => 1000,
      FoodDataQuality.partial => 300,
      FoodDataQuality.unverified => 0,
    };
    if (product.nutritionVerified) score += 300;
    if (product.hasCompleteNutrition) score += 700;
    if (product.needsReview) score -= 1200;
    return score;
  }

  int _ingredientSearchScore(FoodProduct product, String query) {
    if (query.isEmpty) return 0;
    final name = product.normalizedName;
    final category = normalizeFoodText(product.category ?? '');
    final directNameMatch =
        name.contains(query) ||
        query
            .split(' ')
            .every(
              (token) => name.split(' ').any((word) => word.startsWith(token)),
            );
    var score = directNameMatch ? 4500 : -9000;

    const genericStems = [
      'картоф',
      'морков',
      'лук',
      'чеснок',
      'рис',
      'греч',
      'куриц',
      'курин',
      'говядин',
      'свинин',
      'рыб',
      'яйц',
      'молок',
      'масл',
      'сыр',
      'творог',
      'мук',
      'сахар',
    ];
    final generic = genericStems.any(query.contains);
    if (generic && directNameMatch) {
      score += name.split(' ').length <= 3 ? 3000 : 800;
      if (product.brand != null) score -= 1800;
      if (const [
        'сыр',
        'сырой',
        'отвар',
        'варен',
        'запеч',
      ].any(name.contains)) {
        score += 900;
      }
    }

    if (query.contains('картоф')) {
      if (!name.contains('картоф')) return -20000;
      if (name == 'картофель' || name == 'картошка') {
        score += 12000;
      } else if (name.contains('сыр') || name.contains('raw')) {
        score += 10000;
      } else if (name.contains('варен') || name.contains('отвар')) {
        score += 8500;
      } else if (name.contains('запеч')) {
        score += 7200;
      } else if (name.contains('пюре')) {
        score += 6000;
      } else if (name.contains('фри')) {
        score += 4200;
      }
      if (name.contains('чипс')) score -= 18000;
    }
    if (query.contains('творог')) {
      if (!name.contains('творог')) return -20000;
      score += 9000;
      if (name.contains('сырок') || name.contains('глазир')) score -= 7000;
    }
    if (query.split(' ').contains('сыр') && !name.split(' ').contains('сыр')) {
      return -20000;
    }

    final snackLike = '$name $category';
    for (final term in const [
      'чипс',
      'конфет',
      'шоколад',
      'десерт',
      'сладост',
      'snack',
      'candy',
    ]) {
      if (snackLike.contains(term)) score -= 6500;
    }
    if (product.brand != null && !name.startsWith(query)) score -= 700;
    return score;
  }

  bool _matchesCategory(FoodProduct product, String category) =>
      category == 'all' ||
      (category == 'favorite' && product.favorite) ||
      product.localCategory == category;

  bool _matchesRetailer(FoodProduct product, String retailer) {
    final wanted = canonicalRetailerId(retailer);
    return product.retailerTags.any(
      (tag) => canonicalRetailerId(tag) == wanted,
    );
  }
}

String? _semanticCategoryQuery(String query) {
  if (query.contains('молоч') ||
      query.contains('молок') ||
      query.contains('творог') ||
      query.contains('кефир') ||
      query.contains('йогурт') ||
      query == 'сыр') {
    return 'dairy';
  }
  if (query.contains('напит') || query == 'вода') return 'drinks';
  if (query.contains('хлеб')) return 'bread';
  if (query.contains('булоч') || query.contains('выпеч')) return 'hotBakery';
  if (query.contains('шоколад') || query.contains('печень')) return 'sweets';
  if (query.contains('макарон')) return 'grains';
  if (query.contains('куриц') || query.contains('колбас')) return 'meat';
  return null;
}

bool _hasPhoto(FoodProduct product) =>
    (product.imageUrl?.trim().isNotEmpty ?? false) ||
    (product.localImagePath?.trim().isNotEmpty ?? false);

bool isUsableCatalogProduct(FoodProduct product) {
  final calories = product.nutrition.calories;
  return product.nutritionBasisAmount.isFinite &&
      product.nutritionBasisAmount > 0 &&
      calories != null &&
      calories.isFinite &&
      calories >= 0;
}

String canonicalRetailerId(String value) {
  final normalized = normalizeFoodText(value).replaceAll(' ', '');
  if (normalized.contains('пятер') || normalized.contains('pyater')) {
    return 'pyaterochka';
  }
  if (normalized.contains('перекрест') || normalized.contains('perekrest')) {
    return 'perekrestok';
  }
  if (normalized.contains('вкусвилл') || normalized.contains('vkusvill')) {
    return 'vkusvill';
  }
  if (normalized.contains('fixprice') || normalized.contains('фиксцен')) {
    return 'fix_price';
  }
  if (normalized.contains('победа') || normalized.contains('pobeda')) {
    return 'pobeda';
  }
  if (normalized.contains('магнит') || normalized.contains('magnit')) {
    return 'magnit';
  }
  return normalized;
}

String catalogTaxonomyOf(FoodProduct product) {
  final name = normalizeFoodText(product.name);
  if (name.contains('козинак') ||
      name.contains('халва') ||
      name.contains('арахисовая паста')) {
    return 'sweets';
  }
  final value = normalizeFoodText(
    '${product.name} ${product.category ?? ''} ${product.subcategory ?? ''} ${product.localCategory}',
  );
  if ((value.contains('горяч') &&
          (value.contains('выпеч') || value.contains('пекар'))) ||
      value.contains('hot bakery') ||
      value.contains('fresh bakery') ||
      value.contains('bakery') ||
      value.contains('pastry') ||
      value.contains('croissant') ||
      value.contains('buns') ||
      value.contains('pies') ||
      value.contains('свежая выпечка') ||
      value.contains('круассан') ||
      value.contains('слойк') ||
      value.contains('пирожок') ||
      value.contains('булочк') ||
      value.contains('пицца слайс')) {
    return 'hotBakery';
  }
  if (value.contains('готов') ||
      value.contains('prepared') ||
      value.contains('ready meal') ||
      value.contains('ready meals') ||
      value.contains('prepared dish') ||
      value.contains('cooked food') ||
      value.contains('culinary') ||
      value.contains('salad') ||
      value.contains('soup') ||
      value.contains('sandwich') ||
      value.contains('салат') ||
      value.contains('суп') ||
      value.contains('сэндвич') ||
      value.contains('сендвич') ||
      value.contains('ролл')) {
    return 'preparedFood';
  }
  if (value.contains('молоч') ||
      value.contains('dairy') ||
      value.contains('творог') ||
      value.contains('йогурт') ||
      value.contains('кефир')) {
    return 'dairy';
  }
  if (value.contains('хлеб') || value.contains('bread')) return 'bread';
  if (value.contains('мяс') || value.contains('meat')) return 'meat';
  if (value.contains('рыб') || value.contains('fish')) return 'fish';
  if (value.contains('замор') || value.contains('frozen')) return 'frozen';
  if (value.contains('напит') ||
      value.contains('drink') ||
      value.contains('beverage') ||
      value.contains('вода')) {
    return 'drinks';
  }
  if (value.contains('слад') ||
      value.contains('dessert') ||
      value.contains('шоколад')) {
    return 'sweets';
  }
  if (value.contains('снек') || value.contains('snack')) return 'snacks';
  if (value.contains('соус') || value.contains('sauce')) return 'sauces';
  if (value.contains('круп') ||
      value.contains('grain') ||
      value.contains('макарон') ||
      value.contains('pasta')) {
    return 'grains';
  }
  if (value.contains('консерв') || value.contains('canned')) return 'canned';
  if (value.contains('завтрак') ||
      value.contains('breakfast') ||
      value.contains('cereal')) {
    return 'breakfast';
  }
  return 'other';
}

/// A soft preference used only for ordering. It never removes products.
int mealAffinityScore(FoodProduct product, MealType meal) {
  final value = normalizeFoodText(
    '${product.name} ${product.category ?? ''} ${product.subcategory ?? ''} ${product.localCategory}',
  );
  final terms = switch (meal) {
    MealType.breakfast => const [
      'каш',
      'яйц',
      'омлет',
      'йогурт',
      'творог',
      'сырник',
      'блин',
      'хлеб',
      'тост',
      'breakfast',
    ],
    MealType.lunch => const ['суп', 'готов', 'мяс', 'гарнир', 'салат', 'lunch'],
    MealType.dinner => const [
      'мяс',
      'рыб',
      'кур',
      'индей',
      'овощ',
      'гарнир',
      'легк',
      'dinner',
    ],
    MealType.snack => const [
      'фрукт',
      'яблок',
      'банан',
      'йогурт',
      'снек',
      'десерт',
      'орех',
      'snack',
    ],
  };
  var matches = 0;
  for (final term in terms) {
    if (value.contains(term)) matches++;
  }
  return matches * 2200;
}

FoodProduct mergeProducts(FoodProduct first, FoodProduct second) {
  if (foodProductIdentity(first) != foodProductIdentity(second)) {
    throw const FormatException('Cannot merge different products');
  }
  final firstWins = foodSourcePriority(first) >= foodSourcePriority(second);
  final preferred = firstWins ? first : second;
  final fallback = firstWins ? second : first;
  final nutritionConflict = _nutritionConflict(
    first.nutrition,
    second.nutrition,
  );
  return FoodProduct(
    id: preferred.id,
    barcode: preferred.barcode ?? fallback.barcode,
    name: preferred.name,
    normalizedName: preferred.normalizedName,
    brand: preferred.brand ?? fallback.brand,
    retailerTags: {...first.retailerTags, ...second.retailerTags}.toList()
      ..sort(),
    category: preferred.category ?? fallback.category,
    subcategory: preferred.subcategory ?? fallback.subcategory,
    packageAmount: preferred.packageAmount ?? fallback.packageAmount,
    packageUnit: preferred.packageUnit ?? fallback.packageUnit,
    netWeightGrams: preferred.netWeightGrams ?? fallback.netWeightGrams,
    netVolumeMl: preferred.netVolumeMl ?? fallback.netVolumeMl,
    servingSize: preferred.servingSize ?? fallback.servingSize,
    servingUnit: preferred.servingUnit ?? fallback.servingUnit,
    nutritionBasis: preferred.nutritionBasis,
    nutritionBasisAmount: preferred.nutritionBasisAmount,
    nutrition: preferred.nutrition.isEmpty
        ? fallback.nutrition
        : preferred.nutrition,
    ingredients: preferred.ingredients ?? fallback.ingredients,
    imageUrl: preferred.imageUrl ?? fallback.imageUrl,
    localImagePath: preferred.localImagePath ?? fallback.localImagePath,
    source: preferred.source,
    sourceProductId: preferred.sourceProductId ?? fallback.sourceProductId,
    sourceUrl: preferred.sourceUrl ?? fallback.sourceUrl,
    nutritionSource: preferred.nutrition.isEmpty
        ? fallback.nutritionSource
        : preferred.nutritionSource,
    nutritionVerified: preferred.nutrition.isEmpty
        ? fallback.nutritionVerified
        : preferred.nutritionVerified,
    dataQuality: preferred.dataQuality,
    imageLicense: preferred.imageLicense ?? fallback.imageLicense,
    imageAttribution: preferred.imageAttribution ?? fallback.imageAttribution,
    lastUpdatedAt: first.lastUpdatedAt.isAfter(second.lastUpdatedAt)
        ? first.lastUpdatedAt
        : second.lastUpdatedAt,
    lastFetchedAt: preferred.lastFetchedAt ?? fallback.lastFetchedAt,
    lastVerifiedAt: preferred.lastVerifiedAt ?? fallback.lastVerifiedAt,
    sourceRevision: preferred.sourceRevision ?? fallback.sourceRevision,
    needsReview: first.needsReview || second.needsReview || nutritionConflict,
    favorite: first.favorite || second.favorite,
    localCategory: preferred.localCategory,
    colorSeed: preferred.colorSeed,
  );
}

List<FoodProduct> legacyLocalProducts() => [
  for (var index = 0; index < kFoodCatalog.length; index++)
    _legacyProduct(kFoodCatalog[index], index),
];

FoodProduct _legacyProduct(FoodCatalogItem item, int index) => FoodProduct(
  id: 'local:$index:${normalizeFoodText(item.name)}',
  name: item.name,
  nutrition: NutritionValues(
    calories: item.kcalPer100g.toDouble(),
    protein: item.proteinPer100g,
    fat: item.fatPer100g,
    carbs: item.carbsPer100g,
  ),
  source: FoodProductSource.verifiedCatalog,
  nutritionSource: FoodProductSource.verifiedCatalog,
  nutritionVerified: false,
  favorite: item.favorite,
  localCategory: item.category,
  colorSeed: item.colorSeed,
);

String foodProductIdentity(FoodProduct product) {
  if (product.barcode != null) return 'barcode:${product.barcode}';
  if (product.sourceProductId?.trim().isNotEmpty ?? false) {
    return 'source:${product.source.name}:${product.sourceProductId}';
  }
  return 'name:${product.normalizedName}|${normalizeFoodText(product.brand ?? '')}|'
      '${product.packageAmount ?? ''}|${product.packageUnit ?? ''}';
}

String foodProductSearchText(FoodProduct product) => normalizeFoodText(
  [
    product.name,
    if (product.brand != null) product.brand!,
    if (product.category != null) product.category!,
    ...product.retailerTags,
  ].join(' '),
);

bool _nutritionConflict(NutritionValues a, NutritionValues b) {
  bool differs(double? left, double? right) =>
      left != null &&
      right != null &&
      (left - right).abs() > max(5, left * 0.15);
  return differs(a.calories, b.calories) ||
      differs(a.protein, b.protein) ||
      differs(a.fat, b.fat) ||
      differs(a.carbs, b.carbs);
}

bool _editDistanceAtMostTwo(String a, String b) {
  if ((a.length - b.length).abs() > 2) return false;
  if (a == b) return true;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = <int>[i];
    var rowMinimum = i;
    for (var j = 1; j <= b.length; j++) {
      final value = min(
        min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + (a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1),
      );
      current.add(value);
      rowMinimum = min(rowMinimum, value);
    }
    if (rowMinimum > 2) return false;
    previous = current;
  }
  return previous.last <= 2;
}
