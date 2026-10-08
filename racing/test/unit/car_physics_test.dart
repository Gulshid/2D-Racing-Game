import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/models/surface_type.dart';
import 'package:racing/game/components/car/car_physics.dart';
import 'package:racing/game/systems/input_controller.dart';

void run(
  CarPhysics car,
  InputSource input,
  double seconds, {
  SurfaceType surface = SurfaceType.asphalt,
}) {
  final steps = (seconds / GameConfig.physicsStep).round();
  for (var i = 0; i < steps; i++) {
    car.step(GameConfig.physicsStep, input, surface);
  }
}

CarPhysics newCar() => CarPhysics(CarPresets.starter)
  ..reset(Vector2.zero(), 0);

void main() {
  test('accelerates up to, but not beyond, top speed', () {
    final car = newCar();
    run(car, InputSource()..gas = true, 12);
    expect(car.forwardSpeed, greaterThan(CarPresets.starter.maxSpeed * 0.97));
    expect(car.forwardSpeed, lessThanOrEqualTo(CarPresets.starter.maxSpeed + 1));
  });

  test('cannot steer while standing still', () {
    final car = newCar();
    run(car, InputSource()..right = true, 1);
    expect(car.heading, 0);
  });

  test('steering right turns clockwise (heading increases)', () {
    final car = newCar();
    run(car, InputSource()..gas = true, 3);
    final before = car.heading;
    run(car, InputSource()..gas = true..right = true, 0.5);
    expect(car.heading, greaterThan(before));
  });

  test('grass is slower than asphalt', () {
    final onRoad = newCar();
    final onGrass = newCar();
    final gas = InputSource()..gas = true;
    run(onRoad, gas, 12);
    run(onGrass, gas, 12, surface: SurfaceType.grass);
    expect(onGrass.forwardSpeed, lessThan(onRoad.forwardSpeed * 0.7));
  });

  test('handbrake while steering produces a drift', () {
    final car = newCar();
    run(car, InputSource()..gas = true, 8);
    run(
      car,
      InputSource()
        ..gas = true
        ..right = true
        ..handbrakeOn = true,
      0.5,
    );
    expect(car.lateralSpeed.abs(), greaterThan(50));
    expect(car.isDrifting, isTrue);
  });

  test('ice has far less grip than asphalt', () {
    final input = InputSource()
      ..gas = true
      ..right = true;
    final road = newCar();
    final ice = newCar();
    run(road, InputSource()..gas = true, 6);
    run(ice, InputSource()..gas = true, 6);
    run(road, input, 0.5);
    run(ice, input, 0.5, surface: SurfaceType.ice);
    expect(ice.lateralSpeed.abs(), greaterThan(road.lateralSpeed.abs()));
  });

  test('nitro raises speed above normal top speed', () {
    final car = newCar();
    car.velocity.x = CarPresets.starter.maxSpeed;
    run(car, InputSource()..nitroOn = true, 1);
    expect(car.forwardSpeed, greaterThan(CarPresets.starter.maxSpeed * 1.05));
    expect(car.nitro, lessThan(1));
  });

  test('brake slows the car, then reverses', () {
    final car = newCar();
    car.velocity.x = 400;
    run(car, InputSource()..brakePedal = true, 0.3);
    expect(car.forwardSpeed, lessThan(200));
    expect(car.forwardSpeed, greaterThan(0));

    final reverse = newCar();
    run(reverse, InputSource()..brakePedal = true, 2);
    expect(reverse.forwardSpeed, lessThan(-100));
  });

  test('coasting slows the car down', () {
    final car = newCar();
    car.velocity.x = 400;
    run(car, InputSource(), 3);
    expect(car.forwardSpeed, lessThan(200));
    expect(car.forwardSpeed, greaterThan(0));
  });

  test('same result at different step sizes (roughly)', () {
    final a = newCar();
    final b = newCar();
    final gas = InputSource()..gas = true;
    for (var i = 0; i < 240; i++) {
      a.step(1 / 120, gas, SurfaceType.asphalt);
    }
    for (var i = 0; i < 480; i++) {
      b.step(1 / 240, gas, SurfaceType.asphalt);
    }
    expect((a.position.x - b.position.x).abs(), lessThan(6));
  });
}
