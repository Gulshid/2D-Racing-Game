import 'dart:ui';

/// Handling values for one car. Everything is in pixels and seconds.
class CarStats {
  const CarStats({
    required this.name,
    required this.color,
    required this.maxSpeed,
    required this.acceleration,
    required this.braking,
    required this.steering,
    required this.grip,
    required this.driftFactor,
    required this.slideTendency,
    required this.mass,
    required this.nitroPower,
    required this.nitroCapacity,
  });

  final String name;
  final Color color;

  /// Top speed in px/s.
  final double maxSpeed;

  /// Engine acceleration in px/s^2.
  final double acceleration;

  /// Braking deceleration in px/s^2.
  final double braking;

  /// Max steering rate in rad/s.
  final double steering;

  /// Lateral grip: how fast sideways speed is removed (1/s). Higher = planted.
  final double grip;

  /// Multiplier on grip while the handbrake is held. Lower = more drift.
  final double driftFactor;

  /// How much grip is lost when steering hard at high speed (0..1).
  final double slideTendency;

  /// Used by car-to-car collisions in Phase 5.
  final double mass;

  /// Acceleration multiplier while nitro is active.
  final double nitroPower;

  /// Seconds of continuous nitro from a full meter.
  final double nitroCapacity;

  CarStats copyWith({
    String? name,
    Color? color,
    double? maxSpeed,
    double? acceleration,
    double? braking,
    double? steering,
    double? grip,
    double? driftFactor,
    double? slideTendency,
    double? mass,
    double? nitroPower,
    double? nitroCapacity,
  }) {
    return CarStats(
      name: name ?? this.name,
      color: color ?? this.color,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      acceleration: acceleration ?? this.acceleration,
      braking: braking ?? this.braking,
      steering: steering ?? this.steering,
      grip: grip ?? this.grip,
      driftFactor: driftFactor ?? this.driftFactor,
      slideTendency: slideTendency ?? this.slideTendency,
      mass: mass ?? this.mass,
      nitroPower: nitroPower ?? this.nitroPower,
      nitroCapacity: nitroCapacity ?? this.nitroCapacity,
    );
  }
}

/// The four cars available in version 1.
abstract final class CarPresets {
  static const CarStats starter = CarStats(
    name: 'Starter',
    color: Color(0xFFFF5A1F),
    maxSpeed: 520,
    acceleration: 220,
    braking: 900,
    steering: 2.6,
    grip: 10,
    driftFactor: 0.2,
    slideTendency: 0.3,
    mass: 1,
    nitroPower: 1.8,
    nitroCapacity: 3,
  );

  static const CarStats drifter = CarStats(
    name: 'Drifter',
    color: Color(0xFF8E44FF),
    maxSpeed: 500,
    acceleration: 210,
    braking: 850,
    steering: 2.9,
    grip: 7.5,
    driftFactor: 0.15,
    slideTendency: 0.45,
    mass: 0.9,
    nitroPower: 1.8,
    nitroCapacity: 3,
  );

  static const CarStats speedster = CarStats(
    name: 'Speedster',
    color: Color(0xFF16B7E8),
    maxSpeed: 640,
    acceleration: 250,
    braking: 950,
    steering: 2.3,
    grip: 9,
    driftFactor: 0.22,
    slideTendency: 0.35,
    mass: 0.95,
    nitroPower: 2,
    nitroCapacity: 2.5,
  );

  static const CarStats heavy = CarStats(
    name: 'Heavy',
    color: Color(0xFF3DBE5B),
    maxSpeed: 480,
    acceleration: 170,
    braking: 800,
    steering: 2.2,
    grip: 11,
    driftFactor: 0.3,
    slideTendency: 0.2,
    mass: 1.6,
    nitroPower: 1.6,
    nitroCapacity: 4,
  );

  static const List<CarStats> all = [starter, drifter, speedster, heavy];

  static CarStats byIndex(int index) =>
      all[(index < 0 || index >= all.length) ? 0 : index];
}
