import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/router.dart';
import 'package:racing/game/racing_game.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({required this.game, super.key});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: game.resumeGame,
              child: const Text('RESUME'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                game
                  ..restart()
                  ..resumeGame();
              },
              child: const Text('RESTART'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.menu),
              child: const Text('QUIT TO MENU'),
            ),
          ],
        ),
      ),
    );
  }
}
