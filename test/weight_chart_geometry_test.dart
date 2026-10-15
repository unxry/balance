import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/screens/weight_screen.dart';

void main() {
  test('weight curve is smooth without endpoint overshoot', () {
    final source = [
      const FlSpot(0, 80),
      const FlSpot(1, 79.4),
      const FlSpot(2, 79.8),
      const FlSpot(3, 78.9),
    ];
    final curve = conservativeWeightCurveSpots(source);

    expect(curve.first, source.first);
    expect(curve.last, source.last);
    for (var segment = 0; segment < source.length - 1; segment++) {
      final minY = source[segment].y < source[segment + 1].y
          ? source[segment].y
          : source[segment + 1].y;
      final maxY = source[segment].y > source[segment + 1].y
          ? source[segment].y
          : source[segment + 1].y;
      final from = segment * 10;
      final to = from + 10;
      for (final spot in curve.sublist(from, to + 1)) {
        expect(spot.y, inInclusiveRange(minY, maxY));
      }
    }
    expect(curve.length, 31);
  });
  test('irregular curves preserve every reading and segment direction', () {
    final random = Random(42);
    for (var trial = 0; trial < 80; trial++) {
      var x = 0.0;
      final source = List.generate(12, (i) {
        x += i == 5 ? 0 : .05 + random.nextDouble() * 9;
        return FlSpot(x, i % 3 == 0 ? 80 : 78 + random.nextDouble() * 4);
      });
      final curve = conservativeWeightCurveSpots(source);
      for (var segment = 0; segment < source.length - 1; segment++) {
        expect(curve[segment * 10], source[segment]);
        final a = source[segment];
        final b = source[segment + 1];
        final samples = curve.sublist(segment * 10, segment * 10 + 11);
        for (var j = 0; j < samples.length; j++) {
          expect(samples[j].y, inInclusiveRange(min(a.y, b.y), max(a.y, b.y)));
          expect(samples[j].x, inInclusiveRange(a.x, b.x));
          if (j > 0) {
            expect(
              (samples[j].y - samples[j - 1].y) * (b.y - a.y),
              greaterThanOrEqualTo(-1e-10),
            );
          }
        }
      }
      expect(curve.last, source.last);
    }
  });
  test('a constant series stays constant and one reading stays one', () {
    expect(conservativeWeightCurveSpots([const FlSpot(3, 80)]), [
      const FlSpot(3, 80),
    ]);
    expect(
      conservativeWeightCurveSpots([
        const FlSpot(0, 80),
        const FlSpot(1, 80),
        const FlSpot(20, 80),
      ]).every((p) => p.y == 80),
      isTrue,
    );
  });
}
