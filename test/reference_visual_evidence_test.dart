import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/models/food_product.dart';
import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/models/recipe_models.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/add_food_screen.dart';
import 'package:flutter_app/screens/advice_screen.dart';
import 'package:flutter_app/screens/dashboard_screen.dart';
import 'package:flutter_app/screens/diary_screen.dart';
import 'package:flutter_app/screens/my_recipes_screen.dart';
import 'package:flutter_app/screens/legal_screen.dart';
import 'package:flutter_app/screens/profile_screen.dart';
import 'package:flutter_app/screens/root_shell.dart';
import 'package:flutter_app/screens/steps_screen.dart';
import 'package:flutter_app/screens/weight_screen.dart';
import 'package:flutter_app/services/food_catalog_repository.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/theme/i18n.dart';
import 'package:flutter_app/widgets/common.dart';
import 'package:flutter_app/widgets/premium_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box<dynamic> userBox;
  late Box<dynamic> foodBox;
  late Box<dynamic> weightBox;
  late AppDataProvider data;
  late ui.FragmentProgram waterMaterialProgram;
  var sequence = 0;

  setUpAll(() async {
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
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
    waterMaterialProgram = await ui.FragmentProgram.fromAsset(
      'shaders/water_material.frag',
    );
    directory = await Directory.systemTemp.createTemp('balance_visual_');
    Hive.init(directory.path);
  });

  setUp(() async {
    sequence++;
    userBox = await Hive.openBox<dynamic>('visual_user_$sequence');
    foodBox = await Hive.openBox<dynamic>('visual_food_$sequence');
    weightBox = await Hive.openBox<dynamic>('visual_weight_$sequence');
    data = AppDataProvider(
      now: () => DateTime(2026, 9, 9, 12),
      userBox: userBox,
      foodBox: foodBox,
      weightBox: weightBox,
      waterWriter: (_, _) => Future.value(),
    );
    await data.load();
    await data.updateProfile(
      UserProfile(
        name: 'Александра',
        weightKg: 80.6,
        targetWeightKg: 72,
        joinedAt: DateTime(2026, 8, 28),
        onboarded: true,
      ),
    );
    for (var i = 0; i < 7; i++) {
      final date = DateTime(2026, 9, 3 + i);
      await data.addWeightEntry(80.4 - i * .25, date: date);
      await data.addFoodForDate(
        FoodEntry(
          id: 'visual-$i',
          name: 'Овсянка с ягодами',
          grams: 180,
          kcal: 240,
          proteinG: 8,
          fatG: 6,
          carbsG: 38,
          meal: MealType.breakfast,
          time: date,
        ),
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      );
    }
  });

  tearDown(() => data.dispose());
  tearDownAll(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  Widget app(
    Widget child,
    String key, {
    AppColors colors = AppColors.wellness,
  }) => AppColorsScope(
    colors: colors,
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: data),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        key: ValueKey('golden-$key'),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: colors.brightness,
          useMaterial3: true,
          scaffoldBackgroundColor: colors.surface,
          fontFamily: 'Inter',
          fontFamilyFallback: const ['Inter'],
          colorScheme: ColorScheme.fromSeed(
            seedColor: colors.accent,
            brightness: colors.brightness,
            surface: colors.surface,
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: colors.accent,
          ),
          cardTheme: CardThemeData(
            color: colors.card,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          bottomSheetTheme: BottomSheetThemeData(
            backgroundColor: colors.surface,
            modalBackgroundColor: colors.surface,
            elevation: 0,
            modalElevation: 0,
            modalBarrierColor: colors.fg.withValues(alpha: .28),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.antiAlias,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: colors.card,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          dividerColor: colors.line,
          splashFactory: NoSplash.splashFactory,
        ),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(body: child),
        ),
      ),
    ),
  );

  Future<void> capture(
    WidgetTester tester,
    Widget child,
    String name, {
    AppColors colors = AppColors.wellness,
  }) async {
    await tester.pumpWidget(app(child, name, colors: colors));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/verification_$name.png'),
    );
  }

  Future<void> configureViewport(WidgetTester tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Future<UserRecipe> createVisualRecipe(WidgetTester tester) async {
    final ingredient = RecipeIngredient(
      id: 'visual-oats',
      nameSnapshot: 'Овсянка',
      amount: 100,
      unit: RecipeUnit.g,
      nutritionSnapshot: const NutritionValues(
        calories: 360,
        protein: 12,
        fat: 6,
        carbs: 60,
      ),
    );
    late UserRecipe recipe;
    await tester.runAsync(() async {
      recipe = await data.createRecipe(
        name: 'Овсянка с ягодами',
        ingredients: [ingredient],
        cookedWeightGrams: 250,
        portions: 2,
      );
    });
    return recipe;
  }

  FoodCatalogRepository visualCatalog() =>
      FoodCatalogRepository(cache: MemoryProductCache(), sources: const []);

  testWidgets('A dashboard golden', (tester) async {
    await configureViewport(tester);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await capture(
      tester,
      DashboardScreen(
        onOpenSteps: () {},
        onOpenWeight: () {},
        onOpenAdvice: () {},
        dashboardMotionPreviewProgress: 0,
      ),
      'a_dashboard',
    );
  });

  testWidgets('A dashboard dark glass cards', (tester) async {
    await configureViewport(tester);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await capture(
      tester,
      DashboardScreen(
        onOpenSteps: () {},
        onOpenWeight: () {},
        onOpenAdvice: () {},
        dashboardMotionPreviewProgress: 0,
      ),
      'a_dashboard_dark_glass',
      colors: AppColors.darkTheme,
    );
  });

  testWidgets('A water production dashboard states', (tester) async {
    await configureViewport(tester);
    await tester.runAsync(preloadBalanceActivitySprites);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final materialShader = waterMaterialProgram.fragmentShader();
    addTearDown(materialShader.dispose);
    for (final state in const [
      (ml: 150, name: 'water_dashboard_150'),
      (ml: 250, name: 'water_dashboard_250'),
      (ml: 1250, name: 'water_dashboard_1250'),
      (ml: 2500, name: 'water_dashboard_2500'),
    ]) {
      await tester.runAsync(() => data.setWater(state.ml / 1000));
      await capture(
        tester,
        DashboardScreen(
          onOpenSteps: () {},
          onOpenWeight: () {},
          onOpenAdvice: () {},
          waterPreviewElapsedSeconds: 8.4,
          waterMaterialPreviewShader: materialShader,
          dashboardMotionPreviewProgress: 0,
        ),
        state.name,
      );
    }
  });

  testWidgets('B weight detail golden', (tester) async {
    await configureViewport(tester);
    await capture(tester, WeightScreen(onBack: () {}), 'b_weight_detail');
  });

  testWidgets('C steps detail golden', (tester) async {
    await configureViewport(tester);
    await capture(tester, StepsScreen(onBack: () {}), 'c_steps_detail');
  });

  testWidgets('D advice detail golden', (tester) async {
    await configureViewport(tester);
    await capture(
      tester,
      const Scaffold(body: AdviceDetailSheet()),
      'd_advice_detail',
    );
  });

  testWidgets('E diary golden', (tester) async {
    await configureViewport(tester);
    await capture(tester, DiaryScreen(onSearch: (_) {}), 'e_diary');
  });

  testWidgets('F add food golden', (tester) async {
    await configureViewport(tester);
    await capture(
      tester,
      AddFoodScreen(
        onBack: () {},
        initialMeal: MealType.breakfast,
        selectedDate: DateTime(2026, 9, 9),
      ),
      'f_add_food',
    );
  });

  testWidgets('G filter sheet golden', (tester) async {
    await configureViewport(tester);
    await tester.pumpWidget(
      app(
        AddFoodScreen(
          onBack: () {},
          initialMeal: MealType.breakfast,
          selectedDate: DateTime(2026, 9, 9),
        ),
        'g_filter_sheet',
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('foodFiltersButton')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(BottomSheet), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/verification_g_filter_sheet.png'),
    );
  });

  testWidgets('H history golden', (tester) async {
    await configureViewport(tester);
    await capture(tester, WeightScreen(onBack: () {}), 'h_history');
  });

  testWidgets('I recipe actions list golden', (tester) async {
    await configureViewport(tester);
    await createVisualRecipe(tester);
    await capture(
      tester,
      MyRecipesScreen(
        catalog: visualCatalog(),
        scannerStrings: const S(AppLang.ru),
      ),
      'i_recipe_actions',
    );
  });

  testWidgets('I recipe action sheet golden', (tester) async {
    await configureViewport(tester);
    final recipe = await createVisualRecipe(tester);
    await tester.pumpWidget(
      app(
        MyRecipesScreen(
          catalog: visualCatalog(),
          scannerStrings: const S(AppLang.ru),
        ),
        'i_recipe_action_sheet',
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final recipeActions = find.byKey(ValueKey('recipeActions-${recipe.id}'));
    await tester.ensureVisible(recipeActions);
    await tester.tap(recipeActions);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Приготовить снова'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/verification_i_recipe_action_sheet.png'),
    );
  });

  testWidgets('J recipe final weight golden', (tester) async {
    await configureViewport(tester);
    final recipe = await createVisualRecipe(tester);
    await tester.pumpWidget(
      app(
        RecipeEditorScreen(
          catalog: visualCatalog(),
          scannerStrings: const S(AppLang.ru),
          recipe: recipe,
        ),
        'j_recipe_final_weight',
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('recipeNextButton')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recipeNextButton')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Вес готового блюда'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/verification_j_recipe_final_weight.png'),
    );
  });

  testWidgets('K glass navigation rest golden', (tester) async {
    await configureViewport(tester);
    await capture(tester, const RootShell(), 'k_glass_nav_rest');
  });

  testWidgets('L character pose sheet golden', (tester) async {
    await configureViewport(tester);
    await tester.runAsync(preloadBalanceActivitySprites);
    await capture(
      tester,
      Scaffold(
        body: GridView.count(
          crossAxisCount: 3,
          padding: const EdgeInsets.all(18),
          childAspectRatio: 1.1,
          children: [
            for (final item in const [
              ('Idle', BalanceActivityPose.idle),
              ('Walk A', BalanceActivityPose.walkContact),
              ('Walk B', BalanceActivityPose.walkDown),
              ('Passing', BalanceActivityPose.walkPassing),
              ('Run A', BalanceActivityPose.runContact),
              ('Run B', BalanceActivityPose.runFlight),
            ])
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.$1),
                  const SizedBox(height: 8),
                  BalanceActivityCharacter(
                    colors: AppColors.wellness,
                    size: 34,
                    travelWidth: 60,
                    previewPose: item.$2,
                  ),
                ],
              ),
          ],
        ),
      ),
      'l_character_pose_sheet',
    );
  });

  testWidgets('M profile settings golden', (tester) async {
    await configureViewport(tester);
    await tester.pumpWidget(
      app(ProfileScreen(onEditGoal: () {}), 'm_profile_settings'),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profileLastSection')),
      700,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/verification_m_profile_settings.png'),
    );
  });

  testWidgets('N legal privacy golden', (tester) async {
    await configureViewport(tester);
    await capture(
      tester,
      LegalScreen(doc: LegalDoc.privacy, onBack: () {}),
      'n_legal_privacy',
    );
  });

  testWidgets('O neutral System dashboard golden', (tester) async {
    await configureViewport(tester);
    await capture(
      tester,
      DashboardScreen(
        onOpenSteps: () {},
        onOpenWeight: () {},
        onOpenAdvice: () {},
        dashboardMotionPreviewProgress: 0,
      ),
      'o_system_dashboard',
      colors: AppColors.systemLight,
    );
  });
}
