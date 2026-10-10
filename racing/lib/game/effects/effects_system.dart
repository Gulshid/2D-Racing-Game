import 'dart:math' as math;
import 'dart:typed_data';

import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/app_settings.dart';
import 'package:racing/data/models/surface_type.dart';
import 'package:racing/game/components/car/car_physics.dart';

/// How much visual effect work each graphics quality allows.
class EffectsBudget {
  const EffectsBudget({
    required this.emitScale,
    required this.marks,
    required this.particles,
    required this.shadows,
    required this.speedLines,
    required this.vignette,
  });

  factory EffectsBudget.of(GraphicsQuality q) => switch (q) {
        GraphicsQuality.low => const EffectsBudget(
            emitScale: 0.25,
            marks: 0,
            particles: 90,
            shadows: false,
            speedLines: false,
            vignette: false,
          ),
        GraphicsQuality.medium => const EffectsBudget(
            emitScale: 0.6,
            marks: 500,
            particles: 220,
            shadows: true,
            speedLines: true,
            vignette: true,
          ),
        GraphicsQuality.high => const EffectsBudget(
            emitScale: 1,
            marks: 1200,
            particles: 420,
            shadows: true,
            speedLines: true,
            vignette: true,
          ),
      };

  /// Multiplies how many particles are emitted per second.
  final double emitScale;

  /// Number of tire-mark segments kept (0 = off).
  final int marks;

  /// Number of particles kept.
  final int particles;

  final bool shadows;
  final bool speedLines;
  final bool vignette;
}

/// Fixed-size pool of tire-mark line segments. Old segments fade and are
/// reused in a ring, so nothing is allocated while racing.
class TireMarkPool {
  TireMarkPool(this.capacity)
      : x1 = Float64List(capacity),
        y1 = Float64List(capacity),
        x2 = Float64List(capacity),
        y2 = Float64List(capacity),
        age = Float64List(capacity),
        life = Float64List(capacity);

  /// Seconds a mark stays visible.
  static const double markLife = 7;

  final int capacity;
  final Float64List x1;
  final Float64List y1;
  final Float64List x2;
  final Float64List y2;
  final Float64List age;
  final Float64List life;
  int _next = 0;

  void add(double ax, double ay, double bx, double by) {
    if (capacity == 0) return;
    final i = _next;
    _next = (_next + 1) % capacity;
    x1[i] = ax;
    y1[i] = ay;
    x2[i] = bx;
    y2[i] = by;
    age[i] = 0;
    life[i] = markLife;
  }

  void update(double dt) {
    for (var i = 0; i < capacity; i++) {
      if (age[i] < life[i]) age[i] += dt;
    }
  }

  bool alive(int i) => age[i] < life[i];

  void clear() {
    for (var i = 0; i < capacity; i++) {
      life[i] = 0;
      age[i] = 0;
    }
  }
}

/// Fixed-size pool of particles (dust, smoke, nitro flame).
class ParticlePool {
  ParticlePool(this.capacity)
      : x = Float64List(capacity),
        y = Float64List(capacity),
        vx = Float64List(capacity),
        vy = Float64List(capacity),
        life = Float64List(capacity),
        maxLife = Float64List(capacity),
        size0 = Float64List(capacity),
        size1 = Float64List(capacity),
        alpha = Float64List(capacity),
        rgb = Int32List(capacity);

  final int capacity;
  final Float64List x;
  final Float64List y;
  final Float64List vx;
  final Float64List vy;

  /// Seconds left; a particle is alive while this is above 0.
  final Float64List life;
  final Float64List maxLife;
  final Float64List size0;
  final Float64List size1;
  final Float64List alpha;

  /// Colour as 0xRRGGBB.
  final Int32List rgb;
  int _next = 0;

  void emit(
    double px,
    double py,
    double pvx,
    double pvy, {
    required double life,
    required double size0,
    required double size1,
    required int rgb,
    required double alpha,
  }) {
    if (capacity == 0) return;
    final i = _next;
    _next = (_next + 1) % capacity;
    x[i] = px;
    y[i] = py;
    vx[i] = pvx;
    vy[i] = pvy;
    this.life[i] = life;
    maxLife[i] = life;
    this.size0[i] = size0;
    this.size1[i] = size1;
    this.rgb[i] = rgb;
    this.alpha[i] = alpha;
  }

  void update(double dt) {
    final drag = math.exp(-2.5 * dt);
    for (var i = 0; i < capacity; i++) {
      if (life[i] <= 0) continue;
      x[i] += vx[i] * dt;
      y[i] += vy[i] * dt;
      vx[i] *= drag;
      vy[i] *= drag;
      life[i] -= dt;
    }
  }

  void clear() {
    for (var i = 0; i < capacity; i++) {
      life[i] = 0;
    }
  }
}

class _Trail {
  bool has = false;
  double x = 0;
  double y = 0;
}

/// Per-car emitter state (accumulators and wheel trails).
class _CarFx {
  final _Trail left = _Trail();
  final _Trail right = _Trail();
  double dust = 0;
  double smoke = 0;
  double flame = 0;

  void reset() {
    left.has = false;
    right.has = false;
  }
}

/// Decides what effects each car makes each frame: tire marks while
/// drifting, dust on grass and sand, drift smoke, and nitro flame.
///
/// Pure logic (no drawing). The views in effects_views.dart draw it.
/// Cars far from the player are skipped to save work.
class EffectsSystem {
  EffectsSystem({required GraphicsQuality quality, required this.cars})
      : budget = EffectsBudget.of(quality),
        marks = TireMarkPool(EffectsBudget.of(quality).marks),
        particles = ParticlePool(EffectsBudget.of(quality).particles),
        _fx = [for (var i = 0; i < cars.length; i++) _CarFx()];

  static const double _farDistance = 1400;

  EffectsBudget budget;

  /// Every car on the track. cars[0] is the player.
  final List<CarPhysics> cars;
  final TireMarkPool marks;
  final ParticlePool particles;
  final List<_CarFx> _fx;
  final math.Random _rnd = math.Random(11);

  /// Lowers (or sets) the effect budget during a race. The pools keep their
  /// size, so this costs nothing beyond the next frame's emission rate.
  void setQuality(GraphicsQuality q) {
    budget = EffectsBudget.of(q);
  }

  /// Removes all effects (used on restart).
  void clear() {
    marks.clear();
    particles.clear();
    for (final f in _fx) {
      f.reset();
    }
  }

  void update(double dt) {
    marks.update(dt);
    particles.update(dt);
    if (cars.isEmpty) return;
    final player = cars.first;
    for (var i = 0; i < cars.length; i++) {
      final car = cars[i];
      final fx = _fx[i];
      if (i > 0 && _distance(car, player) > _farDistance) {
        fx.reset();
        continue;
      }
      _emit(car, fx, dt: dt);
    }
  }

  double _distance(CarPhysics a, CarPhysics b) {
    final dx = a.position.x - b.position.x;
    final dy = a.position.y - b.position.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  void _emit(CarPhysics p, _CarFx fx, {required double dt}) {
    final fwdX = math.cos(p.heading);
    final fwdY = math.sin(p.heading);
    final rightX = -fwdY;
    final rightY = fwdX;
    final rearX = p.position.x - fwdX * GameConfig.carLength * 0.35;
    final rearY = p.position.y - fwdY * GameConfig.carLength * 0.35;
    final half = GameConfig.carWidth * 0.42;
    final leftX = rearX - rightX * half;
    final leftY = rearY - rightY * half;
    final rightWheelX = rearX + rightX * half;
    final rightWheelY = rearY + rightY * half;
    final scale = budget.emitScale;
    final drifting = p.isDrifting;

    // Tire marks: follow both rear wheels while the car is sliding.
    if (drifting && budget.marks > 0) {
      _trail(fx.left, leftX, leftY);
      _trail(fx.right, rightWheelX, rightWheelY);
    } else {
      fx.reset();
    }

    // Drift smoke from the rear wheels.
    if (drifting && p.speed > 150) {
      fx.smoke += dt * 26 * scale;
      while (fx.smoke >= 1) {
        fx.smoke -= 1;
        final useLeft = _rnd.nextBool();
        _spawnSmoke(useLeft ? leftX : rightWheelX, useLeft ? leftY : rightWheelY);
      }
    }

    // Dust kicked up on grass and sand.
    final surface = p.surface;
    final dusty = surface == SurfaceType.grass || surface == SurfaceType.sand;
    if (dusty && p.speed > 120) {
      final isSand = surface == SurfaceType.sand;
      fx.dust += dt * (isSand ? 40 : 26) * scale;
      while (fx.dust >= 1) {
        fx.dust -= 1;
        _spawnDust(rearX, rearY, sand: isSand);
      }
    }

    // Nitro / boost flame behind the car.
    if (p.boostActive && p.speed > 40) {
      fx.flame += dt * 70 * scale;
      while (fx.flame >= 1) {
        fx.flame -= 1;
        _spawnFlame(p, rearX, rearY, fwdX, fwdY);
      }
    }
  }

  void _trail(_Trail t, double x, double y) {
    if (t.has) {
      final dx = x - t.x;
      final dy = y - t.y;
      // Ignore big jumps (respawns) so no long line is drawn across the track.
      if (dx * dx + dy * dy < 40 * 40) marks.add(t.x, t.y, x, y);
    }
    t.has = true;
    t.x = x;
    t.y = y;
  }

  double _r(double a, double b) => a + (b - a) * _rnd.nextDouble();

  void _spawnDust(double x, double y, {required bool sand}) {
    particles.emit(
      x + _r(-6, 6),
      y + _r(-6, 6),
      _r(-40, 40),
      _r(-40, 40),
      life: _r(0.45, 0.75),
      size0: 5,
      size1: _r(12, 18),
      rgb: sand ? 0xD6BE82 : 0x6E8C3C,
      alpha: 120,
    );
  }

  void _spawnSmoke(double x, double y) {
    particles.emit(
      x + _r(-3, 3),
      y + _r(-3, 3),
      _r(-25, 25),
      _r(-25, 25),
      life: _r(0.6, 0.95),
      size0: 5,
      size1: _r(14, 20),
      rgb: 0xC8C8CD,
      alpha: 150,
    );
  }

  void _spawnFlame(CarPhysics p, double x, double y, double fwdX, double fwdY) {
    final back = p.speed * 0.35 + 50;
    particles.emit(
      x + _r(-3, 3),
      y + _r(-3, 3),
      -fwdX * back + _r(-30, 30),
      -fwdY * back + _r(-30, 30),
      life: _r(0.22, 0.38),
      size0: _r(7, 10),
      size1: 2,
      rgb: 0xFFB03A,
      alpha: 210,
    );
  }
}
