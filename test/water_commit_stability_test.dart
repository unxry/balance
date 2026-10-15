import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_app/providers/app_data_provider.dart';
import 'package:flutter_app/services/water_save_trace.dart';

void main() {
  test('water commit profile and durable reopen', () async {
    final directory = await Directory.systemTemp.createTemp('water_commit_');
    Hive.init(directory.path);
    final user = await Hive.openBox<dynamic>('profile_user');
    final food = await Hive.openBox<dynamic>('profile_food');
    final weight = await Hive.openBox<dynamic>('profile_weight');
    final data = AppDataProvider(
      userBox: user,
      foodBox: food,
      weightBox: weight,
    );
    await data.load();
    final trace = WaterSaveTrace();
    expect(await data.addWater(.25), isTrue);
    expect(data.waterLiters, .25);
    final result = Map<String, int>.of(trace.microseconds);
    data.dispose();
    await user.close();
    final reopened = await Hive.openBox<dynamic>('profile_user');
    expect((reopened.get('waterHistory') as Map).values, contains(.25));
    // ignore: avoid_print
    print('WATER_PROFILE ${jsonEncode(result)}');
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test(
    'pending primary write does not publish water and concurrent adds serialize',
    () async {
      final directory = await Directory.systemTemp.createTemp('water_serial_');
      Hive.init(directory.path);
      final user = await Hive.openBox<dynamic>('serial_user');
      final food = await Hive.openBox<dynamic>('serial_food');
      final weight = await Hive.openBox<dynamic>('serial_weight');
      final gate = Completer<void>();
      final writes = <double>[];
      final data = AppDataProvider(
        userBox: user,
        foodBox: food,
        weightBox: weight,
        waterWriter: (liters, key) async {
          writes.add(liters);
          if (writes.length == 1) await gate.future;
        },
      );
      await data.load();
      final key = data.dashboardDay().dateKey;
      final first = data.addWaterForDate(.25, key);
      final second = data.addWaterForDate(.15, key);
      await Future<void>.delayed(Duration.zero);
      expect(data.waterLiters, 0);
      expect(writes, [.25]);
      gate.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(writes, [.25, .4]);
      expect(data.waterLiters, .4);
      data.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    },
  );
}
