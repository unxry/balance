import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/daily_tips_catalog.dart';
import 'package:flutter_app/data/tip_sources.dart';
import 'package:flutter_app/models/daily_tip.dart';
import 'package:flutter_app/models/weight_trend_insight.dart';
import 'package:flutter_app/services/daily_tips_service.dart';
import '../tool/export_daily_tips_catalog.dart';
import 'daily_tips_service_test.dart' show MemoryTipStore, Catalog;

void main() {
  test(
    'published machine catalog matches runtime content and applicability',
    () {
      final published = jsonDecode(
        File('docs/daily_tips_catalog.json').readAsStringSync(),
      );
      expect(published, dailyTipsCatalogSnapshot());
      expect(activeDailyTips, hasLength(150));
      expect(
        activeDailyTips.where((t) => t.basis == TipBasis.universal),
        hasLength(137),
      );
      expect(
        activeDailyTips.where((t) => t.basis != TipBasis.universal),
        hasLength(13),
      );
      expect(activeDailyTips.where((t) => t.version == 5), hasLength(95));
      for (final tip in activeDailyTips) {
        expect(tip.retired, isFalse);
        expect(tip.sourceIds, isNotEmpty);
        expect(
          tip.sourceIds.every(tipSources.containsKey),
          isTrue,
          reason: tip.id,
        );
        expect(tip.evidenceLevel, isNot(TipEvidenceLevel.unverified));
        for (final c in [tip.ru, tip.en]) {
          expect(
            [
              c.title,
              c.body,
              c.task,
              c.example,
              c.alternative,
              c.doneWhen,
              c.why,
              c.explanation,
            ].every((v) => v != null && v.trim().isNotEmpty),
            isTrue,
            reason: tip.id,
          );
          expect(c.steps.length, inInclusiveRange(2, 3));
        }
        expect(tip.ru.steps.length, tip.en.steps.length, reason: tip.id);
      }
    },
  );

  test('review covers every scenario, not merely distinct IDs', () {
    final review =
        jsonDecode(
              File('docs/daily_tips_semantic_review.json').readAsStringSync(),
            )
            as Map;
    final rows = (review['plans'] as List).cast<Map>();
    expect(
      rows.map((r) => r['id']).toSet(),
      activeDailyTips.map((t) => t.id).toSet(),
    );
    for (final row in rows) {
      final tip = activeDailyTips.singleWhere((t) => t.id == row['id']);
      expect(row['action'], tip.ru.task);
      expect(row['context'], tip.ru.body);
      expect(row['ruEnReviewed'], isTrue);
      expect(row['limitations'], tip.ru.alternative);
    }
    for (final ru in [true, false]) {
      String normal(String s) =>
          s.toLowerCase().replaceAll(RegExp(r'[^a-zа-яё0-9]+'), ' ').trim();
      final signatures = activeDailyTips.map((t) {
        final c = t.copy(ru);
        return normal('${c.task} ${c.steps.join(' ')}');
      });
      expect(signatures.toSet(), hasLength(150));
    }
    for (final group in (review['relatedGroups'] as List).cast<Map>()) {
      expect(group['distinction'], isNotEmpty);
      final tips = (group['ids'] as List).map(
        (id) => activeDailyTips.singleWhere((t) => t.id == id),
      );
      expect(
        tips.map((t) => t.topicKey).toSet(),
        hasLength(1),
        reason: '${group['ids']}',
      );
      expect(tips.map((t) => t.ru.task).toSet(), hasLength(tips.length));
    }
    expect(review['consolidated'], hasLength(5));
  });

  test('all 200 build 22 IDs retain both copies and completion meaning', () {
    final before =
        jsonDecode(
              File('test/fixtures/daily_tips_build22.json').readAsStringSync(),
            )
            as Map;
    final originals = {
      for (final t in (before['active'] as List).cast<Map>()) t['id']: t,
    };
    final aliases = before['aliases'] as Map;
    for (final id in {...originals.keys, ...aliases.keys}) {
      final old = originals[id] ?? originals[aliases[id]]!;
      final tip = dailyTipsCatalog.singleWhere((t) => t.id == id);
      expect(tipCopySnapshot(tip.ru), old['ru'], reason: 'RU $id');
      expect(tipCopySnapshot(tip.en), old['en'], reason: 'EN $id');
      expect(tip.version, old['version'], reason: id as String);
    }
    for (final entry in legacyTipAliases.entries) {
      expect(activeDailyTips.any((t) => t.id == entry.value), isTrue);
      expect(
        dailyTipsCatalog.singleWhere((t) => t.id == entry.key).canonicalId,
        entry.value,
      );
    }
  });

  test(
    'build 22 assignments, favorites and chosen retired alternatives survive restart without writes',
    () async {
      const retired = [
        'macros-02',
        'nutrition-09',
        'activity-02',
        'food-fibre',
        'meal-dinner',
      ];
      for (final id in retired) {
        final store = MemoryTipStore();
        store.value = {
          'version': 1,
          'personalized': false,
          'saved': dailyTipsCatalog
              .where((t) => t.version == 4)
              .map((t) => t.id)
              .toList(),
          'history': [
            TipVisit(
              dateKey: '2026-10-20',
              tipId: 'meal-lunch',
              basis: TipBasis.universal,
              catalogVersion: 4,
              completed: true,
              completedVersion: 4,
              selectedId: id,
              alternatives: [
                TipVisit(
                  dateKey: '2026-10-20',
                  tipId: id,
                  basis: TipBasis.universal,
                  catalogVersion: 4,
                  completed: true,
                  completedVersion: 4,
                  reasonRu: 'Сохранённая причина',
                  reasonEn: 'Saved reason',
                ),
              ],
            ).toJson(),
          ],
        };
        // meal-lunch differs from all retired IDs, including the old dinner plan.
        final original = jsonEncode(store.value);
        for (var restart = 0; restart < 2; restart++) {
          final service = DailyTipsService(
            store: store,
            now: () => DateTime(2026, 10, 20),
          );
          await service.refresh();
          expect(service.currentVisit!.tipId, 'meal-lunch');
          expect(service.displayVisit!.tipId, id);
          expect(service.displayVisit!.completed, isTrue);
          expect(service.displayVisit!.completionVersion, 4);
          expect(service.displayVisit!.reasonEn, 'Saved reason');
          expect(service.currentTip!.retired, isTrue);
          expect(service.saved, hasLength(200));
          expect(service.canChoose(id), isFalse);
          expect(jsonEncode(store.value), original);
          expect(store.writes, 0);
        }
      }
    },
  );

  final profiles = <String, TipSafetyProfile>{
    'unknown': const TipSafetyProfile(),
    'minor': const TipSafetyProfile(age: 16, checked: true),
    'adult': const TipSafetyProfile(age: 30, checked: true),
    'pregnancy': const TipSafetyProfile(age: 30, checked: true, pregnant: true),
    'lactation': const TipSafetyProfile(
      age: 30,
      checked: true,
      breastfeeding: true,
    ),
    'eating risk': const TipSafetyProfile(
      age: 30,
      checked: true,
      eatingDisorderRisk: true,
    ),
    'medical restriction': const TipSafetyProfile(
      age: 30,
      checked: true,
      medicalRestriction: true,
    ),
  };
  for (final entry in profiles.entries) {
    test(
      '${entry.key}: incomplete logs retain 137 universal plans after actual filters',
      () async {
        final service = DailyTipsService(store: MemoryTipStore());
        await service.setPersonalized(true);
        await service.refresh(
          context: TipContext(
            hasFood: true,
            loggedFoodDays: 1,
            diaryGaps: true,
            safety: entry.value,
          ),
        );
        final pool = service.eligiblePlans;
        expect(
          pool.where((t) => t.basis == TipBasis.universal),
          hasLength(137),
        );
        expect(
          pool
              .where((t) => t.basis == TipBasis.universal)
              .map((t) => t.topicKey)
              .toSet()
              .length,
          greaterThanOrEqualTo(90),
        );
        expect(pool.every((t) => !t.retired), isTrue);
        expect(pool.every((t) => service.canChoose(t.id)), isTrue);
        expect(pool.any((t) => t.weightManagementOnly), isFalse);
        expect(pool.any((t) => t.basis == TipBasis.variety), isFalse);
        expect(() => pool.clear(), throwsUnsupportedError);
      },
    );
  }

  for (final personalized in [false, true]) {
    test(
      'real catalog: 500 days, 60-day ID/topic window and restart, personalization=$personalized',
      () async {
        var now = DateTime(2026, 1, 1);
        final store = MemoryTipStore();
        var service = DailyTipsService(store: store, now: () => now);
        await service.setPersonalized(personalized);
        const context = TipContext(
          hasFood: true,
          loggedFoodDays: 1,
          diaryGaps: true,
        );
        final visits = <({String id, String topic, TipCategory category})>[];
        for (var day = 0; day < 500; day++) {
          now = DateTime(2026, 1, 1 + day);
          await service.refresh(context: context);
          final tip = service.currentTip!;
          final recent = visits.skip(
            visits.length > 59 ? visits.length - 59 : 0,
          );
          expect(
            recent.map((v) => v.id),
            isNot(contains(tip.id)),
            reason: 'day $day',
          );
          expect(
            recent.map((v) => v.topic),
            isNot(contains(tip.topicKey)),
            reason: 'topic day $day',
          );
          if (visits.isNotEmpty) {
            // Category changes take priority when an alternative survives the topic window.
            final recentTopics = recent.map((v) => v.topic).toSet();
            final other = service.eligiblePlans.any(
              (t) =>
                  !recentTopics.contains(t.topicKey) &&
                  t.category != visits.last.category,
            );
            if (other) {
              expect(
                tip.category,
                isNot(visits.last.category),
                reason: 'category day $day',
              );
            }
          }
          visits.add((id: tip.id, topic: tip.topicKey, category: tip.category));
          if (day % 37 == 0) {
            final snapshot = jsonEncode(store.value);
            service = DailyTipsService(store: store, now: () => now);
            await service.refresh(context: context);
            expect(service.currentTip!.id, tip.id);
            expect(jsonEncode(store.value), snapshot);
          }
        }
        expect(
          visits.map((v) => v.id).toSet(),
          containsAll(
            activeDailyTips
                .where((t) => t.basis == TipBasis.universal)
                .map((t) => t.id),
          ),
        );
      },
    );
  }

  test(
    'restricted pool reports true capacity and falls back without hanging',
    () async {
      var now = DateTime(2026, 1, 1);
      final base = activeDailyTips.first;
      final catalog = [
        for (var i = 0; i < 3; i++)
          DailyTip(
            id: 'limited-$i',
            topic: 'limited-topic-$i',
            category: TipCategory.values[i],
            ru: base.ru,
            en: base.en,
            sourceIds: base.sourceIds,
            evidenceLevel: base.evidenceLevel,
          ),
      ];
      final service = DailyTipsService(
        store: MemoryTipStore(),
        repository: Catalog(catalog),
        now: () => now,
      );
      final ids = <String>[];
      for (var day = 0; day < 70; day++) {
        now = DateTime(2026, 1, 1 + day);
        await service.refresh();
        expect(service.eligiblePlans, hasLength(3));
        if (ids.isNotEmpty) expect(service.currentTip!.id, isNot(ids.last));
        ids.add(service.currentTip!.id);
      }
      expect(ids.toSet(), hasLength(3));
      expect(ids.take(60).toSet().length, lessThan(60));
    },
  );
}
