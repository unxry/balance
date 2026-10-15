import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../models/recipe_models.dart';
import '../utils/entry_id.dart';

class RecipeRepository {
  RecipeRepository({required Box<dynamic> userBox, DateTime Function()? now})
    : _userBox = userBox,
      _now = now ?? DateTime.now;

  static const recipesKey = 'userRecipes';
  static const usageKey = 'recipeUsage';

  final Box<dynamic> _userBox;
  final DateTime Function() _now;
  final List<UserRecipe> _recipes = [];
  final Map<String, int> _usage = {};

  List<UserRecipe> get recipes {
    final values = [..._recipes]
      ..sort((a, b) {
        final favorite = (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0);
        if (favorite != 0) return favorite;
        final used = usageCount(b.id) - usageCount(a.id);
        return used != 0 ? used : b.updatedAt.compareTo(a.updatedAt);
      });
    return List.unmodifiable(values);
  }

  Future<void> load() async {
    _recipes.clear();
    final saved = _userBox.get(recipesKey);
    if (saved is List) {
      _recipes.addAll(
        saved.map(UserRecipe.tryFromJson).whereType<UserRecipe>(),
      );
    }
    _usage.clear();
    final usage = _userBox.get(usageKey);
    if (usage is Map) {
      for (final entry in usage.entries) {
        if (entry.key is String && entry.value is num) {
          _usage[entry.key as String] = (entry.value as num).toInt();
        }
      }
    }
  }

  UserRecipe? find(String id) {
    for (final recipe in _recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  List<UserRecipe> search(String query, {int limit = 20}) {
    final normalized = query.trim().toLowerCase();
    final candidates =
        _recipes.where((recipe) {
          if (normalized.isEmpty) {
            return recipe.favorite || usageCount(recipe.id) > 0;
          }
          return recipe.normalizedName.contains(normalized) ||
              (recipe.category?.toLowerCase().contains(normalized) ?? false);
        }).toList()..sort(
          (a, b) => _score(b, normalized).compareTo(_score(a, normalized)),
        );
    return candidates.take(limit).toList();
  }

  Future<UserRecipe> create({
    required String name,
    String? category,
    String? note,
    Uint8List? imageBytes,
    required List<RecipeIngredient> ingredients,
    double? cookedWeightGrams,
    int? portions,
  }) async {
    final timestamp = _now().toUtc();
    final recipe = UserRecipe(
      id: 'recipe:${newEntryId()}',
      name: name.trim(),
      category: category?.trim(),
      note: note?.trim(),
      imageBytes: imageBytes,
      versions: [
        RecipeVersion(
          version: 1,
          ingredients: ingredients,
          cookedWeightGrams: cookedWeightGrams,
          portions: portions,
          createdAt: timestamp,
        ),
      ],
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    _recipes.add(recipe);
    await _persist();
    return recipe;
  }

  Future<UserRecipe> addVersion({
    required String recipeId,
    required String name,
    String? category,
    String? note,
    Uint8List? imageBytes,
    required List<RecipeIngredient> ingredients,
    double? cookedWeightGrams,
    int? portions,
  }) async {
    final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index < 0) throw const FormatException('Recipe not found');
    final current = _recipes[index];
    final timestamp = _now().toUtc();
    final nextVersion = RecipeVersion(
      version: current.currentVersion.version + 1,
      ingredients: ingredients,
      cookedWeightGrams: cookedWeightGrams,
      portions: portions,
      createdAt: timestamp,
    );
    final updated = UserRecipe(
      id: current.id,
      name: name.trim(),
      category: category?.trim(),
      note: note?.trim(),
      imageBytes: imageBytes ?? current.imageBytes,
      favorite: current.favorite,
      versions: [...current.versions, nextVersion],
      createdAt: current.createdAt,
      updatedAt: timestamp,
    );
    _recipes[index] = updated;
    await _persist();
    return updated;
  }

  Future<UserRecipe> duplicate(String recipeId, {String? name}) async {
    final source = find(recipeId);
    if (source == null) throw const FormatException('Recipe not found');
    final version = source.currentVersion;
    return create(
      name: name?.trim().isNotEmpty == true
          ? name!.trim()
          : '${source.name} — копия',
      category: source.category,
      note: source.note,
      imageBytes: source.imageBytes,
      ingredients: version.ingredients,
      cookedWeightGrams: version.cookedWeightGrams,
      portions: version.portions,
    );
  }

  RecipeVersion prepareAgain(String recipeId) {
    final recipe = find(recipeId);
    if (recipe == null) throw const FormatException('Recipe not found');
    final version = recipe.currentVersion;
    return RecipeVersion(
      version: version.version + 1,
      ingredients: version.ingredients,
      cookedWeightGrams: version.cookedWeightGrams,
      portions: version.portions,
      createdAt: _now().toUtc(),
    );
  }

  Future<void> delete(String recipeId) async {
    _recipes.removeWhere((recipe) => recipe.id == recipeId);
    _usage.remove(recipeId);
    await _persist();
  }

  Future<void> setFavorite(String recipeId, bool favorite) async {
    final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index < 0) return;
    _recipes[index] = _recipes[index].copyWith(
      favorite: favorite,
      updatedAt: _now().toUtc(),
    );
    await _persist();
  }

  int usageCount(String recipeId) => _usage[recipeId] ?? 0;

  Future<void> markUsed(String recipeId) async {
    _usage[recipeId] = usageCount(recipeId) + 1;
    await _userBox.put(usageKey, Map<String, int>.from(_usage));
    await _userBox.flush();
  }

  Future<void> _persist() async {
    await _userBox.put(
      recipesKey,
      _recipes.map((recipe) => recipe.toJson()).toList(),
    );
    await _userBox.flush();
  }

  int _score(UserRecipe recipe, String query) {
    var score = 10000 + usageCount(recipe.id) * 600;
    if (recipe.favorite) score += 3000;
    if (query.isNotEmpty && recipe.normalizedName == query) score += 5000;
    if (query.isNotEmpty && recipe.normalizedName.startsWith(query)) {
      score += 2500;
    }
    return score;
  }
}
