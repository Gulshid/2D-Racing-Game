import 'package:flutter_test/flutter_test.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/game/systems/car_damage.dart';

void main() {
  test('a new car is pristine', () {
    final d = CarDamage();
    expect(d.damage, 0);
    expect(d.integrity, 1);
    expect(d.performance, 1);
    expect(d.steerPull, 0);
    expect(d.isDamaged, isFalse);
  });

  test('gentle bumps cause no damage', () {
    final d = CarDamage();
    expect(d.hit(GameConfig.damageMinImpact), 0);
    expect(d.hit(10), 0);
    expect(d.isDamaged, isFalse);
  });

  test('harder impacts cause more damage', () {
    final soft = CarDamage()..hit(150);
    final hard = CarDamage()..hit(400);
    expect(soft.damage, greaterThan(0));
    expect(hard.damage, greaterThan(soft.damage));
  });

  test('car hits hurt less than the same wall hit', () {
    final wall = CarDamage()..hit(300);
    final car = CarDamage()..hit(300, factor: GameConfig.damageCarHitFactor);
    expect(car.damage, lessThan(wall.damage));
  });

  test('damage is capped so the car can always finish', () {
    final d = CarDamage();
    for (var i = 0; i < 100; i++) {
      d.hit(600);
    }
    expect(d.damage, GameConfig.damageMax);
    expect(d.integrity, 0);
    expect(d.performance, closeTo(GameConfig.damageMinPerformance, 1e-9));
  });

  test('performance falls as damage grows', () {
    final d = CarDamage();
    final before = d.performance;
    d.hit(300);
    expect(d.performance, lessThan(before));
    expect(d.performance, greaterThanOrEqualTo(GameConfig.damageMinPerformance));
  });

  test('steering pull only appears after heavy damage', () {
    final light = CarDamage()..hit(150);
    expect(light.steerPull, 0);
    final heavy = CarDamage();
    for (var i = 0; i < 20; i++) {
      heavy.hit(400);
    }
    expect(heavy.steerPull.abs(), greaterThan(0));
    expect(heavy.steerPull.abs(), lessThanOrEqualTo(GameConfig.damageSteerPull));
  });

  test('repair removes a fraction of the damage', () {
    final d = CarDamage()..hit(400);
    final before = d.damage;
    d.repair(0.25);
    expect(d.damage, closeTo(before * 0.75, 1e-9));
    d.repair(1);
    expect(d.damage, 0);
  });

  test('reset repairs everything', () {
    final d = CarDamage()..hit(500);
    d.reset();
    expect(d.damage, 0);
  });
}
