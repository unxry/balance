import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:hive/hive.dart';
import 'local_backup_service.dart';
import 'local_store.dart';

typedef LocalAutosaveService = BackupCoordinator;

class BackupCoordinator {
  BackupCoordinator({
    required this.directory,
    required this.boxes,
    required this.readExtras,
    required this.appVersion,
    DateTime Function()? now,
    this.debounce = const Duration(seconds: 2),
    this.beforeValidate,
  }) : _now = now ?? DateTime.now;

  final Directory directory;
  final Map<String, Box<dynamic>> boxes;
  final Future<Map<String, dynamic>> Function() readExtras;
  final String appVersion;
  final DateTime Function() _now;
  final Duration debounce;
  final Future<void> Function(File temporary)? beforeValidate;
  final List<StreamSubscription<BoxEvent>> _subscriptions = [];
  Timer? _timer;
  Timer? _midnightTimer;
  Future<void>? _inFlight;
  int _version = 0;
  int _savedVersion = 0;
  int _failures = 0;
  bool _disposed = false;
  String? _lastDailyDate;
  Map<String, dynamic>? latestMetadata;
  bool _started = false;
  bool _active = true;
  Future<void>? _healthCheck;
  bool get isDirty => _version != _savedVersion;
  Object? lastError;
  int rollingWrites = 0;
  int dailyWrites = 0;

  String get _date {
    final date = _now();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void start() {
    if (_disposed || _started) return;
    _started = true;
    _healthCheck = _checkHealth();
    for (final box in boxes.values) {
      _subscriptions.add(box.watch().listen((_) => markDirty()));
    }
    markDirty();
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = _now();
    _midnightTimer = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (_disposed) return;
        markDirty();
        _scheduleMidnight();
      },
    );
  }

  void markDirty() {
    if (_disposed) return;
    _version++;
    _timer?.cancel();
    if (_active) _timer = Timer(debounce, () => unawaited(flush()));
  }

  void resume() {
    if (_disposed) return;
    _active = true;
    if (_lastDailyDate != _date) markDirty();
    if (isDirty) {
      _timer?.cancel();
      _timer = Timer(debounce, () => unawaited(flush()));
    }
    _scheduleMidnight();
  }

  Future<void> pause() {
    _active = false;
    _midnightTimer?.cancel();
    return flush().timeout(const Duration(seconds: 3), onTimeout: () {});
  }

  Future<void> _checkHealth() async {
    try {
      final index = File('${directory.path}/metadata.json');
      if (!await index.exists()) return;
      final metadata = Map<String, dynamic>.from(
        jsonDecode(await index.readAsString()) as Map,
      );
      final latest = File('${directory.path}/latest.json');
      if (!await latest.exists() || await latest.length() == 0) return;
      latestMetadata = metadata;
      _lastDailyDate = metadata['dailyDate'] as String?;
      final contents = await latest.readAsString();
      await Isolate.run(() => const LocalBackupService().inspectJson(contents));
      final daily = File('${directory.path}/daily-$_lastDailyDate.json');
      if (!await daily.exists()) {
        _lastDailyDate = null;
      } else {
        final contents = await daily.readAsString();
        await Isolate.run(
          () => const LocalBackupService().inspectJson(contents),
        );
      }
    } catch (_) {
      latestMetadata = null;
      _lastDailyDate = null;
    }
  }

  Future<void> flush() {
    if (_disposed) return Future.value();
    _timer?.cancel();
    if (_inFlight != null) return _inFlight!;
    if (_version == _savedVersion && _lastDailyDate == _date) {
      return Future.value();
    }
    final operation = _writeSnapshot();
    _inFlight = operation;
    return operation.whenComplete(() {
      _inFlight = null;
      if (!_disposed && _active && _version != _savedVersion) {
        _timer?.cancel();
        _timer = Timer(
          lastError == null
              ? debounce
              : Duration(seconds: (2 << _failures.clamp(0, 4))),
          () => unawaited(flush()),
        );
      }
    });
  }

  Future<void> _writeSnapshot() async {
    final version = _version;
    final date = _date;
    try {
      await _healthCheck;
      final extras = await readExtras();
      await Future.wait(boxes.values.map((box) => box.flush()));
      final createdAt = _now().toUtc().toIso8601String();
      final snapshot = <String, dynamic>{
        'format': 'balance-local-backup',
        'backupVersion': LocalBackupService.backupFormatVersion,
        'storageSchemaVersion': LocalStore.schemaVersion,
        'exportedAt': createdAt,
        'createdAt': createdAt,
        'schemaVersion': LocalStore.schemaVersion,
        'storageVersion': LocalStore.schemaVersion,
        'appVersion': appVersion,
        'boxes': {
          for (final entry in boxes.entries) entry.key: entry.value.toMap(),
        },
        ...extras,
      };
      final json = await Isolate.run(
        () => LocalBackupService.encodeSnapshot(snapshot),
      );
      await directory.create(recursive: true);
      await _atomicWrite(File('${directory.path}/latest.json'), json);
      await _atomicWrite(
        File(
          '${directory.path}/mutation-${_now().microsecondsSinceEpoch}-${version.toString().padLeft(8, '0')}.json',
        ),
        json,
      );
      rollingWrites++;
      final daily = File('${directory.path}/daily-$date.json');
      if (_lastDailyDate != date) {
        var valid = false;
        if (await daily.exists()) {
          try {
            final existing = await daily.readAsString();
            valid = await Isolate.run(() {
              const LocalBackupService().inspectJson(existing);
              return true;
            });
          } catch (_) {
            valid = false;
          }
        }
        if (!valid) {
          await _atomicWrite(daily, json);
          dailyWrites++;
        }
      }
      _lastDailyDate = date;
      latestMetadata = {
        'createdAt': createdAt,
        'appVersion': appVersion,
        'backupVersion': LocalBackupService.backupFormatVersion,
        'storageSchemaVersion': LocalStore.schemaVersion,
        'dailyDate': date,
      };
      final index = File('${directory.path}/metadata.json.pending');
      await index.writeAsString(jsonEncode(latestMetadata), flush: true);
      await index.rename('${directory.path}/metadata.json');
      await _prune();
      _savedVersion = version;
      _failures = 0;
      lastError = null;
    } catch (error) {
      lastError = error;
      _failures++;
    }
  }

  Future<void> _atomicWrite(File target, String json) async {
    final temporary = File('${target.path}.pending');
    try {
      await temporary.writeAsString(json, flush: true);
      await beforeValidate?.call(temporary);
      final written = await temporary.readAsString();
      await Isolate.run(() => const LocalBackupService().inspectJson(written));
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _prune() async {
    final files = await directory
        .list()
        .where((entry) => entry is File)
        .toList();
    for (final policy in {'daily-': 14, 'mutation-': 3}.entries) {
      final candidates = files.whereType<File>().where((file) {
        final name = file.uri.pathSegments.last;
        return name.startsWith(policy.key) && name.endsWith('.json');
      }).toList()..sort((a, b) => b.path.compareTo(a.path));
      for (final file in candidates.skip(policy.value)) {
        await file.delete();
      }
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _midnightTimer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
  }
}
