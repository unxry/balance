import 'dart:io';

import 'package:flutter_app/models/achievement_models.dart';
import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/services/achievement_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  const engine = AchievementEngine();
  final unlockedAt = DateTime(2026, 9, 5, 12);

  test('catalog is substantial and covers every requested category', () {
    expect(AchievementEngine.catalog, hasLength(38));
    expect(
      AchievementEngine.catalog.map((item) => item.category).toSet(),
      AchievementCategory.values.toSet(),
    );
    expect(
      AchievementEngine.catalog.map((item) => item.id).toSet(),
      hasLength(AchievementEngine.catalog.length),
    );
  });

  test('locked, in-progress and unlocked states use source metrics', () {
    final evaluation = engine.evaluate(
      metrics: const AchievementMetrics({'foodDays': 1, 'foodEntries': 1}),
      persistedUnlocks: const {},
      now: unlockedAt,
    );

    AchievementProgress byId(String id) =>
        evaluation.achievements.singleWhere((item) => item.definition.id == id);

    expect(byId('food_first').state, AchievementState.unlocked);
    expect(byId('food_first').fraction, 1);
    expect(byId('food_7').state, AchievementState.inProgress);
    expect(byId('food_7').fraction, closeTo(1 / 7, 0.001));
    expect(byId('water_first').state, AchievementState.locked);
    expect(
      evaluation.newlyUnlocked.map((item) => item.definition.id),
      contains('food_first'),
    );
  });

  test('persisted unlock never rolls back when a metric decreases', () {
    final evaluation = engine.evaluate(
      metrics: const AchievementMetrics({}),
      persistedUnlocks: {'food_first': unlockedAt},
      now: unlockedAt.add(const Duration(days: 20)),
    );
    final achievement = evaluation.achievements.singleWhere(
      (item) => item.definition.id == 'food_first',
    );

    expect(achievement.state, AchievementState.unlocked);
    expect(achievement.unlockedAt, unlockedAt);
    expect(evaluation.newlyUnlocked, isEmpty);
  });

  test('unlock timestamp survives provider restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'balance_achievements_',
    );
    Hive.init(directory.path);
    final user = await Hive.openBox<dynamic>('ach_user');
    final food = await Hive.openBox<dynamic>('ach_food');
    final weight = await Hive.openBox<dynamic>('ach_weight');
    final achievements = await Hive.openBox<dynamic>('achievements');
    final now = DateTime(2026, 9, 5, 12);

    try {
      final first = AppDataProvider(
        now: () => now,
        userBox: user,
        foodBox: food,
        weightBox: weight,
        achievementsBox: achievements,
      );
      await first.load();
      expect(
        await first.addFood(
          FoodEntry(
            id: 'food-1',
            name: 'Test',
            grams: 100,
            kcal: 100,
            proteinG: 5,
            fatG: 3,
            carbsG: 12,
            meal: MealType.lunch,
            time: now,
          ),
        ),
        isTrue,
      );
      final original = first.achievements
          .singleWhere((item) => item.definition.id == 'food_first')
          .unlockedAt;
      expect(original, isNotNull);

      await first.removeFood('food-1');
      final relaunched = AppDataProvider(
        now: () => now.add(const Duration(days: 1)),
        userBox: user,
        foodBox: food,
        weightBox: weight,
        achievementsBox: achievements,
      );
      await relaunched.load();
      final restored = relaunched.achievements.singleWhere(
        (item) => item.definition.id == 'food_first',
      );

      expect(restored.state, AchievementState.unlocked);
      expect(restored.unlockedAt?.toUtc(), original?.toUtc());
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });
}
