import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/game/components/car/player_car.dart';
import 'package:racing/game/racing_game.dart';

/// Smooth follow camera with look-ahead, speed zoom and impact shake.
class CameraController extends Component with HasGameReference<RacingGame> {
  CameraController({required this.target}) : super(priority: 100);

  final PlayerCar target;
  final Vector2 _pos = Vector2.zero();
  final math.Random _rnd = math.Random();
  bool _snap = true;
  double _trauma = 0;

  /// Jump to the target on the next update (used on spawn and restart).
  void snap() => _snap = true;

  /// Adds camera shake. [amount] is 0..1; shake fades out by itself.
  void addShake(double amount) {
    _trauma = math.min(1, _trauma + amount);
  }

  @override
  void update(double dt) {
    final viewfinder = game.camera.viewfinder;
    final p = target.physics;

    final desiredX = p.position.x + p.velocity.x * GameConfig.cameraLookAhead;
    final desiredY = p.position.y + p.velocity.y * GameConfig.cameraLookAhead;
    final speedT = clampD(p.speed / GameConfig.cameraSpeedForMinZoom, 0, 1);
    final desiredZoom = lerpD(
      GameConfig.cameraBaseZoom,
      GameConfig.cameraMinZoom,
      speedT,
    );

    if (_snap) {
      _pos.setValues(desiredX, desiredY);
      viewfinder.zoom = desiredZoom;
      _snap = false;
      _trauma = 0;
    } else {
      final kPos = 1 - math.exp(-GameConfig.cameraFollowRate * dt);
      final kZoom = 1 - math.exp(-GameConfig.cameraZoomRate * dt);
      _pos.x += (desiredX - _pos.x) * kPos;
      _pos.y += (desiredY - _pos.y) * kPos;
      viewfinder.zoom += (desiredZoom - viewfinder.zoom) * kZoom;
    }

    _trauma = math.max(0, _trauma - GameConfig.shakeDecay * dt);
    final shake = _trauma * _trauma * GameConfig.shakeMax;
    viewfinder.position = Vector2(
      _pos.x + (_rnd.nextDouble() * 2 - 1) * shake,
      _pos.y + (_rnd.nextDouble() * 2 - 1) * shake,
    );
  }
}
