import 'package:flutter/foundation.dart';

import '../models/food_product.dart';
import '../utils/gtin.dart';
import 'food_catalog_repository.dart';
import 'food_search_service.dart';

enum PackageScannerPhase {
  scanning,
  searching,
  found,
  invalidCode,
  notFound,
  offlineNotFound,
  permissionDenied,
  restricted,
  error,
}

class PackageScannerCoordinator extends ChangeNotifier {
  PackageScannerCoordinator(this.repository, {this.retailerSlug});

  final FoodCatalogRepository repository;
  final String? retailerSlug;
  PackageScannerPhase phase = PackageScannerPhase.scanning;
  FoodProduct? product;
  String? barcode;
  bool _scanLocked = false;
  int _generation = 0;

  bool get scanLocked => _scanLocked;

  Future<bool> handleBarcode(
    Object? raw, {
    VoidCallback? onAccepted,
    VoidCallback? onRejected,
  }) async {
    if (_scanLocked) return false;
    final normalized = normalizeGtin(raw);
    if (normalized == null) {
      _scanLocked = true;
      phase = PackageScannerPhase.invalidCode;
      notifyListeners();
      onRejected?.call();
      return false;
    }
    _scanLocked = true;
    barcode = normalized;
    phase = PackageScannerPhase.searching;
    notifyListeners();
    onAccepted?.call();
    return _lookup(normalized, ++_generation);
  }

  Future<bool> retryLookup() async {
    final value = barcode;
    if (value == null) return false;
    _scanLocked = true;
    product = null;
    phase = PackageScannerPhase.searching;
    notifyListeners();
    return _lookup(value, ++_generation);
  }

  Future<bool> _lookup(String normalized, int generation) async {
    try {
      final found = await repository.findByBarcode(normalized);
      if (generation != _generation) return false;
      if (found != null && retailerSlug != null) {
        await repository.rememberRetailer(found, retailerSlug!);
      }
      product = found;
      phase = product != null
          ? PackageScannerPhase.found
          : repository.lastBarcodeLookupError == FoodSearchError.offline ||
                repository.lastBarcodeLookupError == FoodSearchError.timeout
          ? PackageScannerPhase.offlineNotFound
          : PackageScannerPhase.notFound;
    } catch (_) {
      if (generation != _generation) return false;
      phase = PackageScannerPhase.notFound;
    }
    notifyListeners();
    return true;
  }

  void permissionDenied({bool restricted = false}) {
    _scanLocked = true;
    phase = restricted
        ? PackageScannerPhase.restricted
        : PackageScannerPhase.permissionDenied;
    notifyListeners();
  }

  void cameraError() {
    _scanLocked = true;
    phase = PackageScannerPhase.error;
    notifyListeners();
  }

  void resume() {
    _generation++;
    _scanLocked = false;
    barcode = null;
    product = null;
    phase = PackageScannerPhase.scanning;
    notifyListeners();
  }
}
