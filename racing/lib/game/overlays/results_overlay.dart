import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/router.dart';
import 'package:racing/core/utils/time_format.dart';
import 'package:racing/data/models/race_result.dart';
import 'package:racing/game/racing_game.dart';

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
    const gold = Color(0xFFFFC107);
    return Container(
      width: 520,
      constraints: const BoxConstraints(maxHeight: 340),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xF20B1F3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.trackName.toUpperCase(),
              style: const TextStyle(fontSize: 12, letterSpacing: 2),
            ),
            const SizedBox(height: 2),
            Text(
              '${ordinal(result.position)} PLACE',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: gold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stat('TOTAL TIME', formatTime(result.totalTime),
                    badge: result.newBestTotal ? 'NEW RECORD' : null),
                const SizedBox(width: 28),
                _stat(
                  'BEST LAP',
                  result.bestLap == null ? '-' : formatTime(result.bestLap!),
                  badge: result.newBestLap ? 'NEW RECORD' : null,
                ),
                const SizedBox(width: 28),
                _stat('COINS', '+${result.reward}',
                    sub: '${result.coins} collected'),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 2,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < result.lapTimes.length; i++)
                  Text(
                    'Lap ${i + 1}  ${formatTime(result.lapTimes[i])}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            if (result.standings.length > 1) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  for (final s in result.standings) _standing(s),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: game.restart,
                  child: const Text('RACE AGAIN'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.setup),
                  child: const Text('CHANGE TRACK / CAR'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.menu),
                  child: const Text('MENU'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _standing(StandingEntry s) {
    final name = s.isPlayer ? 'YOU' : s.name;
    final time = s.time == null ? 'racing' : formatTime(s.time!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.isPlayer ? const Color(0x55FFC107) : const Color(0x33FFFFFF),
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

  Widget _stat(String label, String value, {String? badge, String? sub}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, letterSpacing: 1.5)),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        if (badge != null)
          Text(
            badge,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7CFC9A),
            ),
          ),
        if (sub != null) Text(sub, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
