import 'package:flutter/material.dart';
import 'package:racing/game/racing_game.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({required this.game, super.key});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton.filled(
            onPressed: game.pauseGame,
            icon: const Icon(Icons.pause),
          ),
        ),
      ),
    );
  }
}
