import 'package:hive/hive.dart';

import '../data/daily_tips_catalog.dart';
import '../data/tip_sources.dart';
import '../models/daily_tip.dart';
import '../utils/calendar_date.dart';

abstract interface class DailyTipsRepository {
  Future<List<DailyTip>> load();
}

class OfflineDailyTipsRepository implements DailyTipsRepository {
  const OfflineDailyTipsRepository();
  @override
  Future<List<DailyTip>> load() async => dailyTipsCatalog;
}

abstract interface class DailyTipsStore {
  Object get identity;
  Object? read();
  Future<void> write(Map<String, Object> state);
}

class HiveDailyTipsStore implements DailyTipsStore {
  static const storageKey = 'dailyTipsV1';
  final Box<dynamic> box;
  HiveDailyTipsStore(this.box);
  @override
  Object get identity => box;
  @override
  Object? read() => box.get(storageKey);
  @override
  Future<void> write(Map<String, Object> state) async {
    final previous = box.get(storageKey);
    try {
      await box.put(storageKey, state);
      await box.flush();
    } catch (error, stack) {
      // Hive updates its in-memory value before flushing the file.
      try {
        if (previous == null) {
          await box.delete(storageKey);
        } else {
          await box.put(storageKey, previous);
        }
      } catch (_) {}
      Error.throwWithStackTrace(error, stack);
    }
  }
}

class DailyTipsService {
  final DailyTipsStore store;
  final DailyTipsRepository repository;
  final DateTime Function() _now;
  static final _queues = Expando<Future<void>>();
  List<DailyTip>? _catalog;
  List<TipVisit> _history = [];
  Set<String> _saved = {};
  bool _personalized = false;
  String? _currentDate;
  TipContext context = const TipContext();

  DailyTipsService({
    required this.store,
    this.repository = const OfflineDailyTipsRepository(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  bool get personalized => _personalized;
  List<TipVisit> get history => List.unmodifiable(_history);
  Set<String> get saved => Set.unmodifiable(_saved);
  DailyTip? tipById(String id) {
    for (final tip in _catalog ?? <DailyTip>[]) {
      if (tip.id == id) return tip;
    }
    return null;
  }

  TipVisit? get currentVisit {
    for (final visit in _history.reversed) {
      if (visit.dateKey == _currentDate) return visit;
    }
    return null;
  }

  DailyTip? get currentTip {
    final tip = tipById(currentVisit?.tipId ?? '');
    if (tip != null && !isSuitable(tip)) {
      return tipById('care-context')?.asLegacy(tip.id);
    }
    return tip;
  }

  bool isSuitable(DailyTip tip) =>
      !tip.weightManagementOnly ||
      (context.safety.allowsWeightManagement &&
          !context.maintenance &&
          !context.lowLoggedIntake);
  Future<void> get pending => _queues[store.identity] ?? Future<void>.value();

  Future<void> refresh({TipContext context = const TipContext()}) => _serial(
    () async {
      this.context = context;
      _catalog ??= List.unmodifiable(await repository.load());
      if (_catalog!.isEmpty ||
          _catalog!.map((tip) => tip.id).toSet().length != _catalog!.length) {
        throw StateError('Daily tips require a nonempty catalog of unique IDs');
      }
      _read();
      final date = localDateKey(_now());
      _currentDate = date;
      if (_history.any((visit) => visit.dateKey == date)) return;
      final tip = _select(date, context);
      final next = [
        ..._history,
        TipVisit(
          dateKey: date,
          tipId: tip.id,
          basis: tip.basis,
          reasonRu: context.reason(tip.basis, true),
          reasonEn: context.reason(tip.basis, false),
          catalogVersion: tip.version,
        ),
      ];
      await _write(history: next);
      _history = next;
    },
  );

  Future<void> setPersonalized(bool value) => _serial(() async {
    _read();
    await _write(personalized: value);
    _personalized = value;
  });

  Future<void> toggleSaved(String id) => _serial(() async {
    _read();
    if (tipById(id) == null) return;
    final next = {..._saved};
    if (!next.remove(id)) next.add(id);
    await _write(saved: next);
    _saved = next;
  });

  Future<void> setCompleted(String dateKey, bool completed) => _serial(
    () async {
      _read();
      final next = [
        for (final visit in _history)
          if (visit.dateKey == dateKey && tipById(visit.tipId)?.ru.task != null)
            TipVisit(
              dateKey: dateKey,
              tipId: visit.tipId,
              basis: visit.basis,
              completed: completed,
              reasonRu: visit.reasonRu,
              reasonEn: visit.reasonEn,
              catalogVersion: visit.catalogVersion,
            )
          else
            visit,
      ];
      await _write(history: next);
      _history = next;
    },
  );

  Future<void> _serial(Future<void> Function() operation) {
    final result = pending.then((_) => operation());
    // A failed write must not poison later retries or another service instance.
    _queues[store.identity] = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  DailyTip _select(String date, TipContext context) {
    var eligible = _catalog!
        .where(
          (tip) =>
              !tip.retired &&
              tip.sourceIds.isNotEmpty &&
              tip.sourceIds.every(tipSources.containsKey) &&
              tip.evidenceLevel != TipEvidenceLevel.unverified &&
              isSuitable(tip) &&
              (!tip.usesLoggedMacros ||
                  (context.distinctFoods >= 2 &&
                      context.loggedProteinG != null &&
                      context.loggedFatG != null &&
                      context.loggedCarbsG != null)) &&
              (tip.basis == TipBasis.universal ||
                  (_personalized && context.supports(tip.basis))),
        )
        .toList();
    if (eligible.isEmpty) throw StateError('No eligible daily tips');
    if (eligible.length > 1 && _history.isNotEmpty) {
      final previous = tipById(_history.last.tipId);
      final previousId = previous?.canonicalId ?? _history.last.tipId;
      eligible.removeWhere((tip) => tip.id == previousId);
    }
    final recent = <String>{};
    final lastSeen = <String, int>{};
    final completed = <String>{};
    for (var i = 0; i < _history.length; i++) {
      final visit = _history[i];
      final id = tipById(visit.tipId)?.canonicalId ?? visit.tipId;
      lastSeen[id] = i;
      if (visit.completed) completed.add(id);
      final age = calendarDayDifference(date, visit.dateKey);
      // Future civil dates can occur after travelling west. Keep them recent.
      if (age < 60) recent.add(id);
    }
    final fresh = eligible.where((tip) => !recent.contains(tip.id)).toList();
    if (fresh.isNotEmpty) eligible = fresh;
    final unseen = eligible
        .where((tip) => !lastSeen.containsKey(tip.id))
        .toList();
    if (unseen.isNotEmpty) {
      eligible = unseen;
    } else {
      final unfinished = eligible
          .where((tip) => !completed.contains(tip.id))
          .toList();
      if (unfinished.isNotEmpty) eligible = unfinished;
    }
    final previous = _history.isEmpty
        ? null
        : tipById(_history.last.tipId)?.category;
    if (_personalized &&
        (_history.isEmpty || _history.last.basis == TipBasis.universal)) {
      final relevant = eligible
          .where(
            (tip) =>
                tip.basis != TipBasis.universal && tip.category != previous,
          )
          .toList();
      if (relevant.isNotEmpty) {
        int priority(DailyTip tip) => switch (tip.basis) {
          TipBasis.gentleFuel => 3,
          TipBasis.maintenance => 2,
          TipBasis.plateau => 1,
          _ => 0,
        };
        relevant.sort((a, b) {
          final score = priority(b).compareTo(priority(a));
          return score != 0
              ? score
              : _rank(date, a.id).compareTo(_rank(date, b.id));
        });
        return relevant.first;
      }
    }
    final start = previous == null ? 0 : previous.index + 1;
    for (var offset = 0; offset < TipCategory.values.length; offset++) {
      final category =
          TipCategory.values[(start + offset) % TipCategory.values.length];
      final pool = eligible.where((tip) => tip.category == category).toList();
      if (pool.isEmpty) continue;
      pool.sort((a, b) {
        final age = (lastSeen[a.id] ?? -1).compareTo(lastSeen[b.id] ?? -1);
        if (age != 0) return age;
        final done = (completed.contains(a.id) ? 1 : 0).compareTo(
          completed.contains(b.id) ? 1 : 0,
        );
        if (done != 0) return done;
        // Prefer relevant, available context within the rotating category.
        final relevance = (b.basis == TipBasis.universal ? 0 : 1).compareTo(
          a.basis == TipBasis.universal ? 0 : 1,
        );
        if (relevance != 0) return relevance;
        return _rank(date, a.id).compareTo(_rank(date, b.id));
      });
      return pool.first;
    }
    throw StateError('No daily tip category');
  }

  int _rank(String date, String id) {
    var hash = 2166136261;
    for (final value in '$date:$id'.codeUnits) {
      hash = ((hash ^ value) * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  void _read() {
    final raw = store.read();
    if (raw == null) {
      _history = [];
      _saved = {};
      _personalized = false;
      return;
    }
    if (raw is! Map || raw['version'] != 1) {
      throw const FormatException('Unsupported daily tips state');
    }
    final seenDates = <String>{};
    _history = [
      if (raw['history'] is List)
        for (final item in raw['history'] as List)
          if (item is Map &&
              storedLocalDateKey(item['date']) == item['date'] &&
              item['date'] is String &&
              item['id'] is String &&
              seenDates.add(item['date'] as String))
            TipVisit(
              dateKey: item['date'] as String,
              tipId: item['id'] as String,
              basis: TipBasis.values.firstWhere(
                (value) => value.name == item['basis'],
                orElse: () => TipBasis.universal,
              ),
              completed: item['completed'] == true,
              reasonRu: item['reasonRu'] is String
                  ? item['reasonRu'] as String
                  : null,
              reasonEn: item['reasonEn'] is String
                  ? item['reasonEn'] as String
                  : null,
              catalogVersion: item['catalogVersion'] is int
                  ? item['catalogVersion'] as int
                  : 0,
            ),
    ];
    _saved = raw['saved'] is List
        ? (raw['saved'] as List).whereType<String>().toSet()
        : {};
    _personalized = raw['personalized'] == true;
  }

  Future<void> _write({
    List<TipVisit>? history,
    Set<String>? saved,
    bool? personalized,
  }) => store.write({
    'version': 1,
    'history': (history ?? _history).map((visit) => visit.toJson()).toList(),
    'saved': (saved ?? _saved).toList()..sort(),
    'personalized': personalized ?? _personalized,
  });
}
