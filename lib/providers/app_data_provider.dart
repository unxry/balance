import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/achievement_models.dart';
import '../models/food_models.dart';
import '../models/history_models.dart';
import '../models/body_measurement.dart';
import '../models/recipe_models.dart';
import '../models/reminder_models.dart';
import '../models/user_profile.dart';
import '../models/daily_tip.dart';
import '../models/weight_trend_insight.dart';
import '../services/weight_trend_insights_service.dart';
import '../services/daily_tips_service.dart';
import '../services/weight_forecast_cache.dart';
import '../services/achievement_engine.dart';
import '../services/activity_motion_service.dart';
import '../services/health_service.dart';
import '../services/balance_analytics_service.dart';
import '../services/image_sanitizer.dart';
import '../services/local_store.dart';
import '../services/water_save_trace.dart';
import '../services/recipe_repository.dart';
import '../utils/calendar_date.dart';
import '../services/smart_reminder_engine.dart';
import '../utils/entry_id.dart';

class DashboardDaySnapshot {
  final DateTime date;
  final String dateKey;
  final int caloriesConsumed;
  final int calorieGoal;
  final double protein;
  final double fat;
  final double carbs;
  final double waterConsumedLiters;
  final double waterGoalLiters;
  final int? steps;
  final List<FoodEntry> foodEntries;

  const DashboardDaySnapshot({
    required this.date,
    required this.dateKey,
    required this.caloriesConsumed,
    required this.calorieGoal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.waterConsumedLiters,
    required this.waterGoalLiters,
    required this.steps,
    required this.foodEntries,
  });

  int get caloriesRemaining => max(0, calorieGoal - caloriesConsumed);
  int get caloriesAboveGoal => max(0, caloriesConsumed - calorieGoal);
  bool get hasFood => foodEntries.isNotEmpty;
}

class AppDataProvider extends ChangeNotifier {
  AppDataProvider({
    DateTime Function()? now,
    Box<dynamic>? userBox,
    Box<dynamic>? foodBox,
    Box<dynamic>? weightBox,
    Box<dynamic>? achievementsBox,
    HealthService? healthService,
    ActivityMotionService? activityMotionService,
    Future<void> Function(double liters, String dateKey)? waterWriter,
  }) : _now = now ?? DateTime.now,
       _injectedUserBox = userBox,
       _injectedFoodBox = foodBox,
       _injectedWeightBox = weightBox,
       _injectedAchievementsBox = achievementsBox,
       _healthService = healthService ?? HealthService(),
       _activityMotionService =
           activityMotionService ?? ActivityMotionService(),
       _waterWriter = waterWriter;

  final DateTime Function() _now;
  final Box<dynamic>? _injectedUserBox;
  final Box<dynamic>? _injectedFoodBox;
  final Box<dynamic>? _injectedWeightBox;
  final Box<dynamic>? _injectedAchievementsBox;
  final HealthService _healthService;
  final ActivityMotionService _activityMotionService;
  final ActivityStateMachine _activityStateMachine = ActivityStateMachine();
  StreamSubscription<ActivitySignal>? _activitySubscription;
  final Future<void> Function(double liters, String dateKey)? _waterWriter;
  final BalanceAnalyticsService _analyticsService =
      const BalanceAnalyticsService();
  final Map<int, WeightAnalytics> _analyticsCache = {};
  String? _analyticsCacheDay;
  final AchievementEngine _achievementEngine = const AchievementEngine();
  final SmartReminderEngine _smartReminderEngine = const SmartReminderEngine();
  late DailyTipsService dailyTips;
  String? dailyTipsError;
  WeightForecastCache? _weightForecastCache;
  WeightForecastSnapshot weightForecast = const WeightForecastSnapshot();

  Future<void> refreshWeightForecast({bool notify = true}) async {
    final cache = _weightForecastCache;
    if (cache == null) return;
    final previous = weightForecast;
    try {
      weightForecast = await cache.refresh(weights: weightHistory, now: _now());
    } catch (_) {
      weightForecast = const WeightForecastSnapshot(
        status: WeightForecastStatus.unreliable,
        reason: 'storage',
      );
    }
    if (!identical(previous, weightForecast)) {
      _invalidateAnalytics();
      if (notify && !_disposed) notifyListeners();
    }
  }

  TipSafetyProfile get tipsSafety {
    final raw = _userBox.get('profile');
    final age = raw is Map && raw['onboarded'] == true ? raw['age'] : null;
    return TipSafetyProfile.fromJson(
      _userBox.get('tipsSafetyV1'),
      age: age is int && age >= 0 && age <= 100 ? age : null,
    );
  }

  Future<void> setTipsSafety(TipSafetyProfile value) async {
    await _userBox.put('tipsSafetyV1', value.toJson());
    await _userBox.flush();
    _invalidateAnalytics();
    await refreshDailyTip();
  }

  WeightTrendInsight get weightInsight =>
      const WeightTrendInsightsService().analyze(
        weights: weightHistory,
        now: _now(),
        goal: _userBox.containsKey('profile') ? profile.goal : null,
        targetKg: _userBox.containsKey('profile')
            ? profile.targetWeightKg
            : null,
        safety: tipsSafety,
      );

  TipContext get tipContext {
    final cutoff = localDateKey(
      DateTime(today.year, today.month, today.day - 6),
    );
    final foodDays = _foodHistory.entries.where(
      (entry) =>
          entry.key.compareTo(cutoff) >= 0 &&
          entry.key.compareTo(localDateKey(today)) <= 0 &&
          entry.value.isNotEmpty,
    );
    final previousWeek = _foodHistory.entries
        .where(
          (entry) =>
              entry.key.compareTo(
                    localDateKey(
                      DateTime(today.year, today.month, today.day - 7),
                    ),
                  ) >=
                  0 &&
              entry.key.compareTo(localDateKey(today)) < 0 &&
              entry.value.isNotEmpty,
        )
        .toList();
    final lowDays = previousWeek.where((entry) {
      final goal = calorieGoalForDate(entry.key);
      final logged = entry.value.fold<int>(0, (sum, food) => sum + food.kcal);
      return goal > 0 && logged < goal * .75;
    }).length;
    final insight = weightInsight;
    final foods = previousWeek.expand((day) => day.value).toList();
    return TipContext(
      hasFood: foodDays.isNotEmpty,
      hasWater: _waterHistory.entries.any(
        (entry) =>
            entry.key.compareTo(cutoff) >= 0 &&
            entry.key.compareTo(localDateKey(today)) <= 0 &&
            entry.value > 0,
      ),
      hasSteps:
          activityAvailable ||
          dailyBalances.any(
            (day) =>
                day.dateKey.compareTo(cutoff) >= 0 &&
                day.dateKey.compareTo(localDateKey(today)) <= 0 &&
                day.stepCount != null,
          ),
      hasWeightTrend:
          insight.measuredDays >= 4 &&
          insight.spanDays >= 7 &&
          insight.state != WeightInsightState.uncertainTrend &&
          insight.state != WeightInsightState.insufficientData,
      lowLoggedIntake: lowDays >= 3,
      diaryGaps: previousWeek.length < 7,
      loggedFoodDays: previousWeek.length,
      distinctFoods: foods
          .map((e) => e.productId ?? e.name.trim().toLowerCase())
          .toSet()
          .length,
      loggedProteinG: foods.isEmpty
          ? null
          : foods.fold<double>(0, (sum, e) => sum + e.proteinG),
      loggedFatG: foods.isEmpty
          ? null
          : foods.fold<double>(0, (sum, e) => sum + e.fatG),
      loggedCarbsG: foods.isEmpty
          ? null
          : foods.fold<double>(0, (sum, e) => sum + e.carbsG),
      hasBody: bodyMeasurements.any(
        (e) =>
            localDateKey(e.date).compareTo(cutoff) >= 0 &&
            localDateKey(e.date).compareTo(localDateKey(today)) <= 0,
      ),
      maintenance:
          profile.goal == Goal.hold ||
          insight.state == WeightInsightState.maintenance ||
          (profile.goal == Goal.lose &&
              weightHistory.isNotEmpty &&
              weightHistory.last.kg <= profile.targetWeightKg * 1.005),
      insight: insight,
      safety: tipsSafety,
    );
  }

  Future<void> refreshDailyTip() async {
    try {
      await dailyTips.refresh(context: tipContext);
      dailyTipsError = null;
    } catch (_) {
      dailyTipsError = 'storage';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> setTipsPersonalized(bool value) async {
    await dailyTips.setPersonalized(value);
    if (!_disposed) notifyListeners();
  }

  Future<void> toggleSavedTip(String id) async {
    await dailyTips.toggleSaved(id);
    if (!_disposed) notifyListeners();
  }

  Future<void> setTipCompleted(String date, bool value) async {
    await dailyTips.setCompleted(date, value);
    if (!_disposed) notifyListeners();
  }

  UserProfile profile = UserProfile();

  final List<FoodEntry> _todayFood = [];
  List<FoodEntry> get todayFood => List.unmodifiable(_todayFood);
  final Map<String, List<FoodEntry>> _foodHistory = {};
  final Map<String, double> _waterHistory = {};
  Map<String, double> get waterHistory => Map.unmodifiable(_waterHistory);
  List<FoodEntry> foodEntriesForDate(String dateKey) =>
      List.unmodifiable(_foodHistory[dateKey] ?? const <FoodEntry>[]);
  List<FoodEntry> get allFoodEntries {
    final entries = _foodHistory.values.expand((value) => value).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return List.unmodifiable(entries);
  }

  final List<WeightEntry> weightHistory = [];
  final List<BodyMeasurement> _bodyMeasurements = [];
  Future<void> _bodyWrites = Future<void>.value();
  int _pendingBodyWrites = 0;
  List<BodyMeasurement> get bodyMeasurements =>
      List.unmodifiable(_bodyMeasurements);
  final Map<String, DailyBalanceSnapshot> _dailyBalances = {};
  final List<CalorieGoalHistoryEntry> _calorieGoalHistory = [];
  final List<GoalHistoryEntry> _goalHistory = [];
  final List<DailyAdviceHistoryEntry> _adviceHistory = [];
  List<CalorieGoalHistoryEntry> get calorieGoalHistory =>
      List.unmodifiable(_calorieGoalHistory);
  List<GoalHistoryEntry> get goalHistory => List.unmodifiable(_goalHistory);
  List<DailyAdviceHistoryEntry> get adviceHistory =>
      List.unmodifiable(_adviceHistory);
  List<DailyBalanceSnapshot> get dailyBalances {
    final values = _dailyBalances.values.toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return List.unmodifiable(values);
  }

  StepAccessState stepAccess = StepAccessState.loading;
  bool stepsLoading = false;
  int? todaySteps;
  ActivityMotionState activityMotionState = ActivityMotionState.idle;
  bool activitySignalAvailable = false;
  String? stepsError;
  bool get activityAvailable =>
      stepAccess == StepAccessState.authorized && todaySteps != null;

  int streakDays = 0;
  double waterLiters = 0;
  static const double maxWaterGoalLiters = 2.5;
  static const double minWaterGoalLiters = 0.5;
  double _waterGoalLiters = maxWaterGoalLiters;
  double get waterGoalLiters => _waterGoalLiters;

  late DateTime _selectedDate;
  DateTime get selectedDate => _selectedDate;
  String get selectedDateKey => localDateKey(_selectedDate);
  DateTime get today {
    final value = _now().toLocal();
    return DateTime(value.year, value.month, value.day);
  }

  bool get isTodaySelected => selectedDateKey == localDateKey(today);

  /// Earliest civil day that can contain meaningful user history.
  DateTime get firstUsageDate {
    final candidates = <DateTime>[];
    void add(DateTime? value) {
      if (value == null) return;
      final day = DateTime(value.year, value.month, value.day);
      if (!day.isAfter(today)) candidates.add(day);
    }

    if (profile.onboarded) add(profile.joinedAt.toLocal());
    for (final key in <String>{
      ..._foodHistory.keys,
      ..._waterHistory.keys,
      ..._dailyBalances.keys,
    }) {
      add(_dateFromKey(key));
    }
    for (final entry in weightHistory) {
      add(entry.date.toLocal());
    }
    if (candidates.isEmpty) return today;
    candidates.sort();
    return candidates.first;
  }

  int get dashboardDayCount =>
      today.difference(firstUsageDate).inDays.clamp(0, 36500) + 1;

  List<String> get foodHistoryDateKeys {
    final keys =
        _foodHistory.entries
            .where((entry) => entry.value.isNotEmpty)
            .map((entry) => entry.key)
            .toList()
          ..sort((a, b) => b.compareTo(a));
    return List.unmodifiable(keys);
  }

  /// Civil days that contain at least one real user signal.
  int get informativeDayCount => _activeDateKeys().length;

  late Box<dynamic> _userBox;
  late Box<dynamic> _foodBox;
  late Box<dynamic> _weightBox;
  late Box<dynamic> _achievementsBox;
  late RecipeRepository _recipeRepository;
  String? _activeDayKey;

  bool _loaded = false;
  bool get loaded => _loaded;
  List<UserRecipe> get userRecipes => _recipeRepository.recipes;
  int recipeUsageCount(String recipeId) =>
      _recipeRepository.usageCount(recipeId);
  ReminderSettings reminderSettings = const ReminderSettings();
  final List<ManualReminder> _manualReminders = [];
  List<ManualReminder> get manualReminders =>
      List.unmodifiable(_manualReminders);
  List<AchievementProgress> _achievementProgress = const [];
  List<AchievementProgress> get achievements => _achievementProgress;
  final List<AchievementProgress> _pendingAchievementReveals = [];
  final Map<String, DateTime> _achievementUnlocks = {};

  Future<void> load() async {
    _loaded = false;
    _userBox = _injectedUserBox ?? Hive.box<dynamic>(LocalStore.userBox);
    _foodBox = _injectedFoodBox ?? Hive.box<dynamic>(LocalStore.foodBox);
    _weightBox = _injectedWeightBox ?? Hive.box<dynamic>(LocalStore.weightBox);
    _achievementsBox =
        _injectedAchievementsBox ??
        _injectedUserBox ??
        Hive.box<dynamic>(LocalStore.achievementsBox);
    _recipeRepository = RecipeRepository(userBox: _userBox, now: _now);
    await _recipeRepository.load();

    _todayFood.clear();
    _foodHistory.clear();
    _waterHistory.clear();
    weightHistory.clear();
    _bodyMeasurements.clear();
    _dailyBalances.clear();
    _calorieGoalHistory.clear();
    _goalHistory.clear();
    _adviceHistory.clear();
    _manualReminders.clear();
    _pendingAchievementReveals.clear();
    _invalidateAnalytics();

    final savedProfile = _userBox.get('profile');
    if (savedProfile is Map) {
      profile = UserProfile.fromJson(Map<dynamic, dynamic>.from(savedProfile));
    }
    _migrateProfileAvatarCrop();
    final savedWaterGoal = _userBox.get('waterGoalLiters');
    if (savedWaterGoal is num && savedWaterGoal.isFinite) {
      _waterGoalLiters = savedWaterGoal.toDouble().clamp(
        minWaterGoalLiters,
        maxWaterGoalLiters,
      );
    }
    _userBox.put('waterGoalLiters', _waterGoalLiters);
    _selectedDate = today;
    _loadGoalHistories();

    _loadDailyBalances();
    _loadDailyState();
    _loadWeightHistory();
    final savedMeasurements = _userBox.get('bodyMeasurements');
    if (savedMeasurements is List) {
      _bodyMeasurements.addAll(
        savedMeasurements
            .map(BodyMeasurement.tryFromJson)
            .whereType<BodyMeasurement>(),
      );
      _sortBodyMeasurements();
    }
    _loadReminderSettings();
    _loadAchievementUnlocks();
    _seedGoalHistoriesIfNeeded();

    _updateStreak();

    _weightForecastCache = WeightForecastCache(
      read: () => _userBox.get(WeightForecastCache.storageKey),
      write: (state) async {
        await _userBox.put(WeightForecastCache.storageKey, state);
        await _userBox.flush();
      },
    );
    await refreshWeightForecast(notify: false);
    dailyTips = DailyTipsService(
      store: HiveDailyTipsStore(_userBox),
      now: _now,
    );
    _loaded = true;
    _syncDailyBalance();
    await refreshSteps();
    await refreshDailyTip();
    notifyListeners();
  }

  Future<UserRecipe> createRecipe({
    required String name,
    String? category,
    String? note,
    Uint8List? imageBytes,
    required List<RecipeIngredient> ingredients,
    double? cookedWeightGrams,
    int? portions,
  }) async {
    final recipe = await _recipeRepository.create(
      name: name,
      category: category,
      note: note,
      imageBytes: imageBytes,
      ingredients: ingredients,
      cookedWeightGrams: cookedWeightGrams,
      portions: portions,
    );
    notifyListeners();
    return recipe;
  }

  Future<UserRecipe> updateRecipe({
    required String recipeId,
    required String name,
    String? category,
    String? note,
    Uint8List? imageBytes,
    required List<RecipeIngredient> ingredients,
    double? cookedWeightGrams,
    int? portions,
  }) async {
    final recipe = await _recipeRepository.addVersion(
      recipeId: recipeId,
      name: name,
      category: category,
      note: note,
      imageBytes: imageBytes,
      ingredients: ingredients,
      cookedWeightGrams: cookedWeightGrams,
      portions: portions,
    );
    notifyListeners();
    return recipe;
  }

  Future<UserRecipe> duplicateRecipe(String recipeId, {String? name}) async {
    final recipe = await _recipeRepository.duplicate(recipeId, name: name);
    notifyListeners();
    return recipe;
  }

  RecipeVersion prepareRecipeAgain(String recipeId) =>
      _recipeRepository.prepareAgain(recipeId);

  Future<void> deleteRecipe(String recipeId) async {
    await _recipeRepository.delete(recipeId);
    notifyListeners();
  }

  Future<void> setRecipeFavorite(String recipeId, bool favorite) async {
    await _recipeRepository.setFavorite(recipeId, favorite);
    notifyListeners();
  }

  Future<void> markRecipeUsed(String recipeId) async {
    await _recipeRepository.markUsed(recipeId);
    notifyListeners();
  }

  void _migrateProfileAvatarCrop() {
    const migrationKey = 'profileAvatarCropVersion';
    if (profile.avatarBytes == null || _userBox.get(migrationKey) == 1) return;
    try {
      profile.avatarBytes = ImageSanitizer.sanitize(
        profile.avatarBytes!,
        cropSquare: true,
        maxOutputLongEdge: 768,
      ).bytes;
      _userBox.put('profile', profile.toJson());
    } on ImageValidationException {
      // Preserve a previously accepted image if it cannot be normalized.
    } finally {
      _userBox.put(migrationKey, 1);
    }
  }

  void _loadDailyBalances() {
    final saved = _userBox.get('dailyBalances');
    if (saved is! List) return;
    for (final value in saved) {
      final snapshot = DailyBalanceSnapshot.tryFromJson(value);
      if (snapshot != null) _dailyBalances[snapshot.dateKey] = snapshot;
    }
  }

  void _loadGoalHistories() {
    final savedCalories = _userBox.get('calorieGoalHistory');
    if (savedCalories is List) {
      for (final value in savedCalories) {
        final entry = CalorieGoalHistoryEntry.tryFromJson(value);
        if (entry != null) _calorieGoalHistory.add(entry);
      }
      _calorieGoalHistory.sort(
        (a, b) => a.effectiveFrom.compareTo(b.effectiveFrom),
      );
    }
    final savedGoals = _userBox.get('goalHistory');
    if (savedGoals is List) {
      for (final value in savedGoals) {
        final entry = GoalHistoryEntry.tryFromJson(value);
        if (entry != null) _goalHistory.add(entry);
      }
      _goalHistory.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    }
    final savedAdvice = _userBox.get('adviceHistory');
    if (savedAdvice is List) {
      for (final value in savedAdvice) {
        final entry = DailyAdviceHistoryEntry.tryFromJson(value);
        if (entry != null) _adviceHistory.add(entry);
      }
      _adviceHistory.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    }
  }

  void _seedGoalHistoriesIfNeeded() {
    if (!profile.onboarded) return;
    final effectiveFrom = profile.joinedAt.isAfter(_now())
        ? _now()
        : profile.joinedAt;
    if (_calorieGoalHistory.isEmpty) {
      _calorieGoalHistory.add(
        CalorieGoalHistoryEntry(
          effectiveFrom: effectiveFrom,
          calories: profile.effectiveCalorieGoal,
          mode: profile.calorieGoalMode,
        ),
      );
    }
    if (_goalHistory.isEmpty) {
      _goalHistory.add(
        GoalHistoryEntry(
          effectiveFrom: effectiveFrom,
          goal: profile.goal,
          targetWeightKg: profile.targetWeightKg,
        ),
      );
    }
    _persistGoalHistories();
  }

  void _loadDailyState() {
    final todayKey = localDateKey(_now());
    _activeDayKey = todayKey;

    final savedDays = _foodBox.get('days');
    if (savedDays is Map) {
      for (final day in savedDays.entries) {
        if (day.key is! String || day.value is! List) continue;
        final entries = <FoodEntry>[];
        for (final value in day.value as List) {
          final entry = FoodEntry.tryFromJson(value);
          if (entry != null && localDateKey(entry.time) == day.key) {
            entries.add(entry);
          }
        }
        if (entries.isNotEmpty) _foodHistory[day.key as String] = entries;
      }
    }

    final savedFoodKey = storedLocalDateKey(
      _foodBox.get('dayKey') ?? _foodBox.get('today_date'),
    );
    final savedFood = _foodBox.get('today');
    if (_foodHistory[todayKey] case final entries?) {
      _todayFood.addAll(entries);
    } else if (savedFoodKey == todayKey && savedFood is List) {
      for (final value in savedFood) {
        final entry = FoodEntry.tryFromJson(value);
        if (entry != null && localDateKey(entry.time) == todayKey) {
          _todayFood.add(entry);
        }
      }
    }
    _foodHistory[todayKey] = List<FoodEntry>.of(_todayFood);
    _persistFood();

    final savedWaterHistory = _userBox.get('waterHistory');
    if (savedWaterHistory is Map) {
      for (final entry in savedWaterHistory.entries) {
        if (entry.key is String &&
            entry.value is num &&
            (entry.value as num).isFinite) {
          _waterHistory[entry.key as String] = (entry.value as num)
              .toDouble()
              .clamp(0, 10);
        }
      }
    }

    final waterKey = storedLocalDateKey(_userBox.get('waterDate'));
    final savedWater = _userBox.get('water');
    if (_waterHistory[todayKey] case final stored?) {
      waterLiters = stored;
    } else if (waterKey == todayKey &&
        savedWater is num &&
        savedWater.isFinite) {
      waterLiters = savedWater.toDouble().clamp(0, 10);
    } else {
      waterLiters = 0;
    }
    _waterHistory[todayKey] = waterLiters;
    _persistWater();
  }

  void _loadWeightHistory() {
    final savedWeights = _weightBox.get('history');
    if (savedWeights is List) {
      final ids = <String>{};
      var migrated = false;
      for (final value in savedWeights) {
        final entry = WeightEntry.tryFromJson(value);
        if (entry != null) {
          var unique = entry;
          while (!ids.add(unique.id)) {
            unique = WeightEntry(
              id: '${entry.id}-${newEntryId().substring(0, 8)}',
              date: entry.date,
              kg: entry.kg,
              source: entry.source,
            );
            migrated = true;
          }
          weightHistory.add(unique);
        }
      }
      weightHistory.sort((a, b) => a.date.compareTo(b.date));
      if (migrated) _persistWeights();
    }

    // Never seed a pre-onboarding default value. For an onboarded legacy user
    // with no history, the current profile weight is the only honest point.
    if (savedWeights == null && weightHistory.isEmpty && profile.onboarded) {
      _addInitialWeight(profile.joinedAt, profile.weightKg);
    } else if (weightHistory.isNotEmpty && profile.onboarded) {
      _syncProfileWeightFromHistory();
      _userBox.put('profile', profile.toJson());
    }
  }

  /// Called on resume and before every daily mutation. Civil-date keys include
  /// the year and intentionally follow the user's current local timezone.
  void refreshForCurrentDay() {
    if (!_loaded) return;
    unawaited(refreshWeightForecast());
    final todayKey = localDateKey(_now());
    if (_activeDayKey == todayKey) return;
    unawaited(refreshDailyTip());

    final followedActiveDay = selectedDateKey == _activeDayKey;

    _syncDailyBalance();
    _activeDayKey = todayKey;
    if (followedActiveDay) _selectedDate = today;
    _todayFood.clear();
    _todayFood.addAll(_foodHistory[todayKey] ?? const <FoodEntry>[]);
    waterLiters = 0;
    waterLiters = _waterHistory[todayKey] ?? 0;
    todaySteps = null;
    _persistFood();
    _persistWater();
    _updateStreak();
    _syncDailyBalance();
    notifyListeners();
  }

  bool selectDashboardDate(DateTime date) {
    final local = date.toLocal();
    final selected = DateTime(local.year, local.month, local.day);
    if (selected.isAfter(today) || selected.isBefore(firstUsageDate)) {
      return false;
    }
    if (localDateKey(selected) == selectedDateKey) return true;
    _selectedDate = selected;
    notifyListeners();
    return true;
  }

  DashboardDaySnapshot dashboardDay([DateTime? date]) {
    final selected = date == null
        ? _selectedDate
        : DateTime(date.year, date.month, date.day);
    final key = localDateKey(selected);
    final entries = List<FoodEntry>.unmodifiable(
      _foodHistory[key] ?? const <FoodEntry>[],
    );
    final saved = _dailyBalances[key];
    final calories = entries.fold<int>(0, (sum, entry) => sum + entry.kcal);
    final protein = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.proteinG,
    );
    final fat = entries.fold<double>(0, (sum, entry) => sum + entry.fatG);
    final carbs = entries.fold<double>(0, (sum, entry) => sum + entry.carbsG);
    final isToday = key == localDateKey(today);
    return DashboardDaySnapshot(
      date: selected,
      dateKey: key,
      caloriesConsumed: calories,
      calorieGoal: calorieGoalForDate(key),
      protein: protein,
      fat: fat,
      carbs: carbs,
      waterConsumedLiters: _waterHistory[key] ?? saved?.waterLiters ?? 0,
      waterGoalLiters: _waterGoalLiters,
      steps: isToday ? (todaySteps ?? saved?.stepCount) : saved?.stepCount,
      foodEntries: entries,
    );
  }

  int calorieGoalForDate(String dateKey) {
    final stored = _dailyBalances[dateKey]?.calorieTarget;
    if (stored != null) return stored;
    CalorieGoalHistoryEntry? match;
    for (final entry in _calorieGoalHistory) {
      if (localDateKey(entry.effectiveFrom).compareTo(dateKey) <= 0 &&
          (match == null || entry.effectiveFrom.isAfter(match.effectiveFrom))) {
        match = entry;
      }
    }
    return match?.calories ?? profile.effectiveCalorieGoal;
  }

  List<FoodEntry> mealEntriesForDate(String dateKey, MealType meal) =>
      foodEntriesForDate(dateKey).where((entry) => entry.meal == meal).toList()
        ..sort((a, b) => a.time.compareTo(b.time));

  void _updateStreak() {
    streakDays = _currentUsefulStreak(_activeDateKeys());
    _userBox.put('streak', streakDays);
  }

  int get caloriesEaten => _todayFood.fold(0, (sum, entry) => sum + entry.kcal);
  int get caloriesRemaining => max(0, profile.calorieTarget - caloriesEaten);
  double get proteinEaten =>
      _todayFood.fold(0, (sum, entry) => sum + entry.proteinG);
  double get fatEaten => _todayFood.fold(0, (sum, entry) => sum + entry.fatG);
  double get carbsEaten =>
      _todayFood.fold(0, (sum, entry) => sum + entry.carbsG);

  List<FoodEntry> mealEntries(MealType meal) =>
      _todayFood.where((entry) => entry.meal == meal).toList()
        ..sort((a, b) => a.time.compareTo(b.time));

  Future<bool> addFood(FoodEntry entry) async {
    refreshForCurrentDay();
    return addFoodForDate(entry, _activeDayKey ?? localDateKey(_now()));
  }

  Future<bool> addFoodForDate(FoodEntry entry, String dateKey) async {
    if (!_isEditableDateKey(dateKey)) return false;
    final validated = FoodEntry.tryFromJson(entry.toJson());
    if (validated == null || localDateKey(validated.time) != dateKey) {
      return false;
    }
    final entries = _foodHistory.putIfAbsent(dateKey, () => <FoodEntry>[]);
    entries.add(validated);
    if (dateKey == _activeDayKey) {
      _todayFood
        ..clear()
        ..addAll(entries);
      await _persistFood();
    } else {
      await _persistFoodHistory();
    }
    _syncDailyBalanceForDate(dateKey);
    await persistPendingMutations();
    notifyListeners();
    return true;
  }

  Future<void> removeFood(String id) async {
    refreshForCurrentDay();
    await removeFoodForDate(id, _activeDayKey ?? localDateKey(_now()));
  }

  Future<void> removeFoodForDate(String id, String dateKey) async {
    if (!_isEditableDateKey(dateKey)) return;
    final entries = _foodHistory[dateKey];
    if (entries == null) return;
    entries.removeWhere((entry) => entry.id == id);
    if (dateKey == _activeDayKey) {
      _todayFood
        ..clear()
        ..addAll(entries);
      await _persistFood();
    } else {
      await _persistFoodHistory();
    }
    _syncDailyBalanceForDate(dateKey);
    await persistPendingMutations();
    notifyListeners();
  }

  Future<bool> updateFoodGrams(String id, double grams) async {
    refreshForCurrentDay();
    return updateFoodGramsForDate(
      id,
      grams,
      _activeDayKey ?? localDateKey(_now()),
    );
  }

  Future<bool> updateFoodGramsForDate(
    String id,
    double grams,
    String dateKey,
  ) async {
    if (!_isEditableDateKey(dateKey)) return false;
    if (!grams.isFinite || grams < 1 || grams > 5000) return false;
    final entries = _foodHistory[dateKey];
    if (entries == null) return false;
    final index = entries.indexWhere((entry) => entry.id == id);
    if (index == -1) return false;
    final current = entries[index];
    if (current.grams <= 0) return false;
    final factor = grams / current.grams;
    final updated = FoodEntry(
      id: current.id,
      name: current.name,
      grams: grams,
      kcal: (current.kcal * factor).round(),
      proteinG: current.proteinG * factor,
      fatG: current.fatG * factor,
      carbsG: current.carbsG * factor,
      meal: current.meal,
      time: current.time,
      colorSeed: current.colorSeed,
      productId: current.productId,
      productVersion: current.productVersion,
      productSource: current.productSource,
      sourceType: current.sourceType,
      recipeId: current.recipeId,
      recipeVersion: current.recipeVersion,
    );
    final validated = FoodEntry.tryFromJson(updated.toJson());
    if (validated == null) return false;
    entries[index] = validated;
    if (dateKey == _activeDayKey) {
      _todayFood
        ..clear()
        ..addAll(entries);
      await _persistFood();
    } else {
      await _persistFoodHistory();
    }
    _syncDailyBalanceForDate(dateKey);
    await persistPendingMutations();
    notifyListeners();
    return true;
  }

  Future<bool> addWater(double liters) async {
    refreshForCurrentDay();
    if (!liters.isFinite || liters <= 0) return false;
    return addWaterForDate(liters, _activeDayKey ?? localDateKey(_now()));
  }

  Future<void> _waterCommitTail = Future<void>.value();
  Timer? _waterDerivedTimer;
  final Set<String> _pendingWaterDerived = {};
  bool _disposed = false;

  Future<bool> addWaterForDate(double liters, String dateKey) {
    if (!_isEditableDateKey(dateKey) ||
        !liters.isFinite ||
        liters <= 0 ||
        liters > 2) {
      return Future.value(false);
    }
    return _queueWaterCommit(liters, dateKey, additive: true);
  }

  Future<bool> setWater(double liters) async {
    refreshForCurrentDay();
    if (!liters.isFinite || liters < 0 || liters > 10) return false;
    return setWaterForDate(liters, _activeDayKey ?? localDateKey(_now()));
  }

  Future<bool> setWaterForDate(double liters, String dateKey) {
    if (!_isEditableDateKey(dateKey) ||
        !liters.isFinite ||
        liters < 0 ||
        liters > 10) {
      return Future.value(false);
    }
    return _queueWaterCommit(liters, dateKey, additive: false);
  }

  Future<bool> _queueWaterCommit(
    double liters,
    String key, {
    required bool additive,
  }) {
    final result = _waterCommitTail.then(
      (_) => _commitWaterForDate(
        additive ? min(10, (_waterHistory[key] ?? 0) + liters) : liters,
        key,
      ),
    );
    _waterCommitTail = result.then<void>((_) {});
    return result;
  }

  Future<bool> _commitWaterForDate(double liters, String key) async {
    final previousTrace = WaterSaveTrace.latest;
    final trace =
        previousTrace != null &&
            !previousTrace.microseconds.containsKey('commitStart')
        ? previousTrace
        : WaterSaveTrace();
    trace.mark('commitStart');
    try {
      final nextHistory = Map<String, double>.of(_waterHistory)..[key] = liters;
      final writer = _waterWriter;
      trace.mark('primaryStart');
      if (writer == null) {
        await _userBox.putAll({
          'waterHistory': nextHistory,
          if (key == _activeDayKey) 'water': liters,
          if (key == _activeDayKey) 'waterDate': key,
        });
        await _userBox.flush();
      } else {
        await writer(liters, key);
      }
      trace.mark('primaryPersist');
      if (_disposed) return true;
      _waterHistory[key] = liters;
      if (key == _activeDayKey) waterLiters = liters;
      _syncDailyBalanceForDate(key, persist: false);
      super.notifyListeners();
      trace.mark('state');
      _pendingWaterDerived.add(key);
      _waterDerivedTimer?.cancel();
      _waterDerivedTimer = Timer(const Duration(milliseconds: 350), () async {
        if (_disposed || !_userBox.isOpen) return;
        final keys = _pendingWaterDerived.toList();
        _pendingWaterDerived.clear();
        for (final dateKey in keys) {
          try {
            await _syncDailyBalanceForDate(dateKey);
          } catch (_) {
            /* Canonical water is already durable. */
          }
        }
        if (_disposed) return;
        notifyListeners();
        trace.mark('derived');
      });
      return true;
    } catch (_) {
      trace.mark('failed');
      return false;
    }
  }

  Future<double> setWaterGoalLiters(double liters) async {
    if (!liters.isFinite) return _waterGoalLiters;
    _waterGoalLiters = liters.clamp(minWaterGoalLiters, maxWaterGoalLiters);
    await _userBox.put('waterGoalLiters', _waterGoalLiters);
    await _userBox.flush();
    _invalidateAnalytics();
    notifyListeners();
    return _waterGoalLiters;
  }

  bool _isEditableDateKey(String dateKey) =>
      storedLocalDateKey(dateKey) == dateKey &&
      dateKey.compareTo(localDateKey(today)) <= 0;

  Future<void> updateProfile(UserProfile next) async {
    final persisted = _userBox.get('profile');
    final previous = persisted is Map
        ? UserProfile.fromJson(Map<dynamic, dynamic>.from(persisted))
        : UserProfile.fromJson(profile.toJson());
    final wasOnboarded = previous.onboarded;
    profile = UserProfile.fromJson(next.toJson());
    await _userBox.put('profile', profile.toJson());
    if (!wasOnboarded && profile.onboarded && weightHistory.isEmpty) {
      _addInitialWeight(profile.joinedAt, profile.weightKg);
    }
    if (profile.onboarded) {
      if (!wasOnboarded ||
          previous.effectiveCalorieGoal != profile.effectiveCalorieGoal ||
          previous.calorieGoalMode != profile.calorieGoalMode) {
        _recordCalorieGoalHistory();
      }
      if (!wasOnboarded ||
          previous.goal != profile.goal ||
          (previous.targetWeightKg - profile.targetWeightKg).abs() >= 0.05) {
        _recordGoalHistory();
      }
      _seedGoalHistoriesIfNeeded();
    }
    _invalidateAnalytics();
    _syncDailyBalance();
    await persistPendingMutations();
    notifyListeners();
  }

  Future<void> resetPersonalData() async {
    _waterDerivedTimer?.cancel();
    _pendingWaterDerived.clear();
    await _waterCommitTail;
    await dailyTips.pending;
    await _weightForecastCache?.pending;
    _stopActivityMotion();
    await _userBox.clear();
    await _foodBox.clear();
    await _weightBox.clear();
    if (!identical(_achievementsBox, _userBox)) {
      await _achievementsBox.clear();
    }
    await LocalStore.migrateBoxes(
      user: _userBox,
      food: _foodBox,
      weight: _weightBox,
    );
    profile = UserProfile();
    _waterGoalLiters = maxWaterGoalLiters;
    stepAccess = StepAccessState.loading;
    todaySteps = null;
    stepsError = null;
    _loaded = false;
    await load();
  }

  void _sortBodyMeasurements() => _bodyMeasurements.sort((a, b) {
    final order = a.date.compareTo(b.date);
    return order == 0 ? a.id.compareTo(b.id) : order;
  });

  Future<void> _saveBodyMeasurements(List<BodyMeasurement> next) async {
    await _userBox.put(
      'bodyMeasurements',
      next.map((entry) => entry.toJson()).toList(),
    );
    await _userBox.flush();
    _bodyMeasurements
      ..clear()
      ..addAll(next);
    _sortBodyMeasurements();
    notifyListeners();
  }

  Future<bool> _mutateBodyMeasurements(
    List<BodyMeasurement>? Function() change,
  ) {
    _pendingBodyWrites++;
    final result = _bodyWrites.then((_) async {
      final next = change();
      if (next == null) return false;
      await _saveBodyMeasurements(next);
      return true;
    });
    _bodyWrites = result.then<void>(
      (_) {
        _pendingBodyWrites--;
      },
      onError: (Object _, StackTrace _) {
        _pendingBodyWrites--;
      },
    );
    return result;
  }

  Future<bool> addBodyMeasurement({
    required BodyMeasurementType type,
    required double cm,
    DateTime? date,
  }) async {
    final measuredAt = date ?? _now();
    if (!BodyMeasurement.validValue(cm) || !_validWeightDate(measuredAt)) {
      return false;
    }
    return _mutateBodyMeasurements(
      () => [
        ..._bodyMeasurements,
        BodyMeasurement(id: newEntryId(), date: measuredAt, type: type, cm: cm),
      ],
    );
  }

  Future<bool> updateBodyMeasurement(
    String id, {
    required double cm,
    required DateTime date,
  }) async {
    if (!BodyMeasurement.validValue(cm) || !_validWeightDate(date)) {
      return false;
    }
    return _mutateBodyMeasurements(() {
      final index = _bodyMeasurements.indexWhere((entry) => entry.id == id);
      if (index < 0) return null;
      final next = [..._bodyMeasurements];
      next[index] = BodyMeasurement(
        id: id,
        date: date,
        type: next[index].type,
        cm: cm,
      );
      return next;
    });
  }

  Future<bool> deleteBodyMeasurement(String id) async {
    return _mutateBodyMeasurements(() {
      if (!_bodyMeasurements.any((entry) => entry.id == id)) return null;
      return _bodyMeasurements.where((entry) => entry.id != id).toList();
    });
  }

  Future<bool> addWeightEntry(
    double kg, {
    DateTime? date,
    WeightEntrySource source = WeightEntrySource.manual,
  }) async {
    if (!kg.isFinite || kg < 20 || kg > 400) return false;
    final measuredAt = date ?? _now();
    if (!_validWeightDate(measuredAt)) return false;
    final previousCalorieGoal = profile.effectiveCalorieGoal;
    weightHistory.add(
      WeightEntry(id: newEntryId(), date: measuredAt, kg: kg, source: source),
    );
    weightHistory.sort((a, b) => a.date.compareTo(b.date));
    _syncProfileWeightFromHistory();
    _recordAutoCalorieChangeIfNeeded(previousCalorieGoal);
    await _userBox.put('profile', profile.toJson());
    await _persistWeights();
    _invalidateAnalytics();
    _syncDailyBalance();
    await persistPendingMutations();
    notifyListeners();
    return true;
  }

  Future<bool> updateWeightEntry(
    String id, {
    required double kg,
    required DateTime date,
  }) async {
    if (!kg.isFinite || kg < 20 || kg > 400 || !_validWeightDate(date)) {
      return false;
    }
    final index = weightHistory.indexWhere((entry) => entry.id == id);
    if (index == -1) return false;
    final previousCalorieGoal = profile.effectiveCalorieGoal;
    weightHistory[index] = weightHistory[index].copyWith(
      date: date,
      kg: kg,
      updatedAt: _now(),
    );
    weightHistory.sort((a, b) => a.date.compareTo(b.date));
    _syncProfileWeightFromHistory();
    _recordAutoCalorieChangeIfNeeded(previousCalorieGoal);
    await _userBox.put('profile', profile.toJson());
    await _persistWeights();
    _invalidateAnalytics();
    _syncDailyBalance();
    await persistPendingMutations();
    notifyListeners();
    return true;
  }

  Future<bool> deleteWeightEntry(String id) async {
    final index = weightHistory.indexWhere((entry) => entry.id == id);
    if (index == -1) return false;
    final previousCalorieGoal = profile.effectiveCalorieGoal;
    weightHistory.removeAt(index);
    _syncProfileWeightFromHistory();
    _recordAutoCalorieChangeIfNeeded(previousCalorieGoal);
    await _userBox.put('profile', profile.toJson());
    await _persistWeights();
    _invalidateAnalytics();
    _syncDailyBalance();
    await persistPendingMutations();
    notifyListeners();
    return true;
  }

  void _addInitialWeight(DateTime date, double kg) {
    weightHistory.add(WeightEntry(id: newEntryId(), date: date, kg: kg));
    _persistWeights();
    _invalidateAnalytics();
  }

  bool _validWeightDate(DateTime value) {
    final now = _now();
    final localNow = now.toLocal();
    final latestAllowed = DateTime(
      localNow.year,
      localNow.month,
      localNow.day + 1,
    );
    final earliestAllowed = DateTime(now.year - 50, now.month, now.day);
    return value.isBefore(latestAllowed) && !value.isBefore(earliestAllowed);
  }

  void _syncProfileWeightFromHistory() {
    if (weightHistory.isNotEmpty) profile.weightKg = weightHistory.last.kg;
  }

  Future<void> persistPendingMutations() async {
    if (_loaded) await dailyTips.pending;
    await _weightForecastCache?.pending;
    if (_pendingBodyWrites > 0) await _bodyWrites;
    await Future.wait(
      {
        _userBox,
        _foodBox,
        _weightBox,
        _achievementsBox,
      }.map((box) => box.flush()),
    );
  }

  Future<void> _persistFood() {
    final key = _activeDayKey ?? localDateKey(_now());
    _foodHistory[key] = List<FoodEntry>.of(_todayFood);
    return _foodBox.putAll({
      'days': _foodHistory.map(
        (day, entries) =>
            MapEntry(day, entries.map((entry) => entry.toJson()).toList()),
      ),
      'today': _todayFood.map((entry) => entry.toJson()).toList(),
      'dayKey': key,
      'today_date': key,
    });
  }

  Future<void> _persistFoodHistory() => _foodBox.put(
    'days',
    _foodHistory.map(
      (day, entries) =>
          MapEntry(day, entries.map((entry) => entry.toJson()).toList()),
    ),
  );

  void _persistWater() {
    final key = _activeDayKey ?? localDateKey(_now());
    _waterHistory[key] = waterLiters;
    _userBox.put('waterHistory', _waterHistory);
    _userBox.put('water', waterLiters);
    _userBox.put('waterDate', key);
  }

  Future<void> _persistWeights() async {
    weightForecast = const WeightForecastSnapshot();
    await _weightBox.put(
      'history',
      weightHistory.map((entry) => entry.toJson()).toList(),
    );
    await refreshWeightForecast(notify: false);
  }

  void _recordAutoCalorieChangeIfNeeded(int previousCalories) {
    if (profile.calorieGoalMode == CalorieGoalMode.auto &&
        profile.effectiveCalorieGoal != previousCalories) {
      _recordCalorieGoalHistory();
    }
  }

  void _recordCalorieGoalHistory() {
    final entry = CalorieGoalHistoryEntry(
      effectiveFrom: _now(),
      calories: profile.effectiveCalorieGoal,
      mode: profile.calorieGoalMode,
    );
    if (_calorieGoalHistory.isNotEmpty &&
        _calorieGoalHistory.last.calories == entry.calories &&
        _calorieGoalHistory.last.mode == entry.mode) {
      return;
    }
    _calorieGoalHistory.add(entry);
    _persistGoalHistories();
  }

  void _recordGoalHistory() {
    final entry = GoalHistoryEntry(
      effectiveFrom: _now(),
      goal: profile.goal,
      targetWeightKg: profile.targetWeightKg,
    );
    if (_goalHistory.isNotEmpty &&
        _goalHistory.last.goal == entry.goal &&
        (_goalHistory.last.targetWeightKg - entry.targetWeightKg).abs() <
            0.05) {
      return;
    }
    _goalHistory.add(entry);
    _persistGoalHistories();
  }

  void _persistGoalHistories() {
    _userBox.put(
      'calorieGoalHistory',
      _calorieGoalHistory.map((entry) => entry.toJson()).toList(),
    );
    _userBox.put(
      'goalHistory',
      _goalHistory.map((entry) => entry.toJson()).toList(),
    );
  }

  Future<void> refreshSteps() async {
    if (!_loaded) return;
    stepsLoading = true;
    stepsError = null;
    notifyListeners();
    try {
      final status = await _healthService.getStatus();
      stepAccess = status;
      if (status == StepAccessState.authorized) {
        todaySteps = await _healthService.readTodaySteps();
        _startActivityMotion();
      } else {
        todaySteps = null;
        _stopActivityMotion();
      }
    } on HealthServiceException catch (error) {
      todaySteps = null;
      if (error.code == 'denied') {
        stepAccess = StepAccessState.denied;
      } else {
        stepsError = error.code;
      }
    } finally {
      stepsLoading = false;
      _syncDailyBalance();
      notifyListeners();
    }
  }

  Future<void> connectSteps() async {
    if (!_loaded) return;
    stepsLoading = true;
    stepsError = null;
    notifyListeners();
    try {
      stepAccess = await _healthService.requestAccess();
      if (stepAccess == StepAccessState.authorized) {
        todaySteps = await _healthService.readTodaySteps();
        _startActivityMotion();
      } else {
        todaySteps = null;
        _stopActivityMotion();
      }
    } on HealthServiceException catch (error) {
      if (error.code == 'denied') {
        stepAccess = StepAccessState.denied;
      } else {
        stepsError = error.code;
      }
    } finally {
      stepsLoading = false;
      _syncDailyBalance();
      notifyListeners();
    }
  }

  Future<void> openHealthSettings() => _healthService.openSettings();

  void _startActivityMotion() {
    _activitySubscription ??= _activityMotionService.signals().listen((signal) {
      final next = _activityStateMachine.update(signal, _now());
      final changed =
          activitySignalAvailable != signal.available ||
          activityMotionState != next;
      activitySignalAvailable = signal.available;
      activityMotionState = next;
      if (changed) notifyListeners();
    });
  }

  void _stopActivityMotion() {
    unawaited(_activitySubscription?.cancel());
    _activitySubscription = null;
    activitySignalAvailable = false;
    activityMotionState = ActivityMotionState.idle;
  }

  void _syncDailyBalance() =>
      _syncDailyBalanceForDate(_activeDayKey ?? localDateKey(_now()));

  Future<void> _syncDailyBalanceForDate(
    String key, {
    bool persist = true,
  }) async {
    if (!_loaded) return;
    final entries = _foodHistory[key] ?? const <FoodEntry>[];
    final isToday = key == localDateKey(today);
    final previous = _dailyBalances[key];
    _dailyBalances[key] = DailyBalanceSnapshot(
      dateKey: key,
      caloriesEaten: entries.fold(0, (sum, entry) => sum + entry.kcal),
      calorieTarget: isToday ? profile.calorieTarget : calorieGoalForDate(key),
      maintenanceCalories: profile.maintenanceCalorieEstimate,
      stepCount: isToday
          ? (todaySteps ?? previous?.stepCount)
          : previous?.stepCount,
      waterLiters: _waterHistory[key] ?? previous?.waterLiters ?? 0,
      proteinG: entries.fold(0, (sum, entry) => sum + entry.proteinG),
      fatG: entries.fold(0, (sum, entry) => sum + entry.fatG),
      carbsG: entries.fold(0, (sum, entry) => sum + entry.carbsG),
      mealCount: entries.length,
      mealMinutes: [
        for (final entry in entries) entry.time.hour * 60 + entry.time.minute,
      ],
      estimatedWeightKg: previous?.estimatedWeightKg,
    );
    _invalidateAnalytics();
    if (!persist) return;
    unawaited(
      _userBox
          .put(
            'dailyBalances',
            dailyBalances.map((entry) => entry.toJson()).toList(),
          )
          .catchError((Object _) {}),
    );
    if (isToday) _recordTodayAdvice(analyticsForDays(30).advice.type);
  }

  void _recordTodayAdvice(AdviceType type) {
    final key = _activeDayKey ?? localDateKey(_now());
    final index = _adviceHistory.indexWhere((entry) => entry.dateKey == key);
    final entry = DailyAdviceHistoryEntry(dateKey: key, type: type);
    if (index == -1) {
      _adviceHistory.add(entry);
    } else if (_adviceHistory[index].type == type) {
      return;
    } else {
      _adviceHistory[index] = entry;
    }
    _adviceHistory.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    unawaited(
      _userBox
          .put(
            'adviceHistory',
            _adviceHistory.map((value) => value.toJson()).toList(),
          )
          .catchError((Object _) {}),
    );
  }

  WeightTrendEstimate? get weightTrend {
    final analytics = analyticsForDays(30);
    final slope = analytics.forecast?.slopePerDay;
    if (slope == null || analytics.forecastPoints.isEmpty) return null;
    return WeightTrendEstimate(
      daysUsed: analytics.forecast!.spanDays,
      delta7DaysKg: slope * 7,
      predictedWeightKg: analytics.forecastPoints.last.kg,
    );
  }

  WeightAnalytics analyticsForDays(int periodDays) {
    final now = _now();
    final day = localDateKey(now);
    if (_analyticsCacheDay != day) {
      _analyticsCache.clear();
      _analyticsCacheDay = day;
    }
    final safeDays = periodDays.clamp(7, 365);
    return _analyticsCache.putIfAbsent(
      safeDays,
      () => _analyticsService.calculate(
        profile: profile,
        weights: weightHistory,
        dailyBalances: dailyBalances,
        periodDays: safeDays,
        now: now,
        waterGoalLiters: _waterGoalLiters,
        calorieGoalHistory: calorieGoalHistory,
        previousAdviceType: _previousAdviceType(),
        forecastSnapshot: weightForecast,
      ),
    );
  }

  AdviceType? _previousAdviceType() {
    final today = _activeDayKey ?? localDateKey(_now());
    for (final entry in _adviceHistory.reversed) {
      if (entry.dateKey.compareTo(today) < 0) return entry.type;
    }
    return null;
  }

  void _invalidateAnalytics() {
    _analyticsCache.clear();
    if (_loaded) dailyTips.context = tipContext;
  }

  DateTime? get latestActualWeightDate =>
      weightHistory.isEmpty ? null : weightHistory.last.date;

  int? get averageSteps7Days {
    final withSteps = dailyBalances
        .where((entry) => entry.stepCount != null)
        .toList();
    if (withSteps.isEmpty) return null;
    final recent = withSteps.length > 7
        ? withSteps.sublist(withSteps.length - 7)
        : withSteps;
    return (recent.fold<int>(0, (sum, day) => sum + day.stepCount!) /
            recent.length)
        .round();
  }

  double get totalWeightChange {
    if (weightHistory.isEmpty) return 0;
    return weightHistory.first.kg - profile.weightKg;
  }

  int get bestUsefulStreak => _bestStreak(_activeDateKeys());

  Set<String> get activeDateKeys => Set.unmodifiable(_activeDateKeys());

  AchievementProgress? takeNextAchievementReveal() {
    if (_pendingAchievementReveals.isEmpty) return null;
    return _pendingAchievementReveals.removeAt(0);
  }

  Future<void> updateReminderSettings(ReminderSettings value) async {
    reminderSettings = value;
    await _userBox.put('notificationSettings', value.toJson());
    await _userBox.flush();
    notifyListeners();
  }

  Future<void> setNotificationPermission(NotificationPermissionState value) =>
      updateReminderSettings(reminderSettings.copyWith(permission: value));

  Future<void> saveManualReminder(ManualReminder reminder) async {
    final index = _manualReminders.indexWhere((item) => item.id == reminder.id);
    if (index == -1) {
      _manualReminders.add(reminder);
    } else {
      _manualReminders[index] = reminder;
    }
    await _persistManualReminders();
    await _userBox.flush();
    notifyListeners();
  }

  Future<void> deleteManualReminder(String id) async {
    _manualReminders.removeWhere((item) => item.id == id);
    await _persistManualReminders();
    await _userBox.flush();
    notifyListeners();
  }

  List<ReminderCandidate> smartReminderPlan({DateTime? now}) {
    final value = now ?? _now();
    return _smartReminderEngine.plan(
      SmartReminderContext(
        now: value,
        settings: reminderSettings,
        todayFood: todayFood,
        foodHistory: allFoodEntries,
        waterLiters: waterLiters,
        waterGoalLiters: waterGoalLiters,
        steps: todaySteps,
        latestWeightDate: latestActualWeightDate,
        advice:
            dailyTips.currentTip?.ru.body ??
            'Откройте Balance, чтобы посмотреть идею дня.',
        manualReminders: manualReminders,
      ),
    );
  }

  void _loadReminderSettings() {
    final raw = _userBox.get('notificationSettings');
    if (raw is Map) {
      reminderSettings = ReminderSettings.fromJson(
        Map<dynamic, dynamic>.from(raw),
      );
    }
    final reminders = _userBox.get('manualReminders');
    if (reminders is List) {
      for (final item in reminders.whereType<Map>()) {
        final reminder = ManualReminder.fromJson(
          Map<dynamic, dynamic>.from(item),
        );
        if (reminder.id.isNotEmpty) _manualReminders.add(reminder);
      }
    }
  }

  Future<void> _persistManualReminders() => _userBox.put(
    'manualReminders',
    _manualReminders.map((item) => item.toJson()).toList(),
  );

  void _loadAchievementUnlocks() {
    _achievementUnlocks.clear();
    final raw = _achievementsBox.get('unlockedAt');
    if (raw is! Map) return;
    for (final entry in raw.entries) {
      final date = DateTime.tryParse(entry.value?.toString() ?? '');
      if (date != null) _achievementUnlocks[entry.key.toString()] = date;
    }
  }

  void _refreshAchievements() {
    if (!_loaded) return;
    final evaluation = _achievementEngine.evaluate(
      metrics: _achievementMetrics(),
      persistedUnlocks: _achievementUnlocks,
      now: _now(),
    );
    _achievementProgress = evaluation.achievements;
    if (evaluation.newlyUnlocked.isNotEmpty) {
      _pendingAchievementReveals.addAll(evaluation.newlyUnlocked);
    }
    if (evaluation.unlockedAt.length != _achievementUnlocks.length) {
      _achievementUnlocks
        ..clear()
        ..addAll(evaluation.unlockedAt);
      _achievementsBox.put(
        'unlockedAt',
        _achievementUnlocks.map(
          (id, date) => MapEntry(id, date.toUtc().toIso8601String()),
        ),
      );
    }
    _updateStreak();
  }

  AchievementMetrics _achievementMetrics() {
    final initialWeight = weightHistory.isEmpty
        ? profile.weightKg
        : weightHistory.first.kg;
    final currentWeight = weightHistory.isEmpty
        ? profile.weightKg
        : weightHistory.last.kg;
    final progressKg = switch (profile.goal) {
      Goal.lose => initialWeight - currentWeight,
      Goal.gain => currentWeight - initialWeight,
      Goal.hold => 0.0,
    };
    final initialDistance = (initialWeight - profile.targetWeightKg).abs();
    final currentDistance = (currentWeight - profile.targetWeightKg).abs();
    final goalPercent = initialDistance <= .05
        ? 100.0
        : ((initialDistance - currentDistance) / initialDistance * 100).clamp(
            0,
            100,
          );
    final activeKeys = _activeDateKeys();
    final stepValues = <int>[
      for (final day in _dailyBalances.values)
        if (day.stepCount != null) day.stepCount!,
      if (todaySteps != null) todaySteps!,
    ];
    final weightKeys = weightHistory
        .map((entry) => localDateKey(entry.date))
        .toSet();
    final completeDays = activeKeys.where((key) {
      final balance = _dailyBalances[key];
      return (_foodHistory[key]?.isNotEmpty ?? false) &&
          (_waterHistory[key] ?? 0) > 0 &&
          weightKeys.contains(key) &&
          (balance?.stepCount ?? 0) > 0;
    }).length;
    return AchievementMetrics({
      'weightEntries': weightHistory.length.toDouble(),
      'weightProgressKg': max(0.0, progressKg),
      'weightGoalPercent': goalPercent.toDouble(),
      'foodEntries': _foodHistory.values
          .fold<int>(0, (sum, items) => sum + items.length)
          .toDouble(),
      'foodDays': _foodHistory.values
          .where((items) => items.isNotEmpty)
          .length
          .toDouble(),
      'balancedDays': _dailyBalances.values
          .where((day) {
            final target = day.calorieTarget;
            if (day.mealCount == 0 || target == null || target <= 0) {
              return false;
            }
            final ratio = day.caloriesEaten / target;
            return ratio >= .85 && ratio <= 1.15;
          })
          .length
          .toDouble(),
      'proteinGoalDays': _dailyBalances.values
          .where((day) {
            return day.mealCount > 0 && day.proteinG >= profile.proteinTargetG;
          })
          .length
          .toDouble(),
      'waterDays': _waterHistory.values
          .where((value) => value > 0)
          .length
          .toDouble(),
      'waterGoalDays': _waterHistory.values
          .where((value) => value >= waterGoalLiters)
          .length
          .toDouble(),
      'maxDailySteps': stepValues.isEmpty
          ? 0
          : stepValues.reduce(max).toDouble(),
      'averageSteps7': (averageSteps7Days ?? 0).toDouble(),
      'stepsGoalDays': _dailyBalances.values
          .where((day) => (day.stepCount ?? 0) >= 10000)
          .length
          .toDouble(),
      'bestActiveStreak': _bestStreak(activeKeys).toDouble(),
      'recipes': userRecipes.length.toDouble(),
      'activeDays': activeKeys.length.toDouble(),
      'completeDays': completeDays.toDouble(),
      'daysSinceJoined': today
          .difference(
            DateTime(
              profile.joinedAt.year,
              profile.joinedAt.month,
              profile.joinedAt.day,
            ),
          )
          .inDays
          .toDouble(),
    });
  }

  Set<String> _activeDateKeys() {
    final keys = <String>{};
    for (final entry in _foodHistory.entries) {
      if (entry.value.isNotEmpty) keys.add(entry.key);
    }
    for (final entry in _waterHistory.entries) {
      if (entry.value > 0) keys.add(entry.key);
    }
    keys.addAll(weightHistory.map((entry) => localDateKey(entry.date)));
    for (final day in _dailyBalances.values) {
      if ((day.stepCount ?? 0) > 0) keys.add(day.dateKey);
    }
    return keys;
  }

  int _bestStreak(Set<String> keys) {
    if (keys.isEmpty) return 0;
    final days = keys.map(_dateFromKey).whereType<DateTime>().toList()..sort();
    var best = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      final difference = days[i].difference(days[i - 1]).inDays;
      if (difference == 1) {
        current++;
        best = max(best, current);
      } else if (difference > 1) {
        current = 1;
      }
    }
    return best;
  }

  int _currentUsefulStreak(Set<String> keys) {
    if (keys.isEmpty) return 0;
    final todayKey = localDateKey(today);
    final yesterdayKey = localDateKey(today.subtract(const Duration(days: 1)));
    var cursor = keys.contains(todayKey)
        ? today
        : keys.contains(yesterdayKey)
        ? today.subtract(const Duration(days: 1))
        : null;
    if (cursor == null) return 0;
    var result = 0;
    while (keys.contains(localDateKey(cursor!))) {
      result++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return result;
  }

  @override
  void notifyListeners() {
    _refreshAchievements();
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _waterDerivedTimer?.cancel();
    unawaited(_activitySubscription?.cancel());
    super.dispose();
  }
}

DateTime? _dateFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  final value = DateTime(year, month, day);
  return value.year == year && value.month == month && value.day == day
      ? value
      : null;
}
