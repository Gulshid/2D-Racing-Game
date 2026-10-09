import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/race_records.dart';
import 'package:racing/game/racing_game.dart';
import 'package:racing/game/systems/race_manager.dart';

/// Translucent replay of the best lap so far on this track.
class GhostCar extends PositionComponent with HasGameReference<RacingGame> {
  GhostCar()
      : super(
          size: Vector2(GameConfig.carLength, GameConfig.carWidth),
          anchor: Anchor.center,
          priority: 9,
        );

  bool _visible = false;

  final Paint _body = Paint()..color = const Color(0x66FFFFFF);
  final Paint _glass = Paint()..color = const Color(0x66224466);

  @override
  void update(double dt) {
    _visible = false;
    final ghost = RaceRecords.of(game.trackData.id).ghost;
    final s = game.playerState;
    if (ghost == null ||
        game.race.state != RaceState.racing ||
        s.lapStart == null ||
        s.finished ||
        ghost.sampleCount < 2) {
      return;
    }
    final t = s.currentLapTime;
    if (t > ghost.duration) return;

    final f = t * ghost.rate;
    final last = ghost.sampleCount - 1;
    final i0 = math.min(f.floor(), last);
    final i1 = math.min(i0 + 1, last);
    final a = f - f.floor();
    final d = ghost.samples;

    final x = d[i0 * 3] + (d[i1 * 3] - d[i0 * 3]) * a;
    final y = d[i0 * 3 + 1] + (d[i1 * 3 + 1] - d[i0 * 3 + 1]) * a;
    var dh = d[i1 * 3 + 2] - d[i0 * 3 + 2];
    while (dh > math.pi) {
      dh -= 2 * math.pi;
    }
    while (dh < -math.pi) {
      dh += 2 * math.pi;
    }
    position.setValues(x, y);
    angle = d[i0 * 3 + 2] + dh * a;
    _visible = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    final w = size.x;
    final h = size.y;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h),
          const Radius.circular(9),
        ),
        _body,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.52, h * 0.16, w * 0.2, h * 0.68),
          const Radius.circular(4),
        ),
        _glass,
      );
  }
}
