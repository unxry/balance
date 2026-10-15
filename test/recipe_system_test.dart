import 'dart:io';

import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/models/food_product.dart';
import 'package:flutter_app/models/recipe_models.dart';
import 'package:flutter_app/models/unified_food_item.dart';
import 'package:flutter_app/services/dish_catalog_repository.dart';
import 'package:flutter_app/services/food_catalog_repository.dart';
import 'package:flutter_app/services/local_backup_service.dart';
import 'package:flutter_app/services/local_store.dart';
import 'package:flutter_app/services/recipe_repository.dart';
import 'package:flutter_app/services/unified_food_search_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  late Box<dynamic> user;
  late Box<dynamic> food;
  late Box<dynamic> weight;

  setUpAll(() async {
    sqfliteFfiInit();
    directory = await Directory.systemTemp.createTemp('balance_recipes_');
    Hive.init(directory.path);
    user = await Hive.openBox<dynamic>('recipes_user');
    food = await Hive.openBox<dynamic>('recipes_food');
    weight = await Hive.openBox<dynamic>('recipes_weight');
  });

  setUp(() async {
    await user.clear();
    await food.clear();
    await weight.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test('recipe totals, cooked weight, per100 and portion are correct', () {
    final version = RecipeVersion(
      version: 1,
      ingredients: [
        _ingredient('a', 'Ingredient A', 100, 100, 10, 2, 5),
        _ingredient('b', 'Ingredient B', 200, 400, 20, 8, 40),
      ],
      cookedWeightGrams: 500,
      portions: 2,
    );

    expect(version.totals.calories, 500);
    expect(version.nutritionPer100g.calories, 100);
    expect(version.nutritionForGrams(150).calories, 150);
    expect(version.nutritionForGrams(150).protein, 9);
    expect(version.gramsPerPortion, 250);
    expect(version.nutritionPerPortion!.calories, 250);
  });

  test('cooked weight changes density but never total calories', () {
    final ingredient = _ingredient('a', 'Ingredient', 100, 160, 8, 4, 20);

    RecipeVersion version(double cookedWeight) => RecipeVersion(
      version: 1,
      ingredients: [ingredient],
      cookedWeightGrams: cookedWeight,
    );

    expect(version(100).totals.calories, 160);
    expect(version(100).nutritionPer100g.calories, 160);
    expect(version(100).nutritionPer100g.protein, 8);
    expect(version(100).nutritionPer100g.fat, 4);
    expect(version(100).nutritionPer100g.carbs, 20);
    expect(version(200).totals.calories, 160);
    expect(version(200).nutritionPer100g.calories, 80);
    expect(version(200).nutritionPer100g.protein, 4);
    expect(version(200).nutritionPer100g.fat, 2);
    expect(version(200).nutritionPer100g.carbs, 10);
    expect(version(2).totals.calories, 160);
    expect(version(2).nutritionPer100g.calories, 8000);
    expect(version(2).nutritionPer100g.protein, 400);
    expect(version(2).nutritionPer100g.fat, 200);
    expect(version(2).nutritionPer100g.carbs, 1000);
    expect(version(2).hasSuspiciousCookedWeight, isTrue);
    expect(version(100).hasSuspiciousCookedWeight, isFalse);
  });

  test('water contributes weight but no nutrition', () {
    final water = RecipeIngredient(
      id: 'water',
      nameSnapshot: 'Вода',
      amount: 2500,
      unit: RecipeUnit.ml,
      nutritionSnapshot: const NutritionValues(
        calories: 0,
        protein: 0,
        fat: 0,
        carbs: 0,
      ),
    );
    final version = RecipeVersion(version: 1, ingredients: [water]);
    expect(version.effectiveWeightGrams, 2500);
    expect(version.totals.calories, 0);
  });

  test('non-weight units require a normalized gram equivalent', () {
    expect(
      () => RecipeIngredient(
        id: 'egg',
        nameSnapshot: 'Яйцо',
        amount: 2,
        unit: RecipeUnit.piece,
        nutritionSnapshot: const NutritionValues(
          calories: 140,
          protein: 12,
          fat: 10,
          carbs: 1,
        ),
      ),
      throwsFormatException,
    );
  });

  test('ingredient is an immutable product nutrition snapshot', () {
    final original = _product('ingredient', calories: 100);
    final snapshot = RecipeIngredient.fromProduct(
      id: 'snapshot',
      product: original,
      amount: 150,
    );
    final changedCatalogProduct = _product('ingredient', calories: 240);

    expect(snapshot.nutritionSnapshot.calories, 150);
    expect(changedCatalogProduct.nutritionForAmount(150).calories, 360);
    expect(
      RecipeIngredient.fromJson(snapshot.toJson()).nutritionSnapshot.calories,
      150,
    );
  });

  test('recipe diary metadata survives serialization and portion edits', () {
    final entry = FoodEntry(
      id: 'entry',
      name: 'Мой суп',
      grams: 200,
      kcal: 120,
      proteinG: 8,
      fatG: 4,
      carbsG: 14,
      meal: MealType.lunch,
      time: DateTime(2026, 9, 5, 12),
      sourceType: FoodEntrySourceType.userRecipe,
      recipeId: 'recipe:1',
      recipeVersion: 3,
    );
    final restored = FoodEntry.fromJson(entry.toJson());
    expect(restored.sourceType, FoodEntrySourceType.userRecipe);
    expect(restored.recipeId, 'recipe:1');
    expect(restored.recipeVersion, 3);
    expect(restored.kcal, 120);
  });

  test('versioning and prepare again preserve previous versions', () async {
    var clock = DateTime.utc(2026, 9, 5, 10);
    final repository = RecipeRepository(userBox: user, now: () => clock);
    await repository.load();
    final v1 = await repository.create(
      name: 'Мой борщ',
      ingredients: [_ingredient('beef', 'Говядина', 100, 200, 20, 10, 0)],
      cookedWeightGrams: 400,
    );
    final diarySnapshot = FoodEntry(
      id: 'diary',
      name: v1.name,
      grams: 200,
      kcal: v1.currentVersion.nutritionForGrams(200).calories!.round(),
      proteinG: 10,
      fatG: 5,
      carbsG: 0,
      meal: MealType.lunch,
      time: clock,
      sourceType: FoodEntrySourceType.userRecipe,
      recipeId: v1.id,
      recipeVersion: 1,
    );

    clock = clock.add(const Duration(days: 1));
    final preparedDraft = repository.prepareAgain(v1.id);
    expect(preparedDraft.version, 2);
    final v2 = await repository.addVersion(
      recipeId: v1.id,
      name: v1.name,
      ingredients: [_ingredient('beef2', 'Говядина', 100, 120, 15, 5, 0)],
      cookedWeightGrams: 400,
    );

    expect(v2.versions, hasLength(2));
    expect(v2.versions.first.totals.calories, 200);
    expect(v2.currentVersion.totals.calories, 120);
    expect(diarySnapshot.kcal, 100);
    expect(diarySnapshot.recipeVersion, 1);

    await repository.delete(v1.id);
    expect(repository.recipes, isEmpty);
    expect(diarySnapshot.kcal, 100);
  });

  test('duplicate creates an independent recipe at version one', () async {
    final repository = RecipeRepository(userBox: user);
    await repository.load();
    final source = await repository.create(
      name: 'Плов',
      ingredients: [_ingredient('rice', 'Рис', 200, 260, 5, 1, 56)],
    );
    final copy = await repository.duplicate(source.id, name: 'Плов с курицей');
    expect(copy.id, isNot(source.id));
    expect(copy.currentVersion.version, 1);
    expect(copy.currentVersion.ingredients.first.nameSnapshot, 'Рис');
  });

  test('migration and backup restore recipes non-destructively', () async {
    final existingRecipe = UserRecipe(
      id: 'recipe:existing',
      name: 'Сохранённый суп',
      versions: [
        RecipeVersion(
          version: 2,
          ingredients: [_ingredient('water', 'Вода', 500, 0, 0, 0, 0)],
        ),
      ],
    );
    await user.putAll({
      LocalStore.schemaVersionKey: 3,
      'profile': {'name': 'Saved'},
      'waterHistory': {'2026-09-05': 1.8},
      RecipeRepository.recipesKey: [existingRecipe.toJson()],
    });
    await LocalStore.migrateBoxes(user: user, food: food, weight: weight);
    final repository = RecipeRepository(userBox: user);
    await repository.load();
    expect(repository.find(existingRecipe.id)!.currentVersion.version, 2);
    final recipe = await repository.create(
      name: 'Запеканка',
      ingredients: [_ingredient('cottage', 'Творог', 500, 600, 80, 25, 15)],
      cookedWeightGrams: 600,
    );
    final backup = const LocalBackupService().exportJson(
      user: user,
      food: food,
      weight: weight,
    );
    expect(user.get(LocalStore.schemaVersionKey), 5);
    expect(user.get('waterHistory'), {'2026-09-05': 1.8});
    expect(backup, contains('userRecipes'));
    expect(backup, contains('nutritionSnapshot'));

    await user.clear();
    await const LocalBackupService().restoreJson(
      backup,
      user: user,
      food: food,
      weight: weight,
    );
    final restored = RecipeRepository(userBox: user);
    await restored.load();
    expect(restored.find(recipe.id)!.currentVersion.ingredients, hasLength(1));
    expect(restored.find(recipe.id)!.currentVersion.version, 1);
    expect(
      restored.find(existingRecipe.id)!.currentVersion.ingredients,
      hasLength(1),
    );
  });

  test('indexed dish catalog and unified ranking keep entity types', () async {
    final seedText = File('assets/catalog/dishes_v1.tsv').readAsStringSync();
    final fullSeed = DishCatalogRepository.parseDishSeed(seedText);
    expect(fullSeed.length, greaterThanOrEqualTo(100));
    expect(
      fullSeed.map((dish) => dish.cuisine).toSet().length,
      greaterThan(10),
    );
    expect(fullSeed.every((dish) => dish.isEstimated), isTrue);

    final dishDatabase = '${directory.path}/dish-search.db';
    final dishes = await DishCatalogRepository.open(
      factory: databaseFactoryFfi,
      databasePath: dishDatabase,
      seed: fullSeed,
    );
    final recipeRepository = RecipeRepository(userBox: user);
    await recipeRepository.load();
    final recipe = await recipeRepository.create(
      name: 'Мой борщ',
      ingredients: [_ingredient('veg', 'Овощи', 500, 180, 7, 4, 30)],
      cookedWeightGrams: 800,
    );
    await recipeRepository.markUsed(recipe.id);
    final barcodeProduct = FoodProduct(
      id: 'barcode:4601234567893',
      barcode: '4601234567893',
      name: 'Борщ готовый',
      nutrition: const NutritionValues(
        calories: 70,
        protein: 4,
        fat: 3,
        carbs: 7,
      ),
      source: FoodProductSource.officialRetailer,
    );
    final products = FoodCatalogRepository(
      cache: MemoryProductCache(),
      localProducts: [barcodeProduct],
    );
    final search = UnifiedFoodSearchService(
      products: products,
      dishes: dishes,
      recipes: () => recipeRepository.recipes,
      recipeUsageCount: recipeRepository.usageCount,
    );
    final result = await search.search('борщ', online: false);
    expect(result.items.first.type, UnifiedFoodType.userRecipe);
    expect(
      result.items.any((item) => item.type == UnifiedFoodType.genericDish),
      isTrue,
    );
    await dishes.importCatalog([
      fullSeed.first.copyWith(favorite: true),
    ], version: 'remote-test-1');
    expect(await dishes.count(), fullSeed.length);
    final barcode = await search.findByBarcode('4601234567893');
    expect(barcode!.type, UnifiedFoodType.product);
    expect(barcode.dish, isNull);
    await dishes.close();
  });
}

RecipeIngredient _ingredient(
  String id,
  String name,
  double weight,
  double calories,
  double protein,
  double fat,
  double carbs,
) => RecipeIngredient(
  id: id,
  nameSnapshot: name,
  amount: weight,
  unit: RecipeUnit.g,
  nutritionSnapshot: NutritionValues(
    calories: calories,
    protein: protein,
    fat: fat,
    carbs: carbs,
  ),
);

FoodProduct _product(String id, {required double calories}) => FoodProduct(
  id: id,
  name: 'Product',
  nutrition: NutritionValues(calories: calories, protein: 10, fat: 5, carbs: 8),
  source: FoodProductSource.officialManufacturer,
  sourceRevision: 'v1',
);
