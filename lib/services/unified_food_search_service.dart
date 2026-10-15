import '../models/dish.dart';
import '../models/food_models.dart';
import '../models/food_product.dart';
import '../models/recipe_models.dart';
import '../models/unified_food_item.dart';
import 'dish_catalog_repository.dart';
import 'food_catalog_repository.dart';
import 'food_search_service.dart';

class UnifiedFoodSearchOutcome {
  final List<UnifiedFoodItem> items;
  final FoodSearchError? productSearchError;

  const UnifiedFoodSearchOutcome(this.items, {this.productSearchError});
}

class UnifiedFoodSearchService {
  const UnifiedFoodSearchService({
    required this.products,
    required this.dishes,
    required this.recipes,
    required this.recipeUsageCount,
  });

  final FoodCatalogRepository products;
  final DishCatalogRepository dishes;
  final List<UserRecipe> Function() recipes;
  final int Function(String id) recipeUsageCount;

  Future<UnifiedFoodItem?> findByBarcode(String barcode) async {
    final product = await products.findByBarcode(barcode);
    return product == null ? null : UnifiedFoodItem.fromProduct(product);
  }

  Future<UnifiedFoodSearchOutcome> search(
    String query, {
    int limit = 30,
    bool online = true,
    String category = 'all',
    String? retailer,
    String taxonomyCategory = 'all',
    ProductSort sort = ProductSort.relevance,
    bool onlyCompleteNutrition = false,
    bool onlyPhoto = false,
    String? brand,
    MealType? meal,
  }) async {
    final normalized = normalizeFoodText(query);
    final results = await Future.wait<Object>([
      products.search(
        query,
        limit: limit,
        online: online,
        category: category,
        retailer: retailer,
        taxonomyCategory: taxonomyCategory,
        sort: sort,
        onlyCompleteNutrition: onlyCompleteNutrition,
        onlyPhoto: onlyPhoto,
        brand: brand,
        meal: meal,
      ),
      dishes.search(query, limit: limit, favoritesOnly: category == 'favorite'),
    ]);
    final productOutcome = results[0] as FoodSearchOutcome;
    final dishItems = results[1] as List<Dish>;
    final recipeItems = recipes().where((recipe) {
      if (retailer != null || brand != null || onlyPhoto) return false;
      if (category == 'favorite' && !recipe.favorite) return false;
      if (category == 'recent' && recipeUsageCount(recipe.id) == 0) {
        return false;
      }
      if (normalized.isEmpty) {
        return recipe.favorite || recipeUsageCount(recipe.id) > 0;
      }
      return recipe.normalizedName.contains(normalized) ||
          (recipe.category != null &&
              normalizeFoodText(recipe.category!).contains(normalized));
    });
    final items = <UnifiedFoodItem>[
      ...productOutcome.items.map(UnifiedFoodItem.fromProduct),
      if (retailer == null && brand == null && !onlyPhoto)
        ...dishItems.map(UnifiedFoodItem.fromDish),
      ...recipeItems.map(UnifiedFoodItem.fromRecipe),
    ].where((item) => item.isUsableForDiary).toList();
    if (sort == ProductSort.relevance) {
      items.sort(
        (a, b) =>
            _score(b, normalized, meal).compareTo(_score(a, normalized, meal)),
      );
    }
    return UnifiedFoodSearchOutcome(
      items.take(limit).toList(),
      productSearchError: productOutcome.error,
    );
  }

  int _score(UnifiedFoodItem item, String query, MealType? meal) {
    final name = normalizeFoodText(item.name);
    var score = switch (item.type) {
      UnifiedFoodType.product ||
      UnifiedFoodType.restaurantProduct ||
      UnifiedFoodType.preparedRetailProduct => 8000,
      UnifiedFoodType.userRecipe => 10000 + recipeUsageCount(item.id) * 700,
      UnifiedFoodType.genericDish => 5000,
    };
    if (item.favorite) score += 1800;
    score += item.dataQualityRank * 450;
    if (item.hasCompleteNutrition) score += 900;
    if (item.product?.nutritionVerified == true) score += 500;
    if (item.product?.needsReview == true) score -= 1600;
    if (query.isNotEmpty && name == query) score += 6000;
    if (query.isNotEmpty && name.startsWith(query)) score += 2500;
    if (meal != null) {
      final product = item.product;
      score += product == null
          ? _mealTextAffinity(
              '$name ${item.recipe?.category ?? ''} ${item.dish?.category ?? ''}',
              meal,
            )
          : mealAffinityScore(product, meal);
    }
    return score;
  }

  int _mealTextAffinity(String value, MealType meal) {
    final proxy = FoodProduct(
      id: 'ranking-only',
      name: value,
      source: FoodProductSource.manual,
    );
    return mealAffinityScore(proxy, meal);
  }
}
