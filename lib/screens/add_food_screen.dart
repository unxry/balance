import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_models.dart';
import '../models/food_product.dart';
import '../models/product_retailer_relation.dart';
import '../models/recipe_models.dart';
import '../models/unified_food_item.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/food_catalog_repository.dart';
import '../services/dish_catalog_repository.dart';
import '../services/food_search_service.dart';
import '../services/local_catalog_bootstrap.dart';
import '../services/remote_catalog_source.dart';
import '../services/sqlite_product_cache.dart';
import '../services/unified_food_search_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/balance_motion.dart';
import '../theme/i18n.dart';
import '../utils/entry_id.dart';
import '../utils/calendar_date.dart';
import '../widgets/common.dart';
import '../widgets/food_thumb.dart';
import '../widgets/balance_feedback.dart';
import 'package_scanner_screen.dart';
import 'my_recipes_screen.dart';

const _retailerOptions = <(String, String, String)>[
  ('pyaterochka', 'Пятёрочка', 'Pyaterochka'),
  ('magnit', 'Магнит', 'Magnit'),
  ('perekrestok', 'Перекрёсток', 'Perekrestok'),
  ('vkusvill', 'ВкусВилл', 'VkusVill'),
  ('pobeda', 'Победа', 'Pobeda'),
  ('fix_price', 'Fix Price', 'Fix Price'),
];

const _retailerCategories = <(String, String, String)>[
  ('all', 'Все', 'All'),
  ('preparedFood', 'Готовая еда', 'Prepared food'),
  ('hotBakery', 'Горячая выпечка', 'Hot bakery'),
  ('bread', 'Хлеб', 'Bread'),
  ('dairy', 'Молочное', 'Dairy'),
  ('meat', 'Мясо', 'Meat'),
  ('fish', 'Рыба', 'Fish'),
  ('frozen', 'Заморозка', 'Frozen'),
  ('drinks', 'Напитки', 'Drinks'),
  ('sweets', 'Сладости', 'Sweets'),
  ('snacks', 'Снеки', 'Snacks'),
  ('sauces', 'Соусы', 'Sauces'),
  ('grains', 'Крупы', 'Grains'),
  ('canned', 'Консервы', 'Canned'),
  ('breakfast', 'Завтраки', 'Breakfast'),
  ('other', 'Другое', 'Other'),
];

class AddFoodScreen extends StatefulWidget {
  final VoidCallback onBack;
  final MealType initialMeal;
  final DateTime selectedDate;
  final ValueChanged<FoodEntry>? onAdded;
  final Map<String, Map<String, int>>? initialRetailerCategoryCounts;
  const AddFoodScreen({
    super.key,
    required this.onBack,
    required this.initialMeal,
    required this.selectedDate,
    this.onAdded,
    this.initialRetailerCategoryCounts,
  });

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _resultsScroll = ScrollController();
  String query = '';
  String chip = 'all';
  String? _retailer;
  String _retailerCategory = 'all';
  String? _brand;
  ProductSort _productSort = ProductSort.relevance;
  bool _onlyCompleteNutrition = false;
  bool _onlyPhoto = false;
  late MealType targetMeal;
  Timer? _debounce;
  late final FoodSearchService _foodSearch;
  late final RemoteCatalogSource _remoteCatalog;
  late FoodCatalogRepository _catalog;
  SqliteProductCache? _sqliteCache;
  DishCatalogRepository? _dishCatalog;
  UnifiedFoodSearchService? _unifiedSearch;
  List<UnifiedFoodItem> _results = [];
  List<UnifiedFoodItem> _generalFallbackResults = [];
  bool _searching = false;
  bool _catalogPreparing = false;
  bool _canLoadMore = false;
  int _loadedLimit = 50;
  Map<String, Map<String, int>> _retailerCategoryCounts = const {};
  FoodSearchError? _searchError;
  int _searchGeneration = 0;
  Future<void>? _catalogReady;

  @override
  void initState() {
    super.initState();
    targetMeal = widget.initialMeal;
    _retailerCategoryCounts = widget.initialRetailerCategoryCounts ?? const {};
    _foodSearch = FoodSearchService();
    _remoteCatalog = RemoteCatalogSource();
    _catalog = FoodCatalogRepository(
      cache: MemoryProductCache(),
      sources: [_remoteCatalog, _foodSearch],
    );
    _resultsScroll.addListener(_loadMoreIfNeeded);
    _initCatalogCache();
  }

  Future<void> _initCatalogCache() async {
    try {
      final cache = await SqliteProductCache.open();
      if (!mounted) {
        await cache.close();
        return;
      }
      _sqliteCache = cache;
      _catalog = FoodCatalogRepository(
        cache: cache,
        sources: [_remoteCatalog, _foodSearch],
      );
      setState(() => _catalogPreparing = true);
      _catalogReady = LocalCatalogBootstrap(cache: cache)
          .ensureImported()
          .then((_) async {
            if (!mounted) return;
            final counts = await cache.retailerCategoryCounts();
            if (!mounted) return;
            setState(() {
              _catalogPreparing = false;
              _retailerCategoryCounts = counts;
            });
            await _runSearch(query, online: false);
          })
          .catchError((Object _) {
            if (mounted) setState(() => _catalogPreparing = false);
          });
      unawaited(_remoteCatalog.syncCatalog(cache));
    } catch (_) {
      // Memory fallback keeps search/manual diary usable on unsupported hosts.
    }
    try {
      _dishCatalog = await DishCatalogRepository.open();
      if (!mounted) {
        await _dishCatalog?.close();
        return;
      }
      final data = context.read<AppDataProvider>();
      _unifiedSearch = UnifiedFoodSearchService(
        products: _catalog,
        dishes: _dishCatalog!,
        recipes: () => data.userRecipes,
        recipeUsageCount: data.recipeUsageCount,
      );
    } catch (_) {
      // Product search remains available if the separate dish cache fails.
    }
    await _runSearch(query, online: false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _foodSearch.dispose();
    _remoteCatalog.dispose();
    _sqliteCache?.close();
    _dishCatalog?.close();
    _searchController.dispose();
    _searchFocus.dispose();
    _resultsScroll.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    setState(() {
      query = v;
      _loadedLimit = 50;
    });
    _debounce?.cancel();
    final generation = ++_searchGeneration;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    final delay = v.trim().length < 2
        ? Duration.zero
        : const Duration(milliseconds: 450);
    _debounce = Timer(delay, () => _runSearch(v, generation: generation));
  }

  Future<void> _runSearch(
    String value, {
    int? generation,
    bool online = true,
  }) async {
    final unified = _unifiedSearch;
    final catalogCategory = chip == 'retailer' ? 'all' : chip;
    final inStore = chip == 'retailer' && _retailer != null;
    late final UnifiedFoodSearchOutcome outcome;
    var fallback = <UnifiedFoodItem>[];
    if (inStore) {
      final store = await _catalog.search(
        value,
        limit: _loadedLimit,
        online: online && value.trim().length >= 2,
        category: 'all',
        retailer: _retailer,
        taxonomyCategory: _retailerCategory,
        sort: _productSort,
        onlyCompleteNutrition: _onlyCompleteNutrition,
        onlyPhoto: _onlyPhoto,
        brand: _brand,
        meal: targetMeal,
      );
      outcome = UnifiedFoodSearchOutcome(
        store.items.map(UnifiedFoodItem.fromProduct).toList(),
        productSearchError: store.error,
      );
      if (value.trim().isNotEmpty || store.items.isEmpty) {
        final general = await _catalog.search(
          value,
          limit: _loadedLimit,
          online: false,
          category: 'all',
          taxonomyCategory: _retailerCategory,
          sort: _productSort,
          onlyCompleteNutrition: _onlyCompleteNutrition,
          onlyPhoto: _onlyPhoto,
          brand: _brand,
          meal: targetMeal,
        );
        final storeIds = store.items.map((item) => item.id).toSet();
        fallback = general.items
            .where((item) => !storeIds.contains(item.id))
            .map(UnifiedFoodItem.fromProduct)
            .toList();
      }
    } else if (unified == null) {
      final products = await _catalog.search(
        value,
        limit: _loadedLimit,
        online: online && value.trim().length >= 2,
        category: catalogCategory,
        sort: _productSort,
        onlyCompleteNutrition: _onlyCompleteNutrition,
        onlyPhoto: _onlyPhoto,
        brand: _brand,
        meal: targetMeal,
      );
      outcome = UnifiedFoodSearchOutcome(
        products.items.map(UnifiedFoodItem.fromProduct).toList(),
        productSearchError: products.error,
      );
    } else {
      outcome = await unified.search(
        value,
        limit: _loadedLimit,
        online: online && value.trim().length >= 2,
        category: catalogCategory,
        sort: _productSort,
        onlyCompleteNutrition: _onlyCompleteNutrition,
        onlyPhoto: _onlyPhoto,
        brand: _brand,
        meal: targetMeal,
      );
    }
    if (!mounted || (generation != null && generation != _searchGeneration)) {
      return;
    }
    setState(() {
      _results = outcome.items.where((item) => item.isUsableForDiary).toList();
      _generalFallbackResults = fallback
          .where((item) => item.isUsableForDiary)
          .toList();
      _canLoadMore =
          _results.length >= _loadedLimit ||
          _generalFallbackResults.length >= _loadedLimit;
      _searchError = outcome.productSearchError;
      _searching = false;
    });
  }

  void _loadMoreIfNeeded() {
    if (!_canLoadMore || _searching || !_resultsScroll.hasClients) return;
    if (_resultsScroll.position.extentAfter > 280) return;
    setState(() {
      _loadedLimit += 50;
      _searching = true;
    });
    unawaited(_runSearch(query, online: false));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final lang = context.watch<SettingsProvider>().lang;
    final s = S(lang);

    final filtered = chip == 'retailer' && _retailer == null
        ? const <UnifiedFoodItem>[]
        : _results;
    final inStore = chip == 'retailer' && _retailer != null;
    final rows = <({UnifiedFoodItem? item, String? title, bool general})>[];
    if (inStore &&
        (filtered.isNotEmpty || _generalFallbackResults.isNotEmpty)) {
      final retailerName = s.isRu
          ? _retailerOption?.$2 ?? ''
          : _retailerOption?.$3 ?? '';
      rows.add((
        item: null,
        title: filtered.isEmpty
            ? (s.isRu
                  ? 'В локальном каталоге сети пока нет таких товаров'
                  : 'No matching products in the local retailer catalog')
            : (s.isRu ? 'Товары $retailerName' : '$retailerName products'),
        general: false,
      ));
      rows.addAll(
        filtered.map((item) => (item: item, title: null, general: false)),
      );
      if (_generalFallbackResults.isNotEmpty) {
        rows.add((
          item: null,
          title: s.isRu
              ? 'Похожие товары из общего каталога'
              : 'Similar products from the general catalog',
          general: true,
        ));
        rows.addAll(
          _generalFallbackResults.map(
            (item) => (item: item, title: null, general: true),
          ),
        );
      }
    } else {
      rows.addAll(
        filtered.map((item) => (item: item, title: null, general: false)),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GhostBackButton(onTap: widget.onBack),
                const Spacer(),
                InkWell(
                  onTap: () => _showManualEntry(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Pill(
                    text: s.isRu ? 'РУЧНОЙ ВВОД' : 'MANUAL ENTRY',
                    bg: c.accentSoft,
                    fg: c.accent,
                    mono: true,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              s.isRu ? 'Добавить еду' : 'Add food',
              style: t.fraunces(size: 28, weight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _catalogAction(
                    c,
                    t,
                    icon: Icons.search_rounded,
                    label: s.isRu ? 'Найти продукт' : 'Find product',
                    onTap: _searchFocus.requestFocus,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _catalogAction(
                    c,
                    t,
                    icon: Icons.document_scanner_outlined,
                    label: s.isRu ? 'Сканировать упаковку' : 'Scan packaging',
                    onTap: () => _openScanner(context, s),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _catalogAction(
              c,
              t,
              icon: Icons.menu_book_outlined,
              label: s.isRu ? 'Мои рецепты' : 'My recipes',
              secondary: true,
              onTap: () => _openMyRecipes(context),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: c.card2,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: c.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: _onQueryChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchFocus.unfocus(),
                      decoration: InputDecoration(
                        hintText: _searchHint(s),
                        hintStyle: t.inter(size: 13, color: c.muted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      style: t.inter(size: 13),
                    ),
                  ),
                  if (_searching)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.accent,
                      ),
                    ),
                  if (query.isNotEmpty && !_searching)
                    InkWell(
                      onTap: () {
                        _searchController.clear();
                        _onQueryChanged('');
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: c.muted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _categoryRow(c, t, s),
            const SizedBox(height: 8),
            _mealPicker(c, t, s),
            if (_catalogPreparing) ...[
              const SizedBox(height: 8),
              Text(
                s.isRu ? 'Подготавливаем каталог…' : 'Preparing catalog…',
                key: const ValueKey('catalogPreparing'),
                style: t.mono(size: 8, color: c.muted),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(.02, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: rows.isEmpty
                    ? chip == 'retailer' && _retailer != null && !_searching
                          ? _emptyRetailerState(context, c, t, s)
                          : Center(
                              key: ValueKey(
                                'foodSearchEmpty:$chip:${_retailer ?? ''}:$_retailerCategory:$_searching',
                              ),
                              child: Text(
                                _searching
                                    ? (s.isRu ? 'Ищу…' : 'Searching…')
                                    : _searchError != null
                                    ? (s.isRu
                                          ? 'Онлайн-поиск недоступен. Проверь интернет.'
                                          : 'Online search is unavailable. Check your connection.')
                                    : chip == 'retailer'
                                    ? (s.isRu
                                          ? 'Выберите магазин'
                                          : 'Choose a retailer')
                                    : (s.isRu
                                          ? 'Ничего не найдено'
                                          : 'Nothing found'),
                                textAlign: TextAlign.center,
                                style: t.inter(size: 13, color: c.muted),
                              ),
                            )
                    : ListView.separated(
                        controller: _resultsScroll,
                        key: ValueKey(
                          'foodSearchResults:${_retailer ?? 'all'}:$_retailerCategory:${_brand ?? 'all'}:${_productSort.name}:$_onlyCompleteNutrition:$_onlyPhoto:${targetMeal.name}',
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final row = rows[i];
                          if (row.title case final title?) {
                            return _storeSectionHeader(c, t, title);
                          }
                          return _foodResultRow(
                            context,
                            c,
                            t,
                            s,
                            row.item!,
                            generalFallback: row.general,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeSectionHeader(dynamic c, AppText t, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 6, 2, 2),
    child: Text(
      title,
      style: t.inter(size: 11, weight: FontWeight.w600, color: c.fg2),
    ),
  );

  Widget _categoryRow(dynamic c, AppText t, S s) {
    final primary = [
      (s.chipAll, 'all'),
      (s.chipRecent, 'recent'),
      (s.chipFav, 'favorite'),
    ];
    final hasFilters =
        const {'meal', 'retailer'}.contains(chip) ||
        _retailer != null ||
        _retailerCategory != 'all' ||
        _brand != null ||
        _productSort != ProductSort.relevance ||
        _onlyCompleteNutrition ||
        _onlyPhoto;
    return Column(
      key: const ValueKey('foodCategoryRow'),
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: c.card2,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    for (final item in primary)
                      Expanded(
                        child: _chip(c, t, item.$1, item.$2, segmented: true),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: s.isRu ? 'Фильтры' : 'Filters',
              child: InkWell(
                key: const ValueKey('foodFiltersButton'),
                onTap: () => _showFiltersSheet(c, t, s),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasFilters ? c.accentSoft : c.card2,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: hasFilters ? c.accent : c.line),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 19,
                    color: hasFilters ? c.accent : c.fg2,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasFilters) ...[
          const SizedBox(height: 7),
          Container(
            key: const ValueKey('activeFoodFilterCapsule'),
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: c.accentSoft.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: c.accent.withValues(alpha: .16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _filterSummary(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.inter(
                      size: 10,
                      weight: FontWeight.w600,
                      color: c.accent,
                    ),
                  ),
                ),
                InkWell(
                  key: const ValueKey('clearFoodFilters'),
                  onTap: _clearFilters,
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    width: 40,
                    height: 36,
                    child: Icon(Icons.close_rounded, size: 16, color: c.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _filterSummary(S s) {
    final values = <String>[];
    if (chip == 'meal') values.add(s.chipMeals);
    if (chip == 'retailer') {
      final retailer = _retailerOption;
      values.add(
        retailer == null
            ? (s.isRu ? 'Магазин' : 'Retailer')
            : (s.isRu ? retailer.$2 : retailer.$3),
      );
      if (_retailerCategory != 'all') {
        final category = _retailerCategories.firstWhere(
          (item) => item.$1 == _retailerCategory,
        );
        values.add(s.isRu ? category.$2 : category.$3);
      }
    }
    if (_brand != null) values.add(_brand!);
    if (_onlyPhoto) values.add(s.isRu ? 'С фото' : 'With photo');
    if (_productSort != ProductSort.relevance) {
      values.add(_sortLabel(_productSort, s));
    }
    return values.join(' · ');
  }

  bool get _shouldSearchOnline => query.trim().length >= 2 || _retailer != null;

  void _clearFilters() {
    setState(() {
      chip = 'all';
      _retailer = null;
      _retailerCategory = 'all';
      _brand = null;
      _productSort = ProductSort.relevance;
      _onlyCompleteNutrition = false;
      _onlyPhoto = false;
      _loadedLimit = 50;
    });
    _runSearch(query, online: _shouldSearchOnline);
  }

  Widget _filterChoice({
    Key? key,
    required dynamic c,
    required AppText t,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.card2.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? c.accent.withValues(alpha: .38)
                : c.line.withValues(alpha: .55),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: t.inter(
            size: 10,
            weight: FontWeight.w700,
            color: selected ? c.accent : c.fg2,
          ),
        ),
      ),
    ),
  );

  Widget _retailerChoice({
    Key? key,
    required dynamic c,
    required AppText t,
    required String name,
    required int count,
    required double width,
    required bool isRu,
    required bool enabled,
    required bool selected,
    required VoidCallback? onTap,
  }) => SizedBox(
    width: width,
    height: 72,
    child: Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: count == 0
          ? '$name, ${isRu ? 'нет известных товаров' : 'no known products'}'
          : '$name, $count',
      child: InkWell(
        key: key,
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? c.accentSoft.withValues(alpha: .62)
                : c.card2.withValues(alpha: enabled ? .52 : .28),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? c.accent.withValues(alpha: .42)
                  : c.line.withValues(alpha: enabled ? .55 : .32),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.inter(size: 11, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      count == 0
                          ? (isRu ? 'Нет известных товаров' : 'No known items')
                          : '$count ${isRu ? (count == 1 ? 'товар' : 'тов.') : (count == 1 ? 'item' : 'items')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.mono(size: 7.5, color: c.muted),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 16, color: c.accent),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _categoryChoice({
    Key? key,
    required dynamic c,
    required AppText t,
    required String title,
    required int count,
    required bool isRu,
    required bool selected,
    required VoidCallback onTap,
  }) => Semantics(
    button: true,
    selected: selected,
    label: '$title, $count',
    child: InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? c.accentSoft.withValues(alpha: .58)
              : c.card2.withValues(alpha: .46),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? c.accent.withValues(alpha: .42)
                : c.line.withValues(alpha: .52),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.inter(size: 10.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$count ${isRu ? (count == 1 ? 'товар' : 'тов.') : (count == 1 ? 'item' : 'items')}',
                    style: t.mono(size: 7.5, color: c.muted),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_rounded, size: 15, color: c.accent),
          ],
        ),
      ),
    ),
  );

  List<(String, String, String)> _availableRetailerCategories(
    String? retailer,
  ) => _retailerCategories
      .where(
        (item) =>
            item.$1 == 'all' ||
            (retailer != null &&
                (_retailerCategoryCounts[retailer]?[item.$1] ?? 0) > 0),
      )
      .toList();

  List<(String, String, String)> _compactRetailerCategories(
    String? retailer,
    String selected,
  ) {
    final available = _availableRetailerCategories(retailer);
    final compact = available.take(6).toList();
    final selectedItem = available.where((item) => item.$1 == selected);
    if (selectedItem.isNotEmpty &&
        !compact.any((item) => item.$1 == selected)) {
      compact[compact.length - 1] = selectedItem.first;
    }
    return compact;
  }

  Future<String?> _showCategoryPicker(
    dynamic c,
    AppText t,
    S s, {
    required String retailer,
    required String selected,
  }) async {
    var search = '';
    final searchController = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (pickerContext) => StatefulBuilder(
        builder: (_, setPickerState) {
          final categories = _availableRetailerCategories(retailer)
              .where(
                (item) => (s.isRu ? item.$2 : item.$3).toLowerCase().contains(
                  search.trim().toLowerCase(),
                ),
              )
              .toList();
          return SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.sizeOf(pickerContext).height * .68,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
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
                    const SizedBox(height: 16),
                    Text(
                      s.isRu ? 'Все категории' : 'All categories',
                      style: t.fraunces(size: 23, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('retailerCategorySearch'),
                      controller: searchController,
                      onChanged: (value) =>
                          setPickerState(() => search = value),
                      decoration: InputDecoration(
                        hintText: s.isRu ? 'Найти категорию' : 'Find category',
                        prefixIcon: Icon(Icons.search_rounded, color: c.muted),
                        suffixIcon: search.isEmpty
                            ? null
                            : IconButton(
                                tooltip: s.isRu ? 'Очистить' : 'Clear',
                                onPressed: () {
                                  searchController.clear();
                                  setPickerState(() => search = '');
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                        filled: true,
                        fillColor: c.card2.withValues(alpha: .72),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: c.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: c.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: c.accent, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: categories.isEmpty
                          ? Center(
                              key: const ValueKey('categoryPickerEmpty'),
                              child: Text(
                                s.isRu
                                    ? 'Категории не найдены'
                                    : 'No categories found',
                                style: t.inter(size: 12, color: c.muted),
                              ),
                            )
                          : GridView.builder(
                              key: const ValueKey('categoryPickerGrid'),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    mainAxisExtent: 76,
                                  ),
                              itemCount: categories.length,
                              itemBuilder: (_, index) {
                                final item = categories[index];
                                final count =
                                    _retailerCategoryCounts[retailer]?[item
                                        .$1] ??
                                    0;
                                return _categoryChoice(
                                  key: ValueKey('categoryPicker-${item.$1}'),
                                  c: c,
                                  t: t,
                                  title: s.isRu ? item.$2 : item.$3,
                                  count: count,
                                  isRu: s.isRu,
                                  selected: selected == item.$1,
                                  onTap: () =>
                                      Navigator.pop(pickerContext, item.$1),
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
    searchController.dispose();
    return result;
  }

  Future<void> _showFiltersSheet(dynamic c, AppText t, S s) async {
    if (_catalogPreparing) await _catalogReady;
    if (!mounted) return;
    var hasDishes = false;
    try {
      hasDishes = context.read<AppDataProvider>().userRecipes.isNotEmpty;
    } on ProviderNotFoundException {
      // Lightweight widget tests may exercise the local catalog without app data.
    }
    var mode = const {'meal', 'retailer'}.contains(chip) ? chip : 'all';
    if (mode == 'meal' && !hasDishes) mode = 'all';
    var retailer = _retailer;
    var category = _retailerCategory;
    String? brand;
    var sort = ProductSort.relevance;
    var photo = false;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
            ),
            child: Column(
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
                const SizedBox(height: 16),
                Text(
                  s.isRu ? 'Фильтры' : 'Filters',
                  style: t.fraunces(size: 24, weight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                MonoLabel(s.isRu ? 'ИСТОЧНИК' : 'SOURCE'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final item in [
                      (s.isRu ? 'Весь каталог' : 'Full catalog', 'all'),
                      if (hasDishes) (s.chipMeals, 'meal'),
                      (s.isRu ? 'Магазины' : 'Retailers', 'retailer'),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: _filterChoice(
                            key: ValueKey('filterSource-${item.$2}'),
                            c: c,
                            t: t,
                            label: item.$1,
                            selected: mode == item.$2,
                            onTap: () => setSheetState(() {
                              mode = item.$2;
                              if (mode != 'retailer') {
                                retailer = null;
                                category = 'all';
                              }
                              brand = null;
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
                if (mode == 'retailer') ...[
                  const SizedBox(height: 16),
                  MonoLabel(s.isRu ? 'МАГАЗИН' : 'RETAILER'),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (_, constraints) {
                      const gap = 8.0;
                      final width = (constraints.maxWidth - gap) / 2;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final item in _retailerOptions)
                            _retailerChoice(
                              key: ValueKey('retailer-${item.$1}'),
                              c: c,
                              t: t,
                              name: s.isRu ? item.$2 : item.$3,
                              count:
                                  _retailerCategoryCounts[item.$1]?["all"] ?? 0,
                              width: width,
                              isRu: s.isRu,
                              enabled:
                                  item.$1 != 'pobeda' ||
                                  (_retailerCategoryCounts[item.$1]?["all"] ??
                                          0) >
                                      0,
                              selected: retailer == item.$1,
                              onTap: () => setSheetState(() {
                                retailer = item.$1;
                                category = 'all';
                                brand = null;
                              }),
                            ),
                        ],
                      );
                    },
                  ),
                  if (retailer != null) ...[
                    const SizedBox(height: 16),
                    MonoLabel(s.isRu ? 'КАТЕГОРИЯ' : 'CATEGORY'),
                    const SizedBox(height: 8),
                    GridView.builder(
                      key: const ValueKey('filterCategoryGrid'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            mainAxisExtent: 70,
                          ),
                      itemCount: _compactRetailerCategories(
                        retailer,
                        category,
                      ).length,
                      itemBuilder: (_, index) {
                        final item = _compactRetailerCategories(
                          retailer,
                          category,
                        )[index];
                        return _categoryChoice(
                          key: ValueKey('retailerCategory-${item.$1}'),
                          c: c,
                          t: t,
                          title: s.isRu ? item.$2 : item.$3,
                          count:
                              _retailerCategoryCounts[retailer]?[item.$1] ?? 0,
                          isRu: s.isRu,
                          selected: category == item.$1,
                          onTap: () => setSheetState(() {
                            category = item.$1;
                            brand = null;
                          }),
                        );
                      },
                    ),
                    if (_availableRetailerCategories(retailer).length > 6) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        key: const ValueKey('allRetailerCategories'),
                        onTap: retailer == null
                            ? null
                            : () async {
                                final selected = await _showCategoryPicker(
                                  c,
                                  t,
                                  s,
                                  retailer: retailer!,
                                  selected: category,
                                );
                                if (selected != null) {
                                  setSheetState(() => category = selected);
                                }
                              },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.line),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: 15,
                                color: c.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.isRu ? 'Все категории' : 'All categories',
                                  style: t.inter(
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: c.accent,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 17,
                                color: c.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => setSheetState(() {
                          mode = 'all';
                          retailer = null;
                          category = 'all';
                          brand = null;
                          sort = ProductSort.relevance;
                          photo = false;
                        }),
                        child: Text(s.isRu ? 'Сбросить' : 'Reset'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PrimaryButton(
                        label: s.isRu ? 'Применить' : 'Apply',
                        icon: Icons.check_rounded,
                        onTap: mode == 'retailer' && retailer == null
                            ? null
                            : () => Navigator.pop(sheetContext, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (applied != true || !mounted) return;
    setState(() {
      if (mode != 'all') {
        chip = mode;
      } else if (const {'meal', 'retailer'}.contains(chip)) {
        chip = 'all';
      }
      _retailer = mode == 'retailer' ? retailer : null;
      _retailerCategory = mode == 'retailer' ? category : 'all';
      _brand = brand;
      _productSort = sort;
      _onlyCompleteNutrition = false;
      _onlyPhoto = photo;
      _loadedLimit = 50;
    });
    _runSearch(query, online: _shouldSearchOnline);
  }

  Widget _chip(
    dynamic c,
    AppText t,
    String label,
    String value, {
    bool segmented = false,
  }) {
    final active = chip == value;
    return InkWell(
      onTap: () {
        setState(() {
          chip = value;
          _loadedLimit = 50;
          if (value != 'retailer') {
            _retailer = null;
            _retailerCategory = 'all';
            _productSort = ProductSort.relevance;
            _onlyCompleteNutrition = false;
            _onlyPhoto = false;
            _brand = null;
          }
        });
        _runSearch(query, online: _shouldSearchOnline);
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: segmented ? 4 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active
              ? (segmented ? c.card : c.accentSoft)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(segmented ? 11 : 10),
          border: segmented || !active
              ? null
              : Border.all(color: c.accent.withValues(alpha: .35)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.inter(
            size: segmented ? 10 : 9,
            weight: FontWeight.w600,
            color: active ? c.accent : c.fg2,
          ),
        ),
      ),
    );
  }

  String _searchHint(S s) {
    final retailer = _retailerOption;
    if (chip == 'retailer' && retailer != null) {
      final name = s.isRu ? retailer.$2 : retailer.$3;
      return s.isRu ? 'Найти товар в $name' : 'Find a product at $name';
    }
    return s.searchPh;
  }

  (String, String, String)? get _retailerOption {
    final id = _retailer;
    if (id == null) return null;
    for (final item in _retailerOptions) {
      if (item.$1 == id) return item;
    }
    return null;
  }

  String _sortLabel(ProductSort sort, S s) => switch (sort) {
    ProductSort.relevance => s.isRu ? 'По релевантности' : 'Relevance',
    ProductSort.recentlyUsed =>
      s.isRu ? 'Недавно использованные' : 'Recently used',
    ProductSort.name => s.isRu ? 'По названию' : 'By name',
  };

  Widget _emptyRetailerState(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
  ) => Center(
    key: const ValueKey('emptyRetailerCategory'),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.isRu
                ? 'В локальном каталоге сети пока нет таких товаров.\nПопробуйте общий поиск или сканирование штрихкода.'
                : 'The local retailer catalog has no matching products yet.\nTry general search or scan a barcode.',
            textAlign: TextAlign.center,
            style: t.inter(size: 12, color: c.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton(
                key: const ValueKey('retailerGeneralSearch'),
                onPressed: () {
                  setState(() {
                    chip = 'all';
                    _retailer = null;
                    _retailerCategory = 'all';
                  });
                  _runSearch(query, online: _shouldSearchOnline);
                  _searchFocus.requestFocus();
                },
                child: Text(s.isRu ? 'Общий поиск' : 'General search'),
              ),
              TextButton.icon(
                key: const ValueKey('retailerScan'),
                onPressed: () => _openScanner(context, s),
                icon: const Icon(Icons.document_scanner_outlined, size: 16),
                label: Text(s.isRu ? 'Сканировать' : 'Scan'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _catalogAction(
    dynamic c,
    AppText t, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool secondary = false,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: secondary ? 42 : 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: secondary ? c.card2.withValues(alpha: .72) : c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: secondary ? 17 : 19, color: c.accent),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: t.inter(size: 11, weight: FontWeight.w600),
            ),
          ),
          if (secondary) ...[
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 14, color: c.muted),
          ],
        ],
      ),
    ),
  );

  Future<void> _openScanner(BuildContext context, S s) async {
    final result = await Navigator.of(context).push<PackageScanResult>(
      MaterialPageRoute(
        builder: (_) => PackageScannerScreen(
          repository: _catalog,
          strings: s,
          retailerSlug: _retailer,
        ),
      ),
    );
    if (!context.mounted || result == null) return;
    if (result.action == PackageScanAction.manual) {
      await _showManualEntry(context);
    } else if (result.product != null) {
      var product = result.product!;
      if (_retailer != null) {
        final retailer = _retailerOption;
        if (retailer != null) {
          BalanceFeedbackHost.maybeOf(context)?.success(
            s.isRu
                ? 'Добавлено в вашу ${retailer.$2}'
                : 'Added to your ${retailer.$3}',
          );
          product = product.withRetailerTags({
            ...product.retailerTags,
            _retailer!,
          });
        }
      } else {
        final selected = await _askScannedRetailer(context, s);
        if (selected != null) {
          await _catalog.rememberRetailer(
            product,
            selected,
            source: RetailerRelationSource.userScan,
            userConfirmed: true,
          );
          product = product.withRetailerTags({
            ...product.retailerTags,
            selected,
          });
        }
      }
      if (!context.mounted) return;
      await _showPortionSheet(
        context,
        UnifiedFoodItem.fromProduct(product),
        product.nutritionBasis == FoodNutritionBasis.perItem
            ? 1
            : product.servingSize ?? 100,
      );
    }
  }

  Future<String?> _askScannedRetailer(BuildContext context, S s) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.isRu ? 'Где вы нашли этот товар?' : 'Where did you find it?',
                style: AppText(
                  context.colors,
                ).fraunces(size: 22, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final retailer in _retailerOptions.take(2))
                    ActionChip(
                      label: Text(s.isRu ? retailer.$2 : retailer.$3),
                      onPressed: () => Navigator.pop(ctx, retailer.$1),
                    ),
                  ActionChip(
                    label: Text(s.isRu ? 'Другой' : 'Other'),
                    onPressed: () => Navigator.pop(ctx, '__other__'),
                  ),
                  ActionChip(
                    label: Text(s.isRu ? 'Не указывать' : 'Skip'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != '__other__' || !context.mounted) return selected;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final retailer in _retailerOptions.skip(2))
                ActionChip(
                  label: Text(s.isRu ? retailer.$2 : retailer.$3),
                  onPressed: () => Navigator.pop(ctx, retailer.$1),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mealPicker(dynamic c, AppText t, S s) {
    final items = [
      (MealType.breakfast, s.breakfast),
      (MealType.lunch, s.lunch),
      (MealType.dinner, s.dinner),
      (MealType.snack, s.snack),
    ];
    return Container(
      key: const ValueKey('mealSelector'),
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: items.map((it) {
          final active = targetMeal == it.$1;
          return Expanded(
            child: InkWell(
              key: ValueKey('mealTarget-${it.$1.name}'),
              onTap: () {
                if (targetMeal == it.$1) return;
                setState(() => targetMeal = it.$1);
                _runSearch(query, online: false);
              },
              borderRadius: BorderRadius.circular(11),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? c.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    it.$2,
                    style: t.mono(size: 9, color: active ? c.accent : c.muted),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _foodResultRow(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    UnifiedFoodItem item, {
    bool generalFallback = false,
  }) {
    const defaultGrams = 100.0;
    final kcal = item.nutrition.calories?.round();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          FoodThumb(
            seed: item.colorSeed,
            size: 40,
            radius: 12,
            imageUrl: item.imageUrl,
            imageBytes: item.imageBytes,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: t.inter(
                    size: 13,
                    weight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  s.isRu ? item.labelRu : item.labelEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.mono(
                    size: 8,
                    color: item.estimated ? c.accent2 : c.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.hasCompleteNutrition
                      ? s.isRu
                            ? 'Б${item.proteinPer100g.round()} Ж${item.fatPer100g.round()} У${item.carbsPer100g.round()}'
                            : 'P${item.proteinPer100g.round()} F${item.fatPer100g.round()} C${item.carbsPer100g.round()}'
                      : (s.isRu ? 'Нет полных данных' : 'Incomplete data'),
                  style: t.mono(size: 9),
                ),
                if (chip == 'retailer' && item.product != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    generalFallback
                        ? (s.isRu ? 'Общий каталог' : 'General catalog')
                        : (s.isRu
                              ? _retailerOption?.$2 ?? ''
                              : _retailerOption?.$3 ?? ''),
                    style: t.mono(size: 7, color: c.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      kcal?.toString() ?? '—',
                      style: t.fraunces(size: 18, weight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                InkWell(
                  onTap: () => _toggleFavorite(item),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey('favoriteStar-${item.id}-${item.favorite}'),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      builder: (_, progress, child) {
                        final scale = progress < .58
                            ? .9 + .15 * (progress / .58)
                            : 1.05 - .05 * ((progress - .58) / .42);
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Icon(
                        item.favorite ? Icons.star_rounded : Icons.star_border,
                        size: 18,
                        color: item.favorite ? c.champagne : c.muted,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: item.nutrition.calories == null
                      ? null
                      : () => _showPortionSheet(
                          context,
                          item,
                          item.suggestedAmount > 0
                              ? item.suggestedAmount
                              : defaultGrams,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.fg,
                    ),
                    child: Icon(Icons.add_rounded, size: 18, color: c.surface),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPortionSheet(
    BuildContext context,
    UnifiedFoodItem item,
    double initialGrams,
  ) async {
    final c = context.colors;
    final s = S(context.read<SettingsProvider>().lang);
    final controller = TextEditingController(
      text: initialGrams.round().toString(),
    );
    int selected = initialGrams.round();
    double? grams;
    try {
      grams = await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            final t = AppText(c);
            final value = double.tryParse(
              controller.text.trim().replaceAll(',', '.'),
            );
            final valid = value != null && value >= 1 && value <= 5000;
            final calculated = valid
                ? item.nutritionForAmount(value)
                : const NutritionValues();
            const presets = [50, 100, 150, 200, 250];
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: c.line2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        FoodThumb(
                          seed: item.colorSeed,
                          size: 48,
                          radius: 14,
                          imageUrl: item.imageUrl,
                          imageBytes: item.imageBytes,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: t.fraunces(
                                  size: 19,
                                  weight: FontWeight.w700,
                                  height: 1.12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.isRu
                                    ? 'Настрой порцию'
                                    : 'Adjust serving size',
                                style: t.inter(
                                  size: 12,
                                  color: c.muted,
                                  height: 1.3,
                                ),
                              ),
                              if (item.estimated)
                                Text(
                                  s.isRu
                                      ? 'Примерное значение по типовому рецепту'
                                      : 'Estimated from a typical recipe',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.mono(size: 7, color: c.muted),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (item.product != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const ValueKey('productRetailers'),
                          onPressed: () =>
                              _showRetailerAssignment(ctx, item.product!, s),
                          icon: const Icon(Icons.storefront_outlined, size: 16),
                          label: Text(s.isRu ? 'Магазины' : 'Retailers'),
                        ),
                      ),
                    const SizedBox(height: 18),
                    PortionPresetRow(
                      values: presets,
                      selected: selected,
                      unit: s.isRu ? 'г' : 'g',
                      onSelected: (g) {
                        controller.text = '$g';
                        setSheetState(() => selected = g);
                      },
                    ),
                    const SizedBox(height: 12),
                    LabeledNumberField(
                      label: s.isRu ? 'Вес порции' : 'Serving weight',
                      controller: controller,
                      unit: s.isRu ? 'г' : 'g',
                      onChanged: (raw) => setSheetState(
                        () => selected = int.tryParse(raw) ?? -1,
                      ),
                      errorText: controller.text.isNotEmpty && !valid
                          ? (s.isRu ? 'От 1 до 5000 г' : '1–5000 g')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: c.line.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          _nutritionPreview(
                            t,
                            s.kcalLbl,
                            calculated.calories?.round().toString() ?? '—',
                          ),
                          _nutritionPreview(
                            t,
                            s.isRu ? 'белки' : 'protein',
                            calculated.protein == null
                                ? '—'
                                : '${calculated.protein!.toStringAsFixed(1)} г',
                          ),
                          _nutritionPreview(
                            t,
                            s.isRu ? 'жиры' : 'fat',
                            calculated.fat == null
                                ? '—'
                                : '${calculated.fat!.toStringAsFixed(1)} г',
                          ),
                          _nutritionPreview(
                            t,
                            s.isRu ? 'углев.' : 'carbs',
                            calculated.carbs == null
                                ? '—'
                                : '${calculated.carbs!.toStringAsFixed(1)} г',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: s.isRu ? 'Добавить в дневник' : 'Add to diary',
                      icon: Icons.check_rounded,
                      onTap: valid ? () => Navigator.of(ctx).pop(value) : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      controller.dispose();
    }
    if (grams != null && context.mounted) _addItem(context, item, grams);
  }

  Future<void> _showRetailerAssignment(
    BuildContext context,
    FoodProduct product,
    S s,
  ) async {
    final selected = product.retailerTags.map(canonicalRetailerId).toSet();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isRu ? 'Магазины' : 'Retailers',
                  style: AppText(
                    context.colors,
                  ).fraunces(size: 22, weight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final retailer in _retailerOptions)
                      FilterChip(
                        label: Text(s.isRu ? retailer.$2 : retailer.$3),
                        selected: selected.contains(retailer.$1),
                        onSelected: selected.contains(retailer.$1)
                            ? null
                            : (_) async {
                                await _catalog.rememberRetailer(
                                  product,
                                  retailer.$1,
                                  source: RetailerRelationSource.userManual,
                                  userConfirmed: true,
                                );
                                selected.add(retailer.$1);
                                setSheetState(() {});
                                if (mounted) {
                                  unawaited(_runSearch(query, online: false));
                                }
                              },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nutritionPreview(AppText t, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: t.inter(size: 11, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: t.mono(size: 7), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _showManualEntry(BuildContext context) async {
    final s = S(context.read<SettingsProvider>().lang);
    final c = context.colors;
    final controllers = List.generate(6, (_) => TextEditingController());
    final labels = s.isRu
        ? ['Название', 'Граммы', 'Ккал', 'Белки', 'Жиры', 'Углеводы']
        : ['Name', 'Grams', 'Calories', 'Protein', 'Fat', 'Carbs'];
    FoodProduct? product;
    double? grams;
    try {
      product = await showModalBottomSheet<FoodProduct>(
        context: context,
        isScrollControlled: true,
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            double? number(int index) => double.tryParse(
              controllers[index].text.trim().replaceAll(',', '.'),
            );
            grams = number(1);
            final values = [for (var i = 2; i < 6; i++) number(i)];
            final valid =
                controllers.first.text.trim().isNotEmpty &&
                grams != null &&
                grams! >= 1 &&
                grams! <= 5000 &&
                values.every(
                  (value) => value != null && value >= 0 && value <= 10000,
                );
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  MediaQuery.viewInsetsOf(ctx).bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.isRu ? 'Добавить вручную' : 'Manual entry',
                      style: AppText(
                        c,
                      ).fraunces(size: 22, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < controllers.length; i++) ...[
                      TextField(
                        controller: controllers[i],
                        keyboardType: i == 0
                            ? TextInputType.text
                            : const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                        textInputAction: i == controllers.length - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onSubmitted: i == controllers.length - 1
                            ? (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus()
                            : null,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(labelText: labels[i]),
                      ),
                      const SizedBox(height: 6),
                    ],
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: s.isRu ? 'Сохранить и добавить' : 'Save and add',
                      icon: Icons.check_rounded,
                      onTap: valid
                          ? () {
                              final factor = 100 / grams!;
                              Navigator.of(ctx).pop(
                                FoodProduct(
                                  id: 'manual:${DateTime.now().microsecondsSinceEpoch}',
                                  name: controllers[0].text.trim(),
                                  nutrition: NutritionValues(
                                    calories: values[0]! * factor,
                                    protein: values[1]! * factor,
                                    fat: values[2]! * factor,
                                    carbs: values[3]! * factor,
                                  ),
                                  source: FoodProductSource.manual,
                                  nutritionSource: FoodProductSource.manual,
                                  nutritionBasis: FoodNutritionBasis.per100g,
                                  nutritionBasisAmount: 100,
                                  localCategory: 'recent',
                                  colorSeed: controllers[0].text.hashCode,
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
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    if (product == null || grams == null || !context.mounted) return;
    await _catalog.saveManual(product);
    if (!context.mounted) return;
    _addItem(context, UnifiedFoodItem.fromProduct(product), grams!);
    _runSearch(query, online: false);
  }

  Future<void> _addItem(
    BuildContext context,
    UnifiedFoodItem item,
    double grams,
  ) async {
    final data = context.read<AppDataProvider>();
    final nutrition = item.nutritionForAmount(grams);
    if (nutrition.calories == null) return;
    final now = DateTime.now();
    final entryTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );
    final entry = FoodEntry(
      id: newEntryId(),
      name: item.name,
      grams: grams,
      kcal: nutrition.calories!.round(),
      proteinG: nutrition.protein ?? 0,
      fatG: nutrition.fat ?? 0,
      carbsG: nutrition.carbs ?? 0,
      meal: targetMeal,
      time: entryTime,
      colorSeed: item.colorSeed,
      productId: item.id,
      productVersion: item.sourceRevision,
      productSource: item.product?.source.name ?? item.type.name,
      sourceType: item.diarySourceType,
      recipeId: item.recipe?.id,
      recipeVersion: item.recipe?.currentVersion.version,
    );
    await data.addFoodForDate(entry, localDateKey(widget.selectedDate));
    if (!context.mounted) return;
    if (item.product != null) {
      _catalog.markUsed(item.product!);
    } else if (item.recipe != null) {
      data.markRecipeUsed(item.recipe!.id);
    } else if (item.dish != null) {
      _dishCatalog?.markUsed(item.dish!.id);
    }
    unawaited(BalanceMotion.selection());
    final onAdded = widget.onAdded;
    if (onAdded != null) {
      onAdded(entry);
    } else {
      final s = S(context.read<SettingsProvider>().lang);
      BalanceFeedbackHost.maybeOf(
        context,
      )?.success(s.isRu ? 'Еда добавлена' : 'Food added');
    }
  }

  Future<void> _openMyRecipes(BuildContext context) async {
    final recipe = await Navigator.of(context).push<UserRecipe>(
      MaterialPageRoute(
        builder: (_) => MyRecipesScreen(
          catalog: _catalog,
          scannerStrings: S(context.read<SettingsProvider>().lang),
        ),
      ),
    );
    if (recipe != null && context.mounted) {
      final item = UnifiedFoodItem.fromRecipe(recipe);
      await _showPortionSheet(context, item, item.suggestedAmount);
    }
    if (mounted) await _runSearch(query, online: false);
  }

  Future<void> _toggleFavorite(UnifiedFoodItem item) async {
    final favorite = !item.favorite;
    setState(() {
      final replacement = _withFavorite(item, favorite);
      _results = [
        for (final result in _results)
          if (result.id != item.id)
            result
          else if (chip != 'favorite' || favorite)
            replacement,
      ];
    });
    if (item.product != null) {
      await _catalog.setFavorite(item.product!, favorite);
    } else if (item.recipe != null && mounted) {
      await context.read<AppDataProvider>().setRecipeFavorite(
        item.recipe!.id,
        favorite,
      );
    } else if (item.dish != null) {
      await _dishCatalog?.setFavorite(item.dish!.id, favorite);
    }
    if (mounted) await _runSearch(query, online: false);
  }

  UnifiedFoodItem _withFavorite(UnifiedFoodItem item, bool favorite) {
    if (item.product case final product?) {
      return UnifiedFoodItem.fromProduct(product.withFavorite(favorite));
    }
    if (item.recipe case final recipe?) {
      return UnifiedFoodItem.fromRecipe(recipe.copyWith(favorite: favorite));
    }
    if (item.dish case final dish?) {
      return UnifiedFoodItem.fromDish(dish.copyWith(favorite: favorite));
    }
    return item;
  }
}
