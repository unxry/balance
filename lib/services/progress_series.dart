import 'dart:math';

import '../models/weight_forecast.dart';
import '../utils/calendar_date.dart';

/// Rolling local calendar days, including today: 7 / 30 / 90 / 365.
/// Midnight at start is inclusive; midnight after today is exclusive.
class ProgressWindow {
  final int days;
  final DateTime start;
  final DateTime endExclusive;

  ProgressWindow({required this.days, required DateTime now})
    : assert(days > 0),
      start = DateTime(
        now.toLocal().year,
        now.toLocal().month,
        now.toLocal().day - days + 1,
      ),
      endExclusive = DateTime(
        now.toLocal().year,
        now.toLocal().month,
        now.toLocal().day + 1,
      );

  bool contains(DateTime date) =>
      !date.isBefore(start) && date.isBefore(endExclusive);

  // Civil coordinates keep dates aligned even on 23/25-hour DST days.
  double x(DateTime date) {
    final local = date.toLocal();
    return DateTime.utc(
              local.year,
              local.month,
              local.day,
              local.hour,
              local.minute,
              local.second,
              local.millisecond,
              local.microsecond,
            )
            .difference(DateTime.utc(start.year, start.month, start.day))
            .inMicroseconds /
        Duration.microsecondsPerDay;
  }

  DateTime dateAt(double x) {
    final civil = DateTime.utc(
      start.year,
      start.month,
      start.day,
    ).add(Duration(microseconds: (x * Duration.microsecondsPerDay).round()));
    return DateTime(
      civil.year,
      civil.month,
      civil.day,
      civil.hour,
      civil.minute,
      civil.second,
      civil.millisecond,
      civil.microsecond,
    );
  }
}

class ProgressPoint {
  final String id;
  final DateTime date;
  final double value;

  const ProgressPoint(this.id, this.date, this.value);
}

/// A uniform civil-time scale, cropped to the real dates in the chosen period.
class ProgressDomain {
  final double origin;
  final double span;
  const ProgressDomain(this.origin, this.span);

  factory ProgressDomain.forPoints(
    ProgressWindow window,
    Iterable<ProgressPoint> points, {
    List<WeightForecastPoint> forecast = const [],
  }) {
    final dates = points
        .where((p) => window.contains(p.date))
        .map((p) => window.x(p.date))
        .toList();
    if (dates.isEmpty) return const ProgressDomain(0, 0);
    final first = dates.reduce(min);
    final last = [
      ...dates,
      ...forecast.map((p) => window.x(p.date)),
    ].reduce(max);
    return ProgressDomain(first, max(0, last - first));
  }

  double get minX => span == 0 ? -.06 : -span * .05;
  double get maxX => span == 0 ? .94 : span * 1.05;
  double x(ProgressWindow window, DateTime date) => window.x(date) - origin;
  DateTime dateAt(ProgressWindow window, double x) => window.dateAt(origin + x);
}

/// Limit the visible continuation rather than distort real time intervals.
List<WeightForecastPoint> forecastInProgressView(
  ProgressWindow window,
  List<ProgressPoint> actual,
  List<WeightForecastPoint> forecast,
) {
  if (actual.isEmpty || forecast.isEmpty) return const [];
  final dates = actual.map((p) => window.x(p.date)).toList();
  final span = dates.reduce(max) - dates.reduce(min);
  if (span < 1 - 1e-9) return const [];
  return List.unmodifiable(forecast.take((span + 1e-9).floor() + 1));
}

List<ProgressPoint> pointsInWindow(
  Iterable<ProgressPoint> source,
  ProgressWindow window,
) =>
    source.where((point) => window.contains(point.date)).toList()..sort((a, b) {
      final order = a.date.compareTo(b.date);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });

double? progressChange(List<ProgressPoint> sorted) =>
    sorted.length < 2 ? null : sorted.last.value - sorted.first.value;

/// Comparison uses the last real reading on the selected local day.
/// No interpolation or carrying values from adjacent dates.
ProgressPoint? lastPointOnDay(List<ProgressPoint> sorted, DateTime day) {
  final key = localDateKey(day);
  for (final point in sorted.reversed) {
    if (localDateKey(point.date) == key) return point;
  }
  return null;
}

class ProgressScale {
  final double minY;
  final double maxY;
  final double step;

  const ProgressScale(this.minY, this.maxY, this.step);

  factory ProgressScale.forValues(
    Iterable<double> values, {
    required double minimumSpan,
  }) {
    final data = values.toList();
    if (data.isEmpty) return const ProgressScale(0, 10, 5);
    final low = data.reduce(min);
    final high = data.reduce(max);
    final span = max(minimumSpan, (high - low) * 1.4);
    final roughStep = span / 3;
    final magnitude = pow(10, (log(roughStep) / ln10).floor()).toDouble();
    final normalized = roughStep / magnitude;
    final step =
        (normalized <= 1
            ? 1
            : normalized <= 2
            ? 2
            : normalized <= 2.5
            ? 2.5
            : normalized <= 5
            ? 5
            : 10) *
        magnitude;
    final center = (low + high) / 2;
    final quantum = step / 5;
    final bottom = max(0.0, ((center - span / 2) / quantum).floor() * quantum);
    final top = ((center + span / 2) / quantum).ceil() * quantum;
    return ProgressScale(bottom, top, step);
  }
}
