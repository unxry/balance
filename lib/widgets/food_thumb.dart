import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Renders a stylised food "photo" using layered radial gradients,
/// matching the CSS food renderings from the design (no external images).
/// `seed` picks a deterministic palette so the same food always looks
/// the same across the app.
class FoodThumb extends StatelessWidget {
  static final CacheManager _imageCache = CacheManager(
    Config(
      'balanceProductImagesV1',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 300,
    ),
  );
  final int seed;
  final double size;
  final double radius;
  final String? imageUrl;
  final Uint8List? imageBytes;

  const FoodThumb({
    super.key,
    required this.seed,
    this.size = 34,
    this.radius = 10,
    this.imageUrl,
    this.imageBytes,
  });

  static const _palettes = [
    [Color(0xFFE7C48A), Color(0xFFC98F4A)], // oats
    [Color(0xFF8A6A4B), Color(0xFF4B3626)], // coffee
    [Color(0xFF7FA65A), Color(0xFF4F7D3E)], // salad
    [Color(0xFFD8B36B), Color(0xFFB8933A)], // tea/honey
    [Color(0xFFC9A876), Color(0xFF8A6A44)], // nuts
    [Color(0xFFD97A3E), Color(0xFFA85A2A)], // chicken
    [Color(0xFFE0A64E), Color(0xFFB87A2E)], // chicken2
    [Color(0xFFC97A5A), Color(0xFF8A4A32)], // soup
    [Color(0xFFDCC47A), Color(0xFFB8933A)], // wrap
    [Color(0xFFE79A7A), Color(0xFFC15A3E)], // fish/salmon
    [Color(0xFFEAD9A8), Color(0xFFC9A876)], // oats+berries
    [Color(0xFF9BB86E), Color(0xFF4F7D3E)], // greens
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[(seed & 0x7fffffff) % _palettes.length];
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 1.1,
          colors: palette,
        ),
      ),
    );
    final uri = imageUrl == null ? null : Uri.tryParse(imageUrl!);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: imageBytes != null
            ? Image.memory(
                imageBytes!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : uri?.scheme == 'https'
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: CachedNetworkImage(
                  cacheManager: _imageCache,
                  imageUrl: imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  fadeInDuration: const Duration(milliseconds: 120),
                  placeholder: (_, __) => placeholder,
                  errorWidget: (_, __, ___) => placeholder,
                ),
              )
            : placeholder,
      ),
    );
  }
}
