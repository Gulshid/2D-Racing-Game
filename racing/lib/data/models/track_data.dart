import 'dart:ui';

import 'package:racing/data/models/surface_type.dart';

/// Colors and decoration settings for a track.
class TrackTheme {
  const TrackTheme({
    required this.grass,
    required this.road,
    required this.curbA,
    required this.curbB,
    required this.line,
    required this.decoration,
    required this.decorationDark,
    required this.decorationCount,
    this.offRoad = SurfaceType.grass,
  });

  /// Background / off-road color.
  final Color grass;
  final Color road;
  final Color curbA;
  final Color curbB;
  final Color line;
  final Color decoration;
  final Color decorationDark;
  final int decorationCount;

  /// Surface used for everything beyond the curbs.
  final SurfaceType offRoad;
}

/// A patch of special surface on the road, defined along the track.
class SurfaceZone {
  const SurfaceZone({
    required this.surface,
    required this.start,
    required this.end,
    this.lateralMin = -1,
    this.lateralMax = 1,
  });

  final SurfaceType surface;

  /// Start and end as a fraction of track length (0..1, start < end).
  final double start;
  final double end;

  /// Sideways range across the road, -1 (left edge) to 1 (right edge).
  final double lateralMin;
  final double lateralMax;
}

/// Everything needed to build and race a track. Pure data.
class TrackData {
  const TrackData({
    required this.id,
    required this.name,
    required this.laps,
    required this.roadWidth,
    required this.difficulty,
    required this.parTimeSeconds,
    required this.controlPoints,
    required this.theme,
    this.zones = const [],
    this.seed = 1,
  });

  final String id;
  final String name;
  final int laps;
  final double roadWidth;

  /// 1 = easy, 2 = medium, 3 = hard.
  final int difficulty;
  final int parTimeSeconds;

  /// Closed loop of points the road passes through (smoothed by a spline).
  final List<Offset> controlPoints;
  final TrackTheme theme;
  final List<SurfaceZone> zones;

  /// Seed for decoration placement so a track always looks the same.
  final int seed;
}
