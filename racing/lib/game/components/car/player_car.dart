import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/game/components/car/car_painter.dart';
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
        _painter = CarBodyPainter(stats.color),
        super(
          size: Vector2(GameConfig.carLength, GameConfig.carWidth),
          anchor: Anchor.center,
          priority: 10,
        );

  final CarPhysics physics;

  /// Latest track info under the car (surface, progress, lateral position).
  TrackQuery? lastQuery;

  double _stuckTimer = 0;

  final CarBodyPainter _painter;

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
  void render(Canvas canvas) => _painter.paint(canvas, size, physics);
}
