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
  variety,
  observation,
}

enum TipEvidenceLevel { guidance, practicalIdea, unverified }

enum TipDestination { none, food, weight, insights }

class TipCopy {
  final String title;
  final String body;
  final String? why;
  final String? task;
  final String? explanation;
  final List<String> steps;
  final String? example;
  final String? alternative;
  final String? doneWhen;
  const TipCopy(
    this.title,
    this.body, {
    this.why,
    this.task,
    this.explanation,
    this.steps = const [],
    this.example,
    this.alternative,
    this.doneWhen,
  });
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
  final String? topic;
  final TipDestination destination;
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
    this.version = 4,
    this.usesLoggedMacros = false,
    this.topic,
    this.destination = TipDestination.none,
  });
  String get topicKey => topic ?? canonicalId ?? id;
  TipCopy copy(bool isRu) => isRu ? ru : en;
  List<String> get requiredSignals => [
    if (basis != TipBasis.universal) basis.name,
    if (usesLoggedMacros) ...['loggedMacros', 'distinctFoods'],
  ];
  List<String> get eligibilityRules => [
    if (basis != TipBasis.universal) 'optInAndRealSignal',
    if (weightManagementOnly) 'adultSafetyConfirmed',
  ];
  DailyTip asLegacy(String legacyId, {String? canonicalId}) => DailyTip(
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
    canonicalId: canonicalId ?? id,
    topic: topicKey,
    destination: destination,
    version: version,
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
  final bool repeatedLoggedFoods;
  final bool sparseWeight;
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
    this.repeatedLoggedFoods = false,
    this.sparseWeight = false,
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
    TipBasis.variety => hasFood && repeatedLoggedFoods,
    TipBasis.observation => sparseWeight,
  };

  String reason(TipBasis basis, bool ru) => switch (basis) {
    TipBasis.universal =>
      ru
          ? 'Практическая идея на сегодня. Выберите подходящий вам вариант.'
          : 'A practical idea for today. Choose an option that suits you.',
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
    TipBasis.variety =>
      ru
          ? 'В $loggedFoodDays завершённых днях среди записей повторяются продукты; разных записанных продуктов: $distinctFoods. Это описание записей, а не всего рациона.'
          : 'Across $loggedFoodDays completed logged days, foods recur; distinct logged foods: $distinctFoods. This describes records, not your full diet.',
    TipBasis.observation =>
      ru
          ? 'В окне анализа ${insight?.measuredDays ?? 0} дней с измерениями. Для устойчивого вывода этого покрытия пока недостаточно; отсутствие записи не означает отсутствие взвешивания.'
          : 'The analysis window has ${insight?.measuredDays ?? 0} measured days. Coverage is insufficient for a robust conclusion; a missing entry does not prove no weigh-in happened.',
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
  final int completedVersion;
  final String? selectedId;
  final List<TipVisit> alternatives;
  const TipVisit({
    required this.dateKey,
    required this.tipId,
    this.basis = TipBasis.universal,
    this.completed = false,
    this.reasonRu,
    this.reasonEn,
    this.catalogVersion = 0,
    this.completedVersion = 0,
    this.selectedId,
    this.alternatives = const [],
  });
  TipVisit get displayed {
    for (final choice in alternatives) {
      if (choice.tipId == selectedId) return choice;
    }
    return this;
  }

  int get completionVersion =>
      completedVersion > 0 ? completedVersion : catalogVersion;

  TipVisit copyWith({
    bool? completed,
    int? completedVersion,
    String? selectedId,
    bool clearSelection = false,
    List<TipVisit>? alternatives,
  }) => TipVisit(
    dateKey: dateKey,
    tipId: tipId,
    basis: basis,
    completed: completed ?? this.completed,
    reasonRu: reasonRu,
    reasonEn: reasonEn,
    catalogVersion: catalogVersion,
    completedVersion: completedVersion ?? this.completedVersion,
    selectedId: clearSelection ? null : selectedId ?? this.selectedId,
    alternatives: alternatives ?? this.alternatives,
  );

  Map<String, Object> toJson() => {
    'date': dateKey,
    'id': tipId,
    'basis': basis.name,
    'completed': completed,
    if (reasonRu != null) 'reasonRu': reasonRu!,
    if (reasonEn != null) 'reasonEn': reasonEn!,
    if (catalogVersion > 0) 'catalogVersion': catalogVersion,
    if (completedVersion > 0) 'completedVersion': completedVersion,
    if (selectedId != null) 'selectedId': selectedId!,
    if (alternatives.isNotEmpty)
      'alternatives': alternatives.map((v) => v.toJson()).toList(),
  };
}
