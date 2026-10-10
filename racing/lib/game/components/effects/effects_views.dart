import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/data/models/app_settings.dart';
import 'package:racing/game/effects/effects_system.dart';
import 'package:racing/game/racing_game.dart';

/// Draws tire marks and soft car shadows under the cars (priority 4).
class GroundEffectsView extends Component {
  GroundEffectsView(this.fx) : super(priority: 4);

  final EffectsSystem fx;

  final Paint _mark = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round;

  final Paint _shadow = Paint()..color = const Color(0x55000000);

  @override
  void render(Canvas canvas) {
    final marks = fx.marks;
    for (var i = 0; i < marks.capacity; i++) {
      if (!marks.alive(i)) continue;
      final fade = 1 - marks.age[i] / marks.life[i];
      _mark.color = Color.fromARGB((fade * 90).round(), 25, 22, 20);
      canvas.drawLine(
        Offset(marks.x1[i], marks.y1[i]),
        Offset(marks.x2[i], marks.y2[i]),
        _mark,
      );
    }

    if (!fx.budget.shadows) return;
    for (final car in fx.cars) {
      canvas
        ..save()
        ..translate(car.position.x + 3, car.position.y + 4)
        ..rotate(car.heading)
        ..drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: GameConfig.carLength * 0.95,
            height: GameConfig.carWidth * 1.05,
          ),
          _shadow,
        )
        ..restore();
    }
  }
}

/// Draws particles (dust, smoke, nitro flame) above the cars (priority 9).
class ParticleEffectsView extends Component {
  ParticleEffectsView(this.fx) : super(priority: 9);

  final EffectsSystem fx;
  final Paint _paint = Paint();

  @override
  void render(Canvas canvas) {
    final p = fx.particles;
    for (var i = 0; i < p.capacity; i++) {
      final life = p.life[i];
      if (life <= 0) continue;
      final t = life / p.maxLife[i];
      final size = p.size1[i] + (p.size0[i] - p.size1[i]) * t;
      final alpha = math.max(0, math.min(255, (p.alpha[i] * t).round()));
      final c = p.rgb[i];
      _paint.color = Color.fromARGB(
        alpha,
        (c >> 16) & 0xFF,
        (c >> 8) & 0xFF,
        c & 0xFF,
      );
      canvas.drawCircle(Offset(p.x[i], p.y[i]), size, _paint);
    }
  }
}

class _Streak {
  _Streak(math.Random rnd)
      : angle = rnd.nextDouble() * math.pi * 2,
        offset = rnd.nextDouble(),
        speed = 0.6 + rnd.nextDouble() * 0.8;

  final double angle;
  final double offset;
  final double speed;
}

/// Screen-space effects drawn over the race: speed lines at high speed and a
/// blue vignette while nitro is on. Added to the camera viewport, so it
/// ignores the zoom and does not move with the world.
class ScreenEffects extends Component with HasGameReference<RacingGame> {
  ScreenEffects({required GraphicsQuality quality})
      : budget = EffectsBudget.of(quality),
        super(priority: 40);

  final EffectsBudget budget;

  final math.Random _rnd = math.Random(3);
  late final List<_Streak> _streaks =
      List.generate(22, (_) => _Streak(_rnd));

  double _speed = 0;
  double _speedTarget = 0;
  double _nitro = 0;
  double _nitroTarget = 0;
  double _phase = 0;

  /// Called every frame by the game. [speed01] is 0..1 of top speed.
  void setLevels({required double speed01, required bool nitro}) {
    _speedTarget = speed01;
    _nitroTarget = nitro ? 1 : 0;
  }

  @override
  void update(double dt) {
    _speed += (_speedTarget - _speed) * (1 - math.exp(-6 * dt));
    _nitro += (_nitroTarget - _nitro) * (1 - math.exp(-8 * dt));
    _phase += dt;
  }

  @override
  void render(Canvas canvas) {
    if (budget.vignette && _nitro > 0.01) _drawVignette(canvas);
    if (budget.speedLines && _speed > 0.55) _drawSpeedLines(canvas);
  }

  void _drawVignette(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final radius = math.max(w, h) * 0.75;
    final paint = Paint()
      ..shader = Gradient.radial(
        Offset(w / 2, h / 2),
        radius,
        [
          const Color(0x00000000),
          Color.fromARGB((_nitro * 110).round(), 60, 170, 255),
        ],
        [0.55, 1],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
  }

  void _drawSpeedLines(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final cx = w / 2;
    final cy = h / 2;
    final strength = clampD((_speed - 0.55) / 0.45, 0, 1);
    final reach = math.max(w, h);
    final paint = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = Color.fromARGB((strength * 70).round(), 255, 255, 255);
    final len = 40 + 90 * strength;

    for (final s in _streaks) {
      final t = (s.offset + _phase * s.speed * 0.4) % 1.0;
      final dx = math.cos(s.angle);
      final dy = math.sin(s.angle);
      final d0 = reach * (0.2 + t * 0.6);
      canvas.drawLine(
        Offset(cx + dx * d0, cy + dy * d0),
        Offset(cx + dx * (d0 + len), cy + dy * (d0 + len)),
        paint,
      );
    }
  }
}
