import 'dart:math' as math;
import '../models/history_models.dart';
import '../models/user_profile.dart';
import '../models/weight_trend_insight.dart';
import '../utils/calendar_date.dart';

class WeightTrendInsightsService {
  const WeightTrendInsightsService();
  static double _median(Iterable<double> source) {
    final x = source.toList()..sort();
    if (x.isEmpty) return 0;
    final m = x.length ~/ 2;
    return x.length.isOdd ? x[m] : (x[m - 1] + x[m]) / 2;
  }

  WeightTrendInsight analyze({
    required Iterable<WeightEntry> weights,
    required DateTime now,
    Goal? goal,
    double? targetKg,
    TipSafetyProfile safety = const TipSafetyProfile(),
  }) {
    final today = localDateKey(now);
    final localNow = now.toLocal();
    final start = localDateKey(
      DateTime(localNow.year, localNow.month, localNow.day - 27),
    );
    final byDay = <String, List<double>>{};
    final ids = <String, WeightEntry>{};
    var rejected = 0;
    for (final e in weights) {
      final key = localDateKey(e.date);
      if (key.compareTo(start) < 0) continue;
      if (key.compareTo(today) > 0 ||
          !e.kg.isFinite ||
          e.kg < 20 ||
          e.kg > 500) {
        rejected++;
        continue;
      }
      final prior = ids[e.id];
      if (prior != null) {
        if (prior.kg != e.kg || !prior.date.isAtSameMomentAs(e.date)) {
          rejected++;
        }
        continue;
      }
      ids[e.id] = e;
      byDay.putIfAbsent(key, () => []).add(e.kg);
    }
    final days = byDay.keys.toList()..sort();
    final values = [for (final d in days) _median(byDay[d]!)];
    final x = [
      for (final d in days) calendarDayDifference(d, days.first).toDouble(),
    ];
    final span = days.isEmpty ? 0 : x.last.toInt() + 1;
    final gap = x.length < 2
        ? 0
        : [
            for (var i = 1; i < x.length; i++) x[i] - x[i - 1],
          ].reduce(math.max).toInt();
    WeightTrendInsight result(
      WeightInsightState state,
      String reason, {
      double? weekly,
      double? change,
      double? noise,
      bool preliminary = true,
    }) => WeightTrendInsight(
      state: state,
      reason: reason,
      calculatedAt: now,
      measuredDays: days.length,
      spanDays: span,
      maxGapDays: gap,
      rejectedRecords: rejected,
      weeklyPercent: weekly,
      changePercent: change,
      noisePercent: noise,
      preliminary: preliminary,
    );
    if (days.length < 4 || span < 7) {
      return result(WeightInsightState.insufficientData, 'short');
    }
    if (rejected > 0 ||
        calendarDayDifference(today, days.last) > 7 ||
        gap > 7 ||
        days.length / span < .3) {
      return result(WeightInsightState.uncertainTrend, 'coverage');
    }
    final slopes = <double>[];
    for (var i = 0; i < x.length; i++) {
      for (var j = i + 1; j < x.length; j++) {
        slopes.add((values[j] - values[i]) / (x[j] - x[i]));
      }
    }
    final slope = _median(slopes);
    final intercept = _median([
      for (var i = 0; i < x.length; i++) values[i] - slope * x[i],
    ]);
    final center = _median(values);
    final noise =
        _median([
          for (var i = 0; i < x.length; i++)
            (values[i] - intercept - slope * x[i]).abs(),
        ]) /
        center *
        100;
    final weekly = slope * 7 / center * 100;
    final firstWeek = _median([
      for (var i = 0; i < x.length; i++)
        if (x[i] < 7) values[i],
    ]);
    final lastWeek = _median([
      for (var i = 0; i < x.length; i++)
        if (x[i] >= span - 7) values[i],
    ]);
    final change = (lastWeek - firstWeek) / center * 100;
    final weekMedians = <double>[];
    final counts = <int>[];
    for (var end = span; end > 0; end -= 7) {
      final v = [
        for (var i = 0; i < x.length; i++)
          if (x[i] >= end - 7 && x[i] < end) values[i],
      ];
      counts.add(v.length);
      if (v.isNotEmpty) weekMedians.insert(0, _median(v));
    }
    var up = false, down = false;
    for (var i = 1; i < weekMedians.length; i++) {
      final delta = (weekMedians[i] - weekMedians[i - 1]) / center * 100;
      up |= delta > .3;
      down |= delta < -.3;
    }
    WeightTrendInsight classified(
      WeightInsightState s,
      String reason, {
      bool preliminary = true,
    }) => result(
      s,
      reason,
      weekly: weekly,
      change: change,
      noise: noise,
      preliminary: preliminary,
    );
    if (noise > .6 || (up && down) || weekly.abs() > 1.5) {
      return classified(WeightInsightState.uncertainTrend, 'variation');
    }
    final stable = weekly.abs() <= .1 && change.abs() <= .4;
    final dense =
        span >= 21 &&
        days.length >= 12 &&
        days.length / span >= .5 &&
        gap <= 4 &&
        counts.take(3).every((n) => n >= 3);
    final preliminary = span < 14 || days.length < 8;
    if (stable) {
      if (preliminary) {
        return classified(WeightInsightState.uncertainTrend, 'tooSoon');
      }
      final reached =
          targetKg != null &&
          targetKg.isFinite &&
          targetKg >= 20 &&
          targetKg <= 500 &&
          lastWeek <= targetKg * 1.005;
      if (goal == Goal.hold || (goal == Goal.lose && reached)) {
        return classified(
          WeightInsightState.maintenance,
          'goal',
          preliminary: !dense,
        );
      }
      if (dense && goal == Goal.lose && safety.allowsWeightManagement) {
        return classified(
          WeightInsightState.possiblePlateau,
          'stableWeeks',
          preliminary: false,
        );
      }
      return classified(
        WeightInsightState.stableTrend,
        dense ? 'stable' : 'provisional',
        preliminary: !dense,
      );
    }
    if (weekly < -.1 && change < 0) {
      return classified(
        WeightInsightState.decreasingTrend,
        'slope',
        preliminary: preliminary,
      );
    }
    if (weekly > .1 && change > 0) {
      return classified(
        WeightInsightState.increasingTrend,
        'slope',
        preliminary: preliminary,
      );
    }
    return classified(WeightInsightState.uncertainTrend, 'disagreement');
  }
}
