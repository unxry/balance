import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/achievement_models.dart';
import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/models/history_models.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/profile_screen.dart';
import 'package:flutter_app/services/achievement_engine.dart';
import 'package:flutter_app/services/health_service.dart';
import 'package:flutter_app/widgets/achievement_medal.dart';
import 'package:flutter_app/widgets/premium_motion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class _NoHealthData extends HealthService {
  @override
  Future<StepAccessState> getStatus() async => StepAccessState.notDetermined;
}

void main() {
  testWidgets('locked achievement detail shows its exact requirement', (
    tester,
  ) async {
    final achievement = const AchievementEngine()
        .evaluate(
          metrics: const AchievementMetrics({'foodDays': 1}),
          persistedUnlocks: const {},
        )
        .achievements
        .singleWhere((item) => item.definition.id == 'food_7');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showAchievementDetails(context, achievement, isRu: true),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('КАК ПОЛУЧИТЬ'), findsOneWidget);
    expect(find.text(achievement.definition.requirementRu), findsOneWidget);
    expect(find.text('СЕРЕБРО'), findsOneWidget);
    expect(find.textContaining('Осталось:'), findsOneWidget);
    expect(find.text('1 / 7'), findsOneWidget);
  });

  testWidgets('unlocked achievement detail shows tier and unlock date', (
    tester,
  ) async {
    final definition = AchievementEngine.catalog.singleWhere(
      (item) => item.id == 'weight_first',
    );
    final achievement = AchievementProgress(
      definition: definition,
      currentValue: 1,
      state: AchievementState.unlocked,
      unlockedAt: DateTime(2026, 9, 8),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showAchievementDetails(context, achievement, isRu: true),
            child: const Text('open unlocked'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open unlocked'));
    await tester.pumpAndSettle();

    expect(find.text('БРОНЗА'), findsOneWidget);
    expect(find.text('ПОЛУЧЕНО'), findsOneWidget);
    expect(find.text('08.09.2026'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('all four profile cards open the correct source-backed detail', (
    tester,
  ) async {
    await initializeDateFormatting('ru');
    late Directory directory;
    late Box<dynamic> user;
    late Box<dynamic> food;
    late Box<dynamic> weight;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp(
        'balance_profile_stats_',
      );
      Hive.init(directory.path);
      user = await Hive.openBox<dynamic>('profile_user');
      food = await Hive.openBox<dynamic>('profile_food');
      weight = await Hive.openBox<dynamic>('profile_weight');
    });
    final now = DateTime(2026, 9, 7, 12);
    await tester.runAsync(
      () => user.put(
        'dailyBalances',
        List.generate(14, (index) {
          final date = now.subtract(Duration(days: 13 - index));
          return DailyBalanceSnapshot(
            dateKey:
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            caloriesEaten: 0,
            calorieTarget: 2000,
            maintenanceCalories: 2200,
            stepCount: index < 7 ? 1000 : 2000,
            waterLiters: 0,
          ).toJson();
        }),
      ),
    );
    final data = AppDataProvider(
      now: () => now,
      userBox: user,
      foodBox: food,
      weightBox: weight,
      healthService: _NoHealthData(),
    );
    await tester.runAsync(data.load);
    await tester.runAsync(
      () => data.updateProfile(
        UserProfile(
          name: 'Любовь',
          weightKg: 80,
          targetWeightKg: 70,
          joinedAt: now.subtract(const Duration(days: 30)),
          onboarded: true,
        ),
      ),
    );
    await tester.runAsync(() => data.addWeightEntry(78, date: now));
    await tester.runAsync(
      () => data.addFood(
        FoodEntry(
          id: 'breakfast',
          name: 'Каша',
          grams: 250,
          kcal: 350,
          proteinG: 12,
          fatG: 8,
          carbsG: 58,
          meal: MealType.breakfast,
          time: now,
        ),
      ),
    );
    var diaryOpened = false;
    var weightOpened = false;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(() {
      data.dispose();
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: data),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProfileScreen(
              onEditGoal: () {},
              onOpenDiary: () => diaryOpened = true,
              onOpenWeight: () => weightOpened = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    await _openCard(tester, 'СЕРИЯ');
    expect(find.text('Серия'), findsOneWidget);
    expect(find.text('ПОСЛЕДНИЕ 30 ДНЕЙ'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await _openCard(tester, 'СБРОШЕНО');
    expect(find.text('Изменение веса'), findsOneWidget);
    expect(find.text('80.0 kg'), findsOneWidget);
    expect(find.text('78.0 kg'), findsOneWidget);
    await tester.ensureVisible(find.text('Открыть историю веса'));
    await tester.tap(find.text('Открыть историю веса'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(weightOpened, isTrue);

    await _openCard(tester, 'БЛЮД СЕГОДНЯ');
    expect(find.text('Блюда сегодня'), findsOneWidget);
    expect(find.text('Каша'), findsOneWidget);
    expect(find.text('350'), findsOneWidget);
    await tester.ensureVisible(find.text('Открыть дневник'));
    await tester.tap(find.text('Открыть дневник'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(diaryOpened, isTrue);

    await _openCard(tester, 'СРЕД. ШАГИ');
    expect(find.text('Средние шаги'), findsOneWidget);
    expect(find.text('2000'), findsOneWidget);
    expect(find.text('+100%'), findsOneWidget);
    final capsule = find.ancestor(
      of: find.byKey(const ValueKey('stepsPeriodCapsule')),
      matching: find.byType(AnimatedAlign),
    );
    expect(
      tester.widget<AnimatedAlign>(capsule).alignment,
      Alignment.centerLeft,
    );
    await tester.tap(find.byKey(const ValueKey('stepsPeriod-30')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.widget<AnimatedAlign>(capsule).alignment,
      Alignment.centerRight,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _openCard(WidgetTester tester, String label) async {
  final card = find.ancestor(
    of: find.text(label),
    matching: find.byType(PressableScale),
  );
  await tester.ensureVisible(card);
  await tester.pump(const Duration(milliseconds: 300));
  final gesture = tester.widget<GestureDetector>(
    find.descendant(of: card, matching: find.byType(GestureDetector)).first,
  );
  gesture.onTap!.call();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}
