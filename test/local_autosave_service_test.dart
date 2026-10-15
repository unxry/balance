import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_app/services/local_autosave_service.dart';
import 'package:flutter_app/services/local_backup_service.dart';
import 'package:flutter_app/services/local_store.dart';

void main() {
  test(
    'debounce, paused coalescing, truncated temp, retention and restart health',
    () async {
      final root = await Directory.systemTemp.createTemp('backup_failures_');
      Hive.init(root.path);
      final user = await Hive.openBox<dynamic>(LocalStore.userBox);
      var now = DateTime(2026, 10, 3, 12);
      var truncate = false;
      Completer<void>? gate;
      final service = BackupCoordinator(
        directory: Directory('${root.path}/snapshots'),
        boxes: {LocalStore.userBox: user},
        appVersion: '1.0.0+16',
        now: () => now,
        debounce: const Duration(milliseconds: 30),
        readExtras: () async {
          await gate?.future;
          return {'settings': <String, dynamic>{}};
        },
        beforeValidate: (temporary) async {
          if (truncate) await temporary.writeAsString('{', flush: true);
        },
      )..start();
      try {
        service.start();
        for (var i = 0; i < 10; i++) {
          await user.put('counter', i);
        }
        expect(service.isDirty, isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 180));
        await service.flush();
        expect(service.rollingWrites, 1);
        final latest = File('${root.path}/snapshots/latest.json');
        final previous = await latest.readAsString();
        truncate = true;
        await user.put('counter', 10);
        await service.flush();
        expect(service.lastError, isNotNull);
        expect(await latest.readAsString(), previous);
        truncate = false;
        gate = Completer<void>();
        final firstPause = service.pause();
        final secondPause = service.pause();
        gate.complete();
        await Future.wait([firstPause, secondPause]);
        expect(service.rollingWrites, 2);
        expect(service.isDirty, isFalse);
        gate = null;
        for (var i = 1; i < 18; i++) {
          now = DateTime(2026, 10, 3 + i, 12);
          service.resume();
          await user.put('counter', i + 10);
          await service.flush();
        }
        final files = await service.directory.list().toList();
        expect(files.where((f) => f.path.contains('/daily-')).length, 14);
        expect(files.where((f) => f.path.contains('/mutation-')).length, 3);
        expect(files.where((f) => f.path.endsWith('.pending')), isEmpty);
        for (final file in files.whereType<File>().where(
          (f) => !f.path.endsWith('metadata.json'),
        )) {
          const LocalBackupService().inspectJson(await file.readAsString());
        }
        service.dispose();
        final restarted = BackupCoordinator(
          directory: service.directory,
          boxes: {LocalStore.userBox: user},
          appVersion: '1.0.0+16',
          now: () => now,
          readExtras: () async => {},
        )..start();
        try {
          await restarted.flush();
          expect(restarted.latestMetadata?['dailyDate'], '2026-10-20');
          expect(restarted.dailyWrites, 0);
        } finally {
          restarted.dispose();
        }
      } finally {
        service.dispose();
        await Hive.close();
        await root.delete(recursive: true);
      }
    },
  );
  test(
    'coalesced rolling, one daily per date, atomic retry and durable canonical data',
    () async {
      final root = await Directory.systemTemp.createTemp('autosave_test_');
      Hive.init(root.path);
      final user = await Hive.openBox<dynamic>(LocalStore.userBox);
      var now = DateTime(2026, 10, 3, 12);
      var fail = false;
      var reads = 0;
      final service = LocalAutosaveService(
        directory: Directory('${root.path}/snapshots'),
        boxes: {LocalStore.userBox: user},
        appVersion: '1.0.0+17',
        now: () => now,
        debounce: const Duration(milliseconds: 30),
        readExtras: () async {
          reads++;
          if (fail) throw const FileSystemException('test failure');
          return {
            'settings': {'language': 'ru'},
            'catalogFavorites': ['favorite'],
            'catalogRetailerRelations': <dynamic>[],
          };
        },
      )..start();
      try {
        await user.put('waterHistory', {'2026-10-03': .25});
        await user.put('profile', {'name': 'preserved'});
        await user.put('recipes', ['recipe']);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        expect(service.rollingWrites, 0);
        await service.flush();
        expect(service.rollingWrites, 1);
        expect(service.dailyWrites, 1);
        final latest = File('${root.path}/snapshots/latest.json');
        final first = await latest.readAsString();
        final inspection = const LocalBackupService().inspectJson(first);
        expect(inspection.recordCounts[LocalStore.userBox], 3);
        expect(inspection.productFavoriteCount, 1);
        expect(jsonDecode(first)['appVersion'], '1.0.0+17');
        now = DateTime(2026, 10, 4, 12);
        service.resume();
        await user.put('waterHistory', {'2026-10-03': .25, '2026-10-04': .15});
        await service.flush();
        expect(service.dailyWrites, 2);
        for (var i = 0; i < 20; i++) {
          await user.put('counter', i);
        }
        await service.flush();
        expect(service.dailyWrites, 2);
        expect(service.rollingWrites, 3);
        final previous = await latest.readAsString();
        fail = true;
        await user.put('counter', 21);
        await service.flush();
        expect(service.lastError, isNotNull);
        expect(await latest.readAsString(), previous);
        expect(user.get('counter'), 21);
        fail = false;
        await service.flush();
        expect(service.lastError, isNull);
        expect(service.rollingWrites, 4);
        expect(
          (await service.directory.list().toList()).whereType<File>().where(
            (file) => file.path.endsWith('.pending'),
          ),
          isEmpty,
        );
        expect(reads, 5);
      } finally {
        service.dispose();
        await Hive.close();
        await root.delete(recursive: true);
      }
    },
  );
}
