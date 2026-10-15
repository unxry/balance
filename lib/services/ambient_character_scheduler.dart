import 'dart:async';
import 'package:flutter/foundation.dart';

enum AmbientGait { idle, walk, run }

class AmbientCharacterScheduler extends ChangeNotifier {
  AmbientCharacterScheduler({DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  @visibleForTesting
  static int activeSchedulers = 0;
  static const _runMilliseconds = [10300, 9500, 11000, 8700];
  static const _idleMilliseconds = [2200, 2400, 1900, 2100];
  AmbientGait gait = AmbientGait.idle;
  bool transitioning = false;
  Timer? _timer;
  DateTime? _deadline;
  Duration _remaining = const Duration(milliseconds: 800);
  int _index = -1;
  int _generation = 0;
  bool _active = false;
  bool _disposed = false;

  void setActive(bool active) {
    if (_disposed || _active == active) return;
    activeSchedulers += active ? 1 : -1;
    _active = active;
    if (!active) {
      if (_deadline != null) {
        _remaining = _deadline!.difference(_now());
        if (_remaining.isNegative) _remaining = Duration.zero;
      }
      _generation++;
      _timer?.cancel();
      _timer = null;
      _deadline = null;
    } else if (!transitioning) {
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    final generation = ++_generation;
    _deadline = _now().add(_remaining);
    _timer = Timer(_remaining, () {
      if (_disposed || !_active || generation != _generation) return;
      _timer = null;
      _deadline = null;
      gait = gait == AmbientGait.idle ? AmbientGait.run : AmbientGait.idle;
      if (gait == AmbientGait.run) {
        _index = (_index + 1) % _runMilliseconds.length;
      }
      transitioning = true;
      notifyListeners();
    });
  }

  void transitionFinished() {
    if (_disposed || !transitioning) return;
    transitioning = false;
    _remaining = Duration(
      milliseconds: gait == AmbientGait.run
          ? _runMilliseconds[_index]
          : _idleMilliseconds[_index],
    );
    if (_active) _schedule();
  }

  @override
  void dispose() {
    if (_active) activeSchedulers--;
    _disposed = true;
    _generation++;
    _timer?.cancel();
    super.dispose();
  }
}
