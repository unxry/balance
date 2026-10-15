import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_app/models/body_measurement.dart';
import 'package:flutter_app/models/history_models.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/services/balance_analytics_service.dart';
import 'package:flutter_app/services/local_backup_service.dart';
import 'package:flutter_app/services/local_store.dart';
import 'package:flutter_app/services/progress_series.dart';
import 'package:flutter_app/widgets/progress_chart.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12);
  for (final days in [7, 30, 90, 365]) {
    test('$days local days include boundaries and exclude tomorrow', () {
      final window = ProgressWindow(days: days, now: now);
      expect(window.contains(window.start), isTrue);
      expect(
        window.contains(window.start.subtract(const Duration(microseconds: 1))),
        isFalse,
      );
      expect(
        window.contains(DateTime(2026, 1, 1, 23, 59, 59, 999, 999)),
        isTrue,
      );
      expect(window.contains(DateTime(2026, 1, 2)), isFalse);
      expect(window.x(window.start), 0);
      expect(window.x(DateTime(2026, 1, 1, 12)), days - .5);
      expect(window.dateAt(days - 1), DateTime(2026, 1, 1));
      final sorted = pointsInWindow([
        ProgressPoint('end', now, 90),
        ProgressPoint('future', DateTime(2026, 1, 2), 50),
        ProgressPoint('start', window.start, 95),
        ProgressPoint(
          'before',
          window.start.subtract(const Duration(seconds: 1)),
          100,
        ),
      ], window);
      expect(sorted.map((entry) => entry.id), ['start', 'end']);
      expect(progressChange(sorted), -5);
      final analytics = const BalanceAnalyticsService().calculate(
        profile: UserProfile(),
        weights: [
          WeightEntry(id: 'end', date: now, kg: 80),
          WeightEntry(id: 'future', date: DateTime(2026, 1, 2), kg: 40),
          WeightEntry(id: 'start', date: window.start, kg: 82),
        ],
        dailyBalances: [],
        periodDays: days,
        now: now,
        waterGoalLiters: 2,
      );
      expect(analytics.actualWeights.map((entry) => entry.id), [
        'start',
        'end',
      ]);
      expect(analytics.actualWeightChange, -2);
    });
  }

  test('DST and UTC timestamps retain local dates and intraday positions', () {
    for (final now in [DateTime(2026, 3, 30), DateTime(2026, 10, 26)]) {
      final window = ProgressWindow(days: 7, now: now);
      for (var day = 0; day < 7; day++) {
        final local = DateTime(
          window.start.year,
          window.start.month,
          window.start.day + day,
          12,
        );
        expect(window.x(local), day + .5);
        expect(window.x(local.toUtc()), day + .5);
        expect(window.dateAt(day + .5), local);
      }
    }
  });

  test('empty, one, two, dense and same-day histories use real points', () {
    final window = ProgressWindow(days: 365, now: now);
    expect(progressChange([]), isNull);
    final one = [ProgressPoint('a', now, 92.5)];
    expect(progressChange(one), isNull);
    final morning = ProgressPoint('b', DateTime(2026, 1, 1, 8), 93);
    final two = pointsInWindow([one.single, morning], window);
    expect(two.map((entry) => entry.id), ['b', 'a']);
    expect(window.x(two.last.date), greaterThan(window.x(two.first.date)));
    expect(progressChange(two), -.5);
    expect(lastPointOnDay(two, now)?.id, 'a');
    expect(lastPointOnDay(two, DateTime(2025, 12, 31)), isNull);
    final dense = pointsInWindow(
      List.generate(
        500,
        (i) =>
            ProgressPoint('$i', now.subtract(Duration(hours: i)), 90 + i / 100),
      ),
      window,
    );
    expect(dense, hasLength(500));
    expect(dense.map((point) => point.id).toSet(), hasLength(500));
  });

  test('localized values and changes hide binary floating point artifacts', () {
    expect(progressNumber(94 - 9 * .15, true), '92,65');
    expect(progressNumber(92.3, true), '92,3');
    expect(progressDelta(92.3 - 92.5, true, 'см'), '−0,2 см');
    expect(progressDelta(1e-14, true, 'см'), '0 см');
    expect(progressDelta(1.5, false, 'cm'), '+1.5 cm');
  });

  test('decimal parsing and timestamp round trip', () {
    expect(BodyMeasurement.parseValue(' 92,5 '), 92.5);
    expect(BodyMeasurement.parseValue('92.5'), 92.5);
    for (final invalid in ['', 'NaN', 'Infinity', '-1', '0', '301', '1,2,3']) {
      expect(BodyMeasurement.parseValue(invalid), isNull);
    }
    final entry = BodyMeasurement(
      id: 'stable',
      date: now,
      type: BodyMeasurementType.hips,
      cm: 98.5,
    );
    final restored = BodyMeasurement.tryFromJson(entry.toJson())!;
    expect(restored.id, entry.id);
    expect(restored.date.isAtSameMomentAs(entry.date), isTrue);
    expect(restored.cm, 98.5);
    expect(
      BodyMeasurement.tryFromJson({'id': 'x', 'cm': 90, 'type': 'unknown'}),
      isNull,
    );
  });

  test('adaptive scales retain context and include endpoints', () {
    for (final values in [
      [80.0],
      [80.0, 80.1],
      [20.0, 400.0],
      [299.9, 300.0],
    ]) {
      final scale = ProgressScale.forValues(values, minimumSpan: 4);
      expect(scale.maxY - scale.minY, greaterThanOrEqualTo(4));
      for (final value in values) {
        expect(value, inInclusiveRange(scale.minY, scale.maxY));
      }
    }
  });

  group('Hive storage and backups', () {
    late Directory directory;
    late Box<dynamic> user;
    late Box<dynamic> food;
    late Box<dynamic> weight;
    AppDataProvider create() => AppDataProvider(
      now: () => now,
      userBox: user,
      foodBox: food,
      weightBox: weight,
    );

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('balance_body_');
      Hive.init(directory.path);
      user = await Hive.openBox<dynamic>('body_user');
      food = await Hive.openBox<dynamic>('body_food');
      weight = await Hive.openBox<dynamic>('body_weight');
    });
    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test(
      'legacy migration preserves profile, food, achievements and weight',
      () async {
        await user.putAll({
          LocalStore.schemaVersionKey: 5,
          'profile': UserProfile(
            name: 'Existing',
            onboarded: true,
            joinedAt: now,
          ).toJson(),
          'achievementUnlocks': {'saved': '2025-12-01'},
        });
        final savedWeight = WeightEntry(id: 'old', date: now, kg: 80).toJson();
        await weight.put('history', [savedWeight]);
        await food.put('days', {'2025-12-31': []});
        final beforeUser = Map.of(user.toMap());
        await LocalStore.migrateBoxes(user: user, food: food, weight: weight);
        expect(user.get(LocalStore.schemaVersionKey), 6);
        expect(user.get('bodyMeasurements'), isEmpty);
        expect(user.get('profile'), beforeUser['profile']);
        expect(
          user.get('achievementUnlocks'),
          beforeUser['achievementUnlocks'],
        );
        expect(weight.get('history'), [savedWeight]);
        expect(food.get('days'), {'2025-12-31': []});
        final data = create();
        await data.load();
        expect(data.weightHistory.single.id, 'old');
        expect(data.bodyMeasurements, isEmpty);
        data.dispose();
      },
    );

    for (final type in BodyMeasurementType.values) {
      test(
        '${type.name} alone survives edits, restart, backup and deletion',
        () async {
          final data = create();
          await data.load();
          expect(
            await data.addBodyMeasurement(
              type: type,
              cm: 92.5,
              date: DateTime(2025, 12, 31, 20),
            ),
            isTrue,
          );
          expect(
            await data.addBodyMeasurement(
              type: type,
              cm: 94,
              date: DateTime(2025, 12, 30),
            ),
            isTrue,
          );
          final id = data.bodyMeasurements.last.id;
          expect(
            await data.updateBodyMeasurement(
              id,
              cm: 91.5,
              date: DateTime(2025, 12, 29, 23, 59),
            ),
            isTrue,
          );
          expect(data.bodyMeasurements.first.id, id);
          expect(
            await data.addBodyMeasurement(type: type, cm: double.nan),
            isFalse,
          );
          expect(
            await data.addBodyMeasurement(
              type: type,
              cm: 95,
              date: DateTime(2026, 1, 2),
            ),
            isFalse,
          );
          final backup = const LocalBackupService().exportJson(
            user: user,
            food: food,
            weight: weight,
          );
          expect(backup, contains('bodyMeasurements'));
          data.dispose();
          await Hive.close();
          user = await Hive.openBox<dynamic>('body_user');
          food = await Hive.openBox<dynamic>('body_food');
          weight = await Hive.openBox<dynamic>('body_weight');
          final relaunched = create();
          await relaunched.load();
          expect(relaunched.bodyMeasurements.map((entry) => entry.cm), [
            91.5,
            94,
          ]);
          expect(
            relaunched.bodyMeasurements.every((entry) => entry.type == type),
            isTrue,
          );
          expect(await relaunched.deleteBodyMeasurement(id), isTrue);
          expect(relaunched.bodyMeasurements, hasLength(1));
          expect(await relaunched.deleteBodyMeasurement(id), isFalse);
          await const LocalBackupService().restoreJson(
            backup,
            user: user,
            food: food,
            weight: weight,
          );
          await relaunched.load();
          expect(relaunched.bodyMeasurements.map((entry) => entry.cm), [
            91.5,
            94,
          ]);
          await LocalStore.migrateBoxes(user: user, food: food, weight: weight);
          expect((user.get('bodyMeasurements') as List), hasLength(2));
          relaunched.dispose();
        },
      );
    }

    test(
      'cached periods advance at local midnight without a mutation',
      () async {
        var clock = DateTime(2026, 1, 1, 23, 59);
        final data = AppDataProvider(
          now: () => clock,
          userBox: user,
          foodBox: food,
          weightBox: weight,
        );
        await data.load();
        await data.addWeightEntry(80, date: DateTime(2025, 12, 26));
        expect(data.analyticsForDays(7).actualWeights, hasLength(1));
        clock = DateTime(2026, 1, 2);
        expect(data.analyticsForDays(7).actualWeights, isEmpty);
        expect(data.analyticsForDays(7).periodStart, DateTime(2025, 12, 27));
        data.dispose();
      },
    );

    test('concurrent independent measurements are never lost', () async {
      final data = create();
      await data.load();
      final results = await Future.wait([
        for (final type in BodyMeasurementType.values)
          data.addBodyMeasurement(type: type, cm: 92.5),
      ]);
      expect(results, everyElement(isTrue));
      await data.load();
      expect(
        data.bodyMeasurements.map((entry) => entry.type).toSet(),
        BodyMeasurementType.values.toSet(),
      );
      data.dispose();
    });

    test('deleting all weight readings stays empty after restart', () async {
      await user.put(
        'profile',
        UserProfile(onboarded: true, joinedAt: now).toJson(),
      );
      final data = create();
      await data.load();
      final id = data.weightHistory.single.id;
      await data.deleteWeightEntry(id);
      await data.load();
      expect(data.weightHistory, isEmpty);
      data.dispose();
    });

    test(
      'older backups retain added measurements; migration is idempotent',
      () async {
        final oldBackup = const LocalBackupService().exportJson(
          user: user,
          food: food,
          weight: weight,
        );
        final data = create();
        await data.load();
        await data.addBodyMeasurement(type: BodyMeasurementType.chest, cm: 92);
        await const LocalBackupService().restoreJson(
          oldBackup,
          user: user,
          food: food,
          weight: weight,
        );
        await LocalStore.migrateBoxes(user: user, food: food, weight: weight);
        await LocalStore.migrateBoxes(user: user, food: food, weight: weight);
        await data.load();
        expect(data.bodyMeasurements.single.cm, 92);
        data.dispose();
      },
    );
  });
}
