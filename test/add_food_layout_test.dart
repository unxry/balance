import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/add_food_screen.dart';

Future<void> _pumpAddFood(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: MaterialApp(
        home: Scaffold(
          body: AddFoodScreen(
            onBack: () {},
            initialMeal: MealType.breakfast,
            selectedDate: DateTime(2026, 9, 5),
            initialRetailerCategoryCounts: const {
              'pyaterochka': {
                'all': 157,
                'preparedFood': 3,
                'hotBakery': 4,
                'bread': 3,
                'dairy': 39,
                'meat': 2,
                'fish': 2,
                'drinks': 52,
              },
              'magnit': {'all': 131},
              'perekrestok': {'all': 51},
              'vkusvill': {'all': 83},
              'fix_price': {'all': 15},
              'pobeda': {'all': 0},
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openRetailerFilter(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('foodFiltersButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('filterSource-retailer')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('food search and portion sheet fit a small iPhone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: AddFoodScreen(
              onBack: () {},
              initialMeal: MealType.breakfast,
              selectedDate: DateTime(2026, 9, 5),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Вес порции'), findsOneWidget);
    expect(find.text('Добавить в дневник'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(375, 667), Size(390, 844), Size(430, 932)]) {
    testWidgets('food category row stays fixed at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: AddFoodScreen(
                onBack: () {},
                initialMeal: MealType.breakfast,
                selectedDate: DateTime(2026, 9, 5),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final category = find.byKey(const ValueKey('foodCategoryRow'));
      expect(category, findsOneWidget);
      expect(
        find.descendant(of: category, matching: find.byType(ListView)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('retailer filters expose the compact deluxe controls only', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: AddFoodScreen(
              onBack: () {},
              initialMeal: MealType.breakfast,
              selectedDate: DateTime(2026, 9, 5),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('foodFiltersButton')));
    await tester.pumpAndSettle();
    expect(find.text('Весь каталог'), findsOneWidget);
    expect(find.text('Бренды'), findsNothing);
    expect(find.text('Полные КБЖУ'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('filterSource-retailer')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('retailer-pyaterochka')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('retailer-pyaterochka')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('retailerCategory-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('retailerSort')), findsNothing);
    expect(find.byKey(const ValueKey('brandPicker')), findsNothing);
    expect(find.byKey(const ValueKey('onlyPhoto')), findsNothing);
    expect(
      tester
          .widget<Semantics>(
            find
                .ancestor(
                  of: find.byKey(const ValueKey('retailer-pyaterochka')),
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .properties
          .selected,
      isTrue,
    );
    expect(find.byKey(const ValueKey('onlyCompleteNutrition')), findsNothing);
    expect(find.byType(DropdownButton), findsNothing);
    await tester.ensureVisible(find.text('Применить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('activeFoodFilterCapsule')),
      findsOneWidget,
    );
    expect(find.textContaining('Полные КБЖУ'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('foodFiltersButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onlyCompleteNutrition')), findsNothing);
    Navigator.of(tester.element(find.text('Фильтры'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clearFoodFilters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('activeFoodFilterCapsule')), findsNothing);
  });

  testWidgets('filter_category_grid_test', (tester) async {
    await _pumpAddFood(tester, const Size(390, 844));
    await _openRetailerFilter(tester);
    await tester.tap(find.byKey(const ValueKey('retailer-pyaterochka')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('filterCategoryGrid')), findsOneWidget);
    final all = tester.getSize(
      find.byKey(const ValueKey('retailerCategory-all')),
    );
    expect(all.height, 70);
    expect(all.width, lessThan(180));
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter_small_iphone_layout_test', (tester) async {
    await _pumpAddFood(tester, const Size(320, 568));
    await _openRetailerFilter(tester);
    await tester.tap(find.byKey(const ValueKey('retailer-pyaterochka')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Применить'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('filterCategoryGrid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('store_zero_state_test', (tester) async {
    await _pumpAddFood(tester, const Size(390, 844));
    await _openRetailerFilter(tester);
    final pobeda = find.byKey(const ValueKey('retailer-pobeda'));
    expect(find.text('Победа'), findsOneWidget);
    final semantics = tester.widget<Semantics>(
      find.ancestor(of: pobeda, matching: find.byType(Semantics)).first,
    );
    expect(semantics.properties.enabled, isFalse);
    expect(find.text('Нет известных товаров'), findsOneWidget);
  });

  testWidgets('category_nested_selector_test', (tester) async {
    await _pumpAddFood(tester, const Size(390, 844));
    await _openRetailerFilter(tester);
    await tester.tap(find.byKey(const ValueKey('retailer-pyaterochka')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('allRetailerCategories')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('categoryPickerGrid')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('retailerCategorySearch')),
      'напит',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('categoryPicker-drinks')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('retailerCategorySearch')),
      'неттакойкатегории',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('categoryPickerEmpty')), findsOneWidget);
  });
}
