import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

final _fullAssets = <String>[
  'assets/character/idle.png',
  for (var index = 0; index < 16; index++)
    'assets/character/walk_${index.toString().padLeft(2, '0')}.png',
  for (var index = 0; index < 16; index++)
    'assets/character/run_${index.toString().padLeft(2, '0')}.png',
  for (var index = 0; index < 4; index++)
    'assets/character/transition_idle_walk_${index.toString().padLeft(2, '0')}.png',
  for (var index = 0; index < 5; index++)
    'assets/character/transition_walk_run_${index.toString().padLeft(2, '0')}.png',
];

final _smallAssets = <String>[
  'assets/character/dashboard_idle.png',
  for (var index = 0; index < 16; index++)
    'assets/character/dashboard_walk_${index.toString().padLeft(2, '0')}.png',
  for (var index = 0; index < 16; index++)
    'assets/character/dashboard_run_${index.toString().padLeft(2, '0')}.png',
  for (var index = 0; index < 4; index++)
    'assets/character/dashboard_transition_idle_walk_${index.toString().padLeft(2, '0')}.png',
  for (var index = 0; index < 5; index++)
    'assets/character/dashboard_transition_walk_run_${index.toString().padLeft(2, '0')}.png',
];

Future<(ui.Image, Uint8List)> _decode(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  return (frame.image, data!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('activity_sprite_alpha_test', () async {
    for (final path in [..._fullAssets, ..._smallAssets]) {
      final (image, pixels) = await _decode(path);
      var transparent = 0;
      var opaque = 0;
      var neon = 0;
      final blackMattePixels = <int>{};
      for (var offset = 0; offset < pixels.length; offset += 4) {
        final r = pixels[offset];
        final g = pixels[offset + 1];
        final b = pixels[offset + 2];
        final a = pixels[offset + 3];
        if (a == 0) transparent++;
        if (a >= 250) opaque++;
        // Very low alpha loses RGB precision during Skia unpremultiplication.
        if (a >= 16 && a < 250) {
          final greenFringe = g >= 250 && r <= 20 && b <= 20;
          final yellowFringe = r >= 250 && g >= 250 && b <= 30;
          if (greenFringe || yellowFringe) neon++;
          if (r < 12 && g < 12 && b < 12) {
            blackMattePixels.add(offset ~/ 4);
          }
        }
      }
      expect(transparent, greaterThan(image.width * image.height ~/ 3));
      expect(opaque, greaterThan(400));
      expect(neon, 0, reason: '$path contains neon edge pixels');
      // A matte forms a band; isolated Lanczos rounding pixels do not.
      final blackMatteBand = blackMattePixels.any((pixel) {
        final x = pixel % image.width;
        return (x > 0 && blackMattePixels.contains(pixel - 1)) ||
            (x + 1 < image.width && blackMattePixels.contains(pixel + 1)) ||
            blackMattePixels.contains(pixel - image.width) ||
            blackMattePixels.contains(pixel + image.width);
      });
      expect(
        blackMatteBand,
        isFalse,
        reason: '$path contains a black matte band',
      );
      image.dispose();
    }
  });

  test('activity_sprite_anchor_test', () async {
    final centers = <double>[];
    for (final path in _fullAssets.where((path) => path.contains('/walk_'))) {
      final (image, pixels) = await _decode(path);
      var minY = image.height;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          if (pixels[(y * image.width + x) * 4 + 3] >= 240) {
            minY = y < minY ? y : minY;
          }
        }
      }
      var sumX = 0.0;
      var count = 0;
      final headBottom = (minY + image.height * .24).round();
      for (var y = minY; y < headBottom && y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          if (pixels[(y * image.width + x) * 4 + 3] >= 240) {
            sumX += x;
            count++;
          }
        }
      }
      centers.add(sumX / count);
      image.dispose();
    }
    final minCenter = centers.reduce((a, b) => a < b ? a : b);
    final maxCenter = centers.reduce((a, b) => a > b ? a : b);
    expect(maxCenter - minCenter, lessThan(18));

    for (final path in _fullAssets) {
      final (image, _) = await _decode(path);
      expect((image.width, image.height), (256, 342));
      image.dispose();
    }
    for (final path in _smallAssets) {
      final (image, _) = await _decode(path);
      expect((image.width, image.height), (128, 171));
      image.dispose();
    }
  });

  test('all 16 walk poses are unique', () async {
    final fingerprints = <int>{};
    for (final path in _fullAssets.where((path) => path.contains('/walk_'))) {
      fingerprints.add(Object.hashAll(await File(path).readAsBytes()));
    }
    expect(fingerprints, hasLength(16));
  });

  test('all 16 run poses are unique', () async {
    final fingerprints = <int>{};
    for (final path in _fullAssets.where((path) => path.contains('/run_'))) {
      fingerprints.add(Object.hashAll(await File(path).readAsBytes()));
    }
    expect(fingerprints, hasLength(16));
  });

  test('all authored transition poses are unique', () async {
    for (final marker in ['transition_idle_walk_', 'transition_walk_run_']) {
      final assets = _fullAssets.where((path) => path.contains(marker));
      final fingerprints = <int>{};
      for (final path in assets) {
        fingerprints.add(Object.hashAll(await File(path).readAsBytes()));
      }
      expect(fingerprints, hasLength(marker.contains('idle') ? 4 : 5));
    }
  });
}
