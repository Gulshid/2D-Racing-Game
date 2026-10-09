import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/game/components/car/car_physics.dart';
import 'package:racing/game/components/track/track_map.dart';
import 'package:racing/game/racing_game.dart';
import 'package:racing/game/systems/fixed_update.dart';
import 'package:racing/game/systems/input_controller.dart';

/// The player's car: runs [CarPhysics] at a fixed rate and draws the car.
/// The car is drawn facing +x (right); the component rotates by heading.
class PlayerCar extends PositionComponent
    with HasGameReference<RacingGame>, FixedUpdate {
  PlayerCar({required CarStats stats})
      : physics = CarPhysics(stats),
        _body = Paint()..color = stats.color,
        super(
          size: Vector2(GameConfig.carLength, GameConfig.carWidth),
          anchor: Anchor.center,
          priority: 10,
        );

  final CarPhysics physics;

  /// Latest track info under the car (surface, progress, lateral position).
  TrackQuery? lastQuery;

  double _stuckTimer = 0;

  final Paint _body;
  final Paint _shadow = Paint()..color = const Color(0x55000000);
  final Paint _dark = Paint()..color = const Color(0xFF14181F);
  final Paint _glass = Paint()..color = const Color(0xFF1F3A5A);
  final Paint _head = Paint()..color = const Color(0xFFFFF3B0);
  final Paint _tail = Paint()..color = const Color(0xFFB01818);
  final Paint _brakeLight = Paint()..color = const Color(0xFFFF4040);
  final Paint _flame = Paint()..color = const Color(0xFFFFA726);

  @override
  Future<void> onLoad() async {
    game.registerFixed(this);
  }

  @override
  void onRemove() {
    game.unregisterFixed(this);
    super.onRemove();
  }

  void resetTo(Vector2 pos, double heading) {
    physics.reset(pos, heading);
    position.setFrom(pos);
    angle = heading;
    lastQuery = null;
    _stuckTimer = 0;
  }

  @override
  void fixedUpdate(double dt) {
    final q = game.track.query(physics.position, hint: physics.trackHint);
    physics.trackHint = q.index;
    lastQuery = q;

    // Controls are locked during the countdown.
    final DriveInput drive =
        game.race.canDrive ? game.input : IdleInput.instance;
    physics.step(dt, drive, q.surface);

    _checkStuck(dt, drive);
  }

  /// Respawns the car if it is pinned against a wall for a few seconds.
  void _checkStuck(double dt, DriveInput drive) {
    final wantsToMove = drive.throttle > 0 || drive.brake > 0;
    if (physics.wallContact > 0 &&
        physics.speed < GameConfig.stuckSpeed &&
        wantsToMove) {
      _stuckTimer += dt;
    } else {
      _stuckTimer = _stuckTimer > dt ? _stuckTimer - dt : 0;
    }
    if (_stuckTimer >= GameConfig.stuckTime) {
      _stuckTimer = 0;
      game.respawnPlayer();
    }
  }

  @override
  void update(double dt) {
    position.setFrom(physics.position);
    angle = physics.heading;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Flame behind the car while nitro or a boost pad is pushing.
    if (physics.boostActive) {
      final flame = Path()
        ..moveTo(0, h * 0.28)
        ..lineTo(-22, h * 0.5)
        ..lineTo(0, h * 0.72)
        ..close();
      canvas.drawPath(flame, _flame);
    }

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 3, w, h),
          const Radius.circular(9),
        ),
        _shadow,
      )
      // Wheels
      ..drawRect(Rect.fromLTWH(w * 0.1, -2, 12, 5), _dark)
      ..drawRect(Rect.fromLTWH(w * 0.1, h - 3, 12, 5), _dark)
      ..drawRect(Rect.fromLTWH(w * 0.66, -2, 12, 5), _dark)
      ..drawRect(Rect.fromLTWH(w * 0.66, h - 3, 12, 5), _dark)
      // Body
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h),
          const Radius.circular(9),
        ),
        _body,
      )
      // Windshield and rear window
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.52, h * 0.16, w * 0.2, h * 0.68),
          const Radius.circular(4),
        ),
        _glass,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.14, h * 0.6),
          const Radius.circular(3),
        ),
        _glass,
      )
      // Headlights
      ..drawRect(Rect.fromLTWH(w - 5, 3, 4, 6), _head)
      ..drawRect(Rect.fromLTWH(w - 5, h - 9, 4, 6), _head);
    final tail = physics.braking ? _brakeLight : _tail;
    canvas
      ..drawRect(Rect.fromLTWH(1, 3, 4, 6), tail)
      ..drawRect(Rect.fromLTWH(1, h - 9, 4, 6), tail);
  }
}
