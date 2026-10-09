import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/data/models/ai_profile.dart';
import 'package:racing/game/components/car/car_physics.dart';
import 'package:racing/game/components/track/track_map.dart';
import 'package:racing/game/systems/input_controller.dart';
import 'package:racing/game/systems/racing_line.dart';

enum AiMode { driving, reversing }

/// The AI driver's brain. It produces the same [DriveInput] a player would,
/// so the car physics is identical for AI and player.
///
/// Every think step (30 times a second) it:
///  1. checks if the car is stuck or spun out and recovers,
///  2. looks at nearby cars and picks a sideways offset to pass or avoid,
///  3. steers toward a look-ahead point on the racing line (pure pursuit),
///  4. picks a target speed from the speed profile and brakes or accelerates,
///  5. now and then makes a small mistake, depending on the difficulty.
class AiController implements DriveInput {
  AiController({
    required this.line,
    required this.profile,
    math.Random? random,
  }) : _rnd = random ?? math.Random() {
    reset();
  }

  final RacingLine line;
  final AiProfile profile;
  final math.Random _rnd;

  late final SpeedProfile _speed = line.buildSpeedProfile(
    maxSpeed: profile.stats.maxSpeed,
    steering: profile.stats.steering,
    cornerSafety: profile.difficulty.cornerSafety,
    decel: profile.stats.braking * profile.brakeFactor,
  );

  // ---- DriveInput outputs --------------------------------------------------
  double _steer = 0;
  double _throttle = 0;
  double _brake = 0;
  bool _nitro = false;

  @override
  double get steer => _steer;

  @override
  double get throttle => _throttle;

  @override
  double get brake => _brake;

  @override
  bool get handbrake => false;

  @override
  bool get nitro => _nitro;

  // ---- Debug / state -------------------------------------------------------
  AiMode mode = AiMode.driving;

  /// Point the car is aiming at.
  final Vector2 target = Vector2.zero();
  double targetSpeed = 0;

  /// How far ahead (px) the traffic sensor looks, for the debug view.
  double sensorReach = 0;

  /// Half-width (px) of the traffic sensor lane, for the debug view.
  double sensorLane = 0;

  /// True when the car keeps getting stuck; the game puts it back on track.
  bool wantsRespawn = false;

  double _clock = 0;
  double _lineBias = 0;
  double _lateral = 0;
  double _wantOffset = 0;
  double _trafficCap = double.infinity;
  double _passSide = 0;
  double _passTimer = 0;

  double _mistakeTimer = 0;
  int _mistakeKind = 0;
  double _mistakeSign = 1;

  double _stuckTime = 0;
  double _spunTime = 0;
  double _reverseTime = 0;
  int _recoveries = 0;
  double _recoveryAge = 0;

  /// Full reset for a new race. Picks a new random line offset.
  void reset() {
    final half = line.track.halfWidth;
    _lineBias =
        (_rnd.nextDouble() * 2 - 1) * profile.personality.lineBiasRange * half;
    _recoveries = 0;
    _recoveryAge = 0;
    _passSide = 0;
    _passTimer = 0;
    _mistakeTimer = 0;
    _mistakeKind = 0;
    onRespawned();
    _lateral = 0;
    targetSpeed = 0;
    mode = AiMode.driving;
  }

  /// Called after the car was placed back on the road.
  void onRespawned() {
    wantsRespawn = false;
    mode = AiMode.driving;
    _stuckTime = 0;
    _spunTime = 0;
    _reverseTime = 0;
    _recoveries = 0;
    _clock = GameConfig.aiThinkInterval; // think on the very next update
    _setIdle();
  }

  void _setIdle() {
    _steer = 0;
    _throttle = 0;
    _brake = 0;
    _nitro = false;
  }

  /// Call every fixed step. [gapToPlayer] is how many px this car is ahead of
  /// the player (negative = behind), or null to switch rubber-banding off.
  void update(
    double dt, {
    required CarPhysics car,
    required TrackQuery query,
    required List<CarPhysics> others,
    required bool racing,
    required bool finished,
    required double? gapToPlayer,
  }) {
    _clock += dt;
    if (_clock < GameConfig.aiThinkInterval) return;
    final h = _clock;
    _clock = 0;
    if (!racing) {
      _setIdle();
      return;
    }
    _think(h, car, query, others, finished, gapToPlayer);
  }

  // ----------------------------------------------------------------- think --

  void _think(
    double dt,
    CarPhysics car,
    TrackQuery q,
    List<CarPhysics> others,
    bool finished,
    double? gapToPlayer,
  ) {
    final track = line.track;
    final idx = q.index;
    final n = line.count;
    final stats = car.stats;
    final half = track.halfWidth;
    final speed = car.speed;
    final fwd = car.forwardSpeed;
    final tan = track.tangents[idx];
    final trackAngle = math.atan2(tan.y, tan.x);

    _recoveryAge += dt;
    if (_recoveryAge > GameConfig.aiRecoveryWindow) {
      _recoveryAge = 0;
      _recoveries = 0;
    }

    // ---- 1. Recovery -------------------------------------------------------
    if (mode == AiMode.reversing) {
      _reverse(dt, car, trackAngle);
      return;
    }
    if (!finished && _isStuck(dt, car, trackAngle, speed)) {
      _startRecovery();
      _reverse(dt, car, trackAngle);
      return;
    }

    // ---- 2. Mistakes -------------------------------------------------------
    _mistakeTimer -= dt;
    if (_mistakeTimer <= 0) {
      _mistakeKind = 0;
      if (!finished && speed > GameConfig.aiMistakeMinSpeed) {
        final chance = profile.mistakesPerMinute / 60 * dt;
        if (_rnd.nextDouble() < chance) {
          _mistakeKind = 1 + _rnd.nextInt(3);
          _mistakeTimer = 0.5 + 0.5 * _rnd.nextDouble();
          _mistakeSign = _rnd.nextBool() ? 1 : -1;
        }
      }
    }

    // ---- 3. Traffic and sideways offset -----------------------------------
    _scanTraffic(dt, car, q, speed, others);
    final maxSlide = GameConfig.aiLateralRate * dt;
    _lateral += clampD(_wantOffset - _lateral, -maxSlide, maxSlide);

    // ---- 4. Steering (pure pursuit toward a look-ahead point) -------------
    final lookDist = clampD(
      GameConfig.aiLookMin + speed * profile.lookTime,
      GameConfig.aiLookMin,
      GameConfig.aiLookMax,
    );
    final ahead = math.max(2, (lookDist / line.spacing).round());
    final j = (idx + ahead) % n;
    final limit = half - GameConfig.aiEdgeMargin;
    final off = clampD(line.offsets[j] + _lateral, -limit, limit);
    final cj = track.points[j];
    final nj = track.normals[j];
    target.setValues(cj.x + nj.x * off, cj.y + nj.y * off);

    final dx = target.x - car.position.x;
    final dy = target.y - car.position.y;
    final dist = math.max(1.0, math.sqrt(dx * dx + dy * dy));
    final err = wrapAngle(math.atan2(dy, dx) - car.heading);

    var steer = 0.0;
    if (err.abs() > GameConfig.aiTurnAroundAngle) {
      steer = err >= 0 ? 1.0 : -1.0;
    } else {
      final prop = clampD(err * GameConfig.aiSteerGain, -1, 1);
      final v = fwd.abs();
      final low = math.max(0.1, clampD(v / GameConfig.steerFullSpeed, 0, 1));
      final ratio = clampD(v / stats.maxSpeed, 0, 1);
      final avail =
          stats.steering * low * (1 - GameConfig.highSpeedSteerLoss * ratio);
      final needed = v * 2 * math.sin(err) / dist;
      final pursuit = clampD(needed / avail, -1, 1);
      steer = lerpD(prop, pursuit, clampD((v - 30) / 60, 0, 1));
    }
    if (_mistakeKind == 1) steer += _mistakeSign * 0.35;
    _steer = clampD(steer, -1, 1);

    // ---- 5. Speed ----------------------------------------------------------
    var tgt = math.min(_speed.target[idx], _speed.target[(idx + 2) % n]);
    tgt *= profile.speedScale * _rubber(gapToPlayer);
    if (_mistakeKind == 2) tgt *= 1.2;
    tgt *= 1 - 0.5 * clampD((err.abs() - 0.35) / 0.8, 0, 1);
    tgt = math.min(tgt, _trafficCap);
    if (err.abs() > GameConfig.aiTurnAroundAngle) {
      tgt = math.min(tgt, GameConfig.aiTurnAroundSpeed);
    }

    // Nitro: only on a long straight with a decent meter.
    final wantNitro = !finished &&
        err.abs() < GameConfig.aiNitroMaxSteerError &&
        car.nitro >
            math.max(GameConfig.aiNitroMinMeter, 1 - profile.nitroUse) &&
        _speed.minAhead[idx] > stats.maxSpeed * 0.95 &&
        _trafficCap == double.infinity &&
        _mistakeKind == 0;
    _nitro = wantNitro;
    if (_nitro || car.boostActive) tgt *= GameConfig.nitroTopSpeedBoost;

    if (finished) tgt = stats.maxSpeed * GameConfig.aiFinishedCruise;
    targetSpeed = tgt;

    final diff = tgt - fwd;
    _throttle = clampD(diff / GameConfig.aiThrottleBand, 0, 1);
    _brake = 0;
    if (!_nitro &&
        diff < -GameConfig.aiBrakeDeadband &&
        fwd > GameConfig.reverseThreshold) {
      _brake = clampD(
        (-diff - GameConfig.aiBrakeDeadband) / GameConfig.aiBrakeBand,
        0,
        1,
      );
    }
    if (_mistakeKind == 3) {
      _throttle = math.min(_throttle, 0.25);
      _nitro = false;
    }
  }

  double _rubber(double? gap) {
    if (!GameConfig.aiRubberBand || gap == null) return 1;
    const dead = GameConfig.aiRubberDeadZone;
    const range = GameConfig.aiRubberRange;
    if (gap > dead) {
      return 1 - profile.difficulty.rubberSlow * clampD((gap - dead) / range, 0, 1);
    }
    if (gap < -dead) {
      return 1 +
          profile.difficulty.rubberBoost * clampD((-gap - dead) / range, 0, 1);
    }
    return 1;
  }

  // -------------------------------------------------------------- traffic --

  /// Looks for the nearest car in our lane and decides how to get past it.
  /// Sets [_wantOffset] (sideways offset from the racing line, px) and
  /// [_trafficCap] (speed limit while stuck behind a slower car).
  void _scanTraffic(
    double dt,
    CarPhysics car,
    TrackQuery q,
    double speed,
    List<CarPhysics> others,
  ) {
    final track = line.track;
    final idx = q.index;
    final t = track.tangents[idx];
    final half = track.halfWidth;
    final limitLat = half - GameConfig.aiEdgeMargin;

    final myLat = q.lateral * half;
    sensorReach = (GameConfig.aiSensorRange +
            speed * GameConfig.aiSensorSpeedFactor) *
        profile.personality.sensorScale;
    sensorLane = GameConfig.carWidth +
        GameConfig.aiSideGap +
        profile.personality.sideGapDelta;

    _trafficCap = double.infinity;
    _wantOffset = _lineBias;

    // Distance and sideways position of other cars are measured along the
    // road (using their own track position), so this also works in corners.
    CarPhysics? blocker;
    var bestAbs = sensorReach;
    var blockerAlong = 0.0;
    var blockerLat = 0.0;
    final near = (sensorReach + GameConfig.carLength) *
        (sensorReach + GameConfig.carLength);
    for (final o in others) {
      if (identical(o, car)) continue;
      final rx = o.position.x - car.position.x;
      final ry = o.position.y - car.position.y;
      if (rx * rx + ry * ry > near) continue;
      final oq = track.query(o.position, hint: o.trackHint);
      var dp = oq.progress - q.progress;
      if (dp > 0.5) dp -= 1;
      if (dp < -0.5) dp += 1;
      final along = dp * track.length;
      if (along < -GameConfig.aiAlongside || along > sensorReach) continue;
      final oLat = oq.lateral * half;
      if ((oLat - myLat).abs() > sensorLane) continue;
      if (along.abs() < bestAbs) {
        bestAbs = along.abs();
        blocker = o;
        blockerAlong = along;
        blockerLat = oLat;
      }
    }

    if (blocker == null) {
      // Forget the passing side once the road has been clear for a while.
      _passTimer += dt;
      if (_passTimer > GameConfig.aiPassHold) _passSide = 0;
      return;
    }
    _passTimer = 0;

    // Pick a side once and stick with it (no zig-zagging). Pick again only
    // if that side no longer has room.
    bool hasRoom(double side) =>
        (blockerLat + side * sensorLane).abs() <= limitLat;
    if (_passSide == 0 || !hasRoom(_passSide)) {
      final roomL = hasRoom(-1);
      final roomR = hasRoom(1);
      if (roomL && roomR) {
        if ((myLat - blockerLat).abs() > 6) {
          _passSide = myLat < blockerLat ? -1 : 1;
        } else {
          // Dead behind it: go toward the middle of the road.
          _passSide = blockerLat > 0 ? -1 : 1;
        }
      } else if (roomL) {
        _passSide = -1;
      } else if (roomR) {
        _passSide = 1;
      } else {
        _passSide = 0;
      }
    }
    if (_passSide != 0) {
      final absTarget =
          clampD(blockerLat + _passSide * sensorLane, -limitLat, limitLat);
      _wantOffset = absTarget - line.offsets[idx];
    }

    // Still right behind it: do not ram it, follow at its speed. If there is
    // room to go around, keep creeping so the car can actually steer around.
    if (blockerAlong > 0 &&
        (blockerLat - myLat).abs() < GameConfig.carWidth + 4) {
      final vo = blocker.velocity.x * t.x + blocker.velocity.y * t.y;
      var cap = vo +
          (blockerAlong - GameConfig.aiFollowDistance) *
              GameConfig.aiFollowGain;
      if (_passSide != 0) cap = math.max(cap, GameConfig.aiPassCreepSpeed);
      _trafficCap = math.max(0, cap);
    }
  }

  // ------------------------------------------------------------- recovery --

  bool _isStuck(double dt, CarPhysics car, double trackAngle, double speed) {
    if (speed < GameConfig.aiStuckSpeed && targetSpeed > 60) {
      _stuckTime += dt;
    } else {
      _stuckTime = math.max(0, _stuckTime - dt * 2);
    }

    final off = wrapAngle(trackAngle - car.heading).abs();
    if (off > GameConfig.aiSpunAngle && speed < 160) {
      _spunTime += dt;
    } else {
      _spunTime = math.max(0, _spunTime - dt);
    }

    return _stuckTime > GameConfig.aiStuckSeconds ||
        _spunTime > GameConfig.aiSpunSeconds;
  }

  void _startRecovery() {
    mode = AiMode.reversing;
    _reverseTime = GameConfig.aiReverseSeconds * (0.8 + 0.4 * _rnd.nextDouble());
    _stuckTime = 0;
    _spunTime = 0;
    _recoveries++;
    _recoveryAge = 0;
    if (_recoveries >= GameConfig.aiRespawnAfterRecoveries) {
      wantsRespawn = true;
    }
  }

  /// Backs up while turning the nose toward the road direction.
  void _reverse(double dt, CarPhysics car, double trackAngle) {
    _reverseTime -= dt;
    final err = wrapAngle(trackAngle - car.heading);
    _throttle = 0;
    _brake = 1;
    _nitro = false;
    // Steering is mirrored while reversing, so the sign is flipped.
    _steer = err >= 0 ? -1.0 : 1.0;
    targetSpeed = 0;
    if (_reverseTime <= 0) {
      mode = AiMode.driving;
      _stuckTime = 0;
      _spunTime = 0;
      _setIdle();
    }
  }
}
