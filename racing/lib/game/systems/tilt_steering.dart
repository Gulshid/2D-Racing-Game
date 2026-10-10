import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Turns phone tilt into steering, using the accelerometer.
///
/// Holding the phone in landscape like a steering wheel and turning it left or
/// right steers the car. The first reading after [recalibrate] is treated as
/// "straight", so each player can hold the phone however they like.
///
/// The output is [steer] (-1..1), the same range as the wheel and buttons, so
/// the car physics and the sensitivity setting work unchanged.
class TiltSteering {
  TiltSteering({
    this.fullTiltMs2 = 4.0,
    this.smoothing = 0.35,
    this.invert = false,
  });

  /// Change from straight, in m/s^2, that gives full lock (about 25 degrees).
  final double fullTiltMs2;

  /// 0..1. Higher reacts faster but jitters more.
  final double smoothing;

  /// Set to true if steering feels backwards on a device.
  final bool invert;

  /// Current steering, -1..1. Read every frame by the game.
  final ValueNotifier<double> steer = ValueNotifier<double>(0);

  /// True once the sensor has sent readings. False on devices without an
  /// accelerometer (for example the iOS Simulator).
  final ValueNotifier<bool> hasData = ValueNotifier<bool>(false);

  StreamSubscription<AccelerometerEvent>? _sub;
  bool _calibrate = true;
  double _neutralY = 0;
  double _sign = 1;
  double _smoothed = 0;

  /// Starts listening to the accelerometer. Safe to call twice.
  void start() {
    if (_sub != null) return;
    _sub = accelerometerEventStream().listen(
      _onEvent,
      onError: (Object _) => hasData.value = false,
      cancelOnError: false,
    );
  }

  /// Stops listening and centres the steering.
  void stop() {
    _sub?.cancel();
    _sub = null;
    steer.value = 0;
  }

  /// Makes the next reading the new "straight".
  void recalibrate() {
    _calibrate = true;
  }

  void _onEvent(AccelerometerEvent e) {
    if (!hasData.value) hasData.value = true;
    if (_calibrate) {
      // In landscape, gravity runs along x. Its sign tells which way the
      // phone is rotated (home button left or right), so steering keeps the
      // same direction in both landscape orientations.
      _neutralY = e.y;
      _sign = e.x >= 0 ? 1 : -1;
      _smoothed = 0;
      _calibrate = false;
    }
    final direction = invert ? -_sign : _sign;
    final raw = clampD(direction * (e.y - _neutralY) / fullTiltMs2, -1, 1);
    _smoothed += (raw - _smoothed) * smoothing;
    steer.value = _smoothed;
  }
}
