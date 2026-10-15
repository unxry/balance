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
              // Fixed reserves keep comparison plots aligned independently of units.
              final divisions = constraints.maxWidth < 340 ? 2 : 3;
              final lastDay = (widget.window.days - 1).toDouble();
              final ticks = List.generate(
                divisions + 1,
                (index) => (lastDay * index / divisions).round().toDouble(),
              );
              return RootSwipeGuard(
                child: SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minX: -.35,
                      maxX: widget.window.days + .35,
                      minY: scale.minY,
                      maxY: scale.maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: scale.step,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: colors.line.withValues(alpha: .45),
                          strokeWidth: .6,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: _noTitle,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: scale.step,
                            minIncluded: false,
                            maxIncluded: false,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 6,
                              child: Text(
                                progressNumber(value, widget.isRu),
                                style: text.inter(size: 9, color: colors.muted),
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
                                      ).format(widget.window.dateAt(value)),
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
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: false,
                        touchSpotThreshold: 32,
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response?.lineBarSpots?.isNotEmpty != true) {
                            return;
                          }
                          final spot = response!.lineBarSpots!.first;
                          final point =
                              lines[spot.barIndex].points[spot.spotIndex];
                          if (_selectedId != point.id) {
                            setState(() => _selectedId = point.id);
                          }
                          widget.onSelectDay?.call(point.date.toLocal());
                        },
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
                            isCurved: false,
                            color: line.color,
                            barWidth: 2,
                            dashArray: line.dashed ? [6, 4] : null,
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
                                        size: highlighted ? 8 : 5,
                                        color: line.color,
                                        strokeColor: colors.card,
                                        strokeWidth: 1,
                                      )
                                    : FlDotCirclePainter(
                                        radius: highlighted
                                            ? 4.5
                                            : line.points.length > 90
                                            ? 1.8
                                            : 3,
                                        color: line.color,
                                        strokeColor: colors.card,
                                        strokeWidth: 1.5,
                                      );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: lines.length == 1 && line.points.length > 1,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  line.color.withValues(alpha: .12),
                                  line.color.withValues(alpha: .01),
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
              );
            },
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.card2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selection == null
                    ? (widget.isRu
                          ? 'Коснитесь точки для просмотра'
                          : 'Touch a point to inspect')
                    : '${selectionLine!.label} · ${progressNumber(selection.value, widget.isRu)} ${widget.unit}'
                          '\n${DateFormat('d MMM y · HH:mm:ss', widget.isRu ? 'ru' : 'en').format(selection.date.toLocal())}',
                style: text.inter(size: 11, height: 1.5),
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

Widget _noTitle(double value, TitleMeta meta) => const SizedBox.shrink();
