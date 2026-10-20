import 'weight_trend_insight.dart';

enum TipCategory {
  nutrition('Питание', 'Balanced eating'),
  macros('БЖУ', 'Protein, fats & carbs'),
  hydration('Вода', 'Hydration'),
  activity('Движение', 'Movement'),
  recovery('Восстановление', 'Rest & sleep'),
  habits('Привычки', 'Habits'),
  mindful('Осознанность', 'Mindful eating'),
  progress('Прогресс', 'Progress'),
  facts('Интересный факт', 'Food facts'),
  today('Маленький шаг', 'One small action');

  final String ru;
  final String en;
  const TipCategory(this.ru, this.en);
  String label(bool isRu) => isRu ? ru : en;
}

enum TipBasis {
  universal,
  food,
  steps,
  water,
  weight,
  gentleFuel,
  plateau,
  maintenance,
  diary,
  body,
}

enum TipEvidenceLevel { guidance, practicalIdea, unverified }

class TipCopy {
  final String title;
  final String body;
  final String? why;
  final String? task;
  final String? explanation;
  const TipCopy(this.title, this.body, {this.why, this.task, this.explanation});
}

class DailyTip {
  final String id;
  final TipCategory category;
  final TipCopy ru;
  final TipCopy en;
  final TipBasis basis;
  final List<String> sourceIds;
  final TipEvidenceLevel evidenceLevel;
  final List<String> safetyTags;
  final List<String> contraindicationRules;
  final bool weightManagementOnly;
  final bool retired;
  final String? canonicalId;
  final int version;
  final bool usesLoggedMacros;
  const DailyTip({
    required this.id,
    required this.category,
    required this.ru,
    required this.en,
    this.basis = TipBasis.universal,
    this.sourceIds = const [],
    this.evidenceLevel = TipEvidenceLevel.unverified,
    this.safetyTags = const ['noRestriction', 'adaptToNeeds'],
    this.contraindicationRules = const ['followClinicalPlan', 'avoidAllergens'],
    this.weightManagementOnly = false,
    this.retired = false,
    this.canonicalId,
    this.version = 3,
    this.usesLoggedMacros = false,
  });
  TipCopy copy(bool isRu) => isRu ? ru : en;
  List<String> get requiredSignals => [
    if (basis != TipBasis.universal) basis.name,
    if (usesLoggedMacros) ...['loggedMacros', 'distinctFoods'],
  ];
  List<String> get eligibilityRules => [
    if (basis != TipBasis.universal) 'optInAndRealSignal',
    if (weightManagementOnly) 'adultSafetyConfirmed',
  ];
  DailyTip asLegacy(String legacyId) => DailyTip(
    id: legacyId,
    category: category,
    ru: ru,
    en: en,
    basis: basis,
    sourceIds: sourceIds,
    evidenceLevel: evidenceLevel,
    safetyTags: safetyTags,
    contraindicationRules: contraindicationRules,
    weightManagementOnly: weightManagementOnly,
    usesLoggedMacros: usesLoggedMacros,
    retired: true,
    canonicalId: id,
  );
}

class TipContext {
  final bool hasFood;
  final bool hasSteps;
  final bool hasWater;
  final bool hasWeightTrend;
  final bool lowLoggedIntake;
  final bool diaryGaps;
  final bool hasBody;
  final bool maintenance;
  final WeightTrendInsight? insight;
  final TipSafetyProfile safety;
  final int loggedFoodDays;
  final int distinctFoods;
  final double? loggedProteinG;
  final double? loggedFatG;
  final double? loggedCarbsG;
  const TipContext({
    this.hasFood = false,
    this.hasSteps = false,
    this.hasWater = false,
    this.hasWeightTrend = false,
    this.lowLoggedIntake = false,
    this.diaryGaps = false,
    this.hasBody = false,
    this.maintenance = false,
    this.insight,
    this.safety = const TipSafetyProfile(),
    this.loggedFoodDays = 0,
    this.distinctFoods = 0,
    this.loggedProteinG,
    this.loggedFatG,
    this.loggedCarbsG,
  });

  bool supports(TipBasis basis) => switch (basis) {
    TipBasis.universal => true,
    TipBasis.food => hasFood,
    TipBasis.steps => hasSteps,
    TipBasis.water => hasWater,
    TipBasis.weight => hasWeightTrend,
    TipBasis.gentleFuel => hasFood && lowLoggedIntake,
    TipBasis.plateau =>
      insight?.state == WeightInsightState.possiblePlateau &&
          safety.allowsWeightManagement,
    TipBasis.maintenance => maintenance,
    TipBasis.diary => hasFood && diaryGaps,
    TipBasis.body => hasBody && hasWeightTrend,
  };

  String reason(TipBasis basis, bool ru) => switch (basis) {
    TipBasis.universal =>
      ru
          ? 'Общий материал; личная причина не устанавливалась.'
          : 'General information; no personal cause was established.',
    TipBasis.food =>
      ru
          ? 'В последние 7 дней есть записи питания. Полнота рациона неизвестна.'
          : 'Food was logged in the last 7 days. Full intake is unknown.',
    TipBasis.diary =>
      ru
          ? 'В части последних 7 завершённых дней нет записей. Это не доказывает пропуск еды.'
          : 'Some of the last 7 completed days have no entries. This does not establish missed meals.',
    TipBasis.gentleFuel =>
      ru
          ? 'В нескольких завершённых днях записано мало еды. Записи могут быть неполными; ограничивать питание сильнее не предлагается.'
          : 'Several completed days have low logged intake. Entries may be incomplete; further restriction is not suggested.',
    TipBasis.weight =>
      ru
          ? 'Есть достаточно реальных записей для наблюдения за тенденцией. Причины изменения веса неизвестны.'
          : 'There are enough actual readings to observe a trend. The causes of weight change are unknown.',
    TipBasis.plateau => insight?.explanation(ru) ?? '',
    TipBasis.maintenance =>
      ru
          ? 'Выбрано поддержание или сглаженный вес близок к достигнутой цели. Советы по дальнейшему похудению не предлагаются.'
          : 'Maintenance is selected or smoothed weight is near a reached target. Further weight-loss advice is not offered.',
    TipBasis.steps =>
      ru
          ? 'Доступны реальные данные шагов. Они не измеряют все энергозатраты.'
          : 'Actual step data is available. It does not measure all energy expenditure.',
    TipBasis.water =>
      ru
          ? 'Есть записи воды. По ним нельзя определить полный водный баланс.'
          : 'Water has been logged. This cannot establish total fluid balance.',
    TipBasis.body =>
      ru
          ? 'Есть реальные записи веса и обхватов. По ним нельзя определить состав тела.'
          : 'Actual weight and circumference readings exist. These cannot establish body composition.',
  };
}

class TipVisit {
  final String dateKey;
  final String tipId;
  final TipBasis basis;
  final bool completed;
  final String? reasonRu;
  final String? reasonEn;
  final int catalogVersion;
  const TipVisit({
    required this.dateKey,
    required this.tipId,
    this.basis = TipBasis.universal,
    this.completed = false,
    this.reasonRu,
    this.reasonEn,
    this.catalogVersion = 0,
  });

  Map<String, Object> toJson() => {
    'date': dateKey,
    'id': tipId,
    'basis': basis.name,
    'completed': completed,
    if (reasonRu != null) 'reasonRu': reasonRu!,
    if (reasonEn != null) 'reasonEn': reasonEn!,
    if (catalogVersion > 0) 'catalogVersion': catalogVersion,
  };
}
