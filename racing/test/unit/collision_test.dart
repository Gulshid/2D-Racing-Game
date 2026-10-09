import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/models/surface_type.dart';
import 'package:racing/data/models/track_data.dart';
import 'package:racing/data/tracks/track_library.dart';
import 'package:racing/game/components/car/car_physics.dart';
import 'package:racing/game/components/props/cone_component.dart';
import 'package:racing/game/components/props/pickup_component.dart';
import 'package:racing/game/components/track/track_map.dart';
import 'package:racing/game/systems/collision_system.dart';
import 'package:racing/game/systems/input_controller.dart';

CarPhysics car({CarStats stats = CarPresets.starter}) =>
    CarPhysics(stats)..reset(Vector2.zero(), 0);

void main() {
  final map = TrackMap(TrackLibrary.oval);

  group('walls', () {
    test('a car driving straight at the wall stays inside and slows down', () {
      final c = car();
      final frame = map.frame(0.1);
      // Heading points to the outside of the track.
      final heading = math.atan2(frame.normal.y, frame.normal.x);
      c.reset(frame.position, heading);
      c.velocity.setValues(math.cos(heading) * 450, math.sin(heading) * 450);

      final system = CollisionSystem(track: map, cars: [c]);
      var hits = 0;
      system.onWall = (car, point, normal, impact, slide) {
        if (impact > 0) hits++;
      };
      final gas = InputSource()..gas = true;
      var maxDistance = 0.0;

      for (var i = 0; i < 360; i++) {
        final q = map.query(c.position, hint: c.trackHint);
        c.trackHint = q.index;
        c.step(GameConfig.physicsStep, gas, q.surface);
        system.step(GameConfig.physicsStep);
        maxDistance = math.max(maxDistance, map.query(c.position).distance);
      }

      expect(hits, greaterThan(0));
      expect(maxDistance, lessThan(map.wallDistance));
      expect(c.wallContact, greaterThan(0));
    });

    test('a hard hit loses speed and reports an impact', () {
      final c = car();
      final frame = map.frame(0.1);
      final heading = math.atan2(frame.normal.y, frame.normal.x);
      c.reset(frame.position, heading);
      c.velocity.setValues(math.cos(heading) * 500, math.sin(heading) * 500);
      final system = CollisionSystem(track: map, cars: [c]);
      var strongest = 0.0;
      system.onWall = (car, point, normal, impact, slide) {
        strongest = math.max(strongest, impact);
      };
      final idle = InputSource();
      for (var i = 0; i < 240; i++) {
        c.step(GameConfig.physicsStep, idle, SurfaceType.asphalt);
        system.step(GameConfig.physicsStep);
      }
      expect(strongest, greaterThan(100));
      expect(c.speed, lessThan(250));
    });

    test('walls of different track sections never merge', () {
      for (final data in TrackLibrary.all) {
        final m = TrackMap(data);
        final needed = 2 * (m.wallDistance + GameConfig.barrierThickness);
        for (var i = 0; i < m.count; i += 4) {
          for (var j = i + 1; j < m.count; j += 4) {
            final along = m.cumulative[j] - m.cumulative[i];
            final arc = math.min(along, m.length - along);
            if (arc > data.roadWidth * 3) {
              expect(m.points[i].distanceTo(m.points[j]), greaterThan(needed));
            }
          }
        }
      }
    });
  });

  group('car vs car', () {
    test('head-on equal cars bounce apart and stop overlapping', () {
      final a = car()..reset(Vector2(0, 0), 0);
      final b = car()..reset(Vector2(30, 0), math.pi);
      a.velocity.setValues(200, 0);
      b.velocity.setValues(-200, 0);
      final system = CollisionSystem(track: map, cars: [a, b]);
      var impact = 0.0;
      system.onCarHit = (x, y, point, i) => impact = math.max(impact, i);

      system.resolveCars(a, b);

      expect(impact, greaterThan(100));
      expect(a.velocity.x, lessThan(200));
      expect(b.velocity.x, greaterThan(-200));
      expect(a.velocity.x + b.velocity.x, closeTo(0, 1e-6));
    });

    test('the heavy car is pushed less than the light car', () {
      final heavy = car(stats: CarPresets.heavy)..reset(Vector2(0, 0), 0);
      final light = car(stats: CarPresets.drifter)
        ..reset(Vector2(30, 0), math.pi);
      heavy.velocity.setValues(200, 0);
      light.velocity.setValues(-200, 0);
      final system = CollisionSystem(track: map, cars: [heavy, light]);

      system.resolveCars(heavy, light);

      final heavyChange = (heavy.velocity.x - 200).abs();
      final lightChange = (light.velocity.x + 200).abs();
      expect(heavyChange, lessThan(lightChange));
    });

    test('eight cars on top of each other do not blow up', () {
      final base = map.frame(0.2).position;
      final cars = List.generate(
        8,
        (i) => car()..reset(Vector2(base.x + i * 6.0, base.y + (i % 2) * 5.0), 0),
      );
      final system = CollisionSystem(track: map, cars: cars);
      for (var i = 0; i < 120; i++) {
        system.step(GameConfig.physicsStep);
      }
      for (final c in cars) {
        expect(c.position.x.isFinite, isTrue);
        expect(c.velocity.length.isFinite, isTrue);
      }
    });
  });

  group('props', () {
    test('boost pad boosts the car once', () {
      final pad = map.props.firstWhere((p) => p.type == PropType.boostPad);
      final c = car()..reset(pad.position, pad.heading);
      c.velocity.setValues(100, 0);
      final system = CollisionSystem(track: map, cars: [c]);
      var triggered = 0;
      system.onBoostPad = (_) => triggered++;

      system.step(GameConfig.physicsStep);
      system.step(GameConfig.physicsStep);

      expect(triggered, 1);
      expect(c.boostTime, greaterThan(0));
      expect(c.boostActive, isTrue);
    });

    test('hitting a cone knocks it over and slows the car', () {
      final f = map.frame(0.2);
      final c = car()..reset(f.position, 0);
      c.velocity.setValues(300, 0);
      final cone = ConeComponent(
        position: Vector2(f.position.x + 20, f.position.y),
      );
      final system = CollisionSystem(track: map, cars: [c], cones: [cone]);
      system.step(GameConfig.physicsStep);
      expect(cone.knocked, isTrue);
      expect(c.velocity.x, lessThan(300));
      cone.reset();
      expect(cone.knocked, isFalse);
    });

    test('only the player collects coins, anyone collects nitro', () {
      final spot = map.frame(0.3).position;
      final player = car()..reset(map.frame(0.6).position, 0);
      final other = car()..reset(spot, 0);
      final coin = PickupComponent(type: PropType.coin, position: spot.clone());
      final nitro =
          PickupComponent(type: PropType.nitro, position: spot.clone());
      other.nitro = 0.2;
      final system = CollisionSystem(
        track: map,
        cars: [player, other],
        pickups: [coin, nitro],
        player: player,
      );
      system.step(GameConfig.physicsStep);

      expect(coin.collected, isFalse);
      expect(nitro.collected, isTrue);
      expect(other.nitro, greaterThan(0.6));
    });

    test('nitro pickups respawn, coins do not', () {
      final coin = PickupComponent(type: PropType.coin, position: Vector2.zero())
        ..collect();
      final nitro =
          PickupComponent(type: PropType.nitro, position: Vector2.zero())
            ..collect();
      for (var i = 0; i < 20 * 60; i++) {
        coin.update(1 / 60);
        nitro.update(1 / 60);
      }
      expect(coin.collected, isTrue);
      expect(nitro.collected, isFalse);
    });

    test('every track has props and they sit on the road', () {
      for (final data in TrackLibrary.all) {
        final m = TrackMap(data);
        expect(m.props, isNotEmpty);
        for (final p in m.props) {
          expect(m.query(p.position).distance, lessThan(m.halfWidth));
        }
      }
    });
  });
}
