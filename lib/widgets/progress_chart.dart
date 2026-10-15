import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weight_forecast.dart';
import '../services/progress_series.dart';
import '../theme/app_text_styles.dart';
import '../utils/calendar_date.dart';
import 'common.dart';
import 'progress_curve.dart';
import 'root_swipe_guard.dart';

class ProgressLine {
  final String label;
  final Color color;
  final List<ProgressPoint> points;
  final bool dashed;
  const ProgressLine({
    required this.label,
    required this.color,
    required this.points,
    this.dashed = false,
  });
}

String progressNumber(double value, bool isRu, {int digits = 6}) =>
    NumberFormat(
      digits == 0 ? '0' : '0.${'#' * digits}',
      isRu ? 'ru' : 'en',
    ).format(value);
String progressDelta(double? value, bool isRu, String unit, {int digits = 1}) {
  if (value == null) return '—';
  final rounded = double.parse(value.toStringAsFixed(digits));
  return '${rounded > 0
      ? '+'
      : rounded < 0
      ? '−'
      : ''}${progressNumber(rounded.abs(), isRu, digits: digits)} $unit';
}

class ProgressChart extends StatefulWidget {
  final ProgressWindow window;
  final List<ProgressLine> lines;
  final String unit;
  final bool isRu;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onSelectDay;
  final List<WeightForecastPoint> forecast;
  final ProgressDomain? sharedDomain;
  final double height;
  final bool showSelection;
  final bool showXAxis;
  const ProgressChart({
    super.key,
    required this.window,
    required this.lines,
    required this.unit,
    required this.isRu,
    this.selectedDay,
    this.onSelectDay,
    this.forecast = const [],
    this.sharedDomain,
    this.height = 192,
    this.showSelection = true,
    this.showXAxis = true,
  });
  ProgressDomain get domain =>
      sharedDomain ??
      ProgressDomain.forPoints(
        window,
        lines.expand((line) => line.points),
        forecast: forecast,
      );
  @override
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart>
    with SingleTickerProviderStateMixin {
  String? _selectedId;
  late final AnimationController _focus = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    value: 1,
  )..addListener(_focusFrame);
  void _focusFrame() {
    if (mounted) setState(() {});
  }

  void _animateFocus() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _focus.value = 1;
    } else {
      _focus.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant ProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateFocus();
      });
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focus = Curves.easeOutCubic.transform(_focus.value);
    final c = context.colors;
    final t = AppText(c);
    final lines = [
      for (final line in widget.lines)
        ProgressLine(
          label: line.label,
          color: line.color,
          dashed: line.dashed,
          points: pointsInWindow(
            line.points,
            widget.window,
          ).where((p) => p.value.isFinite).toList(),
        ),
    ];
    final actual = lines.expand((line) => line.points).toList();
    final predictions = widget.forecast.isEmpty
        ? <ProgressPoint>[]
        : [
            for (var i = 1; i < widget.forecast.length; i++)
              ProgressPoint(
                'forecast-${widget.forecast[i].date.toIso8601String()}',
                widget.forecast[i].date,
                widget.forecast[i].kg,
              ),
          ];
    if (actual.isEmpty && predictions.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.lines.isEmpty
                  ? (widget.isRu
                        ? 'Выберите показатель в легенде'
                        : 'Select a metric in the legend')
                  : (widget.isRu
                        ? 'Нет измерений за этот период'
                        : 'No measurements in this period'),
              textAlign: TextAlign.center,
              style: t.inter(size: 12, color: c.muted, height: 1.5),
            ),
          ),
        ),
      );
    }
    final scale = ProgressScale.forValues([
      ...actual.map((p) => p.value),
      for (final p in widget.forecast) ...[
        p.kg,
        if (p.lowerKg != null) p.lowerKg!,
        if (p.upperKg != null) p.upperKg!,
      ],
    ], minimumSpan: widget.unit == 'kg' || widget.unit == 'кг' ? 2 : 1.5);
    final all = [...actual, ...predictions];
    ProgressPoint? selected;
    ProgressLine? selectedLine;
    for (final point in all) {
      if (point.id == _selectedId &&
          (widget.selectedDay == null ||
              isSameLocalCalendarDay(point.date, widget.selectedDay!))) {
        selected = point;
      }
    }
    if (selected == null && widget.selectedDay != null) {
      for (final line in lines) {
        selected = lastPointOnDay(line.points, widget.selectedDay!);
        if (selected != null) break;
      }
      selected ??= lastPointOnDay(predictions, widget.selectedDay!);
    }
    if (selected == null && widget.selectedDay == null && actual.isNotEmpty) {
      selected = ([...actual]..sort((a, b) => a.date.compareTo(b.date))).last;
    }
    for (final line in lines) {
      if (line.points.any((p) => p.id == selected?.id)) selectedLine = line;
    }
    final predictionSelected =
        selected != null && predictions.any((p) => p.id == selected!.id);
    final selection = selected;
    final label = predictionSelected
        ? (widget.isRu ? 'Прогноз · ориентир' : 'Forecast · estimate')
        : selectedLine?.label;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.5);
    final reserve = 32.0 * textScale;
    final bottom = widget.showXAxis ? 28.0 * textScale : 0.0;
    final domain = widget.domain;
    final minX = domain.minX;
    final maxX = domain.maxX;
    double x(DateTime date) => domain.x(widget.window, date);
    final bars = <LineChartBarData>[];
    final bandIndices = <int>[];
    for (final line in lines) {
      final realSpots = [
        for (final point in line.points) FlSpot(x(point.date), point.value),
      ];
      final markers = <(double, double), ProgressPoint>{
        for (var i = 0; i < realSpots.length; i++)
          (realSpots[i].x, realSpots[i].y): line.points[i],
      };
      final combined = [...realSpots];
      final hasForecast = widget.forecast.isNotEmpty && lines.length == 1;
      if (hasForecast) {
        final anchor = widget.forecast.first;
        if (!combined.any((p) => p.x == x(anchor.date) && p.y == anchor.kg)) {
          combined.add(FlSpot(x(anchor.date), anchor.kg));
        }
        combined.addAll(predictions.map((p) => FlSpot(x(p.date), p.value)));
      }
      final curve = conservativeWeightCurveSpots(
        combined,
        samplesPerSegment: actual.length > 90 ? 4 : 12,
      );
      final anchorX = hasForecast
          ? x(widget.forecast.first.date)
          : double.infinity;
      bars.add(
        LineChartBarData(
          spots: curve.where((p) => p.x <= anchorX).toList(),
          isCurved: false,
          color: line.color,
          barWidth: 2.5,
          dashArray: line.dashed ? [5, 3] : null,
          isStrokeCapRound: true,
          isStrokeJoinRound: true,
          dotData: FlDotData(
            checkToShowDot: (spot, _) => markers.containsKey((spot.x, spot.y)),
            getDotPainter: (spot, _, _, _) {
              final point = markers[(spot.x, spot.y)]!;
              final active =
                  point.id == selection?.id ||
                  (widget.selectedDay != null &&
                      isSameLocalCalendarDay(point.date, widget.selectedDay!));
              return line.dashed
                  ? FlDotSquarePainter(
                      size: active ? 5.8 + .7 * focus : 3.8,
                      color: active ? c.card : line.color,
                      strokeColor: active ? line.color : c.card,
                      strokeWidth: active ? 2 : 1,
                    )
                  : FlDotCirclePainter(
                      radius: active
                          ? 3.5 + .7 * focus
                          : actual.length > 90
                          ? 1.5
                          : 2.3,
                      color: active ? c.card : line.color,
                      strokeColor: active ? line.color : c.card,
                      strokeWidth: active ? 1.4 + .6 * focus : 1.3,
                    );
            },
          ),
          belowBarData: BarAreaData(
            show: lines.length == 1 && actual.length > 1,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                line.color.withValues(alpha: .085),
                line.color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      );
      if (hasForecast) {
        bars.add(
          LineChartBarData(
            spots: curve.where((p) => p.x >= anchorX).toList(),
            color: line.color.withValues(alpha: .6),
            barWidth: 2,
            dashArray: [4, 5],
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        );
        if (widget.forecast.every(
          (p) => p.lowerKg != null && p.upperKg != null,
        )) {
          bandIndices.addAll([bars.length, bars.length + 1]);
          for (final lower in [true, false]) {
            bars.add(
              LineChartBarData(
                spots: [
                  for (final p in widget.forecast)
                    FlSpot(x(p.date), lower ? p.lowerKg! : p.upperKg!),
                ],
                color: Colors.transparent,
                barWidth: 0,
                dotData: const FlDotData(show: false),
              ),
            );
          }
        }
      }
    }
    if (predictionSelected) {
      bars.add(
        LineChartBarData(
          spots: [FlSpot(x(selection!.date), selection.value)],
          barWidth: 0,
          dotData: FlDotData(
            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
              radius: 4,
              color: c.card,
              strokeColor: c.accent.withValues(alpha: .65),
              strokeWidth: 1.8,
            ),
          ),
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 220),
      builder: (_, value, child) => Opacity(opacity: value, child: child),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              void selectPoint(Offset position) {
                ProgressPoint? nearest;
                var distance = 32.0 * 32;
                for (final point in all) {
                  final pixel = Offset(
                    (x(point.date) - minX) /
                        (maxX - minX) *
                        (constraints.maxWidth - reserve),
                    (scale.maxY - point.value) /
                        (scale.maxY - scale.minY) *
                        widget.height,
                  );
                  final d = (pixel - position).distanceSquared;
                  if (d < distance) {
                    distance = d;
                    nearest = point;
                  }
                }
                final point = nearest;
                if (point == null) return;
                if (_selectedId != point.id) {
                  setState(() => _selectedId = point.id);
                  _animateFocus();
                }
                widget.onSelectDay?.call(point.date.toLocal());
              }

              final desiredDivisions =
                  constraints.maxWidth < 340 || textScale > 1.35 ? 2 : 3;
              final divisions = domain.span.floor().clamp(1, desiredDivisions);
              final tickStep = domain.span == 0 ? 1.0 : domain.span / divisions;
              return RootSwipeGuard(
                child: SizedBox(
                  height: widget.height + bottom,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => selectPoint(d.localPosition),
                    onHorizontalDragStart: (d) => selectPoint(d.localPosition),
                    onHorizontalDragUpdate: (d) => selectPoint(d.localPosition),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onHover: (e) => selectPoint(e.localPosition),
                      child: IgnorePointer(
                        child: LineChart(
                          LineChartData(
                            minX: minX,
                            maxX: maxX,
                            minY: scale.minY,
                            maxY: scale.maxY,
                            clipData: const FlClipData.horizontal(),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              drawVerticalLine: false,
                              horizontalInterval: scale.step,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: c.line.withValues(alpha: .28),
                                strokeWidth: .5,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: reserve,
                                  interval: scale.step,
                                  minIncluded: false,
                                  maxIncluded: false,
                                  getTitlesWidget: (v, m) => SideTitleWidget(
                                    axisSide: m.axisSide,
                                    space: 6,
                                    child: Text(
                                      progressNumber(v, widget.isRu, digits: 2),
                                      style: t.inter(size: 9, color: c.muted),
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: widget.showXAxis,
                                  reservedSize: bottom,
                                  interval: tickStep,
                                  minIncluded: false,
                                  maxIncluded: false,
                                  getTitlesWidget: (v, m) =>
                                      v >= -1e-8 && v <= domain.span + 1e-8
                                      ? SideTitleWidget(
                                          axisSide: m.axisSide,
                                          space: 9,
                                          fitInside:
                                              SideTitleFitInsideData.fromTitleMeta(
                                                m,
                                                enabled: true,
                                                distanceFromEdge: 0,
                                              ),
                                          child: Text(
                                            DateFormat(
                                              domain.span > 0 && domain.span < 1
                                                  ? 'HH:mm'
                                                  : 'd MMM',
                                              widget.isRu ? 'ru' : 'en',
                                            ).format(
                                              domain.dateAt(widget.window, v),
                                            ),
                                            style: t.inter(
                                              size: 9,
                                              color: c.muted,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),
                            extraLinesData: ExtraLinesData(
                              verticalLines: [
                                if (widget.forecast.isNotEmpty)
                                  VerticalLine(
                                    x: x(widget.forecast.first.date),
                                    color: c.accent.withValues(alpha: .13),
                                    strokeWidth: .7,
                                    dashArray: [2, 4],
                                  ),
                                if (widget.selectedDay != null)
                                  VerticalLine(
                                    x: x(
                                      DateTime(
                                        widget.selectedDay!.year,
                                        widget.selectedDay!.month,
                                        widget.selectedDay!.day,
                                        12,
                                      ),
                                    ),
                                    color: c.muted.withValues(alpha: .3),
                                    strokeWidth: .8,
                                    dashArray: [3, 4],
                                  ),
                              ],
                            ),
                            betweenBarsData: bandIndices.isEmpty
                                ? []
                                : [
                                    BetweenBarsData(
                                      fromIndex: bandIndices[0],
                                      toIndex: bandIndices[1],
                                      color: c.accent.withValues(alpha: .075),
                                    ),
                                  ],
                            lineTouchData: const LineTouchData(
                              enabled: false,
                              handleBuiltInTouches: false,
                            ),
                            lineBarsData: bars,
                          ),
                          duration: Duration.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.showSelection) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: AnimatedSwitcher(
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                child: Container(
                  key: ValueKey(
                    'selection-${selection?.id}:${widget.selectedDay}',
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: c.accentSoft.withValues(alpha: .32),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: c.accent.withValues(alpha: .08)),
                  ),
                  child: selection == null
                      ? Text(
                          widget.isRu
                              ? 'Нет измерения за выбранный день'
                              : 'No reading on the selected day',
                          style: t.inter(size: 11, color: c.fg2),
                        )
                      : Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 5,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label ?? '',
                                  style: t.inter(
                                    size: 10,
                                    color: predictionSelected
                                        ? c.accent
                                        : selectedLine?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'd MMM y${predictionSelected ? '' : ' · HH:mm'}',
                                    widget.isRu ? 'ru' : 'en',
                                  ).format(selection.date.toLocal()),
                                  style: t.inter(size: 10, color: c.fg2),
                                ),
                              ],
                            ),
                            Text(
                              '${predictionSelected ? '≈ ' : ''}${progressNumber(selection.value, widget.isRu, digits: 1)} ${widget.unit}',
                              key: const ValueKey('progressSelection'),
                              style: t.fraunces(
                                size: 22,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            if (actual.length == 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.isRu
                      ? 'Первое измерение · Динамики пока нет'
                      : 'One reading — no change yet',
                  style: t.inter(size: 10, color: c.muted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
