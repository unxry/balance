import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/dashboard_screen.dart';
import 'package:flutter_app/screens/root_shell.dart';
import 'package:flutter_app/services/health_service.dart';
import 'package:flutter_app/widgets/realistic_water.dart';
import 'package:flutter_app/widgets/tab_bar_pill.dart';
import 'package:flutter_app/widgets/common.dart';

class _NotDeterminedHealth extends HealthService {
  @override
  Future<StepAccessState> getStatus() async => StepAccessState.notDetermined;
}

class _ControlledWaterProvider extends AppDataProvider {
  _ControlledWaterProvider({
    required super.now,
    required super.userBox,
    required super.foodBox,
    required super.weightBox,
    required super.healthService,
    required super.waterWriter,
  });

  bool failNextAdd = false;

  @override
  Future<bool> addWaterForDate(double liters, String dateKey) {
    if (failNextAdd) {
      failNextAdd = false;
      return Future.value(false);
    }
    return super.addWaterForDate(liters, dateKey);
  }
}

void main() {
  late Directory directory;
  late Box<dynamic> userBox;
  late Box<dynamic> foodBox;
  late Box<dynamic> weightBox;

  setUpAll(() async {
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
    directory = await Directory.systemTemp.createTemp(
      'balance_water_feedback_',
    );
    Hive.init(directory.path);
    userBox = await Hive.openBox<dynamic>('water_feedback_user');
    foodBox = await Hive.openBox<dynamic>('water_feedback_food');
    weightBox = await Hive.openBox<dynamic>('water_feedback_weight');
  });

  tearDownAll(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  testWidgets(
    'water feedback updates inline, replaces rapid adds, resets, and retries',
    (tester) async {
      final data = _ControlledWaterProvider(
        now: () => DateTime(2026, 9, 4, 12),
        userBox: userBox,
        foodBox: foodBox,
        weightBox: weightBox,
        healthService: _NotDeterminedHealth(),
        waterWriter: (_, _) => Future.value(),
      );
      await data.load();
      addTearDown(() async {
        data.dispose();
      });

      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppDataProvider>.value(value: data),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: const MaterialApp(home: RootShell()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));
      debugDashboardWaterTransitionEvents.clear();

      await tester.ensureVisible(find.text('ВОДА'));
      await tester.pump();
      final dateKey = data.dashboardDay().dateKey;
      final cardFinder = find.byKey(ValueKey('dashboardWaterCard-$dateKey'));
      final layerFinder = find.byKey(ValueKey('dashboardWaterLayer-$dateKey'));
      final cardElementBefore = tester.element(cardFinder);
      final waterStateBefore = tester.state(layerFinder);
      final controllerBefore =
          (waterStateBefore as dynamic).debugLevelControllerIdentity as Object;
      final scrollableFinder = find.ancestor(
        of: cardFinder,
        matching: find.byType(Scrollable),
      );

      Future<void> openWaterSheet() async {
        if (find.text('НОВОЕ ДОСТИЖЕНИЕ').evaluate().isNotEmpty) {
          await tester.tapAt(const Offset(6, 6));
          await tester.pump(const Duration(milliseconds: 900));
        }
        await tester.ensureVisible(find.text('ВОДА'));
        await tester.pump(const Duration(milliseconds: 900));
        await tester.tap(find.text('ВОДА'));
        await tester.pump(const Duration(milliseconds: 900));
        await tester.ensureVisible(
          find.byKey(const ValueKey('addWaterButton')),
        );
        await tester.pump(const Duration(milliseconds: 900));
      }

      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pump();
      await tester.ensureVisible(find.text('ВОДА'));
      await tester.pump(const Duration(milliseconds: 900));
      final cardRectBefore = tester.getRect(cardFinder);
      final scrollBefore = tester
          .state<ScrollableState>(scrollableFinder.first)
          .position
          .pixels;
      final navigationFinder = find.byType(TabBarPill);
      final navigationElementBefore = tester.element(navigationFinder);
      final navigationRectBefore = tester.getRect(navigationFinder);
      await openWaterSheet();

      int previewValue() => int.parse(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('waterAmountPreview')),
                matching: find.byType(Text),
              ),
            )
            .data!,
      );

      int mainValue() => int.parse(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('waterModalAmount')),
                matching: find.byType(Text),
              ),
            )
            .data!
            .split(' ')
            .first,
      );

      final sheetRect = tester.getRect(
        find.byKey(const ValueKey('waterSheetFixedGeometry')),
      );
      final buttonRect = tester.getRect(
        find.byKey(const ValueKey('addWaterButton')),
      );
      final fieldRect = tester.getRect(find.byType(TextField));

      await tester.tap(find.text('150 мл'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(previewValue(), inExclusiveRange(150, 250));
      expect(mainValue(), inExclusiveRange(150, 250));
      await tester.pump(const Duration(milliseconds: 260));
      expect(previewValue(), 150);
      expect(mainValue(), 150);

      await tester.tap(find.text('350 мл'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(previewValue(), inExclusiveRange(150, 350));
      await tester.pump(const Duration(milliseconds: 350));
      expect(previewValue(), 350);

      await tester.tap(find.text('250 мл'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(previewValue(), inExclusiveRange(250, 350));
      await tester.pump(const Duration(milliseconds: 260));
      expect(previewValue(), 250);

      await tester.enterText(find.byType(TextField), '420');
      await tester.pump();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      final caretBefore = editable.controller.selection;
      await tester.pump(const Duration(milliseconds: 200));
      expect(previewValue(), inExclusiveRange(250, 420));
      expect(editable.controller.selection, caretBefore);
      await tester.pump(const Duration(milliseconds: 350));
      expect(previewValue(), 420);

      await tester.tap(find.text('250 мл'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.tap(find.byKey(const ValueKey('addWaterButton')));
      await tester.pump();
      expect(find.text('Сохраняем…'), findsNothing);
      expect(
        tester.getRect(find.byKey(const ValueKey('waterSheetFixedGeometry'))),
        sheetRect,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('addWaterButton'))),
        buttonRect,
      );
      expect(tester.getRect(find.byType(TextField)), fieldRect);
      await tester.pump();
      expect(data.waterLiters, closeTo(0.25, 0.001));
      expect(
        tester
            .widget<RealisticWaterLayer>(
              find.byKey(
                ValueKey('dashboardWaterLayer-${data.dashboardDay().dateKey}'),
              ),
            )
            .valueMl,
        250,
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 50));

      expect(data.waterLiters, closeTo(0.25, 0.001));
      expect(
        tester
            .widget<RealisticWaterLayer>(
              find.byKey(
                ValueKey('dashboardWaterLayer-${data.dashboardDay().dateKey}'),
              ),
            )
            .valueMl,
        250,
      );
      expect(find.text('✓ +250 мл'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      final firstFade = tester.widget<FadeTransition>(
        find.byKey(const ValueKey('waterSuccessFade')),
      );
      expect(firstFade.opacity.value, greaterThan(0));
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.element(cardFinder), same(cardElementBefore));
      expect(tester.state(layerFinder), same(waterStateBefore));
      expect(
        (tester.state(layerFinder) as dynamic).debugLevelControllerIdentity,
        same(controllerBefore),
      );
      expect(tester.getRect(cardFinder), cardRectBefore);
      expect(
        tester.state<ScrollableState>(scrollableFinder.first).position.pixels,
        scrollBefore,
      );
      expect(tester.element(navigationFinder), same(navigationElementBefore));
      expect(tester.getRect(navigationFinder), navigationRectBefore);
      expect(
        debugDashboardWaterTransitionEvents.map((event) => event.name),
        containsAllInOrder(const [
          'persisted',
          'routeDismissed',
          'displayRetarget',
        ]),
      );

      // Reopen before the first feedback would normally finish. The same
      // indicator is restarted with the latest amount; no message is queued.
      await openWaterSheet();
      expect(find.text('Добавить 250 мл'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('addWaterButton')));
      await tester.tap(find.byKey(const ValueKey('addWaterButton')));
      await tester.pump();
      tester.testTextInput.hide();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 50));
      expect(data.waterLiters, closeTo(0.5, 0.001));
      expect(find.text('✓ +250 мл'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      await openWaterSheet();
      await tester.ensureVisible(find.text('Сбросить воду'));
      await tester.tap(find.text('Сбросить воду'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Сбросить'));
      await tester.pump();
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Сбросить'))
          .onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));
      expect(data.waterLiters, 0);
      expect(find.text('✓ сброшено'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      // Check the custom error state on a modern iPhone surface with the real
      // bottom navigation present.
      data.failNextAdd = true;
      await openWaterSheet();
      await tester.tap(find.byKey(const ValueKey('addWaterButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Не удалось сохранить воду. Попробуйте ещё раз.'),
        findsOneWidget,
      );
      expect(find.text('Добавить воду'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '250',
      );
      expect(find.byType(SnackBar), findsNothing);
      await tester.tap(find.byKey(const ValueKey('addWaterButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(data.waterLiters, closeTo(0.25, 0.001));
      expect(find.text('✓ +250 мл'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'keyboard keeps amount input and action visible, raw typing and double save',
    (tester) async {
      final boxes = (await tester.runAsync(
        () async => [
          await Hive.openBox<dynamic>('keyboard_user'),
          await Hive.openBox<dynamic>('keyboard_food'),
          await Hive.openBox<dynamic>('keyboard_weight'),
        ],
      ))!;
      final gate = Completer<void>();
      var writes = 0;
      final data = _ControlledWaterProvider(
        now: () => DateTime(2026, 9, 4, 12),
        userBox: boxes[0],
        foodBox: boxes[1],
        weightBox: boxes[2],
        healthService: _NotDeterminedHealth(),
        waterWriter: (_, _) async {
          writes++;
          await gate.future;
        },
      );
      await tester.runAsync(data.load);
      addTearDown(data.dispose);
      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppDataProvider>.value(value: data),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: const MaterialApp(home: RootShell()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));
      if (find.text('НОВОЕ ДОСТИЖЕНИЕ').evaluate().isNotEmpty) {
        await tester.tapAt(const Offset(6, 6));
        await tester.pump(const Duration(milliseconds: 900));
      }
      await tester.ensureVisible(find.text('ВОДА'));
      await tester.tap(find.text('ВОДА'));
      await tester.pump(const Duration(milliseconds: 400));
      tester.view.viewInsets = FakeViewPadding(
        bottom: 300 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      for (final key in ['waterModalAmount', 'addWaterButton']) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(rect.bottom, lessThanOrEqualTo(367));
        expect(rect.top, greaterThanOrEqualTo(0));
      }
      expect(
        tester.getRect(find.byType(TextField)).bottom,
        lessThanOrEqualTo(367),
      );
      for (final text in ['2', '25', '250']) {
        await tester.enterText(find.byType(TextField), text);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          text,
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('250 мл'), findsOneWidget);
      final button = tester.widget<PrimaryButton>(
        find.byKey(const ValueKey('addWaterButton')),
      );
      button.onTap!();
      for (var i = 0; i < 10; i++) {
        button.onTap!();
      }
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(writes, 1);
      expect(data.waterLiters, 0);
      expect(find.text('Сохраняем…'), findsNothing);
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.text('Сохраняем…'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Добавить воду'), findsOneWidget);
      expect(writes, 1);
      gate.complete();
      await tester.pump();
      button.onTap!();
      await tester.pump();
      expect(writes, 1);
      await tester.pump(const Duration(milliseconds: 400));
      expect(data.waterLiters, .25);
      expect(find.text('Добавить воду'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    },
  );
}
