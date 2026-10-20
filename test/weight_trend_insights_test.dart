import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/history_models.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/models/weight_trend_insight.dart';
import 'package:flutter_app/services/weight_trend_insights_service.dart';

void main() {
  const service = WeightTrendInsightsService();
  final now = DateTime(2026, 10, 28, 12);
  const safe = TipSafetyProfile(age: 32, checked: true);
  List<WeightEntry> series(int n, double Function(int) value, {int step = 1}) =>
      [
        for (var i = 0; i < n; i++)
          WeightEntry(
            id: 'w$i',
            date: DateTime(2026, 10, 28 - (n - 1 - i) * step, 8),
            kg: value(i),
          ),
      ];
  WeightTrendInsight analyze(
    List<WeightEntry> weights, {
    Goal? goal = Goal.lose,
    double target = 65,
    TipSafetyProfile safety = safe,
  }) => service.analyze(
    weights: weights,
    now: now,
    goal: goal,
    targetKg: target,
    safety: safety,
  );

  for (final days in [0, 2, 3, 6]) {
    test('$days days never establishes a plateau', () {
      final result = analyze(series(days, (_) => 80));
      expect(result.state, WeightInsightState.insufficientData);
    });
  }
  for (final days in [7, 10, 13]) {
    test('$days stable days are preliminary, not a plateau', () {
      final result = analyze(series(days, (_) => 80));
      expect(result.state, WeightInsightState.uncertainTrend);
      expect(result.preliminary, isTrue);
      expect(result.explanation(false), contains('longer observation'));
    });
  }
  for (final days in [14, 20]) {
    test('$days stable days allow provisional stability only', () {
      final result = analyze(series(days, (_) => 80));
      expect(result.state, WeightInsightState.stableTrend);
      expect(result.preliminary, isTrue);
    });
  }
  test(
    'dense stable weeks can indicate possible plateau only for eligible losing goal',
    () {
      for (final days in [21, 28, 42]) {
        final r = analyze(series(days, (_) => 80));
        expect(r.state, WeightInsightState.possiblePlateau);
        expect(r.reliable, isTrue);
        expect(r.measuredDays, lessThanOrEqualTo(28));
        expect(r.calculatedAt, now);
      }
    },
  );
  test('real daily median, sorting and duplicates do not inflate coverage', () {
    final a = series(28, (_) => 80);
    final repeated = [
      for (final e in a) ...[e, e, e],
    ]..shuffle();
    final r = analyze(repeated);
    expect(r.measuredDays, 28);
    expect(r.state, WeightInsightState.possiblePlateau);
    final pair = [
      WeightEntry(id: 'a', date: now, kg: 80),
      WeightEntry(id: 'b', date: now.add(const Duration(minutes: 1)), kg: 80),
    ];
    expect(analyze(pair).state, WeightInsightState.insufficientData);
    final robust = [
      for (final e in a) ...[
        e,
        WeightEntry(
          id: 'x${e.id}',
          date: e.date.add(const Duration(hours: 1)),
          kg: 80,
        ),
        WeightEntry(
          id: 'y${e.id}',
          date: e.date.add(const Duration(hours: 2)),
          kg: 83,
        ),
      ],
    ];
    expect(analyze(robust).state, WeightInsightState.possiblePlateau);
  });
  test('missing weeks and old data refuse a stable classification', () {
    expect(
      analyze(series(4, (_) => 80, step: 7)).state,
      WeightInsightState.uncertainTrend,
    );
    final old = series(14, (_) => 80)
        .map((e) => e.copyWith(date: e.date.subtract(const Duration(days: 8))))
        .toList();
    expect(analyze(old).state, WeightInsightState.uncertainTrend);
  });
  test('noise, reversals and contradictory records lower reliability', () {
    expect(
      analyze(series(28, (i) => 80 + (i.isEven ? 2 : -2))).state,
      WeightInsightState.uncertainTrend,
    );
    expect(
      analyze(
        series(28, (i) => i < 14 ? 80 - i * .1 : 78.6 + (i - 14) * .1),
      ).state,
      WeightInsightState.uncertainTrend,
    );
    final invalid = series(28, (_) => 80)
      ..add(WeightEntry(id: 'bad', date: now, kg: double.nan));
    expect(analyze(invalid).state, WeightInsightState.uncertainTrend);
    final conflict = series(28, (_) => 80)
      ..add(WeightEntry(id: 'w0', date: now, kg: 82));
    expect(analyze(conflict).state, WeightInsightState.uncertainTrend);
  });
  test('downward and upward trends use real measurements', () {
    expect(
      analyze(series(28, (i) => 82 - i * .04)).state,
      WeightInsightState.decreasingTrend,
    );
    expect(
      analyze(series(28, (i) => 80 + i * .04)).state,
      WeightInsightState.increasingTrend,
    );
  });
  test('reached target and maintenance are not problems to fix', () {
    final stable = series(28, (_) => 80);
    expect(analyze(stable, target: 80).state, WeightInsightState.maintenance);
    expect(
      analyze(stable, goal: Goal.hold).state,
      WeightInsightState.maintenance,
    );
    expect(
      analyze(stable, goal: Goal.gain).state,
      WeightInsightState.stableTrend,
    );
  });
  test(
    'minors, unknown age/context and known restrictions suppress plateau advice',
    () {
      for (final safety in [
        const TipSafetyProfile(),
        const TipSafetyProfile(age: 32),
        const TipSafetyProfile(age: 17, checked: true),
        const TipSafetyProfile(age: 32, checked: true, pregnant: true),
        const TipSafetyProfile(age: 32, checked: true, breastfeeding: true),
        const TipSafetyProfile(
          age: 32,
          checked: true,
          eatingDisorderRisk: true,
        ),
        const TipSafetyProfile(
          age: 32,
          checked: true,
          medicalRestriction: true,
        ),
      ]) {
        expect(
          analyze(series(28, (_) => 80), safety: safety).state,
          WeightInsightState.stableTrend,
        );
      }
    },
  );
  test(
    'edits, removals and restored input recompute, no stale derived cache',
    () {
      final stable = series(28, (_) => 80);
      expect(analyze(stable).state, WeightInsightState.possiblePlateau);
      final edited = series(28, (i) => 80 + i * .04);
      expect(analyze(edited).state, WeightInsightState.increasingTrend);
      expect(
        analyze(stable.take(2).toList()).state,
        WeightInsightState.insufficientData,
      );
      expect(analyze(stable).state, WeightInsightState.possiblePlateau);
    },
  );
  test('threshold sensitivity across body sizes and irregular records', () {
    for (final mass in [50.0, 80.0, 140.0]) {
      for (final percent in [.02, .05, .08]) {
        expect(
          analyze(
            series(28, (i) => mass + i * mass * percent / 100 / 7),
            target: mass * .8,
          ).state,
          WeightInsightState.possiblePlateau,
        );
      }
      for (final percent in [.15, .3, .6]) {
        expect(
          analyze(series(28, (i) => mass - i * mass * percent / 100 / 7)).state,
          WeightInsightState.decreasingTrend,
        );
      }
      expect(
        analyze(series(14, (_) => mass, step: 2), target: mass * .8).state,
        WeightInsightState.possiblePlateau,
      );
    }
  });
  test('UTC and local instants produce the same local window', () {
    final localNow = DateTime(2026, 10, 28, 0, 15);
    final weights = series(28, (_) => 80);
    final a = service.analyze(
      weights: weights,
      now: localNow,
      goal: Goal.lose,
      safety: safe,
    );
    final b = service.analyze(
      weights: weights,
      now: localNow.toUtc(),
      goal: Goal.lose,
      safety: safe,
    );
    expect(a.state, b.state);
    expect(a.measuredDays, b.measuredDays);
    expect(a.calculationDateKey, b.calculationDateKey);
  });
  test(
    'calendar month and timezone-style local boundaries use civil dates',
    () {
      final weights = [
        for (var i = 0; i < 28; i++)
          WeightEntry(
            id: '$i',
            date: DateTime(2027, 1, 10 - i, 23, 59),
            kg: 80,
          ),
      ];
      final r = service.analyze(
        weights: weights,
        now: DateTime(2027, 1, 10, 23, 59),
        goal: Goal.lose,
        safety: safe,
      );
      expect(r.state, WeightInsightState.possiblePlateau);
      expect(r.calculationDateKey, '2027-01-10');
    },
  );
}
