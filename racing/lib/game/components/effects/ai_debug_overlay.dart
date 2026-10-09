import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/game/components/car/ai_car.dart';
import 'package:racing/game/racing_game.dart';
import 'package:racing/game/systems/ai_controller.dart';

/// Debug view for the AI: racing line, aim point and traffic sensor of every
/// AI car. Switched on and off with [RacingGame.aiDebug].
class AiDebugOverlay extends Component with HasGameReference<RacingGame> {
  AiDebugOverlay() : super(priority: 45);

  Path? _linePath;

  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xAA00E5FF);
  final Paint _aim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0xFFFFEB3B);
  final Paint _aimRecovery = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0xFFFF5252);
  final Paint _dot = Paint()..color = const Color(0xFFFFEB3B);
  final Paint _sensor = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const Color(0x99FF9800);

  Path _buildLine() {
    final pts = game.racingLine.points;
    final path = Path()..moveTo(pts.first.x, pts.first.y);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].x, pts[i].y);
    }
    return path..close();
  }

  @override
  void render(Canvas canvas) {
    if (!game.aiDebug.value) return;
    canvas.drawPath(_linePath ??= _buildLine(), _line);

    final track = game.track;
    for (final ai in game.aiCars) {
      final c = ai.controller;
      final p = ai.physics.position;
      final tgt = c.target;
      final recovering = c.mode == AiMode.reversing;

      canvas
        ..drawLine(
          Offset(p.x, p.y),
          Offset(tgt.x, tgt.y),
          recovering ? _aimRecovery : _aim,
        )
        ..drawCircle(Offset(tgt.x, tgt.y), 6, _dot);

      _drawSensor(canvas, ai, track.tangents, track.normals);
    }
  }

  void _drawSensor(
    Canvas canvas,
    AiCar ai,
    List<Vector2> tangents,
    List<Vector2> normals,
  ) {
    final q = ai.lastQuery;
    if (q == null) return;
    final t = tangents[q.index];
    final n = normals[q.index];
    final p = ai.physics.position;
    final reach = ai.controller.sensorReach;
    final lane = ai.controller.sensorLane;
    final path = Path()
      ..moveTo(p.x + n.x * lane, p.y + n.y * lane)
      ..lineTo(p.x + n.x * lane + t.x * reach, p.y + n.y * lane + t.y * reach)
      ..lineTo(p.x - n.x * lane + t.x * reach, p.y - n.y * lane + t.y * reach)
      ..lineTo(p.x - n.x * lane, p.y - n.y * lane);
    canvas.drawPath(path, _sensor);
  }
}
