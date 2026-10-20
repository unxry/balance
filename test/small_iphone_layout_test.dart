import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/models/history_models.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/diary_screen.dart';
import 'package:flutter_app/screens/add_food_screen.dart';
import 'package:flutter_app/screens/dashboard_screen.dart';
import 'package:flutter_app/screens/profile_screen.dart';
import 'package:flutter_app/screens/profile_stat_detail_screen.dart';
import 'package:flutter_app/screens/root_shell.dart';
import 'package:flutter_app/screens/steps_screen.dart';
import 'package:flutter_app/screens/weight_screen.dart';
import 'package:flutter_app/services/health_service.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/balance_feedback.dart';
import 'package:flutter_app/widgets/premium_motion.dart';
import 'package:flutter_app/widgets/tab_bar_pill.dart';

class _NotDeterminedHealth extends HealthService {
  @override
  Future<StepAccessState> getStatus() async => StepAccessState.notDetermined;
}

class _SparseStepsData extends AppDataProvider {
  _SparseStepsData({
    required Box<dynamic> userBox,
    required Box<dynamic> foodBox,
    required Box<dynamic> weightBox,
  }) : super(
         now: () => DateTime(2026, 9, 2, 12),
         userBox: userBox,
         foodBox: foodBox,
         weightBox: weightBox,
         healthService: _NotDeterminedHealth(),
         waterWriter: (_, _) => Future.value(),
       );

  @override
  List<DailyBalanceSnapshot> get dailyBalances => [
    DailyBalanceSnapshot(
      dateKey: '2026-08-31',
      caloriesEaten: 0,
      stepCount: 101,
      waterLiters: 0,
    ),
    DailyBalanceSnapshot(
      dateKey: '2026-09-01',
      caloriesEaten: 0,
      stepCount: 202,
      waterLiters: 0,
    ),
  ];
}

void main() {
  late Directory directory;
  late Box<dynamic> userBox;
  late Box<dynamic> foodBox;
  late Box<dynamic> weightBox;
  late AppDataProvider data;
  var boxSequence = 0;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
    directory = await Directory.systemTemp.createTemp('balance_layout_test_');
    Hive.init(directory.path);
  });

  setUp(() async {
    boxSequence++;
    userBox = await Hive.openBox<dynamic>('layout_user_$boxSequence');
    foodBox = await Hive.openBox<dynamic>('layout_food_$boxSequence');
    weightBox = await Hive.openBox<dynamic>('layout_weight_$boxSequence');
    data = AppDataProvider(
      now: () => DateTime(2026, 9, 2, 12),
      userBox: userBox,
      foodBox: foodBox,
      weightBox: weightBox,
      healthService: _NotDeterminedHealth(),
      waterWriter: (_, _) => Future.value(),
    );
    await data.load();
    await data.updateProfile(
      UserProfile(
        name: 'Александра',
        weightKg: 80,
        targetWeightKg: 72,
        joinedAt: DateTime(2026, 8, 28),
        onboarded: true,
      ),
    );
  });

  tearDown(() {
    data.dispose();
  });

  tearDownAll(() {
    // Each widget-test file runs in its own Flutter tester process. Removing
    // the temporary files synchronously avoids waiting on writes deliberately
    // issued without awaiting by the production provider API.
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  Widget app(Widget child, {double textScale = 1, bool reduceMotion = true}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: data),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: reduceMotion,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('dashboard and water sheet fit iPhone SE dimensions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const RootShell()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('ВОДА'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ВОДА'));
    await tester.pumpAndSettle();
    expect(find.text('Точный объём'), findsOneWidget);
    expect(find.text('Добавить 250 мл'), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.showKeyboard(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
  });

  testWidgets('dashboard pager moves through days and blocks future', (
    tester,
  ) async {
    expect(
      await tester.runAsync(
        () => data.addFoodForDate(
          FoodEntry(
            id: 'yesterday-food',
            name: 'Каша',
            grams: 250,
            kcal: 350,
            proteinG: 12,
            fatG: 8,
            carbsG: 58,
            meal: MealType.breakfast,
            time: DateTime(2026, 9, 1, 8),
          ),
          '2026-09-01',
        ),
      ),
      isTrue,
    );
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      app(
        DashboardScreen(
          onOpenSteps: () {},
          onOpenWeight: () {},
          onOpenAdvice: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pager = find.byKey(const ValueKey('dashboardDayPager'));

    await tester.drag(pager, const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(data.selectedDateKey, '2026-09-01');
    expect(find.textContaining('ВЧЕРА'), findsOneWidget);
    expect(find.text('СОВЕТ ДНЯ'), findsOneWidget);
    expect(find.text('ИТОГ ДНЯ'), findsNothing);
    expect(find.textContaining('рацион'), findsOneWidget);
    expect(find.byKey(const ValueKey('adviceStar')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(data.selectedDateKey, '2026-09-01');
    expect(tester.takeException(), isNull);

    await tester.drag(pager, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(data.selectedDateKey, '2026-09-02');

    await tester.drag(pager, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(data.selectedDateKey, '2026-09-02');

    for (var i = 0; i < 5; i++) {
      await tester.drag(pager, const Offset(300, 0));
      await tester.pumpAndSettle();
    }
    expect(data.selectedDateKey, '2026-08-28');
    for (var i = 0; i < 5; i++) {
      await tester.drag(pager, const Offset(-300, 0));
      await tester.pumpAndSettle();
    }
    expect(data.selectedDateKey, '2026-09-02');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('activity, weight, diary and profile fit compact iPhone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final screens = <Widget>[
      StepsScreen(onBack: () {}),
      WeightScreen(onBack: () {}),
      DiaryScreen(onSearch: (MealType _) {}),
      ProfileScreen(onEditGoal: () {}),
    ];
    for (final screen in screens) {
      await tester.pumpWidget(app(screen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.takeException(),
        isNull,
        reason: '${screen.runtimeType} overflowed',
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('dashboard and Steps use ambient character without live motion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    data.stepAccess = StepAccessState.authorized;
    data.todaySteps = 2345;

    await tester.pumpWidget(
      app(
        DashboardScreen(
          onOpenSteps: () {},
          onOpenWeight: () {},
          onOpenAdvice: () {},
        ),
        reduceMotion: false,
      ),
    );
    await tester.pump();
    final dashboardCharacter = tester.widget<BalanceActivityCharacter>(
      find.byType(BalanceActivityCharacter),
    );
    expect(
      dashboardCharacter.animationMode,
      BalanceActivityAnimationMode.ambient,
    );

    await tester.pumpWidget(
      app(StepsScreen(onBack: () {}), reduceMotion: false),
    );
    await tester.pump();
    final stepsCharacter = tester.widget<BalanceActivityCharacter>(
      find.byType(BalanceActivityCharacter),
    );
    expect(stepsCharacter.animationMode, BalanceActivityAnimationMode.ambient);
    expect(stepsCharacter.size, greaterThan(dashboardCharacter.size));
  });

  testWidgets(
    'dashboard hero survives rebuild, tabs, scroll and theme changes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      data.stepAccess = StepAccessState.authorized;
      data.todaySteps = 4800;
      await tester.pumpWidget(app(const RootShell(), reduceMotion: false));
      await tester.pump(const Duration(milliseconds: 600));

      void expectHero() {
        expect(
          tester.getSize(find.byKey(const ValueKey('dashboardHeroViewport'))),
          const Size(350, 345),
        );
        expect(
          find.byKey(ValueKey('calorieRingTap:${data.selectedDateKey}')),
          findsOneWidget,
        );
      }

      expectHero();
      await tester.tap(find.byKey(const ValueKey('rootTab-profile')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(const ValueKey('rootTab-home')));
      await tester.pump(const Duration(milliseconds: 600));
      expectHero();

      final dashboardScroll = find.ancestor(
        of: find.byKey(const ValueKey('dashboardHeroViewport')),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(dashboardScroll, const Offset(0, -420));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(const ValueKey('rootTab-home')));
      await tester.pump(const Duration(milliseconds: 600));
      expectHero();

      final settings = tester
          .element(find.byKey(const ValueKey('balanceRootScaffold')))
          .read<SettingsProvider>();
      settings.setTheme(AppThemeMode.system);
      await tester.pump(const Duration(milliseconds: 100));
      expectHero();
      await tester.pumpWidget(app(const RootShell(), reduceMotion: false));
      await tester.pump(const Duration(milliseconds: 600));
      expectHero();
      expect(find.byType(BalanceActivityCharacter), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'Average Steps starts sparse data at the left and switches period',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      data.todaySteps = 1234;

      await tester.pumpWidget(
        app(
          ProfileStatDetailScreen(
            kind: ProfileStatKind.averageSteps,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      var chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.data.barGroups.first.barRods.first.toY, 1234);
      expect(
        chart.data.barGroups
            .skip(1)
            .every((group) => group.barRods.first.toY == 0),
        isTrue,
      );
      expect(find.text('Недостаточно данных'), findsOneWidget);
      expect(find.byKey(const ValueKey('stepsFirstDayState')), findsOneWidget);
      final tooltip = chart.data.barTouchData.touchTooltipData.getTooltipItem;
      expect(
        tooltip(
          chart.data.barGroups.first,
          0,
          chart.data.barGroups.first.barRods.first,
          0,
        ),
        isNotNull,
      );
      expect(
        tooltip(
          chart.data.barGroups[1],
          1,
          chart.data.barGroups[1].barRods.first,
          0,
        ),
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('stepsPeriod-30')));
      await tester.pumpAndSettle();
      chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.data.barGroups, hasLength(30));
      expect(chart.data.barGroups.first.barRods.first.toY, 1234);
      expect(find.byKey(const ValueKey('stepsPeriodCapsule')), findsOneWidget);
    },
  );

  testWidgets('three sparse step days fill the first three chart slots', (
    tester,
  ) async {
    data.dispose();
    data = _SparseStepsData(
      userBox: userBox,
      foodBox: foodBox,
      weightBox: weightBox,
    );
    data.todaySteps = 303;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      app(
        ProfileStatDetailScreen(
          kind: ProfileStatKind.averageSteps,
          onBack: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final groups = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barGroups;
    expect(groups.take(3).map((group) => group.barRods.first.toY), [
      101,
      202,
      303,
    ]);
    expect(
      groups.skip(3).every((group) => group.barRods.first.toY == 0),
      isTrue,
    );
  });

  testWidgets('single weight uses a compact first-measurement state', (
    tester,
  ) async {
    expect(data.weightHistory, hasLength(1));
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      app(
        ProfileStatDetailScreen(
          kind: ProfileStatKind.weightChange,
          onBack: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Собираем данные'), findsOneWidget);
    expect(find.text('Первое измерение'), findsOneWidget);
    expect(find.byKey(const ValueKey('balancePulsePoint')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('singleWeightCompactState')),
      findsOneWidget,
    );
    expect(find.textContaining('Добавьте ещё одно измерение'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('goal and nutrition editor fits iPhone SE', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(const RootShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('ЦЕЛЬ И ПИТАНИЕ'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goalNutritionCard')));
    await tester.pumpAndSettle();

    expect(find.text('Автоматически'), findsWidgets);
    expect(find.text('Вручную'), findsOneWidget);
    expect(find.textContaining('новая рекомендация'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Сохранить'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('weight analytics fits a small iPhone with larger text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(WeightScreen(onBack: () {}), textScale: 1.5));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('periodWeightChange')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Первое измерение'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('balanceInsight')),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'weight chart shows actual readings without a food-data threshold',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(WeightScreen(onBack: () {})));
      await tester.pump();
      expect(find.byKey(const ValueKey('weightFullChart')), findsOneWidget);
      final firstChart = tester.widget<LineChart>(find.byType(LineChart));
      expect(firstChart.data.lineBarsData.single.spots, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('weightRange-week')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('weightWeeklyOverview')),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(const ValueKey('weightWeeklyOverview')),
        findsOneWidget,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 700));
      await tester.pumpAndSettle();
      final collection = find.byKey(const ValueKey('weightCollectionState'));
      expect(
        find.descendant(
          of: collection,
          matching: find.byIcon(Icons.arrow_forward_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: collection,
          matching: find.byIcon(Icons.flag_outlined),
        ),
        findsNothing,
      );

      expect(
        await tester.runAsync(
          () => data.addWeightEntry(79.6, date: DateTime(2026, 9, 1)),
        ),
        isTrue,
      );
      for (final date in [
        DateTime(2026, 8, 27),
        DateTime(2026, 8, 29),
        DateTime(2026, 8, 30),
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 2),
      ]) {
        expect(
          await tester.runAsync(
            () => data.addFoodForDate(
              FoodEntry(
                id: 'threshold-${date.day}',
                name: 'Тестовый рацион',
                grams: 100,
                kcal: 120,
                proteinG: 8,
                fatG: 4,
                carbsG: 12,
                meal: MealType.breakfast,
                time: date,
              ),
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            ),
          ),
          isTrue,
        );
      }
      await tester.pump();

      expect(data.informativeDayCount, greaterThanOrEqualTo(7));
      expect(find.byKey(const ValueKey('weightFullChart')), findsOneWidget);
      expect(find.byKey(const ValueKey('weightCollectionState')), findsNothing);
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.single.spots.length, greaterThan(2));
      expect(chart.data.lineBarsData.single.spots.first.y, 80);
      expect(chart.data.lineBarsData.single.spots.last.y, 79.6);
      expect(chart.data.lineBarsData.first.isCurved, isFalse);
      expect(chart.data.lineBarsData.first.isStrokeCapRound, isTrue);
    },
  );

  testWidgets('weight summary cards restore scroll and compact sheets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(WeightScreen(onBack: () {})));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('за период'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final before = scrollable.position.pixels;
    await tester.ensureVisible(find.text('за период'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('за период'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(scrollable.position.pixels, lessThan(before));
    expect(find.byType(BottomSheet), findsNothing);

    await tester.scrollUntilVisible(
      find.text('до цели'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('до цели'));
    await tester.pumpAndSettle();
    expect(find.text('Цель по весу'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    Navigator.of(tester.element(find.text('Цель по весу'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('нужно больше данных'));
    await tester.pumpAndSettle();
    expect(find.text('Прогноз'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('weight screen handles dense history and editing sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final anchor = DateTime(2026, 9, 2, 8);
    for (var day = 60; day >= 1; day--) {
      expect(
        await tester.runAsync(
          () => data.addWeightEntry(
            80 + day * 0.025 + (day.isEven ? 0.12 : -0.08),
            date: anchor.subtract(Duration(days: day)),
          ),
        ),
        isTrue,
      );
    }
    final foodDate = anchor;
    expect(
      await tester.runAsync(
        () => data.addFoodForDate(
          FoodEntry(
            id: 'history-food',
            name: 'Очень длинное название тестового блюда для истории',
            grams: 280,
            kcal: 420,
            proteinG: 24,
            fatG: 15,
            carbsG: 46,
            meal: MealType.lunch,
            time: foodDate,
          ),
          '2026-09-02',
        ),
      ),
      isTrue,
    );

    await tester.pumpWidget(app(WeightScreen(onBack: () {})));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('weightRange-year')));
    await tester.pumpAndSettle();
    expect(find.text('за 365 дней'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('weightMeasurementsHistory')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('weightMeasurementsHistory')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('weightFoodHistory')), findsOneWidget);
    final measurement = find
        .byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'measurement-',
              ),
        )
        .first;
    await tester.tap(measurement);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('saveWeightButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('selectedWeightDayData')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('deleteWeightButton')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('confirmDeleteWeightButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cancelDeleteWeightButton')),
      findsOneWidget,
    );
    expect(find.text('Отмена'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cancelDeleteWeightButton')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(WeightScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weightHistoryTabs')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('food-history-2026-09-02')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('food-history-2026-09-02')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('food-history-2026-09-02')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Очень длинное название'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(
      tester.element(find.textContaining('Очень длинное название')),
    ).pop();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('addWeightButton')),
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('addWeightButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weightDateField')), findsOneWidget);
    expect(find.byKey(const ValueKey('saveWeightButton')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Dispose the still-open modal route before closing the Hive boxes used by
    // this test file; otherwise its provider listener can outlive the test.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('root swipe, live glass capsule and dated diary stay in sync', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const RootShell(), reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 900));

    final indicator = find.byKey(const ValueKey('balanceGlassIndicator'));
    final initialIndicator = tester.widget<Positioned>(indicator);
    final initialLeft = initialIndicator.left!;
    expect(initialIndicator.width, 50);
    expect(initialIndicator.height, 50);
    final lens = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('balanceGlassLensSurface')),
    );
    expect((lens.decoration as BoxDecoration).borderRadius, isNotNull);
    var pager = tester.widget<PageView>(
      find.byKey(const ValueKey('rootTabPager')),
    );
    pager.controller!.position.jumpTo(
      pager.controller!.position.viewportDimension * .5,
    );
    await tester.pump();
    final midpointIndicator = tester.widget<Positioned>(indicator);
    final draggedLeft = midpointIndicator.left!;
    expect(draggedLeft, greaterThan(initialLeft));
    expect(midpointIndicator.width, greaterThan(50));
    pager.controller!.jumpToPage(0);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rootTab-weight')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(pager.controller!.page, greaterThan(0));
    expect(pager.controller!.page, lessThan(1));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.widget<TabBarPill>(find.byType(TabBarPill)).selectedIndex, 1);
    await tester.pumpWidget(
      app(
        const RootShell(key: ValueKey('reducedMotionRoot')),
        reduceMotion: true,
      ),
    );
    await tester.pump();
    pager = tester.widget<PageView>(find.byKey(const ValueKey('rootTabPager')));
    pager.controller!.jumpToPage(0);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('rootTab-home')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.dragFrom(const Offset(360, 610), const Offset(-320, 0));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.widget<TabBarPill>(find.byType(TabBarPill)).selectedIndex, 1);

    await tester.tap(find.byKey(const ValueKey('rootTab-home')));
    await tester.pump(const Duration(milliseconds: 900));
    pager.controller!.jumpToPage(0);
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('dashboardDayPager')),
      const Offset(300, 0),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(data.selectedDateKey, '2026-09-01');
    expect(tester.widget<TabBarPill>(find.byType(TabBarPill)).selectedIndex, 0);

    await tester.tap(find.byKey(const ValueKey('calorieRingTap:2026-09-01')));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.widget<TabBarPill>(find.byType(TabBarPill)).selectedIndex, 2);
    expect(data.selectedDateKey, '2026-09-01');
    expect(find.textContaining('1 СЕНТЯБРЯ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fast Profile selection stays aligned with the visible page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app(const RootShell()));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Главная'), findsOneWidget);
    expect(find.bySemanticsLabel('Вес'), findsOneWidget);
    expect(find.bySemanticsLabel('Дневник'), findsOneWidget);
    expect(find.bySemanticsLabel('Профиль'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rootTab-profile')));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.dragFrom(const Offset(190, 500), const Offset(0, -90));
    await tester.pump();

    final pager = tester.widget<PageView>(
      find.byKey(const ValueKey('rootTabPager')),
    );
    final selected = tester
        .widget<TabBarPill>(find.byType(TabBarPill))
        .selectedIndex;
    expect(selected, (pager.controller!.page ?? 0).round());

    await tester.pumpAndSettle();
    expect(
      tester.widget<TabBarPill>(find.byType(TabBarPill)).selectedIndex,
      (pager.controller!.page ?? 0).round(),
    );
    await tester.tap(find.byKey(const ValueKey('rootTab-profile')));
    await tester.pumpAndSettle();
    expect(pager.controller!.page, 3);
    expect(tester.widget<TabBarPill>(find.byType(TabBarPill)).selectedIndex, 3);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('navigation race: the last tab tap always wins', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const RootShell(), reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 900));

    Future<void> tapTab(String tab, [int milliseconds = 16]) async {
      await tester.tap(find.byKey(ValueKey('rootTab-$tab')));
      await tester.pump();
      await tester.pump(Duration(milliseconds: milliseconds));
    }

    void expectTab(int index) {
      final pager = tester.widget<PageView>(
        find.byKey(const ValueKey('rootTabPager')),
      );
      expect(pager.controller!.page, index);
      expect(
        tester.widget<TabBarPill>(find.byType(TabBarPill)).selectedIndex,
        index,
      );
    }

    await tapTab('diary');
    await tapTab('profile');
    await tapTab('home');
    await tester.pump(const Duration(milliseconds: 900));
    expectTab(0);

    await tapTab('profile');
    await tapTab('home');
    await tapTab('diary');
    await tester.pump(const Duration(milliseconds: 900));
    expectTab(2);

    for (final tab in ['home', 'profile', 'weight', 'diary', 'home']) {
      await tapTab(tab, 1);
    }
    await tester.pump(const Duration(milliseconds: 900));
    expectTab(0);

    final morphPager = tester.widget<PageView>(
      find.byKey(const ValueKey('rootTabPager')),
    );
    morphPager.controller!.position.jumpTo(
      morphPager.controller!.position.viewportDimension * .4,
    );
    await tester.pump();
    expect(
      tester
          .widget<Positioned>(
            find.byKey(const ValueKey('balanceGlassIndicator')),
          )
          .width,
      greaterThan(50),
    );
    await tapTab('profile');
    await tester.pump(const Duration(milliseconds: 900));
    expectTab(3);

    await tapTab('diary', 500);
    await tapTab('home');
    await tester.pump(const Duration(milliseconds: 900));
    expectTab(0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing Add Food restores the selected Diary page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const RootShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rootTab-diary')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить блюдо'));
    await tester.pumpAndSettle();
    expect(find.text('Добавить еду'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    final pager = tester.widget<PageView>(
      find.byKey(const ValueKey('rootTabPager')),
    );
    expect(pager.controller!.page, 2);
    expect(tester.widget<TabBarPill>(find.byType(TabBarPill)).selectedIndex, 2);
    expect(find.textContaining('ДНЕВНИК'), findsWidgets);
  });

  testWidgets('profile controls and legal rows expose production semantics', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app(const RootShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rootTab-profile')));
    await tester.pumpAndSettle();

    final wellness = tester.getSemantics(find.bySemanticsLabel('Wellness'));
    expect(wellness.flagsCollection.isButton, isTrue);
    expect(wellness.flagsCollection.isSelected, Tristate.isTrue);
    final ru = tester.getSemantics(find.bySemanticsLabel('RU'));
    final en = tester.getSemantics(find.bySemanticsLabel('EN'));
    expect(ru.flagsCollection.isButton, isTrue);
    expect(ru.flagsCollection.isSelected, Tristate.isTrue);
    expect(en.flagsCollection.isButton, isTrue);
    expect(en.flagsCollection.isSelected, Tristate.isFalse);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Профиль'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('EN'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.runAsync(() async {
      await tester.tap(find.bySemanticsLabel('EN'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('EN'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Weight'), findsOneWidget);
    expect(find.bySemanticsLabel('Diary'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Profile'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.tap(find.bySemanticsLabel('RU'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('editProfileAction')), findsNothing);
    expect(find.byKey(const ValueKey('startOverAction')), findsOneWidget);
    expect(find.bySemanticsLabel('Изменить фото профиля'), findsOneWidget);
    expect(find.bySemanticsLabel('Настройки уведомлений'), findsOneWidget);
    expect(
      find.bySemanticsLabel(data.achievements.first.definition.titleRu),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profileLastSection')),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Политика конфиденциальности'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Условия использования'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Политика конфиденциальности'));
    await tester.pumpAndSettle();
    expect(find.text('Политика конфиденциальности'), findsOneWidget);
    expect(find.textContaining('BLOCKER'), findsNothing);
    expect(
      find.bySemanticsLabel('Связаться с поддержкой Balance'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Home owns its scroll state and repeated Home tap returns top', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const RootShell()));
    await tester.pumpAndSettle();

    final dashboardScroll = find.descendant(
      of: find.byType(DashboardScreen),
      matching: find.byType(SingleChildScrollView),
    );
    final controller = tester
        .widget<SingleChildScrollView>(dashboardScroll.first)
        .controller!;
    expect(controller.offset, 0);

    await tester.tap(find.byKey(const ValueKey('rootTab-diary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rootTab-home')));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);

    await tester.drag(dashboardScroll.first, const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    await tester.tap(find.byKey(const ValueKey('rootTab-home')));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
  });

  testWidgets('Advice and glass simplify under Reduce Motion', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(const RootShell(), reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('adviceMotion-active')), findsOneWidget);
    for (var index = 0; index < 15; index++) {
      expect(find.byKey(ValueKey('adviceSparkle-$index')), findsOneWidget);
    }

    await tester.pumpWidget(app(const RootShell(), reduceMotion: true));
    await tester.pump();
    expect(find.byKey(const ValueKey('adviceMotion-stopped')), findsOneWidget);
    for (var index = 0; index < 15; index++) {
      expect(find.byKey(ValueKey('adviceSparkle-$index')), findsOneWidget);
    }

    final pager = tester.widget<PageView>(
      find.byKey(const ValueKey('rootTabPager')),
    );
    pager.controller!.position.jumpTo(
      pager.controller!.position.viewportDimension * .5,
    );
    await tester.pump();
    final indicator = tester.widget<Positioned>(
      find.byKey(const ValueKey('balanceGlassIndicator')),
    );
    expect(indicator.width, 50);
  });

  testWidgets('home action stays usable at 200 percent text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const RootShell(), textScale: 2));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('tryTodayFromHome'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Что сделать сегодня'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('whole Advice card opens the contextual detail sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const RootShell()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('adviceCard')));
    final adviceSemantics = tester.getSemantics(
      find.byKey(const ValueKey('adviceCard')),
    );
    expect(adviceSemantics.flagsCollection.isButton, isTrue);
    expect(adviceSemantics.label, contains('СОВЕТ ДНЯ'));
    await tester.tap(find.byKey(const ValueKey('adviceCard')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('adviceDetailSheet')), findsOneWidget);
    expect(find.text('Что сделать сегодня'), findsWidgets);
    expect(find.text('На основе'), findsOneWidget);
    expect(
      find.text(
        'Практическая идея на сегодня. Выберите подходящий вам вариант.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('tipPersonalization')), findsOneWidget);
  });

  testWidgets('Diary action ends above the glass navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const RootShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rootTab-diary')));
    await tester.pumpAndSettle();

    final action = tester.getRect(
      find.byKey(const ValueKey('diaryPrimaryAction')),
    );
    final navigation = tester.getRect(
      find.byKey(const ValueKey('balanceGlassNavigation')),
    );
    expect(action.bottom, lessThan(navigation.top));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('diaryPrimaryAction')));
    await tester.pumpAndSettle();
    tester.widget<AddFoodScreen>(find.byType(AddFoodScreen)).onAdded!(
      FoodEntry(
        id: 'navigation-entry',
        name: 'Navigation entry',
        grams: 100,
        kcal: 100,
        proteinG: 0,
        fatG: 0,
        carbsG: 0,
        meal: MealType.lunch,
        time: DateTime(2026, 9, 2, 12),
      ),
    );
    await tester.pumpAndSettle();
    final pager = tester.widget<PageView>(
      find.byKey(const ValueKey('rootTabPager')),
    );
    expect(pager.controller!.page, AppTab.diary.index.toDouble());
    expect(find.byKey(const ValueKey('diaryPrimaryAction')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('root glass navigation keeps the themed surface underlay', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const RootShell()));
    await tester.pump(const Duration(milliseconds: 100));

    final root = tester.widget<Scaffold>(
      find.byKey(const ValueKey('balanceRootScaffold')),
    );
    expect(root.extendBody, isTrue);
    expect(root.backgroundColor, isNot(Colors.black));
    expect(
      find.byKey(const ValueKey('balanceGlassNavigation')),
      findsOneWidget,
    );
  });

  testWidgets('Profile final section remains above glass navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const RootShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rootTab-profile')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profileLastSection')),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    final lastSection = tester.getRect(
      find.byKey(const ValueKey('profileLastSection')),
    );
    final navigation = tester.getRect(
      find.byKey(const ValueKey('balanceGlassNavigation')),
    );
    expect(lastSection.bottom, lessThanOrEqualTo(navigation.top));
  });

  testWidgets('diary deletion uses top undo feedback and restores entry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final entry = FoodEntry(
      id: 'undo-entry',
      name: 'Йогурт для теста',
      grams: 150,
      kcal: 120,
      proteinG: 7,
      fatG: 4,
      carbsG: 13,
      meal: MealType.breakfast,
      time: DateTime(2026, 9, 2, 9),
    );
    expect(
      await tester.runAsync(() => data.addFoodForDate(entry, '2026-09-02')),
      isTrue,
    );
    await tester.pumpWidget(
      app(BalanceFeedbackHost(child: DiaryScreen(onSearch: (_) {}))),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('undo-entry')));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.fling(
        find.byKey(const ValueKey('undo-entry')),
        const Offset(-500, 0),
        2400,
      );
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byKey(const ValueKey('undo-entry')), findsNothing);
    expect(find.byKey(const ValueKey('balanceToast')), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('balanceToastAction')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('undo-entry')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
