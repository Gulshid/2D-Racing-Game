import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/game/racing_game.dart';
import 'package:racing/game/systems/fixed_update.dart';


/// Temporary component proving the loop and fixed timestep work.
class TestBox extends RectangleComponent
    with HasGameReference<RacingGame>, FixedUpdate {
  TestBox()
      : super(
          size: Vector2.all(GameConfig.testBoxSize),
          paint: Paint()..color = const Color(0xFFFF5A1F),
        );

  final Vector2 _velocity = Vector2(1, 0.6)..scaleTo(GameConfig.testBoxSpeed);

  @override
  void fixedUpdate(double dt) {
    position += _velocity * dt;

    final bounds = game.size;
    if (position.x < 0 || position.x + size.x > bounds.x) {
      _velocity.x = -_velocity.x;
      position.x = position.x.clamp(0, bounds.x - size.x).toDouble();
    }
    if (position.y < 0 || position.y + size.y > bounds.y) {
      _velocity.y = -_velocity.y;
      position.y = position.y.clamp(0, bounds.y - size.y).toDouble();
    }
  }
}
