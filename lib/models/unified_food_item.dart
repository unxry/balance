import 'dart:typed_data';

import 'dish.dart';
import 'food_models.dart';
import 'food_product.dart';
import 'recipe_models.dart';

enum UnifiedFoodType {
  product,
  restaurantProduct,
  preparedRetailProduct,
  genericDish,
  userRecipe,
}

class UnifiedFoodItem {
  final UnifiedFoodType type;
  final String id;
  final String name;
  final NutritionValues nutrition;
  final double nutritionBasisAmount;
  final double suggestedAmount;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String labelRu;
  final String labelEn;
  final bool estimated;
  final bool favorite;
  final int colorSeed;
  final FoodProduct? product;
  final Dish? dish;
  final UserRecipe? recipe;

  const UnifiedFoodItem({
    required this.type,
    required this.id,
    required this.name,
    required this.nutrition,
    required this.nutritionBasisAmount,
    required this.suggestedAmount,
    this.imageUrl,
    this.imageBytes,
    required this.labelRu,
    required this.labelEn,
    this.estimated = false,
    this.favorite = false,
    required this.colorSeed,
    this.product,
    this.dish,
    this.recipe,
  });

  bool get hasCompleteNutrition => nutrition.isComplete;
  bool get isUsableForDiary {
    final calories = nutrition.calories;
    return nutritionBasisAmount.isFinite &&
        nutritionBasisAmount > 0 &&
        calories != null &&
        calories.isFinite &&
        calories >= 0;
  }

  int get dataQualityRank {
    final value = product;
    if (value == null) return hasCompleteNutrition ? 4 : 2;
    if (value.needsReview) return 0;
    return switch (value.dataQuality) {
      FoodDataQuality.verified => 5,
      FoodDataQuality.good => 4,
      FoodDataQuality.partial => 2,
      FoodDataQuality.unverified => 1,
    };
  }

  double get proteinPer100g => nutrition.protein ?? 0;
  double get fatPer100g => nutrition.fat ?? 0;
  double get carbsPer100g => nutrition.carbs ?? 0;

  NutritionValues nutritionForAmount(double amount) {
    if (!amount.isFinite || amount <= 0) {
      throw const FormatException('Amount must be positive');
    }
    return nutrition.scale(amount / nutritionBasisAmount);
  }

  FoodEntrySourceType get diarySourceType => switch (type) {
    UnifiedFoodType.restaurantProduct => FoodEntrySourceType.restaurantProduct,
    UnifiedFoodType.preparedRetailProduct =>
      FoodEntrySourceType.preparedRetailProduct,
    UnifiedFoodType.genericDish => FoodEntrySourceType.genericDish,
    UnifiedFoodType.userRecipe => FoodEntrySourceType.userRecipe,
    UnifiedFoodType.product => FoodEntrySourceType.packagedProduct,
  };

  String? get sourceRevision =>
      recipe?.currentVersion.version.toString() ?? product?.sourceRevision;

  factory UnifiedFoodItem.fromProduct(FoodProduct product) {
    final isRestaurant = product.source == FoodProductSource.restaurantMenu;
    final retailer = product.retailerTags.isEmpty
        ? null
        : _retailerTitle(product.retailerTags.first);
    final category = _categoryTitle(product.category ?? product.subcategory);
    final prepared =
        !isRestaurant &&
        (product.category?.toLowerCase().contains('готов') ?? false);
    final type = isRestaurant
        ? UnifiedFoodType.restaurantProduct
        : prepared
        ? UnifiedFoodType.preparedRetailProduct
        : UnifiedFoodType.product;
    return UnifiedFoodItem(
      type: type,
      id: product.id,
      name: product.name,
      nutrition: product.nutrition,
      nutritionBasisAmount: product.nutritionBasisAmount,
      suggestedAmount: product.nutritionBasis == FoodNutritionBasis.perItem
          ? 1
          : product.servingSize ?? product.netWeightGrams ?? 100,
      imageUrl: product.imageUrl,
      labelRu: isRestaurant
          ? '${product.brand ?? 'Ресторан'} · Ресторан'
          : retailer != null
          ? '$retailer · $category'
          : prepared
          ? '${product.brand ?? 'Магазин'} · Готовый продукт'
          : product.brand ?? 'Продукт',
      labelEn: isRestaurant
          ? 'Restaurant'
          : prepared
          ? 'Prepared product'
          : 'Product',
      favorite: product.favorite,
      colorSeed: product.colorSeed,
      product: product,
    );
  }

  factory UnifiedFoodItem.fromDish(Dish dish) => UnifiedFoodItem(
    type: UnifiedFoodType.genericDish,
    id: dish.id,
    name: dish.name,
    nutrition: dish.nutritionPer100g,
    nutritionBasisAmount: 100,
    suggestedAmount: dish.typicalServingGrams,
    imageUrl: dish.imageUrl,
    labelRu: '≈ Типовое блюдо',
    labelEn: '≈ Typical dish',
    estimated: dish.isEstimated,
    favorite: dish.favorite,
    colorSeed: dish.id.hashCode,
    dish: dish,
  );

  factory UnifiedFoodItem.fromRecipe(UserRecipe recipe) => UnifiedFoodItem(
    type: UnifiedFoodType.userRecipe,
    id: recipe.id,
    name: recipe.name,
    nutrition: recipe.currentVersion.nutritionPer100g,
    nutritionBasisAmount: 100,
    suggestedAmount: recipe.currentVersion.gramsPerPortion ?? 100,
    imageBytes: recipe.imageBytes,
    labelRu: '★ Мой рецепт',
    labelEn: '★ My recipe',
    favorite: recipe.favorite,
    colorSeed: recipe.id.hashCode,
    recipe: recipe,
  );
}

String _retailerTitle(String value) {
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  if (normalized.contains('pyater') || normalized.contains('пятер')) {
    return 'Пятёрочка';
  }
  if (normalized.contains('magnit') || normalized.contains('магнит')) {
    return 'Магнит';
  }
  if (normalized.contains('perekrest') || normalized.contains('перекрест')) {
    return 'Перекрёсток';
  }
  if (normalized.contains('vkusvill') || normalized.contains('вкусвилл')) {
    return 'ВкусВилл';
  }
  if (normalized.contains('pobeda') || normalized.contains('победа')) {
    return 'ПОБЕДА';
  }
  if (normalized.contains('fixprice') || normalized.contains('фиксцен')) {
    return 'Fix Price';
  }
  return value;
}

String _categoryTitle(String? value) {
  final normalized = value?.toLowerCase() ?? '';
  if (normalized.contains('горяч') && normalized.contains('выпеч')) {
    return 'горячая выпечка';
  }
  if (normalized.contains('готов')) return 'готовая еда';
  return value?.trim().isNotEmpty == true ? value!.trim() : 'продукт';
}
