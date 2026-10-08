import 'package:racing/core/utils/math_utils.dart';

/// What a driver (player or AI) asks the car to do.
abstract interface class DriveInput {
  /// -1 (left) .. 1 (right).
  double get steer;

  /// 0..1
  double get throttle;

  /// 0..1 (brake, then reverse when stopped).
  double get brake;
  bool get handbrake;
  bool get nitro;
}

/// One physical input source (touch buttons or keyboard).
class InputSource implements DriveInput {
  bool left = false;
  bool right = false;
  bool gas = false;
  bool brakePedal = false;
  bool handbrakeOn = false;
  bool nitroOn = false;

  @override
  double get steer => (right ? 1.0 : 0.0) - (left ? 1.0 : 0.0);

  @override
  double get throttle => gas ? 1.0 : 0.0;

  @override
  double get brake => brakePedal ? 1.0 : 0.0;

  @override
  bool get handbrake => handbrakeOn;

  @override
  bool get nitro => nitroOn;

  void reset() {
    left = false;
    right = false;
    gas = false;
    brakePedal = false;
    handbrakeOn = false;
    nitroOn = false;
  }
}

/// Combines touch and keyboard into one DriveInput for the player car.
class InputController implements DriveInput {
  final InputSource touch = InputSource();
  final InputSource keyboard = InputSource();

  @override
  double get steer => clampD(touch.steer + keyboard.steer, -1, 1);

  @override
  double get throttle => touch.throttle > keyboard.throttle
      ? touch.throttle
      : keyboard.throttle;

  @override
  double get brake => touch.brake > keyboard.brake ? touch.brake : keyboard.brake;

  @override
  bool get handbrake => touch.handbrake || keyboard.handbrake;

  @override
  bool get nitro => touch.nitro || keyboard.nitro;

  void reset() {
    touch.reset();
    keyboard.reset();
  }
}
