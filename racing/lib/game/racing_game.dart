import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/models/track_data.dart';
import 'package:racing/game/components/car/player_car.dart';
import 'package:racing/game/components/track/track_component.dart';
import 'package:racing/game/components/track/track_map.dart';
import 'package:racing/game/systems/camera_controller.dart';
import 'package:racing/game/systems/fixed_stepper.dart';
import 'package:racing/game/systems/fixed_update.dart';
import 'package:racing/game/systems/hud_state.dart';
import 'package:racing/game/systems/input_controller.dart';

class RacingGame extends FlameGame with KeyboardEvents {
  RacingGame({required this.trackData, required this.carStats});

  static const String hudOverlay = 'hud';
  static const String controlsOverlay = 'controls';
  static const String tuningOverlay = 'tuning';
  static const String pauseOverlay = 'pause';

  final TrackData trackData;
  final CarStats carStats;

  // These are created lazily so overlays can read them at any time.
  late final TrackMap track = TrackMap(trackData);
  late final PlayerCar car = PlayerCar(stats: carStats);
  late final CameraController cameraController =
      CameraController(target: car);

  final InputController input = InputController();

  /// 0..1, listened to by the loading screen.
  final ValueNotifier<double> loadProgress = ValueNotifier<double>(0);

  /// Values shown by the HUD.
  final ValueNotifier<HudState> hud = ValueNotifier<HudState>(const HudState());

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

    await world.add(TrackComponent(track));
    await world.add(car);
    await world.add(cameraController);

    restart();
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

  /// Puts the car back on the start grid.
  void restart() {
    final spawn = track.spawn(0);
    car.resetTo(spawn.position, spawn.heading);
    input.reset();
    _stepper.reset();
    cameraController.snap();
  }

  @override
  void update(double dt) {
    _stepper.run(dt, (step) {
      for (var i = 0; i < _fixed.length; i++) {
        _fixed[i].fixedUpdate(step);
      }
    });

    super.update(dt);

    final p = car.physics;
    final next = HudState(
      speedKmh: (p.speed * GameConfig.kmhPerUnit).round(),
      surface: p.surface,
      nitro: (p.nitro * 100).round() / 100,
      nitroActive: p.nitroActive,
      drifting: p.isDrifting,
    );
    if (next != hud.value) hud.value = next;
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
    pauseEngine();
    input.reset();
    overlays
      ..remove(hudOverlay)
      ..remove(controlsOverlay)
      ..remove(tuningOverlay)
      ..add(pauseOverlay);
  }

  void resumeGame() {
    overlays
      ..remove(pauseOverlay)
      ..add(hudOverlay)
      ..add(controlsOverlay);
    input.reset();
    _stepper.reset();
    resumeEngine();
  }
}
