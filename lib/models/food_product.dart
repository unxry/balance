enum FoodProductSource {
  officialManufacturer,
  officialRetailer,
  verifiedCatalog,
  openFoodFacts,
  restaurantMenu,
  manual,
}

enum FoodDataQuality { verified, good, partial, unverified }

enum FoodNutritionBasis { per100g, per100ml, perServing, perItem }

class NutritionValues {
  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;

  const NutritionValues({this.calories, this.protein, this.fat, this.carbs});

  bool get isEmpty =>
      calories == null && protein == null && fat == null && carbs == null;
  bool get isComplete =>
      calories != null && protein != null && fat != null && carbs != null;

  NutritionValues scale(double factor) => NutritionValues(
    calories: calories == null ? null : calories! * factor,
    protein: protein == null ? null : protein! * factor,
    fat: fat == null ? null : fat! * factor,
    carbs: carbs == null ? null : carbs! * factor,
  );

  static NutritionValues sum(Iterable<NutritionValues> values) {
    final snapshot = values.toList();
    double? total(double? Function(NutritionValues value) select) {
      var result = 0.0;
      var present = false;
      for (final value in snapshot) {
        final selected = select(value);
        if (selected != null) {
          result += selected;
          present = true;
        }
      }
      return present ? result : null;
    }

    return NutritionValues(
      calories: total((value) => value.calories),
      protein: total((value) => value.protein),
      fat: total((value) => value.fat),
      carbs: total((value) => value.carbs),
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
  };

  factory NutritionValues.fromJson(Object? value) {
    final map = value is Map ? Map<dynamic, dynamic>.from(value) : const {};
    return NutritionValues(
      calories: _nullableNumber(map['calories']),
      protein: _nullableNumber(map['protein']),
      fat: _nullableNumber(map['fat']),
      carbs: _nullableNumber(map['carbs']),
    );
  }
}

class RestaurantFoodProduct extends FoodProduct {
  RestaurantFoodProduct({
    required super.id,
    required super.name,
    super.brand,
    super.category,
    super.servingSize,
    super.servingUnit,
    required super.nutrition,
    required super.nutritionBasis,
    super.nutritionBasisAmount,
    super.imageUrl,
    super.sourceProductId,
    super.sourceUrl,
    super.nutritionVerified,
    super.dataQuality,
    super.imageLicense,
    super.imageAttribution,
    super.lastUpdatedAt,
    super.lastFetchedAt,
    super.lastVerifiedAt,
    super.sourceRevision,
    super.needsReview,
  }) : assert(
         nutritionBasis == FoodNutritionBasis.perServing ||
             nutritionBasis == FoodNutritionBasis.perItem,
       ),
       super(
         source: FoodProductSource.restaurantMenu,
         nutritionSource: FoodProductSource.restaurantMenu,
       );
}

/// Source-aware catalog record. Missing nutrition remains null intentionally.
class FoodProduct {
  final String id;
  final String? barcode;
  final String name;
  final String normalizedName;
  final String? brand;
  final List<String> retailerTags;
  final String? category;
  final String? subcategory;
  final double? packageAmount;
  final String? packageUnit;
  final double? netWeightGrams;
  final double? netVolumeMl;
  final double? servingSize;
  final String? servingUnit;
  final FoodNutritionBasis nutritionBasis;
  final double nutritionBasisAmount;
  final NutritionValues nutrition;
  final String? ingredients;
  final String? imageUrl;
  final String? localImagePath;
  final FoodProductSource source;
  final String? sourceProductId;
  final String? sourceUrl;
  final FoodProductSource nutritionSource;
  final bool nutritionVerified;
  final FoodDataQuality dataQuality;
  final String? imageLicense;
  final String? imageAttribution;
  final DateTime lastUpdatedAt;
  final DateTime? lastFetchedAt;
  final DateTime? lastVerifiedAt;
  final String? sourceRevision;
  final bool needsReview;
  final bool favorite;
  final String localCategory;
  final int colorSeed;

  FoodProduct({
    required this.id,
    this.barcode,
    required this.name,
    String? normalizedName,
    this.brand,
    this.retailerTags = const [],
    this.category,
    this.subcategory,
    this.packageAmount,
    this.packageUnit,
    this.netWeightGrams,
    this.netVolumeMl,
    this.servingSize,
    this.servingUnit,
    this.nutritionBasis = FoodNutritionBasis.per100g,
    double? nutritionBasisAmount,
    this.nutrition = const NutritionValues(),
    this.ingredients,
    this.imageUrl,
    this.localImagePath,
    required this.source,
    this.sourceProductId,
    this.sourceUrl,
    FoodProductSource? nutritionSource,
    this.nutritionVerified = false,
    FoodDataQuality? dataQuality,
    this.imageLicense,
    this.imageAttribution,
    DateTime? lastUpdatedAt,
    this.lastFetchedAt,
    this.lastVerifiedAt,
    this.sourceRevision,
    bool? needsReview,
    this.favorite = false,
    this.localCategory = 'all',
    this.colorSeed = 0,
  }) : normalizedName = normalizedName ?? normalizeFoodText(name),
       nutritionBasisAmount =
           nutritionBasisAmount ??
           switch (nutritionBasis) {
             FoodNutritionBasis.per100g || FoodNutritionBasis.per100ml => 100,
             FoodNutritionBasis.perServing => servingSize ?? 1,
             FoodNutritionBasis.perItem => 1,
           },
       nutritionSource = nutritionSource ?? source,
       dataQuality = dataQuality ?? _inferQuality(nutrition, nutritionVerified),
       lastUpdatedAt = lastUpdatedAt ?? DateTime.now().toUtc(),
       needsReview = needsReview ?? _nutritionLooksAnomalous(nutrition) {
    if (id.trim().isEmpty || name.trim().isEmpty) {
      throw const FormatException('Product id and name are required');
    }
    if (this.nutritionBasisAmount <= 0 || !this.nutritionBasisAmount.isFinite) {
      throw const FormatException('Invalid nutrition basis amount');
    }
    _validateNutrition(nutrition);
  }

  bool get hasCompleteNutrition => nutrition.isComplete;
  int get kcalPer100g => nutrition.calories?.round() ?? 0;
  double get proteinPer100g => nutrition.protein ?? 0;
  double get fatPer100g => nutrition.fat ?? 0;
  double get carbsPer100g => nutrition.carbs ?? 0;

  NutritionValues nutritionForAmount(double amount) {
    if (!amount.isFinite || amount <= 0) {
      throw const FormatException('Amount must be positive');
    }
    return nutrition.scale(amount / nutritionBasisAmount);
  }

  FoodProduct withFavorite(bool value) =>
      FoodProduct.fromJson({...toJson(), 'favorite': value});

  FoodProduct withRetailerTags(Iterable<String> values) => FoodProduct.fromJson(
    {...toJson(), 'retailerTags': values.toSet().toList()},
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'barcode': barcode,
    'name': name,
    'normalizedName': normalizedName,
    'brand': brand,
    'retailerTags': retailerTags,
    'category': category,
    'subcategory': subcategory,
    'packageAmount': packageAmount,
    'packageUnit': packageUnit,
    'netWeightGrams': netWeightGrams,
    'netVolumeMl': netVolumeMl,
    'servingSize': servingSize,
    'servingUnit': servingUnit,
    'nutritionBasis': nutritionBasis.name,
    'nutritionBasisAmount': nutritionBasisAmount,
    'nutrition': nutrition.toJson(),
    'ingredients': ingredients,
    'imageUrl': imageUrl,
    'localImagePath': localImagePath,
    'source': source.name,
    'sourceProductId': sourceProductId,
    'sourceUrl': sourceUrl,
    'nutritionSource': nutritionSource.name,
    'nutritionVerified': nutritionVerified,
    'dataQuality': dataQuality.name,
    'imageLicense': imageLicense,
    'imageAttribution': imageAttribution,
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    'lastFetchedAt': lastFetchedAt?.toIso8601String(),
    'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
    'sourceRevision': sourceRevision,
    'needsReview': needsReview,
    'favorite': favorite,
    'localCategory': localCategory,
    'colorSeed': colorSeed,
  };

  factory FoodProduct.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid product');
    final map = Map<dynamic, dynamic>.from(value);
    return FoodProduct(
      id: _requiredText(map['id']),
      barcode: _optionalText(map['barcode']),
      name: _requiredDisplayText(map['name']),
      normalizedName: _optionalText(map['normalizedName']),
      brand: _optionalDisplayText(map['brand']),
      retailerTags: _stringList(map['retailerTags']),
      category: _optionalDisplayText(map['category']),
      subcategory: _optionalDisplayText(map['subcategory']),
      packageAmount: _nullableNumber(map['packageAmount']),
      packageUnit: _optionalText(map['packageUnit']),
      netWeightGrams: _nullableNumber(map['netWeightGrams']),
      netVolumeMl: _nullableNumber(map['netVolumeMl']),
      servingSize: _nullableNumber(map['servingSize']),
      servingUnit: _optionalText(map['servingUnit']),
      nutritionBasis: _enumByName(
        FoodNutritionBasis.values,
        map['nutritionBasis'],
        FoodNutritionBasis.per100g,
      ),
      nutritionBasisAmount: _nullableNumber(map['nutritionBasisAmount']),
      nutrition: NutritionValues.fromJson(map['nutrition']),
      ingredients: _optionalDisplayText(map['ingredients']),
      imageUrl: _safeImageUrl(map['imageUrl']),
      localImagePath: _optionalText(map['localImagePath']),
      source: _enumByName(
        FoodProductSource.values,
        map['source'],
        FoodProductSource.manual,
      ),
      sourceProductId: _optionalText(map['sourceProductId']),
      sourceUrl: _optionalText(map['sourceUrl']),
      nutritionSource: _enumByName(
        FoodProductSource.values,
        map['nutritionSource'],
        FoodProductSource.manual,
      ),
      nutritionVerified: map['nutritionVerified'] == true,
      dataQuality: _enumByName(
        FoodDataQuality.values,
        map['dataQuality'],
        FoodDataQuality.unverified,
      ),
      imageLicense: _optionalText(map['imageLicense']),
      imageAttribution: _optionalDisplayText(map['imageAttribution']),
      lastUpdatedAt: _date(map['lastUpdatedAt']) ?? DateTime.now().toUtc(),
      lastFetchedAt: _date(map['lastFetchedAt']),
      lastVerifiedAt: _date(map['lastVerifiedAt']),
      sourceRevision: _optionalText(map['sourceRevision']),
      needsReview: map['needsReview'] == true,
      favorite: map['favorite'] == true,
      localCategory: _optionalText(map['localCategory']) ?? 'all',
      colorSeed: map['colorSeed'] is num
          ? (map['colorSeed'] as num).toInt()
          : 0,
    );
  }

  static FoodProduct? tryFromJson(Object? value) {
    try {
      return FoodProduct.fromJson(value);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

int foodSourcePriority(FoodProduct product) => switch (product.source) {
  FoodProductSource.officialManufacturer => 600,
  FoodProductSource.officialRetailer => 500,
  FoodProductSource.restaurantMenu => 475,
  FoodProductSource.openFoodFacts => product.nutritionVerified ? 400 : 300,
  FoodProductSource.verifiedCatalog => 350,
  FoodProductSource.manual => 200,
};

String normalizeFoodText(String value) {
  const latinToCyrillic = {
    'barilla': 'барилла',
    'barila': 'барилла',
    'macaroni': 'макароны',
    'pasta': 'макароны',
  };
  var result = value.toLowerCase().replaceAll('ё', 'е');
  for (final replacement in latinToCyrillic.entries) {
    result = result.replaceAll(replacement.key, replacement.value);
  }
  return result
      .replaceAll(RegExp(r'[^a-zа-я0-9]+', unicode: true), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

FoodDataQuality _inferQuality(NutritionValues value, bool verified) {
  if (verified && value.isComplete) return FoodDataQuality.verified;
  if (value.isComplete) return FoodDataQuality.good;
  if (!value.isEmpty) return FoodDataQuality.partial;
  return FoodDataQuality.unverified;
}

void _validateNutrition(NutritionValues value) {
  final fields = [value.calories, value.protein, value.fat, value.carbs];
  for (final number in fields) {
    if (number != null && (!number.isFinite || number < 0 || number > 5000)) {
      throw const FormatException('Invalid nutrition value');
    }
  }
}

bool _nutritionLooksAnomalous(NutritionValues value) {
  if (!value.isComplete) return false;
  final macroKcal = value.protein! * 4 + value.carbs! * 4 + value.fat! * 9;
  final tolerance = 80 + value.calories! * 0.25;
  return (value.calories! - macroKcal).abs() > tolerance;
}

double? _nullableNumber(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed != null && parsed.isFinite) return parsed;
  }
  return null;
}

String _requiredText(Object? value) {
  final text = _optionalText(value);
  if (text == null) throw const FormatException('Required text is missing');
  return text;
}

String _requiredDisplayText(Object? value) {
  final text = _optionalDisplayText(value);
  if (text == null) throw const FormatException('Required text is missing');
  return text;
}

String? _optionalDisplayText(Object? value) {
  final text = _optionalText(value);
  if (text == null) return null;
  return text.replaceAllMapped(
    RegExp(r'&(?:#x[0-9a-fA-F]+|#[0-9]+|quot|apos|amp|lt|gt);'),
    (match) {
      final entity = match.group(0)!;
      const named = {
        '&quot;': '"',
        '&apos;': "'",
        '&amp;': '&',
        '&lt;': '<',
        '&gt;': '>',
      };
      final namedValue = named[entity];
      if (namedValue != null) return namedValue;
      final hex = entity.startsWith('&#x');
      final digits = entity.substring(hex ? 3 : 2, entity.length - 1);
      final codePoint = int.tryParse(digits, radix: hex ? 16 : 10);
      if (codePoint == null ||
          codePoint <= 0 ||
          codePoint > 0x10ffff ||
          (codePoint >= 0xd800 && codePoint <= 0xdfff)) {
        return entity;
      }
      return String.fromCharCodes([codePoint]);
    },
  );
}

String? _optionalText(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

String? _safeImageUrl(Object? value) {
  final text = _optionalText(value);
  if (text == null) return null;
  final uri = Uri.tryParse(text);
  return uri != null && uri.scheme == 'https' ? text : null;
}

List<String> _stringList(Object? value) => value is List
    ? value
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
    : const [];

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

T _enumByName<T extends Enum>(List<T> values, Object? value, T fallback) {
  if (value is String) {
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
  }
  return fallback;
}
