import 'dart:typed_data';

import 'food_product.dart';

enum RecipeUnit { g, ml, piece, tbsp, tsp }

class RecipeIngredient {
  final String id;
  final String? productId;
  final String? productVersion;
  final String nameSnapshot;
  final double amount;
  final RecipeUnit unit;
  final double? gramsEquivalent;
  final NutritionValues nutritionSnapshot;

  RecipeIngredient({
    required this.id,
    this.productId,
    this.productVersion,
    required this.nameSnapshot,
    required this.amount,
    required this.unit,
    this.gramsEquivalent,
    required this.nutritionSnapshot,
  }) {
    if (id.trim().isEmpty || nameSnapshot.trim().isEmpty || amount <= 0) {
      throw const FormatException('Invalid recipe ingredient');
    }
    if (!amount.isFinite ||
        (gramsEquivalent != null &&
            (!gramsEquivalent!.isFinite || gramsEquivalent! <= 0))) {
      throw const FormatException('Invalid ingredient amount');
    }
    if (unit != RecipeUnit.g &&
        unit != RecipeUnit.ml &&
        gramsEquivalent == null) {
      throw const FormatException('Weight is required for this unit');
    }
    _validateNutrition(nutritionSnapshot);
  }

  double? get weightGrams =>
      gramsEquivalent ??
      switch (unit) {
        RecipeUnit.g || RecipeUnit.ml => amount,
        RecipeUnit.piece || RecipeUnit.tbsp || RecipeUnit.tsp => null,
      };

  factory RecipeIngredient.fromProduct({
    required String id,
    required FoodProduct product,
    required double amount,
    RecipeUnit unit = RecipeUnit.g,
    double? gramsEquivalent,
  }) {
    final nutritionAmount = switch (unit) {
      RecipeUnit.g || RecipeUnit.ml => amount,
      RecipeUnit.piece
          when product.nutritionBasis == FoodNutritionBasis.perItem =>
        amount,
      _ => gramsEquivalent,
    };
    if (nutritionAmount == null) {
      throw const FormatException('Weight is required for this unit');
    }
    final nutrition = product.nutritionForAmount(nutritionAmount);
    if (!nutrition.isComplete) {
      throw const FormatException('Complete nutrition is required');
    }
    return RecipeIngredient(
      id: id,
      productId: product.id,
      productVersion: product.sourceRevision,
      nameSnapshot: product.name,
      amount: amount,
      unit: unit,
      gramsEquivalent: gramsEquivalent,
      nutritionSnapshot: nutrition,
    );
  }

  RecipeIngredient copyWith({double? amount, double? gramsEquivalent}) {
    final nextAmount = amount ?? this.amount;
    final factor = nextAmount / this.amount;
    return RecipeIngredient(
      id: id,
      productId: productId,
      productVersion: productVersion,
      nameSnapshot: nameSnapshot,
      amount: nextAmount,
      unit: unit,
      gramsEquivalent:
          gramsEquivalent ??
          (this.gramsEquivalent == null
              ? null
              : this.gramsEquivalent! * factor),
      nutritionSnapshot: nutritionSnapshot.scale(factor),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productVersion': productVersion,
    'nameSnapshot': nameSnapshot,
    'amount': amount,
    'unit': unit.name,
    'gramsEquivalent': gramsEquivalent,
    'nutritionSnapshot': nutritionSnapshot.toJson(),
  };

  factory RecipeIngredient.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid ingredient');
    final map = Map<dynamic, dynamic>.from(value);
    return RecipeIngredient(
      id: _text(map['id']),
      productId: _optionalText(map['productId']),
      productVersion: _optionalText(map['productVersion']),
      nameSnapshot: _text(map['nameSnapshot']),
      amount: _positive(map['amount']),
      unit: _enumByName(RecipeUnit.values, map['unit'], RecipeUnit.g),
      gramsEquivalent: _optionalPositive(map['gramsEquivalent']),
      nutritionSnapshot: NutritionValues.fromJson(map['nutritionSnapshot']),
    );
  }
}

class RecipeTotals {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double ingredientWeightGrams;

  const RecipeTotals({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.ingredientWeightGrams,
  });

  factory RecipeTotals.fromIngredients(Iterable<RecipeIngredient> ingredients) {
    var calories = 0.0;
    var protein = 0.0;
    var fat = 0.0;
    var carbs = 0.0;
    var weight = 0.0;
    for (final ingredient in ingredients) {
      calories += ingredient.nutritionSnapshot.calories ?? 0;
      protein += ingredient.nutritionSnapshot.protein ?? 0;
      fat += ingredient.nutritionSnapshot.fat ?? 0;
      carbs += ingredient.nutritionSnapshot.carbs ?? 0;
      weight += ingredient.weightGrams ?? 0;
    }
    return RecipeTotals(
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      ingredientWeightGrams: weight,
    );
  }

  NutritionValues get nutrition => NutritionValues(
    calories: calories,
    protein: protein,
    fat: fat,
    carbs: carbs,
  );

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'ingredientWeightGrams': ingredientWeightGrams,
  };
}

class RecipeVersion {
  final int version;
  final List<RecipeIngredient> ingredients;
  final double? cookedWeightGrams;
  final int? portions;
  final RecipeTotals totals;
  final DateTime createdAt;

  RecipeVersion({
    required this.version,
    required List<RecipeIngredient> ingredients,
    this.cookedWeightGrams,
    this.portions,
    RecipeTotals? totals,
    DateTime? createdAt,
  }) : ingredients = List.unmodifiable(ingredients),
       totals = totals ?? RecipeTotals.fromIngredients(ingredients),
       createdAt = createdAt ?? DateTime.now().toUtc() {
    if (version < 1 || ingredients.isEmpty) {
      throw const FormatException('Recipe must contain ingredients');
    }
    if (cookedWeightGrams != null &&
        (!cookedWeightGrams!.isFinite || cookedWeightGrams! <= 0)) {
      throw const FormatException('Invalid cooked weight');
    }
    if (portions != null && (portions! < 1 || portions! > 1000)) {
      throw const FormatException('Invalid portions');
    }
    if (effectiveWeightGrams <= 0) {
      throw const FormatException('Recipe weight is required');
    }
  }

  double get effectiveWeightGrams =>
      cookedWeightGrams ?? totals.ingredientWeightGrams;
  bool get usesCalculatedWeight => cookedWeightGrams == null;
  NutritionValues get nutritionPer100g =>
      totals.nutrition.scale(100 / effectiveWeightGrams);
  bool get hasSuspiciousCookedWeight =>
      cookedWeightGrams != null &&
      ((nutritionPer100g.calories ?? 0) > 2000 ||
          (nutritionPer100g.protein ?? 0) > 100 ||
          (nutritionPer100g.fat ?? 0) > 100 ||
          (nutritionPer100g.carbs ?? 0) > 100);
  double? get gramsPerPortion =>
      portions == null ? null : effectiveWeightGrams / portions!;
  NutritionValues? get nutritionPerPortion =>
      portions == null ? null : totals.nutrition.scale(1 / portions!);

  NutritionValues nutritionForGrams(double grams) {
    if (!grams.isFinite || grams <= 0) {
      throw const FormatException('Invalid consumed weight');
    }
    return nutritionPer100g.scale(grams / 100);
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'ingredients': ingredients.map((item) => item.toJson()).toList(),
    'cookedWeightGrams': cookedWeightGrams,
    'portions': portions,
    'totals': totals.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory RecipeVersion.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid recipe version');
    final map = Map<dynamic, dynamic>.from(value);
    final ingredients =
        (map['ingredients'] is List
                ? map['ingredients'] as List
                : const <dynamic>[])
            .map(RecipeIngredient.fromJson)
            .toList();
    return RecipeVersion(
      version: (map['version'] as num?)?.toInt() ?? 1,
      ingredients: ingredients,
      cookedWeightGrams: _optionalPositive(map['cookedWeightGrams']),
      portions: (map['portions'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
    );
  }
}

class UserRecipe {
  final String id;
  final String name;
  final String normalizedName;
  final String? category;
  final String? note;
  final Uint8List? imageBytes;
  final bool favorite;
  final List<RecipeVersion> versions;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserRecipe({
    required this.id,
    required this.name,
    String? normalizedName,
    this.category,
    this.note,
    this.imageBytes,
    this.favorite = false,
    required List<RecipeVersion> versions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : normalizedName = normalizedName ?? normalizeFoodText(name),
       versions = List.unmodifiable(versions),
       createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? DateTime.now().toUtc() {
    if (id.trim().isEmpty || name.trim().isEmpty || versions.isEmpty) {
      throw const FormatException('Invalid user recipe');
    }
  }

  RecipeVersion get currentVersion => versions.last;

  UserRecipe copyWith({
    String? id,
    String? name,
    String? category,
    String? note,
    Uint8List? imageBytes,
    bool? favorite,
    List<RecipeVersion>? versions,
    DateTime? updatedAt,
  }) => UserRecipe(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    note: note ?? this.note,
    imageBytes: imageBytes ?? this.imageBytes,
    favorite: favorite ?? this.favorite,
    versions: versions ?? this.versions,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'normalizedName': normalizedName,
    'category': category,
    'note': note,
    'imageBytes': imageBytes,
    'favorite': favorite,
    'versions': versions.map((item) => item.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserRecipe.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid user recipe');
    final map = Map<dynamic, dynamic>.from(value);
    final bytes = map['imageBytes'];
    return UserRecipe(
      id: _text(map['id']),
      name: _text(map['name']),
      normalizedName: _optionalText(map['normalizedName']),
      category: _optionalText(map['category']),
      note: _optionalText(map['note']),
      imageBytes: bytes is Uint8List
          ? bytes
          : bytes is List
          ? Uint8List.fromList(
              bytes.whereType<num>().map((v) => v.toInt()).toList(),
            )
          : null,
      favorite: map['favorite'] == true,
      versions:
          (map['versions'] is List
                  ? map['versions'] as List
                  : const <dynamic>[])
              .map(RecipeVersion.fromJson)
              .toList(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
    );
  }

  static UserRecipe? tryFromJson(Object? value) {
    try {
      return UserRecipe.fromJson(value);
    } catch (_) {
      return null;
    }
  }
}

void _validateNutrition(NutritionValues value) {
  final fields = [value.calories, value.protein, value.fat, value.carbs];
  if (fields.any((item) => item == null || !item.isFinite || item < 0)) {
    throw const FormatException('Complete non-negative nutrition is required');
  }
}

String _text(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Required text is missing');
  }
  return value.trim();
}

String? _optionalText(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

double _positive(Object? value) {
  if (value is! num || !value.isFinite || value <= 0) {
    throw const FormatException('Positive number required');
  }
  return value.toDouble();
}

double? _optionalPositive(Object? value) =>
    value == null ? null : _positive(value);

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
