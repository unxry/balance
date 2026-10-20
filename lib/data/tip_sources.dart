class TipSource {
  final String id, title, url, scopeRu, scopeEn;
  final String checkedOn;
  const TipSource(
    this.id,
    this.title,
    this.url,
    this.scopeRu,
    this.scopeEn, {
    this.checkedOn = '2026-10-19',
  });
}

const tipSources = <String, TipSource>{
  'cleveland-fluid': TipSource(
    'cleveland-fluid',
    'Cleveland Clinic · Weight fluctuations',
    'https://health.clevelandclinic.org/weight-fluctuations',
    'Вода, пищеварение и колебания: возможные, не подтверждённые личные причины.',
    'Fluid, digestion and fluctuations: possible, not established individual causes.',
  ),
  'cleveland-exercise': TipSource(
    'cleveland-exercise',
    'Cleveland Clinic · Exercise and weight',
    'https://health.clevelandclinic.org/just-started-exercising-gaining-weight',
    'Непривычная нагрузка может сопровождаться временными изменениями жидкости.',
    'Unfamiliar exercise can accompany temporary fluid changes.',
  ),
  'nhs-eating-support': TipSource(
    'nhs-eating-support',
    'NHS · Eating disorders',
    'https://www.nhs.uk/mental-health/feelings-symptoms-behaviours/behaviours/eating-disorders/overview/',
    'Трудности с питанием и обращение за помощью; диагноз по приложению не устанавливается.',
    'Eating difficulties and seeking support; no diagnosis is made by the app.',
  ),
  'niddk-eating': TipSource(
    'niddk-eating',
    'NIDDK · Eating & physical activity',
    'https://www.niddk.nih.gov/health-information/weight-management/adult-overweight-obesity/eating-physical-activity',
    'Общие принципы питания, посильной активности и поддержания веса у взрослых.',
    'General adult eating, accessible activity and weight-maintenance guidance.',
  ),
  'cdc-eating': TipSource(
    'cdc-eating',
    'CDC · Healthy eating',
    'https://www.cdc.gov/healthy-weight-growth/healthy-eating/index.html',
    'Разнообразие продуктов; идеи еды — иллюстрации, без расчёта КБЖУ.',
    'Food variety; meal ideas are illustrations without nutrient calculations.',
  ),
  'cdc-habits': TipSource(
    'cdc-habits',
    'CDC · Steps for losing weight',
    'https://www.cdc.gov/healthy-weight-growth/losing-weight/',
    'Дневник, сон, стресс, доступные действия и поддержка. Не обещание темпа.',
    'Logging, sleep, stress, practical actions and support; no promised rate.',
  ),
  'mayo-plateau': TipSource(
    'mayo-plateau',
    'Mayo Clinic · Weight-loss plateau',
    'https://www.mayoclinic.org/healthy-lifestyle/weight-loss/in-depth/weight-loss-plateau/art-20044615',
    'Вода, гликоген и изменение энергопотребностей; причина у конкретного человека неизвестна.',
    'Water, glycogen and changing energy needs; no individual cause is established.',
  ),
  'niddk-planner': TipSource(
    'niddk-planner',
    'NIDDK · Body Weight Planner',
    'https://www.niddk.nih.gov/health-information/weight-management/body-weight-planner',
    'Ограничения применения: взрослые, не беременность и не грудное вскармливание.',
    'Scope restrictions: adults, excluding pregnancy and breastfeeding.',
  ),
  'who-diet': TipSource(
    'who-diet',
    'WHO · Healthy diet',
    'https://www.who.int/news-room/fact-sheets/detail/healthy-diet',
    'Разнообразие, углеводы, белок, пищевые волокна и качество жиров.',
    'Variety, carbohydrate, protein, fibre and dietary fat quality.',
  ),
  'cdc-water': TipSource(
    'cdc-water',
    'CDC · Water and healthier drinks',
    'https://www.cdc.gov/healthy-weight-growth/water-healthy-drinks/',
    'Жидкость из еды и напитков; потребности различаются. Не лечение плато.',
    'Fluid from food and drinks; needs vary. Not a plateau treatment.',
  ),
  'nhs-weigh': TipSource(
    'nhs-weigh',
    'NHS · How to record your weight',
    'https://www.england.nhs.uk/wp-content/uploads/2021/06/PRN00916-how-to-record-your-weight.pdf',
    'Сопоставимые условия измерений; не требование взвешиваться ежедневно.',
    'Comparable measuring conditions; not a requirement for daily weighing.',
  ),
  'nhs-fibre': TipSource(
    'nhs-fibre',
    'NHS · Fibre in your diet',
    'https://www.nhs.uk/live-well/eat-well/digestive-health/how-to-get-more-fibre-into-your-diet/',
    'Источники клетчатки; лечебные диеты требуют индивидуального подхода.',
    'Fibre sources; clinical diets require individual guidance.',
  ),
  'niddk-portions': TipSource(
    'niddk-portions',
    'NIDDK · Food portions',
    'https://www.niddk.nih.gov/health-information/weight-management/just-enough-food-portions',
    'Различие порции и данных этикетки; дневник остаётся оценкой.',
    'Portions and label serving sizes; a diary remains an estimate.',
  ),
  'nhs-pms': TipSource(
    'nhs-pms',
    'NHS · PMS',
    'https://www.nhs.uk/conditions/pre-menstrual-syndrome/',
    'Возможные симптомы цикла. Balance не знает этот контекст по полу.',
    'Possible cycle symptoms. Balance cannot infer this context from sex.',
  ),
};
