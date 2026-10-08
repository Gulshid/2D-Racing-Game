/// Central place for all tuning values. No magic numbers elsewhere.
abstract final class GameConfig {
  /// Physics runs at 120 steps per second, independent of display FPS.
  static const double physicsStep = 1 / 120;

  /// Longest frame time accepted; prevents a "spiral of death" after a hitch.
  static const double maxFrameTime = 0.1;

  /// Test box values (removed in Phase 3).
  static const double testBoxSize = 60;
  static const double testBoxSpeed = 300;
}
