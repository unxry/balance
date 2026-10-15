import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/dish.dart';
import '../models/food_product.dart';

class DishCatalogRepository {
  static void Function()? onUserMutation;
  static const databaseName = 'balance_dish_catalog.db';
  static const schemaVersion = 1;
  static const seedAsset = 'assets/catalog/dishes_v1.tsv';
  static const seedVersion = 2;

  final Database database;

  const DishCatalogRepository._(this.database);

  static Future<List<Map<String, Object?>>> readUserBackup() async {
    final path = p.join(await getDatabasesPath(), databaseName);
    if (!await File(path).exists()) return [];
    final database = await openDatabase(
      path,
      readOnly: true,
      singleInstance: false,
    );
    try {
      return await database.query(
        'dishes',
        columns: ['id', 'favorite', 'use_count', 'last_used_at'],
        where: 'favorite = 1 OR use_count > 0',
        orderBy: 'id',
      );
    } finally {
      await database.close();
    }
  }

  static Future<DishCatalogRepository> open({
    DatabaseFactory? factory,
    String? databasePath,
    List<Dish>? seed,
  }) async {
    final selectedFactory = factory ?? databaseFactory;
    final path =
        databasePath ??
        p.join(await selectedFactory.getDatabasesPath(), databaseName);
    final database = await selectedFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, _) => _createSchema(db),
      ),
    );
    final repository = DishCatalogRepository._(database);
    await repository._seedIfNeeded(seed ?? await _loadAssetSeed());
    return repository;
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE dishes (
        id TEXT PRIMARY KEY,
        normalized_name TEXT NOT NULL,
        cuisine TEXT NOT NULL,
        category TEXT NOT NULL,
        favorite INTEGER NOT NULL DEFAULT 0,
        use_count INTEGER NOT NULL DEFAULT 0,
        last_used_at INTEGER,
        payload_json TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX dishes_cuisine_idx ON dishes(cuisine)');
    await db.execute('CREATE INDEX dishes_category_idx ON dishes(category)');
    await db.execute(
      'CREATE INDEX dishes_recent_idx ON dishes(last_used_at DESC)',
    );
    await db.execute('''
      CREATE VIRTUAL TABLE dish_search USING fts5(
        id UNINDEXED,
        normalized_name,
        search_text,
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');
    await db.execute('''
      CREATE TABLE dish_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<List<Dish>> _loadAssetSeed() async {
    final text = await rootBundle.loadString(seedAsset);
    return parseDishSeed(text);
  }

  static List<Dish> parseDishSeed(String text) {
    final dishes = <Dish>[];
    for (final raw in const LineSplitter().convert(text)) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('\t');
      if (parts.length < 10) continue;
      try {
        dishes.add(
          Dish(
            id: parts[0],
            name: parts[1],
            cuisine: DishCuisine.values.byName(parts[2]),
            category: DishCategory.values.byName(parts[3]),
            subcategory: parts[4].isEmpty ? null : parts[4],
            variant: parts[5].isEmpty ? null : parts[5],
            nutritionPer100g: NutritionValues(
              calories: double.parse(parts[6]),
              protein: double.parse(parts[7]),
              fat: double.parse(parts[8]),
              carbs: double.parse(parts[9]),
            ),
            typicalServingGrams: parts.length > 10
                ? double.parse(parts[10])
                : 250,
            dataSource: 'Balance curated typical recipe estimates v1',
            dataQuality: DishDataQuality.curatedEstimate,
            isEstimated: true,
          ),
        );
      } catch (_) {
        // A malformed seed row must not prevent the app from opening.
      }
    }
    return dishes;
  }

  Future<void> _seedIfNeeded(List<Dish> dishes) async {
    final versionRows = await database.query(
      'dish_metadata',
      where: 'key = ?',
      whereArgs: ['seedVersion'],
      limit: 1,
    );
    final current = versionRows.isEmpty
        ? 0
        : int.tryParse(versionRows.first['value']?.toString() ?? '') ?? 0;
    if (current >= seedVersion) return;
    await importCatalog(
      dishes,
      versionKey: 'seedVersion',
      version: '$seedVersion',
    );
  }

  /// Idempotent import entry point for future downloaded catalog revisions.
  /// Existing favorites and usage counters are kept by the upsert.
  Future<void> importCatalog(
    Iterable<Dish> dishes, {
    String versionKey = 'remoteCatalogVersion',
    required String version,
  }) async {
    await database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final dish in dishes) {
        batch.rawInsert(
          '''INSERT INTO dishes(id, normalized_name, cuisine, category, payload_json)
             VALUES (?, ?, ?, ?, ?)
             ON CONFLICT(id) DO UPDATE SET
               normalized_name=excluded.normalized_name,
               cuisine=excluded.cuisine,
               category=excluded.category,
               payload_json=excluded.payload_json''',
          [
            dish.id,
            dish.normalizedName,
            dish.cuisine.name,
            dish.category.name,
            jsonEncode(dish.toJson()),
          ],
        );
      }
      await batch.commit(noResult: true);
      await transaction.delete('dish_search');
      await transaction.execute('''
        INSERT INTO dish_search(id, normalized_name, search_text)
        SELECT id, normalized_name, normalized_name || ' ' || cuisine || ' ' || category
        FROM dishes
      ''');
      await transaction.insert('dish_metadata', {
        'key': versionKey,
        'value': version,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<Dish>> search(
    String query, {
    int limit = 20,
    int offset = 0,
    DishCategory? category,
    DishCuisine? cuisine,
    bool favoritesOnly = false,
  }) async {
    final normalized = normalizeFoodText(query);
    final where = <String>[];
    final args = <Object?>[];
    if (category != null) {
      where.add('d.category = ?');
      args.add(category.name);
    }
    if (cuisine != null) {
      where.add('d.cuisine = ?');
      args.add(cuisine.name);
    }
    if (favoritesOnly) where.add('d.favorite = 1');
    if (normalized.isEmpty) where.add('(d.favorite = 1 OR d.use_count > 0)');
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = normalized.isEmpty
        ? await database.rawQuery(
            'SELECT d.payload_json, d.favorite FROM dishes d $whereSql '
            'ORDER BY d.favorite DESC, d.last_used_at DESC LIMIT ? OFFSET ?',
            [...args, limit.clamp(1, 100), offset.clamp(0, 1000000)],
          )
        : await database.rawQuery(
            'SELECT d.payload_json, d.favorite FROM dish_search f '
            'JOIN dishes d ON d.id = f.id $whereSql '
            '${whereSql.isEmpty ? 'WHERE' : 'AND'} dish_search MATCH ? '
            'ORDER BY bm25(dish_search), d.favorite DESC, d.use_count DESC '
            'LIMIT ? OFFSET ?',
            [
              ...args,
              _ftsQuery(normalized),
              limit.clamp(1, 100),
              offset.clamp(0, 1000000),
            ],
          );
    return rows.map(_fromRow).whereType<Dish>().toList();
  }

  Future<void> markUsed(String id) async {
    await database.rawUpdate(
      'UPDATE dishes SET use_count = use_count + 1, last_used_at = ? WHERE id = ?',
      [DateTime.now().toUtc().millisecondsSinceEpoch, id],
    );
  }

  Future<void> setFavorite(String id, bool favorite) async {
    await database.rawUpdate('UPDATE dishes SET favorite = ? WHERE id = ?', [
      favorite ? 1 : 0,
      id,
    ]);
    onUserMutation?.call();
  }

  Future<int> usageCount(String id) async {
    final rows = await database.query(
      'dishes',
      columns: ['use_count'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? 0 : (rows.first['use_count'] as num).toInt();
  }

  Future<int> count() async =>
      Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM dishes'),
      ) ??
      0;

  Future<void> close() => database.close();

  static String _ftsQuery(String normalized) => normalized
      .split(' ')
      .where((token) => token.isNotEmpty)
      .map((token) => '"${token.replaceAll('"', '')}"*')
      .join(' AND ');

  static Dish? _fromRow(Map<String, Object?> row) {
    try {
      final dish = Dish.fromJson(jsonDecode(row['payload_json'] as String));
      return dish.copyWith(favorite: row['favorite'] == 1);
    } catch (_) {
      return null;
    }
  }
}
