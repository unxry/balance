import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/history_models.dart';
import 'package:flutter_app/services/balance_analytics_service.dart';
import 'package:flutter_app/services/weight_forecast_cache.dart';

void main() {
  const analytics = BalanceAnalyticsService();
  final base = DateTime(2026, 12, 25, 8);
  DateTime day(int n) => DateTime(base.year, base.month, base.day + n, 8);
  WeightEntry entry(int n, double kg, {String? id}) =>
      WeightEntry(id: id ?? 'w$n', date: day(n), kg: kg);
  List<WeightEntry> stable(Iterable<int> days) => [
    for (final n in days) entry(n, 80 - .06 * n),
  ];
  WeightForecastSnapshot fit(List<WeightEntry> input, int n) =>
      analytics.calculateForecast(weights: input, now: day(n));

  test(
    'requires seven inclusive calendar days and four distinct measured days',
    () {
      expect(
        fit(stable([0, 1, 3, 5]), 5).status,
        WeightForecastStatus.collecting,
      );
      expect(fit(stable([0, 3, 6]), 6).status, WeightForecastStatus.collecting);
      final ready = fit(stable([0, 2, 4, 6]), 6);
      expect(ready.ready, isTrue);
      expect(ready.dailyCount, 4);
      expect(ready.spanDays, 7);
      expect(ready.horizonDays, 7);
      expect(ready.slopePerDay, closeTo(-.06, 1e-10));
      expect(ready.project().last.kg, closeTo(80 - .06 * 13, 1e-10));
      expect(ready.lowerSlope, isNull);
    },
  );
  test('a sudden new deviation hides an outdated cached projection', () {
    final result = fit(stable([0, 2, 4, 6]), 6);
    expect(result.project(latest: entry(7, 90)), isEmpty);
    expect(result.project(latest: entry(7, 79.58)).first.kg, 79.58);
  });
  test('same-day entries do not manufacture observation days', () {
    expect(
      fit(
        List.generate(20, (i) => entry(0, 80 + i * .01, id: 'same$i')),
        6,
      ).dailyCount,
      1,
    );
  });
  test('daily median is safe and does not modify source records', () {
    final raw = [
      ...stable([0, 2, 4, 6]),
      entry(2, 90, id: 'duplicate-a'),
      entry(2, 79.88, id: 'duplicate-b'),
    ];
    final original = raw.map((e) => e.toJson()).toList();
    final result = fit(raw.reversed.toList(), 6);
    expect(result.ready, isTrue);
    expect(result.dailyCount, 4);
    expect(result.slopePerDay, closeTo(-.06, 1e-10));
    expect(raw.map((e) => e.toJson()).toList(), original);
  });
  test('real dates, not ordinal indices, determine the robust rate', () {
    final result = fit(stable([0, 1, 4, 6, 12, 14]), 14);
    expect(result.slopePerDay, closeTo(-.06, 1e-10));
  });
  test('unchanged weight produces a neutral flat forecast', () {
    final result = fit([
      for (final n in [0, 2, 4, 6]) entry(n, 80),
    ], 6);
    expect(result.ready, isTrue);
    expect(result.slopePerDay, 0);
    expect(result.project().map((p) => p.kg).toSet(), {80.0});
  });
  test(
    'unstable noise and a reversed trend do not produce precise predictions',
    () {
      expect(
        fit([
          for (var n = 0; n < 14; n++) entry(n, 80 + (n.isEven ? 2 : -2)),
        ], 13).ready,
        isFalse,
      );
      expect(
        fit([
          for (var n = 0; n < 14; n++) entry(n, 80 + (n < 7 ? n : 13 - n) * .1),
        ], 13).ready,
        isFalse,
      );
    },
  );
  test('isolated historical outlier has limited influence', () {
    final input = stable(List.generate(14, (i) => i));
    input[5] = entry(5, 90);
    final result = fit(input, 13);
    expect(result.ready, isTrue);
    expect(result.outlierCount, 1);
    expect(result.slopePerDay, closeTo(-.06, 1e-10));
    expect(result.horizonDays, 14);
    expect(result.lowerSlope, isNotNull);
    expect(result.upperSlope, isNotNull);
    for (final point in result.project()) {
      expect(point.lowerKg!, lessThanOrEqualTo(point.kg + 1e-10));
      expect(point.upperKg!, greaterThanOrEqualTo(point.kg - 1e-10));
    }
  });
  test(
    'an anomalous latest weight prevents a continuation from that outlier',
    () {
      final input = stable(List.generate(14, (i) => i))..[13] = entry(13, 95);
      expect(fit(input, 13).ready, isFalse);
    },
  );
  test('unrealistic rate, invalid weights and future days are rejected', () {
    expect(
      fit([for (var n = 0; n < 8; n++) entry(n, 80 - n * .5)], 7).ready,
      isFalse,
    );
    expect(
      fit([
        entry(0, double.nan),
        entry(2, double.infinity),
        entry(4, 10),
        entry(6, 500),
      ], 6).ready,
      isFalse,
    );
    expect(fit(stable([0, 2, 4, 6]), 3).ready, isFalse);
  });
  test(
    'bootstrap band is deterministic and represents fitted rate variation',
    () {
      final raw = [
        for (var n = 0; n < 18; n++)
          entry(n, 80 - .05 * n + [0, .08, -.04, .03][n % 4]),
      ];
      final a = fit(raw, 17), b = fit(raw, 17);
      expect(a.ready, isTrue);
      expect(a.lowerSlope, b.lowerSlope);
      expect(a.upperSlope, b.upperSlope);
      expect(a.lowerSlope!, lessThan(a.upperSlope!));
      expect(a.toJson(), b.toJson());
    },
  );
  test('year boundary uses calendar dates and stable fingerprints', () {
    final raw = stable([0, 2, 4, 6, 8, 10]);
    final result = fit(raw, 10);
    expect(result.spanDays, 11);
    expect(result.calculatedDateKey, '2027-01-04');
    expect(
      result.sourceHash,
      forecastSourceHash(forecastSourceRecords(raw.reversed)),
    );
  });
  test('old records outside the recent 28-day window do not dominate', () {
    final result = fit([
      entry(-70, 120),
      ...stable(List.generate(14, (i) => i)),
    ], 13);
    expect(result.dailyCount, 14);
    expect(result.slopePerDay, closeTo(-.06, 1e-10));
  });
  test('snapshot round trip and algorithm version invalidation', () {
    final result = fit(stable([0, 2, 4, 6]), 6);
    final restored = WeightForecastSnapshot.tryFromJson(
      jsonDecode(jsonEncode(result.toJson())),
    )!;
    expect(restored.project().last.kg, result.project().last.kg);
    expect(restored.sourceHash, result.sourceHash);
    expect(
      WeightForecastSnapshot.tryFromJson({
        ...result.toJson(),
        'algorithmVersion': 0,
      }),
      isNull,
    );
  });

  group('persistent four-day cadence', () {
    late Object? stored;
    late int writes;
    WeightForecastCache cache() => WeightForecastCache(
      read: () => stored,
      write: (value) async {
        writes++;
        stored = jsonDecode(jsonEncode(value));
      },
    );
    setUp(() {
      stored = null;
      writes = 0;
    });
    test(
      'first eligibility is immediate; reopening does not recalculate',
      () async {
        final model = cache();
        await model.refresh(weights: stable([0, 2, 4]), now: day(4));
        expect(model.current!.ready, isFalse);
        await model.refresh(weights: stable([0, 2, 4, 6]), now: day(6));
        expect(model.current!.ready, isTrue);
        final reopened = cache();
        final same = await reopened.refresh(
          weights: stable([0, 2, 4, 6]),
          now: day(7),
        );
        expect(reopened.calculationCount, 0);
        expect(same.calculatedDateKey, '2026-12-31');
        expect(writes, 2);
      },
    );
    test(
      'new append waits four calendar days and keeps the fitted source hash',
      () async {
        final model = cache();
        final first = await model.refresh(
          weights: stable([0, 2, 4, 6]),
          now: day(6),
        );
        for (var n = 7; n <= 8; n++) {
          await model.refresh(
            weights: stable([0, 2, 4, 6, for (var i = 7; i <= n; i++) i]),
            now: day(n),
          );
        }
        final pending = await model.refresh(
          weights: stable([0, 2, 4, 6, 7, 8, 9]),
          now: day(9),
        );
        expect(pending.sourceHash, first.sourceHash);
        expect(pending.calculatedAt, first.calculatedAt);
        expect(model.calculationCount, 1);
        // UI continuation can start at a fresh actual reading without refitting.
        expect(pending.project(latest: entry(9, 79.46)).first.kg, 79.46);
        final updated = await model.refresh(
          weights: stable([0, 2, 4, 6, 7, 8, 9, 10]),
          now: day(10),
        );
        expect(updated.sourceHash, isNot(first.sourceHash));
        expect(updated.calculatedDateKey, '2027-01-04');
        expect(model.calculationCount, 2);
      },
    );
    test(
      'pending additions are fitted on day four even without another append',
      () async {
        final model = cache();
        await model.refresh(weights: stable([0, 2, 4, 6]), now: day(6));
        await model.refresh(weights: stable([0, 2, 4, 6, 7]), now: day(7));
        final reopened = cache();
        final next = await reopened.refresh(
          weights: stable([0, 2, 4, 6, 7]),
          now: day(10),
        );
        expect(next.calculatedDateKey, '2027-01-04');
        expect(reopened.calculationCount, 1);
      },
    );
    test(
      'editing or deleting a pending append invalidates after restart',
      () async {
        for (final remove in [false, true]) {
          stored = null;
          final model = cache();
          await model.refresh(weights: stable([0, 2, 4, 6]), now: day(6));
          final raw = stable([0, 2, 4, 6, 7]);
          await model.refresh(weights: raw, now: day(7));
          if (remove) {
            raw.removeLast();
          } else {
            raw[4] = entry(7, 79.5);
          }
          final reopened = cache();
          final next = await reopened.refresh(weights: raw, now: day(8));
          expect(next.calculatedDateKey, '2027-01-02');
          expect(reopened.calculationCount, 1);
        }
      },
    );
    test(
      'a backdated addition newer than the old anchor is still immediate',
      () async {
        final model = cache();
        await model.refresh(weights: stable([0, 2, 4, 6]), now: day(6));
        await model.refresh(weights: stable([0, 2, 4, 6, 7]), now: day(8));
        expect(model.calculationCount, 2);
      },
    );
    test('four days with no new data do not manufacture a new model', () async {
      final model = cache();
      final first = await model.refresh(
        weights: stable([0, 2, 4, 6]),
        now: day(6),
      );
      final later = await model.refresh(
        weights: stable([0, 2, 4, 6]),
        now: day(18),
      );
      expect(later.calculatedAt, first.calculatedAt);
      expect(model.calculationCount, 1);
      expect(later.project(now: day(18)), isEmpty);
    });
    test(
      'edits, removal and same-day additions invalidate immediately',
      () async {
        for (final operation in ['edit', 'delete', 'same-day', 'backdated']) {
          stored = null;
          final model = cache();
          final raw = stable([0, 2, 4, 6]);
          final first = await model.refresh(weights: raw, now: day(6));
          switch (operation) {
            case 'edit':
              raw[1] = entry(2, 79.8);
            case 'delete':
              raw.removeAt(1);
            case 'same-day':
              raw.add(
                WeightEntry(
                  id: 'late',
                  date: day(6).add(const Duration(hours: 2)),
                  kg: 79.6,
                ),
              );
            case 'backdated':
              raw.add(entry(3, 79.82));
          }
          final next = await model.refresh(weights: raw, now: day(7));
          expect(next.sourceHash, isNot(first.sourceHash), reason: operation);
          expect(model.calculationCount, 2, reason: operation);
          if (operation == 'delete') expect(next.ready, isFalse);
        }
      },
    );
    test(
      'deleted history cannot keep a ready forecast after restart',
      () async {
        final model = cache();
        await model.refresh(weights: stable([0, 2, 4, 6]), now: day(6));
        final next = await cache().refresh(weights: [], now: day(7));
        expect(next.status, WeightForecastStatus.collecting);
        expect(next.project(), isEmpty);
      },
    );
    test('backward civil clock with new data is safely refitted', () async {
      final model = cache();
      await model.refresh(weights: stable([0, 2, 4, 6]), now: day(8));
      final changed = await model.refresh(
        weights: stable([0, 2, 4, 6, 7]),
        now: day(7),
      );
      expect(changed.calculatedDateKey, '2027-01-01');
      expect(model.calculationCount, 2);
    });
    test('failed cache writes remain retryable', () async {
      var fail = true;
      final model = WeightForecastCache(
        read: () => null,
        write: (_) async {
          if (fail) throw StateError('disk');
        },
      );
      await expectLater(
        model.refresh(weights: stable([0, 2, 4, 6]), now: day(6)),
        throwsStateError,
      );
      expect(model.current, isNull);
      fail = false;
      expect(
        (await model.refresh(weights: stable([0, 2, 4, 6]), now: day(6))).ready,
        isTrue,
      );
    });
  });

  test(
    'cache survives a real process restart in a different time zone',
    () async {
      final directory = await Directory.systemTemp.createTemp('forecast_tz_');
      try {
        final root = Platform.environment['FLUTTER_ROOT']!;
        final executable = '$root/bin/cache/dart-sdk/bin/dart';
        Future<Map<String, dynamic>> probe(String zone) async {
          final result = await Process.run(
            executable,
            [
              '--packages=.dart_tool/package_config.json',
              'test/fixtures/forecast_timezone_probe.dart',
              '${directory.path}/cache.json',
            ],
            environment: {'TZ': zone},
          );
          expect(result.exitCode, 0, reason: result.stderr.toString());
          return jsonDecode(result.stdout.toString().trim())
              as Map<String, dynamic>;
        }

        final east = await probe('Asia/Tokyo');
        final west = await probe('America/Los_Angeles');
        expect(east['offset'], isNot(west['offset']));
        expect(east['hash'], isNot(west['hash']));
        expect(west['calculations'], 1);
        expect(west['ready'], isTrue);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
