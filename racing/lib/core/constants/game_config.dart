/// Central place for all tuning values. No magic numbers elsewhere.
abstract final class GameConfig {
  // ---- Engine / loop -------------------------------------------------------
  /// Physics runs at 120 steps per second, independent of display FPS.
  static const double physicsStep = 1 / 120;

  /// Longest frame time accepted; prevents a "spiral of death" after a hitch.
  static const double maxFrameTime = 0.1;

  /// Draws Flame hitboxes and component bounds when true.
  static const bool debugOverlays = false;

  // ---- Car -----------------------------------------------------------------
  static const double carLength = 52;
  static const double carWidth = 28;

  /// Seconds-based rates for smoothing digital steering input.
  static const double steerRiseRate = 5;
  static const double steerReturnRate = 9;

  /// Speed (px/s) at which steering reaches full effect.
  static const double steerFullSpeed = 90;

  /// Fraction of steering lost at top speed (keeps high speed stable).
  static const double highSpeedSteerLoss = 0.45;
  static const double handbrakeSteerBoost = 1.3;
  static const double handbrakeDrag = 0.6;

  static const double reverseThreshold = 5;
  static const double reverseSpeedFactor = 0.35;
  static const double rollingDrag = 0.45;
  static const double overspeedDrag = 3.5;

  // ---- Nitro ---------------------------------------------------------------
  static const double nitroTopSpeedBoost = 1.3;
  static const double nitroRegenRate = 0.12;
  static const double nitroRegenDelay = 1.5;
  static const double nitroUnlockLevel = 0.25;

  // ---- Feedback ------------------------------------------------------------
  /// Sideways speed (px/s) above which the car counts as drifting.
  static const double driftThreshold = 90;

  /// Converts px/s into the km/h number shown on the HUD.
  static const double kmhPerUnit = 0.4;

  // ---- Camera --------------------------------------------------------------
  static const double cameraBaseZoom = 1;
  static const double cameraMinZoom = 0.62;
  static const double cameraFollowRate = 6;
  static const double cameraZoomRate = 2.5;

  /// Seconds of velocity the camera looks ahead.
  static const double cameraLookAhead = 0.3;
  static const double cameraSpeedForMinZoom = 620;

  // ---- Track ---------------------------------------------------------------
  /// Approximate distance in px between centerline samples.
  static const double trackSampleSpacing = 20;
  static const double curbWidth = 16;

  /// How many samples either side of the last known index are searched first.
  static const int trackQueryWindow = 30;
}
