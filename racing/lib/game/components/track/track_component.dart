import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/surface_type.dart';
import 'package:racing/data/models/track_data.dart';
import 'package:racing/game/components/track/track_map.dart';

/// Draws the whole track once into a cached Picture, then replays it each
/// frame. No image assets needed: road, curbs, zones, start line, scenery.
class TrackComponent extends Component {
  TrackComponent(this.map) : super(priority: -100);

  final TrackMap map;
  Picture? _picture;

  @override
  Future<void> onLoad() async {
    _picture = _record();
  }

  @override
  void render(Canvas canvas) {
    final picture = _picture;
    if (picture != null) canvas.drawPicture(picture);
  }

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    super.onRemove();
  }

  Picture _record() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final theme = map.data.theme;
    final road = map.data.roadWidth;
    const curb = GameConfig.curbWidth;

    final centerline = Path()
      ..moveTo(map.points.first.x, map.points.first.y);
    for (var i = 1; i < map.count; i++) {
      centerline.lineTo(map.points[i].x, map.points[i].y);
    }
    centerline.close();

    Paint stroke(Color color, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true
      ..color = color;

    _drawDecor(canvas, shadowOnly: true);

    // Barriers: a ring around the whole drivable area. Everything inside
    // "wall distance" is cleared again with the ground color.
    final wall = map.wallDistance;
    const barrier = GameConfig.barrierThickness;
    canvas
      ..drawPath(centerline, stroke(theme.curbA, (wall + barrier) * 2))
      ..drawPath(
        _dash(centerline, 40, 40),
        stroke(theme.curbB, (wall + barrier) * 2),
      )
      ..drawPath(centerline, stroke(theme.grass, wall * 2));

    // Curbs: solid color A, dashes of color B on top, asphalt narrower.
    canvas
      ..drawPath(centerline, stroke(theme.curbA, road + curb * 2))
      ..drawPath(
        _dash(centerline, 36, 36),
        stroke(theme.curbB, road + curb * 2),
      )
      ..drawPath(centerline, stroke(theme.road, road));

    _drawZones(canvas);
    _drawBoostPads(canvas);

    canvas.drawPath(_dash(centerline, 28, 28), stroke(theme.line, 4));

    _drawStartLine(canvas);
    _drawDecor(canvas, shadowOnly: false);

    return recorder.endRecording();
  }

  Path _dash(Path source, double dash, double gap) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = math.min(d + dash, metric.length);
        out.addPath(metric.extractPath(d, end), Offset.zero);
        d += dash + gap;
      }
    }
    return out;
  }

  Color _zoneColor(SurfaceType s) {
    switch (s) {
      case SurfaceType.sand:
        return const Color(0xFFE9CE86);
      case SurfaceType.ice:
        return const Color(0xFFBFE6F5);
      case SurfaceType.oil:
        return const Color(0xE6101216);
      case SurfaceType.asphalt:
      case SurfaceType.curb:
      case SurfaceType.grass:
        return const Color(0x00000000);
    }
  }

  void _drawZones(Canvas canvas) {
    final half = map.halfWidth;
    for (final z in map.data.zones) {
      final left = <Offset>[];
      final right = <Offset>[];
      for (var i = 0; i < map.count; i++) {
        final prog = map.progressOfIndex(i);
        if (prog < z.start || prog > z.end) continue;
        final c = map.points[i];
        final n = map.normals[i];
        left.add(
          Offset(
            c.x + n.x * z.lateralMin * half,
            c.y + n.y * z.lateralMin * half,
          ),
        );
        right.add(
          Offset(
            c.x + n.x * z.lateralMax * half,
            c.y + n.y * z.lateralMax * half,
          ),
        );
      }
      if (left.length < 2) continue;
      final path = Path()..moveTo(left.first.dx, left.first.dy);
      for (final o in left.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      for (final o in right.reversed) {
        path.lineTo(o.dx, o.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = _zoneColor(z.surface));
    }
  }

  void _drawBoostPads(Canvas canvas) {
    const len = GameConfig.padLength;
    final width = map.data.roadWidth * GameConfig.padWidthFactor;
    final base = Paint()..color = const Color(0xE61565C0);
    final chevron = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    for (final pad in map.props) {
      if (pad.type != PropType.boostPad) continue;
      Offset pt(double along, double across) => Offset(
            pad.position.x + pad.tangent.x * along + pad.normal.x * across,
            pad.position.y + pad.tangent.y * along + pad.normal.y * across,
          );

      final rect = Path()
        ..moveTo(pt(-len / 2, -width / 2).dx, pt(-len / 2, -width / 2).dy)
        ..lineTo(pt(len / 2, -width / 2).dx, pt(len / 2, -width / 2).dy)
        ..lineTo(pt(len / 2, width / 2).dx, pt(len / 2, width / 2).dy)
        ..lineTo(pt(-len / 2, width / 2).dx, pt(-len / 2, width / 2).dy)
        ..close();
      canvas.drawPath(rect, base);

      for (var i = -1; i <= 1; i++) {
        final a = i * 18.0;
        final arrow = Path()
          ..moveTo(pt(a - 8, -width * 0.3).dx, pt(a - 8, -width * 0.3).dy)
          ..lineTo(pt(a + 8, 0).dx, pt(a + 8, 0).dy)
          ..lineTo(pt(a - 8, width * 0.3).dx, pt(a - 8, width * 0.3).dy);
        canvas.drawPath(arrow, chevron);
      }
    }
  }

  void _drawStartLine(Canvas canvas) {
    final origin = map.points[0];
    final along = map.tangents[0];
    final across = map.normals[0];
    const cols = 10;
    const rows = 2;
    final cell = map.data.roadWidth / cols;
    final white = Paint()..color = const Color(0xFFFFFFFF);
    final black = Paint()..color = const Color(0xFF15181D);

    Offset pt(double x, double y) => Offset(
          origin.x + across.x * x + along.x * y,
          origin.y + across.y * x + along.y * y,
        );

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x0 = -map.halfWidth + c * cell;
        final y0 = (r - 1) * cell;
        final path = Path()
          ..moveTo(pt(x0, y0).dx, pt(x0, y0).dy)
          ..lineTo(pt(x0 + cell, y0).dx, pt(x0 + cell, y0).dy)
          ..lineTo(pt(x0 + cell, y0 + cell).dx, pt(x0 + cell, y0 + cell).dy)
          ..lineTo(pt(x0, y0 + cell).dx, pt(x0, y0 + cell).dy)
          ..close();
        canvas.drawPath(path, (r + c).isEven ? white : black);
      }
    }
  }

  void _drawDecor(Canvas canvas, {required bool shadowOnly}) {
    final theme = map.data.theme;
    final shadow = Paint()..color = const Color(0x33000000);
    final dark = Paint()..color = theme.decorationDark;
    final light = Paint()..color = theme.decoration;
    for (final d in map.decor) {
      final p = Offset(d.position.x, d.position.y);
      if (shadowOnly) {
        canvas.drawCircle(p.translate(5, 6), d.size, shadow);
      } else {
        canvas
          ..drawCircle(p, d.size, dark)
          ..drawCircle(p.translate(-d.size * 0.15, -d.size * 0.15), d.size * 0.7, light);
      }
    }
  }
}
