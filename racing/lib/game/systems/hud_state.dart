import 'package:racing/data/models/surface_type.dart';

/// Snapshot of values the HUD shows. Compared by value so the HUD only
/// rebuilds when something visible changes.
class HudState {
  const HudState({
    this.speedKmh = 0,
    this.surface = SurfaceType.asphalt,
    this.nitro = 1,
    this.nitroActive = false,
    this.drifting = false,
  });

  final int speedKmh;
  final SurfaceType surface;
  final double nitro;
  final bool nitroActive;
  final bool drifting;

  @override
  bool operator ==(Object other) =>
      other is HudState &&
      other.speedKmh == speedKmh &&
      other.surface == surface &&
      other.nitro == nitro &&
      other.nitroActive == nitroActive &&
      other.drifting == drifting;

  @override
  int get hashCode =>
      Object.hash(speedKmh, surface, nitro, nitroActive, drifting);
}
