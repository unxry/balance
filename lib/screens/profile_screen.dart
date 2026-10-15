import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/achievement_models.dart';
import '../models/reminder_models.dart';
import '../models/user_profile.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/image_sanitizer.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/i18n.dart';
import '../widgets/common.dart';
import '../widgets/achievement_medal.dart';
import '../widgets/premium_motion.dart';
import '../widgets/balance_feedback.dart';
import '../widgets/tab_bar_pill.dart';
import 'achievements_screen.dart';
import 'legal_screen.dart';
import 'profile_stat_detail_screen.dart';
import 'reminder_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onEditGoal;
  final VoidCallback? onOpenDiary;
  final VoidCallback? onOpenWeight;
  final VoidCallback? onStartOver;
  const ProfileScreen({
    super.key,
    required this.onEditGoal,
    this.onOpenDiary,
    this.onOpenWeight,
    this.onStartOver,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final data = context.watch<AppDataProvider>();
    final settings = context.watch<SettingsProvider>();
    final lang = settings.lang;
    final s = S(lang);
    final p = data.profile;
    final weightChange = data.totalWeightChange;
    final initialWeight = data.weightHistory.isEmpty
        ? p.weightKg
        : data.weightHistory.first.kg;
    final initialGoalDistance = (initialWeight - p.targetWeightKg).abs();

    final goalLabel = p.goal == Goal.lose
        ? '${s.isRu ? "Цель" : "Goal"}: −${(p.weightKg - p.targetWeightKg).abs().round()} kg'
        : p.goal == Goal.gain
        ? '${s.isRu ? "Цель" : "Goal"}: +${(p.targetWeightKg - p.weightKg).abs().round()} kg'
        : '${s.isRu ? "Цель" : "Goal"}: ${s.goalHold}';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const PageStorageKey('profileScroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          BalanceRootMetrics.contentBottomInset(context),
        ),
        child: Column(
          children: [
            Semantics(
              button: true,
              label: s.isRu ? 'Изменить фото профиля' : 'Edit profile photo',
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: () => _showAvatarSheet(context, data, s, c),
                  customBorder: const CircleBorder(),
                  child: ProfileAvatar(
                    imageBytes: p.avatarBytes,
                    fallbackLetter: p.avatarLetter,
                    size: 78,
                    badge: Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: c.fg,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        size: 13,
                        color: c.surface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              p.avatarBytes == null
                  ? (s.isRu
                        ? 'Нажми, чтобы добавить фото'
                        : 'Tap to add a photo')
                  : (s.isRu
                        ? 'Нажми, чтобы изменить фото'
                        : 'Tap to edit photo'),
              style: t.inter(size: 10, color: c.muted),
            ),
            const SizedBox(height: 6),
            Semantics(
              button: true,
              label: s.isRu ? 'Изменить имя' : 'Edit name',
              value: p.name,
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: () => _showEditNameSheet(context, data, s, c),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.name.isEmpty
                              ? (s.isRu ? 'Без имени' : 'No name')
                              : p.name,
                          style: t.fraunces(size: 20, weight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.edit_rounded, size: 15, color: c.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${s.isRu ? "в Balance с" : "with Balance since"} ${p.joinedAt.toLocal().year}',
              style: t.mono(size: 10),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Pill(
                  text: p.gender == Gender.female
                      ? '${s.isRu ? "Ж" : "F"} · ${p.age}'
                      : '${s.isRu ? "М" : "M"} · ${p.age}',
                  bg: c.card2,
                  fg: c.fg,
                  mono: true,
                ),
                Pill(
                  text: '${p.heightCm.round()}/${p.weightKg.round()}',
                  bg: c.card2,
                  fg: c.fg,
                  mono: true,
                ),
                Pill(
                  text: goalLabel,
                  bg: c.accent2Soft,
                  fg: c.accent2,
                  mono: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: MonoLabel(s.isRu ? 'ЦЕЛЬ И ПИТАНИЕ' : 'GOAL & NUTRITION'),
            ),
            const SizedBox(height: 8),
            _goalNutritionCard(c, t, s, p),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 124,
              children: [
                PressableScale(
                  onTap: () => _openStat(context, ProfileStatKind.streak),
                  child: _invertedTile(
                    c,
                    t,
                    Icons.local_fire_department_outlined,
                    '${data.streakDays} ${s.isRu ? "дн" : "d"}',
                    s.streak,
                    s.isRu ? 'полезные действия' : 'useful actions',
                  ),
                ),
                PressableScale(
                  onTap: () => _openStat(context, ProfileStatKind.weightChange),
                  child: _statTile(
                    c,
                    t,
                    '${weightChange.abs().toStringAsFixed(1)} kg',
                    weightChange >= 0 ? s.totLost : s.totGained,
                    '${s.isRu ? "из цели" : "of goal"} ${initialGoalDistance.toStringAsFixed(1)} kg',
                  ),
                ),
                PressableScale(
                  onTap: () => _openStat(context, ProfileStatKind.mealsToday),
                  child: _statTile(
                    c,
                    t,
                    '${data.todayFood.length}',
                    s.isRu ? 'БЛЮД СЕГОДНЯ' : 'MEALS TODAY',
                    s.isRu ? 'записей в дневнике' : 'diary entries',
                  ),
                ),
                PressableScale(
                  onTap: () => _openStat(context, ProfileStatKind.averageSteps),
                  child: _statTile(
                    c,
                    t,
                    data.averageSteps7Days?.toString() ?? '—',
                    s.avgSteps,
                    data.averageSteps7Days == null
                        ? (s.isRu ? 'нет данных' : 'no data')
                        : s.lastWeek,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.achievements,
                    style: t.fraunces(size: 16, weight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  key: const ValueKey('allAchievementsButton'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AchievementsScreen(
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  child: Text(s.isRu ? 'Все' : 'All'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 116,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: data.achievements.take(8).map((a) {
                  final title = s.isRu
                      ? a.definition.titleRu
                      : a.definition.titleEn;
                  final status = a.state == AchievementState.unlocked
                      ? (s.isRu ? 'Получено' : 'Unlocked')
                      : (s.isRu ? 'Прогресс' : 'Progress');
                  return PressableScale(
                    onTap: () =>
                        showAchievementDetails(context, a, isRu: s.isRu),
                    semanticsLabel: title,
                    semanticsValue: '$status, ${(a.fraction * 100).round()}%',
                    child: Container(
                      width: 92,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          AchievementMedal(achievement: a, colors: c, size: 64),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: t.inter(size: 8.5, weight: FontWeight.w700),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            _notificationSection(context, c, t, s, data),
            const SizedBox(height: 12),
            _settingsSection(context, c, t, s, settings, data),
            const SizedBox(height: 12),
            _startOverAction(context, c, t, s, data, settings),
            const SizedBox(height: 12),
            _legalSection(context, c, t, s),
          ],
        ),
      ),
    );
  }

  Widget _startOverAction(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    AppDataProvider data,
    SettingsProvider settings,
  ) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      key: const ValueKey('startOverAction'),
      onPressed: () => _confirmStartOver(context, c, t, s, data, settings),
      style: TextButton.styleFrom(foregroundColor: c.muted),
      icon: const Icon(Icons.restart_alt_rounded, size: 17),
      label: Text(s.isRu ? 'Начать заново' : 'Start over'),
    ),
  );

  Future<void> _confirmStartOver(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    AppDataProvider data,
    SettingsProvider settings,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                s.isRu ? 'Начать заново?' : 'Start over?',
                style: t.fraunces(size: 24, weight: FontWeight.w800),
              ),
              const SizedBox(height: 9),
              Text(
                s.isRu
                    ? 'Личные данные Balance будут очищены, затем откроется первоначальная настройка. Каталог продуктов останется на устройстве.'
                    : 'Your personal Balance data will be cleared and initial setup will open. The bundled product catalog stays on the device.',
                style: t.inter(size: 12, color: c.muted, height: 1.45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('confirmStartOver'),
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: .88),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(s.isRu ? 'Начать заново' : 'Start over'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  child: Text(s.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    await data.resetPersonalData();
    await settings.resetToDefaults();
    if (context.mounted) onStartOver?.call();
  }

  Widget _goalNutritionCard(dynamic c, AppText t, S s, UserProfile profile) {
    final goal = switch (profile.goal) {
      Goal.lose => s.goalLose,
      Goal.hold => s.goalHold,
      Goal.gain => s.goalGain,
    };
    final automatic = profile.calorieGoalMode == CalorieGoalMode.auto;
    return Semantics(
      button: true,
      label: s.isRu ? 'Изменить цель и питание' : 'Edit goal and nutrition',
      child: InkWell(
        key: const ValueKey('goalNutritionCard'),
        onTap: onEditGoal,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.line),
          ),
          child: Column(
            children: [
              _goalRow(c, t, s.isRu ? 'Цель' : 'Goal', goal),
              const SizedBox(height: 11),
              _goalRow(
                c,
                t,
                s.isRu ? 'Целевой вес' : 'Target weight',
                '${profile.targetWeightKg.toStringAsFixed(1)} kg',
              ),
              const SizedBox(height: 11),
              _goalRow(
                c,
                t,
                s.isRu ? 'Дневная норма' : 'Daily target',
                '${profile.effectiveCalorieGoal} ${s.isRu ? "ккал" : "kcal"}',
                accent: true,
              ),
              const SizedBox(height: 11),
              _goalRow(
                c,
                t,
                s.isRu ? 'Расчёт Balance' : 'Balance calculation',
                automatic
                    ? (s.isRu ? 'Автоматически' : 'Automatic')
                    : (s.isRu ? 'Вручную' : 'Manual'),
              ),
              if (!automatic) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${s.isRu ? "Рекомендация Balance" : "Balance recommendation"}: ${profile.recommendedCalories} ${s.isRu ? "ккал" : "kcal"}',
                    style: t.inter(size: 11, color: c.muted),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    s.isRu ? 'Изменить' : 'Edit',
                    style: t.inter(
                      size: 12,
                      weight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: c.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalRow(
    dynamic c,
    AppText t,
    String label,
    String value, {
    bool accent = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: t.inter(size: 12, color: c.muted)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: t.inter(
              size: 12,
              weight: FontWeight.w700,
              color: accent ? c.accent : c.fg,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAvatarSheet(
    BuildContext context,
    AppDataProvider data,
    S s,
    dynamic c,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final t = AppText(c);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.line2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  s.isRu ? 'Фото профиля' : 'Profile photo',
                  style: t.fraunces(size: 21, weight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _avatarAction(
                  ctx,
                  c,
                  t,
                  Icons.photo_library_outlined,
                  s.isRu ? 'Выбрать из галереи' : 'Choose from library',
                  'pick',
                ),
                if (data.profile.avatarBytes != null) ...[
                  const SizedBox(height: 8),
                  _avatarAction(
                    ctx,
                    c,
                    t,
                    Icons.delete_outline_rounded,
                    s.isRu ? 'Удалить фото' : 'Remove photo',
                    'remove',
                    destructive: true,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (!context.mounted || action == null) return;
    if (action == 'remove') {
      final profile = data.profile;
      profile.avatarBytes = null;
      await data.updateProfile(profile);
      return;
    }
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (file == null || !context.mounted) return;
      final sanitized = ImageSanitizer.sanitize(
        await file.readAsBytes(),
        cropSquare: true,
        maxOutputLongEdge: 768,
      );
      final profile = data.profile;
      profile.avatarBytes = sanitized.bytes;
      await data.updateProfile(profile);
    } on PlatformException {
      if (!context.mounted) return;
      BalanceFeedbackHost.maybeOf(context)?.error(
        s.isRu
            ? 'Не удалось открыть галерею. Проверь доступ к фото в Настройках.'
            : 'Could not open the library. Check Photos access in Settings.',
      );
    } on ImageValidationException {
      if (!context.mounted) return;
      BalanceFeedbackHost.maybeOf(context)?.error(
        s.isRu
            ? 'Выбери другое фото: файл слишком большой или повреждён.'
            : 'Choose another photo: this file is too large or damaged.',
      );
    }
  }

  Widget _avatarAction(
    BuildContext context,
    dynamic c,
    AppText t,
    IconData icon,
    String label,
    String value, {
    bool destructive = false,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: destructive ? c.accent2Soft : c.card2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: destructive ? c.accent2 : c.fg),
            const SizedBox(width: 12),
            Text(
              label,
              style: t.inter(
                size: 13,
                weight: FontWeight.w600,
                color: destructive ? c.accent2 : c.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legalSection(BuildContext context, dynamic c, AppText t, S s) {
    return SectionCard(
      key: const ValueKey('profileLastSection'),
      radius: 20,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Column(
        children: [
          _legalLinkRow(
            context,
            c,
            t,
            s.privacyPolicy,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LegalScreen(
                  doc: LegalDoc.privacy,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: c.line.withValues(alpha: 0.5)),
          _legalLinkRow(
            context,
            c,
            t,
            s.termsOfService,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LegalScreen(
                  doc: LegalDoc.terms,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legalLinkRow(
    BuildContext context,
    dynamic c,
    AppText t,
    String label,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: t.inter(size: 13, weight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _invertedTile(
    dynamic c,
    AppText t,
    IconData icon,
    String value,
    String label,
    String sub,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.fg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c.surface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 17, color: c.surface.withValues(alpha: .8)),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 9,
              color: c.surface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 8,
              color: c.surface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(
    dynamic c,
    AppText t,
    String value,
    String label,
    String sub,
  ) {
    return SectionCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: t.fraunces(size: 20, weight: FontWeight.w800)),
          const Spacer(),
          Text(label, style: t.mono(size: 9)),
          Text(sub, style: t.mono(size: 8, color: c.muted)),
        ],
      ),
    );
  }

  void _openStat(BuildContext context, ProfileStatKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => ProfileStatDetailScreen(
          kind: kind,
          onBack: () => Navigator.of(routeContext).pop(),
          onOpenDiary: onOpenDiary == null
              ? null
              : () {
                  Navigator.of(routeContext).pop();
                  onOpenDiary!();
                },
          onOpenWeight: onOpenWeight == null
              ? null
              : () {
                  Navigator.of(routeContext).pop();
                  onOpenWeight!();
                },
        ),
      ),
    );
  }

  Widget _notificationSection(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    AppDataProvider data,
  ) {
    final settings = data.reminderSettings;
    final mode = switch (settings.mode) {
      ReminderMode.smart => s.isRu ? 'Умные' : 'Smart',
      ReminderMode.manual => s.isRu ? 'Мои' : 'Manual',
      ReminderMode.smartAndManual => s.isRu ? 'Умные + мои' : 'Smart + manual',
    };
    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (routeContext) => ReminderSettingsScreen(
            onBack: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
      semanticsLabel: s.isRu
          ? 'Настройки уведомлений'
          : 'Notification settings',
      semanticsValue:
          '$mode, ${data.manualReminders.length} ${s.isRu ? "по расписанию" : "scheduled"}',
      child: SectionCard(
        radius: 20,
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: c.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.isRu ? 'Уведомления' : 'Notifications',
                    style: t.inter(size: 13, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$mode · ${data.manualReminders.length} ${s.isRu ? "по расписанию" : "scheduled"}',
                    style: t.inter(size: 9, color: c.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }

  Widget _settingsSection(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    SettingsProvider settings,
    AppDataProvider data,
  ) {
    return SectionCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.settings,
            style: t.fraunces(size: 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _settingRow(c, t, s.language, [
            _segBtn(
              c,
              t,
              'RU',
              settings.lang == AppLang.ru,
              () => settings.setLang(AppLang.ru),
            ),
            _segBtn(
              c,
              t,
              'EN',
              settings.lang == AppLang.en,
              () => settings.setLang(AppLang.en),
            ),
          ]),
          const SizedBox(height: 12),
          _settingRow(c, t, s.theme, [
            _segBtn(
              c,
              t,
              'Wellness',
              settings.themeMode == AppThemeMode.wellness,
              () => settings.setTheme(AppThemeMode.wellness),
            ),
            _segBtn(
              c,
              t,
              s.isRu ? 'Тёмная' : 'Dark',
              settings.themeMode == AppThemeMode.dark,
              () => settings.setTheme(AppThemeMode.dark),
            ),
          ]),
          const SizedBox(height: 12),
          _settingRow(c, t, s.gender, [
            _segBtn(
              c,
              t,
              s.isRu ? 'Ж' : 'F',
              data.profile.gender == Gender.female,
              () async {
                final p = data.profile;
                p.gender = Gender.female;
                await data.updateProfile(p);
              },
            ),
            _segBtn(
              c,
              t,
              s.isRu ? 'М' : 'M',
              data.profile.gender == Gender.male,
              () async {
                final p = data.profile;
                p.gender = Gender.male;
                await data.updateProfile(p);
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _settingRow(dynamic c, AppText t, String label, List<Widget> buttons) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 270) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: t.inter(size: 13, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 4, runSpacing: 4, children: buttons),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: t.inter(size: 13, weight: FontWeight.w600),
              ),
            ),
            ...buttons,
          ],
        );
      },
    );
  }

  Future<void> _showEditNameSheet(
    BuildContext context,
    AppDataProvider data,
    S s,
    dynamic c,
  ) async {
    final controller = TextEditingController(text: data.profile.name);
    String? error;
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setSheetState) {
              final t = AppText(c);
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.editName,
                      style: t.fraunces(size: 18, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLength: 80,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) {
                        if (error != null) setSheetState(() => error = null);
                      },
                      decoration: InputDecoration(
                        hintText: s.yourName,
                        filled: true,
                        fillColor: c.card2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        errorText: error,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(s.cancel),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PrimaryButton(
                            label: s.save,
                            icon: Icons.check_rounded,
                            onTap: () async {
                              final name = controller.text.trim();
                              if (name.isEmpty) {
                                setSheetState(() => error = s.nameEmptyError);
                                return;
                              }
                              final p = data.profile;
                              p.name = name;
                              await data.updateProfile(p);
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Widget _segBtn(
    dynamic c,
    AppText t,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: ExcludeSemantics(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? c.fg : c.card2,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: t.inter(
                  size: 11,
                  weight: FontWeight.w700,
                  color: active ? c.surface : c.fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
