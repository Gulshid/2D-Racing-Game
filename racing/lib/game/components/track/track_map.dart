import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/data/models/surface_type.dart';
import 'package:racing/data/models/track_data.dart';

/// Result of asking "what is under this point?".
class TrackQuery {
  const TrackQuery({
    required this.surface,
    required this.distance,
    required this.index,
    required this.lateral,
    required this.progress,
    required this.closest,
  });

  final SurfaceType surface;

  /// Distance from the road centerline in px.
  final double distance;

  /// Index of the nearest centerline segment.
  final int index;

  /// Sideways position across the road: -1 left edge, 0 center, 1 right edge.
  final double lateral;

  /// Progress along the track, 0..1.
  final double progress;

  /// Nearest point on the centerline.
  final Vector2 closest;
}

class DecorItem {
  const DecorItem(this.position, this.size);
  final Vector2 position;
  final double size;
}

/// A prop with its final world position.
class PropSpawn {
  const PropSpawn({
    required this.type,
    required this.position,
    required this.heading,
    required this.tangent,
    required this.normal,
  });

  final PropType type;
  final Vector2 position;
  final double heading;
  final Vector2 tangent;
  final Vector2 normal;
}

/// Geometry of a track: a smooth closed centerline sampled into points, with
/// fast queries for surface type and progress. Pure Dart, no rendering.
class TrackMap {
  TrackMap(this.data) {
    _build();
  }

  final TrackData data;

  late final List<Vector2> points;
  late final List<Vector2> tangents;
  late final List<Vector2> normals;
  late final List<double> cumulative;
  late final double length;
  late final Rect bounds;

  /// Trees / rocks placed away from the road. Built on first use.
  late final List<DecorItem> decor = _buildDecor();

  /// Cones, pads, coins and pickups with world positions. Built on first use.
  late final List<PropSpawn> props = _buildProps();

  int get count => points.length;
  double get halfWidth => data.roadWidth / 2;

  /// Distance from the centerline at which the barrier surface starts.
  double get wallDistance =>
      halfWidth + GameConfig.curbWidth + GameConfig.runoffWidth;

  void _build() {
    final cp = data.controlPoints.map((o) => Vector2(o.dx, o.dy)).toList();
    final n = cp.length;
    final pts = <Vector2>[];
    for (var i = 0; i < n; i++) {
      final p0 = cp[(i - 1 + n) % n];
      final p1 = cp[i];
      final p2 = cp[(i + 1) % n];
      final p3 = cp[(i + 2) % n];
      final steps = math.max(
        4,
        (p1.distanceTo(p2) / GameConfig.trackSampleSpacing).ceil(),
      );
      for (var s = 0; s < steps; s++) {
        pts.add(_catmullRom(p0, p1, p2, p3, s / steps));
      }
    }
    points = pts;

    final m = pts.length;
    final tans = <Vector2>[];
    final nors = <Vector2>[];
    for (var i = 0; i < m; i++) {
      final a = pts[(i - 1 + m) % m];
      final b = pts[(i + 1) % m];
      final t = Vector2(b.x - a.x, b.y - a.y)..normalize();
      tans.add(t);
      nors.add(Vector2(-t.y, t.x));
    }
    tangents = tans;
    normals = nors;

    final cum = <double>[0];
    for (var i = 1; i < m; i++) {
      cum.add(cum[i - 1] + pts[i - 1].distanceTo(pts[i]));
    }
    cumulative = cum;
    length = cum.last + pts.last.distanceTo(pts.first);

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    for (final p in pts) {
      minX = math.min(minX, p.x);
      minY = math.min(minY, p.y);
      maxX = math.max(maxX, p.x);
      maxY = math.max(maxY, p.y);
    }
    bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static Vector2 _catmullRom(
    Vector2 p0,
    Vector2 p1,
    Vector2 p2,
    Vector2 p3,
    double t,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;
    double f(double a, double b, double c, double d) =>
        0.5 *
        ((2 * b) +
            (-a + c) * t +
            (2 * a - 5 * b + 4 * c - d) * t2 +
            (-a + 3 * b - 3 * c + d) * t3);
    return Vector2(f(p0.x, p1.x, p2.x, p3.x), f(p0.y, p1.y, p2.y, p3.y));
  }

  /// Progress (0..1) of a centerline sample.
  double progressOfIndex(int i) => cumulative[i] / length;

  /// Finds the surface and position info under [p].
  /// Pass the previous result's index as [hint] to make it faster.
  TrackQuery query(Vector2 p, {int hint = -1}) {
    var bestD2 = double.infinity;
    var bestI = 0;
    var bestT = 0.0;

    void check(int i) {
      final a = points[i];
      final b = points[(i + 1) % count];
      final abx = b.x - a.x;
      final aby = b.y - a.y;
      final len2 = abx * abx + aby * aby;
      final t = len2 == 0
          ? 0.0
          : clampD(((p.x - a.x) * abx + (p.y - a.y) * aby) / len2, 0, 1);
      final dx = p.x - (a.x + abx * t);
      final dy = p.y - (a.y + aby * t);
      final d2 = dx * dx + dy * dy;
      if (d2 < bestD2) {
        bestD2 = d2;
        bestI = i;
        bestT = t;
      }
    }

    var done = false;
    if (hint >= 0 && hint < count) {
      for (var o = -GameConfig.trackQueryWindow;
          o <= GameConfig.trackQueryWindow;
          o++) {
        check((hint + o + count) % count);
      }
      final accept = data.roadWidth * 1.5;
      done = bestD2 <= accept * accept;
    }
    if (!done) {
      bestD2 = double.infinity;
      for (var i = 0; i < count; i++) {
        check(i);
      }
    }

    final a = points[bestI];
    final b = points[(bestI + 1) % count];
    final cx = a.x + (b.x - a.x) * bestT;
    final cy = a.y + (b.y - a.y) * bestT;
    final n = normals[bestI];
    final lateral = ((p.x - cx) * n.x + (p.y - cy) * n.y) / halfWidth;
    final dist = math.sqrt(bestD2);
    final segLen = a.distanceTo(b);
    final progress = (cumulative[bestI] + segLen * bestT) / length;

    return TrackQuery(
      surface: _surfaceAt(dist, lateral, progress),
      distance: dist,
      index: bestI,
      lateral: lateral,
      progress: progress >= 1 ? progress - 1 : progress,
      closest: Vector2(cx, cy),
    );
  }

  SurfaceType _surfaceAt(double dist, double lateral, double progress) {
    if (dist <= halfWidth) {
      for (final z in data.zones) {
        if (progress >= z.start &&
            progress <= z.end &&
            lateral >= z.lateralMin &&
            lateral <= z.lateralMax) {
          return z.surface;
        }
      }
      return SurfaceType.asphalt;
    }
    if (dist <= halfWidth + GameConfig.curbWidth) return SurfaceType.curb;
    return data.theme.offRoad;
  }

  /// World position and direction at [progress] (0..1) and a sideways offset
  /// [lateral] (-1 left edge .. 1 right edge).
  ({Vector2 position, double heading, Vector2 tangent, Vector2 normal}) frame(
    double progress, [
    double lateral = 0,
  ]) {
    var p = progress % 1.0;
    if (p < 0) p += 1;
    final s = p * length;

    var lo = 0;
    var hi = count - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (cumulative[mid] <= s) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final i = lo;
    final a = points[i];
    final b = points[(i + 1) % count];
    final segLen = a.distanceTo(b);
    final t = segLen == 0 ? 0.0 : clampD((s - cumulative[i]) / segLen, 0, 1);

    final cx = a.x + (b.x - a.x) * t;
    final cy = a.y + (b.y - a.y) * t;
    final t0 = tangents[i];
    final t1 = tangents[(i + 1) % count];
    final tangent = Vector2(
      t0.x + (t1.x - t0.x) * t,
      t0.y + (t1.y - t0.y) * t,
    )..normalize();
    final normal = Vector2(-tangent.y, tangent.x);
    final off = lateral * halfWidth;
    return (
      position: Vector2(cx + normal.x * off, cy + normal.y * off),
      heading: math.atan2(tangent.y, tangent.x),
      tangent: tangent,
      normal: normal,
    );
  }

  /// Start grid slot. Slot 0 is the pole position (player), slots 1-6 are
  /// the AI cars. Slots are placed along the road (not in a straight line
  /// behind the start), so the last rows stay on the asphalt in corners.
  ({Vector2 position, double heading}) spawn(int slot) {
    final row = slot ~/ 2;
    final side = slot.isEven ? -1.0 : 1.0;
    final back = 70.0 + row * 70.0;
    final f = frame(-back / length, side * 0.4);
    return (position: f.position, heading: f.heading);
  }

  List<PropSpawn> _buildProps() {
    final out = <PropSpawn>[];
    for (final prop in data.props) {
      for (var k = 0; k < prop.count; k++) {
        final progress = prop.progress + k * prop.spacing / length;
        final lateral = prop.lateral + k * prop.lateralStep;
        final f = frame(progress, lateral);
        out.add(
          PropSpawn(
            type: prop.type,
            position: f.position,
            heading: f.heading,
            tangent: f.tangent,
            normal: f.normal,
          ),
        );
      }
    }
    return out;
  }

  List<DecorItem> _buildDecor() {
    final rnd = math.Random(data.seed);
    final area = bounds.inflate(900);
    final out = <DecorItem>[];
    final maxTries = data.theme.decorationCount * 20;
    var tries = 0;
    final safe = wallDistance + GameConfig.barrierThickness + 30;
    while (out.length < data.theme.decorationCount && tries < maxTries) {
      tries++;
      final p = Vector2(
        area.left + rnd.nextDouble() * area.width,
        area.top + rnd.nextDouble() * area.height,
      );
      if (query(p).distance < safe) continue;
      out.add(DecorItem(p, 14 + rnd.nextDouble() * 22));
    }
    return out;
  }
}
