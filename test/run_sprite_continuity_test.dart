import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

class _Frame {
  const _Frame({
    required this.width,
    required this.height,
    required this.mask,
    required this.alignedMask,
    required this.opaquePixels,
    required this.anchorX,
    required this.anchorY,
  });

  final int width;
  final int height;
  final Uint8List mask;
  final Uint8List alignedMask;
  final int opaquePixels;
  final double anchorX;
  final double anchorY;
}

Future<_Frame> _loadFrame(int index) async {
  final path = 'assets/character/run_${index.toString().padLeft(2, '0')}.png';
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  final pixels = data!.buffer.asUint8List();
  final mask = Uint8List(image.width * image.height);
  var opaquePixels = 0;
  var top = image.height;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (pixels[(y * image.width + x) * 4 + 3] >= 240) {
        mask[y * image.width + x] = 1;
        opaquePixels++;
        top = math.min(top, y);
      }
    }
  }

  var sumX = 0.0;
  var sumY = 0.0;
  var anchorPixels = 0;
  final anchorBottom = top + (image.height * .17).round();
  for (var y = top; y <= anchorBottom; y++) {
    for (var x = 0; x < image.width; x++) {
      if (mask[y * image.width + x] == 1) {
        sumX += x;
        sumY += y;
        anchorPixels++;
      }
    }
  }
  final anchorX = sumX / anchorPixels;
  final anchorY = sumY / anchorPixels;
  final dx = (image.width * .625 - anchorX).round();
  final dy = (image.height * .265 - anchorY).round();
  final alignedMask = Uint8List(mask.length);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final targetX = x + dx;
      final targetY = y + dy;
      if (targetX >= 0 &&
          targetX < image.width &&
          targetY >= 0 &&
          targetY < image.height) {
        alignedMask[targetY * image.width + targetX] =
            mask[y * image.width + x];
      }
    }
  }
  final frame = _Frame(
    width: image.width,
    height: image.height,
    mask: mask,
    alignedMask: alignedMask,
    opaquePixels: opaquePixels,
    anchorX: anchorX,
    anchorY: anchorY,
  );
  image.dispose();
  codec.dispose();
  return frame;
}

double _maskChange(Uint8List a, Uint8List b, {bool Function(int)? use}) {
  var union = 0;
  var changed = 0;
  for (var i = 0; i < a.length; i++) {
    if (use != null && !use(i)) continue;
    if (a[i] != 0 || b[i] != 0) union++;
    if (a[i] != b[i]) changed++;
  }
  return changed / union;
}

double _median(Iterable<double> values) {
  final sorted = values.toList()..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}

String _pair(int index) =>
    '${index.toString().padLeft(2, '0')}→${((index + 1) % 16).toString().padLeft(2, '0')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<_Frame> frames;

  setUpAll(() async {
    frames = await Future.wait([for (var i = 0; i < 16; i++) _loadFrame(i)]);
  });

  test('run alpha mass and root proxy stay stable', () {
    final issues = <String>[];
    final meanArea =
        frames.fold<int>(0, (sum, frame) => sum + frame.opaquePixels) /
        frames.length;
    for (var i = 0; i < frames.length; i++) {
      final areaRatio = frames[i].opaquePixels / meanArea;
      if (areaRatio < .81 || areaRatio > 1.18) {
        issues.add(
          '${i.toString().padLeft(2, '0')} alpha ${areaRatio.toStringAsFixed(2)}× mean',
        );
      }
      final next = frames[(i + 1) % frames.length];
      final rootStep = math.sqrt(
        math.pow(next.anchorX - frames[i].anchorX, 2) +
            math.pow(next.anchorY - frames[i].anchorY, 2),
      );
      if (rootStep > 7.5) {
        issues.add('${_pair(i)} root ${rootStep.toStringAsFixed(1)} px');
      }
    }
    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  test('run has no duplicate hold followed by a pose pop', () {
    final changes = [
      for (var i = 0; i < frames.length; i++)
        _maskChange(frames[i].mask, frames[(i + 1) % frames.length].mask),
    ];
    final issues = <String>[];
    for (var i = 0; i < changes.length; i++) {
      final following = math.max(
        changes[(i + 1) % changes.length],
        changes[(i + 2) % changes.length],
      );
      if (changes[i] < .08 && following > .18) {
        issues.add(
          '${_pair(i)} hold ${changes[i].toStringAsFixed(3)} before ${following.toStringAsFixed(3)}',
        );
      }
      if (changes[i] > .50) {
        issues.add('${_pair(i)} pop ${changes[i].toStringAsFixed(3)}');
      }
    }
    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  test('run seam is comparable to internal adjacent motion', () {
    final silhouetteSteps = [
      for (var i = 0; i < frames.length; i++)
        _maskChange(frames[i].mask, frames[(i + 1) % frames.length].mask),
    ];
    final rootSteps = [
      for (var i = 0; i < frames.length; i++)
        math.sqrt(
          math.pow(frames[(i + 1) % 16].anchorX - frames[i].anchorX, 2) +
              math.pow(frames[(i + 1) % 16].anchorY - frames[i].anchorY, 2),
        ),
    ];
    final bodySilhouette = _median(silhouetteSteps.take(15));
    final bodyRoot = _median(rootSteps.take(15));
    expect(
      silhouetteSteps.last,
      inInclusiveRange(bodySilhouette * .60, bodySilhouette * 1.45),
      reason: '15→00 silhouette seam differs from normal adjacent motion',
    );
    expect(
      rootSteps.last,
      lessThanOrEqualTo(math.max(3.0, bodyRoot * 1.50)),
      reason: '15→00 root seam is larger than normal adjacent motion',
    );
  });

  test('run has measurable head-aligned upper-peripheral motion', () {
    bool upperPeripheral(int offset) {
      final x = offset % frames.first.width;
      final y = offset ~/ frames.first.width;
      return y >= frames.first.height * .34 &&
          y <= frames.first.height * .56 &&
          (x <= frames.first.width * .51 || x >= frames.first.width * .70);
    }

    final adjacent = [
      for (var i = 0; i < frames.length; i++)
        _maskChange(
          frames[i].alignedMask,
          frames[(i + 1) % frames.length].alignedMask,
          use: upperPeripheral,
        ),
    ];
    // Half-cycle swaps can share a silhouette; quarter-cycle reach must move.
    final quarterPhase = [
      for (var i = 0; i < frames.length; i++)
        _maskChange(
          frames[i].alignedMask,
          frames[(i + 4) % frames.length].alignedMask,
          use: upperPeripheral,
        ),
    ];
    final adjacentMean = adjacent.reduce((a, b) => a + b) / adjacent.length;
    final phaseMean =
        quarterPhase.reduce((a, b) => a + b) / quarterPhase.length;
    expect(
      adjacentMean,
      greaterThanOrEqualTo(.19),
      reason: 'upper-peripheral adjacent motion is too weak',
    );
    expect(
      phaseMean,
      greaterThanOrEqualTo(.32),
      reason:
          'quarter-cycle run reach retains nearly the same upper silhouette',
    );
  });
}
