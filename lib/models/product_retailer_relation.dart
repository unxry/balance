enum RetailerRelationSource {
  offStoreTag,
  officialFeed,
  userScan,
  userManual,
  legacyImport,
}

extension RetailerRelationSourceStorage on RetailerRelationSource {
  String get storageValue => switch (this) {
    RetailerRelationSource.offStoreTag => 'off_store_tag',
    RetailerRelationSource.officialFeed => 'official_feed',
    RetailerRelationSource.userScan => 'user_scan',
    RetailerRelationSource.userManual => 'user_manual',
    RetailerRelationSource.legacyImport => 'legacy_import',
  };

  static RetailerRelationSource parse(Object? value) => switch (value) {
    'off_store_tag' || 'offStoreTag' => RetailerRelationSource.offStoreTag,
    'official_feed' || 'officialFeed' => RetailerRelationSource.officialFeed,
    'user_scan' || 'userScan' => RetailerRelationSource.userScan,
    'user_manual' || 'userManual' => RetailerRelationSource.userManual,
    _ => RetailerRelationSource.legacyImport,
  };
}

class ProductRetailerRelation {
  final String productId;
  final String retailerSlug;
  final RetailerRelationSource source;
  final double confidence;
  final bool userConfirmed;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  ProductRetailerRelation({
    required this.productId,
    required this.retailerSlug,
    required this.source,
    required this.confidence,
    required this.userConfirmed,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
  }) : firstSeenAt = (firstSeenAt ?? DateTime.now()).toUtc(),
       lastSeenAt = (lastSeenAt ?? DateTime.now()).toUtc() {
    if (productId.isEmpty || retailerSlug.isEmpty) {
      throw const FormatException('Product and retailer are required');
    }
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw const FormatException('Invalid retailer confidence');
    }
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'retailerSlug': retailerSlug,
    'source': source.storageValue,
    'confidence': confidence,
    'userConfirmed': userConfirmed,
    'firstSeenAt': firstSeenAt.toIso8601String(),
    'lastSeenAt': lastSeenAt.toIso8601String(),
  };

  factory ProductRetailerRelation.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid retailer relation');
    final map = Map<dynamic, dynamic>.from(value);
    final source = RetailerRelationSourceStorage.parse(map['source']);
    return ProductRetailerRelation(
      productId: map['productId'] as String,
      retailerSlug: map['retailerSlug'] as String,
      source: source,
      confidence: (map['confidence'] as num).toDouble(),
      userConfirmed: map['userConfirmed'] == true,
      firstSeenAt: DateTime.parse(map['firstSeenAt'] as String),
      lastSeenAt: DateTime.parse(map['lastSeenAt'] as String),
    );
  }
}
