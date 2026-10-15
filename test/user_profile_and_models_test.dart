import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/models/history_models.dart';
import 'package:flutter_app/models/user_profile.dart';

void main() {
  group('UserProfile calculations', () {
    test('calculates Mifflin-St Jeor targets deterministically', () {
      final profile = UserProfile(
        gender: Gender.female,
        age: 28,
        heightCm: 168,
        weightKg: 67,
        activityLevel: ActivityLevel.light,
        goal: Goal.lose,
      );

      expect(profile.calorieTarget, 1500);
      expect(profile.proteinTargetG, 121);
      expect(profile.fatTargetG, 42);
      expect(profile.carbTargetG, 160);
      profile.activityLevel = ActivityLevel.active;
      expect(profile.calorieTarget, 2000);
    });

    test('clamps unsafe profile JSON and rejects fake default names', () {
      final profile = UserProfile.fromJson({
        'gender': 99,
        'goal': -4,
        'age': 4,
        'heightCm': double.infinity,
        'weightKg': 900,
        'targetWeightKg': -1,
        'name': 123,
        'joinedAt': 'broken',
        'onboarded': 'yes',
      });

      expect(profile.gender, Gender.female);
      expect(profile.goal, Goal.lose);
      expect(profile.activityLevel, ActivityLevel.light);
      expect(profile.age, 16);
      expect(profile.heightCm, 168);
      expect(profile.weightKg, 400);
      expect(profile.targetWeightKg, 20);
      expect(profile.name, isEmpty);
      expect(profile.onboarded, isFalse);
      expect(profile.avatarLetter, 'B');
    });

    test('profile photo bytes survive local serialization', () {
      final original = UserProfile(
        name: 'Любовь',
        avatarBytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      final restored = UserProfile.fromJson(original.toJson());
      expect(restored.avatarBytes, [1, 2, 3, 4]);
      expect(restored.avatarLetter, 'Л');
    });

    test('manual calorie target survives profile recalculation and JSON', () {
      final profile = UserProfile(
        weightKg: 80,
        goal: Goal.lose,
        calorieGoalMode: CalorieGoalMode.manual,
        manualCalories: 1750,
      );
      final originalRecommendation = profile.recommendedCalories;

      profile.weightKg = 79;
      final restored = UserProfile.fromJson(profile.toJson());

      expect(restored.calorieGoalMode, CalorieGoalMode.manual);
      expect(restored.effectiveCalorieGoal, 1750);
      expect(restored.calorieTarget, 1750);
      expect(restored.recommendedCalories, isNot(originalRecommendation));
    });

    test('legacy profile defaults to automatic calories', () {
      final restored = UserProfile.fromJson({
        'weightKg': 67,
        'targetWeightKg': 60,
        'goal': Goal.lose.index,
      });

      expect(restored.calorieGoalMode, CalorieGoalMode.auto);
      expect(restored.effectiveCalorieGoal, restored.recommendedCalories);
    });
  });

  group('local model serialization', () {
    test('FoodEntry round-trips', () {
      final original = FoodEntry(
        id: 'id-1',
        name: 'Apple',
        grams: 120,
        kcal: 62,
        proteinG: 0.4,
        fatG: 0.2,
        carbsG: 16,
        meal: MealType.snack,
        time: DateTime(2026, 8, 29, 12, 30),
      );

      final decoded = FoodEntry.fromJson(original.toJson());
      expect(decoded.id, original.id);
      expect(decoded.meal, MealType.snack);
      expect(decoded.time, original.time);
      expect(decoded.grams, 120);
    });

    test('FoodEntry.tryFromJson rejects corrupt and out-of-range data', () {
      expect(FoodEntry.tryFromJson('not-a-map'), isNull);
      expect(
        FoodEntry.tryFromJson({
          'id': 'x',
          'name': 'Bad',
          'grams': -1,
          'kcal': 10,
          'proteinG': 0,
          'fatG': 0,
          'carbsG': 0,
          'meal': 99,
          'time': 'invalid',
        }),
        isNull,
      );
    });

    test('WeightEntry.tryFromJson rejects corrupt history rows', () {
      expect(WeightEntry.tryFromJson({'date': 'no', 'kg': 70}), isNull);
      expect(
        WeightEntry.tryFromJson({'date': '2026-01-01', 'kg': 1000}),
        isNull,
      );
    });
  });
}
