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

  /// Max camera shake offset in px at full trauma, and how fast it fades.
  static const double shakeMax = 16;
  static const double shakeDecay = 2.2;

  // ---- Track ---------------------------------------------------------------
  /// Approximate distance in px between centerline samples.
  static const double trackSampleSpacing = 20;
  static const double curbWidth = 16;

  /// How many samples either side of the last known index are searched first.
  static const int trackQueryWindow = 30;

  // ---- Walls (Phase 5) -----------------------------------------------------
  /// Drivable grass/sand between the curb and the barrier.
  static const double runoffWidth = 70;
  static const double barrierThickness = 14;
  static const double wallRestitution = 0.35;

  /// Fraction of sideways speed lost on an impact with a wall.
  static const double wallFriction = 0.12;

  /// Continuous speed loss per second while scraping along a wall.
  static const double wallScrapeDrag = 1.2;

  /// How strongly an impact at the car's nose or tail rotates the car.
  static const double wallYawFactor = 8e-5;

  /// Each car is two circles (front and rear) for collisions.
  static const double carCircleRadius = 14;
  static const double carCircleOffset = 12;

  // ---- Car vs car ----------------------------------------------------------
  static const double carRestitution = 0.3;
  static const double carYawFactor = 6e-5;

  // ---- Props ---------------------------------------------------------------
  static const double coneRadius = 9;
  static const double coinRadius = 10;
  static const double nitroPickupRadius = 16;
  static const double coneHitSlowdown = 0.93;
  static const double nitroPickupAmount = 0.5;
  static const double nitroRespawnSeconds = 12;

  /// Boost pad size: length along the road, width as a fraction of the road.
  static const double padLength = 70;
  static const double padWidthFactor = 0.55;
  static const double padBoostSeconds = 1.2;
  static const double padBoostPower = 2.2;
  static const double padKick = 120;

  // ---- Anti-stuck ----------------------------------------------------------
  static const double stuckTime = 3;
  static const double stuckSpeed = 30;

  // ---- Sparks --------------------------------------------------------------
  static const int sparkPoolSize = 120;

  // ---- Race (Phase 6) ------------------------------------------------------
  static const int countdownSeconds = 3;
  static const double goDisplaySeconds = 0.8;

  /// Approximate distance in px between checkpoints.
  static const double checkpointSpacing = 800;

  /// A progress change bigger than this in one step is a teleport; ignored.
  static const double progressJumpLimit = 0.2;
  static const double wrongWaySeconds = 1.2;
  static const double wrongWayMinSpeed = 60;

  /// Ghost car sample rate (samples per second of lap time).
  static const int ghostRate = 20;
}
