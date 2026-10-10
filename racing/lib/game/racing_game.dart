import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/ai_profile.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/models/race_records.dart';
import 'package:racing/data/models/progression_config.dart';
import 'package:racing/data/models/race_result.dart';
import 'package:racing/data/models/track_data.dart';
import 'package:racing/game/components/car/ai_car.dart';
import 'package:racing/game/components/car/car_physics.dart';
import 'package:racing/game/components/car/ghost_car.dart';
import 'package:racing/game/components/car/player_car.dart';
import 'package:racing/game/components/effects/ai_debug_overlay.dart';
import 'package:racing/game/components/effects/effects_views.dart';
import 'package:racing/game/components/effects/spark_emitter.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:racing/game/audio/audio_service.dart';
import 'package:racing/game/performance/adaptive_quality.dart';
import 'package:racing/game/performance/frame_monitor.dart';
import 'package:racing/game/performance/perf_session.dart';
import 'package:racing/game/effects/effects_system.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/data/models/app_settings.dart';
import 'package:racing/game/components/props/cone_component.dart';
import 'package:racing/game/components/props/pickup_component.dart';
import 'package:racing/game/components/track/track_component.dart';
import 'package:racing/game/components/track/track_map.dart';
import 'package:racing/game/systems/ai_profiler.dart';
import 'package:racing/game/systems/camera_controller.dart';
import 'package:racing/game/systems/collision_system.dart';
import 'package:racing/game/systems/fixed_stepper.dart';
import 'package:racing/game/systems/fixed_update.dart';
import 'package:racing/game/systems/ghost_recorder.dart';
import 'package:racing/game/systems/hud_state.dart';
import 'package:racing/game/systems/impact_feedback.dart';
import 'package:racing/game/systems/input_controller.dart';
import 'package:racing/game/systems/minimap_marker.dart';
import 'package:racing/game/systems/race_hud_state.dart';
import 'package:racing/game/systems/race_manager.dart';
import 'package:racing/game/systems/racing_line.dart';

class RacingGame extends FlameGame with KeyboardEvents {
  RacingGame({
    required this.trackData,
    required this.carStats,
    required this.audio,
    this.difficulty = AiDifficulty.medium,
    this.aiCount = GameConfig.aiDefaultOpponents,
    this.quality = GraphicsQuality.high,
    this.haptics = true,
  });

  static const String hudOverlay = 'hud';
  static const String controlsOverlay = 'controls';
  static const String tuningOverlay = 'tuning';
  static const String pauseOverlay = 'pause';
  static const String resultsOverlay = 'results';

  final TrackData trackData;
  final CarStats carStats;

  /// How good the AI drivers are, and how many of them race (0-6).
  final AiDifficulty difficulty;
  final int aiCount;

  /// Sound playback (shared across the app, owned by the provider).
  final AudioService audio;

  /// Graphics preset: scales particles, marks, shadows and screen effects.
  final GraphicsQuality quality;

  /// Vibration on impacts (from the settings screen).
  final bool haptics;

  // ---- Performance (Phase 11) ------------------------------------------------
  /// Real frame times from Flutter's frame timings.
  final FrameMonitor frames = FrameMonitor();

  /// Timed test run that writes a PERF report to the console.
  final PerfSession perf = PerfSession();

  /// Steps graphics quality down when frames run slow.
  late final AdaptiveQuality adaptive = AdaptiveQuality(start: quality);

  /// Quality in use right now (can be lower than the setting after adaptation).
  late GraphicsQuality _level = quality;

  // These are created lazily so overlays can read them at any time.
  late final TrackMap track = TrackMap(trackData);
  late final PlayerCar car = PlayerCar(stats: carStats);
  late final CameraController cameraController =
      CameraController(target: car);
  late final SparkEmitter sparks = SparkEmitter();

  // ---- Effects (Phase 9) -----------------------------------------------------
  late final EffectsSystem effects =
      EffectsSystem(quality: quality, cars: allPhysics);
  late final GroundEffectsView groundFx = GroundEffectsView(effects);
  late final ParticleEffectsView particleFx = ParticleEffectsView(effects);
  late final ScreenEffects screenFx = ScreenEffects(quality: quality);
  double _audioClock = 0;
  double _lastEngineTick = -1;
  RaceState _lastRaceState = RaceState.idle;
  String _lastLabel = '';
  bool _lastBoost = false;
  bool _finalLapMusic = false;

  // ---- Progression counters for this race (Phase 10) --------------------------
  int _drifts = 0;
  bool _wasDrifting = false;
  int _cleanLaps = 0;
  bool _lapHadHit = false;
  late final GhostCar ghost = GhostCar();
  late final RaceCarState playerState =
      RaceCarState(id: 'player', name: carStats.name, isPlayer: true);

  // ---- AI opponents (Phase 7) ----------------------------------------------
  late final RacingLine racingLine = RacingLine.build(track);
  late final List<AiCar> aiCars = _buildAiCars();

  /// Physics of every car on the track (player first). Used for traffic
  /// sensing and collisions.
  late final List<CarPhysics> allPhysics = [
    car.physics,
    for (final ai in aiCars) ai.physics,
  ];
  late final List<MinimapMarker> minimapMarkers = [
    for (final ai in aiCars) MinimapMarker(ai.physics.position, ai.profile.color),
  ];

  /// Shows the racing line, aim points and sensors of the AI cars.
  final ValueNotifier<bool> aiDebug = ValueNotifier<bool>(false);

  /// Measures AI cost per frame; shown in the debug HUD.
  final AiProfiler aiProfiler = AiProfiler();
  final ValueNotifier<double> aiCostMs = ValueNotifier<double>(0);
  int _frame = 0;

  late final RaceManager race = RaceManager(
    track: track,
    totalLaps: trackData.laps,
    cars: [playerState, for (final ai in aiCars) ai.state],
  );

  final InputController input = InputController();
  final GhostRecorder _recorder = GhostRecorder();

  late CollisionSystem collisions;
  late ImpactFeedback feedback;
  final List<ConeComponent> _cones = [];
  final List<PickupComponent> _pickups = [];
  bool _ready = false;

  /// Best times when this race started (to detect new records).
  double? _bestLapAtStart;
  double? _bestTotalAtStart;

  /// 0..1, listened to by the loading screen.
  final ValueNotifier<double> loadProgress = ValueNotifier<double>(0);

  /// Speed, surface and nitro for the HUD.
  final ValueNotifier<HudState> hud = ValueNotifier<HudState>(const HudState());

  /// Laps, position, countdown text and warnings.
  final ValueNotifier<RaceHudState> raceHud =
      ValueNotifier<RaceHudState>(const RaceHudState());

  /// Lap, best lap and total race time.
  final ValueNotifier<RaceTiming> timing =
      ValueNotifier<RaceTiming>(const RaceTiming());

  /// Set when the player finishes the race.
  final ValueNotifier<RaceResult?> result = ValueNotifier<RaceResult?>(null);

  /// Incremented every frame; the minimap repaints on it.
  final ValueNotifier<int> minimapTick = ValueNotifier<int>(0);

  final FixedStepper _stepper = FixedStepper(
    GameConfig.physicsStep,
    maxFrameTime: GameConfig.maxFrameTime,
  );
  final List<FixedUpdate> _fixed = [];

  @override
  Color backgroundColor() => trackData.theme.grass;

  @override
  Future<void> onLoad() async {
    frames.attach();
    debugMode = GameConfig.debugOverlays;
    await _preloadAssets();

    camera.viewport.add(FpsTextComponent(position: Vector2(12, 8)));

    // Scenery, props and cars.
    await world.add(TrackComponent(track));
    await world.add(ghost);
    for (final spawn in track.props) {
      switch (spawn.type) {
        case PropType.cone:
          _cones.add(ConeComponent(position: spawn.position.clone()));
        case PropType.coin:
        case PropType.nitro:
          _pickups.add(
            PickupComponent(type: spawn.type, position: spawn.position.clone()),
          );
        case PropType.boostPad:
          break; // drawn by TrackComponent, handled by CollisionSystem
      }
    }
    await world.addAll(_cones);
    await world.addAll(_pickups);
    await world.addAll(aiCars);
    await world.add(car);
    await world.add(sparks);
    await world.add(groundFx);
    await world.add(particleFx);
    camera.viewport.add(screenFx);
    await world.add(AiDebugOverlay());
    await world.add(cameraController);

    _setUpSystems();
    _ready = true;
    restart();
  }

  void _setUpSystems() {
    collisions = CollisionSystem(
      track: track,
      cars: allPhysics,
      cones: _cones,
      pickups: _pickups,
      player: car.physics,
    );
    feedback = ImpactFeedback(
      camera: cameraController,
      sparks: sparks,
      haptics: haptics,
    );

    bool isPlayer(Object c) => identical(c, car.physics);

    collisions.onWall = (c, point, normal, impact, slide) {
      feedback.wall(point, normal, impact, slide, isPlayer: isPlayer(c));
      if (isPlayer(c) && impact > 40) {
        _lapHadHit = true;
        audio.playSfx(
          Sfx.impactWall,
          volume: clampD(impact / 420, 0.2, 1),
          rate: audio.jitter(),
        );
      }
    };
    collisions.onCarHit = (a, b, point, impact) {
      final involved = isPlayer(a) || isPlayer(b);
      feedback.carHit(point, impact, involvesPlayer: involved);
      if (involved && impact > 30) {
        _lapHadHit = true;
        audio.playSfx(
          Sfx.impactCar,
          volume: clampD(impact / 380, 0.2, 1),
          rate: audio.jitter(),
        );
      }
    };
    collisions.onPickup = (c, type) {
      if (isPlayer(c)) {
        if (type == PropType.coin) playerState.coins++;
        feedback.light();
        audio.playSfx(Sfx.pickup, volume: 0.8);
      }
    };
    collisions.onConeHit = (c) {
      if (isPlayer(c)) {
        feedback.light();
        audio.playSfx(Sfx.impactWall, volume: 0.35, rate: 1.4);
      }
    };
    collisions.onBoostPad = (c) {
      if (isPlayer(c)) {
        cameraController.addShake(0.25);
        feedback.light();
      }
    };

    race.onLapStart = (s) {
      if (s.isPlayer) {
        _recorder.begin();
        _lapHadHit = false;
      }
    };
    race.onLapComplete = (s, lapTime, lap) {
      if (!s.isPlayer) return;
      if (!_lapHadHit) _cleanLaps++;
      _lapHadHit = false;
      final record = RaceRecords.of(trackData.id);
      final best = record.bestLap;
      if (best == null || lapTime < best) {
        record.bestLap = lapTime;
        record.ghost = _recorder.finish(lapTime);
      }
    };
    race.onFinish = (s) {
      if (s.isPlayer) _onPlayerFinished();
    };
  }

  List<AiCar> _buildAiCars() {
    final roster = AiProfile.roster(
      base: carStats,
      difficulty: difficulty,
      count: math.max(0, math.min(aiCount, GameConfig.aiMaxOpponents)),
    );
    return [
      for (var i = 0; i < roster.length; i++)
        AiCar(profile: roster[i], slot: i + 1, line: racingLine),
    ];
  }

  /// How many px [state] is ahead of the player (negative = behind). Null
  /// when rubber-banding should not apply (race not running, player done).
  double? gapToPlayer(RaceCarState state) {
    if (race.state != RaceState.racing || playerState.finished) return null;
    return (state.totalProgress - playerState.totalProgress) * track.length;
  }

  /// Puts an AI car back on the road at its last checkpoint.
  void respawnAi(AiCar ai) {
    if (!race.canDrive) return;
    final progress = race.respawnProgress(ai.state);
    final f = track.frame(progress);
    final nitro = ai.physics.nitro;
    ai.resetTo(f.position, f.heading);
    ai.physics.nitro = nitro;
  }

  void toggleAiDebug() => aiDebug.value = !aiDebug.value;

  /// Add image file names (relative to assets/images/) as you add assets.
  Future<void> _preloadAssets() async {
    const imageFiles = <String>[];
    if (imageFiles.isEmpty) {
      loadProgress.value = 1;
      return;
    }
    for (var i = 0; i < imageFiles.length; i++) {
      await images.load(imageFiles[i]);
      loadProgress.value = (i + 1) / imageFiles.length;
    }
  }

  void registerFixed(FixedUpdate c) => _fixed.add(c);
  void unregisterFixed(FixedUpdate c) => _fixed.remove(c);

  /// Puts everything back to the start and begins the countdown.
  void restart() {
    final spawn = track.spawn(0);
    car.resetTo(spawn.position, spawn.heading);
    input.reset();
    _stepper.reset();
    cameraController.snap();

    for (final ai in aiCars) {
      final slot = track.spawn(ai.slot);
      ai.resetTo(slot.position, slot.heading);
      ai.controller.reset();
    }

    for (final c in _cones) {
      c.reset();
    }
    for (final p in _pickups) {
      p.reset();
    }
    sparks.clear();
    _recorder.begin();

    final record = RaceRecords.of(trackData.id);
    _bestLapAtStart = record.bestLap;
    _bestTotalAtStart = record.bestTotal;

    result.value = null;
    overlays
      ..remove(resultsOverlay)
      ..add(hudOverlay)
      ..add(controlsOverlay);

    race.startCountdown();
    effects.clear();
    audio.startRaceAudio();
    audio.playMusic(Music.race);
    audio.setMusicRate(1);
    _lastRaceState = RaceState.idle;
    _lastLabel = '';
    _lastBoost = false;
    _finalLapMusic = false;
    _drifts = 0;
    _wasDrifting = false;
    _cleanLaps = 0;
    _lapHadHit = false;
  }

  /// Puts the player back on the road at the last checkpoint.
  void respawnPlayer() {
    if (!race.canDrive) return;
    final progress = race.respawnProgress(playerState);
    final f = track.frame(progress);
    final nitro = car.physics.nitro;
    car.resetTo(f.position, f.heading);
    car.physics.nitro = nitro;
    cameraController.snap();
  }

  void _onPlayerFinished() {
    final record = RaceRecords.of(trackData.id);
    final total = playerState.finishTime;
    final bestLap = playerState.bestLap;

    final newBestLap = bestLap != null &&
        (_bestLapAtStart == null || bestLap < _bestLapAtStart!);
    final newBestTotal =
        _bestTotalAtStart == null || total < _bestTotalAtStart!;
    if (newBestTotal) record.bestTotal = total;

    result.value = RaceResult(
      trackName: trackData.name,
      laps: trackData.laps,
      position: playerState.position,
      carCount: race.cars.length,
      totalTime: total,
      bestLap: bestLap,
      lapTimes: List.of(playerState.lapTimes),
      coins: playerState.coins,
      reward: RaceReward.of(
        position: playerState.position,
        coins: playerState.coins,
        cleanLaps: _cleanLaps,
        drifts: _drifts,
      ).total,
      trackId: trackData.id,
      drifts: _drifts,
      cleanLaps: _cleanLaps,
      newBestLap: newBestLap,
      newBestTotal: newBestTotal,
      standings: _standings(),
    );

    audio.stopRaceAudio();
    audio.playSfx(Sfx.goBeep, volume: 0.6);
    audio.setMusicRate(1);
    input.reset();
    overlays
      ..remove(hudOverlay)
      ..remove(controlsOverlay)
      ..remove(tuningOverlay)
      ..add(resultsOverlay);
  }

  List<StandingEntry> _standings() {
    final order = List<RaceCarState>.of(race.cars)
      ..sort((a, b) => a.position.compareTo(b.position));
    return [
      for (final s in order)
        StandingEntry(
          name: s.name,
          isPlayer: s.isPlayer,
          position: s.position,
          time: s.finished ? s.finishTime : null,
        ),
    ];
  }

  @override
  void update(double dt) {
    if (!_ready) {
      super.update(dt);
      return;
    }

    _stepper.run(dt, (step) {
      for (var i = 0; i < _fixed.length; i++) {
        _fixed[i].fixedUpdate(step);
      }
      collisions.step(step);
      race.update(step);
      final q = car.lastQuery;
      if (q != null) {
        race.observe(
          playerState,
          q,
          car.physics.velocity.x,
          car.physics.velocity.y,
          step,
        );
      }
      for (final ai in aiCars) {
        final aq = ai.lastQuery;
        if (aq != null) {
          race.observe(
            ai.state,
            aq,
            ai.physics.velocity.x,
            ai.physics.velocity.y,
            step,
          );
        }
      }
    });

    super.update(dt);
    feedback.tick(dt);
    _updateAudio(dt);
    _tickPerformance(dt);

    // Record the lap for the ghost car.
    if (race.state == RaceState.racing &&
        playerState.lapStart != null &&
        !playerState.finished) {
      _recorder.sample(
        playerState.currentLapTime,
        car.physics.position.x,
        car.physics.position.y,
        car.physics.heading,
      );
    }

    aiProfiler.endFrame();
    if (++_frame % 20 == 0) aiCostMs.value = aiProfiler.averageMs;

    // The HUD and minimap do not need 60 updates a second; 30 looks the same
    // and halves the Flutter rebuild cost during a race.
    if (_frame.isEven) _updateHud();
  }

  // ---- Performance (Phase 11) ----------------------------------------------

  /// Runs once per frame: adaptive quality, and the timed test run if active.
  void _tickPerformance(double dt) {
    final next = adaptive.onFrame(dt);
    if (next != null && next != _level) {
      _level = next;
      effects.setQuality(next);
      screenFx.setQuality(next);
      perf.noteQualityChange(next);
    }
    final report = perf.tick(
      dt: dt,
      aiMs: aiProfiler.averageMs,
      quality: _level,
    );
    if (report != null) debugPrint(report);
  }

  /// Starts a 30-second timed test run, or stops it early. The report goes to
  /// the console with the "PERF" prefix.
  void togglePerfSession() {
    if (perf.isRecording) {
      final report = perf.stop();
      if (report != null) debugPrint(report);
      return;
    }
    perf.start(label: trackData.id, quality: _level, frames: frames);
  }

  /// True when a world position is close enough to the player to be drawn.
  /// Radius = half the screen diagonal in world units, plus a margin, so
  /// nothing visible is ever skipped.
  bool isNearPlayer(double x, double y) {
    final p = car.physics.position;
    final dx = x - p.x;
    final dy = y - p.y;
    final zoom = math.max(0.01, camera.viewfinder.zoom);
    final radius = size.length / (2 * zoom) + 300;
    return dx * dx + dy * dy <= radius * radius;
  }

  @override
  void onRemove() {
    frames.detach();
    perf.stop();
    audio.stopRaceAudio();
    effects.clear();
    super.onRemove();
  }

  // ---- Audio and effects per frame (Phase 9) ---------------------------------

  double _rateBase(CarStats s) => clampD(s.maxSpeed / 520, 0.85, 1.2);

  void _updateAudio(double dt) {
    _audioClock += dt;
    final p = car.physics;
    final speed01 = clampD(p.speed / carStats.maxSpeed, 0, 1);

    // Countdown beeps, then the GO beep as the race starts.
    final label = race.countdownLabel;
    if (race.state == RaceState.countdown &&
        label != _lastLabel &&
        label.isNotEmpty) {
      audio.playSfx(Sfx.countdownBeep, volume: 0.9);
    }
    _lastLabel = label;
    if (race.state == RaceState.racing &&
        _lastRaceState == RaceState.countdown) {
      audio.playSfx(Sfx.goBeep, volume: 0.9);
    }
    _lastRaceState = race.state;

    // Music speeds up slightly on the final lap.
    if (!_finalLapMusic &&
        race.state == RaceState.racing &&
        race.displayLap(playerState) >= trackData.laps) {
      _finalLapMusic = true;
      audio.setMusicRate(1.06);
    }

    // Count drift starts (for achievements and rewards).
    final drifting = p.isDrifting;
    if (drifting && !_wasDrifting && race.state == RaceState.racing) {
      _drifts++;
    }
    _wasDrifting = drifting;

    // Nitro or boost pad: whoosh on the moment it starts.
    final boost = p.boostActive;
    if (boost && !_lastBoost && race.state == RaceState.racing) {
      audio.playSfx(Sfx.nitro, volume: 0.7, rate: audio.jitter());
    }
    _lastBoost = boost;

    // Engines and tyre squeal, refreshed ten times a second.
    if (_audioClock - _lastEngineTick >= 0.1) {
      _lastEngineTick = _audioClock;
      final playerMix = EngineMix(
        clampD(0.2 + 0.55 * speed01, 0, 0.8),
        (0.75 + 0.8 * speed01) * _rateBase(carStats),
      );
      final near = List<AiCar>.of(aiCars)
        ..sort((a, b) => a.physics.position
            .distanceTo(p.position)
            .compareTo(b.physics.position.distanceTo(p.position)));
      final others = <EngineMix>[];
      for (final ai in near.take(2)) {
        final attenuation =
            clampD(1 - ai.physics.position.distanceTo(p.position) / 1400, 0, 1);
        if (attenuation <= 0.02) continue;
        final s = clampD(ai.physics.speed / ai.profile.stats.maxSpeed, 0, 1);
        others.add(EngineMix(
          attenuation * (0.15 + 0.4 * s),
          (0.75 + 0.8 * s) * _rateBase(ai.profile.stats),
        ));
      }
      audio.updateEngines(playerMix, others);
      final slide =
          clampD((p.lateralSpeed.abs() - GameConfig.driftThreshold) / 220, 0, 1);
      audio.updateScreech(slide * 0.85);
    }

    effects.update(dt);
    screenFx.setLevels(speed01: speed01, nitro: boost);
  }

  void _updateHud() {
    final p = car.physics;
    final nextHud = HudState(
      speedKmh: (p.speed * GameConfig.kmhPerUnit).round(),
      surface: p.surface,
      nitro: (p.nitro * 100).round() / 100,
      nitroActive: p.boostActive,
      drifting: p.isDrifting,
    );
    if (nextHud != hud.value) hud.value = nextHud;

    final nextRace = RaceHudState(
      label: race.countdownLabel,
      lap: race.displayLap(playerState),
      totalLaps: trackData.laps,
      position: playerState.position,
      carCount: race.cars.length,
      wrongWay: playerState.wrongWay,
      coins: playerState.coins,
      state: race.state,
    );
    if (nextRace != raceHud.value) raceHud.value = nextRace;

    final nextTiming = RaceTiming(
      lapTime: playerState.currentLapTime,
      bestLap: playerState.bestLap,
      totalTime: race.raceTime,
    );
    if (nextTiming != timing.value) timing.value = nextTiming;

    minimapTick.value++;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    bool down(LogicalKeyboardKey k) => keysPressed.contains(k);
    input.keyboard
      ..left = down(LogicalKeyboardKey.arrowLeft) || down(LogicalKeyboardKey.keyA)
      ..right =
          down(LogicalKeyboardKey.arrowRight) || down(LogicalKeyboardKey.keyD)
      ..gas = down(LogicalKeyboardKey.arrowUp) || down(LogicalKeyboardKey.keyW)
      ..brakePedal =
          down(LogicalKeyboardKey.arrowDown) || down(LogicalKeyboardKey.keyS)
      ..handbrakeOn = down(LogicalKeyboardKey.space)
      ..nitroOn = down(LogicalKeyboardKey.shiftLeft) ||
          down(LogicalKeyboardKey.shiftRight) ||
          down(LogicalKeyboardKey.keyN);
    if (down(LogicalKeyboardKey.keyR)) respawnPlayer();
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyB) {
      toggleAiDebug();
    }
    return KeyEventResult.handled;
  }

  void toggleTuning() {
    if (overlays.isActive(tuningOverlay)) {
      overlays.remove(tuningOverlay);
    } else {
      overlays.add(tuningOverlay);
    }
  }

  void pauseGame() {
    race.pause();
    pauseEngine();
    audio.setGamePaused(true);
    input.reset();
    overlays
      ..remove(hudOverlay)
      ..remove(controlsOverlay)
      ..remove(tuningOverlay)
      ..add(pauseOverlay);
  }

  void resumeGame() {
    overlays.remove(pauseOverlay);
    if (result.value == null) {
      overlays
        ..add(hudOverlay)
        ..add(controlsOverlay);
    }
    input.reset();
    _stepper.reset();
    race.resume();
    resumeEngine();
    audio.setGamePaused(false);
  }
}
