import 'package:racing/data/models/app_settings.dart';

/// Lowers graphics quality when the game cannot keep up with the target
/// frame rate, so it stays playable on older phones.
///
/// Rules:
///  - It only steps DOWN (high -> medium -> low) and never raises quality,
///    so the screen does not flicker between levels.
///  - It looks at one-second averages. Quality steps down only after
///    [slowSecondsToStep] slow seconds in a row.
///  - Nothing happens during the first [warmupSeconds] of a race (loading,
///    countdown, first shader compiles), and there is a cooldown between
///    steps.
///  - Frames longer than one second (pauses, app switches) are ignored.
///  - The player's own setting is untouched; this only affects the current race.
class AdaptiveQuality {
  AdaptiveQuality({
    required GraphicsQuality start,
    this.targetFps = 50,
    this.warmupSeconds = 5,
    this.slowSecondsToStep = 3,
    this.cooldownSeconds = 6,
  }) : _level = start;

  final double targetFps;
  final double warmupSeconds;
  final int slowSecondsToStep;
  final double cooldownSeconds;

  GraphicsQuality _level;
  GraphicsQuality get level => _level;

  double _elapsed = 0;
  double _bucketTime = 0;
  int _bucketFrames = 0;
  int _slowSeconds = 0;
  double _cooldown = 0;
  int _steps = 0;

  int get stepsTaken => _steps;

  /// Call once per frame with that frame's duration in seconds. Returns the
  /// new level when it changes, otherwise null.
  GraphicsQuality? onFrame(double dt) {
    if (dt <= 0 || dt > 1) return null;
    _elapsed += dt;
    if (_cooldown > 0) _cooldown -= dt;

    _bucketTime += dt;
    _bucketFrames++;
    if (_bucketTime < 1) return null;

    final fps = _bucketFrames / _bucketTime;
    _bucketTime = 0;
    _bucketFrames = 0;

    final ready = _elapsed >= warmupSeconds &&
        _cooldown <= 0 &&
        _level != GraphicsQuality.low;
    if (!ready) {
      _slowSeconds = 0;
      return null;
    }

    _slowSeconds = fps < targetFps ? _slowSeconds + 1 : 0;
    if (_slowSeconds < slowSecondsToStep) return null;

    _slowSeconds = 0;
    _cooldown = cooldownSeconds;
    _steps++;
    _level = _level == GraphicsQuality.high
        ? GraphicsQuality.medium
        : GraphicsQuality.low;
    return _level;
  }
}
