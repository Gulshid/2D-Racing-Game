import 'dart:math' as math;

/// Small math helpers that always return double (avoids num from clamp).
double clampD(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);

double lerpD(double a, double b, double t) => a + (b - a) * t;

/// Wraps an angle in radians to -pi..pi.
double wrapAngle(double a) {
  final r = (a + math.pi) % (2 * math.pi);
  return r - math.pi;
}
