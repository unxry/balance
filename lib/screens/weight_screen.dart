import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../models/food_models.dart';
import '../models/history_models.dart';
import '../models/user_profile.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/balance_analytics_service.dart';
import '../services/progress_series.dart';
import '../widgets/progress_chart.dart';
import '../widgets/weight_forecast_note.dart';
import '../widgets/progress_segmented_control.dart';
import 'body_progress_section.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/i18n.dart';
import '../widgets/common.dart';
import '../widgets/premium_motion.dart';
import '../widgets/tab_bar_pill.dart';

export '../widgets/progress_curve.dart' show conservativeWeightCurveSpots;

enum WeightRange { week, month, m3, year }

extension on WeightRange {
  int get days => switch (this) {
    WeightRange.week => 7,
    WeightRange.month => 30,
    WeightRange.m3 => 90,
    WeightRange.year => 365,
  };
}

class WeightScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onEditGoal;
  final bool isActive;
  final int activationEpoch;

  const WeightScreen({
    super.key,
    required this.onBack,
    this.onEditGoal,
    this.isActive = true,
    this.activationEpoch = 1,
  });

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  WeightRange _range = WeightRange.month;
  int _progressMode = 0;
  int _measurementHistoryLimit = 12;
  int _foodHistoryLimit = 14;
  final GlobalKey _analyticsChartKey = GlobalKey();
  final GlobalKey _summaryGraphMotionKey = GlobalKey();
  bool _summaryGraphVisible = false;
  int _lastHandledActivationEpoch = -1;
  int _summaryGraphActivationEpoch = 0;

  @override
  void initState() {
    super.initState();
    _handleActivation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleSummaryGraphVisibilityCheck();
  }

  @override
  void didUpdateWidget(covariant WeightScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleActivation();
    if (!oldWidget.isActive && widget.isActive) {
      _scheduleSummaryGraphVisibilityCheck();
    }
  }

  void _handleActivation() {
    if (!widget.isActive ||
        widget.activationEpoch <= 0 ||
        widget.activationEpoch == _lastHandledActivationEpoch) {
      return;
    }
    _lastHandledActivationEpoch = widget.activationEpoch;
    _summaryGraphActivationEpoch = widget.activationEpoch;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = AppText(colors);
    final data = context.watch<AppDataProvider>();
    final strings = S(context.watch<SettingsProvider>().lang);
    final analytics = data.analyticsForDays(_range.days);
    final history = data.weightHistory;
    final current = history.isEmpty ? data.profile.weightKg : history.last.kg;
    final start = history.isEmpty ? current : history.first.kg;

    return SafeArea(
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _scheduleSummaryGraphVisibilityCheck();
          return false;
        },
        child: CustomScrollView(
          key: const ValueKey('weightHistoryScroll'),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                BalanceRootMetrics.contentBottomInset(context),
              ),
              sliver: SliverList.list(
                children: [
                  _header(colors, strings, data),
                  const SizedBox(height: 18),
                  _progressModes(colors, text, strings),
                  const SizedBox(height: 20),
                  if (_progressMode != 0) ...[
                    _rangeSegment(colors, text, strings),
                    const SizedBox(height: 18),
                    BodyProgressSection(
                      days: _range.days,
                      comparison: _progressMode == 2,
                      isRu: strings.isRu,
                    ),
                  ] else ...[
                    _hero(
                      colors,
                      text,
                      strings,
                      data.profile,
                      current,
                      current - start,
                      data.latestActualWeightDate,
                    ),
                    const SizedBox(height: 24),
                    _rangeSegment(colors, text, strings),
                    const SizedBox(height: 14),
                    KeyedSubtree(
                      key: _analyticsChartKey,
                      child: Container(
                        key: const ValueKey('weightAnalyticsSection'),
                        child: _analyticsChart(
                          colors,
                          text,
                          strings,
                          analytics,
                          data,
                        ),
                      ),
                    ),
                    if (_range == WeightRange.week) ...[
                      const SizedBox(height: 14),
                      _weeklyOverview(colors, text, strings, data),
                    ],
                    const SizedBox(height: 22),
                    _historySection(colors, text, strings, data, analytics),
                    const SizedBox(height: 24),
                    _summaryCards(
                      colors,
                      text,
                      strings,
                      data.profile,
                      analytics,
                      current,
                    ),
                    const SizedBox(height: 26),
                    _factors(colors, text, strings, analytics),
                    const SizedBox(height: 18),
                    _insight(colors, text, strings, analytics),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressModes(AppColors colors, AppText text, S strings) =>
      ProgressSegmentedControl(
        labels: strings.isRu
            ? const ['Вес', 'Замеры', 'Сравнение']
            : const ['Weight', 'Measurements', 'Compare'],
        itemKeys: List.generate(3, (index) => ValueKey('progressMode-$index')),
        selected: _progressMode,
        onChanged: (index) => setState(() => _progressMode = index),
      );

  void _scheduleSummaryGraphVisibilityCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = _summaryGraphMotionKey.currentContext
          ?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final top = renderObject.localToGlobal(Offset.zero).dy;
      final bottom = top + renderObject.size.height;
      final visible =
          widget.isActive &&
          bottom > 0 &&
          top < MediaQuery.sizeOf(context).height - 80;
      if (visible != _summaryGraphVisible) {
        setState(() => _summaryGraphVisible = visible);
      }
    });
  }

  Widget _header(AppColors colors, S strings, AppDataProvider data) {
    return Row(
      children: [
        GhostBackButton(onTap: widget.onBack),
        const SizedBox(width: 12),
        Expanded(child: MonoLabel(strings.isRu ? 'ИСТОРИЯ' : 'HISTORY')),
        Semantics(
          button: true,
          label: _progressMode == 0
              ? (strings.isRu ? 'Добавить вес' : 'Add weight')
              : (strings.isRu ? 'Добавить замер' : 'Add measurement'),
          child: InkWell(
            key: const ValueKey('addWeightButton'),
            onTap: () => _progressMode == 0
                ? _showWeightEditor(context, data)
                : showBodyMeasurementEditor(context, isRu: strings.isRu),
            customBorder: const CircleBorder(),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.fg,
              ),
              child: Icon(Icons.add_rounded, color: colors.surface, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero(
    AppColors colors,
    AppText text,
    S strings,
    UserProfile profile,
    double current,
    double sinceStart,
    DateTime? lastActual,
  ) {
    final startColor = _movementColor(colors, profile.goal, sinceStart);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: BalanceAnimatedValue(
                  value: '${current.toStringAsFixed(1)} kg',
                  style: text.fraunces(
                    size: 52,
                    weight: FontWeight.w800,
                    height: 0.96,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Pill(
                    text: _signedWeight(sinceStart),
                    bg: startColor.withValues(alpha: 0.11),
                    fg: startColor,
                    mono: true,
                  ),
                  Text(
                    strings.sinceStart,
                    style: text.inter(size: 12, color: colors.muted),
                  ),
                ],
              ),
              if (lastActual != null) ...[
                const SizedBox(height: 8),
                Text(
                  strings.isRu
                      ? 'Измерено ${_dateTime(lastActual, true)}'
                      : 'Measured ${_dateTime(lastActual, false)}',
                  style: text.inter(size: 10, color: colors.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MonoLabel(strings.target),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${profile.targetWeightKg.toStringAsFixed(1)} kg',
                style: text.fraunces(
                  size: 25,
                  weight: FontWeight.w800,
                  color: colors.accent2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rangeSegment(AppColors colors, AppText text, S strings) {
    final items = [
      (WeightRange.week, strings.rngWeek),
      (WeightRange.month, strings.rngMonth),
      (WeightRange.m3, strings.rng3m),
      (WeightRange.year, strings.rngYear),
    ];
    return Semantics(
      label: strings.isRu ? 'Период анализа' : 'Analytics period',
      child: ProgressSegmentedControl(
        secondary: true,
        labels: items.map((item) => item.$2).toList(),
        itemKeys: items
            .map((item) => ValueKey('weightRange-${item.$1.name}'))
            .toList(),
        selected: items.indexWhere((item) => item.$1 == _range),
        onChanged: (index) => setState(() => _range = items[index].$1),
      ),
    );
  }

  Widget _analyticsChart(
    AppColors colors,
    AppText text,
    S strings,
    WeightAnalytics analytics,
    AppDataProvider data,
  ) {
    final change = analytics.actualWeightChange;
    final changeColor = _movementColor(colors, data.profile.goal, change);
    return SectionCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      change == null
                          ? '—'
                          : _signedWeight(change, withArrow: true),
                      key: const ValueKey('periodWeightChange'),
                      style: text.fraunces(
                        size: 21,
                        weight: FontWeight.w800,
                        color: change == null ? colors.muted : changeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.isRu
                          ? 'за ${_range.days} дней'
                          : 'over ${_range.days} days',
                      style: text.inter(size: 11, color: colors.muted),
                    ),
                  ],
                ),
              ),
              _legend(colors, text, strings, analytics),
            ],
          ),
          const SizedBox(height: 14),
          _WeightChart(
            analytics: analytics,
            colors: colors,
            isRu: strings.isRu,
          ),
          const SizedBox(height: 10),
          _confidenceLine(colors, text, strings, analytics),
        ],
      ),
    );
  }

  Widget _legend(
    AppColors colors,
    AppText text,
    S strings,
    WeightAnalytics analytics,
  ) {
    final items = <(String, bool, Color)>[
      (strings.isRu ? 'фактический' : 'actual', false, colors.accent),
      if (analytics.forecastPoints.isNotEmpty)
        (
          strings.isRu ? 'прогноз' : 'forecast',
          true,
          colors.accent.withValues(alpha: .55),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 8,
                  child: CustomPaint(
                    painter: _LegendLinePainter(
                      color: item.$3,
                      dashed: item.$2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(item.$1, style: text.inter(size: 9, color: colors.muted)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _confidenceLine(
    AppColors colors,
    AppText text,
    S strings,
    WeightAnalytics analytics,
  ) {
    final count = analytics.actualWeights.length;
    final last = count == 0 ? null : analytics.actualWeights.last;
    final label =
        '${strings.isRu ? 'Измерений' : 'Readings'}: $count'
        '${last == null ? '' : ' · ${strings.isRu ? 'Последнее' : 'Latest'}: ${progressNumber(last.kg, strings.isRu)} ${strings.isRu ? 'кг' : 'kg'}'}';
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: colors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: text.inter(size: 9, color: colors.muted)),
        ),
      ],
    );
  }

  Widget _measurementHistorySection(
    AppColors colors,
    AppText text,
    S strings,
    AppDataProvider data,
    WeightAnalytics analytics,
  ) {
    final allEntries = analytics.actualWeights.reversed.toList();
    final entries = allEntries.take(_measurementHistoryLimit).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entries.isEmpty)
          _historyEmptyCard(
            colors,
            text,
            data.weightHistory.isEmpty
                ? (strings.isRu
                      ? 'Добавьте первое измерение веса'
                      : 'Add your first weight measurement')
                : (strings.isRu
                      ? 'Нет измерений за этот период'
                      : 'No measurements in this period'),
          )
        else
          for (final entry in entries) ...[
            _measurementRow(colors, text, strings, data, entry),
            const SizedBox(height: 9),
          ],
        if (allEntries.length > entries.length)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              key: const ValueKey('weightMeasurementsButton'),
              onPressed: () => setState(() => _measurementHistoryLimit += 12),
              child: Text(strings.isRu ? 'Показать ещё' : 'Show more'),
            ),
          ),
      ],
    );
  }

  Widget _weeklyOverview(
    AppColors colors,
    AppText text,
    S strings,
    AppDataProvider data,
  ) {
    final today = _day(data.today);
    final days = [
      for (var offset = 6; offset >= 0; offset--)
        DateTime(today.year, today.month, today.day - offset),
    ];
    WeightEntry? measurement(DateTime date) {
      for (final entry in data.weightHistory.reversed) {
        if (_day(entry.date) == date) return entry;
      }
      return null;
    }

    return SectionCard(
      key: const ValueKey('weightWeeklyOverview'),
      radius: 22,
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel(strings.isRu ? '7 ДНЕЙ' : '7 DAYS'),
          const SizedBox(height: 13),
          Row(
            children: [
              for (final date in days)
                Expanded(
                  child: Builder(
                    builder: (_) {
                      final entry = measurement(date);
                      final current = date == today;
                      return Column(
                        children: [
                          Text(
                            intl.DateFormat(
                              'E',
                              strings.isRu ? 'ru' : 'en',
                            ).format(date).substring(0, 2).toUpperCase(),
                            style: text.mono(
                              size: 7,
                              color: current ? colors.accent : colors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: entry == null ? 7 : 11,
                            height: entry == null ? 7 : 11,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: entry == null
                                  ? colors.track
                                  : colors.accent,
                              border: current
                                  ? Border.all(color: colors.card, width: 2)
                                  : null,
                              boxShadow: current && entry != null
                                  ? [
                                      BoxShadow(
                                        color: colors.accent.withValues(
                                          alpha: .18,
                                        ),
                                        blurRadius: 7,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            entry == null ? '—' : entry.kg.toStringAsFixed(1),
                            style: text.inter(
                              size: 8,
                              weight: entry == null
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: entry == null ? colors.muted : colors.fg,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
          if (days.where((date) => measurement(date) != null).length < 2) ...[
            const SizedBox(height: 12),
            Text(
              strings.isRu
                  ? 'Для недельной линии нужно ещё одно измерение'
                  : 'Add one more measurement for a weekly line',
              style: text.inter(size: 9, color: colors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _historySection(
    AppColors colors,
    AppText text,
    S strings,
    AppDataProvider data,
    WeightAnalytics analytics,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.isRu ? 'ИЗМЕРЕНИЯ' : 'MEASUREMENTS',
          key: const ValueKey('weightMeasurementsHistory'),
          style: text.mono(size: 10, color: colors.muted),
        ),
        const SizedBox(height: 10),
        _measurementHistorySection(colors, text, strings, data, analytics),
        const SizedBox(height: 24),
        _foodHistorySection(colors, text, strings, data),
      ],
    );
  }

  Widget _measurementRow(
    AppColors colors,
    AppText text,
    S strings,
    AppDataProvider data,
    WeightEntry entry,
  ) {
    final all = data.weightHistory;
    final index = all.indexWhere((value) => value.id == entry.id);
    final delta = index > 0 ? entry.kg - all[index - 1].kg : null;
    return PressableScale(
      key: ValueKey('measurement-${entry.id}'),
      pressedScale: .985,
      onTap: () => _showWeightEditor(context, data, entry: entry),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dateLong(entry.date, strings.isRu),
                    style: text.inter(size: 12, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (delta != null)
              Text(
                _signedWeight(delta, withArrow: true),
                style: text.inter(
                  size: 10,
                  color: _movementColor(colors, data.profile.goal, delta),
                ),
              ),
            const SizedBox(width: 12),
            Text(
              '${entry.kg.toStringAsFixed(1)} kg',
              style: text.fraunces(size: 17, weight: FontWeight.w800),
            ),
            const SizedBox(width: 3),
            Icon(Icons.chevron_right_rounded, size: 18, color: colors.muted),
          ],
        ),
      ),
    );
  }

  Widget _foodHistorySection(
    AppColors colors,
    AppText text,
    S strings,
    AppDataProvider data,
  ) {
    final firstDate = ProgressWindow(days: _range.days, now: data.today).start;
    final keys = data.foodHistoryDateKeys.where((key) {
      final date = _dateFromKey(key);
      return date != null &&
          !date.isBefore(firstDate) &&
          !date.isAfter(data.today);
    }).toList();
    final visible = keys.take(_foodHistoryLimit).toList();
    return Column(
      key: const ValueKey('weightFoodHistory'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.isRu ? 'ИСТОРИЯ ПИТАНИЯ' : 'FOOD HISTORY',
          style: text.mono(size: 10, color: colors.muted),
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          _historyEmptyCard(
            colors,
            text,
            strings.isRu ? 'Пока нет записей питания.' : 'No food entries yet.',
          )
        else
          for (final key in visible) ...[
            _foodDayCard(colors, text, strings, data, key),
            const SizedBox(height: 9),
          ],
        if (keys.length > visible.length)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              key: const ValueKey('moreFoodHistoryButton'),
              onPressed: () => setState(() => _foodHistoryLimit += 14),
              child: Text(strings.isRu ? 'Показать ещё' : 'Show more'),
            ),
          ),
      ],
    );
  }

  Widget _foodDayCard(
    AppColors colors,
    AppText text,
    S strings,
    AppDataProvider data,
    String dateKey,
  ) {
    final date = _dateFromKey(dateKey)!;
    final day = data.dashboardDay(date);
    final mealCount = day.foodEntries.map((entry) => entry.meal).toSet().length;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          InkWell(
            key: ValueKey('food-history-$dateKey'),
            onTap: () =>
                _showFoodDaySheet(colors, text, strings, date, day.foodEntries),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dateLong(date, strings.isRu),
                          style: text.inter(size: 12, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${day.caloriesConsumed} / ${day.calorieGoal} ${strings.isRu ? "ккал" : "kcal"}',
                          style: text.fraunces(
                            size: 17,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${strings.isRu ? "Б" : "P"} ${day.protein.round()} · '
                          '${strings.isRu ? "Ж" : "F"} ${day.fat.round()} · '
                          '${strings.isRu ? "У" : "C"} ${day.carbs.round()}  ·  '
                          '$mealCount ${strings.isRu ? "приёмов" : "meals"}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.mono(size: 8, color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colors.muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFoodDaySheet(
    AppColors colors,
    AppText text,
    S strings,
    DateTime date,
    List<FoodEntry> entries,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
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
                  color: colors.line2,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _dateLong(date, strings.isRu),
              style: text.fraunces(size: 23, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _foodDayDetails(colors, text, strings, entries),
          ],
        ),
      ),
    ),
  );

  Widget _foodDayDetails(
    AppColors colors,
    AppText text,
    S strings,
    List<FoodEntry> entries,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colors.line.withValues(alpha: .6)),
          for (final meal in MealType.values)
            if (entries.any((entry) => entry.meal == meal)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 5),
                child: Text(
                  _mealName(meal, strings),
                  style: text.mono(size: 8, color: colors.muted),
                ),
              ),
              for (final entry in entries.where((item) => item.meal == meal))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.inter(size: 11, weight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${entry.grams.round()} ${strings.isRu ? "г" : "g"} · ${entry.kcal}',
                        style: text.mono(size: 8),
                      ),
                    ],
                  ),
                ),
            ],
        ],
      ),
    );
  }

  Widget _historyEmptyCard(AppColors colors, AppText text, String label) =>
      SectionCard(
        radius: 18,
        padding: const EdgeInsets.all(16),
        child: Text(label, style: text.inter(size: 11, color: colors.muted)),
      );

  String _mealName(MealType meal, S strings) => switch (meal) {
    MealType.breakfast => strings.breakfast,
    MealType.lunch => strings.lunch,
    MealType.snack => strings.snack,
    MealType.dinner => strings.dinner,
  };

  Widget _summaryCards(
    AppColors colors,
    AppText text,
    S strings,
    UserProfile profile,
    WeightAnalytics analytics,
    double current,
  ) {
    final change = analytics.actualWeightChange;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _summaryCard(
                    colors,
                    text,
                    value: change == null ? '—' : _signedWeight(change),
                    label: strings.isRu ? 'за период' : 'for period',
                    icon: Icons.show_chart_rounded,
                    color: colors.accent,
                    compact: compact,
                    semanticsLabel: strings.isRu
                        ? 'Открыть динамику веса'
                        : 'Open weight trend',
                    onTap: _scrollToAnalytics,
                  ),
                  const SizedBox(width: 8),
                  _summaryCard(
                    colors,
                    text,
                    value:
                        '${(current - profile.targetWeightKg).abs().toStringAsFixed(1)} kg',
                    label: strings.isRu ? 'до цели' : 'to goal',
                    icon: Icons.flag_outlined,
                    color: colors.accent2,
                    compact: compact,
                    semanticsLabel: strings.isRu
                        ? 'Открыть цель по весу'
                        : 'Open weight goal',
                    onTap: () => _showGoalDetail(
                      colors,
                      text,
                      strings,
                      profile,
                      current,
                      context.read<AppDataProvider>(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _summaryCard(
                    colors,
                    text,
                    value: analytics.forecastPoints.isEmpty
                        ? '—'
                        : '${analytics.forecastPoints.length - 1} ${strings.isRu ? "дн" : "days"}',
                    label: analytics.forecastPoints.isEmpty
                        ? (strings.isRu
                              ? 'нужно больше данных'
                              : 'more data needed')
                        : (strings.isRu
                              ? 'горизонт прогноза'
                              : 'forecast horizon'),
                    icon: Icons.schedule_rounded,
                    color: colors.accent,
                    compact: compact,
                    semanticsLabel: strings.isRu
                        ? 'Открыть прогноз'
                        : 'Open forecast',
                    onTap: () =>
                        _showForecastDetail(colors, text, strings, analytics),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    AppColors colors,
    AppText text, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required bool compact,
    required String semanticsLabel,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        label: semanticsLabel,
        child: PressableScale(
          onTap: onTap,
          pressedScale: .985,
          child: SectionCard(
            radius: 18,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 7 : 10,
              vertical: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BalanceSummaryMotionIcon(
                  key: icon == Icons.show_chart_rounded
                      ? _summaryGraphMotionKey
                      : null,
                  kind: icon == Icons.show_chart_rounded
                      ? BalanceSummaryMotionKind.graph
                      : icon == Icons.flag_outlined
                      ? BalanceSummaryMotionKind.flag
                      : BalanceSummaryMotionKind.clock,
                  color: color,
                  isActive:
                      icon != Icons.show_chart_rounded ||
                      (widget.isActive && _summaryGraphVisible),
                  activationEpoch: icon == Icons.show_chart_rounded
                      ? _summaryGraphActivationEpoch
                      : 0,
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: text.fraunces(
                      size: compact ? 17 : 20,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: text.inter(
                    size: compact ? 8 : 9,
                    color: colors.muted,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToAnalytics() {
    final chartContext = _analyticsChartKey.currentContext;
    if (chartContext == null) return;
    Scrollable.ensureVisible(
      chartContext,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      alignment: .04,
    );
  }

  // ignore: unused_element
  Future<void> _showPeriodDetail(
    AppColors colors,
    AppText text,
    S strings,
    WeightAnalytics analytics,
    AppDataProvider data,
    double current,
  ) {
    final measurements = analytics.actualWeights;
    final start = measurements.isEmpty ? current : measurements.first.kg;
    return _showSummarySheet(
      colors,
      text,
      title: strings.isRu ? 'Динамика веса' : 'Weight trend',
      child: Column(
        children: [
          _analyticsChart(colors, text, strings, analytics, data),
          const SizedBox(height: 14),
          _detailRow(
            colors,
            text,
            strings.isRu ? 'Начало' : 'Start',
            '${start.toStringAsFixed(1)} kg',
          ),
          _detailRow(
            colors,
            text,
            strings.isRu ? 'Сейчас' : 'Current',
            '${current.toStringAsFixed(1)} kg',
          ),
          _detailRow(
            colors,
            text,
            strings.isRu ? 'Изменение' : 'Change',
            analytics.actualWeightChange == null
                ? '—'
                : _signedWeight(analytics.actualWeightChange!),
          ),
          _detailRow(
            colors,
            text,
            strings.isRu ? 'Измерений' : 'Measurements',
            '${measurements.length}',
          ),
          if (measurements.length < 2)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                strings.isRu
                    ? 'Добавьте ещё измерения, чтобы увидеть надёжную динамику.'
                    : 'Add more measurements to see a reliable trend.',
                style: text.inter(size: 11, color: colors.muted, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showGoalDetail(
    AppColors colors,
    AppText text,
    S strings,
    UserProfile profile,
    double current,
    AppDataProvider data,
  ) {
    final initial = data.weightHistory.isEmpty
        ? current
        : data.weightHistory.first.kg;
    final total = (initial - profile.targetWeightKg).abs();
    final remaining = (current - profile.targetWeightKg).abs();
    final progress = total <= .05
        ? 1.0
        : ((total - remaining) / total).clamp(0.0, 1.0);
    return _showSummarySheet(
      colors,
      text,
      title: strings.isRu ? 'Цель по весу' : 'Weight goal',
      child: Column(
        children: [
          _detailRow(
            colors,
            text,
            strings.isRu ? 'Сейчас' : 'Current',
            '${current.toStringAsFixed(1)} kg',
          ),
          _detailRow(
            colors,
            text,
            strings.isRu ? 'Цель' : 'Goal',
            '${profile.targetWeightKg.toStringAsFixed(1)} kg',
          ),
          _detailRow(
            colors,
            text,
            strings.isRu ? 'Осталось' : 'Remaining',
            '${remaining.toStringAsFixed(1)} kg',
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: colors.track,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: strings.isRu ? 'Изменить цель' : 'Edit goal',
            icon: Icons.edit_outlined,
            onTap: widget.onEditGoal == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    widget.onEditGoal!();
                  },
          ),
        ],
      ),
    );
  }

  Future<void> _showForecastDetail(
    AppColors colors,
    AppText text,
    S strings,
    WeightAnalytics analytics,
  ) => _showSummarySheet(
    colors,
    text,
    title: strings.isRu ? 'Прогноз' : 'Forecast',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WeightForecastNote(
          snapshot: analytics.forecast ?? const WeightForecastSnapshot(),
          isRu: strings.isRu,
          active: analytics.forecastPoints.isNotEmpty,
          horizonDays: analytics.forecastPoints.length - 1,
        ),
        const SizedBox(height: 14),
        Text(
          strings.isRu
              ? 'Медиана за сутки и робастная оценка Theil–Sen по последним 28 дням. Минимум 4 дня с измерениями за 7 календарных дней. Расчёт обновляется раз в 4 дня при новых записях; исправления и удаления проверяются сразу. Продолжение строится от последнего реального веса с сохранённым темпом.'
              : 'Daily medians and a robust Theil–Sen trend over the last 28 days. At least 4 measured days across 7 calendar days. The fit updates every 4 days when new data exists; edits and deletions are checked immediately. The continuation starts at the latest real weight using the saved rate.',
          style: text.inter(size: 12, color: colors.fg2, height: 1.5),
        ),
      ],
    ),
  );

  Future<void> _showSummarySheet(
    AppColors colors,
    AppText text, {
    required String title,
    required Widget child,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
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
                  color: colors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: text.fraunces(size: 24, weight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );

  Widget _detailRow(
    AppColors colors,
    AppText text,
    String label,
    String value,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: text.inter(size: 12, color: colors.muted)),
        ),
        Text(value, style: text.inter(size: 12, weight: FontWeight.w700)),
      ],
    ),
  );

  Widget _factors(
    AppColors colors,
    AppText text,
    S strings,
    WeightAnalytics analytics,
  ) {
    final calorieValue = analytics.averageCalorieBalance == null
        ? '—'
        : '${_signedNumber(analytics.averageCalorieBalance!.round())} ${strings.isRu ? "ккал/день от цели" : "kcal/day vs target"}';
    final activityValue = analytics.averageSteps == null
        ? (strings.isRu ? 'нет данных HealthKit' : 'no HealthKit data')
        : '${_compactInt(analytics.averageSteps!.round())} ${strings.isRu ? "шагов/день" : "steps/day"}';
    final waterValue = analytics.averageWater == null
        ? '—'
        : '${analytics.averageWater!.toStringAsFixed(1)} ${strings.isRu ? "л/день" : "L/day"} · ${(analytics.waterGoalAdherence * 100).round()}%';
    final weightValue = analytics.smoothedWeightChange == null
        ? '—'
        : '${_signedWeight(analytics.smoothedWeightChange!)} / ${_range.days} ${strings.isRu ? "дн" : "d"}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.isRu ? 'Что влияет на динамику' : 'What shapes the trend',
          style: text.fraunces(size: 19, weight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SectionCard(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              _factorRow(
                colors,
                text,
                Icons.restaurant_outlined,
                strings.isRu ? 'Питание' : 'Nutrition',
                calorieValue,
              ),
              _divider(colors),
              _factorRow(
                colors,
                text,
                Icons.directions_walk_rounded,
                strings.isRu ? 'Активность' : 'Activity',
                activityValue,
              ),
              _divider(colors),
              _factorRow(
                colors,
                text,
                Icons.water_drop_outlined,
                strings.isRu ? 'Вода' : 'Water',
                waterValue,
              ),
              _divider(colors),
              _factorRow(
                colors,
                text,
                Icons.monitor_weight_outlined,
                strings.isRu ? 'Вес' : 'Weight',
                weightValue,
              ),
            ],
          ),
        ),
        if (analytics.averageCalories != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _detailChip(
                colors,
                text,
                '${analytics.averageCalories!.round()} ${strings.isRu ? "ккал" : "kcal"}',
                strings.isRu ? 'среднее' : 'average',
              ),
              _detailChip(
                colors,
                text,
                '${analytics.averageProtein?.round() ?? 0} ${strings.isRu ? "г" : "g"}',
                strings.isRu ? 'белок/день' : 'protein/day',
              ),
              _detailChip(
                colors,
                text,
                '${(analytics.foodTargetAdherence * 100).round()}%',
                strings.isRu ? 'дней в цели' : 'days on target',
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _factorRow(
    AppColors colors,
    AppText text,
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 17, color: colors.accent),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: text.inter(size: 12, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: text.inter(size: 11, color: colors.fg2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppColors colors) =>
      Divider(height: 1, color: colors.line.withValues(alpha: 0.55));

  Widget _detailChip(
    AppColors colors,
    AppText text,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: text.inter(size: 10, color: colors.fg),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: '  $label',
              style: TextStyle(color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insight(
    AppColors colors,
    AppText text,
    S strings,
    WeightAnalytics analytics,
  ) {
    return Container(
      key: const ValueKey('balanceInsight'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: colors.accentSoft.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 17, color: colors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.isRu ? 'Наблюдение Balance' : 'Balance observation',
                  style: text.inter(size: 12, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            strings.isRu ? analytics.insightRu : analytics.insightEn,
            style: text.inter(size: 12, color: colors.fg2, height: 1.45),
          ),
        ],
      ),
    );
  }

  // Kept for backward-compatible deep links; the main history now paginates inline.
  // ignore: unused_element
  Future<void> _showMeasurements(
    BuildContext context,
    AppDataProvider data,
  ) async {
    final colors = context.colors;
    final strings = S(context.read<SettingsProvider>().lang);
    final text = AppText(colors);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          final entries = data.weightHistory.reversed.toList();
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.line2,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.isRu ? 'История измерений' : 'Measurements',
                        style: text.fraunces(size: 21, weight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          strings.isRu
                              ? 'Пока нет измерений'
                              : 'No measurements yet',
                          style: text.inter(color: colors.muted),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) =>
                            Divider(color: colors.line.withValues(alpha: 0.6)),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _dateLong(entry.date, strings.isRu),
                              style: text.inter(
                                size: 12,
                                weight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              entry.source == WeightEntrySource.manual
                                  ? (strings.isRu ? 'вручную' : 'manual')
                                  : (strings.isRu ? 'импорт' : 'imported'),
                              style: text.inter(size: 9, color: colors.muted),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${entry.kg.toStringAsFixed(1)} kg',
                                  style: text.fraunces(
                                    size: 18,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: colors.muted,
                                ),
                              ],
                            ),
                            onTap: () async {
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                              await _showWeightEditor(
                                this.context,
                                data,
                                entry: entry,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showWeightEditor(
    BuildContext context,
    AppDataProvider data, {
    WeightEntry? entry,
  }) async {
    final editing = entry != null;
    final controller = TextEditingController(
      text: (entry?.kg ?? data.profile.weightKg).toStringAsFixed(1),
    );
    final colors = context.colors;
    final strings = S(context.read<SettingsProvider>().lang);
    var selectedDate = entry?.date.toLocal() ?? DateTime.now();
    String? error;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) {
            final text = AppText(colors);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.line2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    editing
                        ? (strings.isRu
                              ? 'Изменить измерение'
                              : 'Edit measurement')
                        : (strings.isRu ? 'Добавить вес' : 'Add weight'),
                    style: text.fraunces(size: 22, weight: FontWeight.w800),
                  ),
                  if (editing) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${strings.isRu ? "Добавлено" : "Added"}: '
                      '${_dateLong(entry.createdAt, strings.isRu)}',
                      style: text.inter(size: 10, color: colors.muted),
                    ),
                  ],
                  const SizedBox(height: 18),
                  LabeledNumberField(
                    label: strings.isRu ? 'Вес' : 'Weight',
                    controller: controller,
                    unit: 'kg',
                    autofocus: !editing,
                    errorText: error,
                    onChanged: (_) {
                      if (error != null) {
                        setSheetState(() => error = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.isRu ? 'Дата' : 'Date',
                    style: text.inter(size: 12, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    key: const ValueKey('weightDateField'),
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate.isAfter(now)
                            ? now
                            : selectedDate,
                        firstDate: DateTime(now.year - 50),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setSheetState(
                          () => selectedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            selectedDate.hour,
                            selectedDate.minute,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: colors.card2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.line.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 17,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _dateLong(selectedDate, strings.isRu),
                              style: text.inter(
                                size: 13,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    key: const ValueKey('saveWeightButton'),
                    label: strings.save,
                    icon: Icons.check_rounded,
                    onTap: () async {
                      final kg = double.tryParse(
                        controller.text.replaceAll(',', '.'),
                      );
                      final saved =
                          kg != null &&
                          (editing
                              ? await data.updateWeightEntry(
                                  entry.id,
                                  kg: kg,
                                  date: selectedDate,
                                )
                              : await data.addWeightEntry(
                                  kg,
                                  date: selectedDate,
                                ));
                      if (!saved) {
                        setSheetState(() => error = '20–400 kg');
                        return;
                      }
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                  if (editing) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        key: const ValueKey('deleteWeightButton'),
                        onPressed: () async {
                          final confirmed = await _confirmWeightDeletion(
                            context,
                            colors,
                            text,
                            strings,
                            entry,
                          );
                          if (confirmed == true &&
                              await data.deleteWeightEntry(entry.id) &&
                              sheetContext.mounted) {
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          }
                        },
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: colors.accent2,
                        ),
                        label: Text(
                          strings.isRu
                              ? 'Удалить измерение'
                              : 'Delete measurement',
                          style: text.inter(
                            size: 12,
                            color: colors.accent2,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<bool> _confirmWeightDeletion(
    BuildContext context,
    AppColors colors,
    AppText text,
    S strings,
    WeightEntry entry,
  ) async =>
      await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.isRu ? 'Удалить измерение?' : 'Delete measurement?',
                  style: text.fraunces(size: 22, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.isRu
                      ? '${entry.kg.toStringAsFixed(1)} кг · ${_dateLong(entry.date, true)}. Питание, вода и шаги этого дня останутся.'
                      : '${entry.kg.toStringAsFixed(1)} kg · ${_dateLong(entry.date, false)}. Food, water and steps for this day will remain.',
                  style: text.inter(size: 12, color: colors.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  key: const ValueKey('confirmDeleteWeightButton'),
                  label: strings.isRu
                      ? 'Удалить измерение'
                      : 'Delete measurement',
                  icon: Icons.delete_outline_rounded,
                  onTap: () => Navigator.pop(sheetContext, true),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const ValueKey('cancelDeleteWeightButton'),
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: Text(strings.isRu ? 'Отмена' : 'Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;

  Color _movementColor(AppColors colors, Goal goal, double? change) {
    if (change == null || change.abs() < 0.1) return colors.muted;
    final toward = switch (goal) {
      Goal.lose => change < 0,
      Goal.gain => change > 0,
      Goal.hold => change.abs() <= 0.3,
    };
    return toward ? colors.accent : colors.accent2;
  }
}

class _WeightChart extends StatelessWidget {
  final WeightAnalytics analytics;
  final AppColors colors;
  final bool isRu;

  const _WeightChart({
    required this.analytics,
    required this.colors,
    required this.isRu,
  });

  @override
  Widget build(BuildContext context) {
    final window = ProgressWindow(
      days: analytics.periodDays,
      now: DateTime(
        analytics.periodStart.year,
        analytics.periodStart.month,
        analytics.periodStart.day + analytics.periodDays - 1,
      ),
    );
    final points = [
      for (final entry in analytics.actualWeights)
        ProgressPoint(entry.id, entry.date, entry.kg),
    ];
    final forecast = forecastInProgressView(
      window,
      points,
      analytics.forecastPoints,
    );
    return KeyedSubtree(
      key: const ValueKey('weightFullChart'),
      child: Column(
        children: [
          ProgressChart(
            window: window,
            lines: [
              ProgressLine(
                label: isRu ? 'Вес' : 'Weight',
                color: colors.accent,
                points: points,
              ),
            ],
            unit: isRu ? 'кг' : 'kg',
            isRu: isRu,
            forecast: forecast,
            height: 202,
          ),
          const SizedBox(height: 12),
          WeightForecastNote(
            snapshot: analytics.forecast ?? const WeightForecastSnapshot(),
            isRu: isRu,
            active: forecast.isNotEmpty,
            horizonDays: analytics.forecastPoints.length - 1,
            displayedDays: forecast.length - 1,
            emptyPeriod: points.isEmpty,
            limitedPeriod:
                analytics.forecastPoints.isNotEmpty && forecast.isEmpty,
            onRetry: () =>
                context.read<AppDataProvider>().refreshWeightForecast(),
          ),
        ],
      ),
    );
  }
}

class _DataCollectionStory extends StatefulWidget {
  final AppColors colors;
  final bool isRu;

  const _DataCollectionStory({required this.colors, required this.isRu});

  @override
  State<_DataCollectionStory> createState() => _DataCollectionStoryState();
}

class _DataCollectionStoryState extends State<_DataCollectionStory>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate) {
      _controller
        ..stop()
        ..value = .62;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      key: const ValueKey('weightDataCollectionStory'),
      animation: _controller,
      builder: (_, __) {
        final phase = reduce ? .62 : _controller.value;
        final breathing = .72 + .18 * (1 - cos(phase * pi * 2)) / 2;
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isRu ? 'Собираем данные' : 'Collecting data',
                style: AppText(widget.colors).inter(
                  size: 11,
                  color: widget.colors.muted.withValues(alpha: breathing),
                ),
              ),
              const SizedBox(width: 6),
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Transform.scale(
                    scale: reduce ? 1 : .85 + .15 * _sequentialDot(phase, i),
                    child: Container(
                      key: ValueKey('collectingDot-$i'),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.colors.accent.withValues(
                          alpha: .18 + .62 * _sequentialDot(phase, i),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _sequentialDot(double phase, int index) {
    final local = (phase - index * .14) % 1;
    if (local >= .42) return 0;
    return sin(local / .42 * pi).clamp(0, 1);
  }
}

class _CollectingWeightPoint extends StatefulWidget {
  const _CollectingWeightPoint({required this.colors, required this.visible});

  final AppColors colors;
  final bool visible;

  @override
  State<_CollectingWeightPoint> createState() => _CollectingWeightPointState();
}

class _CollectingWeightPointState extends State<_CollectingWeightPoint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  );
  Timer? _pause;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _CollectingWeightPoint oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate =
        widget.visible &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate) {
      _play();
    } else {
      _pause?.cancel();
      _pause = null;
      _controller.stop();
      _controller.value = 0;
    }
  }

  void _play() {
    if (_controller.isAnimating || _pause != null) return;
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _pause = Timer(const Duration(milliseconds: 250), () {
        _pause = null;
        if (mounted &&
            widget.visible &&
            !MediaQuery.disableAnimationsOf(context) &&
            TickerMode.valuesOf(context).enabled) {
          _play();
        }
      });
    });
  }

  @override
  void dispose() {
    _pause?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('singleWeightPulse'),
    width: 42,
    height: 42,
    child: widget.visible
        ? AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final wave = (1 - cos(_controller.value * pi * 2)) / 2;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: 1 + .35 * wave,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.colors.accent.withValues(
                          alpha: .18 - .14 * wave,
                        ),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 1 + .06 * wave,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.colors.accent,
                        border: Border.all(color: widget.colors.card, width: 2),
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        : Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.colors.muted.withValues(alpha: .4),
              ),
            ),
          ),
  );
}

enum BalanceSummaryMotionKind { graph, flag, clock }

class BalanceSummaryMotionIcon extends StatefulWidget {
  const BalanceSummaryMotionIcon({
    super.key,
    required this.kind,
    required this.color,
    this.progressOverride,
    this.isActive = true,
    this.activationEpoch = 1,
  });

  final BalanceSummaryMotionKind kind;
  final Color color;
  final double? progressOverride;
  final bool isActive;
  final int activationEpoch;

  @override
  State<BalanceSummaryMotionIcon> createState() =>
      _BalanceSummaryMotionIconState();
}

class _BalanceSummaryMotionIconState extends State<BalanceSummaryMotionIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: switch (widget.kind) {
      BalanceSummaryMotionKind.graph => const Duration(milliseconds: 1100),
      BalanceSummaryMotionKind.flag => const Duration(milliseconds: 5200),
      BalanceSummaryMotionKind.clock => const Duration(hours: 12),
    },
  );
  bool _reduceMotion = false;
  int _lastGraphActivationEpoch = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant BalanceSummaryMotionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _controller.duration = switch (widget.kind) {
        BalanceSummaryMotionKind.graph => const Duration(milliseconds: 1100),
        BalanceSummaryMotionKind.flag => const Duration(milliseconds: 5200),
        BalanceSummaryMotionKind.clock => const Duration(hours: 12),
      };
    }
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.progressOverride != null) {
      _controller.stop();
      return;
    }
    final animate =
        widget.isActive &&
        !_reduceMotion &&
        TickerMode.valuesOf(context).enabled;
    if (widget.kind == BalanceSummaryMotionKind.graph) {
      if (!widget.isActive) {
        _controller
          ..stop()
          ..value = 0;
      } else if (_reduceMotion) {
        _lastGraphActivationEpoch = widget.activationEpoch;
        _controller.value = 1;
      } else if (animate &&
          widget.activationEpoch > 0 &&
          widget.activationEpoch != _lastGraphActivationEpoch) {
        _lastGraphActivationEpoch = widget.activationEpoch;
        _controller.forward(from: 0);
      }
    } else if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox(
      key: ValueKey('summaryMotion-${widget.kind.name}'),
      width: widget.kind == BalanceSummaryMotionKind.clock ? 40 : 62,
      height: 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final rawProgress = (widget.progressOverride ?? _controller.value)
              .clamp(0.0, 1.0);
          final progress =
              widget.kind == BalanceSummaryMotionKind.graph &&
                  widget.progressOverride == null
              ? Curves.easeOutCubic.transform(rawProgress)
              : rawProgress;
          return CustomPaint(
            key: ValueKey(
              'summaryMotionFrame-${widget.kind.name}-${(progress * 1000000).floor()}',
            ),
            painter: _SummaryMotionPainter(
              kind: widget.kind,
              color: widget.color,
              progress: progress,
            ),
          );
        },
      ),
    ),
  );
}

class _SummaryMotionPainter extends CustomPainter {
  const _SummaryMotionPainter({
    required this.kind,
    required this.color,
    required this.progress,
  });

  final BalanceSummaryMotionKind kind;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    switch (kind) {
      case BalanceSummaryMotionKind.graph:
        final path = _summaryGraphPath();
        final metric = path.computeMetrics().first;
        final drawProgress = progress.clamp(0.0, 1.0);
        final drawn = metric.length * drawProgress;
        final visiblePath = metric.extractPath(0, drawn);
        if (drawProgress > 0) {
          canvas.drawPath(
            visiblePath,
            paint
              ..color = color
              ..strokeWidth = 2.65,
          );
        }
        canvas.drawCircle(
          const Offset(7, 31),
          1.45,
          Paint()..color = color.withValues(alpha: .78),
        );
        if (progress >= .90) {
          final settle = Curves.easeOutCubic.transform(
            ((progress - .90) / .10).clamp(0.0, 1.0),
          );
          final point = metric.getTangentForOffset(metric.length)?.position;
          if (point != null) {
            canvas.drawCircle(
              point,
              4.4 * settle,
              Paint()
                ..color = color.withValues(alpha: .12 * settle)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
            );
            canvas.drawCircle(
              point,
              (1.65 * (.9 + .1 * settle)),
              Paint()..color = color,
            );
          }
        }
      case BalanceSummaryMotionKind.flag:
        canvas.drawLine(const Offset(7, 34), const Offset(7, 6), paint);
        final cloth = _summaryFlagCloth(progress);
        final flag = cloth.$1;
        canvas.drawPath(
          flag,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, Colors.white, .30)!,
                color,
                Color.lerp(color, Colors.black, .10)!,
              ],
            ).createShader(flag.getBounds())
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          cloth.$2,
          Paint()
            ..color = Color.lerp(
              color,
              Colors.white,
              .32,
            )!.withValues(alpha: .48)
            ..strokeWidth = 1.15
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
        canvas.drawPath(
          flag,
          paint
            ..color = color.withValues(alpha: .96)
            ..strokeWidth = 1.65,
        );
      case BalanceSummaryMotionKind.clock:
        final center = Offset(size.width / 2, size.height / 2);
        canvas.drawCircle(
          center + const Offset(0, 1),
          12.5,
          Paint()
            ..color = Colors.black.withValues(alpha: .10)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          center,
          11.8,
          Paint()
            ..color = Color.lerp(const Color(0xFFFFF8E9), color, .035)!
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          center,
          11.8,
          paint
            ..color = color.withValues(alpha: .32)
            ..strokeWidth = 1.5,
        );
        for (var index = 0; index < 12; index++) {
          final angle = index * pi / 6;
          final outer = center + Offset(sin(angle) * 10.2, -cos(angle) * 10.2);
          final inner = center + Offset(sin(angle) * 8.6, -cos(angle) * 8.6);
          canvas.drawLine(
            inner,
            outer,
            Paint()
              ..color = color.withValues(alpha: .46)
              ..strokeWidth = index % 3 == 0 ? 1.05 : .72
              ..strokeCap = StrokeCap.round,
          );
        }
        final (second, minute, hour) = debugBalanceClockAngles(progress);
        canvas.drawLine(
          center,
          center + Offset(sin(second) * 10.0, -cos(second) * 10.0),
          Paint()
            ..color = color.withValues(alpha: .88)
            ..strokeWidth = 1.05
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          center,
          center + Offset(sin(minute) * 8.2, -cos(minute) * 8.2),
          paint
            ..color = color
            ..strokeWidth = 1.8,
        );
        canvas.drawLine(
          center,
          center + Offset(sin(hour) * 5.8, -cos(hour) * 5.8),
          paint..strokeWidth = 2.35,
        );
        canvas.drawCircle(center, 1.45, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SummaryMotionPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.progress != progress;
}

Path _summaryGraphPath() => Path()
  ..moveTo(7, 31)
  ..cubicTo(12, 31, 13.5, 23.5, 20, 22.5)
  ..cubicTo(27, 21.4, 29, 24.2, 35, 20.2)
  ..cubicTo(41, 16.2, 43.5, 12.4, 49, 11.0)
  ..cubicTo(53, 10.0, 54.5, 8.0, 56, 7.0);

@visibleForTesting
double debugBalancePeriodGraphDrawLength(double progress) {
  final metric = _summaryGraphPath().computeMetrics().first;
  return metric.length * progress.clamp(0.0, 1.0);
}

@visibleForTesting
(double, double, double, double) debugBalanceGoalFlagGeometry(double progress) {
  return (
    _flagWaveOffset(.18, progress),
    _flagWaveOffset(.40, progress),
    _flagWaveOffset(.65, progress),
    _flagWaveOffset(.92, progress),
  );
}

(Path, Path) _summaryFlagCloth(double progress) {
  const samples = 24;
  final upper = <Offset>[];
  final lower = <Offset>[];
  final highlight = <Offset>[];
  for (var index = 0; index <= samples; index++) {
    final u = index / samples;
    final center = _flagCenterPoint(u, progress);
    final before = _flagCenterPoint(max(0, u - .01), progress);
    final after = _flagCenterPoint(min(1, u + .01), progress);
    final delta = after - before;
    final length = sqrt(delta.dx * delta.dx + delta.dy * delta.dy);
    final normal = Offset(-delta.dy / length, delta.dx / length);
    const halfThickness = 4.0;
    upper.add(center - normal * halfThickness);
    lower.add(center + normal * halfThickness);
    highlight.add(center - normal * 2.7);
  }

  final flag = Path()..moveTo(upper.first.dx, upper.first.dy);
  for (final point in upper.skip(1)) {
    flag.lineTo(point.dx, point.dy);
  }
  final lastCenter = _flagCenterPoint(1, progress);
  flag.quadraticBezierTo(
    lastCenter.dx + 1.2,
    lastCenter.dy,
    lower.last.dx,
    lower.last.dy,
  );
  for (final point in lower.reversed.skip(1)) {
    flag.lineTo(point.dx, point.dy);
  }
  flag.close();

  final shine = Path()..moveTo(highlight.first.dx, highlight.first.dy);
  for (final point in highlight.skip(1)) {
    shine.lineTo(point.dx, point.dy);
  }
  return (flag, shine);
}

Offset _flagCenterPoint(double u, double progress) =>
    Offset(7.4 + 41.4 * u, 11.2 + .45 * u + _flagWaveOffset(u, progress));

double _flagWaveOffset(double u, double progress) {
  final rawEnvelope = ((u - .08) / .92).clamp(0.0, 1.0);
  final envelope = rawEnvelope * rawEnvelope * (3 - 2 * rawEnvelope);
  final amplitude = 1.40 * pow(envelope, .55);
  return sin(2 * pi * (u * .92 - progress)) * amplitude;
}

@visibleForTesting
(double, double, double) debugBalanceClockAngles(double progress) {
  final phase = progress.clamp(0.0, 1.0);
  final second = -.55 + phase * pi * 2 * 720;
  final minute = 2.15 + phase * pi * 2 * 12;
  final hour = -.08 + phase * pi * 2;
  return (second, minute, hour);
}

class _LegendLinePainter extends CustomPainter {
  final Color color;
  final bool dashed;

  const _LegendLinePainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, y), Offset(min(x + 3.5, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}

DateTime _day(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String _dateLong(DateTime value, bool isRu) => intl.DateFormat(
  isRu ? 'd MMMM' : 'MMMM d',
  isRu ? 'ru' : 'en',
).format(value.toLocal());

String _dateTime(DateTime value, bool isRu) => intl.DateFormat(
  isRu ? 'd MMM y' : 'MMM d, y',
  isRu ? 'ru' : 'en',
).format(value.toLocal());

DateTime? _dateFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  final value = DateTime(year, month, day);
  return value.year == year && value.month == month && value.day == day
      ? value
      : null;
}

String _signedWeight(double value, {bool withArrow = false}) {
  if (value.abs() < 0.05) {
    return withArrow ? '– 0.0 kg' : '0.0 kg';
  }
  final sign = value < 0 ? '−' : '+';
  final arrow = withArrow ? (value < 0 ? '↓ ' : '↑ ') : '';
  return '$arrow$sign${value.abs().toStringAsFixed(1)} kg';
}

String _signedNumber(int value) => value < 0 ? '−${value.abs()}' : '+$value';

String _compactInt(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    if (index > 0 && (raw.length - index) % 3 == 0) buffer.write(' ');
    buffer.write(raw[index]);
  }
  return buffer.toString();
}
