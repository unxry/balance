enum AchievementCategory {
  weight,
  nutrition,
  water,
  steps,
  streak,
  diary,
  recipes,
  consistency,
  special,
}

enum AchievementTier { bronze, silver, gold, premium }

enum AchievementState { locked, inProgress, unlocked }

class AchievementDefinition {
  final String id;
  final AchievementCategory category;
  final AchievementTier tier;
  final String titleRu;
  final String titleEn;
  final String descriptionRu;
  final String descriptionEn;
  final String requirementRu;
  final String requirementEn;
  final String metric;
  final double targetValue;
  final String symbol;

  const AchievementDefinition({
    required this.id,
    required this.category,
    required this.tier,
    required this.titleRu,
    required this.titleEn,
    required this.descriptionRu,
    required this.descriptionEn,
    required this.requirementRu,
    required this.requirementEn,
    required this.metric,
    required this.targetValue,
    required this.symbol,
  });
}

class AchievementProgress {
  final AchievementDefinition definition;
  final double currentValue;
  final AchievementState state;
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.definition,
    required this.currentValue,
    required this.state,
    this.unlockedAt,
  });

  double get fraction => definition.targetValue <= 0
      ? 0
      : (currentValue / definition.targetValue).clamp(0, 1);

  double get remaining =>
      (definition.targetValue - currentValue).clamp(0, double.infinity);
}

class AchievementMetrics {
  final Map<String, double> values;

  const AchievementMetrics(this.values);

  double value(String metric) => values[metric] ?? 0;
}
