import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/weight_forecast.dart';
import 'package:flutter_app/services/progress_series.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12);
  for (final days in [7, 30, 90, 365]) {
    for (final atEnd in [false, true]) {
      test(
        '$days days, sparse records at ${atEnd ? 'end' : 'start'} fill the plot',
        () {
          final window = ProgressWindow(days: days, now: now);
          final start = atEnd ? DateTime(2026, 10, 13, 8) : window.start;
          final points = [
            ProgressPoint('a', start, 80),
            ProgressPoint('b', start.add(const Duration(hours: 12)), 79.9),
            ProgressPoint('c', start.add(const Duration(days: 2)), 79.8),
          ];
          final domain = ProgressDomain.forPoints(window, points);
          double fraction(DateTime date) =>
              (domain.x(window, date) - domain.minX) /
              (domain.maxX - domain.minX);
          expect(fraction(points.first.date), closeTo(1 / 22, 1e-9));
          expect(fraction(points.last.date), closeTo(21 / 22, 1e-9));
          expect(
            domain.x(window, points[1].date) / domain.span,
            closeTo(.25, 1e-9),
          );
          for (final point in points) {
            expect(
              domain.dateAt(window, domain.x(window, point.date)),
              point.date,
            );
          }
          expect(window.days, days);
          expect(points.map((p) => p.id), ['a', 'b', 'c']);
        },
      );
    }
  }
  test('empty and singleton domains remain finite with a left inset', () {
    final window = ProgressWindow(days: 30, now: now);
    final empty = ProgressDomain.forPoints(window, []);
    expect(empty.minX.isFinite && empty.maxX > empty.minX, isTrue);
    final point = ProgressPoint('one', now, 80);
    final one = ProgressDomain.forPoints(window, [point]);
    expect(one.span, 0);
    expect(
      (one.x(window, now) - one.minX) / (one.maxX - one.minX),
      closeTo(.06, 1e-9),
    );
    expect(one.dateAt(window, 0), now);
  });
  test('two intraday readings retain their actual hours', () {
    final window = ProgressWindow(days: 30, now: now);
    final points = [
      ProgressPoint('am', DateTime(2026, 10, 15, 8), 80),
      ProgressPoint('pm', DateTime(2026, 10, 15, 11), 80.1),
    ];
    final domain = ProgressDomain.forPoints(window, points);
    expect(domain.span, closeTo(3 / 24, 1e-10));
    expect(domain.dateAt(window, domain.span), points.last.date);
    expect(points, hasLength(2));
  });
  test('dense histories preserve all dates and proportions', () {
    final window = ProgressWindow(days: 365, now: now);
    final points = [
      for (var i = 0; i < 365; i++)
        ProgressPoint('$i', window.dateAt(i.toDouble()), 80 - i * .01),
    ];
    final domain = ProgressDomain.forPoints(window, points);
    expect(domain.span, 364);
    for (var i = 0; i < points.length; i++) {
      expect(domain.x(window, points[i].date), i.toDouble());
    }
  });
  test(
    'adds, edits and deletes recompute the range without modifying records',
    () {
      final window = ProgressWindow(days: 30, now: now);
      final a = ProgressPoint('a', DateTime(2026, 10, 14, 8), 80);
      final b = ProgressPoint('b', DateTime(2026, 10, 15, 8), 79.9);
      final before = ProgressDomain.forPoints(window, [a, b]);
      final c = ProgressPoint('c', DateTime(2026, 10, 1, 8), 80.5);
      final added = ProgressDomain.forPoints(window, [a, b, c]);
      expect(added.origin, lessThan(before.origin));
      expect(added.span, greaterThan(before.span));
      final edited = ProgressDomain.forPoints(window, [
        a,
        ProgressPoint('b', DateTime(2026, 10, 15, 11), 79.8),
      ]);
      expect(edited.span, greaterThan(before.span));
      final deleted = ProgressDomain.forPoints(window, [b]);
      expect(deleted.span, 0);
      expect(a.date, DateTime(2026, 10, 14, 8));
      expect(b.value, 79.9);
    },
  );
  test('forecast extends the axis but cannot squeeze the actual history', () {
    final window = ProgressWindow(days: 7, now: now);
    final points = [
      ProgressPoint('a', DateTime(2026, 10, 13, 8), 80),
      ProgressPoint('b', DateTime(2026, 10, 15, 8), 79.9),
    ];
    final forecast = [
      for (var d = 0; d <= 7; d++)
        WeightForecastPoint(
          date: DateTime(2026, 10, 15 + d, 8),
          kg: 79.9 - d * .03,
        ),
    ];
    final visible = forecastInProgressView(window, points, forecast);
    final domain = ProgressDomain.forPoints(window, points, forecast: visible);
    expect(visible, hasLength(3));
    expect(visible.first.date, points.last.date);
    expect(visible.last.date.isAfter(points.last.date), isTrue);
    expect(
      domain.x(window, points.last.date) / domain.span,
      greaterThanOrEqualTo(.5 - 1e-10),
    );
    expect(forecast, hasLength(8));
    expect(forecastInProgressView(window, [points.last], forecast), isEmpty);
  });
  test(
    'comparison uses the union of actual dates on the same uniform axis',
    () {
      final window = ProgressWindow(days: 30, now: now);
      final weight = ProgressPoint('weight', DateTime(2026, 10, 15, 8), 80);
      final chest = ProgressPoint('chest', DateTime(2026, 10, 1, 8), 92);
      final domain = ProgressDomain.forPoints(window, [weight, chest]);
      expect(
        domain.x(window, weight.date) - domain.x(window, chest.date),
        closeTo(14, 1e-10),
      );
      expect(lastPointOnDay([chest], weight.date), isNull);
    },
  );
}
