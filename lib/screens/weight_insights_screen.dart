import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/daily_tips_catalog.dart';
import '../models/daily_tip.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common.dart';
import '../widgets/daily_tip_card.dart';
import '../widgets/tip_sources_panel.dart';
import '../utils/calendar_date.dart';
import 'weight_screen.dart';

class WeightInsightsScreen extends StatelessWidget {
  const WeightInsightsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final ru = context.watch<SettingsProvider>().lang == AppLang.ru;
    final c = context.colors, t = AppText(context.colors);
    final insight = data.weightInsight, signals = data.tipContext;
    Widget paragraph(String title, String body) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SectionCard(
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.fraunces(size: 22)),
            const SizedBox(height: 9),
            Text(body, style: t.inter(size: 13, color: c.fg2, height: 1.6)),
          ],
        ),
      ),
    );
    return Scaffold(
      backgroundColor: c.page,
      appBar: AppBar(
        backgroundColor: c.page,
        title: Text(ru ? 'Динамика веса' : 'Weight insights'),
      ),
      body: SingleChildScrollView(
        key: const ValueKey('weightInsightsScroll'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonoLabel(
              ru ? 'НАБЛЮДЕНИЕ БЕЗ ДИАГНОЗОВ' : 'OBSERVATION, NOT DIAGNOSIS',
            ),
            const SizedBox(height: 12),
            Text(
              ru ? 'Почему вес стоит?' : 'Why is weight not changing?',
              style: t.fraunces(size: 32),
            ),
            const SizedBox(height: 18),
            SectionCard(
              radius: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.insights_rounded, color: c.accent, size: 28),
                  const SizedBox(height: 12),
                  Text(
                    insight.title(ru),
                    key: const ValueKey('insightState'),
                    style: t.fraunces(size: 25),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    insight.explanation(ru),
                    style: t.inter(size: 13, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    insight.evidence(ru),
                    style: t.inter(size: 11, color: c.accent, height: 1.6),
                  ),
                  if (insight.weeklyPercent != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${ru ? 'Наблюдаемый наклон' : 'Observed slope'}: ${NumberFormat('0.00', ru ? 'ru' : 'en').format(insight.weeklyPercent)}% / ${ru ? 'нед.' : 'week'}',
                        style: t.inter(size: 11, color: c.fg2),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    insight.limits(ru),
                    style: t.inter(size: 11, color: c.fg2, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${ru ? 'Рассчитано' : 'Calculated'} ${DateFormat('d MMM y', ru ? 'ru' : 'en').format(insight.calculatedAt)}',
                    style: t.inter(size: 10, color: c.muted),
                  ),
                ],
              ),
            ),
            paragraph(
              ru ? 'Что можно сделать?' : 'What can you do?',
              insight.action(ru),
            ),
            paragraph(
              ru ? 'Что известно из дневника' : 'What the log can tell us',
              ru
                  ? 'За 7 завершённых дней записи есть в ${signals.loggedFoodDays}. Полнота каждого дня не подтверждена. ${signals.lowLoggedIntake ? 'В нескольких днях записано мало еды: сначала проверьте полноту и полноценность питания, не уменьшайте рацион. ' : ''}Разных записанных продуктов: ${signals.distinctFoods}. Суммы БЖУ относятся только к записям; по ним не определяется дефицит нутриентов или калорий. ${signals.hasSteps ? 'Есть реальные данные шагов; весь расход энергии неизвестен.' : 'Данных шагов нет; активность не оценивается.'}'
                  : 'Of the last 7 completed days, ${signals.loggedFoodDays} have entries. No day is verified complete. ${signals.lowLoggedIntake ? 'Several low logs call for reviewing completeness and adequate eating, not reducing food. ' : ''}Distinct logged foods: ${signals.distinctFoods}. Macro totals describe entries only; they do not establish nutrient or energy deficits. ${signals.hasSteps ? 'Actual steps exist; total expenditure is unknown.' : 'No step data is available; activity is not inferred.'}',
            ),
            paragraph(
              ru ? 'Почему такое бывает?' : 'Why might this happen?',
              ru
                  ? 'Это возможные объяснения, а не установленные причины в вашем случае. По графику нельзя определить задержку жидкости, гормональные нарушения, точное питание или изменение состава тела.'
                  : 'These are possibilities, not established causes in your case. A chart cannot identify fluid retention, hormonal conditions, exact intake or body-composition change.',
            ),
            for (final article in [
              (
                'facts-fluid',
                ru
                    ? 'Вода и естественные колебания'
                    : 'Fluid and natural fluctuations',
              ),
              (
                'insight-stable',
                ru
                    ? 'Энергопотребности и длительная стабильность'
                    : 'Energy needs and longer stability',
              ),
              (
                'diary-gaps',
                ru ? 'Пробелы и точность дневника' : 'Gaps and diary accuracy',
              ),
              (
                'activity-context',
                ru ? 'Повседневная активность' : 'Everyday activity',
              ),
              (
                'recovery-appetite',
                ru ? 'Сон и восстановление' : 'Sleep and recovery',
              ),
              (
                'recovery-stress',
                ru ? 'Стресс и привычки' : 'Stress and routines',
              ),
              (
                'insight-long',
                ru ? 'Когда стоит получить помощь' : 'When to seek support',
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: SectionCard(
                  radius: 20,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Text(
                        article.$2,
                        style: t.inter(size: 14, weight: FontWeight.w600),
                      ),
                      children: [
                        Text(
                          activeDailyTips
                              .singleWhere((tip) => tip.id == article.$1)
                              .copy(ru)
                              .explanation!,
                          style: t.inter(size: 13, color: c.fg2, height: 1.6),
                        ),
                        const SizedBox(height: 12),
                        TipSourcesPanel(
                          sourceIds: activeDailyTips
                              .singleWhere((tip) => tip.id == article.$1)
                              .sourceIds,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            paragraph(
              ru ? 'Когда нужен специалист' : 'When professional help matters',
              ru
                  ? 'При внезапном необъяснимом изменении веса, отёках, выраженной слабости или других тревожных симптомах обратитесь к врачу. При трудностях с питанием, навязчивом контроле или длительном отсутствии желаемого результата поможет индивидуальная консультация. Не используйте мочегонные, слабительные или усиление ограничений как решение плато.'
                  : 'Seek medical advice for sudden unexplained weight change, swelling, marked weakness or other concerning symptoms. Eating difficulties, compulsive tracking or persistent concerns call for individual support. Diuretics, laxatives and tighter restriction are not plateau solutions.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('openInsightGraph'),
                  icon: const Icon(Icons.show_chart),
                  label: Text(ru ? 'Открыть графики' : 'Open graphs'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (ctx) => Scaffold(
                        backgroundColor: ctx.colors.page,
                        body: WeightScreen(onBack: () => Navigator.pop(ctx)),
                      ),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('openInsightFood'),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(ru ? 'Записи питания' : 'Food records'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const InsightFoodRecordsScreen(),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.restaurant_outlined),
                  label: Text(ru ? 'Идеи питания' : 'Food ideas'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const TipLibraryScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TipLibraryScreen extends StatelessWidget {
  const TipLibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final ru = context.watch<SettingsProvider>().lang == AppLang.ru;
    final data = context.watch<AppDataProvider>();
    final t = AppText(context.colors);
    return Scaffold(
      backgroundColor: context.colors.page,
      appBar: AppBar(
        title: Text(ru ? 'Библиотека советов' : 'Advice library'),
        backgroundColor: context.colors.page,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            ru
                ? 'Идеи для разных привычек и предпочтений. Это общие материалы; источники и ограничения доступны внутри.'
                : 'Ideas for different routines and preferences. These are general materials; sources and limitations appear inside.',
            style: t.inter(size: 13, height: 1.6),
          ),
          for (final category in TipCategory.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 22, bottom: 8),
              child: Text(category.label(ru), style: t.fraunces(size: 24)),
            ),
            for (final tip in activeDailyTips.where(
              (tip) =>
                  tip.category == category && data.dailyTips.isSuitable(tip),
            ))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  tip.copy(ru).title,
                  style: t.inter(size: 14, weight: FontWeight.w600),
                ),
                subtitle: Text(
                  tip.copy(ru).body,
                  style: t.inter(size: 11, color: context.colors.fg2),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TipReadingScreen(tip: tip),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class TipReadingScreen extends StatelessWidget {
  final DailyTip tip;
  const TipReadingScreen({super.key, required this.tip});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.page,
    appBar: AppBar(backgroundColor: context.colors.page),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: DailyTipCard(
        tip: tip,
        assigned: false,
        visit: TipVisit(
          dateKey: localDateKey(context.read<AppDataProvider>().today),
          tipId: tip.id,
        ),
      ),
    ),
  );
}

class InsightFoodRecordsScreen extends StatelessWidget {
  const InsightFoodRecordsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final ru = context.watch<SettingsProvider>().lang == AppLang.ru;
    final t = AppText(context.colors);
    return Scaffold(
      backgroundColor: context.colors.page,
      appBar: AppBar(
        title: Text(ru ? 'Записи питания' : 'Food records'),
        backgroundColor: context.colors.page,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            ru
                ? 'Только записанная еда. Полнота и точное потребление неизвестны.'
                : 'Logged food only. Completeness and actual intake are unknown.',
            style: t.inter(size: 13, height: 1.5),
          ),
          if (data.foodHistoryDateKeys.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                ru ? 'Записей пока нет' : 'No entries yet',
                style: t.fraunces(size: 24),
              ),
            ),
          for (final date in data.foodHistoryDateKeys.reversed) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Text(
                date,
                style: t.inter(size: 14, weight: FontWeight.w600),
              ),
            ),
            for (final e in data.foodEntriesForDate(date))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.name, style: t.inter(size: 13)),
                subtitle: Text(
                  '${e.kcal} ${ru ? 'ккал записано' : 'kcal logged'}',
                  style: t.inter(size: 11, color: context.colors.fg2),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
