import '../providers/settings_provider.dart';

/// Localization strings ported from app.js i18n dictionary (RU/EN).
class S {
  final AppLang lang;
  const S(this.lang);

  bool get isRu => lang == AppLang.ru;

  String t(String ru, String en) => isRu ? ru : en;

  // Onboarding
  String get obTitle => t('Настроим\nтвой Balance', "Let's tune\nyour Balance");
  String get obSub => t(
    'Пара шагов — и мы рассчитаем норму калорий и цель',
    "A few steps and we'll calc your calorie target",
  );
  String get obName => t('ИМЯ', 'NAME');
  String get obNameHint => t('Как тебя зовут?', "What's your name?");
  String get obNamePh => t('Введи имя', 'Enter your name');
  String get obGender => t('ПОЛ', 'GENDER');
  String get obAge => t('ВОЗРАСТ', 'AGE');
  String get obHeight => t('РОСТ', 'HEIGHT');
  String get obWeight => t('ВЕС', 'WEIGHT');
  String get obGoal => t('ЦЕЛЬ', 'GOAL');
  String get years => t('лет', 'yrs');
  String get genderF => t('Женский', 'Female');
  String get genderM => t('Мужской', 'Male');
  String get goalLose => t('Сбросить', 'Lose');
  String get goalHold => t('Удержать', 'Maintain');
  String get goalGain => t('Набрать', 'Gain');
  String get continueLbl => t('Продолжить', 'Continue');
  String get agreeToLegalPrefix => t('Я согласен(на) с ', 'I agree to the ');
  String get privacyPolicy =>
      t('Политика конфиденциальности', 'Privacy Policy');
  String get termsOfService => t('Условия использования', 'Terms of Service');
  String get support => t('Поддержка', 'Support');
  String get supportHint =>
      t('Связаться с поддержкой Balance', 'Contact Balance Support');
  String get supportUnavailableTitle =>
      t('Поддержка недоступна', 'Support unavailable');
  String get supportUnavailableBody => t(
    'Сейчас не удалось открыть контакт поддержки. Попробуйте позже.',
    'The support contact could not be opened. Please try again later.',
  );
  String get privacyPolicyAgreement =>
      t('Политикой конфиденциальности', 'Privacy Policy');
  String get termsOfServiceAgreement =>
      t('Условиями использования', 'Terms of Service');
  String get legalAnd => t(' и ', ' and ');
  String get mustAcceptLegal => t(
    'Необходимо принять условия и политику конфиденциальности',
    'You must accept the Terms and Privacy Policy',
  );
  String get updatedOn =>
      t('ОБНОВЛЕНО: 29 АВГУСТА 2026', 'UPDATED: AUGUST 29, 2026');

  // Dashboard
  String get hello => t('Привет', 'Hi');
  String get remainingWord => t('осталось', 'to go');
  String get steps => t('ШАГИ', 'STEPS');
  String get of_ => t('из', 'of');
  String get weight => t('ВЕС', 'WEIGHT');
  String get inMonth => t('за месяц', 'this month');
  String get water => t('ВОДА', 'WATER');
  String get adviceToday => t('СОВЕТ ДНЯ', 'TIP OF THE DAY');
  String get kcalLbl => t('ккал', 'kcal');

  // Weight
  String get weightHistory => t('ИСТОРИЯ ВЕСА', 'WEIGHT HISTORY');
  String get sinceStart => t('от старта', 'since start');
  String get target => t('Цель', 'Target');
  String get rngWeek => t('Неделя', 'Week');
  String get rngMonth => t('Месяц', 'Month');
  String get rng3m => t('3 мес', '3 mo');
  String get rngYear => t('Год', 'Year');
  String get kgLost => t('кг сброшено', 'kg lost');
  String get kgGained => t('кг набрано', 'kg gained');
  String get kgToGoal => t('кг до цели', 'kg to go');
  String get onPlan => t('оценка до цели', 'estimated to goal');
  String get today => t('Сегодня', 'Today');
  String get addWeight => t('Добавить вес', 'Add weight');

  // Steps
  String get stepsToday => t('АКТИВНОСТЬ · СЕГОДНЯ', 'ACTIVITY · TODAY');
  String get active => t('активн.', 'active');
  String get byHours => t('Активность по часам', 'Activity by hour');
  String get weekStrip => t('Неделя', 'This week');

  // Diary
  String get diaryToday => t('ДНЕВНИК · СЕГОДНЯ', 'DIARY · TODAY');
  String get eaten => t('Съедено', 'Eaten');
  String get breakfast => t('Завтрак', 'Breakfast');
  String get lunch => t('Обед', 'Lunch');
  String get dinner => t('Ужин', 'Dinner');
  String get snack => t('Перекус', 'Snack');
  String get emptyAdd => t('Пусто · добавь блюдо', 'Empty · add a meal');
  String get fabSearch => t('Найти', 'Search');
  String get left => t('ккал осталось', 'kcal left');

  // Add food
  String get whatAte => t('Что ты съел?', 'What did you eat?');
  String get searchPh =>
      t('Курица гриль, яблоко...', 'Grilled chicken, apple...');
  String get chipAll => t('Всё', 'All');
  String get chipRecent => t('Недавние', 'Recent');
  String get chipFav => t('Избранное', 'Favorites');
  String get chipMeals => t('Блюда', 'Meals');
  String get chipBrand => t('Бренды', 'Brands');

  // Advice
  String get adviceScreen =>
      t('СОВЕТЫ · ПЛАН НА ДЕНЬ', 'TIPS · PLAN FOR TODAY');
  String get recommendedToday =>
      t('Рекомендуется сегодня', 'Recommended today');
  String get doEat => t('ЧТО ЕСТЬ', 'DO EAT');
  String get avoid => t('ИЗБЕГАТЬ', 'AVOID');
  String get howToEat => t('Как есть', 'How to eat');

  // Profile
  String get profile => t('ПРОФИЛЬ', 'PROFILE');
  String get joined => t('в Balance с', 'with Balance since');
  String get streak => t('СЕРИЯ', 'STREAK');
  String get streakSub => t('дни использования', 'days used');
  String get totLost => t('СБРОШЕНО', 'LOST');
  String get totGained => t('НАБРАНО', 'GAINED');
  String get avgSteps => t('СРЕД. ШАГИ', 'AVG STEPS');
  String get lastWeek => t('за неделю', 'this week');
  String get achievements => t('Достижения', 'Achievements');
  String get editGoal => t('Изменить цель', 'Edit goal');
  String get editName => t('Изменить имя', 'Edit name');
  String get yourName => t('Твоё имя', 'Your name');
  String get save => t('Сохранить', 'Save');
  String get cancel => t('Отмена', 'Cancel');
  String get nameEmptyError => t('Введите имя', 'Please enter a name');
  String get editGoalTitle => t('Изменить цель', 'Edit goal');
  String get currentWeight => t('Текущий вес', 'Current weight');
  String get targetWeight => t('Целевой вес', 'Target weight');
  String get settings => t('Настройки', 'Settings');
  String get language => t('Язык', 'Language');
  String get theme => t('Тема', 'Theme');
  String get gender => t('Пол', 'Gender');

  // Tabs
  String get tabHome => t('Главная', 'Home');
  String get tabWeight => t('Вес', 'Weight');
  String get tabDiary => t('Дневник', 'Diary');
  String get tabProfile => t('Профиль', 'Profile');
}
