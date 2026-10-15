import 'dart:async';

import 'package:flutter_app/models/food_product.dart';
import 'package:flutter_app/models/product_retailer_relation.dart';
import 'package:flutter_app/services/food_catalog_repository.dart';
import 'package:flutter_app/services/food_search_service.dart';
import 'package:flutter_app/services/package_scanner_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

class _BarcodeSource implements FoodProductSourceAdapter {
  _BarcodeSource({this.product, this.error, this.gate});

  FoodProduct? product;
  FoodSearchError? error;
  final Completer<void>? gate;
  int calls = 0;

  @override
  FoodSearchError? get lastBarcodeError => error;

  @override
  Future<FoodProduct?> findByBarcode(String barcode) async {
    calls++;
    await gate?.future;
    return product;
  }

  @override
  Future<FoodSearchOutcome> search(String query, {int limit = 20}) async =>
      const FoodSearchOutcome([]);
}

FoodProduct _product() => FoodProduct(
  id: 'barcode:4006381333931',
  barcode: '4006381333931',
  name: 'Test product',
  nutrition: const NutritionValues(calories: 100),
  source: FoodProductSource.openFoodFacts,
);

FoodCatalogRepository _repository(_BarcodeSource source) =>
    FoodCatalogRepository(
      cache: MemoryProductCache(),
      sources: [source],
      localProducts: const [],
    );

class _LearningCache extends MemoryProductCache
    implements RetailerAwareProductCache {
  final relations = <ProductRetailerRelation>[];

  @override
  Future<void> saveRetailerRelation(ProductRetailerRelation relation) async {
    relations.add(relation);
  }

  @override
  Future<List<FoodProduct>> searchRetailerCandidates(
    String normalizedQuery, {
    required String retailerSlug,
    required String taxonomyCategory,
    required int limit,
    required int offset,
    String? brand,
    bool onlyCompleteNutrition = false,
    bool onlyPhoto = false,
  }) async => const [];
}

void main() {
  test(
    'valid scan locks immediately, shows loading and ignores duplicates',
    () async {
      final gate = Completer<void>();
      final source = _BarcodeSource(product: _product(), gate: gate);
      final coordinator = PackageScannerCoordinator(_repository(source));

      final first = coordinator.handleBarcode('4006381333931');
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.scanLocked, isTrue);
      expect(coordinator.phase, PackageScannerPhase.searching);
      expect(await coordinator.handleBarcode('4006381333931'), isFalse);
      expect(source.calls, 1);

      gate.complete();
      expect(await first, isTrue);
      expect(coordinator.phase, PackageScannerPhase.found);
      expect(coordinator.product?.barcode, '4006381333931');
    },
  );

  test(
    'invalid scan never reaches catalog and leading zero remains a String',
    () async {
      final source = _BarcodeSource(product: _product());
      final coordinator = PackageScannerCoordinator(_repository(source));
      var rejected = false;
      expect(
        await coordinator.handleBarcode(
          '4006381333932',
          onRejected: () => rejected = true,
        ),
        isFalse,
      );
      expect(rejected, isTrue);
      expect(coordinator.phase, PackageScannerPhase.invalidCode);
      expect(coordinator.scanLocked, isTrue);
      expect(source.calls, 0);

      coordinator.resume();
      expect(coordinator.phase, PackageScannerPhase.scanning);
      expect(coordinator.scanLocked, isFalse);

      final leadingZero = _BarcodeSource();
      final second = PackageScannerCoordinator(_repository(leadingZero));
      await second.handleBarcode('0036000291452');
      expect(second.barcode, '0036000291452');
    },
  );

  test('retry cancels stale lookup and resumes detector state', () async {
    final gate = Completer<void>();
    final source = _BarcodeSource(product: _product(), gate: gate);
    final coordinator = PackageScannerCoordinator(_repository(source));

    final pending = coordinator.handleBarcode('4006381333931');
    await Future<void>.delayed(Duration.zero);
    coordinator.resume();
    gate.complete();

    expect(await pending, isFalse);
    expect(coordinator.phase, PackageScannerPhase.scanning);
    expect(coordinator.scanLocked, isFalse);
    expect(coordinator.barcode, isNull);
    expect(coordinator.product, isNull);
  });

  test('not found and offline are calm explicit states', () async {
    final missing = PackageScannerCoordinator(_repository(_BarcodeSource()));
    await missing.handleBarcode('4006381333931');
    expect(missing.phase, PackageScannerPhase.notFound);

    final offline = PackageScannerCoordinator(
      _repository(_BarcodeSource(error: FoodSearchError.offline)),
    );
    await offline.handleBarcode('4006381333931');
    expect(offline.phase, PackageScannerPhase.offlineNotFound);

    _sourceRetry(offline.repository).error = null;
    await offline.retryLookup();
    expect(offline.phase, PackageScannerPhase.notFound);
  });

  test('failed scan can reset and succeed on the second scan', () async {
    final source = _BarcodeSource();
    final coordinator = PackageScannerCoordinator(_repository(source));

    expect(await coordinator.handleBarcode('4006381333931'), isTrue);
    expect(coordinator.phase, PackageScannerPhase.notFound);
    expect(coordinator.scanLocked, isTrue);

    coordinator.resume();
    expect(coordinator.barcode, isNull);
    expect(coordinator.product, isNull);
    expect(coordinator.scanLocked, isFalse);
    expect(coordinator.phase, PackageScannerPhase.scanning);

    source.product = _product();
    expect(await coordinator.handleBarcode('4006381333931'), isTrue);
    expect(coordinator.phase, PackageScannerPhase.found);
    expect(coordinator.product?.id, 'barcode:4006381333931');
    expect(source.calls, 2);
  });

  test('camera denied and restricted states can be represented and reset', () {
    final coordinator = PackageScannerCoordinator(
      _repository(_BarcodeSource()),
    );
    coordinator.permissionDenied();
    expect(coordinator.phase, PackageScannerPhase.permissionDenied);
    coordinator.resume();
    expect(coordinator.phase, PackageScannerPhase.scanning);
    coordinator.permissionDenied(restricted: true);
    expect(coordinator.phase, PackageScannerPhase.restricted);
  });

  test('scanner opened from a store learns the retailer locally', () async {
    final source = _BarcodeSource(product: _product());
    final cache = _LearningCache();
    final repository = FoodCatalogRepository(
      cache: cache,
      sources: [source],
      localProducts: const [],
    );
    final coordinator = PackageScannerCoordinator(
      repository,
      retailerSlug: 'pyaterochka',
    );

    expect(await coordinator.handleBarcode('4006381333931'), isTrue);
    expect(cache.relations, hasLength(1));
    expect(cache.relations.single.productId, _product().id);
    expect(cache.relations.single.retailerSlug, 'pyaterochka');
    expect(cache.relations.single.source, RetailerRelationSource.userScan);
    expect(cache.relations.single.confidence, .95);
  });
}

_BarcodeSource _sourceRetry(FoodCatalogRepository repository) =>
    repository.sources.single as _BarcodeSource;
