import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/models/surface_type.dart';
import 'package:racing/game/systems/input_controller.dart';

/// Arcade car physics. Pure Dart (no rendering) so it can be unit tested and
/// reused by AI cars. Call [step] at a fixed rate.
///
/// Heading 0 points along +x; positive heading turns clockwise on screen.
class CarPhysics {
  CarPhysics(this.stats);

  /// Can be replaced at runtime (tuning panel, upgrades).
  CarStats stats;

  final Vector2 position = Vector2.zero();
  final Vector2 velocity = Vector2.zero();
  double heading = 0;

  /// Smoothed steering, -1..1.
  double steerInput = 0;

  /// Nitro meter, 0..1.
  double nitro = 1;
  bool nitroActive = false;
  bool braking = false;

  double forwardSpeed = 0;
  double lateralSpeed = 0;
  SurfaceType surface = SurfaceType.asphalt;

  bool _nitroLocked = false;
  double _nitroDelay = 0;

  double get speed => velocity.length;
  bool get isDrifting =>
      lateralSpeed.abs() > GameConfig.driftThreshold && speed > 80;

  void reset(Vector2 pos, double newHeading) {
    position.setFrom(pos);
    velocity.setZero();
    heading = newHeading;
    steerInput = 0;
    nitro = 1;
    nitroActive = false;
    braking = false;
    forwardSpeed = 0;
    lateralSpeed = 0;
    _nitroLocked = false;
    _nitroDelay = 0;
  }

  void step(double dt, DriveInput input, SurfaceType surf) {
    if (dt <= 0) return;
    surface = surf;
    final s = stats;

    // ---- Steering smoothing (digital buttons -> smooth analog) -------------
    final target = clampD(input.steer, -1, 1);
    final sameDirection = target != 0 && target.sign == steerInput.sign;
    final rate = (target == 0 || (steerInput != 0 && !sameDirection))
        ? GameConfig.steerReturnRate
        : GameConfig.steerRiseRate;
    steerInput += clampD(target - steerInput, -rate * dt, rate * dt);

    // ---- Nitro --------------------------------------------------------------
    nitroActive = input.nitro && !_nitroLocked && nitro > 0;
    if (nitroActive) {
      nitro -= dt / s.nitroCapacity;
      _nitroDelay = GameConfig.nitroRegenDelay;
      if (nitro <= 0) {
        nitro = 0;
        _nitroLocked = true;
        nitroActive = false;
      }
    } else {
      if (_nitroDelay > 0) {
        _nitroDelay -= dt;
      } else {
        nitro = math.min(1, nitro + GameConfig.nitroRegenRate * dt);
      }
      if (_nitroLocked && nitro >= GameConfig.nitroUnlockLevel) {
        _nitroLocked = false;
      }
    }

    // ---- Heading (uses speed along the OLD heading) -------------------------
    var fx = math.cos(heading);
    var fy = math.sin(heading);
    var vF = velocity.x * fx + velocity.y * fy;
    final speedRatio = clampD(vF.abs() / s.maxSpeed, 0, 1);
    final lowSpeed = clampD(vF.abs() / GameConfig.steerFullSpeed, 0, 1);
    final dir = vF >= 0 ? 1.0 : -1.0;
    final handbrakeBoost = input.handbrake ? GameConfig.handbrakeSteerBoost : 1.0;
    heading += steerInput *
        s.steering *
        lowSpeed *
        (1 - GameConfig.highSpeedSteerLoss * speedRatio) *
        dir *
        handbrakeBoost *
        dt;
    if (heading > math.pi) {
      heading -= 2 * math.pi;
    } else if (heading < -math.pi) {
      heading += 2 * math.pi;
    }

    // ---- Split velocity into forward and sideways using the NEW heading ----
    fx = math.cos(heading);
    fy = math.sin(heading);
    final rx = -fy;
    final ry = fx;
    vF = velocity.x * fx + velocity.y * fy;
    var vL = velocity.x * rx + velocity.y * ry;

    // ---- Engine, brake, reverse --------------------------------------------
    final topSpeed = s.maxSpeed *
        surf.speed *
        (nitroActive ? GameConfig.nitroTopSpeedBoost : 1.0);
    final accel = s.acceleration * (nitroActive ? s.nitroPower : 1.0);
    final throttle = nitroActive ? 1.0 : clampD(input.throttle, 0, 1);
    final brake = clampD(input.brake, 0, 1);
    final traction = 0.35 + 0.65 * clampD(surf.grip, 0, 1);

    if (throttle > 0) {
      final ratio = clampD(vF / topSpeed, 0, 1);
      final falloff = 1 - ratio * ratio * ratio;
      vF += accel * throttle * falloff * traction * dt;
    }

    braking = false;
    if (brake > 0) {
      if (vF > GameConfig.reverseThreshold) {
        vF = math.max(0, vF - s.braking * brake * traction * dt);
        braking = true;
      } else {
        final reverseTop =
            s.maxSpeed * GameConfig.reverseSpeedFactor * surf.speed;
        final ratio = clampD(-vF / reverseTop, 0, 1);
        vF -= s.acceleration * 0.6 * brake * (1 - ratio) * traction * dt;
      }
    }

    if (throttle == 0 && brake == 0) {
      vF -= vF * GameConfig.rollingDrag * surf.drag * dt;
      if (vF.abs() < 4) vF = 0;
    }

    if (vF > topSpeed) {
      vF -= (vF - topSpeed) * math.min(1.0, GameConfig.overspeedDrag * dt);
    }

    // ---- Lateral grip (this is what makes drifting) -------------------------
    var gripRate = s.grip * surf.grip;
    gripRate *= 1 - s.slideTendency * steerInput.abs() * speedRatio;
    if (input.handbrake) {
      gripRate *= s.driftFactor;
      vF -= vF * GameConfig.handbrakeDrag * dt;
    }
    vL *= math.exp(-gripRate * dt);

    // ---- Recompose, cap, integrate ------------------------------------------
    velocity.x = fx * vF + rx * vL;
    velocity.y = fy * vF + ry * vL;

    final cap = s.maxSpeed * 1.6;
    final sp = velocity.length;
    if (sp > cap) velocity.scale(cap / sp);

    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    forwardSpeed = vF;
    lateralSpeed = vL;
  }
}
