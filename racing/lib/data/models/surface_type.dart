/// Driving surfaces. Multipliers are applied by CarPhysics.
enum SurfaceType {
  asphalt(label: 'Asphalt', grip: 1, speed: 1, drag: 1),
  curb(label: 'Curb', grip: 0.95, speed: 0.97, drag: 1.1),
  grass(label: 'Grass', grip: 0.55, speed: 0.55, drag: 2.2),
  sand(label: 'Sand', grip: 0.45, speed: 0.4, drag: 3.2),
  ice(label: 'Ice', grip: 0.12, speed: 1, drag: 0.4),
  oil(label: 'Oil', grip: 0.07, speed: 0.9, drag: 0.8);

  const SurfaceType({
    required this.label,
    required this.grip,
    required this.speed,
    required this.drag,
  });

  final String label;

  /// Multiplies lateral grip and traction.
  final double grip;

  /// Multiplies the top speed.
  final double speed;

  /// Multiplies coasting drag.
  final double drag;
}
