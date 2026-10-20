import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/daily_tips_catalog.dart';
import 'package:flutter_app/models/daily_tip.dart';
import 'package:flutter_app/models/weight_trend_insight.dart';
import 'package:flutter_app/services/daily_tips_service.dart';
import 'daily_tips_service_test.dart' show MemoryTipStore, Catalog;

void main() {
  test('every active plan has distinct actionable content in both languages', () {
    expect(activeDailyTips, hasLength(150));
    expect(legacyTipAliases, hasLength(145));
    expect(dailyTipsCatalog.map((t) => t.id).toSet(), hasLength(295));
    for (final ru in [true, false]) {
      final copies = activeDailyTips.map((t) => t.copy(ru));
      expect(copies.map((c) => c.task).toSet(), hasLength(150));
      expect(copies.map((c) => c.example).toSet(), hasLength(150));
      expect(copies.map((c) => c.why).toSet(), hasLength(150));
      for (final copy in copies) {
        expect(copy.steps.length, inInclusiveRange(2, 3), reason: copy.title);
        expect(copy.example, isNotEmpty, reason: copy.title);
        expect(copy.alternative, isNotEmpty, reason: copy.title);
        expect(copy.doneWhen, isNotEmpty, reason: copy.title);
        expect(copy.task, isNot(copy.why), reason: copy.title);
        expect(
          copy.steps.toSet().length,
          copy.steps.length,
          reason: copy.title,
        );
      }
    }
    // These scenarios check usable choices and limits, beyond action-word presence.
    final expectations = <String, List<String>>{
      'nutrition-01': ['овощ', 'помидор', 'замороженная'],
      'macros-04': ['перекус', 'йогурт', 'готовый'],
      'hydration-18': ['дискомфорт', 'допить', 'незакрытым'],
      'activity-02': ['комфортный', 'коляске', 'отдых'],
      'recovery-04': ['изменение', 'свет', 'комната'],
      'habits-15': ['недостающий', 'фасоль', 'имеющегося'],
      'mindful-09': ['без компенсации', 'обычный ужин', 'обычному'],
      'progress-02': ['условия', 'весы', 'паузу'],
      'facts-16': ['запись', 'готовый рис', 'приблизительной'],
      'today-15': ['комбинацию', 'хумус', 'сэндвич'],
      'insight-stable': ['завершённый день', 'масло', 'Нет дневника'],
    };
    for (final e in expectations.entries) {
      final tip = dailyTipsCatalog.singleWhere((t) => t.id == e.key);
      expect(tip.ru.task!.toLowerCase(), contains(e.value[0].toLowerCase()));
      expect(tip.ru.example!.toLowerCase(), contains(e.value[1].toLowerCase()));
      expect(
        tip.ru.alternative!.toLowerCase(),
        contains(e.value[2].toLowerCase()),
      );
      expect(tip.en.steps.length, tip.ru.steps.length);
    }
  });

  test(
    'explicit alternatives persist separately from assignments and completion',
    () async {
      final store = MemoryTipStore();
      var now = DateTime(2026, 10, 20, 12);
      DailyTipsService service() =>
          DailyTipsService(store: store, now: () => now);
      final s = service();
      await s.refresh();
      final original = s.currentVisit!.tipId;
      final alternative = s.alternativeOptions.first;
      await s.chooseAlternative(alternative.id);
      expect(s.currentVisit!.tipId, original);
      expect(s.displayVisit!.tipId, alternative.id);
      expect(s.history.length, 1);
      expect(s.displayVisit!.completed, isFalse);
      await s.setCompleted(
        s.currentVisit!.dateKey,
        true,
        tipId: alternative.id,
      );
      expect(s.currentVisit!.completed, isFalse);
      expect(s.displayVisit!.completed, isTrue);
      await s.toggleSaved(alternative.id);
      final restarted = service();
      await restarted.refresh();
      expect(restarted.currentTip!.id, alternative.id);
      expect(restarted.displayVisit!.completed, isTrue);
      expect(restarted.saved, contains(alternative.id));
      await restarted.chooseAlternative(null);
      expect(restarted.currentTip!.id, original);
      expect(restarted.currentVisit!.alternatives.single.completed, isTrue);
      await restarted.setCompleted(restarted.currentVisit!.dateKey, true);
      await restarted.chooseAlternative(alternative.id);
      expect(restarted.currentVisit!.completed, isTrue);
      expect(restarted.displayVisit!.completed, isTrue);
      expect((store.value as Map)['version'], 1);
      now = DateTime(2026, 10, 21);
      await restarted.refresh();
      expect(restarted.currentTip!.id, isNot(alternative.id));
      expect(restarted.currentVisit!.alternatives, isEmpty);
      expect(restarted.history, hasLength(2));
      now = DateTime(2026, 10, 20);
      await restarted.refresh();
      expect(restarted.currentTip!.id, alternative.id);
      expect(restarted.displayVisit!.completed, isTrue);
    },
  );

  test(
    'new completion records its task version without rewriting assignment context',
    () async {
      final tip = activeDailyTips.first;
      final store = MemoryTipStore()
        ..value = {
          'version': 1,
          'history': [
            {
              'date': '2026-10-20',
              'id': tip.id,
              'basis': 'universal',
              'completed': true,
              'catalogVersion': 3,
            },
          ],
        };
      final s = DailyTipsService(
        store: store,
        now: () => DateTime(2026, 10, 20),
      );
      await s.refresh();
      expect(s.currentVisit!.completionVersion, 3);
      await s.setCompleted('2026-10-20', false);
      await s.setCompleted('2026-10-20', true);
      expect(s.currentVisit!.completionVersion, 4);
      expect(s.currentVisit!.catalogVersion, 3);
      final restarted = DailyTipsService(
        store: store,
        now: () => DateTime(2026, 10, 20),
      );
      await restarted.refresh();
      expect(restarted.currentVisit!.completionVersion, 4);
    },
  );

  test(
    'failed alternative write is retryable and midnight cannot change yesterday',
    () async {
      final store = MemoryTipStore();
      var now = DateTime(2026, 10, 20, 23, 59);
      final s = DailyTipsService(store: store, now: () => now);
      await s.refresh();
      final original = s.currentTip!.id, choice = s.alternativeOptions.first.id;
      store.fail = true;
      await expectLater(s.chooseAlternative(choice), throwsStateError);
      expect(s.currentTip!.id, original);
      expect(s.currentVisit!.alternatives, isEmpty);
      store.fail = false;
      await s.chooseAlternative(choice);
      now = DateTime(2026, 10, 21);
      await expectLater(s.chooseAlternative(null), throwsStateError);
      expect(s.currentTip!.id, choice);
      await s.refresh();
      expect(s.history.first.displayed.tipId, choice);
    },
  );

  test(
    'unsafe, retired and unsupported-context alternatives are rejected',
    () async {
      final s = DailyTipsService(store: MemoryTipStore());
      await s.refresh();
      final id = s.currentVisit!.tipId;
      for (final bad in [
        'insight-stable',
        'food-protein',
        'nutrition-04',
        'missing',
      ]) {
        await expectLater(s.chooseAlternative(bad), throwsStateError);
        expect(s.currentVisit!.tipId, id);
      }
      expect(
        s.alternativeOptions.every(
          (t) =>
              !t.retired &&
              !t.weightManagementOnly &&
              t.basis == TipBasis.universal,
        ),
        isTrue,
      );
    },
  );

  test(
    'expanded real library avoids adjacent article and topic repetition for 500 days',
    () async {
      var now = DateTime(2026, 1, 1);
      final s = DailyTipsService(store: MemoryTipStore(), now: () => now);
      String? previous, topic;
      final seen = <String>{};
      for (var i = 0; i < 500; i++) {
        now = DateTime(2026, 1, 1 + i);
        await s.refresh();
        final t = s.currentTip!;
        expect(t.id, isNot(previous));
        expect(t.topicKey, isNot(topic));
        expect(t.retired, isFalse);
        previous = t.id;
        topic = t.topicKey;
        seen.add(t.id);
      }
      expect(
        seen,
        containsAll(
          activeDailyTips
              .where((t) => t.basis == TipBasis.universal)
              .map((t) => t.id),
        ),
      );
    },
  );

  test(
    'nested malformed alternatives cannot create a selected assignment',
    () async {
      final id = activeDailyTips.first.id;
      final store = MemoryTipStore();
      store.value = jsonDecode(
        jsonEncode({
          'version': 1,
          'history': [
            {
              'date': '2026-10-20',
              'id': id,
              'selectedId': 'wrong',
              'alternatives': [
                {'id': 'wrong', 'date': '2026-10-19', 'completed': true},
              ],
            },
          ],
        }),
      );
      final s = DailyTipsService(
        store: store,
        now: () => DateTime(2026, 10, 20),
      );
      await s.refresh();
      expect(s.currentVisit!.tipId, id);
      expect(s.currentVisit!.selectedId, isNull);
    },
  );

  test(
    'a real repetition signal plus macros gates a variety recommendation',
    () async {
      final protein = activeDailyTips.singleWhere(
        (t) => t.id == 'food-protein',
      );
      final general = activeDailyTips.first;
      for (final repeats in [false, true]) {
        final s = DailyTipsService(
          store: MemoryTipStore(),
          repository: Catalog([general, protein]),
        );
        await s.setPersonalized(true);
        await s.refresh(
          context: TipContext(
            hasFood: true,
            repeatedLoggedFoods: repeats,
            distinctFoods: 2,
            loggedFoodDays: 3,
            loggedProteinG: 60,
            loggedFatG: 50,
            loggedCarbsG: 100,
          ),
        );
        expect(s.currentTip!.id, repeats ? protein.id : general.id);
        if (repeats) {
          expect(s.currentVisit!.reasonRu, contains('описание записей'));
        }
      }
      final s = DailyTipsService(
        store: MemoryTipStore(),
        repository: Catalog([general, protein]),
      );
      await s.setPersonalized(true);
      await s.refresh(
        context: TipContext(
          hasFood: true,
          repeatedLoggedFoods: true,
          distinctFoods: 2,
          loggedProteinG: double.nan,
          loggedFatG: 50,
          loggedCarbsG: 100,
        ),
      );
      expect(s.currentTip!.id, general.id);
    },
  );

  test('missing weights do not imply an infrequent weighing habit', () async {
    final short = activeDailyTips.singleWhere((t) => t.id == 'insight-short'),
        general = activeDailyTips.first;
    for (final sparse in [false, true]) {
      final s = DailyTipsService(
        store: MemoryTipStore(),
        repository: Catalog([general, short]),
      );
      await s.setPersonalized(true);
      await s.refresh(
        context: TipContext(
          sparseWeight: sparse,
          insight: WeightTrendInsight(
            state: WeightInsightState.insufficientData,
            calculatedAt: DateTime(2026),
            reason: 'short',
            measuredDays: sparse ? 2 : 0,
          ),
        ),
      );
      expect(s.currentTip!.id, sparse ? short.id : general.id);
    }
  });
}
