import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'services/local_autosave_service.dart';
import 'services/sqlite_product_cache.dart';
import 'services/dish_catalog_repository.dart';
import 'models/reminder_models.dart';
import 'providers/app_data_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_shell.dart';
import 'widgets/keyboard_dismiss_region.dart';
import 'widgets/premium_motion.dart';
import 'widgets/realistic_water.dart';
import 'services/local_store.dart';
import 'services/balance_notification_service.dart';
import 'theme/app_colors.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  await initializeDateFormatting('en');
  runApp(const BalanceApp());
}

class BalanceApp extends StatefulWidget {
  const BalanceApp({super.key});

  @override
  State<BalanceApp> createState() => _BalanceAppState();
}

class _BalanceAppState extends State<BalanceApp> with WidgetsBindingObserver {
  late final SettingsProvider _settings;
  late final AppDataProvider _data;
  bool _ready = false;
  bool _bootstrapping = false;
  BackupCoordinator? _autosave;
  String? _bootError;
  Timer? _reminderDebounce;
  Timer? _dayRolloverTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = SettingsProvider();
    _data = AppDataProvider();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapping) return;
    _bootstrapping = true;
    try {
      await LocalStore.init();
      await _settings.load();
      await _data.load();
      _autosave?.dispose();
      final boxes = {
        for (final name in [
          LocalStore.userBox,
          LocalStore.foodBox,
          LocalStore.weightBox,
          LocalStore.achievementsBox,
        ])
          name: Hive.box<dynamic>(name),
      };
      _autosave = BackupCoordinator(
        directory: Directory(
          '${File(boxes[LocalStore.userBox]!.path!).parent.path}/balance_backups',
        ),
        boxes: boxes,
        appVersion: const String.fromEnvironment(
          'BALANCE_APP_VERSION',
          defaultValue: '1.0.0+17',
        ),
        readExtras: () async => {
          'settings': _settings.exportSettings(),
          ...await SqliteProductCache.readUserBackup(),
          'dishUserState': await DishCatalogRepository.readUserBackup(),
        },
      )..start();
      _settings.removeListener(_settingsCommitted);
      _settings.addListener(_settingsCommitted);
      SqliteProductCache.onUserMutation = _settingsCommitted;
      DishCatalogRepository.onUserMutation = _settingsCommitted;
      await preloadBalanceActivitySprites().timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
      try {
        await preloadWaterMaterial();
      } catch (_) {
        // The water widget retains its deterministic painter fallback.
      }
      await BalanceNotificationService.instance.initialize();
      final permission = await BalanceNotificationService.instance
          .permissionState();
      final storedPermission = _data.reminderSettings.permission;
      final permissionIsKnown =
          permission == NotificationPermissionState.authorized ||
          permission == NotificationPermissionState.provisional ||
          (storedPermission != NotificationPermissionState.notDetermined &&
              permission != NotificationPermissionState.notDetermined);
      if (permissionIsKnown && permission != storedPermission) {
        await _data.setNotificationPermission(permission);
      }
      _data.addListener(_queueReminderSync);
      _queueReminderSync();
      _scheduleDayRollover();
      if (mounted) setState(() => _ready = true);
    } catch (e, st) {
      _autosave?.dispose();
      _autosave = null;
      if (kDebugMode) debugPrint('Bootstrap failed: $e\n$st');
      if (mounted) {
        setState(
          () => _bootError = 'Локальные данные недоступны. Повторите попытку.',
        );
      }
    } finally {
      _bootstrapping = false;
    }
  }

  void _settingsCommitted() => _autosave?.markDirty();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _ready) {
      _autosave?.resume();
      _data.refreshForCurrentDay();
      _data.refreshSteps();
      _queueReminderSync();
      _scheduleDayRollover();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_autosave?.pause());
      _dayRolloverTimer?.cancel();
      _reminderDebounce?.cancel();
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reminderDebounce?.cancel();
    _dayRolloverTimer?.cancel();
    _data.removeListener(_queueReminderSync);
    _settings.removeListener(_settingsCommitted);
    SqliteProductCache.onUserMutation = null;
    DishCatalogRepository.onUserMutation = null;
    _autosave?.dispose();
    _settings.dispose();
    _data.dispose();
    super.dispose();
  }

  void _queueReminderSync() {
    _reminderDebounce?.cancel();
    _reminderDebounce = Timer(const Duration(milliseconds: 450), () {
      final settings = _data.reminderSettings;
      unawaited(
        BalanceNotificationService.instance.reconcile(
          settings: settings,
          manual: _data.manualReminders,
          smart: _data.smartReminderPlan(),
        ),
      );
    });
  }

  void _scheduleDayRollover() {
    _dayRolloverTimer?.cancel();
    final now = DateTime.now();
    final untilMidnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ).difference(now);
    // Recheck the civil clock while foregrounded after a timezone/clock change.
    _dayRolloverTimer = Timer(
      untilMidnight < const Duration(minutes: 1)
          ? untilMidnight
          : const Duration(minutes: 1),
      () {
        if (!mounted) return;
        _data.refreshForCurrentDay();
        _scheduleDayRollover();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bootError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFECE4D3),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Не удалось запустить приложение',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _bootError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _bootError = null;
                        _ready = false;
                      });
                      _bootstrap();
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFFECE4D3),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _settings),
        ChangeNotifierProvider.value(value: _data),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final colors = AppColors.of(
            settings.themeMode,
            platformBrightness:
                WidgetsBinding.instance.platformDispatcher.platformBrightness,
          );
          return AppColorsScope(
            colors: colors,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Balance',
              theme: _buildThemeData(colors),
              themeAnimationDuration: const Duration(milliseconds: 420),
              themeAnimationCurve: Curves.easeOutCubic,
              builder: (context, child) => KeyboardDismissRegion(
                child: child ?? const SizedBox.shrink(),
              ),
              home: _data.profile.onboarded
                  ? const RootShell()
                  : OnboardingScreen(onDone: () => setState(() {})),
            ),
          );
        },
      ),
    );
  }

  ThemeData _buildThemeData(AppColors c) {
    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      scaffoldBackgroundColor: c.surface,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Inter'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: c.brightness,
        surface: c.surface,
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: c.accent),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: c.fg.withValues(alpha: .28),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerColor: c.line,
      splashFactory: NoSplash.splashFactory,
    );
  }
}
