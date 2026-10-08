import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:racing_game/core/constants/game_config.dart';
import 'package:racing_game/game/components/test_box.dart';
import 'package:racing_game/game/systems/fixed_stepper.dart';
import 'package:racing_game/game/systems/fixed_update.dart';

class RacingGame extends FlameGame {
  RacingGame();

  static const String hudOverlay = 'hud';
  static const String pauseOverlay = 'pause';

  /// 0..1, listened to by the loading screen.
  final ValueNotifier<double> loadProgress = ValueNotifier<double>(0);

  final FixedStepper _stepper = FixedStepper(
    GameConfig.physicsStep,
    maxFrameTime: GameConfig.maxFrameTime,
  );

  int _stepsThisSecond = 0;
  double _logTimer = 0;

  @override
  Color backgroundColor() => const Color(0xFF1B2A41);

  @override
  Future<void> onLoad() async {
    debugMode = kDebugMode;
    await _preloadAssets();

    camera.viewport.add(FpsTextComponent(position: Vector2(12, 8)));
    await world.add(TestBox()..position = Vector2(100, 100));
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

  @override
  void update(double dt) {
    final steps = _stepper.run(dt, (step) {
      for (final c in world.children.whereType<FixedUpdate>()) {
        c.fixedUpdate(step);
      }
    });

    super.update(dt);

    if (kDebugMode) {
      _stepsThisSecond += steps;
      _logTimer += dt;
      if (_logTimer >= 1) {
        debugPrint('physics steps/sec: $_stepsThisSecond');
        _stepsThisSecond = 0;
        _logTimer = 0;
      }
    }
  }

  void pauseGame() {
    pauseEngine();
    overlays
      ..remove(hudOverlay)
      ..add(pauseOverlay);
  }

  void resumeGame() {
    overlays
      ..remove(pauseOverlay)
      ..add(hudOverlay);
    _stepper.reset();
    resumeEngine();
  }

  @override
  void onRemove() {
    loadProgress.dispose();
    super.onRemove();
  }
}
