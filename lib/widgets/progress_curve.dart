import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

/// Shape-preserving Hermite interpolation. Generated vertices are drawing
/// geometry only; measurement markers and hit testing use the original records.
List<FlSpot> conservativeWeightCurveSpots(
  List<FlSpot> spots, {
  int samplesPerSegment = 10,
}) {
  if (spots.length < 2 || samplesPerSegment < 1) return List.of(spots);
  final indexed = spots.asMap().entries.toList()
    ..sort((a, b) {
      final order = a.value.x.compareTo(b.value.x);
      return order == 0 ? a.key.compareTo(b.key) : order;
    });
  final points = indexed.map((e) => e.value).toList();
  final h = List.generate(
    points.length - 1,
    (i) => points[i + 1].x - points[i].x,
  );
  final d = List.generate(
    h.length,
    (i) => h[i] == 0 ? 0.0 : (points[i + 1].y - points[i].y) / h[i],
  );
  final m = List<double>.filled(points.length, 0);
  for (var i = 1; i < points.length - 1; i++) {
    if (d[i - 1] * d[i] <= 0 || h[i - 1] == 0 || h[i] == 0) continue;
    final w1 = 2 * h[i] + h[i - 1];
    final w2 = h[i] + 2 * h[i - 1];
    m[i] = (w1 + w2) / (w1 / d[i - 1] + w2 / d[i]);
  }
  double endpoint(double h0, double h1, double d0, double d1) {
    if (h0 == 0 || d0 == 0) return 0;
    final value = ((2 * h0 + h1) * d0 - h0 * d1) / (h0 + h1);
    if (value.sign != d0.sign) return 0;
    return d0.sign != d1.sign && value.abs() > 3 * d0.abs() ? 3 * d0 : value;
  }

  if (d.length == 1) {
    m[0] = m[1] = d[0];
  } else {
    m[0] = endpoint(h[0], h[1], d[0], d[1]);
    m.last = endpoint(h.last, h[h.length - 2], d.last, d[d.length - 2]);
  }
  for (var i = 0; i < d.length; i++) {
    if (d[i] == 0) {
      m[i] = m[i + 1] = 0;
      continue;
    }
    final a = m[i] / d[i];
    final b = m[i + 1] / d[i];
    final norm = a * a + b * b;
    if (norm > 9) {
      final scale = 3 / sqrt(norm);
      m[i] = scale * a * d[i];
      m[i + 1] = scale * b * d[i];
    }
  }
  final result = <FlSpot>[points.first];
  for (var i = 0; i < d.length; i++) {
    for (var step = 1; step <= samplesPerSegment; step++) {
      if (step == samplesPerSegment) {
        result.add(points[i + 1]);
        continue;
      }
      final t = step / samplesPerSegment;
      final t2 = t * t;
      final t3 = t2 * t;
      final y =
          (2 * t3 - 3 * t2 + 1) * points[i].y +
          (t3 - 2 * t2 + t) * h[i] * m[i] +
          (-2 * t3 + 3 * t2) * points[i + 1].y +
          (t3 - t2) * h[i] * m[i + 1];
      result.add(
        FlSpot(
          points[i].x + h[i] * t,
          y.clamp(
            min(points[i].y, points[i + 1].y),
            max(points[i].y, points[i + 1].y),
          ),
        ),
      );
    }
  }
  return result;
}
