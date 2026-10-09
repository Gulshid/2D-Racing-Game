import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';

/// A traffic cone. Stands until a car hits it, then slides and spins away.
class ConeComponent extends PositionComponent {
  ConeComponent({required Vector2 position})
      : home = position.clone(),
        super(
          position: position,
          size: Vector2.all(GameConfig.coneRadius * 2),
          anchor: Anchor.center,
          priority: 5,
        );

  final Vector2 home;
  bool knocked = false;

  final Vector2 _velocity = Vector2.zero();
  double _spin = 0;

  final Paint _shadow = Paint()..color = const Color(0x55000000);
  final Paint _orange = Paint()..color = const Color(0xFFFF7A1A);
  final Paint _white = Paint()..color = const Color(0xFFFFFFFF);
  final Paint _dark = Paint()..color = const Color(0xFF8A3B05);

  double get radius => GameConfig.coneRadius;

  void knock(Vector2 impulse, {double spin = 8}) {
    knocked = true;
    _velocity.setFrom(impulse);
    _spin = spin;
  }

  void reset() {
    knocked = false;
    _velocity.setZero();
    _spin = 0;
    position.setFrom(home);
    angle = 0;
  }

  @override
  void update(double dt) {
    if (!knocked) return;
    if (_velocity.length2 > 1) {
      position.x += _velocity.x * dt;
      position.y += _velocity.y * dt;
      final k = math.exp(-3 * dt);
      _velocity.scale(k);
    }
    angle += _spin * dt;
    _spin *= math.exp(-2 * dt);
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    final r = size.x / 2;
    if (!knocked) {
      canvas
        ..drawCircle(c.translate(2, 3), r, _shadow)
        ..drawCircle(c, r, _orange)
        ..drawCircle(c, r * 0.62, _white)
        ..drawCircle(c, r * 0.3, _dark);
    } else {
      // Lying on its side: a short rounded body with a stripe.
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: r * 2.6, height: r * 1.5),
        Radius.circular(r * 0.5),
      );
      canvas
        ..drawRRect(body.shift(const Offset(2, 3)), _shadow)
        ..drawRRect(body, _orange)
        ..drawRect(
          Rect.fromCenter(center: c, width: r * 0.6, height: r * 1.5),
          _white,
        );
    }
  }
}
