import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/app/router.dart';
import 'package:racing/core/utils/time_format.dart';
import 'package:racing/data/models/race_result.dart';
import 'package:racing/game/racing_game.dart';
import 'package:racing/l10n/app_localizations.dart';

/// Shown when the player finishes the race.
class ResultsOverlay extends StatelessWidget {
  const ResultsOverlay({required this.game, super.key});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: ValueListenableBuilder<RaceResult?>(
          valueListenable: game.result,
          builder: (context, r, _) {
            if (r == null) return const SizedBox.shrink();
            return _Card(game: game, result: r);
          },
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.game, required this.result});

  final RacingGame game;
  final RaceResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    return Container(
      width: 560,
      constraints: const BoxConstraints(maxHeight: 340),
      padding: const EdgeInsets.all(AppSpace.l),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppSpace.radius),
        border: Border.all(color: p.border),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.trackName.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                color: p.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.placeResult(ordinal(result.position)).toUpperCase(),
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: p.gold,
              ),
            ),
            const SizedBox(height: AppSpace.s),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpace.xl,
              runSpacing: AppSpace.s,
              children: [
                _Stat(
                  label: l10n.totalTime,
                  value: formatTime(result.totalTime),
                  badge: result.newBestTotal ? l10n.newRecord : null,
                ),
                _Stat(
                  label: l10n.bestLap,
                  value: result.bestLap == null
                      ? '-'
                      : formatTime(result.bestLap!),
                  badge: result.newBestLap ? l10n.newRecord : null,
                ),
                _Stat(
                  label: l10n.coins,
                  value: '+${result.reward}',
                  sub: l10n.collected(result.coins),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s),
            Wrap(
              spacing: AppSpace.m,
              runSpacing: 2,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < result.lapTimes.length; i++)
                  Text(
                    l10n.lapNumber(i + 1, formatTime(result.lapTimes[i])),
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            if (result.standings.length > 1) ...[
              const SizedBox(height: AppSpace.s),
              Wrap(
                spacing: AppSpace.s,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  for (final s in result.standings) _standing(context, s),
                ],
              ),
            ],
            const SizedBox(height: AppSpace.m),
            Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.s,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: 170,
                  child: AppButton(
                    label: l10n.raceAgain,
                    icon: Icons.replay,
                    onPressed: game.restart,
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: AppButton(
                    label: l10n.changeTrackCar,
                    primary: false,
                    onPressed: () => context.go(AppRoutes.tracks),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: AppButton(
                    label: l10n.menu,
                    primary: false,
                    onPressed: () => context.go(AppRoutes.menu),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _standing(BuildContext context, StandingEntry s) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    final name = s.isPlayer ? l10n.you : s.name;
    final time = s.time == null ? l10n.racing : formatTime(s.time!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.isPlayer ? p.gold.withValues(alpha: 0.35) : p.border.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${s.position}. $name  $time',
        style: TextStyle(
          fontSize: 11,
          fontWeight: s.isPlayer ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.badge,
    this.sub,
  });

  final String label;
  final String value;
  final String? badge;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: p.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        if (badge != null)
          Text(
            badge!.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: p.gold,
            ),
          ),
        if (sub != null) Text(sub!, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
