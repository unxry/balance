import '../models/daily_tip.dart';

// Existing IDs resolve to revised content; retired aliases never enter rotation.
final dailyTipsCatalog = <DailyTip>[
  ...activeDailyTips,
  for (final entry in legacyTipAliases.entries)
    activeDailyTips
        .singleWhere((tip) => tip.id == entry.value)
        .asLegacy(entry.key),
];

const activeDailyTips = <DailyTip>[
  DailyTip(
    id: "nutrition-01",
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Тарелка с продолжением",
      "Добавьте к привычному блюду овощ, который вам нравится. Не нужно менять весь рацион за один день.",
      explanation:
          "Овощи добавляют разнообразие и пищевые волокна. Подойдут свежие, замороженные или консервированные варианты без избытка соли. Конкретная порция зависит от вашего плана.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Выберите одно дополнение к ужину.",
    ),
    en: TipCopy(
      "A plate with room to grow",
      "Add a vegetable you enjoy to a familiar meal. You do not need to change your whole diet today.",
      explanation:
          "Vegetables add variety and fibre. Fresh, frozen or canned options without excess salt can work. Portions depend on your own plan.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Choose one addition to dinner.",
    ),
  ),
  DailyTip(
    id: "nutrition-02",
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Заморозка выручает",
      "Замороженные овощи удобно держать под рукой для супа, пасты или гарнира. Это полноценный вариант для занятого вечера.",
      explanation:
          "Заморозка помогает хранить овощи для быстрого блюда. Состав смеси и соус могут различаться: проверьте упаковку. Это удобный способ разнообразить еду, а не особый продукт для похудения.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Проверьте, что есть в морозилке.",
    ),
    en: TipCopy(
      "Let the freezer help",
      "Keep frozen vegetables ready for soup, pasta or a side dish. They are a practical option on a busy evening.",
      explanation:
          "Frozen vegetables are a practical store-cupboard option. Mixes and sauces vary, so check the package. They offer convenience, not a special weight-loss effect.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Check what is in your freezer.",
    ),
  ),
  DailyTip(
    id: "nutrition-04",
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Обед из того, что есть",
      "Основа из крупы, овощей и удобного источника белка может стать простым обедом. Подойдут и остатки вчерашнего ужина.",
      explanation:
          "Комбинация крупы, овощей и белкового продукта объединяет разные группы пищи. Например, гречка с чечевицей или рыбой и овощами. Здесь нет расчёта калорий и обещания насыщения для всех.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Соберите обед из доступных продуктов.",
    ),
    en: TipCopy(
      "Lunch from what you have",
      "Grains, vegetables and a convenient protein source can make a simple lunch. Leftovers from dinner can work too.",
      explanation:
          "Grain, vegetables and a protein food combine different food groups. Try buckwheat with lentils or fish and vegetables. This is not a calorie calculation or a promise of satiety for everyone.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Put together lunch with ingredients you have.",
    ),
  ),
  DailyTip(
    id: "nutrition-05",
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Чечевица на пробу",
      "Красную чечевицу можно добавить в суп или соус. Начните с небольшого количества, если бобовые пока непривычны.",
      explanation:
          "Бобовые содержат растительный белок и пищевые волокна. При непривычном рационе добавляйте их постепенно; при назначенной лечебной диете обсудите замену со специалистом.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Добавьте чечевицу в список покупок.",
    ),
    en: TipCopy(
      "Try lentils",
      "Red lentils can go into soup or sauce. Start with a little if pulses are new to you.",
      explanation:
          "Pulses provide plant protein and fibre. Introduce unfamiliar foods gradually; discuss substitutions with a professional if you follow a clinical diet.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Add lentils to your shopping list.",
    ),
  ),
  DailyTip(
    id: "nutrition-09",
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Консервы для буднего дня",
      "Фасоль или нут из банки можно промыть и добавить в салат. Полезный набор продуктов не обязан требовать долгой готовки.",
      explanation:
          "Консервированные бобовые экономят время и позволяют добавить растительный белок. Сравните соль на этикетке, при желании промойте. Выбирайте продукт, который подходит вашим ограничениям.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Соберите один быстрый вариант обеда.",
    ),
    en: TipCopy(
      "A cupboard shortcut",
      "Rinse canned beans or chickpeas and add them to a salad. A varied meal does not have to involve lengthy cooking.",
      explanation:
          "Canned pulses save time and add a plant-protein option. Compare label sodium and rinse if desired. Choose a product compatible with your restrictions.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Put together one quick lunch option.",
    ),
  ),
  DailyTip(
    id: "nutrition-18",
    category: TipCategory.nutrition,
    basis: TipBasis.gentleFuel,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Достаточно ли записано?",
      "В некоторые дни в дневнике мало еды. Запись может быть неполной: проверьте пропуски и позаботьтесь о регулярном питании без дополнительных ограничений.",
      explanation:
          "Небольшая сумма в дневнике не доказывает низкое фактическое потребление: часть еды могла не попасть в записи. Если рацион действительно долго скудный или есть слабость, нужна индивидуальная помощь, а не новые ограничения.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Спокойно проверьте полноту вчерашних записей.",
    ),
    en: TipCopy(
      "Is the log complete?",
      "Some days show little food in your diary. The log may be incomplete: check for missing entries and make room for regular meals without further restriction.",
      explanation:
          "A low logged total does not establish actual low intake: entries may be missing. A persistently inadequate diet or weakness calls for individual support, not further restriction.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Gently check whether yesterday's log is complete.",
    ),
  ),
  DailyTip(
    id: "macros-01",
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Белок бывает разным",
      "Яйца, рыба, тофу, бобовые и кисломолочные продукты могут быть источниками белка. Выбирайте то, что доступно и подходит вам.",
      explanation:
          "Белок участвует в поддержании тканей. Разные продукты дают и другие нутриенты; чередуйте доступные варианты. Универсальная высокая норма белка здесь не назначается.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Назовите три удобных для вас источника белка.",
    ),
    en: TipCopy(
      "Protein comes in many forms",
      "Eggs, fish, tofu, pulses and cultured dairy can provide protein. Choose options that are accessible and suit you.",
      explanation:
          "Protein helps maintain tissues. Different foods also supply other nutrients, so rotate accessible choices. No universal high-protein target is prescribed here.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Name three protein foods that work for you.",
    ),
  ),
  DailyTip(
    id: "macros-02",
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Углеводы дают энергию",
      "Хлеб, рис и картофель могут быть частью разнообразного питания. Их не нужно исключать только из-за названия группы нутриентов.",
      explanation:
          "Важны весь рацион и подходящие порции, а не запрет группы продуктов. Цельнозерновые варианты и бобовые дают клетчатку. Хлеб, картофель, рис, паста и фрукты могут оставаться в меню.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Оставьте привычный гарнир и добавьте к нему овощи или бобовые.",
    ),
    en: TipCopy(
      "Carbohydrates provide energy",
      "Bread, rice and potatoes can belong in a varied diet. There is no need to exclude them simply because they contain carbohydrates.",
      explanation:
          "The whole eating pattern and suitable portions matter more than banning a food group. Whole grains and pulses supply fibre. Bread, potatoes, rice, pasta and fruit can remain on the menu.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Keep a familiar side and add vegetables or pulses.",
    ),
  ),
  DailyTip(
    id: "macros-03",
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Жиры тоже нужны",
      "Орехи, семена, масла и другие продукты с жирами могут входить в обычное меню. Не стремитесь сделать весь рацион обезжиренным.",
      explanation:
          "Жир необходим организму. Растительные масла, орехи, семена и рыба дают ненасыщенные жиры; порция и личная переносимость тоже имеют значение. Полностью обезжиривать питание не нужно.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Выберите подходящее растительное масло, орехи или семена для одного блюда.",
    ),
    en: TipCopy(
      "Fat has a place",
      "Nuts, seeds, oils and other foods containing fat can be part of everyday meals. Your whole diet does not need to be fat-free.",
      explanation:
          "Dietary fat is essential. Plant oils, nuts, seeds and fish supply unsaturated fats; portions and individual tolerance still matter. A completely fat-free diet is unnecessary.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Choose suitable plant oil, nuts or seeds for one meal.",
    ),
  ),
  DailyTip(
    id: "macros-04",
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Пара для перекуса",
      "Фрукт и йогурт или хлеб и хумус дают сочетание вкусов и нутриентов. Подбирайте перекус по аппетиту, а не по строгому шаблону.",
      explanation:
          "Сочетайте доступный белковый продукт с фруктом или цельнозерновым хлебом, если это вам подходит. Это пример разнообразия, а не обязательный перекус или фиксированная порция.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Придумайте свою пару для перекуса.",
    ),
    en: TipCopy(
      "A snack pairing",
      "Fruit with yogurt or bread with hummus brings together flavours and nutrients. Let appetite guide your snack rather than a rigid formula.",
      explanation:
          "Pair an accessible protein food with fruit or wholegrain bread if that suits you. This illustrates variety, not a compulsory snack or fixed portion.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Think of your own snack pairing.",
    ),
  ),
  DailyTip(
    id: "macros-13",
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Йогурт без обязательств",
      "Молочный или подходящий растительный йогурт можно сочетать с фруктами и овсяными хлопьями. Состав растительных вариантов отличается — смотрите этикетку.",
      explanation:
          "Молочные и растительные аналоги отличаются по белку, кальцию и добавленному сахару. Читайте этикетку; при исключении молочного выбирайте подходящую обогащённую альтернативу.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Посмотрите состав выбранного йогурта.",
    ),
    en: TipCopy(
      "Yogurt your way",
      "Pair dairy yogurt or a suitable plant alternative with fruit and oats. Plant-based options vary, so check the label.",
      explanation:
          "Dairy and plant alternatives differ in protein, calcium and added sugar. Read the label; an appropriately fortified alternative may help when avoiding dairy.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Look at the ingredients of your chosen yogurt.",
    ),
  ),
  DailyTip(
    id: "macros-17",
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["nhs-fibre"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Клетчатка постепенно",
      "Когда добавляете больше цельных круп и бобовых, двигайтесь постепенно. Резкая перемена привычного меню может быть некомфортной.",
      explanation:
          "Овощи, фрукты, бобовые и цельнозерновые продукты дают разные волокна. Увеличивайте непривычные продукты постепенно и соблюдайте назначенные ограничения при заболеваниях ЖКТ.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Добавьте небольшое количество привычных бобовых или цельной крупы, если переносите их.",
    ),
    en: TipCopy(
      "Fibre at a comfortable pace",
      "Introduce more whole grains and pulses gradually. A sudden change from your usual meals may feel uncomfortable.",
      explanation:
          "Vegetables, fruit, pulses and whole grains provide different fibres. Introduce unfamiliar foods gradually and follow prescribed restrictions for digestive conditions.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Add a little familiar pulse or whole grain if you tolerate it.",
    ),
  ),
  DailyTip(
    id: "hydration-03",
    category: TipCategory.hydration,
    basis: TipBasis.universal,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Вкус без сложности",
      "Долька лимона, ягоды или мята могут сделать воду приятнее. Это вопрос вкуса, а не способ «очистить» организм.",
      explanation:
          "Вода с добавками меняет вкус, но не становится средством сжигания жира. Если вам не подходят кислые добавки, обычная вода тоже нормальный выбор.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Попробуйте воду с любимым вкусом.",
    ),
    en: TipCopy(
      "A simple change of flavour",
      "Lemon, berries or mint can make water more enjoyable. This changes the flavour; it is not a way to detox your body.",
      explanation:
          "Flavouring water does not turn it into a fat-burning treatment. Plain water is equally valid if acidic additions do not suit you.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Try water with a flavour you enjoy.",
    ),
  ),
  DailyTip(
    id: "hydration-04",
    category: TipCategory.hydration,
    basis: TipBasis.water,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Не все напитки записаны",
      "В Balance есть записи воды, но они могут отражать не всё питьё. Не воспринимайте пустую часть шкалы как точное измерение обезвоживания.",
      explanation:
          "Приложение знает только введённые объёмы. Оно не измеряет потери жидкости, поступление воды с едой и другими напитками или обезвоживание.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Проверьте, все ли записи воды внесены.",
    ),
    en: TipCopy(
      "A log is only part of the picture",
      "Your water log may not include everything you drink. An unfilled part of the tracker is not a measurement of dehydration.",
      explanation:
          "The app knows only entered volumes. It does not measure fluid loss, water in food and other drinks, or dehydration.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Check whether your water entries are complete.",
    ),
  ),
  DailyTip(
    id: "hydration-05",
    category: TipCategory.hydration,
    basis: TipBasis.universal,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Чашка тоже считается",
      "Чай, молоко и другие напитки тоже дают жидкость. Шкала воды в приложении — удобная запись, а не полный водный баланс организма.",
      explanation:
          "Часть жидкости поступает с едой, молоком, чаем и другими напитками. Поэтому сумма чистой воды в Balance не равна всей поступившей жидкости.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Отделите запись чистой воды от других напитков; не считайте кольцо полным водным балансом.",
    ),
    en: TipCopy(
      "A cup counts too",
      "Tea, milk and other drinks also provide fluid. The app's water tracker is a convenient log, not a full measure of fluid balance.",
      explanation:
          "Food, milk, tea and other drinks also supply fluid. The plain-water total in Balance is therefore not total fluid intake.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "Distinguish plain water from other drinks; do not read the ring as total fluid balance.",
    ),
  ),
  DailyTip(
    id: "hydration-07",
    category: TipCategory.hydration,
    basis: TipBasis.universal,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "После прогулки",
      "После движения дайте себе возможность отдохнуть и попить по потребности. Погода и нагрузка бывают разными, поэтому единого объёма на всех нет.",
      explanation:
          "Нагрузка и жара могут менять потребности в жидкости. Дневник не рассчитывает индивидуальный водный баланс; соблюдайте клинические ограничения, если они есть.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "После посильной нагрузки предусмотрите доступ к питью и отдыху.",
    ),
    en: TipCopy(
      "After a walk",
      "After moving, leave time to rest and drink as needed. Weather and effort vary, so one fixed amount does not suit everyone.",
      explanation:
          "Activity and heat can change fluid needs. A diary cannot calculate individual fluid balance; follow any clinical restrictions.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "After accessible activity, make drinking and rest available.",
    ),
  ),
  DailyTip(
    id: "hydration-10",
    category: TipCategory.hydration,
    basis: TipBasis.universal,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Шкала без соревнования",
      "Цель воды можно использовать как личный ориентир. Не соревнуйтесь с чужими объёмами и соблюдайте назначенные врачом ограничения жидкости.",
      explanation:
          "Объём из приложения не является лечебным назначением. При ограничениях жидкости из-за заболевания приоритет имеет согласованный с врачом план.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Проверьте, согласуется ли цель приложения с назначенными ограничениями жидкости.",
    ),
    en: TipCopy(
      "A tracker without competition",
      "Use your water goal as a personal guide. Avoid competing with other people's totals, and follow any prescribed fluid restrictions.",
      explanation:
          "An app volume is not a clinical prescription. With a medically prescribed fluid restriction, your agreed care plan takes priority.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "Check whether the app goal agrees with any prescribed fluid restrictions.",
    ),
  ),
  DailyTip(
    id: "hydration-18",
    category: TipCategory.hydration,
    basis: TipBasis.universal,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Жажда не задача на баллы",
      "Не нужно пить через выраженный дискомфорт, чтобы закрыть кольцо. Цель приложения не заменяет ваши ощущения и индивидуальные рекомендации.",
      explanation:
          "Не нужно быстро выпивать большой объём ради показателя. Если питьё вызывает выраженный дискомфорт или есть необычные симптомы, обсудите это с медицинским специалистом.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Не догоняйте шкалу большим объёмом воды за один раз.",
    ),
    en: TipCopy(
      "Thirst is not a score",
      "You do not need to drink through marked discomfort to close a ring. An app goal does not replace your needs or individual guidance.",
      explanation:
          "Avoid rapidly drinking a large volume to satisfy a tracker. Discuss marked discomfort or unusual symptoms with a healthcare professional.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "Avoid catching up with the tracker by drinking a large volume at once.",
    ),
  ),
  DailyTip(
    id: "activity-01",
    category: TipCategory.activity,
    basis: TipBasis.universal,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Небольшой маршрут",
      "Выберите короткий знакомый маршрут и комфортный темп. Прогулка может быть приятной паузой без цели по скорости или расстоянию.",
      explanation:
          "Короткая прогулка — один из вариантов посильного движения. Она не должна компенсировать еду; при боли, головокружении или медицинских ограничениях сначала нужна оценка безопасности.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Наметьте посильный маршрут.",
    ),
    en: TipCopy(
      "A short route",
      "Choose a short familiar route and a comfortable pace. A walk can be a pleasant break without a speed or distance goal.",
      explanation:
          "A short walk is one accessible movement option. It should not compensate for food; pain, dizziness or medical restrictions call for a safety review first.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Plan a manageable route.",
    ),
  ),
  DailyTip(
    id: "activity-02",
    category: TipCategory.activity,
    basis: TipBasis.universal,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Движение бывает разным",
      "Прогулка, движение на коляске, танцы и домашние дела тоже относятся к активности. Выберите то, что доступно вашему телу сегодня.",
      explanation:
          "Общая активность включает бытовое и адаптированное движение. Приложение не знает всей нагрузки по одному счётчику шагов. Выбирайте подходящий способ, а не обязательную тренировку.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Выберите доступное движение: прогулку, движение на коляске или бытовую паузу.",
    ),
    en: TipCopy(
      "Movement takes many forms",
      "Walking, wheeling, dancing and household tasks all count as activity. Choose what is accessible to your body today.",
      explanation:
          "Activity includes household tasks and adapted movement. A step counter does not capture all effort. Choose a suitable option rather than a compulsory workout.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "Choose accessible movement: a walk, wheeling or a household break.",
    ),
  ),
  DailyTip(
    id: "activity-03",
    category: TipCategory.activity,
    basis: TipBasis.universal,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Пауза от стула",
      "Если долго сидите, попробуйте ненадолго сменить позу или подвигаться удобным способом. Дискомфорт — повод остановиться и подобрать другой вариант.",
      explanation:
          "Доступное движение можно распределять в течение дня. Смена положения удобна как короткая пауза; она не гарантирует изменение веса.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Сделайте комфортную паузу в работе.",
    ),
    en: TipCopy(
      "A break from sitting",
      "After sitting for a while, try changing position or moving in an accessible way. If it feels uncomfortable, stop and choose another option.",
      explanation:
          "Accessible movement can be spread through the day. Changing position is a practical short break, without a guaranteed weight effect.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Take a comfortable break from work.",
    ),
  ),
  DailyTip(
    id: "activity-04",
    category: TipCategory.activity,
    basis: TipBasis.steps,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Шаги без сравнения",
      "В приложении есть реальные данные шагов. Смотрите на собственный обычный ритм, а не на чужие рекорды; лёгкий день тоже имеет место.",
      explanation:
          "Данные шагов полезны для сравнения с собственным ритмом, но телефон мог быть не с вами. Снижение счётчика само по себе не доказывает уменьшение всей активности.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Посмотрите на свой ритм без оценки.",
    ),
    en: TipCopy(
      "Steps without comparison",
      "The app has real step data. Compare with your usual rhythm rather than someone else's records; lighter days belong too.",
      explanation:
          "Steps can be compared with your usual pattern, but the device may not have been with you. A lower count does not establish lower total activity.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Look at your own pattern without judging it.",
    ),
  ),
  DailyTip(
    id: "activity-13",
    category: TipCategory.activity,
    basis: TipBasis.universal,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Активность не наказание",
      "Не нужно «отрабатывать» еду движением. Выбирайте активность ради приятного занятия, общения или смены обстановки.",
      explanation:
          "Еда обеспечивает организм энергией независимо от тренировок. Планируйте движение ради самочувствия; не увеличивайте нагрузку как наказание за приём пищи.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Запланируйте движение ради приятного занятия, без компенсации еды.",
    ),
    en: TipCopy(
      "Movement is not punishment",
      "You do not have to earn or burn off food with movement. Choose activity for enjoyment, company or a change of scene.",
      explanation:
          "Food provides energy regardless of exercise. Plan movement for wellbeing, without using extra effort as punishment for eating.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "Plan movement for an enjoyable activity, without compensating for food.",
    ),
  ),
  DailyTip(
    id: "activity-18",
    category: TipCategory.activity,
    basis: TipBasis.universal,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "День без рекорда",
      "Вам не нужно каждый день превосходить вчерашние показатели. Устойчивый ритм включает разные по нагрузке дни.",
      explanation:
          "Нагрузка зависит от самочувствия и обстоятельств. Оставляйте дни полегче; устойчивый подход не требует ежедневно повышать цифры.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Оставьте сегодня посильную нагрузку, даже если вчера её было больше.",
    ),
    en: TipCopy(
      "A day without a record",
      "You do not have to beat yesterday's numbers every day. A sustainable rhythm includes days with different levels of effort.",
      explanation:
          "Effort depends on wellbeing and circumstances. Allow lighter days; a sustainable approach does not demand higher numbers every day.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Keep effort manageable today, even if you did more yesterday.",
    ),
  ),
  DailyTip(
    id: "recovery-01",
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Тихий переход ко сну",
      "Выберите спокойное действие перед сном: чтение, музыку или душ. Повторяющийся ритуал может помочь обозначить конец дня.",
      explanation:
          "Повторяемый спокойный ритуал может помочь организовать вечер. Он не лечит бессонницу и не обещает снижение веса; выбирайте доступный вариант.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Выберите один вечерний ритуал.",
    ),
    en: TipCopy(
      "A quieter transition to sleep",
      "Choose a quiet activity before bed, such as reading, music or a shower. A familiar routine can help mark the end of the day.",
      explanation:
          "A repeatable quiet routine may help structure the evening. It does not treat insomnia or promise weight loss; choose something practical.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Choose one evening ritual.",
    ),
  ),
  DailyTip(
    id: "recovery-04",
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Комната для сна",
      "Проверьте, не мешают ли вам свет, шум или неудобная температура. Начните с одного доступного изменения в спальне.",
      explanation:
          "Свет, шум и комфорт спальни относятся к привычкам сна. Начните с одного изменения, которое можете сделать; при стойких проблемах нужна индивидуальная оценка.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Уберите один источник неудобства.",
    ),
    en: TipCopy(
      "A room for sleep",
      "Check whether light, noise or an uncomfortable temperature is disturbing you. Start with one accessible change in the bedroom.",
      explanation:
          "Light, noise and bedroom comfort belong to sleep habits. Start with one feasible change; persistent problems need individual assessment.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Address one source of discomfort.",
    ),
  ),
  DailyTip(
    id: "recovery-06",
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Кофеин и ваш вечер",
      "Обратите внимание, влияет ли поздний кофе на ваш сон. Если замечаете связь, попробуйте перенести его на более раннее время.",
      explanation:
          "Кофеин может мешать сну. Чувствительность различается; попробуйте более раннее время без требования полностью отказаться от любимого напитка.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Отметьте время последнего кофе.",
    ),
    en: TipCopy(
      "Caffeine and your evening",
      "Notice whether late coffee affects your sleep. If you see a pattern, try having it earlier.",
      explanation:
          "Caffeine can disrupt sleep. Sensitivity varies; trying an earlier time does not require giving up a favourite drink entirely.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Notice when you have your last coffee.",
    ),
  ),
  DailyTip(
    id: "recovery-07",
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Экран можно отложить",
      "Попробуйте закончить просмотр ленты немного раньше, если он затягивает отход ко сну. Выберите занятие, которое приятно завершить.",
      explanation:
          "Если экран отодвигает сон, выберите точку остановки и спокойную альтернативу. Это практический эксперимент, а не способ автоматически исправить вес.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Определите удобный момент убрать телефон.",
    ),
    en: TipCopy(
      "Put the screen aside",
      "Try ending your scroll a little earlier if it delays bedtime. Choose something you can comfortably bring to a close.",
      explanation:
          "If screens delay sleep, choose a stopping point and a quiet alternative. This is a practical experiment, not an automatic way to change weight.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Choose a convenient time to put your phone away.",
    ),
  ),
  DailyTip(
    id: "recovery-15",
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Постоянство без жёсткости",
      "Примерно похожее время сна и подъёма может быть удобной опорой. Рабочие смены и жизненные обстоятельства требуют гибкости.",
      explanation:
          "Регулярный режим может быть удобной опорой, но сменная работа и уход за близкими требуют гибкости. Сон нельзя оценить по записям веса.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Наметьте удобное время завершить вечер с учётом вашего расписания.",
    ),
    en: TipCopy(
      "Consistency with flexibility",
      "Similar sleep and wake times can provide a useful anchor. Shift work and life circumstances may require flexibility.",
      explanation:
          "A regular schedule may provide an anchor, while shift work and caring duties need flexibility. Weight records cannot measure sleep.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Choose a practical time to wind down within your schedule.",
    ),
  ),
  DailyTip(
    id: "recovery-17",
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Когда нужна поддержка",
      "Если проблемы со сном повторяются и мешают днём, обсудите их со специалистом. Приложение не определяет причину и не назначает лечение.",
      explanation:
          "Приложение не выявляет причины усталости и нарушений сна. Если они устойчиво мешают жизни, врач поможет оценить возможные причины и подходящую помощь.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Если сон регулярно мешает днём, запишите вопрос для врача.",
    ),
    en: TipCopy(
      "When to seek support",
      "If sleep problems keep recurring and affect your daytime life, discuss them with a qualified professional. The app cannot diagnose or prescribe treatment.",
      explanation:
          "The app cannot identify causes of fatigue or sleep problems. If they persist and affect daily life, a clinician can assess causes and suitable support.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "If sleep regularly affects your day, note a question for your clinician.",
    ),
  ),
  DailyTip(
    id: "habits-01",
    category: TipCategory.habits,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Один понятный шаг",
      "Формулировка «положить фрукт в сумку» конкретнее, чем «питаться идеально». Небольшое действие легче встроить в обычный день.",
      explanation:
          "Конкретное небольшое действие проще проверить в реальных условиях. Выберите одно доступное изменение, затем оцените удобство, а не идеальную серию.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Сформулируйте одну привычку как действие.",
    ),
    en: TipCopy(
      "One clear step",
      "Putting fruit in your bag is more specific than eating perfectly. A small action is easier to fit into an ordinary day.",
      explanation:
          "A specific small action is easier to try in real conditions. Choose one practical change and judge its usefulness, not a perfect streak.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Describe one habit as a specific action.",
    ),
  ),
  DailyTip(
    id: "habits-04",
    category: TipCategory.habits,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Пропуск не обнуление",
      "После пропуска можно продолжить со следующего удобного действия. Вам не нужно компенсировать день усиленной нагрузкой или ограничениями.",
      explanation:
          "Пропуск записи или прогулки не требует компенсации. Возвращайтесь к обычной еде и посильному ритму, не ужесточая ограничения.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "После пропуска вернитесь к следующему обычному приёму пищи без компенсации.",
    ),
    en: TipCopy(
      "A missed day is not a reset",
      "After a missed day, resume with the next convenient action. You do not need to compensate with extra exercise or restrictions.",
      explanation:
          "A missed entry or walk needs no compensation. Return to regular eating and manageable routines without tightening restrictions.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "After a missed day, return to the next usual meal without compensation.",
    ),
  ),
  DailyTip(
    id: "habits-06",
    category: TipCategory.habits,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "План с запасным выходом",
      "Если привычный обед недоступен, полезно иметь простой запасной вариант. Гибкость помогает продолжать без ощущения провала.",
      explanation:
          "Запасной обед снижает сложность выбора в занятый день. Например, фасоль, хлеб и овощи; состав и порцию подбирайте под свой план.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Выберите запасной вариант обеда.",
    ),
    en: TipCopy(
      "A plan with an alternative",
      "Have a simple alternative when your usual lunch is unavailable. Flexibility helps you continue without feeling you have failed.",
      explanation:
          "A fallback lunch reduces planning effort on a busy day. Beans, bread and vegetables are one option; adapt ingredients and portions to your plan.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Choose a backup lunch option.",
    ),
  ),
  DailyTip(
    id: "habits-14",
    category: TipCategory.habits,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Список коротких рецептов",
      "Соберите несколько блюд, которые умеете готовить без подробной инструкции. Такой список пригодится в уставший вечер.",
      explanation:
          "Небольшой набор знакомых блюд помогает организовать питание без сложного меню. Включайте разные источники белка и овощи, когда это подходит.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Запишите три знакомых блюда.",
    ),
    en: TipCopy(
      "A list of easy meals",
      "List a few meals you can make without detailed instructions. The list can help on a tired evening.",
      explanation:
          "A small repertoire helps organize meals without an elaborate menu. Include varied protein foods and vegetables when suitable.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Write down three familiar meals.",
    ),
  ),
  DailyTip(
    id: "habits-15",
    category: TipCategory.habits,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Планирование покупок",
      "Перед покупками загляните в холодильник и выберите несколько блюд. Это помогает покупать то, чему найдётся применение.",
      explanation:
          "План покупок можно составлять из доступных продуктов. Нет необходимости покупать дорогой суперфуд: обычные крупы, бобовые и сезонные овощи тоже дают разнообразие.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Проверьте один продукт перед покупкой.",
    ),
    en: TipCopy(
      "A little shopping planning",
      "Check the fridge and choose a few meals before shopping. This helps you buy ingredients you are likely to use.",
      explanation:
          "Plan shopping around accessible foods. Expensive superfoods are unnecessary: familiar grains, pulses and seasonal vegetables can provide variety.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Check one ingredient before buying more.",
    ),
  ),
  DailyTip(
    id: "habits-16",
    category: TipCategory.habits,
    basis: TipBasis.food,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Удобство записи",
      "Если записи питания занимают много сил, начните с доступного уровня подробности. Дневник должен помогать, а не занимать весь день.",
      explanation:
          "По дневнику нельзя гарантировать полноту рациона. Если детализация вызывает напряжение, используйте более простой формат или обсудите другой способ наблюдения со специалистом.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Выберите удобное время для записи еды.",
    ),
    en: TipCopy(
      "Make logging convenient",
      "If food logging feels demanding, start with a manageable level of detail. A diary should help without taking over your day.",
      explanation:
          "A diary cannot guarantee complete intake data. If detailed tracking causes distress, use a simpler format or discuss another approach with a professional.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Choose a convenient time to log food.",
    ),
  ),
  DailyTip(
    id: "mindful-02",
    category: TipCategory.mindful,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Пауза для аппетита",
      "Перед едой можно коротко спросить себя, насколько вы голодны и чего хочется. Это наблюдение, а не правило, разрешающее или запрещающее есть.",
      explanation:
          "Голод и насыщение можно замечать без строгих правил. При медицинском плане регулярных приёмов пищи следуйте ему, а не ждите обязательного сигнала голода.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Заметьте самочувствие перед едой, не превращая голод в разрешение или запрет.",
    ),
    en: TipCopy(
      "Check in with your appetite",
      "Before eating, briefly notice your hunger and what appeals to you. This is an observation, not a rule for allowing or forbidding food.",
      explanation:
          "Hunger and fullness can be noticed without rigid rules. If a clinical plan calls for regular meals, follow it rather than waiting for a hunger cue.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "Notice how you feel before eating without making hunger a permission rule.",
    ),
  ),
  DailyTip(
    id: "mindful-03",
    category: TipCategory.mindful,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Еда без ярлыков",
      "Попробуйте описывать еду через вкус, удобство и состав. Слова «плохая» и «запрещённая» редко помогают спокойно выбрать обед.",
      explanation:
          "Продукты различаются по составу, а моральная оценка не описывает рацион. Обсудите тревожные запреты или чувство вины с подходящим специалистом.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Опишите одно блюдо без оценки.",
    ),
    en: TipCopy(
      "Food without labels",
      "Try describing food by taste, convenience and ingredients. Calling it bad or forbidden rarely helps you choose lunch calmly.",
      explanation:
          "Foods differ in composition; a moral label does not describe an eating pattern. Discuss distressing rules or guilt with an appropriate professional.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Describe one dish without judging it.",
    ),
  ),
  DailyTip(
    id: "mindful-08",
    category: TipCategory.mindful,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Голод не ошибка",
      "Если после еды вы всё ещё голодны, можно добавить ещё. План и цифры не обязаны отменять потребность в еде.",
      explanation:
          "Аппетит и потребности не всегда совпадают с планом приложения. Если голод сохраняется или рацион ограничен, оцените регулярность и полноценность еды с поддержкой специалиста.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Если после еды остался голод, оцените, чем можно удобно дополнить приём пищи.",
    ),
    en: TipCopy(
      "Hunger is not a mistake",
      "If you are still hungry after a meal, you can have more. A plan and its numbers do not have to overrule your need for food.",
      explanation:
          "Appetite and needs may differ from an app plan. Persistent hunger or a restrictive diet calls for a review of regular, adequate eating with professional support.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "If still hungry after a meal, consider a practical addition.",
    ),
  ),
  DailyTip(
    id: "mindful-09",
    category: TipCategory.mindful,
    basis: TipBasis.universal,
    sourceIds: ["nhs-eating-support", "cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Сладкое без компенсации",
      "Любимый десерт может быть частью обычной жизни. Не нужно пропускать следующий приём пищи, чтобы его «компенсировать».",
      explanation:
          "Один десерт не требует отменять следующую еду. Вернитесь к привычному ритму; если возникают компенсаторные ограничения, это повод обратиться за поддержкой.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "После десерта оставьте следующий обычный приём пищи на месте.",
    ),
    en: TipCopy(
      "Enjoyment without compensation",
      "A favourite dessert can be part of everyday life. You do not have to skip your next meal to compensate for it.",
      explanation:
          "One dessert does not require cancelling the next meal. Return to your usual routine; compensatory restriction is a reason to seek support.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Keep your next usual meal after having dessert.",
    ),
  ),
  DailyTip(
    id: "mindful-12",
    category: TipCategory.mindful,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Забота в напряжённый день",
      "При напряжении еда может стать торопливой или нерегулярной. Подумайте о доступном приёме пищи и одном другом способе поддержать себя.",
      explanation:
          "Стресс может менять расписание, аппетит и привычки. Он не доказывает блокировку потери жира; приложение не измеряет уровень стресса по весам.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Выберите простую еду и короткую передышку.",
    ),
    en: TipCopy(
      "Care on a stressful day",
      "Stress can make meals rushed or irregular. Consider an accessible meal and one other way to support yourself.",
      explanation:
          "Stress can affect schedules, appetite and habits. It does not establish a block on fat loss; the app cannot measure stress from weight.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Choose a simple meal and a short breather.",
    ),
  ),
  DailyTip(
    id: "mindful-16",
    category: TipCategory.mindful,
    basis: TipBasis.food,
    sourceIds: ["nhs-eating-support", "cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Запись без приговора",
      "Дневник — запись событий, а не оценка характера. Можно посмотреть на привычки с любопытством и выбрать одно удобное изменение.",
      explanation:
          "В дневнике отражена лишь часть жизни. Используйте его для вопросов и удобных действий, а не оценки характера; при навязчивом контроле допустима пауза.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Прочитайте одну запись нейтрально.",
    ),
    en: TipCopy(
      "A log without a verdict",
      "A diary records events; it does not grade your character. Look at patterns with curiosity and choose one practical adjustment.",
      explanation:
          "A diary captures only part of life. Use it for questions and practical actions, not a character judgement; a break is valid if tracking becomes compulsive.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Read one entry neutrally.",
    ),
  ),
  DailyTip(
    id: "progress-01",
    category: TipCategory.progress,
    basis: TipBasis.universal,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Смотрите на недели",
      "Вес меняется не только из-за долгосрочных изменений тела. Несколько недель сопоставимых записей дают больше контекста, чем отдельная цифра.",
      explanation:
          "Вода, еда в пищеварительном тракте и условия измерения могут менять цифру. Сравнивайте сопоставимые наблюдения за недели; причину отдельного скачка график не определяет.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Откройте график на месяц вместо оценки одной последней цифры.",
    ),
    en: TipCopy(
      "Look across weeks",
      "Weight changes for reasons beyond long-term body changes. Several weeks of comparable readings offer more context than one number.",
      explanation:
          "Fluid, digestive contents and measuring conditions can change a reading. Compare observations over weeks; a chart cannot determine the cause of a single jump.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Open the monthly graph instead of judging one latest reading.",
    ),
  ),
  DailyTip(
    id: "progress-02",
    category: TipCategory.progress,
    basis: TipBasis.universal,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Сравнимые условия",
      "Если отслеживаете вес, старайтесь выбирать похожие условия измерения. Так меньше случайных различий, но идеальной точности всё равно не требуется.",
      explanation:
          "Одни весы, ровная поверхность и похожее время уменьшают случайные различия. Ежедневное взвешивание не требуется; при тревоге можно выбрать более редкий ритм.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Выберите удобные условия для следующих измерений.",
    ),
    en: TipCopy(
      "Comparable conditions",
      "If you track weight, aim for similar measuring conditions. This reduces incidental differences without requiring perfect precision.",
      explanation:
          "The same scale, level floor and similar timing reduce incidental differences. Daily weighing is optional; choose a less frequent rhythm if it causes distress.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Choose convenient conditions for future measurements.",
    ),
  ),
  DailyTip(
    id: "progress-08",
    category: TipCategory.progress,
    basis: TipBasis.universal,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Замеры без спешки",
      "При замерах важны одинаковое место и удобное положение ленты. Не затягивайте её и не пытайтесь получить желаемую цифру.",
      explanation:
          "Сантиметры зависят от места и натяжения ленты. Повторяйте технику, не затягивайте ленту и не делайте вывод о жировой или мышечной ткани по одному замеру.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Перед следующим плановым замером проверьте место и натяжение ленты.",
    ),
    en: TipCopy(
      "Measurements at your own pace",
      "When measuring, use the same position and place the tape comfortably. Avoid pulling it tight to obtain a particular number.",
      explanation:
          "Circumferences depend on tape position and tension. Repeat the technique without tightening the tape, and avoid inferring fat or muscle change from one measurement.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "Before your next planned measurement, check tape position and tension.",
    ),
  ),
  DailyTip(
    id: "progress-12",
    category: TipCategory.progress,
    basis: TipBasis.universal,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Плато не диагноз",
      "Ровная линия за короткий период сама по себе не объясняет происходящее. Приложение не может определить медицинскую причину по графику.",
      explanation:
          "Два одинаковых значения или три дня без снижения не подтверждают плато. Отдельный анализ Balance требует данных за недели и всё равно не устанавливает медицинскую причину.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Оставьте короткий ровный участок без срочных изменений питания.",
    ),
    en: TipCopy(
      "A plateau is not a diagnosis",
      "A flat line over a short period does not explain what is happening by itself. The app cannot identify a medical cause from a chart.",
      explanation:
          "Two equal readings or three days without loss do not establish a plateau. The separate Balance analysis needs weeks of data and still cannot identify a medical cause.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Leave a short flat stretch without urgent eating changes.",
    ),
  ),
  DailyTip(
    id: "progress-13",
    category: TipCategory.progress,
    basis: TipBasis.universal,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Разные линии, разные единицы",
      "Килограммы и сантиметры показывают разные измерения. Не сравнивайте их значения напрямую: смотрите на даты и динамику каждого показателя.",
      explanation:
          "Вес и обхваты могут меняться в разном темпе. Они дополняют наблюдение, но не измеряют состав тела; отсутствие изменения одного показателя не отменяет остальных.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "В сравнении проверьте реальные даты веса и обхватов отдельно.",
    ),
    en: TipCopy(
      "Different lines, different units",
      "Kilograms and centimetres measure different things. Avoid comparing their values directly; look at dates and each metric's own pattern.",
      explanation:
          "Weight and circumferences may change at different rates. They add context but do not measure body composition; one unchanged metric does not invalidate the others.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "In comparison, check the actual dates of weight and circumferences separately.",
    ),
  ),
  DailyTip(
    id: "progress-16",
    category: TipCategory.progress,
    basis: TipBasis.universal,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Цель можно обсуждать",
      "Если цель перестала подходить вашей жизни или самочувствию, её можно пересмотреть. При сомнениях о здоровье обсудите ориентиры со специалистом.",
      explanation:
          "Достигнутую цель можно сменить на поддержание. Безопасность и самочувствие важнее дальнейшего снижения; подходящий ориентир можно обсудить с врачом или диетологом.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Проверьте, подходит ли текущая цель; при сомнениях обсудите её со специалистом.",
    ),
    en: TipCopy(
      "Goals can be revisited",
      "If a goal no longer fits your life or wellbeing, you can revisit it. Discuss health-related concerns with a qualified professional.",
      explanation:
          "A reached target can become maintenance. Safety and wellbeing matter more than further loss; discuss a suitable target with a clinician or dietitian.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "Review whether your goal still fits; discuss doubts with a professional.",
    ),
  ),
  DailyTip(
    id: "facts-04",
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Коричневый цвет не гарантия",
      "Тёмный хлеб не обязательно цельнозерновой. О составе лучше расскажет список ингредиентов, чем цвет корочки.",
      explanation:
          "Слова на лицевой стороне и цвет не заменяют состав и таблицу пищевой ценности. Сравнивайте продукты на одинаковую массу, учитывая личные ограничения.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Посмотрите состав привычного хлеба.",
    ),
    en: TipCopy(
      "Brown is not a guarantee",
      "Dark bread is not necessarily wholegrain. The ingredients list tells you more than the colour of its crust.",
      explanation:
          "Front-of-pack words and colour do not replace ingredients and nutrition information. Compare foods on the same weight basis and account for your restrictions.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Check the ingredients of your usual bread.",
    ),
  ),
  DailyTip(
    id: "facts-06",
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Состав и порция",
      "Данные на 100 г и на порцию отвечают на разные вопросы. Перед сравнением продуктов убедитесь, что смотрите на одинаковую основу.",
      explanation:
          "Проверьте, указана ли энергия на 100 г, на порцию или на упаковку. Производитель задаёт способ представления данных, а не обязательный размер вашей еды.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Сравните основу двух этикеток.",
    ),
    en: TipCopy(
      "Ingredients and serving size",
      "Values per 100 grams and per serving answer different questions. Check the basis is the same before comparing products.",
      explanation:
          "Check whether energy is listed per 100 g, serving or package. A manufacturer defines a reporting unit, not a compulsory portion.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Compare the reference amounts on two labels.",
    ),
  ),
  DailyTip(
    id: "facts-09",
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Рецепт меняет цифры",
      "Одинаковые названия блюд могут скрывать разные рецепты. Запись из каталога — ориентир, особенно если состав приготовленного блюда неизвестен.",
      explanation:
          "Каталожное блюдо может отличаться от вашего по ингредиентам и порции. Если рецепт неизвестен, считайте запись оценкой и не делайте точный вывод о дефиците.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Уточните состав одного часто записываемого блюда или помните о его приблизительности.",
    ),
    en: TipCopy(
      "Recipes change the numbers",
      "The same dish name can refer to different recipes. A catalog entry is an estimate, especially when the actual ingredients are unknown.",
      explanation:
          "A catalog dish can differ from yours in ingredients and portion. With an unknown recipe, treat the entry as an estimate rather than proof of an energy deficit.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "Clarify one frequently logged dish or keep its uncertainty in mind.",
    ),
  ),
  DailyTip(
    id: "facts-13",
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: ["nhs-fibre"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Пищевые волокна",
      "Клетчатка содержится в растительных продуктах: бобовых, цельных злаках, овощах и фруктах. Её источники можно менять по вкусу.",
      explanation:
          "Волокна поступают из разных растительных продуктов. Выбирайте доступное сочетание; при назначенной низковолокнистой диете самостоятельно увеличивать их не нужно.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Выберите один переносимый источник клетчатки из привычных продуктов.",
    ),
    en: TipCopy(
      "Dietary fibre",
      "Fibre is found in plant foods such as pulses, whole grains, vegetables and fruit. Choose different sources according to your taste.",
      explanation:
          "Fibre comes from different plant foods. Choose accessible combinations; do not independently increase fibre on a prescribed low-fibre diet.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Choose one tolerated fibre source from familiar foods.",
    ),
  ),
  DailyTip(
    id: "facts-16",
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Сухой и готовый вес",
      "Крупы впитывают воду при приготовлении. Поэтому данные на 100 г сухой и готовой крупы отличаются, даже если это один продукт.",
      explanation:
          "При готовке крупа впитывает воду: масса меняется без добавления энергии от воды. Выбирайте в каталоге запись, соответствующую сухому или готовому весу; это правило расчёта, не диета.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Проверьте, соответствует ли запись крупы её сухому или готовому весу.",
    ),
    en: TipCopy(
      "Dry and cooked weight",
      "Grains absorb water when cooked. Values per 100 grams differ for dry and cooked grains even when they are the same food.",
      explanation:
          "Grain absorbs water during cooking: weight changes without energy from water. Match the catalog entry to dry or cooked weight; this is bookkeeping, not a diet.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Check whether the grain entry matches dry or cooked weight.",
    ),
  ),
  DailyTip(
    id: "facts-18",
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Точность дневника ограничена",
      "Этикетки, рецепты и оценка порции могут отличаться от фактического блюда. Дневник полезен как инструмент наблюдения, даже без абсолютной точности.",
      explanation:
          "Размер порции, состав рецепта и этикетка могут давать погрешность. Приложение видит зарегистрированные данные, а не измеряет фактическое потребление.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task:
          "Уточните одну удобную для вас порцию, без требования абсолютной точности.",
    ),
    en: TipCopy(
      "Food logs have limits",
      "Labels, recipes and portion estimates can differ from the actual meal. A diary can support observation without absolute precision.",
      explanation:
          "Portion size, recipe composition and labels introduce uncertainty. The app sees recorded data rather than measuring actual intake.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task:
          "Clarify one convenient portion without demanding absolute precision.",
    ),
  ),
  DailyTip(
    id: "today-02",
    category: TipCategory.today,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Один продукт для разнообразия",
      "Добавьте в список покупок продукт, которого давно не было в меню. Выберите недорогой и понятный вариант, который хочется попробовать.",
      explanation:
          "Покупка доступного овоща, крупы или бобовых — один способ разнообразить меню. Идея не требует специального продукта и не обещает изменения веса.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Запишите один продукт.",
    ),
    en: TipCopy(
      "One ingredient for variety",
      "Add an ingredient you have not eaten recently to your shopping list. Choose something affordable and familiar enough to enjoy trying.",
      explanation:
          "Buying an accessible vegetable, grain or pulse is one way to vary meals. No special product or weight change is promised.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Write down one ingredient.",
    ),
  ),
  DailyTip(
    id: "today-03",
    category: TipCategory.today,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Обед в календаре",
      "Если дела часто вытесняют еду, оставьте в расписании время на обед. Это забота об удобстве дня, а не новый показатель продуктивности.",
      explanation:
          "Регулярная возможность поесть помогает организовать день. Если пропущены записи, приложение не знает, была ли пропущена еда; действие можно начать с удобного времени для обеда.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Освободите время для одного приёма пищи.",
    ),
    en: TipCopy(
      "Put lunch in the calendar",
      "If tasks often crowd out meals, leave time for lunch in your schedule. This is about making your day workable, not adding a productivity score.",
      explanation:
          "An opportunity to eat helps organize the day. Missing entries do not tell the app whether food was missed; start with a convenient lunch time.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Make time for one meal.",
    ),
  ),
  DailyTip(
    id: "today-07",
    category: TipCategory.today,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Выберите маршрут заранее",
      "Найдите короткий удобный путь для прогулки, если она вам подходит. План можно сократить или перенести по самочувствию.",
      explanation:
          "Посильное движение можно начинать с короткого маршрута. Если он не подходит вашему состоянию, выберите отдых или согласованную альтернативу, без компенсации еды.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Сохраните удобный маршрут.",
    ),
    en: TipCopy(
      "Choose a route in advance",
      "Find a short accessible walking route if walking suits you. You can shorten or postpone it according to how you feel.",
      explanation:
          "Accessible movement can start with a short route. If unsuitable for your condition, choose rest or an agreed alternative, without compensating for food.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Save a convenient route.",
    ),
  ),
  DailyTip(
    id: "today-09",
    category: TipCategory.today,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Разморозьте основу ужина",
      "Если планируете готовить, заранее безопасно разморозьте нужный продукт в холодильнике. Следуйте указаниям на упаковке.",
      explanation:
          "Размораживайте продукт по инструкции и соблюдайте безопасное хранение. Это практическая идея подготовки, без медицинского обещания.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Проверьте, что нужно подготовить к ужину.",
    ),
    en: TipCopy(
      "Prepare a dinner ingredient",
      "If you plan to cook, thaw a needed ingredient safely in the fridge in advance. Follow the instructions on its packaging.",
      explanation:
          "Thaw and store food according to safe package instructions. This is a preparation idea without a medical outcome claim.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Check what needs preparing for dinner.",
    ),
  ),
  DailyTip(
    id: "today-13",
    category: TipCategory.today,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Овощ к привычному блюду",
      "Выберите уже знакомый овощ и придумайте, к чему его добавить. Сегодня не нужен сложный новый рецепт.",
      explanation:
          "Овощ можно добавить к знакомой еде, не заменяя весь приём пищи. Например, замороженную смесь к рису с фасолью. Учитывайте переносимость.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Подготовьте один овощ для следующей еды.",
    ),
    en: TipCopy(
      "A vegetable for a familiar dish",
      "Choose a familiar vegetable and a dish it could go with. Today does not need a complicated new recipe.",
      explanation:
          "A vegetable can complement a familiar meal rather than replace it. Try frozen vegetables alongside rice and beans, accounting for tolerance.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Prepare one vegetable for your next meal.",
    ),
  ),
  DailyTip(
    id: "today-15",
    category: TipCategory.today,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Идея без готовки",
      "Придумайте доступную комбинацию, которую можно собрать без плиты. Она пригодится в поездке или в вечер без сил.",
      explanation:
          "Вариант без плиты: цельнозерновой хлеб, хумус и овощи или йогурт с овсянкой и фруктом. Подберите подходящие замены при аллергиях; КБЖУ здесь не вычислялись.",
      why:
          "Это вариант для наблюдения и практики. Он не доказывает индивидуальную причину изменения веса.",
      task: "Запишите свой вариант еды без плиты.",
    ),
    en: TipCopy(
      "A no-cook idea",
      "Think of an accessible combination that needs no stove. It can help while travelling or on a low-energy evening.",
      explanation:
          "A no-cook option: wholegrain bread, hummus and vegetables, or yogurt with oats and fruit. Adapt for allergies; no nutrient totals have been calculated.",
      why:
          "This is an option for observation and practice, not evidence of an individual cause of weight change.",
      task: "Write down your own no-cook meal.",
    ),
  ),
  DailyTip(
    id: "insight-short",
    category: TipCategory.progress,
    basis: TipBasis.universal,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Три дня — ещё не плато",
      "Несколько дней без снижения не описывают долгосрочный результат.",
      explanation:
          "Вода, недавняя еда и условия измерения могут влиять на вес. По одной цифре Balance не определяет причину. Сопоставляйте наблюдения за более длительный период без требования взвешиваться чаще.",
      why:
          "Короткий отрезок не позволяет отделить обычные колебания от тенденции.",
      task:
          "Оставьте питание без резких изменений и проверьте сопоставимость записей.",
    ),
    en: TipCopy(
      "Three days are not a plateau",
      "A few days without a drop do not describe long-term progress.",
      explanation:
          "Fluid, recent food and measuring conditions may affect weight. Balance cannot infer a cause from one number. Compare a longer period without a demand to weigh more often.",
      why: "A short window cannot separate ordinary variation from a trend.",
      task:
          "Keep eating changes gradual and review whether readings are comparable.",
    ),
  ),
  DailyTip(
    id: "insight-stable",
    category: TipCategory.progress,
    basis: TipBasis.plateau,
    sourceIds: ["mayo-plateau", "niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    weightManagementOnly: true,
    ru: TipCopy(
      "Стабильность за несколько недель",
      "Сглаженный вес относительно стабилен; причина по графику неизвестна.",
      explanation:
          "При достаточно плотных записях можно заметить устойчивую стабильность. Меньшая масса может требовать меньше энергии, но дневник и вес не доказывают личный энергетический баланс. Проверьте записи и привычный ритм; не уменьшайте питание автоматически.",
      why: "Возможное плато — описательная категория алгоритма, а не диагноз.",
      task:
          "Просмотрите несколько недель питания и активности; при длительных трудностях обсудите план со специалистом.",
    ),
    en: TipCopy(
      "Stable over several weeks",
      "Smoothed weight is relatively stable; the chart cannot explain why.",
      explanation:
          "Sufficiently distributed records can reveal stability. A smaller body may need less energy, but logs and weight do not establish your energy balance. Review records and routines without automatically reducing food.",
      why:
          "A possible plateau is a descriptive algorithm category, not a diagnosis.",
      task:
          "Review several weeks of food and activity; discuss persistent difficulties with a professional.",
    ),
  ),
  DailyTip(
    id: "insight-maintenance",
    category: TipCategory.progress,
    basis: TipBasis.maintenance,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Сохранить достигнутое",
      "При поддержании веса дальнейшее снижение не является задачей.",
      explanation:
          "Выбранная цель или стабильные значения около достигнутого ориентира меняют смысл наблюдения. Поддерживайте удобные привычки, разнообразие и посильное движение вместо новых ограничений. Цель приложения не определяет медицински оптимальный вес.",
      why: "Поддержание — самостоятельный результат, а не отсутствие успеха.",
      task: "Выберите одну привычку, которую удобно сохранять длительно.",
    ),
    en: TipCopy(
      "Keep what works",
      "Further weight loss is not the task during maintenance.",
      explanation:
          "A maintenance goal or stable readings near a reached target changes the interpretation. Keep practical routines, variety and accessible movement rather than adding restriction. An app target does not define a medically optimal weight.",
      why: "Maintenance is a result in its own right.",
      task: "Choose one habit you can comfortably keep over time.",
    ),
  ),
  DailyTip(
    id: "insight-down",
    category: TipCategory.progress,
    basis: TipBasis.weight,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Тенденция и отдельные колебания",
      "Направление за недели полезнее оценки одного взвешивания.",
      explanation:
          "Реальная история может идти вниз с отдельными подъёмами. Алгоритм использует дневные медианы, но не измеряет потерю жира и не гарантирует продолжение темпа. При слабости или неожиданном снижении обсудите состояние с врачом.",
      why:
          "Сглаживание уменьшает влияние отдельных цифр, не объясняя их причину.",
      task:
          "Откройте график на месяц и сопоставьте даты, без дополнительных взвешиваний.",
    ),
    en: TipCopy(
      "A trend includes fluctuations",
      "The direction over weeks is more useful than judging one reading.",
      explanation:
          "A downward history can include individual rises. The algorithm uses daily medians but does not measure fat loss or guarantee a continued rate. Discuss weakness or unexpected loss with a clinician.",
      why:
          "Smoothing reduces the influence of individual readings without explaining them.",
      task:
          "Open the monthly graph and compare dates, without extra weigh-ins.",
    ),
  ),
  DailyTip(
    id: "insight-body",
    category: TipCategory.progress,
    basis: TipBasis.body,
    sourceIds: ["nhs-weigh"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Вес и сантиметры — разные наблюдения",
      "Показатели могут меняться в разном темпе.",
      explanation:
          "Сравнивайте каждый ряд по его датам и единицам. Колебания веса и различия техники замера не дают по отдельности измерения мышц или жира. Не подставляйте значения в дни без замеров.",
      why:
          "Совпадение или расхождение графиков не устанавливает изменение состава тела.",
      task: "Откройте сравнение и проверьте даты настоящих измерений.",
    ),
    en: TipCopy(
      "Weight and centimetres are different observations",
      "Metrics may change at different rates.",
      explanation:
          "Compare each series using its own dates and units. Weight fluctuations and measuring technique cannot individually measure muscle or fat. Leave dates without readings empty.",
      why:
          "Matching or diverging graphs do not establish body-composition change.",
      task: "Open comparison and check dates of actual measurements.",
    ),
  ),
  DailyTip(
    id: "insight-long",
    category: TipCategory.progress,
    basis: TipBasis.plateau,
    sourceIds: ["mayo-plateau", "cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    weightManagementOnly: true,
    ru: TipCopy(
      "Когда нужна помощь с планом",
      "Длительную стабильность можно обсудить без поиска вины.",
      explanation:
          "Сначала проверьте полноту записей, тенденцию и посильную активность. Если ситуация долго беспокоит, врач или зарегистрированный диетолог поможет оценить подходящий план. Приложение не назначает анализы, лекарства или снижение калорий.",
      why: "График не различает все поведенческие и медицинские причины.",
      task:
          "Подготовьте даты и вопросы для консультации, а не новый строгий запрет.",
    ),
    en: TipCopy(
      "When to ask for help with a plan",
      "Persistent stability can be discussed without blame.",
      explanation:
          "Review record coverage, the trend and accessible activity first. If concerns persist, a clinician or registered dietitian can assess an appropriate plan. The app does not prescribe tests, medication or calorie cuts.",
      why: "A chart cannot distinguish all behavioural and medical causes.",
      task:
          "Prepare dates and questions for a consultation rather than another strict rule.",
    ),
  ),
  DailyTip(
    id: "meal-breakfast",
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating", "nhs-fibre"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Завтрак из доступных продуктов",
      "Попробуйте овсянку, йогурт и фрукт — или хлеб, яйцо и овощи.",
      explanation:
          "Это примеры сочетания разных групп продуктов. При вегетарианском выборе подойдут бобовая намазка или тофу; при исключении молочного сравните состав обогащённой альтернативы. Размер порции и время еды зависят от вас.",
      why: "Пример не содержит рассчитанных КБЖУ и не обещает снижение веса.",
      task: "Выберите один удобный вариант завтрака с подходящими заменами.",
    ),
    en: TipCopy(
      "Breakfast from accessible foods",
      "Try oats, yogurt and fruit, or bread, egg and vegetables.",
      explanation:
          "These examples combine food groups. Bean spread or tofu can suit vegetarian choices; compare fortified alternatives when avoiding dairy. Portion size and timing depend on your needs.",
      why: "No nutrient totals or weight-loss outcome are claimed.",
      task: "Choose one convenient breakfast with suitable substitutions.",
    ),
  ),
  DailyTip(
    id: "meal-lunch",
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Обед из четырёх компонентов",
      "Белковый продукт, овощи, гарнир и подходящая заправка — удобная отправная точка.",
      explanation:
          "Например, чечевица или курица, гречка и овощи с растительным маслом. Сочетание помогает разнообразить рацион; порции не универсальны, а насыщение индивидуально.",
      why: "Разнообразие важнее поиска одного продукта для похудения.",
      task:
          "Соберите обед из того, что доступно, без обязательной точности пропорций.",
    ),
    en: TipCopy(
      "A lunch with four components",
      "A protein food, vegetables, a side and a suitable dressing offer a starting point.",
      explanation:
          "Try lentils or chicken with buckwheat and vegetables with plant oil. The combination supports variety; portions are not universal and fullness varies.",
      why: "Variety matters more than searching for a single slimming food.",
      task:
          "Build lunch from what is available without compulsory exact proportions.",
    ),
  ),
  DailyTip(
    id: "meal-dinner",
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating", "who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Ужин без запрета гарнира",
      "Рис, картофель или паста могут остаться частью ужина.",
      explanation:
          "Добавьте овощи и доступный источник белка, например фасоль, тофу или рыбу. Само наличие углеводов вечером не доказывает, что питание мешает снижению веса. Учитывайте свой режим и назначения.",
      why: "Группа продуктов и время сами по себе не описывают весь рацион.",
      task: "Выберите привычный гарнир и подходящие дополнения.",
    ),
    en: TipCopy(
      "Dinner can include a side",
      "Rice, potatoes or pasta can stay in dinner.",
      explanation:
          "Add vegetables and an accessible protein source such as beans, tofu or fish. Evening carbohydrate alone does not establish a barrier to weight loss. Consider your routine and care plan.",
      why: "A food group and time alone do not describe the full diet.",
      task: "Choose a familiar side with suitable additions.",
    ),
  ),
  DailyTip(
    id: "meal-budget",
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Разнообразно и недорого",
      "Бобовые, обычные крупы и замороженные овощи помогают собрать простую еду.",
      explanation:
          "Можно приготовить крупу на несколько блюд и менять белковое дополнение. Соблюдайте безопасное хранение и инструкцию продукта. Дорогие добавки для этого не требуются.",
      why: "Это идея организации еды, без вымышленных КБЖУ.",
      task: "Выберите два блюда с одним доступным базовым ингредиентом.",
    ),
    en: TipCopy(
      "Variety on a budget",
      "Pulses, familiar grains and frozen vegetables can make simple meals.",
      explanation:
          "Prepare a grain for different dishes and vary the protein addition. Follow safe storage and package instructions. Expensive supplements are unnecessary.",
      why: "This is a meal-planning idea without invented nutrition totals.",
      task: "Choose two meals sharing an affordable base ingredient.",
    ),
  ),
  DailyTip(
    id: "food-fibre",
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["nhs-fibre"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Клетчатка из разных продуктов",
      "Не обязательно добавлять отруби: начните с привычной еды.",
      explanation:
          "Овощи, овсянка, цельнозерновой хлеб и бобовые — разные варианты. Вводите непривычные продукты постепенно. При заболеваниях ЖКТ и лечебной диете согласуйте изменения.",
      why: "Пример не задаёт персональную норму клетчатки.",
      task: "Добавьте один переносимый источник клетчатки к обычному блюду.",
    ),
    en: TipCopy(
      "Fibre from different foods",
      "Bran is optional: start with familiar foods.",
      explanation:
          "Vegetables, oats, wholegrain bread and pulses offer different choices. Introduce unfamiliar foods gradually. Discuss changes if you have digestive conditions or a clinical diet.",
      why: "This does not set an individual fibre target.",
      task: "Add one tolerated fibre source to a familiar meal.",
    ),
  ),
  DailyTip(
    id: "food-protein",
    usesLoggedMacros: true,
    category: TipCategory.macros,
    basis: TipBasis.food,
    sourceIds: ["who-diet", "niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Разнообразить белковые продукты",
      "Дневник может подсказать идеи для разнообразия, а не диагноз дефицита белка.",
      explanation:
          "Сравните записанные блюда. Можно чередовать яйца, рыбу, птицу, подходящие молочные продукты, фасоль или тофу. Неполные записи и суммы БЖУ не доказывают, сколько белка вы реально получили.",
      why: "Персональная белковая норма не рассчитывается этим советом.",
      task:
          "Найдите в записях один продукт, который хотите заменить или дополнить.",
    ),
    en: TipCopy(
      "Vary protein foods",
      "A diary can suggest variety without diagnosing protein deficiency.",
      explanation:
          "Review logged dishes. Eggs, fish, poultry, suitable dairy, beans or tofu offer options. Incomplete entries and macro totals do not establish actual protein intake.",
      why: "This tip does not calculate an individual protein target.",
      task: "Find one logged food you would like to vary or complement.",
    ),
  ),
  DailyTip(
    id: "diary-gaps",
    category: TipCategory.habits,
    basis: TipBasis.diary,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Записи — ещё не весь рацион",
      "В некоторых завершённых днях нет записей. Это не доказывает, что еды не было.",
      explanation:
          "Приложение не может проверить полноту дневника. Даже заполненные дни могут не включать напитки, перекусы или добавки. Поэтому средняя записанная энергия не равна точно известному потреблению и не доказывает дефицит.",
      why:
          "Пропуски ограничивают интерпретацию, но не устанавливают причину стабильного веса.",
      task:
          "Если вам комфортно, несколько дней отмечайте также напитки и небольшие дополнения.",
    ),
    en: TipCopy(
      "Entries are not the whole diet",
      "Some completed days have no entries. This does not prove food was absent.",
      explanation:
          "The app cannot verify diary completeness. Even logged days may omit drinks, snacks or additions. Average logged energy is not exact known consumption and does not establish a deficit.",
      why: "Gaps limit interpretation without explaining stable weight.",
      task:
          "If comfortable, include drinks and small additions for a few days.",
    ),
  ),
  DailyTip(
    id: "diary-additions",
    category: TipCategory.habits,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Масла и соусы без обвинений",
      "Небольшие добавки тоже могут быть частью записи блюда.",
      explanation:
          "Если хотите проверить дневник, посмотрите на заправки, масло при готовке и напитки. Уточнение записи не означает запрет продукта и не требует сокращения еды.",
      why: "Разница между рецептом и записью создаёт погрешность.",
      task: "Выберите одно часто готовимое блюдо и уточните его состав.",
    ),
    en: TipCopy(
      "Oils and sauces without blame",
      "Small additions can also belong in a dish entry.",
      explanation:
          "To review a diary, look at dressings, cooking oil and drinks. Clarifying a record does not ban a food or require eating less.",
      why: "Differences between a recipe and its entry introduce uncertainty.",
      task: "Choose one familiar dish and clarify its ingredients.",
    ),
  ),
  DailyTip(
    id: "diary-low",
    category: TipCategory.habits,
    basis: TipBasis.gentleFuel,
    sourceIds: ["nhs-eating-support", "niddk-planner", "cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Мало записано — не повод есть меньше",
      "Низкие суммы могут означать пропуски, а иногда — недостаточное питание.",
      explanation:
          "Проверьте полноту записей. Если еда действительно длительно ограничена, есть слабость или навязчивый контроль, обратитесь к врачу или специалисту по питанию. Balance не предлагает урезать рацион или компенсировать его тренировкой.",
      why: "Без проверки нельзя считать низкий дневник доказанным дефицитом.",
      task: "Позаботьтесь о регулярной полноценной еде и подходящей поддержке.",
    ),
    en: TipCopy(
      "A low log is not a reason to eat less",
      "Low totals may reflect missing entries or sometimes inadequate eating.",
      explanation:
          "Review the entries. If intake is persistently restricted, or you experience weakness or compulsive control, seek clinical or nutrition support. Balance does not suggest cutting food or compensating with exercise.",
      why: "An unverified low log cannot establish an energy deficit.",
      task: "Make room for regular adequate eating and appropriate support.",
    ),
  ),
  DailyTip(
    id: "recovery-appetite",
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Сон, аппетит и обычный день",
      "Недосып может затруднять привычный ритм еды и движения.",
      explanation:
          "Balance не знает, как вы спали, по весам. Вместо вывода о гормонах проверьте доступность еды, отдых и вечерний режим; при устойчивых проблемах со сном обратитесь за помощью.",
      why:
          "Связь поведения и сна не означает автоматическую блокировку снижения жира.",
      task: "Выберите одно доступное улучшение вечера.",
    ),
    en: TipCopy(
      "Sleep, appetite and everyday routines",
      "Poor sleep can make eating and movement routines harder.",
      explanation:
          "Balance cannot know your sleep from weight. Rather than infer hormone changes, review access to food, rest and an evening routine; seek help for persistent sleep problems.",
      why: "Links with sleep do not establish an automatic block on fat loss.",
      task: "Choose one feasible improvement to your evening.",
    ),
  ),
  DailyTip(
    id: "recovery-stress",
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Стресс не ставит диагноз графику",
      "Напряжение может менять привычки, но не объясняет каждый скачок веса.",
      explanation:
          "В загруженный день могут измениться аппетит, сон и движение. Приложение не измеряет эти причины. Поддержка, посильный отдых и доступная еда полезнее обвинения себя.",
      why: "Стресс нельзя установить по одному периоду стабильного веса.",
      task: "Подготовьте простой вариант еды и один способ получить поддержку.",
    ),
    en: TipCopy(
      "Stress does not diagnose a chart",
      "Stress may affect habits without explaining every weight change.",
      explanation:
          "A demanding day may affect appetite, sleep and movement. The app does not measure these causes. Support, manageable rest and accessible food are more useful than self-blame.",
      why: "A stable-weight window cannot establish stress.",
      task: "Plan one easy meal and one way to get support.",
    ),
  ),
  DailyTip(
    id: "facts-fluid",
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: [
      "mayo-plateau",
      "nhs-pms",
      "cleveland-fluid",
      "cleveland-exercise",
    ],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Вода и цифра на весах",
      "Кратковременное изменение массы не равно такому же изменению жира.",
      explanation:
          "Соль, изменение количества углеводов и непривычная нагрузка могут сопровождаться изменением воды. Еда в пищеварительном тракте тоже влияет на массу. Гормональные изменения иногда связаны с колебаниями; контекст цикла нельзя вывести по полу. Balance не определяет, какая из причин относится к вам.",
      why: "Это возможные объяснения, а не установленные причины.",
      task:
          "Сравните условия и даты записей без резкого ограничения еды или воды.",
    ),
    en: TipCopy(
      "Water and the scale",
      "A short-term weight change is not an equal change in fat.",
      explanation:
          "Salt, carbohydrate changes and unfamiliar activity may accompany changes in body water. Digestive contents also affect weight. Hormonal changes can accompany fluctuations; sex alone does not reveal cycle context. Balance cannot identify which explanation applies to you.",
      why: "These are possible explanations, not established causes.",
      task:
          "Compare conditions and dates without abruptly restricting food or water.",
    ),
  ),
  DailyTip(
    id: "activity-context",
    category: TipCategory.activity,
    basis: TipBasis.steps,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Посмотреть на обычное движение",
      "Сравнивайте доступные шаги со своим ритмом, без обязательной интенсивной тренировки.",
      explanation:
          "Если устройство было с вами, записи помогут вспомнить более спокойные дни. Но пропуски и неполный день ограничивают сравнение. Шаги не дают точного расхода калорий и не доказывают причину стабильности веса.",
      why: "Данные счётчика не описывают всю физическую активность.",
      task:
          "Выберите удобную паузу для посильного движения, если нет противопоказаний.",
    ),
    en: TipCopy(
      "Review everyday movement",
      "Compare available steps with your own routine without requiring intense workouts.",
      explanation:
          "When the device was with you, records may help recall quieter days. Missing data and partial days limit comparisons. Steps do not provide exact expenditure or explain stable weight.",
      why: "A step counter does not describe all physical activity.",
      task: "Choose an accessible movement break if it is safe for you.",
    ),
  ),
  DailyTip(
    id: "care-context",
    category: TipCategory.mindful,
    basis: TipBasis.universal,
    sourceIds: ["nhs-eating-support", "niddk-planner", "cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Когда общих советов недостаточно",
      "Возраст и состояние здоровья меняют применимость рекомендаций.",
      explanation:
          "Для несовершеннолетних, беременности, грудного вскармливания, риска расстройства питания и известных противопоказаний нужны индивидуальные рекомендации. Если контекст не уточнён, Balance не назначает персональные нормы или усиление ограничений.",
      why: "Общий материал не заменяет план специалиста.",
      task: "Уточните безопасный подход с подходящим медицинским специалистом.",
    ),
    en: TipCopy(
      "When general advice is not enough",
      "Age and health context change which advice is appropriate.",
      explanation:
          "Minors, pregnancy, breastfeeding, eating-disorder risk and known contraindications call for individual guidance. With unknown context, Balance does not prescribe personal targets or tighter restrictions.",
      why: "General information does not replace an individual care plan.",
      task: "Discuss an appropriate approach with a healthcare professional.",
    ),
  ),
];

const legacyTipAliases = <String, String>{
  "nutrition-03": "food-protein",
  "nutrition-06": "meal-breakfast",
  "nutrition-07": "meal-lunch",
  "nutrition-08": "meal-dinner",
  "nutrition-10": "nutrition-01",
  "nutrition-11": "nutrition-02",
  "nutrition-12": "nutrition-04",
  "nutrition-13": "nutrition-05",
  "nutrition-14": "nutrition-09",
  "nutrition-15": "meal-breakfast",
  "nutrition-16": "meal-lunch",
  "nutrition-17": "meal-dinner",
  "macros-05": "macros-13",
  "macros-06": "macros-17",
  "macros-07": "food-fibre",
  "macros-08": "macros-01",
  "macros-09": "macros-02",
  "macros-10": "food-protein",
  "macros-11": "macros-04",
  "macros-12": "macros-13",
  "macros-14": "food-fibre",
  "macros-15": "macros-01",
  "macros-16": "macros-02",
  "macros-18": "diary-low",
  "hydration-01": "hydration-03",
  "hydration-02": "hydration-05",
  "hydration-06": "hydration-03",
  "hydration-08": "hydration-07",
  "hydration-09": "hydration-10",
  "hydration-11": "hydration-03",
  "hydration-12": "hydration-05",
  "hydration-13": "hydration-07",
  "hydration-14": "hydration-04",
  "hydration-15": "hydration-18",
  "hydration-16": "hydration-03",
  "hydration-17": "hydration-05",
  "activity-05": "activity-18",
  "activity-06": "activity-01",
  "activity-07": "activity-02",
  "activity-08": "activity-03",
  "activity-09": "activity-13",
  "activity-10": "activity-18",
  "activity-11": "activity-01",
  "activity-12": "activity-02",
  "activity-14": "activity-context",
  "activity-15": "activity-18",
  "activity-16": "activity-01",
  "activity-17": "activity-02",
  "recovery-02": "recovery-04",
  "recovery-03": "recovery-06",
  "recovery-05": "recovery-15",
  "recovery-08": "recovery-stress",
  "recovery-09": "recovery-01",
  "recovery-10": "recovery-04",
  "recovery-11": "recovery-06",
  "recovery-12": "recovery-07",
  "recovery-13": "recovery-15",
  "recovery-14": "recovery-17",
  "recovery-16": "recovery-stress",
  "recovery-18": "recovery-04",
  "habits-02": "habits-04",
  "habits-03": "habits-06",
  "habits-05": "habits-15",
  "habits-07": "habits-01",
  "habits-08": "habits-04",
  "habits-09": "habits-06",
  "habits-10": "habits-14",
  "habits-11": "habits-15",
  "habits-12": "diary-additions",
  "habits-13": "habits-01",
  "habits-17": "habits-15",
  "habits-18": "diary-additions",
  "mindful-01": "mindful-02",
  "mindful-04": "mindful-09",
  "mindful-05": "mindful-12",
  "mindful-06": "care-context",
  "mindful-07": "mindful-02",
  "mindful-10": "mindful-09",
  "mindful-11": "mindful-12",
  "mindful-13": "mindful-02",
  "mindful-14": "mindful-03",
  "mindful-15": "mindful-08",
  "mindful-17": "mindful-12",
  "mindful-18": "care-context",
  "progress-03": "insight-down",
  "progress-04": "progress-12",
  "progress-05": "diary-gaps",
  "progress-06": "insight-short",
  "progress-07": "progress-01",
  "progress-09": "progress-02",
  "progress-10": "progress-02",
  "progress-11": "progress-12",
  "progress-14": "facts-18",
  "progress-15": "progress-12",
  "progress-17": "progress-08",
  "progress-18": "habits-01",
  "facts-01": "hydration-05",
  "facts-02": "nutrition-02",
  "facts-03": "meal-budget",
  "facts-05": "macros-01",
  "facts-07": "facts-fluid",
  "facts-08": "macros-02",
  "facts-10": "macros-17",
  "facts-11": "care-context",
  "facts-12": "facts-06",
  "facts-14": "hydration-03",
  "facts-15": "facts-06",
  "facts-17": "macros-03",
  "today-01": "today-02",
  "today-04": "today-09",
  "today-05": "today-13",
  "today-06": "today-15",
  "today-08": "today-03",
  "today-10": "today-09",
  "today-11": "today-13",
  "today-12": "today-15",
  "today-14": "today-03",
  "today-16": "today-09",
  "today-17": "today-13",
  "today-18": "today-15",
};
