import 'dart:convert';
import 'dart:math';

import 'history_models.dart';
import '../utils/calendar_date.dart';

enum WeightForecastStatus { collecting, unreliable, ready }

class WeightForecastPoint {
  final DateTime date;
  final double kg;
  final double? lowerKg;
  final double? upperKg;
  const WeightForecastPoint({
    required this.date,
    required this.kg,
    this.lowerKg,
    this.upperKg,
  });
}

class WeightForecastSnapshot {
  static const algorithmVersion = 2;
  final WeightForecastStatus status;
  final String reason;
  final DateTime? calculatedAt;
  final String? calculatedDateKey;
  final String sourceHash;
  final String usedSourceHash;
  final List<String> sourceRecords;
  final DateTime? anchorDate;
  final double? anchorKg;
  final double? slopePerDay;
  final double? lowerSlope;
  final double? upperSlope;
  final int dailyCount;
  final int spanDays;
  final int horizonDays;
  final int outlierCount;

  const WeightForecastSnapshot({
    this.status = WeightForecastStatus.collecting,
    this.reason = 'collecting',
    this.calculatedAt,
    this.calculatedDateKey,
    this.sourceHash = '',
    this.usedSourceHash = '',
    this.sourceRecords = const [],
    this.anchorDate,
    this.anchorKg,
    this.slopePerDay,
    this.lowerSlope,
    this.upperSlope,
    this.dailyCount = 0,
    this.spanDays = 0,
    this.horizonDays = 7,
    this.outlierCount = 0,
  });

  bool get ready => status == WeightForecastStatus.ready;
  bool staleAt(DateTime now, {DateTime? latestDate}) =>
      ready &&
      calendarDayDifference(
            localDateKey(now),
            localDateKey(latestDate ?? anchorDate!),
          ) >=
          horizonDays;

  // Only the continuation is re-anchored after a new real reading. The fitted
  // rate, source hash and calculation date stay frozen until the next update.
  List<WeightForecastPoint> project({
    WeightEntry? latest,
    int? maxDays,
    DateTime? now,
  }) {
    if (!ready) return const [];
    final date = (latest?.date ?? anchorDate!).toLocal();
    final kg = latest?.kg ?? anchorKg!;
    if (now != null && staleAt(now, latestDate: date)) return const [];
    if (latest != null) {
      final elapsed = calendarDayDifference(
        localDateKey(date),
        localDateKey(anchorDate!),
      );
      final expected = anchorKg! + slopePerDay! * elapsed;
      if ((kg - expected).abs() > .8) return const [];
    }
    final horizon = min(horizonDays, maxDays ?? horizonDays);
    final end = kg + slopePerDay! * horizon;
    if (end < 20 || end > 400) return const [];
    return List.unmodifiable([
      for (var day = 0; day <= horizon; day++)
        WeightForecastPoint(
          date: DateTime(
            date.year,
            date.month,
            date.day + day,
            date.hour,
            date.minute,
            date.second,
            date.millisecond,
            date.microsecond,
          ),
          kg: kg + slopePerDay! * day,
          lowerKg: lowerSlope == null ? null : kg + lowerSlope! * day,
          upperKg: upperSlope == null ? null : kg + upperSlope! * day,
        ),
    ]);
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'algorithmVersion': algorithmVersion,
    'status': status.name,
    'reason': reason,
    'calculatedAt': calculatedAt?.toIso8601String(),
    'calculatedDateKey': calculatedDateKey,
    'sourceHash': sourceHash,
    'usedSourceHash': usedSourceHash,
    'sourceRecords': sourceRecords,
    'anchorDate': anchorDate?.toIso8601String(),
    'anchorKg': anchorKg,
    'slopePerDay': slopePerDay,
    'lowerSlope': lowerSlope,
    'upperSlope': upperSlope,
    'dailyCount': dailyCount,
    'spanDays': spanDays,
    'horizonDays': horizonDays,
    'outlierCount': outlierCount,
  };

  static WeightForecastSnapshot? tryFromJson(Object? value) {
    if (value is! Map ||
        value['version'] != 1 ||
        value['algorithmVersion'] != algorithmVersion) {
      return null;
    }
    try {
      final status = WeightForecastStatus.values.byName(
        value['status'] as String,
      );
      double? number(String key) {
        final n = value[key];
        if (n == null) return null;
        if (n is! num || !n.isFinite) throw const FormatException();
        return n.toDouble();
      }

      final calculated = value['calculatedAt'] == null
          ? null
          : DateTime.parse(value['calculatedAt'] as String);
      final anchor = value['anchorDate'] == null
          ? null
          : DateTime.parse(value['anchorDate'] as String);
      final kg = number('anchorKg');
      final slope = number('slopePerDay');
      final lower = number('lowerSlope');
      final upper = number('upperSlope');
      final count = value['dailyCount'] as int;
      final span = value['spanDays'] as int;
      final horizon = value['horizonDays'] as int;
      final records = (value['sourceRecords'] as List).cast<String>();
      if (value['sourceHash'] != forecastSourceHash(records) ||
          horizon < 7 ||
          horizon > 14 ||
          count < 0 ||
          span < 0 ||
          (status == WeightForecastStatus.ready &&
              (calculated == null ||
                  storedLocalDateKey(value['calculatedDateKey']) == null ||
                  anchor == null ||
                  kg == null ||
                  kg < 20 ||
                  kg > 400 ||
                  slope == null ||
                  slope.abs() * 7 > 1.5 ||
                  count < 4 ||
                  span < 7)) ||
          ((lower == null) != (upper == null)) ||
          (lower != null && (lower > slope! || upper! < slope))) {
        return null;
      }
      return WeightForecastSnapshot(
        status: status,
        reason: value['reason'] as String,
        calculatedAt: calculated,
        calculatedDateKey: value['calculatedDateKey'] as String?,
        sourceHash: value['sourceHash'] as String,
        usedSourceHash: value['usedSourceHash'] as String,
        sourceRecords: List.unmodifiable(records),
        anchorDate: anchor,
        anchorKg: kg,
        slopePerDay: slope,
        lowerSlope: lower,
        upperSlope: upper,
        dailyCount: count,
        spanDays: span,
        horizonDays: horizon,
        outlierCount: value['outlierCount'] as int,
      );
    } catch (_) {
      return null;
    }
  }
}

List<String> forecastSourceRecords(Iterable<WeightEntry> entries) {
  final records =
      entries
          .map(
            (e) => jsonEncode([
              e.id,
              e.date.toUtc().microsecondsSinceEpoch,
              localDateKey(e.date),
              e.kg.toString(),
            ]),
          )
          .toList()
        ..sort();
  return List.unmodifiable(records);
}

String forecastSourceHash(Iterable<String> records) {
  var a = 2166136261;
  var b = 0x9e3779b9;
  for (final byte in utf8.encode(records.join('\n'))) {
    a = ((a ^ byte) * 16777619) & 0xffffffff;
    b = ((b ^ byte) * 2246822519) & 0xffffffff;
  }
  return '${a.toRadixString(16).padLeft(8, '0')}${b.toRadixString(16).padLeft(8, '0')}';
}
