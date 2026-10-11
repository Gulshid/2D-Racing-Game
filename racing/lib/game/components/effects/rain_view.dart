import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/app_settings.dart';
import 'package:racing/data/models/weather_type.dart';
import 'package:racing/game/racing_game.dart';

/// Screen-space rain: a dark tint plus falling streaks. Added to the camera
/// viewport, so it ignores zoom. Drop positions live in 0..1 screen space
/// and are reused every frame (nothing is allocated while racing).
class RainView extends Component with HasGameReference<RacingGame> {
  RainView({required this.weather, required GraphicsQuality quality})
      : _active = _countFor(quality),
        super(priority: 38);

  final WeatherType weather;

  static const double _slant = 0.18;

  static int _countFor(GraphicsQuality q) => switch (q) {
        GraphicsQuality.low => (GameConfig.rainDropsHigh * 0.3).round(),
        GraphicsQuality.medium => (GameConfig.rainDropsHigh * 0.6).round(),
        GraphicsQuality.high => GameConfig.rainDropsHigh,
      };

  final math.Random _rnd = math.Random(5);
  late final List<double> _x =
      List.generate(GameConfig.rainDropsHigh, (_) => _rnd.nextDouble());
  late final List<double> _y =
      List.generate(GameConfig.rainDropsHigh, (_) => _rnd.nextDouble());
  late final List<double> _v = List.generate(
    GameConfig.rainDropsHigh,
    (_) => 1.1 + _rnd.nextDouble() * 0.9,
  );
  int _active;

  final Paint _drop = Paint()
    ..strokeWidth = 1.3
    ..strokeCap = StrokeCap.round
    ..color = const Color(0x66CFE3FF);
  final Paint _tint = Paint();

  /// Lowers or raises the number of drops (adaptive quality).
  void setQuality(GraphicsQuality q) => _active = _countFor(q);

  @override
  void update(double dt) {
    if (!weather.isWet) return;
    for (var i = 0; i < _active; i++) {
      _y[i] += _v[i] * dt;
      _x[i] += _v[i] * _slant * dt * 0.6;
      if (_y[i] > 1) {
        _y[i] -= 1;
        _x[i] = _rnd.nextDouble();
      }
      if (_x[i] > 1) _x[i] -= 1;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!weather.isWet) return;
    final w = game.size.x;
    final h = game.size.y;
    _tint.color = Color.fromARGB((weather.darkness * 255).round(), 8, 14, 30);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _tint);
    final len = h * 0.045;
    for (var i = 0; i < _active; i++) {
      final px = _x[i] * w;
      final py = _y[i] * h;
      canvas.drawLine(
        Offset(px, py),
        Offset(px - len * _slant, py - len),
        _drop,
      );
    }
  }
}
