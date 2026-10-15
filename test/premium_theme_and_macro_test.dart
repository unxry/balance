import 'package:flutter/material.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/animated_macro_ring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Wellness and Dark persist; legacy System maps to Wellness', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    await settings.load();
    expect(settings.themeMode, AppThemeMode.wellness);

    await settings.setTheme(AppThemeMode.dark);
    final darkRelaunch = SettingsProvider();
    await darkRelaunch.load();
    expect(darkRelaunch.themeMode, AppThemeMode.dark);

    await darkRelaunch.setTheme(AppThemeMode.system);
    final systemRelaunch = SettingsProvider();
    await systemRelaunch.load();
    expect(systemRelaunch.themeMode, AppThemeMode.wellness);
    expect(
      AppColors.of(AppThemeMode.dark, platformBrightness: Brightness.dark),
      same(AppColors.darkTheme),
    );
    expect(AppColors.systemDark.surface, isNot(AppColors.darkTheme.surface));
    expect(AppColors.systemLight.surface, isNot(AppColors.wellness.surface));
    expect(AppColors.systemLight.brightness, Brightness.light);
    expect(AppColors.systemDark.brightness, Brightness.dark);
  });

  test('macro ring uses 4/9/4 energy and a separate over-goal layer', () {
    final breakdown = MacroEnergyBreakdown.calculate(
      proteinG: 25,
      fatG: 10,
      carbsG: 50,
      calories: 2200,
      calorieGoal: 2000,
    );

    expect(breakdown.proteinCalories, 100);
    expect(breakdown.fatCalories, 90);
    expect(breakdown.carbCalories, 200);
    expect(breakdown.totalCalories, 390);
    expect(breakdown.shares.reduce((a, b) => a + b), closeTo(1, 0.0001));
    expect(breakdown.calorieProgress, 1);
    expect(breakdown.overGoalProgress, closeTo(0.1, 0.0001));
  });

  testWidgets('Reduce Motion renders the completed ring without ticker work', (
    tester,
  ) async {
    final breakdown = MacroEnergyBreakdown.calculate(
      proteinG: 25,
      fatG: 10,
      carbsG: 50,
      calories: 1000,
      calorieGoal: 2000,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Center(
            child: SizedBox.square(
              dimension: 180,
              child: AnimatedMacroRing(
                breakdown: breakdown,
                colors: AppColors.wellness,
                animationKey: 'today-1000',
                child: const Text('1000'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('macroCalorieRing')), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });
}
