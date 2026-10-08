/// Runs gameplay logic in equal time slices regardless of frame rate.
class FixedStepper {
  FixedStepper(this.step, {this.maxFrameTime = 0.1});

  final double step;
  final double maxFrameTime;
  double _accumulator = 0;

  /// 0..1 progress between two steps; used later for smooth rendering.
  double get alpha => _accumulator / step;

  /// Adds [dt] and calls [onStep] as many times as needed.
  /// Returns the number of steps executed.
  int run(double dt, void Function(double step) onStep) {
    _accumulator += dt > maxFrameTime ? maxFrameTime : dt;
    var steps = 0;
    while (_accumulator >= step) {
      onStep(step);
      _accumulator -= step;
      steps++;
    }
    return steps;
  }

  void reset() => _accumulator = 0;
}
