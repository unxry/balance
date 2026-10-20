import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/daily_tips_catalog.dart';
import 'package:flutter_app/data/tip_sources.dart';
import 'package:flutter_app/models/daily_tip.dart';
import 'package:flutter_app/models/weight_trend_insight.dart';
import 'package:flutter_app/models/history_models.dart';
import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/services/daily_tips_service.dart';
import 'daily_tips_service_test.dart' show MemoryTipStore, Catalog;

void main() {
  test(
    'every article has verified references, specific explanation, action and bilingual limitations',
    () {
      for (final tip in activeDailyTips) {
        expect(tip.sourceIds, isNotEmpty, reason: tip.id);
        expect(
          tip.sourceIds.every(tipSources.containsKey),
          isTrue,
          reason: tip.id,
        );
        expect(tip.evidenceLevel, isNot(TipEvidenceLevel.unverified));
        expect(tip.version, 4);
        expect(tip.safetyTags, isNotEmpty);
        expect(tip.contraindicationRules, isNotEmpty);
        for (final copy in [tip.ru, tip.en]) {
          expect(copy.explanation!.length, greaterThan(90), reason: tip.id);
          expect(copy.task, isNotEmpty);
          expect(copy.why, isNotEmpty);
        }
      }
      for (final source in tipSources.values) {
        expect(Uri.parse(source.url).scheme, 'https');
        expect(source.checkedOn, '2026-10-19');
      }
    },
  );
  test(
    'all old IDs, favorites and completion remain resolvable after catalog replacement',
    () async {
      final store = MemoryTipStore();
      final ids = [
        for (final category in TipCategory.values)
          for (var n = 1; n <= 18; n++)
            '${category.name}-${n.toString().padLeft(2, '0')}',
      ];
      store.value = {
        'version': 1,
        'saved': ids,
        'personalized': true,
        'history': [
          for (var i = 0; i < ids.length; i++)
            {
              'date': DateTime(
                2026,
                1,
                1 + i,
              ).toIso8601String().substring(0, 10),
              'id': ids[i],
              'basis': 'universal',
              'completed': true,
            },
        ],
      };
      final service = DailyTipsService(
        store: store,
        now: () => DateTime(2026, 10, 19),
      );
      await service.refresh();
      expect(service.saved.toSet(), ids.toSet());
      expect(service.history.take(180).every((v) => v.completed), isTrue);
      for (final id in ids) {
        expect(service.tipById(id), isNotNull, reason: id);
      }
      expect(service.currentTip!.retired, isFalse);
      final restarted = DailyTipsService(
        store: store,
        now: () => DateTime(2026, 10, 19),
      );
      await restarted.refresh();
      expect(restarted.currentTip!.id, service.currentTip!.id);
      expect(restarted.saved, containsAll(ids));
    },
  );
  test(
    'legacy aliases cannot repeat the previous article in a small pool',
    () async {
      final a = activeDailyTips.first;
      final b = activeDailyTips[1];
      final store = MemoryTipStore()
        ..value = {
          'version': 1,
          'history': [
            {'date': '2026-10-17', 'id': b.id, 'basis': 'universal'},
            {'date': '2026-10-18', 'id': 'legacy-a', 'basis': 'universal'},
          ],
        };
      final s = DailyTipsService(
        store: store,
        repository: Catalog([a, b, a.asLegacy('legacy-a')]),
        now: () => DateTime(2026, 10, 19),
      );
      await s.refresh();
      expect(s.currentTip!.id, b.id);
    },
  );
  test('unknown and unverified sources never enter rotation', () async {
    final good = activeDailyTips.first;
    for (final bad in [
      DailyTip(
        id: 'unsourced',
        category: TipCategory.nutrition,
        ru: good.ru,
        en: good.en,
      ),
      DailyTip(
        id: 'fake',
        category: TipCategory.nutrition,
        ru: good.ru,
        en: good.en,
        sourceIds: const ['imaginary'],
        evidenceLevel: TipEvidenceLevel.guidance,
      ),
    ]) {
      final service = DailyTipsService(
        store: MemoryTipStore(),
        repository: Catalog([bad, good]),
      );
      await service.refresh();
      expect(service.currentTip!.id, good.id);
    }
  });
  test(
    'plateau priority needs opt-in, reliable signal and confirmed safety; low logs veto it',
    () async {
      final plateau = activeDailyTips.singleWhere(
        (t) => t.id == 'insight-stable',
      );
      final general = activeDailyTips.singleWhere((t) => t.id == 'progress-16');
      final result = WeightTrendInsight(
        state: WeightInsightState.possiblePlateau,
        calculatedAt: DateTime(2026),
        reason: 'stableWeeks',
        preliminary: false,
      );
      const safe = TipSafetyProfile(age: 30, checked: true);
      for (final c in [
        const TipContext(),
        TipContext(insight: result),
        TipContext(insight: result, safety: safe, lowLoggedIntake: true),
        TipContext(insight: result, safety: safe, maintenance: true),
      ]) {
        final s = DailyTipsService(
          store: MemoryTipStore(),
          repository: Catalog([general, plateau]),
        );
        await s.setPersonalized(true);
        await s.refresh(context: c);
        expect(s.currentTip!.id, general.id);
      }
      final store = MemoryTipStore();
      var now = DateTime(2026, 10, 19);
      final s = DailyTipsService(
        store: store,
        repository: Catalog([
          general,
          plateau,
          activeDailyTips.singleWhere((t) => t.id == 'care-context'),
        ]),
        now: () => now,
      );
      await s.setPersonalized(true);
      await s.refresh(
        context: TipContext(insight: result, safety: safe),
      );
      expect(s.currentTip!.id, plateau.id);
      expect(s.currentVisit!.reasonRu, isNotNull);
      final id = s.currentVisit!.tipId;
      await s.refresh(
        context: TipContext(insight: result, safety: safe, maintenance: true),
      );
      expect(s.currentVisit!.tipId, id);
      expect(s.currentTip!.canonicalId, 'care-context');
      now = DateTime(2026, 10, 20);
      await s.refresh(
        context: TipContext(insight: result, safety: safe, maintenance: true),
      );
      expect(s.currentTip!.weightManagementOnly, isFalse);
    },
  );

  test(
    'macro-based advice needs actual varied food records with macros',
    () async {
      final protein = activeDailyTips.singleWhere(
        (t) => t.id == 'food-protein',
      );
      final general = activeDailyTips.singleWhere((t) => t.id == 'progress-16');
      for (final complete in [false, true]) {
        final s = DailyTipsService(
          store: MemoryTipStore(),
          repository: Catalog([general, protein]),
        );
        await s.setPersonalized(true);
        await s.refresh(
          context: TipContext(
            hasFood: true,
            repeatedLoggedFoods: true,
            distinctFoods: complete ? 2 : 1,
            loggedProteinG: complete ? 45 : null,
            loggedFatG: complete ? 30 : null,
            loggedCarbsG: complete ? 100 : null,
          ),
        );
        expect(s.currentTip!.id, complete ? protein.id : general.id);
      }
    },
  );

  test('incomplete or malformed safety consent remains unknown', () {
    for (final raw in [
      null,
      {'checked': true},
      {'checked': true, 'pregnant': 'false'},
    ]) {
      expect(
        TipSafetyProfile.fromJson(raw, age: 30).allowsWeightManagement,
        isFalse,
      );
    }
    expect(
      TipSafetyProfile.fromJson(
        const TipSafetyProfile(checked: true).toJson(),
        age: 30,
      ).allowsWeightManagement,
      isTrue,
    );
  });

  group('provider uses only available data and recalculates after changes', () {
    late Directory directory;
    late Box<dynamic> user, food, weight;
    late AppDataProvider data;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      directory = await Directory.systemTemp.createTemp('tips_insights_');
      Hive.init(directory.path);
      user = await Hive.openBox<dynamic>('user');
      food = await Hive.openBox<dynamic>('food');
      weight = await Hive.openBox<dynamic>('weight');
      data = AppDataProvider(
        now: () => DateTime(2026, 10, 28, 12),
        userBox: user,
        foodBox: food,
        weightBox: weight,
      );
      await data.load();
    });
    tearDown(() async {
      await data.persistPendingMutations();
      data.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    });
    test(
      'repetition uses several completed logged days without claiming a complete diet',
      () async {
        for (var i = 0; i < 3; i++) {
          for (var j = 0; j < 2; j++) {
            final date = DateTime(2026, 10, 25 + i, 12 + j);
            await data.addFoodForDate(
              FoodEntry(
                id: 'repeat-$i-$j',
                name: j == 0 ? 'Rice' : 'Beans',
                grams: 100,
                kcal: 200,
                proteinG: 5,
                fatG: 2,
                carbsG: 25,
                meal: MealType.lunch,
                time: date,
              ),
              '2026-10-${25 + i}',
            );
          }
        }
        expect(data.tipContext.repeatedLoggedFoods, isTrue);
        expect(data.tipContext.distinctFoods, 2);
        expect(data.tipContext.loggedFoodDays, 3);
        expect(
          data.tipContext.reason(TipBasis.variety, false),
          contains('not your full diet'),
        );
        expect(data.dailyTips.personalized, isFalse);
      },
    );
    test(
      'today alone cannot establish recurring logged foods; sparse weights use actual entries',
      () async {
        for (var i = 0; i < 6; i++) {
          await data.addFoodForDate(
            FoodEntry(
              id: 'today-$i',
              name: 'Rice',
              grams: 100,
              kcal: 100,
              proteinG: 4,
              fatG: 2,
              carbsG: 12,
              meal: MealType.lunch,
              time: DateTime(2026, 10, 28, 9 + i),
            ),
            '2026-10-28',
          );
        }
        expect(data.tipContext.hasFood, isTrue);
        expect(data.tipContext.repeatedLoggedFoods, isFalse);
        expect(data.tipContext.sparseWeight, isFalse);
        await data.addWeightEntry(80, date: DateTime(2026, 10, 26, 8));
        await data.addWeightEntry(80, date: DateTime(2026, 10, 27, 8));
        expect(data.tipContext.sparseWeight, isTrue);
        expect(data.tipContext.insight!.measuredDays, 2);
      },
    );
    test('no entries, unknown age, food and step signals are not invented', () {
      final c = data.tipContext;
      expect(c.hasFood, isFalse);
      expect(c.hasSteps, isFalse);
      expect(c.hasWeightTrend, isFalse);
      expect(c.safety.age, isNull);
      expect(c.safety.allowsWeightManagement, isFalse);
      expect(c.loggedProteinG, isNull);
      expect(c.insight!.state, WeightInsightState.insufficientData);
    });
    test(
      'confirmed adult context, edits, deletion and goal change update analysis',
      () async {
        await data.updateProfile(
          UserProfile(
            age: 30,
            onboarded: true,
            goal: Goal.lose,
            targetWeightKg: 65,
          ),
        );
        for (final e in data.weightHistory.toList()) {
          await data.deleteWeightEntry(e.id);
        }
        await data.setTipsSafety(const TipSafetyProfile(checked: true));
        for (var i = 0; i < 28; i++) {
          await data.addWeightEntry(80, date: DateTime(2026, 10, 1 + i, 8));
        }
        expect(data.weightInsight.state, WeightInsightState.possiblePlateau);
        final saved = [for (final e in data.weightHistory) e.toJson()];
        for (final e in data.weightHistory.toList()) {
          await data.deleteWeightEntry(e.id);
        }
        expect(data.weightInsight.state, WeightInsightState.insufficientData);
        for (final e in saved.map(WeightEntry.fromJson)) {
          await data.addWeightEntry(e.kg, date: e.date);
        }
        expect(data.weightInsight.state, WeightInsightState.possiblePlateau);
        final profile = UserProfile.fromJson(data.profile.toJson())
          ..goal = Goal.hold;
        await data.updateProfile(profile);
        expect(data.weightInsight.state, WeightInsightState.maintenance);
        expect(data.tipContext.maintenance, isTrue);
        expect(data.tipContext.hasFood, isFalse);
      },
    );
    test(
      'partial and low diary never establishes intake, deficits or missing steps',
      () async {
        for (var i = 0; i < 3; i++) {
          final date = DateTime(2026, 10, 25 + i, 12);
          await data.addFoodForDate(
            FoodEntry(
              id: 'f$i',
              name: 'Logged food',
              grams: 100,
              kcal: 100,
              proteinG: 4,
              fatG: 2,
              carbsG: 12,
              meal: MealType.lunch,
              time: date,
            ),
            '2026-10-${25 + i}',
          );
        }
        final c = data.tipContext;
        expect(c.hasFood, isTrue);
        expect(c.diaryGaps, isTrue);
        expect(c.lowLoggedIntake, isTrue);
        expect(c.loggedFoodDays, 3);
        expect(c.loggedProteinG, 12);
        expect(c.hasSteps, isFalse);
        expect(c.reason(TipBasis.gentleFuel, false), contains('incomplete'));
        expect(data.profile.manualCalories, isNull);
      },
    );
  });
}
