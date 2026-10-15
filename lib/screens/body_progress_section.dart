import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/body_measurement.dart';
import '../models/weight_forecast.dart';
import '../providers/app_data_provider.dart';
import '../services/progress_series.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/calendar_date.dart';
import '../widgets/common.dart';
import '../widgets/progress_chart.dart';
import '../widgets/weight_forecast_note.dart';

String bodyTypeLabel(BodyMeasurementType type, bool isRu) => switch (type) {
  BodyMeasurementType.chest => isRu ? 'Грудь' : 'Chest',
  BodyMeasurementType.hips => isRu ? 'Бёдра' : 'Hips',
};

Color _bodyColor(BodyMeasurementType type, AppColors colors) =>
    type == BodyMeasurementType.chest
    ? colors.accent
    : colors.brightness == Brightness.dark
    ? const Color(0xFFD5A28D)
    : const Color(0xFFA96D58);

Future<void> showBodyMeasurementEditor(
  BuildContext context, {
  required bool isRu,
  BodyMeasurement? entry,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: context.colors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => _BodyMeasurementEditor(
    data: context.read<AppDataProvider>(),
    isRu: isRu,
    entry: entry,
  ),
);

class BodyProgressSection extends StatefulWidget {
  final int days;
  final bool comparison;
  final bool isRu;

  const BodyProgressSection({
    super.key,
    required this.days,
    required this.comparison,
    required this.isRu,
  });

  @override
  State<BodyProgressSection> createState() => _BodyProgressSectionState();
}

class _BodyProgressSectionState extends State<BodyProgressSection> {
  final _visible = <BodyMeasurementType>{...BodyMeasurementType.values};
  DateTime? _selectedDay;
  int _historyLimit = 20;

  @override
  void didUpdateWidget(BodyProgressSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days != widget.days) {
      _selectedDay = null;
      _historyLimit = 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final colors = context.colors;
    final text = AppText(colors);
    final ru = widget.isRu;
    final cm = ru ? 'см' : 'cm';
    final kg = ru ? 'кг' : 'kg';
    final window = ProgressWindow(days: widget.days, now: data.today);
    final measurements = data.bodyMeasurements;
    List<ProgressPoint> bodyPoints(BodyMeasurementType type) => pointsInWindow(
      measurements
          .where((entry) => entry.type == type)
          .map((entry) => ProgressPoint(entry.id, entry.date, entry.cm)),
      window,
    );
    final weights = pointsInWindow(
      data.weightHistory.map(
        (entry) => ProgressPoint(entry.id, entry.date, entry.kg),
      ),
      window,
    );
    final chest = bodyPoints(BodyMeasurementType.chest);
    final hips = bodyPoints(BodyMeasurementType.hips);
    final dates = <String, DateTime>{};
    for (final point in [...weights, ...chest, ...hips]) {
      dates[localDateKey(point.date)] = point.date.toLocal();
    }
    final keys = dates.keys.toList()..sort();
    final fullForecast = data.analyticsForDays(widget.days).forecastPoints;
    final forecast = weights.isEmpty
        ? <WeightForecastPoint>[]
        : forecastInProgressView(window, [
            ...weights,
            ...chest,
            ...hips,
          ], fullForecast);
    final domain = ProgressDomain.forPoints(window, [
      ...weights,
      ...chest,
      ...hips,
    ], forecast: forecast);
    final maxX = math.max(
      widget.days + .15,
      forecast.isEmpty ? 0.0 : window.x(forecast.last.date) + .6,
    );
    final selectedDay =
        _selectedDay != null &&
            !(_selectedDay!.isBefore(window.start)) &&
            window.x(_selectedDay!) <= maxX
        ? _selectedDay
        : (keys.isEmpty ? null : dates[keys.last]);
    final history = measurements
        .where((entry) => window.contains(entry.date))
        .toList()
        .reversed
        .toList();

    final bodyLines = [
      for (final type in BodyMeasurementType.values)
        if (_visible.contains(type))
          ProgressLine(
            label: bodyTypeLabel(type, ru),
            color: _bodyColor(type, colors),
            dashed: type == BodyMeasurementType.hips,
            points: type == BodyMeasurementType.chest ? chest : hips,
          ),
    ];
    Widget legend() => Wrap(
      spacing: 7,
      runSpacing: 4,
      children: [
        for (final type in BodyMeasurementType.values)
          FilterChip(
            key: ValueKey('bodyLegend-${type.name}'),
            selected: _visible.contains(type),
            selectedColor: _bodyColor(type, colors).withValues(alpha: .07),
            backgroundColor: Colors.transparent,
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            side: BorderSide(
              color: _bodyColor(
                type,
                colors,
              ).withValues(alpha: _visible.contains(type) ? .22 : .08),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            avatar: Icon(
              type == BodyMeasurementType.chest ? Icons.circle : Icons.square,
              size: 7,
              color: _bodyColor(type, colors),
            ),
            label: Text(
              bodyTypeLabel(type, ru),
              style: text.inter(
                size: 10,
                color: _visible.contains(type) ? colors.fg2 : colors.muted,
                weight: FontWeight.w500,
              ),
            ),
            onSelected: (visible) => setState(
              () => visible ? _visible.add(type) : _visible.remove(type),
            ),
          ),
      ],
    );
    Widget chart(
      List<ProgressLine> lines,
      String unit, {
      bool weight = false,
    }) => ProgressChart(
      key: ValueKey('bodyChart-$unit'),
      window: window,
      lines: lines,
      unit: unit,
      isRu: ru,
      forecast: weight ? forecast : const [],
      sharedDomain: widget.comparison ? domain : null,
      selectedDay: widget.comparison ? selectedDay : null,
      onSelectDay: widget.comparison
          ? (day) => setState(() => _selectedDay = day)
          : null,
      height: widget.comparison ? 126 : 184,
      showSelection: !widget.comparison,
      showXAxis: !weight || !widget.comparison,
    );
    Widget selectedDate() => Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: colors.accentSoft.withValues(alpha: .28),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            key: const ValueKey('comparisonDate'),
            style: TextButton.styleFrom(
              foregroundColor: colors.accent,
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            icon: const Icon(Icons.calendar_today_outlined, size: 13),
            label: Text(
              selectedDay == null
                  ? (ru ? 'Выберите дату' : 'Select date')
                  : DateFormat('d MMM y', ru ? 'ru' : 'en').format(selectedDay),
              style: text.inter(
                size: 11,
                color: colors.accent,
                weight: FontWeight.w600,
              ),
            ),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDay ?? data.today,
                firstDate: window.start,
                lastDate: forecast.isEmpty
                    ? window.dateAt(widget.days - 1)
                    : forecast.last.date,
              );
              if (date != null && mounted) setState(() => _selectedDay = date);
            },
          ),
          if (selectedDay != null &&
              lastPointOnDay(weights, selectedDay) == null &&
              forecast.any((p) => isSameLocalCalendarDay(p.date, selectedDay)))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${ru ? 'Вес' : 'Weight'}: ≈ ${progressNumber(forecast.lastWhere((p) => isSameLocalCalendarDay(p.date, selectedDay)).kg, ru, digits: 1)} $kg · ${ru ? 'Прогноз' : 'Forecast'}',
                key: ValueKey('comparisonValue-${ru ? 'Вес' : 'Weight'}'),
                style: text.inter(size: 12, color: colors.accent),
              ),
            )
          else
            _dayRow(text, ru ? 'Вес' : 'Weight', weights, selectedDay, kg),
          _dayRow(
            text,
            bodyTypeLabel(BodyMeasurementType.chest, ru),
            chest,
            selectedDay,
            cm,
          ),
          _dayRow(
            text,
            bodyTypeLabel(BodyMeasurementType.hips, ru),
            hips,
            selectedDay,
            cm,
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ru
              ? (widget.comparison ? 'Сравнение' : 'Замеры тела')
              : (widget.comparison ? 'Comparison' : 'Body measurements'),
          style: text.fraunces(size: 30, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '${DateFormat('d MMM', ru ? 'ru' : 'en').format(window.start)} — ${DateFormat('d MMM y', ru ? 'ru' : 'en').format(window.dateAt(widget.days - 1))}',
          style: text.inter(size: 10, color: colors.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        if (widget.comparison) ...[
          _comparisonSummary(context, [
            (ru ? 'Вес' : 'Weight', weights, kg, colors.accent),
            (
              bodyTypeLabel(BodyMeasurementType.chest, ru),
              chest,
              cm,
              colors.accent,
            ),
            (
              bodyTypeLabel(BodyMeasurementType.hips, ru),
              hips,
              cm,
              _bodyColor(BodyMeasurementType.hips, colors),
            ),
          ]),
          const SizedBox(height: 12),
          SectionCard(
            radius: 26,
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ru ? 'Вес' : 'Weight',
                        style: text.fraunces(size: 18),
                      ),
                    ),
                    if (forecast.isNotEmpty)
                      Text(
                        ru ? '┄  Прогноз' : '┄  Forecast',
                        style: text.inter(size: 10, color: colors.accent),
                      ),
                    const SizedBox(width: 10),
                    Text(kg, style: text.inter(size: 10, color: colors.muted)),
                  ],
                ),
                const SizedBox(height: 12),
                chart(
                  [
                    ProgressLine(
                      label: ru ? 'Вес' : 'Weight',
                      color: colors.accent,
                      points: weights,
                    ),
                  ],
                  kg,
                  weight: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    color: colors.line.withValues(alpha: .5),
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: legend()),
                    Text(cm, style: text.inter(size: 10, color: colors.muted)),
                  ],
                ),
                const SizedBox(height: 8),
                chart(bodyLines, cm),
                const SizedBox(height: 12),
                selectedDate(),
                const SizedBox(height: 10),
                Text(
                  ru
                      ? 'Общая дата · отдельные шкалы. Пропуски остаются пустыми.'
                      : 'Shared date · separate scales. Missing readings stay empty.',
                  style: text.inter(size: 9, color: colors.fg2, height: 1.5),
                ),
                if (forecast.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      ru
                          ? 'Пунктир — прогноз веса. Подложка — разброс оценок темпа, не гарантия.${forecast.length < fullForecast.length ? ' Показана ближайшая часть прогноза.' : ''}'
                          : 'Dashes show the weight forecast. Shading shows trend variation, not a guarantee.${forecast.length < fullForecast.length ? ' Only the nearest part of the forecast is shown.' : ''}',
                      style: text.inter(
                        size: 9,
                        color: colors.fg2,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (forecast.isEmpty) ...[
            const SizedBox(height: 10),
            WeightForecastNote(
              snapshot: data.weightForecast,
              isRu: ru,
              active: false,
              compact: true,
              limitedPeriod: fullForecast.isNotEmpty,
              emptyPeriod: weights.isEmpty,
            ),
          ],
        ] else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                for (final type in BodyMeasurementType.values)
                  _metricCard(
                    context,
                    type,
                    measurements
                        .where(
                          (entry) =>
                              entry.type == type &&
                              entry.date.isBefore(window.endExclusive),
                        )
                        .toList(),
                  ),
              ];
              return constraints.maxWidth < 270 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.35
                  ? Column(
                      children: [
                        cards[0],
                        const SizedBox(height: 10),
                        cards[1],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 10),
                        Expanded(child: cards[1]),
                      ],
                    );
            },
          ),
          const SizedBox(height: 14),
          SectionCard(
            radius: 26,
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ru ? 'Динамика обхватов' : 'Measurement trends',
                  style: text.fraunces(size: 19),
                ),
                const SizedBox(height: 8),
                legend(),
                const SizedBox(height: 10),
                chart(bodyLines, cm),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            radius: 20,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ru ? 'Изменение за период' : 'Change in this period',
                  style: text.inter(size: 12, weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                _summaryRow(
                  text,
                  bodyTypeLabel(BodyMeasurementType.chest, ru),
                  chest,
                  cm,
                ),
                _summaryRow(
                  text,
                  bodyTypeLabel(BodyMeasurementType.hips, ru),
                  hips,
                  cm,
                ),
                const SizedBox(height: 6),
                Text(
                  ru
                      ? 'От первой до последней реальной записи.'
                      : 'First to last real reading.',
                  style: text.inter(size: 9, color: colors.muted),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          key: const ValueKey('addBodyMeasurement'),
          label: ru ? 'Добавить замер' : 'Add measurement',
          icon: Icons.add_rounded,
          onTap: () => showBodyMeasurementEditor(context, isRu: ru),
        ),
        const SizedBox(height: 22),
        Text(
          ru ? 'История замеров' : 'Measurement history',
          style: text.fraunces(size: 21, weight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              ru
                  ? 'Пока нет замеров. Можно добавить только один обхват.'
                  : 'No measurements yet. You can record just one circumference.',
              style: text.inter(size: 12, color: colors.muted),
            ),
          ),
        for (final entry in history.take(_historyLimit))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: colors.line),
              ),
              child: ListTile(
                key: ValueKey('bodyEntry-${entry.id}'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                title: Text(
                  bodyTypeLabel(entry.type, ru),
                  style: text.inter(size: 13, weight: FontWeight.w700),
                ),
                subtitle: Text(
                  DateFormat(
                    'd MMM y · HH:mm',
                    ru ? 'ru' : 'en',
                  ).format(entry.date.toLocal()),
                  style: text.inter(size: 10, color: colors.muted),
                ),
                trailing: Text(
                  '${progressNumber(entry.cm, ru)} $cm',
                  style: text.fraunces(size: 20),
                ),
                onTap: () =>
                    showBodyMeasurementEditor(context, isRu: ru, entry: entry),
              ),
            ),
          ),
        if (history.length > _historyLimit)
          TextButton(
            onPressed: () => setState(() => _historyLimit += 20),
            child: Text(ru ? 'Показать ещё' : 'Show more'),
          ),
      ],
    );
  }

  Widget _summaryRow(
    AppText text,
    String label,
    List<ProgressPoint> points,
    String unit,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Text(label, style: text.inter(size: 12)),
        Text(
          '${progressDelta(progressChange(points), widget.isRu, unit)} · '
          '${points.length} ${widget.isRu ? 'зап.' : 'readings'}',
          style: text.inter(size: 12),
        ),
      ],
    ),
  );

  Widget _dayRow(
    AppText text,
    String label,
    List<ProgressPoint> points,
    DateTime? day,
    String unit,
  ) {
    final point = day == null ? null : lastPointOnDay(points, day);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '$label: ${point == null ? (widget.isRu ? 'нет данных' : 'no data') : '${progressNumber(point.value, widget.isRu, digits: 1)} $unit · ${DateFormat('HH:mm').format(point.date.toLocal())}'}',
        key: ValueKey('comparisonValue-$label'),
        style: text.inter(size: 13),
      ),
    );
  }

  Widget _comparisonSummary(
    BuildContext context,
    List<(String, List<ProgressPoint>, String, Color)> metrics,
  ) {
    final c = context.colors;
    final t = AppText(c);
    Widget item(int index, {bool row = false}) {
      final metric = metrics[index];
      final label = Text(metric.$1, style: t.inter(size: 10, color: c.fg2));
      final value = Text(
        progressDelta(progressChange(metric.$2), widget.isRu, metric.$3),
        key: ValueKey('comparisonDelta-$index'),
        style: t.fraunces(size: 21, color: metric.$4),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: row
            ? Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 5,
                children: [label, value],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [label, const SizedBox(height: 5), value],
              ),
      );
    }

    return SectionCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: MediaQuery.textScalerOf(context).scale(1) > 1.35
          ? Column(
              children: [
                for (var i = 0; i < metrics.length; i++) item(i, row: true),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < metrics.length; i++)
                  Expanded(child: item(i)),
              ],
            ),
    );
  }

  Widget _metricCard(
    BuildContext context,
    BodyMeasurementType type,
    List<BodyMeasurement> entries,
  ) {
    final c = context.colors;
    final t = AppText(c);
    final ru = widget.isRu;
    final last = entries.isEmpty ? null : entries.last;
    final previous = entries.length < 2 ? null : entries[entries.length - 2];
    final delta = previous == null ? null : last!.cm - previous.cm;
    final color = _bodyColor(type, c);
    return SectionCard(
      radius: 23,
      padding: const EdgeInsets.all(13),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      type == BodyMeasurementType.chest ? 5 : 1,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    bodyTypeLabel(type, ru),
                    style: t.inter(
                      size: 11,
                      weight: FontWeight.w600,
                      color: c.fg2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: last == null
                        ? '—'
                        : progressNumber(last.cm, ru, digits: 1),
                    style: t.fraunces(
                      size: constraints.maxWidth < 140 ? 28 : 32,
                    ),
                  ),
                  TextSpan(
                    text: ' ${ru ? 'см' : 'cm'}',
                    style: t.inter(size: 11, color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .075),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                progressDelta(delta, ru, ru ? 'см' : 'cm'),
                style: t.inter(size: 11, color: color, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              previous == null
                  ? (ru ? 'Первый замер' : 'First reading')
                  : '${ru ? 'Было' : 'Previous'} ${progressNumber(previous.cm, ru, digits: 1)}',
              style: t.inter(size: 9, color: c.muted),
            ),
            const SizedBox(height: 8),
            Text(
              last == null
                  ? (ru ? 'Добавьте замер' : 'Add a reading')
                  : DateFormat(
                      'd MMM y',
                      ru ? 'ru' : 'en',
                    ).format(last.date.toLocal()),
              style: t.inter(size: 9, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyMeasurementEditor extends StatefulWidget {
  final AppDataProvider data;
  final bool isRu;
  final BodyMeasurement? entry;
  const _BodyMeasurementEditor({
    required this.data,
    required this.isRu,
    this.entry,
  });
  @override
  State<_BodyMeasurementEditor> createState() => _BodyMeasurementEditorState();
}

class _BodyMeasurementEditorState extends State<_BodyMeasurementEditor> {
  late final TextEditingController _value;
  late BodyMeasurementType _type;
  late DateTime _date;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = widget.data.today;
    final clock = DateTime.now();
    _date =
        widget.entry?.date.toLocal() ??
        DateTime(today.year, today.month, today.day, clock.hour, clock.minute);
    _type = widget.entry?.type ?? BodyMeasurementType.chest;
    _value = TextEditingController(
      text: widget.entry == null
          ? ''
          : (widget.isRu
                ? widget.entry!.cm.toString().replaceAll('.', ',')
                : widget.entry!.cm.toString()),
    );
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = BodyMeasurement.parseValue(_value.text);
    if (value == null) {
      setState(
        () => _error = widget.isRu
            ? 'Введите значение от 10 до 300 см'
            : 'Enter a value from 10 to 300 cm',
      );
      return;
    }
    await _commit(
      () => widget.entry == null
          ? widget.data.addBodyMeasurement(type: _type, cm: value, date: _date)
          : widget.data.updateBodyMeasurement(
              widget.entry!.id,
              cm: value,
              date: _date,
            ),
    );
  }

  Future<void> _commit(Future<bool> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await action();
      if (!mounted) return;
      if (saved) {
        Navigator.of(context).pop();
        return;
      }
      setState(
        () => _error = widget.isRu
            ? 'Проверьте дату и значение'
            : 'Check date and value',
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = widget.isRu
              ? 'Не удалось сохранить. Попробуйте ещё раз.'
              : 'Could not save. Please try again.',
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete() async {
    final ru = widget.isRu;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ru ? 'Удалить замер?' : 'Delete measurement?'),
        content: Text(
          ru
              ? 'Запись будет удалена из истории.'
              : 'This reading will be removed from history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ru ? 'Отмена' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(ru ? 'Удалить' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _commit(() => widget.data.deleteBodyMeasurement(widget.entry!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = AppText(colors);
    final ru = widget.isRu;
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AbsorbPointer(
            absorbing: _saving,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ru
                      ? (widget.entry == null
                            ? 'Новый замер'
                            : 'Изменить замер')
                      : (widget.entry == null
                            ? 'New measurement'
                            : 'Edit measurement'),
                  style: text.fraunces(size: 28),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final type in BodyMeasurementType.values)
                      ChoiceChip(
                        label: Text(bodyTypeLabel(type, ru)),
                        selected: _type == type,
                        onSelected: widget.entry == null
                            ? (_) => setState(() => _type = type)
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('bodyMeasurementValue'),
                  controller: _value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: text.fraunces(size: 32),
                  decoration: InputDecoration(
                    labelText: ru ? 'Обхват' : 'Circumference',
                    suffixText: ru ? 'см' : 'cm',
                    hintText: ru ? '92,5' : '92.5',
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined, size: 17),
                      label: Text(
                        DateFormat('d MMM y', ru ? 'ru' : 'en').format(_date),
                      ),
                      onPressed: () async {
                        final today = widget.data.today;
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(
                            today.year - 50,
                            today.month,
                            today.day,
                          ),
                          lastDate: today,
                        );
                        if (date != null && mounted) {
                          setState(
                            () => _date = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              _date.hour,
                              _date.minute,
                              _date.second,
                              _date.millisecond,
                              _date.microsecond,
                            ),
                          );
                        }
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.schedule_rounded, size: 17),
                      label: Text(DateFormat('HH:mm').format(_date)),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_date),
                        );
                        if (time != null && mounted) {
                          setState(
                            () => _date = DateTime(
                              _date.year,
                              _date.month,
                              _date.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  key: const ValueKey('saveBodyMeasurement'),
                  label: _saving
                      ? (ru ? 'Сохранение…' : 'Saving…')
                      : (ru ? 'Сохранить' : 'Save'),
                  onTap: _saving ? null : _save,
                ),
                if (widget.entry != null)
                  Center(
                    child: TextButton(
                      key: const ValueKey('deleteBodyMeasurement'),
                      onPressed: _saving ? null : _delete,
                      child: Text(ru ? 'Удалить замер' : 'Delete measurement'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
