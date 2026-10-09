import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/models/race_records.dart';
import 'package:racing/data/models/race_result.dart';
import 'package:racing/data/models/track_data.dart';
import 'package:racing/game/components/car/ghost_car.dart';
import 'package:racing/game/components/car/player_car.dart';
import 'package:racing/game/components/effects/spark_emitter.dart';
import 'package:racing/game/components/props/cone_component.dart';
import 'package:racing/game/components/props/pickup_component.dart';
import 'package:racing/game/components/track/track_component.dart';
import 'package:racing/game/components/track/track_map.dart';
import 'package:racing/game/systems/camera_controller.dart';
import 'package:racing/game/systems/collision_system.dart';
import 'package:racing/game/systems/fixed_stepper.dart';
import 'package:racing/game/systems/fixed_update.dart';
import 'package:racing/game/systems/ghost_recorder.dart';
import 'package:racing/game/systems/hud_state.dart';
import 'package:racing/game/systems/impact_feedback.dart';
import 'package:racing/game/systems/input_controller.dart';
import 'package:racing/game/systems/race_hud_state.dart';
import 'package:racing/game/systems/race_manager.dart';

class RacingGame extends FlameGame with KeyboardEvents {
  RacingGame({required this.trackData, required this.carStats});

  static const String hudOverlay = 'hud';
  static const String controlsOverlay = 'controls';
  static const String tuningOverlay = 'tuning';
  static const String pauseOverlay = 'pause';
  static const String resultsOverlay = 'results';

  final TrackData trackData;
  final CarStats carStats;

  // These are created lazily so overlays can read them at any time.
  late final TrackMap track = TrackMap(trackData);
  late final PlayerCar car = PlayerCar(stats: carStats);
  late final CameraController cameraController =
      CameraController(target: car);
  late final SparkEmitter sparks = SparkEmitter();
  late final GhostCar ghost = GhostCar();
  late final RaceCarState playerState =
      RaceCarState(id: 'player', name: carStats.name, isPlayer: true);
  late final RaceManager race = RaceManager(
    track: track,
    totalLaps: trackData.laps,
    cars: [playerState],
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
    await world.add(car);
    await world.add(sparks);
    await world.add(cameraController);

    _setUpSystems();
    _ready = true;
    restart();
  }

  void _setUpSystems() {
    collisions = CollisionSystem(
      track: track,
      cars: [car.physics],
      cones: _cones,
      pickups: _pickups,
      player: car.physics,
    );
    feedback = ImpactFeedback(camera: cameraController, sparks: sparks);

    bool isPlayer(Object c) => identical(c, car.physics);

    collisions.onWall = (c, point, normal, impact, slide) {
      feedback.wall(point, normal, impact, slide, isPlayer: isPlayer(c));
    };
    collisions.onCarHit = (a, b, point, impact) {
      feedback.carHit(
        point,
        impact,
        involvesPlayer: isPlayer(a) || isPlayer(b),
      );
    };
    collisions.onPickup = (c, type) {
      if (isPlayer(c)) {
        if (type == PropType.coin) playerState.coins++;
        feedback.light();
      }
    };
    collisions.onConeHit = (c) {
      if (isPlayer(c)) feedback.light();
    };
    collisions.onBoostPad = (c) {
      if (isPlayer(c)) {
        cameraController.addShake(0.25);
        feedback.light();
      }
    };

    race.onLapStart = (s) {
      if (s.isPlayer) _recorder.begin();
    };
    race.onLapComplete = (s, lapTime, lap) {
      if (!s.isPlayer) return;
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
      reward: RaceResult.rewardFor(playerState.position, playerState.coins),
      newBestLap: newBestLap,
      newBestTotal: newBestTotal,
    );

    input.reset();
    overlays
      ..remove(hudOverlay)
      ..remove(controlsOverlay)
      ..remove(tuningOverlay)
      ..add(resultsOverlay);
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
    });

    super.update(dt);
    feedback.tick(dt);

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

    _updateHud();
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

    timing.value = RaceTiming(
      lapTime: playerState.currentLapTime,
      bestLap: playerState.bestLap,
      totalTime: race.raceTime,
    );

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
  }
}
