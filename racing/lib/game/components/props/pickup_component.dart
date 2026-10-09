import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/track_data.dart';

/// A coin or a nitro canister. Hidden after pickup; nitro respawns.
class PickupComponent extends PositionComponent {
  PickupComponent({required this.type, required Vector2 position})
      : _time = math.Random().nextDouble() * 6,
        super(
          position: position,
          size: Vector2.all(
            (type == PropType.nitro
                    ? GameConfig.nitroPickupRadius
                    : GameConfig.coinRadius) *
                2,
          ),
          anchor: Anchor.center,
          priority: 6,
        );

  /// PropType.coin or PropType.nitro.
  final PropType type;
  bool collected = false;

  double _time;
  double _respawn = 0;

  final Paint _gold = Paint()..color = const Color(0xFFFFC107);
  final Paint _goldLight = Paint()..color = const Color(0xFFFFE082);
  final Paint _blue = Paint()..color = const Color(0xFF29B6F6);
  final Paint _glow = Paint()..color = const Color(0x5529B6F6);
  final Paint _white = Paint()..color = const Color(0xFFFFFFFF);

  double get radius => type == PropType.nitro
      ? GameConfig.nitroPickupRadius
      : GameConfig.coinRadius;

  void collect() {
    collected = true;
    _respawn = type == PropType.nitro ? GameConfig.nitroRespawnSeconds : 0;
  }

  void reset() {
    collected = false;
    _respawn = 0;
  }

  @override
  void update(double dt) {
    _time += dt;
    if (collected && _respawn > 0) {
      _respawn -= dt;
      if (_respawn <= 0) collected = false;
    }
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;
    final c = Offset(size.x / 2, size.y / 2);
    final r = size.x / 2;
    final pulse = 1 + 0.1 * math.sin(_time * 6);

    if (type == PropType.coin) {
      canvas
        ..drawCircle(c, r * pulse, _gold)
        ..drawCircle(c, r * 0.65 * pulse, _goldLight);
    } else {
      final bolt = Path()
        ..moveTo(c.dx + r * 0.1, c.dy - r * 0.6)
        ..lineTo(c.dx - r * 0.35, c.dy + r * 0.1)
        ..lineTo(c.dx - r * 0.02, c.dy + r * 0.1)
        ..lineTo(c.dx - r * 0.12, c.dy + r * 0.6)
        ..lineTo(c.dx + r * 0.38, c.dy - r * 0.15)
        ..lineTo(c.dx + r * 0.05, c.dy - r * 0.15)
        ..close();
      canvas
        ..drawCircle(c, r * 1.35 * pulse, _glow)
        ..drawCircle(c, r * pulse, _blue)
        ..drawPath(bolt, _white);
    }
  }
}
