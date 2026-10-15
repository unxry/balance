import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/progress_series.dart';
import 'common.dart';
import '../theme/app_text_styles.dart';
import '../utils/calendar_date.dart';
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

String progressNumber(double value, bool isRu) =>
    NumberFormat('0.######', isRu ? 'ru' : 'en').format(value);

String progressDelta(double? value, bool isRu, String unit) {
  if (value == null) return '—';
  final rounded = double.parse(value.toStringAsFixed(6));
  return '${rounded > 0
          ? '+'
          : rounded < 0
          ? '−'
          : ''}'
      '${progressNumber(rounded.abs(), isRu)} $unit';
}

class ProgressChart extends StatefulWidget {
  final ProgressWindow window;
  final List<ProgressLine> lines;
  final String unit;
  final bool isRu;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onSelectDay;

  const ProgressChart({
    super.key,
    required this.window,
    required this.lines,
    required this.unit,
    required this.isRu,
    this.selectedDay,
    this.onSelectDay,
  });

  @override
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = AppText(colors);
    final lines = [
      for (final line in widget.lines)
        ProgressLine(
          label: line.label,
          color: line.color,
          dashed: line.dashed,
          points: pointsInWindow(line.points, widget.window),
        ),
    ];
    final all = lines.expand((line) => line.points).toList();
    if (all.isEmpty) {
      return SizedBox(
        height: 240,
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
              style: text.inter(size: 13, color: colors.muted),
            ),
          ),
        ),
      );
    }
    final scale = ProgressScale.forValues(
      all.map((point) => point.value),
      minimumSpan: widget.unit == 'kg' || widget.unit == 'кг' ? 4 : 8,
    );
    ProgressPoint? selected;
    ProgressLine? selectedLine;
    for (final line in lines) {
      for (final point in line.points) {
        if (point.id == _selectedId &&
            (widget.selectedDay == null ||
                isSameLocalCalendarDay(point.date, widget.selectedDay!))) {
          selected = point;
          selectedLine = line;
        }
      }
    }
    if (selected == null && widget.selectedDay == null) {
      final sorted = [...all]..sort((a, b) => a.date.compareTo(b.date));
      selected = sorted.last;
      selectedLine = lines.firstWhere((line) => line.points.contains(selected));
    }
    if (selected == null && widget.selectedDay != null) {
      for (final line in lines) {
        final point = lastPointOnDay(line.points, widget.selectedDay!);
        if (point != null) {
          selected = point;
          selectedLine = line;
          break;
        }
      }
    }
    final selection = selected;
    final selectionLine = selectedLine;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
      builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Matching axis reserves align plots for kilograms and centimetres.
              final divisions = constraints.maxWidth < 340 ? 2 : 3;
              final lastDay = (widget.window.days - 1).toDouble();
              final ticks = List.generate(
                divisions + 1,
                (index) => (lastDay * index / divisions).round().toDouble(),
              );
              void selectPoint(Offset position) {
                final width = constraints.maxWidth - 32;
                const height = 232.0 - 30;
                ProgressPoint? nearest;
                var distance = 32.0 * 32;
                for (final line in lines) {
                  for (final point in line.points) {
                    final location = Offset(
                      (widget.window.x(point.date) + .2) /
                          (widget.window.days + .35) *
                          width,
                      (scale.maxY - point.value) /
                          (scale.maxY - scale.minY) *
                          height,
                    );
                    final delta = (location - position).distanceSquared;
                    if (delta < distance) {
                      distance = delta;
                      nearest = point;
                    }
                  }
                }
                if (nearest == null) return;
                if (_selectedId != nearest.id) {
                  setState(() => _selectedId = nearest!.id);
                }
                widget.onSelectDay?.call(nearest.date.toLocal());
              }

              return RootSwipeGuard(
                child: SizedBox(
                  height: 232,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) => selectPoint(details.localPosition),
                    onHorizontalDragStart: (details) =>
                        selectPoint(details.localPosition),
                    onHorizontalDragUpdate: (details) =>
                        selectPoint(details.localPosition),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onHover: (event) => selectPoint(event.localPosition),
                      child: IgnorePointer(
                        child: LineChart(
                          LineChartData(
                            minX: -.2,
                            maxX: widget.window.days + .15,
                            minY: scale.minY,
                            maxY: scale.maxY,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: scale.step,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: colors.line.withValues(alpha: .38),
                                strokeWidth: .5,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
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
                                  reservedSize: 32,
                                  interval: scale.step,
                                  minIncluded: false,
                                  maxIncluded: false,
                                  getTitlesWidget: (value, meta) =>
                                      SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 8,
                                        child: Text(
                                          NumberFormat(
                                            '0.#',
                                            widget.isRu ? 'ru' : 'en',
                                          ).format(value),
                                          style: text.inter(
                                            size: 9,
                                            color: colors.muted,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  minIncluded: false,
                                  maxIncluded: false,
                                  getTitlesWidget: (value, meta) =>
                                      ticks.contains(value)
                                      ? SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          space: 9,
                                          fitInside:
                                              SideTitleFitInsideData.fromTitleMeta(
                                                meta,
                                                enabled: true,
                                                distanceFromEdge: 0,
                                              ),
                                          child: Text(
                                            DateFormat(
                                              'd MMM',
                                              widget.isRu ? 'ru' : 'en',
                                            ).format(
                                              widget.window.dateAt(value),
                                            ),
                                            style: text.inter(
                                              size: 9,
                                              color: colors.muted,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),
                            extraLinesData: ExtraLinesData(
                              verticalLines: [
                                if (widget.selectedDay != null &&
                                    widget.window.contains(widget.selectedDay!))
                                  VerticalLine(
                                    x: widget.window.x(
                                      DateTime(
                                        widget.selectedDay!.toLocal().year,
                                        widget.selectedDay!.toLocal().month,
                                        widget.selectedDay!.toLocal().day,
                                        12,
                                      ),
                                    ),
                                    color: colors.muted.withValues(alpha: .4),
                                    strokeWidth: 1,
                                    dashArray: [3, 4],
                                  ),
                              ],
                            ),
                            lineTouchData: const LineTouchData(
                              enabled: false,
                              handleBuiltInTouches: false,
                            ),
                            lineBarsData: [
                              for (final line in lines)
                                LineChartBarData(
                                  spots: [
                                    for (final point in line.points)
                                      FlSpot(
                                        widget.window.x(point.date),
                                        point.value,
                                      ),
                                  ],
                                  isCurved: true,
                                  curveSmoothness: .12,
                                  preventCurveOverShooting: true,
                                  preventCurveOvershootingThreshold: 0,
                                  color: line.color,
                                  barWidth: 2.4,
                                  dashArray: line.dashed ? [5, 4] : null,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, _, _, index) {
                                      final point = line.points[index];
                                      final highlighted =
                                          point.id == selection?.id ||
                                          (widget.selectedDay != null &&
                                              isSameLocalCalendarDay(
                                                point.date,
                                                widget.selectedDay!,
                                              ));
                                      return line.dashed
                                          ? FlDotSquarePainter(
                                              size: highlighted ? 7 : 4,
                                              color: line.color,
                                              strokeColor: colors.card,
                                              strokeWidth: 1,
                                            )
                                          : FlDotCirclePainter(
                                              radius: highlighted
                                                  ? 4.5
                                                  : line.points.length > 45
                                                  ? 1.5
                                                  : 2.4,
                                              color: highlighted
                                                  ? colors.card
                                                  : line.color,
                                              strokeColor: highlighted
                                                  ? line.color
                                                  : colors.card,
                                              strokeWidth: highlighted
                                                  ? 2.4
                                                  : 1.4,
                                            );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show:
                                        lines.length == 1 &&
                                        line.points.length > 1,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        line.color.withValues(alpha: .105),
                                        line.color.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Never interpolate timestamps/values when switching datasets.
                          duration: Duration.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Container(
              key: const ValueKey('progressSelection'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              decoration: BoxDecoration(
                color: colors.accentSoft.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.accent.withValues(alpha: .08)),
              ),
              child: selection == null
                  ? Text(
                      widget.selectedDay != null
                          ? (widget.isRu
                                ? 'Нет измерения за выбранный день'
                                : 'No reading on the selected day')
                          : (widget.isRu
                                ? 'Коснитесь точки для просмотра'
                                : 'Touch a point to inspect'),
                      style: text.inter(
                        size: 11,
                        color: colors.fg2,
                        height: 1.5,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              '${progressNumber(selection.value, widget.isRu)} ${widget.unit}',
                              style: text.fraunces(
                                size: 21,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              selectionLine!.label,
                              style: text.inter(
                                size: 10,
                                color: selectionLine.color,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          DateFormat(
                            'd MMM y · HH:mm:ss',
                            widget.isRu ? 'ru' : 'en',
                          ).format(selection.date.toLocal()),
                          style: text.inter(
                            size: 10,
                            color: colors.fg2,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (all.length == 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.isRu
                    ? 'Первое измерение · Динамики пока нет'
                    : 'One reading — no change yet',
                style: text.inter(size: 10, color: colors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
