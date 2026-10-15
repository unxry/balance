import 'package:flutter_app/models/food_product.dart';
import 'package:flutter_app/services/food_catalog_repository.dart';
import 'package:flutter_app/services/package_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts brand, name, variant, fat and package amount from OCR', () {
    final features = PackagingTextFeatures.parse('''
Простоквашино
Творог клубника
5%
Масса нетто 180 г
''');
    expect(features.brand, 'простоквашино');
    expect(features.productName, 'творог клубника');
    expect(features.variant, 'клубника');
    expect(features.fatPercent, 5);
    expect(features.weightGrams, 180);
  });

  test(
    'ranks matching package but never selects a candidate automatically',
    () async {
      final cache = MemoryProductCache();
      final best = FoodProduct(
        id: 'best',
        name: 'Творог клубника 5%',
        brand: 'Простоквашино',
        netWeightGrams: 180,
        nutrition: const NutritionValues(calories: 121),
        source: FoodProductSource.officialManufacturer,
        nutritionVerified: true,
        dataQuality: FoodDataQuality.verified,
      );
      final other = FoodProduct(
        id: 'other',
        name: 'Творог классический 9%',
        brand: 'Простоквашино',
        netWeightGrams: 220,
        nutrition: const NutritionValues(calories: 170),
        source: FoodProductSource.openFoodFacts,
      );
      await cache.write(best);
      await cache.write(other);
      await cache.markUsed(best.id);
      final repository = FoodCatalogRepository(
        cache: cache,
        localProducts: const [],
      );
      final features = PackagingTextFeatures.parse(
        'Простоквашино\nТворог клубника\n5%\n180 г',
      );

      final candidates = await PackageRecognitionService().findCandidates(
        features,
        repository,
      );
      expect(candidates, isNotEmpty);
      expect(candidates.first.product.id, 'best');
      expect(candidates.first.confidence, CandidateConfidence.high);
      expect(
        candidates.first.evidence,
        containsAll(['brand', 'package', 'variant', 'previouslyUsed']),
      );
      // Selection is intentionally a separate UI action; the service returns a list.
      expect(candidates.length, lessThanOrEqualTo(5));
    },
  );
}
