import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/models/surface_type.dart';
import 'package:racing/data/models/weather_type.dart';
import 'package:racing/game/components/car/car_physics.dart';
import 'package:racing/game/systems/input_controller.dart';

CarPhysics newCar() =>
    CarPhysics(CarPresets.starter)..reset(Vector2.zero(), 0);

void drive(CarPhysics car, InputSource input, double seconds) {
  final steps = (seconds / GameConfig.physicsStep).round();
  for (var i = 0; i < steps; i++) {
    car.step(GameConfig.physicsStep, input, SurfaceType.asphalt);
  }
}

void main() {
  group('WeatherType', () {
    test('clear weather never changes grip', () {
      for (final s in SurfaceType.values) {
        expect(WeatherType.clear.gripFor(s), 1);
      }
    });

    test('rain lowers grip on paved surfaces', () {
      expect(WeatherType.rain.gripFor(SurfaceType.asphalt), lessThan(1));
      expect(WeatherType.rain.gripFor(SurfaceType.curb), lessThan(1));
      expect(WeatherType.rain.gripFor(SurfaceType.ice), 1);
    });

    test('fromIndex falls back to clear', () {
      expect(WeatherType.fromIndex(null), WeatherType.clear);
      expect(WeatherType.fromIndex(-1), WeatherType.clear);
      expect(WeatherType.fromIndex(99), WeatherType.clear);
      expect(WeatherType.fromIndex(1), WeatherType.rain);
    });
  });

  group('physics', () {
    test('rain makes the car accelerate more slowly', () {
      final dry = newCar();
      final wet = newCar()..weatherGrip = WeatherType.rain.gripFor;
      drive(dry, InputSource()..gas = true, 2);
      drive(wet, InputSource()..gas = true, 2);
      expect(wet.forwardSpeed, lessThan(dry.forwardSpeed));
    });

    test('a damaged car has a lower top speed', () {
      final fresh = newCar();
      final worn = newCar();
      for (var i = 0; i < 10; i++) {
        worn.damage.hit(400);
      }
      drive(fresh, InputSource()..gas = true, 12);
      drive(worn, InputSource()..gas = true, 12);
      expect(worn.forwardSpeed, lessThan(fresh.forwardSpeed * 0.95));
    });

    test('respawn (reset) keeps damage; damage.reset repairs it', () {
      final car = newCar();
      car.damage.hit(400);
      final damage = car.damage.damage;
      car.reset(Vector2.zero(), 0);
      expect(car.damage.damage, damage);
      car.damage.reset();
      expect(car.damage.damage, 0);
    });
  });
}
