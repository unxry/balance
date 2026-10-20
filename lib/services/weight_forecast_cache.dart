import 'dart:convert';

import '../models/history_models.dart';
import '../utils/calendar_date.dart';
import 'balance_analytics_service.dart';

class WeightForecastCache {
  static const storageKey = 'weightForecastV2';
  final Object? Function() read;
  final Future<void> Function(Map<String, Object?>) write;
  final BalanceAnalyticsService analytics;
  WeightForecastSnapshot? current;
  List<String> _observedRecords = const [];
  Future<void> _pending = Future<void>.value();
  Future<void> get pending => _pending;
  int calculationCount = 0;

  WeightForecastCache({
    required this.read,
    required this.write,
    this.analytics = const BalanceAnalyticsService(),
  }) {
    final stored = read();
    current = WeightForecastSnapshot.tryFromJson(stored);
    final observed = stored is Map ? stored['observedRecords'] : null;
    _observedRecords = observed is List && observed.every((r) => r is String)
        ? List<String>.from(observed)
        : current?.sourceRecords ?? const [];
  }

  Future<WeightForecastSnapshot> refresh({
    required List<WeightEntry> weights,
    required DateTime now,
  }) {
    final captured = List<WeightEntry>.of(weights);
    final operation = _pending.then((_) async {
      final records = forecastSourceRecords(captured);
      final previous = current;
      if (previous != null) {
        bool same(List<String> a, List<String> b) =>
            a.length == b.length && a.indexed.every((p) => p.$2 == b[p.$1]);
        final unchanged = same(_observedRecords, records);
        if (unchanged && same(previous.sourceRecords, records)) return previous;
        final previousRecords = _observedRecords.toSet();
        final currentRecords = records.toSet();
        final modified = !previousRecords.every(currentRecords.contains);
        final additions = records.where((r) => !previousRecords.contains(r));
        final observed =
            _observedRecords.map((r) => jsonDecode(r) as List).toList()
              ..sort((a, b) => (a[1] as int).compareTo(b[1] as int));
        final oldLatest = observed.isEmpty ? null : observed.last[1] as int;
        final oldDay = observed.isEmpty ? null : observed.last[2] as String;
        final historicalAddition = additions.any((r) {
          final parts = jsonDecode(r) as List;
          // Same-day additions can alter that day's median, even at a later hour.
          return oldLatest != null &&
              ((parts[1] as int) <= oldLatest ||
                  parts[2] == oldDay ||
                  (parts[2] as String).compareTo(localDateKey(now)) < 0);
        });
        final elapsed = previous.calculatedDateKey == null
            ? 4
            : calendarDayDifference(
                localDateKey(now),
                previous.calculatedDateKey!,
              );
        if (previous.ready &&
            !modified &&
            !historicalAddition &&
            elapsed >= 0 &&
            elapsed < 4) {
          if (!unchanged) {
            await write({...previous.toJson(), 'observedRecords': records});
            _observedRecords = records;
          }
          return previous;
        }
      }
      calculationCount++;
      final next = analytics.calculateForecast(weights: captured, now: now);
      await write({...next.toJson(), 'observedRecords': records});
      _observedRecords = records;
      current = next;
      return next;
    });
    _pending = operation.then<void>((_) {}, onError: (Object _) {});
    return operation;
  }
}
