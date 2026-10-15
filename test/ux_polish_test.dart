import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/food_product.dart';
import 'package:flutter_app/models/unified_food_item.dart';
import 'package:flutter_app/widgets/keyboard_dismiss_region.dart';

void main() {
  testWidgets('keyboard dismisses without clearing and can focus again', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardDismissRegion(
          child: Scaffold(
            body: ListView(
              children: [
                TextField(
                  key: const ValueKey('queryField'),
                  controller: controller,
                  focusNode: focus,
                ),
                const SizedBox(height: 900),
                const Text('Outside'),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('queryField')));
    await tester.enterText(find.byKey(const ValueKey('queryField')), 'творог');
    expect(focus.hasFocus, isTrue);
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    expect(controller.text, 'творог');

    await tester.drag(find.byType(ListView), const Offset(0, 180));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('queryField')));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    await tester.tapAt(const Offset(350, 400));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    expect(controller.text, 'творог');
  });

  test(
    'search usability keeps per-100g products with unknown package mass',
    () {
      final usable = UnifiedFoodItem.fromProduct(
        FoodProduct(
          id: 'usable',
          name: 'Творог',
          source: FoodProductSource.openFoodFacts,
          nutritionBasis: FoodNutritionBasis.per100g,
          nutrition: const NutritionValues(
            calories: 121,
            protein: 17,
            fat: 5,
            carbs: 2,
          ),
        ),
      );
      final unusable = UnifiedFoodItem.fromProduct(
        FoodProduct(
          id: 'unusable',
          name: 'Продукт без КБЖУ',
          source: FoodProductSource.openFoodFacts,
        ),
      );

      expect(usable.product!.netWeightGrams, isNull);
      expect(usable.suggestedAmount, 100);
      expect(usable.isUsableForDiary, isTrue);
      expect(unusable.isUsableForDiary, isFalse);
    },
  );
}
