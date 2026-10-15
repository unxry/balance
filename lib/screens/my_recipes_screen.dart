import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/food_product.dart';
import '../models/recipe_models.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/food_catalog_repository.dart';
import '../services/image_sanitizer.dart';
import '../theme/app_text_styles.dart';
import '../theme/i18n.dart';
import '../utils/entry_id.dart';
import '../widgets/common.dart';
import '../widgets/premium_motion.dart';
import 'package_scanner_screen.dart';

class MyRecipesScreen extends StatelessWidget {
  const MyRecipesScreen({
    super.key,
    required this.catalog,
    required this.scannerStrings,
  });

  final FoodCatalogRepository catalog;
  final S scannerStrings;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final s = S(context.watch<SettingsProvider>().lang);
    final c = context.colors;
    final t = AppText(c);
    final recipes = data.userRecipes;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GhostBackButton(onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  TextButton.icon(
                    key: const ValueKey('createRecipeButton'),
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(s.isRu ? 'Создать' : 'Create'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                s.isRu ? 'Мои рецепты' : 'My recipes',
                style: t.fraunces(size: 28, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                s.isRu
                    ? 'Точный расчёт по вашим ингредиентам'
                    : 'Calculated from your ingredient snapshots',
                style: t.inter(size: 12, color: c.muted),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: recipes.isEmpty
                    ? Center(
                        child: Text(
                          s.isRu
                              ? 'Здесь появятся ваши блюда'
                              : 'Your dishes will appear here',
                          style: t.inter(size: 13, color: c.muted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: recipes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) =>
                            _recipeCard(context, recipes[index], data, s, c, t),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recipeCard(
    BuildContext context,
    UserRecipe recipe,
    AppDataProvider data,
    S s,
    dynamic c,
    AppText t,
  ) {
    final nutrition = recipe.currentVersion.nutritionPer100g;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _recipeImage(recipe, c),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '★ ${recipe.name}',
                      style: t.inter(size: 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${nutrition.calories!.round()} ${s.isRu ? 'ккал / 100 г' : 'kcal / 100 g'}',
                      style: t.mono(size: 10, color: c.accent),
                    ),
                    Text(
                      '${s.isRu ? 'Б' : 'P'} ${nutrition.protein!.toStringAsFixed(1)}  '
                      '${s.isRu ? 'Ж' : 'F'} ${nutrition.fat!.toStringAsFixed(1)}  '
                      '${s.isRu ? 'У' : 'C'} ${nutrition.carbs!.toStringAsFixed(1)}',
                      style: t.mono(size: 9, color: c.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: s.isRu ? 'Избранное' : 'Favorite',
                onPressed: () =>
                    data.setRecipeFavorite(recipe.id, !recipe.favorite),
                icon: Icon(
                  recipe.favorite ? Icons.star_rounded : Icons.star_border,
                  color: recipe.favorite ? c.accent3 : c.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _smallAction(
                t,
                s.isRu ? 'Добавить' : 'Add',
                () => Navigator.of(context).pop(recipe),
              ),
              _smallAction(
                t,
                s.isRu ? 'Изменить' : 'Edit',
                () => _openEditor(context, recipe: recipe),
              ),
              IconButton(
                key: ValueKey('recipeActions-${recipe.id}'),
                tooltip: s.isRu ? 'Действия' : 'Actions',
                onPressed: () => _showRecipeActions(context, data, recipe, s),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recipeImage(UserRecipe recipe, dynamic c) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: c.accentSoft,
      borderRadius: BorderRadius.circular(14),
      image: recipe.imageBytes == null
          ? null
          : DecorationImage(
              image: MemoryImage(recipe.imageBytes!),
              fit: BoxFit.cover,
            ),
    ),
    child: recipe.imageBytes == null
        ? Icon(Icons.soup_kitchen_outlined, color: c.accent)
        : null,
  );

  Widget _smallAction(AppText t, String text, VoidCallback onTap) => Expanded(
    child: TextButton(
      onPressed: onTap,
      child: Text(text, style: t.inter(size: 11, weight: FontWeight.w700)),
    ),
  );

  Future<void> _showRecipeActions(
    BuildContext context,
    AppDataProvider data,
    UserRecipe recipe,
    S s,
  ) async {
    final c = context.colors;
    final t = AppText(c);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              MonoLabel(s.isRu ? 'МОЙ РЕЦЕПТ' : 'MY RECIPE'),
              const SizedBox(height: 8),
              _recipeSheetAction(
                ctx,
                t,
                'prepare',
                Icons.refresh_rounded,
                s.isRu ? 'Приготовить снова' : 'Prepare again',
              ),
              _recipeSheetAction(
                ctx,
                t,
                'edit',
                Icons.edit_outlined,
                s.isRu ? 'Редактировать' : 'Edit',
              ),
              _recipeSheetAction(
                ctx,
                t,
                'copy',
                Icons.copy_outlined,
                s.isRu ? 'Создать копию' : 'Duplicate',
              ),
              Divider(color: c.line),
              _recipeSheetAction(
                ctx,
                t,
                'delete',
                Icons.delete_outline_rounded,
                s.isRu ? 'Удалить' : 'Delete',
                color: c.accent2,
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == 'edit') {
      await _openEditor(context, recipe: recipe);
    } else {
      await _recipeAction(context, data, recipe, action, s);
    }
  }

  Widget _recipeSheetAction(
    BuildContext context,
    AppText t,
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) => InkWell(
    key: ValueKey('recipeAction-$value'),
    onTap: () => Navigator.pop(context, value),
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: 52,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 13),
          Text(
            label,
            style: t.inter(size: 13, weight: FontWeight.w600, color: color),
          ),
        ],
      ),
    ),
  );

  Future<void> _recipeAction(
    BuildContext context,
    AppDataProvider data,
    UserRecipe recipe,
    String action,
    S s,
  ) async {
    if (action == 'prepare') {
      await _openEditor(context, recipe: recipe, prepareAgain: true);
      return;
    }
    if (action == 'copy') {
      await _openEditor(context, recipe: recipe, saveAsCopy: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.isRu ? 'Удалить рецепт?' : 'Delete recipe?'),
        content: Text(
          s.isRu
              ? 'Старые записи дневника останутся без изменений.'
              : 'Existing diary snapshots will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.isRu ? 'Отмена' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.isRu ? 'Удалить' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await data.deleteRecipe(recipe.id);
  }

  Future<void> _openEditor(
    BuildContext context, {
    UserRecipe? recipe,
    bool prepareAgain = false,
    bool saveAsCopy = false,
  }) async {
    await Navigator.of(context).push<UserRecipe>(
      MaterialPageRoute(
        builder: (_) => RecipeEditorScreen(
          catalog: catalog,
          scannerStrings: scannerStrings,
          recipe: recipe,
          prepareAgain: prepareAgain,
          saveAsCopy: saveAsCopy,
        ),
      ),
    );
  }
}

class RecipeEditorScreen extends StatefulWidget {
  const RecipeEditorScreen({
    super.key,
    required this.catalog,
    required this.scannerStrings,
    this.recipe,
    this.prepareAgain = false,
    this.saveAsCopy = false,
  });

  final FoodCatalogRepository catalog;
  final S scannerStrings;
  final UserRecipe? recipe;
  final bool prepareAgain;
  final bool saveAsCopy;

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _note = TextEditingController();
  final _cookedWeight = TextEditingController();
  final _portions = TextEditingController();
  final List<RecipeIngredient> _ingredients = [];
  int _step = 0;
  Uint8List? _imageBytes;
  String? _error;
  double? _lastValidCooked;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    if (recipe != null) {
      _name.text = widget.saveAsCopy ? '${recipe.name} — копия' : recipe.name;
      _category.text = recipe.category ?? '';
      _note.text = recipe.note ?? '';
      _imageBytes = recipe.imageBytes;
      final version = recipe.currentVersion;
      _ingredients.addAll(version.ingredients);
      _cookedWeight.text = version.cookedWeightGrams?.round().toString() ?? '';
      _lastValidCooked = version.cookedWeightGrams;
      _portions.text = version.portions?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _note.dispose();
    _cookedWeight.dispose();
    _portions.dispose();
    super.dispose();
  }

  double? get _cooked {
    final input = _cookedWeight.text.trim();
    if (input.isEmpty) return null;
    final parsed = double.tryParse(input.replaceAll(',', '.'));
    return parsed != null && parsed > 0 ? parsed : _lastValidCooked;
  }

  int? get _portionCount => int.tryParse(_portions.text.trim());
  RecipeTotals get _totals => RecipeTotals.fromIngredients(_ingredients);

  RecipeVersion? get _preview {
    try {
      return RecipeVersion(
        version: widget.recipe?.currentVersion.version ?? 1,
        ingredients: _ingredients,
        cookedWeightGrams: _cooked,
        portions: _portionCount,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<SettingsProvider>().lang);
    final c = context.colors;
    final t = AppText(c);
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GhostBackButton(onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  MonoLabel('${s.isRu ? 'ШАГ' : 'STEP'} ${_step + 1} / 4'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _title(s),
                style: t.fraunces(size: 26, weight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: IndexedStack(
                  index: _step,
                  children: [
                    _infoStep(c, t, s),
                    _ingredientsStep(c, t, s),
                    _weightStep(c, t, s),
                    _resultStep(c, t, s),
                  ],
                ),
              ),
              if (_error != null) ...[
                Text(_error!, style: t.inter(size: 11, color: c.accent2)),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _error = null;
                          _step--;
                        }),
                        child: Text(s.isRu ? 'Назад' : 'Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      key: const ValueKey('recipeNextButton'),
                      label: _step == 3
                          ? (s.isRu ? 'Сохранить рецепт' : 'Save recipe')
                          : (s.isRu ? 'Продолжить' : 'Continue'),
                      icon: _step == 3
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      onTap: () => _next(s),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(S s) => switch (_step) {
    0 => s.isRu ? 'Название блюда' : 'Recipe details',
    1 => s.isRu ? 'Ингредиенты' : 'Ingredients',
    2 => s.isRu ? 'Вес готового блюда' : 'Cooked weight',
    _ =>
      _name.text.trim().isEmpty
          ? (s.isRu ? 'Результат' : 'Result')
          : _name.text.trim(),
  };

  Widget _infoStep(dynamic c, AppText t, S s) => ListView(
    children: [
      _field(_name, s.isRu ? 'Название' : 'Name'),
      const SizedBox(height: 10),
      _field(
        _category,
        s.isRu ? 'Категория (необязательно)' : 'Category (optional)',
      ),
      const SizedBox(height: 10),
      _field(
        _note,
        s.isRu ? 'Заметка (необязательно)' : 'Note (optional)',
        lines: 3,
      ),
      const SizedBox(height: 14),
      InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 88,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              if (_imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _imageBytes!,
                    width: 62,
                    height: 62,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Icon(Icons.add_a_photo_outlined, color: c.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.isRu ? 'Фото блюда (по желанию)' : 'Dish photo (optional)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.inter(size: 12, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _ingredientsStep(dynamic c, AppText t, S s) => Column(
    children: [
      Expanded(
        child: _ingredients.isEmpty
            ? Center(
                child: Text(
                  s.isRu
                      ? 'Добавьте хотя бы один ингредиент'
                      : 'Add at least one ingredient',
                  style: t.inter(size: 12, color: c.muted),
                ),
              )
            : ListView.separated(
                itemCount: _ingredients.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final item = _ingredients[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _editIngredientAmount(index, s),
                    title: Text(
                      item.nameSnapshot,
                      style: t.inter(size: 13, weight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${_unit(item.unit, s)}',
                      style: t.mono(size: 9),
                    ),
                    trailing: IconButton(
                      onPressed: () =>
                          setState(() => _ingredients.removeAt(index)),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  );
                },
              ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const ValueKey('addRecipeIngredientButton'),
        onPressed: () => _showIngredientPicker(s),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.isRu ? 'Добавить ингредиент' : 'Add ingredient'),
      ),
    ],
  );

  Widget _weightStep(dynamic c, AppText t, S s) => ListView(
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.isRu
                  ? 'Вес ингредиентов до приготовления'
                  : 'Ingredient weight before cooking',
              style: t.inter(size: 12, color: c.muted),
            ),
            const SizedBox(height: 4),
            Text(
              '${_totals.ingredientWeightGrams.round()} ${s.isRu ? 'г' : 'g'}',
              style: t.fraunces(size: 25, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _field(
        _cookedWeight,
        s.isRu
            ? 'Фактический вес готового блюда, г'
            : 'Actual cooked weight, g',
        key: const ValueKey('recipeCookedWeight'),
        numeric: true,
        onChanged: (value) {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) _lastValidCooked = parsed;
          setState(() => _error = null);
        },
      ),
      const SizedBox(height: 7),
      Text(
        s.isRu
            ? 'Можно оставить пустым — расчёт будет основан на суммарном весе ингредиентов.'
            : 'Optional: without it, ingredient weight is used.',
        style: t.inter(size: 10, color: c.muted, height: 1.35),
      ),
      const SizedBox(height: 14),
      _field(
        _portions,
        s.isRu ? 'Количество порций (необязательно)' : 'Portions (optional)',
        key: const ValueKey('recipePortions'),
        numeric: true,
      ),
      const SizedBox(height: 16),
      _liveRecipePreview(c, t, s),
    ],
  );

  Widget _liveRecipePreview(dynamic c, AppText t, S s) {
    final version = _preview;
    if (version == null) {
      return Container(
        key: const ValueKey('recipeLivePreview'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Text('—', style: t.fraunces(size: 22, color: c.muted)),
      );
    }
    final per100 = version.nutritionPer100g;
    String one(double value) => value.toStringAsFixed(1);
    return Container(
      key: const ValueKey('recipeLivePreview'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel(s.isRu ? 'ВСЕГО' : 'TOTAL'),
          const SizedBox(height: 10),
          BalanceAnimatedNumber(
            value: version.totals.calories,
            formatter: (value) =>
                '${value.round()} ${s.isRu ? 'ккал' : 'kcal'}',
            style: t.fraunces(size: 25, weight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              for (final item in [
                (s.isRu ? 'Б' : 'P', version.totals.protein),
                (s.isRu ? 'Ж' : 'F', version.totals.fat),
                (s.isRu ? 'У' : 'C', version.totals.carbs),
              ])
                Expanded(
                  child: BalanceAnimatedNumber(
                    value: item.$2,
                    formatter: (value) => '${item.$1} ${one(value)}',
                    style: t.mono(size: 10),
                  ),
                ),
            ],
          ),
          const Divider(height: 22),
          MonoLabel(s.isRu ? 'НА 100 Г' : 'PER 100 G'),
          const SizedBox(height: 8),
          BalanceAnimatedNumber(
            value: per100.calories ?? 0,
            formatter: (value) =>
                '${value.round()} ${s.isRu ? 'ккал' : 'kcal'}',
            style: t.fraunces(size: 22, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '${s.isRu ? 'Б' : 'P'} ${one(per100.protein ?? 0)}   '
            '${s.isRu ? 'Ж' : 'F'} ${one(per100.fat ?? 0)}   '
            '${s.isRu ? 'У' : 'C'} ${one(per100.carbs ?? 0)}',
            style: t.mono(size: 10, color: c.muted),
          ),
          if (version.hasSuspiciousCookedWeight) ...[
            const SizedBox(height: 12),
            _recipeWeightWarning(c, t, s),
          ],
          if (version.nutritionPerPortion case final portion?) ...[
            const SizedBox(height: 5),
            BalanceAnimatedNumber(
              value: portion.calories ?? 0,
              formatter: (value) =>
                  '${s.isRu ? 'На порцию' : 'Per serving'} · ${value.round()} ${s.isRu ? 'ккал' : 'kcal'}',
              style: t.inter(size: 11, color: c.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultStep(dynamic c, AppText t, S s) {
    final version = _preview;
    if (version == null) return const SizedBox.shrink();
    final per100 = version.nutritionPer100g;
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel(s.isRu ? 'ИТОГ РЕЦЕПТА' : 'RECIPE SUMMARY'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _compactResultMetric(
                      t,
                      s.isRu ? 'Вес' : 'Weight',
                      '${version.effectiveWeightGrams.round()} ${s.isRu ? 'г' : 'g'}',
                    ),
                  ),
                  Expanded(
                    child: _compactResultMetric(
                      t,
                      s.isRu ? 'Всего' : 'Total',
                      '${version.totals.calories.round()} ${s.isRu ? 'ккал' : 'kcal'}',
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              MonoLabel(s.isRu ? 'НА 100 Г' : 'PER 100 G'),
              const SizedBox(height: 7),
              Text(
                '${per100.calories!.round()} ${s.isRu ? 'ккал / 100 г' : 'kcal / 100 g'}',
                style: t.fraunces(size: 20, weight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                '${s.isRu ? 'Б' : 'P'} ${per100.protein!.toStringAsFixed(1)}   '
                '${s.isRu ? 'Ж' : 'F'} ${per100.fat!.toStringAsFixed(1)}   '
                '${s.isRu ? 'У' : 'C'} ${per100.carbs!.toStringAsFixed(1)}',
                style: t.mono(size: 10, color: c.muted),
              ),
            ],
          ),
        ),
        if (version.usesCalculatedWeight) ...[
          const SizedBox(height: 10),
          Text(
            s.isRu
                ? 'Расчёт основан на суммарном весе ингредиентов'
                : 'Calculated from total ingredient weight',
            style: t.inter(size: 10, color: c.accent2),
          ),
        ],
        if (version.hasSuspiciousCookedWeight) ...[
          const SizedBox(height: 10),
          _recipeWeightWarning(c, t, s),
        ],
        if (version.gramsPerPortion != null) ...[
          const SizedBox(height: 10),
          Text(
            '${s.isRu ? '1 порция' : '1 serving'} ≈ ${version.gramsPerPortion!.round()} ${s.isRu ? 'г' : 'g'} · ${version.nutritionPerPortion!.calories!.round()} ${s.isRu ? 'ккал' : 'kcal'}',
            style: t.inter(size: 11, color: c.muted),
          ),
        ],
      ],
    );
  }

  Widget _compactResultMetric(AppText t, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: t.mono(size: 8)),
      const SizedBox(height: 3),
      Text(value, style: t.inter(size: 13, weight: FontWeight.w700)),
    ],
  );

  Widget _recipeWeightWarning(dynamic c, AppText t, S s) => Container(
    key: const ValueKey('recipeSuspiciousWeightWarning'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: c.accent2Soft,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c.accent2.withValues(alpha: .24)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 17, color: c.accent2),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            s.isRu
                ? 'Проверьте вес готового блюда'
                : 'Check the cooked dish weight',
            style: t.inter(size: 11, weight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    Key? key,
    int lines = 1,
    bool numeric = false,
    ValueChanged<String>? onChanged,
  }) => TextField(
    key: key,
    controller: controller,
    maxLines: lines,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    onChanged: onChanged ?? (_) => setState(() => _error = null),
    decoration: _balancedDecoration(label),
  );

  InputDecoration _balancedDecoration(
    String label, {
    String? suffixText,
    bool isDense = false,
  }) {
    final colors = context.colors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      labelText: label,
      suffixText: suffixText,
      isDense: isDense,
      filled: true,
      fillColor: colors.card,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(
          color: colors.accent.withValues(alpha: .42),
          width: 1.2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 13,
        vertical: isDense ? 11 : 14,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (image == null) return;
      final sanitized = ImageSanitizer.sanitize(
        await image.readAsBytes(),
        maxOutputLongEdge: 1000,
      );
      if (mounted) setState(() => _imageBytes = sanitized.bytes);
    } on PlatformException {
      // Image is optional; keep the draft intact when access is unavailable.
    } on ImageValidationException {
      // Invalid images are ignored without affecting recipe nutrition.
    }
  }

  Future<void> _showIngredientPicker(S s) async {
    final query = TextEditingController();
    var products = <FoodProduct>[];
    var loading = false;
    Object? selected;
    try {
      final recent = await widget.catalog.search('', online: false, limit: 20);
      products = recent.items;
      if (!mounted) return;
      selected = await showModalBottomSheet<Object>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colors.surface,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> search(String value) async {
              setSheetState(() => loading = true);
              final outcome = await widget.catalog.search(
                value,
                online: value.trim().length >= 2,
                limit: 20,
                searchContext: FoodSearchContext.recipeIngredient,
              );
              if (ctx.mounted) {
                setSheetState(() {
                  products = outcome.items;
                  loading = false;
                });
              }
            }

            return SafeArea(
              top: false,
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * .78,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.viewInsetsOf(ctx).bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.isRu ? 'Добавить ингредиент' : 'Add ingredient',
                        style: AppText(
                          context.colors,
                        ).fraunces(size: 22, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: query,
                        autofocus: true,
                        onChanged: search,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: s.isRu
                              ? 'Продукт или ингредиент'
                              : 'Product or ingredient',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final result = await Navigator.of(ctx)
                                  .push<PackageScanResult>(
                                    MaterialPageRoute(
                                      builder: (_) => PackageScannerScreen(
                                        repository: widget.catalog,
                                        strings: widget.scannerStrings,
                                      ),
                                    ),
                                  );
                              if (result?.product != null && ctx.mounted) {
                                Navigator.pop(ctx, result!.product);
                              }
                            },
                            icon: const Icon(Icons.document_scanner_outlined),
                            label: Text(s.isRu ? 'Штрихкод' : 'Barcode'),
                          ),
                          TextButton.icon(
                            onPressed: () => Navigator.pop(ctx, 'manual'),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(s.isRu ? 'Вручную' : 'Manual'),
                          ),
                        ],
                      ),
                      if (loading) const LinearProgressIndicator(minHeight: 2),
                      Expanded(
                        child: ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (_, index) {
                            final product = products[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: InkWell(
                                onTap: product.hasCompleteNutrition
                                    ? () => Navigator.pop(ctx, product)
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 52,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.card2,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${product.kcalPer100g} ${s.isRu ? 'ккал' : 'kcal'} · '
                                              'Б ${product.proteinPer100g.toStringAsFixed(1)}  '
                                              'Ж ${product.fatPer100g.toStringAsFixed(1)}  '
                                              'У ${product.carbsPer100g.toStringAsFixed(1)}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: context.colors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 20,
                                        color: product.hasCompleteNutrition
                                            ? context.colors.accent
                                            : context.colors.muted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
      if (!mounted) return;
      if (selected == 'manual') {
        final manual = await _manualIngredient(s);
        if (manual != null) setState(() => _ingredients.add(manual));
        return;
      }
      if (selected is! FoodProduct) return;
      final ingredient = await _amountForProduct(selected, s);
      if (ingredient != null && mounted) {
        setState(() => _ingredients.add(ingredient));
      }
    } finally {
      query.dispose();
    }
  }

  Future<RecipeIngredient?> _amountForProduct(FoodProduct product, S s) async {
    final controller = TextEditingController(text: '100');
    try {
      return await showDialog<RecipeIngredient>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(product.name),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _balancedDecoration(
              s.isRu ? 'Количество, г' : 'Amount, g',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );
                if (amount == null || amount <= 0) return;
                try {
                  Navigator.pop(
                    ctx,
                    RecipeIngredient.fromProduct(
                      id: newEntryId(),
                      product: product,
                      amount: amount,
                    ),
                  );
                } catch (_) {}
              },
              child: Text(s.isRu ? 'Добавить' : 'Add'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _editIngredientAmount(int index, S s) async {
    final current = _ingredients[index];
    final controller = TextEditingController(text: '${current.amount}');
    try {
      final amount = await showDialog<double>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(current.nameSnapshot),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _balancedDecoration(
              s.isRu ? 'Количество' : 'Amount',
              suffixText: _unit(current.unit, s),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );
                if (value != null && value > 0) Navigator.pop(ctx, value);
              },
              child: Text(s.isRu ? 'Готово' : 'Done'),
            ),
          ],
        ),
      );
      if (amount != null && mounted) {
        setState(() => _ingredients[index] = current.copyWith(amount: amount));
      }
    } finally {
      controller.dispose();
    }
  }

  Future<RecipeUnit?> _pickRecipeUnit(
    BuildContext owner,
    RecipeUnit current,
    S s,
  ) => showModalBottomSheet<RecipeUnit>(
    context: owner,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              s.isRu ? 'Единица измерения' : 'Measurement unit',
              style: AppText(
                context.colors,
              ).fraunces(size: 20, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (_, constraints) {
                final itemWidth = (constraints.maxWidth - 16) / 3;
                return Wrap(
                  key: const ValueKey('recipeUnitGrid'),
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in RecipeUnit.values)
                      SizedBox(
                        width: itemWidth,
                        child: InkWell(
                          key: ValueKey('recipeUnit-${value.name}'),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(sheetContext, value);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: value == current
                                  ? context.colors.accentSoft
                                  : context.colors.card2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: value == current
                                    ? context.colors.accent.withValues(
                                        alpha: .4,
                                      )
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              _unit(value, s),
                              style: TextStyle(
                                fontWeight: value == current
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: value == current
                                    ? context.colors.accent
                                    : context.colors.fg2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );

  Future<RecipeIngredient?> _manualIngredient(S s) async {
    final fields = List.generate(7, (_) => TextEditingController());
    RecipeUnit unit = RecipeUnit.g;
    try {
      return await showModalBottomSheet<RecipeIngredient>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colors.surface,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            double? number(int i) =>
                double.tryParse(fields[i].text.replaceAll(',', '.'));
            final amount = number(1);
            final equivalent = number(2);
            final weight = unit == RecipeUnit.g || unit == RecipeUnit.ml
                ? amount
                : equivalent;
            final valid =
                fields[0].text.trim().isNotEmpty &&
                amount != null &&
                amount > 0 &&
                weight != null &&
                weight > 0 &&
                [3, 4, 5, 6].every((i) => number(i) != null && number(i)! >= 0);
            final calculatedKcal =
                (number(4) ?? 0) * 4 +
                (number(6) ?? 0) * 4 +
                (number(5) ?? 0) * 9;
            final declaredKcal = number(3);
            final nutritionMismatch =
                declaredKcal != null &&
                declaredKcal > 0 &&
                (calculatedKcal - declaredKcal).abs() >
                    (declaredKcal * .2).clamp(30, double.infinity);
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  MediaQuery.viewInsetsOf(ctx).bottom + 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.isRu ? 'Ингредиент вручную' : 'Manual ingredient',
                      style: AppText(
                        context.colors,
                      ).fraunces(size: 22, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.colors.card2,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            key: const ValueKey('manualIngredientName'),
                            controller: fields[0],
                            onChanged: (_) => setSheetState(() {}),
                            decoration: _balancedDecoration(
                              s.isRu ? 'Название' : 'Name',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            key: const ValueKey('manualIngredientAmountRow'),
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('manualIngredientAmount'),
                                  controller: fields[1],
                                  onChanged: (_) => setSheetState(() {}),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _balancedDecoration(
                                    s.isRu ? 'Количество' : 'Amount',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 94,
                                child: InkWell(
                                  key: const ValueKey(
                                    'manualIngredientUnitPicker',
                                  ),
                                  onTap: () async {
                                    final selected = await _pickRecipeUnit(
                                      ctx,
                                      unit,
                                      s,
                                    );
                                    if (selected != null && ctx.mounted) {
                                      setSheetState(() => unit = selected);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 56,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.card,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: context.colors.line,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(_unit(unit, s)),
                                        const SizedBox(width: 3),
                                        const Icon(
                                          Icons.expand_more_rounded,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (unit != RecipeUnit.g && unit != RecipeUnit.ml)
                            TextField(
                              controller: fields[2],
                              onChanged: (_) => setSheetState(() {}),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _balancedDecoration(
                                s.isRu ? 'Общий вес, г' : 'Total weight, g',
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.colors.card2,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 2.25,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final item in [
                            (3, s.isRu ? 'Ккал / 100 г' : 'Kcal / 100 g'),
                            (4, s.isRu ? 'Белки / 100 г' : 'Protein / 100 g'),
                            (5, s.isRu ? 'Жиры / 100 г' : 'Fat / 100 g'),
                            (6, s.isRu ? 'Углеводы / 100 г' : 'Carbs / 100 g'),
                          ])
                            TextField(
                              key: ValueKey('manualIngredientField-${item.$1}'),
                              controller: fields[item.$1],
                              onChanged: (_) => setSheetState(() {}),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _balancedDecoration(
                                item.$2,
                                isDense: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (nutritionMismatch) ...[
                      const SizedBox(height: 10),
                      Text(
                        s.isRu
                            ? 'Проверьте КБЖУ: по формуле Б×4 + У×4 + Ж×9 получается ${calculatedKcal.round()} ккал.'
                            : 'Check macros: P×4 + C×4 + F×9 gives ${calculatedKcal.round()} kcal.',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.accent2,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    PrimaryButton(
                      key: const ValueKey('saveManualIngredient'),
                      label: s.isRu ? 'Добавить' : 'Add',
                      onTap: valid
                          ? () {
                              final factor = weight / 100;
                              Navigator.pop(
                                ctx,
                                RecipeIngredient(
                                  id: newEntryId(),
                                  nameSnapshot: fields[0].text.trim(),
                                  amount: amount,
                                  unit: unit,
                                  gramsEquivalent:
                                      unit == RecipeUnit.g ||
                                          unit == RecipeUnit.ml
                                      ? null
                                      : weight,
                                  nutritionSnapshot: NutritionValues(
                                    calories: number(3)! * factor,
                                    protein: number(4)! * factor,
                                    fat: number(5)! * factor,
                                    carbs: number(6)! * factor,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      for (final field in fields) {
        field.dispose();
      }
    }
  }

  String _unit(RecipeUnit unit, S s) => switch (unit) {
    RecipeUnit.g => s.isRu ? 'г' : 'g',
    RecipeUnit.ml => s.isRu ? 'мл' : 'ml',
    RecipeUnit.piece => s.isRu ? 'шт.' : 'piece',
    RecipeUnit.tbsp => s.isRu ? 'ст. л.' : 'tbsp',
    RecipeUnit.tsp => s.isRu ? 'ч. л.' : 'tsp',
  };

  Future<void> _next(S s) async {
    setState(() => _error = null);
    if (_step == 0 && _name.text.trim().isEmpty) {
      setState(
        () =>
            _error = s.isRu ? 'Введите название блюда' : 'Enter a recipe name',
      );
      return;
    }
    if (_step == 1 && _ingredients.isEmpty) {
      setState(
        () => _error = s.isRu ? 'Добавьте ингредиенты' : 'Add ingredients',
      );
      return;
    }
    if (_step == 2) {
      if (_cookedWeight.text.trim().isNotEmpty &&
          (_cooked == null || _cooked! <= 0)) {
        setState(
          () => _error = s.isRu
              ? 'Вес должен быть больше нуля'
              : 'Weight must be positive',
        );
        return;
      }
      if (_portionCount != null &&
          (_portionCount! < 1 || _portionCount! > 1000)) {
        setState(
          () => _error = s.isRu
              ? 'Проверьте количество порций'
              : 'Check portions',
        );
        return;
      }
    }
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    await _save(s);
  }

  Future<void> _save(S s) async {
    final data = context.read<AppDataProvider>();
    final existing = widget.recipe;
    var updateExisting = existing != null && !widget.saveAsCopy;
    if (existing != null && !widget.saveAsCopy && !widget.prepareAgain) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.isRu ? 'Сохранить изменения' : 'Save changes'),
          content: Text(
            s.isRu
                ? 'Обновить рецепт новой версией или сохранить отдельный вариант?'
                : 'Create a new version or a separate recipe?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'copy'),
              child: Text(s.isRu ? 'Новый вариант' : 'New variant'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'update'),
              child: Text(s.isRu ? 'Обновить рецепт' : 'Update recipe'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      updateExisting = choice == 'update';
    }
    final recipe = updateExisting
        ? await data.updateRecipe(
            recipeId: existing!.id,
            name: _name.text.trim(),
            category: _category.text,
            note: _note.text,
            imageBytes: _imageBytes,
            ingredients: _ingredients,
            cookedWeightGrams: _cooked,
            portions: _portionCount,
          )
        : await data.createRecipe(
            name: _name.text.trim(),
            category: _category.text,
            note: _note.text,
            imageBytes: _imageBytes,
            ingredients: _ingredients,
            cookedWeightGrams: _cooked,
            portions: _portionCount,
          );
    if (mounted) Navigator.of(context).pop(recipe);
  }
}
