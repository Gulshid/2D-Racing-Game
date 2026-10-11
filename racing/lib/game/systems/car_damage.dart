import 'dart:math' as math;

import 'package:racing/core/constants/game_config.dart';
import 'package:racing/core/utils/math_utils.dart';

/// Wear on one car. Pure Dart so it can be unit tested.
///
/// [damage] runs from 0 (new) to [GameConfig.damageMax]. Damage lowers top
/// speed and acceleration a little ([performance]) and makes the car pull
/// to one side ([steerPull]). It never stops the car from racing.
class CarDamage {
  CarDamage({int seed = 7}) : _pullSign = seed.isEven ? 1 : -1;

  final double _pullSign;
  double _damage = 0;

  /// 0 = pristine, up to [GameConfig.damageMax].
  double get damage => _damage;

  /// 1 = pristine, 0 = worst possible. This is what the HUD shows.
  double get integrity => clampD(1 - _damage / GameConfig.damageMax, 0, 1);

  /// Multiplier (about 0.7..1) for top speed and acceleration.
  double get performance =>
      1 - (1 - GameConfig.damageMinPerformance) * (_damage / GameConfig.damageMax);

  /// Constant sideways steering bias; only noticeable above ~35% damage.
  double get steerPull {
    final over = math.max(0.0, _damage - 0.3) / (GameConfig.damageMax - 0.3);
    return _pullSign * GameConfig.damageSteerPull * over;
  }

  bool get isDamaged => _damage > 0.01;

  /// Adds damage for an impact at [impactSpeed] px/s. [factor] scales it
  /// (car hits use [GameConfig.damageCarHitFactor]). Returns the amount added.
  double hit(double impactSpeed, {double factor = 1}) {
    final over = impactSpeed - GameConfig.damageMinImpact;
    if (over <= 0) return 0;
    final before = _damage;
    _damage = math.min(
      GameConfig.damageMax,
      _damage + over * GameConfig.damagePerSpeed * factor,
    );
    return _damage - before;
  }

  /// Removes [fraction] (0..1) of the current damage.
  void repair(double fraction) {
    _damage = _damage * (1 - clampD(fraction, 0, 1));
    if (_damage < 0.005) _damage = 0;
  }

  void reset() => _damage = 0;
}
