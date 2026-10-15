import 'package:flutter/material.dart';
import 'package:flutter_app/screens/weight_screen.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: false),
    child: Scaffold(
      backgroundColor: AppColors.wellness.page,
      body: Center(child: child),
    ),
  ),
);

void main() {
  test('period_graph_motion_progress_test', () {
    var previousLength = -1.0;
    for (final progress in const [0.0, .25, .5, .75, 1.0]) {
      final length = debugBalancePeriodGraphDrawLength(progress);
      expect(length, greaterThan(previousLength));
      previousLength = length;
    }
  });

  test('goal_flag_motion_progress_test', () {
    (double, double, double, double)? previous;
    for (final progress in const [0.0, .25, .5, .75]) {
      final geometry = debugBalanceGoalFlagGeometry(progress);
      if (previous != null) expect(geometry, isNot(previous));
      previous = geometry;
    }
  });

  for (final evidence in [
    (
      'graph',
      BalanceSummaryMotionKind.graph,
      const [0.0, .15, .30, .50, .70, .88, 1.0],
    ),
    (
      'flag',
      BalanceSummaryMotionKind.flag,
      const [0.0, .125, .25, .375, .50, .625, .75, .875],
    ),
    (
      'clock',
      BalanceSummaryMotionKind.clock,
      const [0.0, .15, .30, .45, .60, .75, .90, 1.0],
    ),
  ]) {
    testWidgets('${evidence.$1} motion visual evidence', (tester) async {
      await tester.binding.setSurfaceSize(
        Size(evidence.$3.length == 8 ? 660 : 580, 72),
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = ValueKey('motion-${evidence.$1}');
      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: AppColors.wellness.page,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final progress in evidence.$3)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: BalanceSummaryMotionIcon(
                          kind: evidence.$2,
                          color: AppColors.wellness.accent,
                          progressOverride: progress,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/motion_${evidence.$1}_sequence.png'),
      );
    });
  }

  test('clock_motion_regression_test', () {
    final phases = [
      debugBalanceClockAngles(0),
      debugBalanceClockAngles(.25),
      debugBalanceClockAngles(.5),
    ];
    expect(phases.toSet(), hasLength(3));
    expect(phases[1].$1, isNot(phases[0].$1));
    expect(phases[2].$2, isNot(phases[1].$2));
    expect(phases[2].$3, isNot(phases[1].$3));

    final start = debugBalanceClockAngles(0);
    final afterEightSeconds = debugBalanceClockAngles(8 / (12 * 60 * 60));
    expect(
      (afterEightSeconds.$1 - start.$1) * 180 / 3.141592653589793,
      closeTo(48, .001),
    );
    expect(
      (afterEightSeconds.$2 - start.$2) * 180 / 3.141592653589793,
      closeTo(.8, .001),
    );
    expect(
      (afterEightSeconds.$3 - start.$3) * 180 / 3.141592653589793,
      closeTo(1 / 15, .001),
    );
  });

  testWidgets('graph draws once per activation epoch', (tester) async {
    int frame() {
      final paint = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'summaryMotionFrame-',
              ),
        ),
      );
      return int.parse((paint.key! as ValueKey<String>).value.split('-').last);
    }

    Widget icon(bool active, int epoch) => _app(
      BalanceSummaryMotionIcon(
        key: const ValueKey('activation-graph'),
        kind: BalanceSummaryMotionKind.graph,
        color: AppColors.wellness.accent,
        isActive: active,
        activationEpoch: epoch,
      ),
    );

    await tester.pumpWidget(icon(false, 0));
    await tester.pump();
    expect(frame(), 0);

    await tester.pumpWidget(icon(true, 1));
    await tester.pump();
    expect(frame(), 0);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(frame(), 1000000);

    await tester.pumpWidget(icon(true, 1));
    await tester.pump(const Duration(seconds: 8));
    expect(frame(), 1000000);

    await tester.pumpWidget(icon(false, 1));
    await tester.pump();
    expect(frame(), 0);

    await tester.pumpWidget(icon(true, 2));
    await tester.pump();
    expect(frame(), 0);
  });

  testWidgets('flag eight-phase overlay evidence', (tester) async {
    const key = ValueKey('flag-eight-phase-overlay');
    await tester.binding.setSurfaceSize(const Size(86, 64));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: AppColors.wellness.page,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  for (var phase = 0; phase < 8; phase++)
                    BalanceSummaryMotionIcon(
                      kind: BalanceSummaryMotionKind.flag,
                      color: AppColors.wellness.accent.withValues(alpha: .24),
                      progressOverride: phase / 8,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/motion_flag_overlay.png'),
    );
  });

  for (final runtimeCase in [
    (BalanceSummaryMotionKind.graph, const Duration(milliseconds: 420)),
    (BalanceSummaryMotionKind.flag, const Duration(milliseconds: 420)),
    (BalanceSummaryMotionKind.clock, const Duration(milliseconds: 420)),
  ]) {
    testWidgets('${runtimeCase.$1.name}_runtime_progression_test', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          BalanceSummaryMotionIcon(
            kind: runtimeCase.$1,
            color: AppColors.wellness.accent,
          ),
        ),
      );
      await tester.pump();
      final first = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'summaryMotionFrame-',
            ),
      );
      expect(first, findsOneWidget);
      final firstKey = tester.widget<CustomPaint>(first).key;
      await tester.pump(runtimeCase.$2);
      final second = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'summaryMotionFrame-',
            ),
      );
      expect(second, findsOneWidget);
      expect(tester.widget<CustomPaint>(second).key, isNot(firstKey));
    });
  }

  testWidgets('summary motion evidence', (tester) async {
    await tester.binding.setSurfaceSize(const Size(660, 130));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        RepaintBoundary(
          key: const ValueKey('summary-motion-sequence'),
          child: ColoredBox(
            color: AppColors.wellness.page,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final progress in const [
                        0.0,
                        .16,
                        .32,
                        .48,
                        .64,
                        .80,
                        1.0,
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: BalanceSummaryMotionIcon(
                            kind: BalanceSummaryMotionKind.graph,
                            color: AppColors.wellness.accent,
                            progressOverride: progress,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final progress in const [
                        0.0,
                        .14,
                        .28,
                        .42,
                        .56,
                        .70,
                        .84,
                        .98,
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: BalanceSummaryMotionIcon(
                            kind: BalanceSummaryMotionKind.flag,
                            color: AppColors.wellness.accent2,
                            progressOverride: progress,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(const ValueKey('summary-motion-sequence')),
      matchesGoldenFile('goldens/motion_summary_sequence.png'),
    );
  });
}
