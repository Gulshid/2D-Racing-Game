import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/data/models/app_settings.dart';
import 'package:racing/game/effects/effects_system.dart';
import 'package:racing/game/racing_game.dart';

/// Reuses Paint objects instead of creating one per particle or mark.
///
/// Colours are quantised to 17 alpha steps. For a few colours that means a
/// few dozen Paints in total, created once and reused every frame. Without
/// this, a few hundred Color and Paint objects were made each frame, which
/// is the main source of garbage-collection stutter in the effects.
class _PaintCache {
  _PaintCache({this.stroke = false, this.strokeWidth = 1});

  final bool stroke;
  final double strokeWidth;
  final Map<int, Paint> _paints = {};

  Paint at(int rgb, double alpha01) {
    var step = (alpha01 * 16).round();
    if (step < 0) step = 0;
    if (step > 16) step = 16;
    final key = rgb * 32 + step;
    final hit = _paints[key];
    if (hit != null) return hit;
    final p = Paint()
      ..color = Color.fromARGB(
        math.min(255, step * 16),
        (rgb >> 16) & 0xFF,
        (rgb >> 8) & 0xFF,
        rgb & 0xFF,
      );
    if (stroke) {
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
    }
    _paints[key] = p;
    return p;
  }
}

/// Draws tire marks and soft car shadows under the cars (priority 4).
/// Only draws what is near the player (see RacingGame.isNearPlayer).
class GroundEffectsView extends Component with HasGameReference<RacingGame> {
  GroundEffectsView(this.fx) : super(priority: 4);

  final EffectsSystem fx;
  final _PaintCache _marks = _PaintCache(stroke: true, strokeWidth: 3.5);
  final Paint _shadow = Paint()..color = const Color(0x55000000);

  static const int _markRgb = 0x191614;

  @override
  void render(Canvas canvas) {
    final marks = fx.marks;
    for (var i = 0; i < marks.capacity; i++) {
      if (!marks.alive(i)) continue;
      final mx = (marks.x1[i] + marks.x2[i]) / 2;
      final my = (marks.y1[i] + marks.y2[i]) / 2;
      if (!game.isNearPlayer(mx, my)) continue;
      final fade = 1 - marks.age[i] / marks.life[i];
      canvas.drawLine(
        Offset(marks.x1[i], marks.y1[i]),
        Offset(marks.x2[i], marks.y2[i]),
        _marks.at(_markRgb, fade * 90 / 255),
      );
    }

    if (!fx.budget.shadows) return;
    for (final car in fx.cars) {
      if (!game.isNearPlayer(car.position.x, car.position.y)) continue;
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
class ParticleEffectsView extends Component with HasGameReference<RacingGame> {
  ParticleEffectsView(this.fx) : super(priority: 9);

  final EffectsSystem fx;
  final _PaintCache _fills = _PaintCache();

  @override
  void render(Canvas canvas) {
    final p = fx.particles;
    for (var i = 0; i < p.capacity; i++) {
      final life = p.life[i];
      if (life <= 0) continue;
      if (!game.isNearPlayer(p.x[i], p.y[i])) continue;
      final t = life / p.maxLife[i];
      final size = p.size1[i] + (p.size0[i] - p.size1[i]) * t;
      canvas.drawCircle(
        Offset(p.x[i], p.y[i]),
        size,
        _fills.at(p.rgb[i], p.alpha[i] * t / 255),
      );
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
/// ignores zoom and does not move with the world.
class ScreenEffects extends Component with HasGameReference<RacingGame> {
  ScreenEffects({required GraphicsQuality quality})
      : budget = EffectsBudget.of(quality),
        super(priority: 40);

  EffectsBudget budget;

  final math.Random _rnd = math.Random(3);
  late final List<_Streak> _streaks =
      List.generate(22, (_) => _Streak(_rnd));

  final Paint _streakPaint = Paint()
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  final Paint _vignettePaint = Paint();
  Shader? _vignetteShader;
  int _vignetteStep = -1;
  double _vignetteW = 0;
  double _vignetteH = 0;

  double _speed = 0;
  double _speedTarget = 0;
  double _nitro = 0;
  double _nitroTarget = 0;
  double _phase = 0;

  /// Lowers (or sets) the effect budget. Safe to call during a race.
  void setQuality(GraphicsQuality q) {
    budget = EffectsBudget.of(q);
  }

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
    // Rebuild the shader only when the strength steps or the screen changes,
    // not every frame.
    final step = (_nitro * 10).round();
    if (step != _vignetteStep || w != _vignetteW || h != _vignetteH) {
      _vignetteStep = step;
      _vignetteW = w;
      _vignetteH = h;
      _vignetteShader = Gradient.radial(
        Offset(w / 2, h / 2),
        math.max(w, h) * 0.75,
        [
          const Color(0x00000000),
          Color.fromARGB(step * 11, 60, 170, 255),
        ],
        [0.55, 1],
      );
      _vignettePaint.shader = _vignetteShader;
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _vignettePaint);
  }

  void _drawSpeedLines(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final cx = w / 2;
    final cy = h / 2;
    final strength = clampD((_speed - 0.55) / 0.45, 0, 1);
    final reach = math.max(w, h);
    final len = 40 + 90 * strength;
    _streakPaint.color = Color.fromARGB((strength * 70).round(), 255, 255, 255);

    for (final s in _streaks) {
      final t = (s.offset + _phase * s.speed * 0.4) % 1.0;
      final dx = math.cos(s.angle);
      final dy = math.sin(s.angle);
      final d0 = reach * (0.2 + t * 0.6);
      canvas.drawLine(
        Offset(cx + dx * d0, cy + dy * d0),
        Offset(cx + dx * (d0 + len), cy + dy * (d0 + len)),
        _streakPaint,
      );
    }
  }
}
