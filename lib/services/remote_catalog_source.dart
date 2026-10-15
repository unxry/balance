import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_product.dart';
import 'food_catalog_repository.dart';
import 'food_search_service.dart';
import 'sqlite_product_cache.dart';

class CatalogUpdatePage {
  final List<FoodProduct> items;
  final String? nextCursor;

  const CatalogUpdatePage(this.items, this.nextCursor);
}

class RemoteCatalogSource
    implements
        FoodProductSourceAdapter,
        RetailerBrowseSource,
        CentralCatalogSource {
  RemoteCatalogSource({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? configuredBaseUrl).replaceAll(RegExp(r'/$'), ''),
      _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const configuredBaseUrl = String.fromEnvironment(
    'BALANCE_CATALOG_API_URL',
  );

  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout = const Duration(seconds: 8);

  bool get isConfigured => baseUrl.startsWith('https://');

  @override
  FoodSearchError? lastBarcodeError;

  @override
  Future<FoodSearchOutcome> search(String query, {int limit = 20}) async {
    if (!isConfigured || query.trim().length < 2) {
      return const FoodSearchOutcome([]);
    }
    try {
      final payload = await _getJson(
        Uri.parse(
          '$baseUrl/products/search',
        ).replace(queryParameters: {'q': query.trim(), 'limit': '$limit'}),
      );
      return FoodSearchOutcome(_products(payload['items']));
    } on TimeoutException {
      return const FoodSearchOutcome([], error: FoodSearchError.timeout);
    } on http.ClientException {
      return const FoodSearchOutcome([], error: FoodSearchError.offline);
    } on _CatalogServerException {
      return const FoodSearchOutcome([], error: FoodSearchError.server);
    } on FormatException {
      return const FoodSearchOutcome(
        [],
        error: FoodSearchError.invalidResponse,
      );
    }
  }

  @override
  Future<FoodSearchOutcome> browseRetailer(
    String retailer, {
    String taxonomy = 'all',
    int limit = 20,
  }) async {
    if (!isConfigured) return const FoodSearchOutcome([]);
    try {
      final payload = await _getJson(
        Uri.parse('$baseUrl/products/browse').replace(
          queryParameters: {
            'retailer': canonicalRetailerId(retailer).replaceAll('_', '-'),
            'taxonomy': taxonomy,
            'limit': '${limit.clamp(1, 100)}',
          },
        ),
      );
      return FoodSearchOutcome(_products(payload['items']));
    } on TimeoutException {
      return const FoodSearchOutcome([], error: FoodSearchError.timeout);
    } on http.ClientException {
      return const FoodSearchOutcome([], error: FoodSearchError.offline);
    } on _CatalogServerException {
      return const FoodSearchOutcome([], error: FoodSearchError.server);
    } on FormatException {
      return const FoodSearchOutcome(
        [],
        error: FoodSearchError.invalidResponse,
      );
    }
  }

  @override
  Future<FoodProduct?> findByBarcode(String barcode) async {
    lastBarcodeError = null;
    if (!isConfigured) return null;
    try {
      final payload = await _getJson(
        Uri.parse('$baseUrl/products/barcode/$barcode'),
        allowNotFound: true,
      );
      return payload.isEmpty ? null : _product(payload);
    } on TimeoutException {
      lastBarcodeError = FoodSearchError.timeout;
    } on http.ClientException {
      lastBarcodeError = FoodSearchError.offline;
    } on _CatalogServerException {
      lastBarcodeError = FoodSearchError.server;
    } on FormatException {
      lastBarcodeError = FoodSearchError.invalidResponse;
    }
    return null;
  }

  Future<CatalogUpdatePage> updates({String? cursor, int limit = 100}) async {
    if (!isConfigured) return const CatalogUpdatePage([], null);
    final payload = await _getJson(
      Uri.parse('$baseUrl/products/updates').replace(
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': '$limit',
        },
      ),
    );
    return CatalogUpdatePage(
      _products(payload['items']),
      payload['nextCursor'] is String ? payload['nextCursor'] as String : null,
    );
  }

  Future<void> syncOnePage(SqliteProductCache cache) async {
    if (!isConfigured) return;
    final cursor = await cache.readSyncCursor('remote-catalog');
    final page = await updates(cursor: cursor);
    if (page.items.isNotEmpty) await cache.writeAll(page.items);
    if (page.nextCursor != null) {
      await cache.writeSyncCursor('remote-catalog', page.nextCursor!);
    }
  }

  Future<int> syncCatalog(
    SqliteProductCache cache, {
    int maxPages = 20,
    int pageSize = 500,
  }) async {
    if (!isConfigured) return 0;
    var cursor = await cache.readSyncCursor('remote-catalog');
    var downloaded = 0;
    try {
      for (var pageIndex = 0; pageIndex < maxPages; pageIndex++) {
        final page = await updates(cursor: cursor, limit: pageSize);
        if (page.items.isNotEmpty) {
          await cache.writeAll(page.items);
          downloaded += page.items.length;
        }
        final next = page.nextCursor;
        if (next == null || next == cursor || page.items.isEmpty) break;
        await cache.writeSyncCursor('remote-catalog', next);
        cursor = next;
      }
    } on TimeoutException {
      return downloaded;
    } on http.ClientException {
      return downloaded;
    } on _CatalogServerException {
      return downloaded;
    } on FormatException {
      return downloaded;
    }
    return downloaded;
  }

  Future<Map<String, dynamic>> _getJson(
    Uri uri, {
    bool allowNotFound = false,
  }) async {
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(timeout);
    if (allowNotFound && response.statusCode == 404) return const {};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const _CatalogServerException();
    }
    if (response.bodyBytes.length > 2 * 1024 * 1024) {
      throw const FormatException('Catalog response is too large');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) throw const FormatException('Invalid catalog JSON');
    return Map<String, dynamic>.from(decoded);
  }

  List<FoodProduct> _products(Object? value) => value is List
      ? value.map(_product).whereType<FoodProduct>().toList()
      : const [];

  FoodProduct? _product(Object? value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final id = map['id'];
    final name = map['name'];
    if (id is! String || name is! String || name.trim().isEmpty) return null;
    final basis = switch (map['nutrition_basis']) {
      'per100ml' => FoodNutritionBasis.per100ml,
      'per_serving' => FoodNutritionBasis.perServing,
      'per_item' => FoodNutritionBasis.perItem,
      _ => FoodNutritionBasis.per100g,
    };
    final source = switch (map['source_type']) {
      'manufacturer' => FoodProductSource.officialManufacturer,
      'official_retailer' => FoodProductSource.officialRetailer,
      'restaurant_menu' => FoodProductSource.restaurantMenu,
      'open_food_facts' => FoodProductSource.openFoodFacts,
      _ => FoodProductSource.verifiedCatalog,
    };
    final quality = switch (map['data_quality']) {
      'verified' => FoodDataQuality.verified,
      'good' => FoodDataQuality.good,
      'partial' => FoodDataQuality.partial,
      _ => FoodDataQuality.unverified,
    };
    final packageValue = _number(map['net_weight']);
    final packageUnit = map['net_weight_unit'] as String?;
    return FoodProduct(
      id: id,
      barcode: map['barcode'] as String?,
      name: name,
      normalizedName: map['normalized_name'] as String?,
      brand: map['brand'] as String?,
      retailerTags:
          (map['retailer_tags'] as List?)?.whereType<String>().toList() ??
          const [],
      category: map['category'] as String?,
      packageAmount: packageValue,
      packageUnit: packageUnit,
      netWeightGrams: packageUnit == 'g' ? packageValue : null,
      netVolumeMl: packageUnit == 'ml' ? packageValue : null,
      servingSize: _number(map['serving_size']),
      servingUnit: map['serving_unit'] as String?,
      nutritionBasis: basis,
      nutritionBasisAmount: _number(map['basis_amount']),
      nutrition: NutritionValues(
        calories: _number(map['energy_kcal']),
        protein: _number(map['protein']),
        fat: _number(map['fat']),
        carbs: _number(map['carbohydrates']),
      ),
      ingredients: map['ingredients'] as String?,
      imageUrl: map['image_url'] as String?,
      source: source,
      sourceProductId: id,
      sourceUrl: map['source_url'] as String?,
      nutritionSource: source,
      nutritionVerified: map['nutrition_verified'] == true,
      dataQuality: quality,
      imageLicense: map['image_license'] as String?,
      imageAttribution: map['image_attribution'] as String?,
      lastUpdatedAt: DateTime.tryParse('${map['updated_at']}'),
      lastFetchedAt: DateTime.now().toUtc(),
      lastVerifiedAt: map['last_verified_at'] == null
          ? null
          : DateTime.tryParse('${map['last_verified_at']}'),
      sourceRevision: map['source_revision'] as String?,
      needsReview: map['needs_review'] == true,
    );
  }

  double? _number(Object? value) => value is num
      ? value.toDouble()
      : value is String
      ? double.tryParse(value)
      : null;

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

class _CatalogServerException implements Exception {
  const _CatalogServerException();
}
