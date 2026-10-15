import 'package:flutter_app/models/food_models.dart';
import 'package:flutter_app/models/reminder_models.dart';
import 'package:flutter_app/services/smart_reminder_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = SmartReminderEngine();
  final now = DateTime(2026, 9, 7, 7);

  FoodEntry meal(MealType type, DateTime time, {String id = 'meal'}) =>
      FoodEntry(
        id: '$id-${time.millisecondsSinceEpoch}',
        name: 'Meal',
        grams: 100,
        kcal: 200,
        proteinG: 10,
        fatG: 6,
        carbsG: 25,
        meal: type,
        time: time,
      );

  SmartReminderContext context({
    ReminderSettings settings = const ReminderSettings(
      permission: NotificationPermissionState.authorized,
      maxSmartPerDay: 4,
    ),
    List<FoodEntry> todayFood = const [],
    List<FoodEntry> foodHistory = const [],
    double water = 0,
    double waterGoal = 2,
    List<ManualReminder> manual = const [],
  }) => SmartReminderContext(
    now: now,
    settings: settings,
    todayFood: todayFood,
    foodHistory: foodHistory,
    waterLiters: water,
    waterGoalLiters: waterGoal,
    steps: 9000,
    latestWeightDate: now,
    advice: 'Advice',
    manualReminders: manual,
  );

  test('permission is required before anything is scheduled', () {
    final settings = const ReminderSettings(
      permission: NotificationPermissionState.notDetermined,
    );
    expect(engine.plan(context(settings: settings)), isEmpty);
  });

  test('logged meal and completed water goal suppress stale reminders', () {
    final breakfast = meal(MealType.breakfast, DateTime(2026, 9, 7, 8));
    final plan = engine.plan(
      context(todayFood: [breakfast], foodHistory: [breakfast], water: 2),
    );

    expect(plan.any((item) => item.type == ReminderType.breakfast), isFalse);
    expect(plan.any((item) => item.type == ReminderType.water), isFalse);
  });

  test('manual meal reminder de-duplicates nearby smart intent', () {
    final manual = ManualReminder(
      id: 'lunch',
      type: ReminderType.lunch,
      title: 'Lunch',
      minuteOfDay: 14 * 60 + 45,
      weekdays: {now.weekday},
    );
    final plan = engine.plan(context(manual: [manual]));

    expect(plan.any((item) => item.type == ReminderType.lunch), isFalse);
    expect(engine.nextManualOccurrence(manual, now).weekday, now.weekday);
  });

  test('quiet hours and daily cap are respected', () {
    final quiet = const ReminderSettings(
      permission: NotificationPermissionState.authorized,
      quietStartMinute: 0,
      quietEndMinute: 1439,
      maxSmartPerDay: 4,
    );
    expect(engine.plan(context(settings: quiet)), isEmpty);

    final capped = const ReminderSettings(
      permission: NotificationPermissionState.authorized,
      maxSmartPerDay: 1,
    );
    expect(engine.plan(context(settings: capped)), hasLength(1));
  });

  test('meal window learns the median after three real entries', () {
    final history = [
      meal(MealType.lunch, DateTime(2026, 9, 4, 12, 10), id: 'a'),
      meal(MealType.lunch, DateTime(2026, 9, 5, 13, 20), id: 'b'),
      meal(MealType.lunch, DateTime(2026, 9, 6, 12, 50), id: 'c'),
    ];
    final window = engine.mealWindows(history)[MealType.lunch]!;

    expect(window.learned, isTrue);
    expect(window.centerMinute, 12 * 60 + 50);
  });
}
