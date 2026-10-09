import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';

class _Spark {
  bool alive = false;
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double life = 0;
  double maxLife = 1;
}

/// Spark particles from a fixed pool (no allocation while racing).
class SparkEmitter extends Component {
  SparkEmitter() : super(priority: 30);

  final List<_Spark> _pool =
      List.generate(GameConfig.sparkPoolSize, (_) => _Spark());
  final math.Random _rnd = math.Random();
  final Paint _paint = Paint()
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  int _next = 0;

  /// Shoots [count] sparks from [position] roughly along [direction].
  void emit(
    Vector2 position,
    Vector2 direction,
    int count, {
    double speed = 260,
  }) {
    final base = math.atan2(direction.y, direction.x);
    for (var i = 0; i < count; i++) {
      final s = _pool[_next];
      _next = (_next + 1) % _pool.length;
      final angle = base + (_rnd.nextDouble() * 2 - 1) * 1.1;
      final v = speed * (0.4 + _rnd.nextDouble() * 0.7);
      s
        ..alive = true
        ..x = position.x
        ..y = position.y
        ..vx = math.cos(angle) * v
        ..vy = math.sin(angle) * v
        ..maxLife = 0.25 + _rnd.nextDouble() * 0.25
        ..life = s.maxLife;
    }
  }

  void clear() {
    for (final s in _pool) {
      s.alive = false;
    }
  }

  @override
  void update(double dt) {
    final drag = math.exp(-4 * dt);
    for (final s in _pool) {
      if (!s.alive) continue;
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vx *= drag;
      s.vy *= drag;
      s.life -= dt;
      if (s.life <= 0) s.alive = false;
    }
  }

  @override
  void render(Canvas canvas) {
    for (final s in _pool) {
      if (!s.alive) continue;
      final t = s.life / s.maxLife;
      _paint.color = Color.fromARGB((255 * t).round(), 255, 200, 70);
      canvas.drawLine(
        Offset(s.x, s.y),
        Offset(s.x - s.vx * 0.035, s.y - s.vy * 0.035),
        _paint,
      );
    }
  }
}
