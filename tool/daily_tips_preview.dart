// Isolated simulator preview; all records below are synthetic.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/body_measurement.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/root_shell.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/common.dart';

Future<void> main() async {
  late SettingsProvider settings;
  late AppDataProvider data;
  var baseline = <(DateTime, double)>[];
  var baselineBody = <(BodyMeasurementType, DateTime, double)>[];
  var largeText = false;
  var reduceMotion = false;
  void Function()? rebuild;

  enableFlutterDriverExtension(
    handler: (message) async {
      if (message == 'dark') await settings.setTheme(AppThemeMode.dark);
      if (message == 'light') await settings.setTheme(AppThemeMode.wellness);
      if (message == 'ru') await settings.setLang(AppLang.ru);
      if (message == 'en') await settings.setLang(AppLang.en);
      if ([
        'sparse',
        'restore',
        'sparse-all',
        'single',
        'empty',
        'restore-all',
      ].contains(message)) {
        for (final entry in data.weightHistory.toList()) {
          await data.deleteWeightEntry(entry.id);
        }
        final records = message == 'restore' || message == 'restore-all'
            ? baseline
            : message == 'empty'
            ? <(DateTime, double)>[]
            : [
                if (message != 'single') (DateTime(2026, 10, 14, 8), 76.6),
                (DateTime(2026, 10, 15, 8), 76.5),
              ];
        for (final entry in records) {
          await data.addWeightEntry(entry.$2, date: entry.$1);
        }
      }
      if (['sparse-all', 'single', 'empty', 'restore-all'].contains(message)) {
        for (final entry in data.bodyMeasurements.toList()) {
          await data.deleteBodyMeasurement(entry.id);
        }
        final records = message == 'restore-all'
            ? baselineBody
            : [
                if (message != 'empty')
                  for (final type in BodyMeasurementType.values)
                    for (final day in [if (message != 'single') 14, 15])
                      (
                        type,
                        DateTime(2026, 10, day, 9),
                        (switch (type) {
                              BodyMeasurementType.chest => 92.3,
                              BodyMeasurementType.waist => 74.5,
                              BodyMeasurementType.hips => 99.1,
                            }) +
                            (15 - day) * .1,
                      ),
              ];
        for (final entry in records) {
          await data.addBodyMeasurement(
            type: entry.$1,
            cm: entry.$3,
            date: entry.$2,
          );
        }
      }
      if (message == 'large') {
        largeText = true;
        reduceMotion = true;
        rebuild?.call();
      }
      if (message == 'close') {
        for (final entry in data.bodyMeasurements.toList()) {
          await data.deleteBodyMeasurement(entry.id);
        }
        for (var day = 1; day <= 15; day += 2) {
          for (final type in BodyMeasurementType.values) {
            await data.addBodyMeasurement(
              type: type,
              cm:
                  94 -
                  day * .035 +
                  (type == BodyMeasurementType.hips ? .35 : 0),
              date: DateTime(2026, 10, day, 9),
            );
          }
        }
      }
      if (message == 'tip') return data.dailyTips.currentTip!.id;
      return 'OK';
    },
  );
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  await initializeDateFormatting('en');
  final directory = await Directory.systemTemp.createTemp(
    'balance_tips_preview_',
  );
  Hive.init(directory.path);
  var now = DateTime(2026, 10, 9, 12);
  data = AppDataProvider(
    now: () => now,
    userBox: await Hive.openBox<dynamic>('preview_user'),
    foodBox: await Hive.openBox<dynamic>('preview_food'),
    weightBox: await Hive.openBox<dynamic>('preview_weight'),
  );
  await data.load();
  await data.updateProfile(
    UserProfile(
      name: 'Balance',
      weightKg: 78.5,
      targetWeightKg: 73,
      onboarded: true,
      joinedAt: DateTime(2026, 9, 18),
    ),
  );
  for (var day = 10; day <= 15; day++) {
    now = DateTime(2026, 10, day, 12);
    data.refreshForCurrentDay();
    await data.dailyTips.pending;
  }
  for (var index = 0; index < 10; index++) {
    final date = DateTime(2026, 9, 20 + index * 3, 8, 30);
    final variation = [
      0.0,
      .1,
      -.08,
      .12,
      -.04,
      .08,
      -.05,
      .1,
      -.06,
      0.0,
    ][index];
    await data.addWeightEntry(78.4 - index * .18 + variation, date: date);
    await data.addBodyMeasurement(
      type: BodyMeasurementType.chest,
      cm: 94 - index * .16 + variation,
      date: date.add(const Duration(hours: 1)),
    );
    await data.addBodyMeasurement(
      type: BodyMeasurementType.waist,
      cm: 76 - index * .14 + variation,
      date: date.add(const Duration(hours: 1, minutes: 5)),
    );
    await data.addBodyMeasurement(
      type: BodyMeasurementType.hips,
      cm: 101 - index * .2 + variation,
      date: date.add(const Duration(hours: 1, minutes: 10)),
    );
  }
  await data.addWeightEntry(76.5, date: DateTime(2026, 10, 15, 8, 30));
  await data.addBodyMeasurement(
    type: BodyMeasurementType.chest,
    cm: 92.3,
    date: DateTime(2026, 10, 15, 9, 30),
  );
  await data.addBodyMeasurement(
    type: BodyMeasurementType.waist,
    cm: 74.5,
    date: DateTime(2026, 10, 15, 9, 35),
  );
  await data.addBodyMeasurement(
    type: BodyMeasurementType.hips,
    cm: 99.1,
    date: DateTime(2026, 10, 15, 9, 40),
  );
  baseline = [for (final entry in data.weightHistory) (entry.date, entry.kg)];
  baselineBody = [
    for (final entry in data.bodyMeasurements)
      (entry.type, entry.date, entry.cm),
  ];
  settings = SettingsProvider();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: data),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final c = AppColors.of(settings.themeMode);
          return AppColorsScope(
            colors: c,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                brightness: c.brightness,
                scaffoldBackgroundColor: c.surface,
                fontFamily: 'Inter',
                colorScheme: ColorScheme.fromSeed(
                  seedColor: c.accent,
                  brightness: c.brightness,
                  surface: c.surface,
                ),
              ),
              builder: (context, child) => StatefulBuilder(
                builder: (context, setState) {
                  rebuild = () => setState(() {});
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(largeText ? 1.5 : 1),
                      disableAnimations: reduceMotion,
                    ),
                    child: child!,
                  );
                },
              ),
              home: const RootShell(),
            ),
          );
        },
      ),
    ),
  );
}
