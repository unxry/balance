import 'package:flutter/material.dart';
import 'package:flutter_app/services/activity_motion_service.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/premium_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activity_state_machine_test', () {
    final machine = ActivityStateMachine();
    final start = DateTime(2026, 9, 24, 12);

    expect(
      machine.update(
        const ActivitySignal(available: true, stationary: true),
        start,
      ),
      ActivityMotionState.idle,
    );
    expect(
      machine.update(
        const ActivitySignal(available: true, walking: true, cadence: 1.6),
        start.add(const Duration(milliseconds: 10)),
      ),
      ActivityMotionState.walk,
    );
    expect(
      machine.update(
        const ActivitySignal(available: true, running: true, cadence: 2.5),
        start.add(const Duration(milliseconds: 20)),
      ),
      ActivityMotionState.run,
    );
  });

  test('activity_hysteresis_test', () {
    final machine = ActivityStateMachine();
    final start = DateTime(2026, 9, 24, 12);
    machine.update(
      const ActivitySignal(available: true, running: true, cadence: 2.5),
      start,
    );
    expect(
      machine.update(
        const ActivitySignal(available: true, walking: true, cadence: 1.5),
        start.add(const Duration(milliseconds: 100)),
      ),
      ActivityMotionState.run,
    );
    expect(
      machine.update(
        const ActivitySignal(available: true, walking: true, cadence: 1.5),
        start.add(const Duration(milliseconds: 550)),
      ),
      ActivityMotionState.walk,
    );
    expect(
      machine.update(
        const ActivitySignal(available: true, stationary: true),
        start.add(const Duration(milliseconds: 650)),
      ),
      ActivityMotionState.walk,
    );
    expect(
      machine.update(
        const ActivitySignal(available: true, stationary: true),
        start.add(const Duration(milliseconds: 1200)),
      ),
      ActivityMotionState.idle,
    );
  });

  for (final size in [36.0, 68.0]) {
    testWidgets(
      size == 36 ? 'dashboard_character_small_test' : 'steps_character_test',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: BalanceActivityCharacter(
                colors: AppColors.wellness,
                size: size,
                travelWidth: size + 24,
                animationMode: BalanceActivityAnimationMode.run,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 310));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('balanceActivityCharacter')),
            matching: find.byType(Image),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('reduce_motion_character_test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: BalanceActivityCharacter(
            colors: AppColors.wellness,
            animationMode: BalanceActivityAnimationMode.run,
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('activityTicker-stopped')),
      findsOneWidget,
    );
  });
}
