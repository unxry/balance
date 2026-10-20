import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_app/data/daily_tips_catalog.dart';
import 'package:flutter_app/models/daily_tip.dart';
import 'package:flutter_app/services/daily_tips_service.dart';
import 'package:flutter_app/services/local_backup_service.dart';
import 'package:flutter_app/services/local_store.dart';

class MemoryTipStore implements DailyTipsStore {
  Object? value;
  int writes = 0;
  bool fail = false;
  @override
  Object get identity => this;
  @override
  Object? read() => value;
  @override
  Future<void> write(Map<String, Object> state) async {
    await Future<void>.delayed(Duration.zero);
    if (fail) throw StateError('disk unavailable');
    writes++;
    value = jsonDecode(jsonEncode(state));
  }
}

class Catalog implements DailyTipsRepository {
  final List<DailyTip> tips;
  Catalog(this.tips);
  @override
  Future<List<DailyTip>> load() async => tips;
}

void main() {
  late MemoryTipStore store;
  late DateTime now;
  DailyTipsService service({DailyTipsRepository? repository}) =>
      DailyTipsService(
        store: store,
        now: () => now,
        repository: repository ?? const OfflineDailyTipsRepository(),
      );
  setUp(() {
    store = MemoryTipStore();
    now = DateTime(2026, 12, 31, 23, 59, 59);
  });

  test(
    '150 practical articles, all 180 legacy IDs, bilingual content and compatible aliases',
    () {
      expect(activeDailyTips, hasLength(150));
      expect(dailyTipsCatalog.map((tip) => tip.id).toSet(), hasLength(295));
      expect(activeDailyTips.map((tip) => tip.ru.body).toSet(), hasLength(150));
      expect(activeDailyTips.map((tip) => tip.en.body).toSet(), hasLength(150));
      for (final category in TipCategory.values) {
        expect(
          activeDailyTips.where((tip) => tip.category == category).length,
          greaterThanOrEqualTo(1),
        );
        for (var n = 1; n <= 18; n++) {
          expect(
            dailyTipsCatalog.any(
              (tip) =>
                  tip.id == '${category.name}-${n.toString().padLeft(2, '0')}',
            ),
            isTrue,
          );
        }
      }
      for (final tip in dailyTipsCatalog) {
        expect(tip.ru.title, isNotEmpty);
        expect(tip.en.title, isNotEmpty);
        expect(tip.copy(true), same(tip.ru));
        expect(tip.copy(false), same(tip.en));
        expect(tip.ru.task == null, tip.en.task == null);
      }
    },
  );

  test('first launch without data gives a universal offline tip', () async {
    final tips = service();
    await tips.refresh();
    expect(tips.currentTip, isNotNull);
    expect(tips.currentVisit!.dateKey, '2026-12-31');
    expect(tips.currentTip!.basis, TipBasis.universal);
    expect(tips.personalized, isFalse);
    expect(store.writes, 1);
  });

  test(
    'restarts, context changes and settings keep the same daily ID',
    () async {
      final tips = service();
      await tips.refresh();
      final id = tips.currentTip!.id;
      await tips.setPersonalized(true);
      await tips.refresh(
        context: const TipContext(hasFood: true, hasWater: true),
      );
      now = DateTime(2026, 12, 31, 23, 59, 59, 999);
      final restarted = service();
      await restarted.refresh();
      expect(restarted.currentTip!.id, id);
      expect(restarted.history, hasLength(1));
      expect(restarted.personalized, isTrue);
      expect(store.writes, 2);
    },
  );

  for (final dates in [
    [DateTime(2026, 10, 15, 23, 59), DateTime(2026, 10, 16)],
    [DateTime(2026, 10, 31, 23, 59), DateTime(2026, 11, 1)],
    [DateTime(2026, 12, 31, 23, 59), DateTime(2027, 1, 1)],
    [DateTime(2028, 2, 28, 23, 59), DateTime(2028, 2, 29)],
  ]) {
    test('new civil day changes the tip: ${dates.first}', () async {
      now = dates.first;
      final tips = service();
      await tips.refresh();
      final previous = tips.currentTip!.id;
      now = dates.last;
      await tips.refresh();
      expect(tips.currentTip!.id, isNot(previous));
      expect(tips.history, hasLength(2));
    });
  }

  test(
    'timezone travel and clock reversal reuse already visited civil dates',
    () async {
      // These are the civil clock readings supplied by a device in Tokyo and LA
      // for the same UTC instant, then on return to Tokyo.
      now = DateTime(2027, 1, 1, 10);
      final tips = service();
      await tips.refresh();
      final tokyo = tips.currentTip!.id;
      now = DateTime(2026, 12, 31, 17);
      await tips.refresh();
      final losAngeles = tips.currentTip!.id;
      expect(losAngeles, isNot(tokyo));
      now = DateTime(2027, 1, 1, 10);
      final restarted = service();
      await restarted.refresh();
      expect(restarted.currentTip!.id, tokyo);
      expect(restarted.history, hasLength(2));
    },
  );

  test(
    'DST-style skipped/repeated hours do not change the civil day',
    () async {
      final tips = service();
      now = DateTime(2026, 11, 1, 1, 59);
      await tips.refresh();
      final id = tips.currentTip!.id;
      now = DateTime(2026, 11, 1, 1, 1);
      await tips.refresh();
      now = DateTime(2026, 11, 1, 3, 1);
      await tips.refresh();
      expect(tips.currentTip!.id, id);
      expect(tips.history, hasLength(1));
    },
  );

  test(
    'category rotation, full cycle and sixty-day exclusion over 500 days',
    () async {
      final base = activeDailyTips.first;
      final catalog = [
        for (var i = 0; i < 80; i++)
          DailyTip(
            id: 'rotation-$i',
            topic: 'topic-$i',
            category: TipCategory.values[i % TipCategory.values.length],
            ru: base.ru,
            en: base.en,
            sourceIds: base.sourceIds,
            evidenceLevel: base.evidenceLevel,
          ),
      ];
      final tips = service(repository: Catalog(catalog));
      final ids = <String>[];
      final categories = <TipCategory>[];
      final universal = catalog.length;
      for (var day = 0; day < 500; day++) {
        now = DateTime(2027, 1, 1 + day);
        await tips.refresh();
        final id = tips.currentTip!.id;
        expect(
          ids.skip(ids.length > 59 ? ids.length - 59 : 0),
          isNot(contains(id)),
        );
        ids.add(id);
        categories.add(tips.currentTip!.category);
      }
      expect(ids.take(universal).toSet(), hasLength(universal));
      expect(categories.take(10).toSet(), hasLength(10));
      expect(ids[universal], isNot(ids[universal - 1]));
    },
  );

  test(
    'small catalogs terminate and avoid immediate repeats where possible',
    () async {
      final tips = service(
        repository: Catalog(dailyTipsCatalog.take(2).toList()),
      );
      for (var i = 0; i < 10; i++) {
        final previous = tips.currentTip?.id;
        now = DateTime(2027, 1, 1 + i);
        await tips.refresh();
        expect(tips.currentTip!.id, isNot(previous));
      }
      final single = DailyTipsService(
        store: MemoryTipStore(),
        repository: Catalog([dailyTipsCatalog.first]),
        now: () => now,
      );
      await single.refresh();
      now = DateTime(2027, 2, 1);
      await single.refresh();
      expect(single.history, hasLength(2));
    },
  );

  test(
    'concurrent services share one durable selection and merge mutations',
    () async {
      final services = List.generate(24, (_) => service());
      await Future.wait(services.map((tips) => tips.refresh()));
      expect(store.writes, 1);
      expect(services.map((tips) => tips.currentTip!.id).toSet(), hasLength(1));
      final id = services.first.currentTip!.id;
      final taskTip = dailyTipsCatalog.firstWhere((tip) => tip.id == id);
      if (taskTip.ru.task == null) {
        fail('The first category should have an actionable tip');
      }
      await Future.wait([
        services[0].toggleSaved(id),
        services[1].setCompleted('2026-12-31', true),
        services[2].setPersonalized(true),
      ]);
      final restarted = service();
      await restarted.refresh();
      expect(restarted.saved, contains(id));
      expect(restarted.currentVisit!.completed, isTrue);
      expect(restarted.personalized, isTrue);
    },
  );

  test('task completion is explicit, persisted and reversible', () async {
    final tips = service(repository: Catalog([dailyTipsCatalog.first]));
    await tips.refresh();
    expect(tips.currentVisit!.completed, isFalse);
    await tips.toggleSaved(tips.currentTip!.id);
    expect(tips.currentVisit!.completed, isFalse);
    await tips.setCompleted('2026-12-31', true);
    final restarted = service(repository: Catalog([dailyTipsCatalog.first]));
    await restarted.refresh();
    expect(restarted.currentVisit!.completed, isTrue);
    await restarted.setCompleted('2026-12-31', false);
    await restarted.toggleSaved(restarted.currentTip!.id);
    expect(restarted.currentVisit!.completed, isFalse);
    expect(restarted.saved, isEmpty);
  });

  test(
    'completed tasks are deprioritized after all eligible tips were seen',
    () async {
      final tips = service(
        repository: Catalog(dailyTipsCatalog.take(3).toList()),
      );
      final done = <String>{};
      for (var day = 0; day < 3; day++) {
        now = DateTime(2027, 1, 1 + day);
        await tips.refresh();
        if (day == 0) {
          done.add(tips.currentTip!.id);
          await tips.setCompleted(tips.currentVisit!.dateKey, true);
        }
      }
      now = DateTime(2027, 5, 1);
      await tips.refresh();
      expect(done, isNot(contains(tips.currentTip!.id)));
    },
  );

  test(
    'personalization requires opt-in AND real context, including low logs',
    () async {
      final special = dailyTipsCatalog.firstWhere(
        (tip) => tip.basis == TipBasis.gentleFuel,
      );
      final universal = dailyTipsCatalog.first;
      final tips = service(repository: Catalog([universal, special]));
      await tips.refresh(
        context: const TipContext(hasFood: true, lowLoggedIntake: true),
      );
      expect(tips.currentTip!.basis, TipBasis.universal);
      await tips.setPersonalized(true);
      now = DateTime(2027, 1, 1);
      await tips.refresh(
        context: const TipContext(hasFood: true, lowLoggedIntake: true),
      );
      expect(tips.currentTip!.id, special.id);
      expect(tips.currentVisit!.basis, TipBasis.gentleFuel);
      await tips.setPersonalized(false);
      expect(tips.currentTip!.id, special.id);
      now = DateTime(2027, 1, 2);
      await tips.refresh(
        context: const TipContext(hasFood: true, lowLoggedIntake: true),
      );
      expect(tips.currentTip!.basis, TipBasis.universal);
    },
  );

  test('each context-gated tip needs its own real data', () async {
    for (final basis in TipBasis.values.where((b) => b != TipBasis.universal)) {
      final tip = dailyTipsCatalog.firstWhere((tip) => tip.basis == basis);
      final tips = DailyTipsService(
        store: MemoryTipStore(),
        repository: Catalog([dailyTipsCatalog.first, tip]),
        now: () => now,
      );
      await tips.setPersonalized(true);
      await tips.refresh();
      expect(tips.currentTip!.basis, TipBasis.universal);
    }
  });

  test('failed writes retry without poisoning the selection queue', () async {
    final tips = service();
    store.fail = true;
    await expectLater(tips.refresh(), throwsStateError);
    expect(tips.currentTip, isNull);
    store.fail = false;
    await tips.refresh();
    final id = tips.currentTip!.id;
    store.fail = true;
    await expectLater(tips.toggleSaved(id), throwsStateError);
    expect(tips.saved, isEmpty);
    store.fail = false;
    await tips.toggleSaved(id);
    expect(tips.saved, contains(id));
  });

  test('future state versions are preserved instead of overwritten', () async {
    store.value = {'version': 99, 'private': 'untouched'};
    await expectLater(service().refresh(), throwsFormatException);
    expect(store.value, {'version': 99, 'private': 'untouched'});
    expect(store.writes, 0);
  });

  test(
    'additive Hive storage survives old-store migration and backup restore',
    () async {
      final dir = await Directory.systemTemp.createTemp('tip_backup_');
      Hive.init(dir.path);
      final user = await Hive.openBox<dynamic>('tip_user');
      final food = await Hive.openBox<dynamic>('tip_food');
      final weight = await Hive.openBox<dynamic>('tip_weight');
      try {
        await user.putAll({
          'profile': {'name': 'Synthetic QA'},
          'water': 1.2,
          LocalStore.schemaVersionKey: 1,
        });
        await LocalStore.migrateBoxes(user: user, food: food, weight: weight);
        final tips = DailyTipsService(
          store: HiveDailyTipsStore(user),
          now: () => now,
        );
        await tips.refresh();
        final id = tips.currentTip!.id;
        await tips.toggleSaved(id);
        final choice = tips.alternativeOptions.first;
        await tips.chooseAlternative(choice.id);
        await tips.setCompleted(
          tips.currentVisit!.dateKey,
          true,
          tipId: choice.id,
        );
        final backup = const LocalBackupService().exportJson(
          user: user,
          food: food,
          weight: weight,
        );
        await user.delete(HiveDailyTipsStore.storageKey);
        await const LocalBackupService().restoreJson(
          backup,
          user: user,
          food: food,
          weight: weight,
        );
        await user.close();
        final reopened = await Hive.openBox<dynamic>('tip_user');
        final restored = DailyTipsService(
          store: HiveDailyTipsStore(reopened),
          now: () => now,
        );
        await restored.refresh();
        expect(restored.currentVisit!.tipId, id);
        expect(restored.currentTip!.id, choice.id);
        expect(restored.displayVisit!.completed, isTrue);
        expect(restored.currentVisit!.completed, isFalse);
        expect(restored.saved, contains(id));
        expect(reopened.get('profile'), {'name': 'Synthetic QA'});
        expect(reopened.get('water'), 1.2);
      } finally {
        await Hive.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
