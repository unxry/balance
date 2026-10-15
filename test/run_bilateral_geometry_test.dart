import 'package:flutter_test/flutter_test.dart';

typedef RunGeometry = ({
  int frame,
  int leftAnkleX,
  int rightAnkleX,
  int leftKneeX,
  int rightKneeX,
  int pelvisX,
  String frontMostLeg,
});

const runGeometry = <RunGeometry>[
  (
    frame: 1,
    leftAnkleX: 190,
    rightAnkleX: 48,
    leftKneeX: 163,
    rightKneeX: 76,
    pelvisX: 116,
    frontMostLeg: 'LEFT',
  ),
  (
    frame: 2,
    leftAnkleX: 143,
    rightAnkleX: 62,
    leftKneeX: 151,
    rightKneeX: 91,
    pelvisX: 118,
    frontMostLeg: 'LEFT',
  ),
  (
    frame: 3,
    leftAnkleX: 151,
    rightAnkleX: 49,
    leftKneeX: 164,
    rightKneeX: 78,
    pelvisX: 119,
    frontMostLeg: 'LEFT',
  ),
  (
    frame: 4,
    leftAnkleX: 183,
    rightAnkleX: 48,
    leftKneeX: 160,
    rightKneeX: 88,
    pelvisX: 117,
    frontMostLeg: 'LEFT',
  ),
  (
    frame: 5,
    leftAnkleX: 48,
    rightAnkleX: 188,
    leftKneeX: 76,
    rightKneeX: 163,
    pelvisX: 116,
    frontMostLeg: 'RIGHT',
  ),
  (
    frame: 6,
    leftAnkleX: 60,
    rightAnkleX: 143,
    leftKneeX: 90,
    rightKneeX: 151,
    pelvisX: 118,
    frontMostLeg: 'RIGHT',
  ),
  (
    frame: 7,
    leftAnkleX: 151,
    rightAnkleX: 47,
    leftKneeX: 164,
    rightKneeX: 78,
    pelvisX: 119,
    frontMostLeg: 'LEFT',
  ),
  (
    frame: 8,
    leftAnkleX: 186,
    rightAnkleX: 49,
    leftKneeX: 161,
    rightKneeX: 86,
    pelvisX: 118,
    frontMostLeg: 'LEFT',
  ),
];

void main() {
  test('run contact phases use opposite knees and ankles', () {
    final r1 = runGeometry[0];
    final r5 = runGeometry[4];
    expect(r1.leftAnkleX, greaterThan(r1.pelvisX));
    expect(r1.leftKneeX, greaterThan(r1.pelvisX));
    expect(r1.rightAnkleX, lessThan(r1.pelvisX));
    expect(r5.rightAnkleX, greaterThan(r5.pelvisX));
    expect(r5.rightKneeX, greaterThan(r5.pelvisX));
    expect(r5.leftAnkleX, lessThan(r5.pelvisX));
  });

  test('both anatomical legs cross pelvis in both directions', () {
    for (final side in ['left', 'right']) {
      final ankles = runGeometry.map(
        (g) => side == 'left' ? g.leftAnkleX : g.rightAnkleX,
      );
      final knees = runGeometry.map(
        (g) => side == 'left' ? g.leftKneeX : g.rightKneeX,
      );
      expect(ankles.any((x) => x < 116), isTrue);
      expect(ankles.any((x) => x > 119), isTrue);
      expect(knees.any((x) => x < 116), isTrue);
      expect(knees.any((x) => x > 119), isTrue);
    }
  });
}
