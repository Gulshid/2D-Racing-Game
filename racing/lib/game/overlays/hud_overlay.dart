import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:racing/core/utils/time_format.dart';
import 'package:racing/game/overlays/minimap.dart';
import 'package:racing/game/racing_game.dart';
import 'package:racing/game/systems/hud_state.dart';
import 'package:racing/game/systems/race_hud_state.dart';

const _shadow = [Shadow(blurRadius: 6, color: Colors.black87)];

class HudOverlay extends StatelessWidget {
  const HudOverlay({required this.game, super.key});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Minimap (top-left, below the FPS counter)
          Positioned(
            left: 4,
            top: 30,
            child: SizedBox(
              width: 130,
              height: 86,
              child: CustomPaint(
                painter: MinimapPainter(
                  map: game.track,
                  carPosition: () => game.car.physics.position,
                  repaint: game.minimapTick,
                ),
              ),
            ),
          ),
          // Lap, position, coins and timers (top-center)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _RaceInfo(game: game),
            ),
          ),
          // Respawn, tuning and pause buttons (top-right)
          Positioned(
            right: 4,
            top: 4,
            child: Row(
              children: [
                if (kDebugMode) ...[
                  IconButton.filledTonal(
                    onPressed: game.toggleTuning,
                    icon: const Icon(Icons.tune),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton.filledTonal(
                  tooltip: 'Back on road',
                  onPressed: game.respawnPlayer,
                  icon: const Icon(Icons.my_location),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: game.pauseGame,
                  icon: const Icon(Icons.pause),
                ),
              ],
            ),
          ),
          // Countdown and wrong-way warning (center)
          Align(
            alignment: const Alignment(0, -0.2),
            child: IgnorePointer(
              child: ValueListenableBuilder<RaceHudState>(
                valueListenable: game.raceHud,
                builder: (context, s, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (s.label.isNotEmpty)
                      Text(
                        s.label,
                        style: const TextStyle(
                          fontSize: 96,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFC107),
                          shadows: _shadow,
                        ),
                      ),
                    if (s.wrongWay)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xDDD32F2F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'WRONG WAY',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Speedometer (bottom-center)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ValueListenableBuilder<HudState>(
                valueListenable: game.hud,
                builder: (context, s, _) => _Speedometer(state: s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaceInfo extends StatelessWidget {
  const _RaceInfo({required this.game});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<RaceHudState>(
            valueListenable: game.raceHud,
            builder: (context, s, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _chip('LAP ${s.lap}/${s.totalLaps}'),
                const SizedBox(width: 6),
                _chip('POS ${s.position}/${s.carCount}'),
                const SizedBox(width: 6),
                _chip('COINS ${s.coins}'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<RaceTiming>(
            valueListenable: game.timing,
            builder: (context, t, _) {
              final best = t.bestLap;
              final bestText =
                  best == null ? '' : '   BEST ${formatTime(best)}';
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatTime(t.totalTime),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      shadows: _shadow,
                    ),
                  ),
                  Text(
                    'LAP ${formatTime(t.lapTime)}$bestText',
                    style: const TextStyle(fontSize: 12, shadows: _shadow),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x99000000),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      );
}

class _Speedometer extends StatelessWidget {
  const _Speedometer({required this.state});

  final HudState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          state.drifting ? 'DRIFT' : ' ',
          style: const TextStyle(
            color: Color(0xFFFFC107),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            shadows: _shadow,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${state.speedKmh}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                shadows: _shadow,
              ),
            ),
            const SizedBox(width: 4),
            const Text('km/h', style: TextStyle(fontSize: 12, shadows: _shadow)),
          ],
        ),
        SizedBox(
          width: 150,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.nitro,
              minHeight: 7,
              backgroundColor: Colors.black45,
              color: state.nitroActive
                  ? const Color(0xFFFFC107)
                  : const Color(0xFF29B6F6),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          state.surface.label,
          style: const TextStyle(fontSize: 11, shadows: _shadow),
        ),
      ],
    );
  }
}
