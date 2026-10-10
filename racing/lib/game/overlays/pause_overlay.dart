import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/app/router.dart';
import 'package:racing/game/racing_game.dart';
import 'package:racing/l10n/app_localizations.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({required this.game, super.key});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(AppSpace.l),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(AppSpace.radius),
            border: Border.all(color: p.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.paused.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpace.l),
              AppButton(
                label: l10n.resume,
                icon: Icons.play_arrow,
                onPressed: game.resumeGame,
              ),
              const SizedBox(height: AppSpace.s),
              AppButton(
                label: l10n.restart,
                icon: Icons.replay,
                primary: false,
                onPressed: () {
                  game
                    ..restart()
                    ..resumeGame();
                },
              ),
              const SizedBox(height: AppSpace.s),
              AppButton(
                label: l10n.quitToMenu,
                icon: Icons.exit_to_app,
                primary: false,
                onPressed: () => context.go(AppRoutes.menu),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
