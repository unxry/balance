import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/daily_tip.dart';
import '../models/weight_trend_insight.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common.dart';
import '../widgets/daily_tip_card.dart';
import 'weight_insights_screen.dart';

class AdviceDetailSheet extends StatelessWidget {
  const AdviceDetailSheet({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    key: const ValueKey('adviceDetailSheet'),
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.line2,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 22),
          const _DailyTipsContent(),
        ],
      ),
    ),
  );
}

class AdviceScreen extends StatelessWidget {
  const AdviceScreen({super.key});
  @override
  Widget build(BuildContext context) => const SafeArea(
    child: SingleChildScrollView(
      key: ValueKey('tipsAdviceScroll'),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 110),
      child: _DailyTipsContent(),
    ),
  );
}

class _DailyTipsContent extends StatelessWidget {
  const _DailyTipsContent();
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText(c);
    final ru = context.watch<SettingsProvider>().lang == AppLang.ru;
    final data = context.watch<AppDataProvider>();
    final service = data.dailyTips;
    final tip = service.currentTip;
    final visit = service.currentVisit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tip != null && visit != null && data.dailyTipsError == null)
          DailyTipCard(tip: tip, visit: visit)
        else
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ru ? 'Совет пока недоступен' : 'Tip unavailable',
                  style: text.fraunces(size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  ru
                      ? 'Не удалось прочитать или сохранить локальные данные.'
                      : 'Could not read or save local data.',
                  style: text.inter(size: 13),
                ),
                TextButton(
                  onPressed: data.refreshDailyTip,
                  child: Text(ru ? 'Повторить' : 'Retry'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        SectionCard(
          radius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ru ? 'Понять свой прогресс' : 'Understand your progress',
                style: text.fraunces(size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                data.weightInsight.title(ru),
                style: text.inter(size: 13, color: c.accent),
              ),
              TextButton.icon(
                key: const ValueKey('openWeightInsights'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const WeightInsightsScreen(),
                  ),
                ),
                icon: Icon(Icons.insights_rounded, color: c.accent),
                label: Text(
                  ru ? 'Почему вес стоит?' : 'Why is weight not changing?',
                ),
              ),
              TextButton.icon(
                key: const ValueKey('openTipLibrary'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const TipLibraryScreen(),
                  ),
                ),
                icon: Icon(Icons.restaurant_outlined, color: c.accent),
                label: Text(
                  ru
                      ? 'Питание и практические идеи'
                      : 'Food and practical ideas',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              key: const ValueKey('tipHistory'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DailyTipsHistoryScreen(),
                ),
              ),
              icon: Icon(Icons.history_rounded, size: 19, color: c.accent),
              label: Text(
                ru ? 'История' : 'History',
                style: text.inter(size: 12, color: c.accent),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('savedTips'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DailyTipsHistoryScreen(savedOnly: true),
                ),
              ),
              icon: Icon(Icons.bookmarks_outlined, size: 18, color: c.accent),
              label: Text(
                ru ? 'Сохранённые' : 'Saved',
                style: text.inter(size: 12, color: c.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile.adaptive(
                  key: const ValueKey('tipPersonalization'),
                  value: service.personalized,
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: c.accent,
                  title: Text(
                    ru ? 'Учитывать мои записи' : 'Use my logged data',
                    style: text.inter(size: 13, weight: FontWeight.w600),
                  ),
                  onChanged: (value) =>
                      tipAction(context, () => data.setTipsPersonalized(value)),
                ),
              ),
              Text(
                ru
                    ? 'Только на устройстве, без отправки данных. Настройка влияет на будущие советы; сегодняшний остаётся прежним.'
                    : 'On your device, without sharing data. This affects future tips; today’s tip stays the same.',
                style: text.inter(size: 11, color: c.fg2, height: 1.5),
              ),
              const SizedBox(height: 14),
              Text(
                ru ? 'На основе' : 'Based on',
                style: text.inter(size: 11, weight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text(
                (ru ? visit?.reasonRu : visit?.reasonEn) ??
                    _basis(visit?.basis ?? TipBasis.universal, ru),
                style: text.inter(size: 11, color: c.accent, height: 1.5),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const TipsSafetyCard(),
      ],
    );
  }
}

String _basis(TipBasis basis, bool ru) => switch (basis) {
  TipBasis.plateau || TipBasis.maintenance || TipBasis.diary || TipBasis.body =>
    ru
        ? 'Основание старой записи не сохранено; актуальная оценка доступна в анализе динамики.'
        : 'The old assignment has no saved rationale; see trend insights for the current assessment.',
  TipBasis.universal =>
    ru
        ? 'Универсальная идея · личные данные не использовались'
        : 'A universal idea · no personal data used',
  TipBasis.food =>
    ru
        ? 'Есть записи питания · без оценки полноты рациона'
        : 'Food entries are available · not an assessment of your diet',
  TipBasis.water =>
    ru
        ? 'Есть записи воды · без оценки гидратации'
        : 'Water entries are available · not an assessment of hydration',
  TipBasis.steps =>
    ru
        ? 'Есть реальные данные шагов · без обязательной нормы'
        : 'Real step data is available · no required target',
  TipBasis.weight =>
    ru
        ? 'Есть история веса · важен контекст нескольких измерений'
        : 'Weight history is available · readings need context',
  TipBasis.gentleFuel =>
    ru
        ? 'В записях питания есть дни ниже цели · дневник может быть неполным'
        : 'Some food logs are below target · entries may be incomplete',
};

class TipsSafetyCard extends StatelessWidget {
  const TipsSafetyCard({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final s = data.tipsSafety;
    final ru = context.watch<SettingsProvider>().lang == AppLang.ru;
    final t = AppText(context.colors);
    Future<void> save({
      bool? pregnant,
      bool? breastfeeding,
      bool? eating,
      bool? medical,
      bool checked = false,
    }) => tipAction(
      context,
      () => data.setTipsSafety(
        TipSafetyProfile(
          age: s.age,
          checked: checked,
          pregnant: pregnant ?? s.pregnant,
          breastfeeding: breastfeeding ?? s.breastfeeding,
          eatingDisorderRisk: eating ?? s.eatingDisorderRisk,
          medicalRestriction: medical ?? s.medicalRestriction,
        ),
      ),
    );
    return SectionCard(
      radius: 24,
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            ru ? 'Применимость советов' : 'Advice suitability',
            style: t.inter(size: 14, weight: FontWeight.w600),
          ),
          subtitle: Text(
            s.allowsWeightManagement
                ? (ru ? 'Контекст уточнён' : 'Context checked')
                : (ru
                      ? 'Общие материалы без персональных норм'
                      : 'General information without personal targets'),
            style: t.inter(size: 11, color: context.colors.fg2),
          ),
          children: [
            Text(
              ru
                  ? 'Необязательная настройка только на устройстве. Ничего не выводится по полу. При неизвестном возрасте, несовершеннолетии или неуточнённых ограничениях советы по снижению веса отключены.'
                  : 'Optional and stored only on this device. Nothing is inferred from sex. Weight-loss suggestions are disabled for unknown age, minors or unchecked restrictions.',
              style: t.inter(size: 12, height: 1.5),
            ),
            for (final item in [
              (
                ru ? 'Беременность' : 'Pregnancy',
                s.pregnant,
                (bool v) => save(pregnant: v),
              ),
              (
                ru ? 'Грудное вскармливание' : 'Breastfeeding',
                s.breastfeeding,
                (bool v) => save(breastfeeding: v),
              ),
              (
                ru
                    ? 'Риск или история нарушений питания'
                    : 'Eating-disorder risk or history',
                s.eatingDisorderRisk,
                (bool v) => save(eating: v),
              ),
              (
                ru ? 'Медицинские ограничения' : 'Medical restrictions',
                s.medicalRestriction,
                (bool v) => save(medical: v),
              ),
            ])
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(item.$1, style: t.inter(size: 12)),
                value: item.$2,
                onChanged: item.$3,
              ),
            TextButton(
              key: const ValueKey('confirmTipsSafety'),
              onPressed: () => save(checked: true),
              child: Text(
                ru
                    ? 'Подтвердить указанный контекст'
                    : 'Confirm the context above',
              ),
            ),
            if (!s.adult)
              Text(
                ru
                    ? 'Возраст не подтверждён как взрослый. Настройка не снимает это ограничение.'
                    : 'Adult age is not confirmed. This setting does not override that restriction.',
                style: t.inter(size: 11, color: context.colors.fg2),
              ),
          ],
        ),
      ),
    );
  }
}

class DailyTipsHistoryScreen extends StatelessWidget {
  final bool savedOnly;
  const DailyTipsHistoryScreen({super.key, this.savedOnly = false});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText(c);
    final ru = context.watch<SettingsProvider>().lang == AppLang.ru;
    final data = context.watch<AppDataProvider>();
    final service = data.dailyTips;
    final seen = <String>{};
    final visits =
        service.history.reversed
            .where(
              (visit) =>
                  service.tipById(visit.tipId) != null &&
                  (!savedOnly ||
                      (service.saved.contains(visit.tipId) &&
                          seen.add(visit.tipId))),
            )
            .toList()
          ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    if (savedOnly) {
      for (final id in service.saved) {
        if (service.tipById(id) != null && seen.add(id)) {
          visits.add(TipVisit(dateKey: '', tipId: id));
        }
      }
    }
    return Scaffold(
      backgroundColor: c.page,
      appBar: AppBar(
        backgroundColor: c.page,
        foregroundColor: c.fg,
        title: Text(
          savedOnly
              ? (ru ? 'Сохранённые идеи' : 'Saved ideas')
              : (ru ? 'История советов' : 'Tip history'),
          style: text.fraunces(size: 23, weight: FontWeight.w700),
        ),
      ),
      body: visits.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  savedOnly
                      ? (ru
                            ? 'Сохраняйте идеи, к которым хочется вернуться.'
                            : 'Save ideas you would like to return to.')
                      : (ru
                            ? 'Здесь появятся показанные советы.'
                            : 'Your daily tips will appear here.'),
                  textAlign: TextAlign.center,
                  style: text.inter(size: 14, color: c.fg2),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: visits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final visit = visits[index];
                final tip = service.tipById(visit.tipId)!;
                return SectionCard(
                  key: ValueKey('tipHistory-${visit.dateKey}-${visit.tipId}'),
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      leading: Icon(
                        visit.completed
                            ? Icons.check_circle_outline_rounded
                            : tipIcon(tip.category),
                        color: c.accent,
                      ),
                      title: Text(
                        tip.copy(ru).title,
                        style: text.inter(size: 14, weight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${visit.dateKey.isEmpty ? (ru ? 'Из библиотеки' : 'From the library') : DateFormat('d MMM y', ru ? 'ru' : 'en').format(DateTime.parse(visit.dateKey))} · ${tip.category.label(ru)}${visit.completed ? (ru ? ' · Выполнено' : ' · Completed') : ''}',
                          style: text.inter(
                            size: 10,
                            color: c.fg2,
                            height: 1.5,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: service.saved.contains(tip.id)
                            ? (ru
                                  ? 'Убрать из сохранённых'
                                  : 'Remove from saved')
                            : (ru ? 'Сохранить' : 'Save'),
                        icon: Icon(
                          service.saved.contains(tip.id)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: c.accent,
                        ),
                        onPressed: () => tipAction(
                          context,
                          () => data.toggleSavedTip(tip.id),
                        ),
                      ),
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: c.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        builder: (_) => SafeArea(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: DailyTipCard(
                              tip: tip,
                              visit: visit,
                              assigned: visit.dateKey.isNotEmpty,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
