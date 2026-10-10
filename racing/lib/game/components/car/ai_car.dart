import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/ai_profile.dart';
import 'package:racing/game/components/car/car_painter.dart';
import 'package:racing/game/components/car/car_physics.dart';
import 'package:racing/game/components/track/track_map.dart';
import 'package:racing/game/racing_game.dart';
import 'package:racing/game/systems/ai_controller.dart';
import 'package:racing/game/systems/fixed_update.dart';
import 'package:racing/game/systems/input_controller.dart';
import 'package:racing/game/systems/race_manager.dart';
import 'package:racing/game/systems/racing_line.dart';

/// A computer-driven car. It uses the same [CarPhysics] as the player; only
/// the source of the input differs ([AiController] instead of the touch and
/// keyboard controls).
class AiCar extends PositionComponent
    with HasGameReference<RacingGame>, FixedUpdate {
  AiCar({
    required this.profile,
    required this.slot,
    required RacingLine line,
  })  : physics = CarPhysics(profile.stats),
        controller = AiController(line: line, profile: profile),
        state = RaceCarState(id: 'ai$slot', name: profile.name),
        _painter = CarBodyPainter(profile.color),
        super(
          size: Vector2(GameConfig.carLength, GameConfig.carWidth),
          anchor: Anchor.center,
          priority: 8,
        );

  final AiProfile profile;

  /// Start grid slot (the player has slot 0).
  final int slot;
  final CarPhysics physics;
  final AiController controller;
  final RaceCarState state;
  final CarBodyPainter _painter;

  /// Latest track info under the car.
  TrackQuery? lastQuery;

  @override
  Future<void> onLoad() async {
    game.registerFixed(this);
  }

  @override
  void onRemove() {
    game.unregisterFixed(this);
    super.onRemove();
  }

  /// Puts the car on the grid (or back on the road) and stops it.
  void resetTo(Vector2 pos, double heading) {
    physics.reset(pos, heading);
    position.setFrom(pos);
    angle = heading;
    lastQuery = null;
  }

  @override
  void fixedUpdate(double dt) {
    final q = game.track.query(physics.position, hint: physics.trackHint);
    physics.trackHint = q.index;
    lastQuery = q;

    final canDrive = game.race.canDrive;
    game.aiProfiler.begin();
    controller.update(
      dt,
      car: physics,
      query: q,
      others: game.allPhysics,
      racing: canDrive,
      finished: state.finished,
      gapToPlayer: game.gapToPlayer(state),
    );
    game.aiProfiler.end();

    if (controller.wantsRespawn) {
      game.respawnAi(this);
      controller.onRespawned();
    }

    // Controls are locked during the countdown, as for the player.
    final DriveInput drive = canDrive ? controller : IdleInput.instance;
    physics.step(dt, drive, q.surface);
  }

  @override
  void update(double dt) {
    position.setFrom(physics.position);
    angle = physics.heading;
  }

  @override
  void render(Canvas canvas) {
    // Skip drawing cars far outside the view. Physics still runs for them.
    if (!game.isNearPlayer(physics.position.x, physics.position.y)) return;
    _painter.paint(canvas, size, physics);
  }
}
