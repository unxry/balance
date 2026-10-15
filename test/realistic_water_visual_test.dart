import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/premium_motion.dart';
import 'package:flutter_app/widgets/realistic_water.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {Size size = const Size(1012, 196)}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(fontFamily: 'Inter'),
  home: MediaQuery(
    data: MediaQueryData(size: size, disableAnimations: false),
    child: Scaffold(
      backgroundColor: AppColors.wellness.page,
      body: Center(child: child),
    ),
  ),
);

Widget _card({
  Key? waterKey,
  Key? counterKey,
  required AppColors colors,
  required double value,
  required double phase,
  required String label,
  bool animatedCounter = false,
  bool debugBubbleLabels = false,
  bool labelAtTopRight = false,
  ui.FragmentShader? materialPreviewShader,
  bool forcePainterMaterial = false,
}) => Container(
  width: 148,
  height: 168,
  clipBehavior: Clip.antiAlias,
  decoration: BoxDecoration(
    color: colors.card,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: colors.line),
  ),
  child: Stack(
    children: [
      Positioned.fill(
        child: RealisticWaterLayer(
          key: waterKey,
          valueMl: value,
          goalMl: 2500,
          colors: colors,
          previewElapsedSeconds: phase * 108,
          debugBubbleLabels: debugBubbleLabels,
          materialPreviewShader: materialPreviewShader,
          forcePainterMaterial: forcePainterMaterial,
        ),
      ),
      Positioned(
        left: 14,
        top: 14,
        child: Text('ВОДА', style: TextStyle(fontSize: 10, color: colors.fg)),
      ),
      Positioned(
        left: labelAtTopRight ? null : 14,
        right: labelAtTopRight ? 14 : null,
        top: labelAtTopRight ? 14 : null,
        bottom: labelAtTopRight ? null : 17,
        child: animatedCounter
            ? BalanceAnimatedNumber(
                key: counterKey,
                value: value,
                duration: const Duration(milliseconds: 740),
                formatter: (value) => '${value.round()} / 2500 мл',
                style: TextStyle(fontSize: 13, color: colors.fg),
              )
            : Text(label, style: TextStyle(fontSize: 13, color: colors.fg)),
      ),
      if (animatedCounter)
        Positioned(
          right: 14,
          top: 14,
          child: SizedBox(
            width: 88,
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 7, height: 1.15, color: colors.muted),
            ),
          ),
        ),
    ],
  ),
);

Widget _sequence({
  required Key boundaryKey,
  required List<double> values,
  required List<String> labels,
  required String keyPrefix,
}) => RepaintBoundary(
  key: boundaryKey,
  child: ColoredBox(
    color: AppColors.wellness.page,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            _card(
              waterKey: ValueKey('$keyPrefix-$i'),
              counterKey: ValueKey('$keyPrefix-counter-$i'),
              colors: AppColors.wellness,
              value: values[i],
              phase: .32,
              label: labels[i],
              animatedCounter: true,
            ),
            if (i != values.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final entry in const {
      'Inter': 'assets/fonts/Inter-Variable.ttf',
      'Fraunces': 'assets/fonts/Fraunces-Variable.ttf',
      'JetBrainsMono': 'assets/fonts/JetBrainsMono-Variable.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot == null) {
      throw StateError('FLUTTER_ROOT is required for golden icon rendering.');
    }
    final materialIcons = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    await (FontLoader('MaterialIcons')..addFont(
          Future<ByteData>.value(
            ByteData.sublistView(materialIcons.readAsBytesSync()),
          ),
        ))
        .load();
  });

  test('water chamber fill remains proportional', () {
    expect(debugWaterChamberFill(0, 2500), 0);
    expect(debugWaterChamberFill(250, 2500), closeTo(.096, .000001));
    expect(debugWaterChamberFill(1250, 2500), closeTo(.48, .000001));
    expect(debugWaterChamberFill(2500, 2500), closeTo(.96, .000001));
  });

  test('surface and optical velocity stay continuous at former seams', () {
    const epsilon = .001;
    for (final boundary in const [1.0, 6.0, 7.2, 10.8, 18.0, 108.0]) {
      for (final x in const [.1, .35, .6, .9]) {
        final before = debugWaterSurfaceSample(x, boundary - epsilon);
        final at = debugWaterSurfaceSample(x, boundary);
        final after = debugWaterSurfaceSample(x, boundary + epsilon);
        expect((at - before).abs(), lessThan(.003));
        expect((after - at).abs(), lessThan(.003));
        final velocityBefore = (at - before) / epsilon;
        final velocityAfter = (after - at) / epsilon;
        expect((velocityAfter - velocityBefore).abs(), lessThan(.01));
      }
      for (var index = 0; index < 4; index++) {
        final causticBefore = debugWaterCausticSample(
          index,
          boundary - epsilon,
        );
        final causticAt = debugWaterCausticSample(index, boundary);
        final causticAfter = debugWaterCausticSample(index, boundary + epsilon);
        expect((causticAt.x - causticBefore.x).abs(), lessThan(.001));
        expect((causticAfter.x - causticAt.x).abs(), lessThan(.001));
        expect((causticAt.morph - causticBefore.morph).abs(), lessThan(.001));
        expect((causticAfter.morph - causticAt.morph).abs(), lessThan(.001));

        final refractionBefore = debugWaterRefractionSample(
          index,
          boundary - epsilon,
        );
        final refractionAt = debugWaterRefractionSample(index, boundary);
        final refractionAfter = debugWaterRefractionSample(
          index,
          boundary + epsilon,
        );
        expect((refractionAt.x - refractionBefore.x).abs(), lessThan(.001));
        expect((refractionAfter.x - refractionAt.x).abs(), lessThan(.001));
      }
    }
  });

  test('ten-second 60 fps idle motion has no adjacent-frame spikes', () {
    List<double> signal(double seconds) {
      final values = <double>[...debugWaterSurfaceProfile(seconds)];
      for (var index = 0; index < 3; index++) {
        final caustic = debugWaterCausticSample(index, seconds);
        final refraction = debugWaterRefractionSample(index, seconds);
        values.addAll([
          caustic.x,
          caustic.morph,
          refraction.x,
          refraction.morph,
        ]);
      }
      return values;
    }

    final energies = <double>[];
    var previous = signal(0);
    for (var frame = 1; frame <= 600; frame++) {
      final current = signal(frame / 60);
      var energy = 0.0;
      for (var index = 0; index < current.length; index++) {
        energy += (current[index] - previous[index]).abs();
      }
      energies.add(energy);
      previous = current;
    }
    final sorted = [...energies]..sort();
    final median = sorted[sorted.length ~/ 2];
    expect(energies.reduce((a, b) => a > b ? a : b), lessThan(median * 2));
    for (var frame = 0; frame <= 600; frame++) {
      final profile = debugWaterSurfaceProfile(frame / 60);
      final mean = profile.reduce((a, b) => a + b) / profile.length;
      expect(mean.abs(), lessThan(1e-12));
    }
  });

  test('visual clock drops excess dt without catch-up', () {
    final afterGap = debugAdvanceWaterMotionTime(3, .2);
    expect(afterGap, closeTo(3.05, 1e-12));
    expect(
      debugAdvanceWaterMotionTime(afterGap, 1 / 60),
      closeTo(afterGap + 1 / 60, 1e-12),
    );
  });

  test('twenty-second dt-normalized water ROI energy has no spike', () {
    final energies = <String, List<double>>{};
    var previous = debugWaterRoiMotionSignals(0);
    for (var frame = 1; frame <= 400; frame++) {
      final seconds = frame / 20;
      final current = debugWaterRoiMotionSignals(seconds);
      for (final entry in current.entries) {
        final before = previous[entry.key]!;
        var energy = 0.0;
        for (var index = 0; index < entry.value.length; index++) {
          energy += (entry.value[index] - before[index]).abs() / .05;
        }
        energies.putIfAbsent(entry.key, () => []).add(energy);
      }
      previous = current;
    }
    for (final entry in energies.entries) {
      final sorted = [...entry.value]..sort();
      final median = sorted[sorted.length ~/ 2];
      expect(
        sorted.last,
        lessThan(median * 3),
        reason: '${entry.key} contains an isolated normalized-energy spike',
      );
    }
  });

  test('bubble respawn happens only while fully invisible', () {
    const timings = [
      (spawn: .4, lifetime: 6.8, delay: 1.1),
      (spawn: .75, lifetime: 7.0, delay: 1.35),
      (spawn: 1.1, lifetime: 7.2, delay: .9),
      (spawn: 1.6, lifetime: 5.4, delay: 1.2),
      (spawn: 5.1, lifetime: 7.2, delay: 1.45),
      (spawn: 3.3, lifetime: 4.6, delay: 1.05),
      (spawn: 2.15, lifetime: 6.25, delay: 1.3),
      (spawn: 4.15, lifetime: 5.85, delay: 1.15),
      (spawn: 2.85, lifetime: 6.4, delay: 1.2),
      (spawn: 3.75, lifetime: 5.1, delay: 1.4),
      (spawn: 1.95, lifetime: 5.7, delay: .8),
      (spawn: 4.65, lifetime: 6.9, delay: .9),
    ];
    const epsilon = .001;
    for (final timing in timings) {
      final cycle = timing.lifetime + timing.delay;
      for (var repetition = 1; repetition <= 4; repetition++) {
        final wrap = cycle * repetition - timing.spawn;
        final before = debugWaterBubbleLifecycle(
          elapsedSeconds: wrap - epsilon,
          spawnTime: timing.spawn,
          lifetime: timing.lifetime,
          invisibleDelay: timing.delay,
        );
        final after = debugWaterBubbleLifecycle(
          elapsedSeconds: wrap + epsilon,
          spawnTime: timing.spawn,
          lifetime: timing.lifetime,
          invisibleDelay: timing.delay,
        );
        expect(before.opacity, lessThan(.01));
        expect(after.opacity, lessThan(.01));
      }
    }
  });

  testWidgets('water level retargets from its current visual position', (
    tester,
  ) async {
    Widget layer(double value) => _app(
      SizedBox(
        width: 430,
        height: 330,
        child: RealisticWaterLayer(
          valueMl: value,
          goalMl: 2500,
          colors: AppColors.wellness,
        ),
      ),
      size: const Size(430, 330),
    );

    double visibleFill() {
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      return ((paint.painter as dynamic).fill as num).toDouble();
    }

    await tester.pumpWidget(layer(0));
    await tester.pumpWidget(layer(750));
    await tester.pump(const Duration(milliseconds: 700));
    final beforeRetarget = visibleFill();
    expect(
      beforeRetarget,
      inExclusiveRange(0, debugWaterChamberFill(750, 2500)),
    );

    await tester.pumpWidget(layer(500));
    final atRetarget = visibleFill();
    expect(atRetarget, closeTo(beforeRetarget, .000001));
    await tester.pump(const Duration(milliseconds: 16));
    expect((visibleFill() - atRetarget).abs(), lessThan(.004));
    await tester.pump(const Duration(milliseconds: 1900));
    expect(visibleFill(), closeTo(debugWaterChamberFill(500, 2500), .000001));
  });

  testWidgets('proportional water chamber levels visual evidence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1812, 196));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('water-level-evidence');
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
                  for (final ml in const [
                    0,
                    250,
                    500,
                    750,
                    1000,
                    1250,
                    1500,
                    1750,
                    2000,
                    2250,
                    2500,
                  ]) ...[
                    _card(
                      colors: AppColors.wellness,
                      value: ml.toDouble(),
                      phase: .32,
                      label: '$ml / 2500 мл',
                    ),
                    if (ml != 2500) const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
        size: const Size(1812, 196),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/water_level_states.png'),
    );
  });

  testWidgets('water idle phases at 150 and 2500 visual evidence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1312, 392));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('water-idle-evidence');
    await tester.pumpWidget(
      _app(
        RepaintBoundary(
          key: key,
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
                      for (var i = 0; i < 8; i++) ...[
                        _card(
                          colors: AppColors.wellness,
                          value: 150,
                          phase: (i * 2) / 108,
                          label: '150 мл · ${i * 2}s',
                        ),
                        if (i != 7) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 8; i++) ...[
                        _card(
                          colors: AppColors.wellness,
                          value: 2500,
                          phase: (i * 2) / 108,
                          label: '2500 мл · ${i * 2}s',
                        ),
                        if (i != 7) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        size: const Size(1312, 392),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/water_idle_low_full_phases.png'),
    );
  });

  testWidgets('water seam boundary frames remain continuous', (tester) async {
    const times = [5.9, 6.0, 6.1, 7.1, 7.2, 7.3, 10.7, 10.8, 10.9];
    const size = Size(1492, 196);
    const key = ValueKey('water-seam-boundary-evidence');
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
                  for (var i = 0; i < times.length; i++) ...[
                    _card(
                      colors: AppColors.wellness,
                      value: 1250,
                      phase: times[i] / 108,
                      label: 't=${times[i].toStringAsFixed(1)}s',
                    ),
                    if (i != times.length - 1) const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
        size: size,
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/water_seam_boundary_frames.png'),
    );
  });

  testWidgets('water bubble trajectories visual evidence', (tester) async {
    const size = Size(692, 196);
    const key = ValueKey('water-bubble-evidence');
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
                  for (var second = 0; second < 4; second++) ...[
                    _card(
                      colors: AppColors.wellness,
                      value: 2500,
                      phase: (second * 2) / 108,
                      label: 't=${second * 2}s',
                      debugBubbleLabels: true,
                      labelAtTopRight: true,
                    ),
                    if (second != 3) const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
        size: size,
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/water_bubble_trajectories.png'),
    );
  });

  testWidgets('water Wellness and Dark theme visual evidence', (tester) async {
    const size = Size(692, 196);
    const key = ValueKey('water-theme-evidence');
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
                  _card(
                    colors: AppColors.wellness,
                    value: 250,
                    phase: 3 / 108,
                    label: 'Wellness · 250',
                  ),
                  const SizedBox(width: 12),
                  _card(
                    colors: AppColors.wellness,
                    value: 2500,
                    phase: 3 / 108,
                    label: 'Wellness · 2500',
                  ),
                  const SizedBox(width: 12),
                  _card(
                    colors: AppColors.darkTheme,
                    value: 250,
                    phase: 3 / 108,
                    label: 'Dark · 250',
                  ),
                  const SizedBox(width: 12),
                  _card(
                    colors: AppColors.darkTheme,
                    value: 2500,
                    phase: 3 / 108,
                    label: 'Dark · 2500',
                  ),
                ],
              ),
            ),
          ),
        ),
        size: size,
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/water_theme_states.png'),
    );
  });

  testWidgets('water add sequence visual evidence', (tester) async {
    const size = Size(812, 196);
    const key = ValueKey('water-add-evidence');
    const labels = [
      'START',
      '0→250 · TRAVEL',
      '250 · SETTLED',
      '250→500 · TRAVEL',
      '500 · SETTLED',
    ];
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(
        _sequence(
          boundaryKey: key,
          values: const [0, 0, 250, 250, 500],
          labels: labels,
          keyPrefix: 'add',
        ),
        size: size,
      ),
    );
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pumpWidget(
      _app(
        _sequence(
          boundaryKey: key,
          values: const [0, 250, 250, 500, 500],
          labels: labels,
          keyPrefix: 'add',
        ),
        size: size,
      ),
    );
    await tester.pump(const Duration(milliseconds: 760));

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/water_add_sequence.png'),
    );
  });

  testWidgets('water decrease sequence visual evidence', (tester) async {
    const size = Size(1132, 196);
    const key = ValueKey('water-decrease-evidence');
    const labels = [
      '750 · START',
      '750→500 · TRAVEL',
      '500 · SETTLED',
      '500→250 · TRAVEL',
      '250 · SETTLED',
      '250→150 · TRAVEL',
      '150 · SETTLED',
    ];
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(
        _sequence(
          boundaryKey: key,
          values: const [750, 750, 500, 500, 250, 250, 150],
          labels: labels,
          keyPrefix: 'decrease',
        ),
        size: size,
      ),
    );
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pumpWidget(
      _app(
        _sequence(
          boundaryKey: key,
          values: const [750, 500, 500, 250, 250, 150, 150],
          labels: labels,
          keyPrefix: 'decrease',
        ),
        size: size,
      ),
    );
    await tester.pump(const Duration(milliseconds: 760));

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/water_decrease_sequence.png'),
    );
  });

  testWidgets('water painter and hybrid shader comparison', (tester) async {
    const size = Size(320, 196);
    const key = ValueKey('water-renderer-comparison');
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/water_material.frag',
    );
    final shader = program.fragmentShader()
      ..setFloat(0, 148)
      ..setFloat(1, 168)
      ..setFloat(2, 4)
      ..setFloat(3, 1 - .62 * .96)
      ..setFloat(4, 0);
    addTearDown(shader.dispose);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(
        RepaintBoundary(
          key: key,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _card(
                colors: AppColors.wellness,
                value: 2500,
                phase: 4 / 108,
                label: 'PAINTER',
                forcePainterMaterial: true,
              ),
              const SizedBox(width: 12),
              _card(
                colors: AppColors.wellness,
                value: 2500,
                phase: 4 / 108,
                label: 'HYBRID',
                materialPreviewShader: shader,
              ),
            ],
          ),
        ),
        size: size,
      ),
    );

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/water_painter_shader_comparison.png'),
    );
  });
}
