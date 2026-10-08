import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/game/components/car/player_car.dart';
import 'package:racing/game/racing_game.dart';

/// Smooth follow camera with look-ahead and speed-based zoom-out.
class CameraController extends Component with HasGameReference<RacingGame> {
  CameraController({required this.target}) : super(priority: 100);

  final PlayerCar target;
  bool _snap = true;

  /// Jump to the target on the next update (used on spawn and restart).
  void snap() => _snap = true;

  @override
  void update(double dt) {
    final viewfinder = game.camera.viewfinder;
    final p = target.physics;

    final desired = Vector2(
      p.position.x + p.velocity.x * GameConfig.cameraLookAhead,
      p.position.y + p.velocity.y * GameConfig.cameraLookAhead,
    );
    final speedT = clampD(p.speed / GameConfig.cameraSpeedForMinZoom, 0, 1);
    final desiredZoom = lerpD(
      GameConfig.cameraBaseZoom,
      GameConfig.cameraMinZoom,
      speedT,
    );

    if (_snap) {
      viewfinder
        ..position = desired
        ..zoom = desiredZoom;
      _snap = false;
      return;
    }

    final kPos = 1 - math.exp(-GameConfig.cameraFollowRate * dt);
    final kZoom = 1 - math.exp(-GameConfig.cameraZoomRate * dt);
    final current = viewfinder.position;
    viewfinder
      ..position = Vector2(
        current.x + (desired.x - current.x) * kPos,
        current.y + (desired.y - current.y) * kPos,
      )
      ..zoom = viewfinder.zoom + (desiredZoom - viewfinder.zoom) * kZoom;
  }
}
