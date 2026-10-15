import 'dart:math';

import '../models/food_models.dart';
import '../models/reminder_models.dart';

class MealWindow {
  final MealType meal;
  final int centerMinute;
  final int startMinute;
  final int endMinute;
  final bool learned;

  const MealWindow({
    required this.meal,
    required this.centerMinute,
    required this.startMinute,
    required this.endMinute,
    required this.learned,
  });
}

class ReminderCandidate {
  final int id;
  final ReminderType type;
  final DateTime scheduledAt;
  final String title;
  final String body;
  final String payload;
  final int priority;

  const ReminderCandidate({
    required this.id,
    required this.type,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.payload,
    required this.priority,
  });
}

class SmartReminderContext {
  final DateTime now;
  final ReminderSettings settings;
  final List<FoodEntry> todayFood;
  final List<FoodEntry> foodHistory;
  final double waterLiters;
  final double waterGoalLiters;
  final int? steps;
  final DateTime? latestWeightDate;
  final String advice;
  final List<ManualReminder> manualReminders;
  final int alreadySentToday;

  const SmartReminderContext({
    required this.now,
    required this.settings,
    required this.todayFood,
    required this.foodHistory,
    required this.waterLiters,
    required this.waterGoalLiters,
    required this.steps,
    required this.latestWeightDate,
    required this.advice,
    required this.manualReminders,
    this.alreadySentToday = 0,
  });
}

class SmartReminderEngine {
  const SmartReminderEngine();

  Map<MealType, MealWindow> mealWindows(List<FoodEntry> history) {
    const defaults = {
      MealType.breakfast: 8 * 60 + 30,
      MealType.lunch: 13 * 60 + 30,
      MealType.snack: 16 * 60 + 30,
      MealType.dinner: 19 * 60,
    };
    return {
      for (final meal in MealType.values)
        meal: _mealWindow(meal, history, defaults[meal]!),
    };
  }

  MealWindow _mealWindow(MealType meal, List<FoodEntry> history, int fallback) {
    final samples =
        history
            .where((entry) => entry.meal == meal)
            .map((entry) => entry.time.hour * 60 + entry.time.minute)
            .toList()
          ..sort();
    final learned = samples.length >= 3;
    final center = learned ? samples[samples.length ~/ 2] : fallback;
    return MealWindow(
      meal: meal,
      centerMinute: center,
      startMinute: max(0, center - 45),
      endMinute: min(1439, center + 60),
      learned: learned,
    );
  }

  List<ReminderCandidate> plan(SmartReminderContext context) {
    if (!context.settings.smartEnabled ||
        (context.settings.permission !=
                NotificationPermissionState.authorized &&
            context.settings.permission !=
                NotificationPermissionState.provisional)) {
      return const [];
    }
    final candidates = <ReminderCandidate>[];
    final windows = mealWindows(context.foodHistory);

    if (context.settings.nutritionEnabled) {
      for (final meal in const [
        MealType.breakfast,
        MealType.lunch,
        MealType.dinner,
      ]) {
        if (context.todayFood.any((entry) => entry.meal == meal)) continue;
        final type = switch (meal) {
          MealType.breakfast => ReminderType.breakfast,
          MealType.lunch => ReminderType.lunch,
          MealType.dinner => ReminderType.dinner,
          MealType.snack => ReminderType.foodDiary,
        };
        final at = _todayAt(context.now, windows[meal]!.endMinute + 15);
        _addIfUseful(
          candidates,
          context,
          ReminderCandidate(
            id: 1100 + meal.index,
            type: type,
            scheduledAt: _notBeforeNow(at, context.now),
            title: 'Balance · дневник',
            body: _mealBody(meal),
            payload: reminderPayload(type),
            priority: meal == MealType.lunch ? 90 : 72,
          ),
        );
      }
    }

    if (context.settings.waterEnabled &&
        context.waterGoalLiters > 0 &&
        context.waterLiters < context.waterGoalLiters) {
      final ratio = context.waterLiters / context.waterGoalLiters;
      final minute = ratio < .35 ? 16 * 60 : 19 * 60 + 30;
      _addIfUseful(
        candidates,
        context,
        ReminderCandidate(
          id: 1200,
          type: ReminderType.water,
          scheduledAt: _notBeforeNow(
            _todayAt(context.now, minute),
            context.now,
          ),
          title: 'Balance · вода',
          body:
              'Сегодня воды пока меньше обычного. Можно постепенно восполнить её до вечера.',
          payload: reminderPayload(ReminderType.water),
          priority: ratio < .35 ? 85 : 64,
        ),
      );
    }

    if (context.settings.adviceEnabled) {
      _addIfUseful(
        candidates,
        context,
        ReminderCandidate(
          id: 1300,
          type: ReminderType.advice,
          scheduledAt: _notBeforeNow(
            _todayAt(context.now, context.settings.adviceMinute),
            context.now,
          ),
          title: 'Balance · совет дня',
          body: context.advice,
          payload: reminderPayload(ReminderType.advice),
          priority: 55,
        ),
      );
    }

    if (context.settings.activityEnabled && (context.steps ?? 0) < 6000) {
      _addIfUseful(
        candidates,
        context,
        ReminderCandidate(
          id: 1400,
          type: ReminderType.activity,
          scheduledAt: _notBeforeNow(
            _todayAt(context.now, 18 * 60 + 30),
            context.now,
          ),
          title: 'Balance · активность',
          body:
              'Если будет удобно, короткая прогулка добавит движения этому дню.',
          payload: reminderPayload(ReminderType.activity),
          priority: 45,
        ),
      );
    }

    if (context.latestWeightDate == null ||
        context.now.difference(context.latestWeightDate!).inDays >= 7) {
      _addIfUseful(
        candidates,
        context,
        ReminderCandidate(
          id: 1500,
          type: ReminderType.weight,
          scheduledAt: _notBeforeNow(
            _todayAt(context.now, 9 * 60 + 30),
            context.now,
          ),
          title: 'Balance · вес',
          body: 'Новое измерение поможет точнее увидеть фактическую динамику.',
          payload: reminderPayload(ReminderType.weight),
          priority: 40,
        ),
      );
    }

    candidates.sort((a, b) => b.priority.compareTo(a.priority));
    final available = max(
      0,
      context.settings.maxSmartPerDay - context.alreadySentToday,
    );
    return candidates.take(available).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  void _addIfUseful(
    List<ReminderCandidate> output,
    SmartReminderContext context,
    ReminderCandidate candidate,
  ) {
    if (_inQuietHours(candidate.scheduledAt, context.settings)) return;
    if (candidate.scheduledAt.difference(context.now).inHours > 24) return;
    final duplicate = context.manualReminders.any(
      (manual) =>
          manual.enabled &&
          _sameIntent(manual.type, candidate.type) &&
          manual.weekdays.contains(candidate.scheduledAt.weekday) &&
          (manual.minuteOfDay -
                      (candidate.scheduledAt.hour * 60 +
                          candidate.scheduledAt.minute))
                  .abs() <=
              60,
    );
    if (!duplicate) output.add(candidate);
  }

  bool _sameIntent(ReminderType a, ReminderType b) {
    const meals = {
      ReminderType.breakfast,
      ReminderType.lunch,
      ReminderType.dinner,
      ReminderType.foodDiary,
    };
    return a == b || (meals.contains(a) && meals.contains(b));
  }

  bool _inQuietHours(DateTime time, ReminderSettings settings) {
    final minute = time.hour * 60 + time.minute;
    final start = settings.quietStartMinute;
    final end = settings.quietEndMinute;
    if (start == end) return false;
    return start < end
        ? minute >= start && minute < end
        : minute >= start || minute < end;
  }

  DateTime nextManualOccurrence(ManualReminder reminder, DateTime after) {
    for (var offset = 0; offset <= 7; offset++) {
      final day = after.add(Duration(days: offset));
      final candidate = DateTime(
        day.year,
        day.month,
        day.day,
        reminder.minuteOfDay ~/ 60,
        reminder.minuteOfDay % 60,
      );
      if (reminder.weekdays.contains(candidate.weekday) &&
          candidate.isAfter(after)) {
        return candidate;
      }
    }
    final fallback = after.add(const Duration(days: 7));
    return DateTime(
      fallback.year,
      fallback.month,
      fallback.day,
      reminder.minuteOfDay ~/ 60,
      reminder.minuteOfDay % 60,
    );
  }

  DateTime _todayAt(DateTime now, int minute) {
    final normalized = minute.clamp(0, 1439);
    return DateTime(
      now.year,
      now.month,
      now.day,
      normalized ~/ 60,
      normalized % 60,
    );
  }

  DateTime _notBeforeNow(DateTime value, DateTime now) {
    if (value.isAfter(now)) return value;
    if (now.difference(value).inMinutes <= 90) {
      return now.add(const Duration(minutes: 1));
    }
    return value.add(const Duration(days: 1));
  }

  String _mealBody(MealType meal) => switch (meal) {
    MealType.breakfast =>
      'Если завтрак уже был, его можно спокойно добавить в дневник.',
    MealType.lunch =>
      'Похоже, привычное время обеда прошло. Если вы уже поели — добавьте запись в дневник.',
    MealType.dinner =>
      'Если ужин уже состоялся, дневник поможет сохранить картину дня.',
    MealType.snack => 'Если был перекус, его можно добавить в дневник.',
  };
}
