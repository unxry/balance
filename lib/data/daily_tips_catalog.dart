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
    topic: "quick-dinner",
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
    id: "nutrition-09",
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
    id: "macros-02",
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
    topic: "yogurt-choice",
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
    id: "activity-02",
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
    topic: "movement-without-compensation",
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
    topic: "sleep-environment",
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
    topic: "recipe-uncertainty",
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
    id: "meal-dinner",
    topic: "quick-dinner",
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
    id: "food-fibre",
    topic: "fibre-addition",
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
    topic: "low-log-review",
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
];

const legacyTipAliases = <String, String>{
  "nutrition-03": "food-protein",
  "nutrition-06": "meal-breakfast",
  "nutrition-07": "meal-lunch",
  "nutrition-08": "meal-dinner",
  "nutrition-10": "nutrition-01",
  "nutrition-11": "nutrition-02",
  "nutrition-12": "meal-lunch",
  "nutrition-13": "nutrition-05",
  "nutrition-14": "nutrition-09",
  "nutrition-15": "meal-breakfast",
  "nutrition-16": "meal-lunch",
  "nutrition-17": "meal-dinner",
  "macros-05": "macros-13",
  "macros-06": "food-fibre",
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
  "activity-07": "activity-02",
  "activity-08": "activity-03",
  "activity-09": "activity-18",
  "activity-10": "activity-18",
  "activity-11": "today-07",
  "activity-12": "activity-02",
  "activity-14": "activity-context",
  "activity-15": "activity-18",
  "activity-16": "today-07",
  "activity-17": "activity-02",
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
  "facts-08": "macros-02",
  "facts-10": "food-fibre",
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
  "macros-17": "food-fibre",
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
  "facts-13": "food-fibre",
  "today-13": "nutrition-01",
  "insight-long": "care-context",
  "recovery-appetite": "recovery-stress",
  "nutrition-18": "diary-low",
};
