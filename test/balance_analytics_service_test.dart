import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/history_models.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/services/balance_analytics_service.dart';

void main() {
  const service = BalanceAnalyticsService();
  final now = DateTime(2026, 9, 2, 12);
  final profile = UserProfile(
    name: 'Test',
    gender: Gender.female,
    age: 32,
    heightCm: 168,
    weightKg: 77.3,
    targetWeightKg: 70,
    activityLevel: ActivityLevel.light,
    goal: Goal.lose,
    onboarded: true,
  );

  WeightEntry weight(int daysAgo, double kg) => WeightEntry(
    id: 'weight-$daysAgo',
    date: now.subtract(Duration(days: daysAgo)),
    kg: kg,
  );

  DailyBalanceSnapshot day(
    int daysAgo, {
    required int calories,
    int? steps = 8200,
    double water = 2,
    double protein = 95,
  }) {
    final date = now.subtract(Duration(days: daysAgo));
    return DailyBalanceSnapshot(
      dateKey:
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      caloriesEaten: calories,
      calorieTarget: profile.calorieTarget,
      maintenanceCalories: profile.maintenanceCalorieEstimate,
      stepCount: steps,
      waterLiters: water,
      proteinG: protein,
      fatG: 55,
      carbsG: 180,
      mealCount: 3,
      mealMinutes: const [480, 780, 1140],
    );
  }

  test('legacy weight and daily records stay readable', () {
    final legacyWeight = WeightEntry.fromJson({
      'date': '2026-08-20T08:00:00',
      'kg': 79.4,
    });
    final legacyDay = DailyBalanceSnapshot.tryFromJson({
      'dateKey': '2026-08-20',
      'caloriesEaten': 1600,
      'stepCount': 7000,
      'waterLiters': 1.8,
      'estimatedWeightKg': 79.2,
    });

    expect(legacyWeight.id, startsWith('legacy-'));
    expect(legacyWeight.source, WeightEntrySource.manual);
    expect(legacyDay, isNotNull);
    expect(legacyDay!.proteinG, 0);
    expect(legacyDay.mealCount, 0);
    expect(legacyDay.calorieTarget, isNull);
    expect(legacyDay.maintenanceCalories, isNull);
  });

  test('does not forecast from one measurement or a few days', () {
    final result = service.calculate(
      profile: profile,
      weights: [weight(0, 77.3)],
      dailyBalances: [
        for (var index = 0; index < 4; index++) day(index, calories: 1500),
      ],
      periodDays: 30,
      now: now,
      waterGoalLiters: 2.5,
    );

    expect(result.confidence, AnalyticsConfidence.insufficient);
    expect(result.forecastPoints, isEmpty);
    expect(result.estimatedWeeksToGoal, isNull);
    expect(result.insightRu, contains('Собираем данные'));
  });

  test(
    'high-quality actual history dominates a conflicting energy estimate',
    () {
      final weights = <WeightEntry>[
        for (var daysAgo = 27; daysAgo >= 0; daysAgo -= 3)
          weight(daysAgo, 77.3 + daysAgo * 0.095),
      ];
      final daily = <DailyBalanceSnapshot>[
        for (var daysAgo = 29; daysAgo >= 0; daysAgo--)
          day(
            daysAgo,
            calories: profile.maintenanceCalorieEstimate + 650,
            steps: 8200,
            water: daysAgo.isEven ? 2.7 : 1.9,
          ),
      ];

      final result = service.calculate(
        profile: profile,
        weights: weights,
        dailyBalances: daily,
        periodDays: 30,
        now: now,
        waterGoalLiters: 2.5,
      );

      expect(result.confidence, AnalyticsConfidence.high);
      expect(result.observedWeeklyTrendKg, isNegative);
      expect(result.energyWeeklyTrendKg, isPositive);
      expect(result.estimatedWeeklyWeightTrendKg, isNegative);
      expect(
        (result.estimatedWeeklyWeightTrendKg! - result.observedWeeklyTrendKg!)
            .abs(),
        lessThan(
          (result.estimatedWeeklyWeightTrendKg! - result.energyWeeklyTrendKg!)
              .abs(),
        ),
      );
      expect(result.forecastPoints, isNotEmpty);
      expect(result.actualWeights.length, weights.length);
      expect(result.forecastPoints, everyElement(isA<WeightForecastPoint>()));
      expect(result.estimatedWeeksToGoal, isNotNull);
      expect(result.averageProtein, closeTo(95, 0.01));
      expect(result.waterGoalDays, 15);
    },
  );

  test('period metrics use only the selected range', () {
    final result = service.calculate(
      profile: profile,
      weights: [weight(40, 90), weight(6, 78), weight(0, 77.3)],
      dailyBalances: [
        day(40, calories: 3000),
        for (var daysAgo = 6; daysAgo >= 0; daysAgo--)
          day(daysAgo, calories: 1500),
      ],
      periodDays: 7,
      now: now,
      waterGoalLiters: 2.5,
    );

    expect(result.actualWeights, hasLength(2));
    expect(result.actualWeightChange, closeTo(-0.7, 0.001));
    expect(result.averageCalories, 1500);
  });

  test('water is context only and does not alter the energy forecast', () {
    final weights = [weight(14, 79), weight(7, 78.5), weight(0, 78)];
    final lowWater = [
      for (var daysAgo = 14; daysAgo >= 0; daysAgo--)
        day(daysAgo, calories: 1500, water: 0.3),
    ];
    final highWater = [
      for (var daysAgo = 14; daysAgo >= 0; daysAgo--)
        day(daysAgo, calories: 1500, water: 3),
    ];

    final low = service.calculate(
      profile: profile,
      weights: weights,
      dailyBalances: lowWater,
      periodDays: 30,
      now: now,
      waterGoalLiters: 2.5,
    );
    final high = service.calculate(
      profile: profile,
      weights: weights,
      dailyBalances: highWater,
      periodDays: 30,
      now: now,
      waterGoalLiters: 2.5,
    );

    expect(low.energyWeeklyTrendKg, high.energyWeeklyTrendKg);
    expect(low.estimatedWeeklyWeightTrendKg, high.estimatedWeeklyWeightTrendKg);
    expect(low.waterGoalAdherence, 0);
    expect(high.waterGoalAdherence, 1);
  });

  test('daily advice combines goal, calories, activity and weight trend', () {
    final adviceProfile = UserProfile(
      name: 'Test',
      gender: Gender.female,
      age: 32,
      heightCm: 168,
      weightKg: 79.5,
      targetWeightKg: 70,
      activityLevel: ActivityLevel.light,
      goal: Goal.lose,
      calorieGoalMode: CalorieGoalMode.manual,
      manualCalories: 1700,
      onboarded: true,
    );
    final weights = [
      WeightEntry(date: now.subtract(const Duration(days: 13)), kg: 80),
      WeightEntry(date: now.subtract(const Duration(days: 7)), kg: 79.8),
      WeightEntry(date: now, kg: 79.5),
    ];
    final daily = <DailyBalanceSnapshot>[
      for (var daysAgo = 27; daysAgo >= 0; daysAgo--)
        DailyBalanceSnapshot(
          dateKey:
              '${now.subtract(Duration(days: daysAgo)).year.toString().padLeft(4, '0')}-'
              '${now.subtract(Duration(days: daysAgo)).month.toString().padLeft(2, '0')}-'
              '${now.subtract(Duration(days: daysAgo)).day.toString().padLeft(2, '0')}',
          caloriesEaten: 1670,
          calorieTarget: 1700,
          maintenanceCalories: adviceProfile.maintenanceCalorieEstimate,
          stepCount: daysAgo >= 14 ? 6800 : 8400,
          waterLiters: 1.7,
          proteinG: 145,
          fatG: 55,
          carbsG: 180,
          mealCount: 3,
        ),
    ];

    final result = service.calculate(
      profile: adviceProfile,
      weights: weights,
      dailyBalances: daily,
      periodDays: 30,
      now: now,
      waterGoalLiters: 2.5,
    );

    expect(result.advice.type, AdviceType.weightTrend);
    expect(result.advice.ru, contains('движется к цели'));
    expect(result.advice.ru, contains('нет необходимости'));
    expect(result.activityChangePercent, greaterThan(20));
  });

  test('legacy days resolve their calorie target from goal history', () {
    final manualProfile = UserProfile(
      weightKg: 77,
      targetWeightKg: 70,
      calorieGoalMode: CalorieGoalMode.manual,
      manualCalories: 1900,
      onboarded: true,
    );
    final legacyDays = [
      for (var daysAgo = 5; daysAgo >= 0; daysAgo--)
        DailyBalanceSnapshot(
          dateKey:
              '${now.subtract(Duration(days: daysAgo)).year.toString().padLeft(4, '0')}-'
              '${now.subtract(Duration(days: daysAgo)).month.toString().padLeft(2, '0')}-'
              '${now.subtract(Duration(days: daysAgo)).day.toString().padLeft(2, '0')}',
          caloriesEaten: 1700,
          stepCount: 7000,
          waterLiters: 2,
        ),
    ];

    final result = service.calculate(
      profile: manualProfile,
      weights: [weight(7, 78), weight(0, 77)],
      dailyBalances: legacyDays,
      calorieGoalHistory: [
        CalorieGoalHistoryEntry(
          effectiveFrom: now.subtract(const Duration(days: 30)),
          calories: 1700,
          mode: CalorieGoalMode.manual,
        ),
      ],
      periodDays: 30,
      now: now,
      waterGoalLiters: 2.5,
    );

    expect(result.averageCalorieBalance, 0);
  });
}
