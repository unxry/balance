import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../theme/i18n.dart';
import '../widgets/common.dart';
import '../widgets/food_thumb.dart';

class AdviceDetailSheet extends StatelessWidget {
  const AdviceDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final s = S(context.watch<SettingsProvider>().lang);
    final data = context.watch<AppDataProvider>();
    final analytics = data.analyticsForDays(30);
    final advice = analytics.advice;
    final day = data.dashboardDay();
    final sparse = analytics.loggedDays < 3;
    final date =
        '${day.date.day.toString().padLeft(2, '0')}.'
        '${day.date.month.toString().padLeft(2, '0')}.${day.date.year}';
    final basis = <String>[
      s.isRu ? 'Питание' : 'Nutrition',
      s.isRu ? 'Вода' : 'Water',
      s.isRu ? 'Шаги' : 'Steps',
      '${s.isRu ? "Дата" : "Date"} · $date',
      if (analytics.loggedDays >= 3) s.isRu ? 'Тренды' : 'Trends',
    ];
    return SafeArea(
      key: const ValueKey('adviceDetailSheet'),
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: c.line2,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            MonoLabel(s.isRu ? 'СОВЕТ ДНЯ' : 'TIP OF THE DAY'),
            const SizedBox(height: 12),
            Text(
              sparse
                  ? (s.isRu
                        ? 'Набираем контекст — спокойно и без догадок'
                        : 'Building context, calmly and without guesses')
                  : (s.isRu ? 'Фокус на сегодня' : 'Today’s focus'),
              style: t.fraunces(
                size: 23,
                weight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              s.isRu ? advice.ru : advice.en,
              style: t.inter(size: 12, color: c.fg2, height: 1.5),
            ),
            const SizedBox(height: 22),
            Text(
              s.isRu ? 'На основе' : 'Based on',
              style: t.inter(size: 12, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final item in basis)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: c.accentSoft.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: c.accent.withValues(alpha: .12),
                      ),
                    ),
                    child: Text(
                      item,
                      style: t.inter(
                        size: 10,
                        weight: FontWeight.w600,
                        color: c.accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              s.isRu
                  ? 'Почему Balance советует это'
                  : 'Why Balance recommends this',
              style: t.inter(size: 12, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              s.isRu
                  ? sparse
                        ? 'Пока данных немного. Продолжайте записывать питание и вес — советы станут точнее.'
                        : 'Совет учитывает записи за выбранный день и только устойчивые изменения последних недель.'
                  : sparse
                  ? 'There is not much data yet. Keep logging food and weight so tips can become more precise.'
                  : 'The tip reflects this day and only stable changes from recent weeks.',
              style: t.inter(size: 11, color: c.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            Text(
              s.isRu
                  ? 'На что обратить внимание сегодня'
                  : 'What to notice today',
              style: t.inter(size: 12, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _observation(
              c,
              t,
              Icons.restaurant_outlined,
              day.foodEntries.isEmpty
                  ? (s.isRu ? 'Питание пока не записано' : 'No food logged yet')
                  : '${day.caloriesConsumed} / ${day.calorieGoal} ${s.isRu ? "ккал" : "kcal"}',
            ),
            _observation(
              c,
              t,
              Icons.water_drop_outlined,
              '${(day.waterConsumedLiters * 1000).round()} ${s.isRu ? "мл воды" : "ml water"}',
            ),
            _observation(
              c,
              t,
              Icons.directions_walk_rounded,
              day.steps == null
                  ? (s.isRu ? 'Нет данных активности' : 'No activity data')
                  : '${day.steps} ${s.isRu ? "шагов" : "steps"}',
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.accentSoft.withValues(alpha: .62),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.accent.withValues(alpha: .10)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: c.accent),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      s.isRu
                          ? 'Один аккуратно заполненный день полезнее неточной догадки.'
                          : 'One carefully logged day is more useful than an inaccurate guess.',
                      style: t.inter(size: 11, color: c.accent, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _observation(AppColors c, AppText t, IconData icon, String label) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 16, color: c.accent),
            const SizedBox(width: 9),
            Expanded(
              child: Text(label, style: t.inter(size: 11, color: c.fg2)),
            ),
          ],
        ),
      );
}

class AdviceScreen extends StatelessWidget {
  const AdviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final lang = context.watch<SettingsProvider>().lang;
    final s = S(lang);
    final data = context.watch<AppDataProvider>();
    final profile = data.profile;
    final advice = data.analyticsForDays(30).advice;

    final goalText = profile.goal == Goal.lose
        ? (s.isRu
              ? 'СБРОСИТЬ ${(profile.weightKg - profile.targetWeightKg).abs().round()} KG'
              : 'LOSE ${(profile.weightKg - profile.targetWeightKg).abs().round()} KG')
        : profile.goal == Goal.gain
        ? (s.isRu
              ? 'НАБРАТЬ ${(profile.targetWeightKg - profile.weightKg).abs().round()} KG'
              : 'GAIN ${(profile.targetWeightKg - profile.weightKg).abs().round()} KG')
        : (s.isRu ? 'УДЕРЖАТЬ ВЕС' : 'MAINTAIN WEIGHT');

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonoLabel(s.adviceScreen),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.accent, c.accent3],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.isRu ? "ДЛЯ ТВОЕЙ ЦЕЛИ" : "FOR YOUR GOAL"} · $goalText',
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.isRu ? advice.ru : advice.en,
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Balance Coach · ${s.isRu ? "сегодня" : "today"}',
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 9,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              s.recommendedToday,
              style: t.fraunces(size: 17, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _recCard(
              c,
              t,
              s,
              1,
              s.isRu
                  ? 'Лосось на пару с брокколи'
                  : 'Steamed salmon & broccoli',
              s.isRu ? 'Б32 Ж14 У8' : 'P32 F14 C8',
              s.isRu ? '↑ омега-3, ↓ калорийность' : '↑ omega-3, ↓ calories',
            ),
            const SizedBox(height: 8),
            _recCard(
              c,
              t,
              s,
              2,
              s.isRu ? 'Салат с нутом и авокадо' : 'Chickpea avocado salad',
              s.isRu ? 'Б14 Ж18 У30' : 'P14 F18 C30',
              s.isRu ? '↑ клетчатка, долгая сытость' : '↑ fiber, long satiety',
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _rulesColumn(c, t, s.doEat, c.accent, [
                    '🥩 ${s.isRu ? "Белок в каждый приём" : "Protein at every meal"}',
                    '🥦 ${s.isRu ? "Половина тарелки — овощи" : "Half the plate — veggies"}',
                    '🌾 ${s.isRu ? "Цельные крупы" : "Whole grains"}',
                    '💧 ${s.isRu ? "2,5 л воды в день" : "2.5 L water per day"}',
                  ]),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _rulesColumn(c, t, s.avoid, c.accent2, [
                    '🍟 ${s.isRu ? "Фастфуд и трансжиры" : "Fast food & trans fats"}',
                    '🥤 ${s.isRu ? "Сладкие напитки" : "Sugary drinks"}',
                    '🌙 ${s.isRu ? "Плотный ужин после 21:00" : "Heavy dinner after 9pm"}',
                    '🍯 ${s.isRu ? "Скрытый сахар в соусах" : "Hidden sugar in sauces"}',
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              s.howToEat,
              style: t.fraunces(size: 17, weight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _timelineRow(
              c,
              t,
              '08:00',
              s.isRu ? 'Плотный завтрак' : 'Hearty breakfast',
              '30%',
              isFirst: true,
            ),
            _timelineRow(
              c,
              t,
              '13:00',
              s.isRu ? 'Основной обед' : 'Main lunch',
              '40%',
            ),
            _timelineRow(
              c,
              t,
              '19:00',
              s.isRu ? 'Лёгкий ужин' : 'Light dinner',
              '30%',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _recCard(
    dynamic c,
    AppText t,
    S s,
    int seed,
    String name,
    String macros,
    String why,
  ) {
    return SectionCard(
      radius: 18,
      child: Row(
        children: [
          FoodThumb(seed: seed, size: 66, radius: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: t.inter(size: 13, weight: FontWeight.w700)),
                Text(macros, style: t.mono(size: 9)),
                const SizedBox(height: 4),
                Text(
                  why,
                  style: t.inter(
                    size: 11,
                    weight: FontWeight.w600,
                    color: c.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rulesColumn(
    dynamic c,
    AppText t,
    String title,
    Color color,
    List<String> rules,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel(title, color: color),
        const SizedBox(height: 8),
        ...rules.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(r, style: t.inter(size: 12, weight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }

  Widget _timelineRow(
    dynamic c,
    AppText t,
    String time,
    String name,
    String pct, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 50, child: Text(time, style: t.mono(size: 10))),
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.accent, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 1.5, color: c.line)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: t.inter(size: 13, weight: FontWeight.w600),
                    ),
                  ),
                  Text(pct, style: t.mono(size: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
