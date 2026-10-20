import '../utils/calendar_date.dart';

enum WeightInsightState {
  insufficientData,
  decreasingTrend,
  stableTrend,
  increasingTrend,
  possiblePlateau,
  uncertainTrend,
  maintenance,
}

class TipSafetyProfile {
  final int? age;
  final bool checked;
  final bool pregnant;
  final bool breastfeeding;
  final bool eatingDisorderRisk;
  final bool medicalRestriction;
  const TipSafetyProfile({
    this.age,
    this.checked = false,
    this.pregnant = false,
    this.breastfeeding = false,
    this.eatingDisorderRisk = false,
    this.medicalRestriction = false,
  });

  bool get adult => age != null && age! >= 18 && age! <= 100;
  bool get allowsWeightManagement =>
      adult &&
      checked &&
      !pregnant &&
      !breastfeeding &&
      !eatingDisorderRisk &&
      !medicalRestriction;

  Map<String, Object> toJson() => {
    'checked': checked,
    'pregnant': pregnant,
    'breastfeeding': breastfeeding,
    'eatingDisorderRisk': eatingDisorderRisk,
    'medicalRestriction': medicalRestriction,
  };

  static TipSafetyProfile fromJson(Object? raw, {int? age}) {
    final m = raw is Map ? raw : const {};
    return TipSafetyProfile(
      age: age,
      checked:
          m['checked'] == true &&
          [
            'pregnant',
            'breastfeeding',
            'eatingDisorderRisk',
            'medicalRestriction',
          ].every((key) => m[key] is bool),
      pregnant: m['pregnant'] == true,
      breastfeeding: m['breastfeeding'] == true,
      eatingDisorderRisk: m['eatingDisorderRisk'] == true,
      medicalRestriction: m['medicalRestriction'] == true,
    );
  }
}

class WeightTrendInsight {
  final WeightInsightState state;
  final DateTime calculatedAt;
  final int measuredDays;
  final int spanDays;
  final int maxGapDays;
  final int rejectedRecords;
  final double? weeklyPercent;
  final double? changePercent;
  final double? noisePercent;
  final bool preliminary;
  final String reason;
  const WeightTrendInsight({
    required this.state,
    required this.calculatedAt,
    this.measuredDays = 0,
    this.spanDays = 0,
    this.maxGapDays = 0,
    this.rejectedRecords = 0,
    this.weeklyPercent,
    this.changePercent,
    this.noisePercent,
    this.preliminary = true,
    required this.reason,
  });

  bool get reliable =>
      !preliminary &&
      rejectedRecords == 0 &&
      state != WeightInsightState.uncertainTrend &&
      state != WeightInsightState.insufficientData;

  String title(bool ru) => switch (state) {
    WeightInsightState.insufficientData =>
      ru ? 'Пока мало данных' : 'Not enough data yet',
    WeightInsightState.decreasingTrend =>
      ru ? 'Тенденция к снижению' : 'A downward trend',
    WeightInsightState.increasingTrend =>
      ru ? 'Тенденция к росту' : 'An upward trend',
    WeightInsightState.stableTrend =>
      ru ? 'Относительно стабильный вес' : 'Relatively stable weight',
    WeightInsightState.possiblePlateau =>
      ru ? 'Возможное плато' : 'A possible plateau',
    WeightInsightState.uncertainTrend =>
      ru ? 'Динамика пока неоднозначна' : 'The pattern is unclear',
    WeightInsightState.maintenance =>
      ru ? 'Поддержание веса' : 'Weight maintenance',
  };

  String explanation(bool ru) => switch (state) {
    WeightInsightState.insufficientData =>
      ru
          ? 'Несколько одинаковых значений за 2–3 дня ещё не означают плато. Для тенденции нужны сопоставимые записи за более длительный период.'
          : 'Two or three days of similar readings do not establish a plateau. A trend needs comparable records over a longer period.',
    WeightInsightState.possiblePlateau =>
      ru
          ? 'За несколько недель сглаженный вес относительно стабилен при цели снижения. Это повод спокойно пересмотреть наблюдения, а не доказательство причины или медицинский диагноз.'
          : 'Over several weeks, the smoothed weight is relatively stable with a weight-loss goal. This invites a review of observations; it does not establish a cause or a medical diagnosis.',
    WeightInsightState.stableTrend =>
      ru
          ? 'Сглаженные значения близки. При коротком периоде вывод предварительный; стабильность сама по себе не объясняет, почему меняется вес.'
          : 'Smoothed readings are close together. Shorter windows give only preliminary evidence; stability alone does not explain why weight changes.',
    WeightInsightState.maintenance =>
      ru
          ? 'Вес относительно стабилен при цели поддержания или рядом с достигнутой целью. Дополнительное похудение не предлагается.'
          : 'Weight is relatively stable with a maintenance goal or near a reached target. Further weight loss is not suggested.',
    WeightInsightState.decreasingTrend =>
      ru
          ? 'Устойчивый наклон реальных измерений направлен вниз. Это изменение массы, а не измерение потери жира или обещание будущего темпа.'
          : 'The robust slope of actual readings points down. This measures body weight, not fat loss, and does not promise a future rate.',
    WeightInsightState.increasingTrend =>
      ru
          ? 'Устойчивый наклон реальных измерений направлен вверх. По весам нельзя определить, какая ткань или жидкость изменилась.'
          : 'The robust slope of actual readings points up. The scale cannot identify a change in a particular tissue or fluid.',
    WeightInsightState.uncertainTrend =>
      reason == 'tooSoon'
          ? (ru
                ? 'Период наблюдений или число измеренных дней пока недостаточны для устойчивого вывода о стабильности. Одна неделя похожих значений ещё не означает плато.'
                : 'The time span or number of measured days needs a longer observation window to establish stability. One week of similar readings does not establish a plateau.')
          : (ru
                ? 'Колебания, пропуски, давность или противоречия записей мешают уверенному выводу. Balance не приписывает им причину.'
                : 'Fluctuations, gaps, old or contradictory records prevent a clear interpretation. Balance does not assign them a cause.'),
  };

  String limits(bool ru) => ru
      ? '${preliminary ? 'Предварительное наблюдение. ' : ''}Только реальные записи за последние 28 дней; не диагноз. Полнота питания, сон, стресс, жидкость и гормональный контекст не устанавливаются по графику.'
      : '${preliminary ? 'Preliminary observation. ' : ''}Only actual readings from the last 28 days; not a diagnosis. The chart cannot establish food-log completeness, sleep, stress, fluid or hormonal context.';

  String action(bool ru) => ru
      ? 'Не меняйте резко питание по одной цифре. Проверьте записи и условия измерений; при длительных затруднениях обсудите план с врачом или квалифицированным диетологом. Частые измерения не обязательны.'
      : 'Avoid abrupt eating changes based on one number. Review records and measuring conditions; discuss persistent difficulties with a clinician or registered dietitian. Frequent weighing is optional.';

  String evidence(bool ru) => ru
      ? '$measuredDays дней с измерениями · период $spanDays дн. · наибольший промежуток $maxGapDays дн.${rejectedRecords > 0 ? ' · спорных записей: $rejectedRecords' : ''}'
      : '$measuredDays measured days · $spanDays-day span · longest gap $maxGapDays days${rejectedRecords > 0 ? ' · disputed records: $rejectedRecords' : ''}';

  String get calculationDateKey => localDateKey(calculatedAt);
}
