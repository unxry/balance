import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/premium_motion.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _sequence({
  required AppColors colors,
  required BalanceActivityAnimationMode mode,
  required double size,
  required int frames,
  required Key key,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Scaffold(
    backgroundColor: colors.page,
    body: Center(
      child: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: colors.page,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < frames; index++)
                  BalanceActivityCharacter(
                    colors: colors,
                    size: size,
                    travelWidth: size + 10,
                    animationMode: mode,
                    previewProgress: index / frames,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

class _WristTrajectoryPainter extends CustomPainter {
  const _WristTrajectoryPainter(this.points, this.color);

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(points.first.dx, points.first.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _WristTrajectoryPainter oldDelegate) => false;
}

void main() {
  setUpAll(() async {
    await preloadBalanceActivitySprites();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
  });

  for (final evidence in [
    (
      'walk_cream',
      AppColors.wellness,
      BalanceActivityAnimationMode.walk,
      82.0,
      16,
    ),
    (
      'walk_dark',
      AppColors.darkTheme,
      BalanceActivityAnimationMode.walk,
      82.0,
      16,
    ),
    (
      'run_cream',
      AppColors.wellness,
      BalanceActivityAnimationMode.run,
      82.0,
      16,
    ),
    (
      'run_dark',
      AppColors.darkTheme,
      BalanceActivityAnimationMode.run,
      82.0,
      16,
    ),
    (
      'dashboard_walk',
      AppColors.wellness,
      BalanceActivityAnimationMode.walk,
      40.0,
      16,
    ),
    (
      'dashboard_run',
      AppColors.darkTheme,
      BalanceActivityAnimationMode.run,
      40.0,
      16,
    ),
  ]) {
    testWidgets('activity sprite ${evidence.$1} visual evidence', (
      tester,
    ) async {
      final width = (evidence.$4 + 10) * evidence.$5 + 24;
      await tester.binding.setSurfaceSize(Size(width, evidence.$4 + 24));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = ValueKey(evidence.$1);
      await tester.pumpWidget(
        _sequence(
          colors: evidence.$2,
          mode: evidence.$3,
          size: evidence.$4,
          frames: evidence.$5,
          key: key,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/activity_sprite_${evidence.$1}.png'),
      );
    });
  }

  testWidgets('activity sprite transition visual evidence', (tester) async {
    await tester.binding.setSurfaceSize(const Size(580, 110));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('activity-transition');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.wellness.page,
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: AppColors.wellness.page,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < 4; index++)
                      Image.asset(
                        'assets/character/transition_idle_walk_${index.toString().padLeft(2, '0')}.png',
                        width: 58,
                        height: 78,
                      ),
                    for (var index = 0; index < 5; index++)
                      Image.asset(
                        'assets/character/transition_walk_run_${index.toString().padLeft(2, '0')}.png',
                        width: 58,
                        height: 78,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/activity_sprite_transition.png'),
    );
  });

  testWidgets('activity master scale and anchor overlay evidence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(180, 140));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('activity-scale-anchor-overlay');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.wellness.page,
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 140,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 8,
                      right: 8,
                      top: 20,
                      child: Container(
                        height: 1,
                        color: AppColors.wellness.line,
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      top: 95,
                      child: Container(
                        height: 1,
                        color: AppColors.wellness.line,
                      ),
                    ),
                    Opacity(
                      opacity: .42,
                      child: BalanceActivityCharacter(
                        colors: AppColors.wellness,
                        size: 88,
                        travelWidth: 100,
                        previewPose: BalanceActivityPose.idle,
                      ),
                    ),
                    for (var index = 0; index < 16; index++)
                      Opacity(
                        opacity: .07,
                        child: BalanceActivityCharacter(
                          colors: AppColors.wellness,
                          size: 88,
                          travelWidth: 100,
                          animationMode: BalanceActivityAnimationMode.walk,
                          previewProgress: index / 16,
                        ),
                      ),
                    for (var index = 0; index < 16; index++)
                      Opacity(
                        opacity: .045,
                        child: BalanceActivityCharacter(
                          colors: AppColors.wellness,
                          size: 88,
                          travelWidth: 100,
                          animationMode: BalanceActivityAnimationMode.run,
                          previewProgress: index / 16,
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
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/activity_scale_anchor_overlay.png'),
    );
  });

  testWidgets('activity W1 W5 opposite overlay evidence', (tester) async {
    await tester.binding.setSurfaceSize(const Size(180, 150));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('activity-w1-w5-overlay');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.wellness.page,
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 140,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    Opacity(
                      opacity: .55,
                      child: BalanceActivityCharacter(
                        colors: AppColors.wellness,
                        size: 106,
                        travelWidth: 120,
                        animationMode: BalanceActivityAnimationMode.walk,
                        previewProgress: 0,
                      ),
                    ),
                    Opacity(
                      opacity: .55,
                      child: BalanceActivityCharacter(
                        colors: AppColors.wellness,
                        size: 106,
                        travelWidth: 120,
                        animationMode: BalanceActivityAnimationMode.walk,
                        previewProgress: .5,
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
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/activity_walk_w1_w5_overlay.png'),
    );
  });

  testWidgets('activity wrist and foot trajectory evidence', (tester) async {
    await tester.binding.setSurfaceSize(const Size(300, 150));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('activity-wrist-trajectories');
    const walk = <Offset>[
      Offset(35, 75),
      Offset(37, 73.5),
      Offset(39, 72),
      Offset(44.5, 68),
      Offset(50, 64),
      Offset(59, 60.5),
      Offset(68, 57),
      Offset(79.5, 55),
      Offset(91, 53),
      Offset(88.5, 55.5),
      Offset(86, 58),
      Offset(75.5, 62.5),
      Offset(65, 67),
      Offset(55, 70),
      Offset(45, 73),
      Offset(40, 74),
    ];
    const run = <Offset>[
      Offset(30, 75),
      Offset(36, 69),
      Offset(52, 58),
      Offset(82, 49),
      Offset(98, 47),
      Offset(89, 53),
      Offset(63, 62),
      Offset(42, 70),
    ];
    const walkFoot = <Offset>[
      Offset(92, 97),
      Offset(86, 98),
      Offset(78, 99),
      Offset(68, 99),
      Offset(58, 98),
      Offset(48, 95),
      Offset(43, 89),
      Offset(50, 84),
      Offset(60, 80),
      Offset(72, 82),
      Offset(84, 86),
      Offset(94, 90),
      Offset(98, 94),
      Offset(96, 96),
      Offset(94, 97),
      Offset(92, 97),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.wellness.page,
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final evidence in [
                    (BalanceActivityAnimationMode.walk, walk),
                    (BalanceActivityAnimationMode.run, run),
                  ])
                    SizedBox(
                      width: 130,
                      height: 120,
                      child: Stack(
                        children: [
                          for (
                            var frame = 0;
                            frame < evidence.$2.length;
                            frame++
                          )
                            Opacity(
                              opacity: .075,
                              child: BalanceActivityCharacter(
                                colors: AppColors.wellness,
                                size: 108,
                                travelWidth: 120,
                                animationMode: evidence.$1,
                                previewProgress: frame / evidence.$2.length,
                              ),
                            ),
                          CustomPaint(
                            size: const Size(120, 108),
                            painter: _WristTrajectoryPainter(
                              evidence.$2,
                              AppColors.wellness.accent,
                            ),
                          ),
                          CustomPaint(
                            size: const Size(120, 108),
                            painter: _WristTrajectoryPainter([
                              ...evidence.$2.skip(evidence.$2.length ~/ 2),
                              ...evidence.$2.take(evidence.$2.length ~/ 2),
                            ], Colors.deepOrange),
                          ),
                          if (evidence.$1 == BalanceActivityAnimationMode.walk)
                            const CustomPaint(
                              size: Size(120, 108),
                              painter: _WristTrajectoryPainter(
                                walkFoot,
                                Colors.blueGrey,
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
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/activity_walk_trajectories.png'),
    );
  });

  testWidgets('walk eight-key bilateral labels', (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('walk-eight-key-bilateral');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.wellness.page,
          body: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: AppColors.wellness.page,
              child: Row(
                children: [
                  for (final frame in [0, 2, 4, 6, 8, 10, 12, 14])
                    SizedBox(
                      width: 120,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          BalanceActivityCharacter(
                            colors: AppColors.wellness,
                            size: 112,
                            travelWidth: 116,
                            animationMode: BalanceActivityAnimationMode.walk,
                            previewProgress: frame / 16,
                          ),
                          Positioned(
                            top: 4,
                            child: Text(
                              'W${frame + 1}',
                              style: const TextStyle(fontFamily: 'Inter'),
                            ),
                          ),
                          const Positioned(
                            left: 2,
                            top: 34,
                            child: Text(
                              'L arm',
                              style: TextStyle(fontFamily: 'Inter'),
                            ),
                          ),
                          const Positioned(
                            right: 2,
                            top: 34,
                            child: Text(
                              'R arm',
                              style: TextStyle(fontFamily: 'Inter'),
                            ),
                          ),
                          const Positioned(
                            left: 2,
                            bottom: 4,
                            child: Text(
                              'L leg',
                              style: TextStyle(fontFamily: 'Inter'),
                            ),
                          ),
                          const Positioned(
                            right: 2,
                            bottom: 4,
                            child: Text(
                              'R leg',
                              style: TextStyle(fontFamily: 'Inter'),
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
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/activity_walk_8_key_bilateral_annotated.png'),
    );
  });

  testWidgets('run bilateral contact flight labels', (tester) async {
    await tester.binding.setSurfaceSize(const Size(560, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('run-bilateral-contact-flight');
    const panels = [
      (0, 'LEFT contact', 'R1'),
      (6, 'LEFT flight', 'R4'),
      (8, 'RIGHT contact', 'R5'),
      (14, 'RIGHT flight', 'R8'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.wellness.page,
          body: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: AppColors.wellness.page,
              child: Row(
                children: [
                  for (final panel in panels)
                    SizedBox(
                      width: 140,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          BalanceActivityCharacter(
                            colors: AppColors.wellness,
                            size: 118,
                            travelWidth: 132,
                            animationMode: BalanceActivityAnimationMode.run,
                            previewProgress: panel.$1 / 16,
                          ),
                          Positioned(
                            top: 4,
                            child: Text(
                              panel.$2,
                              style: const TextStyle(fontFamily: 'Inter'),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            child: Text(
                              panel.$3,
                              style: const TextStyle(fontFamily: 'Inter'),
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
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/activity_run_4_panel_bilateral_annotated.png'),
    );
  });

  testWidgets('run R1 R5 unlabeled contact comparison', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 260));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('run-r1-r5-unlabeled');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.wellness.page,
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: AppColors.wellness.page,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final frame in [0, 8])
                      Image.asset(
                        'assets/character/run_${frame.toString().padLeft(2, '0')}.png',
                        width: 180,
                        height: 240,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/activity_run_r1_r5_unlabeled.png'),
    );
  });

  testWidgets('run adjacent seam runtime frames', (tester) async {
    await tester.binding.setSurfaceSize(const Size(780, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('run-adjacent-seam-runtime');
    const frames = [
      (6, 'R4'),
      (7, 'R4.5'),
      (8, 'R5'),
      (14, 'R8'),
      (15, 'R8.5'),
      (0, 'R1'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.wellness.page,
          body: RepaintBoundary(
            key: key,
            child: Row(
              children: [
                for (final entry in frames)
                  SizedBox(
                    width: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        BalanceActivityCharacter(
                          colors: AppColors.wellness,
                          size: 116,
                          travelWidth: 126,
                          animationMode: BalanceActivityAnimationMode.run,
                          previewProgress: entry.$1 / 16,
                        ),
                        Positioned(
                          bottom: 4,
                          child: Text(
                            entry.$2,
                            style: const TextStyle(fontFamily: 'Inter'),
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
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/activity_run_runtime_seams_adjacent.png'),
    );
  });
}
