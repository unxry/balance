import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/health_service.dart';
import '../services/activity_motion_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/i18n.dart';
import '../widgets/common.dart';
import '../widgets/premium_motion.dart';

class StepsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const StepsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final s = S(context.watch<SettingsProvider>().lang);
    final data = context.watch<AppDataProvider>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GhostBackButton(onTap: onBack),
                const SizedBox(width: 12),
                Expanded(child: MonoLabel(s.stepsToday)),
                if (data.activityAvailable)
                  IconButton(
                    onPressed: data.stepsLoading ? null : data.refreshSteps,
                    tooltip: s.isRu ? 'Обновить' : 'Refresh',
                    icon: Icon(Icons.refresh_rounded, color: c.muted),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: _content(context, c, t, s, data),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    dynamic c,
    AppText t,
    S s,
    AppDataProvider data,
  ) {
    if (data.stepsLoading || data.stepAccess == StepAccessState.loading) {
      return SectionCard(
        radius: 24,
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(strokeWidth: 3, color: c.accent),
            ),
            const SizedBox(height: 18),
            Text(
              s.isRu ? 'Обновляю данные' : 'Updating activity',
              style: t.fraunces(size: 20, weight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    if (data.stepAccess == StepAccessState.authorized &&
        data.todaySteps != null) {
      final steps = data.todaySteps!;
      final goal = _stepGoal(data);
      final progress = (steps / goal).clamp(0.0, 1.0);
      final distanceKm = steps * 0.00075;
      final activeKcal = steps * data.profile.weightKg * 0.0005;
      return SectionCard(
        radius: 26,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          children: [
            SizedBox(
              height: 76,
              child: Center(
                child: BalanceActivityCharacter(
                  colors: c,
                  size: 68,
                  travelWidth: 182,
                  animationMode: data.activitySignalAvailable
                      ? switch (data.activityMotionState) {
                          ActivityMotionState.idle =>
                            BalanceActivityAnimationMode.idle,
                          ActivityMotionState.walk =>
                            BalanceActivityAnimationMode.walk,
                          ActivityMotionState.run =>
                            BalanceActivityAnimationMode.run,
                        }
                      : BalanceActivityAnimationMode.ambient,
                  isVisible: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            BalanceAnimatedValue(
              value: intl.NumberFormat(
                '#,###',
                'ru',
              ).format(steps).replaceAll(',', ' '),
              style: t.fraunces(size: 48, weight: FontWeight.w800),
            ),
            Text(s.isRu ? 'шагов сегодня' : 'steps today', style: t.mono()),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: c.track,
                valueColor: AlwaysStoppedAnimation(c.accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.isRu ? "Цель" : "Goal"}: $goal',
              style: t.inter(size: 11, color: c.muted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _metric(c, t, distanceKm.toStringAsFixed(1), 'km'),
                const SizedBox(width: 10),
                _metric(c, t, activeKcal.round().toString(), s.kcalLbl),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              s.isRu
                  ? 'Данные Apple Health за текущий календарный день'
                  : 'Apple Health data for the current calendar day',
              textAlign: TextAlign.center,
              style: t.inter(size: 10, color: c.muted),
            ),
          ],
        ),
      );
    }

    final denied = data.stepAccess == StepAccessState.denied;
    final restricted = data.stepAccess == StepAccessState.restricted;
    final unavailable = data.stepAccess == StepAccessState.unavailable;
    final title = denied
        ? (s.isRu ? 'Доступ к шагам закрыт' : 'Step access is denied')
        : restricted || unavailable
        ? (s.isRu ? 'Apple Health недоступен' : 'Apple Health is unavailable')
        : (s.isRu ? 'Подключи данные шагов' : 'Connect step data');
    final body = denied
        ? (s.isRu
              ? 'Разреши Balance читать шаги в настройках доступа Apple Health.'
              : 'Allow Balance to read steps in Apple Health access settings.')
        : restricted || unavailable
        ? (s.isRu
              ? 'HealthKit не поддерживается или ограничен на этом устройстве.'
              : 'HealthKit is unsupported or restricted on this device.')
        : (s.isRu
              ? 'Balance использует данные Apple Health, чтобы учитывать активность в дневном балансе.'
              : 'Balance uses Apple Health activity in your daily balance.');

    return SectionCard(
      radius: 24,
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.card2),
            child: Icon(
              denied ? Icons.lock_outline_rounded : Icons.favorite_outline,
              size: 32,
              color: denied ? c.accent2 : c.accent,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: t.fraunces(size: 22, weight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: t.inter(size: 13, color: c.muted, height: 1.45),
          ),
          if (data.stepsError != null) ...[
            const SizedBox(height: 10),
            Text(
              s.isRu
                  ? 'Не удалось обновить данные. Попробуй ещё раз.'
                  : 'Could not update activity. Try again.',
              textAlign: TextAlign.center,
              style: t.inter(size: 11, color: c.accent2),
            ),
          ],
          if (!restricted && !unavailable) ...[
            const SizedBox(height: 20),
            PrimaryButton(
              label: denied
                  ? (s.isRu ? 'Разрешить в настройках' : 'Allow in Settings')
                  : (s.isRu ? 'Подключить шаги' : 'Connect steps'),
              icon: denied ? Icons.settings_outlined : Icons.favorite_rounded,
              onTap: denied ? data.openHealthSettings : data.connectSteps,
            ),
          ],
        ],
      ),
    );
  }

  int _stepGoal(AppDataProvider data) => switch (data.profile.activityLevel) {
    ActivityLevel.sedentary => 6000,
    ActivityLevel.light => 8000,
    ActivityLevel.moderate => 10000,
    ActivityLevel.active => 12000,
  };

  Widget _metric(dynamic c, AppText t, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: c.card2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: t.fraunces(size: 20, weight: FontWeight.w700)),
            Text(label, style: t.mono(size: 8)),
          ],
        ),
      ),
    );
  }
}
