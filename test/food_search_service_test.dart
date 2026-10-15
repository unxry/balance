import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_app/services/food_search_service.dart';

void main() {
  test(
    'retailer browse requests the store tag and parses its products',
    () async {
      late Uri requested;
      final service = FoodSearchService(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'products': [
                  {
                    'code': '4601234567890',
                    'product_name_ru': 'Салат',
                    'stores': 'Пятёрочка',
                    'nutriments': {'energy-kcal_100g': 120},
                  },
                ],
              }),
            ),
            200,
          );
        }),
      );

      final outcome = await service.browseRetailer('pyaterochka', limit: 40);

      expect(outcome.error, isNull);
      expect(requested.queryParameters['tagtype_0'], 'stores');
      expect(requested.queryParameters['tag_0'], 'Пятёрочка');
      expect(requested.queryParameters['page_size'], '40');
      expect(outcome.items.single.retailerTags, contains('Пятёрочка'));
    },
  );

  test('parses and bounds Open Food Facts results', () async {
    final service = FoodSearchService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'products': [
              {
                'product_name': 'Yogurt',
                'brands': 'Brand',
                'nutriments': {
                  'energy-kcal_100g': '62',
                  'proteins_100g': 4,
                  'fat_100g': 3,
                  'carbohydrates_100g': 5,
                },
              },
              {'product_name': 'Broken'},
            ],
          }),
          200,
        ),
      ),
    );

    final outcome = await service.search('yogurt');

    expect(outcome.error, isNull);
    expect(outcome.items, hasLength(2));
    expect(outcome.items.first.name, 'Yogurt');
    expect(outcome.items.first.brand, 'Brand');
    expect(outcome.items.first.kcalPer100g, 62);
    expect(outcome.items.last.hasCompleteNutrition, isFalse);
  });

  test('returns an offline state instead of throwing', () async {
    final service = FoodSearchService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    final outcome = await service.search('apple');

    expect(outcome.items, isEmpty);
    expect(outcome.error, FoodSearchError.offline);
  });

  test('parses current v3 barcode nutrition schema', () async {
    final service = FoodSearchService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'product': {
              'code': '3017620422003',
              'product_name': 'Nutella',
              'nutrition': {
                'aggregated_set': {
                  'nutrients': {
                    'energy-kcal': {'value': 539, 'source_per': '100g'},
                    'proteins': {'value': 6.3},
                    'fat': {'value': 30.9},
                    'carbohydrates': {'value': 57.5},
                  },
                },
              },
            },
          }),
          200,
        ),
      ),
    );

    final product = await service.findByBarcode('3017620422003');
    expect(product, isNotNull);
    expect(product!.nutrition.calories, 539);
    expect(product.nutrition.protein, 6.3);
  });

  test('handles HTTP and invalid JSON responses', () async {
    final server = FoodSearchService(
      client: MockClient((_) async => http.Response('down', 500)),
    );
    final invalid = FoodSearchService(
      client: MockClient((_) async => http.Response('[]', 200)),
    );

    expect((await server.search('apple')).error, FoodSearchError.server);
    expect(
      (await invalid.search('apple')).error,
      FoodSearchError.invalidResponse,
    );
  });

  test('treats an unknown barcode as not found, not a server error', () async {
    final service = FoodSearchService(
      client: MockClient((_) async => http.Response('not found', 404)),
    );

    expect(await service.findByBarcode('2999999999991'), isNull);
    expect(service.lastBarcodeError, isNull);
  });
}
