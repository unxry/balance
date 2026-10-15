import 'dart:io';

import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/models/reminder_models.dart';
import 'package:flutter_app/models/product_retailer_relation.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/services/local_backup_service.dart';
import 'package:flutter_app/services/local_store.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('version A user data survives additive schema upgrade', () async {
    final directory = await Directory.systemTemp.createTemp('balance_upgrade_');
    Hive.init(directory.path);
    final user = await Hive.openBox<dynamic>('upgrade_user');
    final food = await Hive.openBox<dynamic>('upgrade_food');
    final weight = await Hive.openBox<dynamic>('upgrade_weight');
    final achievements = await Hive.openBox<dynamic>('upgrade_achievements');
    final now = DateTime(2026, 9, 4, 12);
    final profile = UserProfile(
      name: 'Upgrade user',
      weightKg: 71,
      targetWeightKg: 65,
      calorieGoalMode: CalorieGoalMode.manual,
      manualCalories: 1780,
      onboarded: true,
      joinedAt: now.subtract(const Duration(days: 30)),
    );
    await user.putAll({
      LocalStore.schemaVersionKey: 1,
      'profile': profile.toJson(),
      'water': 1.7,
      'waterDate': '2026-09-04',
      'dailyBalances': [
        {
          'dateKey': '2026-09-03',
          'caloriesEaten': 1600,
          'calorieTarget': 1780,
          'maintenanceCalories': 2100,
          'stepCount': 9000,
          'waterLiters': 2.1,
          'proteinG': 90,
          'fatG': 55,
          'carbsG': 180,
          'mealCount': 4,
          'mealMinutes': [480, 720, 960, 1200],
        },
      ],
    });
    final meals = List.generate(
      10,
      (index) => FoodEntry(
        id: 'meal-$index',
        name: 'Saved meal $index',
        grams: 100,
        kcal: 100 + index,
        proteinG: 10,
        fatG: 3,
        carbsG: 12,
        meal: MealType.lunch,
        time: now.add(Duration(minutes: index)),
      ).toJson(),
    );
    await food.putAll({
      'today': meals,
      'dayKey': '2026-09-04',
      'today_date': '2026-09-04',
    });
    await weight.put(
      'history',
      List.generate(
        5,
        (index) => {
          'id': 'weight-$index',
          'date': now.subtract(Duration(days: 5 - index)).toIso8601String(),
          'kg': 72 - index * 0.25,
          'source': 0,
        },
      ),
    );
    SharedPreferences.setMockInitialValues({
      'balance_lang': 'en',
      'balance_theme': 'dark',
    });

    await LocalStore.migrateBoxes(user: user, food: food, weight: weight);
    final data = AppDataProvider(
      now: () => now,
      userBox: user,
      foodBox: food,
      weightBox: weight,
      achievementsBox: achievements,
    );
    final settings = SettingsProvider();
    await settings.load();
    await data.load();
    await data.updateReminderSettings(
      const ReminderSettings(
        mode: ReminderMode.smartAndManual,
        quietStartMinute: 21 * 60 + 30,
        quietEndMinute: 7 * 60 + 30,
        permission: NotificationPermissionState.authorized,
      ),
    );
    await data.saveManualReminder(
      const ManualReminder(
        id: 'backup-water',
        type: ReminderType.water,
        title: 'Water',
        minuteOfDay: 11 * 60,
        weekdays: {1, 3, 5},
      ),
    );
    await achievements.put('unlockedAt', {
      'special_year': now.toUtc().toIso8601String(),
    });

    expect(user.get(LocalStore.schemaVersionKey), LocalStore.schemaVersion);
    expect(data.todayFood, hasLength(10));
    expect(data.allFoodEntries, hasLength(10));
    expect(data.weightHistory, hasLength(5));
    expect(data.waterLiters, 1.7);
    expect(data.waterHistory['2026-09-04'], 1.7);
    expect(data.profile.targetWeightKg, 65);
    expect(data.profile.effectiveCalorieGoal, 1780);
    expect(data.dailyBalances.any((day) => day.stepCount == 9000), isTrue);
    expect(settings.lang, AppLang.en);
    expect(settings.themeMode, AppThemeMode.dark);

    final backup = const LocalBackupService().exportJson(
      user: user,
      food: food,
      weight: weight,
      achievements: achievements,
      settings: settings.exportSettings(),
      favoriteProductIds: const ['catalog-favorite-1'],
      productRetailerRelations: [
        ProductRetailerRelation(
          productId: 'barcode:4601234567893',
          retailerSlug: 'pyaterochka',
          source: RetailerRelationSource.userManual,
          confidence: 1,
          userConfirmed: true,
          firstSeenAt: now,
          lastSeenAt: now,
        ),
      ],
    );
    final inspection = const LocalBackupService().inspectJson(backup);
    expect(inspection.backupVersion, LocalBackupService.backupFormatVersion);
    expect(inspection.storageSchemaVersion, LocalStore.schemaVersion);
    expect(inspection.recordCounts[LocalStore.foodBox], greaterThan(0));
    expect(inspection.settingsCount, greaterThan(0));
    expect(inspection.productFavoriteCount, 1);
    expect(inspection.productRetailerRelationCount, 1);
    expect(backup, contains('balance-local-backup'));
    expect(backup, contains('language'));

    await user.clear();
    await food.clear();
    await weight.clear();
    await achievements.clear();
    await settings.setLang(AppLang.ru);
    await settings.setTheme(AppThemeMode.wellness);
    var restoredFavorites = <String>[];
    var restoredRetailers = <ProductRetailerRelation>[];
    await const LocalBackupService().restoreJson(
      backup,
      user: user,
      food: food,
      weight: weight,
      achievements: achievements,
      restoreSettings: settings.restoreSettings,
      restoreProductFavorites: (ids) async => restoredFavorites = ids,
      restoreProductRetailerRelations: (relations) async =>
          restoredRetailers = relations,
    );
    final restored = AppDataProvider(
      now: () => now,
      userBox: user,
      foodBox: food,
      weightBox: weight,
      achievementsBox: achievements,
    );
    await restored.load();
    expect(restored.todayFood, hasLength(10));
    expect(restored.weightHistory, hasLength(5));
    expect(restored.waterLiters, 1.7);
    expect(settings.lang, AppLang.en);
    expect(settings.themeMode, AppThemeMode.dark);
    expect(restored.reminderSettings.quietStartMinute, 21 * 60 + 30);
    expect(restored.manualReminders.single.id, 'backup-water');
    expect(restoredFavorites, ['catalog-favorite-1']);
    expect(restoredRetailers.single.retailerSlug, 'pyaterochka');
    expect(restoredRetailers.single.userConfirmed, isTrue);
    expect(
      restored.achievements
          .singleWhere((item) => item.definition.id == 'special_year')
          .unlockedAt
          ?.toUtc(),
      now.toUtc(),
    );

    await Hive.close();
    await directory.delete(recursive: true);
  });
}
