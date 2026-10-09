import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:flutter/services.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/game/components/effects/spark_emitter.dart';
import 'package:racing/game/systems/camera_controller.dart';

/// Turns collision events into feel: sparks, camera shake and haptics.
class ImpactFeedback {
  ImpactFeedback({
    required this.camera,
    required this.sparks,
    this.haptics = true,
  });

  final CameraController camera;
  final SparkEmitter sparks;

  /// Phase 8 connects this to the settings screen.
  bool haptics;

  double _clock = 0;
  double _lastHaptic = -10;
  double _lastScrape = -10;

  void tick(double dt) => _clock += dt;

  void wall(
    Vector2 point,
    Vector2 normalOut,
    double impact,
    double slide, {
    required bool isPlayer,
  }) {
    final away = Vector2(-normalOut.x, -normalOut.y);
    if (impact > 40) {
      final count = math.max(3, math.min(24, (impact / 25).round()));
      sparks.emit(point, away, count);
      if (isPlayer) {
        camera.addShake(clampD(impact / 500, 0, 1) * 0.9);
        _haptic(impact);
      }
    } else if (slide > 120 && _clock - _lastScrape > 0.05) {
      _lastScrape = _clock;
      sparks.emit(point, away, 2, speed: 160);
    }
  }

  void carHit(Vector2 point, double impact, {required bool involvesPlayer}) {
    if (impact < 30) return;
    final count = math.max(2, math.min(14, (impact / 35).round()));
    sparks.emit(point, Vector2(1, 0), count, speed: 200);
    if (involvesPlayer) {
      camera.addShake(clampD(impact / 600, 0, 1) * 0.7);
      _haptic(impact);
    }
  }

  void light() => _haptic(0);

  void _haptic(double impact) {
    if (!haptics || _clock - _lastHaptic < 0.15) return;
    _lastHaptic = _clock;
    if (impact > 300) {
      HapticFeedback.heavyImpact();
    } else if (impact > 150) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }
}
