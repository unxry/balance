import '../models/daily_tip.dart';

// Retired copy stays readable; only active plans enter daily rotation.
final dailyTipsCatalog = <DailyTip>[
  ...activeDailyTips,
  ...retiredDailyTips,
  for (final entry in legacyTipAliases.entries)
    if (!retiredDailyTips.any((tip) => tip.id == entry.key))
      [...activeDailyTips, ...retiredDailyTips]
          .singleWhere(
            (tip) =>
                tip.id == (preservedLegacyContent[entry.key] ?? entry.value),
          )
          .asLegacy(entry.key, canonicalId: entry.value),
];

const activeDailyTips = <DailyTip>[
  DailyTip(
    id: "nutrition-01",
    topic: "vegetable-addition",
    destination: TipDestination.food,
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Добавьте овощ к ужину",
      "Оставьте привычное блюдо и добавьте один доступный овощ.",
      task: "Дополните сегодняшний ужин овощами.",
      steps: [
        "Выберите овощ, который уже есть дома.",
        "Подайте его рядом с привычным блюдом или добавьте при готовке.",
      ],
      example: "Макароны с фасолью и помидором; картофель с рыбой и огурцом.",
      alternative:
          "Нет свежих овощей — подойдёт подходящая замороженная смесь.",
      doneWhen: "Овощ добавлен к одному приёму пищи, а не вместо всей еды.",
      why:
          "Так в знакомом блюде появляется ещё один источник клетчатки без сложного нового рецепта.",
      explanation:
          "Овощи добавляют разнообразие и пищевые волокна. Подойдут свежие, замороженные или консервированные варианты без избытка соли. Конкретная порция зависит от вашего плана.",
    ),
    en: TipCopy(
      "Add a vegetable to dinner",
      "Keep a familiar meal and add one accessible vegetable.",
      task: "Include a vegetable with dinner today.",
      steps: [
        "Choose a vegetable you already have.",
        "Serve it alongside the meal or add it while cooking.",
      ],
      example: "Pasta with beans and tomato; potato with fish and cucumber.",
      alternative: "No fresh vegetables? A suitable frozen mix can work.",
      doneWhen:
          "A vegetable accompanies one meal rather than replacing the whole meal.",
      why:
          "This adds a fibre source to familiar food without a complicated new recipe.",
      explanation:
          "Vegetables add variety and fibre. Fresh, frozen or canned options without excess salt can work. Portions depend on your own plan.",
    ),
  ),
  DailyTip(
    id: "nutrition-02",
    topic: "meal-building",
    destination: TipDestination.food,
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Приготовьте ужин с замороженными овощами",
      "Не начинайте с нового рецепта: используйте знакомую основу.",
      task: "Добавьте подходящую овощную смесь к одному блюду.",
      steps: [
        "Проверьте морозилку и состав смеси.",
        "Приготовьте её по упаковке и соедините с основой и белковым продуктом.",
      ],
      example: "Рис + овощная смесь + тофу; паста + овощи + фасоль.",
      alternative: "Нет смеси — подойдут овощи, которые уже есть дома.",
      doneWhen: "Одна комбинация приготовлена или выбрана на ужин.",
      why:
          "Замороженная заготовка сокращает подготовку овощей; блюдо остаётся разнообразным.",
      explanation:
          "Заморозка помогает хранить овощи для быстрого блюда. Состав смеси и соус могут различаться: проверьте упаковку. Это удобный способ разнообразить еду, а не особый продукт для похудения.",
    ),
    en: TipCopy(
      "Cook dinner with frozen vegetables",
      "Use a familiar base rather than learning a new recipe.",
      task: "Add a suitable frozen vegetable mix to one meal.",
      steps: [
        "Check your freezer and the ingredients on the pack.",
        "Cook as directed and combine with a base and protein food.",
      ],
      example: "Rice + vegetables + tofu; pasta + vegetables + beans.",
      alternative: "No frozen mix? Use vegetables you already have.",
      doneWhen: "One combination is cooked or chosen for dinner.",
      why:
          "Frozen vegetables reduce preparation while keeping the meal varied.",
      explanation:
          "Frozen vegetables are a practical freezer staple. Mixes and sauces vary, so check the package. They offer convenience, not a special weight-loss effect.",
    ),
  ),
  DailyTip(
    id: "nutrition-05",
    topic: "pulse-introduction",
    destination: TipDestination.food,
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Попробуйте чечевицу в знакомом супе",
      "Начните с небольшого дополнения, если бобовые вам подходят.",
      task: "Добавьте немного чечевицы в привычный суп или соус.",
      steps: [
        "Выберите красную чечевицу и проверьте инструкцию приготовления.",
        "Сначала попробуйте небольшое количество с привычной едой.",
      ],
      example: "Овощной суп с чечевицей; томатный соус с чечевицей к пасте.",
      alternative:
          "Быстрее — подходящая готовая фасоль; при лечебной диете сначала уточните замену.",
      doneWhen: "Выбран или приготовлен один переносимый вариант.",
      why:
          "Бобовые добавляют растительный белок и клетчатку; постепенная проба помогает оценить переносимость.",
      explanation:
          "Бобовые содержат растительный белок и пищевые волокна. При непривычном рационе добавляйте их постепенно; при назначенной лечебной диете обсудите замену со специалистом.",
    ),
    en: TipCopy(
      "Try lentils in a familiar soup",
      "Start with a small addition if pulses suit you.",
      task: "Add a little lentil to a familiar soup or sauce.",
      steps: [
        "Choose red lentils and check the cooking instructions.",
        "Try a small amount alongside familiar food first.",
      ],
      example: "Vegetable soup with lentils; lentil tomato sauce with pasta.",
      alternative:
          "For speed, use suitable ready-cooked beans; check substitutions on a clinical diet.",
      doneWhen: "One tolerated option is chosen or cooked.",
      why:
          "Pulses add plant protein and fibre; a gradual trial lets you assess tolerance.",
      explanation:
          "Pulses provide plant protein and fibre. Introduce unfamiliar foods gradually; discuss substitutions with a professional if you follow a clinical diet.",
    ),
  ),
  DailyTip(
    id: "macros-01",
    topic: "protein-rotation",
    destination: TipDestination.food,
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Выберите другой белковый продукт",
      "Разнообразие можно начать с одной замены.",
      task:
          "Для одного блюда выберите привычный или новый подходящий источник белка.",
      steps: [
        "Вспомните удобный вам вариант.",
        "Подберите к нему знакомый гарнир и овощи.",
      ],
      example: "Рис с тофу; картофель с рыбой; хлеб с фасолевой намазкой.",
      alternative:
          "Яйцо или недорогая фасоль тоже подойдут; дорогой продукт не обязателен.",
      doneWhen: "Одна подходящая комбинация выбрана или приготовлена.",
      why:
          "Разные белковые продукты дают разный состав нутриентов. Высокобелковая норма здесь не назначается.",
      explanation:
          "Белок участвует в поддержании тканей. Разные продукты дают и другие нутриенты; чередуйте доступные варианты. Универсальная высокая норма белка здесь не назначается.",
    ),
    en: TipCopy(
      "Choose another protein food",
      "Variety can start with one substitution.",
      task: "Pick a familiar or new suitable protein food for one meal.",
      steps: [
        "Think of an accessible option.",
        "Pair it with a familiar side and vegetables.",
      ],
      example: "Rice with tofu; potato with fish; bread with bean spread.",
      alternative:
          "Egg or affordable beans can work too; an expensive food is unnecessary.",
      doneWhen: "One suitable combination is chosen or prepared.",
      why:
          "Protein foods differ in their other nutrients. No high-protein target is prescribed.",
      explanation:
          "Protein helps maintain tissues. Different foods also supply other nutrients, so rotate accessible choices. No universal high-protein target is prescribed here.",
    ),
  ),
  DailyTip(
    id: "macros-03",
    topic: "fat-inclusion",
    destination: TipDestination.food,
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Добавьте подходящую заправку",
      "Не нужно делать всё меню обезжиренным.",
      task: "Выберите подходящее масло, семена или орехи для одного блюда.",
      steps: [
        "Проверьте переносимость и назначения.",
        "Добавьте выбранный продукт в удобном для вас количестве.",
      ],
      example:
          "Салат с растительным маслом; каша с семенами, если они подходят.",
      alternative:
          "При аллергии на орехи используйте подходящее масло; при лечебной диете следуйте своему плану.",
      doneWhen: "Выбрано одно подходящее дополнение, без цели убрать все жиры.",
      why:
          "Жиры входят в обычный рацион; эти варианты могут давать ненасыщенные жиры.",
      explanation:
          "Жир необходим организму. Растительные масла, орехи, семена и рыба дают ненасыщенные жиры; порция и личная переносимость тоже имеют значение. Полностью обезжиривать питание не нужно.",
    ),
    en: TipCopy(
      "Choose a suitable dressing",
      "Your whole menu need not be fat-free.",
      task: "Choose suitable oil, seeds or nuts for one dish.",
      steps: [
        "Check tolerance and your care plan.",
        "Add the chosen food in an amount that suits you.",
      ],
      example: "Salad with plant oil; porridge with suitable seeds.",
      alternative:
          "With nut allergy use suitable oil; follow any clinical diet.",
      doneWhen:
          "One suitable addition is chosen without trying to remove all fat.",
      why:
          "Fat belongs in everyday eating; these options can supply unsaturated fats.",
      explanation:
          "Dietary fat is essential. Plant oils, nuts, seeds and fish supply unsaturated fats; portions and individual tolerance still matter. A completely fat-free diet is unnecessary.",
    ),
  ),
  DailyTip(
    id: "macros-04",
    topic: "snack-pair",
    destination: TipDestination.food,
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Подготовьте пару для перекуса",
      "Если хочется есть между приёмами пищи, можно выбрать удобную еду.",
      task: "Подготовьте один подходящий перекус из двух компонентов.",
      steps: [
        "Выберите фрукт или хлеб.",
        "Добавьте подходящий йогурт, сыр или бобовую намазку.",
      ],
      example: "Яблоко + йогурт; хлеб + хумус; груша + подходящий сыр.",
      alternative:
          "Подойдёт готовый перекус, если сейчас нет возможности собирать пару.",
      doneWhen:
          "Один удобный вариант подготовлен; есть его через силу не нужно.",
      why:
          "Сочетание разных продуктов делает выбор разнообразнее; потребность и насыщение индивидуальны.",
      explanation:
          "Сочетайте доступный белковый продукт с фруктом или цельнозерновым хлебом, если это вам подходит. Это пример разнообразия, а не обязательный перекус или фиксированная порция.",
    ),
    en: TipCopy(
      "Prepare a snack pairing",
      "If you want food between meals, choose something convenient.",
      task: "Prepare one suitable two-part snack.",
      steps: [
        "Choose fruit or bread.",
        "Add suitable yogurt, cheese or bean spread.",
      ],
      example: "Apple + yogurt; bread + hummus; pear + suitable cheese.",
      alternative:
          "A ready-made snack is also valid when assembly is impractical.",
      doneWhen: "One convenient option is ready; eating it is optional.",
      why:
          "Combining foods offers variety; appetite and fullness are individual.",
      explanation:
          "Pair an accessible protein food with fruit or wholegrain bread if that suits you. This illustrates variety, not a compulsory snack or fixed portion.",
    ),
  ),
  DailyTip(
    id: "macros-13",
    topic: "dairy-alternative-choice",
    destination: TipDestination.food,
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Сравните два подходящих йогурта",
      "Молочные и растительные варианты отличаются по составу.",
      task: "Выберите йогурт по подходящему составу и удобству.",
      steps: [
        "Сравните состав на одинаковую массу.",
        "Учитывайте белок, обогащение и ограничения, затем выберите один вариант.",
      ],
      example:
          "Подходящий йогурт + овсянка + фрукт — идея еды, без расчёта КБЖУ.",
      alternative:
          "Если йогурт не подходит, выберите хлеб с яйцом или фасолевой намазкой.",
      doneWhen: "Выбран подходящий продукт или замена.",
      why:
          "Этикетка помогает понять различия, а не считать все растительные аналоги одинаковыми.",
      explanation:
          "Молочные и растительные аналоги отличаются по белку, кальцию и добавленному сахару. Читайте этикетку; при исключении молочного выбирайте подходящую обогащённую альтернативу.",
    ),
    en: TipCopy(
      "Compare two suitable yogurts",
      "Dairy and plant options differ in composition.",
      task: "Choose a yogurt that suits your needs and routine.",
      steps: [
        "Compare ingredients and values on the same weight basis.",
        "Consider protein, fortification and restrictions before choosing.",
      ],
      example:
          "Suitable yogurt + oats + fruit is a meal idea, without calculated nutrients.",
      alternative:
          "If yogurt does not suit you, try bread with egg or bean spread.",
      doneWhen: "A suitable product or substitution is chosen.",
      why:
          "Labels show differences rather than treating all plant alternatives as identical.",
      explanation:
          "Dairy and plant alternatives differ in protein, calcium and added sugar. Read the label; an appropriately fortified alternative may help when avoiding dairy.",
    ),
  ),
  DailyTip(
    id: "hydration-03",
    topic: "water-flavour",
    destination: TipDestination.none,
    category: TipCategory.hydration,
    basis: TipBasis.universal,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Попробуйте удобный вкус воды",
      "Добавка нужна только для вкуса, а не для похудения.",
      task: "При желании приготовьте привычную воду с подходящей добавкой.",
      steps: [
        "Выберите мяту, огурец или ягоды, если подходят.",
        "Попробуйте немного и оставьте вариант, который нравится.",
      ],
      example: "Вода с огурцом; вода с мятой; обычная вода без добавок.",
      alternative:
          "Не подходят кислые добавки — обычная вода равноценный выбор для этой задачи.",
      doneWhen: "Выбран комфортный напиток без питья через силу.",
      why:
          "Выбор вкуса может сделать напиток удобнее; он не превращается в средство сжигания жира.",
      explanation:
          "Вода с добавками меняет вкус, но не становится средством сжигания жира. Если вам не подходят кислые добавки, обычная вода тоже нормальный выбор.",
    ),
    en: TipCopy(
      "Try a convenient water flavour",
      "Flavour is for preference, not weight loss.",
      task: "If you wish, prepare familiar water with a suitable addition.",
      steps: [
        "Choose mint, cucumber or berries if suitable.",
        "Try a little and keep the option you enjoy.",
      ],
      example: "Water with cucumber; water with mint; plain water.",
      alternative: "Plain water works if acidic additions do not suit you.",
      doneWhen: "A comfortable drink is chosen without forcing intake.",
      why:
          "A preferred flavour may make a drink more convenient; it is not a fat-burning treatment.",
      explanation:
          "Flavouring water does not turn it into a fat-burning treatment. Plain water is equally valid if acidic additions do not suit you.",
    ),
  ),
  DailyTip(
    id: "hydration-04",
    topic: "water-log-review",
    destination: TipDestination.none,
    category: TipCategory.hydration,
    basis: TipBasis.water,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Уточните одну запись воды",
      "Кольцо отражает только введённые объёмы.",
      task: "Проверьте одну известную запись, если помните выпитый объём.",
      steps: [
        "Сопоставьте запись с известной ёмкостью чашки.",
        "Исправьте только известную неточность; не угадывайте пропущенные объёмы.",
      ],
      example:
          "Чашка известного объёма записана дважды — исправьте повтор в журнале воды.",
      alternative:
          "Если не помните объём, оставьте его неизвестным; догонять кольцо не нужно.",
      doneWhen:
          "Одна запись проверена или её неопределённость оставлена без догадки.",
      why:
          "Проверка делает журнал понятнее, но не измеряет водный баланс или обезвоживание.",
      explanation:
          "Приложение знает только введённые объёмы. Оно не измеряет потери жидкости, поступление воды с едой и другими напитками или обезвоживание.",
    ),
    en: TipCopy(
      "Review one water entry",
      "The ring reflects entered amounts only.",
      task: "Check one known entry if you remember its amount.",
      steps: [
        "Compare it with a known cup size.",
        "Correct only a known error; do not guess missing amounts.",
      ],
      example:
          "A known-size cup was logged twice: correct the duplicate in the water log.",
      alternative:
          "If unsure, leave the amount unknown; there is no need to catch up with the ring.",
      doneWhen: "One entry was checked or its uncertainty left unresolved.",
      why:
          "This improves record clarity without measuring fluid balance or dehydration.",
      explanation:
          "The app knows only entered volumes. It does not measure fluid loss, water in food and other drinks, or dehydration.",
    ),
  ),
  DailyTip(
    id: "hydration-05",
    topic: "drink-log-type",
    destination: TipDestination.food,
    category: TipCategory.hydration,
    basis: TipBasis.universal,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Разделите воду и другие напитки в записях",
      "Чай или молоко не превращаются в чистую воду в журнале.",
      task: "Проверьте, в какой раздел внесён один напиток.",
      steps: [
        "Воду учитывайте в журнале воды.",
        "Для молока или другого напитка с составом проверьте подходящую запись дневника еды.",
      ],
      example:
          "Молоко в кофе можно учесть в составе записи кофе, если известны количество и продукт.",
      alternative: "Не помните количество — не придумывайте точные КБЖУ.",
      doneWhen:
          "Тип одной записи проверен; полного водного баланса по кольцу не выводится.",
      why:
          "Так понятнее, что именно отражают журналы; вода поступает также с едой и напитками.",
      explanation:
          "Часть жидкости поступает с едой, молоком, чаем и другими напитками. Поэтому сумма чистой воды в Balance не равна всей поступившей жидкости.",
    ),
    en: TipCopy(
      "Distinguish water from other drink entries",
      "Tea or milk does not become plain water in the log.",
      task: "Check where one drink is recorded.",
      steps: [
        "Record plain water in the water log.",
        "For milk or another drink with ingredients, review a suitable food-diary entry.",
      ],
      example:
          "Milk in coffee can belong in that entry when the product and amount are known.",
      alternative: "Unknown quantity? Do not invent exact nutrients.",
      doneWhen:
          "One entry type is checked without treating the ring as full fluid balance.",
      why:
          "This clarifies what logs show; food and other drinks also supply fluid.",
      explanation:
          "Food, milk, tea and other drinks also supply fluid. The plain-water total in Balance is therefore not total fluid intake.",
    ),
  ),
  DailyTip(
    id: "hydration-07",
    topic: "water-access",
    destination: TipDestination.none,
    category: TipCategory.hydration,
    basis: TipBasis.universal,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Подготовьте питьё для выхода из дома",
      "После посильного движения удобно иметь доступ к отдыху и напитку.",
      task: "Подготовьте подходящий напиток для запланированного выхода.",
      steps: [
        "Проверьте, где сможете отдохнуть.",
        "Возьмите удобную ёмкость или найдите доступ к питью.",
      ],
      example:
          "Небольшая прогулка: привычный маршрут, место отдыха и вода с собой.",
      alternative:
          "Короткий выход рядом с домом — можно предусмотреть доступ к напитку дома.",
      doneWhen:
          "Для выхода предусмотрены отдых и питьё в рамках ваших ограничений.",
      why:
          "Это упрощает доступ к напитку; объём не назначается, лечебные ограничения имеют приоритет.",
      explanation:
          "Нагрузка и жара могут менять потребности в жидкости. Дневник не рассчитывает индивидуальный водный баланс; соблюдайте клинические ограничения, если они есть.",
    ),
    en: TipCopy(
      "Make a drink accessible for an outing",
      "A manageable outing can include access to rest and a drink.",
      task: "Prepare a suitable drink for a planned outing.",
      steps: [
        "Check where you can rest.",
        "Take a convenient container or plan access to drinking water.",
      ],
      example: "A short walk: familiar route, a rest spot and water available.",
      alternative: "For a short trip near home, plan access to a drink there.",
      doneWhen: "Rest and a drink are accessible within your restrictions.",
      why:
          "This makes access easier without prescribing an amount; clinical fluid limits take priority.",
      explanation:
          "Activity and heat can change fluid needs. A diary cannot calculate individual fluid balance; follow any clinical restrictions.",
    ),
  ),
  DailyTip(
    id: "hydration-18",
    topic: "water-goal-safety",
    destination: TipDestination.none,
    category: TipCategory.hydration,
    basis: TipBasis.universal,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Не догоняйте кольцо через дискомфорт",
      "Показатель приложения не требует пить большой объём сразу.",
      task:
          "Проверьте, не заставляет ли цель пить через выраженный дискомфорт.",
      steps: [
        "Если есть назначенный предел жидкости, сверяйтесь с ним.",
        "При несоответствии цели обсудите ориентир со специалистом, не допивайте ради шкалы.",
      ],
      example:
          "Вечером кольцо не закрыто — это не обязанность быстро допить остаток.",
      alternative:
          "Если цель вам не подходит, можно оставить показатель незакрытым.",
      doneWhen:
          "Выбран комфортный подход; назначенный план не заменён цифрой приложения.",
      why:
          "Шкала описывает запись, а не медицинскую потребность; соревнование с ней не нужно.",
      explanation:
          "Не нужно быстро выпивать большой объём ради показателя. Если питьё вызывает выраженный дискомфорт или есть необычные симптомы, обсудите это с медицинским специалистом.",
    ),
    en: TipCopy(
      "Do not chase a ring through discomfort",
      "The tracker does not require drinking a large amount at once.",
      task:
          "Check whether the goal pressures you to drink through marked discomfort.",
      steps: [
        "Follow any prescribed fluid limit.",
        "Discuss a conflicting goal with a professional instead of catching up.",
      ],
      example:
          "An incomplete evening ring is not an obligation to rapidly drink the remainder.",
      alternative: "Leave the ring incomplete if its target does not suit you.",
      doneWhen:
          "A comfortable approach is chosen without replacing a care plan with an app number.",
      why:
          "The tracker describes entries rather than medical need; competing with it is unnecessary.",
      explanation:
          "Avoid rapidly drinking a large volume to satisfy a tracker. Discuss marked discomfort or unusual symptoms with a healthcare professional.",
    ),
  ),
  DailyTip(
    id: "activity-03",
    topic: "work-break",
    destination: TipDestination.none,
    category: TipCategory.activity,
    basis: TipBasis.universal,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Привяжите паузу к завершению дела",
      "Не нужен новый спортивный план.",
      task: "После одного рабочего дела смените положение удобным способом.",
      steps: [
        "Выберите событие: конец звонка или письма.",
        "Сделайте короткую комфортную паузу перед следующим делом.",
      ],
      example:
          "После звонка пройтись по комнате или удобно сменить положение сидя.",
      alternative:
          "Если вставать не подходит, выберите доступную смену положения или отдых.",
      doneWhen: "Одна рабочая пауза состоялась без неприятных ощущений.",
      why:
          "Привязка к знакомому событию облегчает небольшую паузу; изменения веса не обещаются.",
      explanation:
          "Доступное движение можно распределять в течение дня. Смена положения удобна как короткая пауза; она не гарантирует изменение веса.",
    ),
    en: TipCopy(
      "Attach a break to finishing a task",
      "No new workout plan is needed.",
      task: "After one task, change position in a comfortable way.",
      steps: [
        "Choose a cue such as finishing a call or email.",
        "Take a comfortable brief break before the next task.",
      ],
      example:
          "After a call, move around the room or comfortably change seated position.",
      alternative:
          "If standing is unsuitable, choose an accessible position change or rest.",
      doneWhen: "One comfortable work break happened.",
      why:
          "A familiar cue makes a small break easier to remember; no weight change is promised.",
      explanation:
          "Accessible movement can be spread through the day. Changing position is a practical short break, without a guaranteed weight effect.",
    ),
  ),
  DailyTip(
    id: "activity-04",
    topic: "step-record-review",
    destination: TipDestination.none,
    category: TipCategory.activity,
    basis: TipBasis.steps,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Сравните доступные записи шагов",
      "Счётчик описывает часть движения, а не весь расход энергии.",
      task: "Посмотрите на два завершённых дня, если записи есть.",
      steps: [
        "Проверьте, было ли устройство с вами.",
        "Отметьте разницу обстоятельств без вывода о причине веса.",
      ],
      example:
          "Один день телефон лежал дома — меньший счётчик может быть неполным.",
      alternative:
          "Есть только один день — оставьте сравнение на потом, не подставляйте ноль.",
      doneWhen: "Проверены доступные дни и отмечены ограничения сравнения.",
      why:
          "Это помогает интерпретировать реальные шаги без чужого норматива и ложного вывода о расходе.",
      explanation:
          "Данные шагов полезны для сравнения с собственным ритмом, но телефон мог быть не с вами. Снижение счётчика само по себе не доказывает уменьшение всей активности.",
    ),
    en: TipCopy(
      "Compare available step records",
      "A counter captures part of movement, not total energy use.",
      task: "Review two completed days if records exist.",
      steps: [
        "Check whether you carried the device.",
        "Note different circumstances without explaining weight from them.",
      ],
      example:
          "The phone stayed home on one day: its lower count may be incomplete.",
      alternative:
          "Only one day available? Defer comparison instead of inserting zero.",
      doneWhen: "Available days and comparison limits were reviewed.",
      why:
          "This puts actual steps in context without someone else’s target or a false expenditure estimate.",
      explanation:
          "Steps can be compared with your usual pattern, but the device may not have been with you. A lower count does not establish lower total activity.",
    ),
  ),
  DailyTip(
    id: "activity-18",
    topic: "load-adjustment",
    destination: TipDestination.none,
    category: TipCategory.activity,
    basis: TipBasis.universal,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Выберите посильную нагрузку без рекорда",
      "Вчерашнее число не обязывает повторять или превышать его.",
      task: "Оставьте сегодня один комфортный вариант активности или отдыха.",
      steps: [
        "Оцените самочувствие и ограничения.",
        "Выберите нагрузку без компенсации еды и пропущенных дней.",
      ],
      example:
          "После напряжённого дня — спокойная прогулка, доступное движение или отдых.",
      alternative:
          "Не подходит привычная нагрузка — можно сократить или перенести её.",
      doneWhen: "Выбран и соблюдён посильный вариант без цели побить рекорд.",
      why:
          "Гибкий ритм учитывает обстоятельства; еду не нужно заслуживать тренировкой.",
      explanation:
          "Нагрузка зависит от самочувствия и обстоятельств. Оставляйте дни полегче; устойчивый подход не требует ежедневно повышать цифры.",
    ),
    en: TipCopy(
      "Choose manageable effort without a record",
      "Yesterday’s number is not an obligation to match or exceed it.",
      task: "Keep one comfortable activity or rest option today.",
      steps: [
        "Consider how you feel and any restrictions.",
        "Choose without compensating for food or missed days.",
      ],
      example:
          "After a demanding day: an easy walk, accessible movement or rest.",
      alternative:
          "Shorten or postpone your usual activity if it is unsuitable.",
      doneWhen: "A manageable option was chosen without chasing a record.",
      why:
          "A flexible routine accounts for circumstances; food does not need to be earned through exercise.",
      explanation:
          "Effort depends on wellbeing and circumstances. Allow lighter days; a sustainable approach does not demand higher numbers every day.",
    ),
  ),
  DailyTip(
    id: "recovery-01",
    topic: "wind-down",
    destination: TipDestination.none,
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Подготовьте спокойное завершение вечера",
      "Один короткий ритуал вместо списка идеальных правил.",
      task: "Выберите спокойное действие перед своим обычным временем сна.",
      steps: [
        "Решите, чем закончить вечер.",
        "Подготовьте нужную вещь заранее, чтобы не искать её в последний момент.",
      ],
      example: "Книга у кровати; спокойная музыка; привычный тёплый душ.",
      alternative: "Усталый вечер — достаточно убрать одно лишнее дело.",
      doneWhen: "Выбранный спокойный переход попробован один раз.",
      why:
          "Понятная точка завершения помогает организовать вечер; это не лечение бессонницы.",
      explanation:
          "Повторяемый спокойный ритуал может помочь организовать вечер. Он не лечит бессонницу и не обещает снижение веса; выбирайте доступный вариант.",
    ),
    en: TipCopy(
      "Prepare a quiet end to the evening",
      "Choose one small routine rather than a list of perfect rules.",
      task: "Choose a quiet activity before your usual sleep time.",
      steps: [
        "Decide how to close the evening.",
        "Prepare what you need so it is easy to start.",
      ],
      example: "A book by the bed; quiet music; a familiar warm shower.",
      alternative: "On a tiring evening, simply drop one unnecessary task.",
      doneWhen: "The chosen wind-down activity was tried once.",
      why:
          "A clear stopping point helps structure the evening; it is not insomnia treatment.",
      explanation:
          "A repeatable quiet routine may help structure the evening. It does not treat insomnia or promise weight loss; choose something practical.",
    ),
  ),
  DailyTip(
    id: "recovery-04",
    topic: "rest-environment",
    destination: TipDestination.none,
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Уберите одну помеху для отдыха",
      "Начните с того, что можете изменить без покупок.",
      task: "Попробуйте одно удобное изменение света, шума или температуры.",
      steps: [
        "Назовите одну заметную помеху.",
        "Измените только её и оцените удобство.",
      ],
      example:
          "Приглушить яркий свет; закрыть штору; убрать шумящий прибор, если безопасно.",
      alternative: "Общая комната — выберите доступный вам маленький участок.",
      doneWhen: "Одно изменение сделано и его удобство оценено.",
      why:
          "Так проще проверить условия отдыха по одной переменной, без обещания исправить сон или вес.",
      explanation:
          "Свет, шум и комфорт спальни относятся к привычкам сна. Начните с одного изменения, которое можете сделать; при стойких проблемах нужна индивидуальная оценка.",
    ),
    en: TipCopy(
      "Remove one barrier to rest",
      "Start with something you can change without buying anything.",
      task: "Try one practical light, noise or temperature change.",
      steps: [
        "Identify one noticeable disturbance.",
        "Change just that and assess comfort.",
      ],
      example:
          "Dim a bright light; close a curtain; switch off a noisy device if safe.",
      alternative: "In a shared room, choose one small area you can control.",
      doneWhen: "One change was made and comfort assessed.",
      why:
          "Changing one thing makes conditions easier to review without promising better sleep or weight.",
      explanation:
          "Light, noise and bedroom comfort belong to sleep habits. Start with one feasible change; persistent problems need individual assessment.",
    ),
  ),
  DailyTip(
    id: "recovery-06",
    topic: "caffeine-timing",
    destination: TipDestination.none,
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Проверьте время последнего кофе",
      "Если поздний кофе мешает вашему сну, попробуйте более раннее время.",
      task:
          "Отметьте время кофе и выберите подходящую вечернюю замену при необходимости.",
      steps: [
        "Вспомните последний кофе за день.",
        "Если сами замечаете связь со сном, попробуйте перенести его раньше.",
      ],
      example:
          "Любимый кофе раньше, а вечером — подходящий напиток без кофеина.",
      alternative:
          "Если менять напиток не хочется, начните с наблюдения времени без обязательного запрета.",
      doneWhen: "Время отмечено или выбран небольшой пробный перенос.",
      why:
          "Чувствительность к кофеину различается; такой эксперимент помогает обсудить ваш опыт, а не угадывать сон по весу.",
      explanation:
          "Кофеин может мешать сну. Чувствительность различается; попробуйте более раннее время без требования полностью отказаться от любимого напитка.",
    ),
    en: TipCopy(
      "Review the time of your last coffee",
      "If late coffee disturbs your sleep, try an earlier time.",
      task:
          "Note your coffee timing and choose an evening alternative if needed.",
      steps: [
        "Recall the last coffee of the day.",
        "If you notice a sleep connection yourself, try moving it earlier.",
      ],
      example:
          "A favourite coffee earlier, with a suitable caffeine-free drink in the evening.",
      alternative:
          "Start with noticing the time if you do not want to change drinks.",
      doneWhen: "Timing is noted or a small trial change chosen.",
      why:
          "Caffeine sensitivity differs; this reviews your experience rather than inferring sleep from weight.",
      explanation:
          "Caffeine can disrupt sleep. Sensitivity varies; trying an earlier time does not require giving up a favourite drink entirely.",
    ),
  ),
  DailyTip(
    id: "recovery-07",
    topic: "screen-stopping-point",
    destination: TipDestination.none,
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Выберите точку остановки для ленты",
      "Если просмотр затягивает вечер, заранее решите, где закончить.",
      task: "Один раз завершите просмотр в выбранной точке.",
      steps: [
        "Выберите событие: конец серии или разговора.",
        "Положите телефон в удобное место и переключитесь на спокойное дело.",
      ],
      example:
          "После одной серии убрать телефон на полку и подготовить одежду на завтра.",
      alternative:
          "Если телефон нужен для связи, оставьте его рядом, закрыв только ленту.",
      doneWhen:
          "Просмотр завершён в выбранной точке без требования идеальной серии дней.",
      why:
          "Заранее выбранное завершение уменьшает число вечерних решений; это практический эксперимент.",
      explanation:
          "Если экран отодвигает сон, выберите точку остановки и спокойную альтернативу. Это практический эксперимент, а не способ автоматически исправить вес.",
    ),
    en: TipCopy(
      "Choose a stopping point for scrolling",
      "If scrolling stretches your evening, decide where to stop in advance.",
      task: "End one scrolling session at a chosen point.",
      steps: [
        "Choose a cue such as the end of an episode or conversation.",
        "Put the phone somewhere practical and switch to a quiet task.",
      ],
      example:
          "After one episode, park the phone and prepare tomorrow’s clothes.",
      alternative:
          "Need your phone for contact? Keep it nearby and close only the feed.",
      doneWhen:
          "One session ended at the chosen point, without a perfect-streak target.",
      why:
          "A planned stopping point reduces evening decisions; this is a practical trial.",
      explanation:
          "If screens delay sleep, choose a stopping point and a quiet alternative. This is a practical experiment, not an automatic way to change weight.",
    ),
  ),
  DailyTip(
    id: "recovery-17",
    topic: "sleep-support",
    destination: TipDestination.none,
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Подготовьте вопрос о повторяющихся трудностях сна",
      "Если сон регулярно мешает днём, это можно обсудить со специалистом.",
      task:
          "Запишите один конкретный вопрос для консультации, если он актуален.",
      steps: [
        "Опишите, что повторяется и как мешает днём.",
        "Добавьте пример удобным вам способом без подробного трекера.",
      ],
      example: "«Часто просыпаюсь и устаю днём. Что стоит проверить?»",
      alternative:
          "Не хотите вести записи — достаточно одной заметки или устного вопроса.",
      doneWhen: "Подготовлен вопрос, а не самостоятельно назначенное лечение.",
      why:
          "Описание ситуации делает разговор конкретнее; приложение не определяет диагноз и лечение.",
      explanation:
          "Приложение не выявляет причины усталости и нарушений сна. Если они устойчиво мешают жизни, врач поможет оценить возможные причины и подходящую помощь.",
    ),
    en: TipCopy(
      "Prepare a question about recurring sleep trouble",
      "If sleep repeatedly affects daytime life, you can discuss it with a professional.",
      task: "Write one specific consultation question if relevant.",
      steps: [
        "Describe what recurs and how it affects your day.",
        "Add one example without a detailed sleep tracker.",
      ],
      example:
          "“I often wake and feel tired in the day. What should we review?”",
      alternative:
          "A single note or a spoken question is enough if tracking is unwelcome.",
      doneWhen: "A question is prepared rather than self-prescribed treatment.",
      why:
          "A clear description supports the discussion; the app does not diagnose or treat.",
      explanation:
          "The app cannot identify causes of fatigue or sleep problems. If they persist and affect daily life, a clinician can assess causes and suitable support.",
    ),
  ),
  DailyTip(
    id: "habits-15",
    topic: "shopping-plan",
    destination: TipDestination.food,
    category: TipCategory.habits,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Купите недостающий продукт для одного блюда",
      "Начните с содержимого холодильника, а не длинного списка.",
      task: "Выберите блюдо и внесите в список только недостающий компонент.",
      steps: [
        "Проверьте, что уже есть.",
        "Соедините доступную основу, белковый продукт и овощи, затем отметьте недостающее.",
      ],
      example: "Есть рис и фасоль — в список можно добавить подходящие овощи.",
      alternative: "Сложно идти в магазин — выберите замену из имеющегося.",
      doneWhen: "Один короткий список или вариант без покупок готов.",
      why:
          "Покупка под конкретное блюдо уменьшает число решений и помогает использовать имеющиеся продукты.",
      explanation:
          "План покупок можно составлять из доступных продуктов. Нет необходимости покупать дорогой суперфуд: обычные крупы, бобовые и сезонные овощи тоже дают разнообразие.",
    ),
    en: TipCopy(
      "Buy the missing ingredient for one meal",
      "Start with the fridge rather than a long shopping list.",
      task: "Choose one meal and list its missing component.",
      steps: [
        "Check what you already have.",
        "Combine an accessible base, protein food and vegetables, then note what is missing.",
      ],
      example:
          "Already have rice and beans? Suitable vegetables may be the only addition.",
      alternative: "Cannot shop? Choose a substitution from what you have.",
      doneWhen: "A short list or a no-shopping option is ready.",
      why:
          "Shopping for a specific meal reduces decisions and uses available ingredients.",
      explanation:
          "Plan shopping around accessible foods. Expensive superfoods are unnecessary: familiar grains, pulses and seasonal vegetables can provide variety.",
    ),
  ),
  DailyTip(
    id: "habits-16",
    topic: "comfortable-logging",
    destination: TipDestination.food,
    category: TipCategory.habits,
    basis: TipBasis.food,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Сделайте одну запись удобным способом",
      "Дневник может помогать без требования идеальной детализации.",
      task:
          "Выберите удобный момент для одной известной записи, если отслеживание вам подходит.",
      steps: [
        "Запишите знакомое блюдо без угадывания неизвестного.",
        "Остановитесь на посильном уровне подробности.",
      ],
      example:
          "Записать известный продукт после обеда; неизвестный рецепт оставить приблизительным.",
      alternative:
          "Если контроль вызывает тревогу или навязчивость, допустима пауза и обсуждение другого подхода.",
      doneWhen: "Одна удобная запись сделана или осознанно выбрана пауза.",
      why:
          "Посильный формат может уменьшить трудность ведения дневника; точное потребление по нему не доказывается.",
      explanation:
          "По дневнику нельзя гарантировать полноту рациона. Если детализация вызывает напряжение, используйте более простой формат или обсудите другой способ наблюдения со специалистом.",
    ),
    en: TipCopy(
      "Make one entry in a manageable way",
      "A diary can help without perfect detail.",
      task:
          "Choose a convenient moment for one known entry if tracking suits you.",
      steps: [
        "Record familiar food without guessing unknown details.",
        "Stop at a manageable level of detail.",
      ],
      example:
          "Log a known food after lunch; leave an unknown recipe approximate.",
      alternative:
          "If tracking brings anxiety or compulsive checking, take a break and discuss another approach.",
      doneWhen: "One manageable entry is made or a break deliberately chosen.",
      why:
          "A practical format may reduce logging effort; it cannot prove exact intake.",
      explanation:
          "A diary cannot guarantee complete intake data. If detailed tracking causes distress, use a simpler format or discuss another approach with a professional.",
    ),
  ),
  DailyTip(
    id: "mindful-02",
    topic: "appetite-observation",
    destination: TipDestination.none,
    category: TipCategory.mindful,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Заметьте потребность перед едой без запретов",
      "Это наблюдение, а не экзамен на право поесть.",
      task: "Перед одним приёмом пищи коротко отметьте, что сейчас нужно.",
      steps: [
        "Заметьте голод, самочувствие и доступную еду.",
        "Выберите еду с учётом своего плана, не требуя обязательного голода.",
      ],
      example:
          "«Хочется тёплой еды, есть суп и хлеб» — достаточно конкретного выбора.",
      alternative:
          "При плане регулярного питания следуйте ему, не ждите голода.",
      doneWhen: "Сделано одно нейтральное наблюдение без отмены еды.",
      why:
          "Так можно учесть самочувствие, не превращая аппетит в новое жёсткое правило.",
      explanation:
          "Голод и насыщение можно замечать без строгих правил. При медицинском плане регулярных приёмов пищи следуйте ему, а не ждите обязательного сигнала голода.",
    ),
    en: TipCopy(
      "Notice your needs without food rules",
      "This is an observation, not a test of permission to eat.",
      task: "Before one meal, briefly notice what you need.",
      steps: [
        "Notice appetite, wellbeing and available food.",
        "Choose with your care plan in mind, without demanding hunger.",
      ],
      example:
          "“I want something warm; soup and bread are available” is a concrete choice.",
      alternative:
          "Follow scheduled eating in a care plan rather than waiting for hunger.",
      doneWhen: "One neutral observation was made without cancelling food.",
      why:
          "This considers wellbeing without turning appetite into a rigid new rule.",
      explanation:
          "Hunger and fullness can be noticed without rigid rules. If a clinical plan calls for regular meals, follow it rather than waiting for a hunger cue.",
    ),
  ),
  DailyTip(
    id: "mindful-08",
    topic: "hunger-response",
    destination: TipDestination.food,
    category: TipCategory.mindful,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Если вы ещё голодны, дополните еду",
      "Цифра приложения не отменяет потребность в еде.",
      task: "При сохраняющемся голоде выберите доступное дополнение.",
      steps: [
        "Посмотрите, что удобно добавить к текущей еде.",
        "Выберите по аппетиту, без обязательного ожидания до следующего часа.",
      ],
      example:
          "Ещё немного основного блюда; хлеб с намазкой; йогурт и фрукт, если подходят.",
      alternative:
          "Если трудно решить, можно вернуться к привычному полноценному блюду.",
      doneWhen: "При актуальном голоде выбран подходящий вариант дополнения.",
      why:
          "Это помогает ответить на потребность в еде; при стойком голоде или ограничениях полезна индивидуальная поддержка.",
      explanation:
          "Аппетит и потребности не всегда совпадают с планом приложения. Если голод сохраняется или рацион ограничен, оцените регулярность и полноценность еды с поддержкой специалиста.",
    ),
    en: TipCopy(
      "If still hungry, add to your meal",
      "An app number does not override a need for food.",
      task: "Choose an accessible addition if hunger remains.",
      steps: [
        "See what is convenient to add.",
        "Choose according to appetite without an obligatory wait until later.",
      ],
      example:
          "More of the main dish; bread with spread; suitable yogurt and fruit.",
      alternative:
          "If deciding feels difficult, return to a familiar substantial meal.",
      doneWhen: "A suitable addition is chosen when hunger is relevant.",
      why:
          "This responds to a need for food; persistent hunger or restriction calls for individual support.",
      explanation:
          "Appetite and needs may differ from an app plan. Persistent hunger or a restrictive diet calls for a review of regular, adequate eating with professional support.",
    ),
  ),
  DailyTip(
    id: "mindful-09",
    topic: "eating-without-compensation",
    destination: TipDestination.food,
    category: TipCategory.mindful,
    basis: TipBasis.universal,
    sourceIds: ["nhs-eating-support", "cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "После десерта оставьте обычный приём пищи",
      "Не нужно исправлять сладкое пропуском еды.",
      task: "Сохраните следующий обычный приём пищи без компенсации.",
      steps: [
        "Посмотрите на обычное время еды.",
        "Подготовьте привычный вариант без специального урезания.",
      ],
      example:
          "После десерта в обед — обычный ужин, например рис с фасолью и овощами.",
      alternative:
          "После пропущенной записи тоже можно вернуться к обычному ритму.",
      doneWhen: "Следующий приём пищи не отменён ради компенсации.",
      why:
          "Так один продукт не превращается в повод для новых ограничений; при чувстве вины можно обратиться за поддержкой.",
      explanation:
          "Один десерт не требует отменять следующую еду. Вернитесь к привычному ритму; если возникают компенсаторные ограничения, это повод обратиться за поддержкой.",
    ),
    en: TipCopy(
      "Keep your usual meal after dessert",
      "Dessert does not need fixing by skipping food.",
      task: "Keep the next usual meal without compensation.",
      steps: [
        "Check your usual meal time.",
        "Prepare something familiar without a special cutback.",
      ],
      example:
          "After lunch dessert, have a usual dinner such as rice, beans and vegetables.",
      alternative: "After a missed log, return to the usual routine too.",
      doneWhen: "The next meal was not cancelled as compensation.",
      why:
          "This avoids turning one food into a reason for restriction; seek support for distressing guilt.",
      explanation:
          "One dessert does not require cancelling the next meal. Return to your usual routine; compensatory restriction is a reason to seek support.",
    ),
  ),
  DailyTip(
    id: "mindful-16",
    topic: "neutral-log-review",
    destination: TipDestination.food,
    category: TipCategory.mindful,
    basis: TipBasis.food,
    sourceIds: ["nhs-eating-support", "cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Опишите одну запись без оценки себя",
      "Дневник записывает еду, а не характер.",
      task:
          "Прочитайте одну запись нейтрально и выберите удобное уточнение, если оно нужно.",
      steps: [
        "Назовите еду и обстоятельства без слов «плохой день».",
        "Уточните известную деталь или просто завершите просмотр.",
      ],
      example:
          "«Паста в кафе, состав примерно известен» вместо «я всё испортил(а)».",
      alternative:
          "Если просмотр усиливает тревогу, закройте дневник и обсудите поддержку.",
      doneWhen:
          "Одна запись прочитана нейтрально или выбран безопасный перерыв.",
      why:
          "Так легче отделить сведения от самооценки; точность не требует обвинений.",
      explanation:
          "В дневнике отражена лишь часть жизни. Используйте его для вопросов и удобных действий, а не оценки характера; при навязчивом контроле допустима пауза.",
    ),
    en: TipCopy(
      "Describe one entry without judging yourself",
      "A diary records food, not character.",
      task:
          "Read one entry neutrally and clarify a practical detail only if needed.",
      steps: [
        "Name the food and circumstances without a “bad day” label.",
        "Clarify a known detail or simply finish reviewing.",
      ],
      example:
          "“Cafe pasta, ingredients approximately known” rather than “I ruined everything.”",
      alternative:
          "If reviewing increases anxiety, close the diary and discuss support.",
      doneWhen: "One entry was read neutrally or a safe break chosen.",
      why:
          "This separates information from self-judgement; accuracy does not require blame.",
      explanation:
          "A diary captures only part of life. Use it for questions and practical actions, not a character judgement; a break is valid if tracking becomes compulsive.",
    ),
  ),
  DailyTip(
    id: "progress-02",
    topic: "comparable-weighing",
    destination: TipDestination.weight,
    category: TipCategory.progress,
    basis: TipBasis.universal,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Выберите сопоставимые условия взвешивания",
      "Чаще измерять ради приложения не требуется.",
      task:
          "Подготовьте одинаковые удобные условия для следующего планового измерения.",
      steps: [
        "Выберите те же весы и ровную поверхность.",
        "По возможности сохраняйте похожее время и одежду.",
      ],
      example:
          "Одни весы, привычное утро и похожая одежда; дату записи проверьте при вводе.",
      alternative:
          "Если измерения вызывают тревогу, выберите паузу или обсудите иной способ наблюдения.",
      doneWhen: "Условия выбраны; новое измерение не обязательно сегодня.",
      why:
          "Сходные условия уменьшают случайные различия, не делая показание точным измерением жира.",
      explanation:
          "Одни весы, ровная поверхность и похожее время уменьшают случайные различия. Ежедневное взвешивание не требуется; при тревоге можно выбрать более редкий ритм.",
    ),
    en: TipCopy(
      "Choose comparable weighing conditions",
      "There is no need to weigh more often for the app.",
      task:
          "Prepare similar comfortable conditions for the next planned reading.",
      steps: [
        "Choose the same scale on a level surface.",
        "Keep timing and clothing similar when practical.",
      ],
      example:
          "The same scale, usual morning and similar clothing; check the entered date.",
      alternative:
          "If weighing causes distress, pause or discuss another observation approach.",
      doneWhen: "Conditions are chosen; a new reading is not required today.",
      why:
          "Comparable conditions reduce incidental differences without measuring body fat precisely.",
      explanation:
          "The same scale, level floor and similar timing reduce incidental differences. Daily weighing is optional; choose a less frequent rhythm if it causes distress.",
    ),
  ),
  DailyTip(
    id: "progress-08",
    topic: "circumference-technique",
    destination: TipDestination.weight,
    category: TipCategory.progress,
    basis: TipBasis.universal,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Уточните технику следующего замера",
      "Место и натяжение ленты влияют на результат.",
      task: "Перед следующим плановым замером выберите одно и то же место.",
      steps: [
        "Расположите ленту ровно и без затягивания.",
        "Запишите фактическую дату и показатель, не желаемую цифру.",
      ],
      example:
          "Для талии повторите прежнее место; грудь и бёдра учитывайте отдельно.",
      alternative:
          "Если трудно повторить технику или это вызывает тревогу, допустима пауза.",
      doneWhen: "Техника проверена; обязательного нового замера сегодня нет.",
      why:
          "Повторяемый способ делает наблюдения сопоставимее, но не определяет состав тела.",
      explanation:
          "Сантиметры зависят от места и натяжения ленты. Повторяйте технику, не затягивайте ленту и не делайте вывод о жировой или мышечной ткани по одному замеру.",
    ),
    en: TipCopy(
      "Check your next measurement technique",
      "Tape position and tension affect a reading.",
      task: "Before the next planned measurement, choose the same location.",
      steps: [
        "Keep the tape level without pulling it tight.",
        "Enter the actual date and value rather than a desired number.",
      ],
      example: "Repeat the waist location; record chest and hips separately.",
      alternative:
          "Pause if technique is difficult to repeat or measurement causes distress.",
      doneWhen: "Technique is checked; an extra reading today is unnecessary.",
      why:
          "Repeatable technique improves comparison without establishing body composition.",
      explanation:
          "Circumferences depend on tape position and tension. Repeat the technique without tightening the tape, and avoid inferring fat or muscle change from one measurement.",
    ),
  ),
  DailyTip(
    id: "progress-16",
    topic: "goal-review",
    destination: TipDestination.none,
    category: TipCategory.progress,
    basis: TipBasis.universal,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Запишите один вопрос о текущей цели",
      "Цель можно пересмотреть, если она перестала подходить.",
      task: "Назовите, что именно в нынешнем плане неудобно или беспокоит.",
      steps: [
        "Выберите один конкретный вопрос.",
        "При сомнениях о здоровье обсудите его со специалистом без нового запрета.",
      ],
      example:
          "«Мне трудно сохранять такой режим. Какой ориентир подойдёт сейчас?»",
      alternative:
          "Достигнутая цель — повод обсудить поддержание, а не обязательное дальнейшее снижение.",
      doneWhen: "Один вопрос сформулирован; цель не изменена автоматически.",
      why:
          "Конкретный вопрос помогает обсудить подходящий план, не принимая цифру приложения за медицинское назначение.",
      explanation:
          "Достигнутую цель можно сменить на поддержание. Безопасность и самочувствие важнее дальнейшего снижения; подходящий ориентир можно обсудить с врачом или диетологом.",
    ),
    en: TipCopy(
      "Write one question about your current goal",
      "A goal can be revisited when it no longer fits.",
      task: "Name one practical difficulty or concern with the current plan.",
      steps: [
        "Choose one specific question.",
        "Discuss health concerns with a professional instead of adding a ban.",
      ],
      example:
          "“This routine is difficult to sustain. What goal would fit now?”",
      alternative:
          "A reached target can prompt a maintenance discussion rather than further loss.",
      doneWhen: "One question is formulated; no goal changes automatically.",
      why:
          "A specific question supports plan review without treating an app number as medical advice.",
      explanation:
          "A reached target can become maintenance. Safety and wellbeing matter more than further loss; discuss a suitable target with a clinician or dietitian.",
    ),
  ),
  DailyTip(
    id: "facts-04",
    topic: "bread-label",
    destination: TipDestination.food,
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Выберите хлеб по составу, а не цвету",
      "Тёмная корочка не гарантирует цельное зерно.",
      task: "Посмотрите состав одного привычного хлеба.",
      steps: [
        "Найдите название муки и зерновых ингредиентов.",
        "Выберите подходящий вариант по составу, вкусу и ограничениям.",
      ],
      example:
          "Сравните привычный тёмный хлеб и хлеб с указанным цельным зерном.",
      alternative: "Не хотите менять хлеб — начните только с чтения состава.",
      doneWhen: "Состав одного хлеба прочитан; обязательной замены нет.",
      why: "Этикетка даёт больше сведений о продукте, чем его цвет.",
      explanation:
          "Слова на лицевой стороне и цвет не заменяют состав и таблицу пищевой ценности. Сравнивайте продукты на одинаковую массу, учитывая личные ограничения.",
    ),
    en: TipCopy(
      "Choose bread by ingredients, not colour",
      "A dark crust does not guarantee whole grain.",
      task: "Read the ingredients of one familiar bread.",
      steps: [
        "Find the flour and grain ingredients.",
        "Choose by composition, preference and restrictions.",
      ],
      example: "Compare a familiar dark loaf with a loaf listing whole grains.",
      alternative:
          "Start with reading the label if you do not want to switch bread.",
      doneWhen: "One ingredients list is read; switching is optional.",
      why: "An ingredients list tells you more about bread than its colour.",
      explanation:
          "Front-of-pack words and colour do not replace ingredients and nutrition information. Compare foods on the same weight basis and account for your restrictions.",
    ),
  ),
  DailyTip(
    id: "facts-06",
    topic: "label-basis",
    destination: TipDestination.food,
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Сравните этикетки на одинаковую массу",
      "Порция производителя и 100 г — разные основания сравнения.",
      task: "Сопоставьте два подходящих продукта на одинаковую массу.",
      steps: [
        "Найдите строку «на 100 г» или размер порции.",
        "Выберите одну общую основу перед сравнением.",
      ],
      example:
          "Один йогурт указан на баночку, другой на 100 г: сначала уточните массу баночки.",
      alternative:
          "Если пересчёт неудобен, сравните продукты с одинаковой формой этикетки.",
      doneWhen: "Для сравнения выбрана одинаковая основа.",
      why:
          "Так различия в представлении данных не принимаются за различия самого продукта; порция не назначается этикеткой.",
      explanation:
          "Проверьте, указана ли энергия на 100 г, на порцию или на упаковку. Производитель задаёт способ представления данных, а не обязательный размер вашей еды.",
    ),
    en: TipCopy(
      "Compare labels on the same weight basis",
      "A manufacturer’s serving and 100 g are different bases.",
      task: "Compare two suitable products on the same weight basis.",
      steps: [
        "Find the per-100-g line or serving size.",
        "Choose one common basis before comparing.",
      ],
      example:
          "One yogurt lists a pot and another 100 g: first check the pot weight.",
      alternative:
          "Choose similarly labelled products if conversion is inconvenient.",
      doneWhen: "A common comparison basis is identified.",
      why:
          "This avoids confusing reporting units with food differences; a label does not prescribe your portion.",
      explanation:
          "Check whether energy is listed per 100 g, serving or package. A manufacturer defines a reporting unit, not a compulsory portion.",
    ),
  ),
  DailyTip(
    id: "facts-09",
    topic: "recipe-ingredients",
    destination: TipDestination.food,
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Уточните одну запись готового блюда",
      "Одинаковое название не означает одинаковый рецепт.",
      task: "Проверьте состав одного часто записываемого блюда.",
      steps: [
        "Сопоставьте известные ингредиенты с записью.",
        "Исправьте известное или оставьте оценку приблизительной.",
      ],
      example:
          "Ваша паста с фасолью, а выбранная запись с мясом — найдите более подходящий вариант.",
      alternative:
          "Для еды из кафе без рецепта точность может остаться ограниченной.",
      doneWhen: "Одна запись проверена без выдуманных точных КБЖУ.",
      why:
          "Уточнение уменьшает явное несоответствие, но не доказывает точное потребление или дефицит.",
      explanation:
          "Каталожное блюдо может отличаться от вашего по ингредиентам и порции. Если рецепт неизвестен, считайте запись оценкой и не делайте точный вывод о дефиците.",
    ),
    en: TipCopy(
      "Clarify one prepared-dish entry",
      "The same name does not guarantee the same recipe.",
      task: "Check the ingredients of one frequently logged dish.",
      steps: [
        "Compare known ingredients with the entry.",
        "Correct what is known or keep the estimate approximate.",
      ],
      example:
          "Your pasta has beans but the entry has meat: find a closer option.",
      alternative: "A cafe meal without a recipe may remain uncertain.",
      doneWhen: "One entry is checked without invented exact nutrients.",
      why:
          "Review reduces obvious mismatch without proving exact intake or an energy deficit.",
      explanation:
          "A catalog dish can differ from yours in ingredients and portion. With an unknown recipe, treat the entry as an estimate rather than proof of an energy deficit.",
    ),
  ),
  DailyTip(
    id: "facts-16",
    topic: "dry-cooked-entry",
    destination: TipDestination.food,
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Сверьте сухой и готовый вес крупы",
      "Одна и та же крупа после варки весит иначе.",
      task: "Выберите запись, соответствующую тому, что взвешивали.",
      steps: [
        "Уточните, сухой или готовый продукт был на весах.",
        "Проверьте то же состояние в названии каталога.",
      ],
      example:
          "Взвесили готовый рис — выбирайте запись для готового риса, а не сухой крупы.",
      alternative:
          "Не помните состояние или массу — оставьте оценку приблизительной.",
      doneWhen: "Одна запись сопоставлена с известным состоянием продукта.",
      why:
          "Вода при варке меняет массу; согласованность записи предотвращает явную ошибку расчёта.",
      explanation:
          "При готовке крупа впитывает воду: масса меняется без добавления энергии от воды. Выбирайте в каталоге запись, соответствующую сухому или готовому весу; это правило расчёта, не диета.",
    ),
    en: TipCopy(
      "Match dry and cooked grain entries",
      "The same grain weighs differently after cooking.",
      task: "Choose an entry matching what was weighed.",
      steps: [
        "Identify whether the weighed food was dry or cooked.",
        "Check the same state in the catalog description.",
      ],
      example: "Weighed cooked rice? Choose cooked rice rather than dry grain.",
      alternative: "Unknown state or amount? Keep the estimate approximate.",
      doneWhen: "One entry matches the known food state.",
      why:
          "Cooking water changes weight; a matching entry prevents an obvious calculation mismatch.",
      explanation:
          "Grain absorbs water during cooking: weight changes without energy from water. Match the catalog entry to dry or cooked weight; this is bookkeeping, not a diet.",
    ),
  ),
  DailyTip(
    id: "facts-18",
    topic: "portion-uncertainty",
    destination: TipDestination.food,
    category: TipCategory.facts,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Уточните одну удобную порцию",
      "Не нужно добиваться абсолютной точности всего дневника.",
      task: "Проверьте одну известную массу или упаковку в записи.",
      steps: [
        "Выберите продукт с понятной массой.",
        "Уточните только эту деталь и завершите проверку.",
      ],
      example:
          "Йогурт в баночке известной массы вместо случайной стандартной порции.",
      alternative:
          "Для блюда без известного веса допустима приблизительная запись.",
      doneWhen:
          "Одна известная деталь уточнена без требования перепроверить весь день.",
      why:
          "Это делает отдельную запись понятнее, сохраняя честные границы точности.",
      explanation:
          "Размер порции, состав рецепта и этикетка могут давать погрешность. Приложение видит зарегистрированные данные, а не измеряет фактическое потребление.",
    ),
    en: TipCopy(
      "Clarify one convenient portion",
      "Perfect accuracy across the diary is unnecessary.",
      task: "Review one known weight or package size in an entry.",
      steps: [
        "Choose a product with a known amount.",
        "Clarify just that detail and finish the review.",
      ],
      example:
          "A yogurt pot of known weight instead of an arbitrary standard serving.",
      alternative: "A dish with unknown weight can remain approximate.",
      doneWhen: "One known detail is clarified without checking the whole day.",
      why: "This improves one entry while keeping uncertainty honest.",
      explanation:
          "Portion size, recipe composition and labels introduce uncertainty. The app sees recorded data rather than measuring actual intake.",
    ),
  ),
  DailyTip(
    id: "today-02",
    topic: "ingredient-variety",
    destination: TipDestination.food,
    category: TipCategory.today,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Подберите одну новую комбинацию продуктов",
      "Разнообразие можно попробовать без сложного рецепта.",
      task: "Выберите доступный ингредиент для одного знакомого блюда.",
      steps: [
        "Посмотрите, что уже есть или недорого купить.",
        "Решите, в какое привычное блюдо его добавить.",
      ],
      example: "Фасоль в томатный соус; груша к овсянке; капуста к рису.",
      alternative:
          "Если новое покупать неудобно, иначе сочетайте имеющиеся продукты.",
      doneWhen:
          "Выбрана одна конкретная комбинация, а не только название продукта.",
      why:
          "Одна небольшая замена делает меню разнообразнее без обязательного полного пересмотра.",
      explanation:
          "Покупка доступного овоща, крупы или бобовых — один способ разнообразить меню. Идея не требует специального продукта и не обещает изменения веса.",
    ),
    en: TipCopy(
      "Choose one new ingredient combination",
      "Try variety without a complicated recipe.",
      task: "Choose an accessible ingredient for one familiar dish.",
      steps: [
        "Check what you have or can afford.",
        "Decide which familiar dish it will join.",
      ],
      example: "Beans in tomato sauce; pear with oats; cabbage with rice.",
      alternative:
          "Recombine existing ingredients if shopping is inconvenient.",
      doneWhen:
          "One specific combination is chosen rather than only naming a food.",
      why:
          "A small change adds variety without requiring a whole-menu overhaul.",
      explanation:
          "Buying an accessible vegetable, grain or pulse is one way to vary meals. No special product or weight change is promised.",
    ),
  ),
  DailyTip(
    id: "today-03",
    topic: "meal-time",
    destination: TipDestination.none,
    category: TipCategory.today,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Оставьте место для одного приёма пищи",
      "Если дела вытесняют еду, начните с одного окна в расписании.",
      task: "Выберите удобное время и доступный вариант еды.",
      steps: [
        "Посмотрите на реальное расписание.",
        "Решите, где и что сможете поесть без сложной готовки.",
      ],
      example:
          "Между встречами — время на суп с хлебом или заранее подготовленный обед.",
      alternative:
          "Если расписание меняется, выберите запасное окно и готовую еду.",
      doneWhen: "Для одного приёма пищи выбраны время и доступный вариант.",
      why:
          "Связка времени и еды конкретнее общего намерения; пропуск записи не считается пропуском приёма пищи.",
      explanation:
          "Регулярная возможность поесть помогает организовать день. Если пропущены записи, приложение не знает, была ли пропущена еда; действие можно начать с удобного времени для обеда.",
    ),
    en: TipCopy(
      "Make room for one meal",
      "If tasks crowd out food, start with one opening in the schedule.",
      task: "Choose a practical time and an accessible meal option.",
      steps: [
        "Check the actual schedule.",
        "Decide where and what you can eat without complex preparation.",
      ],
      example:
          "Between meetings, make time for soup with bread or a prepared lunch.",
      alternative:
          "With a changing schedule, choose a fallback window and ready-made food.",
      doneWhen: "A time and accessible option are chosen for one meal.",
      why:
          "Pairing time with food is more specific than an intention; missing logs do not prove missed meals.",
      explanation:
          "An opportunity to eat helps organize the day. Missing entries do not tell the app whether food was missed; start with a convenient lunch time.",
    ),
  ),
  DailyTip(
    id: "today-07",
    topic: "gentle-movement",
    destination: TipDestination.none,
    category: TipCategory.today,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Подготовьте короткий доступный маршрут",
      "План можно сократить по самочувствию.",
      task:
          "Выберите знакомый маршрут для следующей посильной прогулки или движения на коляске.",
      steps: [
        "Проверьте удобство пути и место отдыха.",
        "Выберите точку, где легко вернуться раньше.",
      ],
      example: "До знакомого сквера и обратно; короткий путь рядом с домом.",
      alternative:
          "Плохая погода или неподходящее состояние — доступное домашнее движение либо отдых.",
      doneWhen:
          "Выбран маршрут с возможностью сократить его; проходить его сегодня не обязательно.",
      why:
          "Готовый вариант упрощает выбор посильного движения без требований к скорости и дистанции.",
      explanation:
          "Посильное движение можно начинать с короткого маршрута. Если он не подходит вашему состоянию, выберите отдых или согласованную альтернативу, без компенсации еды.",
    ),
    en: TipCopy(
      "Prepare a short accessible route",
      "The plan can be shortened according to how you feel.",
      task:
          "Choose a familiar route for your next manageable walk or wheeling outing.",
      steps: [
        "Check accessibility and a rest spot.",
        "Choose an easy point for turning back early.",
      ],
      example: "To a familiar small park and back; a short route near home.",
      alternative:
          "Bad weather or an unsuitable condition? Choose accessible indoor movement or rest.",
      doneWhen:
          "A route with a shorter option is chosen; doing it today is optional.",
      why:
          "A ready option makes manageable movement easier to choose without speed or distance targets.",
      explanation:
          "Accessible movement can start with a short route. If unsuitable for your condition, choose rest or an agreed alternative, without compensating for food.",
    ),
  ),
  DailyTip(
    id: "today-09",
    topic: "dinner-preparation",
    destination: TipDestination.food,
    category: TipCategory.today,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Подготовьте один ингредиент к ужину",
      "Выберите то, что можно сделать заранее без полной готовки.",
      task: "Подготовьте один компонент будущего ужина по инструкции продукта.",
      steps: [
        "Решите, что будете готовить.",
        "Проверьте упаковку и безопасный способ подготовки и хранения.",
      ],
      example:
          "Заранее проверить овощи для супа; нужный замороженный продукт разморозить по инструкции.",
      alternative:
          "Нет времени на подготовку — выберите подходящие готовые бобовые и хлеб с овощами.",
      doneWhen:
          "Один компонент безопасно подготовлен или выбран готовый запасной вариант.",
      why:
          "Это сокращает вечернюю подготовку, не требуя сложного меню на неделю.",
      explanation:
          "Размораживайте продукт по инструкции и соблюдайте безопасное хранение. Это практическая идея подготовки, без медицинского обещания.",
    ),
    en: TipCopy(
      "Prepare one dinner ingredient",
      "Choose something you can do ahead without cooking the whole meal.",
      task: "Prepare one component according to its instructions.",
      steps: [
        "Decide what you will cook.",
        "Check the package for safe preparation and storage.",
      ],
      example:
          "Check soup vegetables ahead; thaw a needed frozen ingredient as directed.",
      alternative:
          "No prep time? Choose suitable ready-cooked pulses with bread and vegetables.",
      doneWhen:
          "One component is safely prepared or a ready-made fallback chosen.",
      why: "This reduces evening preparation without a complex weekly menu.",
      explanation:
          "Thaw and store food according to safe package instructions. This is a preparation idea without a medical outcome claim.",
    ),
  ),
  DailyTip(
    id: "today-15",
    topic: "backup-meal",
    destination: TipDestination.food,
    category: TipCategory.today,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Соберите запасной вариант еды без плиты",
      "Пригодится в поездке или в вечер без сил.",
      task:
          "Выберите доступную комбинацию без готовки и подготовьте её компоненты.",
      steps: [
        "Выберите основу, например хлеб или готовые хлопья.",
        "Добавьте подходящий белковый продукт и фрукт или овощи.",
      ],
      example: "Хлеб + хумус + овощи; йогурт + овсянка + фрукт.",
      alternative:
          "Вне дома можно выбрать готовый сэндвич и подходящий овощ или фрукт.",
      doneWhen:
          "Для одного запасного приёма пищи известны продукты и где их взять.",
      why:
          "Готовый запасной вариант уменьшает сложность выбора. Это идея еды без точных КБЖУ.",
      explanation:
          "Вариант без плиты: цельнозерновой хлеб, хумус и овощи или йогурт с овсянкой и фруктом. Подберите подходящие замены при аллергиях; КБЖУ здесь не вычислялись.",
    ),
    en: TipCopy(
      "Build a no-stove fallback meal",
      "Useful when travelling or tired in the evening.",
      task:
          "Choose an accessible no-cook combination and prepare its components.",
      steps: [
        "Choose a base such as bread or ready-to-eat oats.",
        "Add a suitable protein food and fruit or vegetables.",
      ],
      example: "Bread + hummus + vegetables; yogurt + oats + fruit.",
      alternative:
          "Away from home, a suitable ready-made sandwich with fruit or vegetables can work.",
      doneWhen:
          "The foods and where to get them are known for one fallback meal.",
      why:
          "A prepared fallback simplifies decisions. This is a meal idea without exact nutrient totals.",
      explanation:
          "A no-cook option: wholegrain bread, hummus and vegetables, or yogurt with oats and fruit. Adapt for allergies; no nutrient totals have been calculated.",
    ),
  ),
  DailyTip(
    id: "insight-short",
    topic: "comparable-weighing",
    destination: TipDestination.insights,
    category: TipCategory.progress,
    basis: TipBasis.observation,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Проверьте даты короткой истории веса",
      "Несколько одинаковых цифр не объясняют долгосрочную динамику.",
      task: "Посмотрите, сколько реальных дней с измерениями доступно.",
      steps: [
        "Откройте анализ и проверьте период и пропуски.",
        "Выберите сопоставимые условия для следующего планового измерения.",
      ],
      example:
          "Три одинаковых записи за три дня — повод продолжить наблюдение без срочного урезания еды.",
      alternative:
          "Если измерения вызывают тревогу, можно сделать паузу и обсудить другой подход.",
      doneWhen:
          "Покрытие проверено и выбран безопасный следующий шаг; новое измерение сегодня не требуется.",
      why:
          "Это помогает отличить короткий участок от многонедельного наблюдения без диагноза плато.",
      explanation:
          "Вода, недавняя еда и условия измерения могут влиять на вес. По одной цифре Balance не определяет причину. Сопоставляйте наблюдения за более длительный период без требования взвешиваться чаще.",
    ),
    en: TipCopy(
      "Check the dates in a short weight history",
      "A few equal readings do not explain long-term progress.",
      task: "Review how many actual measured days are available.",
      steps: [
        "Open insights and check the time span and gaps.",
        "Choose comparable conditions for the next planned reading.",
      ],
      example:
          "Three equal readings over three days call for longer observation without urgent food restriction.",
      alternative:
          "Pause and discuss another approach if measurement causes distress.",
      doneWhen:
          "Coverage is reviewed and a safe next step chosen; no new reading is required today.",
      why:
          "This distinguishes a short stretch from weeks of observation without diagnosing a plateau.",
      explanation:
          "Fluid, recent food and measuring conditions may affect weight. Balance cannot infer a cause from one number. Compare a longer period without a demand to weigh more often.",
    ),
  ),
  DailyTip(
    id: "insight-stable",
    topic: "plateau-review",
    destination: TipDestination.insights,
    category: TipCategory.progress,
    basis: TipBasis.plateau,
    sourceIds: ["mayo-plateau", "niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    weightManagementOnly: true,
    ru: TipCopy(
      "Проверьте одну запись, прежде чем менять план",
      "Сначала посмотрите на качество записей, а не уменьшайте еду.",
      task: "Откройте один завершённый день и проверьте его состав.",
      steps: [
        "В анализе посмотрите период, измеренные дни и пропуски.",
        "Выберите знакомый день питания: всё ли внесено, понятны ли порции?",
        "Уточните одну известную деталь; неизвестное оставьте неизвестным.",
      ],
      example:
          "Вспомнили масло в салате — уточните запись. Не помните количество — не придумывайте точное число.",
      alternative:
          "Нет дневника — запишите условия следующего планового взвешивания; чаще взвешиваться не требуется.",
      doneWhen:
          "Проверен один день или выбран сопоставимый способ следующего измерения.",
      why:
          "Проверка помогает отделить ограниченность записей от наблюдаемой стабильности. Она не доказывает причину и не требует сокращения питания.",
      explanation:
          "При достаточно плотных записях можно заметить устойчивую стабильность. Меньшая масса может требовать меньше энергии, но дневник и вес не доказывают личный энергетический баланс. Проверьте записи и привычный ритм; не уменьшайте питание автоматически.",
    ),
    en: TipCopy(
      "Review one entry before changing the plan",
      "Start with record quality rather than cutting food.",
      task: "Open one completed day and review what was logged.",
      steps: [
        "Check the observation span, measured days and gaps in insights.",
        "Choose a familiar food-log day: are entries and portions understandable?",
        "Clarify one known detail; leave unknown amounts unknown.",
      ],
      example:
          "Remembered oil in a salad? Clarify the entry. If the amount is unknown, do not invent an exact number.",
      alternative:
          "No food log? Note comparable conditions for your next planned weigh-in; extra weigh-ins are unnecessary.",
      doneWhen:
          "One day was reviewed or comparable measuring conditions were chosen.",
      why:
          "This separates record limitations from observed stability. It does not establish a cause or call for eating less.",
      explanation:
          "Sufficiently distributed records can reveal stability. A smaller body may need less energy, but logs and weight do not establish your energy balance. Review records and routines without automatically reducing food.",
    ),
  ),
  DailyTip(
    id: "insight-maintenance",
    topic: "maintenance-routine",
    destination: TipDestination.none,
    category: TipCategory.progress,
    basis: TipBasis.maintenance,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Оставьте одну привычку для поддержания",
      "После достижения цели не нужно обязательно продолжать снижение.",
      task:
          "Выберите удобную привычку, которую хотите сохранить без ужесточения.",
      steps: [
        "Назовите то, что уже помогает организовать день.",
        "Решите, как повторить это в ближайший удобный день.",
      ],
      example:
          "Запасной обед с фасолью; привычное время еды; посильная прогулка ради самочувствия.",
      alternative:
          "В загруженный день оставьте более простой вариант той же привычки.",
      doneWhen: "Одна привычка и её посильный вариант выбраны.",
      why:
          "Поддержание опирается на устойчивый ритм; приложение не назначает дальнейшее похудение.",
      explanation:
          "Выбранная цель или стабильные значения около достигнутого ориентира меняют смысл наблюдения. Поддерживайте удобные привычки, разнообразие и посильное движение вместо новых ограничений. Цель приложения не определяет медицински оптимальный вес.",
    ),
    en: TipCopy(
      "Keep one habit for maintenance",
      "Reaching a target does not require further loss.",
      task: "Choose one practical habit to keep without tightening it.",
      steps: [
        "Name something that already helps organize your day.",
        "Decide how to repeat it on the next convenient day.",
      ],
      example:
          "A backup bean lunch; a usual meal time; manageable movement for wellbeing.",
      alternative: "Keep a simpler version on a demanding day.",
      doneWhen: "One habit and a manageable version are chosen.",
      why:
          "Maintenance can build on a sustainable routine; the app does not prescribe further loss.",
      explanation:
          "A maintenance goal or stable readings near a reached target changes the interpretation. Keep practical routines, variety and accessible movement rather than adding restriction. An app target does not define a medically optimal weight.",
    ),
  ),
  DailyTip(
    id: "insight-down",
    topic: "trend-window",
    destination: TipDestination.weight,
    category: TipCategory.progress,
    basis: TipBasis.weight,
    sourceIds: ["nhs-weigh", "mayo-plateau"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Посмотрите направление за недели",
      "Последняя цифра не обязана продолжать ровную линию.",
      task: "Откройте график за месяц и проверьте реальные даты.",
      steps: [
        "Сначала найдите период с измерениями.",
        "Оцените направление ряда без требования снижать каждую следующую цифру.",
      ],
      example:
          "Отдельный подъём внутри снижающейся истории не доказывает отмену всей тенденции.",
      alternative:
          "Если данных мало, используйте статус недостатка данных вместо угадывания темпа.",
      doneWhen:
          "Период и реальные даты просмотрены без прогноза обязательного результата.",
      why:
          "Более длинный ряд даёт контекст. Он не измеряет потерю жира; неожиданное снижение или слабость требуют медицинского обсуждения.",
      explanation:
          "Реальная история может идти вниз с отдельными подъёмами. Алгоритм использует дневные медианы, но не измеряет потерю жира и не гарантирует продолжение темпа. При слабости или неожиданном снижении обсудите состояние с врачом.",
    ),
    en: TipCopy(
      "Review the direction over weeks",
      "The latest number need not follow a perfectly straight line.",
      task: "Open the monthly graph and check actual dates.",
      steps: [
        "Find the period with real measurements first.",
        "Review the direction without requiring every next reading to fall.",
      ],
      example:
          "One rise within a downward history does not invalidate the whole pattern.",
      alternative:
          "With little data, use the insufficient-data status rather than guessing a rate.",
      doneWhen:
          "The period and actual dates are reviewed without a promised future result.",
      why:
          "A longer series provides context, not a measurement of fat loss; unexpected loss or weakness calls for medical discussion.",
      explanation:
          "A downward history can include individual rises. The algorithm uses daily medians but does not measure fat loss or guarantee a continued rate. Discuss weakness or unexpected loss with a clinician.",
    ),
  ),
  DailyTip(
    id: "insight-body",
    topic: "metric-comparison",
    destination: TipDestination.weight,
    category: TipCategory.progress,
    basis: TipBasis.body,
    sourceIds: ["nhs-weigh"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Сравните вес и обхваты по их датам",
      "Килограммы и сантиметры не нужно сравнивать напрямую.",
      task: "Откройте сравнение и проверьте каждый ряд отдельно.",
      steps: [
        "Найдите даты настоящих измерений.",
        "Посмотрите направление каждого показателя в собственных единицах.",
      ],
      example:
          "Вес и талия меняются в разном темпе — это разные наблюдения, а не доказательство изменения мышц.",
      alternative:
          "Если замеров нет, оставьте их отсутствующими; новые ради заполнения графика не нужны.",
      doneWhen: "Проверены даты доступных рядов без подстановки пропусков.",
      why:
          "Раздельное чтение рядов уменьшает путаницу единиц, сохраняя ограничения измерений.",
      explanation:
          "Сравнивайте каждый ряд по его датам и единицам. Колебания веса и различия техники замера не дают по отдельности измерения мышц или жира. Не подставляйте значения в дни без замеров.",
    ),
    en: TipCopy(
      "Compare weight and circumferences by date",
      "Kilograms and centimetres should not be compared directly.",
      task: "Open comparison and review each series separately.",
      steps: [
        "Find the actual measurement dates.",
        "Read each metric’s direction in its own units.",
      ],
      example:
          "Weight and waist changing at different rates are observations, not proof of muscle change.",
      alternative:
          "Leave missing circumferences absent; extra measurements to fill a chart are unnecessary.",
      doneWhen: "Dates of available series are checked without filling gaps.",
      why:
          "Separate reading avoids confusion between units while keeping measurement limits clear.",
      explanation:
          "Compare each series using its own dates and units. Weight fluctuations and measuring technique cannot individually measure muscle or fat. Leave dates without readings empty.",
    ),
  ),
  DailyTip(
    id: "meal-breakfast",
    topic: "breakfast",
    destination: TipDestination.food,
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating", "nhs-fibre"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Соберите завтрак без сложного рецепта",
      "Выберите одну из двух комбинаций и адаптируйте под свой аппетит.",
      task: "Подготовьте продукты для одного удобного завтрака.",
      steps: [
        "Выберите основу: овсянку или хлеб.",
        "Добавьте подходящий белковый продукт и фрукт или овощ.",
      ],
      example: "Овсянка + йогурт + яблоко; хлеб + яйцо + помидор.",
      alternative:
          "Вместо яйца — фасолевая намазка или тофу; вместо молочного — подходящий растительный продукт.",
      doneWhen: "Один вариант собран или продукты для него подготовлены.",
      why:
          "Готовая комбинация сокращает утренний выбор и объединяет разные группы продуктов. Это идея еды, без расчёта КБЖУ.",
      explanation:
          "Это примеры сочетания разных групп продуктов. При вегетарианском выборе подойдут бобовая намазка или тофу; при исключении молочного сравните состав обогащённой альтернативы. Размер порции и время еды зависят от вас.",
    ),
    en: TipCopy(
      "Build an easy breakfast",
      "Choose one of two combinations and adapt it to your appetite.",
      task: "Prepare the ingredients for one convenient breakfast.",
      steps: [
        "Choose oats or bread as a base.",
        "Add a suitable protein food and fruit or vegetables.",
      ],
      example: "Oats + yogurt + apple; bread + egg + tomato.",
      alternative:
          "Use bean spread or tofu instead of egg, or a suitable plant alternative to dairy.",
      doneWhen: "One breakfast is assembled or its ingredients are ready.",
      why:
          "A ready combination reduces morning decisions and combines food groups. This is a meal idea without calculated nutrients.",
      explanation:
          "These examples combine food groups. Bean spread or tofu can suit vegetarian choices; compare fortified alternatives when avoiding dairy. Portion size and timing depend on your needs.",
    ),
  ),
  DailyTip(
    id: "meal-lunch",
    topic: "meal-building",
    destination: TipDestination.food,
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Соберите обед из доступных компонентов",
      "Выберите основу, белковый продукт и овощи без сложных пропорций.",
      task: "Соедините доступные продукты в один удобный обед.",
      steps: [
        "Возьмите знакомую крупу, хлеб или картофель.",
        "Добавьте подходящий белковый продукт, овощи и заправку по вкусу.",
      ],
      example:
          "Рис + фасоль + капуста + масло; картофель + рыба + огурец; булгур + тофу + овощи.",
      alternative:
          "Подойдут готовая крупа, бобовые из банки и овощи без долгой готовки.",
      doneWhen: "Один подходящий вариант собран или его продукты подготовлены.",
      why:
          "Сочетание разных групп пищи упрощает разнообразный обед; это идея блюда, без расчёта КБЖУ и обещания сытости для всех.",
      explanation:
          "Например, чечевица или курица, гречка и овощи с растительным маслом. Сочетание помогает разнообразить рацион; порции не универсальны, а насыщение индивидуально.",
    ),
    en: TipCopy(
      "Build lunch from available components",
      "Choose a base, protein food and vegetables without exact ratios.",
      task: "Combine accessible foods into one convenient lunch.",
      steps: [
        "Use a familiar grain, bread or potatoes.",
        "Add a suitable protein food, vegetables and dressing to taste.",
      ],
      example:
          "Rice + beans + cabbage + oil; potato + fish + cucumber; bulgur + tofu + vegetables.",
      alternative:
          "Ready-cooked grain, canned pulses and vegetables save cooking time.",
      doneWhen: "One suitable option is assembled or its ingredients prepared.",
      why:
          "Food groups offer a practical starting point; this is a meal idea without calculated nutrients or guaranteed fullness.",
      explanation:
          "Try lentils or chicken with buckwheat and vegetables with plant oil. The combination supports variety; portions are not universal and fullness varies.",
    ),
  ),
  DailyTip(
    id: "meal-budget",
    topic: "batch-base",
    destination: TipDestination.food,
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Используйте одну основу для двух блюд",
      "Планируйте из обычных круп, бобовых и доступных овощей.",
      task: "Выберите два блюда с одним недорогим базовым продуктом.",
      steps: [
        "Проверьте основу и безопасное приготовление и хранение по упаковке.",
        "Меняйте дополнения вместо покупки двух разных наборов.",
      ],
      example:
          "Рис с фасолью и овощами; рис с яйцом и капустой. Или чечевичный суп и соус.",
      alternative:
          "Если заранее готовить неудобно, используйте подходящие готовые компоненты.",
      doneWhen:
          "Выбраны два блюда с общей основой и подходящий способ подготовки.",
      why:
          "Общая основа упрощает покупки и готовку; дорогие продукты и добавки не обязательны.",
      explanation:
          "Можно приготовить крупу на несколько блюд и менять белковое дополнение. Соблюдайте безопасное хранение и инструкцию продукта. Дорогие добавки для этого не требуются.",
    ),
    en: TipCopy(
      "Use one base for two meals",
      "Plan around familiar grains, pulses and accessible vegetables.",
      task: "Choose two meals sharing an affordable base.",
      steps: [
        "Check the base and its preparation and storage instructions.",
        "Vary additions instead of buying two separate sets of foods.",
      ],
      example:
          "Rice with beans and vegetables; rice with egg and cabbage. Or lentil soup and sauce.",
      alternative:
          "Use suitable ready-made components if batch preparation is inconvenient.",
      doneWhen: "Two meals and a suitable preparation approach are chosen.",
      why:
          "A shared base simplifies shopping and cooking; expensive foods and supplements are unnecessary.",
      explanation:
          "Prepare a grain for different dishes and vary the protein addition. Follow safe storage and package instructions. Expensive supplements are unnecessary.",
    ),
  ),
  DailyTip(
    id: "food-protein",
    usesLoggedMacros: true,
    topic: "protein-rotation",
    destination: TipDestination.food,
    category: TipCategory.macros,
    basis: TipBasis.variety,
    sourceIds: ["who-diet", "niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Подберите замену к одному записанному блюду",
      "Если среди записей повторяются продукты, попробуйте одну подходящую альтернативу.",
      task:
          "Выберите один знакомый белковый компонент и вариант для чередования.",
      steps: [
        "Откройте знакомый день и найдите подходящий компонент.",
        "Сохраните остальное блюдо, меняя только один продукт по желанию.",
      ],
      example:
          "В рисе с курицей — фасоль или тофу; к хлебу с сыром — яйцо или бобовая намазка.",
      alternative:
          "Если менять продукт не хочется, приготовьте его другим привычным способом.",
      doneWhen:
          "Выбрана одна подходящая пара для чередования; полный рацион по записям не оценивается.",
      why:
          "Это даёт практический вариант разнообразия. Суммы БЖУ не доказывают недостаток белка или точное потребление.",
      explanation:
          "Сравните записанные блюда. Можно чередовать яйца, рыбу, птицу, подходящие молочные продукты, фасоль или тофу. Неполные записи и суммы БЖУ не доказывают, сколько белка вы реально получили.",
    ),
    en: TipCopy(
      "Choose a substitution for one logged dish",
      "If foods recur in your records, try one suitable alternative.",
      task:
          "Choose a familiar protein component and an option to rotate with it.",
      steps: [
        "Open a familiar day and find a suitable component.",
        "Keep the rest of the meal and change just one food if desired.",
      ],
      example:
          "In rice with chicken, try beans or tofu; rotate cheese on bread with egg or bean spread.",
      alternative:
          "Keep the food but use another familiar preparation if you prefer.",
      doneWhen:
          "One suitable rotation pair is chosen; records do not establish the whole diet.",
      why:
          "This offers practical variety. Macro totals do not establish protein deficiency or exact intake.",
      explanation:
          "Review logged dishes. Eggs, fish, poultry, suitable dairy, beans or tofu offer options. Incomplete entries and macro totals do not establish actual protein intake.",
    ),
  ),
  DailyTip(
    id: "diary-gaps",
    topic: "log-coverage",
    destination: TipDestination.food,
    category: TipCategory.habits,
    basis: TipBasis.diary,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Проверьте один завершённый день дневника",
      "Отсутствующая запись не означает, что еды не было.",
      task:
          "Просмотрите один день и уточните только то, что действительно помните.",
      steps: [
        "Выберите недавний знакомый день.",
        "Проверьте основные блюда, напитки и дополнения без требования восстановить всё идеально.",
      ],
      example:
          "Вспомнили перекус и известный продукт — добавьте запись; неизвестное количество не угадывайте.",
      alternative:
          "Если восстановить день трудно, начните с одной удобной записи сегодня.",
      doneWhen: "Один день просмотрен или выбрана следующая посильная запись.",
      why:
          "Так видны ограничения дневника; даже день с записями не считается автоматически полным.",
      explanation:
          "Приложение не может проверить полноту дневника. Даже заполненные дни могут не включать напитки, перекусы или добавки. Поэтому средняя записанная энергия не равна точно известному потреблению и не доказывает дефицит.",
    ),
    en: TipCopy(
      "Review one completed food-log day",
      "A missing entry does not mean no food was eaten.",
      task: "Review one day and clarify only what you actually remember.",
      steps: [
        "Choose a recent familiar day.",
        "Check meals, drinks and additions without reconstructing everything perfectly.",
      ],
      example:
          "Remembered a snack and known product? Log it without guessing an unknown amount.",
      alternative:
          "If reconstruction is difficult, make one manageable entry today.",
      doneWhen: "One day is reviewed or a next manageable entry chosen.",
      why:
          "This identifies diary limits; a day with entries is still not automatically complete.",
      explanation:
          "The app cannot verify diary completeness. Even logged days may omit drinks, snacks or additions. Average logged energy is not exact known consumption and does not establish a deficit.",
    ),
  ),
  DailyTip(
    id: "diary-additions",
    topic: "recipe-ingredients",
    destination: TipDestination.food,
    category: TipCategory.habits,
    basis: TipBasis.universal,
    sourceIds: ["niddk-portions"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Уточните соус в одном знакомом блюде",
      "Запись дополнения не означает запрет на него.",
      task: "Проверьте один известный соус, масло или добавку в составе блюда.",
      steps: [
        "Выберите блюдо, состав которого знаете.",
        "Уточните продукт и известное количество либо сохраните приблизительность.",
      ],
      example:
          "В домашнем салате проверьте, учтена ли заправка, если знаете её состав.",
      alternative: "Для еды вне дома без рецепта не придумывайте точные КБЖУ.",
      doneWhen: "Один известный компонент проверен без сокращения еды.",
      why:
          "Так запись лучше описывает блюдо; проверка не доказывает причину стабильного веса.",
      explanation:
          "Если хотите проверить дневник, посмотрите на заправки, масло при готовке и напитки. Уточнение записи не означает запрет продукта и не требует сокращения еды.",
    ),
    en: TipCopy(
      "Clarify the sauce in one familiar dish",
      "Recording an addition does not ban it.",
      task: "Review one known sauce, oil or addition in a dish.",
      steps: [
        "Choose food whose ingredients you know.",
        "Clarify the product and known amount or retain uncertainty.",
      ],
      example:
          "Check whether a home salad includes its dressing when ingredients are known.",
      alternative:
          "Do not invent exact nutrients for food away from home without a recipe.",
      doneWhen: "One known component is reviewed without cutting food.",
      why:
          "This better describes a dish without proving the cause of stable weight.",
      explanation:
          "To review a diary, look at dressings, cooking oil and drinks. Clarifying a record does not ban a food or require eating less.",
    ),
  ),
  DailyTip(
    id: "diary-low",
    topic: "log-coverage",
    destination: TipDestination.food,
    category: TipCategory.habits,
    basis: TipBasis.gentleFuel,
    sourceIds: ["nhs-eating-support", "niddk-planner", "cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "При низких записях сначала проверьте полноту",
      "Мало записано не значит доказанно мало съедено.",
      task:
          "Выберите один низко заполненный день и спокойно проверьте известные записи.",
      steps: [
        "Посмотрите, всё ли известное внесено, не угадывая неизвестное.",
        "Если питание действительно ограничено, выберите регулярную еду и подходящую поддержку.",
      ],
      example:
          "Пропущенный известный обед можно записать; если едите недостаточно, обсудить это со специалистом.",
      alternative:
          "Если контроль вызывает навязчивость, допустима пауза и индивидуальная помощь.",
      doneWhen:
          "Проверена полнота либо выбран поддерживающий шаг, без новых ограничений.",
      why:
          "Это отделяет возможные пропуски от потребности в помощи. Balance не предлагает уменьшать рацион или компенсировать тренировкой.",
      explanation:
          "Проверьте полноту записей. Если еда действительно длительно ограничена, есть слабость или навязчивый контроль, обратитесь к врачу или специалисту по питанию. Balance не предлагает урезать рацион или компенсировать его тренировкой.",
    ),
    en: TipCopy(
      "For low logs, review completeness first",
      "Little logged is not proof of little eaten.",
      task: "Choose one low-log day and gently review known entries.",
      steps: [
        "Check known foods without guessing missing details.",
        "If eating is genuinely restricted, make room for regular food and suitable support.",
      ],
      example:
          "Log a remembered known lunch; discuss inadequate eating with a professional if relevant.",
      alternative:
          "Pause tracking and seek individual support if checking becomes compulsive.",
      doneWhen:
          "Completeness is reviewed or a supportive step chosen without new restriction.",
      why:
          "This separates possible omissions from a need for support. Balance does not suggest cutting food or compensatory exercise.",
      explanation:
          "Review the entries. If intake is persistently restricted, or you experience weakness or compulsive control, seek clinical or nutrition support. Balance does not suggest cutting food or compensating with exercise.",
    ),
  ),
  DailyTip(
    id: "recovery-stress",
    topic: "busy-day-support",
    destination: TipDestination.food,
    category: TipCategory.recovery,
    basis: TipBasis.universal,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Составьте простой план для загруженного дня",
      "Поддержите еду и отдых без требования исправить всё сразу.",
      task: "Выберите доступный приём пищи и одну посильную передышку.",
      steps: [
        "Подберите еду без сложной готовки.",
        "Решите, какое дело можно перенести или о какой помощи попросить.",
      ],
      example:
          "Хлеб с хумусом и овощами; йогурт с овсянкой и фруктом, затем спокойная пауза.",
      alternative: "Готовая подходящая еда и сообщение близкому тоже вариант.",
      doneWhen:
          "Еда выбрана и одна форма поддержки запланирована или получена.",
      why:
          "Конкретный запасной план упрощает день; он не доказывает, что стресс был причиной изменения веса.",
      explanation:
          "В загруженный день могут измениться аппетит, сон и движение. Приложение не измеряет эти причины. Поддержка, посильный отдых и доступная еда полезнее обвинения себя.",
    ),
    en: TipCopy(
      "Make a simple plan for a demanding day",
      "Support eating and rest without fixing everything at once.",
      task: "Choose an accessible meal and one manageable breather.",
      steps: [
        "Pick food that needs little preparation.",
        "Decide which task can wait or what help to request.",
      ],
      example:
          "Bread with hummus and vegetables; yogurt with oats and fruit, then a quiet break.",
      alternative:
          "Suitable ready-made food and a message to someone close can work too.",
      doneWhen: "Food is chosen and one form of support planned or received.",
      why:
          "A concrete fallback makes the day easier; it does not establish stress as the cause of weight change.",
      explanation:
          "A demanding day may affect appetite, sleep and movement. The app does not measure these causes. Support, manageable rest and accessible food are more useful than self-blame.",
    ),
  ),
  DailyTip(
    id: "facts-fluid",
    topic: "short-term-fluctuation",
    destination: TipDestination.weight,
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
      "Сопоставьте условия двух взвешиваний",
      "Краткий скачок веса не определяет изменение жира.",
      task:
          "Сравните даты и известные условия двух записей без срочных ограничений.",
      steps: [
        "Посмотрите, сопоставимы ли время и условия.",
        "Отметьте только известные различия, не выбирая причину по графику.",
      ],
      example: "Вечерняя запись после еды и утренняя запись — разные условия.",
      alternative:
          "Если условия неизвестны, оставьте причину неизвестной и выберите сходные условия на будущее.",
      doneWhen:
          "Сравнены известные условия; еда и вода не ограничены ради цифры.",
      why:
          "Еда, жидкость и другие факторы могут менять массу; это возможные объяснения, не личный диагноз.",
      explanation:
          "Соль, изменение количества углеводов и непривычная нагрузка могут сопровождаться изменением воды. Еда в пищеварительном тракте тоже влияет на массу. Гормональные изменения иногда связаны с колебаниями; контекст цикла нельзя вывести по полу. Balance не определяет, какая из причин относится к вам.",
    ),
    en: TipCopy(
      "Compare the conditions of two weigh-ins",
      "A short-term jump does not establish a fat change.",
      task: "Compare dates and known conditions without urgent restriction.",
      steps: [
        "Check whether timing and conditions are comparable.",
        "Note only known differences rather than assigning a cause from a chart.",
      ],
      example:
          "An evening reading after food and a morning reading reflect different conditions.",
      alternative:
          "Leave the cause unknown when conditions are unknown; choose comparable conditions next time.",
      doneWhen:
          "Known conditions are compared without restricting food or water for the number.",
      why:
          "Food, fluid and other factors may affect weight; these are possibilities, not a personal diagnosis.",
      explanation:
          "Salt, carbohydrate changes and unfamiliar activity may accompany changes in body water. Digestive contents also affect weight. Hormonal changes can accompany fluctuations; sex alone does not reveal cycle context. Balance cannot identify which explanation applies to you.",
    ),
  ),
  DailyTip(
    id: "activity-context",
    topic: "gentle-movement",
    destination: TipDestination.none,
    category: TipCategory.activity,
    basis: TipBasis.steps,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Выберите посильную паузу после просмотра шагов",
      "Записи шагов дают контекст, но не обязательную норму.",
      task:
          "После просмотра доступных записей выберите комфортное движение или отдых.",
      steps: [
        "Проверьте, есть ли завершённые дни и было ли устройство с вами.",
        "Выберите знакомую доступную паузу без цели сжечь еду.",
      ],
      example:
          "После работы — короткая прогулка, доступное движение на коляске или смена положения.",
      alternative:
          "Если данные неполны или движение не подходит, можно остановиться на отдыхе.",
      doneWhen: "Ограничения записей проверены и выбран безопасный вариант.",
      why:
          "Так цифры связываются с реальными обстоятельствами без вывода о расходе калорий или причине стабильности.",
      explanation:
          "Если устройство было с вами, записи помогут вспомнить более спокойные дни. Но пропуски и неполный день ограничивают сравнение. Шаги не дают точного расхода калорий и не доказывают причину стабильности веса.",
    ),
    en: TipCopy(
      "Choose a manageable break after reviewing steps",
      "Step records offer context rather than a required target.",
      task:
          "After reviewing available records, choose comfortable movement or rest.",
      steps: [
        "Check for completed days and whether you carried the device.",
        "Choose a familiar accessible break without trying to burn off food.",
      ],
      example: "After work: a short walk, wheeling or a position change.",
      alternative:
          "Rest is valid if records are incomplete or movement unsuitable.",
      doneWhen: "Record limits are checked and a safe option chosen.",
      why:
          "This connects numbers with circumstances without inferring calorie use or the cause of stability.",
      explanation:
          "When the device was with you, records may help recall quieter days. Missing data and partial days limit comparisons. Steps do not provide exact expenditure or explain stable weight.",
    ),
  ),
  DailyTip(
    id: "care-context",
    topic: "professional-support",
    destination: TipDestination.none,
    category: TipCategory.mindful,
    basis: TipBasis.universal,
    sourceIds: ["nhs-eating-support", "niddk-planner", "cdc-habits"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Подготовьте один вопрос для специалиста",
      "Если общих советов недостаточно, начните с конкретной ситуации.",
      task: "Запишите один вопрос о безопасном и подходящем вам плане.",
      steps: [
        "Назовите ограничение или то, что долго беспокоит.",
        "Подготовьте известные даты или пример, если это удобно.",
      ],
      example:
          "«Какой режим питания подойдёт при моих ограничениях?»; «Что обсудить при длительной стабильности?»",
      alternative:
          "Не хотите вести записи — достаточно одного устного вопроса.",
      doneWhen:
          "Подготовлен вопрос без самостоятельного назначения диеты, лекарств или анализов.",
      why:
          "Индивидуальная помощь учитывает возраст, беременность, лактацию, риск РПП и медицинские ограничения, которые общая статья не оценивает.",
      explanation:
          "Для несовершеннолетних, беременности, грудного вскармливания, риска расстройства питания и известных противопоказаний нужны индивидуальные рекомендации. Если контекст не уточнён, Balance не назначает персональные нормы или усиление ограничений.",
    ),
    en: TipCopy(
      "Prepare one question for a professional",
      "When general tips are insufficient, start with a specific situation.",
      task: "Write one question about a safe plan that suits you.",
      steps: [
        "Name a restriction or a persistent concern.",
        "Prepare known dates or an example if convenient.",
      ],
      example:
          "“What eating routine suits my restrictions?”; “What should we review about persistent stability?”",
      alternative:
          "One spoken question is enough if you prefer not to keep notes.",
      doneWhen:
          "A question is ready without self-prescribing a diet, medicines or tests.",
      why:
          "Individual support considers age, pregnancy, breastfeeding, eating-disorder risk and medical restrictions that a general article cannot assess.",
      explanation:
          "Minors, pregnancy, breastfeeding, eating-disorder risk and known contraindications call for individual guidance. With unknown context, Balance does not prescribe personal targets or tighter restrictions.",
    ),
  ),
  DailyTip(
    id: "meal-no-fridge",
    topic: "packed-lunch-storage",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-chilling"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Обед без холодильника",
      "Если на работе негде охлаждать еду.",
      task:
          "Выберите продукты, которые до открытия можно хранить без холодильника.",
      steps: [
        "Прочитайте условия хранения каждого продукта.",
        "Соберите еду перед приёмом пищи, не храните открытые остатки в тепле.",
      ],
      example:
          "Хлеб, целый фрукт и маленькая банка фасоли, открытая перед едой.",
      alternative:
          "Купите охлаждённую готовую еду непосредственно перед обедом.",
      doneWhen: "Выбран обед с проверенными условиями хранения.",
      why:
          "Хранение становится частью плана обеда, а не неожиданной проблемой.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Lunch without a fridge",
      "For a workplace without chilled storage.",
      task:
          "Choose foods labelled for room-temperature storage before opening.",
      steps: [
        "Read storage instructions for each item.",
        "Assemble at mealtime; do not keep opened leftovers warm.",
      ],
      example:
          "Bread, whole fruit and a small bean tin opened just before eating.",
      alternative: "Buy a chilled ready meal immediately before lunch.",
      doneWhen: "A lunch with checked storage needs is chosen.",
      why: "Storage becomes part of the lunch plan rather than a surprise.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-canteen",
    topic: "meal-canteen",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Сориентируйтесь в столовой",
      "Когда меню заранее неизвестно.",
      task:
          "Найдите в сегодняшнем меню подходящие основное блюдо и дополнение.",
      steps: [
        "Посмотрите весь доступный выбор.",
        "Уточните состав незнакомого блюда и выберите сочетание по своим потребностям.",
      ],
      example: "Рыба с картофелем и салатом; чечевичный суп с хлебом.",
      alternative:
          "Если выбора мало, возьмите подходящее готовое сочетание без требования идеальной тарелки.",
      doneWhen: "Выбрано конкретное сочетание из доступного меню.",
      why:
          "Решение опирается на реальный выбор, а не на недоступное идеальное меню.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Navigate a canteen menu",
      "When the menu is not known in advance.",
      task: "Find a suitable main and accompaniment on today’s menu.",
      steps: [
        "Look at the available choices.",
        "Ask about unfamiliar ingredients and choose a combination for your needs.",
      ],
      example: "Fish with potato and salad; lentil soup with bread.",
      alternative:
          "With limited choice, use a suitable available meal without requiring a perfect plate.",
      doneWhen: "A specific available combination is chosen.",
      why:
          "The decision uses real options rather than an unavailable ideal menu.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-buffet",
    topic: "meal-buffet",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Сначала осмотритесь у общего стола",
      "Если трудно выбрать среди множества блюд.",
      task: "Перед выбором еды спокойно осмотрите доступные блюда.",
      steps: [
        "Найдите знакомые и подходящие продукты.",
        "Выберите желанное сочетание; за добавкой можно вернуться.",
      ],
      example:
          "На общем столе найдите плов, овощи и подходящую закуску, затем решите, что хочется.",
      alternative: "Попросите хозяина назвать состав нескольких блюд.",
      doneWhen: "Сделан осознанный выбор без запрета на добавку.",
      why:
          "Короткий обзор упрощает выбор среди множества вариантов без подсчёта каждого кусочка.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Look around a buffet first",
      "When many dishes make choosing difficult.",
      task: "Look over the available dishes before choosing food.",
      steps: [
        "Find familiar foods that suit you.",
        "Choose a combination you want; returning for more is allowed.",
      ],
      example:
          "Find rice pilaf, vegetables and a suitable starter, then decide what appeals.",
      alternative: "Ask the host about a few dishes.",
      doneWhen: "A considered choice is made without banning seconds.",
      why:
          "A brief overview simplifies a crowded choice without counting every bite.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-delivery-budget",
    topic: "meal-delivery-budget",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Заказ еды в пределах бюджета",
      "Когда нужна доставка без сложной готовки.",
      task: "Сравните итоговую цену двух подходящих заказов.",
      steps: [
        "Проверьте доставку, минимальную сумму и состав блюда.",
        "Выберите заказ, который подходит по еде и полной стоимости.",
      ],
      example:
          "Суп с хлебом из соседнего кафе может стоить иначе после оплаты доставки.",
      alternative:
          "Самовывоз или готовая еда поблизости, если это удобно и доступно.",
      doneWhen: "Выбран вариант с известной итоговой ценой.",
      why:
          "Полная стоимость помогает избежать неожиданной траты при заказе еды.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Order within a food budget",
      "When delivery replaces cooking.",
      task: "Compare the full price of two suitable orders.",
      steps: [
        "Check delivery fees, minimum spend and meal contents.",
        "Choose food that suits both your needs and the total budget.",
      ],
      example:
          "Nearby soup with bread may cost differently after delivery fees.",
      alternative: "Use collection or nearby prepared food if accessible.",
      doneWhen: "An option with a known total price is chosen.",
      why: "The full price helps prevent an unexpected food expense.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-shift-handover",
    topic: "meal-time",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Еда при сменном графике",
      "Если смена сдвигает обычные часы еды.",
      task: "Привяжите один приём пищи к реальной паузе на смене.",
      steps: [
        "Уточните время доступного перерыва и хранения еды.",
        "Подготовьте основной вариант и вариант при переносе паузы.",
      ],
      example:
          "Обед в доступный перерыв; при переносе — подходящий перекус до следующей возможности поесть.",
      alternative:
          "Уточните возможность перерыва с руководителем, если еда регулярно недоступна.",
      doneWhen: "Есть план для обычной и сдвинутой паузы.",
      why:
          "План учитывает устройство смены, не требует есть по чужому расписанию.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Food around shift work",
      "When a shift moves usual meal times.",
      task: "Anchor one meal to an actual break on your shift.",
      steps: [
        "Check break times and food storage access.",
        "Choose a main option and a fallback for a delayed break.",
      ],
      example:
          "Lunch in the available break; a suitable snack if the break moves.",
      alternative:
          "Discuss access to a break if eating is regularly impractical.",
      doneWhen: "Both the usual and delayed break have a food plan.",
      why: "The plan follows the shift rather than someone else’s timetable.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-family-components",
    topic: "meal-family-components",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Один ужин с разными предпочтениями",
      "Если дома едят по-разному.",
      task: "Подайте компоненты ужина отдельно для самостоятельного сочетания.",
      steps: [
        "Выберите общую основу.",
        "Разложите подходящие белковые продукты, овощи и соус отдельно.",
      ],
      example: "Картофель, фасоль, рыба и овощи отдельными блюдами.",
      alternative:
          "Оставьте одну общую основу и одно индивидуальное дополнение.",
      doneWhen:
          "Семья может собрать разные сочетания без нескольких полных ужинов.",
      why:
          "Раздельная подача учитывает предпочтения и уменьшает объём отдельной готовки.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "One dinner, different preferences",
      "When household preferences differ.",
      task: "Serve dinner components separately for people to combine.",
      steps: [
        "Choose a shared base.",
        "Set out suitable protein foods, vegetables and sauce separately.",
      ],
      example: "Potato, beans, fish and vegetables in separate dishes.",
      alternative: "Use one shared base and one individual addition.",
      doneWhen:
          "Different combinations are available without cooking several full dinners.",
      why:
          "Separate components accommodate preferences with less separate cooking.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-single-shop",
    topic: "meal-single-shop",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Покупки для одного человека",
      "Если большая упаковка часто остаётся несъеденной.",
      task:
          "Сравните пригодную к использованию стоимость маленькой и большой упаковки.",
      steps: [
        "Оцените, сколько реально используете до срока хранения.",
        "Выберите размер или делимый замороженный продукт под свои возможности.",
      ],
      example:
          "Небольшой йогурт вместо большой банки; замороженные овощи, которые можно брать частями.",
      alternative: "Разделите покупку с близким, если это удобно.",
      doneWhen: "Выбран размер с понятным использованием остатка.",
      why: "Дешевле за килограмм не всегда означает дешевле за съеденную еду.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Shop for one person",
      "When large packs often go unused.",
      task: "Compare usable cost rather than only the price per kilogram.",
      steps: [
        "Consider how much you can use within storage limits.",
        "Choose a pack size or separable frozen food that fits.",
      ],
      example:
          "A small yogurt pot; frozen vegetables that can be taken in portions.",
      alternative: "Share a purchase with someone if convenient.",
      doneWhen: "A pack size with a clear use for the remainder is chosen.",
      why:
          "A lower unit price does not always mean cheaper food actually eaten.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-low-appetite",
    topic: "meal-low-appetite",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["nhs-eating-support"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Еда, когда большая тарелка не привлекает",
      "Если сейчас проще начать с небольшого объёма.",
      task: "Выберите небольшую привычную еду с возможностью добавить позже.",
      steps: [
        "Возьмите переносимые продукты без требования доесть большую порцию.",
        "Оставьте доступное дополнение на случай дальнейшего аппетита.",
      ],
      example: "Небольшой бутерброд с яйцом и суп; рядом ещё хлеб.",
      alternative:
          "Если снижение аппетита держится или мешает есть, обсудите это со специалистом.",
      doneWhen:
          "Есть доступная еда и возможность продолжить, без цели урезать рацион.",
      why:
          "Небольшое начало может быть удобнее большой тарелки; это не план ограничения еды.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "When a large plate feels unappealing",
      "If a smaller amount feels easier to start with.",
      task: "Choose familiar food in a manageable amount with more available.",
      steps: [
        "Use tolerated foods without requiring a large serving.",
        "Keep an addition available if you want more.",
      ],
      example: "A small egg sandwich and soup, with more bread available.",
      alternative:
          "Discuss persistent appetite loss or difficulty eating with a professional.",
      doneWhen:
          "Food and the option to continue are available, without a restriction goal.",
      why:
          "A small start may be more manageable; this is not a food-reduction plan.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-soft-texture",
    topic: "meal-soft-texture",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Измените текстуру привычного блюда",
      "Когда просто хочется более мягкой еды.",
      task: "Переделайте знакомое блюдо в мягкую комбинацию.",
      steps: [
        "Выберите привычные переносимые продукты.",
        "Разомните или измельчите их и сохраните разные компоненты еды.",
      ],
      example: "Картофельное пюре с мягкой фасолью и тушёной морковью.",
      alternative:
          "Обычная текстура тоже подходит; при трудностях глотания нужна индивидуальная помощь.",
      doneWhen:
          "Выбрана удобная текстура без самостоятельного лечения проблем глотания.",
      why:
          "Изменение текстуры даёт другой способ использовать привычные продукты.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Change a familiar meal’s texture",
      "When softer food simply sounds more appealing.",
      task: "Turn familiar foods into a soft combination.",
      steps: [
        "Choose tolerated familiar ingredients.",
        "Mash or soften them while keeping different meal components.",
      ],
      example: "Mashed potato with soft beans and stewed carrot.",
      alternative:
          "Keep the usual texture if preferred; swallowing difficulty needs individual advice.",
      doneWhen:
          "A comfortable texture is chosen without self-treating swallowing problems.",
      why: "Changing texture offers another way to use familiar ingredients.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-one-burner",
    topic: "meal-one-burner",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Ужин на одной конфорке",
      "Если одновременно можно готовить только в одной кастрюле.",
      task: "Расположите этапы готовки по времени готовности продуктов.",
      steps: [
        "Прочитайте инструкции выбранных продуктов.",
        "Сначала готовьте самый долгий компонент, затем добавляйте подходящие остальные.",
      ],
      example: "Овощной суп: картофель раньше, готовая фасоль ближе к концу.",
      alternative:
          "Возьмите готовую основу, если последовательная готовка неудобна.",
      doneWhen:
          "Выбран порядок, при котором все компоненты доведены до готовности.",
      why: "Последовательность помогает обойтись ограниченным оборудованием.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Dinner with one burner",
      "When only one pot can be used at a time.",
      task: "Order cooking steps by the ingredients’ cooking times.",
      steps: [
        "Read the instructions for your ingredients.",
        "Start the slowest component first, adding suitable others later.",
      ],
      example: "Vegetable soup: potato first, ready-cooked beans near the end.",
      alternative:
          "Use a ready-cooked base if sequential cooking is impractical.",
      doneWhen: "A sequence that cooks every component properly is chosen.",
      why: "Sequencing makes a meal possible with limited equipment.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-cultural-staple",
    topic: "meal-building",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Сохраните привычное национальное блюдо",
      "Если советы кажутся чуждыми вашей кухне.",
      task: "Найдите подходящее дополнение к любимому традиционному блюду.",
      steps: [
        "Сохраните знакомую основу и способ подачи.",
        "Выберите привычное для вашей кухни дополнение по потребностям.",
      ],
      example: "К плову — овощи; к лепёшке — бобовое блюдо; к гречке — рыба.",
      alternative:
          "Оставьте блюдо как есть и обсудите адаптацию лечебной диеты со специалистом.",
      doneWhen: "Намечено сочетание, которое сохраняет знакомую кухню.",
      why:
          "Разнообразие можно строить на своих привычках без замены всей кухни.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Keep a familiar cultural dish",
      "When food advice feels distant from your cuisine.",
      task: "Find a suitable accompaniment for a favourite traditional dish.",
      steps: [
        "Keep the familiar base and way of serving.",
        "Choose an accompaniment from your cuisine for your needs.",
      ],
      example:
          "Vegetables with pilaf; pulses with flatbread; fish with buckwheat.",
      alternative:
          "Keep the dish as it is and discuss clinical adaptations with a professional.",
      doneWhen: "A combination that preserves familiar cuisine is identified.",
      why:
          "Variety can build on existing food traditions without replacing them.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-soup-main",
    topic: "meal-soup-main",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Суп как основной приём пищи",
      "Если обычного лёгкого супа вам недостаточно.",
      task:
          "Подберите дополнение, которое сделает суп удобным основным блюдом.",
      steps: [
        "Посмотрите, что уже есть в супе.",
        "Добавьте недостающий удобный компонент по аппетиту.",
      ],
      example:
          "К овощному бульону — хлеб с фасолевой намазкой; к чечевичному супу — хлеб и овощи.",
      alternative:
          "Подойдёт другое привычное основное блюдо, если суп не хочется.",
      doneWhen: "Выбрано дополнение к конкретному супу.",
      why:
          "Дополнение позволяет учитывать состав супа и собственную потребность в еде.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Make soup a main meal",
      "When a light soup alone is not enough for you.",
      task: "Choose an accompaniment that makes soup a useful main meal.",
      steps: [
        "Check what the soup already contains.",
        "Add a convenient component according to appetite.",
      ],
      example:
          "Bread with bean spread alongside vegetable broth; bread and vegetables with lentil soup.",
      alternative: "Choose another familiar main if soup is unappealing.",
      doneWhen: "An accompaniment to a particular soup is chosen.",
      why:
          "The addition accounts for both the soup’s contents and your need for food.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-sandwich-packing",
    topic: "meal-sandwich-packing",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-chilling"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Сэндвич, который удобно взять с собой",
      "Если начинка размокает до обеда.",
      task: "Упакуйте влажные компоненты отдельно до еды.",
      steps: [
        "Выберите подходящие хлеб и начинку.",
        "Отделите помидор или соус и соблюдайте условия охлаждения начинки.",
      ],
      example:
          "Хлеб и сыр в одном контейнере, помидор отдельно; соединить перед едой.",
      alternative: "Купите или соберите сэндвич непосредственно перед обедом.",
      doneWhen: "Выбран способ сборки и безопасного хранения.",
      why: "Раздельная упаковка сохраняет удобную текстуру еды в дороге.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Pack a sandwich that travels well",
      "When fillings make bread soggy before lunch.",
      task: "Keep wet ingredients separate until eating.",
      steps: [
        "Choose suitable bread and filling.",
        "Separate tomato or sauce and follow chilled-storage instructions.",
      ],
      example:
          "Bread and cheese together, tomato separately; assemble at mealtime.",
      alternative: "Buy or assemble the sandwich just before lunch.",
      doneWhen: "An assembly and safe storage plan is chosen.",
      why: "Separate packing keeps a convenient texture when taking food out.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-guest-preferences",
    topic: "meal-guest-preferences",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fda-allergens"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Уточните еду перед встречей",
      "Если готовите для другого человека.",
      task: "Спросите об ограничениях и удобном блюде до покупки продуктов.",
      steps: [
        "Уточните аллергии и личные предпочтения напрямую.",
        "Согласуйте одно подходящее блюдо и приготовление без перекрёстного контакта аллергенов.",
      ],
      example:
          "Спросите, подходит ли паста с овощами и как безопасно заменить сыр.",
      alternative:
          "Пусть гость предложит знакомый безопасный вариант; не угадывайте по внешности.",
      doneWhen: "Согласован конкретный вариант еды и его ограничения.",
      why: "Прямой вопрос полезнее догадки о том, что человек может есть.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Ask before cooking for a guest",
      "When preparing food for someone else.",
      task: "Ask about restrictions and a comfortable dish before shopping.",
      steps: [
        "Check allergies and preferences directly.",
        "Agree one suitable dish and preparation that avoids allergen cross-contact.",
      ],
      example:
          "Ask whether vegetable pasta works and how to replace cheese safely.",
      alternative:
          "Invite the guest to suggest a familiar safe option; do not guess from appearance.",
      doneWhen: "A particular meal and its limits are agreed.",
      why:
          "A direct question is more useful than guessing what someone can eat.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-restaurant-allergy",
    topic: "meal-restaurant-allergy",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["fda-allergens"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Уточните аллерген в кафе",
      "Если состав блюда влияет на вашу безопасность.",
      task:
          "Задайте сотруднику прямой вопрос о составе и перекрёстном контакте.",
      steps: [
        "Назовите конкретный аллерген и спросите о приготовлении.",
        "Если безопасность не могут подтвердить, выберите подтверждённый вариант.",
      ],
      example:
          "Спросите про орехи не только в соусе, но и при приготовлении блюда.",
      alternative: "Выберите другое место или знакомую безопасную еду.",
      doneWhen:
          "Получен ясный ответ или выбран другой вариант без риска наугад.",
      why:
          "Название блюда само по себе не описывает все ингредиенты и приготовление.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Check an allergen at a cafe",
      "When ingredients affect your safety.",
      task: "Ask staff directly about ingredients and allergen cross-contact.",
      steps: [
        "Name the specific allergen and ask about preparation.",
        "If safety cannot be confirmed, choose a confirmed option.",
      ],
      example: "Ask about nuts in both the sauce and the preparation process.",
      alternative: "Choose another venue or familiar safe food.",
      doneWhen:
          "You have a clear answer or another option without guessing safety.",
      why:
          "A dish’s name alone does not describe every ingredient and preparation step.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-seasonal-swap",
    topic: "meal-seasonal-swap",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Замените дорогой овощ по способу готовки",
      "Если ингредиент из рецепта сейчас дорогой.",
      task: "Подберите доступную замену с похожим способом приготовления.",
      steps: [
        "Определите роль овоща: салат, тушение или суп.",
        "Сравните доступные свежие и замороженные варианты.",
      ],
      example:
          "Для тушения вместо дорогого перца — морковь и капуста с учётом времени готовки.",
      alternative: "Выберите другой рецепт из уже имеющихся продуктов.",
      doneWhen: "Есть подходящая по цене и приготовлению замена.",
      why:
          "Замена учитывает рецепт, а не требует покупать один определённый овощ.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Swap an expensive vegetable by cooking role",
      "When a recipe ingredient costs too much.",
      task: "Choose an affordable replacement that suits the cooking method.",
      steps: [
        "Identify its role: salad, stew or soup.",
        "Compare available fresh and frozen options.",
      ],
      example:
          "For a stew, use carrot and cabbage instead of costly pepper, adjusting cooking time.",
      alternative: "Choose another recipe using food already available.",
      doneWhen: "A replacement fits both price and preparation.",
      why:
          "The swap follows the recipe’s needs without requiring one particular vegetable.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-ready-heat",
    topic: "meal-ready-heat",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Разогрейте готовое блюдо равномерно",
      "Если пользуетесь микроволновкой.",
      task: "Следуйте инструкции разогрева и проверьте всё блюдо.",
      steps: [
        "Посмотрите мощность, время и необходимость перемешивания.",
        "Перемешайте или переверните, если указано, и выдержите нужную паузу.",
      ],
      example:
          "Готовое овощное рагу: перемешать по инструкции, чтобы не осталось холодных участков.",
      alternative:
          "Выберите другой указанный на упаковке способ приготовления.",
      doneWhen: "Блюдо разогрето по инструкции по всему объёму.",
      why:
          "Микроволновка может греть неравномерно; один горячий край недостаточен.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Heat a ready meal evenly",
      "When using a microwave.",
      task: "Follow the heating instructions and check the whole meal.",
      steps: [
        "Check power, time and any stirring instructions.",
        "Stir or turn as directed and allow the stated standing time.",
      ],
      example:
          "A prepared vegetable stew: stir as directed to avoid cold pockets.",
      alternative: "Use another preparation method listed on the pack.",
      doneWhen: "The meal is heated throughout according to instructions.",
      why: "Microwaves can heat unevenly; one hot edge is not enough.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-cold-transport",
    topic: "packed-lunch-storage",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["fsa-chilling"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Доставка домашнего обеда в холоде",
      "Если дорога до холодильника занимает время.",
      task: "Спланируйте охлаждение скоропортящегося обеда в пути.",
      steps: [
        "Проверьте условия хранения и доступ к холодильнику.",
        "Используйте подходящую термосумку с холодовыми элементами и уберите еду в холодильник по прибытии.",
      ],
      example:
          "Охлаждённый контейнер с пастой и фасолью в термосумке, затем в холодильник.",
      alternative:
          "Если холод обеспечить нельзя, выберите продукты без охлаждения до открытия.",
      doneWhen: "Выбран способ поддерживать нужное хранение в дороге.",
      why: "Контейнер сам по себе не обеспечивает безопасную температуру.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Keep a packed lunch chilled in transit",
      "When travel separates two fridges.",
      task: "Plan chilled storage for a perishable packed lunch.",
      steps: [
        "Check storage needs and fridge access.",
        "Use a suitable insulated bag with ice packs, then refrigerate on arrival.",
      ],
      example:
          "Chilled pasta and beans in an insulated bag, then into a fridge.",
      alternative:
          "If chilling is unavailable, choose foods shelf-stable until opened.",
      doneWhen: "A way to maintain required storage in transit is chosen.",
      why: "A container alone does not provide a safe storage temperature.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-access-help",
    topic: "meal-access-help",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Найдите доступ к еде при нехватке средств",
      "Если дело в доступности еды, а не в рецептах.",
      task: "Узнайте один реальный вариант продуктовой поддержки поблизости.",
      steps: [
        "Проверьте местную социальную службу или организацию помощи.",
        "Уточните условия получения и подходящие вам продукты.",
      ],
      example:
          "Узнать время выдачи продуктового набора и необходимость записи.",
      alternative: "Попросите близкого помочь найти актуальные контакты.",
      doneWhen:
          "Проверен один доступный вариант или подготовлен вопрос о помощи.",
      why:
          "Практическая поддержка уместнее требования лучше планировать при нехватке еды.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Find food support when money is short",
      "When food access matters more than recipes.",
      task: "Check one real local source of food support.",
      steps: [
        "Look for a local social service or food-support organisation.",
        "Ask about access requirements and foods that suit you.",
      ],
      example: "Check collection times and whether an appointment is needed.",
      alternative: "Ask someone trusted to help find current contacts.",
      doneWhen:
          "One possible source or a practical request for help is identified.",
      why:
          "Practical support is more useful than demanding better planning when food is scarce.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-share-prep",
    topic: "food-support",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Разделите подготовку ужина",
      "Если вся работа с едой лежит на одном человеке.",
      task:
          "Договоритесь об одной конкретной части готовки с другим человеком.",
      steps: [
        "Назовите отдельную задачу и время.",
        "Передайте её вместе с нужными продуктами или инструкцией.",
      ],
      example:
          "Один готовит крупу, другой моет подходящие овощи и накрывает стол.",
      alternative:
          "Если готовите один, выберите готовый компонент вместо одной задачи.",
      doneWhen: "Согласована одна конкретная задача или готовая замена.",
      why:
          "Понятная небольшая часть работы проще общей просьбы помочь с ужином.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Share one dinner-preparation task",
      "When one person carries all the food work.",
      task: "Agree one specific cooking task with another person.",
      steps: [
        "Name a separate task and a time.",
        "Provide the ingredients or instructions needed.",
      ],
      example:
          "One person cooks grain, another washes suitable vegetables and sets the table.",
      alternative: "Cooking alone? Replace one task with a prepared component.",
      doneWhen: "One specific task or prepared replacement is agreed.",
      why:
          "A defined small task is easier to share than a general request for dinner help.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-spice-separate",
    topic: "meal-spice-separate",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Одна основа с разной остротой",
      "Если дома по-разному любят специи.",
      task: "Отделите мягкую порцию до добавления острой приправы.",
      steps: [
        "Приготовьте общую основу до готовности.",
        "Добавьте подходящую приправу отдельно в нужную порцию.",
      ],
      example:
          "Фасоль с томатами: мягкая часть отдельно, чили добавить только желающим.",
      alternative: "Подайте подходящие специи отдельно за столом.",
      doneWhen: "Одна основа подходит разным вкусовым предпочтениям.",
      why:
          "Отдельная приправа даёт выбор без приготовления нескольких разных блюд.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "One base with different spice levels",
      "When household spice preferences differ.",
      task: "Set aside a mild portion before adding hot seasoning.",
      steps: [
        "Cook the shared base fully.",
        "Add suitable seasoning only to the portions that want it.",
      ],
      example:
          "Beans with tomatoes: keep a mild portion, add chilli to the rest.",
      alternative: "Serve suitable seasonings separately at the table.",
      doneWhen: "One base accommodates different spice preferences.",
      why: "Separate seasoning offers choice without several different meals.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "meal-pantry-order",
    topic: "meal-pantry-order",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Выберите ужин по доступному времени",
      "Если продукты есть, но непонятно, что успеть приготовить.",
      task: "Сравните время приготовления двух имеющихся основ.",
      steps: [
        "Прочитайте инструкции на крупе, пасте или бобовых.",
        "Выберите основу под сегодняшнее время и добавьте доступные компоненты.",
      ],
      example:
          "Быстрая паста с фасолью вместо сухой фасоли, которую ещё нужно замачивать.",
      alternative: "Выберите готовую подходящую основу, если готовить некогда.",
      doneWhen: "Выбран вариант, который помещается в реальное время.",
      why:
          "Проверка времени заранее снижает риск остаться без запланированной еды.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Choose dinner by available cooking time",
      "When food is available but preparation time is unclear.",
      task: "Compare the preparation time of two bases you already have.",
      steps: [
        "Read directions on grains, pasta or pulses.",
        "Pick a base for today’s time and add accessible components.",
      ],
      example:
          "Quick pasta with ready beans instead of dry beans needing soaking.",
      alternative:
          "Use a suitable ready-cooked base when cooking is impractical.",
      doneWhen: "The chosen option fits the time actually available.",
      why: "Checking time in advance makes the food plan more workable.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-overnight-oats",
    topic: "cook-overnight-oats",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-chilling"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Овсянка без утренней варки",
      "Если утром удобнее достать готовый завтрак.",
      task: "Замочите подходящие хлопья в холодильнике по инструкции продукта.",
      steps: [
        "Соедините хлопья с подходящим молоком или йогуртом.",
        "Закройте, охладите и добавьте фрукт перед едой, соблюдая сроки упаковок.",
      ],
      example: "Хлопья, подходящий йогурт и тёртое яблоко.",
      alternative:
          "Если хлопья требуют варки, сварите их по инструкции вместо замачивания.",
      doneWhen:
          "Подготовлен завтрак с подходящими хлопьями и безопасным хранением.",
      why:
          "Холодная подготовка переносит часть утренней работы на удобное время.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Overnight oats without morning cooking",
      "When a ready breakfast is easier in the morning.",
      task: "Soak suitable oats in the fridge as directed on the pack.",
      steps: [
        "Mix oats with suitable milk or yogurt.",
        "Cover and chill; add fruit at serving, following storage limits.",
      ],
      example: "Oats, suitable yogurt and grated apple.",
      alternative:
          "If the oats require cooking, cook them as directed instead of soaking.",
      doneWhen: "Breakfast uses suitable oats and a safe storage plan.",
      why:
          "Cold preparation moves some morning work to a more convenient time.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-savoury-porridge",
    topic: "cook-savoury-porridge",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Несладкая каша на завтрак",
      "Если сладкий завтрак не нравится.",
      task: "Приготовьте кашу с несладкими дополнениями.",
      steps: [
        "Сварите подходящую крупу по упаковке.",
        "Добавьте готовую фасоль или полностью приготовленное яйцо и овощи.",
      ],
      example: "Гречка с фасолью и помидором.",
      alternative: "Используйте рис или овсянку, если гречки нет.",
      doneWhen: "Выбрана или приготовлена одна несладкая комбинация.",
      why:
          "Каша остаётся удобной основой и для тех, кто не любит сладкий вкус.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Savoury breakfast porridge",
      "When a sweet breakfast does not appeal.",
      task: "Make a grain bowl with savoury additions.",
      steps: [
        "Cook a suitable grain as directed.",
        "Add ready-cooked beans or a fully cooked egg and vegetables.",
      ],
      example: "Buckwheat with beans and tomato.",
      alternative: "Use rice or oats if buckwheat is unavailable.",
      doneWhen: "One savoury combination is chosen or prepared.",
      why: "A grain bowl remains useful when sweet flavours are unappealing.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-egg-vegetable-pan",
    topic: "egg-vegetable-cooking",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Овощная яичница на сковороде",
      "Если есть яйца и немного овощей.",
      task: "Приготовьте овощи с яйцом до полной готовности.",
      steps: [
        "Нарежьте подходящие овощи и прогрейте до мягкости.",
        "Добавьте яйцо, доведите до готовности и подайте с хлебом.",
      ],
      example: "Помидор и кабачок с яйцом; рядом хлеб.",
      alternative:
          "Вместо яйца приготовьте с овощами подходящий тофу по упаковке.",
      doneWhen:
          "Есть горячее сочетание с полностью приготовленным яйцом или заменой.",
      why: "Одна сковорода объединяет доступные овощи и белковый компонент.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Vegetable egg skillet",
      "When eggs and a few vegetables are available.",
      task: "Cook vegetables with egg until fully done.",
      steps: [
        "Chop suitable vegetables and cook until tender.",
        "Add egg, cook fully and serve with bread.",
      ],
      example: "Tomato and courgette with egg, plus bread.",
      alternative:
          "Cook suitable tofu with the vegetables as directed instead.",
      doneWhen:
          "A hot combination with fully cooked egg or an alternative is ready.",
      why: "One pan combines accessible vegetables and a protein food.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-jacket-potato",
    topic: "cook-jacket-potato",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Картофель с готовой начинкой",
      "Когда нужна сытная основа без сложного рецепта.",
      task: "Приготовьте картофель и добавьте готовую начинку.",
      steps: [
        "Вымойте картофель и приготовьте безопасным способом по инструкции техники.",
        "Разрежьте и добавьте горячую фасоль с томатами; подайте овощи.",
      ],
      example: "Запечённый картофель с фасолью и капустным салатом.",
      alternative:
          "Подойдёт отварной картофель с подходящим творогом или тофу.",
      doneWhen:
          "Выбрана начинка и полностью приготовленная картофельная основа.",
      why: "Готовая начинка сокращает отдельные этапы приготовления.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Potato with a ready filling",
      "For a substantial base without a complicated recipe.",
      task: "Cook a potato and add a prepared filling.",
      steps: [
        "Wash and cook the potato safely using your appliance instructions.",
        "Split and add hot beans with tomatoes; serve vegetables alongside.",
      ],
      example: "Baked potato with beans and cabbage salad.",
      alternative: "Use boiled potato with suitable cottage cheese or tofu.",
      doneWhen: "A filling and fully cooked potato base are chosen.",
      why: "A ready filling reduces separate preparation steps.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-lentil-bolognese",
    topic: "pulse-introduction",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Томатный соус с чечевицей",
      "Если хочется недорогую начинку к пасте.",
      task: "Сделайте густой томатный соус с чечевицей.",
      steps: [
        "Приготовьте чечевицу по упаковке.",
        "Соедините с томатами и морковью, доведите до готовности и подайте с пастой.",
      ],
      example: "Красная чечевица, протёртые томаты и тёртая морковь.",
      alternative: "Готовая фасоль сократит время приготовления соуса.",
      doneWhen: "Есть густой соус, а не только добавка сырой чечевицы.",
      why:
          "Бобовые становятся основной частью соуса с доступными ингредиентами.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Lentil tomato pasta sauce",
      "For an affordable pasta topping.",
      task: "Make a thick tomato sauce with lentils.",
      steps: [
        "Cook lentils as directed on the pack.",
        "Combine with tomatoes and carrot, cook fully and serve with pasta.",
      ],
      example: "Red lentils, passata and grated carrot.",
      alternative: "Ready-cooked beans shorten the sauce preparation.",
      doneWhen:
          "A thick sauce is prepared rather than adding uncooked lentils.",
      why:
          "Pulses become the main sauce component using accessible ingredients.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-chickpea-mash",
    topic: "cook-chickpea-mash",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Намазка из готового нута",
      "Если хочется начинку для хлеба без плиты.",
      task: "Разомните готовый нут с подходящей заправкой.",
      steps: [
        "Подготовьте нут по упаковке и разомните вилкой.",
        "Добавьте немного подходящего масла или йогурта и подайте с хлебом и овощами.",
      ],
      example: "Нут, масло и зелень; рядом хлеб и огурец.",
      alternative:
          "Готовая белая фасоль тоже разминается вилкой; кунжут не обязателен.",
      doneWhen: "Приготовлена переносимая по составу намазка.",
      why: "Разминание превращает готовые бобовые в другую удобную текстуру.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Mash ready-cooked chickpeas into a spread",
      "For a bread filling without a hob.",
      task: "Mash ready-cooked chickpeas with a suitable dressing.",
      steps: [
        "Prepare chickpeas as directed and mash with a fork.",
        "Add suitable oil or yogurt and serve with bread and vegetables.",
      ],
      example: "Chickpeas, oil and herbs; bread and cucumber alongside.",
      alternative:
          "Ready-cooked white beans also mash easily; sesame is optional.",
      doneWhen: "A spread with suitable ingredients is prepared.",
      why: "Mashing turns ready pulses into a convenient different texture.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-tofu-crumble",
    topic: "cook-tofu-crumble",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Тофу с овощами в крошке",
      "Если хочется попробовать тофу без сложного маринада.",
      task: "Раскрошите тофу и приготовьте с подходящими овощами.",
      steps: [
        "Проверьте состав и инструкцию тофу.",
        "Раскрошите, приготовьте по упаковке с овощами и подайте с рисом или хлебом.",
      ],
      example: "Тофу с морковью и помидором на сковороде.",
      alternative:
          "Если соя не подходит, выберите полностью приготовленное яйцо.",
      doneWhen: "Выбран или приготовлен вариант с проверенным составом.",
      why:
          "Раскрошенный тофу легко распределить по блюду без отдельного маринования.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Tofu and vegetable scramble",
      "To try tofu without a complicated marinade.",
      task: "Crumble tofu and cook it with suitable vegetables.",
      steps: [
        "Check tofu ingredients and preparation directions.",
        "Crumble and cook as directed with vegetables; serve with rice or bread.",
      ],
      example: "Tofu, carrot and tomato in a pan.",
      alternative: "Use a fully cooked egg if soy is unsuitable.",
      doneWhen: "An option with checked ingredients is chosen or prepared.",
      why:
          "Crumbled tofu distributes through a dish without a separate marinade.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-fish-parcel",
    topic: "cook-fish-parcel",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Рыба с овощами в форме",
      "Если есть духовка и подходящая рыба.",
      task: "Запеките рыбу с овощами по инструкции продукта.",
      steps: [
        "Проверьте разморозку и время приготовления рыбы.",
        "Положите в подходящую форму с овощами и доведите всё до готовности; добавьте гарнир.",
      ],
      example: "Рыба с кабачком в форме, рядом картофель.",
      alternative:
          "Возьмите подходящий тофу с овощами, соблюдая его инструкцию.",
      doneWhen: "Все компоненты приготовлены, выбран гарнир.",
      why: "Приготовление в одной форме сокращает количество отдельной посуды.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Fish and vegetables in a baking dish",
      "When an oven and suitable fish are available.",
      task: "Bake fish with vegetables following the product instructions.",
      steps: [
        "Check defrosting and cooking directions.",
        "Use an oven-safe dish with vegetables and cook fully; add a side.",
      ],
      example: "Fish and courgette in a dish, with potato alongside.",
      alternative:
          "Use suitable tofu and vegetables following its own instructions.",
      doneWhen: "All components are cooked and a side is chosen.",
      why: "One baking dish reduces separate cookware.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-tray-chicken",
    topic: "cook-tray-chicken",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Курица и овощи на противне",
      "Если удобно готовить в духовке.",
      task: "Приготовьте курицу с овощами, разделяя сырое и готовое.",
      steps: [
        "Подготовьте овощи отдельно от сырой курицы и вымойте инвентарь.",
        "Запеките по безопасной инструкции до полной готовности; подайте с подходящим гарниром.",
      ],
      example: "Курица, морковь и картофель на противне.",
      alternative:
          "Вместо сырой курицы используйте подходящую растительную замену по её инструкции.",
      doneWhen:
          "Блюдо полностью приготовлено без контакта готовой еды с сырой курицей.",
      why:
          "Один противень упрощает готовку, но не отменяет гигиену сырого мяса.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Chicken and vegetables on a tray",
      "When oven cooking is convenient.",
      task:
          "Cook chicken with vegetables while separating raw and ready-to-eat food.",
      steps: [
        "Prepare vegetables separately from raw chicken and clean utensils.",
        "Bake following safe instructions until fully cooked; serve with a suitable side.",
      ],
      example: "Chicken, carrot and potato on a tray.",
      alternative:
          "Use a suitable plant alternative following its own instructions.",
      doneWhen:
          "The meal is fully cooked without raw chicken contacting ready-to-eat food.",
      why: "One tray simplifies cooking while raw-meat hygiene still matters.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-cabbage-noodles",
    topic: "cook-cabbage-noodles",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Лапша с капустой и фасолью",
      "Если нужен бюджетный горячий обед.",
      task:
          "Соедините приготовленную лапшу с тушёной капустой и готовой фасолью.",
      steps: [
        "Приготовьте лапшу по упаковке, капусту потушите до удобной мягкости.",
        "Добавьте готовую фасоль и подходящую заправку, прогрейте.",
      ],
      example: "Лапша, белокочанная капуста, морковь и фасоль.",
      alternative:
          "Вместо лапши подойдёт картофель; соус выбирайте по ограничениям.",
      doneWhen: "Приготовлено одно сочетание с капустой, основой и бобовыми.",
      why: "Недорогая капуста используется как основная часть горячего блюда.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Noodles with cabbage and beans",
      "For an affordable hot lunch.",
      task: "Combine cooked noodles with stewed cabbage and ready beans.",
      steps: [
        "Cook noodles as directed and soften cabbage to your preference.",
        "Add ready beans and suitable seasoning; heat through.",
      ],
      example: "Noodles, white cabbage, carrot and beans.",
      alternative:
          "Use potato instead of noodles; choose sauces for your restrictions.",
      doneWhen: "One combination of cabbage, a base and pulses is prepared.",
      why: "Affordable cabbage becomes a main part of a hot meal.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-couscous-kettle",
    topic: "cook-couscous-kettle",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Кускус по инструкции без плиты",
      "Если есть только чайник и подходящая крупа.",
      task:
          "Приготовьте кускус, допускающий запаривание, и добавьте готовые компоненты.",
      steps: [
        "Убедитесь по упаковке, что крупу можно запарить в жаростойкой посуде.",
        "Приготовьте указанным способом и добавьте готовый нут и овощи.",
      ],
      example: "Кускус с нутом, помидором и подходящим маслом.",
      alternative:
          "Если крупа требует варки, выберите хлеб с готовой начинкой.",
      doneWhen:
          "Выбран продукт и способ приготовления, подходящие для оборудования.",
      why:
          "Проверенная инструкция позволяет использовать чайник без догадок о готовности.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Couscous prepared with a kettle",
      "When only a kettle and a suitable grain are available.",
      task: "Prepare couscous labelled for soaking and add ready ingredients.",
      steps: [
        "Confirm the pack allows soaking in a heatproof bowl.",
        "Follow directions, then add ready chickpeas and vegetables.",
      ],
      example: "Couscous with chickpeas, tomato and suitable oil.",
      alternative:
          "If the grain requires boiling, use bread with a ready filling.",
      doneWhen: "The product and preparation suit the equipment available.",
      why:
          "Checking directions makes kettle preparation workable without guessing doneness.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-stuffed-wrap",
    topic: "cook-stuffed-wrap",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Рулет с начинкой без сложной сборки",
      "Для еды, которую удобно держать в руках.",
      task: "Сверните лепёшку с готовой начинкой и нарезанными овощами.",
      steps: [
        "Выберите подходящую лепёшку и готовый белковый продукт.",
        "Разложите начинку полосой, добавьте овощи и сверните края.",
      ],
      example: "Лепёшка с готовой фасолью, огурцом и йогуртовым соусом.",
      alternative:
          "Та же начинка в тарелке с хлебом, если сворачивать неудобно.",
      doneWhen: "Есть рулет или удобная тарелочная версия.",
      why:
          "Одинаковые компоненты можно подать в форме, удобной для ваших возможностей.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Fold a filled wrap",
      "For food that is convenient to hold.",
      task: "Fold a flatbread around ready filling and cut vegetables.",
      steps: [
        "Choose a suitable flatbread and ready protein food.",
        "Arrange filling in a strip, add vegetables and fold the edges.",
      ],
      example: "Flatbread with ready beans, cucumber and yogurt sauce.",
      alternative:
          "Serve the same filling in a bowl with bread if folding is difficult.",
      doneWhen: "A wrap or convenient bowl version is ready.",
      why: "The same components can take a form that suits your abilities.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-split-pea-soup",
    topic: "cook-split-pea-soup",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Гороховый суп с запасом времени",
      "Если есть время на длительную варку.",
      task: "Приготовьте суп из сухого колотого гороха по упаковке.",
      steps: [
        "Проверьте необходимость замачивания и длительность варки.",
        "Варите до готовности с подходящими овощами; подайте с хлебом.",
      ],
      example: "Колотый горох, морковь и лук без обязательных копчёностей.",
      alternative:
          "При нехватке времени выберите готовую фасоль для другого супа.",
      doneWhen: "Учтено время и горох полностью приготовлен.",
      why:
          "Сухой горох даёт бюджетную основу, если заранее учесть время готовки.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Split-pea soup with enough cooking time",
      "When a longer simmer fits your day.",
      task: "Make soup using dried split peas as directed.",
      steps: [
        "Check soaking needs and cooking time.",
        "Cook fully with suitable vegetables; serve with bread.",
      ],
      example: "Split peas, carrot and onion without requiring smoked meat.",
      alternative: "Use ready beans in another soup when time is short.",
      doneWhen: "Cooking time is allowed and peas are fully cooked.",
      why:
          "Dried peas offer an affordable base when preparation time is planned.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-frittata-leftovers",
    topic: "cook-frittata-leftovers",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking", "fsa-chilling"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Запеканка из безопасно сохранённых овощей",
      "Если остались готовые овощи с известным хранением.",
      task:
          "Используйте подходящие остатки овощей в полностью приготовленной яичной запеканке.",
      steps: [
        "Проверьте сроки и охлаждение остатков; сомнительное не используйте.",
        "Соедините с яйцом и запеките до полной готовности.",
      ],
      example: "Сохранённые по правилам брокколи и картофель с яйцом.",
      alternative:
          "Используйте свежеприготовленные овощи, если хранение неизвестно.",
      doneWhen: "Выбраны безопасные овощи и полностью приготовлена запеканка.",
      why:
          "Остатки получают новое применение без предположения, что любая вчерашняя еда безопасна.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Bake safely stored vegetables into a frittata",
      "When cooked vegetables remain with known storage.",
      task: "Use suitable vegetable leftovers in a fully cooked egg bake.",
      steps: [
        "Check storage time and chilling; do not use doubtful leftovers.",
        "Combine with egg and bake until fully cooked.",
      ],
      example: "Properly stored broccoli and potato with egg.",
      alternative: "Use freshly cooked vegetables if storage is unknown.",
      doneWhen: "Suitable vegetables are chosen and the bake is fully cooked.",
      why:
          "Leftovers get another use without assuming all yesterday’s food is safe.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "kitchen-separate-board",
    topic: "raw-ready-separation",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Отделите сырые продукты от готовых",
      "Если готовите сырое мясо, рыбу и еду без последующей готовки.",
      task: "Выделите отдельные чистые доску и приборы для готовой еды.",
      steps: [
        "Сначала подготовьте продукты, которые не будут готовиться, чистым инвентарём.",
        "После сырых продуктов вымойте руки, поверхности и инвентарь перед готовой едой.",
      ],
      example: "Салат нарезать чистым ножом отдельно от сырой курицы.",
      alternative:
          "Используйте другой чистый комплект или выберите блюдо без работы с сырым мясом.",
      doneWhen: "Готовая еда отделена от сырья и использован чистый инвентарь.",
      why:
          "Разделение уменьшает перенос загрязнения между разными этапами готовки.",
      explanation:
          "Учитывайте инструкции, свои ограничения и безопасные условия. Это бытовой пример без расчёта личной нормы.",
    ),
    en: TipCopy(
      "Separate raw and ready-to-eat foods",
      "When preparing raw meat or fish alongside food eaten without cooking.",
      task: "Use separate clean boards and utensils for ready-to-eat food.",
      steps: [
        "Prepare food eaten without cooking first with clean equipment.",
        "After raw food, wash hands, surfaces and utensils before handling ready-to-eat food.",
      ],
      example: "Cut salad with a clean knife separately from raw chicken.",
      alternative:
          "Use another clean set or choose a meal without handling raw meat.",
      doneWhen:
          "Ready-to-eat food is separate from raw ingredients with clean equipment.",
      why:
          "Separation reduces contamination between different preparation stages.",
      explanation:
          "Follow instructions, your restrictions and safe conditions. This is an everyday example without a prescribed personal target.",
    ),
  ),

  DailyTip(
    id: "cook-buckwheat-mushroom",
    topic: "cook-buckwheat-mushroom",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Гречка с грибами и фасолью",
      "Если хочется горячую крупу с выраженным вкусом.",
      task: "Приготовьте гречку с покупными грибами и готовой фасолью.",
      steps: [
        "Сварите гречку по упаковке и отдельно приготовьте грибы до готовности.",
        "Соедините с готовой фасолью и подходящей заправкой.",
      ],
      example: "Гречка, шампиньоны и белая фасоль.",
      alternative:
          "Если грибы не подходят, используйте тушёную морковь; лесные грибы для этого плана не нужны.",
      doneWhen: "Крупа и грибы готовы, добавлен бобовый компонент.",
      why:
          "Грибы дают вкус, а бобовые дополняют крупу; грибы не объявляются заменой белкового продукта.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Buckwheat with mushrooms and beans",
      "For a hot grain dish with a savoury flavour.",
      task: "Cook buckwheat with shop-bought mushrooms and ready beans.",
      steps: [
        "Cook buckwheat as directed and cook mushrooms fully separately.",
        "Combine with ready beans and suitable seasoning.",
      ],
      example: "Buckwheat, button mushrooms and white beans.",
      alternative:
          "Use stewed carrot if mushrooms are unsuitable; wild mushrooms are unnecessary.",
      doneWhen: "Grain and mushrooms are cooked and pulses added.",
      why:
          "Mushrooms provide flavour while beans complement the grain; mushrooms are not treated as a protein replacement.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "kitchen-fridge-thaw",
    topic: "dinner-preparation",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["fsa-chilling"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Разморозка с защитой соседних продуктов",
      "Если планируете готовить замороженный продукт.",
      task:
          "Проверьте инструкцию и организуйте безопасную разморозку в холодильнике.",
      steps: [
        "Если нужна разморозка, положите продукт в подходящую ёмкость для сбора жидкости.",
        "Дайте нужное время и используйте по инструкции; не оставляйте на столе ради ускорения.",
      ],
      example:
          "Рыба в закрытой подходящей ёмкости отдельно от готового салата.",
      alternative:
          "Продукт, допускающий готовку из заморозки, готовьте по его инструкции.",
      doneWhen: "Выбран безопасный способ с учётом времени и жидкости.",
      why: "Ёмкость и место защищают другие продукты во время разморозки.",
      explanation:
          "Учитывайте инструкции, свои ограничения и безопасные условия. Это бытовой пример без расчёта личной нормы.",
    ),
    en: TipCopy(
      "Defrost while protecting nearby food",
      "When planning to cook a frozen product.",
      task: "Check directions and arrange safe fridge defrosting.",
      steps: [
        "If defrosting is needed, use a suitable container to catch drips.",
        "Allow enough time and use as directed; do not speed it up on the counter.",
      ],
      example:
          "Fish in a suitable covered container separate from ready salad.",
      alternative:
          "Cook from frozen only when the product instructions allow it.",
      doneWhen: "A safe method accounts for time and drips.",
      why: "The container and location protect other food while defrosting.",
      explanation:
          "Follow instructions, your restrictions and safe conditions. This is an everyday example without a prescribed personal target.",
    ),
  ),

  DailyTip(
    id: "cook-frozen-fruit-bowl",
    topic: "cook-frozen-fruit-bowl",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Завтрак с замороженными ягодами",
      "Если свежие фрукты сейчас дороги.",
      task:
          "Подготовьте замороженные ягоды строго по упаковке для готового завтрака.",
      steps: [
        "Проверьте, нужны ли ягодам термообработка или разморозка.",
        "Подготовьте указанным способом и добавьте к каше с подходящим йогуртом.",
      ],
      example: "Каша с приготовленными по упаковке ягодами и йогуртом.",
      alternative: "Подойдёт нарезанное яблоко без покупки ягод.",
      doneWhen:
          "Ягоды использованы после нужной подготовки или выбрана замена.",
      why:
          "Замороженный продукт удобен, но не всегда предназначен для еды прямо из пакета.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Breakfast with frozen berries",
      "When fresh fruit is expensive.",
      task: "Prepare frozen berries exactly as labelled for a ready breakfast.",
      steps: [
        "Check whether heating or defrosting is required.",
        "Prepare as directed, then add to porridge with suitable yogurt.",
      ],
      example: "Porridge with label-prepared berries and yogurt.",
      alternative: "Use a chopped apple instead of buying berries.",
      doneWhen: "Berries are prepared as required or an alternative is chosen.",
      why:
          "Frozen fruit is convenient but is not always intended to be eaten straight from the pack.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-microwave-vegetable",
    topic: "cook-microwave-vegetable",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Овощи в микроволновке",
      "Если не хочется разогревать духовку.",
      task:
          "Приготовьте овощи в подходящей посуде по инструкции техники или упаковки.",
      steps: [
        "Проверьте безопасность посуды и требования к крышке.",
        "Приготовьте, перемешайте при необходимости и осторожно откройте от себя.",
      ],
      example: "Овощная смесь к готовой крупе и фасоли.",
      alternative:
          "Отварите овощи обычным способом, если нет подходящей посуды.",
      doneWhen: "Выбран безопасный способ и овощи доведены до готовности.",
      why:
          "Микроволновка даёт ещё один способ готовки с меньшим количеством посуды.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Microwave vegetables safely",
      "When heating an oven is inconvenient.",
      task:
          "Cook vegetables in suitable cookware following appliance or pack directions.",
      steps: [
        "Check cookware safety and lid instructions.",
        "Cook, stir if needed and open carefully away from you.",
      ],
      example: "Vegetable mix alongside ready grain and beans.",
      alternative:
          "Boil vegetables normally if suitable cookware is unavailable.",
      doneWhen: "A safe method is chosen and vegetables are cooked.",
      why: "A microwave offers another preparation method with less cookware.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-roast-vegetable-sauce",
    topic: "cook-roast-vegetable-sauce",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Соус из приготовленных овощей",
      "Если хочется другой текстуры к пасте.",
      task: "Превратите приготовленные овощи в соус с бобовыми.",
      steps: [
        "Приготовьте подходящие овощи до мягкости.",
        "Разомните с готовой белой фасолью и добавьте жидкость до удобной густоты.",
      ],
      example: "Морковь и белая фасоль в соусе к пасте.",
      alternative:
          "Разомните вилкой вместо блендера или оставьте овощи кусочками.",
      doneWhen: "Получен соус удобной густоты.",
      why:
          "Изменение формы помогает использовать овощи без покупки готового соуса.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Turn cooked vegetables into a sauce",
      "For a different pasta texture.",
      task: "Make a sauce from cooked vegetables and pulses.",
      steps: [
        "Cook suitable vegetables until soft.",
        "Mash with ready white beans and add liquid to a useful consistency.",
      ],
      example: "Carrot and white bean sauce for pasta.",
      alternative:
          "Use a fork instead of a blender, or keep the vegetables in pieces.",
      doneWhen: "A sauce with a comfortable consistency is made.",
      why: "Changing the form uses vegetables without buying a prepared sauce.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-potato-bean-cakes",
    topic: "cook-potato-bean-cakes",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Картофельно-фасолевые лепёшки",
      "Если хочется формованное горячее блюдо без мяса.",
      task:
          "Сформируйте лепёшки из приготовленного картофеля и готовой фасоли.",
      steps: [
        "Разомните полностью приготовленные компоненты и добавьте подходящую приправу.",
        "Сформируйте небольшие лепёшки и приготовьте до горячей середины; подайте овощи.",
      ],
      example: "Картофель, фасоль и зелень; рядом капустный салат.",
      alternative: "Если масса не держит форму, подайте её как горячее пюре.",
      doneWhen: "Приготовлены лепёшки или удобное горячее пюре.",
      why: "Два недорогих продукта дают другую форму знакомого сочетания.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Potato and bean patties",
      "For a shaped hot dish without meat.",
      task: "Shape cooked potato and ready beans into patties.",
      steps: [
        "Mash fully cooked components with suitable seasoning.",
        "Form small patties and cook until hot throughout; serve vegetables.",
      ],
      example: "Potato, beans and herbs with cabbage salad.",
      alternative: "Serve as hot mash if the mixture will not hold its shape.",
      doneWhen: "Patties or convenient hot mash are prepared.",
      why:
          "Two affordable foods give a different form to a familiar combination.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-shakshuka",
    topic: "egg-vegetable-cooking",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating", "fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Яйца в томатном соусе",
      "Если нужен горячий ужин с хлебом.",
      task:
          "Приготовьте яйца в прогретом томатно-овощном соусе до полной готовности.",
      steps: [
        "Потушите томаты с подходящими овощами.",
        "Добавьте яйца и готовьте до полной готовности, подайте с хлебом.",
      ],
      example: "Томаты, перец и яйца; хлеб для соуса.",
      alternative: "Готовая фасоль в том же соусе вместо яйца.",
      doneWhen: "Соус и белковый компонент полностью приготовлены.",
      why:
          "Соус одновременно готовит начинку и становится дополнением к хлебу.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Eggs in tomato sauce",
      "For a hot dinner with bread.",
      task: "Cook eggs fully in a hot tomato and vegetable sauce.",
      steps: [
        "Simmer tomatoes with suitable vegetables.",
        "Add eggs, cook fully and serve with bread.",
      ],
      example: "Tomatoes, pepper and eggs, with bread for the sauce.",
      alternative: "Use ready beans in the same sauce instead of eggs.",
      doneWhen: "The sauce and protein component are fully cooked.",
      why: "The sauce cooks the filling and accompanies the bread.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "cook-yogurt-dip",
    topic: "cook-yogurt-dip",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Соус из подходящего йогурта",
      "Если хочется отдельную заправку к нескольким компонентам.",
      task: "Смешайте подходящий йогурт с зеленью для соуса.",
      steps: [
        "Проверьте состав, срок и условия хранения йогурта.",
        "Добавьте знакомую зелень и подайте отдельно к основному блюду.",
      ],
      example: "Йогурт с укропом к картофелю, фасоли и огурцу.",
      alternative:
          "Используйте подходящую растительную основу; молочный соус не обязателен.",
      doneWhen: "Приготовлен соус с подходящим составом.",
      why:
          "Отдельный соус меняет вкус знакомого блюда без замены всех компонентов.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Make a suitable yogurt dip",
      "For a separate dressing with several meal components.",
      task: "Mix suitable yogurt with herbs for a dip.",
      steps: [
        "Check ingredients, date and storage instructions.",
        "Add familiar herbs and serve separately with the main meal.",
      ],
      example: "Yogurt and dill with potato, beans and cucumber.",
      alternative: "Use a suitable plant-based base; dairy is optional.",
      doneWhen: "A dip with suitable ingredients is prepared.",
      why:
          "A separate dip changes a familiar meal’s flavour without replacing every component.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "food-fortified-plant",
    topic: "dairy-alternative-choice",
    category: TipCategory.macros,
    version: 5,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Растительный напиток для замены молока",
      "Если вы выбираете растительную замену.",
      task: "Проверьте белок и обогащение на упаковке выбранного напитка.",
      steps: [
        "Сравните состав на одинаковый объём.",
        "Учитывайте подходящие вам белок, кальций и ограничения, а не только название.",
      ],
      example:
          "Два овсяных напитка могут отличаться по обогащению; соевый — по белку.",
      alternative:
          "Если замена нужна по лечебным причинам, уточните подходящий продукт со специалистом.",
      doneWhen: "Выбран продукт с прочитанным составом.",
      why:
          "Растительные напитки не становятся равноценными молоку только из-за похожей упаковки.",
      explanation:
          "Сравнение продуктов не назначает личную норму. Учитывайте аллергию, переносимость и назначенную диету.",
    ),
    en: TipCopy(
      "A plant drink as a milk replacement",
      "When choosing a plant-based alternative.",
      task: "Check protein and fortification on the chosen drink’s label.",
      steps: [
        "Compare ingredients on the same volume basis.",
        "Consider suitable protein, calcium and restrictions rather than the name alone.",
      ],
      example:
          "Two oat drinks may differ in fortification; soy may differ in protein.",
      alternative:
          "Check a suitable product with a professional for a clinical substitution.",
      doneWhen: "A product is chosen after reading its composition.",
      why:
          "Similar packaging does not make plant drinks nutritionally identical to milk.",
      explanation:
          "Food comparisons do not prescribe a personal target. Respect allergies, tolerance and prescribed diets.",
    ),
  ),

  DailyTip(
    id: "food-nut-alternative",
    topic: "food-nut-alternative",
    category: TipCategory.macros,
    version: 5,
    sourceIds: ["who-diet", "fda-allergens"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Замена ореховой пасты по ограничениям",
      "Если орехи вам не подходят.",
      task: "Подберите безопасную намазку вместо ореховой пасты.",
      steps: [
        "Прочитайте состав и предупреждения о перекрёстном контакте.",
        "Выберите знакомый переносимый продукт для хлеба или каши.",
      ],
      example: "Подходящая бобовая намазка вместо ореховой пасты на хлебе.",
      alternative:
          "При сложной аллергии используйте уже согласованный безопасный продукт, не пробуйте наугад.",
      doneWhen: "Найдена подтверждённо подходящая замена.",
      why:
          "Замена сохраняет удобный способ еды без требования употреблять орехи.",
      explanation:
          "Сравнение продуктов не назначает личную норму. Учитывайте аллергию, переносимость и назначенную диету.",
    ),
    en: TipCopy(
      "Replace nut butter for your restrictions",
      "When nuts do not suit you.",
      task: "Find a safe spread instead of nut butter.",
      steps: [
        "Read ingredients and cross-contact warnings.",
        "Choose a familiar tolerated product for bread or porridge.",
      ],
      example: "A suitable bean spread instead of nut butter on bread.",
      alternative:
          "With complex allergy, use an already agreed safe food rather than experimenting.",
      doneWhen: "A confirmed suitable replacement is found.",
      why:
          "A replacement preserves a convenient food format without requiring nuts.",
      explanation:
          "Food comparisons do not prescribe a personal target. Respect allergies, tolerance and prescribed diets.",
    ),
  ),

  DailyTip(
    id: "food-grain-transition",
    topic: "food-grain-transition",
    category: TipCategory.macros,
    version: 5,
    sourceIds: ["nhs-fibre"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Проба цельнозерновой крупы без полной замены",
      "Если хочется попробовать другую крупу.",
      task:
          "Смешайте небольшое количество подходящей цельнозерновой крупы с привычной.",
      steps: [
        "Приготовьте крупы отдельно по их инструкциям.",
        "Соедините в удобном соотношении и оцените вкус и переносимость.",
      ],
      example: "Часть готового бурого риса с привычным белым рисом.",
      alternative:
          "При лечебном ограничении клетчатки следуйте своему плану, не меняйте крупу самостоятельно.",
      doneWhen: "Попробовано удобное сочетание или сохранён лечебный вариант.",
      why:
          "Смешивание позволяет оценить новый вкус постепенно, без обязательной полной замены.",
      explanation:
          "Сравнение продуктов не назначает личную норму. Учитывайте аллергию, переносимость и назначенную диету.",
    ),
    en: TipCopy(
      "Try a whole grain without a full switch",
      "When trying a different grain.",
      task: "Mix a little suitable whole grain with a familiar grain.",
      steps: [
        "Cook each grain separately as directed.",
        "Combine in a comfortable ratio and assess taste and tolerance.",
      ],
      example: "Some cooked brown rice mixed with familiar white rice.",
      alternative:
          "Follow prescribed fibre restrictions rather than changing grain independently.",
      doneWhen: "A manageable mixture is tried or a clinical option retained.",
      why:
          "Mixing allows a gradual taste trial without requiring a complete switch.",
      explanation:
          "Food comparisons do not prescribe a personal target. Respect allergies, tolerance and prescribed diets.",
    ),
  ),

  DailyTip(
    id: "food-pulse-rinse",
    topic: "food-pulse-rinse",
    category: TipCategory.macros,
    version: 5,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Подготовьте консервированные бобовые",
      "Если хотите использовать готовую фасоль или нут.",
      task: "Проверьте, как подготовить одну банку бобовых к еде.",
      steps: [
        "Прочитайте состав и способ употребления.",
        "Слейте или промойте, если это подходит продукту и инструкции, затем добавьте в блюдо.",
      ],
      example: "Фасоль без соуса после подготовки в салат с хлебом.",
      alternative:
          "Бобовые в готовом соусе используйте по их инструкции, промывка не обязательна.",
      doneWhen: "Бобовые подготовлены подходящим способом.",
      why:
          "Разные консервы требуют разной подготовки; не нужно автоматически промывать любой продукт.",
      explanation:
          "Сравнение продуктов не назначает личную норму. Учитывайте аллергию, переносимость и назначенную диету.",
    ),
    en: TipCopy(
      "Prepare a tin of pulses",
      "When using ready beans or chickpeas.",
      task: "Check how to prepare one tin for eating.",
      steps: [
        "Read ingredients and serving directions.",
        "Drain or rinse when suitable and directed, then add to a meal.",
      ],
      example: "Prepared plain beans in a salad with bread.",
      alternative:
          "Use beans in sauce as directed; rinsing is optional rather than universal.",
      doneWhen: "The pulses are prepared appropriately.",
      why:
          "Different tins need different preparation; not every product should automatically be rinsed.",
      explanation:
          "Food comparisons do not prescribe a personal target. Respect allergies, tolerance and prescribed diets.",
    ),
  ),

  DailyTip(
    id: "food-fibre-tolerance",
    topic: "food-fibre-tolerance",
    category: TipCategory.macros,
    version: 5,
    sourceIds: ["nhs-fibre"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Удобный темп изменения клетчатки",
      "Если новая богатая клетчаткой еда вызывает дискомфорт.",
      task:
          "Вернитесь к переносимому количеству и меняйте один продукт за раз.",
      steps: [
        "Отметьте, какой продукт и какое изменение предшествовали дискомфорту.",
        "Выберите знакомую переносимую еду; при стойких симптомах обсудите их со специалистом.",
      ],
      example:
          "Вместо большой новой порции бобовых — привычное блюдо с небольшим переносимым дополнением.",
      alternative:
          "При назначенной диете не экспериментируйте, уточните её со специалистом.",
      doneWhen: "Выбран переносимый вариант без обязанности терпеть симптомы.",
      why:
          "Постепенность помогает оценить переносимость, но не устанавливает причину симптомов.",
      explanation:
          "Сравнение продуктов не назначает личную норму. Учитывайте аллергию, переносимость и назначенную диету.",
    ),
    en: TipCopy(
      "A comfortable pace for fibre changes",
      "If a new high-fibre food feels uncomfortable.",
      task: "Return to a tolerated amount and change one food at a time.",
      steps: [
        "Notice which food and change preceded discomfort.",
        "Use familiar tolerated food; discuss persistent symptoms with a professional.",
      ],
      example:
          "Instead of a large new serving of pulses, use a familiar meal with a small tolerated addition.",
      alternative:
          "With a prescribed diet, seek individual advice rather than experimenting.",
      doneWhen:
          "A tolerated option is chosen without requiring you to endure symptoms.",
      why:
          "Gradual change helps assess tolerance but does not establish the cause of symptoms.",
      explanation:
          "Food comparisons do not prescribe a personal target. Respect allergies, tolerance and prescribed diets.",
    ),
  ),

  DailyTip(
    id: "food-protein-pack-cost",
    topic: "food-protein-pack-cost",
    category: TipCategory.macros,
    version: 5,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Сравните стоимость белкового компонента",
      "Если привычный продукт стал дорогим.",
      task: "Сравните стоимость двух подходящих вариантов для одного блюда.",
      steps: [
        "Посмотрите цену и реально используемый объём.",
        "Выберите вариант, учитывая готовку, хранение и ограничения.",
      ],
      example:
          "Для обеда сравнить готовую фасоль и яйца, а не искать дорогой специальный продукт.",
      alternative:
          "Оставьте знакомый вариант, если замена требует недоступного оборудования.",
      doneWhen: "Выбран доступный компонент с учётом полной подготовки.",
      why:
          "Цена упаковки и удобство готовки вместе помогают выбрать реальную замену.",
      explanation:
          "Сравнение продуктов не назначает личную норму. Учитывайте аллергию, переносимость и назначенную диету.",
    ),
    en: TipCopy(
      "Compare the cost of a protein component",
      "When a familiar food becomes expensive.",
      task: "Compare two suitable options for one dish.",
      steps: [
        "Check price and the amount you can actually use.",
        "Consider cooking, storage and restrictions before choosing.",
      ],
      example:
          "Compare ready beans and eggs for lunch rather than seeking a costly specialist product.",
      alternative:
          "Keep the familiar option if a replacement needs unavailable equipment.",
      doneWhen:
          "An accessible component is chosen with preparation considered.",
      why:
          "Pack price and preparation together make a substitution more realistic.",
      explanation:
          "Food comparisons do not prescribe a personal target. Respect allergies, tolerance and prescribed diets.",
    ),
  ),

  DailyTip(
    id: "food-fat-cooking-role",
    topic: "food-fat-cooking-role",
    category: TipCategory.macros,
    version: 5,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Масло для конкретного способа готовки",
      "Если неясно, какое масло использовать.",
      task: "Проверьте назначение имеющегося масла для нагрева или заправки.",
      steps: [
        "Прочитайте инструкцию и условия хранения.",
        "Используйте подходящее масло по назначению без обязательной покупки нового.",
      ],
      example:
          "Масло, указанное для заправки, оставить для салата, для сковороды выбрать подходящее по маркировке.",
      alternative:
          "Выберите иной способ приготовления, если подходящего масла нет.",
      doneWhen: "Выбран продукт, соответствующий способу использования.",
      why:
          "Различие способов применения полезнее общего правила добавлять любое масло.",
      explanation:
          "Сравнение продуктов не назначает личную норму. Учитывайте аллергию, переносимость и назначенную диету.",
    ),
    en: TipCopy(
      "Choose oil for its cooking role",
      "When unsure which oil to use.",
      task: "Check whether your oil is intended for heating or dressing.",
      steps: [
        "Read usage and storage instructions.",
        "Use a suitable oil for its labelled role without requiring a new purchase.",
      ],
      example:
          "Keep an oil labelled for dressing for salad; use a heating-suitable oil for a pan.",
      alternative:
          "Choose another cooking method if a suitable oil is unavailable.",
      doneWhen: "The product matches the intended use.",
      why:
          "Matching the cooking role is more useful than adding any oil automatically.",
      explanation:
          "Food comparisons do not prescribe a personal target. Respect allergies, tolerance and prescribed diets.",
    ),
  ),

  DailyTip(
    id: "food-gluten-substitution",
    topic: "food-gluten-substitution",
    category: TipCategory.macros,
    version: 5,
    sourceIds: ["cdc-eating", "fda-allergens"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Основа блюда без пшеницы при необходимости",
      "Если пшеница не подходит по вашим ограничениям.",
      task: "Подберите подходящую основу вместо пшеничной пасты.",
      steps: [
        "Уточните свои ограничения и прочитайте маркировку продукта.",
        "Выберите безопасную крупу или картофель и сохраните подходящие остальные компоненты.",
      ],
      example: "Картофель с фасолью и овощами вместо пшеничной пасты.",
      alternative:
          "При целиакии учитывайте сертификацию и перекрёстный контакт по своему лечебному плану.",
      doneWhen: "Выбрана основа с проверенной пригодностью.",
      why:
          "Замена решает конкретное ограничение; отказ от глютена не предлагается всем.",
      explanation:
          "Сравнение продуктов не назначает личную норму. Учитывайте аллергию, переносимость и назначенную диету.",
    ),
    en: TipCopy(
      "A wheat-free meal base when needed",
      "When wheat does not fit your restrictions.",
      task: "Find a suitable base instead of wheat pasta.",
      steps: [
        "Clarify your restrictions and read the product label.",
        "Choose safe grain or potato and keep the suitable remaining components.",
      ],
      example: "Potato with beans and vegetables instead of wheat pasta.",
      alternative:
          "For coeliac disease, follow your care plan on certification and cross-contact.",
      doneWhen: "A base with checked suitability is chosen.",
      why:
          "The swap addresses a specific restriction; gluten avoidance is not suggested for everyone.",
      explanation:
          "Food comparisons do not prescribe a personal target. Respect allergies, tolerance and prescribed diets.",
    ),
  ),

  DailyTip(
    id: "move-indoor-space",
    topic: "move-indoor-space",
    category: TipCategory.activity,
    version: 5,
    sourceIds: ["cdc-accessible"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Освободите место для домашнего движения",
      "Если хотите двигаться дома.",
      task: "Проверьте один небольшой участок на препятствия.",
      steps: [
        "Уберите скользящие предметы и провода, если можете безопасно.",
        "Выберите знакомое доступное движение в свободном месте или отдых.",
      ],
      example:
          "Освободить проход для спокойного движения по комнате или на коляске.",
      alternative:
          "Попросите помочь с тяжёлыми предметами; не переносите их ради плана.",
      doneWhen: "Подготовлено безопасное место или выбран другой вариант.",
      why: "Устранение препятствия делает домашнее движение доступнее.",
      explanation:
          "Выбирайте знакомую посильную нагрузку; отдых допустим. При боли, головокружении или другом дискомфорте остановитесь. Новые ограничения обсудите со специалистом.",
    ),
    en: TipCopy(
      "Clear space for indoor movement",
      "When you want to move at home.",
      task: "Check one small area for obstacles.",
      steps: [
        "Remove loose objects and cables when safe to do so.",
        "Choose familiar accessible movement in the clear space or rest.",
      ],
      example: "Clear a path for comfortable indoor walking or wheeling.",
      alternative:
          "Ask for help with heavy objects rather than moving them for this plan.",
      doneWhen: "A safe space or another option is chosen.",
      why: "Removing an obstacle can make indoor movement more accessible.",
      explanation:
          "Choose familiar manageable activity; rest is valid. Stop with pain, dizziness or other discomfort. Discuss new limitations with a professional.",
    ),
  ),

  DailyTip(
    id: "move-chair-mobility",
    topic: "move-chair-mobility",
    category: TipCategory.activity,
    version: 5,
    sourceIds: ["cdc-accessible"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Знакомое движение сидя",
      "Если удобнее оставаться сидя.",
      task: "Попробуйте одно уже знакомое комфортное движение сидя.",
      steps: [
        "Используйте устойчивое подходящее сиденье и своё согласованное движение.",
        "Выполните в удобном объёме и остановитесь при дискомфорте.",
      ],
      example:
          "Знакомое мягкое движение плечами, если оно вам разрешено и удобно.",
      alternative:
          "Отдых или совет специалиста по подходящему движению при ограничениях.",
      doneWhen:
          "Оценена переносимость одного знакомого движения без обязательного числа повторов.",
      why:
          "Сидячий вариант позволяет выбирать движение с учётом доступных возможностей.",
      explanation:
          "Выбирайте знакомую посильную нагрузку; отдых допустим. При боли, головокружении или другом дискомфорте остановитесь. Новые ограничения обсудите со специалистом.",
    ),
    en: TipCopy(
      "A familiar seated movement",
      "When staying seated is more comfortable.",
      task: "Try one already familiar comfortable seated movement.",
      steps: [
        "Use suitable stable seating and a movement agreed for you.",
        "Do a comfortable amount and stop if uncomfortable.",
      ],
      example:
          "A familiar gentle shoulder movement if allowed and comfortable.",
      alternative:
          "Rest or ask a professional about suitable movement for your limitations.",
      doneWhen:
          "One familiar movement is considered without a required repetition count.",
      why: "A seated option accommodates the abilities available to you.",
      explanation:
          "Choose familiar manageable activity; rest is valid. Stop with pain, dizziness or other discomfort. Discuss new limitations with a professional.",
    ),
  ),

  DailyTip(
    id: "move-carry-task",
    topic: "move-carry-task",
    category: TipCategory.activity,
    version: 5,
    sourceIds: ["cdc-accessible"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Разделите переноску вещей",
      "Если бытовая задача требует неприятного усилия.",
      task: "Разбейте переноску на удобные части или попросите помощь.",
      steps: [
        "Оцените путь и вес без проверки своих пределов.",
        "Возьмите меньшую нагрузку или организуйте помощь.",
      ],
      example:
          "Несколько лёгких пакетов вместо одного тяжёлого, если ходить вам удобно.",
      alternative: "Доставка, тележка или помощь другого человека.",
      doneWhen:
          "Выбран способ выполнить задачу без требования терпеть нагрузку.",
      why:
          "Бытовое движение можно адаптировать, а не превращать в испытание силы.",
      explanation:
          "Выбирайте знакомую посильную нагрузку; отдых допустим. При боли, головокружении или другом дискомфорте остановитесь. Новые ограничения обсудите со специалистом.",
    ),
    en: TipCopy(
      "Split a carrying task",
      "When a household task feels too demanding.",
      task: "Break carrying into manageable parts or ask for help.",
      steps: [
        "Consider the route and weight without testing your limits.",
        "Use a smaller load or arrange assistance.",
      ],
      example:
          "Several light bags instead of one heavy bag if walking suits you.",
      alternative: "Use delivery, a trolley or another person’s help.",
      doneWhen: "A way to do the task without enduring strain is chosen.",
      why:
          "Household movement can be adapted rather than turned into a strength test.",
      explanation:
          "Choose familiar manageable activity; rest is valid. Stop with pain, dizziness or other discomfort. Discuss new limitations with a professional.",
    ),
  ),

  DailyTip(
    id: "move-social-meeting",
    topic: "move-social-meeting",
    category: TipCategory.activity,
    version: 5,
    sourceIds: ["cdc-accessible"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Встреча с возможностью движения",
      "Если хочется совместить общение и посильную активность.",
      task:
          "Предложите знакомому встречу с удобным для обоих форматом движения.",
      steps: [
        "Согласуйте доступность и возможность остановиться.",
        "Выберите короткую встречу без соревнования по темпу.",
      ],
      example:
          "Прогулка или движение на коляске рядом с местом, где можно посидеть.",
      alternative: "Встреча сидя тоже подходит, если движение сейчас неудобно.",
      doneWhen: "Согласован формат с учётом обоих людей.",
      why:
          "Совместный план учитывает доступность, а не требует подстраиваться под чужую скорость.",
      explanation:
          "Выбирайте знакомую посильную нагрузку; отдых допустим. При боли, головокружении или другом дискомфорте остановитесь. Новые ограничения обсудите со специалистом.",
    ),
    en: TipCopy(
      "A meeting with optional movement",
      "To combine company and manageable activity.",
      task: "Suggest a meeting with movement that works for both people.",
      steps: [
        "Agree accessibility and the option to stop.",
        "Choose a short meeting without competing on pace.",
      ],
      example: "Walking or wheeling near a place to sit.",
      alternative:
          "A seated meeting is equally valid if movement is unsuitable.",
      doneWhen: "A format that suits both people is agreed.",
      why:
          "A shared plan accounts for access rather than requiring someone else’s pace.",
      explanation:
          "Choose familiar manageable activity; rest is valid. Stop with pain, dizziness or other discomfort. Discuss new limitations with a professional.",
    ),
  ),

  DailyTip(
    id: "move-first-class",
    topic: "move-first-class",
    category: TipCategory.activity,
    version: 5,
    sourceIds: ["cdc-accessible"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Проверьте доступность занятия до записи",
      "Если рассматриваете новое занятие.",
      task:
          "Задайте организатору один конкретный вопрос об адаптации нагрузки.",
      steps: [
        "Назовите нужное вам условие без обязательного раскрытия диагноза.",
        "Уточните возможность облегчить движение и сделать паузу.",
      ],
      example:
          "Спросить, можно ли выполнять часть занятия сидя и выходить на отдых.",
      alternative:
          "Выберите знакомое движение или индивидуальную консультацию вместо занятия.",
      doneWhen: "Получен ответ об адаптации до оплаты или записи.",
      why: "Проверка доступности заранее помогает выбрать подходящий формат.",
      explanation:
          "Выбирайте знакомую посильную нагрузку; отдых допустим. При боли, головокружении или другом дискомфорте остановитесь. Новые ограничения обсудите со специалистом.",
    ),
    en: TipCopy(
      "Check a class before booking",
      "When considering a new activity class.",
      task:
          "Ask the organiser a specific question about adapting the activity.",
      steps: [
        "Name an access need without having to disclose a diagnosis.",
        "Check options for easier movements and breaks.",
      ],
      example:
          "Ask whether some movements can be seated and breaks are allowed.",
      alternative:
          "Use familiar movement or individual advice instead of a class.",
      doneWhen: "Adaptation information is obtained before paying or booking.",
      why: "Checking access in advance supports a suitable choice of format.",
      explanation:
          "Choose familiar manageable activity; rest is valid. Stop with pain, dizziness or other discomfort. Discuss new limitations with a professional.",
    ),
  ),

  DailyTip(
    id: "move-weather-decision",
    topic: "gentle-movement",
    category: TipCategory.activity,
    version: 5,
    sourceIds: ["cdc-accessible"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "План на небезопасную погоду",
      "Если жара, лёд или другое условие мешает выходу.",
      task: "Замените уличное движение доступным безопасным вариантом.",
      steps: [
        "Проверьте местные условия и свои ограничения.",
        "Перенесите выход или выберите знакомое движение внутри, не догоняя объём.",
      ],
      example:
          "При гололёде — доступное движение дома вместо прогулки по скользкой дорожке.",
      alternative: "Отдых и перенос прогулки на другой день.",
      doneWhen: "План изменён с учётом условий без компенсации.",
      why: "Изменение среды важнее выполнения заранее выбранной дистанции.",
      explanation:
          "Выбирайте знакомую посильную нагрузку; отдых допустим. При боли, головокружении или другом дискомфорте остановитесь. Новые ограничения обсудите со специалистом.",
    ),
    en: TipCopy(
      "Adapt movement to unsafe weather",
      "When heat, ice or another condition makes going out unsuitable.",
      task: "Replace outdoor movement with an accessible safe option.",
      steps: [
        "Check local conditions and your restrictions.",
        "Postpone going out or use familiar indoor movement without catching up volume.",
      ],
      example: "On icy paths, choose accessible indoor movement instead.",
      alternative: "Rest and move the outing to another day.",
      doneWhen: "The plan reflects conditions without compensation.",
      why: "Changing conditions matter more than completing a preset distance.",
      explanation:
          "Choose familiar manageable activity; rest is valid. Stop with pain, dizziness or other discomfort. Discuss new limitations with a professional.",
    ),
  ),

  DailyTip(
    id: "move-activity-menu",
    topic: "move-activity-menu",
    category: TipCategory.activity,
    version: 5,
    sourceIds: ["cdc-accessible"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Выберите движение по интересу",
      "Если привычная активность наскучила.",
      task: "Составьте пару приятных доступных вариантов разного типа.",
      steps: [
        "Вспомните знакомые движения, которые нравятся.",
        "Выберите один по сегодняшним возможностям, без цели сжечь еду.",
      ],
      example: "Знакомое движение под музыку или спокойный уход за растениями.",
      alternative:
          "Отдых тоже остаётся вариантом; новые ограничения обсудите со специалистом.",
      doneWhen:
          "Выбраны два реально доступных варианта, один подходит на сегодня.",
      why: "Интерес помогает расширить выбор за пределы одного счётчика шагов.",
      explanation:
          "Выбирайте знакомую посильную нагрузку; отдых допустим. При боли, головокружении или другом дискомфорте остановитесь. Новые ограничения обсудите со специалистом.",
    ),
    en: TipCopy(
      "Choose movement by interest",
      "When your usual activity feels dull.",
      task: "List a couple of enjoyable accessible options of different types.",
      steps: [
        "Recall familiar movements you enjoy.",
        "Choose one for today’s abilities without a food-burning goal.",
      ],
      example: "Familiar movement to music or gentle plant care.",
      alternative:
          "Rest remains an option; discuss new limitations with a professional.",
      doneWhen: "Two realistic options are listed and one suits today.",
      why: "Interest broadens the choice beyond one step counter.",
      explanation:
          "Choose familiar manageable activity; rest is valid. Stop with pain, dizziness or other discomfort. Discuss new limitations with a professional.",
    ),
  ),

  DailyTip(
    id: "move-restart-gap",
    topic: "load-adjustment",
    category: TipCategory.activity,
    version: 5,
    sourceIds: ["cdc-accessible"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Возвращение после перерыва без догоняния",
      "Если давно не делали привычное движение.",
      task:
          "Вернитесь к облегчённому знакомому варианту, если он вам подходит.",
      steps: [
        "Оцените сегодняшнее самочувствие и ограничения.",
        "Выберите меньший удобный объём без попытки вернуть прежний результат сразу.",
      ],
      example: "Короткая знакомая прогулка вместо прежнего длинного маршрута.",
      alternative:
          "После болезни, травмы или новых симптомов сначала уточните безопасный возврат со специалистом.",
      doneWhen: "Выбран посильный возврат или профессиональная консультация.",
      why: "Перерыв не создаёт долг, который нужно отработать нагрузкой.",
      explanation:
          "Выбирайте знакомую посильную нагрузку; отдых допустим. При боли, головокружении или другом дискомфорте остановитесь. Новые ограничения обсудите со специалистом.",
    ),
    en: TipCopy(
      "Return after a break without catching up",
      "When you have paused a familiar activity.",
      task: "Return to an easier familiar version if suitable.",
      steps: [
        "Consider today’s wellbeing and restrictions.",
        "Choose a smaller comfortable amount without immediately restoring past performance.",
      ],
      example: "A short familiar outing instead of a former long route.",
      alternative:
          "After illness, injury or new symptoms, check a safe return with a professional first.",
      doneWhen: "A manageable return or professional advice is chosen.",
      why: "A break does not create an activity debt to repay.",
      explanation:
          "Choose familiar manageable activity; rest is valid. Stop with pain, dizziness or other discomfort. Discuss new limitations with a professional.",
    ),
  ),

  DailyTip(
    id: "move-accessible-destination",
    topic: "move-accessible-destination",
    category: TipCategory.activity,
    version: 5,
    sourceIds: ["cdc-accessible"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Проверьте доступность места назначения",
      "Если планируете выйти в новое место.",
      task: "Уточните один важный барьер до выхода.",
      steps: [
        "Проверьте вход, покрытие или доступный туалет по своим потребностям.",
        "Наметьте подходящий путь или другое место.",
      ],
      example: "Узнать, есть ли доступный вход в парк и удобное покрытие.",
      alternative:
          "Выберите знакомое доступное место, если информация не подтверждена.",
      doneWhen: "Проверено нужное условие и есть запасной вариант.",
      why:
          "Проверка конкретного барьера помогает избежать недоступного маршрута.",
      explanation:
          "Выбирайте знакомую посильную нагрузку; отдых допустим. При боли, головокружении или другом дискомфорте остановитесь. Новые ограничения обсудите со специалистом.",
    ),
    en: TipCopy(
      "Check access at your destination",
      "When planning to visit somewhere new.",
      task: "Check one important access barrier before leaving.",
      steps: [
        "Verify the entrance, surface or accessible toilet according to your needs.",
        "Choose a workable route or another venue.",
      ],
      example: "Check an accessible park entrance and suitable paths.",
      alternative:
          "Use a familiar accessible place if information is unconfirmed.",
      doneWhen: "A required access feature and fallback are checked.",
      why: "Checking a specific barrier helps avoid an inaccessible outing.",
      explanation:
          "Choose familiar manageable activity; rest is valid. Stop with pain, dizziness or other discomfort. Discuss new limitations with a professional.",
    ),
  ),

  DailyTip(
    id: "move-pace-conversation",
    topic: "load-adjustment",
    category: TipCategory.activity,
    version: 5,
    sourceIds: ["cdc-accessible"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Удобный темп без гонки",
      "Если знакомое движение становится неприятно тяжёлым.",
      task: "Снизьте темп или остановитесь по самочувствию.",
      steps: [
        "Заметьте, остаётся ли обычное движение комфортным.",
        "Уменьшите темп, выберите паузу; необычные симптомы обсудите со специалистом.",
      ],
      example:
          "На прогулке перейти к удобному темпу вместо попытки держаться за другим человеком.",
      alternative: "Отдых, если даже облегчённое движение сейчас не подходит.",
      doneWhen: "Темп адаптирован или движение прекращено при дискомфорте.",
      why: "Чужая скорость не является обязательной нагрузкой для вас.",
      explanation:
          "Выбирайте знакомую посильную нагрузку; отдых допустим. При боли, головокружении или другом дискомфорте остановитесь. Новые ограничения обсудите со специалистом.",
    ),
    en: TipCopy(
      "Use a comfortable pace",
      "When familiar movement feels unpleasantly hard.",
      task: "Slow down or stop according to how you feel.",
      steps: [
        "Notice whether the usual movement remains comfortable.",
        "Ease the pace or pause; discuss unusual symptoms with a professional.",
      ],
      example:
          "Walk at your own comfortable pace rather than keeping up with someone else.",
      alternative: "Rest if even easier movement is unsuitable.",
      doneWhen: "The pace is adapted or movement stopped if uncomfortable.",
      why: "Another person’s speed is not your required workload.",
      explanation:
          "Choose familiar manageable activity; rest is valid. Stop with pain, dizziness or other discomfort. Discuss new limitations with a professional.",
    ),
  ),

  DailyTip(
    id: "plan-two-day-menu",
    topic: "plan-two-day-menu",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Меню только на два ближайших дня",
      "Если недельный план слишком громоздкий.",
      task: "Распишите два дня с учётом реально доступных приёмов пищи.",
      steps: [
        "Посмотрите расписание и продукты дома.",
        "Выберите еду на два дня и оставьте одно место для изменения.",
      ],
      example:
          "На завтра суп, на следующий день паста; ужин можно заменить готовой едой.",
      alternative: "Запланируйте один день, если два пока неудобны.",
      doneWhen: "Есть короткий план с допустимым изменением.",
      why:
          "Меньший горизонт уменьшает объём решений без требования спланировать всю неделю.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Plan only the next two days",
      "When a weekly menu feels unwieldy.",
      task: "Sketch two days around the meals actually accessible to you.",
      steps: [
        "Check your schedule and food at home.",
        "Choose food for two days and leave one option flexible.",
      ],
      example:
          "Soup tomorrow, pasta the next day; dinner can switch to prepared food.",
      alternative: "Plan one day if two feels impractical.",
      doneWhen: "A short plan includes room for change.",
      why:
          "A shorter horizon reduces decisions without requiring a whole-week plan.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-freezer-label",
    topic: "plan-freezer-label",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["fsa-chilling"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Подпишите одну заготовку",
      "Если в морозилке трудно узнать контейнеры.",
      task: "Подпишите название и дату заморозки одной безопасной заготовки.",
      steps: [
        "Выберите еду с известным составом и хранением.",
        "Добавьте читаемую подпись и нужный способ разморозки по инструкции.",
      ],
      example: "«Овощной суп, дата заморозки» на контейнере.",
      alternative:
          "При неизвестном хранении не придумывайте дату и не используйте сомнительную еду.",
      doneWhen: "Одна заготовка получила правдивую подпись.",
      why:
          "Подпись позволяет понять содержимое и срок, не полагаясь на память.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Label one freezer portion",
      "When freezer containers are hard to identify.",
      task:
          "Label one safely prepared portion with its name and freezing date.",
      steps: [
        "Choose food with known contents and storage.",
        "Add a readable label and relevant defrosting instructions.",
      ],
      example: "“Vegetable soup, freezing date” on the container.",
      alternative:
          "Do not invent a date or use doubtful food when storage is unknown.",
      doneWhen: "One portion has an accurate label.",
      why: "A label makes contents and timing clear without relying on memory.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-first-use-shelf",
    topic: "plan-first-use-shelf",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["fsa-chilling"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Поставьте продукты по очереди использования",
      "Если забываете уже открытые упаковки.",
      task: "Выделите место для продуктов, которые нужно использовать раньше.",
      steps: [
        "Проверьте сроки и условия хранения без оценки безопасности по запаху.",
        "Передвиньте подходящие продукты вперёд, соблюдая правила хранения.",
      ],
      example:
          "Открытый подходящий йогурт впереди закрытого, с учётом инструкции после открытия.",
      alternative:
          "Запишите один продукт на видном списке, если переставлять неудобно.",
      doneWhen: "У одного продукта понятен приоритет использования.",
      why:
          "Очередь использования помогает заметить доступную еду до покупки новой.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Arrange food by use priority",
      "When opened packs get forgotten.",
      task: "Make a place for food that should be used sooner.",
      steps: [
        "Check dates and storage instructions rather than judging safety by smell.",
        "Bring suitable items forward while respecting storage rules.",
      ],
      example:
          "An opened suitable yogurt before a sealed one, following after-opening directions.",
      alternative: "List one item visibly if rearranging is difficult.",
      doneWhen: "One item has a clear use priority.",
      why:
          "A use-first order helps you notice available food before buying more.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-batch-freeze",
    topic: "plan-batch-freeze",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["fsa-chilling"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Разделите большую готовку на порции",
      "Если приготовили больше, чем скоро используете.",
      task: "Быстро охладите и уберите безопасные порции на хранение.",
      steps: [
        "Разделите еду для быстрого охлаждения и уберите в холодильник или морозилку в пределах 1–2 часов.",
        "Подпишите замороженные порции; сроки и разморозку проверяйте по продукту.",
      ],
      example:
          "Лишние порции овощного супа разделить по контейнерам и заморозить.",
      alternative:
          "Готовьте меньше, если нет возможности безопасно охлаждать и хранить.",
      doneWhen: "Лишняя еда безопасно разделена и убрана вовремя.",
      why: "Небольшие порции облегчают охлаждение и дальнейшее использование.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Divide a larger batch into portions",
      "When you cook more than you will soon use.",
      task: "Cool food promptly and store suitable portions safely.",
      steps: [
        "Divide for quicker cooling and refrigerate or freeze within 1–2 hours.",
        "Label frozen portions; check food-specific storage and defrosting guidance.",
      ],
      example: "Divide extra vegetable soup into containers and freeze.",
      alternative: "Cook less if safe cooling and storage are unavailable.",
      doneWhen: "Extra food is divided and stored safely in time.",
      why: "Smaller portions make cooling and later use easier.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-shopping-route",
    topic: "plan-shopping-route",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Список по отделам магазина",
      "Если покупки отнимают много сил.",
      task: "Сгруппируйте короткий список по отделам знакомого магазина.",
      steps: [
        "Выберите нужные продукты из конкретного плана еды.",
        "Разместите их в порядке доступного маршрута.",
      ],
      example:
          "Крупа и фасоль вместе в списке, охлаждённые продукты ближе к завершению покупок.",
      alternative:
          "Используйте заказ или помощь с покупками, если магазин недоступен.",
      doneWhen: "Список соответствует удобному маршруту или способу заказа.",
      why: "Порядок списка уменьшает лишние перемещения при покупке еды.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Group a shopping list by store section",
      "When shopping takes too much effort.",
      task: "Group a short list by sections in a familiar shop.",
      steps: [
        "Choose needed foods from a specific meal plan.",
        "Arrange them in an accessible route order.",
      ],
      example:
          "List grains and beans together, with chilled foods near the end.",
      alternative: "Use ordering or help if the shop is inaccessible.",
      doneWhen: "The list fits a useful route or ordering method.",
      why: "An ordered list reduces unnecessary movement while buying food.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-online-substitution",
    topic: "plan-online-substitution",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["fda-allergens", "cdc-eating"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Проверьте замену в продуктовом заказе",
      "Если магазин заменил товар без вас.",
      task: "Перечитайте состав одного заменённого продукта до использования.",
      steps: [
        "Сверьте ограничения, аллергенную маркировку и хранение.",
        "Примите подходящую замену или запросите возврат по правилам магазина.",
      ],
      example:
          "Вместо обычного соевого напитка привезли продукт с другим составом.",
      alternative:
          "Отключите неподходящие автоматические замены в следующем заказе.",
      doneWhen: "Замена проверена, неподходящий продукт не использован наугад.",
      why: "Похожее название не гарантирует тот же состав.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Check a grocery substitution",
      "When a shop replaces an item for you.",
      task: "Reread one replacement product’s label before using it.",
      steps: [
        "Check restrictions, allergen labelling and storage.",
        "Accept a suitable replacement or request a return under store rules.",
      ],
      example: "A substituted soy drink has a different ingredient list.",
      alternative:
          "Disable unsuitable automatic substitutions in the next order.",
      doneWhen: "The replacement is checked rather than used on assumption.",
      why: "A similar name does not guarantee the same composition.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-cooking-tool",
    topic: "plan-cooking-tool",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Уберите одно препятствие к готовке",
      "Если перед едой приходится долго искать нужное.",
      task: "Подготовьте один часто используемый безопасный инструмент.",
      steps: [
        "Назовите, что обычно задерживает приготовление.",
        "Положите чистый нужный предмет в доступное место.",
      ],
      example:
          "Чистая открывалка рядом с консервами, вне доступа маленьких детей.",
      alternative:
          "Выберите упаковку с удобным открыванием, если инструментом трудно пользоваться.",
      doneWhen: "Одно конкретное препятствие стало меньше.",
      why:
          "Доступный инструмент сокращает подготовку без полного переустройства кухни.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Remove one cooking obstacle",
      "When finding equipment delays a meal.",
      task: "Make one frequently used safe tool accessible.",
      steps: [
        "Name the item that usually delays preparation.",
        "Place the clean item somewhere accessible and safe.",
      ],
      example: "A clean tin opener near tins, out of small children’s reach.",
      alternative:
          "Use easier-opening packaging if a tool is difficult to operate.",
      doneWhen: "One specific obstacle is reduced.",
      why:
          "An accessible tool shortens preparation without reorganising the whole kitchen.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-backup-appointment",
    topic: "meal-time",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "План еды на день с приёмом у специалиста",
      "Если дорога и ожидание меняют расписание.",
      task:
          "Подготовьте вариант еды вокруг длительной встречи с учётом указаний.",
      steps: [
        "Проверьте, нет ли специальных требований к еде или питью перед приёмом.",
        "Спланируйте подходящую еду до или после встречи, не нарушая указаний.",
      ],
      example: "После приёма — доступное кафе или безопасно хранимый обед.",
      alternative: "При неясных требованиях заранее уточните их в учреждении.",
      doneWhen: "Есть план еды, согласованный с требованиями встречи.",
      why:
          "Ожидание меньше нарушает еду, а специальные инструкции сохраняются.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Food around a long appointment",
      "When travel and waiting change the schedule.",
      task: "Plan food around the appointment while following instructions.",
      steps: [
        "Check for any food or drink requirements before attending.",
        "Arrange suitable food before or afterwards without breaking those instructions.",
      ],
      example: "A nearby cafe or safely stored lunch after the appointment.",
      alternative: "Ask the provider beforehand if requirements are unclear.",
      doneWhen: "A food plan fits the appointment’s instructions.",
      why:
          "Waiting need not displace food while special instructions are respected.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-change-cue",
    topic: "plan-change-cue",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Проверьте, работает ли напоминание",
      "Если сигнал о еде постоянно попадает на неудобный момент.",
      task:
          "Перенесите одно собственное напоминание на реально доступное событие.",
      steps: [
        "Посмотрите, что обычно мешает ответить на сигнал.",
        "Выберите доступный момент и проверьте удобство, без добавления новых сигналов.",
      ],
      example: "Напоминание подготовить обед после завершения рабочего звонка.",
      alternative:
          "Уберите сигнал, если он вызывает тревогу; выберите записку или помощь.",
      doneWhen: "Одно напоминание адаптировано или отключено осознанно.",
      why: "Удобство сигнала полезнее увеличения количества уведомлений.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Check whether a reminder works",
      "When a food reminder repeatedly arrives at an awkward moment.",
      task: "Move one personal reminder to a genuinely accessible cue.",
      steps: [
        "Notice what usually blocks responding to it.",
        "Choose a workable moment and assess convenience without adding more alerts.",
      ],
      example: "A reminder to prepare lunch after a work call ends.",
      alternative:
          "Remove an anxiety-provoking alert; use a note or support instead.",
      doneWhen: "One reminder is adapted or intentionally removed.",
      why: "A usable cue matters more than adding more notifications.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-choice-default",
    topic: "plan-choice-default",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Сохраните один удачный вариант еды",
      "Если удачное сочетание трудно вспомнить в занятый день.",
      task: "Запишите состав одного удобного блюда в личном списке.",
      steps: [
        "Вспомните конкретное сочетание, которое уже подошло.",
        "Сохраните короткий список компонентов и способ подготовки.",
      ],
      example: "«Гречка, фасоль, огурец; крупа по упаковке» в заметке.",
      alternative: "Фотография блюда с подписью, если так удобнее.",
      doneWhen: "Есть доступная подсказка к одному проверенному блюду.",
      why:
          "Сохранённый вариант уменьшает повторное решение одной и той же бытовой задачи.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Keep one meal that worked",
      "When a useful combination is hard to recall on busy days.",
      task: "Record one convenient meal in your personal list.",
      steps: [
        "Recall a particular combination that suited you.",
        "Save a short ingredient and preparation note.",
      ],
      example:
          "“Buckwheat, beans, cucumber; cook grain as labelled” in a note.",
      alternative: "Use a labelled meal photo if easier.",
      doneWhen: "A prompt for one tried meal is accessible.",
      why:
          "A saved option reduces having to solve the same everyday choice again.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-eating-space",
    topic: "plan-eating-space",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Подготовьте доступное место для еды",
      "Если рабочие вещи занимают весь стол.",
      task: "Освободите небольшой удобный участок для одного приёма пищи.",
      steps: [
        "Уберите мешающие предметы без тяжёлой перестановки.",
        "Подготовьте подходящие посуду и сиденье по своим потребностям.",
      ],
      example: "Освободить край стола для тарелки и чашки.",
      alternative:
          "Подойдёт другое устойчивое доступное место; идеальная сервировка не нужна.",
      doneWhen: "Одно место позволяет удобно разместить еду.",
      why:
          "Пространство помогает поесть без необходимости сначала разбирать всю комнату.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Make an accessible place to eat",
      "When work items fill the table.",
      task: "Clear a small comfortable space for one meal.",
      steps: [
        "Move obstructing items without heavy rearranging.",
        "Prepare suitable tableware and seating for your needs.",
      ],
      example: "Clear a table corner for a plate and cup.",
      alternative:
          "Use another stable accessible place; perfect table-setting is unnecessary.",
      doneWhen: "One space can comfortably hold food.",
      why:
          "A small space makes eating possible without first tidying the whole room.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-split-recipe",
    topic: "plan-split-recipe",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Уменьшите рецепт до нужного объёма",
      "Если рецепт рассчитан на слишком большую компанию.",
      task:
          "Пересчитайте один знакомый рецепт под доступное хранение и число едоков.",
      steps: [
        "Определите, какая часть рецепта нужна.",
        "Пропорционально измените ингредиенты, а время и готовность проверьте отдельно.",
      ],
      example:
          "Половина овощного супа при небольшой кастрюле; время не делить автоматически пополам.",
      alternative:
          "Приготовьте полный объём только при возможности безопасно сохранить остатки.",
      doneWhen: "Выбран подходящий объём и отдельно проверена готовность.",
      why:
          "Меньший объём учитывает возможности кухни, а не заставляет готовить лишнее.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Scale a recipe to the amount needed",
      "When a recipe serves too many people.",
      task: "Scale one familiar recipe to your diners and storage access.",
      steps: [
        "Decide what fraction of the recipe you need.",
        "Scale ingredients proportionally but check cooking time and doneness separately.",
      ],
      example:
          "Half a vegetable soup recipe in a smaller pot; do not automatically halve cooking time.",
      alternative: "Cook the full amount only with safe storage for leftovers.",
      doneWhen:
          "An appropriate amount is chosen and doneness checked separately.",
      why:
          "A smaller batch fits the kitchen rather than requiring excess cooking.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "plan-request-food-help",
    topic: "food-support",
    category: TipCategory.habits,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Попросите конкретную помощь с едой",
      "Если трудно справиться с покупками или готовкой.",
      task: "Сформулируйте одну выполнимую просьбу близкому человеку.",
      steps: [
        "Выберите задачу, которая сейчас мешает поесть.",
        "Назовите конкретный продукт, действие и удобное время.",
      ],
      example: "«Можешь купить хлеб и фасоль по дороге сегодня?»",
      alternative:
          "Готовая подходящая еда или социальная поддержка, если личная помощь недоступна.",
      doneWhen: "Есть конкретная просьба или выбран другой доступный способ.",
      why:
          "Определённая просьба облегчает получение помощи без требования справляться одному.",
      explanation:
          "Это добровольный способ организовать быт, а не оценка дисциплины. Выбирайте доступное; при тревоге от контроля можно сделать паузу. Соблюдайте условия хранения продуктов.",
    ),
    en: TipCopy(
      "Ask for specific food help",
      "When shopping or cooking is difficult to manage.",
      task: "Make one practical request to someone trusted.",
      steps: [
        "Choose the task currently making food difficult.",
        "Name a specific product or action and a useful time.",
      ],
      example: "“Could you pick up bread and beans on your way today?”",
      alternative:
          "Use suitable prepared food or community support when personal help is unavailable.",
      doneWhen:
          "A specific request or another accessible option is identified.",
      why:
          "A clear request makes help easier without requiring you to manage alone.",
      explanation:
          "This is an optional way to organise daily tasks, not a discipline score. Choose what is accessible; pause if monitoring causes anxiety. Follow food storage requirements.",
    ),
  ),

  DailyTip(
    id: "rest-wake-anchor",
    topic: "rest-wake-anchor",
    category: TipCategory.recovery,
    version: 5,
    sourceIds: ["nhs-sleep"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Удобный ориентир пробуждения",
      "Если режим сильно меняется и это вам мешает.",
      task: "Выберите посильное время пробуждения для ближайших похожих дней.",
      steps: [
        "Посмотрите на реальный график и нужное время сна.",
        "Наметьте удобный ориентир без урезания сна ради раннего подъёма.",
      ],
      example:
          "В выходной оставить похожее время, если это совместимо с отдыхом.",
      alternative:
          "При сменной работе подберите индивидуальный режим; при стойких трудностях обсудите сон со специалистом.",
      doneWhen: "Есть реалистичный ориентир без намеренного недосыпа.",
      why:
          "Повторяемый ориентир помогает организовать распорядок, не обещая вылечить нарушения сна.",
      explanation:
          "Бытовой шаг не заменяет лечение и не обещает исправить сон. При стойких трудностях и влиянии на день обратитесь за индивидуальной помощью.",
    ),
    en: TipCopy(
      "A workable waking-time anchor",
      "When changing timing bothers your routine.",
      task: "Choose a manageable waking time for upcoming similar days.",
      steps: [
        "Check your real schedule and sleep needs.",
        "Set a workable anchor without cutting sleep to wake early.",
      ],
      example: "Keep a similar weekend time if compatible with rest.",
      alternative:
          "For shift work use an individual routine; discuss persistent sleep problems with a professional.",
      doneWhen: "A realistic anchor avoids deliberate sleep loss.",
      why:
          "A repeatable anchor supports routine without promising to treat sleep disorders.",
      explanation:
          "An everyday step does not replace treatment or promise to fix sleep. Seek individual help for persistent difficulties affecting your day.",
    ),
  ),

  DailyTip(
    id: "rest-worry-note",
    topic: "rest-worry-note",
    category: TipCategory.recovery,
    version: 5,
    sourceIds: ["nhs-sleep"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Перенесите вечернее дело на бумагу",
      "Если мысли о завтрашних задачах удерживают внимание.",
      task: "Запишите одну задачу и время, когда вернётесь к ней.",
      steps: [
        "Назовите конкретное незавершённое дело.",
        "Оставьте короткую заметку и отложите её до выбранного времени.",
      ],
      example: "«Завтра после завтрака проверить список покупок».",
      alternative: "Устная договорённость с близким вместо записей.",
      doneWhen: "Одно дело получило понятный следующий момент.",
      why: "Заметка сохраняет задачу без необходимости решать её в постели.",
      explanation:
          "Бытовой шаг не заменяет лечение и не обещает исправить сон. При стойких трудностях и влиянии на день обратитесь за индивидуальной помощью.",
    ),
    en: TipCopy(
      "Park one evening task on paper",
      "When tomorrow’s tasks keep holding your attention.",
      task: "Write down one task and a time to return to it.",
      steps: [
        "Name a specific unfinished task.",
        "Leave a short note and set it aside until the chosen time.",
      ],
      example: "“Check the shopping list after breakfast tomorrow.”",
      alternative: "Make a spoken agreement with someone instead of writing.",
      doneWhen: "One task has a clear next moment.",
      why:
          "A note keeps the task available without needing to solve it in bed.",
      explanation:
          "An everyday step does not replace treatment or promise to fix sleep. Seek individual help for persistent difficulties affecting your day.",
    ),
  ),

  DailyTip(
    id: "rest-night-clock",
    topic: "rest-night-clock",
    category: TipCategory.recovery,
    version: 5,
    sourceIds: ["nhs-sleep"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Меньше проверок часов ночью",
      "Если постоянный взгляд на часы усиливает напряжение.",
      task: "Уберите часы из прямого поля зрения, сохранив нужный будильник.",
      steps: [
        "Проверьте, что сигнал и важная связь останутся доступны.",
        "Поверните часы или положите телефон экраном вниз в безопасном месте.",
      ],
      example: "Будильник работает, но циферблат не виден с подушки.",
      alternative:
          "Оставьте нужные медицинские устройства и сигналы как назначено.",
      doneWhen: "Часы меньше привлекают внимание без потери нужных сигналов.",
      why:
          "Это уменьшает один повод проверять время; эффект на сон не гарантируется.",
      explanation:
          "Бытовой шаг не заменяет лечение и не обещает исправить сон. При стойких трудностях и влиянии на день обратитесь за индивидуальной помощью.",
    ),
    en: TipCopy(
      "Reduce night-time clock checking",
      "When repeatedly checking the time adds tension.",
      task: "Move the clock out of direct view while keeping needed alarms.",
      steps: [
        "Check that alarms and important contact remain available.",
        "Turn the clock or place the phone face down safely.",
      ],
      example:
          "An alarm still works but the display is not visible from the pillow.",
      alternative: "Keep required medical devices and alerts as directed.",
      doneWhen: "The clock draws less attention without losing needed alerts.",
      why:
          "This removes one cue to check the time; a sleep benefit is not guaranteed.",
      explanation:
          "An everyday step does not replace treatment or promise to fix sleep. Seek individual help for persistent difficulties affecting your day.",
    ),
  ),

  DailyTip(
    id: "rest-share-quiet",
    topic: "rest-environment",
    category: TipCategory.recovery,
    version: 5,
    sourceIds: ["nhs-sleep"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Договоритесь о тихом времени дома",
      "Если сон зависит от общего пространства.",
      task: "Обсудите одну посильную договорённость о шуме или свете.",
      steps: [
        "Назовите конкретный мешающий источник без обвинений.",
        "Предложите удобный обоим вариант на ближайший вечер.",
      ],
      example:
          "Наушники для вечернего просмотра, если это безопасно и подходит.",
      alternative:
          "Выберите собственный доступный угол, если договориться сейчас нельзя.",
      doneWhen: "Одна договорённость или доступная личная мера выбрана.",
      why:
          "Общее пространство требует согласования, а не идеального контроля над комнатой.",
      explanation:
          "Бытовой шаг не заменяет лечение и не обещает исправить сон. При стойких трудностях и влиянии на день обратитесь за индивидуальной помощью.",
    ),
    en: TipCopy(
      "Agree a quieter time at home",
      "When sleep depends on shared space.",
      task: "Discuss one workable agreement about noise or light.",
      steps: [
        "Name a particular disturbance without blame.",
        "Suggest an option that works for both people tonight.",
      ],
      example: "Headphones for evening viewing if safe and suitable.",
      alternative:
          "Choose a personal accessible area if agreement is not possible now.",
      doneWhen: "One agreement or manageable personal step is chosen.",
      why:
          "Shared space needs cooperation rather than perfect control of a room.",
      explanation:
          "An everyday step does not replace treatment or promise to fix sleep. Seek individual help for persistent difficulties affecting your day.",
    ),
  ),

  DailyTip(
    id: "water-cup-volume",
    topic: "water-log-review",
    category: TipCategory.hydration,
    version: 5,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Узнайте объём привычной чашки",
      "Если хотите удобнее записывать воду.",
      task: "Один раз определите объём чашки доступным способом.",
      steps: [
        "Посмотрите маркировку или используйте подходящую мерную ёмкость.",
        "Запомните объём для будущих известных записей, не восстанавливая прошлое наугад.",
      ],
      example: "Отметить вместимость привычной чашки по мерной ёмкости.",
      alternative: "Оставьте приблизительную запись, если измерить нечем.",
      doneWhen: "Объём известен или честно оставлен приблизительным.",
      why:
          "Понятная ёмкость упрощает будущую запись без требования точно помнить прошлое.",
      explanation:
          "Потребности в жидкости различаются. Назначенные ограничения важнее шкалы приложения; не нужно допивать через дискомфорт.",
    ),
    en: TipCopy(
      "Learn your usual cup’s volume",
      "To make water logging more convenient.",
      task: "Determine the cup’s volume once using an available method.",
      steps: [
        "Check a volume marking or use a suitable measuring jug.",
        "Keep the amount for future known entries without inventing past intake.",
      ],
      example: "Check a familiar cup against a measuring jug.",
      alternative: "Keep an approximate entry if measurement is unavailable.",
      doneWhen: "The volume is known or honestly approximate.",
      why:
          "A known container simplifies future logging without requiring perfect memory.",
      explanation:
          "Fluid needs vary. Prescribed restrictions take priority over the app ring; do not force drinking through discomfort.",
    ),
  ),

  DailyTip(
    id: "water-clean-bottle",
    topic: "water-clean-bottle",
    category: TipCategory.hydration,
    version: 5,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Подготовьте чистую бутылку",
      "Если пользуетесь многоразовой ёмкостью.",
      task: "Очистите бутылку способом, разрешённым производителем.",
      steps: [
        "Проверьте инструкцию для корпуса, крышки и деталей.",
        "Вымойте, высушите и соберите перед следующим использованием.",
      ],
      example: "Снять разрешённые детали крышки и промыть по инструкции.",
      alternative: "Используйте другую чистую подходящую ёмкость.",
      doneWhen: "Есть чистая подходящая ёмкость для следующего использования.",
      why: "Удобство питья включает уход за самой ёмкостью.",
      explanation:
          "Потребности в жидкости различаются. Назначенные ограничения важнее шкалы приложения; не нужно допивать через дискомфорт.",
    ),
    en: TipCopy(
      "Prepare a clean bottle",
      "When using a reusable container.",
      task: "Clean the bottle using its manufacturer’s instructions.",
      steps: [
        "Check directions for the body, lid and removable parts.",
        "Wash, dry and reassemble before the next use.",
      ],
      example: "Remove permitted lid parts and clean as directed.",
      alternative: "Use another clean suitable container.",
      doneWhen: "A clean suitable container is ready.",
      why: "Convenient drinking includes maintaining the container itself.",
      explanation:
          "Fluid needs vary. Prescribed restrictions take priority over the app ring; do not force drinking through discomfort.",
    ),
  ),

  DailyTip(
    id: "water-drink-access-home",
    topic: "water-drink-access-home",
    category: TipCategory.hydration,
    version: 5,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Сделайте напиток доступным дома",
      "Если трудно дотянуться до привычного места.",
      task: "Разместите подходящий напиток и ёмкость в доступном месте.",
      steps: [
        "Выберите устойчивую поверхность по своим возможностям.",
        "Учитывайте назначенные ограничения жидкости и безопасность рядом с техникой.",
      ],
      example: "Закрытая удобная бутылка на доступном столике.",
      alternative:
          "Попросите помочь с размещением или используйте лёгкую чашку.",
      doneWhen: "Доступ к напитку стал удобнее без обязательного объёма.",
      why: "Организация доступа полезнее требования выпить больше любой ценой.",
      explanation:
          "Потребности в жидкости различаются. Назначенные ограничения важнее шкалы приложения; не нужно допивать через дискомфорт.",
    ),
    en: TipCopy(
      "Make a drink accessible at home",
      "When the usual location is hard to reach.",
      task: "Place a suitable drink and container within comfortable reach.",
      steps: [
        "Choose a stable surface for your abilities.",
        "Respect prescribed fluid limits and safety near electronics.",
      ],
      example: "An easy-to-use closed bottle on an accessible side table.",
      alternative: "Ask for help placing it or use a light cup.",
      doneWhen: "Drink access is easier without a required volume.",
      why:
          "Improving access is more useful than requiring extra fluid at any cost.",
      explanation:
          "Fluid needs vary. Prescribed restrictions take priority over the app ring; do not force drinking through discomfort.",
    ),
  ),

  DailyTip(
    id: "water-container-grip",
    topic: "drink-container-access",
    category: TipCategory.hydration,
    version: 5,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Ёмкость, которую удобно удержать",
      "Если тяжёлую бутылку неудобно поднимать.",
      task: "Выберите лёгкую подходящую ёмкость с удобным захватом.",
      steps: [
        "Проверьте устойчивость и возможность удержать пустую ёмкость.",
        "Добавьте комфортный объём без требования заполнить её целиком.",
      ],
      example:
          "Небольшая чашка с удобной ручкой вместо тяжёлой полной бутылки.",
      alternative:
          "Попросите помочь подобрать или разместить подходящую ёмкость.",
      doneWhen:
          "Есть ёмкость, которую удобно использовать с учётом возможностей.",
      why:
          "Удобный захват решает другую задачу, чем увеличение количества выпитого.",
      explanation:
          "Учитывайте инструкции, свои ограничения и безопасные условия. Это бытовой пример без расчёта личной нормы.",
    ),
    en: TipCopy(
      "A container that is comfortable to hold",
      "When a heavy bottle is difficult to lift.",
      task: "Choose a light suitable container with a comfortable grip.",
      steps: [
        "Check stability and whether you can hold it empty.",
        "Add a manageable amount without needing to fill it completely.",
      ],
      example:
          "A small cup with a comfortable handle instead of a heavy full bottle.",
      alternative: "Ask for help choosing or placing a suitable container.",
      doneWhen: "A container is convenient for your abilities.",
      why:
          "A comfortable grip solves an access problem rather than increasing fluid intake.",
      explanation:
          "Follow instructions, your restrictions and safe conditions. This is an everyday example without a prescribed personal target.",
    ),
  ),

  DailyTip(
    id: "water-drink-temperature",
    topic: "water-drink-temperature",
    category: TipCategory.hydration,
    version: 5,
    sourceIds: ["cdc-water"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Выберите комфортную температуру напитка",
      "Если слишком холодный или горячий напиток вам неудобен.",
      task: "Подберите комфортную температуру подходящего напитка.",
      steps: [
        "Дайте горячему остыть или выберите воду другой температуры.",
        "Проверьте удобство небольшим осторожным глотком, не заставляя себя допивать.",
      ],
      example: "Вода комнатной температуры вместо ледяной, если так приятнее.",
      alternative:
          "При назначенных требованиях к питью следуйте индивидуальным указаниям.",
      doneWhen: "Выбрана комфортная и безопасная температура.",
      why:
          "Предпочтение температуры может сделать обычный напиток удобнее без обещаний изменить обмен веществ.",
      explanation:
          "Потребности в жидкости различаются. Назначенные ограничения важнее шкалы приложения; не нужно допивать через дискомфорт.",
    ),
    en: TipCopy(
      "Choose a comfortable drink temperature",
      "When very cold or hot drinks feel unpleasant.",
      task: "Choose a comfortable temperature for a suitable drink.",
      steps: [
        "Let a hot drink cool or choose water at another temperature.",
        "Try a cautious small sip without making yourself finish it.",
      ],
      example: "Room-temperature water instead of iced water if preferred.",
      alternative: "Follow any individual prescribed drinking requirements.",
      doneWhen: "A comfortable safe temperature is chosen.",
      why:
          "Temperature preference can make a drink more convenient without claims about metabolism.",
      explanation:
          "Fluid needs vary. Prescribed restrictions take priority over the app ring; do not force drinking through discomfort.",
    ),
  ),

  DailyTip(
    id: "record-weight-typo",
    topic: "measurement-entry-check",
    category: TipCategory.progress,
    version: 5,
    sourceIds: ["nhs-weigh"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Проверьте явную опечатку веса",
      "Если сохранённое число не совпадает с тем, что вы точно записали.",
      task:
          "Сверьте одну подозрительную запись с известным исходным значением.",
      steps: [
        "Найдите надёжную запись или показание, которое сохранили.",
        "Исправьте только подтверждённую ошибку, не подгоняйте график.",
      ],
      example:
          "При вводе перепутаны цифры, а фотография показания сохранилась.",
      alternative:
          "Если исходное значение неизвестно, не заменяйте его догадкой.",
      doneWhen:
          "Подтверждённая ошибка исправлена или неопределённость сохранена.",
      why:
          "Проверка ввода отличается от изменения реальных колебаний ради красивой линии.",
      explanation:
          "Используйте только известные сохранённые факты; пропуски не заполняйте догадками. Это не диагноз и не основание усиливать ограничение еды. Измерения и контроль можно отложить, если они вызывают тревогу.",
    ),
    en: TipCopy(
      "Check an obvious weight-entry typo",
      "When a saved number differs from a value you reliably recorded.",
      task: "Compare one suspect entry with its known original value.",
      steps: [
        "Find a reliable original note or saved reading.",
        "Correct only a confirmed error rather than smoothing the graph.",
      ],
      example:
          "Digits were transposed and a photo of the scale reading remains.",
      alternative:
          "If the original is unknown, do not replace it with a guess.",
      doneWhen: "A confirmed error is corrected or uncertainty retained.",
      why:
          "Checking entry errors differs from changing real fluctuations for a smoother line.",
      explanation:
          "Use only known recorded facts; do not fill gaps with guesses. This is not a diagnosis or a reason to restrict food further. Pause measurement or monitoring if it causes distress.",
    ),
  ),

  DailyTip(
    id: "record-weight-unit",
    topic: "measurement-entry-check",
    category: TipCategory.progress,
    version: 5,
    sourceIds: ["nhs-weigh"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Проверьте единицы перед вводом веса",
      "Если весы показывают другую единицу.",
      task: "Сверьте единицу на весах и в поле записи до сохранения.",
      steps: [
        "Посмотрите обозначение на устройстве и в приложении.",
        "Переключите весы на нужную единицу или используйте проверенный перевод.",
      ],
      example: "Не переносите значение в фунтах прямо в поле килограммов.",
      alternative:
          "Если значение уже неизвестно, оставьте запись непроверенной вместо догадки.",
      doneWhen: "Единицы согласованы для известного измерения.",
      why:
          "Проверка единиц предотвращает ошибку масштаба без изменения настоящего результата.",
      explanation:
          "Используйте только известные сохранённые факты; пропуски не заполняйте догадками. Это не диагноз и не основание усиливать ограничение еды. Измерения и контроль можно отложить, если они вызывают тревогу.",
    ),
    en: TipCopy(
      "Check weight units before entering",
      "When scales display another unit.",
      task: "Match the scale unit and entry field before saving.",
      steps: [
        "Read the device unit and the app field label.",
        "Switch the scale unit or use a verified conversion.",
      ],
      example: "Do not copy a pound value straight into a kilogram field.",
      alternative:
          "If the original value is unknown, retain uncertainty rather than guessing.",
      doneWhen: "Units agree for a known measurement.",
      why:
          "A unit check prevents a scale error without altering the real result.",
      explanation:
          "Use only known recorded facts; do not fill gaps with guesses. This is not a diagnosis or a reason to restrict food further. Pause measurement or monitoring if it causes distress.",
    ),
  ),

  DailyTip(
    id: "record-date-check",
    topic: "measurement-entry-check",
    category: TipCategory.progress,
    version: 5,
    sourceIds: ["nhs-weigh"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Дата старого измерения",
      "Если переносите известную запись из заметки.",
      task: "Поставьте фактическую дату измерения перед сохранением.",
      steps: [
        "Найдите дату в исходной заметке.",
        "Выберите её в форме, не используйте автоматически сегодняшний день.",
      ],
      example: "Измерение из понедельника добавить с датой понедельника.",
      alternative:
          "Если дата неизвестна, не создавайте фиктивную точку на графике.",
      doneWhen: "Известное измерение связано с настоящей датой.",
      why: "Динамика зависит от дат, а не только от набора чисел.",
      explanation:
          "Используйте только известные сохранённые факты; пропуски не заполняйте догадками. Это не диагноз и не основание усиливать ограничение еды. Измерения и контроль можно отложить, если они вызывают тревогу.",
    ),
    en: TipCopy(
      "Date a past measurement accurately",
      "When transferring a known reading from a note.",
      task: "Set the actual measurement date before saving.",
      steps: [
        "Find the date in the original note.",
        "Select that date rather than automatically using today.",
      ],
      example: "Enter Monday’s reading with Monday’s date.",
      alternative:
          "Do not create a dated graph point when the date is unknown.",
      doneWhen: "A known reading has its actual date.",
      why: "A trend depends on dates as well as the numbers.",
      explanation:
          "Use only known recorded facts; do not fill gaps with guesses. This is not a diagnosis or a reason to restrict food further. Pause measurement or monitoring if it causes distress.",
    ),
  ),

  DailyTip(
    id: "record-circumference-kind",
    topic: "record-circumference-kind",
    category: TipCategory.progress,
    version: 5,
    sourceIds: ["nhs-weigh"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Не перепутайте обхваты в форме",
      "Если вносите грудь, талию и бёдра.",
      task: "Сверьте название каждого поля с известным замером.",
      steps: [
        "Прочитайте подписи полей перед вводом.",
        "Внесите только реально измеренные значения, остальные оставьте пустыми.",
      ],
      example: "Измерена талия — заполнить талию, не копировать число в бёдра.",
      alternative:
          "Сохраните только доступный замер; полный набор не обязателен.",
      doneWhen: "Каждое введённое значение соответствует своему обхвату.",
      why:
          "Разные места измерения остаются разными рядами, без заполнения пропусков.",
      explanation:
          "Используйте только известные сохранённые факты; пропуски не заполняйте догадками. Это не диагноз и не основание усиливать ограничение еды. Измерения и контроль можно отложить, если они вызывают тревогу.",
    ),
    en: TipCopy(
      "Keep circumference fields distinct",
      "When entering chest, waist and hips.",
      task: "Match each field label with the known measurement.",
      steps: [
        "Read the labels before entering values.",
        "Enter only actual measurements, leaving others empty.",
      ],
      example: "Only waist measured? Fill waist without copying it into hips.",
      alternative:
          "Keep only the available measurement; a full set is optional.",
      doneWhen: "Every entered value matches its circumference field.",
      why:
          "Different sites remain separate series without filling missing observations.",
      explanation:
          "Use only known recorded facts; do not fill gaps with guesses. This is not a diagnosis or a reason to restrict food further. Pause measurement or monitoring if it causes distress.",
    ),
  ),

  DailyTip(
    id: "record-gap-display",
    topic: "record-gap-display",
    category: TipCategory.progress,
    version: 5,
    sourceIds: ["nhs-weigh"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Отличите линию графика от измерений",
      "Если на графике видны соединённые участки без записей.",
      task:
          "Найдите реальные точки по датам, прежде чем оценивать длинный промежуток.",
      steps: [
        "Откройте историю измерений.",
        "Сравните даты записей с соединяющей линией, не считайте её ежедневными замерами.",
      ],
      example:
          "Между двумя записями за месяц линия не доказывает равномерное изменение каждый день.",
      alternative:
          "При большом промежутке оставьте динамику внутри него неизвестной.",
      doneWhen: "Реальные даты отделены от визуального соединения.",
      why: "Визуальная линия не добавляет новых сохранённых наблюдений.",
      explanation:
          "Используйте только известные сохранённые факты; пропуски не заполняйте догадками. Это не диагноз и не основание усиливать ограничение еды. Измерения и контроль можно отложить, если они вызывают тревогу.",
    ),
    en: TipCopy(
      "Distinguish graph lines from readings",
      "When a graph connects periods without entries.",
      task: "Find actual dated points before assessing a long interval.",
      steps: [
        "Open the measurement history.",
        "Compare entry dates with the connecting line rather than treating it as daily readings.",
      ],
      example:
          "A line between two monthly entries does not prove even daily change.",
      alternative: "Leave changes within a long gap unknown.",
      doneWhen: "Actual dates are separated from the visual connection.",
      why: "A drawn line does not create new saved observations.",
      explanation:
          "Use only known recorded facts; do not fill gaps with guesses. This is not a diagnosis or a reason to restrict food further. Pause measurement or monitoring if it causes distress.",
    ),
  ),

  DailyTip(
    id: "record-forecast-boundary",
    topic: "record-forecast-boundary",
    category: TipCategory.progress,
    version: 5,
    sourceIds: ["nhs-weigh", "niddk-planner"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Прогноз отдельно от фактов",
      "Если смотрите на ожидаемую дату достижения цели.",
      task: "Сначала проверьте реальные измерения, затем условный прогноз.",
      steps: [
        "Найдите границу фактических точек и прогноза.",
        "Не используйте ожидаемую дату как срок для ужесточения еды.",
      ],
      example:
          "Прогноз сдвинулся после нового измерения — это обновление оценки, а не провал.",
      alternative: "Если прогноз тревожит, остановитесь на реальной истории.",
      doneWhen: "Ожидаемая дата рассматривается как условная оценка.",
      why:
          "Расчётная линия не является обещанием и не объясняет причины изменения веса.",
      explanation:
          "Используйте только известные сохранённые факты; пропуски не заполняйте догадками. Это не диагноз и не основание усиливать ограничение еды. Измерения и контроль можно отложить, если они вызывают тревогу.",
    ),
    en: TipCopy(
      "Keep forecasts separate from facts",
      "When looking at an estimated goal date.",
      task: "Check actual readings before considering a conditional forecast.",
      steps: [
        "Find where recorded points end and the forecast begins.",
        "Do not use the estimate as a deadline for restricting food.",
      ],
      example:
          "A date shifts after a new reading: an updated estimate rather than failure.",
      alternative: "If forecasts cause distress, use only the actual history.",
      doneWhen: "The estimated date is treated as conditional.",
      why:
          "A calculated line is not a promise or an explanation of weight change.",
      explanation:
          "Use only known recorded facts; do not fill gaps with guesses. This is not a diagnosis or a reason to restrict food further. Pause measurement or monitoring if it causes distress.",
    ),
  ),

  DailyTip(
    id: "record-process-progress",
    topic: "record-process-progress",
    category: TipCategory.progress,
    version: 5,
    sourceIds: ["cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Отметьте практический результат вне весов",
      "Если хотите оценить полезность своей организации дня.",
      task: "Назовите один наблюдаемый бытовой результат.",
      steps: [
        "Выберите действие, которое действительно произошло.",
        "Запишите результат без требования подтвердить его снижением веса.",
      ],
      example:
          "«Два раза был готов удобный обед» вместо «цифра обязана уменьшиться».",
      alternative:
          "Можно просто заметить результат без ведения ещё одного трекера.",
      doneWhen: "Назван конкретный произошедший результат.",
      why:
          "Удобство еды и повседневных действий можно оценивать независимо от краткого колебания веса.",
      explanation:
          "Используйте только известные сохранённые факты; пропуски не заполняйте догадками. Это не диагноз и не основание усиливать ограничение еды. Измерения и контроль можно отложить, если они вызывают тревогу.",
    ),
    en: TipCopy(
      "Notice practical progress beyond weight",
      "To assess how your daily organisation helps.",
      task: "Name one observable everyday result.",
      steps: [
        "Choose something that actually happened.",
        "Record the result without requiring a weight decrease to validate it.",
      ],
      example:
          "“A convenient lunch was ready twice” instead of “the number must fall”.",
      alternative: "Simply notice it without starting another tracker.",
      doneWhen: "A particular result that happened is named.",
      why:
          "Food convenience and daily actions can be assessed separately from short-term weight changes.",
      explanation:
          "Use only known recorded facts; do not fill gaps with guesses. This is not a diagnosis or a reason to restrict food further. Pause measurement or monitoring if it causes distress.",
    ),
  ),

  DailyTip(
    id: "record-sharing-summary",
    topic: "professional-support",
    category: TipCategory.progress,
    version: 5,
    sourceIds: ["nhs-weigh", "cdc-habits"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Краткая сводка к консультации",
      "Если хотите обсудить наблюдения со специалистом.",
      task: "Подготовьте короткую сводку фактов и один вопрос.",
      steps: [
        "Укажите период, известные измерения и пробелы, если они есть.",
        "Отделите наблюдаемое от предположений и запишите вопрос.",
      ],
      example:
          "«За три недели есть такие даты; часть дней без записей. Что нужно уточнить?»",
      alternative: "Покажите историю на экране без создания отдельного файла.",
      doneWhen:
          "Есть сводка известных фактов и вопрос без самостоятельного диагноза.",
      why: "Краткие факты помогают обсуждению, а пропуски остаются видимыми.",
      explanation:
          "Используйте только известные сохранённые факты; пропуски не заполняйте догадками. Это не диагноз и не основание усиливать ограничение еды. Измерения и контроль можно отложить, если они вызывают тревогу.",
    ),
    en: TipCopy(
      "Prepare a short consultation summary",
      "When discussing observations with a professional.",
      task: "Prepare a short factual summary and one question.",
      steps: [
        "Note the period, known readings and any gaps.",
        "Separate observations from guesses and write a question.",
      ],
      example:
          "“These dates cover three weeks, with missing days. What should we clarify?”",
      alternative: "Show the history on screen without creating another file.",
      doneWhen:
          "Known facts and a question are ready without a self-diagnosis.",
      why:
          "A brief factual summary supports discussion while keeping gaps visible.",
      explanation:
          "Use only known recorded facts; do not fill gaps with guesses. This is not a diagnosis or a reason to restrict food further. Pause measurement or monitoring if it causes distress.",
    ),
  ),

  DailyTip(
    id: "kitchen-clean-hands",
    topic: "kitchen-clean-hands",
    category: TipCategory.nutrition,
    version: 5,
    sourceIds: ["fsa-cooking"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Чистые руки перед подготовкой еды",
      "Если переходите от других дел к готовке.",
      task:
          "Вымойте руки перед работой с едой и после контакта с сырыми продуктами.",
      steps: [
        "Подготовьте доступ к воде, мылу и чистому способу высушить руки.",
        "Не переходите от сырого мяса к готовой еде без мытья рук.",
      ],
      example: "После сырой курицы вымыть руки перед приготовлением салата.",
      alternative:
          "Если безопасные условия недоступны, выберите другой доступный способ получения готовой еды.",
      doneWhen: "Подготовка еды включает мытьё рук в нужные моменты.",
      why:
          "Чистые руки помогают не переносить загрязнение на готовые продукты.",
      explanation:
          "Идея блюда — пример без расчёта КБЖУ. Учитывайте аллергии, переносимость, свой лечебный план и инструкции приготовления и хранения.",
    ),
    en: TipCopy(
      "Clean hands before preparing food",
      "When switching from other tasks to cooking.",
      task:
          "Wash hands before handling food and after contact with raw ingredients.",
      steps: [
        "Arrange access to water, soap and a clean way to dry hands.",
        "Do not handle ready-to-eat food after raw meat without washing hands.",
      ],
      example: "Wash hands after raw chicken before making a salad.",
      alternative:
          "If safe facilities are unavailable, choose another accessible way to obtain prepared food.",
      doneWhen:
          "Food preparation includes handwashing at the necessary points.",
      why:
          "Clean hands help avoid transferring contamination to ready-to-eat food.",
      explanation:
          "This meal idea is illustrative, without calculated nutrients. Respect allergies, tolerance, your care plan, and preparation and storage directions.",
    ),
  ),

  DailyTip(
    id: "kitchen-date-meaning",
    topic: "kitchen-date-meaning",
    category: TipCategory.facts,
    version: 5,
    sourceIds: ["gov-food-dates"],
    evidenceLevel: TipEvidenceLevel.practicalIdea,
    ru: TipCopy(
      "Поймите смысл даты на импортной упаковке",
      "Если на упаковке указано use by или best before.",
      task:
          "Различите срок безопасности и срок качества перед использованием продукта.",
      steps: [
        "Use by относится к безопасности, best before — к качеству.",
        "Соблюдайте хранение и указания после открытия; не определяйте безопасность продукта после use by по запаху.",
      ],
      example:
          "На импортном готовом салате проверить use by и условия охлаждения.",
      alternative:
          "Для другой маркировки следуйте местным указаниям и инструкции производителя; при сомнении уточните значение.",
      doneWhen: "Тип даты и условия хранения понятны.",
      why:
          "Одинаково выглядящие даты могут обозначать разные ограничения; запах не подтверждает безопасность.",
      explanation:
          "Сравнение продуктов не назначает личную норму. Учитывайте аллергию, переносимость и назначенную диету.",
    ),
    en: TipCopy(
      "Understand dates on an imported food label",
      "When a label says use by or best before.",
      task:
          "Distinguish a safety date from a quality date before using the food.",
      steps: [
        "Use by concerns safety; best before concerns quality.",
        "Follow storage and after-opening directions; smell does not establish safety after use by.",
      ],
      example:
          "Check the use-by date and chilled storage for a prepared salad.",
      alternative:
          "For other labelling, follow local guidance and manufacturer instructions; clarify uncertainty.",
      doneWhen: "The date type and storage instructions are understood.",
      why:
          "Similar-looking dates can mean different limits; smell does not confirm safety.",
      explanation:
          "Food comparisons do not prescribe a personal target. Respect allergies, tolerance and prescribed diets.",
    ),
  ),
];

const retiredDailyTips = <DailyTip>[
  DailyTip(
    id: "macros-02",
    retired: true,
    canonicalId: "meal-lunch",
    topic: "meal-building",
    destination: TipDestination.food,
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Дополните гарнир вместо запрета",
      "Хлеб, рис или картофель могут остаться в меню.",
      task:
          "Добавьте к привычному гарниру овощи и подходящий белковый продукт.",
      steps: [
        "Выберите гарнир, который вам нравится.",
        "Добавьте два подходящих компонента без обязательных пропорций.",
      ],
      example: "Картофель + рыба + капуста; рис + фасоль + овощи.",
      alternative: "Если нет времени, подойдут готовые подходящие компоненты.",
      doneWhen: "Составлен один приём пищи с привычным гарниром.",
      why:
          "Так проще сочетать разные группы пищи, не запрещая углеводы целиком.",
      explanation:
          "Важны весь рацион и подходящие порции, а не запрет группы продуктов. Цельнозерновые варианты и бобовые дают клетчатку. Хлеб, картофель, рис, паста и фрукты могут оставаться в меню.",
    ),
    en: TipCopy(
      "Complete a side rather than banning it",
      "Bread, rice or potatoes can stay on the menu.",
      task: "Add vegetables and a suitable protein food to a familiar side.",
      steps: [
        "Choose a side you enjoy.",
        "Add two suitable components without compulsory ratios.",
      ],
      example: "Potato + fish + cabbage; rice + beans + vegetables.",
      alternative: "Use suitable ready-made components when time is short.",
      doneWhen: "One meal includes a familiar side with additions.",
      why:
          "This combines food groups without banning carbohydrates altogether.",
      explanation:
          "The whole eating pattern and suitable portions matter more than banning a food group. Whole grains and pulses supply fibre. Bread, potatoes, rice, pasta and fruit can remain on the menu.",
    ),
  ),
  DailyTip(
    id: "nutrition-09",
    retired: true,
    canonicalId: "today-15",
    topic: "backup-meal",
    destination: TipDestination.food,
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Соберите обед с фасолью без плиты",
      "Консервы могут стать основой обычного обеда.",
      task: "Соедините готовые бобовые, хлеб и овощи.",
      steps: [
        "Проверьте состав подходящей банки и подготовьте бобовые по упаковке.",
        "Добавьте хлеб, овощи и подходящую заправку.",
      ],
      example: "Фасоль + помидор + хлеб; нут + огурец + лепёшка.",
      alternative:
          "Нет бобовых — подойдут яйцо или готовая рыба, если подходят вам.",
      doneWhen: "Один вариант обеда собран; количества выбраны по потребности.",
      why:
          "Готовые продукты сокращают готовку и дают несколько групп пищи без сложного рецепта.",
      explanation:
          "Консервированные бобовые экономят время и позволяют добавить растительный белок. Сравните соль на этикетке, при желании промойте. Выбирайте продукт, который подходит вашим ограничениям.",
    ),
    en: TipCopy(
      "Build a no-stove bean lunch",
      "Canned foods can be the base of an ordinary lunch.",
      task: "Combine ready-cooked pulses, bread and vegetables.",
      steps: [
        "Check a suitable can and prepare the pulses as directed.",
        "Add bread, vegetables and a suitable dressing.",
      ],
      example: "Beans + tomato + bread; chickpeas + cucumber + flatbread.",
      alternative: "No pulses? Try egg or ready-to-eat fish if suitable.",
      doneWhen: "One lunch is assembled in amounts that suit your needs.",
      why:
          "Ready-to-eat foods save cooking and combine food groups without a complex recipe.",
      explanation:
          "Canned pulses save time and add a plant-protein option. Compare label sodium and rinse if desired. Choose a product compatible with your restrictions.",
    ),
  ),
  DailyTip(
    id: "activity-02",
    retired: true,
    canonicalId: "today-07",
    topic: "gentle-movement",
    destination: TipDestination.none,
    category: TipCategory.activity,
    basis: TipBasis.universal,
    sourceIds: ["niddk-eating"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Выберите доступное движение на паузу",
      "Способ зависит от возможностей и самочувствия сегодня.",
      task: "Попробуйте один комфортный вариант движения, если он безопасен.",
      steps: [
        "Выберите знакомое действие без цели по калориям.",
        "Остановитесь при боли, головокружении или другом дискомфорте.",
      ],
      example:
          "Короткая прогулка; движение на коляске; знакомые адаптированные движения.",
      alternative:
          "Если движение сейчас не подходит, выберите отдых или согласованный со специалистом вариант.",
      doneWhen:
          "Один безопасный вариант попробован или осознанно выбран отдых.",
      why:
          "Посильное движение можно включать в обычный день без обязательной интенсивной тренировки.",
      explanation:
          "Общая активность включает бытовое и адаптированное движение. Приложение не знает всей нагрузки по одному счётчику шагов. Выбирайте подходящий способ, а не обязательную тренировку.",
    ),
    en: TipCopy(
      "Choose an accessible movement break",
      "The option depends on your abilities and wellbeing today.",
      task: "Try one comfortable movement option if it is safe.",
      steps: [
        "Choose something familiar without a calorie goal.",
        "Stop for pain, dizziness or other discomfort.",
      ],
      example: "A short walk; wheeling; familiar adapted movement.",
      alternative:
          "If movement is unsuitable, choose rest or an agreed professional alternative.",
      doneWhen: "One safe option is tried or rest is deliberately chosen.",
      why:
          "Accessible movement can fit an ordinary day without a compulsory intense workout.",
      explanation:
          "Activity includes household tasks and adapted movement. A step counter does not capture all effort. Choose a suitable option rather than a compulsory workout.",
    ),
  ),
  DailyTip(
    id: "food-fibre",
    retired: true,
    canonicalId: "nutrition-01",
    topic: "vegetable-addition",
    destination: TipDestination.food,
    category: TipCategory.macros,
    basis: TipBasis.universal,
    sourceIds: ["nhs-fibre"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Добавьте привычный источник клетчатки",
      "Начните с переносимого продукта, а не обязательных отрубей.",
      task: "Дополните один приём пищи подходящим растительным продуктом.",
      steps: [
        "Выберите привычный овощ, фрукт, овсянку или бобовые.",
        "Непривычное добавляйте постепенно, соблюдая лечебные ограничения.",
      ],
      example:
          "Яблоко к овсянке; немного фасоли к рису; овощи к привычному обеду.",
      alternative:
          "При назначенной низковолокнистой диете не меняйте её самостоятельно — уточните подходящий вариант.",
      doneWhen: "Один переносимый вариант выбран или уточнён со специалистом.",
      why:
          "Разные растительные продукты дают клетчатку; одна небольшая проба конкретнее общего требования есть полезнее.",
      explanation:
          "Овощи, овсянка, цельнозерновой хлеб и бобовые — разные варианты. Вводите непривычные продукты постепенно. При заболеваниях ЖКТ и лечебной диете согласуйте изменения.",
    ),
    en: TipCopy(
      "Add a familiar fibre source",
      "Start with a tolerated food rather than compulsory bran.",
      task: "Add a suitable plant food to one meal.",
      steps: [
        "Choose familiar vegetables, fruit, oats or pulses.",
        "Introduce unfamiliar foods gradually within clinical restrictions.",
      ],
      example:
          "Apple with oats; a little bean with rice; vegetables with a usual lunch.",
      alternative:
          "Do not independently change a prescribed low-fibre diet; clarify a suitable option.",
      doneWhen:
          "One tolerated option is chosen or checked with a professional.",
      why:
          "Plant foods supply fibre; one manageable trial is more concrete than a general healthy-eating instruction.",
      explanation:
          "Vegetables, oats, wholegrain bread and pulses offer different choices. Introduce unfamiliar foods gradually. Discuss changes if you have digestive conditions or a clinical diet.",
    ),
  ),
  DailyTip(
    id: "meal-dinner",
    retired: true,
    canonicalId: "meal-lunch",
    topic: "meal-building",
    destination: TipDestination.food,
    category: TipCategory.nutrition,
    basis: TipBasis.universal,
    sourceIds: ["cdc-eating", "who-diet"],
    evidenceLevel: TipEvidenceLevel.guidance,
    ru: TipCopy(
      "Выберите ужин с короткой подготовкой",
      "С готовыми компонентами можно ориентироваться на 10–20 минут; время зависит от продукта.",
      task: "Соберите простой ужин, сохранив привычный гарнир.",
      steps: [
        "Выберите готовый гарнир или продукт с подходящим временем по упаковке.",
        "Добавьте овощи и готовые бобовые либо тофу, соблюдая инструкцию.",
      ],
      example: "Готовый рис + овощи + фасоль; паста + томатный соус + тофу.",
      alternative: "Без плиты — хлеб с фасолевой намазкой и овощами.",
      doneWhen:
          "Один вариант приготовлен или выбран с учётом доступного времени.",
      why:
          "Готовые компоненты сокращают подготовку; гарнир вечером не требуется запрещать. Это идея еды, не точные КБЖУ.",
      explanation:
          "Добавьте овощи и доступный источник белка, например фасоль, тофу или рыбу. Само наличие углеводов вечером не доказывает, что питание мешает снижению веса. Учитывайте свой режим и назначения.",
    ),
    en: TipCopy(
      "Choose a dinner with short preparation",
      "With ready components, 10–20 minutes may work; timing depends on the product.",
      task: "Build a simple dinner while keeping a familiar side.",
      steps: [
        "Choose a ready base or a product with suitable package timing.",
        "Add vegetables and ready-cooked pulses or tofu, following instructions.",
      ],
      example: "Ready rice + vegetables + beans; pasta + tomato sauce + tofu.",
      alternative:
          "Without a stove, try bread with bean spread and vegetables.",
      doneWhen: "One option is made or chosen to fit available time.",
      why:
          "Ready components reduce preparation; evening sides need not be banned. This is a meal idea, not exact nutrition.",
      explanation:
          "Add vegetables and an accessible protein source such as beans, tofu or fish. Evening carbohydrate alone does not establish a barrier to weight loss. Consider your routine and care plan.",
    ),
  ),
];

const preservedLegacyContent = <String, String>{
  "nutrition-08": "meal-dinner",
  "nutrition-14": "nutrition-09",
  "nutrition-17": "meal-dinner",
  "macros-06": "food-fibre",
  "macros-07": "food-fibre",
  "macros-09": "macros-02",
  "macros-14": "food-fibre",
  "macros-16": "macros-02",
  "activity-07": "activity-02",
  "activity-12": "activity-02",
  "activity-17": "activity-02",
  "facts-08": "macros-02",
  "facts-10": "food-fibre",
  "macros-17": "food-fibre",
  "facts-13": "food-fibre",
};

const legacyTipAliases = <String, String>{
  "nutrition-03": "food-protein",
  "nutrition-06": "meal-breakfast",
  "nutrition-07": "meal-lunch",
  "nutrition-08": "meal-lunch",
  "nutrition-10": "nutrition-01",
  "nutrition-11": "nutrition-02",
  "nutrition-12": "meal-lunch",
  "nutrition-13": "nutrition-05",
  "nutrition-14": "today-15",
  "nutrition-15": "meal-breakfast",
  "nutrition-16": "meal-lunch",
  "nutrition-17": "meal-lunch",
  "macros-05": "macros-13",
  "macros-06": "nutrition-01",
  "macros-07": "nutrition-01",
  "macros-08": "macros-01",
  "macros-09": "meal-lunch",
  "macros-10": "food-protein",
  "macros-11": "macros-04",
  "macros-12": "macros-13",
  "macros-14": "nutrition-01",
  "macros-15": "macros-01",
  "macros-16": "meal-lunch",
  "macros-18": "diary-low",
  "hydration-01": "hydration-03",
  "hydration-02": "hydration-05",
  "hydration-06": "hydration-03",
  "hydration-08": "hydration-07",
  "hydration-09": "hydration-18",
  "hydration-11": "hydration-03",
  "hydration-12": "hydration-05",
  "hydration-13": "hydration-07",
  "hydration-14": "hydration-04",
  "hydration-15": "hydration-18",
  "hydration-16": "hydration-03",
  "hydration-17": "hydration-05",
  "activity-05": "activity-18",
  "activity-06": "today-07",
  "activity-07": "today-07",
  "activity-08": "activity-03",
  "activity-09": "activity-18",
  "activity-10": "activity-18",
  "activity-11": "today-07",
  "activity-12": "today-07",
  "activity-14": "activity-context",
  "activity-15": "activity-18",
  "activity-16": "today-07",
  "activity-17": "today-07",
  "recovery-02": "recovery-04",
  "recovery-03": "recovery-06",
  "recovery-05": "recovery-01",
  "recovery-08": "recovery-stress",
  "recovery-09": "recovery-01",
  "recovery-10": "recovery-04",
  "recovery-11": "recovery-06",
  "recovery-12": "recovery-07",
  "recovery-13": "recovery-01",
  "recovery-14": "recovery-17",
  "recovery-16": "recovery-stress",
  "recovery-18": "recovery-04",
  "habits-02": "mindful-09",
  "habits-03": "today-15",
  "habits-05": "habits-15",
  "habits-07": "today-02",
  "habits-08": "mindful-09",
  "habits-09": "today-15",
  "habits-10": "meal-budget",
  "habits-11": "habits-15",
  "habits-12": "diary-additions",
  "habits-13": "today-02",
  "habits-17": "habits-15",
  "habits-18": "diary-additions",
  "mindful-01": "mindful-02",
  "mindful-04": "mindful-09",
  "mindful-05": "recovery-stress",
  "mindful-06": "care-context",
  "mindful-07": "mindful-02",
  "mindful-10": "mindful-09",
  "mindful-11": "recovery-stress",
  "mindful-13": "mindful-02",
  "mindful-14": "mindful-16",
  "mindful-15": "mindful-08",
  "mindful-17": "recovery-stress",
  "mindful-18": "care-context",
  "progress-03": "insight-down",
  "progress-04": "insight-short",
  "progress-05": "diary-gaps",
  "progress-06": "insight-short",
  "progress-07": "insight-down",
  "progress-09": "progress-02",
  "progress-10": "progress-02",
  "progress-11": "insight-short",
  "progress-14": "facts-18",
  "progress-15": "insight-short",
  "progress-17": "progress-08",
  "progress-18": "today-02",
  "facts-01": "hydration-05",
  "facts-02": "nutrition-02",
  "facts-03": "meal-budget",
  "facts-05": "macros-01",
  "facts-07": "facts-fluid",
  "facts-08": "meal-lunch",
  "facts-10": "nutrition-01",
  "facts-11": "care-context",
  "facts-12": "facts-06",
  "facts-14": "hydration-03",
  "facts-15": "facts-06",
  "facts-17": "macros-03",
  "today-01": "today-02",
  "today-04": "today-09",
  "today-05": "nutrition-01",
  "today-06": "today-15",
  "today-08": "today-03",
  "today-10": "today-09",
  "today-11": "nutrition-01",
  "today-12": "today-15",
  "today-14": "today-03",
  "today-16": "today-09",
  "today-17": "nutrition-01",
  "today-18": "today-15",
  "nutrition-04": "meal-lunch",
  "macros-17": "nutrition-01",
  "hydration-10": "hydration-18",
  "activity-01": "today-07",
  "activity-13": "activity-18",
  "recovery-15": "recovery-01",
  "habits-01": "today-02",
  "habits-04": "mindful-09",
  "habits-06": "today-15",
  "habits-14": "meal-budget",
  "mindful-03": "mindful-16",
  "mindful-12": "recovery-stress",
  "progress-01": "insight-down",
  "progress-12": "insight-short",
  "progress-13": "insight-body",
  "facts-13": "nutrition-01",
  "today-13": "nutrition-01",
  "insight-long": "care-context",
  "recovery-appetite": "recovery-stress",
  "nutrition-18": "diary-low",
  "macros-02": "meal-lunch",
  "nutrition-09": "today-15",
  "activity-02": "today-07",
  "food-fibre": "nutrition-01",
  "meal-dinner": "meal-lunch",
};
