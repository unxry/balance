import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_models.dart';
import 'smart_reminder_engine.dart';

class BalanceNotificationService {
  BalanceNotificationService._();

  static final instance = BalanceNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<String?> navigationPayload = ValueNotifier(null);
  bool _initialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'balance_reminders',
      'Balance reminders',
      channelDescription: 'Gentle reminders about diary, water and progress',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
      threadIdentifier: 'balance-reminders',
    ),
  );

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // UTC remains a safe fallback; normal app startup must never fail because
      // the platform could not report a time-zone identifier.
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            navigationPayload.value = payload;
          }
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true &&
          payload != null &&
          payload.isNotEmpty) {
        navigationPayload.value = payload;
      }
      _initialized = true;
    } catch (_) {
      // MissingPluginException is expected in widget/unit tests.
    }
  }

  Future<NotificationPermissionState> permissionState() async {
    await initialize();
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final status = await ios?.checkPermissions();
      if (status == null) return NotificationPermissionState.notDetermined;
      if (status.isProvisionalEnabled) {
        return NotificationPermissionState.provisional;
      }
      return status.isEnabled
          ? NotificationPermissionState.authorized
          : NotificationPermissionState.denied;
    } catch (_) {
      return NotificationPermissionState.notDetermined;
    }
  }

  Future<NotificationPermissionState> requestPermission() async {
    await initialize();
    try {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: true);
      return granted == true
          ? NotificationPermissionState.authorized
          : NotificationPermissionState.denied;
    } catch (_) {
      return NotificationPermissionState.notDetermined;
    }
  }

  Future<void> reconcile({
    required ReminderSettings settings,
    required List<ManualReminder> manual,
    required List<ReminderCandidate> smart,
  }) async {
    await initialize();
    if (!_initialized) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (_isManagedReminderId(request.id)) {
          await _plugin.cancel(id: request.id);
        }
      }
      if (settings.permission != NotificationPermissionState.authorized &&
          settings.permission != NotificationPermissionState.provisional) {
        return;
      }
      if (settings.smartEnabled) {
        for (final candidate in smart) {
          await _schedule(
            id: candidate.id,
            at: candidate.scheduledAt,
            title: candidate.title,
            body: candidate.body,
            payload: candidate.payload,
          );
        }
      }
      if (settings.manualEnabled) {
        for (final reminder in manual.where((item) => item.enabled)) {
          await _scheduleManual(reminder);
        }
      }
    } catch (_) {
      // Notification reconciliation is best effort and must not affect diary
      // writes or app startup.
    }
  }

  Future<void> _scheduleManual(ManualReminder reminder) async {
    final now = DateTime.now();
    for (final weekday in reminder.weekdays) {
      final occurrence = _nextWeekdayOccurrence(
        now,
        weekday,
        reminder.minuteOfDay,
      );
      await _plugin.zonedSchedule(
        id: 2000 + _stableId('${reminder.id}:$weekday') % 1000,
        title: 'Balance · напоминание',
        body: reminder.title,
        scheduledDate: tz.TZDateTime.from(occurrence, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminderPayload(reminder.type),
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: tz.TZDateTime.from(at, tz.local),
    notificationDetails: _details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: payload,
  );

  Future<void> showTestNotification(ReminderType type) async {
    await initialize();
    if (!_initialized) return;
    final content = switch (type) {
      ReminderType.breakfast ||
      ReminderType.lunch ||
      ReminderType.dinner ||
      ReminderType.foodDiary => (
        'Balance · дневник',
        'Не забудьте записать приём пищи.',
      ),
      ReminderType.water => (
        'Balance · вода',
        'Сегодня воды пока мало. Откройте Balance, чтобы добавить воду.',
      ),
      ReminderType.weight => (
        'Balance · вес',
        'Добавьте измерение веса, когда будет удобно.',
      ),
      ReminderType.advice => (
        'Balance · совет дня',
        'Откройте персональный совет на сегодня.',
      ),
      ReminderType.activity => (
        'Balance · активность',
        'Откройте экран шагов и активности.',
      ),
      ReminderType.custom => ('Balance', 'Тестовое напоминание готово.'),
    };
    await _plugin.show(
      id: 9001 + type.index,
      title: content.$1,
      body: content.$2,
      notificationDetails: _details,
      payload: reminderPayload(type),
    );
  }

  void consumePayload() => navigationPayload.value = null;

  DateTime _nextWeekdayOccurrence(DateTime now, int weekday, int minuteOfDay) {
    for (var offset = 0; offset <= 7; offset++) {
      final day = now.add(Duration(days: offset));
      final candidate = DateTime(
        day.year,
        day.month,
        day.day,
        minuteOfDay ~/ 60,
        minuteOfDay % 60,
      );
      if (candidate.weekday == weekday && candidate.isAfter(now)) {
        return candidate;
      }
    }
    return now.add(const Duration(days: 7));
  }

  int _stableId(String value) {
    var hash = 2166136261;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  bool _isManagedReminderId(int id) =>
      (id >= 1100 && id <= 1599) || (id >= 2000 && id <= 2999);
}
