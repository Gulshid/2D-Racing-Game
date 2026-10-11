import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/surface_type.dart';

/// Weather for a race. It changes grip (see [gripFor]) and the visuals.
enum WeatherType {
  clear(label: 'Clear', darkness: 0),
  rain(label: 'Rain', darkness: 0.22);

  const WeatherType({required this.label, required this.darkness});

  final String label;

  /// Strength (0..1) of the dark tint drawn over the race.
  final double darkness;

  bool get isWet => this == WeatherType.rain;

  /// Multiplier applied to [SurfaceType.grip] for this weather.
  double gripFor(SurfaceType surface) {
    if (!isWet) return 1;
    return switch (surface) {
      SurfaceType.asphalt || SurfaceType.curb => GameConfig.rainAsphaltGrip,
      SurfaceType.grass => GameConfig.rainGrassGrip,
      SurfaceType.sand || SurfaceType.ice || SurfaceType.oil => 1,
    };
  }

  /// Safe lookup from a URL or saved value; unknown values mean [clear].
  static WeatherType fromIndex(int? i) =>
      (i != null && i >= 0 && i < values.length) ? values[i] : clear;
}
