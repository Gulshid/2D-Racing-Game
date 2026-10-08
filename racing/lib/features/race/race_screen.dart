import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:racing/game/overlays/hud_overlay.dart';
import 'package:racing/game/overlays/loading_view.dart';
import 'package:racing/game/overlays/pause_overlay.dart';
import 'package:racing/game/racing_game.dart';


class RaceScreen extends StatefulWidget {
  const RaceScreen({super.key});

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> with WidgetsBindingObserver {
  late final RacingGame _game;

  @override
  void initState() {
    super.initState();
    _game = RacingGame();
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
          RacingGame.pauseOverlay: (context, game) => PauseOverlay(game: game),
        },
        initialActiveOverlays: const [RacingGame.hudOverlay],
      ),
    );
  }
}
