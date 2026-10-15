import 'package:flutter_app/services/food_search_service.dart';

Future<void> main() async {
  final source = FoodSearchService(timeout: const Duration(seconds: 15));
  const barcodes = <String>[
    '3017620422003',
    '5449000000996',
    '4607119490010',
    '2999999999991',
  ];
  try {
    for (final barcode in barcodes) {
      final watch = Stopwatch()..start();
      final product = await source.findByBarcode(barcode);
      watch.stop();
      // ignore: avoid_print
      print({
        'barcode': barcode,
        'ms': watch.elapsedMilliseconds,
        'found': product != null,
        'name': product?.name,
        'brand': product?.brand,
        'quality': product?.dataQuality.name,
        'completeNutrition': product?.hasCompleteNutrition,
        'error': source.lastBarcodeError?.name,
      });
    }
  } finally {
    source.dispose();
  }
}
