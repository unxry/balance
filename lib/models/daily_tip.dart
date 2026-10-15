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

enum TipBasis { universal, food, steps, water, weight, gentleFuel }

class TipCopy {
  final String title;
  final String body;
  final String? why;
  final String? task;
  const TipCopy(this.title, this.body, {this.why, this.task});
}

class DailyTip {
  final String id;
  final TipCategory category;
  final TipCopy ru;
  final TipCopy en;
  final TipBasis basis;
  const DailyTip({
    required this.id,
    required this.category,
    required this.ru,
    required this.en,
    this.basis = TipBasis.universal,
  });
  TipCopy copy(bool isRu) => isRu ? ru : en;
}

class TipContext {
  final bool hasFood;
  final bool hasSteps;
  final bool hasWater;
  final bool hasWeightTrend;
  final bool lowLoggedIntake;
  const TipContext({
    this.hasFood = false,
    this.hasSteps = false,
    this.hasWater = false,
    this.hasWeightTrend = false,
    this.lowLoggedIntake = false,
  });

  bool supports(TipBasis basis) => switch (basis) {
    TipBasis.universal => true,
    TipBasis.food => hasFood,
    TipBasis.steps => hasSteps,
    TipBasis.water => hasWater,
    TipBasis.weight => hasWeightTrend,
    TipBasis.gentleFuel => hasFood && lowLoggedIntake,
  };
}

class TipVisit {
  final String dateKey;
  final String tipId;
  final TipBasis basis;
  final bool completed;
  const TipVisit({
    required this.dateKey,
    required this.tipId,
    this.basis = TipBasis.universal,
    this.completed = false,
  });

  Map<String, Object> toJson() => {
    'date': dateKey,
    'id': tipId,
    'basis': basis.name,
    'completed': completed,
  };
}
