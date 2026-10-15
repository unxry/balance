import 'dart:developer' as developer;

class WaterSaveTrace {
  WaterSaveTrace() {
    assert(() {
      _clock.start();
      mark('tap');
      return true;
    }());
  }

  static WaterSaveTrace? latest;
  final Stopwatch _clock = Stopwatch();
  final Map<String, int> microseconds = {};

  void mark(String step) {
    assert(() {
      latest = this;
      microseconds[step] = _clock.elapsedMicroseconds;
      developer.Timeline.instantSync('water.$step');
      return true;
    }());
  }
}
