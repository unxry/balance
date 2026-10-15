import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../models/food_models.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import '../theme/i18n.dart';
import '../widgets/common.dart';
import '../widgets/food_thumb.dart';
import '../widgets/balance_feedback.dart';
import '../widgets/premium_motion.dart';
import '../widgets/tab_bar_pill.dart';

class DiaryScreen extends StatefulWidget {
  final ValueChanged<MealType> onSearch;
  final String? highlightedEntryId;
  const DiaryScreen({
    super.key,
    required this.onSearch,
    this.highlightedEntryId,
  });

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final Set<String> _fadingEntries = {};
  final Set<String> _collapsingEntries = {};
  final Set<String> _restoringEntries = {};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final data = context.watch<AppDataProvider>();
    final lang = context.watch<SettingsProvider>().lang;
    final s = S(lang);
    final day = data.dashboardDay();
    final target = day.calorieGoal;
    final eaten = day.caloriesConsumed;
    final progress = (eaten / target).clamp(0.0, 1.0);

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoLabel(
                  data.isTodaySelected
                      ? s.diaryToday
                      : '${s.isRu ? "ДНЕВНИК" : "DIARY"} · ${intl.DateFormat(s.isRu ? 'd MMMM' : 'MMMM d', s.isRu ? 'ru' : 'en').format(day.date).toUpperCase()}',
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    BalanceAnimatedNumber(
                      value: eaten.toDouble(),
                      formatter: (value) => value.round().toString(),
                      style: t.fraunces(size: 30, weight: FontWeight.w800),
                    ),
                    Text(' / $target', style: t.mono(size: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: c.track,
                    valueColor: AlwaysStoppedAnimation(c.accent),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  day.caloriesAboveGoal > 0
                      ? (s.isRu
                            ? 'выше цели на ${day.caloriesAboveGoal} ккал'
                            : '${day.caloriesAboveGoal} kcal above goal')
                      : '${day.caloriesRemaining} ${s.left}',
                  style: t.inter(size: 12, color: c.muted),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    key: const PageStorageKey('diaryScroll'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: BalanceRootMetrics.contentBottomInset(
                        context,
                        breathingRoom: 82,
                      ),
                    ),
                    children: [
                      _mealCard(
                        context,
                        c,
                        t,
                        s,
                        data,
                        MealType.breakfast,
                        s.breakfast,
                        Icons.egg_alt_outlined,
                      ),
                      const SizedBox(height: 10),
                      _mealCard(
                        context,
                        c,
                        t,
                        s,
                        data,
                        MealType.lunch,
                        s.lunch,
                        Icons.rice_bowl_outlined,
                      ),
                      const SizedBox(height: 10),
                      _mealCard(
                        context,
                        c,
                        t,
                        s,
                        data,
                        MealType.snack,
                        s.snack,
                        Icons.eco_outlined,
                      ),
                      const SizedBox(height: 10),
                      _mealCard(
                        context,
                        c,
                        t,
                        s,
                        data,
                        MealType.dinner,
                        s.dinner,
                        Icons.nightlight_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 86,
            child: _fabButton(
              context,
              c,
              t,
              s.isRu ? 'Добавить блюдо' : 'Add food',
              Icons.add_rounded,
              () => widget.onSearch(_mealForCurrentHour()),
              primary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fabButton(
    BuildContext context,
    dynamic c,
    AppText t,
    String label,
    IconData icon,
    VoidCallback onTap, {
    required bool primary,
  }) {
    return Material(
      key: primary ? const ValueKey('diaryPrimaryAction') : null,
      color: primary ? c.fg : c.card,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: primary ? null : Border.all(color: c.line),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: c.fg.withValues(alpha: .16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary ? c.accent : c.card2,
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: primary ? Colors.white : c.fg,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: t.inter(
                  size: 13,
                  weight: FontWeight.w700,
                  color: primary ? c.surface : c.fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mealCard(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    AppDataProvider data,
    MealType meal,
    String title,
    IconData icon,
  ) {
    final entries = data.mealEntriesForDate(data.selectedDateKey, meal);
    final totalKcal = entries.fold<int>(0, (a, b) => a + b.kcal);
    final totalProtein = entries.fold<double>(0, (a, b) => a + b.proteinG);
    final totalFat = entries.fold<double>(0, (a, b) => a + b.fatG);
    final totalCarbs = entries.fold<double>(0, (a, b) => a + b.carbsG);
    final timeLabel = entries.isNotEmpty
        ? '${entries.first.time.hour.toString().padLeft(2, '0')}:${entries.first.time.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return SectionCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.card2,
                ),
                child: Icon(icon, size: 19, color: c.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.fraunces(size: 15, weight: FontWeight.w700),
                    ),
                    Row(
                      children: [
                        Text('$timeLabel · ', style: t.mono(size: 9)),
                        BalanceAnimatedNumber(
                          value: totalKcal.toDouble(),
                          formatter: (value) => value.round().toString(),
                          style: t.mono(size: 9),
                        ),
                        Text(' ${s.kcalLbl}', style: t.mono(size: 9)),
                      ],
                    ),
                    if (entries.isNotEmpty)
                      Row(
                        children: [
                          for (final metric in [
                            (s.isRu ? 'Б' : 'P', totalProtein),
                            (s.isRu ? 'Ж' : 'F', totalFat),
                            (s.isRu ? 'У' : 'C', totalCarbs),
                          ]) ...[
                            Text('${metric.$1} ', style: t.mono(size: 7.5)),
                            BalanceAnimatedNumber(
                              value: metric.$2,
                              formatter: (value) => value.toStringAsFixed(1),
                              style: t.mono(size: 7.5, color: c.muted),
                            ),
                            const SizedBox(width: 7),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => widget.onSearch(meal),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.card2,
                  ),
                  child: Icon(Icons.add_rounded, size: 18, color: c.fg),
                ),
              ),
            ],
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                key: ValueKey('emptyMeal-${meal.name}'),
                onTap: () => widget.onSearch(meal),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Text(
                        s.emptyAdd,
                        style: t.inter(
                          size: 11,
                          weight: FontWeight.w600,
                          color: c.accent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: c.accent,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: entries
                    .map((e) => _foodLine(context, c, t, s, data, e))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _foodLine(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    AppDataProvider data,
    FoodEntry e,
  ) {
    return AnimatedDiaryEntry(
      key: ValueKey('animatedDiary:${e.id}'),
      animate: e.id == widget.highlightedEntryId,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child:
            _collapsingEntries.contains(e.id) ||
                _restoringEntries.contains(e.id)
            ? const SizedBox.shrink()
            : AnimatedOpacity(
                opacity: _fadingEntries.contains(e.id) ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: AnimatedSlide(
                  offset: _fadingEntries.contains(e.id)
                      ? const Offset(-.025, 0)
                      : Offset.zero,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: _fadingEntries.contains(e.id) ? .985 : 1,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: Builder(
                      builder: (lineContext) => Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        movementDuration: const Duration(milliseconds: 180),
                        confirmDismiss: (_) async {
                          await _removeFoodWithMotion(lineContext, data, e, s);
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: c.accent2.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.delete_outline, color: c.accent2),
                        ),
                        child: InkWell(
                          onTap: () =>
                              _showEditPortionSheet(context, data, e, s),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                FoodThumb(seed: e.colorSeed, size: 34),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.inter(
                                          size: 13,
                                          weight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                      Text(
                                        '${e.grams.round()} г · ${e.kcal} ${s.kcalLbl}',
                                        style: t.mono(size: 9),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    BalanceAnimatedNumber(
                                      value: e.kcal.toDouble(),
                                      formatter: (value) =>
                                          value.round().toString(),
                                      style: t.fraunces(
                                        size: 16,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 13,
                                      color: c.muted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _removeFoodWithMotion(
    BuildContext feedbackContext,
    AppDataProvider data,
    FoodEntry entry,
    S s,
  ) async {
    if (_fadingEntries.contains(entry.id)) return;
    final dateKey = data.selectedDateKey;
    final feedback = BalanceFeedbackHost.maybeOf(feedbackContext);
    setState(() => _fadingEntries.add(entry.id));
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _collapsingEntries.add(entry.id));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await data.removeFoodForDate(entry.id, dateKey);
    setState(() {
      _fadingEntries.remove(entry.id);
      _collapsingEntries.remove(entry.id);
    });
    feedback?.undo(
      message: s.isRu ? 'Удалено' : 'Removed',
      actionLabel: s.isRu ? 'Вернуть' : 'Undo',
      onUndo: () async {
        if (!mounted) return;
        setState(() => _restoringEntries.add(entry.id));
        await data.addFoodForDate(entry, dateKey);
        Future<void>.delayed(const Duration(milliseconds: 20), () {
          if (mounted) setState(() => _restoringEntries.remove(entry.id));
        });
      },
    );
  }

  MealType _mealForCurrentHour() {
    final hour = DateTime.now().hour;
    if (hour < 11) return MealType.breakfast;
    if (hour < 16) return MealType.lunch;
    if (hour < 19) return MealType.snack;
    return MealType.dinner;
  }

  Future<void> _showEditPortionSheet(
    BuildContext context,
    AppDataProvider data,
    FoodEntry entry,
    S s,
  ) async {
    final c = context.colors;
    final controller = TextEditingController(
      text: entry.grams.round().toString(),
    );
    int selected = entry.grams.round();
    var deleteRequested = false;
    double? grams;
    try {
      grams = await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            final t = AppText(c);
            final value = double.tryParse(
              controller.text.trim().replaceAll(',', '.'),
            );
            final valid = value != null && value >= 1 && value <= 5000;
            final factor = valid ? value / entry.grams : 0.0;
            const presets = [50, 100, 150, 200, 250];
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                          color: c.line2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      entry.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.fraunces(
                        size: 21,
                        weight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.isRu
                          ? 'Калории и БЖУ пересчитаются автоматически'
                          : 'Calories and macros update automatically',
                      style: t.inter(size: 12, color: c.muted),
                    ),
                    const SizedBox(height: 16),
                    PortionPresetRow(
                      values: presets,
                      selected: selected,
                      unit: s.isRu ? 'г' : 'g',
                      onSelected: (g) {
                        controller.text = '$g';
                        setSheetState(() => selected = g);
                      },
                    ),
                    const SizedBox(height: 12),
                    LabeledNumberField(
                      label: s.isRu ? 'Вес порции' : 'Serving weight',
                      controller: controller,
                      autofocus: true,
                      unit: s.isRu ? 'г' : 'g',
                      onChanged: (raw) => setSheetState(
                        () => selected = int.tryParse(raw) ?? -1,
                      ),
                      errorText: controller.text.isNotEmpty && !valid
                          ? (s.isRu ? 'От 1 до 5000 г' : '1–5000 g')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calculate_outlined, color: c.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Text(
                                valid
                                    ? '${(entry.kcal * factor).round()} ${s.kcalLbl} · '
                                          '${(entry.proteinG * factor).toStringAsFixed(1)} / '
                                          '${(entry.fatG * factor).toStringAsFixed(1)} / '
                                          '${(entry.carbsG * factor).toStringAsFixed(1)} г'
                                    : '—',
                                key: ValueKey(valid ? value : null),
                                style: t.inter(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: c.accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              deleteRequested = true;
                              Navigator.of(ctx).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: c.accent2,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              side: BorderSide(color: c.accent2Soft),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Icon(Icons.delete_outline_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: PrimaryButton(
                            label: s.save,
                            icon: Icons.check_rounded,
                            onTap: valid
                                ? () => Navigator.of(ctx).pop(value)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      controller.dispose();
    }
    if (deleteRequested && context.mounted) {
      await _removeFoodWithMotion(context, data, entry, s);
      return;
    }
    if (grams != null) {
      await data.updateFoodGramsForDate(entry.id, grams, data.selectedDateKey);
    }
  }
}
