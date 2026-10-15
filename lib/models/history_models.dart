import 'user_profile.dart';

enum WeightEntrySource { manual, imported }

enum AdviceType {
  dataIncomplete,
  caloriesHigh,
  caloriesLow,
  protein,
  weightTrend,
  activity,
  water,
  stable,
}

class CalorieGoalHistoryEntry {
  final DateTime effectiveFrom;
  final int calories;
  final CalorieGoalMode mode;

  const CalorieGoalHistoryEntry({
    required this.effectiveFrom,
    required this.calories,
    required this.mode,
  });

  Map<String, dynamic> toJson() => {
    'effectiveFrom': effectiveFrom.toIso8601String(),
    'calories': calories,
    'mode': mode.name,
  };

  static CalorieGoalHistoryEntry? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final map = Map<dynamic, dynamic>.from(value);
    final date = map['effectiveFrom'] is String
        ? DateTime.tryParse(map['effectiveFrom'] as String)
        : null;
    final calories = map['calories'];
    final mode = CalorieGoalMode.values.where(
      (candidate) => candidate.name == map['mode'],
    );
    if (date == null ||
        calories is! num ||
        !calories.isFinite ||
        calories < 1200 ||
        calories > 4000) {
      return null;
    }
    return CalorieGoalHistoryEntry(
      effectiveFrom: date,
      calories: calories.round(),
      mode: mode.isEmpty ? CalorieGoalMode.auto : mode.first,
    );
  }
}

class GoalHistoryEntry {
  final DateTime effectiveFrom;
  final Goal goal;
  final double targetWeightKg;

  const GoalHistoryEntry({
    required this.effectiveFrom,
    required this.goal,
    required this.targetWeightKg,
  });

  Map<String, dynamic> toJson() => {
    'effectiveFrom': effectiveFrom.toIso8601String(),
    'goal': goal.name,
    'targetWeightKg': targetWeightKg,
  };

  static GoalHistoryEntry? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final map = Map<dynamic, dynamic>.from(value);
    final date = map['effectiveFrom'] is String
        ? DateTime.tryParse(map['effectiveFrom'] as String)
        : null;
    final goals = Goal.values.where(
      (candidate) => candidate.name == map['goal'],
    );
    final target = map['targetWeightKg'];
    if (date == null ||
        goals.isEmpty ||
        target is! num ||
        !target.isFinite ||
        target < 20 ||
        target > 400) {
      return null;
    }
    return GoalHistoryEntry(
      effectiveFrom: date,
      goal: goals.first,
      targetWeightKg: target.toDouble(),
    );
  }
}

class DailyAdviceHistoryEntry {
  final String dateKey;
  final AdviceType type;

  const DailyAdviceHistoryEntry({required this.dateKey, required this.type});

  Map<String, dynamic> toJson() => {'dateKey': dateKey, 'type': type.name};

  static DailyAdviceHistoryEntry? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final map = Map<dynamic, dynamic>.from(value);
    final dateKey = map['dateKey'];
    final types = AdviceType.values.where(
      (candidate) => candidate.name == map['type'],
    );
    if (dateKey is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey) ||
        types.isEmpty) {
      return null;
    }
    return DailyAdviceHistoryEntry(dateKey: dateKey, type: types.first);
  }
}

class WeightEntry {
  final String id;
  final DateTime date;
  final double kg;
  final WeightEntrySource source;
  final DateTime createdAt;
  final DateTime? updatedAt;

  double get weightKg => kg;
  DateTime get measurementDate => date;

  WeightEntry({
    String? id,
    required this.date,
    required this.kg,
    this.source = WeightEntrySource.manual,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? _legacyWeightId(date, kg),
       createdAt = createdAt ?? date;

  WeightEntry copyWith({
    DateTime? date,
    double? kg,
    WeightEntrySource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WeightEntry(
    id: id,
    date: date ?? this.date,
    kg: kg ?? this.kg,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'kg': kg,
    'source': source.name,
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  factory WeightEntry.fromJson(Map<dynamic, dynamic> j) {
    final rawDate = j['date'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
    final rawKg = j['kg'];
    final kg = rawKg is num ? rawKg.toDouble() : double.nan;
    if (date == null || !kg.isFinite || kg < 20 || kg > 400) {
      throw const FormatException('Invalid weight entry');
    }
    final rawId = j['id'];
    final id = rawId is String && rawId.trim().isNotEmpty && rawId.length <= 120
        ? rawId.trim()
        : _legacyWeightId(date, kg);
    final sourceName = j['source'];
    final source = WeightEntrySource.values.where(
      (candidate) => candidate.name == sourceName,
    );
    final createdAt = j['createdAt'] is String
        ? DateTime.tryParse(j['createdAt'] as String) ?? date
        : date;
    final updatedAt = j['updatedAt'] is String
        ? DateTime.tryParse(j['updatedAt'] as String)
        : null;
    return WeightEntry(
      id: id,
      date: date,
      kg: kg,
      source: source.isEmpty ? WeightEntrySource.manual : source.first,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static WeightEntry? tryFromJson(Object? value) {
    if (value is! Map) return null;
    try {
      return WeightEntry.fromJson(Map<dynamic, dynamic>.from(value));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

String _legacyWeightId(DateTime date, double kg) =>
    'legacy-${date.microsecondsSinceEpoch}-${(kg * 10).round()}';

class StepsDay {
  final DateTime date;
  final int steps;
  final double km;
  final int kcal;
  final int activeMinutes;
  final List<int> hourly; // 24 buckets

  StepsDay({
    required this.date,
    required this.steps,
    required this.km,
    required this.kcal,
    required this.activeMinutes,
    required this.hourly,
  });
}

class DailyBalanceSnapshot {
  final String dateKey;
  final int caloriesEaten;
  final int? calorieTarget;
  final int? maintenanceCalories;
  final int? stepCount;
  final double waterLiters;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final int mealCount;
  final List<int> mealMinutes;
  final double? estimatedWeightKg;

  const DailyBalanceSnapshot({
    required this.dateKey,
    required this.caloriesEaten,
    this.calorieTarget,
    this.maintenanceCalories,
    required this.stepCount,
    required this.waterLiters,
    this.proteinG = 0,
    this.fatG = 0,
    this.carbsG = 0,
    this.mealCount = 0,
    this.mealMinutes = const [],
    this.estimatedWeightKg,
  });

  DailyBalanceSnapshot copyWith({double? estimatedWeightKg}) {
    return DailyBalanceSnapshot(
      dateKey: dateKey,
      caloriesEaten: caloriesEaten,
      calorieTarget: calorieTarget,
      maintenanceCalories: maintenanceCalories,
      stepCount: stepCount,
      waterLiters: waterLiters,
      proteinG: proteinG,
      fatG: fatG,
      carbsG: carbsG,
      mealCount: mealCount,
      mealMinutes: mealMinutes,
      estimatedWeightKg: estimatedWeightKg ?? this.estimatedWeightKg,
    );
  }

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey,
    'caloriesEaten': caloriesEaten,
    'calorieTarget': calorieTarget,
    'maintenanceCalories': maintenanceCalories,
    'stepCount': stepCount,
    'waterLiters': waterLiters,
    'proteinG': proteinG,
    'fatG': fatG,
    'carbsG': carbsG,
    'mealCount': mealCount,
    'mealMinutes': mealMinutes,
    'estimatedWeightKg': estimatedWeightKg,
  };

  static DailyBalanceSnapshot? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final map = Map<dynamic, dynamic>.from(value);
    final dateKey = map['dateKey'];
    final calories = map['caloriesEaten'];
    final calorieTarget = map['calorieTarget'];
    final maintenanceCalories = map['maintenanceCalories'];
    final steps = map['stepCount'];
    final water = map['waterLiters'];
    final protein = map['proteinG'] ?? 0;
    final fat = map['fatG'] ?? 0;
    final carbs = map['carbsG'] ?? 0;
    final mealCount = map['mealCount'] ?? 0;
    final rawMealMinutes = map['mealMinutes'];
    final estimated = map['estimatedWeightKg'];
    if (dateKey is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey) ||
        calories is! num ||
        calories < 0 ||
        calories > 50000 ||
        (calorieTarget != null &&
            (calorieTarget is! num ||
                calorieTarget < 800 ||
                calorieTarget > 6000)) ||
        (maintenanceCalories != null &&
            (maintenanceCalories is! num ||
                maintenanceCalories < 800 ||
                maintenanceCalories > 6000)) ||
        water is! num ||
        !water.isFinite ||
        water < 0 ||
        water > 10 ||
        !_validNutrition(protein) ||
        !_validNutrition(fat) ||
        !_validNutrition(carbs) ||
        mealCount is! num ||
        mealCount < 0 ||
        mealCount > 100 ||
        (steps != null && (steps is! num || steps < 0 || steps > 1000000)) ||
        (estimated != null &&
            (estimated is! num ||
                !estimated.isFinite ||
                estimated < 20 ||
                estimated > 400))) {
      return null;
    }
    final mealMinutes = <int>[];
    if (rawMealMinutes is List) {
      for (final value in rawMealMinutes) {
        if (value is num && value >= 0 && value < 24 * 60) {
          mealMinutes.add(value.toInt());
        }
      }
    }
    return DailyBalanceSnapshot(
      dateKey: dateKey,
      caloriesEaten: calories.toInt(),
      calorieTarget: calorieTarget is num ? calorieTarget.toInt() : null,
      maintenanceCalories: maintenanceCalories is num
          ? maintenanceCalories.toInt()
          : null,
      stepCount: steps is num ? steps.toInt() : null,
      waterLiters: water.toDouble(),
      proteinG: (protein as num).toDouble(),
      fatG: (fat as num).toDouble(),
      carbsG: (carbs as num).toDouble(),
      mealCount: mealCount.toInt(),
      mealMinutes: List.unmodifiable(mealMinutes),
      estimatedWeightKg: estimated is num ? estimated.toDouble() : null,
    );
  }
}

bool _validNutrition(Object? value) =>
    value is num && value.isFinite && value >= 0 && value <= 5000;

class WeightTrendEstimate {
  final int daysUsed;
  final double delta7DaysKg;
  final double predictedWeightKg;

  const WeightTrendEstimate({
    required this.daysUsed,
    required this.delta7DaysKg,
    required this.predictedWeightKg,
  });
}
