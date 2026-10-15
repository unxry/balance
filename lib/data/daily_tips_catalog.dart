import '../models/daily_tip.dart';

// Stable IDs are persisted in user history. Keep retired entries available.
const dailyTipsCatalog = <DailyTip>[
  DailyTip(
    id: "nutrition-01",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Тарелка с продолжением",
      "Добавьте к привычному блюду овощ, который вам нравится. Не нужно менять весь рацион за один день.",
      task: "Выберите одно дополнение к ужину.",
      why:
          "Разнообразие можно строить маленькими дополнениями к привычной еде.",
    ),
    en: TipCopy(
      "A plate with room to grow",
      "Add a vegetable you enjoy to a familiar meal. You do not need to change your whole diet today.",
      task: "Choose one addition to dinner.",
      why: "Small additions to familiar meals can build variety.",
    ),
  ),
  DailyTip(
    id: "nutrition-02",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Заморозка выручает",
      "Замороженные овощи удобно держать под рукой для супа, пасты или гарнира. Это полноценный вариант для занятого вечера.",
      task: "Проверьте, что есть в морозилке.",
    ),
    en: TipCopy(
      "Let the freezer help",
      "Keep frozen vegetables ready for soup, pasta or a side dish. They are a practical option on a busy evening.",
      task: "Check what is in your freezer.",
    ),
  ),
  DailyTip(
    id: "nutrition-03",
    category: TipCategory.nutrition,
    basis: TipBasis.food,
    ru: TipCopy(
      "Разнообразие без спешки",
      "Посмотрите на записи питания: какие продукты вам особенно нравились? Рядом с одним из них попробуйте новый ингредиент.",
      task: "Найдите в дневнике идею для следующего блюда.",
    ),
    en: TipCopy(
      "Variety at your own pace",
      "Look through your food log for foods you enjoyed. Try a new ingredient alongside one of those favourites.",
      task: "Find an idea for your next meal in your log.",
    ),
  ),
  DailyTip(
    id: "nutrition-04",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Обед из того, что есть",
      "Основа из крупы, овощей и удобного источника белка может стать простым обедом. Подойдут и остатки вчерашнего ужина.",
      task: "Соберите обед из доступных продуктов.",
    ),
    en: TipCopy(
      "Lunch from what you have",
      "Grains, vegetables and a convenient protein source can make a simple lunch. Leftovers from dinner can work too.",
      task: "Put together lunch with ingredients you have.",
    ),
  ),
  DailyTip(
    id: "nutrition-05",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Чечевица на пробу",
      "Красную чечевицу можно добавить в суп или соус. Начните с небольшого количества, если бобовые пока непривычны.",
      task: "Добавьте чечевицу в список покупок.",
    ),
    en: TipCopy(
      "Try lentils",
      "Red lentils can go into soup or sauce. Start with a little if pulses are new to you.",
      task: "Add lentils to your shopping list.",
    ),
  ),
  DailyTip(
    id: "nutrition-06",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Хрустящий акцент",
      "Морковь, огурец или капуста добавляют блюду другую текстуру. Иногда именно текстура делает привычный обед интереснее.",
      task: "Добавьте к блюду что-нибудь хрустящее.",
    ),
    en: TipCopy(
      "A little crunch",
      "Carrot, cucumber or cabbage adds a different texture. Sometimes texture makes a familiar lunch more enjoyable.",
      task: "Add something crunchy to a meal.",
    ),
  ),
  DailyTip(
    id: "nutrition-07",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Фрукты в удобном месте",
      "Вымойте фрукт перед тем, как взять его с собой. Когда перекус уже готов, легче вспомнить о нём в нужный момент.",
      task: "Подготовьте фрукт для сумки или рабочего стола.",
    ),
    en: TipCopy(
      "Fruit within reach",
      "Wash a piece of fruit before taking it with you. A ready snack is easier to remember when you need it.",
      task: "Prepare fruit for your bag or desk.",
    ),
  ),
  DailyTip(
    id: "nutrition-08",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Пробуем цельное зерно",
      "Перловка, булгур и овсянка дают разные вкусы и текстуры. Выберите одну крупу, которую давно не готовили.",
      task: "Найдите простой рецепт с новой крупой.",
    ),
    en: TipCopy(
      "Try a whole grain",
      "Barley, bulgur and oats offer different flavours and textures. Choose a grain you have not cooked recently.",
      task: "Find a simple recipe using a different grain.",
    ),
  ),
  DailyTip(
    id: "nutrition-09",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Консервы для буднего дня",
      "Фасоль или нут из банки можно промыть и добавить в салат. Полезный набор продуктов не обязан требовать долгой готовки.",
      task: "Соберите один быстрый вариант обеда.",
    ),
    en: TipCopy(
      "A cupboard shortcut",
      "Rinse canned beans or chickpeas and add them to a salad. A varied meal does not have to involve lengthy cooking.",
      task: "Put together one quick lunch option.",
    ),
  ),
  DailyTip(
    id: "nutrition-10",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Соус тоже часть блюда",
      "Йогурт с зеленью, лимонный сок или тахини могут по-новому раскрыть знакомые продукты. Вкус помогает получать удовольствие от еды.",
      task: "Попробуйте новую заправку.",
    ),
    en: TipCopy(
      "Make room for flavour",
      "Yogurt with herbs, lemon juice or tahini can give familiar foods a fresh flavour. Enjoyment belongs at the table too.",
      task: "Try a new dressing.",
    ),
  ),
  DailyTip(
    id: "nutrition-11",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Готовое тоже подходит",
      "В день без сил можно собрать еду из готового гарнира, овощей и подходящего вам белкового продукта. Удобство не делает еду плохой.",
      task: "Запишите свой вариант еды без готовки.",
    ),
    en: TipCopy(
      "Ready-made can work",
      "On a low-energy day, combine a ready-made side, vegetables and a protein food that suits you. Convenience does not make a meal bad.",
      task: "Write down a meal that needs no cooking.",
    ),
  ),
  DailyTip(
    id: "nutrition-12",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "План без жёсткого меню",
      "Выберите две идеи ужина и оставьте место для перемен. План должен помогать вам, а не требовать идеального исполнения.",
      task: "Наметьте два удобных ужина.",
    ),
    en: TipCopy(
      "A flexible meal plan",
      "Choose two dinner ideas and leave room for changes. A plan should help you, without demanding perfect execution.",
      task: "Sketch out two convenient dinners.",
    ),
  ),
  DailyTip(
    id: "nutrition-13",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Сезонный вкус",
      "На рынке или в магазине присмотритесь к сезонному овощу. Сравнивайте вкус и удобство, а не ищите единственный идеальный продукт.",
      task: "Выберите овощ по сезону.",
    ),
    en: TipCopy(
      "Taste the season",
      "Look for a seasonal vegetable when shopping. Explore taste and convenience rather than searching for one perfect food.",
      task: "Choose a seasonal vegetable.",
    ),
  ),
  DailyTip(
    id: "nutrition-14",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Пряности вместо скуки",
      "Копчёная паприка, укроп или тмин меняют характер блюда. Попробуйте одну приправу, чтобы понять, нравится ли вам сочетание.",
      task: "Добавьте новую пряность к знакомому блюду.",
    ),
    en: TipCopy(
      "Spice up a familiar meal",
      "Smoked paprika, dill or cumin can change a dish. Try one seasoning to discover whether you like the combination.",
      task: "Add a new seasoning to a familiar dish.",
    ),
  ),
  DailyTip(
    id: "nutrition-15",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Суп с опорой",
      "Если после лёгкого супа вы быстро голодны, к нему можно добавить хлеб, фасоль или другой сытный продукт. Еда должна подходить вашему аппетиту.",
      task: "Подумайте, чем дополнить любимый суп.",
    ),
    en: TipCopy(
      "A more substantial soup",
      "If a light soup leaves you hungry soon afterwards, add bread, beans or another substantial food. Let the meal suit your appetite.",
      task: "Think of an addition to your favourite soup.",
    ),
  ),
  DailyTip(
    id: "nutrition-16",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Мягкий старт с овощами",
      "Не все любят сырые овощи. Запекание, тушение и супы дают другие вкусы и могут оказаться приятнее.",
      task: "Выберите комфортный способ приготовления овощей.",
    ),
    en: TipCopy(
      "A gentle start with vegetables",
      "Raw vegetables are not for everyone. Roasting, simmering and soups offer different flavours you may prefer.",
      task: "Choose a way of preparing vegetables you enjoy.",
    ),
  ),
  DailyTip(
    id: "nutrition-17",
    category: TipCategory.nutrition,
    ru: TipCopy(
      "Еда в компании",
      "Попросите близкого человека поделиться простым любимым рецептом. Это способ расширить меню без поиска сложных правил питания.",
      task: "Узнайте один семейный рецепт.",
    ),
    en: TipCopy(
      "Share a meal idea",
      "Ask someone close to you for an easy favourite recipe. It is a way to broaden your menu without complicated food rules.",
      task: "Ask about one family recipe.",
    ),
  ),
  DailyTip(
    id: "nutrition-18",
    category: TipCategory.nutrition,
    basis: TipBasis.gentleFuel,
    ru: TipCopy(
      "Достаточно ли записано?",
      "В некоторые дни в дневнике мало еды. Запись может быть неполной: проверьте пропуски и позаботьтесь о регулярном питании без дополнительных ограничений.",
      task: "Спокойно проверьте полноту вчерашних записей.",
    ),
    en: TipCopy(
      "Is the log complete?",
      "Some days show little food in your diary. The log may be incomplete: check for missing entries and make room for regular meals without further restriction.",
      task: "Gently check whether yesterday's log is complete.",
    ),
  ),
  DailyTip(
    id: "macros-01",
    category: TipCategory.macros,
    ru: TipCopy(
      "Белок бывает разным",
      "Яйца, рыба, тофу, бобовые и кисломолочные продукты могут быть источниками белка. Выбирайте то, что доступно и подходит вам.",
      task: "Назовите три удобных для вас источника белка.",
    ),
    en: TipCopy(
      "Protein comes in many forms",
      "Eggs, fish, tofu, pulses and cultured dairy can provide protein. Choose options that are accessible and suit you.",
      task: "Name three protein foods that work for you.",
    ),
  ),
  DailyTip(
    id: "macros-02",
    category: TipCategory.macros,
    ru: TipCopy(
      "Углеводы дают энергию",
      "Хлеб, рис и картофель могут быть частью разнообразного питания. Их не нужно исключать только из-за названия группы нутриентов.",
    ),
    en: TipCopy(
      "Carbohydrates provide energy",
      "Bread, rice and potatoes can belong in a varied diet. There is no need to exclude them simply because they contain carbohydrates.",
    ),
  ),
  DailyTip(
    id: "macros-03",
    category: TipCategory.macros,
    ru: TipCopy(
      "Жиры тоже нужны",
      "Орехи, семена, масла и другие продукты с жирами могут входить в обычное меню. Не стремитесь сделать весь рацион обезжиренным.",
    ),
    en: TipCopy(
      "Fat has a place",
      "Nuts, seeds, oils and other foods containing fat can be part of everyday meals. Your whole diet does not need to be fat-free.",
    ),
  ),
  DailyTip(
    id: "macros-04",
    category: TipCategory.macros,
    ru: TipCopy(
      "Пара для перекуса",
      "Фрукт и йогурт или хлеб и хумус дают сочетание вкусов и нутриентов. Подбирайте перекус по аппетиту, а не по строгому шаблону.",
      task: "Придумайте свою пару для перекуса.",
    ),
    en: TipCopy(
      "A snack pairing",
      "Fruit with yogurt or bread with hummus brings together flavours and nutrients. Let appetite guide your snack rather than a rigid formula.",
      task: "Think of your own snack pairing.",
    ),
  ),
  DailyTip(
    id: "macros-05",
    category: TipCategory.macros,
    ru: TipCopy(
      "Тофу любит вкус",
      "Тофу можно запечь с любимыми специями или добавить в овощное рагу. Вкус часто зависит от приготовления, а не только от продукта.",
      task: "Найдите один способ приготовить тофу.",
    ),
    en: TipCopy(
      "Give tofu some flavour",
      "Bake tofu with favourite spices or add it to a vegetable stew. Preparation often matters as much as the ingredient.",
      task: "Find one way to prepare tofu.",
    ),
  ),
  DailyTip(
    id: "macros-06",
    category: TipCategory.macros,
    ru: TipCopy(
      "Завтрак с дополнением",
      "Если привычного завтрака вам мало, попробуйте добавить йогурт, яйцо или бобовую намазку. Ориентируйтесь на доступность и свои предпочтения.",
      task: "Выберите дополнение к завтраку.",
    ),
    en: TipCopy(
      "An addition to breakfast",
      "If your usual breakfast is not enough, try adding yogurt, an egg or a bean spread. Follow your preferences and what is available.",
      task: "Choose an addition to breakfast.",
    ),
  ),
  DailyTip(
    id: "macros-07",
    category: TipCategory.macros,
    ru: TipCopy(
      "Крупа плюс бобовые",
      "Рис с фасолью или гречка с чечевицей — простые сочетания для разнообразия. Необязательно собирать все нутриенты идеально в одном блюде.",
      task: "Сохраните одно сочетание на будущее.",
    ),
    en: TipCopy(
      "Grains meet pulses",
      "Rice with beans or buckwheat with lentils are simple ways to add variety. Every meal does not have to balance every nutrient perfectly.",
      task: "Save one combination for later.",
    ),
  ),
  DailyTip(
    id: "macros-08",
    category: TipCategory.macros,
    ru: TipCopy(
      "Рыба без сложного рецепта",
      "Запечённая рыба или подходящие консервы могут стать основой быстрого блюда. Учитывайте свои ограничения и рекомендации по безопасному выбору рыбы.",
      task: "Придумайте удобный гарнир к рыбе.",
    ),
    en: TipCopy(
      "Fish without a complicated recipe",
      "Baked fish or suitable canned fish can anchor a quick meal. Follow any personal restrictions and relevant fish safety guidance.",
      task: "Think of a convenient side for fish.",
    ),
  ),
  DailyTip(
    id: "macros-09",
    category: TipCategory.macros,
    ru: TipCopy(
      "Семечки как деталь",
      "Тыквенные или подсолнечные семечки добавляют каше и салату текстуру. Используйте их, если они подходят вам и нравятся на вкус.",
      task: "Попробуйте небольшое дополнение из семян.",
    ),
    en: TipCopy(
      "Seeds as a finishing touch",
      "Pumpkin or sunflower seeds add texture to porridge and salads. Use them if they suit you and you enjoy them.",
      task: "Try a small topping of seeds.",
    ),
  ),
  DailyTip(
    id: "macros-10",
    category: TipCategory.macros,
    basis: TipBasis.food,
    ru: TipCopy(
      "Не только куриная грудка",
      "Ваш дневник может подсказать, какой белковый продукт повторяется чаще всего. Для разнообразия выберите другой знакомый вариант.",
      task: "Сравните два дня питания без оценки «хорошо» или «плохо».",
    ),
    en: TipCopy(
      "Beyond chicken breast",
      "Your diary can show which protein food appears most often. Choose another familiar option for a little variety.",
      task: "Compare two logged days without labelling them good or bad.",
    ),
  ),
  DailyTip(
    id: "macros-11",
    category: TipCategory.macros,
    ru: TipCopy(
      "Читаем состав блюда",
      "Название «фитнес» мало говорит о составе еды. Смотрите на ингредиенты и порцию, а не только на крупную надпись на упаковке.",
      task: "Прочитайте состав привычного продукта.",
    ),
    en: TipCopy(
      "Look at the whole dish",
      "The word fitness says little about a food's ingredients. Look at what is in it and the serving information, beyond the headline on the pack.",
      task: "Read the ingredients of a familiar product.",
    ),
  ),
  DailyTip(
    id: "macros-12",
    category: TipCategory.macros,
    ru: TipCopy(
      "Макароны остаются макаронами",
      "К пасте можно добавить овощи и фасоль, рыбу или сыр. Вам не нужно отказываться от любимого блюда ради более разнообразной тарелки.",
      task: "Придумайте добавку к любимой пасте.",
    ),
    en: TipCopy(
      "Pasta belongs on the menu",
      "Add vegetables and beans, fish or cheese to pasta. You can keep a favourite dish while making the meal more varied.",
      task: "Think of an addition to your favourite pasta.",
    ),
  ),
  DailyTip(
    id: "macros-13",
    category: TipCategory.macros,
    ru: TipCopy(
      "Йогурт без обязательств",
      "Молочный или подходящий растительный йогурт можно сочетать с фруктами и овсяными хлопьями. Состав растительных вариантов отличается — смотрите этикетку.",
      task: "Посмотрите состав выбранного йогурта.",
    ),
    en: TipCopy(
      "Yogurt your way",
      "Pair dairy yogurt or a suitable plant alternative with fruit and oats. Plant-based options vary, so check the label.",
      task: "Look at the ingredients of your chosen yogurt.",
    ),
  ),
  DailyTip(
    id: "macros-14",
    category: TipCategory.macros,
    ru: TipCopy(
      "Порция не экзамен",
      "Баланс БЖУ удобнее рассматривать как ориентир, а не ежедневный экзамен на точность. Один приём пищи не описывает весь ваш рацион.",
    ),
    en: TipCopy(
      "A portion is not an exam",
      "Treat macro balance as a guide rather than a daily precision test. One meal does not describe your whole way of eating.",
    ),
  ),
  DailyTip(
    id: "macros-15",
    category: TipCategory.macros,
    ru: TipCopy(
      "Хумус для бутерброда",
      "Нутовую или фасолевую намазку удобно использовать в бутерброде вместе с овощами. Это ещё один вариант привычного перекуса.",
      task: "Попробуйте намазку из бобовых.",
    ),
    en: TipCopy(
      "Hummus for a sandwich",
      "Chickpea or bean spread works in a sandwich with vegetables. It offers another option for a familiar snack.",
      task: "Try a bean or chickpea spread.",
    ),
  ),
  DailyTip(
    id: "macros-16",
    category: TipCategory.macros,
    ru: TipCopy(
      "Орехи по вкусу",
      "Если у вас нет аллергии, орехи можно добавить к каше или взять с собой. Выбирайте вкус и форму, которые вам удобны.",
      task: "Подберите удобный вариант орехов или семян.",
    ),
    en: TipCopy(
      "Nuts you enjoy",
      "If you do not have an allergy, add nuts to porridge or take some with you. Choose a type and form you enjoy.",
      task: "Choose a convenient nut or seed option.",
    ),
  ),
  DailyTip(
    id: "macros-17",
    category: TipCategory.macros,
    ru: TipCopy(
      "Клетчатка постепенно",
      "Когда добавляете больше цельных круп и бобовых, двигайтесь постепенно. Резкая перемена привычного меню может быть некомфортной.",
    ),
    en: TipCopy(
      "Fibre at a comfortable pace",
      "Introduce more whole grains and pulses gradually. A sudden change from your usual meals may feel uncomfortable.",
    ),
  ),
  DailyTip(
    id: "macros-18",
    category: TipCategory.macros,
    basis: TipBasis.gentleFuel,
    ru: TipCopy(
      "Еда прежде точности",
      "Если записи часто заметно ниже вашей цели, не усиливайте ограничения ради красивых цифр. Проверьте полноту дневника и предусмотрите доступную еду на день.",
      task: "Подготовьте вариант полноценного приёма пищи.",
    ),
    en: TipCopy(
      "Food before perfect numbers",
      "If logs are often well below your target, do not add more restrictions to tidy up the numbers. Check the log is complete and plan accessible meals.",
      task: "Plan an accessible, substantial meal.",
    ),
  ),
  DailyTip(
    id: "hydration-01",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Вода на виду",
      "Поставьте воду там, где проводите время. Небольшое изменение окружения помогает вспомнить о питье без постоянных уведомлений.",
      task: "Поставьте стакан в удобное место.",
    ),
    en: TipCopy(
      "Water in sight",
      "Keep water where you spend time. A small change in your surroundings can remind you to drink without constant alerts.",
      task: "Place a glass somewhere convenient.",
    ),
  ),
  DailyTip(
    id: "hydration-02",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Ваш ритм питья",
      "Пейте в удобные моменты в течение дня. Не нужно наверстывать дневную отметку большим количеством воды за один раз.",
    ),
    en: TipCopy(
      "Your own drinking rhythm",
      "Drink at convenient moments during the day. There is no need to catch up with a daily marker by drinking a lot at once.",
    ),
  ),
  DailyTip(
    id: "hydration-03",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Вкус без сложности",
      "Долька лимона, ягоды или мята могут сделать воду приятнее. Это вопрос вкуса, а не способ «очистить» организм.",
      task: "Попробуйте воду с любимым вкусом.",
    ),
    en: TipCopy(
      "A simple change of flavour",
      "Lemon, berries or mint can make water more enjoyable. This changes the flavour; it is not a way to detox your body.",
      task: "Try water with a flavour you enjoy.",
    ),
  ),
  DailyTip(
    id: "hydration-04",
    category: TipCategory.hydration,
    basis: TipBasis.water,
    ru: TipCopy(
      "Не все напитки записаны",
      "В Balance есть записи воды, но они могут отражать не всё питьё. Не воспринимайте пустую часть шкалы как точное измерение обезвоживания.",
      task: "Проверьте, все ли записи воды внесены.",
      why:
          "Приложение знает только внесённые записи и не оценивает состояние организма.",
    ),
    en: TipCopy(
      "A log is only part of the picture",
      "Your water log may not include everything you drink. An unfilled part of the tracker is not a measurement of dehydration.",
      task: "Check whether your water entries are complete.",
      why:
          "The app only knows what you log; it cannot assess your hydration status.",
    ),
  ),
  DailyTip(
    id: "hydration-05",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Чашка тоже считается",
      "Чай, молоко и другие напитки тоже дают жидкость. Шкала воды в приложении — удобная запись, а не полный водный баланс организма.",
    ),
    en: TipCopy(
      "A cup counts too",
      "Tea, milk and other drinks also provide fluid. The app's water tracker is a convenient log, not a full measure of fluid balance.",
    ),
  ),
  DailyTip(
    id: "hydration-06",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Бутылка для дороги",
      "Перед выходом проверьте, можно ли взять воду и где пополнить бутылку. Особенно удобно подумать об этом перед долгой поездкой.",
      task: "Проверьте бутылку перед выходом.",
    ),
    en: TipCopy(
      "A bottle for the journey",
      "Before leaving, check whether you can take water and where to refill. This is especially useful before a long journey.",
      task: "Check your bottle before heading out.",
    ),
  ),
  DailyTip(
    id: "hydration-07",
    category: TipCategory.hydration,
    ru: TipCopy(
      "После прогулки",
      "После движения дайте себе возможность отдохнуть и попить по потребности. Погода и нагрузка бывают разными, поэтому единого объёма на всех нет.",
    ),
    en: TipCopy(
      "After a walk",
      "After moving, leave time to rest and drink as needed. Weather and effort vary, so one fixed amount does not suit everyone.",
    ),
  ),
  DailyTip(
    id: "hydration-08",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Любимая температура",
      "Кому-то приятнее прохладная вода, кому-то тёплая. Подберите комфортную температуру: питьё не должно быть неприятной обязанностью.",
      task: "Попробуйте другую температуру напитка.",
    ),
    en: TipCopy(
      "Find your preferred temperature",
      "Some people prefer cool water, others warm. Choose a comfortable temperature so drinking does not become an unpleasant chore.",
      task: "Try a different drink temperature.",
    ),
  ),
  DailyTip(
    id: "hydration-09",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Чистая бутылка",
      "Многоразовую бутылку стоит мыть по инструкции, включая крышку. Удобная привычка начинается с чистой и доступной посуды.",
      task: "Вымойте бутылку и крышку.",
    ),
    en: TipCopy(
      "A clean bottle",
      "Clean a reusable bottle as instructed, including its lid. A convenient habit starts with clean, accessible drinkware.",
      task: "Wash your bottle and its lid.",
    ),
  ),
  DailyTip(
    id: "hydration-10",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Шкала без соревнования",
      "Цель воды можно использовать как личный ориентир. Не соревнуйтесь с чужими объёмами и соблюдайте назначенные врачом ограничения жидкости.",
    ),
    en: TipCopy(
      "A tracker without competition",
      "Use your water goal as a personal guide. Avoid competing with other people's totals, and follow any prescribed fluid restrictions.",
    ),
  ),
  DailyTip(
    id: "hydration-11",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Напиток к обеду",
      "Поставьте напиток рядом с обедом, если так удобнее помнить о питье. Вам не нужен строгий таймер для каждого глотка.",
      task: "Предусмотрите напиток к следующему обеду.",
    ),
    en: TipCopy(
      "A drink with lunch",
      "Have a drink with lunch if that helps you remember. You do not need a strict timer for every sip.",
      task: "Plan a drink with your next lunch.",
    ),
  ),
  DailyTip(
    id: "hydration-12",
    category: TipCategory.hydration,
    ru: TipCopy(
      "В жаркий день",
      "В жару заранее подумайте о доступе к воде и прохладному месту для отдыха. Ориентируйтесь на условия и индивидуальные рекомендации.",
      task: "Найдите место для пополнения воды.",
    ),
    en: TipCopy(
      "On a warm day",
      "In hot weather, plan access to water and a cool place to rest. Consider the conditions and any individual guidance you have.",
      task: "Find somewhere to refill your water.",
    ),
  ),
  DailyTip(
    id: "hydration-13",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Реальный объём кружки",
      "Размер любимой кружки может отличаться от стандартной порции в приложении. Один раз измерьте её, если хотите удобнее вести записи.",
      task: "Уточните объём своей кружки.",
    ),
    en: TipCopy(
      "Know your cup",
      "Your favourite mug may differ from the app's default serving. Measure it once if you want easier logging.",
      task: "Check the capacity of your mug.",
    ),
  ),
  DailyTip(
    id: "hydration-14",
    category: TipCategory.hydration,
    basis: TipBasis.water,
    ru: TipCopy(
      "Вода и планы",
      "Если в дневнике часто появляются пропуски, привяжите запись воды к уже существующему действию. Это помогает помнить о записи, а не заставляет пить больше.",
      task: "Выберите удобный момент для записи воды.",
    ),
    en: TipCopy(
      "Water in your plans",
      "If water entries are easy to miss, link logging to something you already do. This helps you remember the entry without pressuring you to drink more.",
      task: "Choose a convenient time to log water.",
    ),
  ),
  DailyTip(
    id: "hydration-15",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Лёд по желанию",
      "Лёд меняет температуру и ощущение напитка. Используйте его для удовольствия, а не ради обещаний «ускорить обмен веществ».",
    ),
    en: TipCopy(
      "Ice if you like",
      "Ice changes a drink's temperature and feel. Use it for enjoyment, without expecting it to speed up metabolism.",
    ),
  ),
  DailyTip(
    id: "hydration-16",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Напоминание без давления",
      "Если уведомления о воде раздражают, выберите более спокойный режим. Хорошая подсказка помогает вам, а не вызывает чувство вины.",
      task: "Проверьте удобство своих напоминаний.",
    ),
    en: TipCopy(
      "A gentle reminder",
      "If water reminders feel irritating, choose a quieter setting. A useful reminder helps without creating guilt.",
      task: "Check whether your reminders suit you.",
    ),
  ),
  DailyTip(
    id: "hydration-17",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Домашний кувшин",
      "Если вода из-под крана пригодна для питья, кувшин может быть удобнее отдельных бутылок. Выберите безопасный и доступный вам вариант.",
      task: "Подумайте, как сделать воду доступнее дома.",
    ),
    en: TipCopy(
      "A jug at home",
      "Where tap water is safe to drink, a jug may be more convenient than separate bottles. Choose a safe, accessible option.",
      task: "Think of a way to keep water accessible at home.",
    ),
  ),
  DailyTip(
    id: "hydration-18",
    category: TipCategory.hydration,
    ru: TipCopy(
      "Жажда не задача на баллы",
      "Не нужно пить через выраженный дискомфорт, чтобы закрыть кольцо. Цель приложения не заменяет ваши ощущения и индивидуальные рекомендации.",
    ),
    en: TipCopy(
      "Thirst is not a score",
      "You do not need to drink through marked discomfort to close a ring. An app goal does not replace your needs or individual guidance.",
    ),
  ),
  DailyTip(
    id: "activity-01",
    category: TipCategory.activity,
    ru: TipCopy(
      "Небольшой маршрут",
      "Выберите короткий знакомый маршрут и комфортный темп. Прогулка может быть приятной паузой без цели по скорости или расстоянию.",
      task: "Наметьте посильный маршрут.",
      why: "Посильное движение легче вписать в реальное расписание.",
    ),
    en: TipCopy(
      "A short route",
      "Choose a short familiar route and a comfortable pace. A walk can be a pleasant break without a speed or distance goal.",
      task: "Plan a manageable route.",
      why: "Manageable movement is easier to fit into your real schedule.",
    ),
  ),
  DailyTip(
    id: "activity-02",
    category: TipCategory.activity,
    ru: TipCopy(
      "Движение бывает разным",
      "Прогулка, движение на коляске, танцы и домашние дела тоже относятся к активности. Выберите то, что доступно вашему телу сегодня.",
    ),
    en: TipCopy(
      "Movement takes many forms",
      "Walking, wheeling, dancing and household tasks all count as activity. Choose what is accessible to your body today.",
    ),
  ),
  DailyTip(
    id: "activity-03",
    category: TipCategory.activity,
    ru: TipCopy(
      "Пауза от стула",
      "Если долго сидите, попробуйте ненадолго сменить позу или подвигаться удобным способом. Дискомфорт — повод остановиться и подобрать другой вариант.",
      task: "Сделайте комфортную паузу в работе.",
    ),
    en: TipCopy(
      "A break from sitting",
      "After sitting for a while, try changing position or moving in an accessible way. If it feels uncomfortable, stop and choose another option.",
      task: "Take a comfortable break from work.",
    ),
  ),
  DailyTip(
    id: "activity-04",
    category: TipCategory.activity,
    basis: TipBasis.steps,
    ru: TipCopy(
      "Шаги без сравнения",
      "В приложении есть реальные данные шагов. Смотрите на собственный обычный ритм, а не на чужие рекорды; лёгкий день тоже имеет место.",
      task: "Посмотрите на свой ритм без оценки.",
    ),
    en: TipCopy(
      "Steps without comparison",
      "The app has real step data. Compare with your usual rhythm rather than someone else's records; lighter days belong too.",
      task: "Look at your own pattern without judging it.",
    ),
  ),
  DailyTip(
    id: "activity-05",
    category: TipCategory.activity,
    ru: TipCopy(
      "Музыкальная пауза",
      "Включите любимую песню и подвигайтесь так, как приятно. Можно танцевать сидя или ограничиться мягкими движениями рук.",
      task: "Выберите одну песню для паузы.",
    ),
    en: TipCopy(
      "A musical break",
      "Play a favourite song and move in a way you enjoy. Dancing seated or moving your arms gently is an option too.",
      task: "Choose one song for a movement break.",
    ),
  ),
  DailyTip(
    id: "activity-06",
    category: TipCategory.activity,
    ru: TipCopy(
      "Удобная обувь",
      "Для прогулки важнее удобство, чем спортивный образ. Проверьте обувь, одежду и погоду, прежде чем выбирать маршрут.",
      task: "Подготовьте удобную одежду для выхода.",
    ),
    en: TipCopy(
      "Comfort comes first",
      "Comfort matters more than looking sporty on a walk. Check your shoes, clothing and the weather before choosing a route.",
      task: "Prepare comfortable clothes for going out.",
    ),
  ),
  DailyTip(
    id: "activity-07",
    category: TipCategory.activity,
    ru: TipCopy(
      "Прогулка с интересом",
      "Книжный магазин, парк или красивая улица могут стать поводом выйти. Движение проще вписать в день, когда оно связано с интересом.",
      task: "Выберите приятную точку маршрута.",
    ),
    en: TipCopy(
      "A walk with a purpose",
      "A bookshop, park or favourite street can be a reason to go out. Movement can fit more naturally when it connects with something you enjoy.",
      task: "Choose an enjoyable destination.",
    ),
  ),
  DailyTip(
    id: "activity-08",
    category: TipCategory.activity,
    ru: TipCopy(
      "Посильнее — не всегда лучше",
      "Усталость и восстановление тоже стоит учитывать в планах. Сегодня подходящим решением может быть более короткая прогулка или отдых.",
    ),
    en: TipCopy(
      "More is not always the aim",
      "Consider tiredness and recovery when making plans. A shorter walk or rest may be the right choice today.",
    ),
  ),
  DailyTip(
    id: "activity-09",
    category: TipCategory.activity,
    ru: TipCopy(
      "Компания для движения",
      "Предложите близкому человеку спокойную прогулку или другое доступное вам занятие. Договорённость может помочь найти время, без соревнования.",
      task: "Пригласите кого-нибудь на удобную прогулку.",
    ),
    en: TipCopy(
      "Some company for movement",
      "Invite someone for a relaxed walk or another activity you can access. Making a plan together can help you find time without competition.",
      task: "Invite someone for a manageable walk.",
    ),
  ),
  DailyTip(
    id: "activity-10",
    category: TipCategory.activity,
    ru: TipCopy(
      "Лестница по желанию",
      "Если лестница вам подходит, можно выбрать один удобный пролёт. Лифт остаётся нормальным выбором при усталости, боли или ограничениях.",
    ),
    en: TipCopy(
      "Stairs are optional",
      "If stairs suit you, choose one manageable flight. A lift remains a reasonable choice with fatigue, pain or mobility limits.",
    ),
  ),
  DailyTip(
    id: "activity-11",
    category: TipCategory.activity,
    ru: TipCopy(
      "После звонка",
      "Завершение рабочего звонка может стать напоминанием сменить положение. Не обязательно добавлять ещё одну сложную тренировку в расписание.",
      task: "Свяжите один звонок с короткой паузой.",
    ),
    en: TipCopy(
      "After a call",
      "The end of a work call can remind you to change position. You do not have to add another complicated workout to your schedule.",
      task: "Link one call with a short break.",
    ),
  ),
  DailyTip(
    id: "activity-12",
    category: TipCategory.activity,
    ru: TipCopy(
      "Маршрут под погоду",
      "Когда на улице скользко или слишком жарко, план можно изменить. Подойдёт доступное помещение или спокойный день дома.",
    ),
    en: TipCopy(
      "A weather-friendly route",
      "When it is slippery or very hot outside, change your plan. An accessible indoor space or a quiet day at home can work.",
    ),
  ),
  DailyTip(
    id: "activity-13",
    category: TipCategory.activity,
    ru: TipCopy(
      "Активность не наказание",
      "Не нужно «отрабатывать» еду движением. Выбирайте активность ради приятного занятия, общения или смены обстановки.",
    ),
    en: TipCopy(
      "Movement is not punishment",
      "You do not have to earn or burn off food with movement. Choose activity for enjoyment, company or a change of scene.",
    ),
  ),
  DailyTip(
    id: "activity-14",
    category: TipCategory.activity,
    basis: TipBasis.steps,
    ru: TipCopy(
      "Своя отправная точка",
      "Посмотрите на несколько дней с данными шагов. Разные значения могут отражать разные обстоятельства, а не недостаток старания.",
      task: "Вспомните контекст одного более спокойного дня.",
    ),
    en: TipCopy(
      "Your own starting point",
      "Look at several days with step records. Different totals may reflect different circumstances rather than a lack of effort.",
      task: "Recall the context of one quieter day.",
    ),
  ),
  DailyTip(
    id: "activity-15",
    category: TipCategory.activity,
    ru: TipCopy(
      "Разминка по ощущениям",
      "Начните выбранное занятие спокойно и дайте себе время освоиться. Если движение вызывает боль, не продолжайте через неё.",
    ),
    en: TipCopy(
      "Ease into movement",
      "Begin your chosen activity gently and allow time to settle in. If a movement causes pain, do not push through it.",
    ),
  ),
  DailyTip(
    id: "activity-16",
    category: TipCategory.activity,
    ru: TipCopy(
      "Приятный подкаст",
      "Аудиокнига или подкаст могут сделать привычный маршрут интереснее. Сохраняйте внимание к дороге и окружающим звукам.",
      task: "Выберите выпуск для спокойного маршрута.",
    ),
    en: TipCopy(
      "A podcast companion",
      "An audiobook or podcast can make a familiar route more interesting. Stay aware of traffic and sounds around you.",
      task: "Choose an episode for a relaxed outing.",
    ),
  ),
  DailyTip(
    id: "activity-17",
    category: TipCategory.activity,
    ru: TipCopy(
      "Движение между делами",
      "Убрать несколько вещей или полить растения — тоже смена активности. Короткие бытовые дела могут стать естественными паузами.",
      task: "Выберите одно небольшое домашнее дело.",
    ),
    en: TipCopy(
      "Movement between tasks",
      "Putting a few things away or watering plants changes your activity too. Small household tasks can become natural breaks.",
      task: "Choose one small household task.",
    ),
  ),
  DailyTip(
    id: "activity-18",
    category: TipCategory.activity,
    ru: TipCopy(
      "День без рекорда",
      "Вам не нужно каждый день превосходить вчерашние показатели. Устойчивый ритм включает разные по нагрузке дни.",
    ),
    en: TipCopy(
      "A day without a record",
      "You do not have to beat yesterday's numbers every day. A sustainable rhythm includes days with different levels of effort.",
    ),
  ),
  DailyTip(
    id: "recovery-01",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Тихий переход ко сну",
      "Выберите спокойное действие перед сном: чтение, музыку или душ. Повторяющийся ритуал может помочь обозначить конец дня.",
      task: "Выберите один вечерний ритуал.",
    ),
    en: TipCopy(
      "A quieter transition to sleep",
      "Choose a quiet activity before bed, such as reading, music or a shower. A familiar routine can help mark the end of the day.",
      task: "Choose one evening ritual.",
    ),
  ),
  DailyTip(
    id: "recovery-02",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Время для отдыха",
      "Посмотрите, не заполнен ли вечер делами до последней минуты. Небольшой запас времени позволяет завершить день спокойнее.",
      task: "Освободите небольшой отрезок вечера.",
    ),
    en: TipCopy(
      "Make room for rest",
      "Notice whether tasks fill every minute of your evening. A little spare time can make the end of the day feel less rushed.",
      task: "Leave a little space in your evening.",
    ),
  ),
  DailyTip(
    id: "recovery-03",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Свет вечером",
      "Если яркий свет мешает расслабиться, попробуйте более мягкое освещение перед сном. Учитывайте безопасность и свой комфорт.",
      task: "Настройте удобный вечерний свет.",
    ),
    en: TipCopy(
      "Evening light",
      "If bright light makes it hard to relax, try softer lighting before bed. Keep safety and your own comfort in mind.",
      task: "Set up comfortable evening lighting.",
    ),
  ),
  DailyTip(
    id: "recovery-04",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Комната для сна",
      "Проверьте, не мешают ли вам свет, шум или неудобная температура. Начните с одного доступного изменения в спальне.",
      task: "Уберите один источник неудобства.",
    ),
    en: TipCopy(
      "A room for sleep",
      "Check whether light, noise or an uncomfortable temperature is disturbing you. Start with one accessible change in the bedroom.",
      task: "Address one source of discomfort.",
    ),
  ),
  DailyTip(
    id: "recovery-05",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Завтрашние дела на бумаге",
      "Если перед сном вспоминаются задачи, запишите несколько пунктов. Необязательно удерживать весь список в голове.",
      task: "Запишите одну задачу на завтра.",
    ),
    en: TipCopy(
      "Put tomorrow on paper",
      "If tasks come to mind at bedtime, write down a few items. You do not have to keep the whole list in your head.",
      task: "Write down one task for tomorrow.",
    ),
  ),
  DailyTip(
    id: "recovery-06",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Кофеин и ваш вечер",
      "Обратите внимание, влияет ли поздний кофе на ваш сон. Если замечаете связь, попробуйте перенести его на более раннее время.",
      task: "Отметьте время последнего кофе.",
    ),
    en: TipCopy(
      "Caffeine and your evening",
      "Notice whether late coffee affects your sleep. If you see a pattern, try having it earlier.",
      task: "Notice when you have your last coffee.",
    ),
  ),
  DailyTip(
    id: "recovery-07",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Экран можно отложить",
      "Попробуйте закончить просмотр ленты немного раньше, если он затягивает отход ко сну. Выберите занятие, которое приятно завершить.",
      task: "Определите удобный момент убрать телефон.",
    ),
    en: TipCopy(
      "Put the screen aside",
      "Try ending your scroll a little earlier if it delays bedtime. Choose something you can comfortably bring to a close.",
      task: "Choose a convenient time to put your phone away.",
    ),
  ),
  DailyTip(
    id: "recovery-08",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Отдых — часть плана",
      "Пауза не отменяет заботу о себе. Не обязательно превращать свободное время в ещё одну задачу по улучшению результатов.",
    ),
    en: TipCopy(
      "Rest belongs in the plan",
      "Taking a break does not undo self-care. Free time does not have to become another task for improving your results.",
    ),
  ),
  DailyTip(
    id: "recovery-09",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Сон без идеальной оценки",
      "Одна трудная ночь не определяет весь режим. Подумайте, что сегодня может облегчить вечер, без требования «уснуть идеально».",
    ),
    en: TipCopy(
      "Sleep without a perfect score",
      "One difficult night does not define your routine. Consider what could make tonight easier without demanding perfect sleep.",
    ),
  ),
  DailyTip(
    id: "recovery-10",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Утро без спешки",
      "Подготовьте с вечера одну вещь: одежду, сумку или завтрак. Это может сделать утро чуть спокойнее.",
      task: "Подготовьте одну вещь на утро.",
    ),
    en: TipCopy(
      "A less hurried morning",
      "Prepare one thing in the evening: clothes, your bag or breakfast. It may make the morning a little calmer.",
      task: "Prepare one thing for the morning.",
    ),
  ),
  DailyTip(
    id: "recovery-11",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Дневной свет",
      "Если есть возможность, проведите часть дня при естественном свете. Можно выйти на улицу или устроиться у окна в удобное время.",
      task: "Найдите приятное место с дневным светом.",
    ),
    en: TipCopy(
      "A little daylight",
      "Spend some of the day in natural light if you can. Go outdoors or sit by a window at a convenient time.",
      task: "Find a pleasant spot with daylight.",
    ),
  ),
  DailyTip(
    id: "recovery-12",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Восстановление после нагрузки",
      "После непривычной активности не требуйте от себя ещё больше на следующий день. Оцените самочувствие и оставьте место для восстановления.",
    ),
    en: TipCopy(
      "Recovery after activity",
      "After unfamiliar activity, avoid demanding more of yourself the next day. Notice how you feel and make room for recovery.",
    ),
  ),
  DailyTip(
    id: "recovery-13",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Тишина по договорённости",
      "Если живёте не одни, обсудите удобное время тишины. Простая договорённость иногда помогает больше сложного вечернего списка.",
      task: "Обсудите одну спокойную вечернюю привычку.",
    ),
    en: TipCopy(
      "Agree on quiet time",
      "If you share a home, agree on a convenient quiet time. A simple agreement can be more useful than an elaborate evening checklist.",
      task: "Discuss one quiet evening habit.",
    ),
  ),
  DailyTip(
    id: "recovery-14",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Короткая передышка",
      "В середине дня можно ненадолго отойти от задач и спокойно посидеть. Отдых не обязательно должен быть заслужен усталостью.",
      task: "Выделите несколько спокойных минут.",
    ),
    en: TipCopy(
      "A short breather",
      "Step away from tasks and sit quietly for a moment during the day. You do not have to wait until you are exhausted to rest.",
      task: "Make room for a few quiet minutes.",
    ),
  ),
  DailyTip(
    id: "recovery-15",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Постоянство без жёсткости",
      "Примерно похожее время сна и подъёма может быть удобной опорой. Рабочие смены и жизненные обстоятельства требуют гибкости.",
    ),
    en: TipCopy(
      "Consistency with flexibility",
      "Similar sleep and wake times can provide a useful anchor. Shift work and life circumstances may require flexibility.",
    ),
  ),
  DailyTip(
    id: "recovery-16",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Удобная подушка",
      "Проверьте простые вещи: не слишком ли жарко под одеялом, удобно ли лежать. Не всякая вечерняя трудность требует нового гаджета.",
      task: "Сделайте спальное место немного удобнее.",
    ),
    en: TipCopy(
      "Everyday comfort",
      "Check simple things: whether your bedding is too warm or your position comfortable. Not every bedtime difficulty needs a new gadget.",
      task: "Make your sleeping space a little more comfortable.",
    ),
  ),
  DailyTip(
    id: "recovery-17",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Когда нужна поддержка",
      "Если проблемы со сном повторяются и мешают днём, обсудите их со специалистом. Приложение не определяет причину и не назначает лечение.",
    ),
    en: TipCopy(
      "When to seek support",
      "If sleep problems keep recurring and affect your daytime life, discuss them with a qualified professional. The app cannot diagnose or prescribe treatment.",
    ),
  ),
  DailyTip(
    id: "recovery-18",
    category: TipCategory.recovery,
    ru: TipCopy(
      "Вечер без догоняния",
      "Не нужно завершать все привычки за оставшиеся минуты дня. Выберите одну важную вещь, а остальное перенесите.",
      task: "Перенесите одну необязательную задачу.",
    ),
    en: TipCopy(
      "An evening without catching up",
      "You do not have to complete every habit in the final minutes of the day. Choose one priority and leave the rest for later.",
      task: "Postpone one nonessential task.",
    ),
  ),
  DailyTip(
    id: "habits-01",
    category: TipCategory.habits,
    ru: TipCopy(
      "Один понятный шаг",
      "Формулировка «положить фрукт в сумку» конкретнее, чем «питаться идеально». Небольшое действие легче встроить в обычный день.",
      task: "Сформулируйте одну привычку как действие.",
    ),
    en: TipCopy(
      "One clear step",
      "Putting fruit in your bag is more specific than eating perfectly. A small action is easier to fit into an ordinary day.",
      task: "Describe one habit as a specific action.",
    ),
  ),
  DailyTip(
    id: "habits-02",
    category: TipCategory.habits,
    ru: TipCopy(
      "Привязка к привычному",
      "Новое действие можно поставить рядом с существующим: записать воду после обеда или подготовить завтрак после ужина.",
      task: "Выберите опору для одной привычки.",
    ),
    en: TipCopy(
      "Link it to something familiar",
      "Link a new action to something familiar, such as logging water after lunch or preparing breakfast after dinner.",
      task: "Choose an anchor for one habit.",
    ),
  ),
  DailyTip(
    id: "habits-03",
    category: TipCategory.habits,
    ru: TipCopy(
      "Минимум на занятый день",
      "Заранее придумайте облегчённый вариант привычки. Короткая прогулка или простая запись могут подойти в день, когда времени мало.",
      task: "Запишите облегчённый вариант своего плана.",
    ),
    en: TipCopy(
      "A minimum for busy days",
      "Plan a lighter version of a habit. A short walk or a simple entry may suit a day with little spare time.",
      task: "Write down a lighter version of your plan.",
    ),
  ),
  DailyTip(
    id: "habits-04",
    category: TipCategory.habits,
    ru: TipCopy(
      "Пропуск не обнуление",
      "После пропуска можно продолжить со следующего удобного действия. Вам не нужно компенсировать день усиленной нагрузкой или ограничениями.",
    ),
    en: TipCopy(
      "A missed day is not a reset",
      "After a missed day, resume with the next convenient action. You do not need to compensate with extra exercise or restrictions.",
    ),
  ),
  DailyTip(
    id: "habits-05",
    category: TipCategory.habits,
    ru: TipCopy(
      "Окружение помогает",
      "Положите нужную вещь ближе: удобную бутылку, контейнер или обувь. Иногда меньше препятствий полезнее нового напоминания.",
      task: "Упростите доступ к одной нужной вещи.",
    ),
    en: TipCopy(
      "Let your surroundings help",
      "Put something useful within reach: a bottle, a lunch box or comfortable shoes. Fewer obstacles can be more helpful than another reminder.",
      task: "Make one useful item easier to reach.",
    ),
  ),
  DailyTip(
    id: "habits-06",
    category: TipCategory.habits,
    ru: TipCopy(
      "План с запасным выходом",
      "Если привычный обед недоступен, полезно иметь простой запасной вариант. Гибкость помогает продолжать без ощущения провала.",
      task: "Выберите запасной вариант обеда.",
    ),
    en: TipCopy(
      "A plan with an alternative",
      "Have a simple alternative when your usual lunch is unavailable. Flexibility helps you continue without feeling you have failed.",
      task: "Choose a backup lunch option.",
    ),
  ),
  DailyTip(
    id: "habits-07",
    category: TipCategory.habits,
    ru: TipCopy(
      "Меньше решений утром",
      "Подготовьте вечером одну деталь следующего дня. Это может быть контейнер, одежда или список покупок.",
      task: "Подготовьте то, что обычно ищете утром.",
    ),
    en: TipCopy(
      "Fewer morning decisions",
      "Prepare one detail of tomorrow tonight. It might be a lunch box, clothes or a shopping list.",
      task: "Prepare something you usually look for in the morning.",
    ),
  ),
  DailyTip(
    id: "habits-08",
    category: TipCategory.habits,
    ru: TipCopy(
      "Проверка удобства",
      "Если привычка не приживается, оцените время, место и сложность. Возможно, стоит изменить условия, а не требовать от себя больше силы воли.",
      task: "Уберите одно препятствие для привычки.",
    ),
    en: TipCopy(
      "Check what feels practical",
      "If a habit is not sticking, look at timing, location and difficulty. Changing the conditions may help more than demanding extra willpower.",
      task: "Remove one obstacle to a habit.",
    ),
  ),
  DailyTip(
    id: "habits-09",
    category: TipCategory.habits,
    ru: TipCopy(
      "Не всё сразу",
      "Выберите одну привычку на ближайшее время. Другие идеи можно сохранить и вернуться к ним, когда появится место.",
      task: "Сохраните лишние идеи на потом.",
    ),
    en: TipCopy(
      "You do not need everything at once",
      "Choose one habit for now. Save other ideas and return to them when you have room.",
      task: "Save extra ideas for later.",
    ),
  ),
  DailyTip(
    id: "habits-10",
    category: TipCategory.habits,
    ru: TipCopy(
      "Окно вместо минуты",
      "Действие можно планировать на промежуток времени, а не на точную минуту. Так в плане остаётся место для обычной жизни.",
    ),
    en: TipCopy(
      "A time window, not a minute",
      "Plan an action within a time window rather than at an exact minute. This leaves room for everyday life.",
    ),
  ),
  DailyTip(
    id: "habits-11",
    category: TipCategory.habits,
    ru: TipCopy(
      "Замечать, что работает",
      "Вспомните, какое полезное действие далось легко на этой неделе. Удачные условия можно использовать снова.",
      task: "Запишите, что помогло вам начать.",
    ),
    en: TipCopy(
      "Notice what works",
      "Recall one helpful action that felt easy this week. You can reuse the conditions that made it practical.",
      task: "Write down what helped you get started.",
    ),
  ),
  DailyTip(
    id: "habits-12",
    category: TipCategory.habits,
    ru: TipCopy(
      "Напоминание с действием",
      "Короткая подпись «подготовить обед» понятнее, чем «стать лучше». Настройте напоминание так, чтобы оно подсказывало следующий шаг.",
      task: "Сделайте одно напоминание конкретнее.",
    ),
    en: TipCopy(
      "A reminder with an action",
      "A short reminder to prepare lunch is clearer than a demand to improve yourself. Let the reminder suggest a next step.",
      task: "Make one reminder more specific.",
    ),
  ),
  DailyTip(
    id: "habits-13",
    category: TipCategory.habits,
    ru: TipCopy(
      "Право передумать",
      "Привычка может перестать подходить вашему расписанию. Изменить её формат — нормальная часть поиска удобного ритма.",
    ),
    en: TipCopy(
      "Permission to adjust",
      "A habit may stop fitting your schedule. Changing its format is a normal part of finding a workable rhythm.",
    ),
  ),
  DailyTip(
    id: "habits-14",
    category: TipCategory.habits,
    ru: TipCopy(
      "Список коротких рецептов",
      "Соберите несколько блюд, которые умеете готовить без подробной инструкции. Такой список пригодится в уставший вечер.",
      task: "Запишите три знакомых блюда.",
    ),
    en: TipCopy(
      "A list of easy meals",
      "List a few meals you can make without detailed instructions. The list can help on a tired evening.",
      task: "Write down three familiar meals.",
    ),
  ),
  DailyTip(
    id: "habits-15",
    category: TipCategory.habits,
    ru: TipCopy(
      "Планирование покупок",
      "Перед покупками загляните в холодильник и выберите несколько блюд. Это помогает покупать то, чему найдётся применение.",
      task: "Проверьте один продукт перед покупкой.",
    ),
    en: TipCopy(
      "A little shopping planning",
      "Check the fridge and choose a few meals before shopping. This helps you buy ingredients you are likely to use.",
      task: "Check one ingredient before buying more.",
    ),
  ),
  DailyTip(
    id: "habits-16",
    category: TipCategory.habits,
    basis: TipBasis.food,
    ru: TipCopy(
      "Удобство записи",
      "Если записи питания занимают много сил, начните с доступного уровня подробности. Дневник должен помогать, а не занимать весь день.",
      task: "Выберите удобное время для записи еды.",
    ),
    en: TipCopy(
      "Make logging convenient",
      "If food logging feels demanding, start with a manageable level of detail. A diary should help without taking over your day.",
      task: "Choose a convenient time to log food.",
    ),
  ),
  DailyTip(
    id: "habits-17",
    category: TipCategory.habits,
    ru: TipCopy(
      "Поддержка без контроля",
      "Можно попросить близкого человека о конкретной помощи: совместно приготовить ужин или напомнить взять обед. Контроль и оценки не обязательны.",
      task: "Назовите один полезный вид поддержки.",
    ),
    en: TipCopy(
      "Support without policing",
      "Ask someone close for a specific kind of help, such as cooking together or reminding you to take lunch. Policing and judgement are unnecessary.",
      task: "Name one kind of support you would find helpful.",
    ),
  ),
  DailyTip(
    id: "habits-18",
    category: TipCategory.habits,
    ru: TipCopy(
      "Привычка ради себя",
      "Подумайте, что даёт вам выбранное действие в обычной жизни: удобство, удовольствие или меньше спешки. Личная причина важнее красивой серии.",
    ),
    en: TipCopy(
      "A habit for your own reasons",
      "Consider what an action brings to daily life: convenience, enjoyment or less rushing. Your own reason matters more than a perfect streak.",
    ),
  ),
  DailyTip(
    id: "mindful-01",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Первый вкус",
      "В начале еды обратите внимание на вкус и температуру. Не нужно превращать весь приём пищи в упражнение на концентрацию.",
      task: "Заметьте вкус первого кусочка.",
    ),
    en: TipCopy(
      "Notice the first taste",
      "At the start of a meal, notice its taste and temperature. The whole meal does not have to become a concentration exercise.",
      task: "Notice the flavour of the first bite.",
    ),
  ),
  DailyTip(
    id: "mindful-02",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Пауза для аппетита",
      "Перед едой можно коротко спросить себя, насколько вы голодны и чего хочется. Это наблюдение, а не правило, разрешающее или запрещающее есть.",
    ),
    en: TipCopy(
      "Check in with your appetite",
      "Before eating, briefly notice your hunger and what appeals to you. This is an observation, not a rule for allowing or forbidding food.",
    ),
  ),
  DailyTip(
    id: "mindful-03",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Еда без ярлыков",
      "Попробуйте описывать еду через вкус, удобство и состав. Слова «плохая» и «запрещённая» редко помогают спокойно выбрать обед.",
      task: "Опишите одно блюдо без оценки.",
    ),
    en: TipCopy(
      "Food without labels",
      "Try describing food by taste, convenience and ingredients. Calling it bad or forbidden rarely helps you choose lunch calmly.",
      task: "Describe one dish without judging it.",
    ),
  ),
  DailyTip(
    id: "mindful-04",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Стол для одного",
      "Если возможно, найдите удобное место для еды. Даже простой перекус может быть приятнее, когда не приходится держать всё на весу.",
      task: "Устройте удобное место для следующей еды.",
    ),
    en: TipCopy(
      "A place for your meal",
      "Find a comfortable place to eat if you can. Even a simple snack can feel nicer when you are not juggling everything.",
      task: "Make a comfortable spot for your next meal.",
    ),
  ),
  DailyTip(
    id: "mindful-05",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Небольшая пауза от экрана",
      "Попробуйте на несколько минут убрать телефон во время еды и посмотреть, нравится ли вам так. Это эксперимент, а не обязательное правило.",
      task: "Попробуйте несколько минут еды без экрана.",
    ),
    en: TipCopy(
      "A short screen break",
      "Try setting your phone aside for a few minutes while eating and see whether you enjoy it. Treat it as an experiment, not a compulsory rule.",
      task: "Try a few minutes of eating without a screen.",
    ),
  ),
  DailyTip(
    id: "mindful-06",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Достаточно вкусно?",
      "Заметьте, приносит ли блюдо удовольствие. Иногда зелень, другая текстура или любимая приправа делают обычную еду приятнее.",
      task: "Найдите одну приятную деталь блюда.",
    ),
    en: TipCopy(
      "Does it taste satisfying?",
      "Notice whether you enjoy the meal. Herbs, a different texture or a favourite seasoning can make everyday food more appealing.",
      task: "Notice one enjoyable detail in a meal.",
    ),
  ),
  DailyTip(
    id: "mindful-07",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Темп без секундомера",
      "Ешьте в комфортном темпе, когда есть такая возможность. Не нужно считать жевательные движения или выполнять строгий ритуал.",
    ),
    en: TipCopy(
      "A pace without a stopwatch",
      "Eat at a comfortable pace when circumstances allow. You do not need to count chews or follow a strict ritual.",
    ),
  ),
  DailyTip(
    id: "mindful-08",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Голод не ошибка",
      "Если после еды вы всё ещё голодны, можно добавить ещё. План и цифры не обязаны отменять потребность в еде.",
    ),
    en: TipCopy(
      "Hunger is not a mistake",
      "If you are still hungry after a meal, you can have more. A plan and its numbers do not have to overrule your need for food.",
    ),
  ),
  DailyTip(
    id: "mindful-09",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Сладкое без компенсации",
      "Любимый десерт может быть частью обычной жизни. Не нужно пропускать следующий приём пищи, чтобы его «компенсировать».",
    ),
    en: TipCopy(
      "Enjoyment without compensation",
      "A favourite dessert can be part of everyday life. You do not have to skip your next meal to compensate for it.",
    ),
  ),
  DailyTip(
    id: "mindful-10",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Разные причины поесть",
      "Иногда мы едим ради праздника, общения или удовольствия. Еда не обязана выполнять только одну функцию.",
    ),
    en: TipCopy(
      "More than one reason to eat",
      "Sometimes we eat for celebration, company or enjoyment. Food does not have to serve just one purpose.",
    ),
  ),
  DailyTip(
    id: "mindful-11",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Что помогло пообедать?",
      "Вспомните спокойный приём пищи: что помогло найти время и устроиться удобно? Этот контекст можно попробовать повторить.",
      task: "Назовите одно удобное условие для обеда.",
    ),
    en: TipCopy(
      "What made lunch easier?",
      "Recall a relaxed meal: what helped you find time and feel comfortable? You could try recreating that setting.",
      task: "Name one condition that makes lunch easier.",
    ),
  ),
  DailyTip(
    id: "mindful-12",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Забота в напряжённый день",
      "При напряжении еда может стать торопливой или нерегулярной. Подумайте о доступном приёме пищи и одном другом способе поддержать себя.",
      task: "Выберите простую еду и короткую передышку.",
    ),
    en: TipCopy(
      "Care on a stressful day",
      "Stress can make meals rushed or irregular. Consider an accessible meal and one other way to support yourself.",
      task: "Choose a simple meal and a short breather.",
    ),
  ),
  DailyTip(
    id: "mindful-13",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Сытость меняется",
      "После разного сна, нагрузки и расписания аппетит может быть разным. Один шаблон порций не обязан подходить каждый день.",
    ),
    en: TipCopy(
      "Appetite can vary",
      "Appetite may vary with sleep, activity and schedule. One portion template does not have to fit every day.",
    ),
  ),
  DailyTip(
    id: "mindful-14",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Вкус из детства",
      "Вспомните блюдо, с которым связаны тёплые воспоминания. Любимые рецепты могут оставаться в меню без необходимости делать их «идеальными».",
      task: "Запишите название любимого домашнего блюда.",
    ),
    en: TipCopy(
      "A familiar comfort",
      "Think of a dish linked with warm memories. Favourite recipes can stay on the menu without being made perfect.",
      task: "Write down a favourite home-cooked dish.",
    ),
  ),
  DailyTip(
    id: "mindful-15",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Обед с компанией",
      "Если вам приятно есть вместе, запланируйте совместный обед. Разговор и еда могут сосуществовать без правил идеальной осознанности.",
      task: "Наметьте удобное время для совместной еды.",
    ),
    en: TipCopy(
      "A meal with company",
      "If you enjoy eating with others, plan a shared lunch. Conversation and food can coexist without rules about perfect mindfulness.",
      task: "Plan a convenient time for a shared meal.",
    ),
  ),
  DailyTip(
    id: "mindful-16",
    category: TipCategory.mindful,
    basis: TipBasis.food,
    ru: TipCopy(
      "Запись без приговора",
      "Дневник — запись событий, а не оценка характера. Можно посмотреть на привычки с любопытством и выбрать одно удобное изменение.",
      task: "Прочитайте одну запись нейтрально.",
    ),
    en: TipCopy(
      "A log without a verdict",
      "A diary records events; it does not grade your character. Look at patterns with curiosity and choose one practical adjustment.",
      task: "Read one entry neutrally.",
    ),
  ),
  DailyTip(
    id: "mindful-17",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Достаточно хорошая еда",
      "В сложный день доступная и приятная еда уже может быть заботой о себе. Необязательно искать самый правильный вариант.",
    ),
    en: TipCopy(
      "A good-enough meal",
      "On a difficult day, accessible food you enjoy can be an act of care. You do not have to find the most correct option.",
    ),
  ),
  DailyTip(
    id: "mindful-18",
    category: TipCategory.mindful,
    ru: TipCopy(
      "Остановить сравнение тарелок",
      "Размер чужой порции не подсказывает, сколько нужно вам. У людей разные обстоятельства, аппетит и потребности.",
    ),
    en: TipCopy(
      "Let each plate be different",
      "Someone else's portion does not tell you how much you need. People have different circumstances, appetites and needs.",
    ),
  ),
  DailyTip(
    id: "progress-01",
    category: TipCategory.progress,
    ru: TipCopy(
      "Смотрите на недели",
      "Вес меняется не только из-за долгосрочных изменений тела. Несколько недель сопоставимых записей дают больше контекста, чем отдельная цифра.",
    ),
    en: TipCopy(
      "Look across weeks",
      "Weight changes for reasons beyond long-term body changes. Several weeks of comparable readings offer more context than one number.",
    ),
  ),
  DailyTip(
    id: "progress-02",
    category: TipCategory.progress,
    ru: TipCopy(
      "Сравнимые условия",
      "Если отслеживаете вес, старайтесь выбирать похожие условия измерения. Так меньше случайных различий, но идеальной точности всё равно не требуется.",
      task: "Выберите удобные условия для следующих измерений.",
    ),
    en: TipCopy(
      "Comparable conditions",
      "If you track weight, aim for similar measuring conditions. This reduces incidental differences without requiring perfect precision.",
      task: "Choose convenient conditions for future measurements.",
    ),
  ),
  DailyTip(
    id: "progress-03",
    category: TipCategory.progress,
    basis: TipBasis.weight,
    ru: TipCopy(
      "История без приговора",
      "В вашей истории есть несколько измерений веса. Посмотрите на общий рисунок и даты; отдельное изменение не требует срочно менять питание.",
      task: "Посмотрите историю за более длинный период.",
      why: "Даты и условия измерений помогают осторожнее читать динамику.",
    ),
    en: TipCopy(
      "History without judgement",
      "You have several weight readings. Look at the overall pattern and dates; one change does not call for an urgent diet adjustment.",
      task: "Look at your history over a longer period.",
      why: "Dates and measuring conditions help put changes in context.",
    ),
  ),
  DailyTip(
    id: "progress-04",
    category: TipCategory.progress,
    ru: TipCopy(
      "Прогресс вне весов",
      "Удобнее готовить, легче находить время на прогулку, спокойнее относиться к еде — это тоже важные изменения в жизни.",
      task: "Запишите одно изменение вне цифр.",
    ),
    en: TipCopy(
      "Progress beyond the scales",
      "Cooking feels easier, walks fit your day, or eating feels calmer: these are meaningful changes in everyday life too.",
      task: "Write down one change beyond numbers.",
    ),
  ),
  DailyTip(
    id: "progress-05",
    category: TipCategory.progress,
    ru: TipCopy(
      "Пустой день — нет данных",
      "Отсутствие записи не равно отсутствию усилий. Приложение видит только внесённые данные и не знает весь ваш день.",
    ),
    en: TipCopy(
      "A blank day means missing data",
      "A missing entry does not mean a lack of effort. The app sees only what you log, not your whole day.",
    ),
  ),
  DailyTip(
    id: "progress-06",
    category: TipCategory.progress,
    ru: TipCopy(
      "Не менять всё из-за точки",
      "Если одна цифра удивила, сначала проверьте дату и условия измерения. Не нужно отвечать на неё резкими ограничениями.",
      task: "Проверьте контекст одной записи.",
    ),
    en: TipCopy(
      "One point does not change the plan",
      "If one reading surprises you, check its date and measuring conditions first. There is no need to respond with abrupt restrictions.",
      task: "Check the context of one reading.",
    ),
  ),
  DailyTip(
    id: "progress-07",
    category: TipCategory.progress,
    ru: TipCopy(
      "Свой масштаб времени",
      "Выберите период просмотра, который помогает увидеть общую картину. Частое переключение на короткий отрезок может давать слишком мало контекста.",
      task: "Сравните месяц и более длинный период.",
    ),
    en: TipCopy(
      "Your own time scale",
      "Choose a viewing period that helps you see the bigger picture. A short interval may provide too little context.",
      task: "Compare a month with a longer period.",
    ),
  ),
  DailyTip(
    id: "progress-08",
    category: TipCategory.progress,
    ru: TipCopy(
      "Замеры без спешки",
      "При замерах важны одинаковое место и удобное положение ленты. Не затягивайте её и не пытайтесь получить желаемую цифру.",
    ),
    en: TipCopy(
      "Measurements at your own pace",
      "When measuring, use the same position and place the tape comfortably. Avoid pulling it tight to obtain a particular number.",
    ),
  ),
  DailyTip(
    id: "progress-09",
    category: TipCategory.progress,
    ru: TipCopy(
      "Повторить удачное",
      "Подумайте, какой выбор на этой неделе оказался удобным. Прогресс может состоять в повторении работающего решения, а не в усложнении плана.",
      task: "Выберите одно решение, которое хочется повторить.",
    ),
    en: TipCopy(
      "Repeat what worked",
      "Consider a choice that worked well this week. Progress can mean repeating a workable solution rather than making the plan harder.",
      task: "Choose one helpful decision to repeat.",
    ),
  ),
  DailyTip(
    id: "progress-10",
    category: TipCategory.progress,
    ru: TipCopy(
      "Меньше давления от цифр",
      "Если частые измерения вызывают напряжение, можно выбрать более редкий ритм или паузу. Данные должны помогать вам.",
    ),
    en: TipCopy(
      "Less pressure from numbers",
      "If frequent measurements feel stressful, choose a less frequent rhythm or take a break. Data should be there to help you.",
    ),
  ),
  DailyTip(
    id: "progress-11",
    category: TipCategory.progress,
    ru: TipCopy(
      "Небольшая ретроспектива",
      "В конце недели спросите себя, что было удобно и что мешало. Один конкретный вывод полезнее строгой оценки всей недели.",
      task: "Запишите одно наблюдение о неделе.",
    ),
    en: TipCopy(
      "A small reflection",
      "At the end of the week, ask what felt practical and what got in the way. One clear observation can help more than grading the whole week.",
      task: "Write down one observation about the week.",
    ),
  ),
  DailyTip(
    id: "progress-12",
    category: TipCategory.progress,
    ru: TipCopy(
      "Плато не диагноз",
      "Ровная линия за короткий период сама по себе не объясняет происходящее. Приложение не может определить медицинскую причину по графику.",
    ),
    en: TipCopy(
      "A plateau is not a diagnosis",
      "A flat line over a short period does not explain what is happening by itself. The app cannot identify a medical cause from a chart.",
    ),
  ),
  DailyTip(
    id: "progress-13",
    category: TipCategory.progress,
    ru: TipCopy(
      "Разные линии, разные единицы",
      "Килограммы и сантиметры показывают разные измерения. Не сравнивайте их значения напрямую: смотрите на даты и динамику каждого показателя.",
    ),
    en: TipCopy(
      "Different lines, different units",
      "Kilograms and centimetres measure different things. Avoid comparing their values directly; look at dates and each metric's own pattern.",
    ),
  ),
  DailyTip(
    id: "progress-14",
    category: TipCategory.progress,
    ru: TipCopy(
      "Записи можно исправить",
      "Если заметили опечатку, исправьте её вместо того, чтобы подстраивать под неё выводы. Качественные данные важнее непрерывной красивой линии.",
      task: "Проверьте одну необычную запись.",
    ),
    en: TipCopy(
      "Entries can be corrected",
      "If you spot a typo, correct it instead of building conclusions around it. Reliable entries matter more than a perfectly unbroken line.",
      task: "Check one unusual entry.",
    ),
  ),
  DailyTip(
    id: "progress-15",
    category: TipCategory.progress,
    basis: TipBasis.weight,
    ru: TipCopy(
      "Реальная история веса",
      "Посмотрите, насколько регулярно сделаны ваши измерения. Пробелы между датами — повод осторожнее читать график, а не додумывать промежуточные значения.",
      task: "Посмотрите на интервалы между измерениями.",
    ),
    en: TipCopy(
      "Your real weight history",
      "Notice the spacing of your weight readings. Gaps call for care when interpreting the chart, not invented values between dates.",
      task: "Look at the intervals between readings.",
    ),
  ),
  DailyTip(
    id: "progress-16",
    category: TipCategory.progress,
    ru: TipCopy(
      "Цель можно обсуждать",
      "Если цель перестала подходить вашей жизни или самочувствию, её можно пересмотреть. При сомнениях о здоровье обсудите ориентиры со специалистом.",
    ),
    en: TipCopy(
      "Goals can be revisited",
      "If a goal no longer fits your life or wellbeing, you can revisit it. Discuss health-related concerns with a qualified professional.",
    ),
  ),
  DailyTip(
    id: "progress-17",
    category: TipCategory.progress,
    ru: TipCopy(
      "Чужая скорость не ориентир",
      "Чужие графики не показывают весь контекст. Сравнивайте свои решения с тем, что доступно вам, а не с историей другого человека.",
    ),
    en: TipCopy(
      "Someone else's pace is not your guide",
      "Other people's charts do not show their full context. Judge your choices by what is feasible for you rather than someone else's story.",
    ),
  ),
  DailyTip(
    id: "progress-18",
    category: TipCategory.progress,
    ru: TipCopy(
      "Выполнено по вашему решению",
      "Отметка задания нужна для вашей памяти. Balance не должен считать действие выполненным только потому, что вы открыли совет.",
      task: "Отметьте только то действие, которое действительно сделали.",
    ),
    en: TipCopy(
      "Completion is your choice",
      "A task check is there for your own record. Opening a tip does not mean you completed the action.",
      task: "Mark only an action you actually completed.",
    ),
  ),
  DailyTip(
    id: "facts-01",
    category: TipCategory.facts,
    ru: TipCopy(
      "Вода есть и в еде",
      "Супы, фрукты и овощи содержат воду. Поэтому запись выпитой воды не описывает всё поступление жидкости.",
    ),
    en: TipCopy(
      "Food contains water too",
      "Soups, fruit and vegetables contain water. A drinking-water log therefore does not describe your full fluid intake.",
    ),
  ),
  DailyTip(
    id: "facts-02",
    category: TipCategory.facts,
    ru: TipCopy(
      "Замороженное — тоже вариант",
      "Овощи могут попадать на стол свежими, замороженными или консервированными. Эти формы помогают сделать питание разнообразнее и удобнее.",
    ),
    en: TipCopy(
      "Frozen is an option too",
      "Vegetables can reach your plate fresh, frozen or canned. These forms can make varied meals more practical.",
    ),
  ),
  DailyTip(
    id: "facts-03",
    category: TipCategory.facts,
    ru: TipCopy(
      "Один продукт — не рацион",
      "Полезнее смотреть на сочетание продуктов в обычной жизни, чем искать единственный «суперфуд». Разнообразию не нужен дорогой ингредиент.",
    ),
    en: TipCopy(
      "One food is not a whole diet",
      "Look at the foods you eat across everyday life rather than searching for one superfood. Variety does not require an expensive ingredient.",
    ),
  ),
  DailyTip(
    id: "facts-04",
    category: TipCategory.facts,
    ru: TipCopy(
      "Коричневый цвет не гарантия",
      "Тёмный хлеб не обязательно цельнозерновой. О составе лучше расскажет список ингредиентов, чем цвет корочки.",
      task: "Посмотрите состав привычного хлеба.",
    ),
    en: TipCopy(
      "Brown is not a guarantee",
      "Dark bread is not necessarily wholegrain. The ingredients list tells you more than the colour of its crust.",
      task: "Check the ingredients of your usual bread.",
    ),
  ),
  DailyTip(
    id: "facts-05",
    category: TipCategory.facts,
    ru: TipCopy(
      "Белок есть в растениях",
      "Фасоль, чечевица, нут и соевые продукты содержат белок. Источники белка не ограничиваются мясом и рыбой.",
    ),
    en: TipCopy(
      "Plants provide protein",
      "Beans, lentils, chickpeas and soy foods contain protein. Protein sources extend beyond meat and fish.",
    ),
  ),
  DailyTip(
    id: "facts-06",
    category: TipCategory.facts,
    ru: TipCopy(
      "Состав и порция",
      "Данные на 100 г и на порцию отвечают на разные вопросы. Перед сравнением продуктов убедитесь, что смотрите на одинаковую основу.",
      task: "Сравните основу двух этикеток.",
    ),
    en: TipCopy(
      "Ingredients and serving size",
      "Values per 100 grams and per serving answer different questions. Check the basis is the same before comparing products.",
      task: "Compare the reference amounts on two labels.",
    ),
  ),
  DailyTip(
    id: "facts-07",
    category: TipCategory.facts,
    ru: TipCopy(
      "Энергия не качество",
      "Калорийность описывает энергию, но не весь состав и не удовольствие от еды. Одна цифра не определяет ценность блюда.",
    ),
    en: TipCopy(
      "Energy is not a quality score",
      "Calories describe energy, not a food's full composition or enjoyment. One number does not determine a meal's value.",
    ),
  ),
  DailyTip(
    id: "facts-08",
    category: TipCategory.facts,
    ru: TipCopy(
      "Углеводы не только сахар",
      "К углеводам относятся разные вещества, включая крахмал и сахара. Название группы само по себе мало говорит о продукте в целом.",
    ),
    en: TipCopy(
      "Carbs are more than sugar",
      "Carbohydrates include different substances, including starches and sugars. The group name alone says little about a food as a whole.",
    ),
  ),
  DailyTip(
    id: "facts-09",
    category: TipCategory.facts,
    ru: TipCopy(
      "Рецепт меняет цифры",
      "Одинаковые названия блюд могут скрывать разные рецепты. Запись из каталога — ориентир, особенно если состав приготовленного блюда неизвестен.",
    ),
    en: TipCopy(
      "Recipes change the numbers",
      "The same dish name can refer to different recipes. A catalog entry is an estimate, especially when the actual ingredients are unknown.",
    ),
  ),
  DailyTip(
    id: "facts-10",
    category: TipCategory.facts,
    ru: TipCopy(
      "Цельное зерно и вкус",
      "У цельных круп бывают ореховые, мягкие и насыщенные вкусы. Если одна крупа не понравилась, это не описывает все остальные.",
      task: "Назовите крупу, которую ещё не пробовали.",
    ),
    en: TipCopy(
      "Whole grains and flavour",
      "Whole grains can taste nutty, mild or rich. Disliking one grain does not mean you will dislike the others.",
      task: "Name a grain you have not tried yet.",
    ),
  ),
  DailyTip(
    id: "facts-11",
    category: TipCategory.facts,
    ru: TipCopy(
      "Не всё с надписью «без» лучше",
      "Надпись «без глютена» важна при соответствующих ограничениях, но сама по себе не делает продукт универсально предпочтительным.",
    ),
    en: TipCopy(
      "A free-from label is not a ranking",
      "Gluten-free labelling matters for relevant dietary needs, but does not automatically make a product preferable for everyone.",
    ),
  ),
  DailyTip(
    id: "facts-12",
    category: TipCategory.facts,
    ru: TipCopy(
      "Соль на этикетке",
      "Надписи «соль» и «натрий» обозначают разные показатели. Сравнивайте одинаковые единицы и одну и ту же массу продукта.",
    ),
    en: TipCopy(
      "Salt on the label",
      "Salt and sodium on labels are different measures. Compare matching units for the same amount of food.",
    ),
  ),
  DailyTip(
    id: "facts-13",
    category: TipCategory.facts,
    ru: TipCopy(
      "Пищевые волокна",
      "Клетчатка содержится в растительных продуктах: бобовых, цельных злаках, овощах и фруктах. Её источники можно менять по вкусу.",
    ),
    en: TipCopy(
      "Dietary fibre",
      "Fibre is found in plant foods such as pulses, whole grains, vegetables and fruit. Choose different sources according to your taste.",
    ),
  ),
  DailyTip(
    id: "facts-14",
    category: TipCategory.facts,
    ru: TipCopy(
      "Напиток не очищает организм",
      "Вода с лимоном остаётся напитком со вкусом лимона. Название «детокс» не превращает её в лечение или способ гарантированно снизить вес.",
    ),
    en: TipCopy(
      "A drink is not a detox",
      "Lemon water is a lemon-flavoured drink. A detox label does not turn it into treatment or a guaranteed way to lose weight.",
    ),
  ),
  DailyTip(
    id: "facts-15",
    category: TipCategory.facts,
    ru: TipCopy(
      "Размер упаковки",
      "Одна упаковка может содержать несколько указанных производителем порций. Эти порции — способ подачи информации, а не приказ, сколько вам есть.",
      task: "Найдите количество порций на упаковке.",
    ),
    en: TipCopy(
      "Package size and portions",
      "A package may contain several labelled servings. Those servings organise information; they are not instructions for how much you must eat.",
      task: "Find the number of servings on a package.",
    ),
  ),
  DailyTip(
    id: "facts-16",
    category: TipCategory.facts,
    ru: TipCopy(
      "Сухой и готовый вес",
      "Крупы впитывают воду при приготовлении. Поэтому данные на 100 г сухой и готовой крупы отличаются, даже если это один продукт.",
    ),
    en: TipCopy(
      "Dry and cooked weight",
      "Grains absorb water when cooked. Values per 100 grams differ for dry and cooked grains even when they are the same food.",
    ),
  ),
  DailyTip(
    id: "facts-17",
    category: TipCategory.facts,
    ru: TipCopy(
      "Жиры несут вкус",
      "Масла, орехи и семена различаются по вкусу и способам применения. Не обязательно выбирать один продукт для всех блюд.",
      task: "Подумайте, какой вкус подойдёт к вашему блюду.",
    ),
    en: TipCopy(
      "Fat carries flavour",
      "Oils, nuts and seeds offer different flavours and uses. One ingredient does not have to suit every dish.",
      task: "Think of a flavour that would suit your meal.",
    ),
  ),
  DailyTip(
    id: "facts-18",
    category: TipCategory.facts,
    ru: TipCopy(
      "Точность дневника ограничена",
      "Этикетки, рецепты и оценка порции могут отличаться от фактического блюда. Дневник полезен как инструмент наблюдения, даже без абсолютной точности.",
    ),
    en: TipCopy(
      "Food logs have limits",
      "Labels, recipes and portion estimates can differ from the actual meal. A diary can support observation without absolute precision.",
    ),
  ),
  DailyTip(
    id: "today-01",
    category: TipCategory.today,
    ru: TipCopy(
      "Подготовьте контейнер",
      "Пустой чистый контейнер на видном месте может напомнить взять с собой обед. Сегодня достаточно подготовить только его.",
      task: "Вымойте и поставьте контейнер на видное место.",
    ),
    en: TipCopy(
      "Get a lunch box ready",
      "A clean lunch box in sight can remind you to take a meal with you. Preparing just the box is enough for today.",
      task: "Wash a lunch box and leave it in sight.",
    ),
  ),
  DailyTip(
    id: "today-02",
    category: TipCategory.today,
    ru: TipCopy(
      "Один продукт для разнообразия",
      "Добавьте в список покупок продукт, которого давно не было в меню. Выберите недорогой и понятный вариант, который хочется попробовать.",
      task: "Запишите один продукт.",
    ),
    en: TipCopy(
      "One ingredient for variety",
      "Add an ingredient you have not eaten recently to your shopping list. Choose something affordable and familiar enough to enjoy trying.",
      task: "Write down one ingredient.",
    ),
  ),
  DailyTip(
    id: "today-03",
    category: TipCategory.today,
    ru: TipCopy(
      "Обед в календаре",
      "Если дела часто вытесняют еду, оставьте в расписании время на обед. Это забота об удобстве дня, а не новый показатель продуктивности.",
      task: "Освободите время для одного приёма пищи.",
    ),
    en: TipCopy(
      "Put lunch in the calendar",
      "If tasks often crowd out meals, leave time for lunch in your schedule. This is about making your day workable, not adding a productivity score.",
      task: "Make time for one meal.",
    ),
  ),
  DailyTip(
    id: "today-04",
    category: TipCategory.today,
    ru: TipCopy(
      "Удобная полка",
      "Поставьте продукты, которые хотите использовать, туда, где их видно. Так проще вспомнить о них до следующего похода в магазин.",
      task: "Переставьте один продукт на удобную полку.",
    ),
    en: TipCopy(
      "A useful shelf",
      "Put ingredients you want to use somewhere visible. They will be easier to remember before your next shopping trip.",
      task: "Move one ingredient to a convenient shelf.",
    ),
  ),
  DailyTip(
    id: "today-05",
    category: TipCategory.today,
    ru: TipCopy(
      "Сохраните рецепт",
      "Выберите один простой рецепт, который действительно хочется приготовить. Не нужно собирать целую коллекцию за один вечер.",
      task: "Сохраните один подходящий рецепт.",
    ),
    en: TipCopy(
      "Save a recipe",
      "Choose one simple recipe you actually want to cook. You do not need to build a whole collection in one evening.",
      task: "Save one recipe that suits you.",
    ),
  ),
  DailyTip(
    id: "today-06",
    category: TipCategory.today,
    ru: TipCopy(
      "Пять минут порядка",
      "Освободите небольшую часть рабочей поверхности кухни. Иногда готовить легче, когда есть место поставить доску и тарелку.",
      task: "Освободите место для приготовления еды.",
    ),
    en: TipCopy(
      "A few minutes of order",
      "Clear a small part of your kitchen worktop. Cooking can feel easier when there is room for a board and a plate.",
      task: "Clear a space to prepare food.",
    ),
  ),
  DailyTip(
    id: "today-07",
    category: TipCategory.today,
    ru: TipCopy(
      "Выберите маршрут заранее",
      "Найдите короткий удобный путь для прогулки, если она вам подходит. План можно сократить или перенести по самочувствию.",
      task: "Сохраните удобный маршрут.",
    ),
    en: TipCopy(
      "Choose a route in advance",
      "Find a short accessible walking route if walking suits you. You can shorten or postpone it according to how you feel.",
      task: "Save a convenient route.",
    ),
  ),
  DailyTip(
    id: "today-08",
    category: TipCategory.today,
    ru: TipCopy(
      "Поставьте воду рядом",
      "Налейте воду и поставьте в удобное место, если хотите пить. Сегодня можно начать с доступности, без задачи закрыть всю шкалу.",
      task: "Подготовьте удобный напиток.",
    ),
    en: TipCopy(
      "Keep water nearby",
      "Pour some water and keep it nearby if you want a drink. Start with accessibility rather than a demand to fill the whole tracker.",
      task: "Prepare a drink that suits you.",
    ),
  ),
  DailyTip(
    id: "today-09",
    category: TipCategory.today,
    ru: TipCopy(
      "Разморозьте основу ужина",
      "Если планируете готовить, заранее безопасно разморозьте нужный продукт в холодильнике. Следуйте указаниям на упаковке.",
      task: "Проверьте, что нужно подготовить к ужину.",
    ),
    en: TipCopy(
      "Prepare a dinner ingredient",
      "If you plan to cook, thaw a needed ingredient safely in the fridge in advance. Follow the instructions on its packaging.",
      task: "Check what needs preparing for dinner.",
    ),
  ),
  DailyTip(
    id: "today-10",
    category: TipCategory.today,
    ru: TipCopy(
      "Одна приятная сервировка",
      "Возьмите удобную тарелку и любимую кружку. Небольшая деталь может сделать обычную еду приятнее без затрат на сложную сервировку.",
      task: "Выберите любимую посуду для еды.",
    ),
    en: TipCopy(
      "A small touch at the table",
      "Use a comfortable plate and a favourite mug. A small detail can make an everyday meal more enjoyable without an elaborate table setting.",
      task: "Choose tableware you enjoy using.",
    ),
  ),
  DailyTip(
    id: "today-11",
    category: TipCategory.today,
    ru: TipCopy(
      "Проверка напоминаний",
      "Оставьте только те уведомления, которые помогают. Если подсказки стали фоновым шумом, попробуйте изменить время или отключить лишнее.",
      task: "Настройте одно напоминание под свой день.",
    ),
    en: TipCopy(
      "Check your reminders",
      "Keep reminders that help you. If alerts have become background noise, try changing their timing or switching some off.",
      task: "Adjust one reminder to fit your day.",
    ),
  ),
  DailyTip(
    id: "today-12",
    category: TipCategory.today,
    ru: TipCopy(
      "Вечерняя точка",
      "Запишите одну вещь, которая сегодня помогла вам позаботиться о себе. Это может быть отдых, удобный обед или просьба о помощи.",
      task: "Назовите одно полезное для вас действие.",
    ),
    en: TipCopy(
      "A closing note for the day",
      "Note one thing that helped you care for yourself today. It might be rest, an easy lunch or asking for help.",
      task: "Name one action that helped you.",
    ),
  ),
  DailyTip(
    id: "today-13",
    category: TipCategory.today,
    ru: TipCopy(
      "Овощ к привычному блюду",
      "Выберите уже знакомый овощ и придумайте, к чему его добавить. Сегодня не нужен сложный новый рецепт.",
      task: "Подготовьте один овощ для следующей еды.",
    ),
    en: TipCopy(
      "A vegetable for a familiar dish",
      "Choose a familiar vegetable and a dish it could go with. Today does not need a complicated new recipe.",
      task: "Prepare one vegetable for your next meal.",
    ),
  ),
  DailyTip(
    id: "today-14",
    category: TipCategory.today,
    ru: TipCopy(
      "Проверьте запасы",
      "Откройте один шкаф или ящик холодильника и посмотрите, что стоит использовать раньше. Это поможет придумать ближайший обед.",
      task: "Выберите один продукт для ближайшего блюда.",
    ),
    en: TipCopy(
      "Check your supplies",
      "Open one cupboard or fridge drawer and see what could be used soon. It may suggest your next lunch.",
      task: "Choose one ingredient for your next meal.",
    ),
  ),
  DailyTip(
    id: "today-15",
    category: TipCategory.today,
    ru: TipCopy(
      "Идея без готовки",
      "Придумайте доступную комбинацию, которую можно собрать без плиты. Она пригодится в поездке или в вечер без сил.",
      task: "Запишите свой вариант еды без плиты.",
    ),
    en: TipCopy(
      "A no-cook idea",
      "Think of an accessible combination that needs no stove. It can help while travelling or on a low-energy evening.",
      task: "Write down your own no-cook meal.",
    ),
  ),
  DailyTip(
    id: "today-16",
    category: TipCategory.today,
    ru: TipCopy(
      "Сделайте перерыв удобным",
      "Положите рядом книгу, наушники или другую вещь для отдыха. Пусть пауза будет доступна, когда появится несколько минут.",
      task: "Подготовьте одну вещь для отдыха.",
    ),
    en: TipCopy(
      "Make a break practical",
      "Keep a book, headphones or something else you enjoy nearby. Make a break accessible when a few minutes open up.",
      task: "Prepare one thing for a restful break.",
    ),
  ),
  DailyTip(
    id: "today-17",
    category: TipCategory.today,
    ru: TipCopy(
      "Спросите себя о помощи",
      "Подумайте, какая небольшая помощь облегчила бы сегодняшний день. Можно попросить о ней прямо и конкретно.",
      task: "Сформулируйте одну конкретную просьбу.",
    ),
    en: TipCopy(
      "Ask what would help",
      "Think of one small kind of help that would make today easier. You can ask for it directly and specifically.",
      task: "Put one specific request into words.",
    ),
  ),
  DailyTip(
    id: "today-18",
    category: TipCategory.today,
    ru: TipCopy(
      "Выберите только одно",
      "Из всех идей выберите одну, которая подходит вашему дню. Сохранённые советы могут подождать; выполнять всё сразу не нужно.",
      task: "Выберите одно посильное действие.",
    ),
    en: TipCopy(
      "Choose just one",
      "Choose one idea that fits your day. Saved tips can wait; you do not have to do everything at once.",
      task: "Choose one manageable action.",
    ),
  ),
];
