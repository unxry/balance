import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/models/history_models.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/services/health_service.dart';

class _FakeHealthService extends HealthService {
  StepAccessState status = StepAccessState.authorized;
  int steps;

  _FakeHealthService({this.steps = 0});

  @override
  Future<StepAccessState> getStatus() async => status;

  @override
  Future<StepAccessState> requestAccess() async => status;

  @override
  Future<int> readTodaySteps() async => steps;
}

void main() {
  late Directory directory;
  late Box<dynamic> userBox;
  late Box<dynamic> foodBox;
  late Box<dynamic> weightBox;
  late DateTime now;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('balance_hive_test_');
    Hive.init(directory.path);
    userBox = await Hive.openBox<dynamic>('test_user');
    foodBox = await Hive.openBox<dynamic>('test_food');
    weightBox = await Hive.openBox<dynamic>('test_weight');
  });

  setUp(() async {
    await userBox.clear();
    await foodBox.clear();
    await weightBox.clear();
    now = DateTime(2025, 12, 31, 23, 59);
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  AppDataProvider provider({
    HealthService? healthService,
    Future<void> Function(double liters, String dateKey)? waterWriter,
  }) {
    final value = AppDataProvider(
      now: () => now,
      userBox: userBox,
      foodBox: foodBox,
      weightBox: weightBox,
      healthService: healthService,
      waterWriter: waterWriter,
    );
    addTearDown(value.dispose);
    return value;
  }

  FoodEntry food() => FoodEntry(
    id: 'food-1',
    name: 'Test meal',
    grams: 100,
    kcal: 200,
    proteinG: 10,
    fatG: 5,
    carbsG: 20,
    meal: MealType.dinner,
    time: now,
  );

  test('food and water reset over 31 December to 1 January', () async {
    final data = provider();
    await data.load();
    expect(await data.addFood(food()), isTrue);
    expect(await data.addWater(0.4), isTrue);

    now = DateTime(2026, 1, 1, 0, 1);
    data.refreshForCurrentDay();

    expect(data.todayFood, isEmpty);
    expect(data.waterLiters, 0);
    expect(foodBox.get('dayKey'), '2026-01-01');
    expect(userBox.get('waterDate'), '2026-01-01');
  });

  test('saved food from the same day and year survives restart', () async {
    final first = provider();
    await first.load();
    await first.addFood(food());
    await first.addWater(0.6);

    final relaunched = provider();
    await relaunched.load();

    expect(relaunched.todayFood, hasLength(1));
    expect(relaunched.waterLiters, closeTo(0.6, 0.001));
    expect(relaunched.dailyBalances, hasLength(1));
    expect(relaunched.dailyBalances.single.caloriesEaten, 200);
    expect(relaunched.dailyBalances.single.waterLiters, closeTo(0.6, 0.001));
    expect(
      relaunched.dailyBalances.single.calorieTarget,
      relaunched.profile.calorieTarget,
    );
    expect(
      relaunched.dailyBalances.single.maintenanceCalories,
      relaunched.profile.maintenanceCalorieEstimate,
    );
  });

  test(
    'start over clears personal state but preserves storage schema',
    () async {
      final data = provider();
      await data.load();
      await data.updateProfile(
        UserProfile(name: 'Alex', weightKg: 79, onboarded: true),
      );
      expect(await data.addFood(food()), isTrue);
      expect(await data.addWater(.4), isTrue);
      expect(await data.addWeightEntry(79), isTrue);
      await userBox.put('userRecipes', <dynamic>[
        {'id': 'old-recipe'},
      ]);

      await data.resetPersonalData();

      expect(data.profile.onboarded, isFalse);
      expect(data.todayFood, isEmpty);
      expect(data.waterLiters, 0);
      expect(data.weightHistory, isEmpty);
      expect(userBox.get('userRecipes'), isEmpty);
      expect(userBox.get('storageSchemaVersion'), isNotNull);
    },
  );

  test(
    'multi-day food and water history survives rollover and restart',
    () async {
      final first = provider();
      await first.load();
      expect(await first.addFood(food()), isTrue);
      expect(await first.addWater(0.8), isTrue);

      now = DateTime(2026, 1, 1, 12);
      first.refreshForCurrentDay();
      expect(
        await first.addFood(
          FoodEntry(
            id: 'food-2',
            name: 'Next day meal',
            grams: 100,
            kcal: 150,
            proteinG: 8,
            fatG: 4,
            carbsG: 20,
            meal: MealType.lunch,
            time: now,
          ),
        ),
        isTrue,
      );
      expect(await first.addWater(1.1), isTrue);

      final relaunched = provider();
      await relaunched.load();
      expect(relaunched.todayFood.single.name, 'Next day meal');
      expect(relaunched.allFoodEntries, hasLength(2));
      expect(relaunched.foodEntriesForDate('2025-12-31'), hasLength(1));
      expect(relaunched.waterHistory['2025-12-31'], 0.8);
      expect(relaunched.waterHistory['2026-01-01'], 1.1);
    },
  );

  test('same day and month from a different year is not loaded', () async {
    await foodBox.put('dayKey', '2024-12-31');
    await foodBox.put('today', [food().toJson()]);
    final data = provider();

    await data.load();

    expect(data.todayFood, isEmpty);
  });

  test('corrupt Hive rows are skipped without losing valid rows', () async {
    await foodBox.put('dayKey', '2025-12-31');
    await foodBox.put('today', [
      'broken',
      {'id': 'missing-fields'},
      food().toJson(),
    ]);
    await weightBox.put('history', [
      {'date': 'broken', 'kg': 70},
      {'date': '2025-12-20T10:00:00', 'kg': 70},
    ]);
    await userBox.put('profile', 'not-a-map');

    final data = provider();
    await data.load();

    expect(data.todayFood, hasLength(1));
    expect(data.weightHistory, hasLength(1));
    expect(data.profile.onboarded, isFalse);
  });

  test('streak uses real useful actions and resets after a gap', () async {
    FoodEntry entry(String id, DateTime date) => FoodEntry(
      id: id,
      name: 'Meal',
      grams: 100,
      kcal: 200,
      proteinG: 10,
      fatG: 5,
      carbsG: 20,
      meal: MealType.dinner,
      time: date,
    );
    await foodBox.put('days', {
      '2025-12-30': [entry('day-1', DateTime(2025, 12, 30, 18)).toJson()],
      '2025-12-31': [entry('day-2', DateTime(2025, 12, 31, 18)).toJson()],
    });
    now = DateTime(2025, 12, 31, 9);
    final consecutive = provider();
    await consecutive.load();
    expect(consecutive.streakDays, 2);

    now = DateTime(2026, 1, 3, 9);
    final afterGap = provider();
    await afterGap.load();
    expect(afterGap.streakDays, 0);
  });

  test('food can be added and removed', () async {
    final data = provider();
    await data.load();
    await data.addFood(food());
    expect(data.caloriesEaten, 200);

    await data.removeFood('food-1');
    expect(data.todayFood, isEmpty);
    expect(data.caloriesEaten, 0);
  });

  test('food portion can be edited with proportional nutrition', () async {
    final data = provider();
    await data.load();
    await data.addFood(food());

    expect(await data.updateFoodGrams('food-1', 150), isTrue);
    final updated = data.todayFood.single;
    expect(updated.grams, 150);
    expect(updated.kcal, 300);
    expect(updated.proteinG, closeTo(15, 0.001));
    expect(await data.updateFoodGrams('missing', 100), isFalse);
    expect(await data.updateFoodGrams('food-1', 0), isFalse);
  });

  test('water supports exact amounts and restoring a previous value', () async {
    final data = provider();
    await data.load();

    expect(await data.addWater(0.35), isTrue);
    expect(data.waterLiters, closeTo(0.35, 0.001));
    expect(await data.setWater(0.12), isTrue);
    expect(data.waterLiters, closeTo(0.12, 0.001));
    expect(await data.setWater(-1), isFalse);
  });

  test('water rolls back when persistence fails', () async {
    final data = provider(
      waterWriter: (_, _) => Future<void>.error(Exception('disk failure')),
    );
    await data.load();

    expect(await data.addWater(0.25), isFalse);
    expect(data.waterLiters, 0);
    expect(data.dailyBalances.last.waterLiters, 0);
  });

  test('onboarding creates only the real initial weight', () async {
    final data = provider();
    await data.load();
    expect(data.weightHistory, isEmpty);

    await data.updateProfile(
      UserProfile(
        name: 'Test',
        weightKg: 82,
        targetWeightKg: 75,
        joinedAt: now,
        onboarded: true,
      ),
    );
    expect(data.weightHistory, hasLength(1));
    expect(data.weightHistory.single.kg, 82);

    expect(await data.addWeightEntry(80.5), isTrue);
    expect(data.weightHistory, hasLength(2));
    expect(data.profile.weightKg, 80.5);
    expect(await data.addWeightEntry(double.nan), isFalse);
  });

  test(
    'every weight measurement keeps its date and survives restart',
    () async {
      final data = provider();
      await data.load();
      await data.updateProfile(
        UserProfile(
          name: 'Test',
          weightKg: 80,
          targetWeightKg: 72,
          joinedAt: DateTime(2025, 12, 18, 8),
          onboarded: true,
        ),
      );
      final firstDate = DateTime(2025, 12, 20, 7, 30);
      final secondDate = DateTime(2025, 12, 23, 19, 45);
      expect(await data.addWeightEntry(80.4, date: firstDate), isTrue);
      expect(await data.addWeightEntry(80, date: secondDate), isTrue);

      final relaunched = provider();
      await relaunched.load();
      expect(relaunched.weightHistory, hasLength(3));
      expect(relaunched.weightHistory[1].date, firstDate);
      expect(relaunched.weightHistory[1].kg, 80.4);
      expect(relaunched.weightHistory[2].date, secondDate);
      expect(relaunched.weightHistory[2].kg, 80);
    },
  );

  test(
    'three exact measurements persist, edit in place, and delete by id',
    () async {
      now = DateTime(2026, 9, 28, 12);
      final first = DateTime(2026, 9, 24, 9, 15);
      final second = DateTime(2026, 9, 25, 18, 40);
      final third = DateTime(2026, 9, 28, 8, 10);
      final data = provider();
      await data.load();
      expect(await data.addWeightEntry(67.0, date: first), isTrue);
      expect(await data.addWeightEntry(66.8, date: second), isTrue);
      expect(await data.addWeightEntry(66.4, date: third), isTrue);

      final relaunched = provider();
      await relaunched.load();
      expect(relaunched.weightHistory, hasLength(3));
      expect(relaunched.weightHistory.map((entry) => entry.date), [
        first,
        second,
        third,
      ]);

      final secondId = relaunched.weightHistory[1].id;
      expect(
        await relaunched.updateWeightEntry(secondId, kg: 66.7, date: second),
        isTrue,
      );
      expect(relaunched.weightHistory, hasLength(3));
      expect(relaunched.weightHistory[1].updatedAt, now);
      expect(
        await relaunched.deleteWeightEntry(relaunched.weightHistory.first.id),
        isTrue,
      );
      expect(relaunched.weightHistory, hasLength(2));
    },
  );

  test('manual calories survive weight changes and app restart', () async {
    final data = provider();
    await data.load();
    await data.updateProfile(
      UserProfile(
        name: 'Test',
        weightKg: 80,
        targetWeightKg: 72,
        calorieGoalMode: CalorieGoalMode.manual,
        manualCalories: 1750,
        joinedAt: now,
        onboarded: true,
      ),
    );
    final recommendationBefore = data.profile.recommendedCalories;

    expect(await data.addWeightEntry(79), isTrue);
    expect(data.profile.effectiveCalorieGoal, 1750);
    expect(data.profile.recommendedCalories, isNot(recommendationBefore));

    final relaunched = provider();
    await relaunched.load();
    expect(relaunched.profile.calorieGoalMode, CalorieGoalMode.manual);
    expect(relaunched.profile.effectiveCalorieGoal, 1750);
    expect(relaunched.calorieGoalHistory.last.calories, 1750);
    expect(relaunched.calorieGoalHistory.last.mode, CalorieGoalMode.manual);
  });

  test(
    'automatic goal change preserves the target used by older days',
    () async {
      final data = provider();
      await data.load();
      await data.updateProfile(
        UserProfile(
          name: 'Test',
          weightKg: 80,
          targetWeightKg: 72,
          goal: Goal.lose,
          joinedAt: now,
          onboarded: true,
        ),
      );
      final oldTarget = data.profile.effectiveCalorieGoal;
      await data.addFood(food());

      now = now.add(const Duration(days: 1));
      data.refreshForCurrentDay();
      final next = UserProfile.fromJson(data.profile.toJson())
        ..goal = Goal.hold
        ..targetWeightKg = 80;
      await data.updateProfile(next);

      expect(data.profile.effectiveCalorieGoal, isNot(oldTarget));
      expect(data.dailyBalances.first.calorieTarget, oldTarget);
      expect(data.dailyBalances.last.calorieTarget, data.profile.calorieTarget);
      expect(data.goalHistory.last.goal, Goal.hold);
      expect(data.calorieGoalHistory.last.calories, data.profile.calorieTarget);

      final relaunched = provider();
      await relaunched.load();
      expect(relaunched.goalHistory.last.goal, Goal.hold);
      expect(relaunched.dailyBalances.first.calorieTarget, oldTarget);
    },
  );

  test('activity is explicitly unavailable and never fabricated', () async {
    final data = provider();
    await data.load();
    expect(data.activityAvailable, isFalse);
  });

  test('real HealthKit steps refresh without double accumulation', () async {
    final health = _FakeHealthService(steps: 4321);
    final data = provider(healthService: health);
    await data.load();
    expect(data.activityAvailable, isTrue);
    expect(data.todaySteps, 4321);

    health.steps = 5100;
    await data.refreshSteps();
    expect(data.todaySteps, 5100);
    expect(data.dailyBalances.last.stepCount, 5100);
  });

  test(
    'weight trend requires sustained history and combines actual and energy data',
    () async {
      final health = _FakeHealthService(steps: 8000);
      final data = provider(healthService: health);
      await data.load();
      await data.updateProfile(
        UserProfile(
          name: 'Test',
          weightKg: 80,
          targetWeightKg: 72,
          activityLevel: ActivityLevel.light,
          goal: Goal.lose,
          onboarded: true,
        ),
      );

      final start = now;
      for (var day = 0; day < 15; day++) {
        if (day > 0) {
          now = start.add(Duration(days: day));
          data.refreshForCurrentDay();
          await data.refreshSteps();
        }
        await data.addFood(
          FoodEntry(
            id: 'meal-$day',
            name: 'Meal',
            grams: 500,
            kcal: 1400,
            proteinG: 80,
            fatG: 40,
            carbsG: 150,
            meal: MealType.lunch,
            time: now,
          ),
        );
        if (day == 5 || day == 10 || day == 14) {
          expect(await data.addWeightEntry(80 - day * 0.08, date: now), isTrue);
        }
      }

      final trend = data.weightTrend;
      expect(trend, isNotNull);
      expect(trend!.daysUsed, 15);
      expect(trend.delta7DaysKg, lessThan(0));
      expect(trend.predictedWeightKg, lessThan(data.profile.weightKg));
      expect(data.dailyBalances.last.estimatedWeightKg, isNotNull);
    },
  );

  test(
    'weight entries support backdated edit and delete with one source of truth',
    () async {
      final data = provider();
      await data.load();
      await data.updateProfile(
        UserProfile(
          name: 'Test',
          weightKg: 80,
          targetWeightKg: 72,
          joinedAt: now,
          onboarded: true,
        ),
      );
      final earlier = now.subtract(const Duration(days: 5));
      expect(await data.addWeightEntry(79.6, date: earlier), isTrue);
      expect(data.profile.weightKg, 80);

      final initial = data.weightHistory.first;
      final latest = data.weightHistory.last;
      expect(
        await data.updateWeightEntry(latest.id, kg: 79.4, date: now),
        isTrue,
      );
      expect(data.profile.weightKg, 79.4);
      expect(await data.deleteWeightEntry(initial.id), isTrue);
      expect(data.weightHistory, hasLength(1));
      expect(await data.addFood(food()), isTrue);
      expect(
        await data.deleteWeightEntry(data.weightHistory.single.id),
        isTrue,
      );
      expect(data.weightHistory, isEmpty);
      expect(data.todayFood, hasLength(1));
    },
  );

  test(
    'selected dashboard date navigates backward but never into future',
    () async {
      now = DateTime(2026, 9, 5, 12);
      await userBox.put(
        'profile',
        UserProfile(
          name: 'Test',
          joinedAt: DateTime(2026, 8, 31),
          onboarded: true,
        ).toJson(),
      );
      final data = provider();
      await data.load();

      expect(data.isTodaySelected, isTrue);
      expect(
        data.selectDashboardDate(now.subtract(const Duration(days: 1))),
        isTrue,
      );
      expect(data.selectedDateKey, '2026-09-04');
      expect(
        data.selectDashboardDate(now.subtract(const Duration(days: 5))),
        isTrue,
      );
      expect(data.selectedDateKey, '2026-08-31');
      expect(
        data.selectDashboardDate(now.subtract(const Duration(days: 6))),
        isFalse,
      );
      expect(data.dashboardDayCount, 6);
      expect(
        data.selectDashboardDate(now.add(const Duration(days: 1))),
        isFalse,
      );
      expect(data.selectedDateKey, '2026-08-31');
      expect(data.selectDashboardDate(now), isTrue);
      expect(data.isTodaySelected, isTrue);
    },
  );

  test(
    'historical dashboard uses isolated food water steps and calorie goal',
    () async {
      now = DateTime(2026, 9, 5, 12);
      await userBox.put(
        'profile',
        UserProfile(
          name: 'Test',
          calorieGoalMode: CalorieGoalMode.manual,
          manualCalories: 1800,
          joinedAt: DateTime(2026, 9, 1),
          onboarded: true,
        ).toJson(),
      );
      await userBox.put('calorieGoalHistory', [
        CalorieGoalHistoryEntry(
          effectiveFrom: DateTime(2026, 9, 1),
          calories: 1600,
          mode: CalorieGoalMode.manual,
        ).toJson(),
        CalorieGoalHistoryEntry(
          effectiveFrom: DateTime(2026, 9, 5),
          calories: 1800,
          mode: CalorieGoalMode.manual,
        ).toJson(),
      ]);
      await userBox.put('dailyBalances', [
        const DailyBalanceSnapshot(
          dateKey: '2026-09-04',
          caloriesEaten: 0,
          stepCount: 8420,
          waterLiters: 0,
        ).toJson(),
      ]);
      final data = provider(healthService: _FakeHealthService(steps: 5100));
      await data.load();
      final yesterday = DateTime(2026, 9, 4, 13);
      expect(
        await data.addFoodForDate(
          FoodEntry(
            id: 'yesterday-food',
            name: 'Yesterday meal',
            grams: 100,
            kcal: 400,
            proteinG: 20,
            fatG: 10,
            carbsG: 30,
            meal: MealType.lunch,
            time: yesterday,
          ),
          '2026-09-04',
        ),
        isTrue,
      );
      expect(await data.setWaterForDate(1.8, '2026-09-04'), isTrue);
      expect(await data.addFood(food()), isTrue);
      expect(await data.setWater(0.75), isTrue);

      data.selectDashboardDate(yesterday);
      final oldDay = data.dashboardDay();
      expect(oldDay.caloriesConsumed, 400);
      expect(oldDay.calorieGoal, 1600);
      expect(oldDay.waterConsumedLiters, 1.8);
      expect(oldDay.steps, 8420);
      expect(oldDay.foodEntries.single.name, 'Yesterday meal');

      expect(
        await data.updateFoodGramsForDate('yesterday-food', 200, '2026-09-04'),
        isTrue,
      );
      expect(data.dashboardDay().caloriesConsumed, 800);
      expect(data.dashboardDay(now).caloriesConsumed, 200);
      expect(data.dashboardDay(now).waterConsumedLiters, 0.75);

      final relaunched = provider(
        healthService: _FakeHealthService(steps: 5100),
      );
      await relaunched.load();
      relaunched.selectDashboardDate(yesterday);
      expect(relaunched.dashboardDay().caloriesConsumed, 800);
      expect(relaunched.dashboardDay().waterConsumedLiters, 1.8);
      expect(relaunched.dashboardDay().steps, 8420);
    },
  );

  test(
    'water goal is capped at 2500 ml while consumed water can exceed it',
    () async {
      now = DateTime(2026, 9, 5, 12);
      final data = provider();
      await data.load();

      expect(await data.setWaterGoalLiters(3), 2.5);
      expect(await data.setWater(2.8), isTrue);
      expect(data.waterGoalLiters, 2.5);
      expect(data.dashboardDay().waterConsumedLiters, 2.8);

      final relaunched = provider();
      await relaunched.load();
      expect(relaunched.waterGoalLiters, 2.5);
      expect(relaunched.waterLiters, 2.8);
    },
  );
}
