import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:racing/game/components/car/car_physics.dart';

/// Draws the car body. Shared by the player car and the AI cars.
/// The car is drawn facing +x (right).
class CarBodyPainter {
  CarBodyPainter(Color color) : _body = Paint()..color = color;

  final Paint _body;
  final Paint _shadow = Paint()..color = const Color(0x55000000);
  final Paint _dark = Paint()..color = const Color(0xFF14181F);
  final Paint _glass = Paint()..color = const Color(0xFF1F3A5A);
  final Paint _head = Paint()..color = const Color(0xFFFFF3B0);
  final Paint _tail = Paint()..color = const Color(0xFFB01818);
  final Paint _brakeLight = Paint()..color = const Color(0xFFFF4040);
  final Paint _flame = Paint()..color = const Color(0xFFFFA726);

  void paint(Canvas canvas, Vector2 size, CarPhysics physics) {
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
