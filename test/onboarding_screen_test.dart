import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/onboarding_screen.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/common.dart';

class _MemoryAppDataProvider extends AppDataProvider {
  @override
  Future<void> updateProfile(UserProfile next) async {
    profile = UserProfile.fromJson(next.toJson());
    notifyListeners();
  }
}

void main() {
  testWidgets('onboarding validates consent and creates the profile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final settings = SettingsProvider();
    final data = _MemoryAppDataProvider();
    var completed = false;
    final colors = AppColors.of(AppThemeMode.wellness);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider<AppDataProvider>.value(value: data),
        ],
        child: AppColorsScope(
          colors: colors,
          child: MaterialApp(
            home: OnboardingScreen(onDone: () => completed = true),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('onboardingName')),
      'Alex',
    );
    final continueButton = find.descendant(
      of: find.byKey(const ValueKey('onboardingContinue')),
      matching: find.byType(InkWell),
    );
    for (var i = 0; i < 5; i++) {
      await tester.tap(continueButton);
      await tester.pump();
    }
    await tester.tap(continueButton);
    await tester.pump();
    expect(completed, isFalse);
    expect(find.textContaining('Необходимо принять'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('legalConsentToggle')));
    await tester.pump();
    await tester.tap(continueButton);
    await tester.pump();

    expect(completed, isTrue);
    expect(data.profile.onboarded, isTrue);
    expect(data.profile.name, 'Alex');
  });

  testWidgets('profile edit reuses onboarding with prefilled values', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final settings = SettingsProvider();
    final data = _MemoryAppDataProvider();
    final joined = DateTime(2024, 2, 3);
    data.profile = UserProfile(
      name: 'Alex',
      gender: Gender.male,
      age: 36,
      heightCm: 181,
      weightKg: 79,
      goal: Goal.hold,
      targetWeightKg: 79,
      joinedAt: joined,
      onboarded: true,
    );
    var completed = false;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider<AppDataProvider>.value(value: data),
        ],
        child: AppColorsScope(
          colors: AppColors.wellness,
          child: MaterialApp(
            home: OnboardingScreen(
              initialProfile: data.profile,
              onDone: () => completed = true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Alex'), findsOneWidget);
    expect(find.byKey(const ValueKey('legalConsent')), findsNothing);
    final button = find.descendant(
      of: find.byKey(const ValueKey('onboardingContinue')),
      matching: find.byType(InkWell),
    );
    for (var i = 0; i < 6; i++) {
      await tester.tap(button);
      await tester.pump();
    }
    expect(completed, isTrue);
    expect(data.profile.name, 'Alex');
    expect(data.profile.gender, Gender.male);
    expect(data.profile.joinedAt, joined);
  });
}
