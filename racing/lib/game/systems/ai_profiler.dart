/// Measures how much time the AI spends per frame (in milliseconds).
/// Used by the debug HUD to check the "under 2 ms per frame" target.
class AiProfiler {
  final Stopwatch _clock = Stopwatch()..start();
  int _t0 = 0;
  int _micros = 0;

  /// Smoothed cost of the AI per rendered frame, in milliseconds.
  double averageMs = 0;

  void begin() => _t0 = _clock.elapsedMicroseconds;

  void end() => _micros += _clock.elapsedMicroseconds - _t0;

  /// Call once per rendered frame.
  void endFrame() {
    final ms = _micros / 1000;
    averageMs += (ms - averageMs) * 0.05;
    _micros = 0;
  }
}
