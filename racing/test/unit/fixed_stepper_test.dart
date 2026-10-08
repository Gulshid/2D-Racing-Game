import 'package:flutter_test/flutter_test.dart';
import 'package:racing_game/game/systems/fixed_stepper.dart';

void main() {
  test('runs the right number of steps and keeps the remainder', () {
    final stepper = FixedStepper(1 / 100);
    var count = 0;

    expect(stepper.run(0.035, (_) => count++), 3);
    expect(count, 3);

    // Remainder 0.005 + 0.006 = 0.011 -> one more step.
    expect(stepper.run(0.006, (_) => count++), 1);
  });

  test('clamps huge frame times', () {
    final stepper = FixedStepper(1 / 100, maxFrameTime: 0.055);
    var count = 0;
    stepper.run(5, (_) => count++);
    expect(count, 5);
  });
}
