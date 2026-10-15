import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:flutter_app/services/image_sanitizer.dart';

void main() {
  test('profile crop removes side letterboxing and produces a square', () {
    final source = img.Image(width: 200, height: 100);
    img.fill(source, color: img.ColorRgb8(255, 255, 255));
    img.fillRect(
      source,
      x1: 50,
      y1: 0,
      x2: 149,
      y2: 99,
      color: img.ColorRgb8(40, 120, 60),
    );

    final sanitized = ImageSanitizer.sanitize(
      img.encodePng(source),
      cropSquare: true,
      maxOutputLongEdge: 768,
    );
    final decoded = img.decodeJpg(sanitized.bytes)!;

    expect(sanitized.width, sanitized.height);
    expect(decoded.width, decoded.height);
    expect(decoded.getPixel(2, 50).g, greaterThan(80));
    expect(decoded.getPixel(2, 50).r, lessThan(100));
  });
}
