import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:racing/data/models/ai_profile.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/tracks/track_library.dart';
import 'package:racing/game/overlays/hud_overlay.dart';
import 'package:racing/game/overlays/loading_view.dart';
import 'package:racing/game/overlays/pause_overlay.dart';
import 'package:racing/game/overlays/results_overlay.dart';
import 'package:racing/game/overlays/touch_controls_overlay.dart';
import 'package:racing/game/overlays/tuning_overlay.dart';
import 'package:racing/game/racing_game.dart';

class RaceScreen extends StatefulWidget {
  const RaceScreen({
    required this.trackId,
    required this.carIndex,
    this.difficulty = AiDifficulty.medium,
    this.aiCount = 5,
    super.key,
  });

  final String trackId;
  final int carIndex;
  final AiDifficulty difficulty;
  final int aiCount;

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> with WidgetsBindingObserver {
  late final RacingGame _game;

  @override
  void initState() {
    super.initState();
    _game = RacingGame(
      trackData: TrackLibrary.byId(widget.trackId),
      carStats: CarPresets.byIndex(widget.carIndex),
      difficulty: widget.difficulty,
      aiCount: widget.aiCount,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        !_game.overlays.isActive(RacingGame.pauseOverlay)) {
      _game.pauseGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<RacingGame>(
        game: _game,
        loadingBuilder: (context) => LoadingView(progress: _game.loadProgress),
        errorBuilder: (context, error) =>
            Center(child: Text('Game error: $error')),
        overlayBuilderMap: {
          RacingGame.hudOverlay: (context, game) => HudOverlay(game: game),
          RacingGame.controlsOverlay: (context, game) =>
              TouchControlsOverlay(game: game),
          RacingGame.tuningOverlay: (context, game) =>
              TuningOverlay(game: game),
          RacingGame.pauseOverlay: (context, game) => PauseOverlay(game: game),
          RacingGame.resultsOverlay: (context, game) =>
              ResultsOverlay(game: game),
        },
        initialActiveOverlays: const [
          RacingGame.hudOverlay,
          RacingGame.controlsOverlay,
        ],
      ),
    );
  }
}
