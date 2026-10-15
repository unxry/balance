import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_product.dart';

enum FoodSearchError { offline, server, invalidResponse, timeout }

class FoodSearchOutcome {
  final List<FoodProduct> items;
  final FoodSearchError? error;

  const FoodSearchOutcome(this.items, {this.error});
}

abstract interface class FoodProductSourceAdapter {
  FoodSearchError? get lastBarcodeError;
  Future<FoodSearchOutcome> search(String query, {int limit = 20});
  Future<FoodProduct?> findByBarcode(String barcode);
}

abstract interface class RetailerBrowseSource {
  Future<FoodSearchOutcome> browseRetailer(
    String retailer, {
    String taxonomy = 'all',
    int limit = 20,
  });
}

/// Marker used only for diagnostics so central API results stay distinguishable
/// from direct public-catalog fallbacks.
abstract interface class CentralCatalogSource {}

/// Open Food Facts adapter. Full-text search still uses its documented legacy
/// endpoint because v3 does not expose full-text search; barcode reads use v3.
class FoodSearchService
    implements FoodProductSourceAdapter, RetailerBrowseSource {
  FoodSearchService({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const _searchUrl = 'https://world.openfoodfacts.org/cgi/search.pl';
  static const _productUrl = 'https://world.openfoodfacts.org/api/v3.6/product';
  static const _maxResponseBytes = 2 * 1024 * 1024;
  static const _fields =
      'code,product_name,product_name_ru,product_name_en,brands,quantity,'
      'serving_size,nutrition_data_per,nutriments,nutrition,ingredients_text,'
      'ingredients_text_ru,categories,categories_tags,image_front_url,'
      'stores,states_tags,last_modified_t,rev';

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  @override
  FoodSearchError? lastBarcodeError;

  Map<String, String> get _headers => const {
    'User-Agent': 'Balance/1.0 (com.arturovna01.balancetracker)',
    'Accept': 'application/json',
  };

  @override
  Future<FoodSearchOutcome> search(String query, {int limit = 20}) async {
    final normalized = query.trim();
    if (normalized.length < 2) return const FoodSearchOutcome([]);
    final safeLimit = limit.clamp(1, 50);
    final uri = Uri.parse(_searchUrl).replace(
      queryParameters: {
        'search_terms': normalized,
        'json': '1',
        'page_size': safeLimit.toString(),
        'fields': _fields,
        'sort_by': 'unique_scans_n',
      },
    );
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(timeout);
      final decoded = _decodeResponse(response);
      final products = decoded['products'];
      if (products is! List) throw const FormatException('Missing products');
      return FoodSearchOutcome(
        products
            .map(_parseProduct)
            .whereType<FoodProduct>()
            .take(safeLimit)
            .toList(),
      );
    } on TimeoutException {
      return const FoodSearchOutcome([], error: FoodSearchError.timeout);
    } on http.ClientException {
      return const FoodSearchOutcome([], error: FoodSearchError.offline);
    } on _ServerException {
      return const FoodSearchOutcome([], error: FoodSearchError.server);
    } on FormatException {
      return const FoodSearchOutcome(
        [],
        error: FoodSearchError.invalidResponse,
      );
    } catch (_) {
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
    final store = switch (retailer) {
      'pyaterochka' => 'Пятёрочка',
      'magnit' => 'Магнит',
      'perekrestok' => 'Перекрёсток',
      'vkusvill' => 'ВкусВилл',
      'pobeda' => 'Победа',
      'fix_price' => 'Fix Price',
      _ => retailer,
    };
    final safeLimit = limit.clamp(1, 50);
    final uri = Uri.parse(_searchUrl).replace(
      queryParameters: {
        'tagtype_0': 'stores',
        'tag_contains_0': 'contains',
        'tag_0': store,
        'json': '1',
        'page_size': safeLimit.toString(),
        'fields': _fields,
        'sort_by': 'unique_scans_n',
      },
    );
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(timeout);
      final decoded = _decodeResponse(response);
      final products = decoded['products'];
      if (products is! List) throw const FormatException('Missing products');
      return FoodSearchOutcome(
        products
            .map(_parseProduct)
            .whereType<FoodProduct>()
            .take(safeLimit)
            .toList(),
      );
    } on TimeoutException {
      return const FoodSearchOutcome([], error: FoodSearchError.timeout);
    } on http.ClientException {
      return const FoodSearchOutcome([], error: FoodSearchError.offline);
    } on _ServerException {
      return const FoodSearchOutcome([], error: FoodSearchError.server);
    } on FormatException {
      return const FoodSearchOutcome(
        [],
        error: FoodSearchError.invalidResponse,
      );
    } catch (_) {
      return const FoodSearchOutcome(
        [],
        error: FoodSearchError.invalidResponse,
      );
    }
  }

  @override
  Future<FoodProduct?> findByBarcode(String barcode) async {
    lastBarcodeError = null;
    final code = barcode.replaceAll(RegExp(r'\D'), '');
    if (code.length < 8 || code.length > 14) return null;
    final uri = Uri.parse(
      '$_productUrl/$code.json',
    ).replace(queryParameters: {'fields': _fields});
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(timeout);
      if (response.statusCode == 404) return null;
      final decoded = _decodeResponse(response);
      return _parseProduct(decoded['product']);
    } on TimeoutException {
      lastBarcodeError = FoodSearchError.timeout;
      return null;
    } on http.ClientException {
      lastBarcodeError = FoodSearchError.offline;
      return null;
    } on _ServerException {
      lastBarcodeError = FoodSearchError.server;
      return null;
    } catch (_) {
      lastBarcodeError = FoodSearchError.invalidResponse;
      return null;
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const _ServerException();
    }
    if (response.bodyBytes.isEmpty ||
        response.bodyBytes.length > _maxResponseBytes) {
      throw const FormatException('Invalid response size');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) throw const FormatException('Invalid response');
    return Map<String, dynamic>.from(decoded);
  }

  FoodProduct? _parseProduct(Object? value) {
    if (value is! Map) return null;
    final product = Map<String, dynamic>.from(value);
    final name = _firstText(product, const [
      'product_name_ru',
      'product_name',
      'product_name_en',
    ]);
    if (name == null) return null;
    final code = _digits(product['code']);
    final nutriments = product['nutriments'] is Map
        ? Map<String, dynamic>.from(product['nutriments'] as Map)
        : <String, dynamic>{};
    final v3Nutrients = _v3Nutrients(product['nutrition']);
    final sourcePer = _v3NutrientField(
      v3Nutrients,
      'energy-kcal',
      'source_per',
    );
    final perServing =
        product['nutrition_data_per'] == 'serving' || sourcePer == 'serving';
    final per100ml =
        product['nutrition_data_per'] == '100ml' || sourcePer == '100ml';
    final suffix = perServing ? '_serving' : '_100g';
    final nutrition = NutritionValues(
      calories: _bounded(
        _number(_v3NutrientField(v3Nutrients, 'energy-kcal', 'value')) ??
            _number(nutriments['energy-kcal$suffix']) ??
            _number(nutriments['energy-kcal_100g']) ??
            _number(nutriments['energy-kcal']),
        0,
        2000,
      ),
      protein: _bounded(
        _number(_v3NutrientField(v3Nutrients, 'proteins', 'value')) ??
            _number(nutriments['proteins$suffix']),
        0,
        200,
      ),
      fat: _bounded(
        _number(_v3NutrientField(v3Nutrients, 'fat', 'value')) ??
            _number(nutriments['fat$suffix']),
        0,
        200,
      ),
      carbs: _bounded(
        _number(_v3NutrientField(v3Nutrients, 'carbohydrates', 'value')) ??
            _number(nutriments['carbohydrates$suffix']),
        0,
        300,
      ),
    );
    final serving = _amount(_firstText(product, const ['serving_size']));
    final quantity = _firstText(product, const ['quantity']);
    final netAmount = _amount(quantity);
    final unit = _unit(quantity);
    final states = product['states_tags'] is List
        ? (product['states_tags'] as List).whereType<String>().toList()
        : const <String>[];
    final verified = states.any(
      (state) => state.contains('complete') && !state.contains('not-complete'),
    );
    final fetchedAt = DateTime.now().toUtc();
    final modified = _unixDate(product['last_modified_t']);
    return FoodProduct(
      id: code == null ? 'off:${name.hashCode}' : 'barcode:$code',
      barcode: code,
      name: name,
      brand: _firstText(product, const ['brands'])?.split(',').first.trim(),
      retailerTags: _retailers(_firstText(product, const ['stores'])),
      category: _firstText(product, const ['categories']),
      packageAmount: netAmount,
      packageUnit: unit,
      netWeightGrams: unit == 'g'
          ? netAmount
          : unit == 'kg' && netAmount != null
          ? netAmount * 1000
          : null,
      netVolumeMl: unit == 'ml'
          ? netAmount
          : unit == 'l' && netAmount != null
          ? netAmount * 1000
          : null,
      servingSize: serving,
      servingUnit: serving == null ? null : 'g',
      nutritionBasis: perServing
          ? FoodNutritionBasis.perServing
          : per100ml
          ? FoodNutritionBasis.per100ml
          : FoodNutritionBasis.per100g,
      nutritionBasisAmount: perServing ? serving : 100,
      nutrition: nutrition,
      ingredients: _firstText(product, const [
        'ingredients_text_ru',
        'ingredients_text',
      ]),
      imageUrl: _httpsUrl(product['image_front_url']),
      source: FoodProductSource.openFoodFacts,
      sourceProductId: code,
      sourceUrl: code == null
          ? null
          : 'https://world.openfoodfacts.org/product/$code',
      nutritionVerified: verified,
      imageLicense: 'CC BY-SA 3.0',
      imageAttribution: 'Open Food Facts contributors',
      lastUpdatedAt: modified ?? fetchedAt,
      lastFetchedAt: fetchedAt,
      lastVerifiedAt: verified ? modified ?? fetchedAt : null,
      sourceRevision: product['rev']?.toString(),
      colorSeed: code?.hashCode ?? name.hashCode,
    );
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }

  static String? _firstText(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static Map<String, dynamic> _v3Nutrients(Object? value) {
    if (value is! Map) return const {};
    final nutrition = Map<String, dynamic>.from(value);
    final aggregate = nutrition['aggregated_set'];
    if (aggregate is! Map) return const {};
    final nutrients = Map<String, dynamic>.from(aggregate)['nutrients'];
    return nutrients is Map ? Map<String, dynamic>.from(nutrients) : const {};
  }

  static Object? _v3NutrientField(
    Map<String, dynamic> nutrients,
    String nutrient,
    String field,
  ) {
    final value = nutrients[nutrient];
    return value is Map ? value[field] : null;
  }

  static String? _digits(Object? value) {
    final digits = value?.toString().replaceAll(RegExp(r'\D'), '');
    return digits != null && digits.length >= 8 && digits.length <= 14
        ? digits
        : null;
  }

  static double? _number(Object? value) {
    if (value is num && value.isFinite) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  static double? _bounded(double? value, double min, double max) =>
      value != null && value >= min && value <= max ? value : null;

  static double? _amount(String? value) => value == null
      ? null
      : double.tryParse(
          RegExp(
                r'\d+(?:[.,]\d+)?',
              ).firstMatch(value)?.group(0)?.replaceAll(',', '.') ??
              '',
        );

  static String? _unit(String? value) {
    final lower = value?.toLowerCase() ?? '';
    if (lower.contains('ml') || lower.contains('мл')) return 'ml';
    if (lower.contains('kg') || lower.contains('кг')) return 'kg';
    if (lower.contains('g') || lower.contains('г')) return 'g';
    if (lower.contains('l') || lower.contains('л')) return 'l';
    return null;
  }

  static String? _httpsUrl(Object? value) {
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    return uri?.scheme == 'https' ? value : null;
  }

  static List<String> _retailers(String? stores) {
    if (stores == null) return const [];
    const known = {
      'магнит': 'Магнит',
      'пятерочка': 'Пятёрочка',
      'пятёрочка': 'Пятёрочка',
      'вкусвилл': 'ВкусВилл',
      'перекресток': 'Перекрёсток',
      'перекрёсток': 'Перекрёсток',
      'победа': 'ПОБЕДА',
      'fix price': 'Fix Price',
      'fixprice': 'Fix Price',
    };
    final lower = stores.toLowerCase().replaceAll('ё', 'е');
    return {
      for (final entry in known.entries)
        if (lower.contains(entry.key.replaceAll('ё', 'е'))) entry.value,
    }.toList();
  }

  static DateTime? _unixDate(Object? value) {
    final seconds = value is num ? value.toInt() : int.tryParse('$value');
    return seconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }
}

class _ServerException implements Exception {
  const _ServerException();
}
