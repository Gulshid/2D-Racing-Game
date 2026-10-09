import 'dart:math' as math;
import 'dart:ui';

import 'package:racing/data/models/car_stats.dart';

/// How good the AI drivers are. Pure data: tune the numbers here.
enum AiDifficulty {
  easy(
    label: 'Easy',
    speedScale: 0.80,
    cornerSafety: 0.62,
    brakeFactor: 0.40,
    mistakesPerMinute: 2.5,
    nitroUse: 0.25,
    lookTime: 0.36,
    rubberSlow: 0.10,
    rubberBoost: 0.04,
  ),
  medium(
    label: 'Medium',
    speedScale: 0.90,
    cornerSafety: 0.75,
    brakeFactor: 0.52,
    mistakesPerMinute: 1,
    nitroUse: 0.55,
    lookTime: 0.30,
    rubberSlow: 0.07,
    rubberBoost: 0.06,
  ),
  hard(
    label: 'Hard',
    speedScale: 0.985,
    cornerSafety: 0.88,
    brakeFactor: 0.66,
    mistakesPerMinute: 0.25,
    nitroUse: 0.9,
    lookTime: 0.26,
    rubberSlow: 0.04,
    rubberBoost: 0.05,
  );

  const AiDifficulty({
    required this.label,
    required this.speedScale,
    required this.cornerSafety,
    required this.brakeFactor,
    required this.mistakesPerMinute,
    required this.nitroUse,
    required this.lookTime,
    required this.rubberSlow,
    required this.rubberBoost,
  });

  final String label;

  /// Fraction of the physically possible speed the AI aims for.
  final double speedScale;

  /// Fraction of the car's turning ability the AI trusts in corners.
  final double cornerSafety;

  /// Fraction of the car's braking power the AI plans with. Lower = brakes
  /// earlier and more gently.
  final double brakeFactor;

  /// Average driving errors per minute.
  final double mistakesPerMinute;

  /// 0..1: how readily nitro is used on straights.
  final double nitroUse;

  /// Seconds of speed the AI looks ahead when steering.
  final double lookTime;

  /// Max speed reduction when far ahead of the player.
  final double rubberSlow;

  /// Max speed gain when far behind the player.
  final double rubberBoost;

  static AiDifficulty fromIndex(int index) =>
      values[(index < 0 || index >= values.length) ? 1 : index];
}

/// A driving style. Multiplies the difficulty settings.
enum AiPersonality {
  aggressive(
    label: 'Aggressive',
    speedBonus: 0.03,
    mistakeScale: 1.3,
    nitroScale: 1.5,
    brakeScale: 1.1,
    sensorScale: 0.8,
    sideGapDelta: -6,
    lineBiasRange: 0.22,
  ),
  cautious(
    label: 'Cautious',
    speedBonus: -0.05,
    mistakeScale: 0.6,
    nitroScale: 0.6,
    brakeScale: 0.85,
    sensorScale: 1.25,
    sideGapDelta: 8,
    lineBiasRange: 0.1,
  ),
  consistent(
    label: 'Consistent',
    speedBonus: 0,
    mistakeScale: 0.3,
    nitroScale: 1,
    brakeScale: 1,
    sensorScale: 1,
    sideGapDelta: 0,
    lineBiasRange: 0.05,
  );

  const AiPersonality({
    required this.label,
    required this.speedBonus,
    required this.mistakeScale,
    required this.nitroScale,
    required this.brakeScale,
    required this.sensorScale,
    required this.sideGapDelta,
    required this.lineBiasRange,
  });

  final String label;

  /// Added to the difficulty speed scale.
  final double speedBonus;
  final double mistakeScale;
  final double nitroScale;
  final double brakeScale;

  /// Multiplies how far ahead the car looks for traffic.
  final double sensorScale;

  /// Added to the sideways gap kept when passing (px).
  final double sideGapDelta;

  /// Random sideways offset from the racing line, as a fraction of half the
  /// road width, picked fresh every race.
  final double lineBiasRange;
}

/// One AI driver: name, colour, style and the car it drives.
///
/// The AI drives with exactly the same [CarStats] and physics as the player,
/// so races are fair.
class AiProfile {
  const AiProfile({
    required this.name,
    required this.color,
    required this.personality,
    required this.difficulty,
    required this.stats,
  });

  final String name;
  final Color color;
  final AiPersonality personality;
  final AiDifficulty difficulty;
  final CarStats stats;

  double get speedScale => difficulty.speedScale + personality.speedBonus;
  double get mistakesPerMinute =>
      difficulty.mistakesPerMinute * personality.mistakeScale;
  double get nitroUse =>
      math.min(1, difficulty.nitroUse * personality.nitroScale);
  double get brakeFactor => difficulty.brakeFactor * personality.brakeScale;
  double get lookTime => difficulty.lookTime;

  static const List<(String, Color, AiPersonality)> _drivers = [
    ('Blaze', Color(0xFFE53935), AiPersonality.aggressive),
    ('Viper', Color(0xFFFDD835), AiPersonality.consistent),
    ('Comet', Color(0xFF1DE9B6), AiPersonality.cautious),
    ('Nova', Color(0xFFEC407A), AiPersonality.aggressive),
    ('Rocket', Color(0xFFECEFF1), AiPersonality.consistent),
    ('Shadow', Color(0xFF3F51B5), AiPersonality.cautious),
  ];

  /// Builds [count] opponents (max 6). Every AI uses the player's car stats
  /// so difficulty comes only from driving skill. To give opponents
  /// different cars, replace `base` with presets from CarPresets here.
  static List<AiProfile> roster({
    required CarStats base,
    required AiDifficulty difficulty,
    required int count,
  }) {
    final n = count < 0 ? 0 : (count > _drivers.length ? _drivers.length : count);
    return [
      for (var i = 0; i < n; i++)
        AiProfile(
          name: _drivers[i].$1,
          color: _drivers[i].$2,
          personality: _drivers[i].$3,
          difficulty: difficulty,
          stats: base.copyWith(name: _drivers[i].$1, color: _drivers[i].$2),
        ),
    ];
  }
}
