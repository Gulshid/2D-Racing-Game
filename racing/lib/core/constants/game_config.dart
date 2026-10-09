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

  // ---- AI opponents (Phase 7) ----------------------------------------------
  static const int aiMaxOpponents = 6;
  static const int aiDefaultOpponents = 5;

  /// AI decisions run this often. Physics still runs every fixed step.
  static const double aiThinkInterval = 1 / 30;

  // Racing line
  /// Relaxation passes that pull the line toward the shortest path.
  static const int aiLineIterations = 400;

  /// How far from the road centre the line may go (fraction of half width).
  static const double aiLineLimit = 0.62;
  static const int aiSmoothRadius = 4;
  static const int aiSmoothPasses = 3;

  /// Bad-surface zones: the line steers around them where it can.
  static const double aiZoneMargin = 0.03;
  static const double aiZonePad = 0.25;
  static const double aiMinCornerSpeed = 110;

  /// Nitro is only used when the road is straight this far ahead (px).
  static const double aiNitroLookAhead = 700;

  // Steering
  static const double aiLookMin = 90;
  static const double aiLookMax = 340;
  static const double aiSteerGain = 2.2;

  /// Above this heading error (rad) the AI just turns as hard as it can.
  static const double aiTurnAroundAngle = 0.9;

  /// Speed limit (px/s) while turning around, so the U-turn fits the road.
  static const double aiTurnAroundSpeed = 90;

  /// How fast the AI slides sideways off its line (px/s).
  static const double aiLateralRate = 140;

  /// The AI never aims closer than this to the road edge (px).
  static const double aiEdgeMargin = 30;

  // Speed control
  static const double aiThrottleBand = 30;
  static const double aiBrakeDeadband = 10;
  static const double aiBrakeBand = 50;

  /// Finished AI cars keep driving at this fraction of top speed.
  static const double aiFinishedCruise = 0.35;
  static const double aiNitroMinMeter = 0.3;
  static const double aiNitroMaxSteerError = 0.12;

  // Traffic (overtaking and avoidance)
  static const double aiSensorRange = 260;
  static const double aiSensorSpeedFactor = 0.25;
  static const double aiSideGap = 18;

  /// Cars this close beside us still count as blocking.
  static const double aiAlongside = 48;
  static const double aiFollowDistance = 70;
  static const double aiFollowGain = 1.5;

  /// The chosen passing side is kept until no car was in the way this long.
  static const double aiPassHold = 1;

  /// While there is room to pass, the AI keeps at least this speed so it
  /// can steer around a slow or stopped car instead of waiting behind it.
  static const double aiPassCreepSpeed = 90;

  // Mistakes
  static const double aiMistakeMinSpeed = 200;

  // Recovery
  static const double aiStuckSpeed = 25;
  static const double aiStuckSeconds = 1.4;
  static const double aiReverseSeconds = 0.9;

  /// Angle to the road direction (rad) that counts as "spun out".
  static const double aiSpunAngle = 2.2;
  static const double aiSpunSeconds = 1.2;
  static const int aiRespawnAfterRecoveries = 3;
  static const double aiRecoveryWindow = 15;

  // Rubber band (light catch-up / slow-down relative to the player)
  static const bool aiRubberBand = true;
  static const double aiRubberDeadZone = 400;
  static const double aiRubberRange = 2000;
}
