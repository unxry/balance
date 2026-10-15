import 'package:hive_flutter/hive_flutter.dart';

/// Thin wrapper around Hive boxes used across the app.
class LocalStore {
  static const schemaVersion = 6;
  static const schemaVersionKey = 'storageSchemaVersion';
  static const userBox = 'balance_user';
  static const foodBox = 'balance_food';
  static const weightBox = 'balance_weight';
  static const achievementsBox = 'balance_achievements';

  static Future<void> init() async {
    await Hive.initFlutter();
    final user = await Hive.openBox<dynamic>(userBox);
    final food = await Hive.openBox<dynamic>(foodBox);
    final weight = await Hive.openBox<dynamic>(weightBox);
    await Hive.openBox(achievementsBox);
    await migrateBoxes(user: user, food: food, weight: weight);
  }

  /// Additive migrations only: no user box is cleared or recreated.
  static Future<void> migrateBoxes({
    required Box<dynamic> user,
    required Box<dynamic> food,
    required Box<dynamic> weight,
  }) async {
    final stored = user.get(schemaVersionKey);
    var version = stored is num ? stored.toInt() : 1;
    if (version > schemaVersion) return;

    if (version < 2) {
      final dayKey = food.get('dayKey') ?? food.get('today_date');
      final legacyFood = food.get('today');
      final days = _mapCopy(food.get('days'));
      if (dayKey is String && legacyFood is List && legacyFood.isNotEmpty) {
        days.putIfAbsent(dayKey, () => List<dynamic>.from(legacyFood));
      }
      await food.put('days', days);

      final waterDate = user.get('waterDate');
      final water = user.get('water');
      final waterHistory = _mapCopy(user.get('waterHistory'));
      if (waterDate is String && water is num && water.isFinite) {
        waterHistory.putIfAbsent(waterDate, () => water.toDouble());
      }
      await user.put('waterHistory', waterHistory);
      version = 2;
      await user.put(schemaVersionKey, version);
    }

    if (version < 3) {
      // Version 3 finalized the additive history migration. Product catalog
      // schema is versioned independently in SQLite.
      version = 3;
      await user.put(schemaVersionKey, version);
    }

    if (version < 4) {
      // Recipes live in the user box so the existing versioned backup includes
      // them automatically. Missing keys are initialized without touching any
      // profile, diary, water, weight, goal, or catalog data.
      if (!user.containsKey('userRecipes')) {
        await user.put('userRecipes', <dynamic>[]);
      }
      if (!user.containsKey('recipeUsage')) {
        await user.put('recipeUsage', <String, int>{});
      }
      version = 4;
      await user.put(schemaVersionKey, version);
    }

    if (version < 5) {
      // Notification preferences are additive and live in the existing user
      // box, so backup/restore includes them without moving older data.
      if (!user.containsKey('notificationSettings')) {
        await user.put('notificationSettings', <String, dynamic>{
          'mode': 'smartAndManual',
          'adviceEnabled': true,
          'waterEnabled': true,
          'nutritionEnabled': true,
          'activityEnabled': false,
          'adviceMinute': 540,
          'quietStartMinute': 1320,
          'quietEndMinute': 480,
          'maxSmartPerDay': 3,
          'permission': 'notDetermined',
        });
      }
      if (!user.containsKey('manualReminders')) {
        await user.put('manualReminders', <dynamic>[]);
      }
      version = 5;
      await user.put(schemaVersionKey, version);
    }

    if (version < 6) {
      if (!user.containsKey('bodyMeasurements')) {
        await user.put('bodyMeasurements', <dynamic>[]);
      }
      version = 6;
      await user.put(schemaVersionKey, version);
    }

    if (stored == null && version == schemaVersion) {
      await user.put(schemaVersionKey, schemaVersion);
    }
  }

  static Map<dynamic, dynamic> _mapCopy(Object? value) =>
      value is Map ? Map<dynamic, dynamic>.from(value) : <dynamic, dynamic>{};
}
