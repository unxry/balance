import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageValidationException implements Exception {
  final String code;
  const ImageValidationException(this.code);

  @override
  String toString() => 'ImageValidationException($code)';
}

class SanitizedImage {
  final Uint8List bytes;
  final int width;
  final int height;

  const SanitizedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

class ImageSanitizer {
  static const maxInputBytes = 8 * 1024 * 1024;
  static const maxDimension = 6000;
  static const maxPixels = 24 * 1000 * 1000;
  static const outputLongEdge = 1600;

  static SanitizedImage sanitize(
    List<int> input, {
    bool cropSquare = false,
    int maxOutputLongEdge = outputLongEdge,
  }) {
    if (input.length < 24 || input.length > maxInputBytes) {
      throw const ImageValidationException('invalid_size');
    }
    final bytes = input is Uint8List ? input : Uint8List.fromList(input);
    final dimensions = _dimensions(bytes);
    if (dimensions == null) {
      throw const ImageValidationException('unsupported_or_corrupt');
    }
    final (width, height) = dimensions;
    if (width <= 0 ||
        height <= 0 ||
        width > maxDimension ||
        height > maxDimension ||
        width * height > maxPixels) {
      throw const ImageValidationException('dimensions_too_large');
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const ImageValidationException('decode_failed');
    }
    var normalized = img.bakeOrientation(decoded);
    if (cropSquare) {
      final edge = normalized.width < normalized.height
          ? normalized.width
          : normalized.height;
      normalized = img.copyCrop(
        normalized,
        x: (normalized.width - edge) ~/ 2,
        y: (normalized.height - edge) ~/ 2,
        width: edge,
        height: edge,
      );
    }
    final outputEdge = maxOutputLongEdge.clamp(128, outputLongEdge);
    final longEdge = normalized.width > normalized.height
        ? normalized.width
        : normalized.height;
    if (longEdge > outputEdge) {
      if (normalized.width >= normalized.height) {
        normalized = img.copyResize(normalized, width: outputEdge);
      } else {
        normalized = img.copyResize(normalized, height: outputEdge);
      }
    }

    // Re-encoding strips EXIF/GPS metadata and normalizes both PNG and JPEG to
    // a MIME type that matches the API data URI.
    var encoded = Uint8List.fromList(img.encodeJpg(normalized, quality: 85));
    if (encoded.length > 4 * 1024 * 1024) {
      encoded = Uint8List.fromList(img.encodeJpg(normalized, quality: 70));
    }
    if (encoded.length > 4 * 1024 * 1024) {
      throw const ImageValidationException('output_too_large');
    }
    return SanitizedImage(
      bytes: encoded,
      width: normalized.width,
      height: normalized.height,
    );
  }

  static (int, int)? _dimensions(Uint8List bytes) {
    const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    if (bytes.length >= 24 &&
        List.generate(8, (i) => bytes[i] == png[i]).every((v) => v)) {
      final width = _u32be(bytes, 16);
      final height = _u32be(bytes, 20);
      return (width, height);
    }
    if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
      return null;
    }
    var offset = 2;
    while (offset + 8 < bytes.length) {
      if (bytes[offset] != 0xff) {
        offset++;
        continue;
      }
      while (offset < bytes.length && bytes[offset] == 0xff) {
        offset++;
      }
      if (offset >= bytes.length) return null;
      final marker = bytes[offset++];
      if (marker == 0xd8 || marker == 0xd9 || marker == 0x01) continue;
      if (offset + 1 >= bytes.length) return null;
      final length = (bytes[offset] << 8) | bytes[offset + 1];
      if (length < 2 || offset + length > bytes.length) return null;
      final isStartOfFrame =
          marker >= 0xc0 &&
          marker <= 0xcf &&
          marker != 0xc4 &&
          marker != 0xc8 &&
          marker != 0xcc;
      if (isStartOfFrame) {
        if (length < 7) return null;
        final height = (bytes[offset + 3] << 8) | bytes[offset + 4];
        final width = (bytes[offset + 5] << 8) | bytes[offset + 6];
        return (width, height);
      }
      offset += length;
    }
    return null;
  }

  static int _u32be(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
