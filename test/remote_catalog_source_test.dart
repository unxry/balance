import 'dart:convert';

import 'package:flutter_app/models/food_product.dart';
import 'package:flutter_app/services/remote_catalog_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('all retailer names become central API slugs', () async {
    const expected = {
      'Пятёрочка': 'pyaterochka',
      'Магнит': 'magnit',
      'Перекрёсток': 'perekrestok',
      'ВкусВилл': 'vkusvill',
      'ПОБЕДА': 'pobeda',
      'Fix Price': 'fix-price',
    };
    final requested = <String>[];
    final source = RemoteCatalogSource(
      baseUrl: 'https://catalog.balance.test',
      client: MockClient((request) async {
        requested.add(request.url.queryParameters['retailer']!);
        return http.Response('{"items": []}', 200);
      }),
    );

    for (final retailer in expected.keys) {
      final result = await source.browseRetailer(retailer);
      expect(result.items, isEmpty);
      expect(result.error, isNull);
    }
    expect(requested, expected.values);
  });

  test('retailer browse uses central API taxonomy filters', () async {
    late Uri requested;
    final source = RemoteCatalogSource(
      baseUrl: 'https://catalog.balance.test',
      client: MockClient((request) async {
        requested = request.url;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'items': [
                {
                  'id': 'bakery-1',
                  'name': 'Слойка с яблоком',
                  'retailer_tags': ['pyaterochka'],
                  'nutrition_basis': 'per100g',
                  'basis_amount': 100,
                  'energy_kcal': 290,
                  'source_type': 'open_food_facts',
                  'data_quality': 'partial',
                  'updated_at': '2026-09-08T10:00:00Z',
                },
              ],
            }),
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final outcome = await source.browseRetailer(
      'Пятёрочка',
      taxonomy: 'hotBakery',
      limit: 50,
    );

    expect(requested.path, '/products/browse');
    expect(requested.queryParameters['retailer'], 'pyaterochka');
    expect(requested.queryParameters['taxonomy'], 'hotBakery');
    expect(outcome.items.single.id, 'bakery-1');
    expect(outcome.items.single.dataQuality, FoodDataQuality.partial);
  });

  test(
    'maps provenance, package and nutrition without inventing fields',
    () async {
      final source = RemoteCatalogSource(
        baseUrl: 'https://catalog.balance.test',
        client: MockClient((request) async {
          expect(request.url.path, '/products/barcode/4607119490010');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'id': 'product-1',
                'barcode': '4607119490010',
                'name': 'Творог 5%',
                'normalized_name': 'творог 5',
                'brand': 'Бренд',
                'retailer_tags': ['magnit'],
                'net_weight': 180,
                'net_weight_unit': 'g',
                'nutrition_basis': 'per100g',
                'basis_amount': 100,
                'energy_kcal': 121,
                'protein': 17,
                'fat': 5,
                'carbohydrates': 3,
                'image_url': 'https://images.example/product.jpg',
                'source_type': 'open_food_facts',
                'data_quality': 'good',
                'nutrition_verified': false,
                'needs_review': false,
                'updated_at': '2026-09-05T10:00:00Z',
              }),
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final product = await source.findByBarcode('4607119490010');

      expect(product, isNotNull);
      expect(product!.source, FoodProductSource.openFoodFacts);
      expect(product.dataQuality, FoodDataQuality.good);
      expect(product.netWeightGrams, 180);
      expect(product.nutrition.isComplete, isTrue);
      expect(product.ingredients, isNull);
      expect(product.retailerTags, ['magnit']);
    },
  );

  test('keeps an unknown barcode distinct from server failure', () async {
    final source = RemoteCatalogSource(
      baseUrl: 'https://catalog.balance.test',
      client: MockClient((_) async => http.Response('{}', 404)),
    );

    expect(await source.findByBarcode('2999999999991'), isNull);
    expect(source.lastBarcodeError, isNull);
  });
}
