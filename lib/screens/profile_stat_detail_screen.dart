import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../models/food_models.dart';
import '../models/history_models.dart';
import '../models/user_profile.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import '../theme/i18n.dart';
import '../utils/calendar_date.dart';
import '../widgets/common.dart';
import '../widgets/premium_motion.dart';

enum ProfileStatKind { streak, weightChange, mealsToday, averageSteps }

class ProfileStatDetailScreen extends StatefulWidget {
  final ProfileStatKind kind;
  final VoidCallback onBack;
  final VoidCallback? onOpenDiary;
  final VoidCallback? onOpenWeight;

  const ProfileStatDetailScreen({
    super.key,
    required this.kind,
    required this.onBack,
    this.onOpenDiary,
    this.onOpenWeight,
  });

  @override
  State<ProfileStatDetailScreen> createState() =>
      _ProfileStatDetailScreenState();
}

class _ProfileStatDetailScreenState extends State<ProfileStatDetailScreen> {
  int _stepsPeriod = 7;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = AppText(colors);
    final data = context.watch<AppDataProvider>();
    final strings = S(context.watch<SettingsProvider>().lang);
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _title(strings.isRu),
                    style: text.fraunces(size: 27, weight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            switch (widget.kind) {
              ProfileStatKind.streak => _streak(data, strings, colors, text),
              ProfileStatKind.weightChange => _weight(
                data,
                strings,
                colors,
                text,
              ),
              ProfileStatKind.mealsToday => _meals(data, strings, colors, text),
              ProfileStatKind.averageSteps => _steps(
                data,
                strings,
                colors,
                text,
              ),
            },
          ],
        ),
      ),
    );
  }

  String _title(bool isRu) => switch (widget.kind) {
    ProfileStatKind.streak => isRu ? 'Серия' : 'Streak',
    ProfileStatKind.weightChange => isRu ? 'Изменение веса' : 'Weight change',
    ProfileStatKind.mealsToday => isRu ? 'Блюда сегодня' : 'Meals today',
    ProfileStatKind.averageSteps => isRu ? 'Средние шаги' : 'Average steps',
  };

  Widget _streak(
    AppDataProvider data,
    S strings,
    dynamic colors,
    AppText text,
  ) {
    final active = data.activeDateKeys;
    final days = List.generate(
      30,
      (index) => data.today.subtract(Duration(days: 29 - index)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _metric(
                colors,
                text,
                strings.isRu ? 'ТЕКУЩАЯ' : 'CURRENT',
                '${data.streakDays}',
                strings.isRu ? 'дней' : 'days',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metric(
                colors,
                text,
                strings.isRu ? 'РЕКОРД' : 'RECORD',
                '${data.bestUsefulStreak}',
                strings.isRu ? 'дней' : 'days',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel(strings.isRu ? 'ПОСЛЕДНИЕ 30 ДНЕЙ' : 'LAST 30 DAYS'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 9,
                children: [
                  for (final day in days)
                    Tooltip(
                      message: intl.DateFormat(
                        'd MMM',
                        strings.isRu ? 'ru' : 'en',
                      ).format(day),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active.contains(localDateKey(day))
                              ? colors.accent
                              : colors.track,
                          border: Border.all(
                            color: active.contains(localDateKey(day))
                                ? colors.accent
                                : colors.line2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                strings.isRu
                    ? 'Активным считается день, когда вы записали питание, воду, фактический вес или реальные шаги.'
                    : 'A day is active when you log food, water, actual weight, or real steps.',
                style: text.inter(size: 12, color: colors.fg2, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weight(
    AppDataProvider data,
    S strings,
    dynamic colors,
    AppText text,
  ) {
    final weights = data.weightHistory;
    final start = weights.isEmpty ? data.profile.weightKg : weights.first.kg;
    final current = weights.isEmpty ? data.profile.weightKg : weights.last.kg;
    final signed = current - start;
    final toGoal = (current - data.profile.targetWeightKg).abs();
    final wording = data.profile.goal == Goal.gain
        ? (strings.isRu ? 'Набрано' : 'Gained')
        : data.profile.goal == Goal.lose
        ? (strings.isRu ? 'Сброшено' : 'Lost')
        : (strings.isRu ? 'Изменение' : 'Change');
    final goalRange = (start - data.profile.targetWeightKg).abs();
    final goalProgress = goalRange == 0
        ? 1.0
        : (1 - toGoal / goalRange).clamp(0.0, 1.0);
    final trend = weights.length >= 7 ? data.weightTrend : null;
    return Column(
      children: [
        SectionCard(
          child: Column(
            children: [
              _dataRow(
                text,
                colors,
                strings.isRu ? 'Старт' : 'Start',
                '${start.toStringAsFixed(1)} kg',
              ),
              _dataRow(
                text,
                colors,
                strings.isRu ? 'Сейчас' : 'Now',
                '${current.toStringAsFixed(1)} kg',
              ),
              _dataRow(
                text,
                colors,
                wording,
                '${signed > 0
                    ? '+'
                    : signed < 0
                    ? '−'
                    : ''}${signed.abs().toStringAsFixed(1)} kg',
                accent: true,
              ),
              _dataRow(
                text,
                colors,
                strings.isRu ? 'До цели' : 'To goal',
                '${toGoal.toStringAsFixed(1)} kg',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (weights.length < 2)
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weights.isEmpty
                      ? (strings.isRu
                            ? 'Добавьте первое фактическое измерение'
                            : 'Add your first actual measurement')
                      : (strings.isRu ? 'Собираем данные' : 'Collecting data'),
                  style: text.inter(size: 13, weight: FontWeight.w700),
                ),
                if (weights.length == 1) ...[
                  Column(
                    key: const ValueKey('singleWeightCompactState'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BalanceAnimatedValue(
                        value: '${current.toStringAsFixed(1)} кг',
                        style: text.fraunces(size: 25, weight: FontWeight.w700),
                      ),
                      Text(
                        strings.isRu ? 'Первое измерение' : 'First measurement',
                        style: text.inter(
                          size: 11,
                          color: colors.muted,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BalancePulsePoint(colors: colors),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: goalProgress,
                      backgroundColor: colors.track,
                      valueColor: AlwaysStoppedAnimation(colors.accent),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  strings.isRu
                      ? 'Добавьте ещё одно измерение, чтобы увидеть динамику.'
                      : 'Add one more measurement to see the trend.',
                  style: text.inter(size: 11, color: colors.muted),
                ),
              ],
            ),
          )
        else
          SectionCard(
            child: SizedBox(
              height: 150,
              child: CustomPaint(
                painter: _MiniWeightPainter(
                  weights: weights,
                  color: colors.accent,
                  track: colors.line,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        if (trend != null) ...[
          const SizedBox(height: 14),
          SectionCard(
            child: Text(
              strings.isRu
                  ? 'Тренд: ${trend.delta7DaysKg >= 0 ? '+' : ''}${trend.delta7DaysKg.toStringAsFixed(2)} кг/нед. Прогноз: ${trend.predictedWeightKg.toStringAsFixed(1)} кг.'
                  : 'Trend: ${trend.delta7DaysKg >= 0 ? '+' : ''}${trend.delta7DaysKg.toStringAsFixed(2)} kg/week. Forecast: ${trend.predictedWeightKg.toStringAsFixed(1)} kg.',
              style: text.inter(size: 12, color: colors.fg2, height: 1.4),
            ),
          ),
        ],
        if (widget.onOpenWeight != null) ...[
          const SizedBox(height: 14),
          FilledButton(
            onPressed: widget.onOpenWeight,
            child: Text(
              strings.isRu ? 'Открыть историю веса' : 'Open weight history',
            ),
          ),
        ],
      ],
    );
  }

  Widget _meals(AppDataProvider data, S strings, dynamic colors, AppText text) {
    final entries = data.todayFood;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _metric(
                colors,
                text,
                strings.isRu ? 'ЗАПИСЕЙ' : 'ENTRIES',
                '${entries.length}',
                strings.isRu ? 'сегодня' : 'today',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metric(
                colors,
                text,
                strings.isRu ? 'КАЛОРИИ' : 'CALORIES',
                '${data.caloriesEaten}',
                strings.isRu ? 'ккал' : 'kcal',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            children: [
              _macroSummary(text, colors, data),
              const SizedBox(height: 10),
              for (final meal in MealType.values) ...[
                if (data.mealEntries(meal).isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MonoLabel(_meal(meal, strings.isRu)),
                  ),
                  const SizedBox(height: 6),
                  for (final item in data.mealEntries(meal))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.inter(
                                size: 12,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${item.grams.round()} г · ${item.kcal} ${strings.isRu ? "ккал" : "kcal"}',
                            style: text.mono(size: 8, color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ],
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    strings.isRu
                        ? 'Сегодня записей питания пока нет.'
                        : 'No food entries today.',
                    style: text.inter(size: 12, color: colors.muted),
                  ),
                ),
            ],
          ),
        ),
        if (widget.onOpenDiary != null) ...[
          const SizedBox(height: 14),
          FilledButton(
            onPressed: widget.onOpenDiary,
            child: Text(strings.isRu ? 'Открыть дневник' : 'Open diary'),
          ),
        ],
      ],
    );
  }

  Widget _steps(AppDataProvider data, S strings, dynamic colors, AppText text) {
    final today = data.today;
    final days = List.generate(
      _stepsPeriod,
      (index) => today.subtract(Duration(days: _stepsPeriod - 1 - index)),
    );
    final lookup = {
      for (final day in data.dailyBalances) day.dateKey: day.stepCount,
    };
    if (data.todaySteps != null) {
      lookup[localDateKey(today)] = data.todaySteps;
    }
    final points = [
      for (final day in days) (day, lookup[localDateKey(day)] ?? 0),
    ];
    final loggedPoints = points.where((point) => point.$2 > 0).toList();
    final logged = loggedPoints.map((point) => point.$2).toList();
    final collecting = logged.length < _stepsPeriod;
    final values = collecting
        ? [...logged, ...List<int>.filled(_stepsPeriod - logged.length, 0)]
        : points.map((point) => point.$2).toList();
    final chartDays = collecting
        ? <DateTime?>[
            ...loggedPoints.map((point) => point.$1),
            ...List<DateTime?>.filled(_stepsPeriod - logged.length, null),
          ]
        : points.map<DateTime?>((point) => point.$1).toList();
    final average = logged.isEmpty
        ? null
        : (logged.reduce((a, b) => a + b) / logged.length).round();
    final previousDays = List.generate(
      _stepsPeriod,
      (index) => today.subtract(Duration(days: _stepsPeriod * 2 - 1 - index)),
    );
    final previous = [
      for (final day in previousDays) lookup[localDateKey(day)] ?? 0,
    ].where((value) => value > 0).toList();
    final previousAverage = previous.isEmpty
        ? null
        : previous.reduce((a, b) => a + b) / previous.length;
    final comparable =
        logged.length == _stepsPeriod && previous.length == _stepsPeriod;
    final comparison =
        !comparable ||
            average == null ||
            previousAverage == null ||
            previousAverage == 0
        ? null
        : ((average - previousAverage) / previousAverage * 100).round();
    final oneDay = logged.length == 1;
    final stepTarget = switch (data.profile.activityLevel) {
      ActivityLevel.sedentary => 6000,
      ActivityLevel.light => 8000,
      ActivityLevel.moderate => 10000,
      ActivityLevel.active => 12000,
    };
    final scaleBase = oneDay
        ? math.max(500, logged.first)
        : math.max(
            stepTarget,
            values.isEmpty ? stepTarget : values.reduce(math.max),
          );
    final maxY = math.max(500, scaleBase * 1.12).toDouble();
    return Column(
      children: [
        _stepsPeriodSelector(strings, colors, text),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _metric(
                colors,
                text,
                strings.isRu ? 'СРЕДНЕЕ' : 'AVERAGE',
                average?.toString() ?? '—',
                strings.isRu ? 'шагов / день' : 'steps / day',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metric(
                colors,
                text,
                strings.isRu ? 'К ПРОШЛОМУ ПЕРИОДУ' : 'VS PREVIOUS',
                comparison == null
                    ? (strings.isRu ? 'Недостаточно данных' : 'Not enough data')
                    : '${comparison >= 0 ? '+' : ''}$comparison%',
                strings.isRu ? 'по реальным дням' : 'logged days',
                subdued: comparison == null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: SizedBox(
            height: oneDay ? 132 : 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (oneDay) ...[
                  Text(
                    strings.isRu
                        ? 'Первый день статистики'
                        : 'Your first statistics day',
                    key: const ValueKey('stepsFirstDayState'),
                    style: text.inter(
                      size: 11,
                      weight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        strings.isRu ? 'Сегодня' : 'Today',
                        style: text.inter(size: 11, color: colors.fg2),
                      ),
                      const Spacer(),
                      Text(
                        '${logged.first} ${strings.isRu ? 'шагов' : 'steps'}',
                        style: text.mono(size: 10, color: colors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Expanded(
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: maxY * 1.08,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: _stepsPeriod == 7,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final index = value.round();
                              if (index < 0 || index >= chartDays.length) {
                                return const SizedBox.shrink();
                              }
                              final day = chartDays[index];
                              if (day == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  intl.DateFormat(
                                    'E',
                                    strings.isRu ? 'ru' : 'en',
                                  ).format(day).substring(0, 2),
                                  style: text.inter(
                                    size: 8,
                                    color: colors.muted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => colors.card,
                          tooltipRoundedRadius: 10,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final index = group.x;
                            if (index < 0 || index >= chartDays.length) {
                              return null;
                            }
                            final day = chartDays[index];
                            if (day == null || rod.toY <= 0) return null;
                            return BarTooltipItem(
                              '${intl.DateFormat('d MMM', strings.isRu ? 'ru' : 'en').format(day)}\n${rod.toY.round()} ${strings.isRu ? 'шагов' : 'steps'}',
                              text.inter(size: 10, color: colors.fg),
                            );
                          },
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < values.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: values[i].toDouble(),
                                width: _stepsPeriod == 7 ? 16 : 5,
                                color: values[i] == 0
                                    ? Colors.transparent
                                    : colors.accent,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 420),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepsPeriodSelector(S strings, dynamic colors, AppText text) =>
      Container(
        key: const ValueKey('stepsPeriodSelector'),
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.card2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (_, constraints) => Stack(
            children: [
              AnimatedAlign(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                alignment: _stepsPeriod == 7
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  key: const ValueKey('stepsPeriodCapsule'),
                  width: constraints.maxWidth / 2,
                  decoration: BoxDecoration(
                    color: colors.accentSoft.withValues(alpha: .82),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: colors.accent.withValues(alpha: .16),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final period in [7, 30])
                    Expanded(
                      child: InkWell(
                        key: ValueKey('stepsPeriod-$period'),
                        onTap: () => setState(() => _stepsPeriod = period),
                        borderRadius: BorderRadius.circular(13),
                        child: Center(
                          child: Text(
                            '$period ${strings.isRu ? "дней" : "days"}',
                            style: text.inter(
                              size: 11,
                              weight: _stepsPeriod == period
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _stepsPeriod == period
                                  ? colors.accent
                                  : colors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _metric(
    dynamic colors,
    AppText text,
    String label,
    String value,
    String sub, {
    bool subdued = false,
  }) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel(label),
        const SizedBox(height: 10),
        Text(
          value,
          maxLines: 2,
          style: subdued
              ? text.inter(
                  size: 12,
                  weight: FontWeight.w600,
                  color: colors.muted,
                )
              : text.fraunces(size: 27, weight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(sub, style: text.inter(size: 10, color: colors.muted)),
      ],
    ),
  );

  Widget _dataRow(
    AppText text,
    dynamic colors,
    String label,
    String value, {
    bool accent = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: text.inter(size: 12, color: colors.muted)),
        ),
        Text(
          value,
          style: text.inter(
            size: 13,
            weight: FontWeight.w700,
            color: accent ? colors.accent : colors.fg,
          ),
        ),
      ],
    ),
  );

  Widget _macroSummary(AppText text, dynamic colors, AppDataProvider data) =>
      Row(
        children: [
          for (final item in [
            ('Б', data.proteinEaten, colors.accent),
            ('Ж', data.fatEaten, colors.accent2),
            ('У', data.carbsEaten, colors.macroCarb),
          ])
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: item.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${item.$1} ${item.$2.round()} г',
                    style: text.mono(size: 9),
                  ),
                ],
              ),
            ),
        ],
      );

  String _meal(MealType meal, bool isRu) => switch (meal) {
    MealType.breakfast => isRu ? 'ЗАВТРАК' : 'BREAKFAST',
    MealType.lunch => isRu ? 'ОБЕД' : 'LUNCH',
    MealType.dinner => isRu ? 'УЖИН' : 'DINNER',
    MealType.snack => isRu ? 'ПЕРЕКУСЫ' : 'SNACKS',
  };
}

class _MiniWeightPainter extends CustomPainter {
  final List<WeightEntry> weights;
  final Color color;
  final Color track;

  const _MiniWeightPainter({
    required this.weights,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.isEmpty) return;
    final values = weights.map((entry) => entry.kg).toList();
    final minY = values.reduce(math.min) - .3;
    final maxY = values.reduce(math.max) + .3;
    final span = math.max(.1, maxY - minY);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = weights.length == 1
          ? size.width / 2
          : i / (weights.length - 1) * size.width;
      final y = size.height - (values[i] - minY) / span * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      Paint()
        ..color = track
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniWeightPainter oldDelegate) =>
      oldDelegate.weights != weights || oldDelegate.color != color;
}
