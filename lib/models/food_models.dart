enum MealType { breakfast, lunch, snack, dinner }

enum FoodEntrySourceType {
  packagedProduct,
  restaurantProduct,
  preparedRetailProduct,
  genericDish,
  userRecipe,
  manual,
}

extension MealTypeX on MealType {
  static MealType? tryFromIndex(Object? value) {
    if (value is! num) return null;
    final index = value.toInt();
    return index >= 0 && index < MealType.values.length
        ? MealType.values[index]
        : null;
  }
}

class FoodEntry {
  final String id;
  final String name;
  final double grams;
  final int kcal;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final MealType meal;
  final DateTime time;
  final int colorSeed;
  final String? productId;
  final String? productVersion;
  final String? productSource;
  final FoodEntrySourceType sourceType;
  final String? recipeId;
  final int? recipeVersion;

  FoodEntry({
    required this.id,
    required this.name,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.meal,
    required this.time,
    this.colorSeed = 0,
    this.productId,
    this.productVersion,
    this.productSource,
    this.sourceType = FoodEntrySourceType.manual,
    this.recipeId,
    this.recipeVersion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'grams': grams,
    'kcal': kcal,
    'proteinG': proteinG,
    'fatG': fatG,
    'carbsG': carbsG,
    'meal': meal.index,
    'time': time.toIso8601String(),
    'colorSeed': colorSeed,
    'productId': productId,
    'productVersion': productVersion,
    'productSource': productSource,
    'sourceType': sourceType.name,
    'recipeId': recipeId,
    'recipeVersion': recipeVersion,
  };

  factory FoodEntry.fromJson(Map<dynamic, dynamic> j) {
    final id = _requiredString(j['id'], 'id', maxLength: 120);
    final name = _requiredString(j['name'], 'name', maxLength: 120);
    final meal = MealTypeX.tryFromIndex(j['meal']);
    final timeValue = j['time'];
    final time = timeValue is String ? DateTime.tryParse(timeValue) : null;
    if (meal == null || time == null) {
      throw const FormatException('Invalid food meal or timestamp');
    }
    return FoodEntry(
      id: id,
      name: name,
      grams: _boundedNumber(j['grams'], 'grams', 1, 5000),
      kcal: _boundedNumber(j['kcal'], 'kcal', 0, 10000).round(),
      proteinG: _boundedNumber(j['proteinG'], 'proteinG', 0, 1000),
      fatG: _boundedNumber(j['fatG'], 'fatG', 0, 1000),
      carbsG: _boundedNumber(j['carbsG'], 'carbsG', 0, 1000),
      meal: meal,
      time: time,
      colorSeed: j['colorSeed'] is num ? (j['colorSeed'] as num).toInt() : 0,
      productId: _optionalString(j['productId'], maxLength: 180),
      productVersion: _optionalString(j['productVersion'], maxLength: 180),
      productSource: _optionalString(j['productSource'], maxLength: 80),
      sourceType: _sourceType(j['sourceType'], j['productSource']),
      recipeId: _optionalString(j['recipeId'], maxLength: 180),
      recipeVersion: j['recipeVersion'] is num
          ? (j['recipeVersion'] as num).toInt()
          : null,
    );
  }

  static FoodEntry? tryFromJson(Object? value) {
    if (value is! Map) return null;
    try {
      return FoodEntry.fromJson(Map<dynamic, dynamic>.from(value));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

FoodEntrySourceType _sourceType(Object? value, Object? legacySource) {
  for (final type in FoodEntrySourceType.values) {
    if (type.name == value) return type;
  }
  if (legacySource == 'restaurantMenu') {
    return FoodEntrySourceType.restaurantProduct;
  }
  if (legacySource == 'manual') return FoodEntrySourceType.manual;
  return legacySource == null
      ? FoodEntrySourceType.manual
      : FoodEntrySourceType.packagedProduct;
}

String? _optionalString(Object? value, {required int maxLength}) {
  if (value is! String || value.trim().isEmpty) return null;
  final normalized = value.trim();
  return normalized.length > maxLength
      ? normalized.substring(0, maxLength)
      : normalized;
}

/// A single catalog item for the manual "Add food" search screen.
class FoodCatalogItem {
  final String name;
  final int kcalPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbsPer100g;
  final bool favorite;
  final String category; // recent, favorite, meal, brand
  final int colorSeed;

  const FoodCatalogItem({
    required this.name,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
    this.favorite = false,
    this.category = 'all',
    this.colorSeed = 0,
  });
}

String _requiredString(Object? value, String field, {required int maxLength}) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid $field');
  }
  final normalized = value.trim();
  return normalized.length > maxLength
      ? normalized.substring(0, maxLength)
      : normalized;
}

double _boundedNumber(
  Object? value,
  String field,
  double min,
  double max, {
  bool clamp = false,
}) {
  if (value is! num) throw FormatException('Missing or invalid $field');
  final number = value.toDouble();
  if (!number.isFinite) throw FormatException('Non-finite $field');
  if (clamp) return number.clamp(min, max).toDouble();
  if (number < min || number > max) {
    throw FormatException('Out-of-range $field');
  }
  return number;
}
