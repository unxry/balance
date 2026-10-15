import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/body_measurement.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/body_progress_section.dart';
import 'package:flutter_app/screens/weight_screen.dart';
import 'package:flutter_app/services/progress_series.dart';
import 'package:flutter_app/widgets/progress_chart.dart';

void main() {
  late Directory directory;
  late AppDataProvider data;
  var sequence = 0;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
    directory = await Directory.systemTemp.createTemp('body_widget_');
    Hive.init(directory.path);
  });
  setUp(() async {
    sequence++;
    data = AppDataProvider(
      now: () => DateTime(2026, 10, 15, 12),
      userBox: await Hive.openBox<dynamic>('body_w_user_$sequence'),
      foodBox: await Hive.openBox<dynamic>('body_w_food_$sequence'),
      weightBox: await Hive.openBox<dynamic>('body_w_weight_$sequence'),
    );
    await data.load();
  });
  tearDown(() => data.dispose());
  tearDownAll(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  Widget app(Widget child, {double scale = 1, bool dark = false}) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: data),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child,
            ),
          ),
        ),
      );

  for (final size in [
    const Size(320, 568),
    const Size(414, 896),
    const Size(430, 932),
  ]) {
    for (final ru in [true, false]) {
      testWidgets(
        'body and comparison fit $size ${ru ? 'RU' : 'EN'} at larger text',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.runAsync(() async {
            await data.addWeightEntry(80, date: DateTime(2026, 10, 1, 8));
            await data.addWeightEntry(79.8, date: DateTime(2026, 10, 15, 8));
            for (final type in BodyMeasurementType.values) {
              await data.addBodyMeasurement(
                type: type,
                cm: 92.5,
                date: DateTime(2026, 10, 2, 9),
              );
              await data.addBodyMeasurement(
                type: type,
                cm: 91,
                date: DateTime(2026, 10, 15, 9),
              );
            }
          });
          for (final comparison in [false, true]) {
            await tester.pumpWidget(
              app(
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: BodyProgressSection(
                      days: 30,
                      comparison: comparison,
                      isRu: ru,
                    ),
                  ),
                ),
                scale: 1.5,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.drag(
              find.byType(SingleChildScrollView).first,
              const Offset(0, -1000),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('add chest only, edit, cancel deletion and confirm deletion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(414, 896));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(WeightScreen(onBack: () {})));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progressMode-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('addWeightButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('bodyMeasurementValue')),
      '92,5',
    );
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('saveBodyMeasurement')));
      await data.persistPendingMutations();
    });
    await tester.pumpAndSettle();
    expect(data.bodyMeasurements, hasLength(1));
    expect(data.bodyMeasurements.single.type, BodyMeasurementType.chest);
    final id = data.bodyMeasurements.single.id;
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('bodyEntry-$id')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(ValueKey('bodyEntry-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('bodyEntry-$id')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('bodyMeasurementValue')),
      '93.5',
    );
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('saveBodyMeasurement')));
      await data.persistPendingMutations();
    });
    await tester.pumpAndSettle();
    expect(data.bodyMeasurements.single.cm, 93.5);
    await tester.tap(find.byKey(ValueKey('bodyEntry-$id')));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => tester.tap(find.byKey(const ValueKey('deleteBodyMeasurement'))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(data.bodyMeasurements, hasLength(1));
    await tester.runAsync(
      () => tester.tap(find.byKey(const ValueKey('deleteBodyMeasurement'))),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Удалить').last);
      await data.persistPendingMutations();
    });
    await tester.pumpAndSettle();
    expect(data.bodyMeasurements, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('comparison aligns axes and never fills unmatched dates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(414, 896));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await data.addWeightEntry(80, date: DateTime(2026, 10, 15, 8));
      await data.addBodyMeasurement(
        type: BodyMeasurementType.chest,
        cm: 92.5,
        date: DateTime(2026, 10, 14, 9),
      );
      await data.addBodyMeasurement(
        type: BodyMeasurementType.hips,
        cm: 98,
        date: DateTime(2026, 10, 13, 9),
      );
    });
    await tester.pumpWidget(
      app(
        SingleChildScrollView(
          child: BodyProgressSection(days: 30, comparison: true, isRu: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final charts = tester
        .widgetList<LineChart>(find.byType(LineChart))
        .toList();
    expect(charts, hasLength(2));
    expect(charts[0].data.minX, charts[1].data.minX);
    expect(charts[0].data.maxX, charts[1].data.maxX);
    expect(
      charts[0].data.extraLinesData.verticalLines.single.x,
      charts[1].data.extraLinesData.verticalLines.single.x,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('comparisonValue-Chest')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Chest: no data'), findsOneWidget);
    expect(find.text('Hips: no data'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('bodyLegend-chest')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('bodyLegend-chest')));
    await tester.tap(find.byKey(const ValueKey('bodyLegend-chest')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<LineChart>(find.byType(LineChart))
          .last
          .data
          .lineBarsData,
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical drags through a plot scroll the containing page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(414, 896));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              ProgressChart(
                window: ProgressWindow(days: 30, now: DateTime(2026, 10, 15)),
                unit: 'cm',
                isRu: false,
                lines: [
                  ProgressLine(
                    label: 'Chest',
                    color: Colors.green,
                    points: [
                      ProgressPoint('a', DateTime(2026, 10, 1), 94),
                      ProgressPoint('b', DateTime(2026, 10, 15), 92.5),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 1000),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragFrom(
      tester.getCenter(find.byType(LineChart)),
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('touch selects a real intraday point and reports its date', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(414, 896));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final window = ProgressWindow(days: 7, now: DateTime(2026, 10, 15));
    final points = [
      ProgressPoint('morning', DateTime(2026, 10, 12, 8), 92.5),
      ProgressPoint('evening', DateTime(2026, 10, 12, 20), 93),
    ];
    DateTime? selected;
    await tester.pumpWidget(
      app(
        ProgressChart(
          window: window,
          unit: 'cm',
          isRu: false,
          lines: [
            ProgressLine(label: 'Chest', color: Colors.green, points: points),
          ],
          onSelectDay: (date) => selected = date,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots, hasLength(2));
    // Touch near the first point in the actual plot rectangle.
    final rect = tester.getRect(find.byType(LineChart));
    final scale = ProgressScale.forValues(
      points.map((p) => p.value),
      minimumSpan: 8,
    );
    final x =
        rect.left +
        (window.x(points.first.date) - chart.data.minX) /
            (chart.data.maxX - chart.data.minX) *
            (rect.width -
                chart.data.titlesData.rightTitles.sideTitles.reservedSize);
    final y =
        rect.top +
        (scale.maxY - 92.5) / (scale.maxY - scale.minY) * (rect.height - 30);
    await tester.tapAt(Offset(x, y));
    await tester.pumpAndSettle();
    expect(selected, points.first.date);
    expect(find.textContaining('08:00:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
