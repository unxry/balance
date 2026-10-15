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
}
