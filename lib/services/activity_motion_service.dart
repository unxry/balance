import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ActivityMotionState { idle, walk, run }

class ActivitySignal {
  const ActivitySignal({
    required this.available,
    this.stationary = false,
    this.walking = false,
    this.running = false,
    this.cadence,
  });

  final bool available;
  final bool stationary;
  final bool walking;
  final bool running;
  final double? cadence;

  factory ActivitySignal.fromMap(Object? value) {
    final map = value is Map ? Map<Object?, Object?>.from(value) : const {};
    final cadence = map['cadence'];
    return ActivitySignal(
      available: map['available'] == true,
      stationary: map['stationary'] == true,
      walking: map['walking'] == true,
      running: map['running'] == true,
      cadence: cadence is num && cadence.isFinite ? cadence.toDouble() : null,
    );
  }
}

class ActivityStateMachine {
  ActivityStateMachine({
    this.enterRunCadence = 2.25,
    this.exitRunCadence = 1.75,
    this.walkCadence = .35,
    this.runExitDelay = const Duration(milliseconds: 400),
    this.idleDelay = const Duration(milliseconds: 500),
  });

  final double enterRunCadence;
  final double exitRunCadence;
  final double walkCadence;
  final Duration runExitDelay;
  final Duration idleDelay;

  ActivityMotionState state = ActivityMotionState.idle;
  DateTime? _runExitStartedAt;
  DateTime? _idleStartedAt;

  ActivityMotionState update(ActivitySignal signal, DateTime now) {
    if (!signal.available) return state;
    final cadence = signal.cadence ?? 0;
    final wantsRun = signal.running || cadence >= enterRunCadence;
    final keepsRun = signal.running || cadence >= exitRunCadence;
    final wantsWalk = signal.walking || cadence >= walkCadence;

    if (wantsRun) {
      _runExitStartedAt = null;
      _idleStartedAt = null;
      return state = ActivityMotionState.run;
    }

    if (state == ActivityMotionState.run && keepsRun) {
      _runExitStartedAt = null;
      _idleStartedAt = null;
      return state;
    }

    if (state == ActivityMotionState.run && wantsWalk) {
      _runExitStartedAt ??= now;
      if (now.difference(_runExitStartedAt!) < runExitDelay) return state;
      _runExitStartedAt = null;
      _idleStartedAt = null;
      return state = ActivityMotionState.walk;
    }

    if (wantsWalk) {
      _runExitStartedAt = null;
      _idleStartedAt = null;
      return state = ActivityMotionState.walk;
    }

    if (signal.stationary || cadence < walkCadence) {
      _idleStartedAt ??= now;
      if (now.difference(_idleStartedAt!) >= idleDelay) {
        _runExitStartedAt = null;
        return state = ActivityMotionState.idle;
      }
    }
    return state;
  }
}

class ActivityMotionService {
  static const EventChannel _channel = EventChannel('balance/activity_motion');

  Stream<ActivitySignal> signals() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return const Stream<ActivitySignal>.empty();
    }
    return _channel
        .receiveBroadcastStream()
        .map(ActivitySignal.fromMap)
        .handleError((Object _) {});
  }
}
