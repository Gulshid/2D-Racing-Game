import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/game/components/track/track_map.dart';

/// Target speed for every point on the racing line.
class SpeedProfile {
  const SpeedProfile(this.target, this.minAhead);

  /// Speed (px/s) the car can carry at each point, including braking zones.
  final List<double> target;

  /// Lowest target over the next [GameConfig.aiNitroLookAhead] px.
  final List<double> minAhead;
}

/// The path the AI follows: the shortest route through the road (cuts
/// corners, goes wide on entry and exit), steered around bad surfaces.
///
/// It has exactly one point per track centerline sample, so a track query
/// index can be used on both. The track samples already come from a
/// Catmull-Rom spline, and the line is smoothed again, so it is smooth.
/// Pure Dart: no rendering, easy to unit test.
class RacingLine {
  RacingLine._({
    required this.track,
    required this.points,
    required this.offsets,
    required this.curvature,
    required this.caution,
    required this.spacing,
  });

  factory RacingLine.build(TrackMap track) {
    final n = track.count;
    final half = track.halfWidth;
    final limit = half * GameConfig.aiLineLimit;
    final d = List<double>.filled(n, 0);

    // 1. Pull every point toward the middle of its neighbours (shortest path)
    //    while staying inside the allowed corridor.
    for (var it = 0; it < GameConfig.aiLineIterations; it++) {
      for (var i = 0; i < n; i++) {
        final a = (i - 1 + n) % n;
        final b = (i + 1) % n;
        final pa = track.points[a];
        final na = track.normals[a];
        final pb = track.points[b];
        final nb = track.normals[b];
        final mx = (pa.x + na.x * d[a] + pb.x + nb.x * d[b]) / 2;
        final my = (pa.y + na.y * d[a] + pb.y + nb.y * d[b]) / 2;
        final c = track.points[i];
        final nn = track.normals[i];
        d[i] = clampD((mx - c.x) * nn.x + (my - c.y) * nn.y, -limit, limit);
      }
    }

    // 2. Steer around sand, ice and oil where there is room to do so.
    _avoidZones(track, d, half, limit);

    // 3. Smooth so the line has no kinks.
    _smooth(d, GameConfig.aiSmoothRadius, GameConfig.aiSmoothPasses);

    // 4. World points.
    final pts = <Vector2>[
      for (var i = 0; i < n; i++)
        Vector2(
          track.points[i].x + track.normals[i].x * d[i],
          track.points[i].y + track.normals[i].y * d[i],
        ),
    ];

    // 5. Curvature (Menger formula), smoothed a little.
    final curv = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final a = pts[(i - 1 + n) % n];
      final b = pts[i];
      final c = pts[(i + 1) % n];
      final abx = b.x - a.x;
      final aby = b.y - a.y;
      final bcx = c.x - b.x;
      final bcy = c.y - b.y;
      final cax = c.x - a.x;
      final cay = c.y - a.y;
      final cross = (abx * bcy - aby * bcx).abs();
      final den = math.sqrt(abx * abx + aby * aby) *
          math.sqrt(bcx * bcx + bcy * bcy) *
          math.sqrt(cax * cax + cay * cay);
      curv[i] = den < 1e-9 ? 0 : 2 * cross / den;
    }
    _smooth(curv, 3, 2);

    // 6. Caution from the surface under the line.
    final caution = List<double>.generate(n, (i) {
      final s = track.query(pts[i], hint: i).surface;
      return lerpD(0.5, 1, s.grip);
    });

    return RacingLine._(
      track: track,
      points: pts,
      offsets: d,
      curvature: curv,
      caution: caution,
      spacing: track.length / n,
    );
  }

  final TrackMap track;

  /// World position of the line at each centerline sample.
  final List<Vector2> points;

  /// Signed sideways offset from the centerline in px (along the normal).
  final List<double> offsets;

  /// 1 / radius in px at each sample.
  final List<double> curvature;

  /// 0.5..1 multiplier for slippery surfaces.
  final List<double> caution;

  /// Average distance between samples in px.
  final double spacing;

  int get count => points.length;

  /// Works out how fast a car with these numbers can take every part of the
  /// line, including slowing down early enough for the next corner.
  SpeedProfile buildSpeedProfile({
    required double maxSpeed,
    required double steering,
    required double cornerSafety,
    required double decel,
  }) {
    final n = count;

    // Turn rate available at speed v: steering * (1 - loss * v / max).
    // Needed turn rate: v * curvature. Solving for v gives the formula.
    final s = steering * cornerSafety;
    final k = GameConfig.highSpeedSteerLoss * s / maxSpeed;
    final v = List<double>.generate(n, (i) {
      final cornerLimit = s / (curvature[i] + k);
      final speed = math.max(
        GameConfig.aiMinCornerSpeed,
        math.min(maxSpeed, cornerLimit),
      );
      return speed * caution[i];
    });

    // Braking: a point may not be faster than what can still stop in time
    // for the next one. Two passes make it work across the lap boundary.
    for (var pass = 0; pass < 2; pass++) {
      for (var i = n - 1; i >= 0; i--) {
        final next = (i + 1) % n;
        final ds = points[i].distanceTo(points[next]);
        final allowed = math.sqrt(v[next] * v[next] + 2 * decel * ds);
        if (v[i] > allowed) v[i] = allowed;
      }
    }

    final window = math.max(1, (GameConfig.aiNitroLookAhead / spacing).ceil());
    final ahead = List<double>.generate(n, (i) {
      var low = double.infinity;
      for (var k2 = 0; k2 <= window; k2++) {
        low = math.min(low, v[(i + k2) % n]);
      }
      return low;
    });
    return SpeedProfile(v, ahead);
  }

  static void _avoidZones(
    TrackMap track,
    List<double> d,
    double half,
    double limit,
  ) {
    final n = track.count;
    final limitLat = limit / half;
    for (final z in track.data.zones) {
      final lo = z.lateralMin - GameConfig.aiZonePad;
      final hi = z.lateralMax + GameConfig.aiZonePad;
      final okLeft = lo >= -limitLat;
      final okRight = hi <= limitLat;
      if (!okLeft && !okRight) continue; // zone covers the road: no way round
      for (var i = 0; i < n; i++) {
        final prog = track.progressOfIndex(i);
        if (prog < z.start - GameConfig.aiZoneMargin ||
            prog > z.end + GameConfig.aiZoneMargin) {
          continue;
        }
        final lat = d[i] / half;
        if (lat < lo || lat > hi) continue;
        final double goal;
        if (okLeft && okRight) {
          goal = (lat - lo) < (hi - lat) ? lo : hi;
        } else {
          goal = okLeft ? lo : hi;
        }
        d[i] = goal * half;
      }
    }
  }

  static void _smooth(List<double> d, int radius, int passes) {
    final n = d.length;
    final tmp = List<double>.filled(n, 0);
    final width = 2 * radius + 1;
    for (var p = 0; p < passes; p++) {
      for (var i = 0; i < n; i++) {
        var sum = 0.0;
        for (var k = -radius; k <= radius; k++) {
          sum += d[(i + k + n) % n];
        }
        tmp[i] = sum / width;
      }
      d.setAll(0, tmp);
    }
  }
}
