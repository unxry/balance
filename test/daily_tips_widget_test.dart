import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/advice_screen.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/common.dart';
import 'package:flutter_app/widgets/daily_tip_card.dart';
import 'package:flutter_app/screens/weight_insights_screen.dart';
import 'package:flutter_app/screens/weight_screen.dart';

void main() {
  late Directory directory;
  late AppDataProvider data;
  late SettingsProvider settings;
  var sequence = 0;
  setUpAll(() async {
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
    directory = await Directory.systemTemp.createTemp('daily_tip_widget_');
    Hive.init(directory.path);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsProvider();
    data = AppDataProvider(
      now: () => DateTime(2026, 10, 15, 12),
      userBox: await Hive.openBox<dynamic>('tip_widget_user_${sequence++}'),
      foodBox: await Hive.openBox<dynamic>('tip_widget_food_$sequence'),
      weightBox: await Hive.openBox<dynamic>('tip_widget_weight_$sequence'),
    );
    await data.load();
  });
  tearDown(() async {
    await data.persistPendingMutations();
    data.dispose();
    settings.dispose();
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Widget app({required bool dark, required double scale, Widget? child}) {
    final colors = dark ? AppColors.darkTheme : AppColors.wellness;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: data),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: AppColorsScope(
        colors: colors,
        child: MaterialApp(
          theme: ThemeData(
            brightness: colors.brightness,
            scaffoldBackgroundColor: colors.page,
          ),
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: Scaffold(body: child ?? const AdviceScreen()),
          ),
        ),
      ),
    );
  }

  for (final width in [320.0, 414.0, 430.0]) {
    for (final ru in [true, false]) {
      for (final dark in [false, true]) {
        testWidgets(
          'daily tip fits $width RU=$ru dark=$dark at 200% with reduced motion',
          (tester) async {
            await tester.binding.setSurfaceSize(Size(width, 896));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            await settings.setLang(ru ? AppLang.ru : AppLang.en);
            await tester.pumpWidget(app(dark: dark, scale: 2));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              find.text(data.dailyTips.currentTip!.copy(ru).title),
              findsOneWidget,
            );
            await tester.drag(
              find.byType(SingleChildScrollView),
              const Offset(0, -1200),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(const ValueKey('tipPersonalization')),
              findsOneWidget,
            );
          },
        );
      }
    }
  }

  testWidgets('insights and library stay usable at 200 percent in RU and EN', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final ru in [true, false]) {
      await settings.setLang(ru ? AppLang.ru : AppLang.en);
      await tester.pumpWidget(
        app(dark: !ru, scale: 2, child: const WeightInsightsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('insightState')), findsOneWidget);
      expect(
        find.text(ru ? 'Пока мало данных' : 'Not enough data yet'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('openInsightFood')));
      await tester.tap(find.byKey(const ValueKey('openInsightFood')));
      await tester.pumpAndSettle();
      expect(find.byType(InsightFoodRecordsScreen), findsOneWidget);
      expect(
        find.text(ru ? 'Записей пока нет' : 'No entries yet'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        app(dark: !ru, scale: 2, child: const TipLibraryScreen()),
      );
      await tester.pumpAndSettle();
      final firstArticle = find.text(
        ru ? 'Тарелка с продолжением' : 'A plate with room to grow',
      );
      await tester.scrollUntilVisible(
        firstArticle,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(firstArticle);
      await tester.pumpAndSettle();
      await tester.tap(firstArticle);
      await tester.pumpAndSettle();
      expect(find.byType(TipReadingScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tipSource-cdc-eating')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('insights open existing graphs on a themed page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      app(dark: true, scale: 1, child: const WeightInsightsScreen()),
    );
    await tester.pumpAndSettle();
    final link = find.byKey(const ValueKey('openInsightGraph'));
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.byType(WeightScreen), findsOneWidget);
    final graphContext = tester.element(find.byType(WeightScreen));
    final scaffold = graphContext.findAncestorWidgetOfExactType<Scaffold>()!;
    expect(scaffold.backgroundColor, AppColors.darkTheme.page);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a library-only favorite appears without creating a daily history visit',
    (tester) async {
      const id = 'meal-breakfast';
      final historyCount = data.dailyTips.history.length;
      await tester.runAsync(() => data.toggleSavedTip(id));
      await tester.pumpWidget(
        app(
          dark: false,
          scale: 1,
          child: const DailyTipsHistoryScreen(savedOnly: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Завтрак из доступных продуктов'), findsOneWidget);
      expect(find.textContaining('Из библиотеки'), findsOneWidget);
      await tester.tap(find.text('Завтрак из доступных продуктов'));
      await tester.pumpAndSettle();
      expect(find.byType(DailyTipCard), findsOneWidget);
      expect(data.dailyTips.history.length, historyCount);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'save, explicit task completion, history and saved detail persist',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(414, 896));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(dark: false, scale: 1));
      await tester.pumpAndSettle();
      final tip = data.dailyTips.currentTip!;
      expect(data.dailyTips.currentVisit!.completed, isFalse);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(ValueKey('saveTip-${tip.id}')));
        await data.dailyTips.pending;
      });
      await tester.pumpAndSettle();
      expect(data.dailyTips.saved, contains(tip.id));
      expect(data.dailyTips.currentVisit!.completed, isFalse);
      await tester.tap(find.byKey(ValueKey('tryTip-${tip.id}')));
      await tester.pumpAndSettle();
      expect(data.dailyTips.currentVisit!.completed, isFalse);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('completeTip-2026-10-15')));
        await data.dailyTips.pending;
      });
      await tester.pumpAndSettle();
      expect(data.dailyTips.currentVisit!.completed, isTrue);
      await tester.ensureVisible(find.byKey(const ValueKey('savedTips')));
      await tester.tap(find.byKey(const ValueKey('savedTips')));
      await tester.pumpAndSettle();
      expect(find.byType(DailyTipsHistoryScreen), findsOneWidget);
      expect(find.text(tip.ru.title), findsOneWidget);
      await tester.tap(find.text(tip.ru.title));
      await tester.pumpAndSettle();
      expect(find.byType(DailyTipCard), findsOneWidget);
      expect(find.text(tip.ru.task!), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
