import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../models/product_retailer_relation.dart';
import 'local_store.dart';

/// Versioned, local-only backup format. It is intentionally independent from
/// the product cache, which can always be rebuilt from catalog sources.
class LocalBackupService {
  static const backupFormatVersion = 1;

  const LocalBackupService();

  String exportJson({
    required Box<dynamic> user,
    required Box<dynamic> food,
    required Box<dynamic> weight,
    Box<dynamic>? achievements,
    Map<String, dynamic> settings = const {},
    Iterable<String> favoriteProductIds = const [],
    Iterable<ProductRetailerRelation> productRetailerRelations = const [],
    String appVersion = const String.fromEnvironment(
      'BALANCE_APP_VERSION',
      defaultValue: '1.0.0+19',
    ),
  }) {
    final favorites = favoriteProductIds.toSet().toList()..sort();
    final retailerRelations = productRetailerRelations
        .map((relation) => relation.toJson())
        .toList();
    final createdAt = DateTime.now().toUtc().toIso8601String();
    return jsonEncode({
      'format': 'balance-local-backup',
      'backupVersion': backupFormatVersion,
      'storageSchemaVersion': LocalStore.schemaVersion,
      'exportedAt': createdAt,
      'createdAt': createdAt,
      'appVersion': appVersion,
      'boxes': {
        LocalStore.userBox: _encode(user.toMap()),
        LocalStore.foodBox: _encode(food.toMap()),
        LocalStore.weightBox: _encode(weight.toMap()),
        if (achievements != null)
          LocalStore.achievementsBox: _encode(achievements.toMap()),
      },
      'settings': _encode(settings),
      'catalogFavorites': favorites,
      'catalogRetailerRelations': retailerRelations,
    });
  }

  static String encodeSnapshot(Map<String, dynamic> snapshot) {
    final service = LocalBackupService();
    final products = snapshot['catalogUserProducts'];
    if (products is List) {
      snapshot['catalogUserProducts'] = products
          .map((product) => product is String ? jsonDecode(product) : product)
          .toList();
    }
    final json = jsonEncode(service._encode(snapshot));
    service.inspectJson(json);
    return json;
  }

  BackupInspection inspectJson(String json) {
    final decoded = _validatedBackup(json);
    final boxes = Map<dynamic, dynamic>.from(decoded['boxes'] as Map);
    final counts = <String, int>{};
    for (final name in [
      LocalStore.userBox,
      LocalStore.foodBox,
      LocalStore.weightBox,
      LocalStore.achievementsBox,
    ]) {
      final value = boxes[name];
      if (value == null) continue;
      final box = _decode(value);
      if (box is! Map) throw FormatException('Invalid backup box: $name');
      counts[name] = box.length;
    }
    final favorites = decoded['catalogFavorites'];
    if (favorites != null && favorites is! List) {
      throw const FormatException('Invalid catalog favorites');
    }
    final retailerRelations = decoded['catalogRetailerRelations'];
    if (retailerRelations != null && retailerRelations is! List) {
      throw const FormatException('Invalid catalog retailer relations');
    }
    return BackupInspection(
      backupVersion: decoded['backupVersion'] as int,
      storageSchemaVersion: decoded['storageSchemaVersion'] as int,
      exportedAt: DateTime.parse(decoded['exportedAt'] as String),
      recordCounts: counts,
      settingsCount: decoded['settings'] is Map
          ? (decoded['settings'] as Map).length
          : 0,
      productFavoriteCount: favorites is List ? favorites.length : 0,
      productRetailerRelationCount: retailerRelations is List
          ? retailerRelations.length
          : 0,
    );
  }

  Future<void> restoreJson(
    String json, {
    required Box<dynamic> user,
    required Box<dynamic> food,
    required Box<dynamic> weight,
    Box<dynamic>? achievements,
    Future<void> Function(Map<String, dynamic> settings)? restoreSettings,
    Future<void> Function(List<String> productIds)? restoreProductFavorites,
    Future<void> Function(List<ProductRetailerRelation> relations)?
    restoreProductRetailerRelations,
  }) async {
    final decoded = _validatedBackup(json);
    final boxes = Map<dynamic, dynamic>.from(decoded['boxes'] as Map);
    await _mergeBox(user, boxes[LocalStore.userBox]);
    await _mergeBox(food, boxes[LocalStore.foodBox]);
    await _mergeBox(weight, boxes[LocalStore.weightBox]);
    if (achievements != null) {
      await _mergeBox(achievements, boxes[LocalStore.achievementsBox]);
    }
    if (restoreSettings != null && decoded['settings'] is Map) {
      await restoreSettings(
        Map<String, dynamic>.from(_decode(decoded['settings']) as Map),
      );
    }
    if (restoreProductFavorites != null) {
      final favorites = decoded['catalogFavorites'];
      if (favorites != null && favorites is! List) {
        throw const FormatException('Invalid catalog favorites');
      }
      await restoreProductFavorites(
        favorites is List ? favorites.whereType<String>().toList() : const [],
      );
    }
    if (restoreProductRetailerRelations != null) {
      final relations = decoded['catalogRetailerRelations'];
      if (relations != null && relations is! List) {
        throw const FormatException('Invalid catalog retailer relations');
      }
      await restoreProductRetailerRelations(
        relations is List
            ? relations.map(ProductRetailerRelation.fromJson).toList()
            : const [],
      );
    }
  }

  Map<dynamic, dynamic> _validatedBackup(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map ||
        decoded['format'] != 'balance-local-backup' ||
        decoded['backupVersion'] != backupFormatVersion ||
        decoded['storageSchemaVersion'] is! int ||
        decoded['exportedAt'] is! String ||
        decoded['boxes'] is! Map) {
      throw const FormatException('Unsupported Balance backup');
    }
    DateTime.parse(decoded['exportedAt'] as String);
    return decoded;
  }

  Future<void> _mergeBox(Box<dynamic> box, Object? encoded) async {
    final decoded = _decode(encoded);
    if (decoded is! Map) throw const FormatException('Invalid backup box');
    await box.putAll(Map<dynamic, dynamic>.from(decoded));
  }

  Object? _encode(Object? value) {
    if (value is Uint8List) {
      return {'__balanceType': 'bytes', 'value': base64Encode(value)};
    }
    if (value is DateTime) {
      return {
        '__balanceType': 'dateTime',
        'value': value.toUtc().toIso8601String(),
      };
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), _encode(item)));
    }
    if (value is Iterable) return value.map(_encode).toList();
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    throw FormatException('Unsupported backup value: ${value.runtimeType}');
  }

  Object? _decode(Object? value) {
    if (value is List) return value.map(_decode).toList();
    if (value is Map) {
      if (value['__balanceType'] == 'bytes' && value['value'] is String) {
        return Uint8List.fromList(base64Decode(value['value'] as String));
      }
      if (value['__balanceType'] == 'dateTime' && value['value'] is String) {
        return DateTime.parse(value['value'] as String);
      }
      return value.map((key, item) => MapEntry(key, _decode(item)));
    }
    return value;
  }
}

class BackupInspection {
  final int backupVersion;
  final int storageSchemaVersion;
  final DateTime exportedAt;
  final Map<String, int> recordCounts;
  final int settingsCount;
  final int productFavoriteCount;
  final int productRetailerRelationCount;

  const BackupInspection({
    required this.backupVersion,
    required this.storageSchemaVersion,
    required this.exportedAt,
    required this.recordCounts,
    required this.settingsCount,
    required this.productFavoriteCount,
    required this.productRetailerRelationCount,
  });
}
