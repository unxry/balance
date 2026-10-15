import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/achievement_models.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/achievement_medal.dart';
import 'package:flutter_app/widgets/premium_motion.dart';

const _achievement = AchievementProgress(
  definition: AchievementDefinition(
    id: 'motion-test',
    category: AchievementCategory.special,
    tier: AchievementTier.gold,
    titleRu: 'Тест',
    titleEn: 'Test',
    descriptionRu: 'Описание',
    descriptionEn: 'Description',
    requirementRu: 'Условие',
    requirementEn: 'Requirement',
    metric: 'test',
    targetValue: 1,
    symbol: 'diamond',
  ),
  currentValue: 1,
  state: AchievementState.unlocked,
);

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('activity character has idle, walking and running states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const BalanceActivityCharacter(
          colors: AppColors.wellness,
          animationMode: BalanceActivityAnimationMode.idle,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('activity-idle')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('balanceActivityCharacter')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _app(
        const BalanceActivityCharacter(
          colors: AppColors.wellness,
          animationMode: BalanceActivityAnimationMode.walkRunCycle,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 370));
    expect(find.byKey(const ValueKey('activity-walk')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3300));
    expect(find.byKey(const ValueKey('activity-run')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('balanceActivityCharacter')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });

  testWidgets('activity character ticker stops offscreen', (tester) async {
    await tester.pumpWidget(
      _app(
        const TickerMode(
          enabled: false,
          child: BalanceActivityCharacter(colors: AppColors.wellness),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('activityTicker-stopped')),
      findsOneWidget,
    );
  });

  testWidgets('all gait key poses keep stable dimensions without overflow', (
    tester,
  ) async {
    for (final pose in BalanceActivityPose.values) {
      await tester.pumpWidget(
        _app(
          BalanceActivityCharacter(
            colors: AppColors.wellness,
            size: 42,
            travelWidth: 108,
            previewPose: pose,
          ),
        ),
      );
      expect(find.byKey(ValueKey('activityPose-${pose.name}')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('balanceActivityCharacter'))),
        const Size(108, 42),
      );
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      _app(
        const BalanceActivityCharacter(
          colors: AppColors.wellness,
          size: 72,
          travelWidth: 182,
          previewPose: BalanceActivityPose.runFlight,
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('balanceActivityCharacter'))),
      const Size(182, 72),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('character and point respect Reduce Motion', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BalanceActivityCharacter(colors: AppColors.wellness),
            BalancePulsePoint(colors: AppColors.wellness),
          ],
        ),
        reduceMotion: true,
      ),
    );
    expect(
      find.byKey(const ValueKey('activityTicker-stopped')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('balancePulseTicker-stopped')),
      findsOneWidget,
    );
  });

  testWidgets('achievement sparkles respect Reduce Motion', (tester) async {
    await tester.pumpWidget(
      _app(
        const AchievementMedal(
          achievement: _achievement,
          colors: AppColors.wellness,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('achievementMedalGlow')), findsOneWidget);
    expect(find.byKey(const ValueKey('achievementSparkles')), findsOneWidget);

    await tester.pumpWidget(
      _app(
        const AchievementMedal(
          achievement: _achievement,
          colors: AppColors.wellness,
        ),
        reduceMotion: true,
      ),
    );
    expect(find.byKey(const ValueKey('achievementSparkles')), findsNothing);
  });

  testWidgets('achievement reveal uses the calm 850ms sequence', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showAchievementReveal(context, _achievement, isRu: true),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();

    final sequence = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('achievementUnlockSequence')),
    );
    expect(sequence.duration, const Duration(milliseconds: 850));
    expect(find.text('НОВОЕ ДОСТИЖЕНИЕ'), findsOneWidget);
    expect(find.text('Условие'), findsOneWidget);
  });
}
