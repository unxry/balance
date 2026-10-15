import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder_models.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/balance_notification_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/i18n.dart';
import '../utils/entry_id.dart';
import '../widgets/common.dart';
import '../widgets/premium_motion.dart';

class ReminderSettingsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const ReminderSettingsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = AppText(colors);
    final data = context.watch<AppDataProvider>();
    final strings = S(context.watch<SettingsProvider>().lang);
    final settings = data.reminderSettings;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    strings.isRu ? 'Напоминания' : 'Reminders',
                    style: text.fraunces(size: 27, weight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (settings.permission ==
                    NotificationPermissionState.notDetermined ||
                settings.permission == NotificationPermissionState.denied)
              _permissionCard(
                context,
                data,
                strings,
                colors,
                text,
                settings.permission,
              ),
            const SizedBox(height: 14),
            MonoLabel(strings.isRu ? 'РЕЖИМ' : 'MODE'),
            const SizedBox(height: 8),
            SectionCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _modeRow(
                    context,
                    data,
                    settings,
                    ReminderMode.smartAndManual,
                    strings.isRu ? 'Умные + мои' : 'Smart + manual',
                    strings.isRu ? 'Рекомендуется' : 'Recommended',
                  ),
                  _modeRow(
                    context,
                    data,
                    settings,
                    ReminderMode.smart,
                    strings.isRu ? 'Только умные' : 'Smart only',
                    strings.isRu
                        ? 'Balance выбирает момент'
                        : 'Balance chooses the moment',
                  ),
                  _modeRow(
                    context,
                    data,
                    settings,
                    ReminderMode.manual,
                    strings.isRu ? 'Только мои' : 'Manual only',
                    strings.isRu
                        ? 'Полностью по расписанию'
                        : 'Only your schedule',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            MonoLabel(strings.isRu ? 'УМНЫЕ НАПОМИНАНИЯ' : 'SMART REMINDERS'),
            const SizedBox(height: 8),
            SectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Column(
                children: [
                  _switchRow(
                    colors,
                    text,
                    strings.isRu ? 'Совет дня' : 'Daily advice',
                    settings.adviceEnabled,
                    (value) => data.updateReminderSettings(
                      settings.copyWith(adviceEnabled: value),
                    ),
                  ),
                  _switchRow(
                    colors,
                    text,
                    strings.isRu ? 'Вода' : 'Water',
                    settings.waterEnabled,
                    (value) => data.updateReminderSettings(
                      settings.copyWith(waterEnabled: value),
                    ),
                  ),
                  _switchRow(
                    colors,
                    text,
                    strings.isRu ? 'Питание' : 'Nutrition',
                    settings.nutritionEnabled,
                    (value) => data.updateReminderSettings(
                      settings.copyWith(nutritionEnabled: value),
                    ),
                  ),
                  _switchRow(
                    colors,
                    text,
                    strings.isRu ? 'Активность' : 'Activity',
                    settings.activityEnabled,
                    (value) => data.updateReminderSettings(
                      settings.copyWith(activityEnabled: value),
                    ),
                  ),
                  _timeRow(
                    context,
                    colors,
                    text,
                    strings.isRu ? 'Время совета' : 'Advice time',
                    settings.adviceMinute,
                    (minute) => data.updateReminderSettings(
                      settings.copyWith(adviceMinute: minute),
                    ),
                  ),
                  _quietRow(
                    context,
                    data,
                    settings,
                    strings.isRu,
                    colors,
                    text,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: MonoLabel(
                    strings.isRu ? 'МОИ НАПОМИНАНИЯ' : 'MY REMINDERS',
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('addManualReminder'),
                  onPressed: () =>
                      _showReminderEditor(context, data, strings.isRu),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: Text(strings.isRu ? 'Добавить' : 'Add'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (data.manualReminders.isEmpty)
              SectionCard(
                child: Text(
                  strings.isRu
                      ? 'Здесь появится ваше личное расписание.'
                      : 'Your personal schedule will appear here.',
                  style: text.inter(size: 12, color: colors.muted),
                ),
              )
            else
              ...data.manualReminders.map(
                (reminder) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PressableScale(
                    onTap: () => _showReminderEditor(
                      context,
                      data,
                      strings.isRu,
                      existing: reminder,
                    ),
                    child: SectionCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: colors.accentSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _typeIcon(reminder.type),
                              color: colors.accent,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reminder.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.inter(
                                    size: 12,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_clock(reminder.minuteOfDay)} · ${_days(reminder.weekdays, strings.isRu)}',
                                  style: text.mono(
                                    size: 8,
                                    color: colors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (settings.permission == NotificationPermissionState.authorized ||
                settings.permission ==
                    NotificationPermissionState.provisional) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                key: const ValueKey('testNotificationButton'),
                onPressed: () =>
                    _showTestNotificationPicker(context, strings.isRu),
                child: Text(
                  strings.isRu
                      ? 'Отправить тестовое уведомление'
                      : 'Send a test notification',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _permissionCard(
    BuildContext context,
    AppDataProvider data,
    S strings,
    dynamic colors,
    AppText text,
    NotificationPermissionState permission,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.accent.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_none_rounded, color: colors.accent),
          const SizedBox(height: 10),
          Text(
            strings.isRu ? 'Мягкие напоминания' : 'Gentle reminders',
            style: text.fraunces(size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            permission == NotificationPermissionState.denied
                ? (strings.isRu
                      ? 'Доступ выключен в настройках iPhone.'
                      : 'Access is disabled in iPhone Settings.')
                : (strings.isRu
                      ? 'Balance может напоминать о воде, питании и дневнике в подходящее время.'
                      : 'Balance can gently remind you about water, food and your diary.'),
            style: text.inter(size: 12, color: colors.fg2, height: 1.4),
          ),
          if (permission == NotificationPermissionState.notDetermined) ...[
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('requestNotificationPermission'),
              onPressed: () async {
                final accepted = await showModalBottomSheet<bool>(
                  context: context,
                  backgroundColor: colors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  builder: (_) => SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 42,
                            color: colors.accent,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            strings.isRu
                                ? 'Разрешить уведомления?'
                                : 'Allow notifications?',
                            style: text.fraunces(
                              size: 22,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.isRu
                                ? 'Только выбранные вами напоминания. Режим тишины 22:00–08:00 включён по умолчанию.'
                                : 'Only reminders you choose. Quiet hours 22:00–08:00 are on by default.',
                            textAlign: TextAlign.center,
                            style: text.inter(
                              size: 12,
                              color: colors.fg2,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              strings.isRu ? 'Продолжить' : 'Continue',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                if (accepted != true) return;
                final state = await BalanceNotificationService.instance
                    .requestPermission();
                await data.setNotificationPermission(state);
              },
              child: Text(
                strings.isRu ? 'Разрешить уведомления' : 'Allow notifications',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showTestNotificationPicker(
    BuildContext context,
    bool isRu,
  ) async {
    final selected = await showModalBottomSheet<ReminderType>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRu ? 'Проверить переход' : 'Test destination',
                style: AppText(
                  context.colors,
                ).fraunces(size: 21, weight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              for (final type in const [
                ReminderType.foodDiary,
                ReminderType.water,
                ReminderType.weight,
                ReminderType.advice,
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_typeIcon(type)),
                  title: Text(_typeLabel(type, isRu)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, type),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      await BalanceNotificationService.instance.showTestNotification(selected);
    }
  }

  Widget _modeRow(
    BuildContext context,
    AppDataProvider data,
    ReminderSettings settings,
    ReminderMode mode,
    String title,
    String sub,
  ) {
    final colors = context.colors;
    final text = AppText(colors);
    return InkWell(
      onTap: () => data.updateReminderSettings(settings.copyWith(mode: mode)),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Row(
          children: [
            Icon(
              settings.mode == mode
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: settings.mode == mode ? colors.accent : colors.muted,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.inter(size: 12, weight: FontWeight.w700),
                  ),
                  Text(sub, style: text.inter(size: 9, color: colors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(
    dynamic colors,
    AppText text,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: text.inter(size: 12, weight: FontWeight.w600),
          ),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: colors.accent,
          onChanged: onChanged,
        ),
      ],
    ),
  );

  Widget _timeRow(
    BuildContext context,
    dynamic colors,
    AppText text,
    String label,
    int minute,
    ValueChanged<int> onChanged,
  ) => InkWell(
    onTap: () async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
      );
      if (picked != null) onChanged(picked.hour * 60 + picked.minute);
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.inter(size: 12, weight: FontWeight.w600),
            ),
          ),
          Text(
            _clock(minute),
            style: text.mono(size: 10, color: colors.accent),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 17, color: colors.muted),
        ],
      ),
    ),
  );

  Widget _quietRow(
    BuildContext context,
    AppDataProvider data,
    ReminderSettings settings,
    bool isRu,
    dynamic colors,
    AppText text,
  ) => InkWell(
    key: const ValueKey('quietHoursRow'),
    onTap: () async {
      final start = await showTimePicker(
        context: context,
        helpText: isRu ? 'Начало режима тишины' : 'Quiet hours start',
        initialTime: TimeOfDay(
          hour: settings.quietStartMinute ~/ 60,
          minute: settings.quietStartMinute % 60,
        ),
      );
      if (start == null || !context.mounted) return;
      final end = await showTimePicker(
        context: context,
        helpText: isRu ? 'Конец режима тишины' : 'Quiet hours end',
        initialTime: TimeOfDay(
          hour: settings.quietEndMinute ~/ 60,
          minute: settings.quietEndMinute % 60,
        ),
      );
      if (end != null) {
        await data.updateReminderSettings(
          settings.copyWith(
            quietStartMinute: start.hour * 60 + start.minute,
            quietEndMinute: end.hour * 60 + end.minute,
          ),
        );
      }
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isRu ? 'Не беспокоить' : 'Quiet hours',
              style: text.inter(size: 12, weight: FontWeight.w600),
            ),
          ),
          Text(
            '${_clock(settings.quietStartMinute)}–${_clock(settings.quietEndMinute)}',
            style: text.mono(size: 9, color: colors.muted),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 17, color: colors.muted),
        ],
      ),
    ),
  );

  Future<void> _showReminderEditor(
    BuildContext context,
    AppDataProvider data,
    bool isRu, {
    ManualReminder? existing,
  }) async {
    var type = existing?.type ?? ReminderType.water;
    var minute = existing?.minuteOfDay ?? 9 * 60;
    var weekdays = Set<int>.from(existing?.weekdays ?? {1, 2, 3, 4, 5, 6, 7});
    final title = TextEditingController(
      text: existing?.title ?? _typeLabel(type, isRu),
    );
    final result = await showModalBottomSheet<ManualReminder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) {
          final colors = context.colors;
          final text = AppText(colors);
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRu ? 'Моё напоминание' : 'My reminder',
                    style: text.fraunces(size: 22, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ReminderType>(
                    initialValue: type,
                    decoration: InputDecoration(
                      labelText: isRu ? 'Тип' : 'Type',
                    ),
                    items: ReminderType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_typeLabel(item, isRu)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      type = value ?? type;
                      if (existing == null) title.text = _typeLabel(type, isRu);
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: title,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: isRu ? 'Текст' : 'Text',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(isRu ? 'Время' : 'Time'),
                    trailing: Text(
                      _clock(minute),
                      style: text.fraunces(size: 20, weight: FontWeight.w700),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: minute ~/ 60,
                          minute: minute % 60,
                        ),
                      );
                      if (picked != null) {
                        setState(
                          () => minute = picked.hour * 60 + picked.minute,
                        );
                      }
                    },
                  ),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      const ru = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
                      const en = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
                      return FilterChip(
                        label: Text((isRu ? ru : en)[index]),
                        selected: weekdays.contains(day),
                        onSelected: (selected) => setState(
                          () => selected
                              ? weekdays.add(day)
                              : weekdays.remove(day),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (existing != null)
                        TextButton(
                          onPressed: () async {
                            await data.deleteManualReminder(existing.id);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          child: Text(
                            isRu ? 'Удалить' : 'Delete',
                            style: TextStyle(color: colors.accent2),
                          ),
                        ),
                      const Spacer(),
                      FilledButton(
                        key: const ValueKey('saveManualReminder'),
                        onPressed: weekdays.isEmpty || title.text.trim().isEmpty
                            ? null
                            : () => Navigator.pop(
                                sheetContext,
                                ManualReminder(
                                  id: existing?.id ?? newEntryId(),
                                  type: type,
                                  title: title.text.trim(),
                                  minuteOfDay: minute,
                                  weekdays: weekdays,
                                ),
                              ),
                        child: Text(isRu ? 'Сохранить' : 'Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    title.dispose();
    if (result != null) await data.saveManualReminder(result);
  }

  String _clock(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
  String _days(Set<int> days, bool isRu) => days.length == 7
      ? (isRu ? 'каждый день' : 'daily')
      : (days.toList()..sort()).join(', ');
  String _typeLabel(ReminderType type, bool isRu) => switch (type) {
    ReminderType.water => isRu ? 'Вода' : 'Water',
    ReminderType.breakfast => isRu ? 'Завтрак' : 'Breakfast',
    ReminderType.lunch => isRu ? 'Обед' : 'Lunch',
    ReminderType.dinner => isRu ? 'Ужин' : 'Dinner',
    ReminderType.foodDiary => isRu ? 'Записать еду' : 'Log food',
    ReminderType.weight => isRu ? 'Взвеситься' : 'Weigh in',
    ReminderType.advice => isRu ? 'Совет дня' : 'Daily advice',
    ReminderType.activity => isRu ? 'Активность' : 'Activity',
    ReminderType.custom => isRu ? 'Другое' : 'Other',
  };
  IconData _typeIcon(ReminderType type) => switch (type) {
    ReminderType.water => Icons.water_drop_outlined,
    ReminderType.weight => Icons.monitor_weight_outlined,
    ReminderType.advice => Icons.auto_awesome_outlined,
    ReminderType.activity => Icons.directions_walk_rounded,
    ReminderType.breakfast ||
    ReminderType.lunch ||
    ReminderType.dinner ||
    ReminderType.foodDiary => Icons.restaurant_outlined,
    ReminderType.custom => Icons.notifications_none_rounded,
  };
}
