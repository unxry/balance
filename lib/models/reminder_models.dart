enum ReminderMode { smart, manual, smartAndManual }

enum ReminderType {
  water,
  breakfast,
  lunch,
  dinner,
  foodDiary,
  weight,
  advice,
  activity,
  custom,
}

enum NotificationPermissionState {
  notDetermined,
  denied,
  authorized,
  provisional,
}

class ReminderSettings {
  final ReminderMode mode;
  final bool adviceEnabled;
  final bool waterEnabled;
  final bool nutritionEnabled;
  final bool activityEnabled;
  final int adviceMinute;
  final int quietStartMinute;
  final int quietEndMinute;
  final int maxSmartPerDay;
  final NotificationPermissionState permission;

  const ReminderSettings({
    this.mode = ReminderMode.smartAndManual,
    this.adviceEnabled = true,
    this.waterEnabled = true,
    this.nutritionEnabled = true,
    this.activityEnabled = false,
    this.adviceMinute = 9 * 60,
    this.quietStartMinute = 22 * 60,
    this.quietEndMinute = 8 * 60,
    this.maxSmartPerDay = 3,
    this.permission = NotificationPermissionState.notDetermined,
  });

  bool get smartEnabled =>
      mode == ReminderMode.smart || mode == ReminderMode.smartAndManual;
  bool get manualEnabled =>
      mode == ReminderMode.manual || mode == ReminderMode.smartAndManual;

  ReminderSettings copyWith({
    ReminderMode? mode,
    bool? adviceEnabled,
    bool? waterEnabled,
    bool? nutritionEnabled,
    bool? activityEnabled,
    int? adviceMinute,
    int? quietStartMinute,
    int? quietEndMinute,
    int? maxSmartPerDay,
    NotificationPermissionState? permission,
  }) => ReminderSettings(
    mode: mode ?? this.mode,
    adviceEnabled: adviceEnabled ?? this.adviceEnabled,
    waterEnabled: waterEnabled ?? this.waterEnabled,
    nutritionEnabled: nutritionEnabled ?? this.nutritionEnabled,
    activityEnabled: activityEnabled ?? this.activityEnabled,
    adviceMinute: adviceMinute ?? this.adviceMinute,
    quietStartMinute: quietStartMinute ?? this.quietStartMinute,
    quietEndMinute: quietEndMinute ?? this.quietEndMinute,
    maxSmartPerDay: maxSmartPerDay ?? this.maxSmartPerDay,
    permission: permission ?? this.permission,
  );

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'adviceEnabled': adviceEnabled,
    'waterEnabled': waterEnabled,
    'nutritionEnabled': nutritionEnabled,
    'activityEnabled': activityEnabled,
    'adviceMinute': adviceMinute,
    'quietStartMinute': quietStartMinute,
    'quietEndMinute': quietEndMinute,
    'maxSmartPerDay': maxSmartPerDay,
    'permission': permission.name,
  };

  factory ReminderSettings.fromJson(Map<dynamic, dynamic> map) =>
      ReminderSettings(
        mode: ReminderMode.values.firstWhere(
          (value) => value.name == map['mode'],
          orElse: () => ReminderMode.smartAndManual,
        ),
        adviceEnabled: map['adviceEnabled'] != false,
        waterEnabled: map['waterEnabled'] != false,
        nutritionEnabled: map['nutritionEnabled'] != false,
        activityEnabled: map['activityEnabled'] == true,
        adviceMinute: _minute(map['adviceMinute'], 9 * 60),
        quietStartMinute: _minute(map['quietStartMinute'], 22 * 60),
        quietEndMinute: _minute(map['quietEndMinute'], 8 * 60),
        maxSmartPerDay: (map['maxSmartPerDay'] is num)
            ? (map['maxSmartPerDay'] as num).toInt().clamp(1, 4)
            : 3,
        permission: NotificationPermissionState.values.firstWhere(
          (value) => value.name == map['permission'],
          orElse: () => NotificationPermissionState.notDetermined,
        ),
      );

  static int _minute(Object? value, int fallback) =>
      value is num ? value.toInt().clamp(0, 1439) : fallback;
}

class ManualReminder {
  final String id;
  final ReminderType type;
  final String title;
  final int minuteOfDay;
  final Set<int> weekdays;
  final bool enabled;

  const ManualReminder({
    required this.id,
    required this.type,
    required this.title,
    required this.minuteOfDay,
    required this.weekdays,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'minuteOfDay': minuteOfDay,
    'weekdays': weekdays.toList()..sort(),
    'enabled': enabled,
  };

  factory ManualReminder.fromJson(Map<dynamic, dynamic> map) {
    final days = map['weekdays'];
    return ManualReminder(
      id: map['id']?.toString() ?? '',
      type: ReminderType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => ReminderType.custom,
      ),
      title: map['title']?.toString() ?? '',
      minuteOfDay: ReminderSettings._minute(map['minuteOfDay'], 9 * 60),
      weekdays: days is List
          ? days
                .whereType<num>()
                .map((value) => value.toInt())
                .where((value) => value >= 1 && value <= 7)
                .toSet()
          : {1, 2, 3, 4, 5, 6, 7},
      enabled: map['enabled'] != false,
    );
  }
}

String reminderPayload(ReminderType type) => switch (type) {
  ReminderType.breakfast ||
  ReminderType.lunch ||
  ReminderType.dinner ||
  ReminderType.foodDiary => 'diary:add',
  ReminderType.water => 'dashboard:water',
  ReminderType.weight => 'weight',
  ReminderType.advice => 'dashboard:advice',
  ReminderType.activity => 'dashboard:steps',
  ReminderType.custom => 'dashboard',
};
