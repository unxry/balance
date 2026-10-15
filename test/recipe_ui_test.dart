import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/food_product.dart';
import 'package:flutter_app/models/recipe_models.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/my_recipes_screen.dart';
import 'package:flutter_app/services/food_catalog_repository.dart';
import 'package:flutter_app/services/health_service.dart';
import 'package:flutter_app/theme/i18n.dart';
import 'package:flutter_app/widgets/premium_motion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class _NoHealth extends HealthService {
  @override
  Future<StepAccessState> getStatus() async => StepAccessState.unavailable;
}

void main() {
  late Directory directory;
  late Box<dynamic> user;
  late Box<dynamic> food;
  late Box<dynamic> weight;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('recipe_ui_');
    Hive.init(directory.path);
    user = await Hive.openBox<dynamic>('recipe_ui_user');
    food = await Hive.openBox<dynamic>('recipe_ui_food');
    weight = await Hive.openBox<dynamic>('recipe_ui_weight');
  });

  setUp(() async {
    await user.clear();
    await food.clear();
    await weight.clear();
  });

  tearDownAll(() {
    // The provider deliberately persists a few derived fields without
    // awaiting them. The isolated widget-test process owns these boxes, so
    // synchronous cleanup avoids waiting on those non-critical writes.
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  testWidgets('my recipes list and four-step editor fit compact iPhone', (
    tester,
  ) async {
    final data = AppDataProvider(
      userBox: user,
      foodBox: food,
      weightBox: weight,
      healthService: _NoHealth(),
    );
    await tester.runAsync(() async {
      await data.load();
      await data.createRecipe(
        name: 'Мой борщ',
        ingredients: [
          RecipeIngredient(
            id: 'vegetables',
            nameSnapshot: 'Овощи',
            amount: 500,
            unit: RecipeUnit.g,
            nutritionSnapshot: const NutritionValues(
              calories: 180,
              protein: 7,
              fat: 4,
              carbs: 30,
            ),
          ),
        ],
        cookedWeightGrams: 800,
        portions: 4,
      );
    });
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: data),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(
          home: MyRecipesScreen(
            catalog: FoodCatalogRepository(cache: MemoryProductCache()),
            scannerStrings: const S(AppLang.ru),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Мой борщ'), findsOneWidget);
    expect(find.textContaining('ккал / 100 г'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final recipeActions = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('recipeActions-'),
    );
    await tester.tap(recipeActions);
    await tester.pumpAndSettle();
    expect(find.text('МОЙ РЕЦЕПТ'), findsOneWidget);
    expect(find.text('Приготовить снова'), findsOneWidget);
    expect(find.text('Редактировать'), findsOneWidget);
    expect(find.text('Создать копию'), findsOneWidget);
    expect(find.text('Удалить'), findsOneWidget);
    Navigator.of(tester.element(find.text('МОЙ РЕЦЕПТ'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('createRecipeButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ШАГ 1 / 4'), findsOneWidget);
    expect(find.text('Название блюда'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField).first, 'Тестовый рецепт');
    await tester.tap(find.byKey(const ValueKey('recipeNextButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('addRecipeIngredientButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Вручную'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('manualIngredientAmountRow')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('manualIngredientUnitPicker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recipeUnitGrid')), findsOneWidget);
    for (final unit in RecipeUnit.values) {
      expect(find.byKey(ValueKey('recipeUnit-${unit.name}')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('recipeUnit-g')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('manualIngredientName')),
      'Картофель',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manualIngredientAmount')),
      '200',
    );
    for (final field in const {3: '77', 4: '2', 5: '0.4', 6: '17'}.entries) {
      await tester.enterText(
        find.byKey(ValueKey('manualIngredientField-${field.key}')),
        field.value,
      );
    }
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('saveManualIngredient')),
    );
    await tester.tap(find.byKey(const ValueKey('saveManualIngredient')));
    await tester.pumpAndSettle();
    expect(find.text('Картофель'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recipeNextButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recipeLivePreview')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('recipeCookedWeight')),
      '250',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('recipeCookedWeight')))
          .controller
          ?.text,
      '250',
    );
    expect(find.byType(BalanceAnimatedNumber), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('recipeCookedWeight')),
      '2',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('recipeSuspiciousWeightWarning')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipeCookedWeight')),
      '250',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('recipeSuspiciousWeightWarning')),
      findsNothing,
    );
    await tester.enterText(find.byKey(const ValueKey('recipePortions')), '2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recipeNextButton')));
    await tester.pumpAndSettle();
    expect(find.text('ИТОГ РЕЦЕПТА'), findsOneWidget);
    expect(find.textContaining('ккал / 100 г'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recipeNextButton')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Тестовый рецепт'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    data.dispose();
  });
}
