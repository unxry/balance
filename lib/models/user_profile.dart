import 'dart:typed_data';

enum Gender { female, male }

enum Goal { lose, hold, gain }

enum CalorieGoalMode { auto, manual }

enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725);

  const ActivityLevel(this.factor);
  final double factor;
}

class UserProfile {
  Gender gender;
  int age;
  double heightCm;
  double weightKg;
  ActivityLevel activityLevel;
  Goal goal;
  double targetWeightKg;
  CalorieGoalMode calorieGoalMode;
  int? manualCalories;
  String name;
  Uint8List? avatarBytes;
  DateTime joinedAt;
  bool onboarded;

  UserProfile({
    this.gender = Gender.female,
    this.age = 28,
    this.heightCm = 168,
    this.weightKg = 67,
    this.activityLevel = ActivityLevel.light,
    this.goal = Goal.lose,
    this.targetWeightKg = 60,
    this.calorieGoalMode = CalorieGoalMode.auto,
    this.manualCalories,
    this.name = '',
    this.avatarBytes,
    DateTime? joinedAt,
    this.onboarded = false,
  }) : joinedAt = joinedAt ?? DateTime.now();

  /// Mifflin-St Jeor maintenance estimate adjusted by selected activity.
  int get maintenanceCalorieEstimate {
    double bmr;
    if (gender == Gender.female) {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    }
    final tdee = (bmr * activityLevel.factor).clamp(1200, 4500);
    return (tdee / 10).round() * 10;
  }

  /// Maintenance estimate plus the explicit goal adjustment used by Balance.
  int get recommendedCalories {
    double tdee = maintenanceCalorieEstimate.toDouble();
    switch (goal) {
      case Goal.lose:
        tdee -= 450;
        break;
      case Goal.gain:
        tdee += 400;
        break;
      case Goal.hold:
        break;
    }
    // Clamp to sane bounds
    if (tdee < 1200) tdee = 1200;
    if (tdee > 4000) tdee = 4000;
    return (tdee / 10).round() * 10;
  }

  /// The single calorie target consumed by the diary, dashboard and analytics.
  /// Legacy callers keep using [calorieTarget], while manual mode remains stable
  /// when weight or activity changes.
  int get effectiveCalorieGoal {
    if (calorieGoalMode == CalorieGoalMode.manual) {
      return (manualCalories ?? recommendedCalories).clamp(1200, 4000);
    }
    return recommendedCalories;
  }

  int get calorieTarget => effectiveCalorieGoal;

  int get proteinTargetG => (weightKg * 1.8).round();
  int get fatTargetG => ((calorieTarget * 0.25) / 9).round();
  int get carbTargetG =>
      ((calorieTarget - proteinTargetG * 4 - fatTargetG * 9) / 4).round().clamp(
        50,
        500,
      );

  String get avatarLetter {
    final trimmed = name.trim();
    return trimmed.isEmpty
        ? 'B'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'gender': gender.index,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'activityLevel': activityLevel.index,
    'goal': goal.index,
    'targetWeightKg': targetWeightKg,
    'calorieGoalMode': calorieGoalMode.name,
    'manualCalories': manualCalories,
    'name': name,
    'avatarBytes': avatarBytes,
    'joinedAt': joinedAt.toIso8601String(),
    'onboarded': onboarded,
  };

  factory UserProfile.fromJson(Map<dynamic, dynamic> json) {
    final genderIndex = _safeIndex(json['gender'], Gender.values.length);
    final goalIndex = _safeIndex(json['goal'], Goal.values.length);
    final rawMode = json['calorieGoalMode'];
    final calorieGoalMode = CalorieGoalMode.values.where(
      (value) => value.name == rawMode,
    );
    final rawManualCalories = json['manualCalories'];
    final manualCalories =
        rawManualCalories is num &&
            rawManualCalories.isFinite &&
            rawManualCalories >= 1200 &&
            rawManualCalories <= 4000
        ? rawManualCalories.round()
        : null;
    final activityIndex = _safeIndex(
      json['activityLevel'],
      ActivityLevel.values.length,
      fallback: ActivityLevel.light.index,
    );
    final age = _safeInt(json['age'], 28).clamp(16, 100);
    final height = _safeDouble(json['heightCm'], 168).clamp(100, 250);
    final weight = _safeDouble(json['weightKg'], 67).clamp(20, 400).toDouble();
    final target = _safeDouble(
      json['targetWeightKg'],
      weight,
    ).clamp(20, 400).toDouble();
    final rawName = json['name'];
    final name = rawName is String ? rawName.trim() : '';
    final rawAvatar = json['avatarBytes'];
    Uint8List? avatarBytes;
    if (rawAvatar is Uint8List && rawAvatar.length <= 4 * 1024 * 1024) {
      avatarBytes = Uint8List.fromList(rawAvatar);
    } else if (rawAvatar is List && rawAvatar.length <= 4 * 1024 * 1024) {
      try {
        avatarBytes = Uint8List.fromList(rawAvatar.cast<int>());
      } catch (_) {
        avatarBytes = null;
      }
    }
    final joinedRaw = json['joinedAt'];
    final joinedAt = joinedRaw is String
        ? DateTime.tryParse(joinedRaw) ?? DateTime.now()
        : DateTime.now();
    return UserProfile(
      gender: Gender.values[genderIndex],
      age: age,
      heightCm: height.toDouble(),
      weightKg: weight.toDouble(),
      activityLevel: ActivityLevel.values[activityIndex],
      goal: Goal.values[goalIndex],
      targetWeightKg: target.toDouble(),
      calorieGoalMode: calorieGoalMode.isEmpty
          ? CalorieGoalMode.auto
          : calorieGoalMode.first,
      manualCalories: manualCalories,
      name: name.length > 80 ? name.substring(0, 80) : name,
      avatarBytes: avatarBytes,
      joinedAt: joinedAt,
      onboarded: json['onboarded'] is bool ? json['onboarded'] as bool : false,
    );
  }
}

int _safeIndex(Object? value, int length, {int fallback = 0}) {
  final index = value is num ? value.toInt() : -1;
  return index >= 0 && index < length ? index : fallback;
}

int _safeInt(Object? value, int fallback) {
  if (value is num && value.isFinite) return value.toInt();
  return fallback;
}

double _safeDouble(Object? value, double fallback) {
  if (value is num) {
    final result = value.toDouble();
    if (result.isFinite) return result;
  }
  return fallback;
}
