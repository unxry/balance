import 'food_product.dart';

enum DishCuisine {
  russian,
  ukrainian,
  georgian,
  armenian,
  uzbek,
  italian,
  french,
  american,
  mexican,
  japanese,
  korean,
  chinese,
  thai,
  vietnamese,
  indian,
  turkish,
  greek,
  middleEastern,
  european,
  other,
}

enum DishCategory {
  soups,
  mainCourses,
  sideDishes,
  salads,
  breakfast,
  snacks,
  bakery,
  desserts,
  drinks,
  sauces,
}

enum DishDataQuality { curatedEstimate, importedEstimate, needsReview }

class Dish {
  final String id;
  final String name;
  final String normalizedName;
  final DishCuisine cuisine;
  final DishCategory category;
  final String? subcategory;
  final String? variant;
  final NutritionValues nutritionPer100g;
  final double typicalServingGrams;
  final String dataSource;
  final DishDataQuality dataQuality;
  final bool isEstimated;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool favorite;

  Dish({
    required this.id,
    required this.name,
    String? normalizedName,
    required this.cuisine,
    required this.category,
    this.subcategory,
    this.variant,
    required this.nutritionPer100g,
    this.typicalServingGrams = 250,
    required this.dataSource,
    this.dataQuality = DishDataQuality.curatedEstimate,
    this.isEstimated = true,
    this.imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.favorite = false,
  }) : normalizedName = normalizedName ?? normalizeFoodText(name),
       createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? DateTime.now().toUtc() {
    if (id.trim().isEmpty || name.trim().isEmpty || dataSource.trim().isEmpty) {
      throw const FormatException('Invalid dish');
    }
    final nutrition = [
      nutritionPer100g.calories,
      nutritionPer100g.protein,
      nutritionPer100g.fat,
      nutritionPer100g.carbs,
    ];
    if (!nutritionPer100g.isComplete ||
        nutrition.any(
          (value) => value == null || !value.isFinite || value < 0,
        ) ||
        !typicalServingGrams.isFinite ||
        typicalServingGrams <= 0) {
      throw const FormatException('Dish nutrition and serving are required');
    }
  }

  NutritionValues nutritionForGrams(double grams) {
    if (!grams.isFinite || grams <= 0) {
      throw const FormatException('Invalid dish amount');
    }
    return nutritionPer100g.scale(grams / 100);
  }

  Dish copyWith({bool? favorite}) => Dish(
    id: id,
    name: name,
    normalizedName: normalizedName,
    cuisine: cuisine,
    category: category,
    subcategory: subcategory,
    variant: variant,
    nutritionPer100g: nutritionPer100g,
    typicalServingGrams: typicalServingGrams,
    dataSource: dataSource,
    dataQuality: dataQuality,
    isEstimated: isEstimated,
    imageUrl: imageUrl,
    createdAt: createdAt,
    updatedAt: updatedAt,
    favorite: favorite ?? this.favorite,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'normalizedName': normalizedName,
    'cuisine': cuisine.name,
    'category': category.name,
    'subcategory': subcategory,
    'variant': variant,
    'nutritionPer100g': nutritionPer100g.toJson(),
    'typicalServingGrams': typicalServingGrams,
    'dataSource': dataSource,
    'dataQuality': dataQuality.name,
    'isEstimated': isEstimated,
    'imageUrl': imageUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'favorite': favorite,
  };

  factory Dish.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid dish');
    final map = Map<dynamic, dynamic>.from(value);
    return Dish(
      id: map['id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalizedName'] as String?,
      cuisine: _enumByName(
        DishCuisine.values,
        map['cuisine'],
        DishCuisine.other,
      ),
      category: _enumByName(
        DishCategory.values,
        map['category'],
        DishCategory.mainCourses,
      ),
      subcategory: map['subcategory'] as String?,
      variant: map['variant'] as String?,
      nutritionPer100g: NutritionValues.fromJson(map['nutritionPer100g']),
      typicalServingGrams: (map['typicalServingGrams'] as num).toDouble(),
      dataSource: map['dataSource'] as String,
      dataQuality: _enumByName(
        DishDataQuality.values,
        map['dataQuality'],
        DishDataQuality.importedEstimate,
      ),
      isEstimated: map['isEstimated'] != false,
      imageUrl: map['imageUrl'] as String?,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
      favorite: map['favorite'] == true,
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
