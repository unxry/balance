import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../models/history_models.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/balance_analytics_service.dart';
import '../services/water_save_trace.dart';
import '../widgets/balance_feedback.dart';
import '../services/health_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/balance_motion.dart';
import '../theme/i18n.dart';
import '../widgets/common.dart';
import '../widgets/animated_macro_ring.dart';
import '../widgets/premium_motion.dart';
import '../widgets/realistic_water.dart';
import '../widgets/root_swipe_guard.dart';
import '../widgets/tab_bar_pill.dart';

@visibleForTesting
final List<({String name, Duration frameTime})>
debugDashboardWaterTransitionEvents = [];

void _recordWaterTransitionEvent(String name) {
  assert(() {
    debugDashboardWaterTransitionEvents.add((
      name: name,
      frameTime: WidgetsBinding.instance.currentSystemFrameTimeStamp,
    ));
    return true;
  }());
}

class DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenWeight;
  final ValueChanged<DateTime>? onOpenDiary;
  final VoidCallback onOpenAdvice;
  final bool openWaterEditor;
  final VoidCallback? onWaterEditorOpened;
  final ScrollController? scrollController;
  final double? waterPreviewElapsedSeconds;
  final ui.FragmentShader? waterMaterialPreviewShader;
  final double? dashboardMotionPreviewProgress;
  const DashboardScreen({
    super.key,
    required this.onOpenSteps,
    required this.onOpenWeight,
    this.onOpenDiary,
    required this.onOpenAdvice,
    this.openWaterEditor = false,
    this.onWaterEditorOpened,
    this.scrollController,
    this.waterPreviewElapsedSeconds,
    @visibleForTesting this.waterMaterialPreviewShader,
    @visibleForTesting this.dashboardMotionPreviewProgress,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waterSuccessController;
  late final Animation<double> _waterSuccessOpacity;
  Timer? _errorHideTimer;
  Timer? _errorRemoveTimer;
  String? _waterSuccessLabel;
  int? _failedWaterMl;
  String? _failedWaterDateKey;
  bool _errorVisible = false;
  late PageController _dayController;
  bool _dayControllerReady = false;
  int? _lastDashboardDayCount;
  bool _waterDeepLinkHandled = false;
  final Map<String, double> _waterVisualMl = {};

  @override
  void initState() {
    super.initState();
    _waterSuccessController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _waterSuccessOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 52),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30,
      ),
    ]).animate(_waterSuccessController);
    _waterSuccessController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _waterSuccessLabel = null);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dayControllerReady) return;
    final data = context.read<AppDataProvider>();
    final daysAgo = data.today
        .difference(data.selectedDate)
        .inDays
        .clamp(0, data.dashboardDayCount - 1);
    _dayController = PageController(initialPage: daysAgo);
    _dayControllerReady = true;
    _openWaterFromDeepLinkIfNeeded();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.openWaterEditor && widget.openWaterEditor) {
      _waterDeepLinkHandled = false;
      _openWaterFromDeepLinkIfNeeded();
    }
  }

  void _openWaterFromDeepLinkIfNeeded() {
    if (!widget.openWaterEditor || _waterDeepLinkHandled) return;
    _waterDeepLinkHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = context.read<AppDataProvider>();
      final s = S(context.read<SettingsProvider>().lang);
      widget.onWaterEditorOpened?.call();
      _openWaterEditor(context, data, s, data.dashboardDay());
    });
  }

  @override
  void dispose() {
    _errorHideTimer?.cancel();
    _errorRemoveTimer?.cancel();
    _waterSuccessController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final data = context.watch<AppDataProvider>();
    final lang = context.watch<SettingsProvider>().lang;
    final s = S(lang);
    final p = data.profile;
    _reconcileDayPager(data);

    final day = data.dashboardDay();

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            primary: widget.scrollController == null,
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              BalanceRootMetrics.contentBottomInset(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MonoLabel(_dayTitle(day.date, data.today, s)),
                          const SizedBox(height: 6),
                          Text(
                            '${s.hello}, ${p.name.trim().isEmpty ? 'Balance' : p.name.trim().split(' ').first}',
                            style: t.fraunces(
                              size: 24,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ProfileAvatar(
                      imageBytes: p.avatarBytes,
                      fallbackLetter: p.avatarLetter,
                      size: 46,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                RootSwipeGuard(
                  child: SizedBox(
                    key: const ValueKey('dashboardHeroViewport'),
                    height: 345,
                    child: PageView.builder(
                      key: const ValueKey('dashboardDayPager'),
                      controller: _dayController,
                      reverse: true,
                      itemCount: data.dashboardDayCount,
                      physics: const PageScrollPhysics(),
                      onPageChanged: (index) => data.selectDashboardDate(
                        data.today.subtract(Duration(days: index)),
                      ),
                      itemBuilder: (context, index) {
                        final date = data.today.subtract(Duration(days: index));
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: _heroCalorieCard(
                            key: ValueKey(
                              'dashboardHero:${data.dashboardDay(date).dateKey}',
                            ),
                            context,
                            c,
                            t,
                            s,
                            data.dashboardDay(date),
                            p,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 180,
                  children: [
                    _stepsTile(context, c, t, s, data, day, widget.onOpenSteps),
                    _weightTile(context, c, t, s, data, widget.onOpenWeight),
                    _waterTile(context, c, t, s, data, day),
                    _tipTile(
                      context,
                      c,
                      t,
                      s,
                      data.analyticsForDays(30).advice,
                      day,
                      data.isTodaySelected,
                      widget.onOpenAdvice,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_failedWaterMl != null)
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 90,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              offset: _errorVisible ? Offset.zero : const Offset(0, 0.15),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _errorVisible ? 1 : 0,
                child: _WaterErrorToast(onRetry: _retryWater, isRu: s.isRu),
              ),
            ),
          ),
      ],
    );
  }

  void _reconcileDayPager(AppDataProvider data) {
    final count = data.dashboardDayCount;
    final expected = data.today
        .difference(data.selectedDate)
        .inDays
        .clamp(0, count - 1);
    if (_lastDashboardDayCount == count &&
        (!_dayController.hasClients ||
            ((_dayController.page ?? expected) - expected).abs() < .01)) {
      return;
    }
    _lastDashboardDayCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dayController.hasClients) return;
      final current = _dayController.page;
      if (current == null ||
          current < 0 ||
          current >= count ||
          (current - expected).abs() >= .01) {
        _dayController.jumpToPage(expected);
      }
    });
  }

  Widget _heroCalorieCard(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    DashboardDaySnapshot day,
    UserProfile p, {
    Key? key,
  }) {
    final target = day.calorieGoal;
    final eaten = day.caloriesConsumed;
    final breakdown = MacroEnergyBreakdown.calculate(
      proteinG: day.protein,
      fatG: day.fat,
      carbsG: day.carbs,
      calories: eaten,
      calorieGoal: target,
    );
    const stroke = 14.0;
    const size = 190.0;

    return KeyedSubtree(
      key: key,
      child: SectionCard(
        radius: 26,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            PressableScale(
              key: ValueKey('calorieRingTap:${day.dateKey}'),
              borderRadius: BorderRadius.circular(size / 2),
              onTap: widget.onOpenDiary == null
                  ? null
                  : () {
                      unawaited(BalanceMotion.selection());
                      widget.onOpenDiary!(day.date);
                    },
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: size,
                      height: size,
                      child: AnimatedMacroRing(
                        breakdown: breakdown,
                        colors: c,
                        strokeWidth: stroke,
                        animationKey:
                            '${day.dateKey}:$eaten:${day.protein}:${day.fat}:${day.carbs}:$target',
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BalanceAnimatedNumber(
                          value: eaten.toDouble(),
                          formatter: (value) => intl.NumberFormat(
                            '#,###',
                            'ru',
                          ).format(value.round()).replaceAll(',', ' '),
                          style: t.fraunces(size: 42, weight: FontWeight.w800),
                        ),
                        Text('/ $target ${s.kcalLbl}', style: t.mono(size: 11)),
                        const SizedBox(height: 8),
                        Pill(
                          text: day.caloriesAboveGoal > 0
                              ? (s.isRu
                                    ? 'выше цели на ${day.caloriesAboveGoal}'
                                    : '${day.caloriesAboveGoal} above goal')
                              : '${s.remainingWord} ${day.caloriesRemaining}',
                          bg: c.accentSoft,
                          fg: c.accent,
                          mono: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!day.hasFood) ...[
              Text(
                s.isRu ? 'В этот день нет записей' : 'No entries for this day',
                style: t.inter(size: 11, color: c.muted),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.line.withValues(alpha: 0.6)),
                ),
              ),
              child: Row(
                children: [
                  _macroCol(
                    c,
                    t,
                    s.isRu ? 'Б' : 'P',
                    day.protein.round(),
                    p.proteinTargetG,
                    c.accent,
                  ),
                  _macroCol(
                    c,
                    t,
                    s.isRu ? 'Ж' : 'F',
                    day.fat.round(),
                    p.fatTargetG,
                    c.accent2,
                  ),
                  _macroCol(
                    c,
                    t,
                    s.isRu ? 'У' : 'C',
                    day.carbs.round(),
                    p.carbTargetG,
                    c.macroCarb,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroCol(
    dynamic c,
    AppText t,
    String letter,
    int val,
    int target,
    Color color,
  ) {
    final progress = target == 0 ? 0.0 : (val / target).clamp(0.0, 1.0);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: c.track,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Text('$letter $val/$target', style: t.mono(size: 10)),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required Widget child,
    VoidCallback? onTap,
  }) {
    return BalanceGlassCard(onTap: onTap, child: child);
  }

  Widget _stepsTile(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    AppDataProvider data,
    DashboardDaySnapshot day,
    VoidCallback onTap,
  ) {
    final isToday = data.isTodaySelected;
    final statusText = !isToday
        ? day.steps == null
              ? '—'
              : intl.NumberFormat(
                  '#,###',
                  'ru',
                ).format(day.steps).replaceAll(',', ' ')
        : switch (data.stepAccess) {
            StepAccessState.authorized =>
              day.steps == null
                  ? '—'
                  : intl.NumberFormat(
                      '#,###',
                      'ru',
                    ).format(day.steps).replaceAll(',', ' '),
            StepAccessState.loading => '···',
            _ => '—',
          };
    final sub = !isToday
        ? (day.steps == null
              ? (s.isRu ? 'нет данных' : 'no data')
              : _shortDate(day.date, s))
        : switch (data.stepAccess) {
            StepAccessState.authorized => s.isRu ? 'сегодня' : 'today',
            StepAccessState.notDetermined => s.isRu ? 'подключить' : 'connect',
            StepAccessState.denied =>
              s.isRu ? 'доступ закрыт' : 'access denied',
            StepAccessState.restricted => s.isRu ? 'недоступно' : 'unavailable',
            StepAccessState.loading => s.isRu ? 'обновление' : 'updating',
            StepAccessState.unavailable =>
              s.isRu ? 'не поддерживается' : 'unsupported',
          };
    return _tile(
      context,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MonoLabel(s.steps),
              const Spacer(),
              data.stepsLoading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: c.accent,
                      ),
                    )
                  : BalanceActivityCharacter(
                      colors: c,
                      size: 36,
                      travelWidth: 58,
                      animationMode: isToday
                          ? BalanceActivityAnimationMode.ambient
                          : BalanceActivityAnimationMode.idle,
                      isVisible: true,
                      previewProgress: widget.dashboardMotionPreviewProgress,
                    ),
            ],
          ),
          const Spacer(),
          BalanceAnimatedValue(
            value: statusText,
            style: t.fraunces(size: 26, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(sub, style: t.mono(size: 9, color: c.muted)),
        ],
      ),
    );
  }

  Widget _weightTile(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    AppDataProvider data,
    VoidCallback onTap,
  ) {
    final w = data.profile.weightKg;
    final trend = data.weightTrend;
    final lastDate = data.latestActualWeightDate;
    final lastLabel = lastDate == null
        ? (s.isRu ? 'нет измерений' : 'no measurements')
        : (s.isRu
              ? 'измерено ${intl.DateFormat('d MMM', 'ru').format(lastDate)}'
              : 'measured ${intl.DateFormat('MMM d', 'en').format(lastDate)}');
    return _tile(
      context,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MonoLabel(s.weight),
              const Spacer(),
              Icon(Icons.edit_outlined, size: 15, color: c.muted),
            ],
          ),
          const Spacer(),
          BalanceAnimatedNumber(
            value: w,
            formatter: (value) => '${value.toStringAsFixed(1)} kg',
            style: t.fraunces(size: 23, weight: FontWeight.w800),
          ),
          Text(lastLabel, style: t.mono(size: 7.5, color: c.muted)),
          const SizedBox(height: 7),
          Text(
            trend == null
                ? (s.isRu
                      ? 'Недостаточно данных для прогноза'
                      : 'Not enough data for a forecast')
                : '${s.isRu ? "Расчётный тренд" : "Estimated trend"} '
                      '${trend.delta7DaysKg < 0 ? "−" : "+"}${trend.delta7DaysKg.abs().toStringAsFixed(1)} kg / 7 ${s.isRu ? "дн" : "d"}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.inter(
              size: 9,
              height: 1.2,
              weight: FontWeight.w600,
              color: trend == null ? c.muted : c.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _waterTile(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    AppDataProvider data,
    DashboardDaySnapshot day,
  ) {
    final logicalWaterMl = day.waterConsumedLiters * 1000;
    final visibleWaterMl = _waterVisualMl[day.dateKey] ?? logicalWaterMl;
    final progress = day.waterGoalLiters <= 0
        ? 0.0
        : (visibleWaterMl / (day.waterGoalLiters * 1000)).clamp(0.0, 1.0);
    return BalanceGlassCard(
      key: ValueKey('dashboardWaterCard-${day.dateKey}'),
      onTap: () => _openWaterEditor(context, data, s, day),
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RealisticWaterLayer(
                key: ValueKey('dashboardWaterLayer-${day.dateKey}'),
                valueMl: visibleWaterMl,
                goalMl: day.waterGoalLiters * 1000,
                colors: c,
                previewElapsedSeconds: widget.waterPreviewElapsedSeconds,
                materialPreviewShader: widget.waterMaterialPreviewShader,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MonoLabel(s.water),
                    const Spacer(),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c.card.withValues(alpha: 0.78),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.62),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 9,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(Icons.add_rounded, size: 18, color: c.fg),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BalanceAnimatedNumber(
                          key: const ValueKey('waterCurrentValue'),
                          value: visibleWaterMl,
                          duration: const Duration(milliseconds: 650),
                          formatter: (value) =>
                              '${value.round()} / ${(day.waterGoalLiters * 1000).round()} ${s.isRu ? "мл" : "ml"}',
                          style: t
                              .fraunces(size: 24, weight: FontWeight.w800)
                              .copyWith(
                                shadows: [
                                  Shadow(
                                    color: c.card.withValues(alpha: 0.72),
                                    blurRadius: 7,
                                  ),
                                ],
                              ),
                        ),
                        if (_waterSuccessLabel != null) ...[
                          const SizedBox(width: 7),
                          FadeTransition(
                            key: const ValueKey('waterSuccessFade'),
                            opacity: _waterSuccessOpacity,
                            child: Text(
                              '✓ $_waterSuccessLabel',
                              key: const ValueKey('waterSuccessIndicator'),
                              style: t.inter(
                                size: 10,
                                weight: FontWeight.w700,
                                color: c.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                WaterProgressIndicators(
                  key: const ValueKey('waterProgressIndicators'),
                  progress: progress,
                  activeColor: c.accent.withValues(alpha: 0.9),
                  trackColor: c.track.withValues(alpha: 0.72),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWaterEditor(
    BuildContext context,
    AppDataProvider data,
    S s,
    DashboardDaySnapshot day,
  ) async {
    final c = context.colors;
    _waterVisualMl[day.dateKey] = day.waterConsumedLiters * 1000;
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return _WaterEditorSheet(
          data: data,
          strings: s,
          dateKey: day.dateKey,
          currentLiters: day.waterConsumedLiters,
          onPersisted: () => _recordWaterTransitionEvent('persisted'),
        );
      },
    );
    if (!context.mounted) return;
    _recordWaterTransitionEvent('routeDismissed');
    WaterSaveTrace.latest?.mark('routeDismissed');
    if (amount == null) {
      _waterVisualMl.remove(day.dateKey);
      return;
    }
    if (amount < -1) {
      await _releaseWaterVisual(day.dateKey);
      _showWaterError(-amount - 1, day.dateKey);
      return;
    }
    if (amount == -1) {
      final confirmed = await _confirmWaterReset(context, s);
      if (confirmed && context.mounted) {
        final saved = await data.setWaterForDate(0, day.dateKey);
        if (!context.mounted) return;
        await _releaseWaterVisual(day.dateKey);
        if (saved) {
          _showWaterSuccess(s.isRu ? 'сброшено' : 'reset');
          unawaited(BalanceMotion.light());
        } else {
          _showWaterError(0, day.dateKey);
        }
      } else {
        _waterVisualMl.remove(day.dateKey);
      }
      return;
    }
    await _releaseWaterVisual(day.dateKey);
    _showWaterSuccess('+$amount ${s.isRu ? "мл" : "ml"}');
    unawaited(BalanceMotion.light());
  }

  Future<void> _releaseWaterVisual(String dateKey) async {
    if (!mounted) return;
    final data = context.read<AppDataProvider>();
    final selected = data.dashboardDay();
    final latest = selected.dateKey == dateKey
        ? selected.waterConsumedLiters * 1000
        : data.dashboardDay(DateTime.parse(dateKey)).waterConsumedLiters * 1000;
    setState(() => _waterVisualMl[dateKey] = latest);
    _recordWaterTransitionEvent('displayRetarget');
    final trace = WaterSaveTrace.latest;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => trace?.mark('visibleDashboard'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waterVisualMl.remove(dateKey);
    });
  }

  void _showWaterSuccess(String label) {
    _hideWaterError();
    setState(() => _waterSuccessLabel = label);
    _waterSuccessController.forward(from: 0);
  }

  void _showWaterError(int amount, String dateKey) {
    _errorHideTimer?.cancel();
    _errorRemoveTimer?.cancel();
    setState(() {
      _failedWaterMl = amount;
      _failedWaterDateKey = dateKey;
      _errorVisible = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _failedWaterMl == null) return;
      setState(() => _errorVisible = true);
    });
    _errorHideTimer = Timer(const Duration(seconds: 3), _hideWaterError);
  }

  void _hideWaterError() {
    _errorHideTimer?.cancel();
    _errorRemoveTimer?.cancel();
    if (!mounted || _failedWaterMl == null) return;
    setState(() => _errorVisible = false);
    _errorRemoveTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _failedWaterMl = null;
          _failedWaterDateKey = null;
        });
      }
    });
  }

  Future<void> _retryWater() async {
    final amount = _failedWaterMl;
    final dateKey = _failedWaterDateKey;
    if (amount == null || dateKey == null) return;
    final data = context.read<AppDataProvider>();
    final s = S(context.read<SettingsProvider>().lang);
    final saved = amount == 0
        ? await data.setWaterForDate(0, dateKey)
        : await data.addWaterForDate(amount / 1000, dateKey);
    if (!mounted) return;
    if (saved) {
      _showWaterSuccess(
        amount == 0
            ? (s.isRu ? 'сброшено' : 'reset')
            : '+$amount ${s.isRu ? "мл" : "ml"}',
      );
      unawaited(BalanceMotion.light());
    } else {
      _showWaterError(amount, dateKey);
    }
  }

  Future<bool> _confirmWaterReset(BuildContext context, S s) async {
    final c = context.colors;
    ModalRoute<bool>? sheetRoute;
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        sheetRoute ??= ModalRoute.of<bool>(ctx);
        final t = AppText(c);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isRu
                      ? 'Сбросить воду за выбранный день?'
                      : 'Reset water for the selected day?',
                  style: t.fraunces(size: 21, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  s.isRu
                      ? 'Будет удалён весь объём воды, добавленный за сегодняшний день.'
                      : 'All water added for today will be removed.',
                  style: t.inter(size: 13, color: c.muted, height: 1.4),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: c.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(s.cancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.accent2,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(s.isRu ? 'Сбросить' : 'Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  Widget _tipTile(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    BalanceAdvice advice,
    DashboardDaySnapshot day,
    bool isToday,
    VoidCallback onTap,
  ) {
    final content = isToday
        ? advice.type == AdviceType.dataIncomplete
              ? (s.isRu
                    ? 'Пока данных немного.\nЗаполняйте питание ещё несколько дней — Balance подготовит персональный совет.'
                    : 'There is not much data yet.\nKeep logging food for a few more days and Balance will prepare a personal tip.')
              : (s.isRu ? advice.ru : advice.en)
        : _daySummary(day, s);
    return Semantics(
      key: const ValueKey('adviceCard'),
      button: isToday,
      label: isToday ? '${s.adviceToday}. $content' : s.adviceToday,
      hint: isToday ? (s.isRu ? 'Открыть подробности' : 'Open details') : null,
      child: ExcludeSemantics(
        child: _tile(
          context,
          onTap: isToday ? onTap : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BalanceSparkleField(
                colors: c,
                previewProgress: widget.dashboardMotionPreviewProgress,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MonoLabel(s.adviceToday),
                            if (!isToday) ...[
                              const SizedBox(height: 3),
                              Text(
                                s.isRu
                                    ? 'По данным ${_shortDate(day.date, s)}'
                                    : 'For ${_shortDate(day.date, s)}',
                                style: t.mono(size: 7, color: c.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _AdviceStar(
                        changeKey: '${day.dateKey}:${advice.type}:$content',
                      ),
                    ],
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: BalanceMotion.resolve(
                      context,
                      BalanceMotion.card,
                    ),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Text(
                      content,
                      key: ValueKey(content),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: t.fraunces(
                        size: 12,
                        weight: FontWeight.w600,
                        height: 1.18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _daySummary(DashboardDaySnapshot day, S s) {
    if (!day.hasFood && day.waterConsumedLiters == 0 && day.steps == null) {
      return s.isRu ? 'В этот день нет записей.' : 'No entries for this day.';
    }
    final difference = day.caloriesConsumed - day.calorieGoal;
    final calories = difference == 0
        ? (s.isRu ? 'точно в цели' : 'right on target')
        : difference > 0
        ? (s.isRu
              ? 'на ${difference.abs()} ккал выше цели'
              : '${difference.abs()} kcal above target')
        : (s.isRu
              ? 'на ${difference.abs()} ккал ниже цели'
              : '${difference.abs()} kcal below target');
    final steps = day.steps == null
        ? ''
        : s.isRu
        ? ', активность — ${intl.NumberFormat('#,###', 'ru').format(day.steps).replaceAll(',', ' ')} шагов'
        : ', with ${intl.NumberFormat('#,###', 'en').format(day.steps)} steps';
    return s.isRu
        ? '${intl.DateFormat('d MMMM', 'ru').format(day.date)}: рацион $calories$steps.'
        : '${intl.DateFormat('MMMM d', 'en').format(day.date)}: intake was $calories$steps.';
  }

  String _dayTitle(DateTime date, DateTime today, S s) {
    final difference = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime(date.year, date.month, date.day)).inDays;
    final primary = difference == 0
        ? (s.isRu ? 'СЕГОДНЯ' : 'TODAY')
        : difference == 1
        ? (s.isRu ? 'ВЧЕРА' : 'YESTERDAY')
        : (s.isRu
              ? intl.DateFormat('d MMMM', 'ru').format(date).toUpperCase()
              : intl.DateFormat('MMMM d', 'en').format(date).toUpperCase());
    final secondary = difference <= 1
        ? _shortDate(date, s).toUpperCase()
        : intl.DateFormat(
            s.isRu ? 'EEEE' : 'EEEE',
            s.isRu ? 'ru' : 'en',
          ).format(date).toUpperCase();
    return '$primary · $secondary';
  }

  String _shortDate(DateTime date, S s) => intl.DateFormat(
    s.isRu ? 'd MMMM' : 'MMMM d',
    s.isRu ? 'ru' : 'en',
  ).format(date);
}

class _AdviceStar extends StatefulWidget {
  const _AdviceStar({required this.changeKey});

  final String changeKey;

  @override
  State<_AdviceStar> createState() => _AdviceStarState();
}

class _AdviceStarState extends State<_AdviceStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _cycleTimer;
  bool _motionEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionEnabled =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (_motionEnabled && !_controller.isAnimating) {
      _startCycle();
    } else if (!_motionEnabled) {
      _cycleTimer?.cancel();
      _cycleTimer = null;
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant _AdviceStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.changeKey != widget.changeKey && _motionEnabled) {
      _cycleTimer?.cancel();
      _cycleTimer = null;
      _startCycle(from: .08);
    }
  }

  void _startCycle({double from = 0}) {
    if (!_motionEnabled) return;
    _controller.forward(from: from).whenComplete(() {
      if (!mounted || !_motionEnabled) return;
      // A tiny rest at the neutral frame is visually continuous, while also
      // avoiding a permanently scheduled frame when the widget is settling.
      _cycleTimer = Timer(const Duration(milliseconds: 120), () {
        _cycleTimer = null;
        _startCycle();
      });
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      key: const ValueKey('adviceStar'),
      width: 38,
      height: 32,
      child: AnimatedBuilder(
        key: ValueKey(
          'adviceMotion-${_controller.isAnimating ? 'active' : 'stopped'}',
        ),
        animation: _controller,
        builder: (_, __) {
          final phase = _controller.value;
          final pulse = (1 - math.cos(phase * math.pi * 2)) / 2;
          final angle = math.sin(phase * math.pi * 2) * math.pi / 90;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: angle,
                child: Transform.scale(
                  scale: 1 + pulse * .06,
                  child: Text(
                    '✦',
                    style: TextStyle(
                      color: c.accent2,
                      shadows: [
                        Shadow(
                          color: c.accent2.withValues(alpha: .22 + pulse * .18),
                          blurRadius: 3 + 3 * pulse,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WaterEditorSheet extends StatefulWidget {
  const _WaterEditorSheet({
    required this.data,
    required this.strings,
    required this.dateKey,
    required this.currentLiters,
    required this.onPersisted,
  });

  final AppDataProvider data;
  final S strings;
  final String dateKey;
  final double currentLiters;
  final VoidCallback onPersisted;

  @override
  State<_WaterEditorSheet> createState() => _WaterEditorSheetState();
}

class _WaterEditorSheetState extends State<_WaterEditorSheet> {
  static const _presets = [150, 250, 350, 500];
  final _controller = TextEditingController(text: '250');
  final _feedback = GlobalKey<BalanceFeedbackHostState>();
  int get _previewMl =>
      (int.tryParse(_controller.text.trim()) ?? 0).clamp(0, 2000);
  static const _previewDuration = Duration(milliseconds: 340);
  var _saving = false;
  var _committed = false;
  var _showProgress = false;
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final s = widget.strings;
    final parsed = int.tryParse(_controller.text.trim());
    final valid = parsed != null && parsed >= 10 && parsed <= 2000;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: !_saving,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboard),
        child: SafeArea(
          top: false,
          child: SizedBox(
            key: const ValueKey('waterSheetFixedGeometry'),
            height: 510,
            child: BalanceFeedbackHost(
              key: _feedback,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: c.line2,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.isRu ? 'Добавить воду' : 'Add water',
                                    style: t.fraunces(
                                      size: 22,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  key: const ValueKey('waterKeyboardDone'),
                                  onPressed: () => FocusManager
                                      .instance
                                      .primaryFocus
                                      ?.unfocus(),
                                  child: Text(s.isRu ? 'Готово' : 'Done'),
                                ),
                                IconButton(
                                  onPressed: _saving
                                      ? null
                                      : () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: s.isRu ? 'Закрыть' : 'Close',
                                ),
                              ],
                            ),
                            Center(
                              child: BalanceAnimatedNumber(
                                key: const ValueKey('waterModalAmount'),
                                value: _previewMl.toDouble(),
                                duration: _previewDuration,
                                formatter: (value) =>
                                    '${value.round()} ${s.isRu ? "мл" : "ml"}',
                                style: t.fraunces(
                                  size: 36,
                                  weight: FontWeight.w700,
                                  color: c.accent,
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: keyboard > 0
                                  ? const SizedBox.shrink()
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          s.isRu
                                              ? 'Выбери стакан или укажи точный объём'
                                              : 'Choose a glass or enter an exact amount',
                                          style: t.inter(
                                            size: 12,
                                            color: c.muted,
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            key: const ValueKey(
                                              'editWaterGoalButton',
                                            ),
                                            onPressed: _saving
                                                ? null
                                                : _openGoalEditor,
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              minimumSize: const Size(0, 36),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              s.isRu
                                                  ? 'Цель: ${(widget.data.waterGoalLiters * 1000).round()} мл'
                                                  : 'Goal: ${(widget.data.waterGoalLiters * 1000).round()} ml',
                                              style: t.inter(
                                                size: 11,
                                                weight: FontWeight.w700,
                                                color: c.accent,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        PortionPresetRow(
                                          values: _presets,
                                          selected: _previewMl,
                                          unit: s.isRu ? 'мл' : 'ml',
                                          onSelected: (ml) {
                                            setState(
                                              () => _controller.text = '$ml',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 14),
                            LabeledNumberField(
                              label: s.isRu ? 'Точный объём' : 'Exact amount',
                              controller: _controller,
                              integerOnly: true,
                              unit: s.isRu ? 'мл' : 'ml',
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) {
                                _save();
                              },
                              errorText: _controller.text.isNotEmpty && !valid
                                  ? (s.isRu ? 'От 10 до 2000 мл' : '10–2000 ml')
                                  : null,
                            ),
                            const SizedBox(height: 7),
                            SizedBox(
                              height: 20,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    s.isRu ? 'Добавим ' : 'Adding ',
                                    style: t.inter(size: 11, color: c.muted),
                                  ),
                                  BalanceAnimatedNumber(
                                    key: const ValueKey('waterAmountPreview'),
                                    value: _previewMl.toDouble(),
                                    duration: _previewDuration,
                                    formatter: (value) =>
                                        value.round().toString(),
                                    style: t.inter(
                                      size: 11,
                                      weight: FontWeight.w700,
                                      color: c.accent,
                                    ),
                                  ),
                                  Text(
                                    s.isRu ? ' мл' : ' ml',
                                    style: t.inter(size: 11, color: c.muted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 7),
                            if (widget.currentLiters > 0) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => Navigator.pop(context, -1),
                                  icon: Icon(
                                    Icons.restart_alt_rounded,
                                    size: 17,
                                    color: c.accent2,
                                  ),
                                  label: Text(
                                    s.isRu ? 'Сбросить воду' : 'Reset water',
                                    style: t.inter(
                                      size: 12,
                                      weight: FontWeight.w600,
                                      color: c.accent2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                      child: Row(
                        children: [
                          if (keyboard > 0)
                            TextButton(
                              onPressed: () =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                              child: Text(s.isRu ? 'Готово' : 'Done'),
                            ),
                          Expanded(
                            child: PrimaryButton(
                              key: const ValueKey('addWaterButton'),
                              label: _showProgress
                                  ? (s.isRu ? 'Сохраняем…' : 'Saving…')
                                  : valid
                                  ? (s.isRu
                                        ? 'Добавить $parsed мл'
                                        : 'Add $parsed ml')
                                  : (s.isRu ? 'Укажи объём' : 'Enter amount'),
                              icon: Icons.water_drop_rounded,
                              onTap: valid && !_saving && !_committed
                                  ? _save
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || _committed) return;
    final amount = int.tryParse(_controller.text.trim());
    if (amount == null || amount < 10 || amount > 2000) return;
    final trace = WaterSaveTrace();
    trace.mark('parse');
    setState(() => _saving = true);
    _progressTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _saving) setState(() => _showProgress = true);
    });
    bool saved;
    try {
      saved = await widget.data.addWaterForDate(amount / 1000, widget.dateKey);
    } catch (_) {
      saved = false;
    }
    _progressTimer?.cancel();
    if (!mounted) return;
    if (saved) {
      _committed = true;
      _saving = false;
      widget.onPersisted();
      trace.mark('sheetClose');
      Navigator.pop(context, amount);
    } else {
      setState(() {
        _saving = false;
        _showProgress = false;
      });
      _feedback.currentState?.error(
        widget.strings.isRu
            ? 'Не удалось сохранить воду. Попробуйте ещё раз.'
            : 'Could not save water. Try again.',
      );
    }
  }

  Future<void> _openGoalEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) =>
          _WaterGoalEditorSheet(data: widget.data, strings: widget.strings),
    );
    if (mounted) setState(() {});
  }
}

class _WaterGoalEditorSheet extends StatefulWidget {
  const _WaterGoalEditorSheet({required this.data, required this.strings});

  final AppDataProvider data;
  final S strings;

  @override
  State<_WaterGoalEditorSheet> createState() => _WaterGoalEditorSheetState();
}

class _WaterGoalEditorSheetState extends State<_WaterGoalEditorSheet> {
  static const _presets = [500, 1000, 1500, 2000, 2500];
  late final TextEditingController _controller = TextEditingController(
    text: (widget.data.waterGoalLiters * 1000).round().toString(),
  );
  late int _selected = int.parse(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final s = widget.strings;
    final parsed = int.tryParse(_controller.text.trim());
    final tooHigh = parsed != null && parsed > 2500;
    final valid = parsed != null && parsed >= 500;
    final savedValue = valid ? parsed.clamp(500, 2500) : null;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.isRu ? 'Цель воды' : 'Water goal',
              style: t.fraunces(size: 22, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              s.isRu ? 'Дневной ориентир' : 'Daily guide',
              style: t.inter(size: 12, color: c.muted),
            ),
            const SizedBox(height: 16),
            PortionPresetRow(
              values: _presets,
              selected: _selected,
              unit: s.isRu ? 'мл' : 'ml',
              onSelected: (value) {
                _controller.text = '$value';
                setState(() => _selected = value);
              },
            ),
            const SizedBox(height: 12),
            LabeledNumberField(
              key: const ValueKey('waterGoalField'),
              label: s.isRu ? 'Точная цель' : 'Exact goal',
              controller: _controller,
              autofocus: true,
              unit: s.isRu ? 'мл' : 'ml',
              onChanged: (value) =>
                  setState(() => _selected = int.tryParse(value) ?? -1),
              errorText: tooHigh
                  ? (s.isRu
                        ? 'Максимальная цель — 2500 мл'
                        : 'Maximum goal is 2500 ml')
                  : _controller.text.isNotEmpty && !valid
                  ? (s.isRu ? 'От 500 до 2500 мл' : '500–2500 ml')
                  : null,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              key: const ValueKey('saveWaterGoalButton'),
              label: savedValue == null
                  ? (s.isRu ? 'Укажи цель' : 'Enter goal')
                  : (s.isRu
                        ? 'Сохранить $savedValue мл'
                        : 'Save $savedValue ml'),
              onTap: savedValue == null
                  ? null
                  : () async {
                      await widget.data.setWaterGoalLiters(savedValue / 1000);
                      if (context.mounted) Navigator.of(context).pop();
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterErrorToast extends StatelessWidget {
  const _WaterErrorToast({required this.onRetry, required this.isRu});

  final VoidCallback onRetry;
  final bool isRu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    return Semantics(
      liveRegion: true,
      label: isRu ? 'Не удалось добавить воду' : 'Could not add water',
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: c.line.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: c.accent2.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 3,
                height: 28,
                decoration: BoxDecoration(
                  color: c.accent2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.error_outline_rounded, size: 18, color: c.accent2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRu ? 'Не удалось добавить воду' : 'Could not add water',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.inter(size: 12, weight: FontWeight.w600),
                ),
              ),
              TextButton(
                key: const ValueKey('retryWaterButton'),
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: c.accent2,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(48, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isRu ? 'Повторить' : 'Retry',
                  style: t.inter(
                    size: 11,
                    weight: FontWeight.w700,
                    color: c.accent2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
