import 'dart:math';

import '../models/history_models.dart';
import '../models/user_profile.dart';
import 'progress_series.dart';
import '../models/weight_forecast.dart';
import '../utils/calendar_date.dart';

export '../models/weight_forecast.dart';

enum AnalyticsConfidence { insufficient, low, medium, high }

class BalanceAdvice {
  final AdviceType type;
  final int priority;
  final String ru;
  final String en;

  const BalanceAdvice({
    required this.type,
    required this.priority,
    required this.ru,
    required this.en,
  });
}

class WeightTrendPoint {
  final DateTime date;
  final double kg;

  const WeightTrendPoint({required this.date, required this.kg});
}

class WeightAnalytics {
  final int periodDays;
  final DateTime periodStart;
  final List<WeightEntry> actualWeights;
  final List<WeightTrendPoint> trendPoints;
  final List<WeightForecastPoint> forecastPoints;
  final WeightForecastSnapshot? forecast;
  final double? actualWeightChange;
  final double? smoothedWeightChange;
  final double? observedWeeklyTrendKg;
  final double? energyWeeklyTrendKg;
  final double? estimatedWeeklyWeightTrendKg;
  final double? averageCalories;
  final double? averageCalories7Days;
  final double? averageCalories14Days;
  final double? averageCalories30Days;
  final double? averageCalorieBalance;
  final double? averageProtein;
  final double? averageFat;
  final double? averageCarbs;
  final double? averageSteps;
  final double? previousAverageSteps;
  final double? activityChangePercent;
  final double? averageWater;
  final double waterGoalAdherence;
  final double foodTargetAdherence;
  final double adherenceScore;
  final double? averageMealCount;
  final double mealTimingRegularity;
  final double dataCompleteness;
  final double measurementNoiseKg;
  final int loggedDays;
  final int foodDays;
  final int stepDays;
  final int waterDays;
  final int activeDays;
  final int waterGoalDays;
  final int? estimatedWeeksToGoal;
  final DateTime? estimatedGoalDate;
  final AnalyticsConfidence confidence;
  final String insightRu;
  final String insightEn;
  final BalanceAdvice advice;

  const WeightAnalytics({
    required this.periodDays,
    required this.periodStart,
    required this.actualWeights,
    required this.trendPoints,
    required this.forecastPoints,
    this.forecast,
    required this.actualWeightChange,
    required this.smoothedWeightChange,
    required this.observedWeeklyTrendKg,
    required this.energyWeeklyTrendKg,
    required this.estimatedWeeklyWeightTrendKg,
    required this.averageCalories,
    required this.averageCalories7Days,
    required this.averageCalories14Days,
    required this.averageCalories30Days,
    required this.averageCalorieBalance,
    required this.averageProtein,
    required this.averageFat,
    required this.averageCarbs,
    required this.averageSteps,
    required this.previousAverageSteps,
    required this.activityChangePercent,
    required this.averageWater,
    required this.waterGoalAdherence,
    required this.foodTargetAdherence,
    required this.adherenceScore,
    required this.averageMealCount,
    required this.mealTimingRegularity,
    required this.dataCompleteness,
    required this.measurementNoiseKg,
    required this.loggedDays,
    required this.foodDays,
    required this.stepDays,
    required this.waterDays,
    required this.activeDays,
    required this.waterGoalDays,
    required this.estimatedWeeksToGoal,
    required this.estimatedGoalDate,
    required this.confidence,
    required this.insightRu,
    required this.insightEn,
    required this.advice,
  });

  bool get hasEnoughData => confidence != AnalyticsConfidence.insufficient;
}

/// Pure derived analytics. Source records remain owned by [AppDataProvider].
class BalanceAnalyticsService {
  const BalanceAnalyticsService();

  WeightAnalytics calculate({
    required UserProfile profile,
    required List<WeightEntry> weights,
    required List<DailyBalanceSnapshot> dailyBalances,
    required int periodDays,
    required DateTime now,
    required double waterGoalLiters,
    List<CalorieGoalHistoryEntry> calorieGoalHistory = const [],
    AdviceType? previousAdviceType,
    WeightForecastSnapshot? forecastSnapshot,
  }) {
    final today = _day(now);
    final window = ProgressWindow(days: periodDays, now: now);
    final periodStart = window.start;
    final actual =
        weights.where((entry) => window.contains(entry.date)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final allActual =
        weights
            .where((entry) => entry.date.isBefore(window.endExclusive))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final days = dailyBalances.where((entry) {
      final date = _parseDateKey(entry.dateKey);
      return date != null &&
          !date.isBefore(periodStart) &&
          !date.isAfter(today);
    }).toList()..sort((a, b) => a.dateKey.compareTo(b.dateKey));

    final trend = _ema(actual);
    final observedWeekly = _observedWeeklyTrend(trend);
    final noise = _measurementNoise(actual, trend);
    final foodDays = days.where((day) => day.caloriesEaten > 0).toList();
    final stepDays = days.where((day) => day.stepCount != null).toList();
    final waterDays = days.where((day) => day.waterLiters > 0).toList();
    final relevantDayCount = _relevantDayCount(
      periodStart: periodStart,
      today: today,
      days: days,
      actual: actual,
    );
    final foodCoverage = relevantDayCount == 0
        ? 0.0
        : foodDays.length / relevantDayCount;
    final stepCoverage = relevantDayCount == 0
        ? 0.0
        : stepDays.length / relevantDayCount;
    final waterCoverage = relevantDayCount == 0
        ? 0.0
        : waterDays.length / relevantDayCount;

    final averageCalories = _average(foodDays.map((day) => day.caloriesEaten));
    final averageCalories7Days = _rollingCalories(dailyBalances, today, 7);
    final averageCalories14Days = _rollingCalories(dailyBalances, today, 14);
    final averageCalories30Days = _rollingCalories(dailyBalances, today, 30);
    final averageCalorieBalance = _average(
      foodDays.map(
        (day) =>
            day.caloriesEaten - _targetForDay(day, calorieGoalHistory, profile),
      ),
    );
    final proteinDays = foodDays.where((day) => day.proteinG > 0).toList();
    final averageProtein = _average(proteinDays.map((day) => day.proteinG));
    final averageFat = _average(foodDays.map((day) => day.fatG));
    final averageCarbs = _average(foodDays.map((day) => day.carbsG));
    final averageSteps = _average(stepDays.map((day) => day.stepCount!));
    final averageWater = _average(waterDays.map((day) => day.waterLiters));
    final averageMealCount = _average(foodDays.map((day) => day.mealCount));
    final mealTimingRegularity = _mealTimingRegularity(foodDays);
    final activeDays = stepDays.where((day) => day.stepCount! >= 7000).length;
    final waterGoalDays = days
        .where((day) => day.waterLiters >= waterGoalLiters)
        .length;
    final waterGoalAdherence = relevantDayCount == 0
        ? 0.0
        : waterGoalDays / relevantDayCount;
    final foodTargetAdherence = relevantDayCount == 0
        ? 0.0
        : foodDays
                  .where(
                    (day) =>
                        (day.caloriesEaten -
                                _targetForDay(day, calorieGoalHistory, profile))
                            .abs() <=
                        max(
                          150,
                          _targetForDay(day, calorieGoalHistory, profile) * 0.1,
                        ),
                  )
                  .length /
              relevantDayCount;
    final adherenceScore = _clamp01(
      foodTargetAdherence * 0.55 +
          waterGoalAdherence * 0.15 +
          stepCoverage * 0.15 +
          mealTimingRegularity * 0.15,
    );

    final comparisonWindow = min(periodDays, 14);
    final currentComparisonSteps = _averageStepsInWindow(
      dailyBalances,
      today.subtract(Duration(days: comparisonWindow - 1)),
      today,
    );
    final previousSteps = _averageStepsInWindow(
      dailyBalances,
      today.subtract(Duration(days: comparisonWindow * 2 - 1)),
      today.subtract(Duration(days: comparisonWindow)),
    );
    final activityChangePercent =
        currentComparisonSteps == null ||
            previousSteps == null ||
            previousSteps <= 0
        ? null
        : ((currentComparisonSteps - previousSteps) / previousSteps) * 100;

    final energyWeekly = _energyWeeklyTrend(profile: profile, days: foodDays);
    final spanDays = actual.length < 2
        ? 0
        : _day(actual.last.date).difference(_day(actual.first.date)).inDays;
    final regularity = _measurementRegularity(actual);
    final observedReliability = _clamp01(
      _clamp01((actual.length - 2) / 8) * 0.35 +
          _clamp01(spanDays / 30) * 0.30 +
          regularity * 0.20 +
          (1 - _clamp01(noise / 1.2)) * 0.15,
    );
    final energyReliability = _clamp01(
      foodCoverage * 0.65 + stepCoverage * 0.35,
    );
    final blendedWeekly = _blendTrends(
      observedWeekly: observedWeekly,
      energyWeekly: energyWeekly,
      observedReliability: observedReliability,
      energyReliability: energyReliability,
    );
    final completeness = _clamp01(
      foodCoverage * 0.45 +
          stepCoverage * 0.30 +
          waterCoverage * 0.10 +
          _clamp01(actual.length / max(3, periodDays / 4)) * 0.15,
    );
    final confidence = _confidence(
      actualCount: actual.length,
      spanDays: spanDays,
      foodCoverage: foodCoverage,
      stepCoverage: stepCoverage,
      regularity: regularity,
      noise: noise,
      blendedWeekly: blendedWeekly,
    );

    final prediction =
        forecastSnapshot ?? calculateForecast(weights: weights, now: now);
    final forecast = prediction.project(
      latest: allActual.isEmpty ? null : allActual.last,
      maxDays: periodDays <= 7 ? 7 : 14,
      now: now,
    );
    final goalEstimate = _goalEstimate(
      profile: profile,
      currentWeight: allActual.isEmpty ? profile.weightKg : allActual.last.kg,
      weeklyTrend: blendedWeekly,
      confidence: confidence,
      now: today,
    );
    final actualChange = actual.length < 2
        ? null
        : actual.last.kg - actual.first.kg;
    final smoothChange = trend.length < 2
        ? null
        : trend.last.kg - trend.first.kg;
    final insight = _insight(
      profile: profile,
      actualChange: actualChange,
      smoothChange: smoothChange,
      averageCalorieBalance: averageCalorieBalance,
      averageSteps: averageSteps,
      activityChangePercent: activityChangePercent,
      noise: noise,
      confidence: confidence,
      spanDays: spanDays,
    );
    final advice = _dailyAdvice(
      profile: profile,
      now: now,
      days: days,
      actual: actual,
      foodDays: foodDays,
      proteinDays: proteinDays,
      averageCalories14Days: averageCalories14Days,
      averageCalorieBalance: averageCalorieBalance,
      averageProtein: averageProtein,
      activityChangePercent: activityChangePercent,
      averageWater: averageWater,
      waterGoalLiters: waterGoalLiters,
      previousAdviceType: previousAdviceType,
      relevantDayCount: relevantDayCount,
    );

    return WeightAnalytics(
      periodDays: periodDays,
      periodStart: periodStart,
      actualWeights: List.unmodifiable(actual),
      trendPoints: List.unmodifiable(trend),
      forecastPoints: List.unmodifiable(forecast),
      forecast: prediction,
      actualWeightChange: actualChange,
      smoothedWeightChange: smoothChange,
      observedWeeklyTrendKg: observedWeekly,
      energyWeeklyTrendKg: energyWeekly,
      estimatedWeeklyWeightTrendKg: blendedWeekly,
      averageCalories: averageCalories,
      averageCalories7Days: averageCalories7Days,
      averageCalories14Days: averageCalories14Days,
      averageCalories30Days: averageCalories30Days,
      averageCalorieBalance: averageCalorieBalance,
      averageProtein: averageProtein,
      averageFat: averageFat,
      averageCarbs: averageCarbs,
      averageSteps: averageSteps,
      previousAverageSteps: previousSteps,
      activityChangePercent: activityChangePercent,
      averageWater: averageWater,
      waterGoalAdherence: waterGoalAdherence,
      foodTargetAdherence: foodTargetAdherence,
      adherenceScore: adherenceScore,
      averageMealCount: averageMealCount,
      mealTimingRegularity: mealTimingRegularity,
      dataCompleteness: completeness,
      measurementNoiseKg: noise,
      loggedDays: relevantDayCount,
      foodDays: foodDays.length,
      stepDays: stepDays.length,
      waterDays: waterDays.length,
      activeDays: activeDays,
      waterGoalDays: waterGoalDays,
      estimatedWeeksToGoal: goalEstimate.$1,
      estimatedGoalDate: goalEstimate.$2,
      confidence: confidence,
      insightRu: insight.$1,
      insightEn: insight.$2,
      advice: advice,
    );
  }

  int _targetForDay(
    DailyBalanceSnapshot day,
    List<CalorieGoalHistoryEntry> history,
    UserProfile profile,
  ) {
    if (day.calorieTarget != null) return day.calorieTarget!;
    final date = _parseDateKey(day.dateKey);
    if (date != null) {
      CalorieGoalHistoryEntry? match;
      for (final entry in history) {
        final effective = _day(entry.effectiveFrom);
        if (!effective.isAfter(date) &&
            (match == null ||
                entry.effectiveFrom.isAfter(match.effectiveFrom))) {
          match = entry;
        }
      }
      if (match != null) return match.calories;
    }
    return profile.effectiveCalorieGoal;
  }

  List<WeightTrendPoint> _ema(List<WeightEntry> actual) {
    if (actual.length < 3) return const [];
    final period = min(7, actual.length);
    final alpha = 2 / (period + 1);
    var value = actual.first.kg;
    return [
      for (final entry in actual)
        WeightTrendPoint(
          date: entry.date,
          kg: value = value + alpha * (entry.kg - value),
        ),
    ];
  }

  double? _observedWeeklyTrend(List<WeightTrendPoint> points) {
    if (points.length < 3) return null;
    final origin = _day(points.first.date);
    final xs = points
        .map((point) => _day(point.date).difference(origin).inHours / 24)
        .toList();
    if (xs.last < 7) return null;
    final ys = points.map((point) => point.kg).toList();
    final meanX = _average(xs)!;
    final meanY = _average(ys)!;
    var numerator = 0.0;
    var denominator = 0.0;
    for (var index = 0; index < xs.length; index++) {
      numerator += (xs[index] - meanX) * (ys[index] - meanY);
      denominator += pow(xs[index] - meanX, 2);
    }
    if (denominator <= 0) return null;
    return (numerator / denominator * 7).clamp(-2.0, 2.0).toDouble();
  }

  double _measurementNoise(
    List<WeightEntry> actual,
    List<WeightTrendPoint> trend,
  ) {
    if (actual.length < 3 || actual.length != trend.length) return 0;
    final residuals = <double>[
      for (var index = 0; index < actual.length; index++)
        actual[index].kg - trend[index].kg,
    ];
    final mean = _average(residuals)!;
    final variance =
        residuals.fold<double>(0, (sum, value) => sum + pow(value - mean, 2)) /
        residuals.length;
    return sqrt(variance);
  }

  double _measurementRegularity(List<WeightEntry> actual) {
    if (actual.length < 3) return actual.length == 2 ? 0.35 : 0;
    final intervals = <double>[];
    for (var index = 1; index < actual.length; index++) {
      final days =
          _day(
            actual[index].date,
          ).difference(_day(actual[index - 1].date)).inHours.abs() /
          24;
      intervals.add(max(0.25, days));
    }
    final mean = _average(intervals)!;
    if (mean == 0) return 0;
    final variance =
        intervals.fold<double>(0, (sum, value) => sum + pow(value - mean, 2)) /
        intervals.length;
    final coefficientOfVariation = sqrt(variance) / mean;
    return 1 - _clamp01(coefficientOfVariation / 1.5);
  }

  double? _energyWeeklyTrend({
    required UserProfile profile,
    required List<DailyBalanceSnapshot> days,
  }) {
    if (days.length < 5) return null;
    final baselineSteps = switch (profile.activityLevel) {
      ActivityLevel.sedentary => 3000,
      ActivityLevel.light => 5000,
      ActivityLevel.moderate => 7500,
      ActivityLevel.active => 10000,
    };
    var totalBalance = 0.0;
    for (final day in days) {
      final maintenance =
          day.maintenanceCalories ??
          _legacyMaintenanceEstimate(day.calorieTarget, profile);
      final steps = day.stepCount ?? baselineSteps;
      final strideMeters = profile.heightCm / 100 * 0.415;
      final extraDistanceKm = (steps - baselineSteps) * strideMeters / 1000;
      final activityEstimate = (extraDistanceKm * profile.weightKg * 0.5).clamp(
        -500,
        800,
      );
      totalBalance += day.caloriesEaten - maintenance - activityEstimate;
    }
    final averageBalance = totalBalance / days.length;
    return (averageBalance * 7 / 7700).clamp(-1.5, 1.5).toDouble();
  }

  int _legacyMaintenanceEstimate(int? recordedTarget, UserProfile profile) {
    if (recordedTarget == null) return profile.maintenanceCalorieEstimate;
    // Older snapshots did not persist maintenance calories. Reconstruct the
    // former goal adjustment as closely as possible without changing storage.
    return switch (profile.goal) {
      Goal.lose => recordedTarget + 450,
      Goal.hold => recordedTarget,
      Goal.gain => recordedTarget - 400,
    };
  }

  double? _blendTrends({
    required double? observedWeekly,
    required double? energyWeekly,
    required double observedReliability,
    required double energyReliability,
  }) {
    if (observedWeekly == null && energyWeekly == null) return null;
    if (observedWeekly == null) {
      return energyReliability >= 0.45 ? energyWeekly : null;
    }
    if (energyWeekly == null || energyReliability < 0.25) return observedWeekly;
    final observedShare = (0.5 + observedReliability * 0.4).clamp(0.5, 0.9);
    final adjustedEnergyShare = (1 - observedShare) * energyReliability;
    final denominator = observedShare + adjustedEnergyShare;
    return ((observedWeekly * observedShare +
                energyWeekly * adjustedEnergyShare) /
            denominator)
        .clamp(-1.5, 1.5)
        .toDouble();
  }

  AnalyticsConfidence _confidence({
    required int actualCount,
    required int spanDays,
    required double foodCoverage,
    required double stepCoverage,
    required double regularity,
    required double noise,
    required double? blendedWeekly,
  }) {
    if (blendedWeekly == null || actualCount < 2 || spanDays < 6) {
      return AnalyticsConfidence.insufficient;
    }
    if (actualCount >= 8 &&
        spanDays >= 27 &&
        foodCoverage >= 0.7 &&
        stepCoverage >= 0.65 &&
        regularity >= 0.5 &&
        noise <= 0.8) {
      return AnalyticsConfidence.high;
    }
    if (actualCount >= 4 &&
        spanDays >= 14 &&
        foodCoverage >= 0.5 &&
        stepCoverage >= 0.35 &&
        noise <= 1.1) {
      return AnalyticsConfidence.medium;
    }
    return AnalyticsConfidence.low;
  }

  WeightForecastSnapshot calculateForecast({
    required List<WeightEntry> weights,
    required DateTime now,
  }) {
    final records = forecastSourceRecords(weights);
    final sourceHash = forecastSourceHash(records);
    final today = localDateKey(now);
    final valid =
        weights
            .where(
              (entry) =>
                  entry.kg.isFinite &&
                  entry.kg >= 20 &&
                  entry.kg <= 400 &&
                  localDateKey(entry.date).compareTo(today) <= 0,
            )
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            return byDate == 0 ? a.id.compareTo(b.id) : byDate;
          });
    final grouped = <String, List<double>>{};
    final used = <WeightEntry>[];
    for (final entry in valid) {
      if (calendarDayDifference(today, localDateKey(entry.date)) >= 28) {
        continue;
      }
      grouped.putIfAbsent(localDateKey(entry.date), () => []).add(entry.kg);
      used.add(entry);
    }
    final dates = grouped.keys.toList()..sort();
    final span = dates.isEmpty
        ? 0
        : calendarDayDifference(dates.last, dates.first) + 1;
    final daily = <({double x, double y})>[
      for (final date in dates)
        (
          x: calendarDayDifference(date, dates.first).toDouble(),
          y: _forecastQuantile(grouped[date]!, .5),
        ),
    ];
    WeightForecastSnapshot result(
      WeightForecastStatus status,
      String reason, {
      double? slope,
      double? lower,
      double? upper,
      int outliers = 0,
    }) => WeightForecastSnapshot(
      status: status,
      reason: reason,
      sourceHash: sourceHash,
      usedSourceHash: forecastSourceHash(forecastSourceRecords(used)),
      sourceRecords: records,
      calculatedAt: status == WeightForecastStatus.collecting ? null : now,
      calculatedDateKey: status == WeightForecastStatus.collecting
          ? null
          : today,
      anchorDate: valid.isEmpty ? null : valid.last.date,
      anchorKg: valid.isEmpty ? null : valid.last.kg,
      dailyCount: daily.length,
      spanDays: span,
      horizonDays: daily.length >= 8 && span >= 14 ? 14 : 7,
      slopePerDay: slope,
      lowerSlope: lower,
      upperSlope: upper,
      outlierCount: outliers,
    );
    if (daily.length < 4 || span < 7) {
      return result(WeightForecastStatus.collecting, 'collecting');
    }
    final firstFit = _forecastFit(daily);
    if (firstFit == null) {
      return result(WeightForecastStatus.unreliable, 'quality');
    }
    final residuals = daily
        .map((p) => p.y - (firstFit.$2 + firstFit.$1 * p.x))
        .toList();
    final centre = _forecastQuantile(residuals, .5);
    final noise =
        1.4826 *
        _forecastQuantile(
          residuals.map((r) => (r - centre).abs()).toList(),
          .5,
        );
    final threshold = max(.6, noise * 3.5);
    final inliers = <({double x, double y})>[
      for (var i = 0; i < daily.length; i++)
        if ((residuals[i] - centre).abs() <= threshold) daily[i],
    ];
    final rejected = daily.length - inliers.length;
    if (inliers.length < 4 ||
        rejected / daily.length > .25 ||
        inliers.last.x - inliers.first.x < 6) {
      return result(
        WeightForecastStatus.unreliable,
        'outliers',
        outliers: rejected,
      );
    }
    final fit = _forecastFit(inliers)!;
    final errors = inliers
        .map((p) => (p.y - fit.$2 - fit.$1 * p.x).abs())
        .toList();
    final scatter = _forecastQuantile(errors, .8);
    final anchorX = calendarDayDifference(
      localDateKey(valid.last.date),
      dates.first,
    ).toDouble();
    final anchorError = (valid.last.kg - fit.$2 - fit.$1 * anchorX).abs();
    if (scatter > .8 || anchorError > max(.8, scatter * 3)) {
      return result(
        WeightForecastStatus.unreliable,
        'noise',
        outliers: rejected,
      );
    }
    if (fit.$1.abs() * 7 > 1.5) {
      return result(
        WeightForecastStatus.unreliable,
        'rate',
        outliers: rejected,
      );
    }
    final half = inliers.length ~/ 2;
    if (half >= 3) {
      final early = _forecastFit(inliers.sublist(0, half))?.$1 ?? 0;
      final late = _forecastFit(inliers.sublist(half))?.$1 ?? 0;
      if (early * late < 0 && early.abs() > .035 && late.abs() > .035) {
        return result(
          WeightForecastStatus.unreliable,
          'unstable',
          outliers: rejected,
        );
      }
    }
    double? lower;
    double? upper;
    if (inliers.length >= 8) {
      final random = Random(int.parse(sourceHash.substring(0, 8), radix: 16));
      final slopes = <double>[];
      for (var run = 0; run < 200; run++) {
        final sample = List.generate(
          inliers.length,
          (_) => inliers[random.nextInt(inliers.length)],
        );
        final estimate = _forecastFit(sample);
        if (estimate != null) slopes.add(estimate.$1);
      }
      if (slopes.length >= 100) {
        lower = min(fit.$1, _forecastQuantile(slopes, .1));
        upper = max(fit.$1, _forecastQuantile(slopes, .9));
        if (upper - lower > .18) {
          return result(
            WeightForecastStatus.unreliable,
            'unstable',
            outliers: rejected,
          );
        }
      }
    }
    return result(
      WeightForecastStatus.ready,
      'ready',
      slope: fit.$1,
      lower: lower,
      upper: upper,
      outliers: rejected,
    );
  }

  (double, double)? _forecastFit(List<({double x, double y})> points) {
    final slopes = <double>[];
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final dx = points[j].x - points[i].x;
        if (dx != 0) slopes.add((points[j].y - points[i].y) / dx);
      }
    }
    if (slopes.isEmpty) return null;
    final slope = _forecastQuantile(slopes, .5);
    return (
      slope,
      _forecastQuantile(points.map((p) => p.y - slope * p.x).toList(), .5),
    );
  }

  double _forecastQuantile(List<double> values, double q) {
    final sorted = [...values]..sort();
    final position = (sorted.length - 1) * q;
    final index = position.floor();
    return sorted[index] +
        (sorted[position.ceil()] - sorted[index]) * (position - index);
  }

  (int?, DateTime?) _goalEstimate({
    required UserProfile profile,
    required double currentWeight,
    required double? weeklyTrend,
    required AnalyticsConfidence confidence,
    required DateTime now,
  }) {
    if (profile.goal == Goal.hold ||
        weeklyTrend == null ||
        confidence.index < AnalyticsConfidence.medium.index ||
        weeklyTrend.abs() < 0.1 ||
        weeklyTrend.abs() > 1.5) {
      return (null, null);
    }
    final distance = profile.targetWeightKg - currentWeight;
    if (distance.abs() < 0.1 || distance.sign != weeklyTrend.sign) {
      return (null, null);
    }
    final weeks = (distance.abs() / weeklyTrend.abs()).ceil();
    if (weeks < 1 || weeks > 156) return (null, null);
    return (weeks, now.add(Duration(days: weeks * 7)));
  }

  BalanceAdvice _dailyAdvice({
    required UserProfile profile,
    required DateTime now,
    required List<DailyBalanceSnapshot> days,
    required List<WeightEntry> actual,
    required List<DailyBalanceSnapshot> foodDays,
    required List<DailyBalanceSnapshot> proteinDays,
    required double? averageCalories14Days,
    required double? averageCalorieBalance,
    required double? averageProtein,
    required double? activityChangePercent,
    required double? averageWater,
    required double waterGoalLiters,
    required AdviceType? previousAdviceType,
    required int relevantDayCount,
  }) {
    final candidates = <BalanceAdvice>[];
    final target = profile.effectiveCalorieGoal;
    final actual14 = actual
        .where(
          (entry) => !_day(
            entry.date,
          ).isBefore(_day(now).subtract(const Duration(days: 13))),
        )
        .toList();
    final weightChange14 = actual14.length < 2
        ? null
        : actual14.last.kg - actual14.first.kg;
    final movingTowardGoal =
        weightChange14 != null &&
        weightChange14.abs() >= 0.15 &&
        ((profile.goal == Goal.lose && weightChange14 < 0) ||
            (profile.goal == Goal.gain && weightChange14 > 0));
    final caloriesNearTarget =
        averageCalorieBalance != null &&
        averageCalorieBalance.abs() <= max(150, target * 0.1);

    if (foodDays.length < 3 && actual.length < 2) {
      candidates.add(
        const BalanceAdvice(
          type: AdviceType.dataIncomplete,
          priority: 100,
          ru: 'Пока данных недостаточно для персонального совета. Записывай питание и фактический вес несколько дней — Balance соберёт устойчивую картину без выводов по одному дню.',
          en: 'There is not enough data for a personal recommendation yet. Log food and actual weight for a few days so Balance can build a stable picture without judging a single day.',
        ),
      );
    }

    final sustainedThreshold = max(180, target * 0.12);
    if (foodDays.length >= 4 &&
        averageCalorieBalance != null &&
        averageCalorieBalance.abs() >= sustainedThreshold) {
      final average = (averageCalories14Days ?? target + averageCalorieBalance)
          .round();
      final difference = averageCalorieBalance.abs().round();
      if (averageCalorieBalance > 0) {
        final goalTextRu = switch (profile.goal) {
          Goal.lose =>
            'Для движения к цели сначала проверь полноту порций и напитков — снижать саму норму не нужно.',
          Goal.hold =>
            'Если это не было запланировано, небольшая коррекция порций поможет вернуться к поддержанию.',
          Goal.gain =>
            'Темп лучше оценивать вместе с трендом веса, не по отдельному дню.',
        };
        final goalTextEn = switch (profile.goal) {
          Goal.lose =>
            'For progress toward the goal, first check portion and drink logging; there is no need to lower the target itself.',
          Goal.hold =>
            'If this was not intentional, a small portion adjustment can help return to maintenance.',
          Goal.gain =>
            'It is better to judge the pace together with the weight trend, not from one day.',
        };
        candidates.add(
          BalanceAdvice(
            type: AdviceType.caloriesHigh,
            priority: 92,
            ru: 'Средний рацион — около $average ккал, это на $difference ккал выше дневной нормы. $goalTextRu',
            en: 'Average intake is about $average kcal, $difference kcal above the daily target. $goalTextEn',
          ),
        );
      } else {
        final goalTextRu = profile.goal == Goal.gain
            ? 'Для набора веса полезнее приблизить рацион к выбранной норме постепенно.'
            : 'Сильнее сокращать рацион сейчас не стоит; важнее устойчивость и полноценность питания.';
        final goalTextEn = profile.goal == Goal.gain
            ? 'For weight gain, it is more useful to move toward the chosen target gradually.'
            : 'There is no need to cut intake further now; consistency and adequate nutrition matter more.';
        candidates.add(
          BalanceAdvice(
            type: AdviceType.caloriesLow,
            priority: 92,
            ru: 'Средний рацион — около $average ккал, это на $difference ккал ниже дневной нормы. $goalTextRu',
            en: 'Average intake is about $average kcal, $difference kcal below the daily target. $goalTextEn',
          ),
        );
      }
    }

    final proteinCoverage = foodDays.isEmpty
        ? 0.0
        : proteinDays.length / foodDays.length;
    if (proteinDays.length >= 3 &&
        proteinCoverage >= 0.5 &&
        averageProtein != null &&
        averageProtein < profile.proteinTargetG * 0.8) {
      candidates.add(
        BalanceAdvice(
          type: AdviceType.protein,
          priority: 78,
          ru: 'В дни с заполненными БЖУ белка в среднем ${averageProtein.round()} г при ориентире ${profile.proteinTargetG} г. Попробуй добавить удобный источник белка в один из привычных приёмов пищи.',
          en: 'On days with complete macro data, protein averages ${averageProtein.round()} g against a ${profile.proteinTargetG} g guide. Try adding a convenient protein source to one regular meal.',
        ),
      );
    }

    if (movingTowardGoal && caloriesNearTarget) {
      final delta = weightChange14.abs().toStringAsFixed(1);
      final signedDelta = profile.goal == Goal.gain ? '+$delta' : '−$delta';
      final activityRu =
          activityChangePercent != null && activityChangePercent >= 10
          ? ' Активность выросла примерно на ${activityChangePercent.round()}%.'
          : '';
      final activityEn =
          activityChangePercent != null && activityChangePercent >= 10
          ? ' Activity increased by about ${activityChangePercent.round()}%.'
          : '';
      candidates.add(
        BalanceAdvice(
          type: AdviceType.weightTrend,
          priority: 76,
          ru: 'За последние две недели вес постепенно движется к цели ($signedDelta кг). Средний рацион остаётся близко к дневной норме.$activityRu ${profile.goal == Goal.gain ? "Сейчас нет необходимости резко повышать калорийность." : "Сейчас нет необходимости сильнее снижать калорийность."}',
          en: 'Over the last two weeks, weight has been moving gradually toward the goal ($signedDelta kg). Average intake remains close to the daily target.$activityEn ${profile.goal == Goal.gain ? "There is no need to increase calories sharply now." : "There is no need to reduce calories further now."}',
        ),
      );
    } else if (weightChange14 != null && weightChange14.abs() >= 0.2) {
      final directionRu = weightChange14 < 0 ? 'снизился' : 'вырос';
      final directionEn = weightChange14 < 0 ? 'decreased' : 'increased';
      candidates.add(
        BalanceAdvice(
          type: AdviceType.weightTrend,
          priority: 66,
          ru: 'За последние две недели вес $directionRu примерно на ${weightChange14.abs().toStringAsFixed(1)} кг. Сопоставляй это со средней калорийностью и оценивай тренд, а не отдельное измерение.',
          en: 'Over the last two weeks, weight $directionEn by about ${weightChange14.abs().toStringAsFixed(1)} kg. Compare this with average intake and focus on the trend, not one measurement.',
        ),
      );
    }

    if (activityChangePercent != null && activityChangePercent.abs() >= 15) {
      final up = activityChangePercent > 0;
      candidates.add(
        BalanceAdvice(
          type: AdviceType.activity,
          priority: 58,
          ru: 'Средняя активность ${up ? "выросла" : "снизилась"} примерно на ${activityChangePercent.abs().round()}% относительно предыдущего периода. Сохраняй комфортный темп и смотри, как на него реагирует общий тренд.',
          en: 'Average activity ${up ? "increased" : "decreased"} by about ${activityChangePercent.abs().round()}% versus the previous period. Keep the pace comfortable and watch the overall trend.',
        ),
      );
    }

    DailyBalanceSnapshot? today;
    final todayKey = _dateKey(now);
    for (final day in days) {
      if (day.dateKey == todayKey) today = day;
    }
    if (now.hour >= 17 &&
        today != null &&
        today.waterLiters > 0 &&
        today.waterLiters < waterGoalLiters * 0.65) {
      candidates.add(
        BalanceAdvice(
          type: AdviceType.water,
          priority: 50,
          ru: 'Сегодня отмечено ${today.waterLiters.toStringAsFixed(1)} л воды при ориентире ${waterGoalLiters.toStringAsFixed(1)} л. Если тебе комфортно, распределённо добавь воду до конца дня.',
          en: '${today.waterLiters.toStringAsFixed(1)} L of water is logged today against a ${waterGoalLiters.toStringAsFixed(1)} L guide. If comfortable, add water gradually through the rest of the day.',
        ),
      );
    }

    if (candidates.isEmpty ||
        candidates.every((value) => value.priority < 70)) {
      final waterContext = averageWater != null
          ? ' Среднее количество воды — ${averageWater.toStringAsFixed(1)} л.'
          : '';
      candidates.add(
        BalanceAdvice(
          type: AdviceType.stable,
          priority: relevantDayCount >= 7 ? 42 : 20,
          ru: 'Рацион и активность выглядят достаточно стабильно.$waterContext Продолжай вести записи — устойчивые данные полезнее резких изменений плана.',
          en: 'Food intake and activity look reasonably stable. Keep logging consistently; stable data is more useful than abrupt plan changes.',
        ),
      );
    }

    candidates.sort((a, b) => b.priority.compareTo(a.priority));
    final top = candidates.first;
    if (previousAdviceType == top.type &&
        top.priority < 90 &&
        candidates.length > 1 &&
        top.priority - candidates[1].priority <= 5) {
      return candidates[1];
    }
    return top;
  }

  (String, String) _insight({
    required UserProfile profile,
    required double? actualChange,
    required double? smoothChange,
    required double? averageCalorieBalance,
    required double? averageSteps,
    required double? activityChangePercent,
    required double noise,
    required AnalyticsConfidence confidence,
    required int spanDays,
  }) {
    if (confidence == AnalyticsConfidence.insufficient) {
      return (
        'Собираем данные. Для устойчивой тенденции нужно несколько недель записей еды, шагов и веса.',
        'Collecting data. A stable trend needs several weeks of food, step, and weight records.',
      );
    }
    if (noise >= 0.65) {
      return (
        'Последние измерения заметно колеблются. По текущим данным лучше ориентироваться на сглаженный тренд, а не на отдельную точку.',
        'Recent measurements vary noticeably. Based on current data, the smoothed trend is more useful than a single reading.',
      );
    }
    if (activityChangePercent != null && activityChangePercent >= 10) {
      final rounded = activityChangePercent.round();
      return (
        'Средняя активность за выбранный период выше предыдущего примерно на $rounded%. Оценка веса учитывает это как один из факторов.',
        'Average activity is about $rounded% higher than in the previous period. The weight estimate uses this as one of several factors.',
      );
    }
    final movingTowardGoal =
        smoothChange != null &&
        smoothChange.abs() >= 0.1 &&
        (profile.goal == Goal.lose && smoothChange < 0 ||
            profile.goal == Goal.gain && smoothChange > 0);
    if (movingTowardGoal) {
      final calorieContext = averageCalorieBalance == null
          ? ''
          : averageCalorieBalance.abs() <= 150
          ? ' Средняя калорийность остаётся близко к цели.'
          : averageCalorieBalance < 0
          ? ' Средняя калорийность ниже цели.'
          : ' Средняя калорийность выше цели.';
      final calorieContextEn = averageCalorieBalance == null
          ? ''
          : averageCalorieBalance.abs() <= 150
          ? ' Average calorie intake remains close to the target.'
          : averageCalorieBalance < 0
          ? ' Average calorie intake is below the target.'
          : ' Average calorie intake is above the target.';
      return (
        'За $spanDays дн. сглаженный тренд веса движется к цели.$calorieContext',
        'Across $spanDays days, the smoothed weight trend is moving toward the goal.$calorieContextEn',
      );
    }
    if (actualChange != null && actualChange.abs() < 0.25) {
      return (
        'За выбранный период вес остаётся примерно на одном уровне. Одного короткого периода недостаточно для вывода о плато.',
        'Weight is approximately stable over the selected period. One short period is not enough to conclude that progress has stalled.',
      );
    }
    return (
      'По текущим данным тенденция пока нестабильна. Продолжай регулярно записывать еду, шаги и фактический вес.',
      'The trend is not stable yet. Keep recording food, steps, and actual weight regularly.',
    );
  }

  double? _averageStepsInWindow(
    List<DailyBalanceSnapshot> allDays,
    DateTime start,
    DateTime end,
  ) {
    final values = allDays
        .where((entry) {
          final date = _parseDateKey(entry.dateKey);
          return entry.stepCount != null &&
              date != null &&
              !date.isBefore(start) &&
              !date.isAfter(end);
        })
        .map((entry) => entry.stepCount!);
    return _average(values);
  }

  double? _rollingCalories(
    List<DailyBalanceSnapshot> allDays,
    DateTime today,
    int windowDays,
  ) {
    final start = today.subtract(Duration(days: windowDays - 1));
    return _average(
      allDays
          .where((entry) {
            final date = _parseDateKey(entry.dateKey);
            return entry.caloriesEaten > 0 &&
                date != null &&
                !date.isBefore(start) &&
                !date.isAfter(today);
          })
          .map((entry) => entry.caloriesEaten),
    );
  }

  double _mealTimingRegularity(List<DailyBalanceSnapshot> days) {
    final dailyCenters = <double>[];
    for (final day in days) {
      if (day.mealMinutes.isEmpty) continue;
      final values = [...day.mealMinutes]..sort();
      dailyCenters.add(values[values.length ~/ 2].toDouble());
    }
    if (dailyCenters.length < 3) return 0;
    final mean = _average(dailyCenters)!;
    final variance =
        dailyCenters.fold<double>(
          0,
          (sum, value) => sum + pow(value - mean, 2),
        ) /
        dailyCenters.length;
    return 1 - _clamp01(sqrt(variance) / 180);
  }

  int _relevantDayCount({
    required DateTime periodStart,
    required DateTime today,
    required List<DailyBalanceSnapshot> days,
    required List<WeightEntry> actual,
  }) {
    DateTime? first;
    if (days.isNotEmpty) first = _parseDateKey(days.first.dateKey);
    if (actual.isNotEmpty) {
      final firstWeight = _day(actual.first.date);
      if (first == null || firstWeight.isBefore(first)) first = firstWeight;
    }
    if (first == null) return 0;
    final start = first.isBefore(periodStart) ? periodStart : first;
    return today.difference(start).inDays + 1;
  }

  double? _average(Iterable<num> values) {
    var total = 0.0;
    var count = 0;
    for (final value in values) {
      if (value.isFinite) {
        total += value.toDouble();
        count++;
      }
    }
    return count == 0 ? null : total / count;
  }

  DateTime _day(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  DateTime? _parseDateKey(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  String _dateKey(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  double _clamp01(num value) => value.clamp(0.0, 1.0).toDouble();
}
