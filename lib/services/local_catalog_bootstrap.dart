import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/food_product.dart';
import 'sqlite_product_cache.dart';

class LocalCatalogBootstrapResult {
  final String version;
  final int importedProducts;
  final Duration elapsed;
  final bool skipped;

  const LocalCatalogBootstrapResult({
    required this.version,
    required this.importedProducts,
    required this.elapsed,
    required this.skipped,
  });
}

class LocalCatalogBootstrap {
  static const assetPath = 'assets/catalog/balance_ru_catalog.db.gz';
  static const batchSize = 2000;

  final SqliteProductCache cache;
  final DatabaseFactory factory;
  final Future<ByteData> Function(String asset) loadAsset;
  final String? bootstrapDatabasePath;

  LocalCatalogBootstrap({
    required this.cache,
    DatabaseFactory? factory,
    Future<ByteData> Function(String asset)? loadAsset,
    this.bootstrapDatabasePath,
  }) : factory = factory ?? databaseFactory,
       loadAsset = loadAsset ?? rootBundle.load;

  Future<LocalCatalogBootstrapResult> ensureImported() async {
    final stopwatch = Stopwatch()..start();
    final sourcePath = await _sourcePath();
    final removeSource = bootstrapDatabasePath == null;
    Database? source;
    try {
      source = await factory.openDatabase(
        sourcePath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final metadata = await source.query(
        'bootstrap_meta',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: ['version'],
        limit: 1,
      );
      if (metadata.isEmpty || metadata.first['value'] is! String) {
        throw const FormatException('Invalid local catalog bootstrap');
      }
      final version = metadata.first['value'] as String;
      if (await cache.readBootstrapVersion() == version) {
        return LocalCatalogBootstrapResult(
          version: version,
          importedProducts: 0,
          elapsed: stopwatch.elapsed,
          skipped: true,
        );
      }

      var offset = 0;
      var imported = 0;
      while (true) {
        final rows = await source.query(
          'bootstrap_products',
          columns: ['payload_json'],
          orderBy: 'product_id',
          limit: batchSize,
          offset: offset,
        );
        if (rows.isEmpty) break;
        final products = rows
            .map((row) => row['payload_json'])
            .whereType<String>()
            .map(jsonDecode)
            .map(FoodProduct.tryFromJson)
            .whereType<FoodProduct>()
            .toList();
        await cache.writeAll(products, rebuildSearchIndex: false);
        imported += products.length;
        offset += rows.length;
        await Future<void>.delayed(Duration.zero);
      }
      await cache.rebuildSearchIndex();
      await cache.writeBootstrapVersion(version);
      assert(() {
        debugPrint(
          '[local-catalog] version=$version imported=$imported '
          'elapsedMs=${stopwatch.elapsedMilliseconds}',
        );
        return true;
      }());
      return LocalCatalogBootstrapResult(
        version: version,
        importedProducts: imported,
        elapsed: stopwatch.elapsed,
        skipped: false,
      );
    } finally {
      await source?.close();
      if (removeSource) {
        final file = File(sourcePath);
        if (await file.exists()) await file.delete();
      }
    }
  }

  Future<String> _sourcePath() async {
    if (bootstrapDatabasePath case final path?) return path;
    final data = await loadAsset(assetPath);
    final path = p.join(
      await factory.getDatabasesPath(),
      'balance_catalog_bootstrap.tmp.db',
    );
    await File(path).parent.create(recursive: true);
    final compressed = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await Stream<List<int>>.value(
      compressed,
    ).transform(gzip.decoder).pipe(File(path).openWrite());
    return path;
  }
}
