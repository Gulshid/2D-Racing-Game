/// Small math helpers that always return double (avoids num from clamp).
double clampD(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);

double lerpD(double a, double b, double t) => a + (b - a) * t;
