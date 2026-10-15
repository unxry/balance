import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/achievement_models.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import '../theme/i18n.dart';
import '../widgets/achievement_medal.dart';
import '../widgets/common.dart';
import '../widgets/premium_motion.dart';

class AchievementsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const AchievementsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = AppText(colors);
    final data = context.watch<AppDataProvider>();
    final strings = S(context.watch<SettingsProvider>().lang);
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.isRu ? 'Достижения' : 'Achievements',
                            style: text.fraunces(
                              size: 27,
                              weight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            strings.isRu
                                ? '${data.achievements.where((item) => item.state == AchievementState.unlocked).length} из ${data.achievements.length} получено'
                                : '${data.achievements.where((item) => item.state == AchievementState.unlocked).length} of ${data.achievements.length} unlocked',
                            style: text.inter(size: 11, color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final category in AchievementCategory.values) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 9),
                sliver: SliverToBoxAdapter(
                  child: MonoLabel(_category(category, strings.isRu)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final items = data.achievements
                          .where((item) => item.definition.category == category)
                          .toList();
                      final item = items[index];
                      final title = strings.isRu
                          ? item.definition.titleRu
                          : item.definition.titleEn;
                      final status = item.state == AchievementState.unlocked
                          ? (strings.isRu ? 'Получено' : 'Unlocked')
                          : (strings.isRu ? 'Прогресс' : 'Progress');
                      return PressableScale(
                        onTap: () => showAchievementDetails(
                          context,
                          item,
                          isRu: strings.isRu,
                        ),
                        semanticsLabel: title,
                        semanticsValue:
                            '$status, ${(item.fraction * 100).round()}%',
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: colors.line.withValues(alpha: .8),
                            ),
                          ),
                          child: Column(
                            children: [
                              AchievementMedal(
                                achievement: item,
                                colors: colors,
                                size: 60,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: text.inter(
                                  size: 10,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: item.fraction,
                                  minHeight: 3,
                                  backgroundColor: colors.track,
                                  valueColor: AlwaysStoppedAnimation(
                                    colors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: data.achievements
                        .where((item) => item.definition.category == category)
                        .length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 142,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }

  String _category(AchievementCategory value, bool isRu) => switch (value) {
    AchievementCategory.weight => isRu ? 'ВЕС' : 'WEIGHT',
    AchievementCategory.nutrition => isRu ? 'ПИТАНИЕ' : 'NUTRITION',
    AchievementCategory.water => isRu ? 'ВОДА' : 'WATER',
    AchievementCategory.steps => isRu ? 'ШАГИ' : 'STEPS',
    AchievementCategory.streak => isRu ? 'СЕРИИ' : 'STREAKS',
    AchievementCategory.diary => isRu ? 'ДНЕВНИК' : 'DIARY',
    AchievementCategory.recipes => isRu ? 'РЕЦЕПТЫ' : 'RECIPES',
    AchievementCategory.consistency => isRu ? 'ПОСТОЯНСТВО' : 'CONSISTENCY',
    AchievementCategory.special => isRu ? 'ОСОБЫЕ' : 'SPECIAL',
  };
}
