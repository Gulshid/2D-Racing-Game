import 'dart:math' as math;

import 'package:flame/extensions.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:racing/game/components/track/track_map.dart';

/// Draws a track outline (and optionally a moving car dot).
class MinimapPainter extends CustomPainter {
  MinimapPainter({required this.map, this.carPosition, Listenable? repaint})
      : super(repaint: repaint);

  final TrackMap map;
  final Vector2 Function()? carPosition;

  Path? _path;
  Size? _pathSize;
  double _scale = 1;
  Offset _origin = Offset.zero;

  void _build(Size size) {
    const pad = 8.0;
    final b = map.bounds;
    _scale = math.min(
      (size.width - pad * 2) / b.width,
      (size.height - pad * 2) / b.height,
    );
    _origin = Offset(
      (size.width - b.width * _scale) / 2 - b.left * _scale,
      (size.height - b.height * _scale) / 2 - b.top * _scale,
    );
    final path = Path();
    for (var i = 0; i < map.count; i += 3) {
      final o = _map(map.points[i].x, map.points[i].y);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    path.close();
    _path = path;
    _pathSize = size;
  }

  Offset _map(double x, double y) =>
      Offset(x * _scale + _origin.dx, y * _scale + _origin.dy);

  @override
  void paint(Canvas canvas, Size size) {
    if (_path == null || _pathSize != size) _build(size);

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(10),
        ),
        Paint()..color = const Color(0x990B1F3A),
      )
      ..drawPath(
        _path!,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xCCFFFFFF),
      );

    final startA = _map(map.points[0].x, map.points[0].y);
    canvas.drawCircle(startA, 3, Paint()..color = const Color(0xFF7CFC9A));

    final car = carPosition?.call();
    if (car != null) {
      canvas.drawCircle(
        _map(car.x, car.y),
        4.5,
        Paint()..color = const Color(0xFFFF5A1F),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MinimapPainter oldDelegate) =>
      oldDelegate.map != map;
}
