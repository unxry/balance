import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_models.dart';
import '../models/user_profile.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/balance_notification_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/balance_motion.dart';
import '../theme/i18n.dart';
import '../widgets/tab_bar_pill.dart';
import '../widgets/common.dart';
import '../widgets/achievement_medal.dart';
import '../widgets/balance_feedback.dart';
import '../widgets/root_swipe_guard.dart';
import 'add_food_screen.dart';
import 'advice_screen.dart';
import 'dashboard_screen.dart';
import 'diary_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import 'steps_screen.dart';
import 'weight_screen.dart';

/// Internal push-stack navigation on top of a bottom tab bar, mirroring the
/// prototype's flow: tabs for Home/Weight/Diary/Profile, with a quick add
/// action and secondary screens pushed on top.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

enum _Overlay { none, steps, addFood }

class _RootShellState extends State<RootShell> {
  final PageController _pageController = PageController();
  final ScrollController _homeScrollController = ScrollController();
  final RootSwipeCoordinator _swipeCoordinator = RootSwipeCoordinator();
  final GlobalKey<BalanceFeedbackHostState> _feedbackKey = GlobalKey();
  int _selectedTabIndex = 0;
  int _visibleTabIndex = 0;
  int _navigationRequest = 0;
  int _settledTabIndex = 0;
  int _weightActivationEpoch = 0;
  bool _programmaticTransition = false;
  _Overlay overlay = _Overlay.none;
  MealType _targetMeal = MealType.lunch;
  bool _openWaterFromNotification = false;
  AppDataProvider? _achievementData;
  bool _showingAchievement = false;
  String? _newDiaryEntryId;
  Timer? _diaryHighlightTimer;

  @override
  void initState() {
    super.initState();
    BalanceNotificationService.instance.navigationPayload.addListener(
      _handleNotificationNavigation,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _handleNotificationNavigation(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = context.read<AppDataProvider>();
    if (identical(data, _achievementData)) return;
    _achievementData?.removeListener(_handleAchievementUnlock);
    _achievementData = data;
    while (data.takeNextAchievementReveal() != null) {
      // Existing achievements are restored silently during upgrade.
    }
    data.addListener(_handleAchievementUnlock);
  }

  @override
  void dispose() {
    BalanceNotificationService.instance.navigationPayload.removeListener(
      _handleNotificationNavigation,
    );
    _achievementData?.removeListener(_handleAchievementUnlock);
    _pageController.dispose();
    _homeScrollController.dispose();
    _swipeCoordinator.dispose();
    _diaryHighlightTimer?.cancel();
    super.dispose();
  }

  void _handleAchievementUnlock() {
    if (_showingAchievement || !mounted) return;
    final achievement = _achievementData?.takeNextAchievementReveal();
    if (achievement == null) return;
    _showingAchievement = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final isRu = context.read<SettingsProvider>().lang == AppLang.ru;
      await showAchievementReveal(context, achievement, isRu: isRu);
      _showingAchievement = false;
    });
  }

  void _handleNotificationNavigation() {
    final service = BalanceNotificationService.instance;
    final payload = service.navigationPayload.value;
    if (!mounted || payload == null) return;
    service.consumePayload();
    switch (payload) {
      case 'diary:add':
        _selectTab(AppTab.diary, haptic: false);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => mounted ? _openAddFood() : null,
        );
      case 'weight':
        setState(() => overlay = _Overlay.none);
        _selectTab(AppTab.weight, haptic: false);
      case 'dashboard:steps':
        setState(() {
          overlay = _Overlay.steps;
        });
        _selectTab(AppTab.home, haptic: false);
      case 'dashboard:water':
        setState(() {
          overlay = _Overlay.none;
          _openWaterFromNotification = true;
        });
        _selectTab(AppTab.home, haptic: false);
      case 'dashboard:advice':
        setState(() => overlay = _Overlay.none);
        _selectTab(AppTab.home, haptic: false);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => mounted ? _openAdviceModal(context) : null,
        );
      default:
        setState(() => overlay = _Overlay.none);
        _selectTab(AppTab.home, haptic: false);
    }
  }

  void _openOverlay(_Overlay o) => setState(() => overlay = o);
  void _closeOverlay() {
    final target = _selectedTabIndex;
    setState(() => overlay = _Overlay.none);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(target);
      if (_visibleTabIndex != target || _programmaticTransition) {
        setState(() {
          _visibleTabIndex = target;
          _programmaticTransition = false;
        });
      }
    });
  }

  void _openAddFood([MealType? meal]) {
    setState(() {
      _targetMeal = meal ?? _mealForCurrentHour();
      overlay = _Overlay.addFood;
    });
  }

  MealType _mealForCurrentHour() {
    final hour = DateTime.now().hour;
    if (hour < 11) return MealType.breakfast;
    if (hour < 16) return MealType.lunch;
    if (hour < 19) return MealType.snack;
    return MealType.dinner;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lang = context.watch<SettingsProvider>().lang;
    late final Widget content;

    if (overlay == _Overlay.steps) {
      content = Scaffold(
        backgroundColor: c.surface,
        body: StepsScreen(onBack: _closeOverlay),
      );
    } else if (overlay == _Overlay.addFood) {
      final selectedDate = context.read<AppDataProvider>().selectedDate;
      content = Scaffold(
        backgroundColor: c.surface,
        body: AddFoodScreen(
          onBack: _closeOverlay,
          initialMeal: _targetMeal,
          selectedDate: selectedDate,
          onAdded: _handleFoodAdded,
        ),
      );
    } else {
      content = Scaffold(
        key: const ValueKey('balanceRootScaffold'),
        backgroundColor: c.surface,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: RootSwipeScope(
                coordinator: _swipeCoordinator,
                child: AnimatedBuilder(
                  animation: _swipeCoordinator,
                  builder: (context, _) =>
                      NotificationListener<ScrollEndNotification>(
                        onNotification: _onPagerScrollEnd,
                        child: PageView(
                          key: const ValueKey('rootTabPager'),
                          controller: _pageController,
                          physics: _swipeCoordinator.blocked
                              ? const NeverScrollableScrollPhysics()
                              : const PageScrollPhysics(),
                          onPageChanged: _onPageChanged,
                          children: [
                            for (final tab in AppTab.values)
                              _KeepAlivePage(
                                key: PageStorageKey('rootPage-${tab.name}'),
                                child: TickerMode(
                                  enabled: tab.index == _visibleTabIndex,
                                  child: _tabBody(context, tab),
                                ),
                              ),
                          ],
                        ),
                      ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TabBarPill(
                selectedIndex: _selectedTabIndex,
                controller: _pageController,
                lang: lang,
                onTap: _onTab,
              ),
            ),
          ],
        ),
      );
    }
    return BalanceFeedbackHost(key: _feedbackKey, child: content);
  }

  void _onTab(AppTab tab) => _selectTab(tab);

  void _selectTab(AppTab tab, {bool haptic = true}) {
    final target = tab.index;
    FocusManager.instance.primaryFocus?.unfocus();
    final page = _pageController.hasClients
        ? _pageController.page ?? _selectedTabIndex.toDouble()
        : _selectedTabIndex.toDouble();
    if (_pageController.hasClients &&
        !_programmaticTransition &&
        target == _selectedTabIndex &&
        (page - target).abs() < .001) {
      if (tab == AppTab.home && _homeScrollController.hasClients) {
        if (haptic) unawaited(BalanceMotion.selection());
        if (MediaQuery.disableAnimationsOf(context)) {
          _homeScrollController.jumpTo(0);
        } else {
          _homeScrollController.animateTo(
            0,
            duration: BalanceMotion.card,
            curve: BalanceMotion.emphasized,
          );
        }
      }
      return;
    }
    if (haptic) unawaited(BalanceMotion.selection());
    final request = ++_navigationRequest;
    setState(() {
      _selectedTabIndex = target;
      _programmaticTransition = true;
    });
    Future<void> move() async {
      if (!mounted ||
          request != _navigationRequest ||
          !_pageController.hasClients) {
        return;
      }
      if (MediaQuery.disableAnimationsOf(context)) {
        _pageController.jumpToPage(target);
      } else {
        await _pageController.animateToPage(
          target,
          duration: BalanceMotion.glass,
          curve: BalanceMotion.emphasized,
        );
      }
      if (mounted && request == _navigationRequest) {
        final settledPage = _pageController.page?.round();
        if (settledPage != target) _pageController.jumpToPage(target);
        setState(() {
          _visibleTabIndex = target;
          _programmaticTransition = false;
          _markTabSettled(target);
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(move()));
  }

  void _onPageChanged(int index) {
    if (_programmaticTransition) {
      if (index != _visibleTabIndex) {
        setState(() => _visibleTabIndex = index);
      }
      return;
    }
    if (index == _selectedTabIndex && index == _visibleTabIndex) return;
    unawaited(BalanceMotion.selection());
    setState(() {
      _selectedTabIndex = index;
      _visibleTabIndex = index;
    });
  }

  bool _onPagerScrollEnd(ScrollEndNotification notification) {
    if (_programmaticTransition || !_pageController.hasClients) return false;
    final page = _pageController.page;
    if (page == null || (page - page.round()).abs() > .001) return false;
    final settled = page.round();
    if (settled != _settledTabIndex) {
      setState(() => _markTabSettled(settled));
    }
    return false;
  }

  void _markTabSettled(int index) {
    final wasWeight = _settledTabIndex == AppTab.weight.index;
    _settledTabIndex = index;
    if (!wasWeight && index == AppTab.weight.index) {
      _weightActivationEpoch++;
    }
  }

  void _handleFoodAdded(FoodEntry entry) {
    setState(() {
      overlay = _Overlay.none;
      _newDiaryEntryId = entry.id;
    });
    _selectTab(AppTab.diary, haptic: false);
    final isRu = context.read<SettingsProvider>().lang == AppLang.ru;
    _feedbackKey.currentState?.success(isRu ? 'Еда добавлена' : 'Food added');
    _diaryHighlightTimer?.cancel();
    _diaryHighlightTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _newDiaryEntryId = null);
    });
  }

  Widget _tabBody(BuildContext context, AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return DashboardScreen(
          scrollController: _homeScrollController,
          onOpenSteps: () => _openOverlay(_Overlay.steps),
          onOpenWeight: () => _selectTab(AppTab.weight),
          onOpenDiary: (date) {
            context.read<AppDataProvider>().selectDashboardDate(date);
            _selectTab(AppTab.diary);
          },
          onOpenAdvice: () => _openAdviceModal(context),
          openWaterEditor: _openWaterFromNotification,
          onWaterEditorOpened: () {
            if (mounted) setState(() => _openWaterFromNotification = false);
          },
        );
      case AppTab.weight:
        return WeightScreen(
          activationEpoch: _weightActivationEpoch,
          isActive:
              _visibleTabIndex == AppTab.weight.index &&
              !_programmaticTransition,
          onBack: () => _selectTab(AppTab.home),
          onEditGoal: () => _showEditGoalSheet(context),
        );
      case AppTab.diary:
        return DiaryScreen(
          onSearch: _openAddFood,
          highlightedEntryId: _newDiaryEntryId,
        );
      case AppTab.profile:
        return ProfileScreen(
          onEditGoal: () => _openAdviceModal(context, edit: true),
          onOpenDiary: () => _selectTab(AppTab.diary),
          onOpenWeight: () => _selectTab(AppTab.weight),
          onStartOver: _openFreshOnboarding,
        );
    }
  }

  void _openFreshOnboarding() {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(
          onDone: () => navigator.pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const RootShell()),
          ),
        ),
      ),
      (_) => false,
    );
  }

  void _openAdviceModal(BuildContext context, {bool edit = false}) {
    if (edit) {
      _showEditGoalSheet(context);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const AdviceDetailSheet(),
    );
  }

  Future<void> _showEditGoalSheet(BuildContext context) async {
    final data = context.read<AppDataProvider>();
    final c = context.colors;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _GoalNutritionEditorSheet(data: data),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({super.key, required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _GoalNutritionEditorSheet extends StatefulWidget {
  const _GoalNutritionEditorSheet({required this.data});

  final AppDataProvider data;

  @override
  State<_GoalNutritionEditorSheet> createState() =>
      _GoalNutritionEditorSheetState();
}

class _GoalNutritionEditorSheetState extends State<_GoalNutritionEditorSheet> {
  late final TextEditingController _weightController;
  late final TextEditingController _targetController;
  late final TextEditingController _manualController;
  late Goal _goal;
  late CalorieGoalMode _mode;
  late final int _previousCalories;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final profile = widget.data.profile;
    _goal = profile.goal;
    _mode = profile.calorieGoalMode;
    _previousCalories = profile.effectiveCalorieGoal;
    _weightController = TextEditingController(
      text: profile.weightKg.toStringAsFixed(1),
    );
    _targetController = TextEditingController(
      text: profile.targetWeightKg.toStringAsFixed(1),
    );
    _manualController = TextEditingController(
      text: (profile.manualCalories ?? profile.effectiveCalorieGoal).toString(),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _targetController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  double? _number(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.'));

  UserProfile get _draft {
    final draft = UserProfile.fromJson(widget.data.profile.toJson());
    draft.goal = _goal;
    draft.weightKg = (_number(_weightController) ?? draft.weightKg)
        .clamp(20.0, 400.0)
        .toDouble();
    draft.targetWeightKg = (_number(_targetController) ?? draft.targetWeightKg)
        .clamp(20.0, 400.0)
        .toDouble();
    draft.calorieGoalMode = _mode;
    final manual = int.tryParse(_manualController.text.trim());
    if (manual != null) draft.manualCalories = manual;
    return draft;
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<SettingsProvider>().lang);
    final c = context.colors;
    final t = AppText(c);
    final draft = _draft;
    final recommended = draft.recommendedCalories;
    final goals = [
      (Goal.lose, s.goalLose),
      (Goal.hold, s.goalHold),
      (Goal.gain, s.goalGain),
    ];
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: c.line2,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              s.isRu ? 'Цель и питание' : 'Goal & nutrition',
              style: t.fraunces(size: 21, weight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            MonoLabel(s.obGoal),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final item in goals)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _choice(
                        c,
                        t,
                        item.$2,
                        _goal == item.$1,
                        () => setState(() => _goal = item.$1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    c,
                    s.currentWeight,
                    _weightController,
                    'kg',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _numberField(
                    c,
                    s.targetWeight,
                    _targetController,
                    'kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MonoLabel(s.isRu ? 'ДНЕВНАЯ НОРМА' : 'DAILY TARGET'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _choice(
                    c,
                    t,
                    s.isRu ? 'Автоматически' : 'Automatic',
                    _mode == CalorieGoalMode.auto,
                    () => setState(() => _mode = CalorieGoalMode.auto),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _choice(
                    c,
                    t,
                    s.isRu ? 'Вручную' : 'Manual',
                    _mode == CalorieGoalMode.manual,
                    () => setState(() => _mode = CalorieGoalMode.manual),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.card2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.line),
              ),
              child: _mode == CalorieGoalMode.auto
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$recommended ${s.isRu ? "ккал в день" : "kcal per day"}',
                          style: t.fraunces(
                            size: 20,
                            weight: FontWeight.w700,
                            color: c.accent,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${s.isRu ? "Текущая норма" : "Current target"}: $_previousCalories · ${s.isRu ? "новая рекомендация" : "new recommendation"}: $recommended',
                          style: t.inter(
                            size: 11,
                            color: c.muted,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.isRu
                              ? 'В автоматическом режиме норма пересчитывается при изменении профиля и веса.'
                              : 'In automatic mode, the target updates when profile data or weight changes.',
                          style: t.inter(
                            size: 11,
                            color: c.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _numberField(
                          c,
                          s.isRu ? 'Своя норма' : 'Custom target',
                          _manualController,
                          s.isRu ? 'ккал' : 'kcal',
                          decimals: false,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${s.isRu ? "Рекомендация Balance" : "Balance recommendation"}: $recommended ${s.isRu ? "ккал" : "kcal"}',
                                style: t.inter(size: 11, color: c.muted),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _mode = CalorieGoalMode.auto),
                              child: Text(s.isRu ? 'Применить' : 'Apply'),
                            ),
                          ],
                        ),
                        Text(
                          s.isRu
                              ? 'Ручная норма сохранится при изменении веса и активности.'
                              : 'A manual target stays unchanged when weight or activity changes.',
                          style: t.inter(size: 11, color: c.muted),
                        ),
                      ],
                    ),
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 10),
              Text(
                _validationError!,
                style: t.inter(size: 11, color: c.accent2),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: s.save,
              icon: Icons.check_rounded,
              onTap: () => _save(s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(
    dynamic c,
    AppText t,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: active ? c.accentSoft : c.card2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? c.accent : Colors.transparent),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: t.inter(
            size: 11,
            weight: FontWeight.w700,
            color: active ? c.accent : c.fg,
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    dynamic c,
    String label,
    TextEditingController controller,
    String suffix, {
    bool decimals = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() => _validationError = null),
          keyboardType: TextInputType.numberWithOptions(decimal: decimals),
          decoration: InputDecoration(
            suffixText: suffix,
            filled: true,
            isDense: true,
            fillColor: c.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.line),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(S s) async {
    final weight = _number(_weightController);
    final target = _number(_targetController);
    final manual = int.tryParse(_manualController.text.trim());
    final validNumbers =
        weight != null &&
        weight.isFinite &&
        weight >= 20 &&
        weight <= 400 &&
        target != null &&
        target.isFinite &&
        target >= 20 &&
        target <= 400;
    final validDirection =
        validNumbers &&
        (_goal == Goal.hold ||
            (_goal == Goal.lose && target <= weight) ||
            (_goal == Goal.gain && target >= weight));
    final validManual =
        _mode == CalorieGoalMode.auto ||
        (manual != null && manual >= 1200 && manual <= 4000);
    if (!validNumbers || !validDirection || !validManual) {
      setState(() {
        _validationError = !validNumbers
            ? (s.isRu
                  ? 'Введите вес от 20 до 400 kg.'
                  : 'Enter weights from 20 to 400 kg.')
            : !validDirection
            ? (s.isRu
                  ? 'Целевой вес не соответствует выбранной цели.'
                  : 'Target weight does not match the selected goal.')
            : (s.isRu
                  ? 'Введите дневную норму от 1200 до 4000 ккал.'
                  : 'Enter a daily target from 1200 to 4000 kcal.');
      });
      return;
    }
    final previousWeight = widget.data.profile.weightKg;
    final next = UserProfile.fromJson(widget.data.profile.toJson());
    next.goal = _goal;
    next.targetWeightKg = target;
    next.weightKg = weight;
    next.calorieGoalMode = _mode;
    if (_mode == CalorieGoalMode.manual) next.manualCalories = manual;
    await widget.data.updateProfile(next);
    if ((weight - previousWeight).abs() >= 0.05) {
      await widget.data.addWeightEntry(weight);
    }
    if (mounted) Navigator.of(context).pop();
  }
}
