import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/track_data.dart';
import 'package:racing/game/components/car/car_physics.dart';
import 'package:racing/game/components/props/cone_component.dart';
import 'package:racing/game/components/props/pickup_component.dart';
import 'package:racing/game/components/track/track_map.dart';

/// Walls, car-to-car collisions and props (cones, pads, coins, nitro).
///
/// Pure physics: it changes car positions and velocities and reports events
/// through callbacks. Run [step] once per fixed update after the cars moved.
///
/// Each car is two circles (nose and tail). Walls are not shapes: the barrier
/// is simply "farther than [TrackMap.wallDistance] from the road centerline",
/// which cannot be tunnelled through and costs two track queries per car.
class CollisionSystem {
  CollisionSystem({
    required this.track,
    required this.cars,
    this.cones = const [],
    this.pickups = const [],
    this.player,
  });

  final TrackMap track;
  final List<CarPhysics> cars;
  final List<ConeComponent> cones;
  final List<PickupComponent> pickups;

  /// Only the player collects coins.
  final CarPhysics? player;

  void Function(
    CarPhysics car,
    Vector2 point,
    Vector2 normalOut,
    double impact,
    double slide,
  )? onWall;
  void Function(CarPhysics a, CarPhysics b, Vector2 point, double impact)?
      onCarHit;
  void Function(CarPhysics car, PropType type)? onPickup;
  void Function(CarPhysics car)? onConeHit;
  void Function(CarPhysics car)? onBoostPad;

  late final List<PropSpawn> _pads =
      track.props.where((p) => p.type == PropType.boostPad).toList();

  void step(double dt) {
    for (final car in cars) {
      resolveWall(car, dt);
    }
    for (var i = 0; i < cars.length; i++) {
      for (var j = i + 1; j < cars.length; j++) {
        resolveCars(cars[i], cars[j]);
      }
    }
    for (final car in cars) {
      _props(car);
    }
  }

  // --------------------------------------------------------------- walls ----

  /// Keeps [car] inside the barriers. Returns the strongest impact speed.
  double resolveWall(CarPhysics car, double dt) {
    final limit = track.wallDistance - GameConfig.carCircleRadius;
    final fx = math.cos(car.heading);
    final fy = math.sin(car.heading);
    var strongest = 0.0;

    for (final sign in const [1.0, -1.0]) {
      final ox = fx * GameConfig.carCircleOffset * sign;
      final oy = fy * GameConfig.carCircleOffset * sign;
      final px = car.position.x + ox;
      final py = car.position.y + oy;
      final q = track.query(Vector2(px, py), hint: car.trackHint);
      if (q.distance <= limit) continue;

      var nx = px - q.closest.x;
      var ny = py - q.closest.y;
      final len = math.sqrt(nx * nx + ny * ny);
      if (len < 1e-6) continue;
      nx /= len;
      ny /= len;

      // Push the car back inside.
      final penetration = q.distance - limit;
      car.position.x -= nx * penetration;
      car.position.y -= ny * penetration;
      car.wallContact = 0.25;

      final vOut = car.velocity.x * nx + car.velocity.y * ny;
      var impact = 0.0;
      if (vOut > 0) {
        impact = vOut;
        final j = (1 + GameConfig.wallRestitution) * vOut;
        car.velocity.x -= nx * j;
        car.velocity.y -= ny * j;

        // Lose some speed along the wall too.
        final vn = car.velocity.x * nx + car.velocity.y * ny;
        final tx = car.velocity.x - nx * vn;
        final ty = car.velocity.y - ny * vn;
        final keep = 1 - GameConfig.wallFriction;
        car.velocity.x = nx * vn + tx * keep;
        car.velocity.y = ny * vn + ty * keep;

        // An impact at the nose or tail turns the car.
        final fxImpulse = -nx * j;
        final fyImpulse = -ny * j;
        final torque = ox * fyImpulse - oy * fxImpulse;
        car.heading += torque * GameConfig.wallYawFactor;
      }

      // Scraping along the wall slows the car down.
      final drag = math.max(0.0, 1 - GameConfig.wallScrapeDrag * dt);
      final vn2 = car.velocity.x * nx + car.velocity.y * ny;
      final tx2 = car.velocity.x - nx * vn2;
      final ty2 = car.velocity.y - ny * vn2;
      car.velocity.x = nx * vn2 + tx2 * drag;
      car.velocity.y = ny * vn2 + ty2 * drag;

      final slide = math.sqrt(tx2 * tx2 + ty2 * ty2);
      strongest = math.max(strongest, impact);
      onWall?.call(
        car,
        Vector2(px + nx * GameConfig.carCircleRadius,
            py + ny * GameConfig.carCircleRadius),
        Vector2(nx, ny),
        impact,
        slide,
      );
    }
    return strongest;
  }

  // ------------------------------------------------------------ car vs car --

  /// Pushes two overlapping cars apart, heavier cars move less.
  /// Returns the strongest impact speed.
  double resolveCars(CarPhysics a, CarPhysics b) {
    const r = GameConfig.carCircleRadius;
    const minDist = r * 2;
    final afx = math.cos(a.heading);
    final afy = math.sin(a.heading);
    final bfx = math.cos(b.heading);
    final bfy = math.sin(b.heading);
    final invA = 1 / a.mass;
    final invB = 1 / b.mass;
    final sumInv = invA + invB;
    var strongest = 0.0;

    for (final sa in const [1.0, -1.0]) {
      for (final sb in const [1.0, -1.0]) {
        final aox = afx * GameConfig.carCircleOffset * sa;
        final aoy = afy * GameConfig.carCircleOffset * sa;
        final box = bfx * GameConfig.carCircleOffset * sb;
        final boy = bfy * GameConfig.carCircleOffset * sb;
        final dx = (a.position.x + aox) - (b.position.x + box);
        final dy = (a.position.y + aoy) - (b.position.y + boy);
        final d2 = dx * dx + dy * dy;
        if (d2 >= minDist * minDist || d2 < 1e-9) continue;

        final d = math.sqrt(d2);
        final nx = dx / d;
        final ny = dy / d;
        final pen = minDist - d;

        a.position.x += nx * pen * (invA / sumInv);
        a.position.y += ny * pen * (invA / sumInv);
        b.position.x -= nx * pen * (invB / sumInv);
        b.position.y -= ny * pen * (invB / sumInv);

        final rvx = a.velocity.x - b.velocity.x;
        final rvy = a.velocity.y - b.velocity.y;
        final vn = rvx * nx + rvy * ny;
        if (vn < 0) {
          final j = -(1 + GameConfig.carRestitution) * vn / sumInv;
          a.velocity.x += nx * j * invA;
          a.velocity.y += ny * j * invA;
          b.velocity.x -= nx * j * invB;
          b.velocity.y -= ny * j * invB;

          // Off-center hits spin the cars a little.
          a.heading +=
              (aox * ny * j - aoy * nx * j) * GameConfig.carYawFactor * invA;
          b.heading -=
              (box * ny * j - boy * nx * j) * GameConfig.carYawFactor * invB;

          final impact = -vn;
          strongest = math.max(strongest, impact);
          onCarHit?.call(
            a,
            b,
            Vector2(
              (a.position.x + aox + b.position.x + box) / 2,
              (a.position.y + aoy + b.position.y + boy) / 2,
            ),
            impact,
          );
        }
      }
    }
    return strongest;
  }

  // ----------------------------------------------------------------- props --

  void _props(CarPhysics car) {
    final fx = math.cos(car.heading);
    final fy = math.sin(car.heading);
    final ax = car.position.x + fx * GameConfig.carCircleOffset;
    final ay = car.position.y + fy * GameConfig.carCircleOffset;
    final bx = car.position.x - fx * GameConfig.carCircleOffset;
    final by = car.position.y - fy * GameConfig.carCircleOffset;

    bool hits(double x, double y, double radius) {
      final reach = radius + GameConfig.carCircleRadius;
      final r2 = reach * reach;
      final d1x = x - ax;
      final d1y = y - ay;
      if (d1x * d1x + d1y * d1y < r2) return true;
      final d2x = x - bx;
      final d2y = y - by;
      return d2x * d2x + d2y * d2y < r2;
    }

    for (final cone in cones) {
      if (cone.knocked) continue;
      if (hits(cone.position.x, cone.position.y, cone.radius)) {
        cone.knock(
          Vector2(car.velocity.x * 0.8, car.velocity.y * 0.8),
          spin: 6 + math.Random().nextDouble() * 8,
        );
        car.velocity.scale(GameConfig.coneHitSlowdown);
        onConeHit?.call(car);
      }
    }

    for (final pickup in pickups) {
      if (pickup.collected) continue;
      if (pickup.type == PropType.coin && !identical(car, player)) continue;
      if (hits(pickup.position.x, pickup.position.y, pickup.radius)) {
        pickup.collect();
        if (pickup.type == PropType.nitro) {
          car.addNitro(GameConfig.nitroPickupAmount);
        }
        onPickup?.call(car, pickup.type);
      }
    }

    final padHalfLength = GameConfig.padLength / 2;
    final padHalfWidth = track.data.roadWidth * GameConfig.padWidthFactor / 2;
    for (final pad in _pads) {
      final rx = car.position.x - pad.position.x;
      final ry = car.position.y - pad.position.y;
      final along = rx * pad.tangent.x + ry * pad.tangent.y;
      final across = rx * pad.normal.x + ry * pad.normal.y;
      if (along.abs() <= padHalfLength &&
          across.abs() <= padHalfWidth &&
          car.boostTime < GameConfig.padBoostSeconds * 0.5) {
        car.applyBoost(GameConfig.padBoostSeconds, GameConfig.padKick);
        onBoostPad?.call(car);
      }
    }
  }
}
