import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/premium_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await inter.load();
  });

  testWidgets('advice sparkles stay transparent across palettes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 220));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFB8B7B2),
          body: Center(
            child: RepaintBoundary(
              key: const ValueKey('sparklePaletteGolden'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sparklePanel(AppColors.wellness, 'WELLNESS'),
                  const SizedBox(width: 12),
                  _sparklePanel(AppColors.systemLight, 'SYSTEM'),
                  const SizedBox(width: 12),
                  _sparklePanel(AppColors.darkTheme, 'DARK'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 720));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('sparklePaletteGolden')),
      matchesGoldenFile('goldens/advice_sparkle_palettes.png'),
    );
  });

  for (final palette in [
    ('wellness', AppColors.wellness),
    ('light', AppColors.systemLight),
    ('dark', AppColors.darkTheme),
  ]) {
    for (final phase in [
      ('quiet', const Duration(milliseconds: 350)),
      ('bright', const Duration(milliseconds: 2300)),
    ]) {
      testWidgets('advice ${palette.$1} ${phase.$1} visual evidence', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(220, 190));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: palette.$2.page,
              body: Center(
                child: RepaintBoundary(
                  key: ValueKey('advice-${palette.$1}-${phase.$1}'),
                  child: _sparklePanel(palette.$2, 'СОВЕТ НА СЕГОДНЯ'),
                ),
              ),
            ),
          ),
        );
        await tester.pump(phase.$2);
        await expectLater(
          find.byKey(ValueKey('advice-${palette.$1}-${phase.$1}')),
          matchesGoldenFile(
            'goldens/advice_${palette.$1}_${phase.$1}_phase.png',
          ),
        );
      });
    }
  }

  testWidgets('advice twinkle sequence visual evidence', (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 140));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('advice-twinkle-sequence');
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
                  for (final progress in const [
                    0.0,
                    .0013,
                    .0026,
                    .0039,
                    .0052,
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _sparklePanel(
                        AppColors.wellness,
                        '',
                        width: 128,
                        height: 108,
                        previewProgress: progress,
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
      matchesGoldenFile('goldens/advice_twinkle_sequence.png'),
    );
  });
}

Widget _sparklePanel(
  AppColors colors,
  String label, {
  double width = 172,
  double height = 144,
  double? previewProgress,
}) => Container(
  width: width,
  height: height,
  decoration: BoxDecoration(
    color: colors.card,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: colors.line),
  ),
  child: Stack(
    fit: StackFit.expand,
    children: [
      BalanceSparkleField(colors: colors, previewProgress: previewProgress),
      Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.muted,
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              'Soft, clear\nand calm.',
              style: TextStyle(
                color: colors.fg,
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
