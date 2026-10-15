import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/root_shell.dart';
import 'package:flutter_app/services/health_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class _NoHealth extends HealthService {
  @override
  Future<StepAccessState> getStatus() async => StepAccessState.notDetermined;
}

void main() {
  late Directory directory;
  late Box<dynamic> user;
  late Box<dynamic> food;
  late Box<dynamic> weight;
  late AppDataProvider data;

  setUpAll(() async {
    await initializeDateFormatting('ru');
    directory = await Directory.systemTemp.createTemp('water_goal_ui_');
    Hive.init(directory.path);
    user = await Hive.openBox<dynamic>('water_goal_user');
    food = await Hive.openBox<dynamic>('water_goal_food');
    weight = await Hive.openBox<dynamic>('water_goal_weight');
  });

  setUp(() async {
    await user.clear();
    await food.clear();
    await weight.clear();
    data = AppDataProvider(
      now: () => DateTime(2026, 9, 5, 12),
      userBox: user,
      foodBox: food,
      weightBox: weight,
      healthService: _NoHealth(),
      waterWriter: (_, _) => Future.value(),
    );
    await data.load();
    await data.updateProfile(UserProfile(name: 'Test', onboarded: true));
    await data.setWaterGoalLiters(2);
  });

  tearDown(() => data.dispose());

  tearDownAll(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  testWidgets('water goal editor clamps values above 2500 inline', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: data),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MaterialApp(home: RootShell()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('ВОДА'));
    await tester.tap(find.text('ВОДА'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(
      find.byKey(const ValueKey('editWaterGoalButton')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('editWaterGoalButton')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(
      find.byKey(const ValueKey('waterGoalField')),
      '3000',
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Максимальная цель — 2500 мл'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.ensureVisible(
      find.byKey(const ValueKey('saveWaterGoalButton')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('saveWaterGoalButton')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(data.waterGoalLiters, 2.5);
    expect(tester.takeException(), isNull);

    // Remove the modal/provider tree before the shared test boxes are reused.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
